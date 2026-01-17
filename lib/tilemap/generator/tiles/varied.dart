import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// COLORED ROOF TILE PALETTES
// ============================================================================

class ColoredRoofPalettes {
  ColoredRoofPalettes._();

  /// Red/terracotta roof tiles
  static const redRoof = TilePalette(
    name: 'Red Roof',
    colors: [
      Color(0xFF8B4A3A), // Base red-brown
      Color(0xFF9B5A4A), // Light
      Color(0xFF7B3A2A), // Dark
      Color(0xFFAB6A5A), // Highlight
      Color(0xFF5B2A1A), // Shadow
    ],
  );

  /// Orange roof tiles
  static const orangeRoof = TilePalette(
    name: 'Orange Roof',
    colors: [
      Color(0xFFB86A30), // Base orange
      Color(0xFFC87A40), // Light
      Color(0xFFA85A20), // Dark
      Color(0xFFD88A50), // Highlight
      Color(0xFF784010), // Shadow
    ],
  );

  /// Teal/cyan roof tiles
  static const tealRoof = TilePalette(
    name: 'Teal Roof',
    colors: [
      Color(0xFF2A5A5A), // Base teal
      Color(0xFF3A6A6A), // Light
      Color(0xFF1A4A4A), // Dark
      Color(0xFF4A7A7A), // Highlight
      Color(0xFF0A3A3A), // Shadow
    ],
  );

  /// Purple roof tiles
  static const purpleRoof = TilePalette(
    name: 'Purple Roof',
    colors: [
      Color(0xFF5A4A6A), // Base purple
      Color(0xFF6A5A7A), // Light
      Color(0xFF4A3A5A), // Dark
      Color(0xFF7A6A8A), // Highlight
      Color(0xFF3A2A4A), // Shadow
    ],
  );

  /// Maroon/dark red roof tiles
  static const maroonRoof = TilePalette(
    name: 'Maroon Roof',
    colors: [
      Color(0xFF5A3A4A), // Base maroon
      Color(0xFF6A4A5A), // Light
      Color(0xFF4A2A3A), // Dark
      Color(0xFF7A5A6A), // Highlight
      Color(0xFF3A1A2A), // Shadow
    ],
  );

  /// Blue roof tiles
  static const blueRoof = TilePalette(
    name: 'Blue Roof',
    colors: [
      Color(0xFF4A5A7A), // Base blue
      Color(0xFF5A6A8A), // Light
      Color(0xFF3A4A6A), // Dark
      Color(0xFF6A7A9A), // Highlight
      Color(0xFF2A3A5A), // Shadow
    ],
  );

  /// Navy/dark blue roof tiles
  static const navyRoof = TilePalette(
    name: 'Navy Roof',
    colors: [
      Color(0xFF3A4A5A), // Base navy
      Color(0xFF4A5A6A), // Light
      Color(0xFF2A3A4A), // Dark
      Color(0xFF5A6A7A), // Highlight
      Color(0xFF1A2A3A), // Shadow
    ],
  );

  /// Gray roof tiles
  static const grayRoof = TilePalette(
    name: 'Gray Roof',
    colors: [
      Color(0xFF5A5A5A), // Base gray
      Color(0xFF6A6A6A), // Light
      Color(0xFF4A4A4A), // Dark
      Color(0xFF7A7A7A), // Highlight
      Color(0xFF3A3A3A), // Shadow
    ],
  );

  /// Dark gray roof tiles
  static const darkGrayRoof = TilePalette(
    name: 'Dark Gray Roof',
    colors: [
      Color(0xFF3A3A3A), // Base
      Color(0xFF4A4A4A), // Light
      Color(0xFF2A2A2A), // Dark
      Color(0xFF5A5A5A), // Highlight
      Color(0xFF1A1A1A), // Shadow
    ],
  );

  /// Brown roof tiles
  static const brownRoof = TilePalette(
    name: 'Brown Roof',
    colors: [
      Color(0xFF6A5040), // Base brown
      Color(0xFF7A6050), // Light
      Color(0xFF5A4030), // Dark
      Color(0xFF8A7060), // Highlight
      Color(0xFF3A2020), // Shadow
    ],
  );

  /// Green roof tiles
  static const greenRoof = TilePalette(
    name: 'Green Roof',
    colors: [
      Color(0xFF3A5A4A), // Base green
      Color(0xFF4A6A5A), // Light
      Color(0xFF2A4A3A), // Dark
      Color(0xFF5A7A6A), // Highlight
      Color(0xFF1A3A2A), // Shadow
    ],
  );

