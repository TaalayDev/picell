import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'tile_palette.dart';

/// Configuration for tile generation
abstract class TileGeneratorConfig {
  /// Display name for this tile type
  String get name;

  /// Description of what this tile type represents
  String get description;

  /// Icon to display in the UI
  String get iconName;

  /// The palette to use for generating tiles
  TilePalette get palette;

  /// Width of tiles to generate
  int get tileWidth;

  /// Height of tiles to generate
  int get tileHeight;

  /// Generate a set of tiles based on this configuration
  List<GeneratedTile> generateTiles();

  /// Generate a single tile variant
  Uint32List generateTile(int variantIndex, Random random);
}

/// A generated tile with metadata
class GeneratedTile {
  final String name;
  final Uint32List pixels;
  final int width;
  final int height;
  final String category;
  final int variantIndex;

  const GeneratedTile({
    required this.name,
    required this.pixels,
    required this.width,
    required this.height,
    required this.category,
    required this.variantIndex,
  });
}

/// Base class for terrain tile generators
abstract class TerrainTileConfig extends TileGeneratorConfig {
  @override
  final int tileWidth;
  @override
  final int tileHeight;
  @override
  final TilePalette palette;

  /// Number of variants to generate
  final int variantCount;

  /// Random seed for reproducible generation
  final int? seed;

  TerrainTileConfig({
    required this.tileWidth,
    required this.tileHeight,
    required this.palette,
    this.variantCount = 4,
    this.seed,
  });

  @override
  List<GeneratedTile> generateTiles() {
    final random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final tiles = <GeneratedTile>[];

    for (int i = 0; i < variantCount; i++) {
      tiles.add(
        GeneratedTile(
          name: '$name ${i + 1}',
          pixels: generateTile(i, random),
          width: tileWidth,
          height: tileHeight,
          category: name,
          variantIndex: i,
        ),
      );
    }

    return tiles;
  }

  int variantSeed(int variantIndex) {
    final base = seed ?? 0;
    return base + (variantIndex * 997) + 17;
  }

  /// Helper to convert Color to ARGB int
  int colorToInt(Color color) {
    return color.value;
  }

  /// Helper to blend two colors
  int blendColors(Color c1, Color c2, double t) {
    final r = (c1.red + (c2.red - c1.red) * t).round();
    final g = (c1.green + (c2.green - c1.green) * t).round();
    final b = (c1.blue + (c2.blue - c1.blue) * t).round();
    final a = (c1.alpha + (c2.alpha - c1.alpha) * t).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Helper to add noise variation to a color
  int addNoise(Color baseColor, Random random, double intensity) {
    final variation = ((random.nextDouble() - 0.5) * 2 * intensity * 255)
        .round();
    final r = (baseColor.red + variation).clamp(0, 255);
    final g = (baseColor.green + variation).clamp(0, 255);
    final b = (baseColor.blue + variation).clamp(0, 255);
    return (baseColor.alpha << 24) | (r << 16) | (g << 8) | b;
  }

  /// Generate Perlin-like noise value
  double noise2D(double x, double y, Random random, int octaves) {
    double value = 0;
    double amplitude = 1;
    double frequency = 1;
    double maxValue = 0;

    for (int i = 0; i < octaves; i++) {
      value += amplitude * _smoothNoise(x * frequency, y * frequency, random);
      maxValue += amplitude;
      amplitude *= 0.5;
      frequency *= 2;
    }

    return value / maxValue;
  }

  double _smoothNoise(double x, double y, Random random) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    // Simple hash-based pseudo-random
    double hash(int x, int y) {
      final n = x + y * 57;
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      return h / 0x7fffffff;
    }

    final v1 = hash(ix, iy);
    final v2 = hash(ix + 1, iy);
    final v3 = hash(ix, iy + 1);
    final v4 = hash(ix + 1, iy + 1);

    final i1 = v1 + fx * (v2 - v1);
    final i2 = v3 + fx * (v4 - v3);

    return i1 + fy * (i2 - i1);
  }
}

/// Grass tile generator
class GrassTileConfig extends TerrainTileConfig {
  final double bladesDensity;
  final bool includeFlowers;

  GrassTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.bladesDensity = 0.3,
    this.includeFlowers = false,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.grass);

  @override
  String get name => 'Grass';

  @override
  String get description => 'Natural grass terrain with subtle variations';

  @override
  String get iconName => 'grass';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final style = variantIndex % 6;
    final variantRandom = Random(variantSeed(variantIndex));
    final styleBladesDensity = switch (style) {
      0 => bladesDensity * 0.6,
      1 => bladesDensity * 0.95,
      2 => bladesDensity * 1.35,
      3 => bladesDensity * 0.8,
      4 => bladesDensity * 0.5,
      _ => bladesDensity * 1.2,
    }.clamp(0.05, 0.95);
    final styleFlowers =
        includeFlowers || style == 1 || style == 4 || style == 5;
    final pixels = Uint32List(tileWidth * tileHeight);

    // Fill base color with noise
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseScale = switch (style) {
          2 => 3.0,
          3 => 5.0,
          4 => 6.0,
          _ => 4.0,
        };
        final noiseVal = noise2D(
          x / noiseScale + variantIndex * 10,
          y / noiseScale,
          variantRandom,
          3,
        );
        final colorIndex = (noiseVal * 2).floor().clamp(0, 2);
        final baseColor = palette.colors[colorIndex];
        final color = switch (style) {
          3 when noiseVal < 0.35 => palette.shadow,
          4 when noiseVal > 0.65 => palette.highlight,
          _ => baseColor,
        };
        pixels[y * tileWidth + x] = addNoise(color, variantRandom, 0.05);
      }
    }

    // Add grass blades
    final bladeCount = (tileWidth * tileHeight * styleBladesDensity).round();
    for (int i = 0; i < bladeCount; i++) {
      final x = variantRandom.nextInt(tileWidth);
      final y = variantRandom.nextInt(tileHeight);
      if (variantRandom.nextDouble() < 0.7) {
        pixels[y * tileWidth + x] = colorToInt(palette.highlight);
      }
    }

    // Add occasional flowers
    if (styleFlowers && variantRandom.nextDouble() < 0.45) {
      final fx = variantRandom.nextInt(tileWidth - 1) + 1;
      final fy = variantRandom.nextInt(tileHeight - 1) + 1;
      final flowerColor = variantRandom.nextBool()
          ? const Color(0xFFFFFF00) // Yellow
          : const Color(0xFFFF6B8A); // Pink
      pixels[fy * tileWidth + fx] = colorToInt(flowerColor);
    }

    return pixels;
  }
}

/// Dirt tile generator
class DirtTileConfig extends TerrainTileConfig {
  final bool includeRocks;
  final double crackDensity;

  DirtTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.includeRocks = true,
    this.crackDensity = 0.1,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.dirt);

  @override
  String get name => 'Dirt';

  @override
  String get description => 'Earthy dirt terrain with rocks and cracks';

  @override
  String get iconName => 'terrain';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final style = variantIndex % 6;
    final variantRandom = Random(variantSeed(variantIndex));
    final styleIncludeRocks = switch (style) {
      0 => false,
      4 => false,
      _ => includeRocks,
    };
    final styleCrackDensity = switch (style) {
      0 => crackDensity * 0.4,
      1 => crackDensity * 0.8,
      2 => crackDensity * 1.8,
      3 => crackDensity * 1.2,
      4 => crackDensity * 0.3,
      _ => crackDensity * 1.4,
    }.clamp(0.0, 1.0);
    final pixels = Uint32List(tileWidth * tileHeight);

    // Fill with noisy dirt
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseScale = switch (style) {
          0 => 4.5,
          2 => 2.3,
          _ => 3.0,
        };
        final noiseVal = noise2D(
          x / noiseScale + variantIndex * 7,
          y / noiseScale,
          variantRandom,
          2,
        );
        final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        final color = switch (style) {
          3 when noiseVal < 0.35 => palette.shadow,
          4 when noiseVal > 0.7 => palette.highlight,
          5 when noiseVal < 0.45 => Color.lerp(
            palette.primary,
            TilePalettes.grass.primary,
            0.25,
          )!,
          _ => baseColor,
        };
        pixels[y * tileWidth + x] = addNoise(color, variantRandom, 0.08);
      }
    }

    // Add small rocks
    if (styleIncludeRocks) {
      final rockCount = variantRandom.nextInt(3) + 1 + (style == 5 ? 1 : 0);
      for (int i = 0; i < rockCount; i++) {
        final rx = variantRandom.nextInt(tileWidth);
        final ry = variantRandom.nextInt(tileHeight);
        pixels[ry * tileWidth + rx] = colorToInt(TilePalettes.stone.primary);
      }
    }

    // Add cracks
    final crackSegments = (tileWidth * styleCrackDensity).round().clamp(
      0,
      tileWidth,
    );
    for (int segment = 0; segment < crackSegments; segment++) {
      final startX = variantRandom.nextInt(tileWidth);
      final startY = variantRandom.nextInt(tileHeight);
      final length = variantRandom.nextInt((tileWidth / 2).ceil()) + 1;
      for (int i = 0; i < length; i++) {
        final cx = (startX + i).clamp(0, tileWidth - 1);
        final cy = (startY + (variantRandom.nextBool() ? 1 : 0)).clamp(
          0,
          tileHeight - 1,
        );
        pixels[cy * tileWidth + cx] = colorToInt(palette.shadow);
      }
    }

    return pixels;
  }
}

