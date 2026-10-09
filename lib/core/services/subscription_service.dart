import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/subscription_model.dart';

/// RevenueCat project settings. SDK keys are public, but live in `.env` so
/// test and production projects can be swapped without code changes.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Entitlement granted by Pro and Ultimate in the RevenueCat dashboard.
  static const String proEntitlement = 'picell_pixel_art_editor_pro';

  /// Offering metadata key that switches the paywall to RevenueCat Paywalls.
  static const String useRevenueCatPaywallKey = 'use_revenuecat_paywall';

  static String? get apiKey {
    String? read(String name) {
      final value = dotenv.maybeGet(name);
      return value == null || value.isEmpty ? null : value;
    }

    final platformKey = Platform.isIOS || Platform.isMacOS
        ? read('REVENUECAT_APPLE_API_KEY')
        : Platform.isAndroid
            ? read('REVENUECAT_GOOGLE_API_KEY')
            : null;
    if (platformKey != null) return platformKey;

    // Test Store keys simulate purchases and must never ship to users.
    return kReleaseMode ? null : read('REVENUECAT_TEST_API_KEY');
  }
}

enum PurchaseOutcome { purchased, restored, cancelled, failed }

/// Result of a purchase or restore started by the user.
class PurchaseEvent {
  const PurchaseEvent(this.outcome, {this.productId, this.message});

  final PurchaseOutcome outcome;
  final String? productId;
  final String? message;
}

/// Purchases through RevenueCat. Owned products are read from RevenueCat's
/// [CustomerInfo] and mapped to entitlements locally by [ProductCatalog].
class SubscriptionService {
  // Singleton instance
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const _storageKey = 'user_subscription';

  /// Set once purchases made before RevenueCat were synced to it.
  static const _storeSyncedKey = 'revenuecat_store_synced';

  // Stream controllers
  final _subscriptionController = StreamController<UserSubscription>.broadcast();
  final _productsController = StreamController<List<StoreProduct>>.broadcast();
  final _purchaseEventsController = StreamController<PurchaseEvent>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Timer? _temporaryAccessTimer;

  // State
  bool _isInitialized = false;
  bool _isConfigured = false;

  /// Until the first sync with the store succeeds, RevenueCat may not know
  /// the original Pro bought through the old in-app purchase flow, so a
  /// cached one is kept alongside what it reports.
  bool _storeSynced = false;
  UserSubscription _currentSubscription = const UserSubscription.free();
  Map<String, StoreProduct> _products = {};
  Offerings? _offerings;

  // Streams
  Stream<UserSubscription> get subscriptionStream => _subscriptionController.stream;
  Stream<List<StoreProduct>> get productsStream => _productsController.stream;
  Stream<PurchaseEvent> get purchaseEvents => _purchaseEventsController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  UserSubscription get currentSubscription => _currentSubscription;
  List<StoreProduct> get products => _products.values.toList();
  bool get isProUser => _currentSubscription.isPro;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Cached state keeps purchases usable offline and holds temporary access.
    await _loadSubscriptionData();
    _startTemporaryAccessTimer();

