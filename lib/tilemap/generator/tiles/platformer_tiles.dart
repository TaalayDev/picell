import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// STYLIZED PLATFORMER TILE PALETTES
// ============================================================================

class PlatformerPalettes {
  PlatformerPalettes._();

  /// Lava/magma palette with drips
  static const lava = TilePalette(
    name: 'Lava',
    colors: [
      Color(0xFF5A2A4A), // Dark purple base
      Color(0xFF8A3A5A), // Purple mid
      Color(0xFFFF6600), // Orange lava
      Color(0xFFFFAA00), // Yellow hot
      Color(0xFF3A1A2A), // Dark shadow
    ],
  );

  /// Metal/industrial palette
  static const metal = TilePalette(
    name: 'Metal',
    colors: [
      Color(0xFF5A6A7A), // Base gray-blue
      Color(0xFF4A5A6A), // Dark panel
      Color(0xFF6A7A8A), // Light panel
      Color(0xFF8A9AAA), // Highlight
      Color(0xFF2A3A4A), // Shadow/gaps
    ],
  );

  /// Clear water palette
  static const waterClear = TilePalette(
    name: 'Clear Water',
    colors: [
      Color(0xFF4A9ADA), // Base blue
      Color(0xFF6ABAFF), // Light blue
      Color(0xFF3A7ABA), // Dark blue
      Color(0xFFAAEEFF), // Highlight/bubble
      Color(0xFF2A5A8A), // Deep shadow
    ],
  );

  /// Stone path palette
  static const stonePath = TilePalette(
    name: 'Stone Path',
    colors: [
      Color(0xFF8A8A7A), // Base stone
      Color(0xFF9A9A8A), // Light stone
      Color(0xFF6A6A5A), // Dark stone
      Color(0xFFAAAA9A), // Highlight
      Color(0xFF4A4A3A), // Gaps/shadow
    ],
  );

  /// Fish scale/water pattern palette
  static const fishScale = TilePalette(
    name: 'Fish Scale',
    colors: [
      Color(0xFF3A8AAA), // Base teal
      Color(0xFF5AAACC), // Light scale
      Color(0xFF2A6A8A), // Dark scale
      Color(0xFF8ADDFF), // Highlight
      Color(0xFF1A4A6A), // Shadow
    ],
  );

  /// Grass top with dirt palette
  static const grassDirt = TilePalette(
    name: 'Grass Dirt',
    colors: [
      Color(0xFF5A9A3A), // Grass green
      Color(0xFF7ABA5A), // Light grass
      Color(0xFF8A6A4A), // Dirt brown
      Color(0xFF6A5A3A), // Dark dirt
      Color(0xFF4A3A2A), // Shadow
    ],
  );

  /// Desert sand layers palette
  static const sandLayers = TilePalette(
    name: 'Sand Layers',
    colors: [
      Color(0xFFDABA8A), // Light sand
      Color(0xFFCAA070), // Mid sand
      Color(0xFFBA8A5A), // Dark sand
      Color(0xFFFADABA), // Highlight
      Color(0xFF8A6A4A), // Shadow
    ],
  );

  /// Lava cracks palette
  static const lavaCracks = TilePalette(
    name: 'Lava Cracks',
    colors: [
      Color(0xFF2A2A2A), // Black rock
      Color(0xFF4A4A4A), // Dark rock
      Color(0xFFFF4400), // Red lava
      Color(0xFFFFAA00), // Yellow glow
      Color(0xFF1A1A1A), // Deep shadow
    ],
  );

  /// Honeycomb palette
  static const honeycomb = TilePalette(
    name: 'Honeycomb',
    colors: [
      Color(0xFFDAA050), // Honey gold
      Color(0xFFBA8040), // Dark cell
      Color(0xFFEAC070), // Light cell
      Color(0xFFFFDD88), // Highlight
      Color(0xFF8A5A30), // Shadow
    ],
  );

  /// Purple slime/poison palette
  static const poisonSlime = TilePalette(
    name: 'Poison Slime',
    colors: [
      Color(0xFF6A4A8A), // Base purple
      Color(0xFF8A6AAA), // Light purple
      Color(0xFF4A2A6A), // Dark purple
      Color(0xFF9ADA6A), // Green slime spots
      Color(0xFF3A1A4A), // Shadow
    ],
  );

  /// Rocky ground palette
  static const rockyGround = TilePalette(
    name: 'Rocky Ground',
    colors: [
      Color(0xFF9A7A5A), // Base tan rock
      Color(0xFFBA9A7A), // Light rock
      Color(0xFF7A5A3A), // Dark rock
      Color(0xFFDABA9A), // Highlight
      Color(0xFF5A3A2A), // Shadow
    ],
  );

