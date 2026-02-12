import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picell/config/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/subscription_model.dart';
import '../core/services/subscription_service.dart';

part 'subscription_provider.g.dart';

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
      return const UserSubscription(
        plan: SubscriptionPlan.free,
        status: AppPurchaseStatus.notPurchased,
        purchaseId: '',
      );
    }

    const testing = bool.fromEnvironment('TESTING');

    if (kIsWeb || Platform.isAndroid || Platform.isWindows || testing) {
      return UserSubscription(
        plan: SubscriptionPlan.proPurchase,
        status: AppPurchaseStatus.purchased,
        purchaseId: '123456',
        purchaseDate: DateTime.now(),
      );
    }

    final service = ref.watch(subscriptionServiceProvider);

    if (!service.isInitialized) {
      service.initialize();
    }

    ref.listenSelf((previous, next) {
      if (previous?.plan != next.plan || previous?.status != next.status) {}
    });

    ref.listen(subscriptionStreamProvider, (previous, next) {
      if (next.valueOrNull != null) {
        state = next.value!;
      }
    });

    return service.currentSubscription;
  }

  Future<void> purchasePro() async {
    final service = ref.read(subscriptionServiceProvider);

    try {
      final productDetails = service.getProProductDetails();
      if (productDetails != null) {
        await service.purchasePro(productDetails);
      } else {
        throw Exception('Pro purchase not available');
      }
    } catch (e, s) {
      print('Error purchasing pro: $e');
      print(s);
      rethrow;
    }
  }

  void grantTemporaryProAccess({Duration duration = const Duration(minutes: 45)}) {
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
Stream<List<ProductDetails>> productsStream(ProductsStreamRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.productsStream;
}

@riverpod
Stream<List<PurchaseDetails>> purchaseUpdatesStream(PurchaseUpdatesStreamRef ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.purchaseUpdatedStream;
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
  final products = service.products;

  final List<PurchaseOffer> offers = [
    const PurchaseOffer(
      plan: SubscriptionPlan.free,
      title: 'Free',
      description: 'Basic pixel art creation',
      price: 'Free',
      features: [
        '10 projects',
        'Basic tools',
        'Canvas up to 64x64 pixels',
        'PNG & JPEG export',
        'Watch ads for temporary Pro access',
      ],
    ),
  ];

  final proProduct = products.firstWhereOrNull((product) => product.id == SubscriptionProductIds.proPurchase);

  if (proProduct != null) {
    offers.add(
      PurchaseOffer(
        plan: SubscriptionPlan.proPurchase,
        title: 'Pro (One-time Purchase)',
        description: 'Unlock everything forever',
        price: proProduct.price,
        isMostPopular: true,
        features: const [
          'Unlimited projects',
          'Advanced tools & effects & templates',
          'Canvas up to 1024x1024 pixels',
          'Export to all formats including video',
          'Cloud backup',
          'Priority support',
          'No ads',
          'No watermarks',
        ],
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
