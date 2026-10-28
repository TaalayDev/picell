import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../../../core/property_spec.dart';
import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// LIQUID TILES
// ============================================================================

/// Base class for liquid tiles
abstract class LiquidTile extends TileBase {
  LiquidTile(super.id);

  @override
  TileCategory get category => TileCategory.liquid;

  @override
  bool get supportsRotation => true;

  @override
  bool get supportsAutoTiling => true;

  List<Uint32List> _generateStyledVariants({
    required int width,
    required int height,
    required int count,
    int? baseSeed,
    required List<_LiquidVariantRecipe> recipes,
    required TileBase Function(_LiquidVariantRecipe recipe) buildTile,
  }) {
    final random = Random(baseSeed ?? 0);
    return List.generate(count, (index) {
      final recipe = recipes[index % recipes.length];
      final recipeSeed = baseSeed == null
          ? random.nextInt(1000000)
          : baseSeed + recipe.seedOffset + (index * 977);
      return buildTile(recipe).generate(
        width: width,
        height: height,
        seed: recipeSeed,
        variation: recipe.variation,
      );
    });
  }
}

class _LiquidVariantRecipe {
  const _LiquidVariantRecipe({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.deep,
    this.foamAmount,
    this.currentStrength,
    this.bubbleRate,
    this.crustAmount,
    this.toxicGlow,
    this.viscosity,
    this.rainbowSheen,
    this.slickStrength,
  });

  final int seedOffset;
  final TileVariation variation;
  final bool? deep;
  final double? foamAmount;
  final double? currentStrength;
  final double? bubbleRate;
  final double? crustAmount;
  final double? toxicGlow;
  final double? viscosity;
  final bool? rainbowSheen;
  final double? slickStrength;
}

/// Water tile with wave animations
class WaterTile extends LiquidTile {
  @override
  String get name => 'Water';

  @override
  String get description => 'Flowing water surface';

  @override
  String get iconName => 'water_drop';

  @override
  TilePalette get palette => TilePalettes.water;

  @override
  List<String> get tags => ['liquid', 'water', 'ocean', 'river'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 200;

  final bool deep;
  final double foamAmount;
  final double currentStrength;

  WaterTile(
    super.id, {
    this.deep = false,
    this.foamAmount = 0.25,
    this.currentStrength = 0.5,
  });

  @override
  List<PropertySpec> getPropertySpecs() => [
    BoolSpec(key: 'deep', label: 'Deep Water', initialValue: deep),
    SliderSpec(
      key: 'foamAmount',
      label: 'Foam Amount',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: foamAmount,
      formatLabel: _percentLabel,
    ),
    SliderSpec(
      key: 'currentStrength',
      label: 'Current Strength',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: currentStrength,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return WaterTile(
      id,
      deep: properties['deep'] as bool? ?? deep,
      foamAmount: (properties['foamAmount'] as num?)?.toDouble() ?? foamAmount,
      currentStrength:
          (properties['currentStrength'] as num?)?.toDouble() ??
          currentStrength,
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
    // Generate just one frame by default (frame 0)
    // For animated display, the UI will request generateFrame
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex * 17);
    final pixels = Uint32List(width * height);
    final pal = palette;

    // Base color
    final baseColor = deep ? pal.shadow : pal.primary;

    // Movement offset based on frame
    final offset = frameIndex * (width / 4) * (0.65 + currentStrength);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Wave pattern
        final wave =
            sin(((x + offset) / width.toDouble()) * 2 * pi) *
            (1.0 + currentStrength);
        final wave2 =
            cos(((y + offset / 2) / height.toDouble()) * 4 * pi) *
            (0.8 + currentStrength);

        // Apply wave brightness
        final brightness = (wave + wave2) / 6.0;
        final rippleNoise = noise2D(
          x / (3.0 - currentStrength.clamp(0.0, 0.8)),
          y / 3.0 + seed * 0.001,
          2,
        );

        Color pixelColor = baseColor;

        if (brightness > (0.25 - foamAmount * 0.18) ||
            rippleNoise > (0.82 - foamAmount * 0.3)) {
          pixelColor = pal.highlight; // Foam/Sparkle
        } else if (brightness > 0.1) {
          pixelColor = pal.secondary;
        } else if (brightness < -0.2) {
          pixelColor = pal.shadow;
        }

        if (variation == TileVariation.pristine && random.nextDouble() < 0.06) {
          pixelColor = pal.highlight;
        } else if (variation == TileVariation.frozen && brightness > 0.05) {
          pixelColor = const Color(0xFFD8F0FF);
        } else if (variation == TileVariation.overgrown &&
            rippleNoise > 0.7 &&
            random.nextDouble() < 0.35) {
          pixelColor = const Color(0xFF4D8C4A);
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.05);
      }
    }

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
      _LiquidVariantRecipe(
        seedOffset: 13,
        deep: false,
        foamAmount: 0.18,
        currentStrength: 0.25,
      ),
      _LiquidVariantRecipe(
        seedOffset: 101,
        deep: false,
        foamAmount: 0.45,
        currentStrength: 0.7,
        variation: TileVariation.pristine,
      ),
      _LiquidVariantRecipe(
        seedOffset: 187,
        deep: true,
        foamAmount: 0.08,
        currentStrength: 0.2,
      ),
      _LiquidVariantRecipe(
        seedOffset: 271,
        deep: true,
        foamAmount: 0.16,
        currentStrength: 0.45,
        variation: TileVariation.overgrown,
      ),
      _LiquidVariantRecipe(
        seedOffset: 359,
        deep: false,
        foamAmount: 0.22,
        currentStrength: 0.35,
        variation: TileVariation.frozen,
      ),
      _LiquidVariantRecipe(
        seedOffset: 443,
        deep: true,
        foamAmount: 0.3,
        currentStrength: 0.85,
      ),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => WaterTile(
        id,
        deep: recipe.deep ?? deep,
        foamAmount: recipe.foamAmount ?? foamAmount,
        currentStrength: recipe.currentStrength ?? currentStrength,
      ),
    );
  }
}

