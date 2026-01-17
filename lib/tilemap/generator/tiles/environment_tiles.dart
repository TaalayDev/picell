import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// ENVIRONMENT TILE PALETTES
// ============================================================================

class EnvironmentPalettes {
  EnvironmentPalettes._();

  // ===== CAVE/UNDERGROUND PALETTES =====

  static const caveFloor = TilePalette(
    name: 'Cave Floor',
    colors: [
      Color(0xFF4A4A4A), // Base dark gray
      Color(0xFF5A5A5A), // Light gray
      Color(0xFF3A3A3A), // Dark gray
      Color(0xFF6A6A6A), // Highlight
      Color(0xFF2A2A2A), // Shadow
    ],
  );

  static const stalactite = TilePalette(
    name: 'Stalactite',
    colors: [
      Color(0xFF6A6A6A), // Base stone
      Color(0xFF8A8A8A), // Light tip
      Color(0xFF4A4A4A), // Dark base
      Color(0xFFAAAAAA), // Highlight
      Color(0xFF3A3A3A), // Shadow
    ],
  );

  static const glowingFungus = TilePalette(
    name: 'Glowing Fungus',
    colors: [
      Color(0xFF2A4A4A), // Dark teal base
      Color(0xFF4AFFFF), // Bright cyan glow
      Color(0xFF2A8A8A), // Medium cyan
      Color(0xFF8AFFFF), // Highlight
      Color(0xFF1A2A2A), // Shadow
    ],
  );

  static const undergroundLake = TilePalette(
    name: 'Underground Lake',
    colors: [
      Color(0xFF1A3A5A), // Deep dark blue
      Color(0xFF2A4A6A), // Medium blue
      Color(0xFF0A2A4A), // Darkest
      Color(0xFF4A6A8A), // Surface reflection
      Color(0xFF0A1A2A), // Abyss
    ],
  );

  // ===== SWAMP/MARSH PALETTES =====

  static const swampMud = TilePalette(
    name: 'Swamp Mud',
    colors: [
      Color(0xFF4A3A2A), // Brown mud base
      Color(0xFF5A4A3A), // Light mud
      Color(0xFF3A2A1A), // Dark mud
      Color(0xFF6A5A4A), // Wet highlight
      Color(0xFF2A1A0A), // Deep mud
    ],
  );

  static const swampWater = TilePalette(
    name: 'Swamp Water',
    colors: [
      Color(0xFF3A5A3A), // Murky green
      Color(0xFF4A6A4A), // Light green
      Color(0xFF2A4A2A), // Dark green
      Color(0xFF5A7A5A), // Surface
      Color(0xFF1A3A1A), // Deep
    ],
  );

  static const lilyPad = TilePalette(
    name: 'Lily Pad',
    colors: [
      Color(0xFF4A8A4A), // Pad green
      Color(0xFF5A9A5A), // Light green
      Color(0xFF3A7A3A), // Dark green
      Color(0xFFFFAACC), // Flower pink
      Color(0xFF2A5A2A), // Shadow
    ],
  );

  static const bog = TilePalette(
    name: 'Bog',
    colors: [
      Color(0xFF3A4A3A), // Sickly green-brown
      Color(0xFF4A5A4A), // Light
      Color(0xFF2A3A2A), // Dark
      Color(0xFF5A6A5A), // Moss highlight
      Color(0xFF1A2A1A), // Shadow
    ],
  );

  // ===== INTERIOR PALETTES =====

  static const carpet = TilePalette(
    name: 'Carpet',
    colors: [
      Color(0xFF8A3A3A), // Red base
      Color(0xFFAA5A5A), // Light red
      Color(0xFF6A2A2A), // Dark red
      Color(0xFFCA7A7A), // Highlight
      Color(0xFF4A1A1A), // Shadow
    ],
  );

  static const wallpaper = TilePalette(
    name: 'Wallpaper',
    colors: [
      Color(0xFFE8D8C8), // Cream base
      Color(0xFFF8E8D8), // Light cream
      Color(0xFFD8C8B8), // Dark cream
      Color(0xFFB89878), // Pattern color
      Color(0xFFA88868), // Shadow
    ],
  );

