import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// EXTENDED TILE PALETTES
// ============================================================================

class ExtendedStoneTilePalettes {
  ExtendedStoneTilePalettes._();

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

  /// Dark dungeon stone
  static const darkStone = TilePalette(
    name: 'Dark Stone',
    colors: [
      Color(0xFF404040), // Base dark gray
      Color(0xFF505050), // Medium gray
      Color(0xFF383838), // Darker gray
      Color(0xFF606060), // Highlight
      Color(0xFF202020), // Deep shadow
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'cobblestone', 'floor', 'small', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'cobblestone', 'floor', 'medium', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'rough', 'floor', 'textured', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'vine', 'moss', 'floor', 'overgrown', 'dungeon'];

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
    final vinePal = ExtendedStoneTilePalettes.mossGreen;

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'brick', 'wall', 'regular', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'stripes', 'vertical', 'column', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'ornate', 'square', 'decorative', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'crosshatch', 'diagonal', 'pattern', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'block', 'large', 'border', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'slab', 'horizontal', 'floor', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'moss', 'large', 'overgrown', 'dungeon'];

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
    final mossPal = ExtendedStoneTilePalettes.mossGreen;

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'inset', 'square', 'decorative', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'striped', 'border', 'decorative', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
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
  TilePalette get palette => ExtendedStoneTilePalettes.mediumGrayStone;
  @override
  List<String> get tags => ['stone', 'lined', 'horizontal', 'pattern', 'dungeon'];

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

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

// ============================================================================
// BROWN BRICK TILES — single parametric class replacing 8 separate classes
// ============================================================================

/// Visual style for brown brick tiles
enum BrownBrickStyle {
  rough('Rough Floor', 'texture', 'Rough noise-based brown brick floor'),
  horizontal('Horizontal', 'view_stream', 'Horizontal row brown brick pattern'),
  diagonal('Diagonal', 'square_foot', 'Diagonal brown brick pattern'),
  vine('Vine', 'eco', 'Brown brick with vine growth overlay'),
  standard('Standard Wall', 'grid_view', 'Classic running-bond brown brick wall'),
  grid('Grid', 'grid_on', 'Brown brick with square grid overlay'),
  largeBordered('Large Bordered', 'check_box_outline_blank', 'Large brown brick block with border'),
  slab('Slab', 'view_agenda', 'Horizontal brown brick slab pattern');

  final String displayName;
  final String icon;
  final String desc;
  const BrownBrickStyle(this.displayName, this.icon, this.desc);
}

/// Brown brick tile — all 8 visual styles in one class.
/// Use [style] to choose the pattern; all share the same brown brick palette.
class BrownBrickTile extends TileBase {
  final BrownBrickStyle style;

  BrownBrickTile(super.id, {this.style = BrownBrickStyle.standard});

  @override
  String get name => '${style.displayName} Brown Brick';
  @override
  String get description => style.desc;
  @override
  String get iconName => style.icon;
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.brownBrick;
  @override
  List<String> get tags => ['brick', 'brown', style.name, 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = switch (style) {
      BrownBrickStyle.rough => _generateRough(width, height, seed),
      BrownBrickStyle.horizontal => _generateHorizontal(width, height, seed),
      BrownBrickStyle.diagonal => _generateDiagonal(width, height, seed),
      BrownBrickStyle.vine => _generateVine(width, height, seed),
      BrownBrickStyle.standard => _generateStandard(width, height, seed),
      BrownBrickStyle.grid => _generateGrid(width, height, seed),
      BrownBrickStyle.largeBordered => _generateLargeBordered(width, height, seed),
      BrownBrickStyle.slab => _generateSlab(width, height, seed),
    };
    final random = Random(seed ^ 0xABCD);
    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }

