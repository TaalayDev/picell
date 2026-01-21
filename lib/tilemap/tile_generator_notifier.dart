import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data.dart';
import 'generator/tile_base.dart';

/// Drawing tool for tile editor
enum TileDrawTool {
  pencil,
  eraser,
  fill,
  eyedropper,
}

/// Canvas display mode
enum CanvasDisplayMode {
  /// Single tile fills available space
  single,

  /// Tile repeated in a 3x3 tilemap pattern
  tilemap,
}

/// Provider for tile generator state
final tileGeneratorProvider =
    StateNotifierProvider.autoDispose.family<TileGeneratorNotifier, TileGeneratorState, Project>((ref, project) {
  return TileGeneratorNotifier(project);
});

/// State for the tile generator
class TileGeneratorState {
  final int tileWidth;
  final int tileHeight;
  final Uint32List? currentTile;
  final String? selectedTileId;
  final TileCategory? selectedCategory;
  final TileVariation variation;
  final int seed;
  final List<Uint32List> variants;
  final int selectedVariantIndex;
  final Color currentColor;
  final TileDrawTool currentTool;
  final CanvasDisplayMode displayMode;
  final List<Uint32List> undoHistory;
  final int undoIndex;

  // Generation settings
  final double noiseIntensity;
  final int noiseOctaves;
  final double topLeftRadius;
  final double topRightRadius;
  final double bottomLeftRadius;
  final double bottomRightRadius;
  final List<Color> paletteColors;

  const TileGeneratorState({
    required this.tileWidth,
    required this.tileHeight,
    this.currentTile,
    this.selectedTileId,
    this.selectedCategory,
    this.variation = TileVariation.standard,
    this.seed = 0,
    this.variants = const [],
    this.selectedVariantIndex = 0,
    this.currentColor = Colors.black,
    this.currentTool = TileDrawTool.pencil,
    this.displayMode = CanvasDisplayMode.single,
    this.undoHistory = const [],
    this.undoIndex = -1,
    // Generation settings defaults
    this.noiseIntensity = 0.08,
    this.noiseOctaves = 3,
    this.topLeftRadius = 0,
    this.topRightRadius = 0,
    this.bottomLeftRadius = 0,
    this.bottomRightRadius = 0,
    this.paletteColors = const [],
  });

  bool get canUndo => undoIndex > 0;
  bool get canRedo => undoIndex < undoHistory.length - 1;

  TileGeneratorState copyWith({
    int? tileWidth,
    int? tileHeight,
    Uint32List? currentTile,
    String? selectedTileId,
    TileCategory? selectedCategory,
    TileVariation? variation,
    int? seed,
    List<Uint32List>? variants,
    int? selectedVariantIndex,
    Color? currentColor,
    TileDrawTool? currentTool,
    CanvasDisplayMode? displayMode,
    List<Uint32List>? undoHistory,
    int? undoIndex,
    double? noiseIntensity,
    int? noiseOctaves,
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomLeftRadius,
    double? bottomRightRadius,
    List<Color>? paletteColors,
  }) {
    return TileGeneratorState(
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      currentTile: currentTile ?? this.currentTile,
      selectedTileId: selectedTileId ?? this.selectedTileId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      variation: variation ?? this.variation,
      seed: seed ?? this.seed,
      variants: variants ?? this.variants,
      selectedVariantIndex: selectedVariantIndex ?? this.selectedVariantIndex,
      currentColor: currentColor ?? this.currentColor,
      currentTool: currentTool ?? this.currentTool,
      displayMode: displayMode ?? this.displayMode,
      undoHistory: undoHistory ?? this.undoHistory,
      undoIndex: undoIndex ?? this.undoIndex,
      noiseIntensity: noiseIntensity ?? this.noiseIntensity,
      noiseOctaves: noiseOctaves ?? this.noiseOctaves,
      topLeftRadius: topLeftRadius ?? this.topLeftRadius,
      topRightRadius: topRightRadius ?? this.topRightRadius,
      bottomLeftRadius: bottomLeftRadius ?? this.bottomLeftRadius,
      bottomRightRadius: bottomRightRadius ?? this.bottomRightRadius,
      paletteColors: paletteColors ?? this.paletteColors,
    );
  }
}