  /// Purple decorative tile palette
  static const purpleTile = TilePalette(
    name: 'Purple Tile',
    colors: [
      Color(0xFF5A4A7A), // Base purple
      Color(0xFF7A6A9A), // Light purple
      Color(0xFF3A2A5A), // Dark purple
      Color(0xFF9A8ABA), // Highlight
      Color(0xFF2A1A3A), // Shadow
    ],
  );

  /// Cracked earth/electric palette
  static const crackedElectric = TilePalette(
    name: 'Cracked Electric',
    colors: [
      Color(0xFF8AAA5A), // Yellow-green base
      Color(0xFFAACA7A), // Light
      Color(0xFF6A8A3A), // Dark
      Color(0xFFFFFFAA), // Electric yellow
      Color(0xFF4A5A2A), // Shadow
    ],
  );

  /// Orange roof scale palette
  static const orangeScale = TilePalette(
    name: 'Orange Scale',
    colors: [
      Color(0xFFDA7A3A), // Base orange
      Color(0xFFEA9A5A), // Light orange
      Color(0xFFBA5A2A), // Dark orange
      Color(0xFFFFBA7A), // Highlight
      Color(0xFF8A3A1A), // Shadow
    ],
  );

  /// Deep water with stones palette
  static const deepWater = TilePalette(
    name: 'Deep Water',
    colors: [
      Color(0xFF2A5A8A), // Deep blue
      Color(0xFF4A8ABA), // Mid blue
      Color(0xFF1A3A5A), // Dark blue
      Color(0xFF7ACAEA), // Light/surface
      Color(0xFF0A2A4A), // Abyss
    ],
  );

  /// Wood plank palette
  static const woodPlank = TilePalette(
    name: 'Wood Plank',
    colors: [
      Color(0xFFCA9A5A), // Base wood
      Color(0xFFDABA7A), // Light wood
      Color(0xFFAA7A4A), // Dark wood
      Color(0xFFEADA9A), // Highlight
      Color(0xFF6A4A2A), // Shadow/gap
    ],
  );

  /// Snow/ice top palette
  static const snowIce = TilePalette(
    name: 'Snow Ice',
    colors: [
      Color(0xFFEAF0FF), // White snow
      Color(0xFFCADAEA), // Light blue ice
      Color(0xFF9ABACC), // Medium ice
      Color(0xFFFFFFFF), // Bright highlight
      Color(0xFF7A9AAA), // Shadow
    ],
  );

  /// Red brick palette
  static const redBrick = TilePalette(
    name: 'Red Brick',
    colors: [
      Color(0xFFBA5A3A), // Base red
      Color(0xFFDA7A5A), // Light brick
      Color(0xFF9A4A2A), // Dark brick
      Color(0xFFEA9A7A), // Highlight
      Color(0xFF5A2A1A), // Mortar
    ],
  );
}

// ============================================================================
// PLATFORMER TILE GENERATORS
// ============================================================================

/// Lava drip tile with flowing lava effect
class LavaDripTile extends TileBase {
  LavaDripTile(super.id);

  @override
  String get name => 'Lava Drip';
  @override
  String get description => 'Volcanic surface with dripping lava';
  @override
  String get iconName => 'local_fire_department';
  @override
  TileCategory get category => TileCategory.special;
  @override
  TilePalette get palette => PlatformerPalettes.lava;
  @override
  List<String> get tags => ['lava', 'volcano', 'drip', 'platformer', 'hazard'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;
  @override
  int get frameSpeed => 200;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Purple rocky base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
        Color baseColor;
        if (noiseVal < 0.4) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    // Lava drips from top
    final dripCount = 3;
    for (int d = 0; d < dripCount; d++) {
      final dripX = (width * (d + 1) / (dripCount + 1)).round();
      final dripLength = (height * 0.6 + (frameIndex * 2) % 4).round();
      final dripWidth = 2;

      // Main drip body
      for (int dy = 0; dy < dripLength && dy < height; dy++) {
        for (int dx = -dripWidth ~/ 2; dx <= dripWidth ~/ 2; dx++) {
          final px = dripX + dx;
          final py = dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            // Gradient from yellow at top to orange at bottom
            final t = dy / dripLength;
            final lavaColor = t < 0.3
                ? palette.highlight
                : t < 0.7
                    ? palette.accent
                    : palette.accent;
            pixels[py * width + px] = colorToInt(lavaColor);
          }
        }
      }

      // Drip bulb at bottom
      final bulbY = min(dripLength, height - 3);
      for (int by = -1; by <= 2; by++) {
        for (int bx = -1; bx <= 1; bx++) {
          final px = dripX + bx;
          final py = bulbY + by;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            pixels[py * width + px] = colorToInt(palette.highlight);
          }
        }
      }
    }

    return pixels;
  }
}