  static const tileMosaic = TilePalette(
    name: 'Tile Mosaic',
    colors: [
      Color(0xFF4A7AAA), // Blue tile
      Color(0xFFFFFFFF), // White tile
      Color(0xFFDAA520), // Gold accent
      Color(0xFF2A5A8A), // Dark blue
      Color(0xFF3A3A3A), // Grout
    ],
  );

  // ===== FARM/RURAL PALETTES =====

  static const tilledSoil = TilePalette(
    name: 'Tilled Soil',
    colors: [
      Color(0xFF5A4030), // Rich dark soil
      Color(0xFF6A5040), // Light soil
      Color(0xFF4A3020), // Dark soil
      Color(0xFF7A6050), // Highlight
      Color(0xFF3A2010), // Shadow
    ],
  );

  static const hayStraw = TilePalette(
    name: 'Hay/Straw',
    colors: [
      Color(0xFFD4B870), // Golden straw
      Color(0xFFE4C880), // Light straw
      Color(0xFFC4A860), // Dark straw
      Color(0xFFF4D890), // Highlight
      Color(0xFFA48840), // Shadow
    ],
  );

  static const wheatField = TilePalette(
    name: 'Wheat Field',
    colors: [
      Color(0xFFD4A840), // Wheat gold
      Color(0xFFE4B850), // Light wheat
      Color(0xFFC49830), // Dark wheat
      Color(0xFF7A9A4A), // Stem green
      Color(0xFF4A5A2A), // Shadow
    ],
  );

  static const fencePath = TilePalette(
    name: 'Fence Path',
    colors: [
      Color(0xFFAA8A60), // Path tan
      Color(0xFFBA9A70), // Light path
      Color(0xFF9A7A50), // Dark path
      Color(0xFF6A5040), // Fence brown
      Color(0xFF4A3020), // Shadow
    ],
  );

  // ===== TRANSITION PALETTES =====

  static const shoreline = TilePalette(
    name: 'Shoreline',
    colors: [
      Color(0xFFE8D4A8), // Sand
      Color(0xFF4A8ABA), // Water blue
      Color(0xFFD4C090), // Wet sand
      Color(0xFFFFFFFF), // Foam
      Color(0xFF3A6A8A), // Deep water
    ],
  );

  static const pathEdge = TilePalette(
    name: 'Path Edge',
    colors: [
      Color(0xFFB8A080), // Path tan
      Color(0xFF5A9A3A), // Grass green
      Color(0xFF9A8A70), // Dark path
      Color(0xFF7ABA5A), // Light grass
      Color(0xFF4A7A2A), // Dark grass
    ],
  );
}

// ============================================================================
// CAVE/UNDERGROUND TILES
// ============================================================================

/// Cave floor with uneven rocky texture
class CaveFloorTile extends TileBase {
  CaveFloorTile(super.id, {this.hasPuddles = false});

  final bool hasPuddles;

