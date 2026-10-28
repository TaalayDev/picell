import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../../../core/property_spec.dart';
import '../tile_base.dart';
import '../tile_palette.dart';

const Map<String, String> _wallStyleOptions = {
  'brick': 'Brick',
  'stone': 'Stone',
  'darkBrick': 'Dark Brick',
  'cobblestone': 'Cobblestone',
};

String _wallStyleKey(WallStyle style) {
  return switch (style) {
    WallStyle.brick => 'brick',
    WallStyle.stone => 'stone',
    WallStyle.darkBrick => 'darkBrick',
    WallStyle.cobblestone => 'cobblestone',
  };
}

WallStyle _wallStyleFromKey(String key) {
  return switch (key) {
    'stone' => WallStyle.stone,
    'darkBrick' => WallStyle.darkBrick,
    'cobblestone' => WallStyle.cobblestone,
    _ => WallStyle.brick,
  };
}

const Map<String, String> _floorStyleOptions = {
  'wood': 'Wood',
  'stone': 'Stone',
  'tile': 'Tile',
};

String _floorStyleKey(FloorStyle style) {
  return switch (style) {
    FloorStyle.wood => 'wood',
    FloorStyle.stone => 'stone',
    FloorStyle.tile => 'tile',
  };
}

FloorStyle _floorStyleFromKey(String key) {
  return switch (key) {
    'stone' => FloorStyle.stone,
    'tile' => FloorStyle.tile,
    _ => FloorStyle.wood,
  };
}

// ============================================================================
// STRUCTURE TILES
// ============================================================================

/// Base class for structure-type tiles
abstract class StructureTile extends TileBase {
  StructureTile(super.id);

  @override
  TileCategory get category => TileCategory.structure;

  @override
  bool get supportsRotation => true;

  @override
  bool get supportsAutoTiling => true;
}

/// Wall tile with brick/stone patterns
class WallTile extends StructureTile {
  @override
  String get name => 'Wall';

  @override
  String get description => 'Solid wall with brick pattern';

  @override
  String get iconName => 'grid_view';

  @override
  TilePalette get palette => TilePalettes.brick;

  @override
  List<String> get tags => ['structure', 'wall', 'building', 'brick'];

  final WallStyle style;
  final int brickWidth;
  final int brickHeight;
  final bool staggered;

  WallTile(
    super.id, {
    this.style = WallStyle.brick,
    this.brickWidth = 8,
    this.brickHeight = 4,
    this.staggered = true,
  });