  Uint32List _generateRough(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n1 = noise2D(x / 2.0 + seed * 3, y / 2.0, 3);
        final n2 = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
        final combined = n1 * 0.6 + n2 * 0.4;
        Color c;
        if (combined < 0.3) {
          c = palette.shadow;
        } else if (combined < 0.5) {
          c = palette.colors[2];
        } else if (combined < 0.7) {
          c = palette.primary;
        } else {
          c = palette.secondary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.06);
      }
    }
    return pixels;
  }

  Uint32List _generateHorizontal(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    const brickH = 4;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickH;
        if (y % brickH == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          pixels[y * width + x] = addNoise(palette.colors[(row + seed) % 3], random, 0.05);
        }
      }
    }
    return pixels;
  }

  Uint32List _generateDiagonal(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final diag = (x + y) ~/ 4;
        if ((x + y) % 4 == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          pixels[y * width + x] = addNoise(palette.colors[(diag + seed) % 3], random, 0.05);
        }
      }
    }
    return pixels;
  }

  Uint32List _generateVine(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final vinePal = ExtendedStoneTilePalettes.mossGreen;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed * 4, y / 3.0, 2);
        final c = n < 0.35 ? palette.shadow : n < 0.65 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(c, random, 0.05);
      }
    }
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final vn = noise2D(x / 4.0 + seed * 2, y / 4.0, 2);
        if (vn > 0.6) {
          pixels[y * width + x] = addNoise(vn > 0.75 ? vinePal.highlight : vinePal.primary, random, 0.05);
        }
      }
    }
    return pixels;
  }

  Uint32List _generateStandard(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    const brickW = 6;
    const brickH = 4;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ brickH;
        final adjX = (x + (row % 2 == 1 ? brickW ~/ 2 : 0)) % width;
        if (y % brickH == 0 || adjX % brickW == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          pixels[y * width + x] = addNoise(palette.colors[(row + adjX ~/ brickW + seed) % 3], random, 0.05);
        }
      }
    }
    return pixels;
  }

  Uint32List _generateGrid(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    const gridSize = 4;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x % gridSize == 0 || y % gridSize == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final cellIdx = (x ~/ gridSize + y ~/ gridSize + seed) % 3;
          pixels[y * width + x] = addNoise(palette.colors[cellIdx], random, 0.05);
        }
      }
    }
    return pixels;
  }

  Uint32List _generateLargeBordered(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final d = min(min(x, width - 1 - x), min(y, height - 1 - y));
        Color c;
        if (d == 0) {
          c = palette.shadow;
        } else if (d == 1) {
          c = palette.highlight;
        } else {
          c = noise2D(x / 3.0 + seed, y / 3.0, 2) > 0.5 ? palette.primary : palette.secondary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.04);
      }
    }
    return pixels;
  }

  Uint32List _generateSlab(int width, int height, int seed) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    const slabH = 5;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final slabIdx = y ~/ slabH;
        final pos = y % slabH;
        Color c;
        if (pos == 0) {
          c = palette.shadow;
        } else if (pos == slabH - 1) {
          c = palette.highlight;
        } else {
          c = palette.colors[(slabIdx + seed) % 3];
        }
        pixels[y * width + x] = addNoise(c, random, 0.05);
      }
    }
    return pixels;
  }
}

// ============================================================================
// NEW DUNGEON SPECIALTY TILES
// ============================================================================

/// Dungeon pit floor — stone with a dark void opening in the center
class DungeonPitFloorTile extends TileBase {
  DungeonPitFloorTile(super.id);

  @override
  String get name => 'Dungeon Pit Floor';
  @override
  String get description => 'Stone floor with a dark pit opening';
  @override
  String get iconName => 'trip_origin';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.darkStone;
  @override
  List<String> get tags => ['stone', 'pit', 'void', 'floor', 'dungeon', 'cave'];

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
    final cx = width / 2;
    final cy = height / 2;
    final pitR = min(width, height) / 3.5;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final n = noise2D(x / 2.5 + seed * 3, y / 2.5, 2);

