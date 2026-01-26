import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data.dart';
import '../pixel/effects/effects.dart';
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

  // Layer system
  final List<Layer> layers;
  final String? activeLayerId;

  /// Composed output of all visible layers
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

  // Undo/Redo now needs to track full layer state
  final List<List<Layer>> undoHistory;
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
    this.layers = const [],
    this.activeLayerId,
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

  Layer? get activeLayer {
    if (activeLayerId == null || layers.isEmpty) return null;
    return layers.firstWhere(
      (l) => l.id == activeLayerId,
      orElse: () => layers.last,
    );
  }

  TileGeneratorState copyWith({
    int? tileWidth,
    int? tileHeight,
    List<Layer>? layers,
    String? activeLayerId,
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
    List<List<Layer>>? undoHistory,
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
      layers: layers ?? this.layers,
      activeLayerId: activeLayerId ?? this.activeLayerId,
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
  final _uuid = const Uuid();

  TileGeneratorNotifier(this.project)
      : super(TileGeneratorState(
          tileWidth: project.tileWidth ?? project.width,
          tileHeight: project.tileHeight ?? project.height,
        )) {
    _initializeDefaultLayer();
  }

  void _initializeDefaultLayer() {
    final layerId = _uuid.v4();
    final layer = Layer(
      layerId: DateTime.now().millisecondsSinceEpoch,
      id: layerId,
      name: 'Layer 1',
      pixels: Uint32List(state.tileWidth * state.tileHeight),
      isVisible: true,
      order: 0,
    );

    state = state.copyWith(
      layers: [layer],
      activeLayerId: layerId,
      currentTile: layer.pixels,
    );
    _pushUndoState();
  }

  // --- Layer Management ---

  /// Add a new empty layer
  void addLayer([String? name]) {
    final layerId = _uuid.v4();
    final layer = Layer(
      layerId: DateTime.now().millisecondsSinceEpoch,
      id: layerId,
      name: name ?? 'Layer ${state.layers.length + 1}',
      pixels: Uint32List(state.tileWidth * state.tileHeight),
      isVisible: true,
      order: state.layers.length,
    );

    final newLayers = [...state.layers, layer];
    state = state.copyWith(
      layers: newLayers,
      activeLayerId: layerId,
    );
    _composeLayers();
    _pushUndoState();
  }

  /// Remove a layer
  void removeLayer(String layerId) {
    if (state.layers.length <= 1) return; // Prevent deleting last layer

    final newLayers = state.layers.where((l) => l.id != layerId).toList();

    // If active layer removed, select the last one
    String? newActiveId = state.activeLayerId;
    if (state.activeLayerId == layerId) {
      newActiveId = newLayers.isNotEmpty ? newLayers.last.id : null;
    }

    state = state.copyWith(
      layers: newLayers,
      activeLayerId: newActiveId,
    );
    _composeLayers();
    _pushUndoState();
  }

  /// Select active layer
  void setActiveLayer(String layerId) {
    if (state.layers.any((l) => l.id == layerId)) {
      state = state.copyWith(activeLayerId: layerId);
    }
  }

  /// Toggle layer visibility
  void toggleLayerVisibility(String layerId) {
    final newLayers = state.layers.map((layer) {
      if (layer.id == layerId) {
        return layer.copyWith(isVisible: !layer.isVisible);
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
    _composeLayers();
    _pushUndoState();
  }

  /// Toggle layer lock
  void toggleLayerLock(String layerId) {
    final newLayers = state.layers.map((layer) {
      if (layer.id == layerId) {
        return layer.copyWith(isLocked: !layer.isLocked);
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
  }

  /// Update layer properties (opacity, blend mode etc)
  void updateLayer(String layerId, {double? opacity, String? name}) {
    final newLayers = state.layers.map((layer) {
      if (layer.id == layerId) {
        return layer.copyWith(
          opacity: opacity,
          name: name,
        );
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
    _composeLayers();
    _pushUndoState();
  }

  /// Reorder layers
  void reorderLayers(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final layers = List<Layer>.from(state.layers);
    final item = layers.removeAt(oldIndex);
    layers.insert(newIndex, item);

    // Update order property if needed, though list order defines drawing order usually
    // (Last painted on top)

    state = state.copyWith(layers: layers);
    _composeLayers();
    _pushUndoState();
  }

  // --- Effect Management ---

  /// Add effect to active layer
  void addEffect(EffectType type) {
    final activeId = state.activeLayerId;
    if (activeId == null) return;

    // Create default effect with some reasonable params if needed
    final effect = EffectsManager.createEffect(type);

    final newLayers = state.layers.map((layer) {
      if (layer.id == activeId) {
        return layer.copyWith(
          effects: [...layer.effects, effect],
        );
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
    _composeLayers();
    _pushUndoState();
  }

  /// Update an effect on active layer
  void updateEffect(int index, Effect updatedEffect) {
    final activeId = state.activeLayerId;
    if (activeId == null) return;

    final newLayers = state.layers.map((layer) {
      if (layer.id == activeId) {
        if (index < 0 || index >= layer.effects.length) return layer;

        final newEffects = List<Effect>.from(layer.effects);
        newEffects[index] = updatedEffect;

        return layer.copyWith(effects: newEffects);
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
    _composeLayers();
    _pushUndoState(); // Could debounce this if sliders are used
  }

  /// Remove effect from active layer
  void removeEffect(int index) {
    final activeId = state.activeLayerId;
    if (activeId == null) return;

    final newLayers = state.layers.map((layer) {
      if (layer.id == activeId) {
        if (index < 0 || index >= layer.effects.length) return layer;

        final newEffects = List<Effect>.from(layer.effects);
        newEffects.removeAt(index);

        return layer.copyWith(effects: newEffects);
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
    _composeLayers();
    _pushUndoState();
  }

  // --- Core Generation & Drawing ---

  /// Compose all layers into final image
  void _composeLayers() {
    // 0x00000000 is transparent
    final width = state.tileWidth;
    final height = state.tileHeight;
    final composed = Uint32List(width * height);

    // Fill with transparent first just in case
    for (int i = 0; i < composed.length; i++) composed[i] = 0x00000000;

    // Draw layers from bottom (index 0) to top
    for (final layer in state.layers) {
      if (!layer.isVisible) continue;

      final layerPixels = layer.processedPixels; // Applies effects

      for (int i = 0; i < composed.length; i++) {
        final src = layerPixels[i];
        if ((src >> 24) == 0) continue; // Skip transparent source pixels

        // Simple alpha blending
        // If layer opacity < 1.0, multiply alpha
        int a = (src >> 24) & 0xFF;
        int r = (src >> 16) & 0xFF;
        int g = (src >> 8) & 0xFF;
        int b = src & 0xFF;

        if (layer.opacity < 1.0) {
          a = (a * layer.opacity).round();
        }

        if (a == 0) continue;

        final dst = composed[i];
        final da = (dst >> 24) & 0xFF;

        if (da == 0) {
          // Direct copy if dest is empty
          composed[i] = (a << 24) | (r << 16) | (g << 8) | b;
        } else {
          // Normal blending
          final alpha = a / 255.0;
          final invAlpha = 1.0 - alpha;

          final dr = (dst >> 16) & 0xFF;
          final dg = (dst >> 8) & 0xFF;
          final db = dst & 0xFF; // FIXED: db was incorrectly defined

          final outR = (r * alpha + dr * invAlpha).round();
          final outG = (g * alpha + dg * invAlpha).round();
          final outB = (b * alpha + db * invAlpha).round();
          final outA = (a + da * invAlpha).round().clamp(0, 255);

          composed[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    state = state.copyWith(currentTile: composed);
  }

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

      // When selecting a variant, we update the ACTIVE layer
      // If no active layer, create one

      String activeId = state.activeLayerId ?? _uuid.v4();
      List<Layer> newLayers;

      if (state.layers.isEmpty) {
        newLayers = [
          Layer(
            layerId: DateTime.now().millisecondsSinceEpoch,
            id: activeId,
            name: 'Generated',
            pixels: pixels,
            isVisible: true,
          )
        ];
      } else {
        newLayers = state.layers.map((layer) {
          if (layer.id == activeId) {
            return layer.copyWith(pixels: pixels);
          }
          return layer;
        }).toList();
      }

      state = state.copyWith(
        selectedVariantIndex: index,
        layers: newLayers,
        activeLayerId: activeId,
      );
      _composeLayers();
      _pushUndoState();
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

  /// Draw a pixel to the ACTIVE layer
  void drawPixel(int x, int y) {
    final activeId = state.activeLayerId;
    if (activeId == null) return;

    // Find active layer
    final activeLayerIndex = state.layers.indexWhere((l) => l.id == activeId);
    if (activeLayerIndex == -1) return;

    final activeLayer = state.layers[activeLayerIndex];
    if (activeLayer.isLocked || !activeLayer.isVisible) return; // Don't draw on locked/hidden layers

    if (x < 0 || x >= state.tileWidth || y < 0 || y >= state.tileHeight) return;

    final pixels = Uint32List.fromList(activeLayer.pixels); // Copy pixels
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
        // Pick from COMPOSITE image, not just layer
        if (state.currentTile != null) {
          final compositePixel = state.currentTile![index];
          if (compositePixel != 0) {
            final pickedColor = Color(compositePixel);
            state = state.copyWith(
              currentColor: pickedColor,
              currentTool: TileDrawTool.pencil,
            );
            return;
          }
        }
        // Fallback to active layer if composite is empty (unlikely) or transparent
        final pickedColor = Color(pixels[index]);
        state = state.copyWith(
          currentColor: pickedColor,
          currentTool: TileDrawTool.pencil,
        );
        return;
    }

    // Update the specific layer
    final newLayers = List<Layer>.from(state.layers);
    newLayers[activeLayerIndex] = activeLayer.copyWith(pixels: pixels);

    state = state.copyWith(layers: newLayers);

    // Efficiently re-compose only if necessary?
    // For now, full compose is fine for 32x32 tiles.
    _composeLayers();
  }

  /// Start drawing (for undo)
  void startDrawing() {
    _pushUndoState();
  }

  /// End drawing
  void endDrawing() {
    // Nothing needed for now
  }

  void _pushUndoState() {
    // Limit history to 50 entries
    final currentLayersSnapshot = state.layers
        .map((l) => l.copyWith(
              pixels: Uint32List.fromList(l.pixels), // Deep copy pixels
              effects: List<Effect>.from(l.effects), // Deep copy list (effects are immutable mostly)
            ))
        .toList();

    final newHistory = state.undoHistory.sublist(0, state.undoIndex + 1);
    newHistory.add(currentLayersSnapshot);

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
    final historicLayers = state.undoHistory[newIndex];

    // Restore layers
    // We need to match active layer ID if it still exists, else pick one
    final restoredLayers = historicLayers
        .map((l) => l.copyWith(
              pixels: Uint32List.fromList(l.pixels),
              effects: List<Effect>.from(l.effects),
            ))
        .toList();

    state = state.copyWith(
      undoIndex: newIndex,
      layers: restoredLayers,
    );

    // Ensure active ID is valid
    if (!state.layers.any((l) => l.id == state.activeLayerId)) {
      state = state.copyWith(activeLayerId: state.layers.isNotEmpty ? state.layers.last.id : null);
    }

    _composeLayers();
  }

  /// Redo
  void redo() {
    if (!state.canRedo) return;
    final newIndex = state.undoIndex + 1;
    final historicLayers = state.undoHistory[newIndex];

    final restoredLayers = historicLayers
        .map((l) => l.copyWith(
              pixels: Uint32List.fromList(l.pixels),
              effects: List<Effect>.from(l.effects),
            ))
        .toList();

    state = state.copyWith(
      undoIndex: newIndex,
      layers: restoredLayers,
    );

    // Ensure active ID is valid
    if (!state.layers.any((l) => l.id == state.activeLayerId)) {
      state = state.copyWith(activeLayerId: state.layers.isNotEmpty ? state.layers.last.id : null);
    }

    _composeLayers();
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

  /// Clear the active layer
  void clear() {
    final activeId = state.activeLayerId;
    if (activeId == null) return;

    final pixels = Uint32List(state.tileWidth * state.tileHeight);
    // Fill with transparent
    for (int i = 0; i < pixels.length; i++) pixels[i] = 0x00000000;

    final newLayers = state.layers.map((layer) {
      if (layer.id == activeId) {
        return layer.copyWith(pixels: pixels);
      }
      return layer;
    }).toList();

    state = state.copyWith(layers: newLayers);
    _composeLayers();
    _pushUndoState();
  }

  /// Create a new blank tile - Resets Everything
  void createBlankTile() {
    final layerId = _uuid.v4();
    final pixels = Uint32List(state.tileWidth * state.tileHeight);

    final layer = Layer(
      layerId: DateTime.now().millisecondsSinceEpoch,
      id: layerId,
      name: 'Layer 1',
      pixels: pixels,
      isVisible: true,
    );

    // Clear history effectively
    final initialLayers = [layer];
    state = state.copyWith(
      layers: initialLayers,
      activeLayerId: layerId,
      selectedTileId: null,
      variants: [],
      undoHistory: [],
      undoIndex: -1,
    );

    _composeLayers();
    _pushUndoState();
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

    state = state.copyWith(
      variants: processedVariants,
      selectedVariantIndex: 0,
    );

    // If not layers exist, or we just want to apply the first variant as preview immediately:
    if (processedVariants.isNotEmpty && state.selectedTileId != null) {
      selectVariant(0);
    }
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