  @override
  String get name => hasPuddles ? 'Cave Floor Wet' : 'Cave Floor';
  @override
  String get description => 'Dark rocky cave floor';
  @override
  String get iconName => 'landscape';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => EnvironmentPalettes.caveFloor;
  @override
  List<String> get tags => ['cave', 'underground', 'floor', 'rock'];

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
        final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 3);
        Color baseColor;

        if (noiseVal > 0.6) {
          baseColor = palette.secondary;
        } else if (noiseVal > 0.3) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.colors[2];
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.08);
      }
    }

    // Add puddles if enabled
    if (hasPuddles) {
      final puddleColor = const Color(0xFF2A4A6A);
      for (int i = 0; i < 3; i++) {
        final px = random.nextInt(width - 3) + 1;
        final py = random.nextInt(height - 2) + 1;
        final pw = random.nextInt(3) + 2;
        for (int dy = 0; dy < 2; dy++) {
          for (int dx = 0; dx < pw; dx++) {
            if (px + dx < width && py + dy < height) {
              pixels[(py + dy) * width + px + dx] = addNoise(puddleColor, random, 0.05);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Stalactite/stalagmite cave ceiling or floor
class StalactiteTile extends TileBase {
  StalactiteTile(super.id, {this.pointingDown = true});

  final bool pointingDown;

  @override
  String get name => pointingDown ? 'Stalactite' : 'Stalagmite';
  @override
  String get description => pointingDown ? 'Cave ceiling formations' : 'Cave floor formations';
  @override
  String get iconName => 'arrow_downward';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => EnvironmentPalettes.stalactite;
  @override
  List<String> get tags => ['cave', 'underground', 'formation', 'stalactite'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with cave background
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate spikes
    final spikeCount = width ~/ 3;
    for (int i = 0; i < spikeCount; i++) {
      final spikeX = random.nextInt(width);
      final spikeHeight = random.nextInt(height ~/ 2) + height ~/ 3;
      final spikeWidth = random.nextInt(2) + 1;

      for (int sy = 0; sy < spikeHeight; sy++) {
        final actualY = pointingDown ? sy : height - 1 - sy;
        final taper = (1 - sy / spikeHeight) * spikeWidth;

        for (int sx = -taper.round(); sx <= taper.round(); sx++) {
          final px = spikeX + sx;
          if (px >= 0 && px < width && actualY >= 0 && actualY < height) {
            final intensity = sy / spikeHeight;
            Color spikeColor;
            if (intensity < 0.3) {
              spikeColor = palette.secondary; // Tip is lighter
            } else if (intensity < 0.7) {
              spikeColor = palette.primary;
            } else {
              spikeColor = palette.colors[2];
            }
            pixels[actualY * width + px] = addNoise(spikeColor, random, 0.05);
          }
        }
      }
    }

    return pixels;
  }
}

/// Glowing bioluminescent fungus tile
class GlowingFungusTile extends TileBase {
  GlowingFungusTile(super.id, {this.density = 0.3});

  final double density;

  @override
  String get name => 'Glowing Fungus';
  @override
  String get description => 'Bioluminescent cave mushrooms';
  @override
  String get iconName => 'brightness_7';
  @override
  TileCategory get category => TileCategory.dungeon;
  @override
  TilePalette get palette => EnvironmentPalettes.glowingFungus;
  @override
  List<String> get tags => ['cave', 'underground', 'fungus', 'glow', 'magic'];
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
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Dark cave background
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = addNoise(palette.primary, random, 0.05);
      }
    }

    // Pulse effect
    final pulse = sin((frameIndex / frameCount) * 2 * pi) * 0.3 + 0.7;

    // Add glowing mushrooms
    final mushroomSeeds = Random(seed);
    final mushroomCount = (width * height * density * 0.02).round().clamp(2, 8);

    for (int m = 0; m < mushroomCount; m++) {
      final mx = mushroomSeeds.nextInt(width - 2) + 1;
      final my = mushroomSeeds.nextInt(height - 3) + 2;

      // Mushroom stem
      for (int sy = 0; sy < 2; sy++) {
        if (my + sy < height) {
          pixels[(my + sy) * width + mx] = colorToInt(palette.colors[2]);
        }
      }

      // Glowing cap
      final glowColor = Color.lerp(palette.secondary, palette.highlight, pulse)!;
      for (int dy = -1; dy <= 0; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final px = mx + dx;
          final py = my + dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            pixels[py * width + px] = colorToInt(glowColor);
          }
        }
      }

      // Glow aura
      for (int dy = -2; dy <= 1; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          if (dx.abs() + dy.abs() > 2) continue;
          final px = mx + dx;
          final py = my + dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            final existing = Color(pixels[py * width + px]);
            final glow = Color.lerp(existing, palette.secondary, pulse * 0.3)!;
            pixels[py * width + px] = colorToInt(glow);
          }
        }
      }
    }

    return pixels;
  }
}

/// Underground lake/pool tile
class UndergroundLakeTile extends TileBase {
  UndergroundLakeTile(super.id);