/// State notifier for tile generation
class TileGeneratorNotifier extends StateNotifier<TileGeneratorState> {
  final Project project;
  final TileRegistry _registry = TileRegistry.instance;

  TileGeneratorNotifier(this.project)
      : super(TileGeneratorState(
          tileWidth: project.tileWidth ?? project.width,
          tileHeight: project.tileHeight ?? project.height,
        ));

  /// Select a tile type to generate
  void selectTileType(String tileId) {
    final tile = _registry.getTile(tileId);
    final paletteColors = tile != null ? tile.palette.colors : <Color>[];

    state = state.copyWith(
      selectedTileId: tileId,
      variants: [],
      selectedVariantIndex: 0,
      paletteColors: paletteColors,
    );
    _generateVariants();
  }

  /// Select a category filter
  void selectCategory(TileCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Change the variation style
  void setVariation(TileVariation variation) {
    state = state.copyWith(variation: variation);
    _generateVariants();
  }

  /// Set noise intensity
  void setNoiseIntensity(double value) {
    state = state.copyWith(noiseIntensity: value);
    _generateVariants();
  }

  /// Set noise octaves
  void setNoiseOctaves(int value) {
    state = state.copyWith(noiseOctaves: value);
    _generateVariants();
  }

  /// Set corner radii
  void setTopLeftRadius(double value) {
    state = state.copyWith(topLeftRadius: value);
    _generateVariants();
  }

  void setTopRightRadius(double value) {
    state = state.copyWith(topRightRadius: value);
    _generateVariants();
  }

  void setBottomLeftRadius(double value) {
    state = state.copyWith(bottomLeftRadius: value);
    _generateVariants();
  }

  void setBottomRightRadius(double value) {
    state = state.copyWith(bottomRightRadius: value);
    _generateVariants();
  }

  /// Set all corners at once
  void setAllCornerRadii(double value) {
    state = state.copyWith(
      topLeftRadius: value,
      topRightRadius: value,
      bottomLeftRadius: value,
      bottomRightRadius: value,
    );
    _generateVariants();
  }

  /// Regenerate with a new seed
  void regenerate() {
    state = state.copyWith(seed: DateTime.now().millisecondsSinceEpoch);
    _generateVariants();
  }

  /// Select a variant
  void selectVariant(int index) {
    if (index >= 0 && index < state.variants.length) {
      final pixels = Uint32List.fromList(state.variants[index]);
      _pushUndoState(pixels);
      state = state.copyWith(
        selectedVariantIndex: index,
        currentTile: pixels,
      );
    }
  }

  /// Set current drawing color
  void setColor(Color color) {
    state = state.copyWith(currentColor: color);
  }

  /// Set current tool
  void setTool(TileDrawTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// Toggle display mode
  void toggleDisplayMode() {
    state = state.copyWith(
      displayMode: state.displayMode == CanvasDisplayMode.single ? CanvasDisplayMode.tilemap : CanvasDisplayMode.single,
    );
  }

  /// Set display mode
  void setDisplayMode(CanvasDisplayMode mode) {
    state = state.copyWith(displayMode: mode);
  }

  /// Draw a pixel
  void drawPixel(int x, int y) {
    if (state.currentTile == null) return;
    if (x < 0 || x >= state.tileWidth || y < 0 || y >= state.tileHeight) return;

    final pixels = Uint32List.fromList(state.currentTile!);
    final index = y * state.tileWidth + x;

    switch (state.currentTool) {
      case TileDrawTool.pencil:
        pixels[index] = state.currentColor.value;
        break;
      case TileDrawTool.eraser:
        pixels[index] = 0x00000000; // Transparent
        break;
      case TileDrawTool.fill:
        _floodFill(pixels, x, y, state.currentColor.value);
        break;
      case TileDrawTool.eyedropper:
        final pickedColor = Color(pixels[index]);
        state = state.copyWith(
          currentColor: pickedColor,
          currentTool: TileDrawTool.pencil,
        );
        return;
    }

    state = state.copyWith(currentTile: pixels);
  }

  /// Start drawing (for undo)
  void startDrawing() {
    if (state.currentTile != null) {
      _pushUndoState(Uint32List.fromList(state.currentTile!));
    }
  }

  /// End drawing
  void endDrawing() {
    // Nothing needed for now
  }

  void _pushUndoState(Uint32List pixels) {
    final newHistory = state.undoHistory.sublist(0, state.undoIndex + 1);
    newHistory.add(Uint32List.fromList(pixels));
    // Limit history to 50 entries
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }
    state = state.copyWith(
      undoHistory: newHistory,
      undoIndex: newHistory.length - 1,
    );
  }

  /// Undo
  void undo() {
    if (!state.canUndo) return;
    final newIndex = state.undoIndex - 1;
    state = state.copyWith(
      undoIndex: newIndex,
      currentTile: Uint32List.fromList(state.undoHistory[newIndex]),
    );
  }

  /// Redo
  void redo() {
    if (!state.canRedo) return;
    final newIndex = state.undoIndex + 1;
    state = state.copyWith(
      undoIndex: newIndex,
      currentTile: Uint32List.fromList(state.undoHistory[newIndex]),
    );
  }

  /// Flood fill algorithm
  void _floodFill(Uint32List pixels, int startX, int startY, int newColor) {
    final targetColor = pixels[startY * state.tileWidth + startX];
    if (targetColor == newColor) return;

    final stack = <(int, int)>[];
    stack.add((startX, startY));

    while (stack.isNotEmpty) {
      final (x, y) = stack.removeLast();
      if (x < 0 || x >= state.tileWidth || y < 0 || y >= state.tileHeight) continue;

      final index = y * state.tileWidth + x;
      if (pixels[index] != targetColor) continue;

      pixels[index] = newColor;

      stack.add((x + 1, y));
      stack.add((x - 1, y));
      stack.add((x, y + 1));
      stack.add((x, y - 1));
    }
  }

  /// Clear the canvas
  void clear() {
    if (state.currentTile == null) return;
    _pushUndoState(Uint32List.fromList(state.currentTile!));
    final pixels = Uint32List(state.tileWidth * state.tileHeight);
    state = state.copyWith(currentTile: pixels);
  }

  /// Create a new blank tile
  void createBlankTile() {
    final pixels = Uint32List(state.tileWidth * state.tileHeight);
    // Fill with transparent
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }
    _pushUndoState(pixels);
    state = state.copyWith(
      currentTile: pixels,
      selectedTileId: null,
      variants: [],
    );
  }