        if (dist < pitR - 1 + n * 0.8) {
          // Pit void — fully dark with a slight void flicker
          final alpha = dist < pitR * 0.6 ? 0xFF : 0xFF;
          final darkness = (10 + (dist / pitR * 18).round()).clamp(0, 40);
          pixels[y * width + x] = (alpha << 24) | (darkness << 16) | (darkness ~/ 2 << 8) | darkness;
        } else if (dist < pitR + 2) {
          // Crumbling edge
          final edgeColor = random.nextDouble() < 0.5 ? palette.shadow : palette.colors[2];
          pixels[y * width + x] = addNoise(edgeColor, random, 0.08);
        } else {
          // Stone floor
          final distFromEdge = min(min(x, width - 1 - x), min(y, height - 1 - y));
          Color baseColor;
          if (distFromEdge == 0) {
            baseColor = palette.shadow;
          } else if (n < 0.35) {
            baseColor = palette.colors[2];
          } else {
            baseColor = n > 0.65 ? palette.secondary : palette.primary;
          }
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    // Radial edge cracks around pit
    for (int r = 0; r < 5; r++) {
      final angle = (r / 5) * 2 * pi + random.nextDouble() * 0.4;
      final len = (pitR * 0.6 + random.nextDouble() * pitR * 0.5).round();
      for (int d = 1; d <= len; d++) {
        final x = (cx + (pitR + d) * cos(angle)).round();
        final y = (cy + (pitR + d) * sin(angle)).round();
        if (x < 0 || y < 0 || x >= width || y >= height) break;
        pixels[y * width + x] = colorToInt(palette.shadow);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Blood-stained stone floor — dark stone with red splatters and dried pools
class BloodStainedFloorTile extends TileBase {
  BloodStainedFloorTile(super.id);

  @override
  String get name => 'Blood Stained Floor';
  @override
  String get description => 'Dark stone floor with dried blood stains';
  @override
  String get iconName => 'water_drop';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.darkStone;
  @override
  List<String> get tags => ['stone', 'blood', 'stain', 'floor', 'dungeon', 'dark'];

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

    // Dark rough stone base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 2.8 + seed * 3, y / 2.8, 3);
        Color baseColor;
        if (n < 0.32) {
          baseColor = palette.shadow;
        } else if (n < 0.56) {
          baseColor = palette.colors[2];
        } else {
          baseColor = palette.primary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.06);
      }
    }

    // Blood pool centers
    const bloodFresh = Color(0xFF8B0000);
    const bloodDry = Color(0xFF4A0A0A);
    const bloodEdge = Color(0xFF3A0808);

    final poolCount = 1 + random.nextInt(2);
    for (int p = 0; p < poolCount; p++) {
      final px = 2 + random.nextInt(width - 4);
      final py = 2 + random.nextInt(height - 4);
      final pr = 1.5 + random.nextDouble() * 2.5;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final dx = x - px;
          final dy = y - py;
          final dist = sqrt(dx * dx + dy * dy);
          final n2 = noise2D(x / 1.5 + seed * 11, y / 1.5, 2);

          if (dist < pr * 0.6 + n2 * 0.4) {
            pixels[y * width + x] = addNoise(bloodFresh, random, 0.05);
          } else if (dist < pr + n2 * 0.6) {
            pixels[y * width + x] = addNoise(bloodDry, random, 0.06);
          }
        }
      }
    }

    // Random splatter droplets
    final dropCount = 3 + random.nextInt(5);
    for (int d = 0; d < dropCount; d++) {
      final x = random.nextInt(width);
      final y = random.nextInt(height);
      pixels[y * width + x] = colorToInt(bloodEdge);
      if (x + 1 < width && random.nextDouble() < 0.5) {
        pixels[y * width + x + 1] = colorToInt(bloodDry);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Runic stone floor — ancient carved runes glowing faintly
class RunicFloorTile extends TileBase {
  RunicFloorTile(super.id);

  @override
  String get name => 'Runic Floor';
  @override
  String get description => 'Ancient stone floor with carved glowing runes';
  @override
  String get iconName => 'auto_fix_high';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.darkStone;
  @override
  List<String> get tags => ['stone', 'rune', 'carved', 'ancient', 'floor', 'dungeon', 'magic'];

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

    // Base dark polished stone with a subtle sheen
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.5 + seed * 4, y / 3.5, 2);
        Color c;
        if (n < 0.35) {
          c = palette.shadow;
        } else if (n < 0.65) {
          c = palette.primary;
        } else {
          c = palette.secondary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.04);
      }
    }

    // Rune-line patterns — two intersecting lines
    const runeGlow = Color(0xFF4060C8);
    const runeDim = Color(0xFF202848);

    // Horizontal rune bar
    final runeY = height ~/ 2;
    for (int x = 1; x < width - 1; x++) {
      pixels[runeY * width + x] = colorToInt(runeGlow);
      if (runeY > 0) pixels[(runeY - 1) * width + x] = colorToInt(runeDim);
      if (runeY + 1 < height) pixels[(runeY + 1) * width + x] = colorToInt(runeDim);
    }

    // Vertical rune bar
    final runeX = width ~/ 2;
    for (int y = 1; y < height - 1; y++) {
      pixels[y * width + runeX] = colorToInt(runeGlow);
      if (runeX > 0) pixels[y * width + runeX - 1] = colorToInt(runeDim);
      if (runeX + 1 < width) pixels[y * width + runeX + 1] = colorToInt(runeDim);
    }