  /// Dark green roof tiles
  static const darkGreenRoof = TilePalette(
    name: 'Dark Green Roof',
    colors: [
      Color(0xFF2A4A3A), // Base
      Color(0xFF3A5A4A), // Light
      Color(0xFF1A3A2A), // Dark
      Color(0xFF4A6A5A), // Highlight
      Color(0xFF0A2A1A), // Shadow
    ],
  );

  /// Olive roof tiles
  static const oliveRoof = TilePalette(
    name: 'Olive Roof',
    colors: [
      Color(0xFF5A5A3A), // Base olive
      Color(0xFF6A6A4A), // Light
      Color(0xFF4A4A2A), // Dark
      Color(0xFF7A7A5A), // Highlight
      Color(0xFF3A3A1A), // Shadow
    ],
  );

  static List<TilePalette> get all => [
        redRoof,
        orangeRoof,
        tealRoof,
        purpleRoof,
        maroonRoof,
        blueRoof,
        navyRoof,
        grayRoof,
        darkGrayRoof,
        brownRoof,
        greenRoof,
        darkGreenRoof,
        oliveRoof,
      ];
}

// ============================================================================
// VARIED STONE/COBBLESTONE PALETTES
// ============================================================================

class VariedStonePalettes {
  VariedStonePalettes._();

  /// Warm gray stone
  static const warmGray = TilePalette(
    name: 'Warm Gray Stone',
    colors: [
      Color(0xFF7A7A70), // Base
      Color(0xFF8A8A80), // Light
      Color(0xFF6A6A60), // Dark
      Color(0xFF9A9A90), // Highlight
      Color(0xFF4A4A40), // Shadow
    ],
  );

  /// Cool gray stone
  static const coolGray = TilePalette(
    name: 'Cool Gray Stone',
    colors: [
      Color(0xFF707080), // Base
      Color(0xFF808090), // Light
      Color(0xFF606070), // Dark
      Color(0xFF9090A0), // Highlight
      Color(0xFF404050), // Shadow
    ],
  );

  /// Tan/beige stone
  static const tanStone = TilePalette(
    name: 'Tan Stone',
    colors: [
      Color(0xFFB0A090), // Base tan
      Color(0xFFC0B0A0), // Light
      Color(0xFFA09080), // Dark
      Color(0xFFD0C0B0), // Highlight
      Color(0xFF706050), // Shadow
    ],
  );

  /// Cream/light beige stone
  static const creamStone = TilePalette(
    name: 'Cream Stone',
    colors: [
      Color(0xFFD0C8B8), // Base cream
      Color(0xFFE0D8C8), // Light
      Color(0xFFC0B8A8), // Dark
      Color(0xFFF0E8D8), // Highlight
      Color(0xFF908878), // Shadow
    ],
  );

  /// Brown stone
  static const brownStone = TilePalette(
    name: 'Brown Stone',
    colors: [
      Color(0xFF8A7A6A), // Base brown
      Color(0xFF9A8A7A), // Light
      Color(0xFF7A6A5A), // Dark
      Color(0xFFAA9A8A), // Highlight
      Color(0xFF5A4A3A), // Shadow
    ],
  );

  /// Dark brown stone
  static const darkBrownStone = TilePalette(
    name: 'Dark Brown Stone',
    colors: [
      Color(0xFF6A5A4A), // Base
      Color(0xFF7A6A5A), // Light
      Color(0xFF5A4A3A), // Dark
      Color(0xFF8A7A6A), // Highlight
      Color(0xFF3A2A1A), // Shadow
    ],
  );

  /// Olive/greenish stone
  static const oliveStone = TilePalette(
    name: 'Olive Stone',
    colors: [
      Color(0xFF7A8070), // Base
      Color(0xFF8A9080), // Light
      Color(0xFF6A7060), // Dark
      Color(0xFF9AA090), // Highlight
      Color(0xFF4A5040), // Shadow
    ],
  );

  /// Weathered/aged stone
  static const weatheredStone = TilePalette(
    name: 'Weathered Stone',
    colors: [
      Color(0xFF909080), // Base
      Color(0xFFA0A090), // Light
      Color(0xFF808070), // Dark
      Color(0xFFB0B0A0), // Highlight
      Color(0xFF505040), // Shadow
    ],
  );

