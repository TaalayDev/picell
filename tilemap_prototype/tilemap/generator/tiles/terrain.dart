import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../../../core/property_spec.dart';
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

  List<Uint32List> _generateStyledVariants({
    required int width,
    required int height,
    required int count,
    int? baseSeed,
    required List<_TerrainVariantRecipe> recipes,
    required TileBase Function(_TerrainVariantRecipe recipe) buildTile,
  }) {
    final random = Random(baseSeed ?? 0);
    return List.generate(count, (index) {
      final recipe = recipes[index % recipes.length];
      final recipeSeed = baseSeed == null
          ? random.nextInt(1000000)
          : baseSeed + recipe.seedOffset + (index * 997);
      return buildTile(recipe).generate(
        width: width,
        height: height,
        seed: recipeSeed,
        variation: recipe.variation,
      );
    });
  }
}

class _TerrainVariantRecipe {
  const _TerrainVariantRecipe({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.bladesDensity,
    this.includeFlowers,
    this.includeRocks,
    this.crackDensity,
    this.pebbleChance,
    this.rippleStrength,
    this.sparkleIntensity,
    this.driftStrength,
  });

  final int seedOffset;
  final TileVariation variation;
  final double? bladesDensity;
  final bool? includeFlowers;
  final bool? includeRocks;
  final double? crackDensity;
  final double? pebbleChance;
  final double? rippleStrength;
  final double? sparkleIntensity;
  final double? driftStrength;
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

  GrassTile(super.id, {this.bladesDensity = 0.3, this.includeFlowers = false});