    // Corner rune marks
    const runeAccent = Color(0xFF6080E0);
    final corners = [
      [2, 2], [width - 3, 2], [2, height - 3], [width - 3, height - 3],
    ];
    for (final c in corners) {
      final cx = c[0];
      final cy = c[1];
      if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
        pixels[cy * width + cx] = colorToInt(runeAccent);
        if (cx + 1 < width) pixels[cy * width + cx + 1] = colorToInt(runeDim);
        if (cy + 1 < height) pixels[(cy + 1) * width + cx] = colorToInt(runeDim);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Catacomb floor — bone fragments embedded in dark mortar stone
class CatacombFloorTile extends TileBase {
  CatacombFloorTile(super.id);

  @override
  String get name => 'Catacomb Floor';
  @override
  String get description => 'Dark stone floor with embedded bone fragments';
  @override
  String get iconName => 'coronavirus';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.darkStone;
  @override
  List<String> get tags => ['stone', 'bone', 'catacomb', 'floor', 'dungeon', 'dark'];

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

    // Dark, slightly mottled stone base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 2.5 + seed * 5, y / 2.5, 3);
        Color c;
        if (n < 0.3) {
          c = palette.shadow;
        } else if (n < 0.58) {
          c = palette.colors[2];
        } else {
          c = palette.primary;
        }
        pixels[y * width + x] = addNoise(c, random, 0.06);
      }
    }

    // Bone shard colors
    const boneLight = Color(0xFFD8CEB0);
    const boneMid = Color(0xFFBAAA88);
    const boneDark = Color(0xFF8A7A60);

    // Scatter small bone fragments
    final boneCount = 3 + random.nextInt(4);
    for (int b = 0; b < boneCount; b++) {
      final bx = random.nextInt(width);
      final by = random.nextInt(height);
      final bLen = 1 + random.nextInt(3);
      final horizontal = random.nextBool();

      for (int i = 0; i < bLen; i++) {
        final x = horizontal ? bx + i : bx;
        final y = horizontal ? by : by + i;
        if (x >= width || y >= height) break;
        final c = i == 0 ? boneDark : (i == bLen - 1 ? boneDark : (random.nextDouble() > 0.4 ? boneLight : boneMid));
        pixels[y * width + x] = colorToInt(c);
      }
    }

    // Small skull dots
    final skullCount = random.nextInt(2);
    const skullColor = Color(0xFFCCBE98);
    for (int s = 0; s < skullCount; s++) {
      final sx = 1 + random.nextInt(width - 2);
      final sy = 1 + random.nextInt(height - 2);
      pixels[sy * width + sx] = colorToInt(skullColor);
      pixels[(sy - 1) * width + sx] = colorToInt(boneMid);
      pixels[sy * width + sx - 1] = colorToInt(boneDark);
      pixels[sy * width + sx + 1] = colorToInt(boneDark);
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Ancient flagstone floor — large irregular stone slabs with deep mortared joints
class AncientFlagstoneFloorTile extends TileBase {
  AncientFlagstoneFloorTile(super.id);

  @override
  String get name => 'Ancient Flagstone Floor';
  @override
  String get description => 'Large irregular ancient flagstone slabs with deep joints';
  @override
  String get iconName => 'view_quilt';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'flagstone', 'ancient', 'floor', 'dungeon', 'slab'];

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

    // Fill base with mortar shadow
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate irregular flagstones using a grid with noise offsets
    const baseW = 8;
    const baseH = 6;

    for (int cy = 0; cy < height; cy += baseH) {
      for (int cx = 0; cx < width; cx += baseW) {
        // Offset the stone boundary slightly with noise
        final x0 = cx + (noise2D(cx / 4.0 + seed, cy / 4.0, 1) * 2 - 1).round().clamp(-1, 1);
        final y0 = cy + (noise2D(cx / 4.0 + seed + 50, cy / 4.0, 1) * 2 - 1).round().clamp(-1, 1);
        final x1 = (cx + baseW - 1).clamp(0, width - 1);
        final y1 = (cy + baseH - 1).clamp(0, height - 1);

        final stoneColorIdx = (cx ~/ baseW + cy ~/ baseH + seed) % 3;
        final stoneBase = palette.colors[stoneColorIdx];

        for (int y = max(0, y0 + 1); y <= y1 - 1; y++) {
          for (int x = max(0, x0 + 1); x <= x1 - 1; x++) {
            if (x >= width || y >= height) continue;
            // Subtle inner shading — lighter top-left, darker bottom-right
            final shade =
                (x - (x0 + 1)) / max(1, x1 - x0 - 2) * 0.08 + (y - (y0 + 1)) / max(1, y1 - y0 - 2) * 0.05;
            final n = noise2D(x / 2.0 + seed * 7, y / 2.0, 2) * 0.06;
            final r = ((stoneBase.red * (1.0 - shade + n))).round().clamp(0, 255);
            final g = ((stoneBase.green * (1.0 - shade + n))).round().clamp(0, 255);
            final b = ((stoneBase.blue * (1.0 - shade + n))).round().clamp(0, 255);
            pixels[y * width + x] = (0xFF << 24) | (r << 16) | (g << 8) | b;
          }
        }

        // Top-left highlight line
        for (int x = max(0, x0 + 1); x <= x1 - 1 && x < width; x++) {
          final y = y0 + 1;
          if (y >= 0 && y < height) {
            pixels[y * width + x] = colorToInt(palette.highlight);
          }
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Dungeon water pool — shallow standing water on stone floor
class DungeonWaterPoolTile extends TileBase {
  DungeonWaterPoolTile(super.id);

  @override
  String get name => 'Dungeon Water Pool';
  @override
  String get description => 'Shallow standing water pooling on stone floor';
  @override
  String get iconName => 'waves';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.darkStone;
  @override
  List<String> get tags => ['water', 'pool', 'dungeon', 'floor', 'wet', 'underground', 'cave'];

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

    // Dark stone base at the edges
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 2.5 + seed * 6, y / 2.5, 2);
        pixels[y * width + x] = addNoise(
          n < 0.45 ? palette.shadow : palette.colors[2],
          random,
          0.05,
        );
      }
    }

    // Water pool blending inward
    const waterDeep = Color(0xFF1A3048);
    const waterMid = Color(0xFF2A4A60);
    const waterLight = Color(0xFF3A6888);
    const waterSheen = Color(0xFF5A90B8);

    final cx = width / 2;
    final cy = height / 2;
    final poolR = min(width, height) / 2.2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final n = noise2D(x / 2.0 + seed * 9, y / 2.0, 2);

        final edge = poolR + n * 1.5 - 1;
        if (dist < edge * 0.5) {
          pixels[y * width + x] = addNoise(waterDeep, random, 0.04);
        } else if (dist < edge * 0.75) {
          pixels[y * width + x] = addNoise(waterMid, random, 0.04);
        } else if (dist < edge) {
          pixels[y * width + x] = addNoise(waterLight, random, 0.04);
        }
      }
    }