  @override
  String get name => 'Underground Lake';
  @override
  String get description => 'Dark still underground water';
  @override
  String get iconName => 'water';
  @override
  TileCategory get category => TileCategory.liquid;
  @override
  TilePalette get palette => EnvironmentPalettes.undergroundLake;
  @override
  List<String> get tags => ['cave', 'underground', 'water', 'lake'];
  @override
  bool get animated => true;
  @override
  int get frameCount => 4;
  @override
  int get frameSpeed => 400;

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

    final waveOffset = frameIndex * 0.5;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Subtle wave pattern
        final wave = sin((x + waveOffset) / 4.0) * 0.1 + sin((y + waveOffset * 0.5) / 3.0) * 0.1;
        final depth = y / height;

        Color waterColor;
        if (depth + wave < 0.2) {
          waterColor = palette.highlight; // Surface reflection
        } else if (depth + wave < 0.5) {
          waterColor = palette.secondary;
        } else if (depth + wave < 0.8) {
          waterColor = palette.primary;
        } else {
          waterColor = palette.colors[2];
        }

        pixels[y * width + x] = addNoise(waterColor, random, 0.03);
      }
    }

    return pixels;
  }
}

// ============================================================================
// SWAMP/MARSH TILES
// ============================================================================

/// Swamp mud terrain
class SwampMudTile extends TileBase {
  SwampMudTile(super.id, {this.hasRipples = false});

  final bool hasRipples;

  @override
  String get name => hasRipples ? 'Swamp Mud Wet' : 'Swamp Mud';
  @override
  String get description => 'Thick murky swamp mud';
  @override
  String get iconName => 'water_damage';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.swampMud;
  @override
  List<String> get tags => ['swamp', 'mud', 'marsh', 'terrain'];

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
        final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 2);
        Color mudColor;

        if (noiseVal > 0.6) {
          mudColor = palette.secondary; // Lighter mud
        } else if (noiseVal > 0.3) {
          mudColor = palette.primary;
        } else {
          mudColor = palette.colors[2]; // Darker mud
        }

        pixels[y * width + x] = addNoise(mudColor, random, 0.06);
      }
    }

    // Add wet spots/ripples
    if (hasRipples) {
      final wetColor = palette.highlight;
      for (int i = 0; i < 4; i++) {
        final cx = random.nextInt(width);
        final cy = random.nextInt(height);
        for (int r = 0; r < 2; r++) {
          _drawCircle(pixels, width, height, cx, cy, r + 1, wetColor, random);
        }
      }
    }

    return pixels;
  }

  void _drawCircle(Uint32List pixels, int w, int h, int cx, int cy, int r, Color color, Random random) {
    for (int y = cy - r; y <= cy + r; y++) {
      for (int x = cx - r; x <= cx + r; x++) {
        if (x >= 0 && x < w && y >= 0 && y < h) {
          final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
          if (dist >= r - 0.5 && dist <= r + 0.5) {
            pixels[y * w + x] = addNoise(color, random, 0.03);
          }
        }
      }
    }
  }
}

/// Murky swamp water
class SwampWaterTile extends TileBase {
  SwampWaterTile(super.id);

  @override
  String get name => 'Swamp Water';
  @override
  String get description => 'Murky green swamp water';
  @override
  String get iconName => 'water';
  @override
  TileCategory get category => TileCategory.liquid;
  @override
  TilePalette get palette => EnvironmentPalettes.swampWater;
  @override
  List<String> get tags => ['swamp', 'water', 'marsh', 'liquid'];
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
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final offset = frameIndex * 0.3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final murk = noise2D((x + offset) / 5.0 + seed, (y + offset * 0.5) / 5.0, 2);

        Color waterColor;
        if (murk > 0.6) {
          waterColor = palette.secondary;
        } else if (murk > 0.3) {
          waterColor = palette.primary;
        } else {
          waterColor = palette.colors[2];
        }

        // Surface scum
        if (y < 2 && random.nextDouble() > 0.7) {
          waterColor = palette.highlight;
        }

