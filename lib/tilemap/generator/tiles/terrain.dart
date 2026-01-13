import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// TERRAIN TILES
// ============================================================================

/// Base class for terrain-type tiles
abstract class TerrainTile extends TileBase {
  TerrainTile(super.id);

  @override
  TileCategory get category => TileCategory.terrain;

  /// Noise scale for texture generation
  double get noiseScale => 4.0;

  /// Noise octaves for detail level
  int get noiseOctaves => 3;

  /// Noise intensity for color variation
  double get noiseIntensity => 0.05;
}

/// Grass terrain tile
class GrassTile extends TerrainTile {
  @override
  String get name => 'Grass';

  @override
  String get description => 'Lush green grass terrain';

  @override
  String get iconName => 'grass';

  @override
  TilePalette get palette => TilePalettes.grass;

  @override
  List<String> get tags => ['terrain', 'nature', 'ground', 'green'];

  final double bladesDensity;
  final bool includeFlowers;

  GrassTile(
    super.id, {
    this.bladesDensity = 0.3,
    this.includeFlowers = false,
  });

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill base color with noise
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / noiseScale + seed * 10, y / noiseScale, noiseOctaves);
        final colorIndex = (noiseVal * 2).floor().clamp(0, 2);
        final baseColor = palette.colors[colorIndex];
        pixels[y * width + x] = addNoise(baseColor, random, noiseIntensity);
      }
    }

    // Add grass blades
    final bladeCount = (width * height * bladesDensity).round();
    for (int i = 0; i < bladeCount; i++) {
      final bx = random.nextInt(width);
      final by = random.nextInt(height);
      if (random.nextDouble() < 0.7) {
        pixels[by * width + bx] = colorToInt(palette.highlight);
      }
    }

    // Add flowers for variation
    if (includeFlowers || variation == TileVariation.pristine) {
      if (random.nextDouble() < 0.3) {
        final fx = random.nextInt(width - 1) + 1;
        final fy = random.nextInt(height - 1) + 1;
        final flowerColor = random.nextBool() ? const Color(0xFFFFFF00) : const Color(0xFFFF6B8A);
        pixels[fy * width + fx] = colorToInt(flowerColor);
      }
    }

    // Add weathering
    if (variation == TileVariation.weathered) {
      final dirtCount = (width * height * 0.1).round();
      for (int i = 0; i < dirtCount; i++) {
        final dx = random.nextInt(width);
        final dy = random.nextInt(height);
        pixels[dy * width + dx] = colorToInt(TilePalettes.dirt.primary);
      }
    }

    return pixels;
  }
}

/// Dirt terrain tile
class DirtTile extends TerrainTile {
  @override
  String get name => 'Dirt';

  @override
  String get description => 'Earthy brown dirt terrain';

  @override
  String get iconName => 'terrain';

  @override
  TilePalette get palette => TilePalettes.dirt;

  @override
  List<String> get tags => ['terrain', 'ground', 'brown', 'earth'];

  final bool includeRocks;
  final double crackDensity;

  DirtTile(
    super.id, {
    this.includeRocks = true,
    this.crackDensity = 0.1,
  });

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with noisy dirt
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed * 7, y / 3.0, 2);
        final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.08);
      }
    }

    // Add rocks
    if (includeRocks) {
      final rockCount = random.nextInt(3) + 1;
      for (int i = 0; i < rockCount; i++) {
        final rx = random.nextInt(width);
        final ry = random.nextInt(height);
        pixels[ry * width + rx] = colorToInt(TilePalettes.stone.primary);
      }
    }

    // Add cracks
    if (variation == TileVariation.cracked || random.nextDouble() < crackDensity) {
      final startX = random.nextInt(width);
      final startY = random.nextInt(height);
      for (int i = 0; i < 3; i++) {
        final cx = (startX + i).clamp(0, width - 1);
        final cy = (startY + (random.nextBool() ? 1 : 0)).clamp(0, height - 1);
        pixels[cy * width + cx] = colorToInt(palette.shadow);
      }
    }

    return pixels;
  }
}

/// Sand terrain tile
class SandTile extends TerrainTile {
  SandTile(super.id);

  @override
  String get name => 'Sand';

  @override
  String get description => 'Desert sand terrain';

  @override
  String get iconName => 'beach_access';

  @override
  TilePalette get palette => TilePalettes.sand;

  @override
  List<String> get tags => ['terrain', 'desert', 'beach', 'yellow'];

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
        final noiseVal = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
        final colorIndex = (noiseVal * 3).floor().clamp(0, 2);
        pixels[y * width + x] = addNoise(palette.colors[colorIndex], random, 0.03);
      }
    }

    // Add pebbles
    if (random.nextDouble() < 0.2) {
      final px = random.nextInt(width);
      final py = random.nextInt(height);
      pixels[py * width + px] = colorToInt(TilePalettes.stone.primary);
    }

    return pixels;
  }
}

/// Snow terrain tile
class SnowTile extends TerrainTile {
  @override
  String get name => 'Snow';

  @override
  String get description => 'Fresh white snow terrain';

  @override
  String get iconName => 'ac_unit';

  @override
  TilePalette get palette => TilePalettes.snow;

  @override
  List<String> get tags => ['terrain', 'winter', 'cold', 'white'];

  final double sparkleIntensity;

  SnowTile(super.id, {this.sparkleIntensity = 0.1});

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
        final noiseVal = noise2D(x / 5.0 + seed * 3, y / 5.0, 2);
        final colorIndex = (noiseVal * 3).floor().clamp(0, 2);
        pixels[y * width + x] = colorToInt(palette.colors[colorIndex]);
      }
    }

    // Add sparkles
    final sparkleCount = (width * height * sparkleIntensity).round();
    for (int i = 0; i < sparkleCount; i++) {
      final sx = random.nextInt(width);
      final sy = random.nextInt(height);
      pixels[sy * width + sx] = 0xFFFFFFFF;
    }

    return pixels;
  }
}