/// Metal grate/panel tile
class MetalGrateTile extends TileBase {
  final int panelSize;

  MetalGrateTile(super.id, {this.panelSize = 4});

  @override
  String get name => 'Metal Grate';
  @override
  String get description => 'Industrial metal panel grating';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => PlatformerPalettes.metal;
  @override
  List<String> get tags => ['metal', 'industrial', 'grate', 'platformer', 'sci-fi'];

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
        final isGap = x % panelSize == 0 || y % panelSize == 0;
        final panelX = x ~/ panelSize;
        final panelY = y ~/ panelSize;

        if (isGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          // Alternate panel colors for variety
          final panelIdx = (panelX + panelY) % 2;
          Color baseColor = panelIdx == 0 ? palette.primary : palette.secondary;

          // Add panel edge highlight/shadow
          final posInPanelX = x % panelSize;
          final posInPanelY = y % panelSize;
          if (posInPanelX == 1 || posInPanelY == 1) {
            baseColor = palette.highlight;
          } else if (posInPanelX == panelSize - 2 || posInPanelY == panelSize - 2) {
            baseColor = palette.colors[2];
          }

          pixels[y * width + x] = addNoise(baseColor, random, 0.03);
        }
      }
    }

    // Add rivets/bolts
    for (int py = panelSize ~/ 2; py < height; py += panelSize) {
      for (int px = panelSize ~/ 2; px < width; px += panelSize) {
        if (px < width && py < height) {
          pixels[py * width + px] = colorToInt(palette.shadow);
          if (px + 1 < width) pixels[py * width + px + 1] = colorToInt(palette.highlight);
        }
      }
    }

    return pixels;
  }
}

/// Water tile with bubbles
class WaterBubbleTile extends TileBase {
  WaterBubbleTile(super.id);

  @override
  String get name => 'Water Bubbles';
  @override
  String get description => 'Clear water with floating bubbles';
  @override
  String get iconName => 'water';
  @override
  TileCategory get category => TileCategory.liquid;
  @override
  TilePalette get palette => PlatformerPalettes.waterClear;
  @override
  List<String> get tags => ['water', 'bubble', 'liquid', 'platformer'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;
  @override
  int get frameSpeed => 250;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex);
    final pixels = Uint32List(width * height);

    // Water gradient (lighter at top)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final t = y / height;
        Color baseColor;
        if (t < 0.2) {
          baseColor = palette.secondary; // Light at top
        } else if (t < 0.5) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.colors[2]; // Darker at bottom
        }

        // Add wave pattern
        final wave = sin((x + frameIndex * 2) / 3.0) * 0.15;
        if (t + wave < 0.15) {
          baseColor = palette.highlight; // Wave crest
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    // Add bubbles
    final bubbleSeeds = [
      [width * 0.3, 0.6 - (frameIndex * 0.1) % 0.5],
      [width * 0.6, 0.8 - (frameIndex * 0.15) % 0.6],
      [width * 0.8, 0.5 - (frameIndex * 0.12) % 0.4],
    ];

    for (final bubble in bubbleSeeds) {
      final bx = bubble[0].round();
      final by = (height * bubble[1]).round();
      if (bx >= 1 && bx < width - 1 && by >= 1 && by < height - 1) {
        // Bubble outline
        pixels[by * width + bx] = colorToInt(palette.highlight);
        pixels[(by - 1) * width + bx] = colorToInt(palette.highlight);
        pixels[(by + 1) * width + bx] = colorToInt(palette.secondary);
        pixels[by * width + bx - 1] = colorToInt(palette.secondary);
        pixels[by * width + bx + 1] = colorToInt(palette.secondary);
      }
    }

    return pixels;
  }
}

/// Stone path tile with grass growing through cracks
class StonePathGrassTile extends TileBase {
  StonePathGrassTile(super.id);