/// Stone tile generator
class StoneTileConfig extends TerrainTileConfig {
  final bool addCracks;
  final bool addMoss;

  StoneTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.addCracks = true,
    this.addMoss = false,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.stone);

  @override
  String get name => 'Stone';

  @override
  String get description => 'Rocky stone terrain with natural patterns';

  @override
  String get iconName => 'landscape';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    // Fill with stone pattern
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseVal = noise2D(
          x / 2.0 + variantIndex * 5,
          y / 2.0,
          random,
          3,
        );
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

    // Add highlight spots
    for (int i = 0; i < 2; i++) {
      final hx = random.nextInt(tileWidth);
      final hy = random.nextInt(tileHeight);
      pixels[hy * tileWidth + hx] = colorToInt(palette.highlight);
    }

    // Add cracks
    if (addCracks && random.nextDouble() < 0.4) {
      _addCrack(pixels, random);
    }

    // Add moss
    if (addMoss && random.nextDouble() < 0.3) {
      final mossCount = random.nextInt(4) + 2;
      for (int i = 0; i < mossCount; i++) {
        final mx = random.nextInt(tileWidth);
        final my = random.nextInt(tileHeight);
        pixels[my * tileWidth + mx] = colorToInt(TilePalettes.grass.primary);
      }
    }

    return pixels;
  }

  void _addCrack(Uint32List pixels, Random random) {
    var x = random.nextInt(tileWidth);
    var y = 0;
    while (y < tileHeight && x >= 0 && x < tileWidth) {
      pixels[y * tileWidth + x] = colorToInt(palette.shadow);
      y++;
      x += random.nextInt(3) - 1;
    }
  }
}

/// Water tile generator
class WaterTileConfig extends TerrainTileConfig {
  final bool animated;
  final double waveIntensity;

  WaterTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.animated = false,
    this.waveIntensity = 0.5,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.water);

  @override
  String get name => 'Water';

  @override
  String get description => 'Flowing water with wave patterns';

  @override
  String get iconName => 'water_drop';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    // Create wave pattern
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final wave =
            sin((x + variantIndex * 3) / 3.0 + y / 4.0) * waveIntensity;
        final noiseVal = noise2D(x / 4.0, y / 4.0, random, 2);
        final combined = (wave + noiseVal) / 2;

        Color baseColor;
        if (combined < 0.3) {
          baseColor = palette.shadow;
        } else if (combined < 0.6) {
          baseColor = palette.primary;
        } else if (combined < 0.8) {
          baseColor = palette.secondary;
        } else {
          baseColor = palette.highlight;
        }
        pixels[y * tileWidth + x] = colorToInt(baseColor);
      }
    }

    // Add foam highlights
    if (random.nextDouble() < 0.4) {
      final foamX = random.nextInt(tileWidth);
      final foamY = random.nextInt(tileHeight);
      pixels[foamY * tileWidth + foamX] = colorToInt(palette.highlight);
    }

    return pixels;
  }
}

