// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$promoAppsHash() => r'9d4d03433533ae69a43f9fd093a0a76a0b696d1d';

/// Cross-promo ads for the developer's other apps.
///
/// Copied from [PromoApps].
@ProviderFor(PromoApps)
final promoAppsProvider =
    AutoDisposeAsyncNotifierProvider<PromoApps, List<PromoAppItem>>.internal(
  PromoApps.new,
  name: r'promoAppsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$promoAppsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PromoApps = AutoDisposeAsyncNotifier<List<PromoAppItem>>;
String _$newsItemsHash() => r'c96467a7d2e38dfc7f870fe2d039f77b8ce03b2a';

/// News / announcements for the discovery carousel.
///
/// Copied from [NewsItems].
@ProviderFor(NewsItems)
final newsItemsProvider =
    AutoDisposeAsyncNotifierProvider<NewsItems, List<NewsItemModel>>.internal(
  NewsItems.new,
  name: r'newsItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$newsItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NewsItems = AutoDisposeAsyncNotifier<List<NewsItemModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
