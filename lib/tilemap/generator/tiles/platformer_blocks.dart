import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// PLATFORMER BLOCK PALETTES (Top Surface + Base Material Combinations)
// ============================================================================

class PlatformerBlockPalettes {
  PlatformerBlockPalettes._();

  // ===== TOP SURFACE PALETTES =====

  /// Grass top surface
  static const grassTop = TilePalette(
    name: 'Grass Top',
    colors: [
      Color(0xFF5A9A3A), // Base grass green
      Color(0xFF7ABA5A), // Light grass
      Color(0xFF4A7A2A), // Dark grass
      Color(0xFF8ADA6A), // Highlight blade
      Color(0xFF3A5A1A), // Shadow
    ],
  );

  /// Snow top surface
  static const snowTop = TilePalette(
    name: 'Snow Top',
    colors: [
      Color(0xFFEEF4FF), // Base white
      Color(0xFFFFFFFF), // Bright white
      Color(0xFFD8E4F0), // Blue tint
      Color(0xFFFFFFFF), // Highlight
      Color(0xFFB8C8D8), // Shadow
    ],
  );

  /// Moss top surface
  static const mossTop = TilePalette(
    name: 'Moss Top',
    colors: [
      Color(0xFF6A8A4A), // Dark moss
      Color(0xFF8AAA6A), // Light moss
      Color(0xFF5A7A3A), // Deep moss
      Color(0xFFAACA8A), // Highlight
      Color(0xFF4A5A2A), // Shadow
    ],
  );

  /// Sand top surface
  static const sandTop = TilePalette(
    name: 'Sand Top',
    colors: [
      Color(0xFFE8D4A8), // Base sand
      Color(0xFFF4E4C0), // Light sand
      Color(0xFFD4C090), // Dark sand
      Color(0xFFFFF0D8), // Highlight
      Color(0xFFB4A070), // Shadow
    ],
  );

  /// Metal plate top
  static const metalTop = TilePalette(
    name: 'Metal Top',
    colors: [
      Color(0xFF7A8A9A), // Base metal
      Color(0xFF9AAABC), // Light metal
      Color(0xFF5A6A7A), // Dark metal
      Color(0xFFBACADA), // Highlight
      Color(0xFF3A4A5A), // Shadow
    ],
  );

  /// Wood plank top
  static const woodTop = TilePalette(
    name: 'Wood Top',
    colors: [
      Color(0xFFC09060), // Base wood
      Color(0xFFD4A878), // Light wood
      Color(0xFFA07848), // Dark wood
      Color(0xFFE8C090), // Highlight
      Color(0xFF705030), // Shadow
    ],
  );

  /// Fungus/mushroom top
  static const fungusTop = TilePalette(
    name: 'Fungus Top',
    colors: [
      Color(0xFF9A6A8A), // Purple-ish base
      Color(0xFFBA8AAA), // Light
      Color(0xFF7A4A6A), // Dark
      Color(0xFFDAAACA), // Highlight spots
      Color(0xFF5A2A4A), // Shadow
    ],
  );

  /// Crystal/gem top
  static const crystalTop = TilePalette(
    name: 'Crystal Top',
    colors: [
      Color(0xFF7A9ADA), // Blue crystal
      Color(0xFF9ABAEF), // Light crystal
      Color(0xFF5A7ABA), // Dark crystal
      Color(0xFFCADAFF), // Highlight
      Color(0xFF3A5A8A), // Shadow
    ],
  );

  /// Ice/frost top
  static const iceTop = TilePalette(
    name: 'Ice Top',
    colors: [
      Color(0xFFB0D8F0), // Base ice
      Color(0xFFD0F0FF), // Light ice
      Color(0xFF80B8D8), // Dark ice
      Color(0xFFFFFFFF), // Highlight
      Color(0xFF60A0C0), // Shadow
    ],
  );

  /// Autumn leaves top
  static const autumnTop = TilePalette(
    name: 'Autumn Top',
    colors: [
      Color(0xFFD87040), // Orange base
      Color(0xFFE89060), // Light orange
      Color(0xFFB85030), // Dark red
      Color(0xFFF0A878), // Highlight
      Color(0xFF884020), // Shadow
    ],
  );