/// Lava tile with bubbling animation
class LavaTile extends LiquidTile {
  final double bubbleRate;
  final double crustAmount;

  LavaTile(super.id, {this.bubbleRate = 0.25, this.crustAmount = 0.3});

  @override
  String get name => 'Lava';

  @override
  String get description => 'Molten lava surface';

  @override
  String get iconName => 'local_fire_department';

  @override
  TilePalette get palette => TilePalettes.lava;

  @override
  List<String> get tags => ['liquid', 'lava', 'fire', 'danger'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 250;

  @override
  List<PropertySpec> getPropertySpecs() => [
    SliderSpec(
      key: 'bubbleRate',
      label: 'Bubble Rate',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: bubbleRate,
      formatLabel: _percentLabel,
    ),
    SliderSpec(
      key: 'crustAmount',
      label: 'Crust Amount',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: crustAmount,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return LavaTile(
      id,
      bubbleRate: (properties['bubbleRate'] as num?)?.toDouble() ?? bubbleRate,
      crustAmount:
          (properties['crustAmount'] as num?)?.toDouble() ?? crustAmount,
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
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex);
    final pixels = Uint32List(width * height);
    final pal = palette;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Heat blobs
        final blob1 =
            sin((x / width * 3 * pi) + frameIndex * 0.5) * cos(y / height * pi);
        final blob2 =
            sin((y / height * 3 * pi) - frameIndex * 0.3) * cos(x / width * pi);
        final heat = (blob1 + blob2) / 2.0;

        Color pixelColor;

        if (heat > (0.62 + crustAmount * 0.15)) {
          pixelColor = pal.highlight; // Hot spots
        } else if (heat > (0.22 + crustAmount * 0.1)) {
          pixelColor = pal.accent; // Bright orange
        } else if (heat > (-0.2 + crustAmount * 0.18)) {
          pixelColor = pal.primary; // Base red
        } else {
          pixelColor = pal.shadow; // Cooled crust
        }

        if (variation == TileVariation.pristine && heat > 0.15) {
          pixelColor = pal.highlight;
        } else if (variation == TileVariation.cracked && heat < 0.05) {
          pixelColor = pal.shadow;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.05);
      }
    }

    // Occasional bubbles
    final bubbleCount = (bubbleRate * 8).round() + random.nextInt(2);
    for (int i = 0; i < bubbleCount; i++) {
      final bx = random.nextInt(width - 2) + 1;
      final by = random.nextInt(height - 2) + 1;
      pixels[by * width + bx] = colorToInt(pal.highlight);
      pixels[(by - 1) * width + bx] = colorToInt(pal.secondary);
      pixels[(by + 1) * width + bx] = colorToInt(pal.shadow);
    }

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
      _LiquidVariantRecipe(seedOffset: 17, bubbleRate: 0.1, crustAmount: 0.45),
      _LiquidVariantRecipe(
        seedOffset: 103,
        bubbleRate: 0.32,
        crustAmount: 0.28,
      ),
      _LiquidVariantRecipe(
        seedOffset: 191,
        bubbleRate: 0.5,
        crustAmount: 0.12,
        variation: TileVariation.pristine,
      ),
      _LiquidVariantRecipe(
        seedOffset: 277,
        bubbleRate: 0.08,
        crustAmount: 0.6,
        variation: TileVariation.cracked,
      ),
      _LiquidVariantRecipe(
        seedOffset: 367,
        bubbleRate: 0.22,
        crustAmount: 0.52,
        variation: TileVariation.weathered,
      ),
      _LiquidVariantRecipe(seedOffset: 457, bubbleRate: 0.42, crustAmount: 0.2),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => LavaTile(
        id,
        bubbleRate: recipe.bubbleRate ?? bubbleRate,
        crustAmount: recipe.crustAmount ?? crustAmount,
      ),
    );
  }
}

