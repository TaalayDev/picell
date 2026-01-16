import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// ADDITIONAL SPECIALIZED PALETTES
// ============================================================================

class SpecializedTilePalettes {
  SpecializedTilePalettes._();

  /// Red paving brick
  static const redPaving = TilePalette(
    name: 'Red Paving',
    colors: [
      Color(0xFFA85A4A), // Base red-brown
      Color(0xFFB86A5A), // Light
      Color(0xFF984A3A), // Dark
      Color(0xFFC87A6A), // Highlight
      Color(0xFF5A3A2A), // Mortar
    ],
  );

  /// Gray paving stone
  static const grayPaving = TilePalette(
    name: 'Gray Paving',
    colors: [
      Color(0xFF6A6A6A), // Base gray
      Color(0xFF7A7A7A), // Light
      Color(0xFF5A5A5A), // Dark
      Color(0xFF8A8A8A), // Highlight
      Color(0xFF3A3A3A), // Mortar
    ],
  );

  /// Multicolor brick mix
  static const mixedBrick = TilePalette(
    name: 'Mixed Brick',
    colors: [
      Color(0xFF8B5A4A), // Brown-red
      Color(0xFF7A6A5A), // Gray-brown
      Color(0xFF9B4A3A), // Red
      Color(0xFF6A5A4A), // Dark brown
      Color(0xFF4A3A3A), // Mortar
    ],
  );

  /// Weathered wood
  static const weatheredWood = TilePalette(
    name: 'Weathered Wood',
    colors: [
      Color(0xFF6A5A4A), // Gray-brown base
      Color(0xFF7A6A5A), // Light
      Color(0xFF5A4A3A), // Dark
      Color(0xFF8A7A6A), // Highlight
      Color(0xFF3A3A2A), // Shadow
    ],
  );

  /// Rusty metal
  static const rustyMetal = TilePalette(
    name: 'Rusty Metal',
    colors: [
      Color(0xFF8B5B3B), // Rust base
      Color(0xFF9B6B4B), // Light rust
      Color(0xFF6B4B2B), // Dark rust
      Color(0xFFAB7B5B), // Highlight
      Color(0xFF4B3B2B), // Shadow
    ],
  );

  /// Marble
  static const marble = TilePalette(
    name: 'Marble',
    colors: [
      Color(0xFFE8E8E0), // Base white
      Color(0xFFF0F0E8), // Light
      Color(0xFFD0D0C8), // Gray veins
      Color(0xFFFFFFF0), // Highlight
      Color(0xFFB0B0A8), // Dark veins
    ],
  );

  /// Polished granite
  static const granite = TilePalette(
    name: 'Granite',
    colors: [
      Color(0xFF5A5A5A), // Base dark
      Color(0xFF7A7A7A), // Light specks
      Color(0xFF4A4A4A), // Dark
      Color(0xFF9A9A9A), // Highlight specks
      Color(0xFF3A3A3A), // Shadow
    ],
  );

  /// Ceramic tile blue
  static const ceramicBlue = TilePalette(
    name: 'Ceramic Blue',
    colors: [
      Color(0xFF4A6A8A), // Blue base
      Color(0xFF5A7A9A), // Light blue
      Color(0xFF3A5A7A), // Dark blue
      Color(0xFF6A8AAA), // Highlight
      Color(0xFF2A4A6A), // Shadow
    ],
  );

  /// Sandstone
  static const sandstone = TilePalette(
    name: 'Sandstone',
    colors: [
      Color(0xFFD4B896), // Tan base
      Color(0xFFE4C8A6), // Light tan
      Color(0xFFC4A886), // Medium
      Color(0xFFF4D8B6), // Highlight
      Color(0xFF947858), // Shadow
    ],
  );

  /// Metal gray
  static const metalGray = TilePalette(
    name: 'Metal Gray',
    colors: [
      Color(0xFF6A6A6A), // Base
      Color(0xFF8A8A8A), // Light
      Color(0xFF4A4A4A), // Dark
      Color(0xFFAAAAAA), // Highlight
      Color(0xFF2A2A2A), // Shadow
    ],
  );
}

