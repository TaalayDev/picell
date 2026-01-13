import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// EXTENDED TILE PALETTES
// ============================================================================

class ExtendedTilePalettes {
  ExtendedTilePalettes._();

  /// Light gray stone palette
  static const lightGrayStone = TilePalette(
    name: 'Light Gray Stone',
    colors: [
      Color(0xFF9A9A9A), // Base light gray
      Color(0xFFAAAAAA), // Lighter gray
      Color(0xFF8A8A8A), // Medium gray
      Color(0xFFBABABA), // Highlight
      Color(0xFF6A6A6A), // Shadow
    ],
  );

  /// Medium gray stone palette
  static const mediumGrayStone = TilePalette(
    name: 'Medium Gray Stone',
    colors: [
      Color(0xFF7A7A7A), // Base
      Color(0xFF8A8A8A), // Light
      Color(0xFF6A6A6A), // Dark
      Color(0xFF9A9A9A), // Highlight
      Color(0xFF5A5A5A), // Shadow
    ],
  );

  /// Brown brick palette
  static const brownBrick = TilePalette(
    name: 'Brown Brick',
    colors: [
      Color(0xFF8B6B5B), // Base brown
      Color(0xFF9B7B6B), // Light brown
      Color(0xFF7B5B4B), // Dark brown
      Color(0xFFAB8B7B), // Highlight
      Color(0xFF5B4B3B), // Shadow/mortar
    ],
  );

  /// Reddish brown brick palette
  static const redBrick = TilePalette(
    name: 'Red Brick',
    colors: [
      Color(0xFF9B5B4B), // Base red-brown
      Color(0xFFAB6B5B), // Light
      Color(0xFF8B4B3B), // Dark
      Color(0xFFBB7B6B), // Highlight
      Color(0xFF4B3B2B), // Shadow
    ],
  );

  /// Vine/moss green
  static const mossGreen = TilePalette(
    name: 'Moss Green',
    colors: [
      Color(0xFF5A8A4A), // Base green
      Color(0xFF6A9A5A), // Light green
      Color(0xFF4A7A3A), // Dark green
      Color(0xFF7AAA6A), // Highlight
      Color(0xFF3A5A2A), // Shadow
    ],
  );
}

// ============================================================================
// GRAY STONE TILES - ROW 1
// ============================================================================

/// Small irregular cobblestone pattern
class SmallCobblestoneFloorTile extends TileBase {
  SmallCobblestoneFloorTile(super.id);

