import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:picell/config/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/subscription_model.dart';
import '../core/services/subscription_service.dart';

part 'subscription_provider.g.dart';

const kIsTestingDefault = kDebugMode;

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

@riverpod
class SubscriptionState extends _$SubscriptionState {
  @override
  UserSubscription build() {
    if (kIsDemo) {
      return const UserSubscription.free();
    }

    const testing = bool.fromEnvironment('TESTING', defaultValue: kIsTestingDefault);

    if (kIsWeb || Platform.isWindows || testing) {
      return const UserSubscription.unlocked();
    }

    final service = ref.watch(subscriptionServiceProvider);

    if (!service.isInitialized) {
      service.initialize();
    }

    ref.listen(subscriptionStreamProvider, (previous, next) {
      if (next.valueOrNull != null) {
        state = next.value!;
      }
    });

    return service.currentSubscription;
  }

  Future<void> purchase(String productId) async {
    final service = ref.read(subscriptionServiceProvider);

    try {
      final productDetails = service.getProductDetails(productId);
      if (productDetails != null) {
        await service.purchase(productDetails);
      } else {
        throw Exception('Product $productId is not available');
      }
    } catch (e, s) {
      print('Error purchasing $productId: $e');
      print(s);
      rethrow;
    }
  }

  void grantTemporaryProAccess({Duration duration = const Duration(hours: 1)}) {
    final service = ref.read(subscriptionServiceProvider);
    service.grantTemporaryProAccess(duration: duration);
  }

  Future<void> restorePurchases() async {
    final service = ref.read(subscriptionServiceProvider);
    await service.restorePurchases();
  }

  bool hasFeatureAccess(SubscriptionFeature feature) {
    return state.hasFeatureAccess(feature);
  }

  T getFeatureLimit<T>(SubscriptionFeature feature) {
    return state.getFeatureLimit<T>(feature);
  }

  Duration? getRemainingTemporaryProTime() {
    if (state.hasTemporaryPro) {
      return state.temporaryProAccess?.remainingTime;
    }
    return null;
  }
}

@riverpod
Stream<UserSubscription> subscriptionStream(SubscriptionStreamRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.subscriptionStream;
}

@riverpod
Stream<List<StoreProduct>> productsStream(ProductsStreamRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.productsStream;
}

@riverpod
Stream<PurchaseEvent> purchaseEventsStream(PurchaseEventsStreamRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.purchaseEvents;
}

@riverpod
Stream<String> subscriptionErrorsStream(SubscriptionErrorsStreamRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.errorStream;
}

@riverpod
bool isFeatureLocked(IsFeatureLockedRef ref, SubscriptionFeature feature) {
  final subscriptionState = ref.watch(subscriptionStateProvider);

  switch (feature) {
    case SubscriptionFeature.advancedTools:
    case SubscriptionFeature.cloudBackup:
    case SubscriptionFeature.noWatermark:
    case SubscriptionFeature.prioritySupport:
      return !ref.read(subscriptionStateProvider.notifier).hasFeatureAccess(feature);
    case SubscriptionFeature.maxProjects:
    case SubscriptionFeature.maxCanvasSize:
    case SubscriptionFeature.exportFormats:
      return false; // These features are never fully locked, just limited
    case SubscriptionFeature.effects:
    case SubscriptionFeature.templates:
    case SubscriptionFeature.proTheme:
      return !ref.read(subscriptionStateProvider.notifier).hasFeatureAccess(feature);
  }
}

@riverpod
List<PurchaseOffer> purchaseOffers(PurchaseOffersRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  // Recompute once store products finish loading.
  ref.watch(productsStreamProvider);
  final plan = ref.watch(subscriptionStateProvider).plan;

  final offers = <PurchaseOffer>[
    if (plan == SubscriptionPlan.free) const PurchaseOffer(plan: SubscriptionPlan.free),
  ];

  final proProduct = service.getProductDetails(SubscriptionProductIds.pro);
  if (proProduct != null && plan == SubscriptionPlan.free) {
    offers.add(
      PurchaseOffer(
        plan: SubscriptionPlan.pro,
        productId: proProduct.identifier,
        price: proProduct.priceString,
      ),
    );
  }

  // Pro owners see the discounted upgrade instead of the full price.
  final isUpgrade = plan == SubscriptionPlan.pro;
  final ultimateProduct = service.getProductDetails(
    isUpgrade ? SubscriptionProductIds.ultimateUpgrade : SubscriptionProductIds.ultimate,
  );
  if (ultimateProduct != null && plan != SubscriptionPlan.ultimate) {
    offers.add(
      PurchaseOffer(
        plan: SubscriptionPlan.ultimate,
        productId: ultimateProduct.identifier,
        price: ultimateProduct.priceString,
        isMostPopular: true,
        isUpgrade: isUpgrade,
      ),
    );
  }

  return offers;
}

@riverpod
class TemporaryProStatus extends _$TemporaryProStatus {
  @override
  Duration? build() {
    final subscription = ref.watch(subscriptionStateProvider);
    return subscription.temporaryProAccess?.remainingTime;
  }

  void updateRemainingTime() {
    final subscription = ref.read(subscriptionStateProvider);
    state = subscription.temporaryProAccess?.remainingTime;
  }
}