  @override
  String get name => 'Stone Path';
  @override
  String get description => 'Stone path with grass in cracks';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => PlatformerPalettes.stonePath;
  @override
  List<String> get tags => ['stone', 'path', 'grass', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final stoneW = 5;
    final stoneH = 4;

    // Fill with gap color (dirt)
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Draw stones
    for (int sy = 0; sy < height; sy += stoneH + 1) {
      for (int sx = 0; sx < width; sx += stoneW + 1) {
        final offset = (sy ~/ (stoneH + 1)) % 2 == 1 ? stoneW ~/ 2 : 0;
        final stoneStartX = (sx + offset) % width;

        for (int dy = 0; dy < stoneH; dy++) {
          for (int dx = 0; dx < stoneW; dx++) {
            final px = (stoneStartX + dx) % width;
            final py = sy + dy;
            if (py < height) {
              final colorIdx = random.nextInt(3);
              final stoneColor = palette.colors[colorIdx];

              // Edge shading
              Color finalColor = stoneColor;
              if (dy == 0 || dx == 0) {
                finalColor = palette.highlight;
              } else if (dy == stoneH - 1 || dx == stoneW - 1) {
                finalColor = palette.colors[2];
              }

              pixels[py * width + px] = addNoise(finalColor, random, 0.04);
            }
          }
        }
      }
    }

    // Add grass tufts in gaps
    final grassColor = const Color(0xFF5A9A3A);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] == colorToInt(palette.shadow)) {
          if (random.nextDouble() < 0.3) {
            pixels[y * width + x] = colorToInt(grassColor);
          }
        }
      }
    }

    return pixels;
  }
}

/// Fish scale / wave pattern tile
class FishScaleTile extends TileBase {
  FishScaleTile(super.id);

  @override
  String get name => 'Fish Scale';
  @override
  String get description => 'Overlapping scale pattern like fish or waves';
  @override
  String get iconName => 'waves';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  TilePalette get palette => PlatformerPalettes.fishScale;
  @override
  List<String> get tags => ['scale', 'fish', 'water', 'pattern', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final scaleW = 4;
    final scaleH = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ scaleH;
        final offset = row % 2 == 1 ? scaleW ~/ 2 : 0;
        final scaleX = ((x + offset) % width) % scaleW;
        final scaleY = y % scaleH;

        // Create curved scale shape
        final centerX = scaleW / 2;
        final distFromCenter = (scaleX - centerX).abs() / centerX;
        final curveY = (distFromCenter * distFromCenter * scaleH * 0.5).round();

        Color baseColor;
        if (scaleY < curveY) {
          // Above curve - previous row's scale
          baseColor = palette.colors[2];
        } else if (scaleY == curveY || scaleY == curveY + 1) {
          // Scale edge highlight
          baseColor = palette.highlight;
        } else {
          // Scale body
          final idx = (row + (x + offset) ~/ scaleW + seed) % 2;
          baseColor = idx == 0 ? palette.primary : palette.secondary;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Grass top with dirt layer tile
class GrassTopDirtTile extends TileBase {
  final int grassHeight;

  GrassTopDirtTile(super.id, {this.grassHeight = 4});

  @override
  String get name => 'Grass Top';
  @override
  String get description => 'Grass surface layer over dirt';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => PlatformerPalettes.grassDirt;
  @override
  List<String> get tags => ['grass', 'dirt', 'ground', 'platformer', 'terrain'];

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
        if (y < grassHeight) {
          // Grass layer
          final grassNoise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          Color grassColor;
          if (grassNoise > 0.6) {
            grassColor = palette.secondary; // Light grass
          } else {
            grassColor = palette.primary; // Base grass
          }

          // Grass blade tips at very top
          if (y < 2 && random.nextDouble() < 0.4) {
            grassColor = palette.secondary;
          }

          pixels[y * width + x] = addNoise(grassColor, random, 0.05);
        } else {
          // Dirt layer
          final dirtNoise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          Color dirtColor;
          if (dirtNoise < 0.3) {
            dirtColor = palette.shadow;
          } else if (dirtNoise < 0.6) {
            dirtColor = palette.colors[3]; // Dark dirt
          } else {
            dirtColor = palette.accent; // Light dirt
          }

          // Add small rocks/pebbles
          if (random.nextDouble() < 0.05) {
            dirtColor = palette.shadow;
          }

          pixels[y * width + x] = addNoise(dirtColor, random, 0.05);
        }
      }
    }

    // Add grass-dirt transition with irregular edge
    for (int x = 0; x < width; x++) {
      final edgeY = grassHeight + (random.nextInt(2) - 1);
      if (edgeY >= 0 && edgeY < height) {
        pixels[edgeY * width + x] = addNoise(palette.colors[3], random, 0.05);
      }
    }

    return pixels;
  }
}

/// Sand with wavy layers
class SandLayersTile extends TileBase {
  SandLayersTile(super.id);

