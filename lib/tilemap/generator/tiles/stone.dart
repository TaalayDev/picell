import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// STONE TILE PALETTES
// ============================================================================

/// Extended stone palettes for dungeon/stone tiles
class StoneTilePalettes {
  StoneTilePalettes._();

  static const grayStone = TilePalette(
    name: 'Gray Stone',
    colors: [
      Color(0xFF7A7A7A), // Base gray
      Color(0xFF8A8A8A), // Light gray
      Color(0xFF6A6A6A), // Medium gray
      Color(0xFF9A9A9A), // Highlight
      Color(0xFF4A4A4A), // Shadow/mortar
    ],
  );

  static const darkStone = TilePalette(
    name: 'Dark Stone',
    colors: [
      Color(0xFF5A5A5A), // Base
      Color(0xFF6A6A6A), // Light
      Color(0xFF4A4A4A), // Dark
      Color(0xFF7A7A7A), // Highlight
      Color(0xFF3A3A3A), // Shadow
    ],
  );

  static const vineGreen = TilePalette(
    name: 'Vine Green',
    colors: [
      Color(0xFF4A7A4A), // Base green
      Color(0xFF5A8A5A), // Light green
      Color(0xFF3A6A3A), // Dark green
      Color(0xFF6A9A6A), // Highlight
      Color(0xFF2A4A2A), // Shadow
    ],
  );

  static const frostBlue = TilePalette(
    name: 'Frost Blue',
    colors: [
      Color(0xFFAADDFF), // Base ice
      Color(0xFFCCEEFF), // Light ice
      Color(0xFF88BBDD), // Medium ice
      Color(0xFFFFFFFF), // Highlight
      Color(0xFF6699BB), // Shadow
    ],
  );

  static const warmBrick = TilePalette(
    name: 'Warm Brick',
    colors: [
      Color(0xFFAA7755), // Base brown
      Color(0xFFBB8866), // Light brown
      Color(0xFF886644), // Dark brown
      Color(0xFFCC9977), // Highlight
      Color(0xFF554433), // Shadow
    ],
  );

  static const darkWood = TilePalette(
    name: 'Dark Wood',
    colors: [
      Color(0xFF4A4A5A), // Base dark
      Color(0xFF5A5A6A), // Light
      Color(0xFF3A3A4A), // Dark
      Color(0xFF6A6A7A), // Highlight
      Color(0xFF2A2A3A), // Shadow
    ],
  );

  static const grassAccent = TilePalette(
    name: 'Grass Accent',
    colors: [
      Color(0xFF5A8A3A), // Base green
      Color(0xFF6A9A4A), // Light green
      Color(0xFF4A7A2A), // Dark green
      Color(0xFF7AAA5A), // Highlight
      Color(0xFF3A5A1A), // Shadow
    ],
  );
}

// ============================================================================
// BASE STONE TILE CLASS
// ============================================================================

/// Base class for stone/dungeon tiles
abstract class StoneTileBase extends TileBase {
  StoneTileBase(super.id);

  @override
  TileCategory get category => TileCategory.dungeon;

  @override
  bool get supportsRotation => true;

  @override
  bool get supportsAutoTiling => true;

  @override
  List<String> get tags => ['stone', 'dungeon', 'wall', 'structure'];
}

// ============================================================================
// HORIZONTAL STONE BRICK TILES (Row 1 of reference)
// ============================================================================

enum HorizontalBrickStyle { standard, light, worn, detailed }

/// Horizontal layered stone brick pattern
class HorizontalStoneBrickTile extends StoneTileBase {
  final HorizontalBrickStyle style;
  final int brickHeight;

  HorizontalStoneBrickTile(
    super.id, {
    this.style = HorizontalBrickStyle.standard,
    this.brickHeight = 4,
  });

  @override
  String get name => 'Horizontal Stone Brick';

  @override
  String get description => 'Horizontal layered stone brick wall';