  static List<TilePalette> get all => [
        warmGray,
        coolGray,
        tanStone,
        creamStone,
        brownStone,
        darkBrownStone,
        oliveStone,
        weatheredStone,
      ];
}

// ============================================================================
// COLORED ROOF TILE GENERATORS
// ============================================================================

/// Roof shingle tile with customizable color
class ColoredRoofShingleTile extends TileBase {
  final TilePalette colorPalette;
  final int shingleHeight;
  final int shingleWidth;

  ColoredRoofShingleTile(
    super.id, {
    required this.colorPalette,
    this.shingleHeight = 4,
    this.shingleWidth = 6,
  });

  @override
  String get name => '${colorPalette.name} Shingle';
  @override
  String get description => 'Roof shingles in ${colorPalette.name.toLowerCase()} color';
  @override
  String get iconName => 'roofing';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['roof', 'shingle', 'colored', colorPalette.name.toLowerCase()];

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
        final row = y ~/ shingleHeight;
        final offset = row % 2 == 1 ? shingleWidth ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final posInRow = y % shingleHeight;
        final posInShingle = adjustedX % shingleWidth;

        Color baseColor;

        // Bottom edge shadow
        if (posInRow == 0) {
          baseColor = palette.shadow;
        }
        // Top highlight
        else if (posInRow == shingleHeight - 1 && posInShingle > 0 && posInShingle < shingleWidth - 1) {
          baseColor = palette.highlight;
        }
        // Side edges
        else if (posInShingle == 0) {
          baseColor = palette.shadow;
        }
        // Main shingle body
        else {
          final shingleIdx = (row + adjustedX ~/ shingleWidth + seed) % 3;
          baseColor = palette.colors[shingleIdx];

          // Add subtle texture variation
          final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
          if (noiseVal > 0.75) {
            baseColor = palette.highlight;
          } else if (noiseVal < 0.2) {
            baseColor = palette.colors[2];
          }
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Roof tile (curved/wave pattern) with customizable color
class ColoredRoofTileTile extends TileBase {
  final TilePalette colorPalette;
  final int tileHeight;

  ColoredRoofTileTile(
    super.id, {
    required this.colorPalette,
    this.tileHeight = 4,
  });

  @override
  String get name => '${colorPalette.name} Tile';
  @override
  String get description => 'Curved roof tiles in ${colorPalette.name.toLowerCase()} color';
  @override
  String get iconName => 'roofing';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['roof', 'tile', 'curved', 'colored', colorPalette.name.toLowerCase()];

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
        final row = y ~/ tileHeight;
        final offset = row % 2 == 1 ? width ~/ 4 : 0;
        final adjustedX = (x + offset) % width;

        final posInTile = y % tileHeight;

        Color baseColor;

        // Create curved shading effect
        if (posInTile == 0) {
          // Bottom edge - darkest (shadow under curve)
          baseColor = palette.shadow;
        } else if (posInTile == 1) {
          // Lower mid - dark
          baseColor = palette.colors[2];
        } else if (posInTile == tileHeight - 1) {
          // Top - highlight (curve peak)
          baseColor = palette.highlight;
        } else {
          // Middle sections
          final tileIdx = (row + adjustedX ~/ (width ~/ 2) + seed) % 3;
          baseColor = palette.colors[tileIdx];
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Small brick/shingle pattern with color
class ColoredSmallBrickTile extends TileBase {
  final TilePalette colorPalette;
  final int brickWidth;
  final int brickHeight;

  ColoredSmallBrickTile(
    super.id, {
    required this.colorPalette,
    this.brickWidth = 4,
    this.brickHeight = 2,
  });

  @override
  String get name => '${colorPalette.name} Small Brick';
  @override
  String get description => 'Small brick pattern in ${colorPalette.name.toLowerCase()}';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['brick', 'small', 'colored', colorPalette.name.toLowerCase()];

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
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// VARIED STONE/COBBLESTONE GENERATORS
// ============================================================================

/// Cobblestone with customizable palette
class ColoredCobblestoneTile extends TileBase {
  final TilePalette colorPalette;
  final int stoneSize;
  final bool irregular;

  ColoredCobblestoneTile(
    super.id, {
    required this.colorPalette,
    this.stoneSize = 3,
    this.irregular = false,
  });

  @override
  String get name => '${colorPalette.name} Cobblestone';
  @override
  String get description => 'Cobblestone in ${colorPalette.name.toLowerCase()} tones';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['cobblestone', 'stone', 'paving', colorPalette.name.toLowerCase()];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with mortar/gap color
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate stones in a grid pattern
    for (int sy = 0; sy < height; sy += stoneSize + 1) {
      for (int sx = 0; sx < width; sx += stoneSize + 1) {
        final offsetX = irregular ? random.nextInt(2) : 0;
        final offsetY = irregular ? random.nextInt(2) : 0;
        final thisSize = irregular ? stoneSize + random.nextInt(2) - 1 : stoneSize;

        final colorIdx = random.nextInt(3);
        final stoneColor = palette.colors[colorIdx];

        for (int dy = 0; dy < thisSize; dy++) {
          for (int dx = 0; dx < thisSize; dx++) {
            final px = sx + dx + offsetX;
            final py = sy + dy + offsetY;
            if (px < width && py < height) {
              // Edge shading
              final isEdge = dx == 0 || dy == 0 || dx == thisSize - 1 || dy == thisSize - 1;
              Color finalColor = stoneColor;
              if (isEdge) {
                finalColor = dy == 0 || dx == 0 ? palette.highlight : palette.colors[2];
              }
              pixels[py * width + px] = addNoise(finalColor, random, 0.05);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Stone brick wall with customizable palette
class ColoredStoneBrickTile extends TileBase {
  final TilePalette colorPalette;
  final int brickWidth;
  final int brickHeight;

  ColoredStoneBrickTile(
    super.id, {
    required this.colorPalette,
    this.brickWidth = 6,
    this.brickHeight = 3,
  });

  @override
  String get name => '${colorPalette.name} Brick';
  @override
  String get description => 'Stone brick in ${colorPalette.name.toLowerCase()} tones';
  @override
  String get iconName => 'view_module';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['stone', 'brick', 'wall', colorPalette.name.toLowerCase()];

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
          Color baseColor = palette.colors[brickIdx];

          // Add texture within brick
          final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
          if (noiseVal > 0.75) {
            baseColor = palette.highlight;
          } else if (noiseVal < 0.2) {
            baseColor = palette.colors[2];
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Rough/textured stone with customizable palette
class ColoredRoughStoneTile extends TileBase {
  final TilePalette colorPalette;

  ColoredRoughStoneTile(
    super.id, {
    required this.colorPalette,
  });

  @override
  String get name => '${colorPalette.name} Rough';
  @override
  String get description => 'Rough stone texture in ${colorPalette.name.toLowerCase()}';
  @override
  String get iconName => 'texture';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['stone', 'rough', 'textured', colorPalette.name.toLowerCase()];

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
        final noise2 = noise2D(x / 5.0 + seed * 7, y / 5.0, 2);
        final combined = noise1 * 0.6 + noise2 * 0.4;

        Color baseColor;
        if (combined < 0.25) {
          baseColor = palette.shadow;
        } else if (combined < 0.4) {
          baseColor = palette.colors[2];
        } else if (combined < 0.6) {
          baseColor = palette.primary;
        } else if (combined < 0.8) {
          baseColor = palette.secondary;
        } else {
          baseColor = palette.highlight;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.06);
      }
    }

    return pixels;
  }
}

/// Large stone blocks with customizable palette
class ColoredLargeBlockTile extends TileBase {
  final TilePalette colorPalette;
  final int blockSize;

  ColoredLargeBlockTile(
    super.id, {
    required this.colorPalette,
    this.blockSize = 8,
  });

  @override
  String get name => '${colorPalette.name} Large Block';
  @override
  String get description => 'Large stone blocks in ${colorPalette.name.toLowerCase()}';
  @override
  String get iconName => 'view_module';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['stone', 'block', 'large', colorPalette.name.toLowerCase()];

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
        final row = y ~/ blockSize;
        final offset = row % 2 == 1 ? blockSize ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final isHJoint = y % blockSize == 0;
        final isVJoint = adjustedX % blockSize == 0;

        if (isHJoint || isVJoint) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          // Edge highlighting
          final posInBlockX = adjustedX % blockSize;
          final posInBlockY = y % blockSize;

          Color baseColor;
          if (posInBlockX == 1 || posInBlockY == 1) {
            baseColor = palette.highlight;
          } else if (posInBlockX == blockSize - 2 || posInBlockY == blockSize - 2) {
            baseColor = palette.colors[2];
          } else {
            final blockIdx = (row + adjustedX ~/ blockSize + seed) % 3;
            baseColor = palette.colors[blockIdx];
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Weathered/stained stone with customizable palette
class ColoredWeatheredStoneTile extends TileBase {
  final TilePalette colorPalette;

  ColoredWeatheredStoneTile(
    super.id, {
    required this.colorPalette,
  });

  @override
  String get name => '${colorPalette.name} Weathered';
  @override
  String get description => 'Weathered stone in ${colorPalette.name.toLowerCase()}';
  @override
  String get iconName => 'blur_on';
  @override
  TileCategory get category => TileCategory.varied;
  @override
  TilePalette get palette => colorPalette;
  @override
  List<String> get tags => ['stone', 'weathered', 'aged', colorPalette.name.toLowerCase()];

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
        // Base texture
        final baseNoise = noise2D(x / 4.0 + seed * 3, y / 4.0, 2);

        // Weathering/stain pattern (larger scale)
        final weatherNoise = noise2D(x / 8.0 + seed * 5, y / 8.0, 3);

        Color baseColor;
        if (baseNoise < 0.35) {
          baseColor = palette.shadow;
        } else if (baseNoise < 0.65) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }

        // Apply weathering stains
        if (weatherNoise > 0.7) {
          baseColor = palette.colors[2]; // Darker stain
        } else if (weatherNoise < 0.2) {
          baseColor = palette.highlight; // Lighter wear
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}

// ============================================================================
// FACTORY METHODS FOR EASY GENERATION
// ============================================================================

/// Factory to create all colored roof tile variants
class ColoredRoofFactory {
  static List<TileBase> createAllShingles() {
    final tiles = <TileBase>[];

    for (final palette in ColoredRoofPalettes.all) {
      tiles.add(ColoredRoofShingleTile('roof_shingle_${palette.name.toLowerCase().replaceAll(' ', '_')}',
          colorPalette: palette));
    }
    return tiles;
  }

  static List<TileBase> createAllCurvedTiles() {
    final tiles = <TileBase>[];

    for (final palette in ColoredRoofPalettes.all) {
      tiles.add(
          ColoredRoofTileTile('roof_curved_${palette.name.toLowerCase().replaceAll(' ', '_')}', colorPalette: palette));
    }
    return tiles;
  }

  static List<TileBase> createAllSmallBricks() {
    final tiles = <TileBase>[];

    for (final palette in ColoredRoofPalettes.all) {
      tiles.add(ColoredSmallBrickTile('small_brick_${palette.name.toLowerCase().replaceAll(' ', '_')}',
          colorPalette: palette));
    }
    return tiles;
  }
}

/// Factory to create all stone color variants
class ColoredStoneFactory {
  static List<TileBase> createAllCobblestones() {
    final tiles = <TileBase>[];

    for (final palette in VariedStonePalettes.all) {
      tiles.add(
          ColoredCobblestoneTile('cobble_${palette.name.toLowerCase().replaceAll(' ', '_')}', colorPalette: palette));
    }
    return tiles;
  }

  static List<TileBase> createAllStoneBricks() {
    final tiles = <TileBase>[];

    for (final palette in VariedStonePalettes.all) {
      tiles.add(ColoredStoneBrickTile('stone_brick_${palette.name.toLowerCase().replaceAll(' ', '_')}',
          colorPalette: palette));
    }
    return tiles;
  }

  static List<TileBase> createAllRoughStones() {
    final tiles = <TileBase>[];

    for (final palette in VariedStonePalettes.all) {
      tiles.add(
          ColoredRoughStoneTile('rough_${palette.name.toLowerCase().replaceAll(' ', '_')}', colorPalette: palette));
    }
    return tiles;
  }

  static List<TileBase> createAllLargeBlocks() {
    final tiles = <TileBase>[];

    for (final palette in VariedStonePalettes.all) {
      tiles.add(ColoredLargeBlockTile('large_block_${palette.name.toLowerCase().replaceAll(' ', '_')}',
          colorPalette: palette));
    }
    return tiles;
  }

  static List<TileBase> createAllWeatheredStones() {
    final tiles = <TileBase>[];

    for (final palette in VariedStonePalettes.all) {
      tiles.add(ColoredWeatheredStoneTile('weathered_${palette.name.toLowerCase().replaceAll(' ', '_')}',
          colorPalette: palette));
    }
    return tiles;
  }
}
