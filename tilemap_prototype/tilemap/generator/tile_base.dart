import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/property_spec.dart';
import 'tile_palette.dart';
import 'tile_palette_factory.dart';
import 'tile_procedural_effects.dart';
import 'tiles/decoration_tiles.dart';
import 'tiles/environment_tiles.dart';
import 'tiles/extended_nature.dart';
import 'tiles/extended_urban.dart';
import 'tiles/platformer_blocks.dart';
import 'tiles/platformer_tiles.dart';
import 'tiles/scifi_tiles.dart';
import 'tiles/terrain.dart';
import 'tiles/structure.dart';
import 'tiles/liquid.dart';
import 'tiles/nature.dart';
import 'tiles/special.dart';
import 'tiles/specialized.dart';
import 'tiles/stone.dart';
import 'tiles/extended_stone.dart';
import 'tiles/urban_tiles.dart';
import 'tiles/varied.dart';
import 'tiles/organic_nature_tiles.dart';
import 'tiles/interactive_animated_tiles.dart';
import 'tiles/decorative_detail_tiles.dart';
import 'tiles/fantasy_magic_tiles.dart';
import 'tiles/modular_connectable_tiles.dart';
import 'tiles/phase4_tiles.dart';

/// Base class for all tile types with powerful abstraction
abstract class TileBase {
  TileBase(this.id);

  /// Unique identifier for this tile type
  String id;

  /// Display name
  String get name;

  /// Description of the tile
  String get description;

  /// Category for grouping (Terrain, Structure, Nature, etc.)
  TileCategory get category;

  /// Icon name for UI display
  String get iconName;

  /// The color palette used for generation
  TilePalette get palette;

  /// Whether this tile can be rotated
  bool get supportsRotation => false;

  /// Whether this tile supports edge variations
  bool get supportsEdgeVariations => false;

  /// Whether this tile can connect to adjacent tiles
  bool get supportsAutoTiling => false;

  /// Tags for filtering and search
  List<String> get tags;

  /// Whether this tile is animated
  bool get animated => false;

  /// Number of animation frames
  int get frameCount => 1;

  /// Duration of each frame in milliseconds
  int get frameSpeed => 100;

