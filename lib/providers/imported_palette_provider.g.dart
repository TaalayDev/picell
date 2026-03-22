// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_palette_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$importedPaletteHash() => r'6f9b06bbeb7f154e3b7c3da5fd30f2ede9c97e07';

/// Holds the color palette extracted from the most recently imported image.
///
/// Updated by [PixelControllerNotifier] after each import (both layer and
/// background). Consumed by [ColorPalettePanel] to display an "Imported" tab.
///
/// Copied from [ImportedPalette].
@ProviderFor(ImportedPalette)
final importedPaletteProvider =
    AutoDisposeNotifierProvider<ImportedPalette, List<Color>>.internal(
  ImportedPalette.new,
  name: r'importedPaletteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$importedPaletteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ImportedPalette = AutoDisposeNotifier<List<Color>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