  @override
  String get name => 'Sand Layers';
  @override
  String get description => 'Desert sand with visible layers';
  @override
  String get iconName => 'terrain';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => PlatformerPalettes.sandLayers;
  @override
  List<String> get tags => ['sand', 'desert', 'layers', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final layerHeight = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Wave offset for each layer
        final wave = sin(x / 4.0 + seed) * 1.5;
        final adjustedY = y + wave.round();
        final layer = adjustedY ~/ layerHeight;

        // Alternate layer colors
        final colorIdx = layer % 3;
        Color baseColor = palette.colors[colorIdx];

        // Add layer edge highlight
        if (adjustedY % layerHeight == 0) {
          baseColor = palette.shadow;
        } else if (adjustedY % layerHeight == 1) {
          baseColor = palette.highlight;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add small stones/dots
    final dotCount = (width * height * 0.02).round();
    for (int i = 0; i < dotCount; i++) {
      final dx = random.nextInt(width);
      final dy = random.nextInt(height);
      pixels[dy * width + dx] = colorToInt(palette.shadow);
    }

    return pixels;
  }
}

/// Lava cracks on black rock
class LavaCracksTile extends TileBase {
  LavaCracksTile(super.id);

  @override
  String get name => 'Lava Cracks';
  @override
  String get description => 'Black volcanic rock with glowing lava cracks';
  @override
  String get iconName => 'whatshot';
  @override
  TileCategory get category => TileCategory.special;
  @override
  TilePalette get palette => PlatformerPalettes.lavaCracks;
  @override
  List<String> get tags => ['lava', 'volcano', 'cracks', 'hazard', 'platformer'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;
  @override
  int get frameSpeed => 200;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Black rock base with texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
        Color rockColor;
        if (noiseVal < 0.4) {
          rockColor = palette.shadow;
        } else if (noiseVal < 0.7) {
          rockColor = palette.primary;
        } else {
          rockColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(rockColor, random, 0.05);
      }
    }

    // Generate lava crack pattern using cellular/blob approach
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final crackNoise = noise2D(x / 4.0 + seed * 3, y / 4.0, 3);
        final pulse = sin(frameIndex * 0.5) * 0.1;

        if (crackNoise > 0.6 + pulse) {
          // Lava glow
          if (crackNoise > 0.75 + pulse) {
            pixels[y * width + x] = colorToInt(palette.highlight); // Yellow hot
          } else {
            pixels[y * width + x] = colorToInt(palette.accent); // Orange
          }
        }
      }
    }

    return pixels;
  }
}

/// Honeycomb pattern tile
class HoneycombTile extends TileBase {
  HoneycombTile(super.id);

  @override
  String get name => 'Honeycomb';
  @override
  String get description => 'Hexagonal honeycomb pattern';
  @override
  String get iconName => 'hexagon';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  TilePalette get palette => PlatformerPalettes.honeycomb;
  @override
  List<String> get tags => ['honeycomb', 'hex', 'pattern', 'platformer', 'gold'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final hexW = 4;
    final hexH = 4;

    // Fill with dark cell wall color
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.secondary);
    }

    // Draw hexagonal cells (simplified as octagons)
    for (int cy = 0; cy < height; cy += hexH) {
      for (int cx = 0; cx < width; cx += hexW) {
        final offset = (cy ~/ hexH) % 2 == 1 ? hexW ~/ 2 : 0;
        final startX = (cx + offset) % width;

        // Draw cell interior
        for (int dy = 1; dy < hexH - 1; dy++) {
          for (int dx = 1; dx < hexW - 1; dx++) {
            final px = (startX + dx) % width;
            final py = cy + dy;
            if (py < height) {
              // Skip corners for hexagonal shape
              final isCorner = (dx == 1 && dy == 1) ||
                  (dx == hexW - 2 && dy == 1) ||
                  (dx == 1 && dy == hexH - 2) ||
                  (dx == hexW - 2 && dy == hexH - 2);

              if (!isCorner) {
                final colorIdx = ((cx ~/ hexW) + (cy ~/ hexH) + seed) % 2;
                final cellColor = colorIdx == 0 ? palette.primary : palette.accent;
                pixels[py * width + px] = addNoise(cellColor, random, 0.05);
              }
            }
          }
        }

        // Cell highlight
        if (cy + 1 < height && startX + 2 < width) {
          pixels[(cy + 1) * width + (startX + 2) % width] = colorToInt(palette.highlight);
        }
      }
    }

    return pixels;
  }
}

/// Purple poison slime tile
class PoisonSlimeTile extends TileBase {
  PoisonSlimeTile(super.id);