  // ===== BASE MATERIAL PALETTES =====

  /// Dirt base
  static const dirtBase = TilePalette(
    name: 'Dirt Base',
    colors: [
      Color(0xFF8A6A4A), // Base brown
      Color(0xFFA08060), // Light dirt
      Color(0xFF6A5038), // Dark dirt
      Color(0xFFB89878), // Highlight
      Color(0xFF4A3020), // Shadow
    ],
  );

  /// Stone base
  static const stoneBase = TilePalette(
    name: 'Stone Base',
    colors: [
      Color(0xFF6A6A6A), // Base gray
      Color(0xFF8A8A8A), // Light stone
      Color(0xFF4A4A4A), // Dark stone
      Color(0xFFAAAAAA), // Highlight
      Color(0xFF2A2A2A), // Shadow
    ],
  );

  /// Brick base
  static const brickBase = TilePalette(
    name: 'Brick Base',
    colors: [
      Color(0xFF9A5A3A), // Base brick red
      Color(0xFFBA7A5A), // Light brick
      Color(0xFF7A4A2A), // Dark brick
      Color(0xFFDA9A7A), // Highlight
      Color(0xFF3A2A1A), // Mortar
    ],
  );

  /// Wood base
  static const woodBase = TilePalette(
    name: 'Wood Base',
    colors: [
      Color(0xFF8A6A40), // Base wood
      Color(0xFFAA8A60), // Light wood
      Color(0xFF6A4A28), // Dark wood
      Color(0xFFCAA880), // Highlight
      Color(0xFF4A3018), // Shadow
    ],
  );

  /// Concrete/cement base
  static const concreteBase = TilePalette(
    name: 'Concrete Base',
    colors: [
      Color(0xFF8A8A8A), // Base concrete
      Color(0xFFA0A0A0), // Light concrete
      Color(0xFF6A6A6A), // Dark concrete
      Color(0xFFB8B8B8), // Highlight
      Color(0xFF505050), // Shadow
    ],
  );

  /// Sandstone base
  static const sandstoneBase = TilePalette(
    name: 'Sandstone Base',
    colors: [
      Color(0xFFD4B88A), // Base sandstone
      Color(0xFFE8D0A8), // Light sandstone
      Color(0xFFB8986A), // Dark sandstone
      Color(0xFFF8E8C8), // Highlight
      Color(0xFF8A7050), // Shadow
    ],
  );

  /// Ice/frozen base
  static const iceBase = TilePalette(
    name: 'Ice Base',
    colors: [
      Color(0xFF90C0D8), // Base ice blue
      Color(0xFFB0D8E8), // Light ice
      Color(0xFF70A0B8), // Dark ice
      Color(0xFFD0F0FF), // Highlight
      Color(0xFF5080A0), // Shadow
    ],
  );

  /// Metal base
  static const metalBase = TilePalette(
    name: 'Metal Base',
    colors: [
      Color(0xFF5A6878), // Base metal
      Color(0xFF7A8898), // Light metal
      Color(0xFF3A4858), // Dark metal
      Color(0xFF9AA8B8), // Highlight
      Color(0xFF2A3848), // Shadow
    ],
  );

  /// Dark brick base
  static const darkBrickBase = TilePalette(
    name: 'Dark Brick Base',
    colors: [
      Color(0xFF4A3A3A), // Base dark brick
      Color(0xFF5A4A4A), // Light brick
      Color(0xFF3A2A2A), // Dark brick
      Color(0xFF6A5A5A), // Highlight
      Color(0xFF2A1A1A), // Mortar
    ],
  );

  /// Clay base
  static const clayBase = TilePalette(
    name: 'Clay Base',
    colors: [
      Color(0xFFB87860), // Base clay
      Color(0xFFD09880), // Light clay
      Color(0xFF985848), // Dark clay
      Color(0xFFE8B8A0), // Highlight
      Color(0xFF684038), // Shadow
    ],
  );
}

// ============================================================================
// ENUMS FOR TOP AND BASE MATERIALS
// ============================================================================