  @override
  String get iconName => 'view_stream';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'brick', 'wall', 'horizontal', 'dungeon'];

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
        final isHorizontalMortar = y % brickHeight == 0;

        if (isHorizontalMortar) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final rowColorIndex = (row + seed) % 3;
          Color baseColor;
          if (rowColorIndex == 0) {
            baseColor = palette.primary;
          } else if (rowColorIndex == 1) {
            baseColor = palette.secondary;
          } else {
            baseColor = palette.colors[2];
          }

          // Style variations
          if (style == HorizontalBrickStyle.light) {
            baseColor = palette.highlight;
          } else if (style == HorizontalBrickStyle.worn) {
            if (random.nextDouble() < 0.15) {
              baseColor = palette.shadow;
            }
          } else if (style == HorizontalBrickStyle.detailed) {
            final striation = noise2D(x / 6.0, y / 2.0 + seed * 5, 2);
            if (striation > 0.7) {
              baseColor = palette.highlight;
            } else if (striation < 0.25) {
              baseColor = palette.shadow;
            }
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    // Add variation effects
    if (variation == TileVariation.weathered) {
      _addWeathering(pixels, width, height, random);
    } else if (variation == TileVariation.mossy) {
      _addMoss(pixels, width, height, random);
    } else if (variation == TileVariation.cracked) {
      _addCracks(pixels, width, height, random);
    }

    return pixels;
  }

  void _addWeathering(Uint32List pixels, int width, int height, Random random) {
    // Improved weathering with noise-based distribution
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final weatherNoise = noise2D(x / 3.0 + 100, y / 3.0, 3);
        if (weatherNoise > 0.7 && random.nextDouble() < 0.4) {
          final current = pixels[y * width + x];
          if (current != 0) {
            pixels[y * width + x] = addNoise(palette.shadow, random, 0.15);
          }
        }
      }
    }
    // Add scattered dark spots
    final spotCount = (width * height * 0.03).round();
    for (int i = 0; i < spotCount; i++) {
      final x = random.nextInt(width);
      final y = random.nextInt(height);
      pixels[y * width + x] = colorToInt(palette.shadow);
    }
  }

  void _addMoss(Uint32List pixels, int width, int height, Random random) {
    // Improved moss with clustered growth pattern
    final mossSeeds = <List<int>>[];
    final seedCount = 3 + random.nextInt(3);
    for (int i = 0; i < seedCount; i++) {
      mossSeeds.add([random.nextInt(width), random.nextInt(height)]);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Check distance to nearest moss seed
        var minDist = double.infinity;
        for (final seed in mossSeeds) {
          final dist = sqrt(pow(x - seed[0], 2) + pow(y - seed[1], 2));
          if (dist < minDist) minDist = dist;
        }

        final mossNoise = noise2D(x / 2.0 + 50, y / 2.0, 2);
        if (minDist < 4 + mossNoise * 3 && random.nextDouble() < 0.6) {
          final mossColor =
              mossNoise > 0.5 ? StoneTilePalettes.vineGreen.highlight : StoneTilePalettes.vineGreen.primary;
          pixels[y * width + x] = addNoise(mossColor, random, 0.1);
        }
      }
    }
  }

  void _addCracks(Uint32List pixels, int width, int height, Random random) {
    // Improved crack generation with branching
    final crackCount = 1 + random.nextInt(2);
    for (int c = 0; c < crackCount; c++) {
      var cx = random.nextInt(width);
      var cy = random.nextBool() ? 0 : random.nextInt(height ~/ 2);
      final targetY = height;

      while (cy < targetY && cx >= 0 && cx < width) {
        pixels[cy * width + cx] = colorToInt(palette.shadow);

        // Occasional branch
        if (random.nextDouble() < 0.15) {
          var bx = cx;
          var by = cy;
          final branchDir = random.nextBool() ? 1 : -1;
          final branchLen = 2 + random.nextInt(4);
          for (int i = 0; i < branchLen; i++) {
            bx += branchDir;
            by += random.nextInt(2);
            if (bx >= 0 && bx < width && by >= 0 && by < height) {
              pixels[by * width + bx] = colorToInt(palette.shadow);
            }
          }
        }

        cy++;
        cx += random.nextInt(3) - 1;
      }
    }
  }
}

// ============================================================================
// IRREGULAR COBBLESTONE (Row 2, tile 1)
// ============================================================================