// ============================================================================
// BRICK PATTERN VARIATIONS
// ============================================================================

/// Running bond brick pattern (standard offset)
class RunningBondBrickTile extends TileBase {
  final int brickWidth;
  final int brickHeight;

  RunningBondBrickTile(super.id, {this.brickWidth = 6, this.brickHeight = 3});

  @override
  String get name => 'Running Bond Brick';
  @override
  String get description => 'Standard running bond brick pattern';
  @override
  String get iconName => 'view_module';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.redPaving;
  @override
  List<String> get tags => ['brick', 'running', 'bond', 'wall', 'paving'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickHeight;
        final offset = row % 2 == 1 ? brickWidth ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final isHMortar = y % brickHeight == 0;
        final isVMortar = adjustedX % brickWidth == 0;

        if (isHMortar || isVMortar) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final brickIdx = (row + adjustedX ~/ brickWidth + seed) % 3;
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Stack bond brick (no offset, aligned)
class StackBondBrickTile extends TileBase {
  final int brickWidth;
  final int brickHeight;

  StackBondBrickTile(super.id, {this.brickWidth = 4, this.brickHeight = 3});

  @override
  String get name => 'Stack Bond Brick';
  @override
  String get description => 'Stack bond brick pattern';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.grayPaving;
  @override
  List<String> get tags => ['brick', 'stack', 'bond', 'aligned'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isHMortar = y % brickHeight == 0;
        final isVMortar = x % brickWidth == 0;

        if (isHMortar || isVMortar) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final brickX = x ~/ brickWidth;
          final brickY = y ~/ brickHeight;
          final brickIdx = (brickX + brickY + seed) % 3;
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Basket weave brick pattern
class BasketWeaveBrickTile extends TileBase {
  BasketWeaveBrickTile(super.id);

  @override
  String get name => 'Basket Weave Brick';
  @override
  String get description => 'Basket weave brick pattern';
  @override
  String get iconName => 'view_quilt';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => SpecializedTilePalettes.mixedBrick;
  @override
  List<String> get tags => ['brick', 'basket', 'weave', 'paving'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final unitSize = 8;

    // Fill with mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final unitX = x ~/ unitSize;
        final unitY = y ~/ unitSize;
        final localX = x % unitSize;
        final localY = y % unitSize;

        final isHorizontal = (unitX + unitY) % 2 == 0;
        bool inBrick = false;
        int brickIdx = 0;

        if (isHorizontal) {
          final brickRow = localY ~/ 4;
          final inBrickY = localY % 4 > 0 && localY % 4 < 3;
          final inBrickX = localX > 0 && localX < unitSize - 1;
          inBrick = inBrickY && inBrickX;
          brickIdx = (unitX + unitY + brickRow) % 3;
        } else {
          final brickCol = localX ~/ 4;
          final inBrickX = localX % 4 > 0 && localX % 4 < 3;
          final inBrickY = localY > 0 && localY < unitSize - 1;
          inBrick = inBrickX && inBrickY;
          brickIdx = (unitX + unitY + brickCol) % 3;
        }

        if (inBrick) {
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Diagonal brick pattern
class DiagonalBrickTile extends TileBase {
  DiagonalBrickTile(super.id);

  @override
  String get name => 'Diagonal Brick';
  @override
  String get description => 'Diagonal brick paving';
  @override
  String get iconName => 'square_foot';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => SpecializedTilePalettes.redPaving;
  @override
  List<String> get tags => ['brick', 'diagonal', 'paving'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickSize = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final rotX = x + y;
        final rotY = x - y + height;

        final isMortar = rotX % brickSize == 0 || rotY % brickSize == 0;

        if (isMortar) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final brickIdx = ((rotX ~/ brickSize) + (rotY ~/ brickSize) + seed) % 3;
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Herringbone brick pattern
class HerringboneBrickTile extends TileBase {
  HerringboneBrickTile(super.id);

  @override
  String get name => 'Herringbone Brick';
  @override
  String get description => 'Herringbone brick pattern';
  @override
  String get iconName => 'view_quilt';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => SpecializedTilePalettes.redPaving;
  @override
  List<String> get tags => ['brick', 'herringbone', 'paving'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickW = 4;
    final brickH = 2;
    final unitSize = brickW + brickH;

    // Fill with mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final unitX = x ~/ unitSize;
        final unitY = y ~/ unitSize;
        final localX = x % unitSize;
        final localY = y % unitSize;

        bool inBrick = false;
        int brickIdx = 0;

        // Horizontal brick
        if (localY < brickH && localX < brickW) {
          inBrick = localY > 0 && localX > 0 && localX < brickW - 1;
          brickIdx = (unitX + unitY) % 3;
        }
        // Vertical brick
        else if (localY >= brickH && localX >= brickH) {
          final vy = localY - brickH;
          final vx = localX - brickH;
          inBrick = vx > 0 && vx < brickH - 1 && vy < brickW - 1;
          brickIdx = (unitX + unitY + 1) % 3;
        }

        if (inBrick) {
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE PATTERN VARIATIONS
// ============================================================================

/// Flagstone irregular paving
class FlagstoneTile extends TileBase {
  FlagstoneTile(super.id);

  @override
  String get name => 'Flagstone';
  @override
  String get description => 'Irregular flagstone paving';
  @override
  String get iconName => 'dashboard';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => SpecializedTilePalettes.sandstone;
  @override
  List<String> get tags => ['stone', 'flagstone', 'irregular', 'paving'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Voronoi cells
    final seedPoints = <List<int>>[];
    final pointCount = 6;
    final seedRandom = Random(seed);
    for (int i = 0; i < pointCount; i++) {
      seedPoints.add([seedRandom.nextInt(width), seedRandom.nextInt(height)]);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var minDist = double.infinity;
        var minDist2 = double.infinity;
        var closestIdx = 0;

        for (int i = 0; i < seedPoints.length; i++) {
          final dx = (x - seedPoints[i][0]).abs();
          final dy = (y - seedPoints[i][1]).abs();
          final dist = sqrt(dx * dx + dy * dy);

          if (dist < minDist) {
            minDist2 = minDist;
            minDist = dist;
            closestIdx = i;
          } else if (dist < minDist2) {
            minDist2 = dist;
          }
        }

        if (minDist2 - minDist < 1.5) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final colorIdx = (closestIdx + seed) % 3;
          final baseColor = palette.colors[colorIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Ashlar cut stone blocks
class AshlarStoneTile extends TileBase {
  final int blockWidth;
  final int blockHeight;

  AshlarStoneTile(super.id, {this.blockWidth = 8, this.blockHeight = 4});

  @override
  String get name => 'Ashlar Stone';
  @override
  String get description => 'Cut stone block pattern';
  @override
  String get iconName => 'view_module';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.sandstone;
  @override
  List<String> get tags => ['stone', 'ashlar', 'block', 'wall'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ blockHeight;
        final offset = row % 2 == 1 ? blockWidth ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final isHJoint = y % blockHeight == 0;
        final isVJoint = adjustedX % blockWidth == 0;

        if (isHJoint || isVJoint) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final blockIdx = (row + adjustedX ~/ blockWidth + seed) % 3;
          final baseColor = palette.colors[blockIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.03);
        }
      }
    }

    return pixels;
  }
}

/// River rock / pebbles
class RiverRockTile extends TileBase {
  RiverRockTile(super.id);

  @override
  String get name => 'River Rock';
  @override
  String get description => 'Smooth river rock surface';
  @override
  String get iconName => 'bubble_chart';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => SpecializedTilePalettes.grayPaving;
  @override
  List<String> get tags => ['rock', 'river', 'pebble', 'smooth'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dark gaps
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Elliptical rocks
    final rockCount = (width * height / 20).round();
    for (int r = 0; r < rockCount; r++) {
      final cx = random.nextInt(width);
      final cy = random.nextInt(height);
      final rx = random.nextInt(2) + 2;
      final ry = random.nextInt(2) + 1;
      final colorIdx = random.nextInt(3);
      final rockColor = palette.colors[colorIdx];

      for (int dy = -ry; dy <= ry; dy++) {
        for (int dx = -rx; dx <= rx; dx++) {
          final inEllipse = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1;
          if (inEllipse) {
            final px = (cx + dx) % width;
            final py = (cy + dy) % height;
            if (px >= 0 && py >= 0) {
              pixels[py * width + px] = addNoise(rockColor, random, 0.04);
            }
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// DECORATIVE FLOOR TILES
// ============================================================================

/// Marble floor
class MarbleFloorTile extends TileBase {
  final int tileSize;

  MarbleFloorTile(super.id, {this.tileSize = 8});

  @override
  String get name => 'Marble Floor';
  @override
  String get description => 'Polished marble floor tiles';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.marble;
  @override
  List<String> get tags => ['marble', 'floor', 'polished', 'luxury'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isGrout = x % tileSize == 0 || y % tileSize == 0;

        if (isGrout) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          // Marble veining
          final vein1 = noise2D(x / 3.0 + seed, y / 5.0, 3);
          final vein2 = noise2D(x / 8.0 + seed * 2, y / 3.0, 2);
          final combined = vein1 * 0.6 + vein2 * 0.4;

          Color baseColor;
          if (combined > 0.7) {
            baseColor = palette.colors[2]; // Gray veins
          } else if (combined < 0.15) {
            baseColor = palette.shadow; // Dark veins
          } else {
            baseColor = combined > 0.5 ? palette.primary : palette.secondary;
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.02);
        }
      }
    }

    return pixels;
  }
}

/// Granite floor
class GraniteFloorTile extends TileBase {
  final int tileSize;

  GraniteFloorTile(super.id, {this.tileSize = 8});

  @override
  String get name => 'Granite Floor';
  @override
  String get description => 'Polished granite floor';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.granite;
  @override
  List<String> get tags => ['granite', 'floor', 'polished', 'speckled'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isGrout = x % tileSize == 0 || y % tileSize == 0;

        if (isGrout) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final speckle = random.nextDouble();

          Color baseColor;
          if (speckle > 0.85) {
            baseColor = palette.highlight;
          } else if (speckle > 0.7) {
            baseColor = palette.secondary;
          } else if (speckle < 0.15) {
            baseColor = palette.shadow;
          } else {
            baseColor = palette.primary;
          }

          pixels[y * width + x] = colorToInt(baseColor);
        }
      }
    }

    return pixels;
  }
}

/// Ceramic colored tile
class CeramicTileTile extends TileBase {
  final int tileSize;

  CeramicTileTile(super.id, {this.tileSize = 4});

  @override
  String get name => 'Ceramic Tile';
  @override
  String get description => 'Colored ceramic tiles';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.ceramicBlue;
  @override
  List<String> get tags => ['ceramic', 'tile', 'colored', 'bathroom'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isGrout = x % tileSize == 0 || y % tileSize == 0;

        if (isGrout) {
          pixels[y * width + x] = colorToInt(const Color(0xFFE0E0E0));
        } else {
          final tileX = x ~/ tileSize;
          final tileY = y ~/ tileSize;
          final tileIdx = (tileX + tileY + seed) % 3;
          final baseColor = palette.colors[tileIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.02);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// WOOD AND METAL SURFACES
// ============================================================================

/// Weathered wood planks
class WeatheredWoodTile extends TileBase {
  final bool vertical;
  final int plankWidth;

  WeatheredWoodTile(super.id, {this.vertical = true, this.plankWidth = 4});

  @override
  String get name => 'Weathered Wood';
  @override
  String get description => 'Weathered wooden planks';
  @override
  String get iconName => 'carpenter';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.weatheredWood;
  @override
  List<String> get tags => ['wood', 'weathered', 'plank', 'old'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final plankPos = vertical ? x : y;
        final grainPos = vertical ? y : x;
        final plankIdx = plankPos ~/ plankWidth;

        if (plankPos % plankWidth == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow);
          continue;
        }

        final grain = sin((grainPos + plankIdx * 5) / 2.5 + seed);
        final weathering = noise2D(x / 3.0 + seed, y / 3.0, 2);

        Color baseColor;
        if (grain < -0.3 || weathering > 0.75) {
          baseColor = palette.shadow;
        } else if (grain < 0.2) {
          baseColor = palette.colors[2];
        } else if (grain < 0.5) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}

/// Corrugated metal
class CorrugatedMetalTile extends TileBase {
  final bool vertical;

  CorrugatedMetalTile(super.id, {this.vertical = true});

  @override
  String get name => 'Corrugated Metal';
  @override
  String get description => 'Corrugated metal sheet';
  @override
  String get iconName => 'view_stream';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.metalGray;
  @override
  List<String> get tags => ['metal', 'corrugated', 'industrial', 'roof'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final waveWidth = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final wavePos = vertical ? x : y;
        final posInWave = wavePos % waveWidth;

        Color baseColor;
        if (posInWave == 0) {
          baseColor = palette.shadow;
        } else if (posInWave == waveWidth - 1) {
          baseColor = palette.highlight;
        } else {
          baseColor = palette.primary;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    return pixels;
  }
}

/// Rusty metal plate
class RustyMetalTile extends TileBase {
  RustyMetalTile(super.id);

  @override
  String get name => 'Rusty Metal';
  @override
  String get description => 'Rusted metal plate';
  @override
  String get iconName => 'square';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.rustyMetal;
  @override
  List<String> get tags => ['metal', 'rust', 'industrial', 'old'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final rust1 = noise2D(x / 3.0 + seed * 4, y / 3.0, 3);
        final rust2 = noise2D(x / 6.0 + seed * 2, y / 6.0, 2);
        final combined = rust1 * 0.6 + rust2 * 0.4;

        Color baseColor;
        if (combined < 0.25) {
          baseColor = palette.shadow;
        } else if (combined < 0.45) {
          baseColor = palette.colors[2];
        } else if (combined < 0.65) {
          baseColor = palette.primary;
        } else if (combined < 0.85) {
          baseColor = palette.secondary;
        } else {
          baseColor = palette.highlight;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}

/// Diamond plate metal
class DiamondPlateTile extends TileBase {
  DiamondPlateTile(super.id);

  @override
  String get name => 'Diamond Plate';
  @override
  String get description => 'Diamond pattern metal';
  @override
  String get iconName => 'blur_on';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.metalGray;
  @override
  List<String> get tags => ['metal', 'diamond', 'plate', 'industrial'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final patternSize = 4;

    // Base metal
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(palette.primary, random, 0.03);
    }

    // Diamond pattern
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final patternX = x % patternSize;
        final patternY = y % patternSize;
        final offset = (y ~/ patternSize) % 2 == 1 ? patternSize ~/ 2 : 0;
        final adjustedX = (patternX + offset) % patternSize;

        final centerDist = (adjustedX - patternSize / 2).abs() + (patternY - patternSize / 2).abs();

        if (centerDist < patternSize / 2) {
          if (centerDist < patternSize / 4) {
            pixels[y * width + x] = colorToInt(palette.highlight);
          } else {
            pixels[y * width + x] = colorToInt(palette.secondary);
          }
        }
      }
    }

    return pixels;
  }
}

/// Metal grating/mesh
class GratingTile extends TileBase {
  final int gridSize;

  GratingTile(super.id, {this.gridSize = 3});

  @override
  String get name => 'Metal Grating';
  @override
  String get description => 'Metal grating/mesh';
  @override
  String get iconName => 'grid_4x4';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => SpecializedTilePalettes.metalGray;
  @override
  List<String> get tags => ['metal', 'grating', 'mesh', 'industrial'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isBar = x % gridSize == 0 || y % gridSize == 0;

        if (isBar) {
          final highlight = (x % gridSize == 0 && y % 2 == 0) || (y % gridSize == 0 && x % 2 == 0);
          final baseColor = highlight ? palette.highlight : palette.primary;
          pixels[y * width + x] = addNoise(baseColor, random, 0.03);
        } else {
          pixels[y * width + x] = colorToInt(const Color(0xFF1A1A1A));
        }
      }
    }

    return pixels;
  }
}