/// Top surface material types
enum TopSurface {
  grass(PlatformerBlockPalettes.grassTop, 'Grass'),
  snow(PlatformerBlockPalettes.snowTop, 'Snow'),
  moss(PlatformerBlockPalettes.mossTop, 'Moss'),
  sand(PlatformerBlockPalettes.sandTop, 'Sand'),
  metal(PlatformerBlockPalettes.metalTop, 'Metal'),
  wood(PlatformerBlockPalettes.woodTop, 'Wood'),
  fungus(PlatformerBlockPalettes.fungusTop, 'Fungus'),
  crystal(PlatformerBlockPalettes.crystalTop, 'Crystal'),
  ice(PlatformerBlockPalettes.iceTop, 'Ice'),
  autumn(PlatformerBlockPalettes.autumnTop, 'Autumn');

  final TilePalette palette;
  final String displayName;
  const TopSurface(this.palette, this.displayName);
}

/// Base material types
enum BaseMaterial {
  dirt(PlatformerBlockPalettes.dirtBase, 'Dirt'),
  stone(PlatformerBlockPalettes.stoneBase, 'Stone'),
  brick(PlatformerBlockPalettes.brickBase, 'Brick'),
  wood(PlatformerBlockPalettes.woodBase, 'Wood'),
  concrete(PlatformerBlockPalettes.concreteBase, 'Concrete'),
  sandstone(PlatformerBlockPalettes.sandstoneBase, 'Sandstone'),
  ice(PlatformerBlockPalettes.iceBase, 'Ice'),
  metal(PlatformerBlockPalettes.metalBase, 'Metal'),
  darkBrick(PlatformerBlockPalettes.darkBrickBase, 'Dark Brick'),
  clay(PlatformerBlockPalettes.clayBase, 'Clay');

  final TilePalette palette;
  final String displayName;
  const BaseMaterial(this.palette, this.displayName);
}

// ============================================================================
// PLATFORMER BLOCK TILE (Configurable Top + Base)
// ============================================================================

/// A highly configurable platformer block with customizable top surface and base material
class PlatformerBlockTile extends TileBase {
  final TopSurface topSurface;
  final BaseMaterial baseMaterial;
  final double topRatio;
  final bool hasTransitionLayer;

  PlatformerBlockTile(
    super.id, {
    this.topSurface = TopSurface.grass,
    this.baseMaterial = BaseMaterial.dirt,
    this.topRatio = 0.2,
    this.hasTransitionLayer = true,
  });

  @override
  String get name => '${topSurface.displayName} on ${baseMaterial.displayName}';

  @override
  String get description =>
      '${topSurface.displayName} surface (${(topRatio * 100).round()}%) over ${baseMaterial.displayName} base';

  @override
  String get iconName => 'layers';

  @override
  TileCategory get category => TileCategory.platformer;

  @override
  TilePalette get palette => topSurface.palette;

