// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionStreamHash() =>
    r'63536bb32d56d3a51ff7aaad33815d609ace7e8d';

/// See also [subscriptionStream].
@ProviderFor(subscriptionStream)
final subscriptionStreamProvider =
    AutoDisposeStreamProvider<UserSubscription>.internal(
  subscriptionStream,
  name: r'subscriptionStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionStreamRef = AutoDisposeStreamProviderRef<UserSubscription>;
String _$productsStreamHash() => r'59fefd0bb131aeb26260ae0aa0b0c762d04969d8';

/// See also [productsStream].
@ProviderFor(productsStream)
final productsStreamProvider =
    AutoDisposeStreamProvider<List<ProductDetails>>.internal(
  productsStream,
  name: r'productsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProductsStreamRef = AutoDisposeStreamProviderRef<List<ProductDetails>>;
String _$purchaseUpdatesStreamHash() =>
    r'63a79d171e85458592c847aa2cb0ea46164f2d34';

/// See also [purchaseUpdatesStream].
@ProviderFor(purchaseUpdatesStream)
final purchaseUpdatesStreamProvider =
    AutoDisposeStreamProvider<List<PurchaseDetails>>.internal(
  purchaseUpdatesStream,
  name: r'purchaseUpdatesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$purchaseUpdatesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PurchaseUpdatesStreamRef
    = AutoDisposeStreamProviderRef<List<PurchaseDetails>>;
String _$subscriptionErrorsStreamHash() =>
    r'b7a0d1d1915dd5f96aa3a778bcd86e89e9500ae4';

/// See also [subscriptionErrorsStream].
@ProviderFor(subscriptionErrorsStream)
final subscriptionErrorsStreamProvider =
    AutoDisposeStreamProvider<String>.internal(
  subscriptionErrorsStream,
  name: r'subscriptionErrorsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionErrorsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionErrorsStreamRef = AutoDisposeStreamProviderRef<String>;
String _$isFeatureLockedHash() => r'e564ad97beed2e5b08f6b68254629494c2cc6f1f';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [isFeatureLocked].
@ProviderFor(isFeatureLocked)
const isFeatureLockedProvider = IsFeatureLockedFamily();

/// See also [isFeatureLocked].
class IsFeatureLockedFamily extends Family<bool> {
  /// See also [isFeatureLocked].
  const IsFeatureLockedFamily();

  /// See also [isFeatureLocked].
  IsFeatureLockedProvider call(
    SubscriptionFeature feature,
  ) {
    return IsFeatureLockedProvider(
      feature,
    );
  }

  @override
  IsFeatureLockedProvider getProviderOverride(
    covariant IsFeatureLockedProvider provider,
  ) {
    return call(
      provider.feature,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isFeatureLockedProvider';
}

/// See also [isFeatureLocked].
class IsFeatureLockedProvider extends AutoDisposeProvider<bool> {
  /// See also [isFeatureLocked].
  IsFeatureLockedProvider(
    SubscriptionFeature feature,
  ) : this._internal(
          (ref) => isFeatureLocked(
            ref as IsFeatureLockedRef,
            feature,
          ),
          from: isFeatureLockedProvider,
          name: r'isFeatureLockedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isFeatureLockedHash,
          dependencies: IsFeatureLockedFamily._dependencies,
          allTransitiveDependencies:
              IsFeatureLockedFamily._allTransitiveDependencies,
          feature: feature,
        );

  IsFeatureLockedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.feature,
  }) : super.internal();

  final SubscriptionFeature feature;

  @override
  Override overrideWith(
    bool Function(IsFeatureLockedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsFeatureLockedProvider._internal(
        (ref) => create(ref as IsFeatureLockedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        feature: feature,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsFeatureLockedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFeatureLockedProvider && other.feature == feature;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, feature.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IsFeatureLockedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `feature` of this provider.
  SubscriptionFeature get feature;
}

class _IsFeatureLockedProviderElement extends AutoDisposeProviderElement<bool>
    with IsFeatureLockedRef {
  _IsFeatureLockedProviderElement(super.provider);

  @override
  SubscriptionFeature get feature =>
      (origin as IsFeatureLockedProvider).feature;
}

String _$purchaseOffersHash() => r'7b55b6c872c0116fc1200748b71f4f3894cc0019';

/// See also [purchaseOffers].
@ProviderFor(purchaseOffers)
final purchaseOffersProvider =
    AutoDisposeProvider<List<PurchaseOffer>>.internal(
  purchaseOffers,
  name: r'purchaseOffersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$purchaseOffersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PurchaseOffersRef = AutoDisposeProviderRef<List<PurchaseOffer>>;
String _$subscriptionStateHash() => r'2a2a7b6a36379c21dd45e3354af10be66e53748b';

/// See also [SubscriptionState].
@ProviderFor(SubscriptionState)
final subscriptionStateProvider =
    AutoDisposeNotifierProvider<SubscriptionState, UserSubscription>.internal(
  SubscriptionState.new,
  name: r'subscriptionStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionState = AutoDisposeNotifier<UserSubscription>;
String _$temporaryProStatusHash() =>
    r'85eea183671278e47aa34bb5c41e7748a7773a8b';

/// See also [TemporaryProStatus].
@ProviderFor(TemporaryProStatus)
final temporaryProStatusProvider =
    AutoDisposeNotifierProvider<TemporaryProStatus, Duration?>.internal(
  TemporaryProStatus.new,
  name: r'temporaryProStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$temporaryProStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TemporaryProStatus = AutoDisposeNotifier<Duration?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