/// Brick tile generator
class BrickTileConfig extends TerrainTileConfig {
  final int brickWidth;
  final int brickHeight;
  final bool staggered;

  BrickTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.brickWidth = 8,
    this.brickHeight = 4,
    this.staggered = true,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.brick);

  @override
  String get name => 'Brick';

  @override
  String get description => 'Classic brick pattern with mortar lines';

  @override
  String get iconName => 'grid_view';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);
    final mortarColor = palette.shadow;

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final row = y ~/ brickHeight;
        final offset = staggered && row % 2 == 1 ? brickWidth ~/ 2 : 0;
        final adjustedX = (x + offset) % tileWidth;

        // Check if on mortar line
        final isHorizontalMortar = y % brickHeight == 0;
        final isVerticalMortar = adjustedX % brickWidth == 0;

        if (isHorizontalMortar || isVerticalMortar) {
          pixels[y * tileWidth + x] = colorToInt(mortarColor);
        } else {
          // Brick color with variation
          final brickIndex = (row + adjustedX ~/ brickWidth) % 3;
          final baseColor = brickIndex == 0
              ? palette.primary
              : brickIndex == 1
              ? palette.secondary
              : palette.accent;
          pixels[y * tileWidth + x] = addNoise(baseColor, random, 0.06);
        }
      }
    }

    return pixels;
  }
}

/// Wood/Plank tile generator
class WoodTileConfig extends TerrainTileConfig {
  final bool vertical;
  final int plankWidth;

  WoodTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.vertical = false,
    this.plankWidth = 4,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.wood);

  @override
  String get name => 'Wood';

  @override
  String get description => 'Wooden planks with grain texture';

  @override
  String get iconName => 'carpenter';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final plankPos = vertical ? x : y;
        final grainPos = vertical ? y : x;
        final plankIndex = plankPos ~/ plankWidth;

        // Plank gap
        if (plankPos % plankWidth == 0) {
          pixels[y * tileWidth + x] = colorToInt(palette.shadow);
          continue;
        }

        // Wood grain
        final grain = sin((grainPos + plankIndex * 3) / 2.0 + variantIndex);
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

    // Add knots
    if (random.nextDouble() < 0.2) {
      final kx = random.nextInt(tileWidth - 2) + 1;
      final ky = random.nextInt(tileHeight - 2) + 1;
      pixels[ky * tileWidth + kx] = colorToInt(palette.shadow);
    }

    return pixels;
  }
}

/// Lava tile generator
class LavaTileConfig extends TerrainTileConfig {
  final double bubbleDensity;

  LavaTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.bubbleDensity = 0.1,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.lava);

  @override
  String get name => 'Lava';

  @override
  String get description => 'Molten lava with glowing patterns';

  @override
  String get iconName => 'whatshot';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseVal = noise2D(
          x / 3.0 + variantIndex * 4,
          y / 3.0,
          random,
          2,
        );
        Color baseColor;
        if (noiseVal < 0.25) {
          baseColor = palette.shadow;
        } else if (noiseVal < 0.5) {
          baseColor = palette.primary;
        } else if (noiseVal < 0.75) {
          baseColor = palette.secondary;
        } else {
          baseColor = palette.highlight;
        }
        pixels[y * tileWidth + x] = colorToInt(baseColor);
      }
    }

    // Add bubbles
    final bubbleCount = (tileWidth * tileHeight * bubbleDensity).round();
    for (int i = 0; i < bubbleCount; i++) {
      final bx = random.nextInt(tileWidth);
      final by = random.nextInt(tileHeight);
      pixels[by * tileWidth + bx] = colorToInt(palette.highlight);
    }

    return pixels;
  }
}