  @override
  List<PropertySpec> getPropertySpecs() => [
    SelectSpec<String>(
      key: 'style',
      label: 'Style',
      initialValue: _wallStyleKey(style),
      options: _wallStyleOptions,
    ),
    SliderSpec(
      key: 'brickWidth',
      label: 'Brick Width',
      min: 2,
      max: 16,
      divisions: 14,
      isInteger: true,
      initialValue: brickWidth,
    ),
    SliderSpec(
      key: 'brickHeight',
      label: 'Brick Height',
      min: 2,
      max: 8,
      divisions: 6,
      isInteger: true,
      initialValue: brickHeight,
    ),
    BoolSpec(
      key: 'staggered',
      label: 'Staggered Rows',
      initialValue: staggered,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    final styleKey = properties['style'] as String? ?? _wallStyleKey(style);
    return WallTile(
      id,
      style: _wallStyleFromKey(styleKey),
      brickWidth: (properties['brickWidth'] as num?)?.round() ?? brickWidth,
      brickHeight: (properties['brickHeight'] as num?)?.round() ?? brickHeight,
      staggered: properties['staggered'] as bool? ?? staggered,
    );
  }

  TilePalette get _effectivePalette {
    switch (style) {
      case WallStyle.brick:
        return TilePalettes.brick;
      case WallStyle.stone:
        return TilePalettes.stone;
      case WallStyle.darkBrick:
        return TilePalettes.darkBrick;
      case WallStyle.cobblestone:
        return TilePalettes.cobblestone;
    }
  }

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final pal = _effectivePalette;
    final mortarColor = pal.shadow;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickHeight;
        final offset = staggered && row % 2 == 1 ? brickWidth ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final isHorizontalMortar = y % brickHeight == 0;
        final isVerticalMortar = adjustedX % brickWidth == 0;

        if (isHorizontalMortar || isVerticalMortar) {
          pixels[y * width + x] = colorToInt(mortarColor);
        } else {
          final brickIndex = (row + adjustedX ~/ brickWidth) % 3;
          final baseColor = brickIndex == 0
              ? pal.primary
              : brickIndex == 1
              ? pal.secondary
              : pal.accent;
          pixels[y * width + x] = addNoise(baseColor, random, 0.06);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Wall style variants
enum WallStyle { brick, stone, darkBrick, cobblestone }

/// Floor tile for indoor surfaces
class FloorTile extends StructureTile {
  @override
  String get name => 'Floor';

  @override
  String get description => 'Indoor floor surface';

  @override
  String get iconName => 'grid_on';

  @override
  TilePalette get palette => TilePalettes.wood;

  @override
  List<String> get tags => ['structure', 'floor', 'indoor', 'wood'];

  final FloorStyle style;
  final int plankWidth;
  final bool vertical;

  FloorTile(
    super.id, {
    this.style = FloorStyle.wood,
    this.plankWidth = 4,
    this.vertical = false,
  });

  @override
  List<PropertySpec> getPropertySpecs() => [
    SelectSpec<String>(
      key: 'style',
      label: 'Style',
      initialValue: _floorStyleKey(style),
      options: _floorStyleOptions,
    ),
    SliderSpec(
      key: 'plankWidth',
      label: 'Plank Width',
      min: 2,
      max: 12,
      divisions: 10,
      isInteger: true,
      initialValue: plankWidth,
    ),
    BoolSpec(
      key: 'vertical',
      label: 'Vertical Pattern',
      initialValue: vertical,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    final styleKey = properties['style'] as String? ?? _floorStyleKey(style);
    return FloorTile(
      id,
      style: _floorStyleFromKey(styleKey),
      plankWidth: (properties['plankWidth'] as num?)?.round() ?? plankWidth,
      vertical: properties['vertical'] as bool? ?? vertical,
    );
  }

  TilePalette get _effectivePalette {
    switch (style) {
      case FloorStyle.wood:
        return TilePalettes.wood;
      case FloorStyle.stone:
        return TilePalettes.stone;
      case FloorStyle.tile:
        return TilePalettes.cobblestone;
    }
  }

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final pal = _effectivePalette;

    if (style == FloorStyle.wood) {
      _generateWoodFloor(pixels, width, height, random, pal, seed);
    } else if (style == FloorStyle.tile) {
      _generateTileFloor(pixels, width, height, random, pal);
    } else {
      _generateStoneFloor(pixels, width, height, random, pal, seed);
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }

  void _generateWoodFloor(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    TilePalette pal,
    int seed,
  ) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final plankPos = vertical ? x : y;
        final grainPos = vertical ? y : x;
        final plankIndex = plankPos ~/ plankWidth;

        if (plankPos % plankWidth == 0) {
          pixels[y * width + x] = colorToInt(pal.shadow);
          continue;
        }

        final grain = sin((grainPos + plankIndex * 3) / 2.0 + seed);
        Color baseColor;
        if (grain < -0.3) {
          baseColor = pal.shadow;
        } else if (grain < 0.3) {
          baseColor = pal.primary;
        } else {
          baseColor = pal.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add knots
    if (random.nextDouble() < 0.2) {
      final kx = random.nextInt(width - 2) + 1;
      final ky = random.nextInt(height - 2) + 1;
      pixels[ky * width + kx] = colorToInt(pal.shadow);
    }
  }

  void _generateStoneFloor(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    TilePalette pal,
    int seed,
  ) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 2.0 + seed * 5, y / 2.0, 3);
        Color baseColor;
        if (noiseVal < 0.3) {
          baseColor = pal.shadow;
        } else if (noiseVal < 0.6) {
          baseColor = pal.primary;
        } else {
          baseColor = pal.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }
  }

  void _generateTileFloor(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    TilePalette pal,
  ) {
    const tileSize = 4;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (y % tileSize == 0 || x % tileSize == 0) {
          pixels[y * width + x] = colorToInt(pal.shadow);
        } else {
          final tileIndex = ((y ~/ tileSize) + (x ~/ tileSize)) % 2;
          final baseColor = tileIndex == 0 ? pal.primary : pal.secondary;
          pixels[y * width + x] = addNoise(baseColor, random, 0.03);
        }
      }
    }
  }
}

/// Floor style variants
enum FloorStyle { wood, stone, tile }
