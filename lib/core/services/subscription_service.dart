import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/subscription_model.dart';

class SubscriptionService {
  // Singleton instance
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // In-App Purchase plugin
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Stream controllers
  final _subscriptionController = StreamController<UserSubscription>.broadcast();
  final _productsController = StreamController<List<ProductDetails>>.broadcast();
  final _purchaseUpdatedController = StreamController<List<PurchaseDetails>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Timer? _temporaryAccessTimer;

  // State
  bool _isInitialized = false;
  UserSubscription _currentSubscription = const UserSubscription.free();
  List<ProductDetails> _products = [];

  // Streams
  Stream<UserSubscription> get subscriptionStream => _subscriptionController.stream;
  Stream<List<ProductDetails>> get productsStream => _productsController.stream;
  Stream<List<PurchaseDetails>> get purchaseUpdatedStream => _purchaseUpdatedController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  UserSubscription get currentSubscription => _currentSubscription;
  List<ProductDetails> get products => _products;
  bool get isProUser => _currentSubscription.isPro;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved subscription data
      await _loadSubscriptionData();

      // Start timer to check temporary access expiry
      _startTemporaryAccessTimer();

      // Initialize the IAP plugin
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        _errorController.add('In-app purchases are not available on this device.');
        return;
      }

      // Set up purchase listener
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          _errorController.add('Purchase error: $error');
        },
      );

      // Fetch available products
      await loadProducts();

      // Verify existing purchases
      await _verifyPreviousPurchases();

      _isInitialized = true;
    } catch (e) {
      _errorController.add('Initialization error: $e');
    }
  }

  // Load products from the store
  Future<void> loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(ProductCatalog.allProductIds);
      if (response.error != null) {
        _errorController.add('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      _productsController.add(_products);
    } catch (e) {
      _errorController.add('Error loading products: $e');
    }
  }

  // Purchase a one-time product (tier, add-on or effect pack)
  Future<void> purchase(ProductDetails product) async {
    try {
      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      // Start the purchase flow
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      _updateSubscription(_currentSubscription.copyWith(isPurchasePending: true));
    } catch (e) {
      _errorController.add('Purchase error: $e');
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

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _errorController.add('Restore error: $e');
    }
  }

  // Process purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    _purchaseUpdatedController.add(purchaseDetailsList);

    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _updateSubscription(_currentSubscription.copyWith(isPurchasePending: true));
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _updateSubscription(_currentSubscription.copyWith(isPurchasePending: false));
          _errorController.add('Purchase error: ${purchaseDetails.error?.message}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Grant entitlement to user
          _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _updateSubscription(_currentSubscription.copyWith(isPurchasePending: false));
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // Process a successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    // Verify the purchase on server (simplified for example)
    final bool isValidPurchase = _verifyPurchase(purchaseDetails);

    if (isValidPurchase && ProductCatalog.isKnownProduct(purchaseDetails.productID)) {
      _updateSubscription(_currentSubscription.withProduct(purchaseDetails.productID));
    } else {
      _errorController.add('Invalid purchase');
    }
  }

  // Simple verification (replace with real verification logic)
  bool _verifyPurchase(PurchaseDetails purchaseDetails) {
    // In a real app, verify with server and store's API
    return purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored;
  }

  // Verify previous purchases on startup
  Future<void> _verifyPreviousPurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _errorController.add('Error verifying purchases: $e');
    }
  }

  // Update subscription and save data
  void _updateSubscription(UserSubscription subscription) {
    _currentSubscription = subscription;
    _subscriptionController.add(_currentSubscription);
    _saveSubscriptionData();
  }

  // Load subscription data from storage
  Future<void> _loadSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('user_subscription');

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

      final data = _currentSubscription.toJson();

      await prefs.setString('user_subscription', jsonEncode(data));
    } catch (e) {
      _errorController.add('Error saving subscription data: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _purchaseSubscription?.cancel();
    _temporaryAccessTimer?.cancel();
    _subscriptionController.close();
    _productsController.close();
    _purchaseUpdatedController.close();
    _errorController.close();
  }

  ProductDetails? getProductDetails(String productId) {
    return _products.firstWhereOrNull((product) => product.id == productId);
  }
}