    final apiKey = RevenueCatConfig.apiKey;
    if (apiKey == null) {
      _errorController.add('In-app purchases are not configured for this platform.');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isConfigured = true;

      await _syncExistingPurchasesOnce();
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      _applyCustomerInfo(await Purchases.getCustomerInfo());
      await loadProducts();
    } on PlatformException catch (e) {
      _errorController.add('Purchases unavailable: ${_describe(e)}');
    } catch (e) {
      _errorController.add('Initialization error: $e');
    }
  }

  /// Sends purchases made before the RevenueCat integration (such as the
  /// original Pro, now Ultimate) to RevenueCat. Silent: no store sign-in.
  Future<void> _syncExistingPurchasesOnce() async {
    final prefs = await SharedPreferences.getInstance();
    _storeSynced = prefs.getBool(_storeSyncedKey) ?? false;
    if (_storeSynced) return;
    try {
      await Purchases.syncPurchases();
      _storeSynced = true;
      await prefs.setBool(_storeSyncedKey, true);
    } on PlatformException catch (e) {
      // Retried on the next launch; cached purchases stay unlocked meanwhile.
      _errorController.add('Could not sync existing purchases: ${_describe(e)}');
    }
  }

  /// Loads prices for every product in [ProductCatalog]: offerings first, so
  /// purchases are attributed to the offering that showed them, then any
  /// product not placed in an offering.
  Future<void> loadProducts() async {
    if (!_isConfigured) return;
    try {
      final products = <String, StoreProduct>{};
      try {
        final offerings = await Purchases.getOfferings();
        _offerings = offerings;
        for (final offering in offerings.all.values) {
          for (final package in offering.availablePackages) {
            products.putIfAbsent(package.storeProduct.identifier, () => package.storeProduct);
          }
        }
      } on PlatformException catch (e) {
        if (PurchasesErrorHelper.getErrorCode(e) != PurchasesErrorCode.configurationError) rethrow;
        // Offerings are optional for the custom store. Keep loading known
        // product IDs directly when the dashboard has no configured offering.
        _offerings = null;
        print('RevenueCat offerings unavailable; loading store products directly: ${_describe(e)}');
      }

      final missing = ProductCatalog.allProductIds.difference(products.keys.toSet()).toList();
      if (missing.isNotEmpty) {
        final fetched = await Purchases.getProducts(missing, productCategory: ProductCategory.nonSubscription);
        for (final product in fetched) {
          products[product.identifier] = product;
        }
      }

      _products = products;
      _productsController.add(this.products);
      print('Loaded ${products.length} products from RevenueCat: ${products.keys.join(', ')}');
    } on PlatformException catch (e) {
      print('Error loading products: ${_describe(e)}');
      _errorController.add('Error loading products: ${_describe(e)}');
    }
  }

  /// Buys a one-time product (tier, upgrade, add-on or effect pack).
  Future<void> purchase(StoreProduct product) async {
    _updateSubscription(_currentSubscription.copyWith(isPurchasePending: true));
    try {
      // Buying through the package keeps offering attribution for analytics.
      final package = _packageFor(product.identifier);
      final result = await Purchases.purchase(
        package != null ? PurchaseParams.package(package) : PurchaseParams.storeProduct(product),
      );
      _applyCustomerInfo(result.customerInfo);
      _purchaseEventsController.add(PurchaseEvent(PurchaseOutcome.purchased, productId: product.identifier));
    } on PlatformException catch (e) {
      switch (PurchasesErrorHelper.getErrorCode(e)) {
        case PurchasesErrorCode.purchaseCancelledError:
          _purchaseEventsController.add(PurchaseEvent(PurchaseOutcome.cancelled, productId: product.identifier));
        case PurchasesErrorCode.productAlreadyPurchasedError:
          // Already owned on this store account: sync it instead of failing.
          await restorePurchases();
        default:
          _purchaseEventsController.add(
            PurchaseEvent(PurchaseOutcome.failed, productId: product.identifier, message: _describe(e)),
          );
          _errorController.add('Purchase error: ${_describe(e)}');
      }
    } finally {
      _updateSubscription(_currentSubscription.copyWith(isPurchasePending: false));
    }
  }

  Future<void> restorePurchases() async {
    if (!_isConfigured) return;
    try {
      _applyCustomerInfo(await Purchases.restorePurchases());
      _purchaseEventsController.add(const PurchaseEvent(PurchaseOutcome.restored));
    } on PlatformException catch (e) {
      _purchaseEventsController.add(PurchaseEvent(PurchaseOutcome.failed, message: _describe(e)));
      _errorController.add('Restore error: ${_describe(e)}');
    }
  }

  /// Whether the dashboard asks for RevenueCat Paywalls instead of the
  /// built-in paywall, through metadata on the current offering.
  bool get usesRevenueCatPaywall {
    final value = _offerings?.current?.metadata[RevenueCatConfig.useRevenueCatPaywallKey];
    return _isConfigured && (value == true || value == 'true');
  }

  /// Shows the paywall designed in the RevenueCat dashboard for the current
  /// offering. Returns true if the user bought or restored something.
  Future<bool> presentPaywall() async {
    if (!_isConfigured) return false;
    try {
      final result = await RevenueCatUI.presentPaywall(displayCloseButton: true);
      // Purchases made in the paywall also reach the customer info listener.
      return result == PaywallResult.purchased || result == PaywallResult.restored;
    } on PlatformException catch (e) {
      _errorController.add('Paywall error: ${_describe(e)}');
      return false;
    }
  }

  /// RevenueCat Customer Center: restore, refund requests and support.
  Future<void> presentCustomerCenter() async {
    if (!_isConfigured) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } on PlatformException catch (e) {
      _errorController.add('Customer Center error: ${_describe(e)}');
    }
  }

  // Grant temporary pro access from watching ads
  void grantTemporaryProAccess({Duration duration = const Duration(hours: 1)}) {
    final temporaryAccess = TemporaryProAccess(
      startTime: DateTime.now(),
      duration: duration,
    );

    _updateSubscription(_currentSubscription.copyWith(temporaryProAccess: temporaryAccess));

    // Restart the timer to check for expiry
    _startTemporaryAccessTimer();
  }

  /// Clear temporary pro access
  void clearTemporaryProAccess() {
    _updateSubscription(_currentSubscription.copyWith(clearTemporaryProAccess: true));
  }

  StoreProduct? getProductDetails(String productId) => _products[productId];

  Package? _packageFor(String productId) {
    final offerings = _offerings;
    if (offerings == null) return null;
    final current = offerings.current;
    final ordered = [
      if (current != null) current,
      ...offerings.all.values.where((offering) => offering.identifier != current?.identifier),
    ];
    for (final offering in ordered) {
      final package = offering.availablePackages.firstWhereOrNull(
        (package) => package.storeProduct.identifier == productId,
      );
      if (package != null) return package;
    }
    return null;
  }

  /// RevenueCat is the source of truth for purchases; known products become
  /// entitlements through [ProductCatalog].
  void _applyCustomerInfo(CustomerInfo info) {
    final owned = info.allPurchasedProductIdentifiers.where(ProductCatalog.isKnownProduct).toSet();

    // Before the first sync, keep only what the old flow could have sold
    // (the original Pro, now Ultimate); everything else comes from RevenueCat.
    if (!_storeSynced && _currentSubscription.ownedProductIds.contains(SubscriptionProductIds.ultimate)) {
      owned.add(SubscriptionProductIds.ultimate);
    }

    // The Pro entitlement unlocks Pro only when granted from the dashboard
    // (promotional grants, products outside the catalog). Catalog products,
    // such as effect packs attached to it by mistake, unlock only what the
    // catalog says.
    final proEntitlement = info.entitlements.active[RevenueCatConfig.proEntitlement];
    final grantedOutsideCatalog =
        proEntitlement != null && !ProductCatalog.isKnownProduct(proEntitlement.productIdentifier);
    final ownsProProduct = ProductCatalog.entitlementsFor(owned).contains(Entitlement.pro);
    if (grantedOutsideCatalog && !ownsProProduct) owned.add(SubscriptionProductIds.pro);

    _updateSubscription(_currentSubscription.copyWith(ownedProductIds: owned));
  }

  String _describe(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    return '${code.name}: ${e.message ?? e.code}';
  }

  // Start timer to monitor temporary access expiry
  void _startTemporaryAccessTimer() {
    _temporaryAccessTimer?.cancel();

    if (_currentSubscription.hasTemporaryPro) {
      final remainingTime = _currentSubscription.temporaryProAccess!.remainingTime;

      if (remainingTime > Duration.zero) {
        _temporaryAccessTimer = Timer(remainingTime, () {
          // Clear temporary access when it expires
          _updateSubscription(_currentSubscription.copyWith(clearTemporaryProAccess: true));
        });
      } else {
        // Access has already expired
        _updateSubscription(_currentSubscription.copyWith(clearTemporaryProAccess: true));
      }
    }
  }

  // Update subscription and save data
  void _updateSubscription(UserSubscription subscription) {
    if (subscription == _currentSubscription) return;
    _currentSubscription = subscription;
    _subscriptionController.add(_currentSubscription);
    _saveSubscriptionData();
  }

  // Load subscription data from storage
  Future<void> _loadSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_storageKey);

      if (jsonData != null) {
        _currentSubscription = UserSubscription.fromJson(jsonDecode(jsonData) as Map<String, dynamic>);
        _subscriptionController.add(_currentSubscription);
      }
    } catch (e) {
      _errorController.add('Error loading subscription data: $e');
    }
  }

  // Save subscription data to storage
  Future<void> _saveSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_currentSubscription.toJson()));
    } catch (e) {
      _errorController.add('Error saving subscription data: $e');
    }
  }

  Future<void> testUnsubscribe() async {
    final service = this;
    _updateSubscription(const UserSubscription.free());
    await _saveSubscriptionData();
    await service.loadProducts();
  }

  // Clean up resources
  void dispose() {
    if (_isConfigured) Purchases.removeCustomerInfoUpdateListener(_applyCustomerInfo);
    _temporaryAccessTimer?.cancel();
    _subscriptionController.close();
    _productsController.close();
    _purchaseEventsController.close();
    _errorController.close();
  }
}