  /// Generate a specific frame for animated tiles
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
    TileOrientation orientation = TileOrientation.none,
  }) {
    return generate(width: width, height: height, seed: seed, variation: variation, orientation: orientation);
  }

  /// Generate pixel data for a tile
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    TileOrientation orientation = TileOrientation.none,
  });

  /// Describes editable parameters for this tile in the generator side panel.
  List<PropertySpec> getPropertySpecs() => const [];

  /// Applies [properties] and returns a configured tile instance for generation.
  TileBase copyWithProperties(Map<String, dynamic> properties) => this;

  /// Generate multiple variants
  List<Uint32List> generateVariants({required int width, required int height, int count = 4, int? baseSeed}) {
    final random = Random(baseSeed);
    if (category == TileCategory.terrain) {
      final profiles = _terrainVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 997),
          variation: profile.variation,
        );
        _applyTerrainVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 131),
          profile,
        );
        return pixels;
      });
    }

    if (category == TileCategory.structure) {
      final profiles = _structureVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 991),
          variation: profile.variation,
        );
        _applyStructureVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 151),
          profile,
        );
        return pixels;
      });
    }

    if (category == TileCategory.liquid) {
      final profiles = _liquidVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 983),
          variation: profile.variation,
        );
        _applyLiquidVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 173),
          profile,
        );
        return pixels;
      });
    }

    if (category == TileCategory.special) {
      final profiles = _specialVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 971),
          variation: profile.variation,
        );
        _applySpecialVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 191),
          profile,
        );
        return pixels;
      });
    }

    if (category == TileCategory.decoration) {
      final profiles = _decorationVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 967),
          variation: profile.variation,
        );
        _applyDecorationVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 211),
          profile,
        );
        return pixels;
      });
    }

    if (category == TileCategory.dungeon) {
      final profiles = _dungeonVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 953),
          variation: profile.variation,
        );
        _applyDungeonVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 233),
          profile,
        );
        return pixels;
      });
    }

    if (category == TileCategory.urban) {
      final profiles = _urbanVariantProfiles();
      return List.generate(count, (i) {
        final profile = profiles[i % profiles.length];
        final pixels = generate(
          width: width,
          height: height,
          seed: baseSeed == null ? random.nextInt(1000000) : baseSeed + profile.seedOffset + (i * 947),
          variation: profile.variation,
        );
        _applyUrbanVariantProfile(
          pixels,
          width,
          height,
          Random((baseSeed ?? 0) + profile.seedOffset + i * 257),
          profile,
        );
        return pixels;
      });
    }

    return List.generate(count, (i) {
      return generate(
        width: width,
        height: height,
        seed: random.nextInt(1000000),
        variation: TileVariation.values[i % TileVariation.values.length],
      );
    });
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
    final variation = ((random.nextDouble() - 0.5) * 2 * intensity * 255).round();
    final r = (baseColor.red + variation).clamp(0, 255);
    final g = (baseColor.green + variation).clamp(0, 255);
    final b = (baseColor.blue + variation).clamp(0, 255);
    return (baseColor.alpha << 24) | (r << 16) | (g << 8) | b;
  }

  /// Generate Perlin-like noise value
  double noise2D(double x, double y, int octaves) {
    double value = 0;
    double amplitude = 1;
    double frequency = 1;
    double maxValue = 0;

    for (int i = 0; i < octaves; i++) {
      value += amplitude * _smoothNoise(x * frequency, y * frequency);
      maxValue += amplitude;
      amplitude *= 0.5;
      frequency *= 2;
    }

    return value / maxValue;
  }

  double _smoothNoise(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

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

  // --------------------------------------------------------------------------
  // VARIATION EFFECTS — shared post-processing for all tiles
  // --------------------------------------------------------------------------

  /// Apply standard variation effects after base pixel generation.
  ///
  /// Call at the end of [generate] to get consistent variation behaviour
  /// across all tile types without duplicating effect logic per tile.
  ///
  /// ```dart
  /// @override
  /// Uint32List generate({...}) {
  ///   // ... base generation ...
  ///   applyVariationEffects(pixels, width, height, random, variation);
  ///   return pixels;
  /// }
  /// ```
  void applyVariationEffects(Uint32List pixels, int width, int height, Random random, TileVariation variation) {
    switch (variation) {
      case TileVariation.standard:
        break;
      case TileVariation.weathered:
        TileProceduralEffects.applyWeathering(pixels, width, height, random, palette);
      case TileVariation.mossy:
        TileProceduralEffects.applyMoss(pixels, width, height, random);
      case TileVariation.cracked:
        TileProceduralEffects.applyCracks(pixels, width, height, random, palette);
      case TileVariation.pristine:
        TileProceduralEffects.applyPristine(pixels, width, height, random, palette);
      case TileVariation.frozen:
        TileProceduralEffects.applyFrost(pixels, width, height, random);
      case TileVariation.overgrown:
        TileProceduralEffects.applyOvergrown(pixels, width, height, random);
      case TileVariation.burnt:
        TileProceduralEffects.applyBurnt(pixels, width, height, random);
      case TileVariation.submerged:
        TileProceduralEffects.applySubmerged(pixels, width, height, random);
      case TileVariation.rusted:
        TileProceduralEffects.applyRusted(pixels, width, height, random);
      case TileVariation.haunted:
        TileProceduralEffects.applyHaunted(pixels, width, height, random);
      case TileVariation.gilded:
        TileProceduralEffects.applyGilded(pixels, width, height, random);
      case TileVariation.shattered:
        TileProceduralEffects.applyShattered(pixels, width, height, random, palette);
    }
  }

  /// Derived palette for a given variation — use for palette-aware generation.
  TilePalette paletteForVariation(TileVariation variation) {
    return switch (variation) {
      TileVariation.weathered => TilePaletteFactory.weathered(palette),
      TileVariation.mossy => TilePaletteFactory.mossy(palette),
      TileVariation.frozen => TilePaletteFactory.frozen(palette),
      TileVariation.pristine => TilePaletteFactory.pristine(palette),
      TileVariation.overgrown => TilePaletteFactory.overgrown(palette),
      TileVariation.burnt => TilePaletteFactory.burnt(palette),
      TileVariation.submerged => TilePaletteFactory.submerged(palette),
      TileVariation.rusted => TilePaletteFactory.rusted(palette),
      TileVariation.haunted => TilePaletteFactory.haunted(palette),
      TileVariation.gilded => TilePaletteFactory.gilded(palette),
      TileVariation.shattered => TilePaletteFactory.shattered(palette),
      _ => palette,
    };
  }

  List<_TerrainVariantProfile> _terrainVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['sand', 'desert', 'beach', 'arid', 'dune', 'quicksand', 'salt'])) {
      return const [
        _TerrainVariantProfile(seedOffset: 11),
        _TerrainVariantProfile(seedOffset: 97, extraStyle: _TerrainExtraStyle.rippled),
        _TerrainVariantProfile(
          seedOffset: 181,
          variation: TileVariation.pristine,
          extraStyle: _TerrainExtraStyle.rippled,
        ),
        _TerrainVariantProfile(
          seedOffset: 263,
          variation: TileVariation.weathered,
          extraStyle: _TerrainExtraStyle.pebbled,
        ),
        _TerrainVariantProfile(
          seedOffset: 347,
          variation: TileVariation.frozen,
          extraStyle: _TerrainExtraStyle.drifted,
        ),
        _TerrainVariantProfile(seedOffset: 431, extraStyle: _TerrainExtraStyle.pebbled),
      ];
    }

    if (hasAny(['snow', 'ice', 'frozen', 'arctic', 'tundra', 'frost', 'glacier'])) {
      return const [
        _TerrainVariantProfile(seedOffset: 17),
        _TerrainVariantProfile(seedOffset: 103, extraStyle: _TerrainExtraStyle.drifted),
        _TerrainVariantProfile(
          seedOffset: 187,
          variation: TileVariation.pristine,
          extraStyle: _TerrainExtraStyle.sparkled,
        ),
        _TerrainVariantProfile(
          seedOffset: 271,
          variation: TileVariation.weathered,
          extraStyle: _TerrainExtraStyle.drifted,
        ),
        _TerrainVariantProfile(
          seedOffset: 359,
          variation: TileVariation.frozen,
          extraStyle: _TerrainExtraStyle.sparkled,
        ),
        _TerrainVariantProfile(seedOffset: 443, extraStyle: _TerrainExtraStyle.drifted),
      ];
    }

    if (hasAny(['grass', 'meadow', 'field', 'prairie', 'lush', 'flower', 'clover', 'leaf', 'bamboo', 'wheat'])) {
      return const [
        _TerrainVariantProfile(seedOffset: 23),
        _TerrainVariantProfile(
          seedOffset: 109,
          variation: TileVariation.pristine,
          extraStyle: _TerrainExtraStyle.vegetated,
        ),
        _TerrainVariantProfile(
          seedOffset: 193,
          variation: TileVariation.overgrown,
          extraStyle: _TerrainExtraStyle.vegetated,
        ),
        _TerrainVariantProfile(seedOffset: 277, variation: TileVariation.weathered),
        _TerrainVariantProfile(
          seedOffset: 361,
          variation: TileVariation.frozen,
          extraStyle: _TerrainExtraStyle.sparkled,
        ),
        _TerrainVariantProfile(seedOffset: 449, extraStyle: _TerrainExtraStyle.vegetated),
      ];
    }

    if (hasAny(['dirt', 'mud', 'bog', 'swamp', 'soil', 'earth', 'path', 'hay'])) {
      return const [
        _TerrainVariantProfile(seedOffset: 31),
        _TerrainVariantProfile(seedOffset: 117, variation: TileVariation.cracked),
        _TerrainVariantProfile(seedOffset: 201, variation: TileVariation.weathered),
        _TerrainVariantProfile(
          seedOffset: 283,
          variation: TileVariation.mossy,
          extraStyle: _TerrainExtraStyle.vegetated,
        ),
        _TerrainVariantProfile(seedOffset: 367, variation: TileVariation.overgrown),
        _TerrainVariantProfile(seedOffset: 457, extraStyle: _TerrainExtraStyle.pebbled),
      ];
    }

    if (hasAny(['stone', 'rock', 'gravel', 'cliff', 'cobble', 'asphalt', 'concrete', 'road'])) {
      return const [
        _TerrainVariantProfile(seedOffset: 37),
        _TerrainVariantProfile(seedOffset: 121, variation: TileVariation.cracked),
        _TerrainVariantProfile(seedOffset: 209, variation: TileVariation.weathered),
        _TerrainVariantProfile(seedOffset: 293, variation: TileVariation.mossy),
        _TerrainVariantProfile(seedOffset: 379, variation: TileVariation.pristine),
        _TerrainVariantProfile(seedOffset: 467, extraStyle: _TerrainExtraStyle.pebbled),
      ];
    }

    return const [
      _TerrainVariantProfile(seedOffset: 41),
      _TerrainVariantProfile(seedOffset: 127, variation: TileVariation.weathered),
      _TerrainVariantProfile(seedOffset: 211, variation: TileVariation.mossy),
      _TerrainVariantProfile(seedOffset: 307, variation: TileVariation.cracked),
      _TerrainVariantProfile(seedOffset: 389, variation: TileVariation.pristine),
      _TerrainVariantProfile(seedOffset: 473, variation: TileVariation.overgrown),
    ];
  }

  List<_StructureVariantProfile> _structureVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['wood', 'plank', 'timber'])) {
      return const [
        _StructureVariantProfile(seedOffset: 19),
        _StructureVariantProfile(seedOffset: 101, extraStyle: _StructureExtraStyle.woodKnotted),
        _StructureVariantProfile(seedOffset: 187, variation: TileVariation.weathered),
        _StructureVariantProfile(
          seedOffset: 271,
          variation: TileVariation.pristine,
          extraStyle: _StructureExtraStyle.panelled,
        ),
        _StructureVariantProfile(seedOffset: 353, variation: TileVariation.overgrown),
        _StructureVariantProfile(seedOffset: 439, extraStyle: _StructureExtraStyle.woodKnotted),
      ];
    }

    if (hasAny(['brick', 'wall', 'masonry'])) {
      return const [
        _StructureVariantProfile(seedOffset: 23),
        _StructureVariantProfile(
          seedOffset: 109,
          variation: TileVariation.weathered,
          extraStyle: _StructureExtraStyle.chipped,
        ),
        _StructureVariantProfile(
          seedOffset: 193,
          variation: TileVariation.cracked,
          extraStyle: _StructureExtraStyle.chipped,
        ),
        _StructureVariantProfile(
          seedOffset: 277,
          variation: TileVariation.pristine,
          extraStyle: _StructureExtraStyle.panelled,
        ),
        _StructureVariantProfile(seedOffset: 359, variation: TileVariation.mossy),
        _StructureVariantProfile(seedOffset: 443, variation: TileVariation.overgrown),
      ];
    }

    if (hasAny(['stone', 'tile', 'floor', 'marble', 'granite', 'slab'])) {
      return const [
        _StructureVariantProfile(seedOffset: 29),
        _StructureVariantProfile(seedOffset: 113, extraStyle: _StructureExtraStyle.panelled),
        _StructureVariantProfile(
          seedOffset: 197,
          variation: TileVariation.pristine,
          extraStyle: _StructureExtraStyle.panelled,
        ),
        _StructureVariantProfile(
          seedOffset: 281,
          variation: TileVariation.weathered,
          extraStyle: _StructureExtraStyle.chipped,
        ),
        _StructureVariantProfile(seedOffset: 367, variation: TileVariation.cracked),
        _StructureVariantProfile(seedOffset: 451, variation: TileVariation.mossy),
      ];
    }

    if (hasAny(['metal', 'grate', 'panel', 'industrial', 'roof'])) {
      return const [
        _StructureVariantProfile(seedOffset: 31),
        _StructureVariantProfile(seedOffset: 127, extraStyle: _StructureExtraStyle.panelled),
        _StructureVariantProfile(seedOffset: 211, variation: TileVariation.pristine),
        _StructureVariantProfile(
          seedOffset: 293,
          variation: TileVariation.weathered,
          extraStyle: _StructureExtraStyle.chipped,
        ),
        _StructureVariantProfile(seedOffset: 379, variation: TileVariation.cracked),
        _StructureVariantProfile(seedOffset: 463, variation: TileVariation.overgrown),
      ];
    }

    return const [
      _StructureVariantProfile(seedOffset: 37),
      _StructureVariantProfile(seedOffset: 121, variation: TileVariation.weathered),
      _StructureVariantProfile(seedOffset: 209, variation: TileVariation.cracked),
      _StructureVariantProfile(
        seedOffset: 293,
        variation: TileVariation.pristine,
        extraStyle: _StructureExtraStyle.panelled,
      ),
      _StructureVariantProfile(seedOffset: 379, variation: TileVariation.mossy),
      _StructureVariantProfile(seedOffset: 467, variation: TileVariation.overgrown),
    ];
  }

  List<_LiquidVariantProfile> _liquidVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['water', 'ocean', 'river', 'lake', 'underwater', 'bubble'])) {
      return const [
        _LiquidVariantProfile(seedOffset: 17, extraStyle: _LiquidExtraStyle.rippled),
        _LiquidVariantProfile(seedOffset: 103, extraStyle: _LiquidExtraStyle.foamy),
        _LiquidVariantProfile(seedOffset: 187, variation: TileVariation.pristine, extraStyle: _LiquidExtraStyle.foamy),
        _LiquidVariantProfile(seedOffset: 271, variation: TileVariation.frozen, extraStyle: _LiquidExtraStyle.bubbly),
        _LiquidVariantProfile(seedOffset: 359, variation: TileVariation.overgrown, extraStyle: _LiquidExtraStyle.algal),
        _LiquidVariantProfile(seedOffset: 443, extraStyle: _LiquidExtraStyle.bubbly),
      ];
    }

    if (hasAny(['lava', 'magma', 'fire', 'volcanic'])) {
      return const [
        _LiquidVariantProfile(seedOffset: 23),
        _LiquidVariantProfile(seedOffset: 109, extraStyle: _LiquidExtraStyle.bubbly),
        _LiquidVariantProfile(
          seedOffset: 193,
          variation: TileVariation.pristine,
          extraStyle: _LiquidExtraStyle.glowing,
        ),
        _LiquidVariantProfile(seedOffset: 277, variation: TileVariation.cracked, extraStyle: _LiquidExtraStyle.glowing),
        _LiquidVariantProfile(seedOffset: 361, variation: TileVariation.weathered),
        _LiquidVariantProfile(seedOffset: 449, extraStyle: _LiquidExtraStyle.bubbly),
      ];
    }

    if (hasAny(['acid', 'corrosive', 'toxic'])) {
      return const [
        _LiquidVariantProfile(seedOffset: 29, extraStyle: _LiquidExtraStyle.caustic),
        _LiquidVariantProfile(seedOffset: 113, extraStyle: _LiquidExtraStyle.bubbly),
        _LiquidVariantProfile(
          seedOffset: 197,
          variation: TileVariation.pristine,
          extraStyle: _LiquidExtraStyle.caustic,
        ),
        _LiquidVariantProfile(seedOffset: 281, variation: TileVariation.overgrown, extraStyle: _LiquidExtraStyle.algal),
        _LiquidVariantProfile(
          seedOffset: 367,
          variation: TileVariation.weathered,
          extraStyle: _LiquidExtraStyle.caustic,
        ),
        _LiquidVariantProfile(seedOffset: 451, extraStyle: _LiquidExtraStyle.bubbly),
      ];
    }

    if (hasAny(['slime', 'goo', 'poison'])) {
      return const [
        _LiquidVariantProfile(seedOffset: 31),
        _LiquidVariantProfile(seedOffset: 127, extraStyle: _LiquidExtraStyle.bubbly),
        _LiquidVariantProfile(
          seedOffset: 211,
          variation: TileVariation.pristine,
          extraStyle: _LiquidExtraStyle.glowing,
        ),
        _LiquidVariantProfile(
          seedOffset: 293,
          variation: TileVariation.weathered,
          extraStyle: _LiquidExtraStyle.bubbly,
        ),
        _LiquidVariantProfile(seedOffset: 379, variation: TileVariation.overgrown, extraStyle: _LiquidExtraStyle.algal),
        _LiquidVariantProfile(seedOffset: 463, extraStyle: _LiquidExtraStyle.caustic),
      ];
    }

    if (hasAny(['oil', 'slick', 'industrial'])) {
      return const [
        _LiquidVariantProfile(seedOffset: 37),
        _LiquidVariantProfile(seedOffset: 121, extraStyle: _LiquidExtraStyle.sheened),
        _LiquidVariantProfile(
          seedOffset: 209,
          variation: TileVariation.pristine,
          extraStyle: _LiquidExtraStyle.sheened,
        ),
        _LiquidVariantProfile(seedOffset: 307, variation: TileVariation.weathered),
        _LiquidVariantProfile(seedOffset: 389, variation: TileVariation.cracked, extraStyle: _LiquidExtraStyle.sheened),
        _LiquidVariantProfile(seedOffset: 473, extraStyle: _LiquidExtraStyle.rippled),
      ];
    }

    return const [
      _LiquidVariantProfile(seedOffset: 41, extraStyle: _LiquidExtraStyle.rippled),
      _LiquidVariantProfile(seedOffset: 127, extraStyle: _LiquidExtraStyle.foamy),
      _LiquidVariantProfile(seedOffset: 211, variation: TileVariation.pristine, extraStyle: _LiquidExtraStyle.bubbly),
      _LiquidVariantProfile(seedOffset: 307, variation: TileVariation.weathered),
      _LiquidVariantProfile(seedOffset: 389, variation: TileVariation.frozen, extraStyle: _LiquidExtraStyle.rippled),
      _LiquidVariantProfile(seedOffset: 473, extraStyle: _LiquidExtraStyle.sheened),
    ];
  }

  List<_SpecialVariantProfile> _specialVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['crystal', 'gem', 'shard'])) {
      return const [
        _SpecialVariantProfile(seedOffset: 19, extraStyle: _SpecialExtraStyle.glints),
        _SpecialVariantProfile(seedOffset: 103, extraStyle: _SpecialExtraStyle.energyVeins),
        _SpecialVariantProfile(
          seedOffset: 187,
          variation: TileVariation.pristine,
          extraStyle: _SpecialExtraStyle.glints,
        ),
        _SpecialVariantProfile(seedOffset: 271, variation: TileVariation.frozen, extraStyle: _SpecialExtraStyle.glints),
        _SpecialVariantProfile(
          seedOffset: 359,
          variation: TileVariation.weathered,
          extraStyle: _SpecialExtraStyle.energyVeins,
        ),
        _SpecialVariantProfile(seedOffset: 443, extraStyle: _SpecialExtraStyle.glyphs),
      ];
    }

    if (hasAny(['magic', 'arcane', 'rune', 'portal', 'enchanted', 'mystic'])) {
      return const [
        _SpecialVariantProfile(seedOffset: 23, extraStyle: _SpecialExtraStyle.glyphs),
        _SpecialVariantProfile(seedOffset: 109, extraStyle: _SpecialExtraStyle.glints),
        _SpecialVariantProfile(
          seedOffset: 193,
          variation: TileVariation.pristine,
          extraStyle: _SpecialExtraStyle.glyphs,
        ),
        _SpecialVariantProfile(
          seedOffset: 277,
          variation: TileVariation.overgrown,
          extraStyle: _SpecialExtraStyle.glyphs,
        ),
        _SpecialVariantProfile(
          seedOffset: 361,
          variation: TileVariation.weathered,
          extraStyle: _SpecialExtraStyle.voidFlecks,
        ),
        _SpecialVariantProfile(seedOffset: 449, extraStyle: _SpecialExtraStyle.energyVeins),
      ];
    }

    if (hasAny(['electric', 'energy', 'charged', 'plasma', 'tech'])) {
      return const [
        _SpecialVariantProfile(seedOffset: 29, extraStyle: _SpecialExtraStyle.energyVeins),
        _SpecialVariantProfile(seedOffset: 113, extraStyle: _SpecialExtraStyle.glints),
        _SpecialVariantProfile(
          seedOffset: 197,
          variation: TileVariation.pristine,
          extraStyle: _SpecialExtraStyle.energyVeins,
        ),
        _SpecialVariantProfile(
          seedOffset: 281,
          variation: TileVariation.cracked,
          extraStyle: _SpecialExtraStyle.energyVeins,
        ),
        _SpecialVariantProfile(
          seedOffset: 367,
          variation: TileVariation.weathered,
          extraStyle: _SpecialExtraStyle.voidFlecks,
        ),
        _SpecialVariantProfile(seedOffset: 451, extraStyle: _SpecialExtraStyle.glyphs),
      ];
    }

    if (hasAny(['shadow', 'void', 'dark', 'realm'])) {
      return const [
        _SpecialVariantProfile(seedOffset: 31, extraStyle: _SpecialExtraStyle.voidFlecks),
        _SpecialVariantProfile(seedOffset: 127, extraStyle: _SpecialExtraStyle.glints),
        _SpecialVariantProfile(
          seedOffset: 211,
          variation: TileVariation.pristine,
          extraStyle: _SpecialExtraStyle.voidFlecks,
        ),
        _SpecialVariantProfile(
          seedOffset: 293,
          variation: TileVariation.weathered,
          extraStyle: _SpecialExtraStyle.voidFlecks,
        ),
        _SpecialVariantProfile(seedOffset: 379, variation: TileVariation.mossy, extraStyle: _SpecialExtraStyle.glyphs),
        _SpecialVariantProfile(seedOffset: 463, extraStyle: _SpecialExtraStyle.energyVeins),
      ];
    }

    if (hasAny(['fire', 'lava', 'flame', 'ember'])) {
      return const [
        _SpecialVariantProfile(seedOffset: 37, extraStyle: _SpecialExtraStyle.energyVeins),
        _SpecialVariantProfile(seedOffset: 121, extraStyle: _SpecialExtraStyle.glints),
        _SpecialVariantProfile(
          seedOffset: 209,
          variation: TileVariation.pristine,
          extraStyle: _SpecialExtraStyle.energyVeins,
        ),
        _SpecialVariantProfile(
          seedOffset: 307,
          variation: TileVariation.cracked,
          extraStyle: _SpecialExtraStyle.energyVeins,
        ),
        _SpecialVariantProfile(
          seedOffset: 389,
          variation: TileVariation.weathered,
          extraStyle: _SpecialExtraStyle.glyphs,
        ),
        _SpecialVariantProfile(seedOffset: 473, extraStyle: _SpecialExtraStyle.glints),
      ];
    }

    return const [
      _SpecialVariantProfile(seedOffset: 41, extraStyle: _SpecialExtraStyle.glints),
      _SpecialVariantProfile(seedOffset: 127, extraStyle: _SpecialExtraStyle.glyphs),
      _SpecialVariantProfile(
        seedOffset: 211,
        variation: TileVariation.pristine,
        extraStyle: _SpecialExtraStyle.energyVeins,
      ),
      _SpecialVariantProfile(
        seedOffset: 307,
        variation: TileVariation.weathered,
        extraStyle: _SpecialExtraStyle.voidFlecks,
      ),
      _SpecialVariantProfile(
        seedOffset: 389,
        variation: TileVariation.overgrown,
        extraStyle: _SpecialExtraStyle.glyphs,
      ),
      _SpecialVariantProfile(seedOffset: 473, extraStyle: _SpecialExtraStyle.glints),
    ];
  }

  List<_DecorationVariantProfile> _decorationVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['wood', 'crate', 'barrel', 'chest', 'storage', 'furniture', 'table', 'chair', 'bookshelf'])) {
      return const [
        _DecorationVariantProfile(seedOffset: 17),
        _DecorationVariantProfile(seedOffset: 101, extraStyle: _DecorationExtraStyle.dusty),
        _DecorationVariantProfile(
          seedOffset: 187,
          variation: TileVariation.pristine,
          extraStyle: _DecorationExtraStyle.trimmed,
        ),
        _DecorationVariantProfile(seedOffset: 271, variation: TileVariation.weathered),
        _DecorationVariantProfile(seedOffset: 359, variation: TileVariation.overgrown),
        _DecorationVariantProfile(seedOffset: 443, extraStyle: _DecorationExtraStyle.shined),
      ];
    }

    if (hasAny(['light', 'torch', 'lantern', 'candle', 'brazier'])) {
      return const [
        _DecorationVariantProfile(seedOffset: 23, extraStyle: _DecorationExtraStyle.shined),
        _DecorationVariantProfile(seedOffset: 109, extraStyle: _DecorationExtraStyle.trimmed),
        _DecorationVariantProfile(
          seedOffset: 193,
          variation: TileVariation.pristine,
          extraStyle: _DecorationExtraStyle.shined,
        ),
        _DecorationVariantProfile(seedOffset: 277, variation: TileVariation.weathered),
        _DecorationVariantProfile(seedOffset: 361, variation: TileVariation.overgrown),
        _DecorationVariantProfile(seedOffset: 449, extraStyle: _DecorationExtraStyle.dusty),
      ];
    }

    if (hasAny(['rug', 'banner', 'curtain', 'painting', 'fabric', 'cloth'])) {
      return const [
        _DecorationVariantProfile(seedOffset: 29, extraStyle: _DecorationExtraStyle.patterned),
        _DecorationVariantProfile(seedOffset: 113, extraStyle: _DecorationExtraStyle.trimmed),
        _DecorationVariantProfile(
          seedOffset: 197,
          variation: TileVariation.pristine,
          extraStyle: _DecorationExtraStyle.patterned,
        ),
        _DecorationVariantProfile(seedOffset: 281, variation: TileVariation.weathered),
        _DecorationVariantProfile(
          seedOffset: 367,
          variation: TileVariation.overgrown,
          extraStyle: _DecorationExtraStyle.patterned,
        ),
        _DecorationVariantProfile(seedOffset: 451, extraStyle: _DecorationExtraStyle.dusty),
      ];
    }

    if (hasAny(['coin', 'gem', 'treasure', 'trophy', 'gold', 'loot', 'key'])) {
      return const [
        _DecorationVariantProfile(seedOffset: 31, extraStyle: _DecorationExtraStyle.shined),
        _DecorationVariantProfile(seedOffset: 127, extraStyle: _DecorationExtraStyle.trimmed),
        _DecorationVariantProfile(
          seedOffset: 211,
          variation: TileVariation.pristine,
          extraStyle: _DecorationExtraStyle.shined,
        ),
        _DecorationVariantProfile(seedOffset: 293, variation: TileVariation.weathered),
        _DecorationVariantProfile(seedOffset: 379, variation: TileVariation.mossy),
        _DecorationVariantProfile(seedOffset: 463, extraStyle: _DecorationExtraStyle.dusty),
      ];
    }

    if (hasAny(['bone', 'skull', 'web', 'spider', 'anvil', 'weapon', 'shield', 'metal'])) {
      return const [
        _DecorationVariantProfile(seedOffset: 37),
        _DecorationVariantProfile(
          seedOffset: 121,
          variation: TileVariation.weathered,
          extraStyle: _DecorationExtraStyle.dusty,
        ),
        _DecorationVariantProfile(seedOffset: 209, variation: TileVariation.cracked),
        _DecorationVariantProfile(
          seedOffset: 307,
          variation: TileVariation.pristine,
          extraStyle: _DecorationExtraStyle.shined,
        ),
        _DecorationVariantProfile(seedOffset: 389, variation: TileVariation.mossy),
        _DecorationVariantProfile(seedOffset: 473, extraStyle: _DecorationExtraStyle.trimmed),
      ];
    }

    return const [
      _DecorationVariantProfile(seedOffset: 41),
      _DecorationVariantProfile(seedOffset: 127, extraStyle: _DecorationExtraStyle.trimmed),
      _DecorationVariantProfile(
        seedOffset: 211,
        variation: TileVariation.pristine,
        extraStyle: _DecorationExtraStyle.shined,
      ),
      _DecorationVariantProfile(seedOffset: 307, variation: TileVariation.weathered),
      _DecorationVariantProfile(seedOffset: 389, variation: TileVariation.overgrown),
      _DecorationVariantProfile(seedOffset: 473, extraStyle: _DecorationExtraStyle.dusty),
    ];
  }

  List<_DungeonVariantProfile> _dungeonVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['ice', 'frost', 'frozen', 'winter'])) {
      return const [
        _DungeonVariantProfile(seedOffset: 43),
        _DungeonVariantProfile(
          seedOffset: 131,
          variation: TileVariation.frozen,
          extraStyle: _DungeonExtraStyle.mineralVeins,
        ),
        _DungeonVariantProfile(
          seedOffset: 219,
          variation: TileVariation.pristine,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
        _DungeonVariantProfile(
          seedOffset: 307,
          variation: TileVariation.weathered,
          extraStyle: _DungeonExtraStyle.damp,
        ),
        _DungeonVariantProfile(
          seedOffset: 397,
          variation: TileVariation.frozen,
          extraStyle: _DungeonExtraStyle.jointed,
        ),
        _DungeonVariantProfile(seedOffset: 487, extraStyle: _DungeonExtraStyle.mineralVeins),
        _DungeonVariantProfile(
          seedOffset: 581,
          variation: TileVariation.shattered,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
        _DungeonVariantProfile(
          seedOffset: 677,
          variation: TileVariation.haunted,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
      ];
    }

    if (hasAny(['moss', 'vine', 'overgrown', 'fungus', 'grass'])) {
      return const [
        _DungeonVariantProfile(seedOffset: 47, variation: TileVariation.mossy),
        _DungeonVariantProfile(
          seedOffset: 139,
          variation: TileVariation.overgrown,
          extraStyle: _DungeonExtraStyle.damp,
        ),
        _DungeonVariantProfile(
          seedOffset: 227,
          variation: TileVariation.weathered,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
        _DungeonVariantProfile(
          seedOffset: 313,
          variation: TileVariation.mossy,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
        _DungeonVariantProfile(seedOffset: 401, variation: TileVariation.cracked, extraStyle: _DungeonExtraStyle.damp),
        _DungeonVariantProfile(
          seedOffset: 491,
          variation: TileVariation.overgrown,
          extraStyle: _DungeonExtraStyle.mineralVeins,
        ),
        _DungeonVariantProfile(
          seedOffset: 583,
          variation: TileVariation.submerged,
          extraStyle: _DungeonExtraStyle.damp,
        ),
        _DungeonVariantProfile(
          seedOffset: 679,
          variation: TileVariation.haunted,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
      ];
    }

    if (hasAny(['carved', 'ornate', 'decorative', 'ancient', 'ruin', 'door'])) {
      return const [
        _DungeonVariantProfile(seedOffset: 53, extraStyle: _DungeonExtraStyle.runeCarved),
        _DungeonVariantProfile(
          seedOffset: 149,
          variation: TileVariation.pristine,
          extraStyle: _DungeonExtraStyle.jointed,
        ),
        _DungeonVariantProfile(
          seedOffset: 239,
          variation: TileVariation.weathered,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
        _DungeonVariantProfile(
          seedOffset: 331,
          variation: TileVariation.cracked,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
        _DungeonVariantProfile(seedOffset: 419, variation: TileVariation.mossy, extraStyle: _DungeonExtraStyle.damp),
        _DungeonVariantProfile(seedOffset: 503, extraStyle: _DungeonExtraStyle.mineralVeins),
        _DungeonVariantProfile(
          seedOffset: 593,
          variation: TileVariation.gilded,
          extraStyle: _DungeonExtraStyle.jointed,
        ),
        _DungeonVariantProfile(
          seedOffset: 683,
          variation: TileVariation.haunted,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
        _DungeonVariantProfile(
          seedOffset: 773,
          variation: TileVariation.shattered,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
      ];
    }

    if (hasAny(['wall', 'brick', 'block', 'column', 'pillar', 'gate'])) {
      return const [
        _DungeonVariantProfile(seedOffset: 59, extraStyle: _DungeonExtraStyle.jointed),
        _DungeonVariantProfile(
          seedOffset: 151,
          variation: TileVariation.weathered,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
        _DungeonVariantProfile(
          seedOffset: 241,
          variation: TileVariation.pristine,
          extraStyle: _DungeonExtraStyle.jointed,
        ),
        _DungeonVariantProfile(
          seedOffset: 337,
          variation: TileVariation.cracked,
          extraStyle: _DungeonExtraStyle.mineralVeins,
        ),
        _DungeonVariantProfile(
          seedOffset: 599,
          variation: TileVariation.rusted,
          extraStyle: _DungeonExtraStyle.damp,
        ),
        _DungeonVariantProfile(
          seedOffset: 689,
          variation: TileVariation.burnt,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
        _DungeonVariantProfile(
          seedOffset: 779,
          variation: TileVariation.shattered,
          extraStyle: _DungeonExtraStyle.mineralVeins,
        ),
        _DungeonVariantProfile(seedOffset: 421, variation: TileVariation.mossy, extraStyle: _DungeonExtraStyle.damp),
        _DungeonVariantProfile(seedOffset: 509, extraStyle: _DungeonExtraStyle.runeCarved),
      ];
    }

    if (hasAny(['floor', 'cobblestone', 'slab', 'rough', 'cave', 'underground', 'rock'])) {
      return const [
        _DungeonVariantProfile(seedOffset: 61, extraStyle: _DungeonExtraStyle.damp),
        _DungeonVariantProfile(
          seedOffset: 157,
          variation: TileVariation.weathered,
          extraStyle: _DungeonExtraStyle.mineralVeins,
        ),
        _DungeonVariantProfile(
          seedOffset: 251,
          variation: TileVariation.cracked,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
        _DungeonVariantProfile(
          seedOffset: 347,
          variation: TileVariation.pristine,
          extraStyle: _DungeonExtraStyle.jointed,
        ),
        _DungeonVariantProfile(seedOffset: 433, variation: TileVariation.mossy, extraStyle: _DungeonExtraStyle.damp),
        _DungeonVariantProfile(seedOffset: 521, extraStyle: _DungeonExtraStyle.mineralVeins),
        _DungeonVariantProfile(
          seedOffset: 601,
          variation: TileVariation.submerged,
          extraStyle: _DungeonExtraStyle.damp,
        ),
        _DungeonVariantProfile(
          seedOffset: 691,
          variation: TileVariation.haunted,
          extraStyle: _DungeonExtraStyle.runeCarved,
        ),
        _DungeonVariantProfile(
          seedOffset: 781,
          variation: TileVariation.shattered,
          extraStyle: _DungeonExtraStyle.chipped,
        ),
      ];
    }

    return const [
      _DungeonVariantProfile(seedOffset: 67),
      _DungeonVariantProfile(seedOffset: 163, variation: TileVariation.weathered, extraStyle: _DungeonExtraStyle.damp),
      _DungeonVariantProfile(seedOffset: 257, variation: TileVariation.cracked, extraStyle: _DungeonExtraStyle.chipped),
      _DungeonVariantProfile(
        seedOffset: 353,
        variation: TileVariation.pristine,
        extraStyle: _DungeonExtraStyle.jointed,
      ),
      _DungeonVariantProfile(
        seedOffset: 439,
        variation: TileVariation.mossy,
        extraStyle: _DungeonExtraStyle.runeCarved,
      ),
      _DungeonVariantProfile(seedOffset: 523, extraStyle: _DungeonExtraStyle.mineralVeins),
      _DungeonVariantProfile(
        seedOffset: 607,
        variation: TileVariation.haunted,
        extraStyle: _DungeonExtraStyle.runeCarved,
      ),
      _DungeonVariantProfile(
        seedOffset: 697,
        variation: TileVariation.rusted,
        extraStyle: _DungeonExtraStyle.damp,
      ),
      _DungeonVariantProfile(
        seedOffset: 787,
        variation: TileVariation.shattered,
        extraStyle: _DungeonExtraStyle.mineralVeins,
      ),
    ];
  }

  List<_UrbanVariantProfile> _urbanVariantProfiles() {
    final tagSet = tags.map((tag) => tag.toLowerCase()).toSet();
    bool hasAny(Iterable<String> values) => values.any(tagSet.contains);

    if (hasAny(['road', 'asphalt', 'street', 'parking', 'line', 'marking'])) {
      return const [
        _UrbanVariantProfile(seedOffset: 71),
        _UrbanVariantProfile(seedOffset: 167, extraStyle: _UrbanExtraStyle.scuffed),
        _UrbanVariantProfile(seedOffset: 263, variation: TileVariation.weathered, extraStyle: _UrbanExtraStyle.patched),
        _UrbanVariantProfile(seedOffset: 359, variation: TileVariation.cracked, extraStyle: _UrbanExtraStyle.vegetated),
        _UrbanVariantProfile(
          seedOffset: 449,
          variation: TileVariation.pristine,
          extraStyle: _UrbanExtraStyle.paintFlecked,
        ),
        _UrbanVariantProfile(seedOffset: 541, extraStyle: _UrbanExtraStyle.scorched),
      ];
    }

    if (hasAny(['concrete', 'slab', 'pavement', 'sidewalk', 'floor', 'tile'])) {
      return const [
        _UrbanVariantProfile(seedOffset: 73, extraStyle: _UrbanExtraStyle.panelled),
        _UrbanVariantProfile(seedOffset: 169, variation: TileVariation.weathered, extraStyle: _UrbanExtraStyle.dusty),
        _UrbanVariantProfile(seedOffset: 267, variation: TileVariation.cracked, extraStyle: _UrbanExtraStyle.chipped),
        _UrbanVariantProfile(seedOffset: 363, variation: TileVariation.pristine, extraStyle: _UrbanExtraStyle.shined),
        _UrbanVariantProfile(seedOffset: 457, extraStyle: _UrbanExtraStyle.damp),
        _UrbanVariantProfile(seedOffset: 547, extraStyle: _UrbanExtraStyle.rustStreaked),
      ];
    }

    if (hasAny(['roof', 'shingle', 'slate', 'terracotta', 'building'])) {
      return const [
        _UrbanVariantProfile(seedOffset: 79),
        _UrbanVariantProfile(
          seedOffset: 173,
          variation: TileVariation.weathered,
          extraStyle: _UrbanExtraStyle.rustStreaked,
        ),
        _UrbanVariantProfile(
          seedOffset: 271,
          variation: TileVariation.pristine,
          extraStyle: _UrbanExtraStyle.paintFlecked,
        ),
        _UrbanVariantProfile(seedOffset: 367, variation: TileVariation.mossy),
        _UrbanVariantProfile(seedOffset: 461, variation: TileVariation.cracked, extraStyle: _UrbanExtraStyle.patched),
        _UrbanVariantProfile(seedOffset: 557, extraStyle: _UrbanExtraStyle.scorched),
      ];
    }

    if (hasAny([
      'metal',
      'industrial',
      'mechanical',
      'pipe',
      'boiler',
      'conveyor',
      'hydraulic',
      'catwalk',
      'grating',
      'fuel',
      'drum',
      'mesh',
      'diamond',
      'plate',
    ])) {
      return const [
        _UrbanVariantProfile(seedOffset: 83, extraStyle: _UrbanExtraStyle.panelled),
        _UrbanVariantProfile(
          seedOffset: 179,
          variation: TileVariation.weathered,
          extraStyle: _UrbanExtraStyle.rustStreaked,
        ),
        _UrbanVariantProfile(seedOffset: 277, variation: TileVariation.pristine, extraStyle: _UrbanExtraStyle.shined),
        _UrbanVariantProfile(seedOffset: 373, variation: TileVariation.cracked, extraStyle: _UrbanExtraStyle.scorched),
        _UrbanVariantProfile(seedOffset: 467, extraStyle: _UrbanExtraStyle.damp),
        _UrbanVariantProfile(seedOffset: 563, extraStyle: _UrbanExtraStyle.chipped),
      ];
    }

    if (hasAny(['brick', 'cobblestone', 'paving', 'stone', 'flagstone', 'marble', 'granite', 'ceramic'])) {
      return const [
        _UrbanVariantProfile(seedOffset: 89, extraStyle: _UrbanExtraStyle.panelled),
        _UrbanVariantProfile(seedOffset: 181, variation: TileVariation.weathered, extraStyle: _UrbanExtraStyle.chipped),
        _UrbanVariantProfile(seedOffset: 281, variation: TileVariation.pristine, extraStyle: _UrbanExtraStyle.shined),
        _UrbanVariantProfile(
          seedOffset: 379,
          variation: TileVariation.cracked,
          extraStyle: _UrbanExtraStyle.rustStreaked,
        ),
        _UrbanVariantProfile(seedOffset: 471, variation: TileVariation.mossy),
        _UrbanVariantProfile(seedOffset: 569, extraStyle: _UrbanExtraStyle.overgrown),
      ];
    }

    if (hasAny(['grass', 'dirt', 'soil', 'sand', 'gravel', 'rock', 'cliff', 'beach'])) {
      return const [
        _UrbanVariantProfile(seedOffset: 97),
        _UrbanVariantProfile(seedOffset: 191, extraStyle: _UrbanExtraStyle.vegetated),
        _UrbanVariantProfile(seedOffset: 283, variation: TileVariation.weathered, extraStyle: _UrbanExtraStyle.pebbled),
        _UrbanVariantProfile(seedOffset: 383, variation: TileVariation.cracked, extraStyle: _UrbanExtraStyle.vegetated),
        _UrbanVariantProfile(seedOffset: 479, extraStyle: _UrbanExtraStyle.damp),
        _UrbanVariantProfile(seedOffset: 571, extraStyle: _UrbanExtraStyle.rippled),
      ];
    }

    return const [
      _UrbanVariantProfile(seedOffset: 101),
      _UrbanVariantProfile(seedOffset: 193, variation: TileVariation.weathered, extraStyle: _UrbanExtraStyle.dusty),
      _UrbanVariantProfile(seedOffset: 287, variation: TileVariation.pristine, extraStyle: _UrbanExtraStyle.shined),
      _UrbanVariantProfile(seedOffset: 389, variation: TileVariation.cracked, extraStyle: _UrbanExtraStyle.chipped),
      _UrbanVariantProfile(seedOffset: 487, extraStyle: _UrbanExtraStyle.panelled),
      _UrbanVariantProfile(seedOffset: 577, extraStyle: _UrbanExtraStyle.paintFlecked),
    ];
  }

  void _applyTerrainVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _TerrainVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _TerrainExtraStyle.none:
        break;
      case _TerrainExtraStyle.rippled:
        TileProceduralEffects.applyRipples(
          pixels,
          width,
          height,
          random,
          strength: 0.45,
          lightColor: palette.highlight,
          darkColor: palette.shadow,
        );
      case _TerrainExtraStyle.pebbled:
        TileProceduralEffects.applyPebbles(
          pixels,
          width,
          height,
          random,
          density: 0.08,
          lightColor: palette.secondary,
          darkColor: palette.shadow,
        );
      case _TerrainExtraStyle.drifted:
        TileProceduralEffects.applyDrifts(
          pixels,
          width,
          height,
          random,
          strength: 0.42,
          crestColor: palette.highlight,
          troughColor: palette.secondary,
        );
      case _TerrainExtraStyle.vegetated:
        TileProceduralEffects.applyVegetationPatches(
          pixels,
          width,
          height,
          random,
          coverage: 0.22,
          lightColor: palette.highlight,
          darkColor: palette.primary,
        );
      case _TerrainExtraStyle.sparkled:
        TileProceduralEffects.applyDrifts(
          pixels,
          width,
          height,
          random,
          strength: 0.28,
          crestColor: palette.highlight,
          troughColor: palette.secondary,
        );
        TileProceduralEffects.applyPebbles(
          pixels,
          width,
          height,
          random,
          density: 0.03,
          lightColor: palette.highlight,
          darkColor: palette.highlight,
        );
    }
  }

  void _applyStructureVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _StructureVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _StructureExtraStyle.none:
        break;
      case _StructureExtraStyle.panelled:
        TileProceduralEffects.applyPanelHighlights(
          pixels,
          width,
          height,
          random,
          lineColor: palette.highlight,
          spacing: width >= 16 ? 6 : 4,
        );
      case _StructureExtraStyle.woodKnotted:
        TileProceduralEffects.applyWoodKnots(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 3 : 2,
          knotColor: palette.shadow,
        );
      case _StructureExtraStyle.chipped:
        TileProceduralEffects.applyMasonryChips(
          pixels,
          width,
          height,
          random,
          density: 0.06,
          chipColor: palette.shadow,
        );
    }
  }

  void _applyLiquidVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _LiquidVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _LiquidExtraStyle.none:
        break;
      case _LiquidExtraStyle.rippled:
        TileProceduralEffects.applyRipples(
          pixels,
          width,
          height,
          random,
          strength: 0.48,
          lightColor: palette.highlight,
          darkColor: palette.shadow,
        );
      case _LiquidExtraStyle.foamy:
        TileProceduralEffects.applyFoamCaps(pixels, width, height, random, density: 0.14, foamColor: palette.highlight);
      case _LiquidExtraStyle.bubbly:
        TileProceduralEffects.applySurfaceBubbles(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 4 : 2,
          bubbleColor: palette.highlight,
          rimColor: palette.secondary,
        );
      case _LiquidExtraStyle.sheened:
        TileProceduralEffects.applyIridescence(pixels, width, height, random, strength: 0.42);
      case _LiquidExtraStyle.caustic:
        TileProceduralEffects.applyCausticGlow(
          pixels,
          width,
          height,
          random,
          strength: 0.4,
          glowColor: palette.highlight,
        );
      case _LiquidExtraStyle.glowing:
        TileProceduralEffects.applyCausticGlow(
          pixels,
          width,
          height,
          random,
          strength: 0.32,
          glowColor: palette.accent,
        );
      case _LiquidExtraStyle.algal:
        TileProceduralEffects.applyVegetationPatches(
          pixels,
          width,
          height,
          random,
          coverage: 0.16,
          lightColor: palette.secondary,
          darkColor: palette.primary,
        );
    }
  }

  void _applySpecialVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _SpecialVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _SpecialExtraStyle.none:
        break;
      case _SpecialExtraStyle.glints:
        TileProceduralEffects.applyStarGlints(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 5 : 3,
          glintColor: palette.highlight,
        );
      case _SpecialExtraStyle.glyphs:
        TileProceduralEffects.applyArcaneGlyphs(
          pixels,
          width,
          height,
          random,
          glyphCount: width >= 16 ? 3 : 2,
          glyphColor: palette.highlight,
        );
      case _SpecialExtraStyle.energyVeins:
        TileProceduralEffects.applyEnergyVeins(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 3 : 2,
          veinColor: palette.accent,
        );
      case _SpecialExtraStyle.voidFlecks:
        TileProceduralEffects.applyVoidFlecks(
          pixels,
          width,
          height,
          random,
          density: 0.08,
          darkColor: palette.shadow,
          lightColor: palette.secondary,
        );
    }
  }

  void _applyDecorationVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _DecorationVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _DecorationExtraStyle.none:
        break;
      case _DecorationExtraStyle.trimmed:
        TileProceduralEffects.applyDecorativeTrim(pixels, width, height, random, trimColor: palette.highlight);
      case _DecorationExtraStyle.patterned:
        TileProceduralEffects.applyFabricPattern(
          pixels,
          width,
          height,
          random,
          patternColor: palette.highlight,
          spacing: width >= 16 ? 4 : 3,
        );
      case _DecorationExtraStyle.shined:
        TileProceduralEffects.applyMetalShine(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 4 : 2,
          shineColor: palette.highlight,
        );
      case _DecorationExtraStyle.dusty:
        TileProceduralEffects.applyDustSpecks(
          pixels,
          width,
          height,
          random,
          density: 0.06,
          dustColor: palette.secondary,
        );
    }
  }

  void _applyDungeonVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _DungeonVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _DungeonExtraStyle.none:
        break;
      case _DungeonExtraStyle.jointed:
        TileProceduralEffects.applyPanelHighlights(
          pixels,
          width,
          height,
          random,
          lineColor: palette.highlight,
          spacing: width >= 16 ? 5 : 4,
        );
      case _DungeonExtraStyle.chipped:
        TileProceduralEffects.applyMasonryChips(
          pixels,
          width,
          height,
          random,
          density: 0.07,
          chipColor: palette.shadow,
        );
      case _DungeonExtraStyle.damp:
        TileProceduralEffects.applyDampPatches(
          pixels,
          width,
          height,
          random,
          strength: 0.26,
          dampColor: palette.shadow,
          sheenColor: palette.secondary,
        );
      case _DungeonExtraStyle.mineralVeins:
        TileProceduralEffects.applyMineralVeins(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 3 : 2,
          veinColor: palette.secondary,
          accentColor: palette.highlight,
        );
      case _DungeonExtraStyle.runeCarved:
        TileProceduralEffects.applyRuneCarvings(
          pixels,
          width,
          height,
          random,
          glyphCount: width >= 16 ? 4 : 2,
          carveColor: palette.shadow,
          highlightColor: palette.highlight,
        );
    }
  }

  void _applyUrbanVariantProfile(
    Uint32List pixels,
    int width,
    int height,
    Random random,
    _UrbanVariantProfile profile,
  ) {
    switch (profile.extraStyle) {
      case _UrbanExtraStyle.none:
        break;
      case _UrbanExtraStyle.scuffed:
        TileProceduralEffects.applyRoadScuffs(
          pixels,
          width,
          height,
          random,
          laneCount: height >= 16 ? 3 : 2,
          darkColor: palette.shadow,
          lightColor: palette.secondary,
        );
      case _UrbanExtraStyle.patched:
        TileProceduralEffects.applyPatchRepairs(
          pixels,
          width,
          height,
          random,
          patchCount: width >= 16 ? 3 : 2,
          patchColor: palette.primary,
          seamColor: palette.shadow,
        );
      case _UrbanExtraStyle.rustStreaked:
        TileProceduralEffects.applyRustStreaks(
          pixels,
          width,
          height,
          random,
          streakCount: width >= 16 ? 4 : 2,
          rustColor: palette.accent,
        );
      case _UrbanExtraStyle.paintFlecked:
        TileProceduralEffects.applyPaintFlecks(
          pixels,
          width,
          height,
          random,
          density: 0.05,
          paintColor: palette.highlight,
        );
      case _UrbanExtraStyle.panelled:
        TileProceduralEffects.applyPanelHighlights(
          pixels,
          width,
          height,
          random,
          lineColor: palette.highlight,
          spacing: width >= 16 ? 6 : 4,
        );
      case _UrbanExtraStyle.chipped:
        TileProceduralEffects.applyMasonryChips(
          pixels,
          width,
          height,
          random,
          density: 0.06,
          chipColor: palette.shadow,
        );
      case _UrbanExtraStyle.shined:
        TileProceduralEffects.applyMetalShine(
          pixels,
          width,
          height,
          random,
          count: width >= 16 ? 4 : 2,
          shineColor: palette.highlight,
        );
      case _UrbanExtraStyle.dusty:
        TileProceduralEffects.applyDustSpecks(
          pixels,
          width,
          height,
          random,
          density: 0.06,
          dustColor: palette.secondary,
        );
      case _UrbanExtraStyle.scorched:
        TileProceduralEffects.applyScorch(pixels, width, height, random);
      case _UrbanExtraStyle.pebbled:
        TileProceduralEffects.applyPebbles(
          pixels,
          width,
          height,
          random,
          density: 0.08,
          lightColor: palette.highlight,
          darkColor: palette.shadow,
        );
      case _UrbanExtraStyle.rippled:
        TileProceduralEffects.applyRipples(
          pixels,
          width,
          height,
          random,
          strength: 0.42,
          lightColor: palette.highlight,
          darkColor: palette.shadow,
        );
      case _UrbanExtraStyle.vegetated:
        TileProceduralEffects.applyVegetationPatches(
          pixels,
          width,
          height,
          random,
          coverage: 0.16,
          lightColor: palette.secondary,
          darkColor: palette.primary,
        );
      case _UrbanExtraStyle.damp:
        TileProceduralEffects.applyDampPatches(
          pixels,
          width,
          height,
          random,
          strength: 0.28,
          dampColor: palette.shadow,
          sheenColor: palette.secondary,
        );
      case _UrbanExtraStyle.overgrown:
        TileProceduralEffects.applyOvergrown(pixels, width, height, random);
    }
  }
}

