// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pixel_canvas_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pixelCanvasNotifierHash() =>
    r'e0f5dd8076e92a905b169bcaa56b0e2274d67d3c';

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

abstract class _$PixelCanvasNotifier
    extends BuildlessAutoDisposeNotifier<PixelCanvasState> {
  late final Project project;

  PixelCanvasState build(
    Project project,
  );
}

/// See also [PixelCanvasNotifier].
@ProviderFor(PixelCanvasNotifier)
const pixelCanvasNotifierProvider = PixelCanvasNotifierFamily();

/// See also [PixelCanvasNotifier].
class PixelCanvasNotifierFamily extends Family<PixelCanvasState> {
  /// See also [PixelCanvasNotifier].
  const PixelCanvasNotifierFamily();

  /// See also [PixelCanvasNotifier].
  PixelCanvasNotifierProvider call(
    Project project,
  ) {
    return PixelCanvasNotifierProvider(
      project,
    );
  }

  @override
  PixelCanvasNotifierProvider getProviderOverride(
    covariant PixelCanvasNotifierProvider provider,
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
  String? get name => r'pixelCanvasNotifierProvider';
}

/// See also [PixelCanvasNotifier].
class PixelCanvasNotifierProvider extends AutoDisposeNotifierProviderImpl<
    PixelCanvasNotifier, PixelCanvasState> {
  /// See also [PixelCanvasNotifier].
  PixelCanvasNotifierProvider(
    Project project,
  ) : this._internal(
          () => PixelCanvasNotifier()..project = project,
          from: pixelCanvasNotifierProvider,
          name: r'pixelCanvasNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pixelCanvasNotifierHash,
          dependencies: PixelCanvasNotifierFamily._dependencies,
          allTransitiveDependencies:
              PixelCanvasNotifierFamily._allTransitiveDependencies,
          project: project,
        );

  PixelCanvasNotifierProvider._internal(
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
    covariant PixelCanvasNotifier notifier,
  ) {
    return notifier.build(
      project,
    );
  }

  @override
  Override overrideWith(PixelCanvasNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PixelCanvasNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<PixelCanvasNotifier, PixelCanvasState>
      createElement() {
    return _PixelCanvasNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PixelCanvasNotifierProvider && other.project == project;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, project.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PixelCanvasNotifierRef
    on AutoDisposeNotifierProviderRef<PixelCanvasState> {
  /// The parameter `project` of this provider.
  Project get project;
}

class _PixelCanvasNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<PixelCanvasNotifier,
        PixelCanvasState> with PixelCanvasNotifierRef {
  _PixelCanvasNotifierProviderElement(super.provider);

  @override
  Project get project => (origin as PixelCanvasNotifierProvider).project;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