class AcidTile extends LiquidTile {
  AcidTile(super.id, {this.bubbleRate = 0.3, this.toxicGlow = 0.45});

  final double bubbleRate;
  final double toxicGlow;

  @override
  String get name => 'Acid';

  @override
  String get description => 'Corrosive acid pool with caustic glow';

  @override
  String get iconName => 'science';

  @override
  TilePalette get palette => TilePalettes.acid;

  @override
  List<String> get tags => ['liquid', 'acid', 'corrosive', 'toxic'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 220;

  @override
  List<PropertySpec> getPropertySpecs() => [
    SliderSpec(
      key: 'bubbleRate',
      label: 'Bubble Rate',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: bubbleRate,
      formatLabel: _percentLabel,
    ),
    SliderSpec(
      key: 'toxicGlow',
      label: 'Toxic Glow',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: toxicGlow,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return AcidTile(
      id,
      bubbleRate: (properties['bubbleRate'] as num?)?.toDouble() ?? bubbleRate,
      toxicGlow: (properties['toxicGlow'] as num?)?.toDouble() ?? toxicGlow,
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
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex * 23);
    final pixels = Uint32List(width * height);
    final pal = palette;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final swirl =
            sin((x / width) * pi * 3 + frameIndex * 0.6) +
            cos((y / height) * pi * 2 - frameIndex * 0.4);
        final noiseVal = noise2D(x / 3.0 + seed * 0.002, y / 3.0, 2);
        Color pixelColor;
        if (swirl + noiseVal > (1.0 - toxicGlow)) {
          pixelColor = pal.highlight;
        } else if (noiseVal > 0.55) {
          pixelColor = pal.secondary;
        } else if (swirl < -0.3) {
          pixelColor = pal.shadow;
        } else {
          pixelColor = pal.primary;
        }

        if (variation == TileVariation.pristine && random.nextDouble() < 0.08) {
          pixelColor = pal.highlight;
        } else if (variation == TileVariation.overgrown && noiseVal > 0.6) {
          pixelColor = pal.accent;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.06);
      }
    }

    final bubbleCount = (bubbleRate * 8).round();
    for (int i = 0; i < bubbleCount; i++) {
      final bx = random.nextInt(width - 2) + 1;
      final by = random.nextInt(height - 2) + 1;
      pixels[by * width + bx] = colorToInt(pal.highlight);
      pixels[(by - 1) * width + bx] = colorToInt(pal.secondary);
    }

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
      _LiquidVariantRecipe(seedOffset: 31, bubbleRate: 0.12, toxicGlow: 0.28),
      _LiquidVariantRecipe(seedOffset: 119, bubbleRate: 0.26, toxicGlow: 0.46),
      _LiquidVariantRecipe(
        seedOffset: 203,
        bubbleRate: 0.34,
        toxicGlow: 0.72,
        variation: TileVariation.pristine,
      ),
      _LiquidVariantRecipe(
        seedOffset: 289,
        bubbleRate: 0.18,
        toxicGlow: 0.35,
        variation: TileVariation.overgrown,
      ),
      _LiquidVariantRecipe(seedOffset: 373, bubbleRate: 0.42, toxicGlow: 0.82),
      _LiquidVariantRecipe(seedOffset: 461, bubbleRate: 0.08, toxicGlow: 0.22),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => AcidTile(
        id,
        bubbleRate: recipe.bubbleRate ?? bubbleRate,
        toxicGlow: recipe.toxicGlow ?? toxicGlow,
      ),
    );
  }
}

