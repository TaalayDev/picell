// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pixel_controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pixelDrawControllerHash() =>
    r'73a11b5768aea6b58fa83918d4271c934bc57b98';

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

abstract class _$PixelDrawController
    extends BuildlessAutoDisposeNotifier<PixelCanvasState> {
  late final Project project;

  PixelCanvasState build(
    Project project,
  );
}

/// See also [PixelDrawController].
@ProviderFor(PixelDrawController)
const pixelDrawControllerProvider = PixelDrawControllerFamily();

/// See also [PixelDrawController].
class PixelDrawControllerFamily extends Family<PixelCanvasState> {
  /// See also [PixelDrawController].
  const PixelDrawControllerFamily();

  /// See also [PixelDrawController].
  PixelDrawControllerProvider call(
    Project project,
  ) {
    return PixelDrawControllerProvider(
      project,
    );
  }

  @override
  PixelDrawControllerProvider getProviderOverride(
    covariant PixelDrawControllerProvider provider,
  ) {
    return call(
      provider.project,
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
  String? get name => r'pixelDrawControllerProvider';
}

/// See also [PixelDrawController].
class PixelDrawControllerProvider extends AutoDisposeNotifierProviderImpl<
    PixelDrawController, PixelCanvasState> {
  /// See also [PixelDrawController].
  PixelDrawControllerProvider(
    Project project,
  ) : this._internal(
          () => PixelDrawController()..project = project,
          from: pixelDrawControllerProvider,
          name: r'pixelDrawControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pixelDrawControllerHash,
          dependencies: PixelDrawControllerFamily._dependencies,
          allTransitiveDependencies:
              PixelDrawControllerFamily._allTransitiveDependencies,
          project: project,
        );

  PixelDrawControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.project,
  }) : super.internal();

  final Project project;

  @override
  PixelCanvasState runNotifierBuild(
    covariant PixelDrawController notifier,
  ) {
    return notifier.build(
      project,
    );
  }

  @override
  Override overrideWith(PixelDrawController Function() create) {
    return ProviderOverride(
      origin: this,
      override: PixelDrawControllerProvider._internal(
        () => create()..project = project,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        project: project,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<PixelDrawController, PixelCanvasState>
      createElement() {
    return _PixelDrawControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PixelDrawControllerProvider && other.project == project;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, project.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PixelDrawControllerRef
    on AutoDisposeNotifierProviderRef<PixelCanvasState> {
  /// The parameter `project` of this provider.
  Project get project;
}

class _PixelDrawControllerProviderElement
    extends AutoDisposeNotifierProviderElement<PixelDrawController,
        PixelCanvasState> with PixelDrawControllerRef {
  _PixelDrawControllerProviderElement(super.provider);

  @override
  Project get project => (origin as PixelDrawControllerProvider).project;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
