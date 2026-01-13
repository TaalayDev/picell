import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

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

    // Add weathering effects
    if (variation == TileVariation.weathered) {
      final wearCount = (width * height * 0.05).round();
      for (int i = 0; i < wearCount; i++) {
        final wx = random.nextInt(width);
        final wy = random.nextInt(height);
        pixels[wy * width + wx] = addNoise(pal.shadow, random, 0.1);
      }
    }

    // Add moss
    if (variation == TileVariation.mossy) {
      final mossCount = (width * height * 0.08).round();
      for (int i = 0; i < mossCount; i++) {
        final mx = random.nextInt(width);
        final my = random.nextInt(height);
        pixels[my * width + mx] = colorToInt(TilePalettes.grass.primary);
      }
    }

    // Add cracks
    if (variation == TileVariation.cracked) {
      var cx = random.nextInt(width);
      var cy = 0;
      while (cy < height && cx >= 0 && cx < width) {
        pixels[cy * width + cx] = colorToInt(pal.shadow);
        cy++;
        cx += random.nextInt(3) - 1;
      }
    }

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

    return pixels;
  }

  void _generateWoodFloor(Uint32List pixels, int width, int height, Random random, TilePalette pal, int seed) {
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

  void _generateStoneFloor(Uint32List pixels, int width, int height, Random random, TilePalette pal, int seed) {
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

  void _generateTileFloor(Uint32List pixels, int width, int height, Random random, TilePalette pal) {
    final tileSize = 4;
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