  @override
  List<PropertySpec> getPropertySpecs() => [
    SliderSpec(
      key: 'bladesDensity',
      label: 'Blade Density',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: bladesDensity,
      formatLabel: _percentLabel,
    ),
    BoolSpec(
      key: 'includeFlowers',
      label: 'Include Flowers',
      initialValue: includeFlowers,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return GrassTile(
      id,
      bladesDensity:
          (properties['bladesDensity'] as num?)?.toDouble() ?? bladesDensity,
      includeFlowers: properties['includeFlowers'] as bool? ?? includeFlowers,
    );
  }

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

    // Fill base color with noise
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(
          x / noiseScale + seed * 10,
          y / noiseScale,
          noiseOctaves,
        );
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

    // Add flowers for pristine/flower variant
    if (includeFlowers || variation == TileVariation.pristine) {
      if (random.nextDouble() < 0.3) {
        final fx = random.nextInt(width - 1) + 1;
        final fy = random.nextInt(height - 1) + 1;
        final flowerColor = random.nextBool()
            ? const Color(0xFFFFFF00)
            : const Color(0xFFFF6B8A);
        pixels[fy * width + fx] = colorToInt(flowerColor);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }

  @override
  List<Uint32List> generateVariants({
    required int width,
    required int height,
    int count = 4,
    int? baseSeed,
  }) {
    const recipes = [
      _TerrainVariantRecipe(seedOffset: 11, bladesDensity: 0.18),
      _TerrainVariantRecipe(
        seedOffset: 97,
        bladesDensity: 0.38,
        includeFlowers: true,
        variation: TileVariation.pristine,
      ),
      _TerrainVariantRecipe(
        seedOffset: 181,
        bladesDensity: 0.52,
        variation: TileVariation.overgrown,
      ),
      _TerrainVariantRecipe(
        seedOffset: 263,
        bladesDensity: 0.24,
        variation: TileVariation.weathered,
      ),
      _TerrainVariantRecipe(
        seedOffset: 347,
        bladesDensity: 0.14,
        includeFlowers: true,
        variation: TileVariation.frozen,
      ),
      _TerrainVariantRecipe(
        seedOffset: 431,
        bladesDensity: 0.46,
        includeFlowers: true,
      ),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => GrassTile(
        id,
        bladesDensity: recipe.bladesDensity ?? bladesDensity,
        includeFlowers: recipe.includeFlowers ?? includeFlowers,
      ),
    );
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

  DirtTile(super.id, {this.includeRocks = true, this.crackDensity = 0.1});

  @override
  List<PropertySpec> getPropertySpecs() => [
    BoolSpec(
      key: 'includeRocks',
      label: 'Include Rocks',
      initialValue: includeRocks,
    ),
    SliderSpec(
      key: 'crackDensity',
      label: 'Crack Density',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: crackDensity,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return DirtTile(
      id,
      includeRocks: properties['includeRocks'] as bool? ?? includeRocks,
      crackDensity:
          (properties['crackDensity'] as num?)?.toDouble() ?? crackDensity,
    );
  }

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

    final crackCount = (width * crackDensity).round();
    for (int i = 0; i < crackCount; i++) {
      final startX = random.nextInt(width);
      final y = random.nextInt(height);
      final length = random.nextInt((width / 2).ceil()) + 1;
      for (int dx = 0; dx < length; dx++) {
        final px = startX + dx;
        if (px >= width) break;
        pixels[y * width + px] = colorToInt(palette.shadow);
      }
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }

  @override
  List<Uint32List> generateVariants({
    required int width,
    required int height,
    int count = 4,
    int? baseSeed,
  }) {
    const recipes = [
      _TerrainVariantRecipe(
        seedOffset: 29,
        includeRocks: false,
        crackDensity: 0.04,
      ),
      _TerrainVariantRecipe(
        seedOffset: 113,
        includeRocks: true,
        crackDensity: 0.08,
      ),
      _TerrainVariantRecipe(
        seedOffset: 197,
        includeRocks: true,
        crackDensity: 0.22,
        variation: TileVariation.cracked,
      ),
      _TerrainVariantRecipe(
        seedOffset: 281,
        includeRocks: true,
        crackDensity: 0.12,
        variation: TileVariation.weathered,
      ),
      _TerrainVariantRecipe(
        seedOffset: 367,
        includeRocks: false,
        crackDensity: 0.03,
        variation: TileVariation.pristine,
      ),
      _TerrainVariantRecipe(
        seedOffset: 449,
        includeRocks: true,
        crackDensity: 0.16,
        variation: TileVariation.mossy,
      ),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => DirtTile(
        id,
        includeRocks: recipe.includeRocks ?? includeRocks,
        crackDensity: recipe.crackDensity ?? crackDensity,
      ),
    );
  }
}

/// Sand terrain tile
class SandTile extends TerrainTile {
  final double pebbleChance;
  final double rippleStrength;

  SandTile(super.id, {this.pebbleChance = 0.2, this.rippleStrength = 0.0});

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
  List<PropertySpec> getPropertySpecs() => [
    SliderSpec(
      key: 'pebbleChance',
      label: 'Pebble Chance',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: pebbleChance,
      formatLabel: _percentLabel,
    ),
    SliderSpec(
      key: 'rippleStrength',
      label: 'Ripple Strength',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: rippleStrength,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return SandTile(
      id,
      pebbleChance:
          (properties['pebbleChance'] as num?)?.toDouble() ?? pebbleChance,
      rippleStrength:
          (properties['rippleStrength'] as num?)?.toDouble() ?? rippleStrength,
    );
  }

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
        final noiseVal = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
        final colorIndex = (noiseVal * 3).floor().clamp(0, 2);
        var pixelColor = addNoise(palette.colors[colorIndex], random, 0.03);
        if (rippleStrength > 0) {
          final ripple = sin((x / width) * pi * 4 + (y / height) * pi * 2);
          if (ripple > (0.55 - rippleStrength * 0.35)) {
            pixelColor = colorToInt(palette.highlight);
          } else if (ripple < (-0.6 + rippleStrength * 0.25)) {
            pixelColor = colorToInt(palette.shadow);
          }
        }
        pixels[y * width + x] = pixelColor;
      }
    }

    // Add pebbles
    final pebbleCount = (width * height * pebbleChance * 0.08).round();
    for (int i = 0; i < pebbleCount; i++) {
      final px = random.nextInt(width);
      final py = random.nextInt(height);
      pixels[py * width + px] = colorToInt(
        random.nextBool() ? TilePalettes.stone.primary : palette.shadow,
      );
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }

  @override
  List<Uint32List> generateVariants({
    required int width,
    required int height,
    int count = 4,
    int? baseSeed,
  }) {
    const recipes = [
      _TerrainVariantRecipe(
        seedOffset: 41,
        pebbleChance: 0.05,
        rippleStrength: 0.0,
      ),
      _TerrainVariantRecipe(
        seedOffset: 127,
        pebbleChance: 0.15,
        rippleStrength: 0.25,
      ),
      _TerrainVariantRecipe(
        seedOffset: 211,
        pebbleChance: 0.08,
        rippleStrength: 0.55,
        variation: TileVariation.pristine,
      ),
      _TerrainVariantRecipe(
        seedOffset: 293,
        pebbleChance: 0.28,
        rippleStrength: 0.12,
        variation: TileVariation.weathered,
      ),
      _TerrainVariantRecipe(
        seedOffset: 379,
        pebbleChance: 0.18,
        rippleStrength: 0.48,
        variation: TileVariation.frozen,
      ),
      _TerrainVariantRecipe(
        seedOffset: 461,
        pebbleChance: 0.35,
        rippleStrength: 0.2,
      ),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => SandTile(
        id,
        pebbleChance: recipe.pebbleChance ?? pebbleChance,
        rippleStrength: recipe.rippleStrength ?? rippleStrength,
      ),
    );
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
  final double driftStrength;

  SnowTile(super.id, {this.sparkleIntensity = 0.1, this.driftStrength = 0.0});

  @override
  List<PropertySpec> getPropertySpecs() => [
    SliderSpec(
      key: 'sparkleIntensity',
      label: 'Sparkle Intensity',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: sparkleIntensity,
      formatLabel: _percentLabel,
    ),
    SliderSpec(
      key: 'driftStrength',
      label: 'Drift Strength',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: driftStrength,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return SnowTile(
      id,
      sparkleIntensity:
          (properties['sparkleIntensity'] as num?)?.toDouble() ??
          sparkleIntensity,
      driftStrength:
          (properties['driftStrength'] as num?)?.toDouble() ?? driftStrength,
    );
  }

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
        final noiseVal = noise2D(x / 5.0 + seed * 3, y / 5.0, 2);
        final colorIndex = (noiseVal * 3).floor().clamp(0, 2);
        var color = colorToInt(palette.colors[colorIndex]);
        if (driftStrength > 0) {
          final driftLine =
              sin((x / width) * pi * 3 + seed * 0.001) +
              cos((y / height) * pi * 2);
          if (driftLine > (1.1 - driftStrength)) {
            color = colorToInt(palette.highlight);
          } else if (driftLine < (-0.7 + driftStrength * 0.35)) {
            color = colorToInt(palette.shadow);
          }
        }
        pixels[y * width + x] = color;
      }
    }

    // Add sparkles
    final sparkleCount = (width * height * sparkleIntensity).round();
    for (int i = 0; i < sparkleCount; i++) {
      final sx = random.nextInt(width);
      final sy = random.nextInt(height);
      pixels[sy * width + sx] = 0xFFFFFFFF;
    }

    applyVariationEffects(pixels, width, height, random, variation);
    return pixels;
  }

  @override
  List<Uint32List> generateVariants({
    required int width,
    required int height,
    int count = 4,
    int? baseSeed,
  }) {
    const recipes = [
      _TerrainVariantRecipe(
        seedOffset: 53,
        sparkleIntensity: 0.04,
        driftStrength: 0.0,
      ),
      _TerrainVariantRecipe(
        seedOffset: 139,
        sparkleIntensity: 0.12,
        driftStrength: 0.18,
      ),
      _TerrainVariantRecipe(
        seedOffset: 223,
        sparkleIntensity: 0.22,
        driftStrength: 0.36,
        variation: TileVariation.pristine,
      ),
      _TerrainVariantRecipe(
        seedOffset: 307,
        sparkleIntensity: 0.08,
        driftStrength: 0.52,
        variation: TileVariation.weathered,
      ),
      _TerrainVariantRecipe(
        seedOffset: 389,
        sparkleIntensity: 0.1,
        driftStrength: 0.28,
        variation: TileVariation.frozen,
      ),
      _TerrainVariantRecipe(
        seedOffset: 473,
        sparkleIntensity: 0.16,
        driftStrength: 0.44,
      ),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => SnowTile(
        id,
        sparkleIntensity: recipe.sparkleIntensity ?? sparkleIntensity,
        driftStrength: recipe.driftStrength ?? driftStrength,
      ),
    );
  }
}

String _percentLabel(double value) => '${(value * 100).round()}%';