  @override
  List<String> get tags => [
        'platformer',
        'block',
        topSurface.displayName.toLowerCase(),
        baseMaterial.displayName.toLowerCase(),
        'layered',
      ];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final topHeight = (height * topRatio).round();
    final transitionHeight = hasTransitionLayer ? max(1, (height * 0.05).round()) : 0;
    final topPal = topSurface.palette;
    final basePal = baseMaterial.palette;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (y < topHeight) {
          // Top surface layer
          pixels[y * width + x] = _generateTopPixel(x, y, width, topHeight, topPal, random, seed);
        } else if (y < topHeight + transitionHeight) {
          // Transition layer
          pixels[y * width + x] = _generateTransitionPixel(
            x,
            y,
            width,
            topHeight,
            transitionHeight,
            topPal,
            basePal,
            random,
            seed,
          );
        } else {
          // Base material layer
          pixels[y * width + x] = _generateBasePixel(x, y, width, height, basePal, random, seed);
        }
      }
    }

    // Add edge variations for organic look
    _addEdgeVariations(pixels, width, height, topHeight, topPal, basePal, random);

    return pixels;
  }

  int _generateTopPixel(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    switch (topSurface) {
      case TopSurface.grass:
        return _generateGrassTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.snow:
        return _generateSnowTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.moss:
        return _generateMossTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.sand:
        return _generateSandTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.metal:
        return _generateMetalTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.wood:
        return _generateWoodTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.fungus:
        return _generateFungusTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.crystal:
        return _generateCrystalTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.ice:
        return _generateIceTop(x, y, width, topHeight, pal, random, seed);
      case TopSurface.autumn:
        return _generateAutumnTop(x, y, width, topHeight, pal, random, seed);
    }
  }

  int _generateBasePixel(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    switch (baseMaterial) {
      case BaseMaterial.dirt:
        return _generateDirtBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.stone:
        return _generateStoneBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.brick:
        return _generateBrickBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.wood:
        return _generateWoodBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.concrete:
        return _generateConcreteBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.sandstone:
        return _generateSandstoneBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.ice:
        return _generateIceBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.metal:
        return _generateMetalBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.darkBrick:
        return _generateDarkBrickBase(x, y, width, height, pal, random, seed);
      case BaseMaterial.clay:
        return _generateClayBase(x, y, width, height, pal, random, seed);
    }
  }

  int _generateTransitionPixel(
    int x,
    int y,
    int width,
    int topHeight,
    int transitionHeight,
    TilePalette topPal,
    TilePalette basePal,
    Random random,
    int seed,
  ) {
    // Blend between top and base colors with some noise
    final t = (y - topHeight) / transitionHeight;
    final topColor = topPal.shadow;
    final baseColor = basePal.primary;
    final blended = Color.lerp(topColor, baseColor, t)!;
    return addNoise(blended, random, 0.08);
  }

  // ===== TOP SURFACE GENERATORS =====

  int _generateGrassTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
    Color grassColor;

    if (y == 0) {
      // Very top - blade tips
      grassColor = random.nextDouble() < 0.5 ? pal.secondary : pal.highlight;
    } else if (y < topHeight / 3) {
      // Upper grass
      grassColor = noiseVal > 0.6 ? pal.secondary : pal.primary;
    } else {
      // Lower grass (darker)
      grassColor = noiseVal > 0.5 ? pal.primary : pal.colors[2];
    }

    return addNoise(grassColor, random, 0.06);
  }

  int _generateSnowTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
    Color snowColor;

    if (noiseVal > 0.7) {
      snowColor = pal.highlight; // Bright white
    } else if (noiseVal > 0.4) {
      snowColor = pal.primary; // Base white
    } else {
      snowColor = pal.secondary; // Blue tint
    }

    // Sparkle effect
    if (random.nextDouble() > 0.95) {
      snowColor = pal.highlight;
    }

    return addNoise(snowColor, random, 0.02);
  }

  int _generateMossTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 2.5 + seed, y / 2.5, 3);
    Color mossColor;

    if (noiseVal > 0.6) {
      mossColor = pal.secondary; // Light moss
    } else if (noiseVal > 0.3) {
      mossColor = pal.primary; // Base moss
    } else {
      mossColor = pal.colors[2]; // Dark moss
    }

    // Occasional bright spots
    if (random.nextDouble() > 0.92) {
      mossColor = pal.highlight;
    }

    return addNoise(mossColor, random, 0.05);
  }

  int _generateSandTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
    Color sandColor;

    if (y == 0 || y == 1) {
      // Top edge highlight
      sandColor = noiseVal > 0.5 ? pal.highlight : pal.secondary;
    } else {
      sandColor = noiseVal > 0.6
          ? pal.secondary
          : noiseVal > 0.3
              ? pal.primary
              : pal.colors[2];
    }

    // Small pebbles
    if (random.nextDouble() > 0.97) {
      sandColor = pal.shadow;
    }

    return addNoise(sandColor, random, 0.04);
  }

  int _generateMetalTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    // Panel pattern
    final panelSize = 4;
    final onEdge = x % panelSize == 0 || y % panelSize == 0;

    Color metalColor;
    if (onEdge) {
      metalColor = pal.shadow;
    } else if (y < 2) {
      metalColor = pal.highlight; // Top edge highlight
    } else {
      final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
      metalColor = noiseVal > 0.5 ? pal.primary : pal.secondary;
    }

    return addNoise(metalColor, random, 0.03);
  }

  int _generateWoodTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    // Wood grain pattern (horizontal planks)
    final plankWidth = 5;
    final onGap = x % plankWidth == 0;

    Color woodColor;
    if (onGap) {
      woodColor = pal.shadow;
    } else {
      final grainNoise = noise2D(x / 8.0 + seed, y / 1.5 + seed, 2);
      if (y < 2) {
        woodColor = pal.highlight;
      } else if (grainNoise > 0.6) {
        woodColor = pal.secondary;
      } else if (grainNoise > 0.3) {
        woodColor = pal.primary;
      } else {
        woodColor = pal.colors[2];
      }
    }

    return addNoise(woodColor, random, 0.05);
  }

  int _generateFungusTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
    Color fungusColor;

    if (noiseVal > 0.65) {
      fungusColor = pal.highlight; // Bright spots
    } else if (noiseVal > 0.4) {
      fungusColor = pal.secondary;
    } else if (noiseVal > 0.2) {
      fungusColor = pal.primary;
    } else {
      fungusColor = pal.colors[2];
    }

    return addNoise(fungusColor, random, 0.06);
  }

  int _generateCrystalTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    // Faceted crystal pattern
    final facetSize = 3;
    final facetX = x ~/ facetSize;
    final facetY = y ~/ facetSize;
    final withinFacetX = x % facetSize;
    final withinFacetY = y % facetSize;

    Color crystalColor;
    if (withinFacetX == 0 || withinFacetY == 0) {
      crystalColor = pal.shadow;
    } else if (withinFacetX == 1 && withinFacetY == 1) {
      crystalColor = pal.highlight;
    } else {
      final facetIdx = (facetX + facetY + seed) % 3;
      crystalColor = facetIdx == 0
          ? pal.primary
          : facetIdx == 1
              ? pal.secondary
              : pal.colors[2];
    }

    // Sparkles
    if (random.nextDouble() > 0.94) {
      crystalColor = pal.highlight;
    }

    return addNoise(crystalColor, random, 0.04);
  }

  int _generateIceTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 2);
    Color iceColor;

    if (y < 2) {
      iceColor = noiseVal > 0.5 ? pal.highlight : pal.secondary;
    } else if (noiseVal > 0.6) {
      iceColor = pal.secondary;
    } else if (noiseVal > 0.3) {
      iceColor = pal.primary;
    } else {
      iceColor = pal.colors[2];
    }

    // Ice cracks
    if ((x + y * 3) % 11 == 0 && random.nextDouble() > 0.7) {
      iceColor = pal.shadow;
    }

    return addNoise(iceColor, random, 0.03);
  }

  int _generateAutumnTop(int x, int y, int width, int topHeight, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
    Color leafColor;

    // Mix of fall colors
    if (noiseVal > 0.7) {
      leafColor = pal.highlight; // Yellow-orange
    } else if (noiseVal > 0.4) {
      leafColor = pal.secondary; // Light orange
    } else if (noiseVal > 0.2) {
      leafColor = pal.primary; // Orange
    } else {
      leafColor = pal.colors[2]; // Dark red
    }

    // Random leaf texture
    if (random.nextDouble() > 0.9) {
      leafColor = random.nextBool() ? pal.highlight : pal.shadow;
    }

    return addNoise(leafColor, random, 0.06);
  }

  // ===== BASE MATERIAL GENERATORS =====

  int _generateDirtBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
    Color dirtColor;

    if (noiseVal < 0.3) {
      dirtColor = pal.shadow;
    } else if (noiseVal < 0.5) {
      dirtColor = pal.colors[2];
    } else if (noiseVal < 0.7) {
      dirtColor = pal.primary;
    } else {
      dirtColor = pal.secondary;
    }

    // Small rocks/pebbles
    if (random.nextDouble() > 0.96) {
      dirtColor = pal.shadow;
    }

    return addNoise(dirtColor, random, 0.06);
  }

  int _generateStoneBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 3);
    Color stoneColor;

    if (noiseVal > 0.6) {
      stoneColor = pal.secondary;
    } else if (noiseVal > 0.3) {
      stoneColor = pal.primary;
    } else {
      stoneColor = pal.colors[2];
    }

    // Cracks
    if ((x * 7 + y * 13) % 17 == 0 && random.nextDouble() > 0.6) {
      stoneColor = pal.shadow;
    }

    return addNoise(stoneColor, random, 0.05);
  }

  int _generateBrickBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final brickW = 5;
    final brickH = 3;
    final row = y ~/ brickH;
    final offset = row % 2 == 1 ? brickW ~/ 2 : 0;
    final adjustedX = (x + offset) % width;

    final isHMortar = y % brickH == 0;
    final isVMortar = adjustedX % brickW == 0;

    Color brickColor;
    if (isHMortar || isVMortar) {
      brickColor = pal.shadow; // Mortar
    } else {
      final brickIdx = (row + adjustedX ~/ brickW + seed) % 3;
      brickColor = pal.colors[brickIdx];

      // Brick shading
      final posInX = adjustedX % brickW;
      final posInY = y % brickH;
      if (posInX == 1 || posInY == 1) {
        brickColor = pal.highlight;
      } else if (posInX == brickW - 2 || posInY == brickH - 2) {
        brickColor = pal.colors[2];
      }
    }

    return addNoise(brickColor, random, 0.04);
  }

  int _generateWoodBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    // Vertical wood planks
    final plankWidth = 4;
    final withinPlank = x % plankWidth;

    Color woodColor;
    if (withinPlank == 0) {
      woodColor = pal.shadow; // Gap between planks
    } else {
      // Wood grain
      final grainNoise = noise2D(x / 2.0 + seed, y / 6.0 + seed, 2);
      if (withinPlank == 1) {
        woodColor = pal.highlight;
      } else if (grainNoise > 0.6) {
        woodColor = pal.secondary;
      } else if (grainNoise > 0.3) {
        woodColor = pal.primary;
      } else {
        woodColor = pal.colors[2];
      }

      // Knots
      if (random.nextDouble() > 0.98) {
        woodColor = pal.shadow;
      }
    }

    return addNoise(woodColor, random, 0.05);
  }

  int _generateConcreteBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 5.0 + seed, y / 5.0, 2);
    Color concreteColor;

    if (noiseVal > 0.6) {
      concreteColor = pal.secondary;
    } else if (noiseVal > 0.3) {
      concreteColor = pal.primary;
    } else {
      concreteColor = pal.colors[2];
    }

    // Concrete joints
    if (x % 8 == 0 || y % 8 == 0) {
      concreteColor = pal.shadow;
    }

    // Aggregate specks
    if (random.nextDouble() > 0.95) {
      concreteColor = random.nextBool() ? pal.highlight : pal.shadow;
    }

    return addNoise(concreteColor, random, 0.04);
  }

  int _generateSandstoneBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    // Horizontal layers
    final layerHeight = 3;
    final layer = y ~/ layerHeight;
    final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 2);

    Color sandstoneColor;
    final layerColor = layer % 2 == 0 ? pal.primary : pal.secondary;

    if (y % layerHeight == 0) {
      sandstoneColor = pal.shadow; // Layer line
    } else if (noiseVal > 0.6) {
      sandstoneColor = pal.highlight;
    } else {
      sandstoneColor = layerColor;
    }

    return addNoise(sandstoneColor, random, 0.05);
  }

  int _generateIceBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 4.0 + seed, y / 4.0, 2);
    Color iceColor;

    if (noiseVal > 0.65) {
      iceColor = pal.highlight;
    } else if (noiseVal > 0.4) {
      iceColor = pal.secondary;
    } else if (noiseVal > 0.2) {
      iceColor = pal.primary;
    } else {
      iceColor = pal.colors[2];
    }

    // Ice cracks
    if ((x * 5 + y * 11) % 13 == 0) {
      iceColor = pal.shadow;
    }

    return addNoise(iceColor, random, 0.03);
  }

  int _generateMetalBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    // Industrial panel pattern
    final panelSize = 5;
    final onEdge = x % panelSize == 0 || y % panelSize == 0;
    final panelX = x ~/ panelSize;
    final panelY = y ~/ panelSize;

    Color metalColor;
    if (onEdge) {
      metalColor = pal.shadow;
    } else {
      final panelIdx = (panelX + panelY + seed) % 2;
      metalColor = panelIdx == 0 ? pal.primary : pal.secondary;

      // Highlight edges
      if (x % panelSize == 1 || y % panelSize == 1) {
        metalColor = pal.highlight;
      }
    }

    // Rust spots
    if (random.nextDouble() > 0.97) {
      metalColor = const Color(0xFF8A5A3A);
    }

    return addNoise(metalColor, random, 0.03);
  }

  int _generateDarkBrickBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final brickW = 4;
    final brickH = 2;
    final row = y ~/ brickH;
    final offset = row % 2 == 1 ? brickW ~/ 2 : 0;
    final adjustedX = (x + offset) % width;

    final isHMortar = y % brickH == 0;
    final isVMortar = adjustedX % brickW == 0;

    Color brickColor;
    if (isHMortar || isVMortar) {
      brickColor = pal.shadow;
    } else {
      final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
      if (noiseVal > 0.6) {
        brickColor = pal.secondary;
      } else if (noiseVal > 0.3) {
        brickColor = pal.primary;
      } else {
        brickColor = pal.colors[2];
      }
    }

    return addNoise(brickColor, random, 0.04);
  }

  int _generateClayBase(int x, int y, int width, int height, TilePalette pal, Random random, int seed) {
    final noiseVal = noise2D(x / 3.0 + seed, y / 3.0, 2);
    Color clayColor;

    if (noiseVal > 0.6) {
      clayColor = pal.secondary;
    } else if (noiseVal > 0.35) {
      clayColor = pal.primary;
    } else {
      clayColor = pal.colors[2];
    }

    // Occasional darker spots
    if (random.nextDouble() > 0.95) {
      clayColor = pal.shadow;
    }

    return addNoise(clayColor, random, 0.05);
  }

  void _addEdgeVariations(
    Uint32List pixels,
    int width,
    int height,
    int topHeight,
    TilePalette topPal,
    TilePalette basePal,
    Random random,
  ) {
    // Add irregular grass/surface edge at transition
    if (topSurface == TopSurface.grass || topSurface == TopSurface.moss || topSurface == TopSurface.autumn) {
      for (int x = 0; x < width; x++) {
        final edgeOffset = random.nextInt(2);
        final edgeY = topHeight + edgeOffset;
        if (edgeY < height && edgeY > 0) {
          if (random.nextDouble() > 0.4) {
            // Extend some grass/surface pixels down
            pixels[edgeY * width + x] = colorToInt(topPal.shadow);
          }
        }
      }
    }

    // Add roots for grass/moss
    if (topSurface == TopSurface.grass || topSurface == TopSurface.moss) {
      final rootColor = const Color(0xFF5A4A3A);
      for (int i = 0; i < 3; i++) {
        final rootX = random.nextInt(width);
        final rootStartY = topHeight;
        final rootLength = random.nextInt(3) + 1;
        for (int dy = 0; dy < rootLength; dy++) {
          final ry = rootStartY + dy;
          if (ry < height) {
            pixels[ry * width + rootX] = addNoise(rootColor, random, 0.1);
          }
        }
      }
    }
  }
}