        pixels[y * width + x] = addNoise(waterColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Lily pad covered water
class LilyPadTile extends TileBase {
  LilyPadTile(super.id, {this.hasFlowers = false});

  final bool hasFlowers;

  @override
  String get name => hasFlowers ? 'Lily Pads Flowering' : 'Lily Pads';
  @override
  String get description => 'Water surface with lily pads';
  @override
  String get iconName => 'local_florist';
  @override
  TileCategory get category => TileCategory.liquid;
  @override
  TilePalette get palette => EnvironmentPalettes.lilyPad;
  @override
  List<String> get tags => ['swamp', 'water', 'lily', 'plant'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Water base
    final waterColor = const Color(0xFF3A6A5A);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = addNoise(waterColor, random, 0.04);
      }
    }

    // Add lily pads
    final padCount = random.nextInt(3) + 2;
    for (int p = 0; p < padCount; p++) {
      final cx = random.nextInt(width - 4) + 2;
      final cy = random.nextInt(height - 4) + 2;
      final size = random.nextInt(2) + 2;

      // Draw oval pad
      for (int dy = -size; dy <= size; dy++) {
        for (int dx = -size - 1; dx <= size + 1; dx++) {
          final dist = sqrt(pow(dx * 0.8, 2) + pow(dy, 2));
          if (dist <= size) {
            final px = cx + dx;
            final py = cy + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              Color padColor = dist < size * 0.6 ? palette.secondary : palette.primary;
              // Notch in pad
              if (dx < 0 && dy.abs() < 1 && dist < size * 0.5) {
                padColor = waterColor;
              }
              pixels[py * width + px] = colorToInt(padColor);
            }
          }
        }
      }

      // Add flower if enabled
      if (hasFlowers && random.nextDouble() > 0.5) {
        if (cx >= 0 && cx < width && cy - size - 1 >= 0) {
          pixels[(cy - size - 1) * width + cx] = colorToInt(palette.highlight);
          if (cx + 1 < width) {
            pixels[(cy - size - 1) * width + cx + 1] = colorToInt(palette.highlight);
          }
        }
      }
    }

    return pixels;
  }
}

/// Bog/peat terrain
class BogTile extends TileBase {
  BogTile(super.id);

  @override
  String get name => 'Bog';
  @override
  String get description => 'Wet peat bog terrain';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.bog;
  @override
  List<String> get tags => ['swamp', 'bog', 'marsh', 'peat'];

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
        final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 3);

        Color bogColor;
        if (noiseVal > 0.65) {
          bogColor = palette.highlight; // Moss patches
        } else if (noiseVal > 0.4) {
          bogColor = palette.secondary;
        } else if (noiseVal > 0.2) {
          bogColor = palette.primary;
        } else {
          bogColor = palette.colors[2];
        }

        pixels[y * width + x] = addNoise(bogColor, random, 0.05);
      }
    }

    // Add small pools
    for (int i = 0; i < 2; i++) {
      final px = random.nextInt(width - 2);
      final py = random.nextInt(height - 2);
      final poolColor = const Color(0xFF2A3A2A);
      for (int dy = 0; dy < 2; dy++) {
        for (int dx = 0; dx < 2; dx++) {
          if (px + dx < width && py + dy < height) {
            pixels[(py + dy) * width + px + dx] = colorToInt(poolColor);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// INTERIOR TILES
// ============================================================================

/// Carpet floor tile
class CarpetTile extends TileBase {
  CarpetTile(super.id, {this.color = CarpetColor.red});

  final CarpetColor color;

  @override
  String get name => 'Carpet ${color.name.substring(0, 1).toUpperCase()}${color.name.substring(1)}';
  @override
  String get description => 'Soft floor carpet';
  @override
  String get iconName => 'square';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => color.palette;
  @override
  List<String> get tags => ['interior', 'carpet', 'floor', 'soft'];

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
        // Carpet weave pattern
        final weaveX = (x + y) % 2 == 0;
        final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);

        Color carpetColor;
        if (weaveX) {
          carpetColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        } else {
          carpetColor = noiseVal > 0.5 ? palette.secondary : palette.colors[2];
        }

        pixels[y * width + x] = addNoise(carpetColor, random, 0.03);
      }
    }

    return pixels;
  }
}