  /// Generate variants for the selected tile type
  void _generateVariants() {
    final tileId = state.selectedTileId;
    if (tileId == null) return;

    final tile = _registry.getTile(tileId);
    if (tile == null) return;

    final variants = tile.generateVariants(
      width: state.tileWidth,
      height: state.tileHeight,
      count: 6,
      baseSeed: state.seed,
    );

    // Apply noise and corner radii to all variants
    final processedVariants = variants.map((pixels) {
      var processed = Uint32List.fromList(pixels);
      processed = _applyNoiseProcessing(processed);
      processed = _applyCornerRadii(processed);
      return processed;
    }).toList();

    if (processedVariants.isNotEmpty) {
      _pushUndoState(Uint32List.fromList(processedVariants[0]));
    }

    state = state.copyWith(
      variants: processedVariants,
      selectedVariantIndex: 0,
      currentTile: processedVariants.isNotEmpty ? Uint32List.fromList(processedVariants[0]) : null,
    );
  }

  /// Apply noise processing based on settings
  Uint32List _applyNoiseProcessing(Uint32List pixels) {
    final w = state.tileWidth;
    final h = state.tileHeight;
    final result = Uint32List.fromList(pixels);
    final random = Random(state.seed);
    final intensity = state.noiseIntensity;
    final octaves = state.noiseOctaves;

    // Skip if no additional noise needed (default is 0.08)
    if (intensity <= 0.08 && octaves <= 3) return result;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final index = y * w + x;
        final pixel = result[index];

        // Skip transparent pixels
        if ((pixel >> 24) == 0) continue;

        // Extract ARGB
        final a = (pixel >> 24) & 0xFF;
        final r = (pixel >> 16) & 0xFF;
        final g = (pixel >> 8) & 0xFF;
        final b = pixel & 0xFF;

        // Generate noise based on octaves
        double noiseValue = 0;
        double amplitude = 1;
        double frequency = 1;
        double maxValue = 0;

        for (int i = 0; i < octaves; i++) {
          noiseValue += amplitude * _smoothNoise(x * frequency / 4.0, y * frequency / 4.0, random);
          maxValue += amplitude;
          amplitude *= 0.5;
          frequency *= 2;
        }
        noiseValue = noiseValue / maxValue;

        // Apply noise variation
        final variation = ((noiseValue - 0.5) * 2 * intensity * 255).round();
        final nr = (r + variation).clamp(0, 255);
        final ng = (g + variation).clamp(0, 255);
        final nb = (b + variation).clamp(0, 255);

        result[index] = (a << 24) | (nr << 16) | (ng << 8) | nb;
      }
    }

    return result;
  }

  /// Simple smooth noise function
  double _smoothNoise(double x, double y, Random random) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    double hash(int x, int y) {
      final n = x + y * 57;
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      return h / 0x7fffffff;
    }

    final v1 = hash(ix, iy);
    final v2 = hash(ix + 1, iy);
    final v3 = hash(ix, iy + 1);
    final v4 = hash(ix + 1, iy + 1);

    final i1 = v1 + fx * (v2 - v1);
    final i2 = v3 + fx * (v4 - v3);

    return i1 + fy * (i2 - i1);
  }

  /// Apply corner radii to the tile pixels
  Uint32List _applyCornerRadii(Uint32List pixels) {
    final w = state.tileWidth;
    final h = state.tileHeight;
    final result = Uint32List.fromList(pixels);

    // Apply top-left radius
    if (state.topLeftRadius > 0) {
      final r = state.topLeftRadius.round();
      for (int y = 0; y < r; y++) {
        for (int x = 0; x < r; x++) {
          final dx = r - x - 1;
          final dy = r - y - 1;
          if (dx * dx + dy * dy > r * r) {
            result[y * w + x] = 0x00000000; // Transparent
          }
        }
      }
    }

    // Apply top-right radius
    if (state.topRightRadius > 0) {
      final r = state.topRightRadius.round();
      for (int y = 0; y < r; y++) {
        for (int x = w - r; x < w; x++) {
          final dx = x - (w - r);
          final dy = r - y - 1;
          if (dx * dx + dy * dy > r * r) {
            result[y * w + x] = 0x00000000;
          }
        }
      }
    }

    // Apply bottom-left radius
    if (state.bottomLeftRadius > 0) {
      final r = state.bottomLeftRadius.round();
      for (int y = h - r; y < h; y++) {
        for (int x = 0; x < r; x++) {
          final dx = r - x - 1;
          final dy = y - (h - r);
          if (dx * dx + dy * dy > r * r) {
            result[y * w + x] = 0x00000000;
          }
        }
      }
    }

    // Apply bottom-right radius
    if (state.bottomRightRadius > 0) {
      final r = state.bottomRightRadius.round();
      for (int y = h - r; y < h; y++) {
        for (int x = w - r; x < w; x++) {
          final dx = x - (w - r);
          final dy = y - (h - r);
          if (dx * dx + dy * dy > r * r) {
            result[y * w + x] = 0x00000000;
          }
        }
      }
    }

    return result;
  }

  /// Get all available tile types
  List<TileBase> getAvailableTiles() {
    if (state.selectedCategory != null) {
      return _registry.getTilesInCategory(state.selectedCategory!);
    }
    return _registry.allIds.map((id) => _registry.getTile(id)!).toList();
  }

  /// Get tiles grouped by category
  Map<TileCategory, List<TileBase>> get tilesByCategory {
    return _registry.tilesByCategory;
  }

  /// Get the current generated tile pixels
  Uint32List? get currentTilePixels => state.currentTile;
}
