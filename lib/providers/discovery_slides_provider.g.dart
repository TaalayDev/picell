// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_slides_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$discoverySlidesHash() => r'd15b0480b76409187fbe498847e51b14d6b6b658';

/// Combines cross-promo apps, featured projects, news, and trending community
/// projects into one ordered slide list for [DiscoveryCarousel]. Each source
/// is fetched independently and tolerates its own failure — a broken/empty
/// source just contributes no slides rather than blanking the whole carousel.
///
/// Copied from [discoverySlides].
@ProviderFor(discoverySlides)
final discoverySlidesProvider =
    AutoDisposeFutureProvider<List<DiscoverySlide>>.internal(
  discoverySlides,
  name: r'discoverySlidesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$discoverySlidesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DiscoverySlidesRef = AutoDisposeFutureProviderRef<List<DiscoverySlide>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