enum CarpetColor {
  red(EnvironmentPalettes.carpet),
  blue(TilePalette(
    name: 'Blue Carpet',
    colors: [
      Color(0xFF3A5A8A),
      Color(0xFF4A6A9A),
      Color(0xFF2A4A7A),
      Color(0xFF5A7AAA),
      Color(0xFF1A3A5A),
    ],
  )),
  green(TilePalette(
    name: 'Green Carpet',
    colors: [
      Color(0xFF3A6A3A),
      Color(0xFF4A7A4A),
      Color(0xFF2A5A2A),
      Color(0xFF5A8A5A),
      Color(0xFF1A4A1A),
    ],
  )),
  purple(TilePalette(
    name: 'Purple Carpet',
    colors: [
      Color(0xFF5A3A6A),
      Color(0xFF6A4A7A),
      Color(0xFF4A2A5A),
      Color(0xFF7A5A8A),
      Color(0xFF3A1A4A),
    ],
  ));

  final TilePalette palette;
  const CarpetColor(this.palette);
}

/// Decorative wallpaper tile
class WallpaperTile extends TileBase {
  WallpaperTile(super.id, {this.pattern = WallpaperPattern.striped});

  final WallpaperPattern pattern;

  @override
  String get name => 'Wallpaper ${pattern.name.substring(0, 1).toUpperCase()}${pattern.name.substring(1)}';
  @override
  String get description => 'Decorative wall covering';
  @override
  String get iconName => 'wallpaper';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => EnvironmentPalettes.wallpaper;
  @override
  List<String> get tags => ['interior', 'wall', 'wallpaper', 'decoration'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base color
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(palette.primary, random, 0.02);
    }

    switch (pattern) {
      case WallpaperPattern.striped:
        // Vertical stripes
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            if (x % 4 < 2) {
              pixels[y * width + x] = addNoise(palette.secondary, random, 0.02);
            }
          }
        }
        break;

      case WallpaperPattern.damask:
        // Damask pattern
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final patternVal = sin(x / 2.0) * cos(y / 2.0);
            if (patternVal > 0.3) {
              pixels[y * width + x] = addNoise(palette.highlight, random, 0.03);
            }
          }
        }
        break;

      case WallpaperPattern.floral:
        // Simple floral dots
        for (int cy = 2; cy < height; cy += 5) {
          for (int cx = 2; cx < width; cx += 5) {
            final offset = (cy ~/ 5) % 2 == 0 ? 0 : 2;
            final px = cx + offset;
            if (px < width) {
              pixels[cy * width + px] = colorToInt(palette.highlight);
              if (px + 1 < width) {
                pixels[cy * width + px + 1] = colorToInt(palette.highlight);
              }
              if (cy + 1 < height) {
                pixels[(cy + 1) * width + px] = colorToInt(palette.highlight);
              }
            }
          }
        }
        break;
    }

    return pixels;
  }
}

enum WallpaperPattern { striped, damask, floral }

/// Decorative mosaic tile
class MosaicTile extends TileBase {
  MosaicTile(super.id);