    // Ripple lines
    for (int r = 0; r < 2; r++) {
      final rippleR = poolR * (0.3 + r * 0.25);
      for (int a = 0; a < 24; a++) {
        final angle = a / 24.0 * 2 * pi;
        final x = (cx + rippleR * cos(angle)).round();
        final y = (cy + rippleR * sin(angle)).round();
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        if (pixels[y * width + x] >> 24 != 0) {
          pixels[y * width + x] = colorToInt(waterSheen);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}

/// Stone pillar base — circular column base on stone floor
class StonePillarBaseTile extends TileBase {
  StonePillarBaseTile(super.id);

  @override
  String get name => 'Stone Pillar Base';
  @override
  String get description => 'Circular stone pillar base on flagstone';
  @override
  String get iconName => 'architecture';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => ExtendedStoneTilePalettes.lightGrayStone;
  @override
  List<String> get tags => ['stone', 'pillar', 'column', 'base', 'dungeon', 'wall'];

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
    final cx = width / 2;
    final cy = height / 2;
    final outerR = min(width, height) / 2.2;
    final innerR = outerR * 0.55;

    // Floor tiles around pillar
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final n = noise2D(x / 3.0 + seed * 3, y / 3.0, 2);
        pixels[y * width + x] = addNoise(
          n < 0.4 ? palette.shadow : (n < 0.65 ? palette.primary : palette.secondary),
          random,
          0.04,
        );
      }
    }

    // Pillar shadow cast (slightly darker ring around base)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > outerR && dist < outerR + 2.5) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        }
      }
    }

    // Outer pillar ring
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist <= outerR) {
          Color c;
          if (dist > outerR - 1) {
            c = palette.shadow;
          } else if (dist > outerR - 2) {
            c = palette.highlight;
          } else if (dist > innerR) {
            // Ring bevel — lighter on top-left
            final angle = atan2(dy, dx);
            final shade = ((cos(angle) + sin(angle)) * -0.5 + 0.5).clamp(0.0, 1.0);
            c = shade > 0.55 ? palette.secondary : palette.primary;
          } else {
            // Inner raised dome
            c = dist < innerR * 0.4 ? palette.highlight : palette.secondary;
          }
          pixels[y * width + x] = addNoise(c, random, 0.03);
        }
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }
}