  @override
  String get name => 'Poison Slime';
  @override
  String get description => 'Toxic purple slime with bubbles';
  @override
  String get iconName => 'bubble_chart';
  @override
  TileCategory get category => TileCategory.liquid;
  @override
  TilePalette get palette => PlatformerPalettes.poisonSlime;
  @override
  List<String> get tags => ['poison', 'slime', 'toxic', 'hazard', 'platformer'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;
  @override
  int get frameSpeed => 300;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex);
    final pixels = Uint32List(width * height);

    // Purple base with swirling pattern
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final swirl = sin(x / 3.0 + y / 4.0 + frameIndex * 0.3) * 0.3;
        final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 2) + swirl;

        Color baseColor;
        if (noiseVal < 0.3) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.5) {
          baseColor = palette.colors[2];
        } else if (noiseVal < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add green toxic bubbles/spots
    final bubblePositions = [
      [width * 0.25, height * 0.3],
      [width * 0.7, height * 0.5],
      [width * 0.4, height * 0.7],
    ];

    for (final pos in bubblePositions) {
      final bx = pos[0].round();
      final by = (pos[1] - frameIndex * 0.5).round() % height;
      if (bx >= 0 && bx < width && by >= 0 && by < height) {
        pixels[by * width + bx] = colorToInt(palette.highlight); // Green bubble
        if (bx + 1 < width) {
          pixels[by * width + bx + 1] = colorToInt(palette.highlight);
        }
      }
    }

    return pixels;
  }
}

/// Rocky ground with boulders
class RockyGroundTile extends TileBase {
  RockyGroundTile(super.id);

  @override
  String get name => 'Rocky Ground';
  @override
  String get description => 'Ground covered with rocks and boulders';
  @override
  String get iconName => 'landscape';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => PlatformerPalettes.rockyGround;
  @override
  List<String> get tags => ['rock', 'ground', 'boulder', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with dirt base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 2);
        Color baseColor;
        if (noiseVal < 0.4) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.7) {
          baseColor = palette.colors[2];
        } else {
          baseColor = palette.primary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    // Add rocks of various sizes
    final rockCount = 5;
    for (int r = 0; r < rockCount; r++) {
      final rx = random.nextInt(width - 3);
      final ry = random.nextInt(height - 2) + 1;
      final rw = random.nextInt(3) + 2;
      final rh = random.nextInt(2) + 1;

      for (int dy = 0; dy < rh; dy++) {
        for (int dx = 0; dx < rw; dx++) {
          final px = rx + dx;
          final py = ry + dy;
          if (px < width && py < height) {
            Color rockColor = palette.secondary;
            // Top highlight
            if (dy == 0) {
              rockColor = palette.highlight;
            } else if (dx == 0) {
              rockColor = palette.highlight;
            } else if (dx == rw - 1 || dy == rh - 1) {
              rockColor = palette.colors[2];
            }
            pixels[py * width + px] = addNoise(rockColor, random, 0.04);
          }
        }
      }
    }

    return pixels;
  }
}

/// Purple decorative octagon tile
class PurpleOctagonTile extends TileBase {
  PurpleOctagonTile(super.id);