  @override
  String get name => 'Mosaic';
  @override
  String get description => 'Decorative tile mosaic';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  TilePalette get palette => EnvironmentPalettes.tileMosaic;
  @override
  List<String> get tags => ['interior', 'mosaic', 'tile', 'decoration'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final tileSize = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final tileX = x ~/ tileSize;
        final tileY = y ~/ tileSize;
        final isGrout = x % tileSize == 0 || y % tileSize == 0;

        if (isGrout) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          // Alternating pattern
          final patternIdx = (tileX + tileY) % 4;
          Color tileColor;
          switch (patternIdx) {
            case 0:
              tileColor = palette.primary; // Blue
              break;
            case 1:
              tileColor = palette.secondary; // White
              break;
            case 2:
              tileColor = palette.accent; // Gold
              break;
            default:
              tileColor = palette.colors[3]; // Dark blue
          }
          pixels[y * width + x] = addNoise(tileColor, random, 0.03);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// FARM/RURAL TILES
// ============================================================================

/// Tilled farmland soil
class TilledSoilTile extends TileBase {
  TilledSoilTile(super.id, {this.hasSeeds = false});

  final bool hasSeeds;

  @override
  String get name => hasSeeds ? 'Tilled Soil Seeded' : 'Tilled Soil';
  @override
  String get description => 'Plowed farmland ready for planting';
  @override
  String get iconName => 'agriculture';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.tilledSoil;
  @override
  List<String> get tags => ['farm', 'soil', 'agriculture', 'dirt'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final rowHeight = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final inRow = y % rowHeight;

        Color soilColor;
        if (inRow == 0) {
          // Ridge top (lighter)
          soilColor = palette.secondary;
        } else if (inRow == rowHeight - 1) {
          // Furrow (darker)
          soilColor = palette.shadow;
        } else {
          soilColor = palette.primary;
        }

        pixels[y * width + x] = addNoise(soilColor, random, 0.05);
      }
    }

    // Add seeds if enabled
    if (hasSeeds) {
      final seedColor = const Color(0xFF4A6A3A);
      for (int row = 0; row < height ~/ rowHeight; row++) {
        final seedY = row * rowHeight + 1;
        for (int x = 2; x < width; x += 4) {
          if (seedY < height && random.nextDouble() > 0.3) {
            pixels[seedY * width + x] = colorToInt(seedColor);
          }
        }
      }
    }

    return pixels;
  }
}

/// Hay/straw surface
class HayTile extends TileBase {
  HayTile(super.id, {this.isBaled = false});

  final bool isBaled;

  @override
  String get name => isBaled ? 'Hay Bale' : 'Loose Hay';
  @override
  String get description => isBaled ? 'Bundled hay bale' : 'Scattered hay and straw';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.hayStraw;
  @override
  List<String> get tags => ['farm', 'hay', 'straw', 'rural'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    if (isBaled) {
      // Baled hay - horizontal strands
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final strand = y % 3;
          Color hayColor;
          if (strand == 0) {
            hayColor = palette.shadow; // Twine line
          } else if ((x + y) % 5 == 0) {
            hayColor = palette.secondary;
          } else {
            hayColor = palette.primary;
          }
          pixels[y * width + x] = addNoise(hayColor, random, 0.04);
        }
      }
    } else {
      // Loose hay - random strands
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
          Color hayColor;
          if (noiseVal > 0.6) {
            hayColor = palette.highlight;
          } else if (noiseVal > 0.3) {
            hayColor = palette.secondary;
          } else {
            hayColor = palette.primary;
          }
          pixels[y * width + x] = addNoise(hayColor, random, 0.05);
        }
      }

      // Add some darker strands
      for (int i = 0; i < width * 2; i++) {
        final x = random.nextInt(width);
        final y = random.nextInt(height);
        pixels[y * width + x] = addNoise(palette.shadow, random, 0.03);
      }
    }

    return pixels;
  }
}

/// Wheat field
class WheatFieldTile extends TileBase {
  WheatFieldTile(super.id, {this.mature = true});

  final bool mature;

  @override
  String get name => mature ? 'Wheat Field Mature' : 'Wheat Field Young';
  @override
  String get description => mature ? 'Golden ripe wheat' : 'Young green wheat';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.wheatField;
  @override
  List<String> get tags => ['farm', 'wheat', 'crops', 'field'];
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
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Wave motion
    final waveOffset = sin(frameIndex / frameCount * 2 * pi) * 0.5;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final wave = sin((x + waveOffset * 2) / 3.0) * 1.5;
        final adjustedY = y + wave.round();

        Color wheatColor;
        if (mature) {
          // Golden wheat
          if (adjustedY < height * 0.3) {
            wheatColor = palette.secondary; // Wheat heads
          } else if (adjustedY < height * 0.6) {
            wheatColor = palette.primary; // Stalks
          } else {
            wheatColor = palette.highlight; // Stems
          }
        } else {
          // Green young wheat
          if (adjustedY < height * 0.4) {
            wheatColor = const Color(0xFF8ABA6A); // Tips
          } else {
            wheatColor = palette.highlight; // Base
          }
        }

        pixels[y * width + x] = addNoise(wheatColor, random, 0.05);
      }
    }

    return pixels;
  }
}

// ============================================================================
// TRANSITION/EDGE TILES
// ============================================================================