class _TerrainVariantProfile {
  const _TerrainVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _TerrainExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _TerrainExtraStyle extraStyle;
}

enum _TerrainExtraStyle { none, rippled, pebbled, drifted, vegetated, sparkled }

class _StructureVariantProfile {
  const _StructureVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _StructureExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _StructureExtraStyle extraStyle;
}

enum _StructureExtraStyle { none, panelled, woodKnotted, chipped }

class _LiquidVariantProfile {
  const _LiquidVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _LiquidExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _LiquidExtraStyle extraStyle;
}

enum _LiquidExtraStyle { none, rippled, foamy, bubbly, sheened, caustic, glowing, algal }

class _SpecialVariantProfile {
  const _SpecialVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _SpecialExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _SpecialExtraStyle extraStyle;
}

enum _SpecialExtraStyle { none, glints, glyphs, energyVeins, voidFlecks }

class _DecorationVariantProfile {
  const _DecorationVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _DecorationExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _DecorationExtraStyle extraStyle;
}

enum _DecorationExtraStyle { none, trimmed, patterned, shined, dusty }

class _DungeonVariantProfile {
  const _DungeonVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _DungeonExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _DungeonExtraStyle extraStyle;
}

enum _DungeonExtraStyle { none, jointed, chipped, damp, mineralVeins, runeCarved }