/// Crystal tile generator
class CrystalTileConfig extends TerrainTileConfig {
  CrystalTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.crystal);

  @override
  String get name => 'Crystal';

  @override
  String get description => 'Mystical crystal formations';

  @override
  String get iconName => 'diamond';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final pixels = Uint32List(tileWidth * tileHeight);

    // Base fill
    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        pixels[y * tileWidth + x] = colorToInt(palette.shadow);
      }
    }

    // Draw crystal facets
    final crystalCount = random.nextInt(2) + 1;
    for (int c = 0; c < crystalCount; c++) {
      final cx = random.nextInt(tileWidth);
      final cy = random.nextInt(tileHeight);
      final size = random.nextInt(4) + 2;

      for (int dy = -size; dy <= size; dy++) {
        for (int dx = -size + dy.abs(); dx <= size - dy.abs(); dx++) {
          final px = cx + dx;
          final py = cy + dy;
          if (px >= 0 && px < tileWidth && py >= 0 && py < tileHeight) {
            final dist = (dx.abs() + dy.abs()) / size;
            final color = dist < 0.3
                ? palette.highlight
                : dist < 0.6
                ? palette.secondary
                : palette.primary;
            pixels[py * tileWidth + px] = colorToInt(color);
          }
        }
      }
    }

    // Add sparkles
    for (int i = 0; i < 2; i++) {
      final sx = random.nextInt(tileWidth);
      final sy = random.nextInt(tileHeight);
      pixels[sy * tileWidth + sx] = 0xFFFFFFFF; // White
    }

    return pixels;
  }
}

/// Snow tile generator
class SnowTileConfig extends TerrainTileConfig {
  final double sparkleIntensity;
  final double driftStrength;

  SnowTileConfig({
    required super.tileWidth,
    required super.tileHeight,
    super.variantCount = 4,
    super.seed,
    this.sparkleIntensity = 0.1,
    this.driftStrength = 0.0,
    TilePalette? customPalette,
  }) : super(palette: customPalette ?? TilePalettes.snow);

  @override
  String get name => 'Snow';

  @override
  String get description => 'Fresh snow with subtle sparkles';

  @override
  String get iconName => 'ac_unit';

  @override
  Uint32List generateTile(int variantIndex, Random random) {
    final style = variantIndex % 6;
    final variantRandom = Random(variantSeed(variantIndex));
    final styleSparkleIntensity = switch (style) {
      0 => sparkleIntensity * 0.4,
      1 => sparkleIntensity,
      2 => sparkleIntensity * 1.8,
      3 => sparkleIntensity * 0.75,
      4 => sparkleIntensity * 0.9,
      _ => sparkleIntensity * 1.35,
    };
    final styleDriftStrength = switch (style) {
      0 => driftStrength,
      1 => driftStrength + 0.15,
      2 => driftStrength + 0.32,
      3 => driftStrength + 0.48,
      4 => driftStrength + 0.24,
      _ => driftStrength + 0.4,
    }.clamp(0.0, 1.0);
    final pixels = Uint32List(tileWidth * tileHeight);

    for (int y = 0; y < tileHeight; y++) {
      for (int x = 0; x < tileWidth; x++) {
        final noiseVal = noise2D(
          x / 5.0 + variantIndex * 3,
          y / 5.0,
          variantRandom,
          2,
        );
        final colorIndex = (noiseVal * 3).floor().clamp(0, 2);
        var color = palette.colors[colorIndex];
        if (styleDriftStrength > 0) {
          final driftLine =
              sin((x / tileWidth) * pi * 3 + variantIndex) +
              cos((y / tileHeight) * pi * 2);
          if (driftLine > (1.1 - styleDriftStrength)) {
            color = palette.highlight;
          } else if (driftLine < (-0.7 + styleDriftStrength * 0.35)) {
            color = palette.shadow;
          }
        }
        pixels[y * tileWidth + x] = colorToInt(color);
      }
    }

    // Add sparkles
    final sparkleCount = (tileWidth * tileHeight * styleSparkleIntensity)
        .round();
    for (int i = 0; i < sparkleCount; i++) {
      final sx = variantRandom.nextInt(tileWidth);
      final sy = variantRandom.nextInt(tileHeight);
      pixels[sy * tileWidth + sx] = 0xFFFFFFFF;
    }

    return pixels;
  }
}