/// Shoreline transition tile (water to sand)
class ShorelineTile extends TileBase {
  ShorelineTile(super.id, {this.direction = EdgeDirection.top});

  final EdgeDirection direction;

  @override
  String get name => 'Shoreline ${direction.name.substring(0, 1).toUpperCase()}${direction.name.substring(1)}';
  @override
  String get description => 'Beach shoreline transition';
  @override
  String get iconName => 'waves';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.shoreline;
  @override
  List<String> get tags => ['transition', 'shore', 'beach', 'water', 'edge'];
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
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final waveOffset = frameIndex * 1.5;
    final transitionLine = height * 0.4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Wave edge varies with animation
        final wave = sin((x + waveOffset) / 3.0) * 2;
        final effectiveY = direction == EdgeDirection.top ? y : height - 1 - y;
        final transitionY = transitionLine + wave;

        Color pixelColor;
        if (effectiveY < transitionY - 2) {
          // Water
          pixelColor = palette.secondary;
        } else if (effectiveY < transitionY) {
          // Foam
          pixelColor = palette.highlight;
        } else if (effectiveY < transitionY + 2) {
          // Wet sand
          pixelColor = palette.accent;
        } else {
          // Dry sand
          pixelColor = palette.primary;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.03);
      }
    }

    return pixels;
  }
}

/// Path to grass edge transition
class PathEdgeTile extends TileBase {
  PathEdgeTile(super.id, {this.direction = EdgeDirection.top});

  final EdgeDirection direction;

  @override
  String get name => 'Path Edge ${direction.name.substring(0, 1).toUpperCase()}${direction.name.substring(1)}';
  @override
  String get description => 'Grass to path transition';
  @override
  String get iconName => 'timeline';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => EnvironmentPalettes.pathEdge;
  @override
  List<String> get tags => ['transition', 'path', 'grass', 'edge'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final transitionLine = height * 0.5;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Irregular edge
        final edgeNoise = noise2D(x / 2.0 + seed, 0, 2) * 3;
        final effectiveY = direction == EdgeDirection.top ? y : height - 1 - y;
        final transitionY = transitionLine + edgeNoise;

        Color pixelColor;
        if (effectiveY < transitionY - 1) {
          // Grass side
          final grassNoise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          pixelColor = grassNoise > 0.5 ? palette.secondary : palette.highlight;
        } else if (effectiveY < transitionY + 1) {
          // Edge
          pixelColor = palette.accent;
        } else {
          // Path side
          final pathNoise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          pixelColor = pathNoise > 0.5 ? palette.primary : palette.accent;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Snow to grass transition
class SnowEdgeTile extends TileBase {
  SnowEdgeTile(super.id, {this.direction = EdgeDirection.top});

  final EdgeDirection direction;

  @override
  String get name => 'Snow Edge ${direction.name.substring(0, 1).toUpperCase()}${direction.name.substring(1)}';
  @override
  String get description => 'Snow to grass transition';
  @override
  String get iconName => 'ac_unit';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  TilePalette get palette => TilePalettes.snow;
  @override
  List<String> get tags => ['transition', 'snow', 'grass', 'edge'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final transitionLine = height * 0.5;
    final grassColor = const Color(0xFF5A9A3A);
    final grassDark = const Color(0xFF4A7A2A);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Irregular melting edge
        final edgeNoise = noise2D(x / 2.0 + seed, 0, 3) * 4;
        final effectiveY = direction == EdgeDirection.top ? y : height - 1 - y;
        final transitionY = transitionLine + edgeNoise;

        Color pixelColor;
        if (effectiveY < transitionY - 2) {
          // Snow
          final snowNoise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          pixelColor = snowNoise > 0.5 ? palette.primary : palette.secondary;
        } else if (effectiveY < transitionY) {
          // Slushy edge
          pixelColor = palette.shadow;
        } else {
          // Grass
          final grassNoise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          pixelColor = grassNoise > 0.5 ? grassColor : grassDark;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.03);
      }
    }

    return pixels;
  }
}

enum EdgeDirection { top, bottom, left, right }