class _UrbanVariantProfile {
  const _UrbanVariantProfile({
    required this.seedOffset,
    this.variation = TileVariation.standard,
    this.extraStyle = _UrbanExtraStyle.none,
  });

  final int seedOffset;
  final TileVariation variation;
  final _UrbanExtraStyle extraStyle;
}

enum _UrbanExtraStyle {
  none,
  scuffed,
  patched,
  rustStreaked,
  paintFlecked,
  panelled,
  chipped,
  shined,
  dusty,
  scorched,
  pebbled,
  rippled,
  vegetated,
  damp,
  overgrown,
}

/// Tile categories for organization
enum TileCategory {
  terrain('Terrain', 'Ground surfaces like grass, dirt, sand'),
  structure('Structure', 'Man-made structures like walls, floors'),
  nature('Nature', 'Natural elements like rocks, trees'),
  liquid('Liquid', 'Water, lava, and other fluids'),
  special('Special', 'Magical and special effect tiles'),
  decoration('Decoration', 'Decorative elements'),
  dungeon('Dungeon', 'Dungeon and cave tiles'),
  urban('Urban', 'City and road tiles'),
  varied('Varied', 'Tiles with varied color palettes'),
  platformer('Platformer', 'Tiles for platformer games'),
  scifi('Sci-Fi', 'Futuristic and sci-fi themed tiles');

  final String name;
  final String description;
  const TileCategory(this.name, this.description);
}

/// Tile variations for generation diversity
enum TileVariation {
  standard,
  weathered,
  mossy,
  cracked,
  pristine,
  frozen,
  overgrown,
  burnt,
  submerged,
  rusted,
  haunted,
  gilded,
  shattered,
}

/// Orientation parameter for generate() / generateFrame() — replaces per-class boolean flags.
enum TileOrientation { none, horizontal, vertical, top, bottom, left, right }

// ============================================================================
// TILE REGISTRY
// ============================================================================

/// Registry of all available tile types
class TileRegistry {
  TileRegistry._();
  static final instance = TileRegistry._();