  @override
  String get name => 'Purple Octagon';
  @override
  String get description => 'Decorative purple octagon pattern';
  @override
  String get iconName => 'stop';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  TilePalette get palette => PlatformerPalettes.purpleTile;
  @override
  List<String> get tags => ['purple', 'octagon', 'decorative', 'pattern', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final tileSize = 4;

    // Fill with background
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Draw octagon pattern
    for (int ty = 0; ty < height; ty += tileSize) {
      for (int tx = 0; tx < width; tx += tileSize) {
        // Draw octagon (square with cut corners)
        for (int dy = 0; dy < tileSize; dy++) {
          for (int dx = 0; dx < tileSize; dx++) {
            final px = tx + dx;
            final py = ty + dy;
            if (px < width && py < height) {
              // Cut corners
              final isCorner = (dx == 0 && dy == 0) ||
                  (dx == tileSize - 1 && dy == 0) ||
                  (dx == 0 && dy == tileSize - 1) ||
                  (dx == tileSize - 1 && dy == tileSize - 1);

              if (!isCorner) {
                final tileIdx = ((tx ~/ tileSize) + (ty ~/ tileSize) + seed) % 2;
                Color tileColor;
                if (dx == 1 || dy == 1) {
                  tileColor = palette.highlight;
                } else if (dx == tileSize - 2 || dy == tileSize - 2) {
                  tileColor = palette.colors[2];
                } else {
                  tileColor = tileIdx == 0 ? palette.primary : palette.secondary;
                }
                pixels[py * width + px] = addNoise(tileColor, random, 0.03);
              }
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Cracked earth with electric effect
class CrackedElectricTile extends TileBase {
  CrackedElectricTile(super.id);

  @override
  String get name => 'Cracked Electric';
  @override
  String get description => 'Cracked ground with electric energy';
  @override
  String get iconName => 'flash_on';
  @override
  TileCategory get category => TileCategory.special;
  @override
  TilePalette get palette => PlatformerPalettes.crackedElectric;
  @override
  List<String> get tags => ['electric', 'cracked', 'energy', 'hazard', 'platformer'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;
  @override
  int get frameSpeed => 150;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Green base
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
        Color baseColor;
        if (noiseVal < 0.4) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.7) {
          baseColor = palette.colors[2];
        } else {
          baseColor = palette.primary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    // Draw cracks with electric glow
    final crackRandom = Random(seed);
    var cx = crackRandom.nextInt(width ~/ 2);
    var cy = 0;

    while (cy < height) {
      if (cx >= 0 && cx < width) {
        // Electric glow around crack (flickers with frameIndex)
        final glowOn = (frameIndex + cx) % 2 == 0;
        if (glowOn) {
          pixels[cy * width + cx] = colorToInt(palette.highlight);
          // Side glow
          if (cx > 0) pixels[cy * width + cx - 1] = colorToInt(palette.secondary);
          if (cx < width - 1) pixels[cy * width + cx + 1] = colorToInt(palette.secondary);
        } else {
          pixels[cy * width + cx] = colorToInt(palette.shadow);
        }
      }
      cy++;
      cx += crackRandom.nextInt(3) - 1;
    }

    // Second crack
    cx = width ~/ 2 + crackRandom.nextInt(width ~/ 2);
    cy = 0;
    while (cy < height) {
      if (cx >= 0 && cx < width) {
        final glowOn = (frameIndex + cx + 1) % 2 == 0;
        pixels[cy * width + cx] = colorToInt(glowOn ? palette.highlight : palette.shadow);
      }
      cy++;
      cx += crackRandom.nextInt(3) - 1;
    }

    return pixels;
  }
}

/// Orange roof scale tile
class OrangeScaleTile extends TileBase {
  OrangeScaleTile(super.id);

  @override
  String get name => 'Orange Scale';
  @override
  String get description => 'Orange overlapping scale/shingle pattern';
  @override
  String get iconName => 'roofing';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => PlatformerPalettes.orangeScale;
  @override
  List<String> get tags => ['orange', 'scale', 'roof', 'shingle', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final scaleW = 4;
    final scaleH = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ scaleH;
        final offset = row % 2 == 1 ? scaleW ~/ 2 : 0;
        final scaleX = ((x + offset) % width) % scaleW;
        final scaleY = y % scaleH;

        // Create curved scale effect
        Color baseColor;
        if (scaleY == 0) {
          baseColor = palette.shadow; // Bottom shadow
        } else if (scaleY == 1 && (scaleX == 0 || scaleX == scaleW - 1)) {
          baseColor = palette.shadow; // Side shadows
        } else if (scaleY == scaleH - 1) {
          baseColor = palette.highlight; // Top highlight
        } else {
          final idx = (row + (x + offset) ~/ scaleW + seed) % 2;
          baseColor = idx == 0 ? palette.primary : palette.secondary;
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Deep water with visible stones at bottom
class DeepWaterStonesTile extends TileBase {
  DeepWaterStonesTile(super.id);

  @override
  String get name => 'Deep Water Stones';
  @override
  String get description => 'Deep water with stones visible at bottom';
  @override
  String get iconName => 'water';
  @override
  TileCategory get category => TileCategory.liquid;
  @override
  TilePalette get palette => PlatformerPalettes.deepWater;
  @override
  List<String> get tags => ['water', 'deep', 'stones', 'underwater', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final surfaceHeight = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        Color baseColor;

        if (y < surfaceHeight) {
          // Surface layer - lightest
          baseColor = y == 0 ? palette.highlight : palette.secondary;
        } else {
          // Depth gradient
          final depthT = (y - surfaceHeight) / (height - surfaceHeight);
          if (depthT < 0.3) {
            baseColor = palette.primary;
          } else if (depthT < 0.6) {
            baseColor = palette.colors[2];
          } else {
            baseColor = palette.shadow;
          }
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add stones at bottom
    final stoneY = height - 4;
    final stoneRandom = Random(seed + 100);
    for (int i = 0; i < 4; i++) {
      final sx = stoneRandom.nextInt(width - 2);
      final sw = stoneRandom.nextInt(3) + 2;

      for (int dx = 0; dx < sw; dx++) {
        for (int dy = 0; dy < 2; dy++) {
          final px = sx + dx;
          final py = stoneY + dy + stoneRandom.nextInt(2);
          if (px < width && py < height) {
            final stoneColor = dy == 0
                ? const Color(0xFF6A8AAA) // Light stone through water
                : const Color(0xFF4A6A8A); // Dark stone
            pixels[py * width + px] = colorToInt(stoneColor);
          }
        }
      }
    }

    return pixels;
  }
}

/// Wood plank tile
class WoodPlankTile extends TileBase {
  final bool vertical;

  WoodPlankTile(super.id, {this.vertical = true});

  @override
  String get name => 'Wood Plank';
  @override
  String get description => 'Wooden plank flooring';
  @override
  String get iconName => 'carpenter';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => PlatformerPalettes.woodPlank;
  @override
  List<String> get tags => ['wood', 'plank', 'floor', 'platformer'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final plankWidth = 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final plankPos = vertical ? x : y;
        final grainPos = vertical ? y : x;
        final plankIdx = plankPos ~/ plankWidth;

        // Gap between planks
        if (plankPos % plankWidth == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow);
          continue;
        }

        // Wood grain
        final grain = sin((grainPos + plankIdx * 7) / 2.5 + seed);
        Color baseColor;
        if (grain < -0.3) {
          baseColor = palette.colors[2]; // Dark grain
        } else if (grain < 0.3) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary; // Light
        }

        // Plank edge highlight
        final posInPlank = plankPos % plankWidth;
        if (posInPlank == 1) {
          baseColor = palette.highlight;
        } else if (posInPlank == plankWidth - 1) {
          baseColor = palette.colors[2];
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add knots
    if (random.nextDouble() < 0.3) {
      final kx = random.nextInt(width - 1);
      final ky = random.nextInt(height - 1);
      pixels[ky * width + kx] = colorToInt(palette.shadow);
    }

    return pixels;
  }
}

/// Snow/ice surface tile
class SnowIceTopTile extends TileBase {
  final int snowHeight;

  SnowIceTopTile(super.id, {this.snowHeight = 5});

  @override
  String get name => 'Snow Ice Top';
  @override
  String get description => 'Snow surface over ice';
  @override
  String get iconName => 'ac_unit';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => PlatformerPalettes.snowIce;
  @override
  List<String> get tags => ['snow', 'ice', 'winter', 'cold', 'platformer'];

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
        if (y < snowHeight) {
          // Snow layer
          final snowNoise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          Color snowColor;
          if (snowNoise > 0.7) {
            snowColor = palette.highlight; // Bright white
          } else if (snowNoise > 0.4) {
            snowColor = palette.primary; // White
          } else {
            snowColor = palette.secondary; // Light blue tint
          }
          pixels[y * width + x] = addNoise(snowColor, random, 0.02);
        } else {
          // Ice layer below
          final iceNoise = noise2D(x / 4.0 + seed, y / 4.0, 2);
          Color iceColor;
          if (iceNoise < 0.3) {
            iceColor = palette.shadow;
          } else if (iceNoise < 0.6) {
            iceColor = palette.colors[2];
          } else {
            iceColor = palette.secondary;
          }
          pixels[y * width + x] = addNoise(iceColor, random, 0.03);
        }
      }
    }

    // Snow drift edge
    for (int x = 0; x < width; x++) {
      final driftY = snowHeight + (sin(x / 3.0 + seed) * 1.5).round();
      if (driftY >= 0 && driftY < height) {
        pixels[driftY * width + x] = colorToInt(palette.primary);
      }
    }

    return pixels;
  }
}

/// Red brick wall tile
class RedBrickPlatformerTile extends TileBase {
  final int brickWidth;
  final int brickHeight;

  RedBrickPlatformerTile(super.id, {this.brickWidth = 5, this.brickHeight = 3});

  @override
  String get name => 'Red Brick';
  @override
  String get description => 'Classic red brick wall';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => PlatformerPalettes.redBrick;
  @override
  List<String> get tags => ['brick', 'red', 'wall', 'classic', 'platformer'];

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
          Color brickColor = palette.colors[brickIdx];

          // Brick edge shading
          final posInBrickX = adjustedX % brickWidth;
          final posInBrickY = y % brickHeight;
          if (posInBrickX == 1 || posInBrickY == 1) {
            brickColor = palette.highlight;
          } else if (posInBrickX == brickWidth - 2 || posInBrickY == brickHeight - 2) {
            brickColor = palette.colors[2];
          }

          pixels[y * width + x] = addNoise(brickColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}