class SlimeTile extends LiquidTile {
  SlimeTile(super.id, {this.bubbleRate = 0.2, this.viscosity = 0.65});

  final double bubbleRate;
  final double viscosity;

  @override
  String get name => 'Slime';

  @override
  String get description => 'Viscous slime with slow swirling motion';

  @override
  String get iconName => 'blur_on';

  @override
  TilePalette get palette => TilePalettes.slime;

  @override
  List<String> get tags => ['liquid', 'slime', 'goo', 'toxic'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 260;

  @override
  List<PropertySpec> getPropertySpecs() => [
    SliderSpec(
      key: 'bubbleRate',
      label: 'Bubble Rate',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: bubbleRate,
      formatLabel: _percentLabel,
    ),
    SliderSpec(
      key: 'viscosity',
      label: 'Viscosity',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: viscosity,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return SlimeTile(
      id,
      bubbleRate: (properties['bubbleRate'] as num?)?.toDouble() ?? bubbleRate,
      viscosity: (properties['viscosity'] as num?)?.toDouble() ?? viscosity,
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
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex * 29);
    final pixels = Uint32List(width * height);
    final pal = palette;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final swirl =
            sin((x / width) * pi * (2 + viscosity) + frameIndex * 0.2) +
            cos((y / height) * pi * 2 - frameIndex * 0.15);
        final n = noise2D(x / (3.2 + viscosity), y / (3.2 + viscosity), 2);
        Color pixelColor;
        if (swirl > (0.9 - viscosity * 0.45)) {
          pixelColor = pal.highlight;
        } else if (n > 0.58) {
          pixelColor = pal.accent;
        } else if (swirl < -0.35) {
          pixelColor = pal.shadow;
        } else {
          pixelColor = pal.primary;
        }

        if (variation == TileVariation.pristine && n > 0.62) {
          pixelColor = pal.highlight;
        } else if (variation == TileVariation.weathered && swirl < -0.1) {
          pixelColor = pal.shadow;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.05);
      }
    }

    final bubbleCount = (bubbleRate * 6).round();
    for (int i = 0; i < bubbleCount; i++) {
      final bx = random.nextInt(width - 2) + 1;
      final by = random.nextInt(height - 2) + 1;
      pixels[by * width + bx] = colorToInt(pal.highlight);
    }

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
      _LiquidVariantRecipe(seedOffset: 41, bubbleRate: 0.08, viscosity: 0.82),
      _LiquidVariantRecipe(seedOffset: 127, bubbleRate: 0.16, viscosity: 0.7),
      _LiquidVariantRecipe(
        seedOffset: 211,
        bubbleRate: 0.28,
        viscosity: 0.54,
        variation: TileVariation.pristine,
      ),
      _LiquidVariantRecipe(
        seedOffset: 293,
        bubbleRate: 0.12,
        viscosity: 0.9,
        variation: TileVariation.weathered,
      ),
      _LiquidVariantRecipe(seedOffset: 379, bubbleRate: 0.22, viscosity: 0.62),
      _LiquidVariantRecipe(seedOffset: 467, bubbleRate: 0.05, viscosity: 0.96),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => SlimeTile(
        id,
        bubbleRate: recipe.bubbleRate ?? bubbleRate,
        viscosity: recipe.viscosity ?? viscosity,
      ),
    );
  }
}

