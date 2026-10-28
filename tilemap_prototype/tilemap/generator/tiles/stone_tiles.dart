import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_generator_config.dart';
import '../tile_palette.dart';

// ============================================================================
// STONE TILE PALETTES
// ============================================================================

/// Extended stone palettes for the new tile types
class StoneTilePalettes {
  StoneTilePalettes._();

  /// Standard gray stone
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

  /// Dark stone for dungeons
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

  /// Vine/moss green for overgrown
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

  /// Ice/frost blue
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

  /// Warm brown brick
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

  /// Dark wood for planks
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

  /// Grass accent for transitions
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
// HORIZONTAL STONE BRICK TILES (Row 1 of image)
// ============================================================================

/// Horizontal stone brick pattern - the most common wall type
class HorizontalStoneBrickConfig extends TerrainTileConfig {
  final int brickHeight;
  final bool addWear;
  final double wearIntensity;

  HorizontalStoneBrickConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.brickHeight = 4,
    this.addWear = false,
    this.wearIntensity = 0.1,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Horizontal Stone Brick';

  @override
  String get description => 'Horizontal layered stone brick wall';

  @override
  String get iconName => 'view_stream';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final row = y ~/ brickHeight;
        final isHorizontalMortar = y % brickHeight == 0;

        if (isHorizontalMortar) {
          pixels[y * tileWidth + x] = colorToInt(palette.shadow);
        } else {
          // Alternate between colors for each row
          final rowColorIndex = (row + variantIndex) % 3;
          Color baseColor;
          if (rowColorIndex == 0) {
            baseColor = palette.primary;
          } else if (rowColorIndex == 1) {
            baseColor = palette.secondary;
          } else {
            baseColor = palette.colors[2];
          }

          // Add subtle horizontal striations
          final striation = noise2D(x / 8.0, y / 2.0 + variantIndex * 10, random, 2);
          if (striation > 0.7) {
            baseColor = palette.highlight;
          } else if (striation < 0.2) {
            baseColor = palette.shadow;
          }

          pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    // Add wear/damage spots
    if (addWear) {
      final wearCount = (tileWidth * tileHeight * wearIntensity).round();
      for (int i = 0; i < wearCount; i++) {
        final wx = random.nextInt(tileWidth);
        final wy = random.nextInt(tileHeight);
        if (random.nextBool()) {
          pixels[wy * tileWidth + wx] = colorToInt(palette.shadow);
        } else {
          pixels[wy * tileWidth + wx] = colorToInt(palette.highlight);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// COBBLESTONE TILES (Row 2, first tile)
// ============================================================================

/// Irregular cobblestone pattern
class IrregularCobblestoneConfig extends TerrainTileConfig {
  final int stoneMinSize;
  final int stoneMaxSize;

  IrregularCobblestoneConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.stoneMinSize = 2,
    this.stoneMaxSize = 4,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.darkStone);

  @override
  String get name => 'Irregular Cobblestone';

  @override
  String get description => 'Rough, irregular cobblestone surface';

  @override
  String get iconName => 'grain';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    // Fill with mortar/dark base
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate irregular stones using cell-based approach
    final cellSize = 3;
    for (int cy = 0; cy < tileHeight; cy += cellSize) {
      for (int cx = 0; cx < tileWidth; cx += cellSize) {
        // Randomize stone position within cell
        final stoneX = cx + random.nextInt(2);
        final stoneY = cy + random.nextInt(2);
        final stoneW = stoneMinSize + random.nextInt(stoneMaxSize - stoneMinSize + 1);
        final stoneH = stoneMinSize + random.nextInt(stoneMaxSize - stoneMinSize + 1);

        // Choose stone color
        final colorChoice = random.nextInt(3);
        Color stoneColor;
        if (colorChoice == 0) {
          stoneColor = palette.primary;
        } else if (colorChoice == 1) {
          stoneColor = palette.secondary;
        } else {
          stoneColor = palette.colors[2];
        }

        // Draw the stone
        for (int dy = 0; dy < stoneH; dy++) {
          for (int dx = 0; dx < stoneW; dx++) {
            final px = stoneX + dx;
            final py = stoneY + dy;
            if (px >= 0 && px < tileWidth && py >= 0 && py < tileHeight) {
              // Add edge darkening
              final isEdge = dx == 0 || dy == 0 || dx == stoneW - 1 || dy == stoneH - 1;
              if (isEdge && random.nextDouble() < 0.5) {
                pixels[py * tileWidth + px] = addNoise(palette.shadow, random, 0.05);
              } else {
                pixels[py * tileWidth + px] = addNoise(stoneColor, random, 0.05);
              }
            }
          }
        }
      }
    }

    // Add some highlight specks
    final speckCount = (tileWidth * tileHeight * 0.02).round();
    for (int i = 0; i < speckCount; i++) {
      final sx = random.nextInt(tileWidth);
      final sy = random.nextInt(tileHeight);
      pixels[sy * tileWidth + sx] = colorToInt(palette.highlight);
    }

    return pixels;
  }
}

// ============================================================================
// VINE-COVERED STONE (Row 2, second tile)
// ============================================================================

/// Stone wall with climbing vines
class VineCoveredStoneConfig extends TerrainTileConfig {
  final double vineDensity;
  final bool addCracks;

  VineCoveredStoneConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.vineDensity = 0.3,
    this.addCracks = true,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Vine-Covered Stone';

  @override
  String get description => 'Ancient stone with climbing vines';

  @override
  String get iconName => 'eco';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);
    final vinePalette = StoneTilePalettes.vineGreen;

    // Generate base stone pattern
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseVal = noise2D(x / 4.0 + variantIndex * 7, y / 4.0, random, 2);
        Color baseColor;
        if (noiseVal < 0.3) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.6) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add cracks
    if (addCracks) {
      final crackCount = random.nextInt(3) + 1;
      for (int c = 0; c < crackCount; c++) {
        var cx = random.nextInt(tileWidth);
        var cy = 0;
        while (cy < tileHeight) {
          if (cx >= 0 && cx < tileWidth) {
            pixels[cy * tileWidth + cx] = colorToInt(palette.shadow);
          }
          cy++;
          cx += random.nextInt(3) - 1;
        }
      }
    }

    // Draw climbing vines
    final vineCount = (vineDensity * 3).round() + 1;
    for (int v = 0; v < vineCount; v++) {
      var vx = random.nextInt(tileWidth);
      final vineColor = random.nextBool() ? vinePalette.primary : vinePalette.secondary;

      for (int vy = 0; vy < tileHeight; vy++) {
        // Main vine stem
        if (vx >= 0 && vx < tileWidth) {
          pixels[vy * tileWidth + vx] = colorToInt(vinePalette.shadow);

          // Add leaves/branches
          if (random.nextDouble() < 0.4) {
            final leafDir = random.nextBool() ? 1 : -1;
            final leafX = vx + leafDir;
            if (leafX >= 0 && leafX < tileWidth) {
              pixels[vy * tileWidth + leafX] = colorToInt(vineColor);
            }
            // Second leaf pixel
            if (random.nextDouble() < 0.5) {
              final leaf2X = vx + leafDir * 2;
              if (leaf2X >= 0 && leaf2X < tileWidth) {
                pixels[vy * tileWidth + leaf2X] = colorToInt(vinePalette.highlight);
              }
            }
          }
        }

        // Vine meanders
        if (random.nextDouble() < 0.3) {
          vx += random.nextInt(3) - 1;
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ROUGH/TEXTURED STONE (Row 2, third tile)
// ============================================================================

/// Rough textured stone surface
class RoughStoneConfig extends TerrainTileConfig {
  final double textureIntensity;

  RoughStoneConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.textureIntensity = 0.15,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Rough Stone';

  @override
  String get description => 'Rough, heavily textured stone';

  @override
  String get iconName => 'texture';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        // Multi-octave noise for rough texture
        final noise1 = noise2D(x / 3.0 + variantIndex * 5, y / 3.0, random, 3);
        final noise2 = noise2D(x / 1.5 + variantIndex * 8, y / 1.5, random, 2);
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

        pixels[y * tileWidth + x] = addNoise(baseColor, random, textureIntensity);
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE TO BRICK TRANSITION (Row 2, fourth tile)
// ============================================================================

/// Transition tile from stone base to brick top
class StoneBrickTransitionConfig extends TerrainTileConfig {
  final double transitionPoint; // 0.0 to 1.0, where transition occurs

  StoneBrickTransitionConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.transitionPoint = 0.5,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Stone-Brick Transition';

  @override
  String get description => 'Stone base transitioning to brick';

  @override
  String get iconName => 'swap_vert';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);
    final brickPalette = StoneTilePalettes.warmBrick;
    final transitionY = (tileHeight * transitionPoint).round();

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        if (y < transitionY) {
          // Brick pattern on top
          final brickHeight = 4;
          final brickWidth = 6;
          final row = y ~/ brickHeight;
          final offset = row % 2 == 1 ? brickWidth ~/ 2 : 0;
          final adjustedX = (x + offset) % tileWidth;

          final isHMortar = y % brickHeight == 0;
          final isVMortar = adjustedX % brickWidth == 0;

          if (isHMortar || isVMortar) {
            pixels[y * tileWidth + x] = colorToInt(palette.shadow);
          } else {
            final brickColor = random.nextBool() ? brickPalette.primary : brickPalette.secondary;
            pixels[y * tileWidth + x] = addNoise(brickColor, random, 0.05);
          }
        } else {
          // Stone pattern on bottom
          final noiseVal = noise2D(x / 4.0 + variantIndex * 6, y / 4.0, random, 2);
          Color stoneColor;
          if (noiseVal < 0.4) {
            stoneColor = palette.shadow;
          } else if (noiseVal < 0.7) {
            stoneColor = palette.primary;
          } else {
            stoneColor = palette.secondary;
          }
          pixels[y * tileWidth + x] = addNoise(stoneColor, random, 0.04);
        }
      }
    }

    // Add irregular transition line
    for (int x = 0; x < tileWidth; x++) {
      final ty = transitionY + random.nextInt(3) - 1;
      if (ty >= 0 && ty < tileHeight) {
        pixels[ty * tileWidth + x] = colorToInt(palette.shadow);
      }
    }

    return pixels;
  }
}

// ============================================================================
// VERTICAL STONE COLUMNS (Row 3, first tile)
// ============================================================================

/// Vertical stone column pattern
class VerticalStoneColumnConfig extends TerrainTileConfig {
  final int columnWidth;
  final bool addDetail;

  VerticalStoneColumnConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.columnWidth = 4,
    this.addDetail = true,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.darkStone);

  @override
  String get name => 'Vertical Stone Column';

  @override
  String get description => 'Vertical stone column pattern';

  @override
  String get iconName => 'view_column';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final col = x ~/ columnWidth;
        final isVerticalGap = x % columnWidth == 0;

        if (isVerticalGap) {
          pixels[y * tileWidth + x] = colorToInt(palette.shadow);
        } else {
          // Alternate column colors
          final colColorIndex = (col + variantIndex) % 2;
          Color baseColor;
          if (colColorIndex == 0) {
            baseColor = palette.primary;
          } else {
            baseColor = palette.secondary;
          }

          // Add vertical striations
          final striation = noise2D(x / 2.0, y / 6.0 + variantIndex * 5, random, 2);
          if (striation > 0.75) {
            baseColor = palette.highlight;
          } else if (striation < 0.2) {
            baseColor = palette.shadow;
          }

          pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    // Add horizontal breaks
    if (addDetail) {
      final breakCount = random.nextInt(2) + 1;
      for (int b = 0; b < breakCount; b++) {
        final by = random.nextInt(tileHeight);
        for (int x = 0; x < tileWidth; x++) {
          if (random.nextDouble() < 0.7) {
            pixels[by * tileWidth + x] = colorToInt(palette.shadow);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE WITH GRASS TOP (Row 3, fourth tile)
// ============================================================================

/// Stone wall with grass growing on top
class StoneWithGrassTopConfig extends TerrainTileConfig {
  final int grassHeight;

  StoneWithGrassTopConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.grassHeight = 4,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Stone with Grass Top';

  @override
  String get description => 'Stone wall with grass growing on top';

  @override
  String get iconName => 'grass';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);
    final grassPalette = StoneTilePalettes.grassAccent;

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        if (y < grassHeight) {
          // Grass on top with drooping blades
          final grassNoise = noise2D(x / 2.0 + variantIndex * 4, y / 2.0, random, 2);

          // Create grass blade effect
          final bladeHeight = grassHeight - (x % 3); // Varying heights
          if (y < bladeHeight && grassNoise > 0.3) {
            final grassColor = grassNoise > 0.6 ? grassPalette.highlight : grassPalette.primary;
            pixels[y * tileWidth + x] = addNoise(grassColor, random, 0.05);
          } else if (y == grassHeight - 1) {
            // Grass/dirt border
            pixels[y * tileWidth + x] = colorToInt(grassPalette.shadow);
          } else {
            // Some stone showing through
            pixels[y * tileWidth + x] = addNoise(palette.primary, random, 0.04);
          }
        } else {
          // Stone below
          final noiseVal = noise2D(x / 4.0 + variantIndex * 6, y / 4.0, random, 2);
          Color stoneColor;
          if (noiseVal < 0.35) {
            stoneColor = palette.shadow;
          } else if (noiseVal < 0.65) {
            stoneColor = palette.primary;
          } else {
            stoneColor = palette.secondary;
          }
          pixels[y * tileWidth + x] = addNoise(stoneColor, random, 0.04);
        }
      }
    }

    // Add hanging grass blades
    for (int x = 0; x < tileWidth; x++) {
      if (random.nextDouble() < 0.4) {
        final bladeLen = random.nextInt(3) + 1;
        for (int dy = 0; dy < bladeLen; dy++) {
          final py = grassHeight + dy;
          if (py < tileHeight) {
            pixels[py * tileWidth + x] = colorToInt(grassPalette.primary);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ORNATE STONE BLOCK (Row 3, third tile)
// ============================================================================

/// Ornate carved stone block with border pattern
class OrnateStoneBlockConfig extends TerrainTileConfig {
  final int borderWidth;

  OrnateStoneBlockConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.borderWidth = 2,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.darkStone);

  @override
  String get name => 'Ornate Stone Block';

  @override
  String get description => 'Decorative carved stone block';

  @override
  String get iconName => 'crop_square';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        // Calculate distance from edges
        final distFromLeft = x;
        final distFromRight = tileWidth - 1 - x;
        final distFromTop = y;
        final distFromBottom = tileHeight - 1 - y;
        final minDist = [distFromLeft, distFromRight, distFromTop, distFromBottom].reduce(min);

        if (minDist < borderWidth) {
          // Outer border - darker
          pixels[y * tileWidth + x] = colorToInt(palette.shadow);
        } else if (minDist < borderWidth * 2) {
          // Middle border - medium
          pixels[y * tileWidth + x] = addNoise(palette.primary, random, 0.03);
        } else if (minDist < borderWidth * 3) {
          // Inner border - lighter
          pixels[y * tileWidth + x] = addNoise(palette.secondary, random, 0.03);
        } else {
          // Center - with subtle pattern
          final centerNoise = noise2D(x / 3.0 + variantIndex, y / 3.0, random, 2);
          if (centerNoise > 0.6) {
            pixels[y * tileWidth + x] = colorToInt(palette.highlight);
          } else {
            pixels[y * tileWidth + x] = addNoise(palette.primary, random, 0.04);
          }
        }
      }
    }

    // Add corner accents
    final cornerPositions = [
      [borderWidth * 2, borderWidth * 2],
      [tileWidth - borderWidth * 2 - 1, borderWidth * 2],
      [borderWidth * 2, tileHeight - borderWidth * 2 - 1],
      [tileWidth - borderWidth * 2 - 1, tileHeight - borderWidth * 2 - 1],
    ];

    for (final pos in cornerPositions) {
      final cx = pos[0];
      final cy = pos[1];
      if (cx >= 0 && cx < tileWidth && cy >= 0 && cy < tileHeight) {
        pixels[cy * tileWidth + cx] = colorToInt(palette.highlight);
      }
    }

    return pixels;
  }
}

// ============================================================================
// DARK VERTICAL PLANKS (Row 4, first tile)
// ============================================================================

/// Dark wooden vertical planks
class DarkVerticalPlanksConfig extends TerrainTileConfig {
  final int plankWidth;

  DarkVerticalPlanksConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.plankWidth = 4,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.darkWood);

  @override
  String get name => 'Dark Vertical Planks';

  @override
  String get description => 'Dark wooden vertical planks';

  @override
  String get iconName => 'view_week';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final plankIndex = x ~/ plankWidth;
        final isGap = x % plankWidth == 0;

        if (isGap) {
          pixels[y * tileWidth + x] = colorToInt(palette.shadow);
        } else {
          // Wood grain - vertical
          final grain = sin((y + plankIndex * 7) / 3.0 + variantIndex);
          Color baseColor;
          if (grain < -0.3) {
            baseColor = palette.shadow;
          } else if (grain < 0.3) {
            baseColor = palette.primary;
          } else {
            baseColor = palette.secondary;
          }
          pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    // Add nail heads
    for (int px = plankWidth ~/ 2; px < tileWidth; px += plankWidth) {
      for (int py = 2; py < tileHeight; py += 6) {
        if (px < tileWidth && py < tileHeight) {
          pixels[py * tileWidth + px] = colorToInt(palette.shadow);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ICE/FROST STONE (Row 4, second tile)
// ============================================================================

/// Stone with ice/frost dripping effect
class IceFrostStoneConfig extends TerrainTileConfig {
  final double icicleChance;

  IceFrostStoneConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.icicleChance = 0.3,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Ice Frost Stone';

  @override
  String get description => 'Stone with ice and frost';

  @override
  String get iconName => 'ac_unit';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);
    final icePalette = StoneTilePalettes.frostBlue;

    // Generate base stone
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseVal = noise2D(x / 4.0 + variantIndex * 5, y / 4.0, random, 2);
        Color baseColor;
        if (noiseVal < 0.3) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.6) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add frost layer at top
    final frostHeight = 3;
    for (int y = 0; y < frostHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final frostNoise = noise2D(x / 2.0, y + variantIndex.toDouble(), random, 2);
        if (frostNoise > 0.3) {
          final iceColor = frostNoise > 0.6 ? icePalette.highlight : icePalette.primary;
          pixels[y * tileWidth + x] = colorToInt(iceColor);
        }
      }
    }

    // Add icicles dripping down
    for (int x = 0; x < tileWidth; x++) {
      if (random.nextDouble() < icicleChance) {
        final icicleLen = random.nextInt(tileHeight - frostHeight - 2) + 2;
        for (int dy = 0; dy < icicleLen; dy++) {
          final py = frostHeight + dy;
          if (py < tileHeight) {
            // Icicle gets thinner at bottom
            final alpha = 1.0 - (dy / icicleLen);
            if (random.nextDouble() < alpha) {
              final iceColor = dy < 2 ? icePalette.primary : icePalette.secondary;
              pixels[py * tileWidth + x] = colorToInt(iceColor);
            }
          }
        }
        // Add highlight at tip
        final tipY = frostHeight + icicleLen - 1;
        if (tipY < tileHeight) {
          pixels[tipY * tileWidth + x] = colorToInt(icePalette.highlight);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// LARGE BRICK PATTERN (Row 4, third tile)
// ============================================================================

/// Large format brick pattern
class LargeBrickPatternConfig extends TerrainTileConfig {
  final int brickWidth;
  final int brickHeight;

  LargeBrickPatternConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.brickWidth = 8,
    this.brickHeight = 4,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Large Brick Pattern';

  @override
  String get description => 'Large format brick/block pattern';

  @override
  String get iconName => 'dashboard';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final row = y ~/ brickHeight;
        final offset = row % 2 == 1 ? brickWidth ~/ 2 : 0;
        final adjustedX = (x + offset) % tileWidth;

        final isHMortar = y % brickHeight == 0;
        final isVMortar = adjustedX % brickWidth == 0;

        if (isHMortar || isVMortar) {
          pixels[y * tileWidth + x] = colorToInt(palette.shadow);
        } else {
          // Calculate brick index for color variation
          final brickCol = adjustedX ~/ brickWidth;
          final brickIdx = (row + brickCol + variantIndex) % 4;

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

          // Add subtle texture within brick
          final innerNoise = noise2D(x / 2.0, y / 2.0, random, 2);
          if (innerNoise > 0.8) {
            baseColor = palette.highlight;
          }

          pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// STONE WITH DOOR (Row 4, fourth tile)
// ============================================================================

/// Stone wall segment with door/gate frame
class StoneWithDoorConfig extends TerrainTileConfig {
  final int doorWidth;

  StoneWithDoorConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.doorWidth = 6,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? StoneTilePalettes.grayStone);

  @override
  String get name => 'Stone with Door';

  @override
  String get description => 'Stone wall with door frame';

  @override
  String get iconName => 'door_front';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);
    final doorStart = (tileWidth - doorWidth) ~/ 2;
    final doorEnd = doorStart + doorWidth;
    final doorTop = 2;

    // Generate base stone wall
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        // Check if in door area
        final inDoorX = x >= doorStart && x < doorEnd;
        final inDoorY = y >= doorTop;

        if (inDoorX && inDoorY) {
          // Dark door interior
          pixels[y * tileWidth + x] = colorToInt(const Color(0xFF1A1A1A));
        } else {
          // Stone wall
          final noiseVal = noise2D(x / 4.0 + variantIndex * 5, y / 4.0, random, 2);
          Color stoneColor;
          if (noiseVal < 0.3) {
            stoneColor = palette.shadow;
          } else if (noiseVal < 0.6) {
            stoneColor = palette.primary;
          } else {
            stoneColor = palette.secondary;
          }
          pixels[y * tileWidth + x] = addNoise(stoneColor, random, 0.04);
        }
      }
    }

    // Draw door frame
    // Left frame
    for (int y = doorTop; y < tileHeight; y++) {
      if (doorStart - 1 >= 0) {
        pixels[y * tileWidth + (doorStart - 1)] = colorToInt(palette.shadow);
      }
    }
    // Right frame
    for (int y = doorTop; y < tileHeight; y++) {
      if (doorEnd < tileWidth) {
        pixels[y * tileWidth + doorEnd] = colorToInt(palette.shadow);
      }
    }
    // Top frame
    for (int x = doorStart - 1; x <= doorEnd && x < tileWidth; x++) {
      if (x >= 0 && doorTop - 1 >= 0) {
        pixels[(doorTop - 1) * tileWidth + x] = colorToInt(palette.shadow);
      }
    }

    // Add arch detail at top of door
    if (doorTop > 0) {
      final archMid = doorStart + doorWidth ~/ 2;
      if (archMid >= 0 && archMid < tileWidth) {
        pixels[(doorTop - 1) * tileWidth + archMid] = colorToInt(palette.highlight);
      }
    }

    return pixels;
  }
}

// ============================================================================
// REGISTRY EXTENSION
// ============================================================================

/// Extension to add stone tiles to the registry
extension StoneTileRegistration on Map<String, dynamic> {
  void registerStoneTiles() {
    // Add all the new stone tile types
    this['horizontal_stone_brick'] = () => HorizontalStoneBrickConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['horizontal_stone_brick_worn'] = () => HorizontalStoneBrickConfig(
          tileWidth: 16,
          tileHeight: 16,
          addWear: true,
          wearIntensity: 0.15,
        );
    this['irregular_cobblestone'] = () => IrregularCobblestoneConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['vine_covered_stone'] = () => VineCoveredStoneConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['rough_stone'] = () => RoughStoneConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['stone_brick_transition'] = () => StoneBrickTransitionConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['vertical_stone_column'] = () => VerticalStoneColumnConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['stone_grass_top'] = () => StoneWithGrassTopConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['ornate_stone_block'] = () => OrnateStoneBlockConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['dark_vertical_planks'] = () => DarkVerticalPlanksConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['ice_frost_stone'] = () => IceFrostStoneConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['large_brick_pattern'] = () => LargeBrickPatternConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
    this['stone_with_door'] = () => StoneWithDoorConfig(
          tileWidth: 16,
          tileHeight: 16,
        );
  }
}

// ============================================================================
// STONE TILE GENERATOR TYPE ENUM EXTENSION
// ============================================================================

/// Extended tile generator types for stone tiles
enum StoneTileGeneratorType {
  horizontalStoneBrick('Horizontal Stone Brick', 'Layered horizontal stone bricks'),
  horizontalStoneBrickWorn('Worn Stone Brick', 'Weathered horizontal stone bricks'),
  irregularCobblestone('Irregular Cobblestone', 'Rough irregular cobblestone'),
  vineCoveredStone('Vine-Covered Stone', 'Ancient stone with climbing vines'),
  roughStone('Rough Stone', 'Heavily textured rough stone'),
  stoneBrickTransition('Stone-Brick Transition', 'Stone transitioning to brick'),
  verticalStoneColumn('Vertical Stone Column', 'Vertical stone column pattern'),
  stoneGrassTop('Stone with Grass', 'Stone with grass growing on top'),
  ornateStoneBlock('Ornate Stone Block', 'Decorative carved stone block'),
  darkVerticalPlanks('Dark Planks', 'Dark wooden vertical planks'),
  iceFrostStone('Ice Frost Stone', 'Stone with ice and icicles'),
  largeBrickPattern('Large Brick Pattern', 'Large format brick blocks'),
  stoneWithDoor('Stone with Door', 'Stone wall with door frame');

  final String displayName;
  final String description;

  const StoneTileGeneratorType(this.displayName, this.description);
}