// ============================================================================
// PRE-BUILT PLATFORMER BLOCK COMBINATIONS
// ============================================================================

/// Classic grass on dirt platformer block
class GrassDirtBlockTile extends PlatformerBlockTile {
  GrassDirtBlockTile(super.id)
      : super(
          topSurface: TopSurface.grass,
          baseMaterial: BaseMaterial.dirt,
        );
}

/// Grass on stone block
class GrassStoneBlockTile extends PlatformerBlockTile {
  GrassStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.grass,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Grass on brick block
class GrassBrickBlockTile extends PlatformerBlockTile {
  GrassBrickBlockTile(super.id)
      : super(
          topSurface: TopSurface.grass,
          baseMaterial: BaseMaterial.brick,
        );
}

/// Snow on ice block
class SnowIceBlockTile extends PlatformerBlockTile {
  SnowIceBlockTile(super.id)
      : super(
          topSurface: TopSurface.snow,
          baseMaterial: BaseMaterial.ice,
        );
}

/// Snow on stone block
class SnowStoneBlockTile extends PlatformerBlockTile {
  SnowStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.snow,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Moss on stone block
class MossStoneBlockTile extends PlatformerBlockTile {
  MossStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.moss,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Moss on brick block
class MossBrickBlockTile extends PlatformerBlockTile {
  MossBrickBlockTile(super.id)
      : super(
          topSurface: TopSurface.moss,
          baseMaterial: BaseMaterial.brick,
        );
}

/// Sand on sandstone block
class SandSandstoneBlockTile extends PlatformerBlockTile {
  SandSandstoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.sand,
          baseMaterial: BaseMaterial.sandstone,
        );
}

/// Sand on stone block
class SandStoneBlockTile extends PlatformerBlockTile {
  SandStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.sand,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Metal on metal block
class MetalBlockTile extends PlatformerBlockTile {
  MetalBlockTile(super.id)
      : super(
          topSurface: TopSurface.metal,
          baseMaterial: BaseMaterial.metal,
        );
}

/// Metal on concrete block
class MetalConcreteBlockTile extends PlatformerBlockTile {
  MetalConcreteBlockTile(super.id)
      : super(
          topSurface: TopSurface.metal,
          baseMaterial: BaseMaterial.concrete,
        );
}

/// Wood on wood block
class WoodBlockTile extends PlatformerBlockTile {
  WoodBlockTile(super.id)
      : super(
          topSurface: TopSurface.wood,
          baseMaterial: BaseMaterial.wood,
        );
}

/// Wood on dirt block
class WoodDirtBlockTile extends PlatformerBlockTile {
  WoodDirtBlockTile(super.id)
      : super(
          topSurface: TopSurface.wood,
          baseMaterial: BaseMaterial.dirt,
        );
}

/// Fungus on dirt block
class FungusDirtBlockTile extends PlatformerBlockTile {
  FungusDirtBlockTile(super.id)
      : super(
          topSurface: TopSurface.fungus,
          baseMaterial: BaseMaterial.dirt,
        );
}

/// Fungus on stone block
class FungusStoneBlockTile extends PlatformerBlockTile {
  FungusStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.fungus,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Crystal on stone block
class CrystalStoneBlockTile extends PlatformerBlockTile {
  CrystalStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.crystal,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Crystal on dark brick block
class CrystalDarkBrickBlockTile extends PlatformerBlockTile {
  CrystalDarkBrickBlockTile(super.id)
      : super(
          topSurface: TopSurface.crystal,
          baseMaterial: BaseMaterial.darkBrick,
        );
}

/// Ice on ice block
class IceBlockTile extends PlatformerBlockTile {
  IceBlockTile(super.id)
      : super(
          topSurface: TopSurface.ice,
          baseMaterial: BaseMaterial.ice,
        );
}

/// Ice on stone block
class IceStoneBlockTile extends PlatformerBlockTile {
  IceStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.ice,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Autumn leaves on dirt block
class AutumnDirtBlockTile extends PlatformerBlockTile {
  AutumnDirtBlockTile(super.id)
      : super(
          topSurface: TopSurface.autumn,
          baseMaterial: BaseMaterial.dirt,
        );
}

/// Autumn leaves on stone block
class AutumnStoneBlockTile extends PlatformerBlockTile {
  AutumnStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.autumn,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Grass on clay block
class GrassClayBlockTile extends PlatformerBlockTile {
  GrassClayBlockTile(super.id)
      : super(
          topSurface: TopSurface.grass,
          baseMaterial: BaseMaterial.clay,
        );
}

/// Grass on concrete block
class GrassConcreteBlockTile extends PlatformerBlockTile {
  GrassConcreteBlockTile(super.id)
      : super(
          topSurface: TopSurface.grass,
          baseMaterial: BaseMaterial.concrete,
        );
}

/// Wood on stone block
class WoodStoneBlockTile extends PlatformerBlockTile {
  WoodStoneBlockTile(super.id)
      : super(
          topSurface: TopSurface.wood,
          baseMaterial: BaseMaterial.stone,
        );
}

/// Snow on dirt block
class SnowDirtBlockTile extends PlatformerBlockTile {
  SnowDirtBlockTile(super.id)
      : super(
          topSurface: TopSurface.snow,
          baseMaterial: BaseMaterial.dirt,
        );
}