class OilTile extends LiquidTile {
  OilTile(super.id, {this.rainbowSheen = true, this.slickStrength = 0.45});

  final bool rainbowSheen;
  final double slickStrength;

  @override
  String get name => 'Oil';

  @override
  String get description => 'Dark oil slick with iridescent sheen';

  @override
  String get iconName => 'water';

  @override
  TilePalette get palette => TilePalettes.oil;

  @override
  List<String> get tags => ['liquid', 'oil', 'industrial', 'slick'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 240;

  @override
  List<PropertySpec> getPropertySpecs() => [
    BoolSpec(
      key: 'rainbowSheen',
      label: 'Rainbow Sheen',
      initialValue: rainbowSheen,
    ),
    SliderSpec(
      key: 'slickStrength',
      label: 'Slick Strength',
      min: 0,
      max: 1,
      divisions: 20,
      initialValue: slickStrength,
      formatLabel: _percentLabel,
    ),
  ];

  @override
  TileBase copyWithProperties(Map<String, dynamic> properties) {
    return OilTile(
      id,
      rainbowSheen: properties['rainbowSheen'] as bool? ?? rainbowSheen,
      slickStrength:
          (properties['slickStrength'] as num?)?.toDouble() ?? slickStrength,
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
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex * 31);
    final pixels = Uint32List(width * height);
    final pal = palette;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final ripple =
            sin((x / width) * pi * 3 + frameIndex * 0.35) +
            cos((y / height) * pi * 2);
        final n = noise2D(x / 4.5 + seed * 0.001, y / 4.5, 2);
        Color pixelColor;
        if (ripple > (1.05 - slickStrength * 0.4)) {
          pixelColor = pal.secondary;
        } else if (n > 0.6) {
          pixelColor = pal.accent;
        } else {
          pixelColor = pal.primary;
        }

        if (rainbowSheen && ripple > 0.85 && random.nextDouble() < 0.4) {
          final sheenColors = [
            const Color(0xFF5AC8FA),
            const Color(0xFFAF52DE),
            const Color(0xFFFF9F0A),
          ];
          pixelColor = sheenColors[(x + y + frameIndex) % sheenColors.length];
        }

        if (variation == TileVariation.pristine && n > 0.65) {
          pixelColor = pal.highlight;
        } else if (variation == TileVariation.weathered && ripple < -0.2) {
          pixelColor = pal.shadow;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.04);
      }
    }

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
      _LiquidVariantRecipe(
        seedOffset: 53,
        rainbowSheen: false,
        slickStrength: 0.2,
      ),
      _LiquidVariantRecipe(
        seedOffset: 137,
        rainbowSheen: true,
        slickStrength: 0.4,
      ),
      _LiquidVariantRecipe(
        seedOffset: 223,
        rainbowSheen: true,
        slickStrength: 0.72,
        variation: TileVariation.pristine,
      ),
      _LiquidVariantRecipe(
        seedOffset: 307,
        rainbowSheen: false,
        slickStrength: 0.55,
        variation: TileVariation.weathered,
      ),
      _LiquidVariantRecipe(
        seedOffset: 389,
        rainbowSheen: true,
        slickStrength: 0.58,
      ),
      _LiquidVariantRecipe(
        seedOffset: 479,
        rainbowSheen: false,
        slickStrength: 0.3,
      ),
    ];

    return _generateStyledVariants(
      width: width,
      height: height,
      count: count,
      baseSeed: baseSeed,
      recipes: recipes,
      buildTile: (recipe) => OilTile(
        id,
        rainbowSheen: recipe.rainbowSheen ?? rainbowSheen,
        slickStrength: recipe.slickStrength ?? slickStrength,
      ),
    );
  }
}

String _percentLabel(double value) => '${(value * 100).round()}%';