  @override
  String get name => 'Small Cobblestone Floor';
  @override
  String get description => 'Small irregular cobblestone floor pattern';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'cobblestone', 'floor', 'small', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with dark mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate small stones
    final stoneSize = 2;
    for (int sy = 0; sy < height; sy += stoneSize + 1) {
      for (int sx = 0; sx < width; sx += stoneSize + 1) {
        final offsetX = random.nextInt(2);
        final offsetY = random.nextInt(2);
        final stoneColor = palette.colors[random.nextInt(3)];

        for (int dy = 0; dy < stoneSize; dy++) {
          for (int dx = 0; dx < stoneSize; dx++) {
            final px = sx + dx + offsetX;
            final py = sy + dy + offsetY;
            if (px < width && py < height) {
              pixels[py * width + px] = addNoise(stoneColor, random, 0.05);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Medium cobblestone with visible gaps
class MediumCobblestoneFloorTile extends TileBase {
  MediumCobblestoneFloorTile(super.id);

  @override
  String get name => 'Medium Cobblestone Floor';
  @override
  String get description => 'Medium sized cobblestone floor';
  @override
  String get iconName => 'apps';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'cobblestone', 'floor', 'medium', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill base
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate medium stones in grid
    final cellSize = 4;
    for (int cy = 0; cy < height; cy += cellSize) {
      for (int cx = 0; cx < width; cx += cellSize) {
        final stoneW = cellSize - 1;
        final stoneH = cellSize - 1;
        final stoneColor = palette.colors[random.nextInt(3)];

        for (int dy = 0; dy < stoneH; dy++) {
          for (int dx = 0; dx < stoneW; dx++) {
            final px = cx + dx;
            final py = cy + dy;
            if (px < width && py < height) {
              // Add edge shading
              final isEdge = dx == 0 || dy == 0 || dx == stoneW - 1 || dy == stoneH - 1;
              if (isEdge) {
                pixels[py * width + px] = addNoise(palette.colors[2], random, 0.04);
              } else {
                pixels[py * width + px] = addNoise(stoneColor, random, 0.04);
              }
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Rough textured stone surface
class RoughStoneFloorTile extends TileBase {
  RoughStoneFloorTile(super.id);

  @override
  String get name => 'Rough Stone Floor';
  @override
  String get description => 'Rough textured stone surface';
  @override
  String get iconName => 'texture';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'rough', 'floor', 'textured', 'dungeon'];

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
        final noise1 = noise2D(x / 2.0 + seed * 3, y / 2.0, 3);
        final noise2 = noise2D(x / 4.0 + seed * 7, y / 4.0, 2);
        final combined = noise1 * 0.6 + noise2 * 0.4;

        Color baseColor;
        if (combined < 0.3) {
          baseColor = palette.shadow;
        } else if (combined < 0.5) {
          baseColor = palette.colors[2];
        } else if (combined < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.06);
      }
    }

    return pixels;
  }
}

/// Stone with vine/moss overlay
class VineStoneFloorTile extends TileBase {
  VineStoneFloorTile(super.id);

  @override
  String get name => 'Vine Stone Floor';
  @override
  String get description => 'Stone floor with vine growth';
  @override
  String get iconName => 'eco';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'vine', 'moss', 'floor', 'overgrown', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final vinePal = ExtendedTilePalettes.mossGreen;

    // Base stone
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed * 5, y / 3.0, 2);
        Color baseColor;
        if (noiseVal < 0.35) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.65) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add vine patches
    final vineNoise = Random(seed + 100);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final vn = noise2D(x / 4.0 + seed * 2, y / 4.0, 2);
        if (vn > 0.55) {
          final vineColor = vn > 0.7 ? vinePal.highlight : vinePal.primary;
          pixels[y * width + x] = addNoise(vineColor, vineNoise, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Regular stone brick pattern
class RegularStoneBrickTile extends TileBase {
  RegularStoneBrickTile(super.id);

  @override
  String get name => 'Regular Stone Brick';
  @override
  String get description => 'Regular stone brick wall pattern';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'brick', 'wall', 'regular', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickW = 8;
    final brickH = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickH;
        final offset = row % 2 == 1 ? brickW ~/ 2 : 0;
        final adjX = (x + offset) % width;

        final isHMortar = y % brickH == 0;
        final isVMortar = adjX % brickW == 0;

        if (isHMortar || isVMortar) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final brickIdx = (row + adjX ~/ brickW + seed) % 3;
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// GRAY STONE TILES - ROW 2
// ============================================================================

/// Vertical column/stripe pattern
class VerticalStoneStripesTile extends TileBase {
  VerticalStoneStripesTile(super.id);

  @override
  String get name => 'Vertical Stone Stripes';
  @override
  String get description => 'Vertical striped stone pattern';
  @override
  String get iconName => 'view_column';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'stripes', 'vertical', 'column', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final stripeW = 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final stripeIdx = x ~/ stripeW;
        final isGap = x % stripeW == 0;

        if (isGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final colorIdx = (stripeIdx + seed) % 2;
          final baseColor = colorIdx == 0 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Concentric square pattern (ornate block)
class ConcentricSquareStoneTile extends TileBase {
  ConcentricSquareStoneTile(super.id);

  @override
  String get name => 'Concentric Square Stone';
  @override
  String get description => 'Ornate stone with concentric square pattern';
  @override
  String get iconName => 'crop_square';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'ornate', 'square', 'decorative', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final distX = (x - centerX).abs();
        final distY = (y - centerY).abs();
        final maxDist = max(distX, distY);

        // Create concentric rings
        final ring = maxDist ~/ 2;
        Color baseColor;
        if (ring % 2 == 0) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }

        // Add border lines
        if (maxDist % 2 == 0) {
          baseColor = palette.shadow;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    return pixels;
  }
}

/// Diagonal cross-hatch pattern
class CrossHatchStoneTile extends TileBase {
  CrossHatchStoneTile(super.id);

  @override
  String get name => 'Cross Hatch Stone';
  @override
  String get description => 'Stone with diagonal cross-hatch pattern';
  @override
  String get iconName => 'grid_4x4';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'crosshatch', 'diagonal', 'pattern', 'dungeon'];

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
        final diag1 = (x + y) % 4 == 0;
        final diag2 = (x - y + height) % 4 == 0;

        Color baseColor;
        if (diag1 || diag2) {
          baseColor = palette.shadow;
        } else {
          final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
          baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

// ============================================================================
// GRAY STONE TILES - ROW 3 (Large blocks)
// ============================================================================

/// Large stone block with border
class LargeBorderedStoneBlockTile extends TileBase {
  LargeBorderedStoneBlockTile(super.id);

  @override
  String get name => 'Large Bordered Stone Block';
  @override
  String get description => 'Large stone block with decorative border';
  @override
  String get iconName => 'check_box_outline_blank';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'block', 'large', 'border', 'dungeon'];

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
        final distFromEdge = min(min(x, width - 1 - x), min(y, height - 1 - y));

        Color baseColor;
        if (distFromEdge == 0) {
          baseColor = palette.shadow;
        } else if (distFromEdge == 1) {
          baseColor = palette.highlight;
        } else if (distFromEdge == 2) {
          baseColor = palette.primary;
        } else {
          final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
          baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    return pixels;
  }
}

/// Horizontal stone slab pattern
class HorizontalStoneSlabTile extends TileBase {
  HorizontalStoneSlabTile(super.id);

  @override
  String get name => 'Horizontal Stone Slab';
  @override
  String get description => 'Horizontal stone slab pattern';
  @override
  String get iconName => 'view_agenda';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'slab', 'horizontal', 'floor', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final slabH = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final slabIdx = y ~/ slabH;
        final isGap = y % slabH == 0;

        if (isGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final baseColor = palette.colors[(slabIdx + seed) % 3];
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Large stone with moss patches
class MossyLargeStoneTile extends TileBase {
  MossyLargeStoneTile(super.id);

  @override
  String get name => 'Mossy Large Stone';
  @override
  String get description => 'Large stone block with moss growth';
  @override
  String get iconName => 'park';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'moss', 'large', 'overgrown', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final mossPal = ExtendedTilePalettes.mossGreen;

    // Base stone with border
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final distFromEdge = min(min(x, width - 1 - x), min(y, height - 1 - y));

        Color baseColor;
        if (distFromEdge == 0) {
          baseColor = palette.shadow;
        } else {
          final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
          baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add moss patches
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final mossNoise = noise2D(x / 3.0 + seed * 7, y / 3.0, 2);
        if (mossNoise > 0.65) {
          final mossColor = mossNoise > 0.8 ? mossPal.highlight : mossPal.primary;
          pixels[y * width + x] = addNoise(mossColor, random, 0.05);
        }
      }
    }

    // Add small flower
    if (random.nextDouble() < 0.5) {
      final fx = width ~/ 2 + random.nextInt(4) - 2;
      final fy = height ~/ 2 + random.nextInt(4) - 2;
      if (fx >= 0 && fx < width && fy >= 0 && fy < height) {
        pixels[fy * width + fx] = colorToInt(const Color(0xFFFFFF00)); // Yellow flower
      }
    }

    return pixels;
  }
}

/// Inset square pattern
class InsetSquareStoneTile extends TileBase {
  InsetSquareStoneTile(super.id);

  @override
  String get name => 'Inset Square Stone';
  @override
  String get description => 'Stone with inset square pattern';
  @override
  String get iconName => 'filter_none';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'inset', 'square', 'decorative', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final insetSize = 4;
    final insetX = (width - insetSize) ~/ 2;
    final insetY = (height - insetSize) ~/ 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final inInsetX = x >= insetX && x < insetX + insetSize;
        final inInsetY = y >= insetY && y < insetY + insetSize;
        final inInset = inInsetX && inInsetY;

        final distFromEdge = min(min(x, width - 1 - x), min(y, height - 1 - y));

        Color baseColor;
        if (distFromEdge == 0) {
          baseColor = palette.shadow;
        } else if (inInset) {
          // Inset area is darker
          final insetEdge = x == insetX || x == insetX + insetSize - 1 || y == insetY || y == insetY + insetSize - 1;
          baseColor = insetEdge ? palette.shadow : palette.colors[2];
        } else {
          baseColor = palette.primary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    return pixels;
  }
}

// ============================================================================
// GRAY STONE TILES - ROW 4 (Decorative patterns)
// ============================================================================

/// Striped border stone block
class StripedBorderStoneTile extends TileBase {
  StripedBorderStoneTile(super.id);

  @override
  String get name => 'Striped Border Stone';
  @override
  String get description => 'Stone block with striped border';
  @override
  String get iconName => 'border_outer';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'striped', 'border', 'decorative', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final borderSize = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final inBorderX = x < borderSize || x >= width - borderSize;
        final inBorderY = y < borderSize || y >= height - borderSize;
        final inBorder = inBorderX || inBorderY;

        Color baseColor;
        if (inBorder) {
          // Striped border
          final stripe = (x + y) % 2 == 0;
          baseColor = stripe ? palette.primary : palette.shadow;
        } else {
          // Center fill
          final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
          baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    return pixels;
  }
}

/// Horizontal lined pattern
class HorizontalLinedStoneTile extends TileBase {
  HorizontalLinedStoneTile(super.id);

  @override
  String get name => 'Horizontal Lined Stone';
  @override
  String get description => 'Stone with horizontal line pattern';
  @override
  String get iconName => 'dehaze';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'lined', 'horizontal', 'pattern', 'dungeon'];

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
        final lineIdx = y % 3;
        Color baseColor;
        if (lineIdx == 0) {
          baseColor = palette.shadow;
        } else if (lineIdx == 1) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

// ============================================================================
// BROWN BRICK TILES - ROW 5
// ============================================================================

/// Rough brown brick floor
class RoughBrownBrickFloorTile extends TileBase {
  RoughBrownBrickFloorTile(super.id);

  @override
  String get name => 'Rough Brown Brick Floor';
  @override
  String get description => 'Rough textured brown brick floor';
  @override
  String get iconName => 'texture';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'floor', 'rough', 'dungeon'];

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
        final noise1 = noise2D(x / 2.0 + seed * 3, y / 2.0, 3);
        final noise2 = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
        final combined = noise1 * 0.6 + noise2 * 0.4;

        Color baseColor;
        if (combined < 0.3) {
          baseColor = palette.shadow;
        } else if (combined < 0.5) {
          baseColor = palette.colors[2];
        } else if (combined < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.06);
      }
    }

    return pixels;
  }
}

/// Brown brick with horizontal pattern
class HorizontalBrownBrickTile extends TileBase {
  HorizontalBrownBrickTile(super.id);

  @override
  String get name => 'Horizontal Brown Brick';
  @override
  String get description => 'Horizontal brown brick pattern';
  @override
  String get iconName => 'view_stream';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'horizontal', 'wall', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickH = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickH;
        final isGap = y % brickH == 0;

        if (isGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final baseColor = palette.colors[(row + seed) % 3];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Diagonal brown brick pattern
class DiagonalBrownBrickTile extends TileBase {
  DiagonalBrownBrickTile(super.id);

  @override
  String get name => 'Diagonal Brown Brick';
  @override
  String get description => 'Diagonal brown brick pattern';
  @override
  String get iconName => 'square_foot';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'diagonal', 'floor', 'dungeon'];

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
        final diag = (x + y) ~/ 4;
        final isGap = (x + y) % 4 == 0;

        if (isGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final baseColor = palette.colors[(diag + seed) % 3];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Brown brick with vine overlay
class VineBrownBrickTile extends TileBase {
  VineBrownBrickTile(super.id);

  @override
  String get name => 'Vine Brown Brick';
  @override
  String get description => 'Brown brick with vine growth';
  @override
  String get iconName => 'eco';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'vine', 'overgrown', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final vinePal = ExtendedTilePalettes.mossGreen;

    // Base brick
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed * 4, y / 3.0, 2);
        Color baseColor;
        if (noiseVal < 0.35) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.65) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    // Add vines
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final vineNoise = noise2D(x / 4.0 + seed * 2, y / 4.0, 2);
        if (vineNoise > 0.6) {
          final vineColor = vineNoise > 0.75 ? vinePal.highlight : vinePal.primary;
          pixels[y * width + x] = addNoise(vineColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Standard brown brick wall pattern
class StandardBrownBrickWallTile extends TileBase {
  StandardBrownBrickWallTile(super.id);

  @override
  String get name => 'Standard Brown Brick Wall';
  @override
  String get description => 'Standard brown brick wall pattern';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'wall', 'standard', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickW = 6;
    final brickH = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickH;
        final offset = row % 2 == 1 ? brickW ~/ 2 : 0;
        final adjX = (x + offset) % width;

        final isHMortar = y % brickH == 0;
        final isVMortar = adjX % brickW == 0;

        if (isHMortar || isVMortar) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final brickIdx = (row + adjX ~/ brickW + seed) % 3;
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// BROWN BRICK TILES - ROW 6 (Decorative)
// ============================================================================

/// Brown brick with grid pattern
class GridBrownBrickTile extends TileBase {
  GridBrownBrickTile(super.id);

  @override
  String get name => 'Grid Brown Brick';
  @override
  String get description => 'Brown brick with grid overlay';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'grid', 'decorative', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final gridSize = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isGridLine = x % gridSize == 0 || y % gridSize == 0;

        if (isGridLine) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final cellX = x ~/ gridSize;
          final cellY = y ~/ gridSize;
          final cellIdx = (cellX + cellY + seed) % 3;
          final baseColor = palette.colors[cellIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Large bordered brown brick block
class LargeBorderedBrownBrickTile extends TileBase {
  LargeBorderedBrownBrickTile(super.id);

  @override
  String get name => 'Large Bordered Brown Brick';
  @override
  String get description => 'Large brown brick block with border';
  @override
  String get iconName => 'check_box_outline_blank';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'large', 'border', 'dungeon'];

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
        final distFromEdge = min(min(x, width - 1 - x), min(y, height - 1 - y));

        Color baseColor;
        if (distFromEdge == 0) {
          baseColor = palette.shadow;
        } else if (distFromEdge == 1) {
          baseColor = palette.highlight;
        } else {
          final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
          baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Horizontal brown brick slab
class HorizontalBrownBrickSlabTile extends TileBase {
  HorizontalBrownBrickSlabTile(super.id);

  @override
  String get name => 'Horizontal Brown Brick Slab';
  @override
  String get description => 'Horizontal brown brick slab pattern';
  @override
  String get iconName => 'view_agenda';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', 'slab', 'horizontal', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final slabH = 5;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final slabIdx = y ~/ slabH;
        final posInSlab = y % slabH;

        Color baseColor;
        if (posInSlab == 0) {
          baseColor = palette.shadow;
        } else if (posInSlab == slabH - 1) {
          baseColor = palette.highlight;
        } else {
          baseColor = palette.colors[(slabIdx + seed) % 3];
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}