class IrregularCobblestoneTile extends StoneTileBase {
  final int stoneMinSize;
  final int stoneMaxSize;

  IrregularCobblestoneTile(
    super.id, {
    this.stoneMinSize = 2,
    this.stoneMaxSize = 4,
  });

  @override
  String get name => 'Irregular Cobblestone';

  @override
  String get description => 'Rough, irregular cobblestone surface';

  @override
  String get iconName => 'grain';

  @override
  TilePalette get palette => StoneTilePalettes.darkStone;

  @override
  List<String> get tags => ['stone', 'cobblestone', 'floor', 'irregular', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate stones
    final cellSize = 3;
    for (int cy = 0; cy < height; cy += cellSize) {
      for (int cx = 0; cx < width; cx += cellSize) {
        final stoneX = cx + random.nextInt(2);
        final stoneY = cy + random.nextInt(2);
        final stoneW = stoneMinSize + random.nextInt(stoneMaxSize - stoneMinSize + 1);
        final stoneH = stoneMinSize + random.nextInt(stoneMaxSize - stoneMinSize + 1);

        final colorChoice = random.nextInt(3);
        Color stoneColor;
        if (colorChoice == 0) {
          stoneColor = palette.primary;
        } else if (colorChoice == 1) {
          stoneColor = palette.secondary;
        } else {
          stoneColor = palette.colors[2];
        }

        for (int dy = 0; dy < stoneH; dy++) {
          for (int dx = 0; dx < stoneW; dx++) {
            final px = stoneX + dx;
            final py = stoneY + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              final isEdge = dx == 0 || dy == 0 || dx == stoneW - 1 || dy == stoneH - 1;
              if (isEdge && random.nextDouble() < 0.5) {
                pixels[py * width + px] = addNoise(palette.shadow, random, 0.05);
              } else {
                pixels[py * width + px] = addNoise(stoneColor, random, 0.05);
              }
            }
          }
        }
      }
    }

    // Add highlight specks
    final speckCount = (width * height * 0.02).round();
    for (int i = 0; i < speckCount; i++) {
      final sx = random.nextInt(width);
      final sy = random.nextInt(height);
      pixels[sy * width + sx] = colorToInt(palette.highlight);
    }

    return pixels;
  }
}

// ============================================================================
// VINE-COVERED STONE (Row 2, tile 2)
// ============================================================================

class VineCoveredStoneTile extends StoneTileBase {
  final double vineDensity;
  final bool addCracks;

  VineCoveredStoneTile(
    super.id, {
    this.vineDensity = 0.3,
    this.addCracks = true,
  });

  @override
  String get name => 'Vine-Covered Stone';

  @override
  String get description => 'Ancient stone with climbing vines';

  @override
  String get iconName => 'eco';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'vine', 'overgrown', 'ancient', 'dungeon', 'nature'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final vinePalette = StoneTilePalettes.vineGreen;

