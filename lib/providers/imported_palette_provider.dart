import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'imported_palette_provider.g.dart';

/// Holds the color palette extracted from the most recently imported image.
///
/// Updated by [PixelControllerNotifier] after each import (both layer and
/// background). Consumed by [ColorPalettePanel] to display an "Imported" tab.
@riverpod
class ImportedPalette extends _$ImportedPalette {
  @override
  List<Color> build() => const [];

  void set(List<Color> colors) => state = List.unmodifiable(colors);

  void clear() => state = const [];
}