  /// All registered tile types
  final Map<String, TileBase Function()> _registry = {
    // =========================================================================
    // TERRAIN TILES (Original)
    // =========================================================================
    'grass': () => GrassTile('grass'),
    'grass_flowers': () => GrassTile('grass_flowers', includeFlowers: true),
    'dirt': () => DirtTile('dirt'),
    'sand': () => SandTile('sand'),
    'snow': () => SnowTile('snow'),

    // =========================================================================
    // STRUCTURE TILES (Original)
    // =========================================================================
    'wall_brick': () => WallTile('wall_brick', style: WallStyle.brick),
    'wall_stone': () => WallTile('wall_stone', style: WallStyle.stone),
    'wall_dark': () => WallTile('wall_dark', style: WallStyle.darkBrick),
    'wall_cobble': () => WallTile('wall_cobble', style: WallStyle.cobblestone),
    'floor_wood': () => FloorTile('floor_wood', style: FloorStyle.wood),
    'floor_stone': () => FloorTile('floor_stone', style: FloorStyle.stone),
    'floor_tile': () => FloorTile('floor_tile', style: FloorStyle.tile),

    // =========================================================================
    // LIQUID TILES (Original)
    // =========================================================================
    'water': () => WaterTile('water'),
    'water_deep': () => WaterTile('water_deep', deep: true),
    'lava': () => LavaTile('lava'),
    'lava_crust': () => LavaTile('lava_crust', bubbleRate: 0.08, crustAmount: 0.62),
    'acid': () => AcidTile('acid'),
    'acid_glow': () => AcidTile('acid_glow', bubbleRate: 0.2, toxicGlow: 0.78),
    'slime': () => SlimeTile('slime'),
    'slime_heavy': () => SlimeTile('slime_heavy', bubbleRate: 0.1, viscosity: 0.88),
    'oil': () => OilTile('oil'),
    'oil_sheen': () => OilTile('oil_sheen', rainbowSheen: true, slickStrength: 0.72),

    // =========================================================================
    // NATURE TILES
    // =========================================================================
    // Rocks and Stones
    'stone': () => StoneTile('stone'),
    'stone_mossy': () => StoneTile('stone_mossy', addMoss: true),
    'stone_large': () => StoneTile('stone_large', large: true),
    'stone_brown': () => StoneTile('stone_brown', rockPalette: NaturePalettes.brownRock),
    'rock_pile': () => RockPileTile('rock_pile'),
    'boulder': () => BoulderTile('boulder'),
    'boulder_cracked': () => BoulderTile('boulder_cracked', cracked: true),

    // Trees
    'tree_trunk_oak': () => TreeTrunkTile('tree_trunk_oak', oak: true),
    'tree_trunk_pine': () => TreeTrunkTile('tree_trunk_pine', oak: false),
    'tree_foliage': () => TreeFoliageTile('tree_foliage'),
    'tree_foliage_autumn': () => TreeFoliageTile('tree_foliage_autumn', autumn: true),
    'tree_foliage_cherry': () => TreeFoliageTile('tree_foliage_cherry', cherry: true),
    'pine_tree': () => PineTreeTile('pine_tree'),
    'pine_tree_snowy': () => PineTreeTile('pine_tree_snowy', snow: true),

    // Flowers
    'flower_red': () => FlowerTile('flower_red', colorPalette: NaturePalettes.flowerRed),
    'flower_yellow': () => FlowerTile('flower_yellow', colorPalette: NaturePalettes.flowerYellow),
    'flower_blue': () => FlowerTile('flower_blue', colorPalette: NaturePalettes.flowerBlue),
    'flower_purple': () => FlowerTile('flower_purple', colorPalette: NaturePalettes.flowerPurple),
    'flower_patch_red': () => FlowerPatchTile('flower_patch_red', colorPalette: NaturePalettes.flowerRed),
    'flower_patch_yellow': () => FlowerPatchTile('flower_patch_yellow', colorPalette: NaturePalettes.flowerYellow),
    'flower_patch_mixed': () => FlowerPatchTile('flower_patch_mixed', flowerCount: 5),

    // Grass and Vegetation
    'tall_grass': () => TallGrassTile('tall_grass'),
    'tall_grass_dense': () => TallGrassTile('tall_grass_dense', dense: true),
    'reed': () => ReedTile('reed'),
    'cattail': () => ReedTile('cattail', cattail: true),
    'bush': () => BushTile('bush'),
    'berry_bush': () => BushTile('berry_bush', berries: true),

    // Mushrooms
    'mushroom': () => MushroomTile('mushroom'),
    'mushroom_glowing': () => MushroomTile('mushroom_glowing', glowing: true),
    'mushroom_cluster': () => MushroomTile('mushroom_cluster', cluster: true),

    // Crystals
    'crystal_blue': () => NatureCrystalTile('crystal_blue'),
    'crystal_purple': () => NatureCrystalTile('crystal_purple', crystalPalette: NaturePalettes.amethyst),
    'crystal_green': () => NatureCrystalTile('crystal_green', crystalPalette: NaturePalettes.emerald),

    // Wood
    'log': () => LogTile('log'),
    'log_mossy': () => LogTile('log_mossy', mossy: true),
    'tree_stump': () => StumpTile('tree_stump'),

    // Water Plants
    'lily_pad': () => NatureLilyPadTile('lily_pad'),
    'lily_pad_flower': () => NatureLilyPadTile('lily_pad_flower', withFlower: true),
    'vine_hanging': () => VineTile('vine_hanging', hanging: true),
    'vine_climbing': () => VineTile('vine_climbing', hanging: false),

    // =========================================================================
    // SPECIAL TILES (Original)
    // =========================================================================
    'crystal': () => CrystalTile('crystal'),

    // =========================================================================
    // URBAN / ROAD TILES (NEW)
    // =========================================================================
    'asphalt': () => AsphaltTile('asphalt'),
    'asphalt_cracked': () => AsphaltTile('asphalt_cracked', addCracks: true),
    'asphalt_patched': () => AsphaltTile('asphalt_patched', addPatches: true),
    'road_center_line': () => RoadCenterLineTile('road_center_line'),
    'road_center_line_dashed': () => RoadCenterLineTile('road_center_line_dashed', dashed: true),
    'road_double_yellow': () => RoadCenterLineTile('road_double_yellow', doubleYellow: true),
    'road_edge_left': () => RoadEdgeLineTile('road_edge_left'),
    'road_edge_right': () => RoadEdgeLineTile('road_edge_right'),
    'parking_lot': () => ParkingLotTile('parking_lot'),

    // =========================================================================
    // CONCRETE TILES (NEW)
    // =========================================================================
    'concrete': () => ConcreteTile('concrete'),
    'concrete_joints': () => ConcreteTile('concrete_joints', addJoints: true),
    'concrete_cracked': () => ConcreteTile('concrete_cracked', addCracks: true),
    'concrete_slab': () => ConcreteSlabTile('concrete_slab'),
    'concrete_slab_small': () => ConcreteSlabTile('concrete_slab_small', slabSize: 4),

    // =========================================================================
    // GRASS VARIATIONS (NEW)
    // =========================================================================
    'lush_grass': () => LushGrassTile('lush_grass'),
    'lush_grass_dense': () => LushGrassTile('lush_grass_dense', density: 0.6),
    'worn_grass': () => WornGrassTile('worn_grass'),
    'dry_grass': () => DryGrassTile('dry_grass'),

    // =========================================================================
    // DIRT AND SOIL TILES (NEW)
    // =========================================================================
    'soil': () => SoilTile('soil'),
    'soil_rocky': () => SoilTile('soil_rocky', addRocks: true),
    'cracked_earth': () => CrackedEarthTile('cracked_earth'),
    'gravel': () => GravelTile('gravel'),
    'fine_gravel': () => GravelTile('fine_gravel', fine: true),

    // =========================================================================
    // ROCK AND CLIFF TILES (NEW)
    // =========================================================================
    'rock_cliff': () => RockCliffTile('rock_cliff'),
    'mossy_rock': () => MossyRockTile('mossy_rock'),

    // =========================================================================
    // ROOF TILES (NEW)
    // =========================================================================
    'roof_tile': () => RoofTileTile('roof_tile'),
    'roof_tile_large': () => RoofTileTile('roof_tile_large', tileHeight: 6),
    'slate_roof': () => SlateRoofTile('slate_roof'),
    'shingle_roof': () => ShingleRoofTile('shingle_roof'),

    // =========================================================================
    // PAVING AND FLOOR TILES (NEW)
    // =========================================================================
    'cobblestone_paving': () => CobblestonePavingTile('cobblestone_paving'),
    'cobblestone_irregular': () => CobblestonePavingTile('cobblestone_irregular', irregular: true),
    'checkered_floor': () => CheckeredFloorTile('checkered_floor'),
    'checkered_floor_small': () => CheckeredFloorTile('checkered_floor_small', tileSize: 2),
    'square_floor_tile': () => SquareFloorTile('square_floor_tile'),
    'beach_sand': () => BeachSandTile('beach_sand'),
    'beach_sand_shells': () => BeachSandTile('beach_sand_shells', addShells: true),

    // =========================================================================
    // BRICK PATTERN VARIATIONS (NEW)
    // =========================================================================
    'running_bond_brick': () => RunningBondBrickTile('running_bond_brick'),
    'stack_bond_brick': () => StackBondBrickTile('stack_bond_brick'),
    'basket_weave_brick': () => BasketWeaveBrickTile('basket_weave_brick'),
    'diagonal_brick': () => DiagonalBrickTile('diagonal_brick'),
    'herringbone_brick': () => HerringboneBrickTile('herringbone_brick'),

    // =========================================================================
    // STONE PATTERN VARIATIONS (NEW)
    // =========================================================================
    'flagstone': () => FlagstoneTile('flagstone'),
    'ashlar_stone': () => AshlarStoneTile('ashlar_stone'),
    'river_rock': () => RiverRockTile('river_rock'),

    // =========================================================================
    // DECORATIVE FLOOR TILES (NEW)
    // =========================================================================
    'marble_floor': () => MarbleFloorTile('marble_floor'),
    'marble_floor_small': () => MarbleFloorTile('marble_floor_small', tileSize: 4),
    'granite_floor': () => GraniteFloorTile('granite_floor'),
    'ceramic_tile': () => CeramicTileTile('ceramic_tile'),

    // =========================================================================
    // WOOD AND METAL SURFACES (NEW)
    // =========================================================================
    'weathered_wood': () => WeatheredWoodTile('weathered_wood'),
    'corrugated_metal': () => CorrugatedMetalTile('corrugated_metal'),
    'rusty_metal': () => RustyMetalTile('rusty_metal'),
    'diamond_plate': () => DiamondPlateTile('diamond_plate'),
    'metal_grating': () => GratingTile('metal_grating'),
    'metal_grating_fine': () => GratingTile('metal_grating_fine', gridSize: 2),

    // =========================================================================
    // EXISTING DUNGEON STONE TILES
    // =========================================================================
    'horizontal_stone_brick': () => HorizontalStoneBrickTile('horizontal_stone_brick'),
    'horizontal_stone_brick_light': () =>
        HorizontalStoneBrickTile('horizontal_stone_brick_light', style: HorizontalBrickStyle.light),
    'horizontal_stone_brick_worn': () =>
        HorizontalStoneBrickTile('horizontal_stone_brick_worn', style: HorizontalBrickStyle.worn),
    'vine_covered_stone': () => VineCoveredStoneTile('vine_covered_stone'),
    'rough_textured_stone': () => RoughTexturedStoneTile('rough_textured_stone'),
    'stone_brick_transition': () => StoneBrickTransitionTile('stone_brick_transition'),
    'vertical_stone_column': () => VerticalStoneColumnTile('vertical_stone_column'),
    'stone_with_grass_top': () => StoneWithGrassTopTile('stone_with_grass_top'),
    'ornate_stone_block': () => OrnateStoneBlockTile('ornate_stone_block'),
    'large_stone_blocks': () => LargeStoneBlocksTile('large_stone_blocks'),
    'dark_vertical_planks': () => DarkVerticalPlanksTile('dark_vertical_planks'),
    'ice_frost_stone': () => IceFrostStoneTile('ice_frost_stone'),
    'large_brick_pattern': () => LargeBrickPatternTile('large_brick_pattern'),
    'stone_with_door': () => StoneWithDoorTile('stone_with_door'),
    'cracked_stone_floor': () => CrackedStoneFloorTile('cracked_stone_floor'),
    'mossy_dungeon_wall': () => MossyDungeonWallTile('mossy_dungeon_wall'),
    'ancient_ruin_stone': () => AncientRuinStoneTile('ancient_ruin_stone'),
    'carved_stone_tile': () => CarvedStoneTileTile('carved_stone_tile'),

    // =========================================================================
    // EXTENDED GRAY STONE TILES
    // =========================================================================
    'rough_stone_floor': () => RoughStoneFloorTile('rough_stone_floor'),
    'vine_stone_floor': () => VineStoneFloorTile('vine_stone_floor'),
    'regular_stone_brick': () => RegularStoneBrickTile('regular_stone_brick'),
    'vertical_stone_stripes': () => VerticalStoneStripesTile('vertical_stone_stripes'),
    'concentric_square_stone': () => ConcentricSquareStoneTile('concentric_square_stone'),
    'cross_hatch_stone': () => CrossHatchStoneTile('cross_hatch_stone'),
    'large_bordered_stone_block': () => LargeBorderedStoneBlockTile('large_bordered_stone_block'),
    'horizontal_stone_slab': () => HorizontalStoneSlabTile('horizontal_stone_slab'),
    'mossy_large_stone': () => MossyLargeStoneTile('mossy_large_stone'),
    'inset_square_stone': () => InsetSquareStoneTile('inset_square_stone'),
    'striped_border_stone': () => StripedBorderStoneTile('striped_border_stone'),
    'horizontal_lined_stone': () => HorizontalLinedStoneTile('horizontal_lined_stone'),

    // =========================================================================
    // NEW DUNGEON SPECIALTY TILES
    // =========================================================================
    'dungeon_pit_floor': () => DungeonPitFloorTile('dungeon_pit_floor'),
    'blood_stained_floor': () => BloodStainedFloorTile('blood_stained_floor'),
    'runic_floor': () => RunicFloorTile('runic_floor'),
    'catacomb_floor': () => CatacombFloorTile('catacomb_floor'),
    'ancient_flagstone_floor': () => AncientFlagstoneFloorTile('ancient_flagstone_floor'),
    'dungeon_water_pool': () => DungeonWaterPoolTile('dungeon_water_pool'),
    'stone_pillar_base': () => StonePillarBaseTile('stone_pillar_base'),

    // =========================================================================
    // EXTENDED BROWN BRICK TILES
    // =========================================================================
    'rough_brown_brick_floor': () => BrownBrickTile('rough_brown_brick_floor', style: BrownBrickStyle.rough),
    'horizontal_brown_brick': () => BrownBrickTile('horizontal_brown_brick', style: BrownBrickStyle.horizontal),
    'diagonal_brown_brick': () => BrownBrickTile('diagonal_brown_brick', style: BrownBrickStyle.diagonal),
    'vine_brown_brick': () => BrownBrickTile('vine_brown_brick', style: BrownBrickStyle.vine),
    'standard_brown_brick_wall': () => BrownBrickTile('standard_brown_brick_wall', style: BrownBrickStyle.standard),
    'grid_brown_brick': () => BrownBrickTile('grid_brown_brick', style: BrownBrickStyle.grid),
    'large_bordered_brown_brick': () =>
        BrownBrickTile('large_bordered_brown_brick', style: BrownBrickStyle.largeBordered),
    'horizontal_brown_brick_slab': () => BrownBrickTile('horizontal_brown_brick_slab', style: BrownBrickStyle.slab),

    // =========================================================================
    // RED ROOF VARIANTS
    // =========================================================================
    'roof_shingle_red': () => ColoredRoofShingleTile('roof_shingle_red', colorPalette: ColoredRoofPalettes.redRoof),
    'roof_curved_red': () => ColoredRoofTileTile('roof_curved_red', colorPalette: ColoredRoofPalettes.redRoof),
    'small_brick_red': () => ColoredSmallBrickTile('small_brick_red', colorPalette: ColoredRoofPalettes.redRoof),

    // =========================================================================
    // ORANGE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_orange': () =>
        ColoredRoofShingleTile('roof_shingle_orange', colorPalette: ColoredRoofPalettes.orangeRoof),
    'roof_curved_orange': () => ColoredRoofTileTile('roof_curved_orange', colorPalette: ColoredRoofPalettes.orangeRoof),
    'small_brick_orange': () =>
        ColoredSmallBrickTile('small_brick_orange', colorPalette: ColoredRoofPalettes.orangeRoof),

    // =========================================================================
    // TEAL ROOF VARIANTS
    // =========================================================================
    'roof_shingle_teal': () => ColoredRoofShingleTile('roof_shingle_teal', colorPalette: ColoredRoofPalettes.tealRoof),
    'roof_curved_teal': () => ColoredRoofTileTile('roof_curved_teal', colorPalette: ColoredRoofPalettes.tealRoof),
    'small_brick_teal': () => ColoredSmallBrickTile('small_brick_teal', colorPalette: ColoredRoofPalettes.tealRoof),

    // =========================================================================
    // PURPLE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_purple': () =>
        ColoredRoofShingleTile('roof_shingle_purple', colorPalette: ColoredRoofPalettes.purpleRoof),
    'roof_curved_purple': () => ColoredRoofTileTile('roof_curved_purple', colorPalette: ColoredRoofPalettes.purpleRoof),
    'small_brick_purple': () =>
        ColoredSmallBrickTile('small_brick_purple', colorPalette: ColoredRoofPalettes.purpleRoof),

    // =========================================================================
    // MAROON ROOF VARIANTS
    // =========================================================================
    'roof_shingle_maroon': () =>
        ColoredRoofShingleTile('roof_shingle_maroon', colorPalette: ColoredRoofPalettes.maroonRoof),
    'roof_curved_maroon': () => ColoredRoofTileTile('roof_curved_maroon', colorPalette: ColoredRoofPalettes.maroonRoof),
    'small_brick_maroon': () =>
        ColoredSmallBrickTile('small_brick_maroon', colorPalette: ColoredRoofPalettes.maroonRoof),

    // =========================================================================
    // BLUE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_blue': () => ColoredRoofShingleTile('roof_shingle_blue', colorPalette: ColoredRoofPalettes.blueRoof),
    'roof_curved_blue': () => ColoredRoofTileTile('roof_curved_blue', colorPalette: ColoredRoofPalettes.blueRoof),
    'small_brick_blue': () => ColoredSmallBrickTile('small_brick_blue', colorPalette: ColoredRoofPalettes.blueRoof),

    // =========================================================================
    // NAVY ROOF VARIANTS
    // =========================================================================
    'roof_shingle_navy': () => ColoredRoofShingleTile('roof_shingle_navy', colorPalette: ColoredRoofPalettes.navyRoof),
    'roof_curved_navy': () => ColoredRoofTileTile('roof_curved_navy', colorPalette: ColoredRoofPalettes.navyRoof),
    'small_brick_navy': () => ColoredSmallBrickTile('small_brick_navy', colorPalette: ColoredRoofPalettes.navyRoof),

    // =========================================================================
    // GRAY ROOF VARIANTS
    // =========================================================================
    'roof_shingle_gray': () => ColoredRoofShingleTile('roof_shingle_gray', colorPalette: ColoredRoofPalettes.grayRoof),
    'roof_curved_gray': () => ColoredRoofTileTile('roof_curved_gray', colorPalette: ColoredRoofPalettes.grayRoof),
    'small_brick_gray': () => ColoredSmallBrickTile('small_brick_gray', colorPalette: ColoredRoofPalettes.grayRoof),

    // =========================================================================
    // DARK GRAY ROOF VARIANTS
    // =========================================================================
    'roof_shingle_dark_gray': () =>
        ColoredRoofShingleTile('roof_shingle_dark_gray', colorPalette: ColoredRoofPalettes.darkGrayRoof),
    'roof_curved_dark_gray': () =>
        ColoredRoofTileTile('roof_curved_dark_gray', colorPalette: ColoredRoofPalettes.darkGrayRoof),
    'small_brick_dark_gray': () =>
        ColoredSmallBrickTile('small_brick_dark_gray', colorPalette: ColoredRoofPalettes.darkGrayRoof),

    // =========================================================================
    // BROWN ROOF VARIANTS
    // =========================================================================
    'roof_shingle_brown': () =>
        ColoredRoofShingleTile('roof_shingle_brown', colorPalette: ColoredRoofPalettes.brownRoof),
    'roof_curved_brown': () => ColoredRoofTileTile('roof_curved_brown', colorPalette: ColoredRoofPalettes.brownRoof),
    'small_brick_brown': () => ColoredSmallBrickTile('small_brick_brown', colorPalette: ColoredRoofPalettes.brownRoof),

    // =========================================================================
    // GREEN ROOF VARIANTS
    // =========================================================================
    'roof_shingle_green': () =>
        ColoredRoofShingleTile('roof_shingle_green', colorPalette: ColoredRoofPalettes.greenRoof),
    'roof_curved_green': () => ColoredRoofTileTile('roof_curved_green', colorPalette: ColoredRoofPalettes.greenRoof),
    'small_brick_green': () => ColoredSmallBrickTile('small_brick_green', colorPalette: ColoredRoofPalettes.greenRoof),

    // =========================================================================
    // DARK GREEN ROOF VARIANTS
    // =========================================================================
    'roof_shingle_dark_green': () =>
        ColoredRoofShingleTile('roof_shingle_dark_green', colorPalette: ColoredRoofPalettes.darkGreenRoof),
    'roof_curved_dark_green': () =>
        ColoredRoofTileTile('roof_curved_dark_green', colorPalette: ColoredRoofPalettes.darkGreenRoof),
    'small_brick_dark_green': () =>
        ColoredSmallBrickTile('small_brick_dark_green', colorPalette: ColoredRoofPalettes.darkGreenRoof),

    // =========================================================================
    // OLIVE ROOF VARIANTS
    // =========================================================================
    'roof_shingle_olive': () =>
        ColoredRoofShingleTile('roof_shingle_olive', colorPalette: ColoredRoofPalettes.oliveRoof),
    'roof_curved_olive': () => ColoredRoofTileTile('roof_curved_olive', colorPalette: ColoredRoofPalettes.oliveRoof),
    'small_brick_olive': () => ColoredSmallBrickTile('small_brick_olive', colorPalette: ColoredRoofPalettes.oliveRoof),

    // =========================================================================
    // WARM GRAY STONE VARIANTS
    // =========================================================================
    'cobble_warm_gray': () => ColoredCobblestoneTile('cobble_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'stone_brick_warm_gray': () =>
        ColoredStoneBrickTile('stone_brick_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'rough_warm_gray': () => ColoredRoughStoneTile('rough_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'large_block_warm_gray': () =>
        ColoredLargeBlockTile('large_block_warm_gray', colorPalette: VariedStonePalettes.warmGray),
    'weathered_warm_gray': () =>
        ColoredWeatheredStoneTile('weathered_warm_gray', colorPalette: VariedStonePalettes.warmGray),

    // =========================================================================
    // COOL GRAY STONE VARIANTS
    // =========================================================================
    'cobble_cool_gray': () => ColoredCobblestoneTile('cobble_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'stone_brick_cool_gray': () =>
        ColoredStoneBrickTile('stone_brick_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'rough_cool_gray': () => ColoredRoughStoneTile('rough_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'large_block_cool_gray': () =>
        ColoredLargeBlockTile('large_block_cool_gray', colorPalette: VariedStonePalettes.coolGray),
    'weathered_cool_gray': () =>
        ColoredWeatheredStoneTile('weathered_cool_gray', colorPalette: VariedStonePalettes.coolGray),

    // =========================================================================
    // TAN STONE VARIANTS
    // =========================================================================
    'cobble_tan': () => ColoredCobblestoneTile('cobble_tan', colorPalette: VariedStonePalettes.tanStone),
    'stone_brick_tan': () => ColoredStoneBrickTile('stone_brick_tan', colorPalette: VariedStonePalettes.tanStone),
    'rough_tan': () => ColoredRoughStoneTile('rough_tan', colorPalette: VariedStonePalettes.tanStone),
    'large_block_tan': () => ColoredLargeBlockTile('large_block_tan', colorPalette: VariedStonePalettes.tanStone),
    'weathered_tan': () => ColoredWeatheredStoneTile('weathered_tan', colorPalette: VariedStonePalettes.tanStone),

    // =========================================================================
    // CREAM STONE VARIANTS
    // =========================================================================
    'cobble_cream': () => ColoredCobblestoneTile('cobble_cream', colorPalette: VariedStonePalettes.creamStone),
    'stone_brick_cream': () => ColoredStoneBrickTile('stone_brick_cream', colorPalette: VariedStonePalettes.creamStone),
    'rough_cream': () => ColoredRoughStoneTile('rough_cream', colorPalette: VariedStonePalettes.creamStone),
    'large_block_cream': () => ColoredLargeBlockTile('large_block_cream', colorPalette: VariedStonePalettes.creamStone),
    'weathered_cream': () => ColoredWeatheredStoneTile('weathered_cream', colorPalette: VariedStonePalettes.creamStone),

    // =========================================================================
    // BROWN STONE VARIANTS
    // =========================================================================
    'cobble_brown_stone': () =>
        ColoredCobblestoneTile('cobble_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'stone_brick_brown_stone': () =>
        ColoredStoneBrickTile('stone_brick_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'rough_brown_stone': () => ColoredRoughStoneTile('rough_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'large_block_brown_stone': () =>
        ColoredLargeBlockTile('large_block_brown_stone', colorPalette: VariedStonePalettes.brownStone),
    'weathered_brown_stone': () =>
        ColoredWeatheredStoneTile('weathered_brown_stone', colorPalette: VariedStonePalettes.brownStone),

    // =========================================================================
    // DARK BROWN STONE VARIANTS
    // =========================================================================
    'cobble_dark_brown': () =>
        ColoredCobblestoneTile('cobble_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'stone_brick_dark_brown': () =>
        ColoredStoneBrickTile('stone_brick_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'rough_dark_brown': () =>
        ColoredRoughStoneTile('rough_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'large_block_dark_brown': () =>
        ColoredLargeBlockTile('large_block_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),
    'weathered_dark_brown': () =>
        ColoredWeatheredStoneTile('weathered_dark_brown', colorPalette: VariedStonePalettes.darkBrownStone),

    // =========================================================================
    // OLIVE STONE VARIANTS
    // =========================================================================
    'cobble_olive_stone': () =>
        ColoredCobblestoneTile('cobble_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'stone_brick_olive_stone': () =>
        ColoredStoneBrickTile('stone_brick_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'rough_olive_stone': () => ColoredRoughStoneTile('rough_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'large_block_olive_stone': () =>
        ColoredLargeBlockTile('large_block_olive_stone', colorPalette: VariedStonePalettes.oliveStone),
    'weathered_olive_stone': () =>
        ColoredWeatheredStoneTile('weathered_olive_stone', colorPalette: VariedStonePalettes.oliveStone),

    // =========================================================================
    // WEATHERED STONE VARIANTS
    // =========================================================================
    'cobble_weathered_stone': () =>
        ColoredCobblestoneTile('cobble_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'stone_brick_weathered_stone': () =>
        ColoredStoneBrickTile('stone_brick_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'rough_weathered_stone': () =>
        ColoredRoughStoneTile('rough_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'large_block_weathered_stone': () =>
        ColoredLargeBlockTile('large_block_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),
    'weathered_weathered_stone': () =>
        ColoredWeatheredStoneTile('weathered_weathered_stone', colorPalette: VariedStonePalettes.weatheredStone),

    // =========================================================================
    // HAZARD TILES
    // =========================================================================
    'lava_drip': () => LavaDripTile('lava_drip'),
    'lava_cracks': () => LavaCracksTile('lava_cracks'),
    'poison_slime': () => PoisonSlimeTile('poison_slime'),
    'cracked_electric': () => CrackedElectricTile('cracked_electric'),

    // =========================================================================
    // LIQUID TILES
    // =========================================================================
    'water_bubble': () => WaterBubbleTile('water_bubble'),
    'deep_water_stones': () => DeepWaterStonesTile('deep_water_stones'),

    // =========================================================================
    // TERRAIN TILES
    // =========================================================================
    'grass_top_dirt': () => GrassTopDirtTile('grass_top_dirt'),
    'grass_top_dirt_thick': () => GrassTopDirtTile('grass_top_dirt_thick', grassHeight: 6),
    'sand_layers': () => SandLayersTile('sand_layers'),
    'rocky_ground': () => RockyGroundTile('rocky_ground'),
    'snow_ice_top': () => SnowIceTopTile('snow_ice_top'),
    'snow_ice_top_thick': () => SnowIceTopTile('snow_ice_top_thick', snowHeight: 7),
    'stone_path_grass': () => StonePathGrassTile('stone_path_grass'),

    // =========================================================================
    // STRUCTURE TILES
    // =========================================================================
    'metal_grate': () => MetalGrateTile('metal_grate'),
    'metal_grate_large': () => MetalGrateTile('metal_grate_large', panelSize: 6),
    'wood_plank_vertical': () => WoodPlankTile('wood_plank_vertical'),
    'wood_plank_horizontal': () => WoodPlankTile('wood_plank_horizontal'),
    'red_brick_platformer': () => RedBrickPlatformerTile('red_brick_platformer'),

    // =========================================================================
    // DECORATION/PATTERN TILES
    // =========================================================================
    'fish_scale': () => FishScaleTile('fish_scale'),
    'honeycomb': () => HoneycombTile('honeycomb'),
    'purple_octagon': () => PurpleOctagonTile('purple_octagon'),
    'orange_scale': () => OrangeScaleTile('orange_scale'),

    // =========================================================================
    // DECORATION TILES - CONTAINERS
    // =========================================================================
    'wooden_crate': () => WoodenCrateTile('wooden_crate'),
    'wooden_crate_open': () => WoodenCrateTile('wooden_crate_open', open: true),
    'barrel': () => BarrelTile('barrel'),
    'barrel_sideways': () => BarrelTile('barrel_sideways', sideways: true),
    'treasure_chest': () => TreasureChestTile('treasure_chest'),
    'treasure_chest_open': () => TreasureChestTile('treasure_chest_open', open: true),
    'mimic_chest': () => TreasureChestTile('mimic_chest', open: true, mimic: true),
    'pot': () => PotTile('pot'),
    'pot_broken': () => PotTile('pot_broken', broken: true),
    'sack': () => SackTile('sack'),
    'sack_open': () => SackTile('sack_open', open: true),

    // =========================================================================
    // DECORATION TILES - LIGHTING
    // =========================================================================
    'torch_lit': () => TorchTile('torch_lit'),
    'torch_unlit': () => TorchTile('torch_unlit', lit: false),
    'lantern_lit': () => LanternTile('lantern_lit'),
    'lantern_unlit': () => LanternTile('lantern_unlit', lit: false),
    'candle': () => CandleTile('candle'),
    'candle_unlit': () => CandleTile('candle_unlit', lit: false),
    'candle_holder': () => CandleTile('candle_holder', inHolder: true),
    'brazier_lit': () => BrazierTile('brazier_lit'),
    'brazier': () => BrazierTile('brazier', lit: false),

    // =========================================================================
    // DECORATION TILES - FURNITURE
    // =========================================================================
    'table': () => TableTile('table'),
    'small_table': () => TableTile('small_table', small: true),
    'chair': () => ChairTile('chair'),
    'bookshelf': () => BookshelfTile('bookshelf'),
    'bed': () => BedTile('bed'),

    // =========================================================================
    // DECORATION TILES - WALL DECORATIONS
    // =========================================================================
    'painting': () => PaintingTile('painting'),
    'painting_landscape': () => PaintingTile('painting_landscape', style: 0),
    'painting_portrait': () => PaintingTile('painting_portrait', style: 1),
    'painting_abstract': () => PaintingTile('painting_abstract', style: 2),
    'banner': () => BannerTile('banner'),
    'rug': () => RugTile('rug'),
    'rug_ornate': () => RugTile('rug_ornate', ornate: true),
    'curtain': () => CurtainTile('curtain'),
    'curtain_open': () => CurtainTile('curtain_open', open: true),
    'clock': () => ClockTile('clock'),

    // =========================================================================
    // DECORATION TILES - SIGNS
    // =========================================================================
    'wood_sign': () => WoodSignTile('wood_sign'),
    'hanging_sign': () => WoodSignTile('hanging_sign', hanging: true),

    // =========================================================================
    // DECORATION TILES - TREASURE & LOOT
    // =========================================================================
    'coin_pile': () => CoinPileTile('coin_pile'),
    'coin_pile_large': () => CoinPileTile('coin_pile_large', large: true),
    'gem_ruby': () => GemTile('gem_ruby', gemType: 0),
    'gem_emerald': () => GemTile('gem_emerald', gemType: 1),
    'gem_sapphire': () => GemTile('gem_sapphire', gemType: 2),
    'gem_amethyst': () => GemTile('gem_amethyst', gemType: 3),

    // =========================================================================
    // DECORATION TILES - BONES & REMAINS
    // =========================================================================
    'skull': () => SkullTile('skull'),
    'bone_pile': () => BonePileTile('bone_pile'),

    // =========================================================================
    // DECORATION TILES - WEAPONS & ARMOR
    // =========================================================================
    'weapon_rack': () => WeaponRackTile('weapon_rack'),
    'wall_shield': () => WallShieldTile('wall_shield'),

    // =========================================================================
    // DECORATION TILES - FOOD & DRINK
    // =========================================================================
    'food_plate': () => FoodPlateTile('food_plate'),
    'mug_full': () => MugTile('mug_full'),
    'mug_empty': () => MugTile('mug_empty', full: false),

    // =========================================================================
    // DECORATION TILES - TROPHIES & DISPLAYS
    // =========================================================================
    'trophy_gold': () => TrophyTile('trophy_gold'),
    'trophy_silver': () => TrophyTile('trophy_silver', gold: false),
    'statue': () => StatueTile('statue'),

    // =========================================================================
    // ORGANIC / NATURE TILES (NEW)
    // =========================================================================
    'vine_overgrown': () => VineOvergrownTile('vine_overgrown'),
    'mushroom_platform': () => MushroomPlatformTile('mushroom_platform'),
    'organic_coral_reef': () => CoralReefTile('organic_coral_reef'),
    'crystal_geode': () => CrystalGeodeTile('crystal_geode'),
    'tree_bark': () => TreeBarkTile('tree_bark'),
    'moss_stone': () => MossStoneTile('moss_stone'),
    'organic_honeycomb': () => OrganicHoneycombTile('organic_honeycomb'),
    'autumn_leaves': () => AutumnLeavesTile('autumn_leaves'),

    // =========================================================================
    // INTERACTIVE / ANIMATED TILES (NEW)
    // =========================================================================
    'conveyor_belt': () => ConveyorBeltTile('conveyor_belt'),
    'crumbling_platform': () => CrumblingPlatformTile('crumbling_platform'),
    'bouncy_gel': () => BouncyGelTile('bouncy_gel'),
    'pressure_plate': () => PressurePlateTile('pressure_plate'),
    'ice_platform': () => IcePlatformTile('ice_platform'),
    'moving_platform': () => MovingPlatformTile('moving_platform'),
    'sticky_goo': () => StickyGooTile('sticky_goo'),
    'breakable_crate': () => BreakableCrateTile('breakable_crate'),

    // =========================================================================
    // DECORATIVE / DETAIL TILES (NEW)
    // =========================================================================
    'graffiti': () => GraffitiTile('graffiti'),
    'chain': () => ChainTile('chain'),
    'neon_sign': () => NeonSignTile('neon_sign'),
    'brick_wall': () => BrickWallTile('brick_wall'),
    'pipe_system': () => PipeSystemTile('pipe_system'),
    'stained_glass': () => StainedGlassTile('stained_glass'),
    'ancient_ruins': () => AncientRuinsTile('ancient_ruins'),
    'detail_circuit_board': () => DetailCircuitBoardTile('detail_circuit_board'),

    // =========================================================================
    // FANTASY / MAGIC TILES (NEW)
    // =========================================================================
    'magic_rune_circle': () => MagicRuneCircleTile('magic_rune_circle'),
    'crystal_glow': () => CrystalGlowTile('crystal_glow'),
    'elemental_fire': () => ElementalFireTile('elemental_fire'),
    'mystic_portal': () => MysticPortalTile('mystic_portal'),
    'enchanted_vines': () => EnchantedVinesTile('enchanted_vines'),
    'dragon_scale': () => DragonScaleTile('dragon_scale'),
    'holy_light': () => HolyLightTile('holy_light'),
    'shadow_realm': () => ShadowRealmTile('shadow_realm'),

    // =========================================================================
    // MODULAR / CONNECTABLE TILES (NEW)
    // =========================================================================
    'edge_aware': () => EdgeAwareTile('edge_aware'),
    'puzzle_piece': () => PuzzlePieceTile('puzzle_piece'),
    'tetris_block': () => TetrisBlockTile('tetris_block'),
    'connector_joint': () => ConnectorJointTile('connector_joint'),
    'rail_track': () => RailTrackTile('rail_track'),
    'lego_brick': () => LegoBrickTile('lego_brick'),
    'modular_corridor': () => ModularCorridorTile('modular_corridor'),
    'auto_tiling_terrain': () => AutoTilingTerrainTile('auto_tiling_terrain'),

    // =========================================================================
    // DECORATION TILES - MISC (Original Continuation)
    // =========================================================================
    // =========================================================================
    'anvil': () => AnvilTile('anvil'),
    'rope_coil': () => RopeCoilTile('rope_coil'),
    'spider_web': () => SpiderWebTile('spider_web'),
    'lever_off': () => LeverTile('lever_off'),
    'lever_on': () => LeverTile('lever_on', activated: true),
    'key': () => KeyTile('key'),
    'golden_key': () => KeyTile('golden_key', golden: true),

    // =========================================================================
    // SPECIALIZED TILES - PORTALS
    // =========================================================================
    'portal_purple': () => PortalTile('portal_purple', portalColor: PortalColor.purple),
    'portal_blue': () => PortalTile('portal_blue', portalColor: PortalColor.blue),
    'portal_green': () => PortalTile('portal_green', portalColor: PortalColor.green),
    'portal_red': () => PortalTile('portal_red', portalColor: PortalColor.red),

    // =========================================================================
    // SPECIALIZED TILES - RUNE CIRCLES
    // =========================================================================
    'rune_circle_arcane': () => RuneCircleTile('rune_circle_arcane', runeStyle: RuneStyle.arcane),
    'rune_circle_shadow': () => RuneCircleTile('rune_circle_shadow', runeStyle: RuneStyle.shadow),
    'rune_circle_frost': () => RuneCircleTile('rune_circle_frost', runeStyle: RuneStyle.frost),
    'rune_circle_ember': () => RuneCircleTile('rune_circle_ember', runeStyle: RuneStyle.ember),

    // =========================================================================
    // SPECIALIZED TILES - ENERGY FIELDS
    // =========================================================================
    'energy_field_blue': () => EnergyFieldTile('energy_field_blue', fieldColor: FieldColor.blue),
    'energy_field_green': () => EnergyFieldTile('energy_field_green', fieldColor: FieldColor.green),
    'energy_field_red': () => EnergyFieldTile('energy_field_red', fieldColor: FieldColor.red),
    'energy_field_purple': () => EnergyFieldTile('energy_field_purple', fieldColor: FieldColor.purple),

    // =========================================================================
    // SPECIALIZED TILES - VOID & SPACE
    // =========================================================================
    'void_space': () => VoidSpaceTile('void_space'),
    'void_space_dense': () => VoidSpaceTile('void_space_dense', starDensity: 0.06),

    // =========================================================================
    // SPECIALIZED TILES - HOLOGRAM & NEON
    // =========================================================================
    'hologram': () => HologramTile('hologram'),
    'neon_grid': () => NeonGridTile('neon_grid'),
    'neon_grid_fine': () => NeonGridTile('neon_grid_fine', gridSize: 2),

    // =========================================================================
    // SPECIALIZED TILES - MAGIC SPARKLES
    // =========================================================================
    'magic_sparkle_gold': () => MagicSparkleTile('magic_sparkle_gold', sparkleColor: SparkleColor.gold),
    'magic_sparkle_blue': () => MagicSparkleTile('magic_sparkle_blue', sparkleColor: SparkleColor.blue),
    'magic_sparkle_purple': () => MagicSparkleTile('magic_sparkle_purple', sparkleColor: SparkleColor.purple),
    'magic_sparkle_green': () => MagicSparkleTile('magic_sparkle_green', sparkleColor: SparkleColor.green),

    // =========================================================================
    // SPECIALIZED TILES - ELEMENTAL
    // =========================================================================
    'flame': () => FlameTile('flame'),
    'flame_intense': () => FlameTile('flame_intense', flameIntensity: 1.5),
    'ice_crystal': () => IceCrystalTile('ice_crystal'),
    'shadow_wisp': () => ShadowWispTile('shadow_wisp'),

    // =========================================================================
    // PLATFORMER BLOCKS - GRASS TOP COMBINATIONS
    // =========================================================================
    'platformer_grass_dirt': () =>
        PlatformerBlockTile('platformer_grass_dirt', topSurface: TopSurface.grass, baseMaterial: BaseMaterial.dirt),
    'platformer_grass_stone': () =>
        PlatformerBlockTile('platformer_grass_stone', topSurface: TopSurface.grass, baseMaterial: BaseMaterial.stone),
    'platformer_grass_brick': () =>
        PlatformerBlockTile('platformer_grass_brick', topSurface: TopSurface.grass, baseMaterial: BaseMaterial.brick),
    'platformer_grass_clay': () =>
        PlatformerBlockTile('platformer_grass_clay', topSurface: TopSurface.grass, baseMaterial: BaseMaterial.clay),
    'platformer_grass_concrete': () => PlatformerBlockTile(
      'platformer_grass_concrete',
      topSurface: TopSurface.grass,
      baseMaterial: BaseMaterial.concrete,
    ),

    // =========================================================================
    // PLATFORMER BLOCKS - SNOW TOP COMBINATIONS
    // =========================================================================
    'platformer_snow_ice': () =>
        PlatformerBlockTile('platformer_snow_ice', topSurface: TopSurface.snow, baseMaterial: BaseMaterial.ice),
    'platformer_snow_stone': () =>
        PlatformerBlockTile('platformer_snow_stone', topSurface: TopSurface.snow, baseMaterial: BaseMaterial.stone),
    'platformer_snow_dirt': () =>
        PlatformerBlockTile('platformer_snow_dirt', topSurface: TopSurface.snow, baseMaterial: BaseMaterial.dirt),

    // =========================================================================
    // PLATFORMER BLOCKS - MOSS TOP COMBINATIONS
    // =========================================================================
    'platformer_moss_stone': () =>
        PlatformerBlockTile('platformer_moss_stone', topSurface: TopSurface.moss, baseMaterial: BaseMaterial.stone),
    'platformer_moss_brick': () =>
        PlatformerBlockTile('platformer_moss_brick', topSurface: TopSurface.moss, baseMaterial: BaseMaterial.brick),

    // =========================================================================
    // PLATFORMER BLOCKS - SAND TOP COMBINATIONS
    // =========================================================================
    'platformer_sand_sandstone': () => PlatformerBlockTile(
      'platformer_sand_sandstone',
      topSurface: TopSurface.sand,
      baseMaterial: BaseMaterial.sandstone,
    ),
    'platformer_sand_stone': () =>
        PlatformerBlockTile('platformer_sand_stone', topSurface: TopSurface.sand, baseMaterial: BaseMaterial.stone),

    // =========================================================================
    // PLATFORMER BLOCKS - METAL TOP COMBINATIONS
    // =========================================================================
    'platformer_metal_metal': () =>
        PlatformerBlockTile('platformer_metal_metal', topSurface: TopSurface.metal, baseMaterial: BaseMaterial.metal),
    'platformer_metal_concrete': () => PlatformerBlockTile(
      'platformer_metal_concrete',
      topSurface: TopSurface.metal,
      baseMaterial: BaseMaterial.concrete,
    ),

    // =========================================================================
    // PLATFORMER BLOCKS - WOOD TOP COMBINATIONS
    // =========================================================================
    'platformer_wood_wood': () =>
        PlatformerBlockTile('platformer_wood_wood', topSurface: TopSurface.wood, baseMaterial: BaseMaterial.wood),
    'platformer_wood_dirt': () =>
        PlatformerBlockTile('platformer_wood_dirt', topSurface: TopSurface.wood, baseMaterial: BaseMaterial.dirt),
    'platformer_wood_stone': () =>
        PlatformerBlockTile('platformer_wood_stone', topSurface: TopSurface.wood, baseMaterial: BaseMaterial.stone),

    // =========================================================================
    // PLATFORMER BLOCKS - FUNGUS TOP COMBINATIONS
    // =========================================================================
    'platformer_fungus_dirt': () =>
        PlatformerBlockTile('platformer_fungus_dirt', topSurface: TopSurface.fungus, baseMaterial: BaseMaterial.dirt),
    'platformer_fungus_stone': () =>
        PlatformerBlockTile('platformer_fungus_stone', topSurface: TopSurface.fungus, baseMaterial: BaseMaterial.stone),

    // =========================================================================
    // PLATFORMER BLOCKS - CRYSTAL TOP COMBINATIONS
    // =========================================================================
    'platformer_crystal_stone': () => PlatformerBlockTile(
      'platformer_crystal_stone',
      topSurface: TopSurface.crystal,
      baseMaterial: BaseMaterial.stone,
    ),
    'platformer_crystal_dark_brick': () => PlatformerBlockTile(
      'platformer_crystal_dark_brick',
      topSurface: TopSurface.crystal,
      baseMaterial: BaseMaterial.darkBrick,
    ),

    // =========================================================================
    // PLATFORMER BLOCKS - ICE TOP COMBINATIONS
    // =========================================================================
    'platformer_ice_ice': () =>
        PlatformerBlockTile('platformer_ice_ice', topSurface: TopSurface.ice, baseMaterial: BaseMaterial.ice),
    'platformer_ice_stone': () =>
        PlatformerBlockTile('platformer_ice_stone', topSurface: TopSurface.ice, baseMaterial: BaseMaterial.stone),

    // =========================================================================
    // PLATFORMER BLOCKS - AUTUMN TOP COMBINATIONS
    // =========================================================================
    'platformer_autumn_dirt': () =>
        PlatformerBlockTile('platformer_autumn_dirt', topSurface: TopSurface.autumn, baseMaterial: BaseMaterial.dirt),
    'platformer_autumn_stone': () =>
        PlatformerBlockTile('platformer_autumn_stone', topSurface: TopSurface.autumn, baseMaterial: BaseMaterial.stone),

    // =========================================================================
    // PLATFORMER BLOCKS - CUSTOM CONFIGURABLE
    // =========================================================================
    'platformer_grass_wood': () =>
        PlatformerBlockTile('platformer_grass_wood', topSurface: TopSurface.grass, baseMaterial: BaseMaterial.wood),
    'platformer_moss_dark_brick': () => PlatformerBlockTile(
      'platformer_moss_dark_brick',
      topSurface: TopSurface.moss,
      baseMaterial: BaseMaterial.darkBrick,
    ),
    'platformer_sand_clay': () =>
        PlatformerBlockTile('platformer_sand_clay', topSurface: TopSurface.sand, baseMaterial: BaseMaterial.clay),
    'platformer_snow_concrete': () => PlatformerBlockTile(
      'platformer_snow_concrete',
      topSurface: TopSurface.snow,
      baseMaterial: BaseMaterial.concrete,
    ),
    'platformer_autumn_brick': () =>
        PlatformerBlockTile('platformer_autumn_brick', topSurface: TopSurface.autumn, baseMaterial: BaseMaterial.brick),
    'platformer_fungus_dark_brick': () => PlatformerBlockTile(
      'platformer_fungus_dark_brick',
      topSurface: TopSurface.fungus,
      baseMaterial: BaseMaterial.darkBrick,
    ),
    'platformer_crystal_ice': () =>
        PlatformerBlockTile('platformer_crystal_ice', topSurface: TopSurface.crystal, baseMaterial: BaseMaterial.ice),
    'platformer_ice_dark_brick': () => PlatformerBlockTile(
      'platformer_ice_dark_brick',
      topSurface: TopSurface.ice,
      baseMaterial: BaseMaterial.darkBrick,
    ),

    // =========================================================================
    // PLATFORMER BLOCKS - NO-TOP FILL VERSIONS
    // =========================================================================
    'platformer_fill_dirt': () => PlatformerBlockFillTile('platformer_fill_dirt', baseMaterial: BaseMaterial.dirt),
    'platformer_fill_stone': () => PlatformerBlockFillTile('platformer_fill_stone', baseMaterial: BaseMaterial.stone),
    'platformer_fill_brick': () => PlatformerBlockFillTile('platformer_fill_brick', baseMaterial: BaseMaterial.brick),
    'platformer_fill_wood': () => PlatformerBlockFillTile('platformer_fill_wood', baseMaterial: BaseMaterial.wood),
    'platformer_fill_concrete': () =>
        PlatformerBlockFillTile('platformer_fill_concrete', baseMaterial: BaseMaterial.concrete),
    'platformer_fill_sandstone': () =>
        PlatformerBlockFillTile('platformer_fill_sandstone', baseMaterial: BaseMaterial.sandstone),
    'platformer_fill_ice': () => PlatformerBlockFillTile('platformer_fill_ice', baseMaterial: BaseMaterial.ice),
    'platformer_fill_metal': () => PlatformerBlockFillTile('platformer_fill_metal', baseMaterial: BaseMaterial.metal),
    'platformer_fill_dark_brick': () =>
        PlatformerBlockFillTile('platformer_fill_dark_brick', baseMaterial: BaseMaterial.darkBrick),
    'platformer_fill_clay': () => PlatformerBlockFillTile('platformer_fill_clay', baseMaterial: BaseMaterial.clay),

    // =========================================================================
    // PLATFORMER TILES - NO-TOP FILL VERSIONS
    // =========================================================================
    'dirt_fill': () => DirtFillTile('dirt_fill'),
    'ice_fill': () => IceFillTile('ice_fill'),
    'sand_fill': () => SandFillTile('sand_fill'),
    'water_fill': () => WaterFillTile('water_fill'),
    'deep_water_fill': () => DeepWaterFillTile('deep_water_fill'),
    'lava_fill': () => LavaFillTile('lava_fill'),
    'lava_cracks_fill': () => LavaCracksFillTile('lava_cracks_fill'),
    'poison_slime_fill': () => PoisonSlimeFillTile('poison_slime_fill'),
    'stone_path_fill': () => StonePathFillTile('stone_path_fill'),
    'rocky_ground_fill': () => RockyGroundFillTile('rocky_ground_fill'),
    'metal_panel_fill': () => MetalPanelFillTile('metal_panel_fill'),
    'wood_fill': () => WoodFillTile('wood_fill'),
    'brick_fill': () => BrickFillTile('brick_fill'),

    // =========================================================================
    // ENVIRONMENT TILES - CAVE/UNDERGROUND
    // =========================================================================
    'cave_floor': () => CaveFloorTile('cave_floor'),
    'cave_floor_wet': () => CaveFloorTile('cave_floor_wet', hasPuddles: true),
    'stalactite': () => StalactiteTile('stalactite'),
    'stalagmite': () => StalactiteTile('stalagmite', pointingDown: false),
    'glowing_fungus': () => GlowingFungusTile('glowing_fungus'),
    'glowing_fungus_dense': () => GlowingFungusTile('glowing_fungus_dense', density: 0.6),
    'underground_lake': () => UndergroundLakeTile('underground_lake'),

    // =========================================================================
    // ENVIRONMENT TILES - SWAMP/MARSH
    // =========================================================================
    'swamp_mud': () => SwampMudTile('swamp_mud'),
    'swamp_mud_wet': () => SwampMudTile('swamp_mud_wet', hasRipples: true),
    'swamp_water': () => SwampWaterTile('swamp_water'),
    'lily_pads': () => LilyPadTile('lily_pads'),
    'lily_pads_flowering': () => LilyPadTile('lily_pads_flowering', hasFlowers: true),
    'bog': () => BogTile('bog'),

    // =========================================================================
    // ENVIRONMENT TILES - INTERIOR
    // =========================================================================
    'carpet_red': () => CarpetTile('carpet_red', color: CarpetColor.red),
    'carpet_blue': () => CarpetTile('carpet_blue', color: CarpetColor.blue),
    'carpet_green': () => CarpetTile('carpet_green', color: CarpetColor.green),
    'carpet_purple': () => CarpetTile('carpet_purple', color: CarpetColor.purple),
    'wallpaper_striped': () => WallpaperTile('wallpaper_striped', pattern: WallpaperPattern.striped),
    'wallpaper_damask': () => WallpaperTile('wallpaper_damask', pattern: WallpaperPattern.damask),
    'wallpaper_floral': () => WallpaperTile('wallpaper_floral', pattern: WallpaperPattern.floral),
    'mosaic': () => MosaicTile('mosaic'),

    // =========================================================================
    // ENVIRONMENT TILES - FARM/RURAL
    // =========================================================================
    'tilled_soil': () => TilledSoilTile('tilled_soil'),
    'tilled_soil_seeded': () => TilledSoilTile('tilled_soil_seeded', hasSeeds: true),
    'hay_loose': () => HayTile('hay_loose'),
    'hay_bale': () => HayTile('hay_bale', isBaled: true),
    'wheat_field_mature': () => WheatFieldTile('wheat_field_mature', mature: true),
    'wheat_field_young': () => WheatFieldTile('wheat_field_young', mature: false),

    // =========================================================================
    // ENVIRONMENT TILES - TRANSITIONS/EDGES
    // =========================================================================
    'shoreline': () => ShorelineTile('shoreline'),
    'path_edge': () => PathEdgeTile('path_edge'),
    'snow_edge': () => SnowEdgeTile('snow_edge'),

    // =========================================================================
    // SCI-FI TILES - FLOORS
    // =========================================================================
    'metal_floor': () => MetalFloorTile('metal_floor'),
    'metal_floor_dark': () => MetalFloorTile('metal_floor_dark', metalPalette: SciFiPalettes.darkMetal),
    'metal_floor_steel': () => MetalFloorTile('metal_floor_steel', metalPalette: SciFiPalettes.brushedSteel),
    'metal_floor_rusty': () =>
        MetalFloorTile('metal_floor_rusty', metalPalette: SciFiPalettes.rustyMetal, addScratches: true),
    'metal_floor_riveted': () => MetalFloorTile('metal_floor_riveted', metalPalette: SciFiPalettes.metalHull),
    'metal_floor_clean': () => MetalFloorTile('metal_floor_clean', metalPalette: SciFiPalettes.brushedSteel, addRivets: false),
    'scifi_diamond_plate': () => SciFiDiamondPlateTile('scifi_diamond_plate'),
    'scifi_diamond_plate_dark': () =>
        SciFiDiamondPlateTile('scifi_diamond_plate_dark', metalPalette: SciFiPalettes.darkMetal),
    'scifi_diamond_plate_steel': () =>
        SciFiDiamondPlateTile('scifi_diamond_plate_steel', metalPalette: SciFiPalettes.brushedSteel),
    'scifi_grating': () => SciFiGratingTile('scifi_grating'),
    'scifi_grating_fine': () => SciFiGratingTile('scifi_grating_fine', gridSize: 2),
    'tech_floor': () => TechFloorTile('tech_floor'),
    'tech_floor_pink': () => TechFloorTile('tech_floor_pink', glowPalette: SciFiPalettes.neonPink),
    'tech_floor_green': () => TechFloorTile('tech_floor_green', glowPalette: SciFiPalettes.neonGreen),
    'tech_floor_orange': () => TechFloorTile('tech_floor_orange', glowPalette: SciFiPalettes.neonOrange),
    'tech_floor_dense': () => TechFloorTile('tech_floor_dense', gridSpacing: 5),

    // =========================================================================
    // SCI-FI TILES - WALL PANELS
    // =========================================================================
    'tech_wall': () => TechWallTile('tech_wall'),
    'tech_wall_cyan': () => TechWallTile('tech_wall_cyan', accentPalette: SciFiPalettes.neonCyan),
    'tech_wall_pink': () => TechWallTile('tech_wall_pink', accentPalette: SciFiPalettes.neonPink),
    'tech_wall_green': () => TechWallTile('tech_wall_green', accentPalette: SciFiPalettes.neonGreen),
    'tech_wall_orange': () => TechWallTile('tech_wall_orange', accentPalette: SciFiPalettes.neonOrange),
    'tech_wall_dark': () => TechWallTile('tech_wall_dark', metalPalette: SciFiPalettes.darkMetal, accentPalette: SciFiPalettes.neonCyan),
    'tech_wall_vents': () => TechWallTile('tech_wall_vents', addVents: true, addLights: false),
    'tech_wall_vents_lit': () => TechWallTile('tech_wall_vents_lit', addVents: true, addLights: true),
    'hex_panel': () => HexPanelTile('hex_panel'),
    'hex_panel_steel': () => HexPanelTile('hex_panel_steel', metalPalette: SciFiPalettes.brushedSteel),
    'hex_panel_dark': () => HexPanelTile('hex_panel_dark', metalPalette: SciFiPalettes.darkMetal),

    // =========================================================================
    // SCI-FI TILES - CIRCUITS & TECH
    // =========================================================================
    'circuit_board': () => CircuitBoardTile('circuit_board'),
    'circuit_board_simple': () => CircuitBoardTile('circuit_board_simple', addComponents: false),
    'data_stream': () => DataStreamTile('data_stream'),
    'data_stream_cyan': () => DataStreamTile('data_stream_cyan', streamPalette: SciFiPalettes.neonCyan),
    'data_stream_pink': () => DataStreamTile('data_stream_pink', streamPalette: SciFiPalettes.neonPink),
    'data_stream_orange': () => DataStreamTile('data_stream_orange', streamPalette: SciFiPalettes.neonOrange),

    // =========================================================================
    // SCI-FI TILES - ENERGY & FORCE FIELDS
    // =========================================================================
    'force_field_blue': () => ForceFieldTile('force_field_blue'),
    'force_field_green': () => ForceFieldTile('force_field_green', energyPalette: SciFiPalettes.neonGreen),
    'force_field_pink': () => ForceFieldTile('force_field_pink', energyPalette: SciFiPalettes.neonPink),
    'force_field_orange': () => ForceFieldTile('force_field_orange', energyPalette: SciFiPalettes.neonOrange),
    'plasma_conduit': () => PlasmaConduitTile('plasma_conduit'),
    'plasma_conduit_cyan': () => PlasmaConduitTile('plasma_conduit_cyan', plasmaPalette: SciFiPalettes.neonCyan),
    'plasma_conduit_green': () => PlasmaConduitTile('plasma_conduit_green', plasmaPalette: SciFiPalettes.neonGreen),
    'plasma_conduit_orange': () => PlasmaConduitTile('plasma_conduit_orange', plasmaPalette: SciFiPalettes.neonOrange),
    'reactor_core': () => ReactorCoreTile('reactor_core'),
    'reactor_core_pink': () => ReactorCoreTile('reactor_core_pink', reactorPalette: SciFiPalettes.neonPink),
    'reactor_core_green': () => ReactorCoreTile('reactor_core_green', reactorPalette: SciFiPalettes.neonGreen),
    'reactor_core_orange': () => ReactorCoreTile('reactor_core_orange', reactorPalette: SciFiPalettes.neonOrange),

    // =========================================================================
    // SCI-FI TILES - HAZARD & WARNING
    // =========================================================================
    'hazard_stripes': () => HazardStripesTile('hazard_stripes'),
    'biohazard': () => BiohazardTile('biohazard'),

    // =========================================================================
    // SCI-FI TILES - SPACE & DISPLAYS
    // =========================================================================
    'space_window': () => SpaceWindowTile('space_window'),
    'space_window_empty': () => SpaceWindowTile('space_window_empty', addStars: false),
    'scifi_hologram': () => SciFiHologramTile('scifi_hologram'),
    'security_scanner': () => SecurityScannerTile('security_scanner'),
    'security_scanner_cyan': () => SecurityScannerTile('security_scanner_cyan', scanPalette: SciFiPalettes.neonCyan),
    'security_scanner_red': () => SecurityScannerTile('security_scanner_red', scanPalette: SciFiPalettes.neonPink),

    // =========================================================================
    // SCI-FI TILES - MECHANICAL
    // =========================================================================
    'gear': () => GearTile('gear'),
    'gear_copper': () => GearTile('gear_copper', metalPalette: SciFiPalettes.copper),
    'gear_dark': () => GearTile('gear_dark', metalPalette: SciFiPalettes.darkMetal),
    'vent_horizontal': () => VentTile('vent_horizontal'),
    'vent_vertical': () => VentTile('vent_vertical'),
    'pipe_vertical': () => PipeTile('pipe_vertical'),
    'pipe_horizontal': () => PipeTile('pipe_horizontal'),
    'pipe_rusty': () => PipeTile('pipe_rusty', addRust: true),
    'pipe_copper': () => PipeTile('pipe_copper', pipePalette: SciFiPalettes.copper),

    // =========================================================================
    // SCI-FI TILES - LIGHTS & NEON
    // =========================================================================
    'neon_strip_cyan': () => NeonStripTile('neon_strip_cyan'),
    'neon_strip_pink': () => NeonStripTile('neon_strip_pink', neonPalette: SciFiPalettes.neonPink),
    'neon_strip_green': () => NeonStripTile('neon_strip_green', neonPalette: SciFiPalettes.neonGreen),
    'neon_strip_orange': () => NeonStripTile('neon_strip_orange', neonPalette: SciFiPalettes.neonOrange),
    'led_panel_green': () => LedPanelTile('led_panel_green'),
    'led_panel_cyan': () => LedPanelTile('led_panel_cyan', ledPalette: SciFiPalettes.neonCyan),
    'led_panel_pink': () => LedPanelTile('led_panel_pink', ledPalette: SciFiPalettes.neonPink),
    'led_panel_orange': () => LedPanelTile('led_panel_orange', ledPalette: SciFiPalettes.neonOrange),
    'led_panel_fine': () => LedPanelTile('led_panel_fine', gridSize: 1),

    // =========================================================================
    // ADVANCED NATURE TILES
    // =========================================================================
    'cactus': () => CactusTile('cactus'),
    'cactus_dense': () => CactusTile('cactus_dense', density: 0.8),
    'bamboo': () => BambooTile('bamboo'),
    'mushroom_giant': () => GiantMushroomTile('mushroom_giant'),
    'coral_reef': () => CoralTile('coral_reef'),
    'vines_flowering': () => FloweringVineTile('vines_flowering'),

    // =========================================================================
    // PHASE 4 - ENVIRONMENTAL TERRAIN TILES
    // =========================================================================
    'volcanic_ash': () => VolcanicAshTile('volcanic_ash'),
    'quicksand': () => QuicksandTile('quicksand'),
    'tundra': () => TundraTile('tundra'),
    'mud_flat': () => MudFlatTile('mud_flat'),
    'salt_flat': () => SaltFlatTile('salt_flat'),
    'meteor_crater': () => MeteorCraterTile('meteor_crater'),
    'fossil_bed': () => FossilBedTile('fossil_bed'),

    // =========================================================================
    // PHASE 4 - MECHANICAL / INDUSTRIAL TILES
    // =========================================================================
    'steam_pipe': () => SteamPipeTile('steam_pipe'),
    'boiler_plate': () => BoilerPlateTile('boiler_plate'),
    'conveyor_belt_active': () => ConveyorBeltActiveTile('conveyor_belt_active'),
    'hydraulic_piston': () => HydraulicPistonTile('hydraulic_piston'),
    'catwalk_floor': () => CatwalkFloorTile('catwalk_floor'),
    'fuel_drum': () => FuelDrumTile('fuel_drum'),

    // =========================================================================
    // PHASE 4 - NATURE TILES
    // =========================================================================
    'bamboo_ground': () => BambooGroundTile('bamboo_ground'),
    'moss_mat': () => MossMatTile('moss_mat'),
    'leaf_litter': () => LeafLitterTile('leaf_litter'),
    'root_network': () => RootNetworkTile('root_network'),
    'thorny_brush': () => ThornyBrushTile('thorny_brush'),
    'seagrass': () => SeagrassTile('seagrass'),
  };

  /// Get all registered tile IDs
  List<String> get allIds => _registry.keys.toList();

  /// Get a tile instance by ID
  TileBase? getTile(String id) {
    final factory = _registry[id];
    return factory?.call();
  }

  /// Get all tiles in a category
  List<TileBase> getTilesInCategory(TileCategory category) {
    return _registry.values.map((f) => f()).where((t) => t.category == category).toList();
  }

  /// Get all categories with tiles
  Map<TileCategory, List<TileBase>> get tilesByCategory {
    final result = <TileCategory, List<TileBase>>{};
    for (final category in TileCategory.values) {
      final tiles = getTilesInCategory(category);
      if (tiles.isNotEmpty) {
        result[category] = tiles;
      }
    }
    return result;
  }

  /// Search tiles by tag
  List<TileBase> searchByTag(String tag) {
    return _registry.values.map((f) => f()).where((t) => t.tags.contains(tag.toLowerCase())).toList();
  }

  /// Get all stone/dungeon tiles
  List<TileBase> get stoneTiles {
    return searchByTag('stone') + searchByTag('dungeon');
  }

  /// Get all structure tiles including new stone types
  List<TileBase> get allStructureTiles {
    return getTilesInCategory(TileCategory.structure) + getTilesInCategory(TileCategory.dungeon);
  }

  /// Register a custom tile type
  void register(String id, TileBase Function() factory) {
    _registry[id] = factory;
  }

  /// Unregister a tile type
  void unregister(String id) {
    _registry.remove(id);
  }

  /// Check if a tile ID exists
  bool hasTile(String id) {
    return _registry.containsKey(id);
  }

  /// Get count of registered tiles
  int get count => _registry.length;

  /// Get all tile IDs matching a pattern
  List<String> searchIds(String pattern) {
    final lowerPattern = pattern.toLowerCase();
    return _registry.keys.where((id) => id.toLowerCase().contains(lowerPattern)).toList();
  }
}