    // Base stone
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 4.0 + seed * 7, y / 4.0, 2);
        Color baseColor;
        if (noiseVal < 0.3) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.6) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add cracks
    if (addCracks) {
      final crackCount = random.nextInt(3) + 1;
      for (int c = 0; c < crackCount; c++) {
        var cx = random.nextInt(width);
        var cy = 0;
        while (cy < height) {
          if (cx >= 0 && cx < width) {
            pixels[cy * width + cx] = colorToInt(palette.shadow);
          }
          cy++;
          cx += random.nextInt(3) - 1;
        }
      }
    }

    // Draw vines
    final vineCount = (vineDensity * 3).round() + 1;
    for (int v = 0; v < vineCount; v++) {
      var vx = random.nextInt(width);
      final vineColor = random.nextBool() ? vinePalette.primary : vinePalette.secondary;

      for (int vy = 0; vy < height; vy++) {
        if (vx >= 0 && vx < width) {
          pixels[vy * width + vx] = colorToInt(vinePalette.shadow);

          // Add leaves
          if (random.nextDouble() < 0.4) {
            final leafDir = random.nextBool() ? 1 : -1;
            final leafX = vx + leafDir;
            if (leafX >= 0 && leafX < width) {
              pixels[vy * width + leafX] = colorToInt(vineColor);
            }
            if (random.nextDouble() < 0.5) {
              final leaf2X = vx + leafDir * 2;
              if (leaf2X >= 0 && leaf2X < width) {
                pixels[vy * width + leaf2X] = colorToInt(vinePalette.highlight);
              }
            }
          }
        }
        if (random.nextDouble() < 0.3) {
          vx += random.nextInt(3) - 1;
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ROUGH TEXTURED STONE (Row 2, tile 3)
// ============================================================================

class RoughTexturedStoneTile extends StoneTileBase {
  final double textureIntensity;

  RoughTexturedStoneTile(
    super.id, {
    this.textureIntensity = 0.15,
  });

  @override
  String get name => 'Rough Textured Stone';

  @override
  String get description => 'Rough, heavily textured stone surface';

  @override
  String get iconName => 'texture';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'rough', 'textured', 'dungeon'];

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
        final noise1 = noise2D(x / 3.0 + seed * 5, y / 3.0, 3);
        final noise2 = noise2D(x / 1.5 + seed * 8, y / 1.5, 2);
        final combined = (noise1 * 0.6 + noise2 * 0.4);

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

        pixels[y * width + x] = addNoise(baseColor, random, textureIntensity);
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE-BRICK TRANSITION (Row 2, tile 4)
// ============================================================================

class StoneBrickTransitionTile extends StoneTileBase {
  final double transitionPoint;

  StoneBrickTransitionTile(
    super.id, {
    this.transitionPoint = 0.5,
  });

  @override
  String get name => 'Stone-Brick Transition';

  @override
  String get description => 'Stone base transitioning to brick';

  @override
  String get iconName => 'swap_vert';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'brick', 'transition', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickPalette = StoneTilePalettes.warmBrick;
    final transitionY = (height * transitionPoint).round();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (y < transitionY) {
          // Brick on top
          final brickHeight = 4;
          final brickWidth = 6;
          final row = y ~/ brickHeight;
          final offset = row % 2 == 1 ? brickWidth ~/ 2 : 0;
          final adjustedX = (x + offset) % width;

          final isHMortar = y % brickHeight == 0;
          final isVMortar = adjustedX % brickWidth == 0;

          if (isHMortar || isVMortar) {
            pixels[y * width + x] = colorToInt(palette.shadow);
          } else {
            final brickColor = random.nextBool() ? brickPalette.primary : brickPalette.secondary;
            pixels[y * width + x] = addNoise(brickColor, random, 0.05);
          }
        } else {
          // Stone below
          final noiseVal = noise2D(x / 4.0 + seed * 6, y / 4.0, 2);
          Color stoneColor;
          if (noiseVal < 0.4) {
            stoneColor = palette.shadow;
          } else if (noiseVal < 0.7) {
            stoneColor = palette.primary;
          } else {
            stoneColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(stoneColor, random, 0.04);
        }
      }
    }

    // Irregular transition line
    for (int x = 0; x < width; x++) {
      final ty = transitionY + random.nextInt(3) - 1;
      if (ty >= 0 && ty < height) {
        pixels[ty * width + x] = colorToInt(palette.shadow);
      }
    }

    return pixels;
  }
}

// ============================================================================
// VERTICAL STONE COLUMN (Row 3, tile 1)
// ============================================================================

class VerticalStoneColumnTile extends StoneTileBase {
  final int columnWidth;
  final bool addDetail;

  VerticalStoneColumnTile(
    super.id, {
    this.columnWidth = 4,
    this.addDetail = true,
  });

  @override
  String get name => 'Vertical Stone Column';

  @override
  String get description => 'Vertical stone column pattern';

  @override
  String get iconName => 'view_column';

  @override
  TilePalette get palette => StoneTilePalettes.darkStone;

  @override
  List<String> get tags => ['stone', 'column', 'vertical', 'pillar', 'dungeon'];

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
        final col = x ~/ columnWidth;
        final isVerticalGap = x % columnWidth == 0;

        if (isVerticalGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final colColorIndex = (col + seed) % 2;
          Color baseColor;
          if (colColorIndex == 0) {
            baseColor = palette.primary;
          } else {
            baseColor = palette.secondary;
          }

          final striation = noise2D(x / 2.0, y / 6.0 + seed * 5, 2);
          if (striation > 0.75) {
            baseColor = palette.highlight;
          } else if (striation < 0.2) {
            baseColor = palette.shadow;
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    // Horizontal breaks
    if (addDetail) {
      final breakCount = random.nextInt(2) + 1;
      for (int b = 0; b < breakCount; b++) {
        final by = random.nextInt(height);
        for (int x = 0; x < width; x++) {
          if (random.nextDouble() < 0.7) {
            pixels[by * width + x] = colorToInt(palette.shadow);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE WITH GRASS TOP (Row 3, tile 4)
// ============================================================================

class StoneWithGrassTopTile extends StoneTileBase {
  final int grassHeight;

  StoneWithGrassTopTile(
    super.id, {
    this.grassHeight = 4,
  });

  @override
  String get name => 'Stone with Grass Top';

  @override
  String get description => 'Stone wall with grass growing on top';

  @override
  String get iconName => 'grass';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'grass', 'nature', 'transition', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final grassPalette = StoneTilePalettes.grassAccent;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (y < grassHeight) {
          final grassNoise = noise2D(x / 2.0 + seed * 4, y / 2.0, 2);
          final bladeHeight = grassHeight - (x % 3);
          if (y < bladeHeight && grassNoise > 0.3) {
            final grassColor = grassNoise > 0.6 ? grassPalette.highlight : grassPalette.primary;
            pixels[y * width + x] = addNoise(grassColor, random, 0.05);
          } else if (y == grassHeight - 1) {
            pixels[y * width + x] = colorToInt(grassPalette.shadow);
          } else {
            pixels[y * width + x] = addNoise(palette.primary, random, 0.04);
          }
        } else {
          final noiseVal = noise2D(x / 4.0 + seed * 6, y / 4.0, 2);
          Color stoneColor;
          if (noiseVal < 0.35) {
            stoneColor = palette.shadow;
          } else if (noiseVal < 0.65) {
            stoneColor = palette.primary;
          } else {
            stoneColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(stoneColor, random, 0.04);
        }
      }
    }

    // Hanging grass blades
    for (int x = 0; x < width; x++) {
      if (random.nextDouble() < 0.4) {
        final bladeLen = random.nextInt(3) + 1;
        for (int dy = 0; dy < bladeLen; dy++) {
          final py = grassHeight + dy;
          if (py < height) {
            pixels[py * width + x] = colorToInt(grassPalette.primary);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ORNATE STONE BLOCK (Row 3, tile 3)
// ============================================================================

class OrnateStoneBlockTile extends StoneTileBase {
  final int borderWidth;

  OrnateStoneBlockTile(
    super.id, {
    this.borderWidth = 2,
  });

  @override
  String get name => 'Ornate Stone Block';

  @override
  String get description => 'Decorative carved stone block';

  @override
  String get iconName => 'crop_square';

  @override
  TilePalette get palette => StoneTilePalettes.darkStone;

  @override
  List<String> get tags => ['stone', 'ornate', 'decorative', 'carved', 'dungeon'];

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
        final distFromLeft = x;
        final distFromRight = width - 1 - x;
        final distFromTop = y;
        final distFromBottom = height - 1 - y;
        final minDist = [distFromLeft, distFromRight, distFromTop, distFromBottom].reduce(min);

        if (minDist < borderWidth) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else if (minDist < borderWidth * 2) {
          pixels[y * width + x] = addNoise(palette.primary, random, 0.03);
        } else if (minDist < borderWidth * 3) {
          pixels[y * width + x] = addNoise(palette.secondary, random, 0.03);
        } else {
          final centerNoise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          if (centerNoise > 0.6) {
            pixels[y * width + x] = colorToInt(palette.highlight);
          } else {
            pixels[y * width + x] = addNoise(palette.primary, random, 0.04);
          }
        }
      }
    }

    // Corner accents
    final corners = [
      [borderWidth * 2, borderWidth * 2],
      [width - borderWidth * 2 - 1, borderWidth * 2],
      [borderWidth * 2, height - borderWidth * 2 - 1],
      [width - borderWidth * 2 - 1, height - borderWidth * 2 - 1],
    ];
    for (final pos in corners) {
      final cx = pos[0];
      final cy = pos[1];
      if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
        pixels[cy * width + cx] = colorToInt(palette.highlight);
      }
    }

    return pixels;
  }
}

// ============================================================================
// LARGE STONE BLOCKS (Row 3, tile 2)
// ============================================================================

class LargeStoneBlocksTile extends StoneTileBase {
  final int blockSize;

  LargeStoneBlocksTile(
    super.id, {
    this.blockSize = 8,
  });

  @override
  String get name => 'Large Stone Blocks';

  @override
  String get description => 'Large format stone block pattern';

  @override
  String get iconName => 'view_module';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'blocks', 'large', 'dungeon'];

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
        final blockX = x ~/ blockSize;
        final blockY = y ~/ blockSize;
        final isHGap = y % blockSize == 0;
        final isVGap = x % blockSize == 0;

        if (isHGap || isVGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final blockIdx = (blockX + blockY + seed) % 3;
          Color baseColor;
          if (blockIdx == 0) {
            baseColor = palette.primary;
          } else if (blockIdx == 1) {
            baseColor = palette.secondary;
          } else {
            baseColor = palette.colors[2];
          }

          final innerNoise = noise2D(x / 3.0, y / 3.0, 2);
          if (innerNoise > 0.8) {
            baseColor = palette.highlight;
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// DARK VERTICAL PLANKS (Row 4, tile 1)
// ============================================================================

class DarkVerticalPlanksTile extends StoneTileBase {
  final int plankWidth;

  DarkVerticalPlanksTile(
    super.id, {
    this.plankWidth = 4,
  });

  @override
  String get name => 'Dark Vertical Planks';

  @override
  String get description => 'Dark wooden vertical planks';

  @override
  String get iconName => 'view_week';

  @override
  TilePalette get palette => StoneTilePalettes.darkWood;

  @override
  TileCategory get category => TileCategory.structure;

  @override
  List<String> get tags => ['wood', 'planks', 'dark', 'vertical', 'dungeon'];

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
        final plankIndex = x ~/ plankWidth;
        final isGap = x % plankWidth == 0;

        if (isGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final grain = sin((y + plankIndex * 7) / 3.0 + seed);
          Color baseColor;
          if (grain < -0.3) {
            baseColor = palette.shadow;
          } else if (grain < 0.3) {
            baseColor = palette.primary;
          } else {
            baseColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    // Nail heads
    for (int px = plankWidth ~/ 2; px < width; px += plankWidth) {
      for (int py = 2; py < height; py += 6) {
        if (px < width && py < height) {
          pixels[py * width + px] = colorToInt(palette.shadow);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ICE FROST STONE (Row 4, tile 2)
// ============================================================================

class IceFrostStoneTile extends StoneTileBase {
  final double icicleChance;

  IceFrostStoneTile(
    super.id, {
    this.icicleChance = 0.3,
  });

  @override
  String get name => 'Ice Frost Stone';

  @override
  String get description => 'Stone with ice and frost';

  @override
  String get iconName => 'ac_unit';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'ice', 'frost', 'frozen', 'dungeon', 'winter'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final icePalette = StoneTilePalettes.frostBlue;

    // Base stone
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
        Color baseColor;
        if (noiseVal < 0.3) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.6) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Frost layer
    final frostHeight = 3;
    for (int y = 0; y < frostHeight; y++) {
      for (int x = 0; x < width; x++) {
        final frostNoise = noise2D(x / 2.0, y + seed.toDouble(), 2);
        if (frostNoise > 0.3) {
          final iceColor = frostNoise > 0.6 ? icePalette.highlight : icePalette.primary;
          pixels[y * width + x] = colorToInt(iceColor);
        }
      }
    }

    // Icicles
    for (int x = 0; x < width; x++) {
      if (random.nextDouble() < icicleChance) {
        final icicleLen = random.nextInt(height - frostHeight - 2) + 2;
        for (int dy = 0; dy < icicleLen; dy++) {
          final py = frostHeight + dy;
          if (py < height) {
            final alpha = 1.0 - (dy / icicleLen);
            if (random.nextDouble() < alpha) {
              final iceColor = dy < 2 ? icePalette.primary : icePalette.secondary;
              pixels[py * width + x] = colorToInt(iceColor);
            }
          }
        }
        final tipY = frostHeight + icicleLen - 1;
        if (tipY < height) {
          pixels[tipY * width + x] = colorToInt(icePalette.highlight);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// LARGE BRICK PATTERN (Row 4, tile 3)
// ============================================================================

class LargeBrickPatternTile extends StoneTileBase {
  final int brickWidth;
  final int brickHeight;

  LargeBrickPatternTile(
    super.id, {
    this.brickWidth = 8,
    this.brickHeight = 4,
  });

  @override
  String get name => 'Large Brick Pattern';

  @override
  String get description => 'Large format brick/block pattern';

  @override
  String get iconName => 'dashboard';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'brick', 'large', 'pattern', 'dungeon'];

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
          final brickCol = adjustedX ~/ brickWidth;
          final brickIdx = (row + brickCol + seed) % 4;

          Color baseColor;
          if (brickIdx == 0) {
            baseColor = palette.primary;
          } else if (brickIdx == 1) {
            baseColor = palette.secondary;
          } else if (brickIdx == 2) {
            baseColor = palette.colors[2];
          } else {
            baseColor = palette.primary;
          }

          final innerNoise = noise2D(x / 2.0, y / 2.0, 2);
          if (innerNoise > 0.8) {
            baseColor = palette.highlight;
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE WITH DOOR (Row 4, tile 4)
// ============================================================================

class StoneWithDoorTile extends StoneTileBase {
  final int doorWidth;

  StoneWithDoorTile(
    super.id, {
    this.doorWidth = 6,
  });

  @override
  String get name => 'Stone with Door';

  @override
  String get description => 'Stone wall with door frame';

  @override
  String get iconName => 'door_front';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'door', 'entrance', 'dungeon', 'structure'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final doorStart = (width - doorWidth) ~/ 2;
    final doorEnd = doorStart + doorWidth;
    final doorTop = 2;

    // Base stone wall
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final inDoorX = x >= doorStart && x < doorEnd;
        final inDoorY = y >= doorTop;

        if (inDoorX && inDoorY) {
          pixels[y * width + x] = colorToInt(const Color(0xFF1A1A1A));
        } else {
          final noiseVal = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
          Color stoneColor;
          if (noiseVal < 0.3) {
            stoneColor = palette.shadow;
          } else if (noiseVal < 0.6) {
            stoneColor = palette.primary;
          } else {
            stoneColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(stoneColor, random, 0.04);
        }
      }
    }

    // Door frame
    for (int y = doorTop; y < height; y++) {
      if (doorStart - 1 >= 0) {
        pixels[y * width + (doorStart - 1)] = colorToInt(palette.shadow);
      }
    }
    for (int y = doorTop; y < height; y++) {
      if (doorEnd < width) {
        pixels[y * width + doorEnd] = colorToInt(palette.shadow);
      }
    }
    for (int x = doorStart - 1; x <= doorEnd && x < width; x++) {
      if (x >= 0 && doorTop - 1 >= 0) {
        pixels[(doorTop - 1) * width + x] = colorToInt(palette.shadow);
      }
    }

    // Arch detail
    if (doorTop > 0) {
      final archMid = doorStart + doorWidth ~/ 2;
      if (archMid >= 0 && archMid < width) {
        pixels[(doorTop - 1) * width + archMid] = colorToInt(palette.highlight);
      }
    }

    return pixels;
  }
}

// ============================================================================
// ADDITIONAL STONE VARIANTS
// ============================================================================

class CrackedStoneFloorTile extends StoneTileBase {
  CrackedStoneFloorTile(super.id);

  @override
  String get name => 'Cracked Stone Floor';

  @override
  String get description => 'Stone floor with cracks';

  @override
  String get iconName => 'broken_image';

  @override
  TilePalette get palette => StoneTilePalettes.darkStone;

  @override
  List<String> get tags => ['stone', 'floor', 'cracked', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base stone
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 4.0 + seed * 3, y / 4.0, 2);
        Color baseColor;
        if (noiseVal < 0.4) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Multiple cracks
    final crackCount = random.nextInt(3) + 2;
    for (int c = 0; c < crackCount; c++) {
      var cx = random.nextInt(width);
      var cy = random.nextInt(height);
      final crackLen = random.nextInt(10) + 5;

      for (int i = 0; i < crackLen; i++) {
        if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
          pixels[cy * width + cx] = colorToInt(palette.shadow);
        }
        cx += random.nextInt(3) - 1;
        cy += random.nextInt(3) - 1;
      }
    }

    return pixels;
  }
}

class MossyDungeonWallTile extends StoneTileBase {
  MossyDungeonWallTile(super.id);

  @override
  String get name => 'Mossy Dungeon Wall';

  @override
  String get description => 'Dungeon wall covered in moss';

  @override
  String get iconName => 'spa';

  @override
  TilePalette get palette => StoneTilePalettes.darkStone;

  @override
  List<String> get tags => ['stone', 'moss', 'dungeon', 'wall', 'overgrown'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final mossPalette = StoneTilePalettes.vineGreen;

    // Base stone
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 4.0 + seed * 4, y / 4.0, 2);
        final mossNoise = noise2D(x / 3.0 + seed * 2, y / 3.0, 3);

        Color baseColor;
        if (mossNoise > 0.6) {
          // Mossy area
          baseColor = mossNoise > 0.8 ? mossPalette.highlight : mossPalette.primary;
        } else if (noiseVal < 0.35) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.65) {
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

class AncientRuinStoneTile extends StoneTileBase {
  AncientRuinStoneTile(super.id);

  @override
  String get name => 'Ancient Ruin Stone';

  @override
  String get description => 'Weathered ancient ruin stone';

  @override
  String get iconName => 'account_balance';

  @override
  TilePalette get palette => StoneTilePalettes.grayStone;

  @override
  List<String> get tags => ['stone', 'ancient', 'ruin', 'weathered', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Weathered stone base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise1 = noise2D(x / 3.0 + seed * 5, y / 3.0, 3);
        final noise2 = noise2D(x / 6.0 + seed * 2, y / 6.0, 2);
        final combined = noise1 * 0.7 + noise2 * 0.3;

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

    // Add worn edges/chips
    final chipCount = (width * height * 0.03).round();
    for (int i = 0; i < chipCount; i++) {
      final cx = random.nextInt(width);
      final cy = random.nextInt(height);
      pixels[cy * width + cx] = colorToInt(palette.shadow);
    }

    return pixels;
  }
}

class CarvedStoneTileTile extends StoneTileBase {
  CarvedStoneTileTile(super.id);

  @override
  String get name => 'Carved Stone Tile';

  @override
  String get description => 'Decorative carved stone tile';

  @override
  String get iconName => 'format_shapes';

  @override
  TilePalette get palette => StoneTilePalettes.darkStone;

  @override
  List<String> get tags => ['stone', 'carved', 'decorative', 'tile', 'dungeon'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Border
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isBorder = x == 0 || y == 0 || x == width - 1 || y == height - 1;
        final isInnerBorder = x == 1 || y == 1 || x == width - 2 || y == height - 2;

        if (isBorder) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else if (isInnerBorder) {
          pixels[y * width + x] = colorToInt(palette.highlight);
        } else {
          // Inner pattern
          final patternX = (x - 2) % 4;
          final patternY = (y - 2) % 4;
          final isPatternCenter = patternX == 1 || patternX == 2 || patternY == 1 || patternY == 2;

          if (isPatternCenter) {
            pixels[y * width + x] = addNoise(palette.primary, random, 0.03);
          } else {
            pixels[y * width + x] = addNoise(palette.secondary, random, 0.03);
          }
        }
      }
    }

    return pixels;
  }
}
