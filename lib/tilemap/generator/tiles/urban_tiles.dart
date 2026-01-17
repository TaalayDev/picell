import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// URBAN TILE PALETTES
// ============================================================================

class UrbanTilePalettes {
  UrbanTilePalettes._();

  /// Asphalt road palette
  static const asphalt = TilePalette(
    name: 'Asphalt',
    colors: [
      Color(0xFF3A3A3A), // Base dark gray
      Color(0xFF4A4A4A), // Medium gray
      Color(0xFF2A2A2A), // Dark
      Color(0xFF5A5A5A), // Light patches
      Color(0xFF1A1A1A), // Shadow/cracks
    ],
  );

  /// Road marking white
  static const roadMarking = TilePalette(
    name: 'Road Marking',
    colors: [
      Color(0xFFE8E8E8), // White marking
      Color(0xFFD0D0D0), // Worn white
      Color(0xFFF0F0F0), // Bright white
      Color(0xFFFFFF00), // Yellow marking
      Color(0xFFCCCC00), // Worn yellow
    ],
  );

  /// Concrete palette
  static const concrete = TilePalette(
    name: 'Concrete',
    colors: [
      Color(0xFF8A8A8A), // Base gray
      Color(0xFF9A9A9A), // Light gray
      Color(0xFF7A7A7A), // Medium gray
      Color(0xFFAAAAAA), // Highlight
      Color(0xFF5A5A5A), // Shadow/joints
    ],
  );

  /// Gravel palette
  static const gravel = TilePalette(
    name: 'Gravel',
    colors: [
      Color(0xFF7A7A7A), // Base
      Color(0xFF8A8A8A), // Light
      Color(0xFF6A6A6A), // Dark
      Color(0xFF9A9A9A), // Highlight
      Color(0xFF4A4A4A), // Shadow
    ],
  );

  /// Grass green palette
  static const grassGreen = TilePalette(
    name: 'Grass Green',
    colors: [
      Color(0xFF4A8A3A), // Base green
      Color(0xFF5A9A4A), // Light green
      Color(0xFF3A7A2A), // Dark green
      Color(0xFF6AAA5A), // Highlight
      Color(0xFF2A5A1A), // Shadow
    ],
  );

  /// Lush grass palette
  static const lushGrass = TilePalette(
    name: 'Lush Grass',
    colors: [
      Color(0xFF3D8B37), // Vibrant green
      Color(0xFF4CAF50), // Light green
      Color(0xFF2E7D32), // Dark green
      Color(0xFF66BB6A), // Highlight
      Color(0xFF1B5E20), // Shadow
    ],
  );

  /// Dry grass palette
  static const dryGrass = TilePalette(
    name: 'Dry Grass',
    colors: [
      Color(0xFF8B9A6B), // Yellow-green
      Color(0xFF9BAA7B), // Light
      Color(0xFF7B8A5B), // Medium
      Color(0xFFABBA8B), // Highlight
      Color(0xFF5B6A4B), // Shadow
    ],
  );

  /// Dirt/soil palette
  static const soil = TilePalette(
    name: 'Soil',
    colors: [
      Color(0xFF6B5A4A), // Brown base
      Color(0xFF7B6A5A), // Light brown
      Color(0xFF5B4A3A), // Dark brown
      Color(0xFF8B7A6A), // Highlight
      Color(0xFF3B2A2A), // Shadow
    ],
  );

  /// Sandy ground palette
  static const sandyGround = TilePalette(
    name: 'Sandy Ground',
    colors: [
      Color(0xFFC4B090), // Tan base
      Color(0xFFD4C0A0), // Light tan
      Color(0xFFB4A080), // Medium tan
      Color(0xFFE4D0B0), // Highlight
      Color(0xFF948060), // Shadow
    ],
  );

  /// Red brick palette
  static const redBrick = TilePalette(
    name: 'Red Brick',
    colors: [
      Color(0xFF8B4513), // Red-brown base
      Color(0xFFA05A23), // Light brick
      Color(0xFF6B3503), // Dark brick
      Color(0xFFB06A33), // Highlight
      Color(0xFF4B2503), // Mortar
    ],
  );

  /// Roof tile palette (terracotta)
  static const roofTile = TilePalette(
    name: 'Roof Tile',
    colors: [
      Color(0xFF9B5B4B), // Terracotta base
      Color(0xFFAB6B5B), // Light
      Color(0xFF8B4B3B), // Dark
      Color(0xFFBB7B6B), // Highlight
      Color(0xFF5B3B2B), // Shadow
    ],
  );

  /// Slate roof palette
  static const slateRoof = TilePalette(
    name: 'Slate Roof',
    colors: [
      Color(0xFF4A5A6A), // Blue-gray base
      Color(0xFF5A6A7A), // Light
      Color(0xFF3A4A5A), // Dark
      Color(0xFF6A7A8A), // Highlight
      Color(0xFF2A3A4A), // Shadow
    ],
  );

  /// Rocky cliff palette
  static const rockCliff = TilePalette(
    name: 'Rock Cliff',
    colors: [
      Color(0xFF7A7A6A), // Gray-brown base
      Color(0xFF8A8A7A), // Light
      Color(0xFF6A6A5A), // Dark
      Color(0xFF9A9A8A), // Highlight
      Color(0xFF4A4A3A), // Shadow
    ],
  );

  /// Beach sand palette
  static const beachSand = TilePalette(
    name: 'Beach Sand',
    colors: [
      Color(0xFFE8D8B8), // Light sand
      Color(0xFFF0E0C0), // Bright sand
      Color(0xFFD0C0A0), // Medium sand
      Color(0xFFF8E8D0), // Highlight
      Color(0xFFB0A080), // Shadow
    ],
  );

  /// Checkered floor palette
  static const checkeredFloor = TilePalette(
    name: 'Checkered Floor',
    colors: [
      Color(0xFF2A2A2A), // Dark tile
      Color(0xFFE8E8E8), // Light tile
      Color(0xFF3A3A3A), // Dark variation
      Color(0xFFD0D0D0), // Light variation
      Color(0xFF1A1A1A), // Grout
    ],
  );

  /// Mossy stone palette
  static const mossyStone = TilePalette(
    name: 'Mossy Stone',
    colors: [
      Color(0xFF5A6A5A), // Green-gray base
      Color(0xFF6A7A6A), // Light
      Color(0xFF4A5A4A), // Dark
      Color(0xFF7A8A7A), // Highlight
      Color(0xFF3A4A3A), // Shadow
    ],
  );

  /// Cracked earth palette
  static const crackedEarth = TilePalette(
    name: 'Cracked Earth',
    colors: [
      Color(0xFF8B7B6B), // Dry earth
      Color(0xFF9B8B7B), // Light
      Color(0xFF7B6B5B), // Medium
      Color(0xFFAB9B8B), // Highlight
      Color(0xFF4B3B2B), // Cracks
    ],
  );
}

// ============================================================================
// ASPHALT AND ROAD TILES
// ============================================================================

/// Plain asphalt surface
class AsphaltTile extends TileBase {
  final bool addCracks;
  final bool addPatches;

  AsphaltTile(super.id, {this.addCracks = false, this.addPatches = false});

  @override
  String get name => 'Asphalt';
  @override
  String get description => 'Plain asphalt road surface';
  @override
  String get iconName => 'road';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.asphalt;
  @override
  List<String> get tags => ['road', 'asphalt', 'urban', 'street'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base asphalt texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise1 = noise2D(x / 2.0 + seed * 3, y / 2.0, 3);
        final noise2 = noise2D(x / 6.0 + seed * 7, y / 6.0, 2);
        final combined = noise1 * 0.7 + noise2 * 0.3;

        Color baseColor;
        if (combined < 0.3) {
          baseColor = palette.shadow;
        } else if (combined < 0.5) {
          baseColor = palette.colors[2];
        } else if (combined < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    // Add aggregate texture (small light specks)
    final speckCount = (width * height * 0.05).round();
    for (int i = 0; i < speckCount; i++) {
      final sx = random.nextInt(width);
      final sy = random.nextInt(height);
      pixels[sy * width + sx] = colorToInt(palette.highlight);
    }

    // Add cracks
    if (addCracks || variation == TileVariation.cracked) {
      _addCracks(pixels, width, height, random);
    }

    // Add repair patches
    if (addPatches || variation == TileVariation.weathered) {
      _addPatches(pixels, width, height, random);
    }

    return pixels;
  }

  void _addCracks(Uint32List pixels, int width, int height, Random random) {
    final crackCount = random.nextInt(2) + 1;
    for (int c = 0; c < crackCount; c++) {
      var cx = random.nextInt(width);
      var cy = random.nextInt(height);
      final length = random.nextInt(10) + 5;

      for (int i = 0; i < length; i++) {
        if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
          pixels[cy * width + cx] = colorToInt(palette.shadow);
        }
        cx += random.nextInt(3) - 1;
        cy += random.nextInt(2);
      }
    }
  }

  void _addPatches(Uint32List pixels, int width, int height, Random random) {
    final patchX = random.nextInt(width - 4);
    final patchY = random.nextInt(height - 4);
    final patchW = random.nextInt(4) + 2;
    final patchH = random.nextInt(4) + 2;

    for (int dy = 0; dy < patchH; dy++) {
      for (int dx = 0; dx < patchW; dx++) {
        final px = patchX + dx;
        final py = patchY + dy;
        if (px < width && py < height) {
          pixels[py * width + px] = addNoise(palette.primary, random, 0.05);
        }
      }
    }
  }
}

/// Asphalt with center line marking
class RoadCenterLineTile extends TileBase {
  final bool dashed;
  final bool doubleYellow;

  RoadCenterLineTile(super.id, {this.dashed = true, this.doubleYellow = false});

  @override
  String get name => 'Road Center Line';
  @override
  String get description => 'Road with center line marking';
  @override
  String get iconName => 'remove';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.asphalt;
  @override
  List<String> get tags => ['road', 'asphalt', 'marking', 'line', 'urban'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final markingPal = UrbanTilePalettes.roadMarking;

    // Base asphalt
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed * 4, y / 3.0, 2);
        final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Center line
    final centerX = width ~/ 2;
    final lineWidth = 2;
    final markingColor = doubleYellow ? markingPal.colors[3] : markingPal.primary;

    for (int y = 0; y < height; y++) {
      // Check if in dashed segment
      final inDash = !dashed || (y % 8) < 5;

      if (inDash) {
        for (int lw = 0; lw < lineWidth; lw++) {
          final lx = centerX - lineWidth ~/ 2 + lw;
          if (lx >= 0 && lx < width) {
            pixels[y * width + lx] = addNoise(markingColor, random, 0.02);
          }
        }

        // Double line
        if (doubleYellow) {
          for (int lw = 0; lw < lineWidth; lw++) {
            final lx = centerX + 1 + lw;
            if (lx >= 0 && lx < width) {
              pixels[y * width + lx] = addNoise(markingColor, random, 0.02);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Asphalt with edge/lane line
class RoadEdgeLineTile extends TileBase {
  final bool leftEdge;

  RoadEdgeLineTile(super.id, {this.leftEdge = true});

  @override
  String get name => 'Road Edge Line';
  @override
  String get description => 'Road with edge line marking';
  @override
  String get iconName => 'border_left';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.asphalt;
  @override
  List<String> get tags => ['road', 'asphalt', 'marking', 'edge', 'urban'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final markingPal = UrbanTilePalettes.roadMarking;

    // Base asphalt
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed * 4, y / 3.0, 2);
        final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Edge line
    final lineX = leftEdge ? 2 : width - 3;
    final lineWidth = 2;

    for (int y = 0; y < height; y++) {
      for (int lw = 0; lw < lineWidth; lw++) {
        final lx = lineX + lw;
        if (lx >= 0 && lx < width) {
          pixels[y * width + lx] = addNoise(markingPal.primary, random, 0.02);
        }
      }
    }

    return pixels;
  }
}

/// Parking lot with lines
class ParkingLotTile extends TileBase {
  ParkingLotTile(super.id);

  @override
  String get name => 'Parking Lot';
  @override
  String get description => 'Parking lot with line markings';
  @override
  String get iconName => 'local_parking';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.asphalt;
  @override
  List<String> get tags => ['road', 'parking', 'urban', 'lines'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final markingPal = UrbanTilePalettes.roadMarking;

    // Base asphalt
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 3.0 + seed * 4, y / 3.0, 2);
        final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Vertical parking lines
    final lineSpacing = width ~/ 2;
    for (int lineX = 0; lineX < width; lineX += lineSpacing) {
      for (int y = 2; y < height - 2; y++) {
        if (lineX < width) {
          pixels[y * width + lineX] = colorToInt(markingPal.primary);
          if (lineX + 1 < width) {
            pixels[y * width + lineX + 1] = colorToInt(markingPal.secondary);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// CONCRETE TILES
// ============================================================================

/// Plain concrete surface
class ConcreteTile extends TileBase {
  final bool addJoints;
  final bool addCracks;

  ConcreteTile(super.id, {this.addJoints = true, this.addCracks = false});

  @override
  String get name => 'Concrete';
  @override
  String get description => 'Concrete surface';
  @override
  String get iconName => 'square';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.concrete;
  @override
  List<String> get tags => ['concrete', 'urban', 'sidewalk', 'floor'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base concrete texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise1 = noise2D(x / 4.0 + seed * 5, y / 4.0, 2);
        final noise2 = noise2D(x / 8.0 + seed * 2, y / 8.0, 3);
        final combined = noise1 * 0.6 + noise2 * 0.4;

        Color baseColor;
        if (combined < 0.35) {
          baseColor = palette.colors[2];
        } else if (combined < 0.65) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    // Add expansion joints
    if (addJoints) {
      // Horizontal joint
      if (height > 8) {
        final jointY = height ~/ 2;
        for (int x = 0; x < width; x++) {
          pixels[jointY * width + x] = colorToInt(palette.shadow);
        }
      }
      // Vertical joint
      if (width > 8) {
        final jointX = width ~/ 2;
        for (int y = 0; y < height; y++) {
          pixels[y * width + jointX] = colorToInt(palette.shadow);
        }
      }
    }

    // Add cracks
    if (addCracks || variation == TileVariation.cracked) {
      var cx = random.nextInt(width);
      var cy = 0;
      while (cy < height) {
        if (cx >= 0 && cx < width) {
          pixels[cy * width + cx] = colorToInt(palette.shadow);
        }
        cy++;
        cx += random.nextInt(3) - 1;
      }
    }

    return pixels;
  }
}

/// Concrete slab/pavement
class ConcreteSlabTile extends TileBase {
  final int slabSize;

  ConcreteSlabTile(super.id, {this.slabSize = 8});

  @override
  String get name => 'Concrete Slab';
  @override
  String get description => 'Concrete pavement slabs';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.concrete;
  @override
  List<String> get tags => ['concrete', 'slab', 'pavement', 'urban'];

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
        final isJointH = y % slabSize == 0;
        final isJointV = x % slabSize == 0;

        if (isJointH || isJointV) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final slabX = x ~/ slabSize;
          final slabY = y ~/ slabSize;
          final slabSeed = seed + slabX * 7 + slabY * 13;

          final noiseVal = noise2D(x / 4.0 + slabSeed, y / 4.0, 2);
          final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(baseColor, random, 0.03);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// GRASS AND VEGETATION TILES
// ============================================================================

/// Lush green grass
class LushGrassTile extends TileBase {
  final double density;

  LushGrassTile(super.id, {this.density = 0.4});

  @override
  String get name => 'Lush Grass';
  @override
  String get description => 'Dense green grass';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.lushGrass;
  @override
  List<String> get tags => ['grass', 'green', 'nature', 'lawn'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base grass color
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noise1 = noise2D(x / 3.0 + seed * 4, y / 3.0, 3);
        final noise2 = noise2D(x / 6.0 + seed * 2, y / 6.0, 2);
        final combined = noise1 * 0.7 + noise2 * 0.3;

        Color baseColor;
        if (combined < 0.3) {
          baseColor = palette.shadow;
        } else if (combined < 0.5) {
          baseColor = palette.colors[2];
        } else if (combined < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    // Add grass blade highlights
    final bladeCount = (width * height * density).round();
    for (int i = 0; i < bladeCount; i++) {
      final bx = random.nextInt(width);
      final by = random.nextInt(height);
      pixels[by * width + bx] = colorToInt(palette.highlight);
    }

    return pixels;
  }
}

/// Grass with patches of dirt/wear
class WornGrassTile extends TileBase {
  WornGrassTile(super.id);

  @override
  String get name => 'Worn Grass';
  @override
  String get description => 'Grass with dirt patches';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.grassGreen;
  @override
  List<String> get tags => ['grass', 'dirt', 'worn', 'nature'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final dirtPal = UrbanTilePalettes.soil;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final grassNoise = noise2D(x / 3.0 + seed * 4, y / 3.0, 2);
        final dirtNoise = noise2D(x / 5.0 + seed * 2, y / 5.0, 3);

        Color baseColor;
        if (dirtNoise > 0.65) {
          // Dirt patch
          baseColor = dirtNoise > 0.8 ? dirtPal.shadow : dirtPal.primary;
        } else if (grassNoise < 0.4) {
          baseColor = palette.shadow;
        } else if (grassNoise < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}

/// Dry/dead grass
class DryGrassTile extends TileBase {
  DryGrassTile(super.id);

  @override
  String get name => 'Dry Grass';
  @override
  String get description => 'Dried yellow grass';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.dryGrass;
  @override
  List<String> get tags => ['grass', 'dry', 'yellow', 'dead'];

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
        final noiseVal = noise2D(x / 3.0 + seed * 5, y / 3.0, 3);

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
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    // Add some green patches
    final greenCount = (width * height * 0.05).round();
    for (int i = 0; i < greenCount; i++) {
      final gx = random.nextInt(width);
      final gy = random.nextInt(height);
      pixels[gy * width + gx] = colorToInt(UrbanTilePalettes.grassGreen.primary);
    }

    return pixels;
  }
}

// ============================================================================
// DIRT AND SOIL TILES
// ============================================================================

/// Rich soil/dirt
class SoilTile extends TileBase {
  final bool addRocks;

  SoilTile(super.id, {this.addRocks = true});

  @override
  String get name => 'Soil';
  @override
  String get description => 'Rich brown soil';
  @override
  String get iconName => 'terrain';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.soil;
  @override
  List<String> get tags => ['dirt', 'soil', 'earth', 'brown'];

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
        final noiseVal = noise2D(x / 3.0 + seed * 6, y / 3.0, 3);

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
        pixels[y * width + x] = addNoise(baseColor, random, 0.06);
      }
    }

    // Add small rocks
    if (addRocks) {
      final rockCount = random.nextInt(4) + 2;
      for (int i = 0; i < rockCount; i++) {
        final rx = random.nextInt(width);
        final ry = random.nextInt(height);
        pixels[ry * width + rx] = colorToInt(UrbanTilePalettes.gravel.primary);
      }
    }

    return pixels;
  }
}

/// Cracked dry earth
class CrackedEarthTile extends TileBase {
  CrackedEarthTile(super.id);

  @override
  String get name => 'Cracked Earth';
  @override
  String get description => 'Dry cracked earth';
  @override
  String get iconName => 'broken_image';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.crackedEarth;
  @override
  List<String> get tags => ['dirt', 'cracked', 'dry', 'desert'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final noiseVal = noise2D(x / 4.0 + seed * 3, y / 4.0, 2);
        final baseColor = noiseVal > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    // Add crack network using Voronoi-like pattern
    final crackSeeds = <List<int>>[];
    final seedCount = 4;
    for (int i = 0; i < seedCount; i++) {
      crackSeeds.add([random.nextInt(width), random.nextInt(height)]);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Find two closest seeds
        var minDist1 = double.infinity;
        var minDist2 = double.infinity;

        for (final seedPos in crackSeeds) {
          final dist = sqrt(pow(x - seedPos[0], 2) + pow(y - seedPos[1], 2));
          if (dist < minDist1) {
            minDist2 = minDist1;
            minDist1 = dist;
          } else if (dist < minDist2) {
            minDist2 = dist;
          }
        }

        // Draw crack at edges between regions
        if ((minDist2 - minDist1).abs() < 1.5) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        }
      }
    }

    return pixels;
  }
}

/// Gravel surface
class GravelTile extends TileBase {
  final bool fine;

  GravelTile(super.id, {this.fine = false});

  @override
  String get name => 'Gravel';
  @override
  String get description => 'Gravel surface';
  @override
  String get iconName => 'grain';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.gravel;
  @override
  List<String> get tags => ['gravel', 'rocks', 'path', 'ground'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Base fill
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    // Generate gravel stones
    final stoneSize = fine ? 1 : 2;
    final stoneCount = (width * height / (stoneSize * stoneSize * 2)).round();

    for (int s = 0; s < stoneCount; s++) {
      final sx = random.nextInt(width);
      final sy = random.nextInt(height);
      final colorIdx = random.nextInt(3);
      final stoneColor = palette.colors[colorIdx];

      for (int dy = 0; dy < stoneSize; dy++) {
        for (int dx = 0; dx < stoneSize; dx++) {
          final px = sx + dx;
          final py = sy + dy;
          if (px < width && py < height) {
            pixels[py * width + px] = addNoise(stoneColor, random, 0.05);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// ROCK AND CLIFF TILES
// ============================================================================

/// Rocky cliff surface
class RockCliffTile extends TileBase {
  RockCliffTile(super.id);

  @override
  String get name => 'Rock Cliff';
  @override
  String get description => 'Rocky cliff surface';
  @override
  String get iconName => 'landscape';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.rockCliff;
  @override
  List<String> get tags => ['rock', 'cliff', 'stone', 'mountain'];

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
        final noise1 = noise2D(x / 2.0 + seed * 3, y / 2.0, 4);
        final noise2 = noise2D(x / 5.0 + seed * 7, y / 5.0, 2);
        final combined = noise1 * 0.6 + noise2 * 0.4;

        // Vertical striations for cliff effect
        final striation = sin(x / 2.0 + noise1 * 3) * 0.2;
        final finalNoise = combined + striation;

        Color baseColor;
        if (finalNoise < 0.3) {
          baseColor = palette.shadow;
        } else if (finalNoise < 0.45) {
          baseColor = palette.colors[2];
        } else if (finalNoise < 0.6) {
          baseColor = palette.primary;
        } else if (finalNoise < 0.8) {
          baseColor = palette.secondary;
        } else {
          baseColor = palette.highlight;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}

/// Mossy rock surface
class MossyRockTile extends TileBase {
  MossyRockTile(super.id);

  @override
  String get name => 'Mossy Rock';
  @override
  String get description => 'Rock with moss growth';
  @override
  String get iconName => 'park';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.mossyStone;
  @override
  List<String> get tags => ['rock', 'moss', 'stone', 'nature'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final rockPal = UrbanTilePalettes.rockCliff;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final rockNoise = noise2D(x / 3.0 + seed * 4, y / 3.0, 3);
        final mossNoise = noise2D(x / 4.0 + seed * 2, y / 4.0, 2);

        Color baseColor;
        if (mossNoise > 0.55) {
          // Moss areas
          baseColor = mossNoise > 0.75 ? palette.highlight : palette.primary;
        } else if (rockNoise < 0.35) {
          baseColor = rockPal.shadow;
        } else if (rockNoise < 0.65) {
          baseColor = rockPal.primary;
        } else {
          baseColor = rockPal.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.05);
      }
    }

    return pixels;
  }
}

// ============================================================================
// ROOF TILES
// ============================================================================

/// Terracotta roof tiles
class RoofTileTile extends TileBase {
  final int tileHeight;

  RoofTileTile(super.id, {this.tileHeight = 4});

  @override
  String get name => 'Roof Tile';
  @override
  String get description => 'Terracotta roof tiles';
  @override
  String get iconName => 'roofing';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.roofTile;
  @override
  List<String> get tags => ['roof', 'tile', 'building', 'terracotta'];

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

        // Position within tile
        final posInTile = y % tileHeight;

        // Rounded tile effect
        Color baseColor;
        if (posInTile == 0) {
          baseColor = palette.shadow; // Bottom edge
        } else if (posInTile == 1) {
          baseColor = palette.colors[2]; // Shadow under curve
        } else if (posInTile == tileHeight - 1) {
          baseColor = palette.highlight; // Top highlight
        } else {
          // Main tile body
          final tileIdx = (row + adjustedX ~/ (width ~/ 2) + seed) % 3;
          baseColor = palette.colors[tileIdx];
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

/// Slate roof tiles
class SlateRoofTile extends TileBase {
  SlateRoofTile(super.id);

  @override
  String get name => 'Slate Roof';
  @override
  String get description => 'Slate roof tiles';
  @override
  String get iconName => 'roofing';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.slateRoof;
  @override
  List<String> get tags => ['roof', 'slate', 'building', 'gray'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final tileW = 4;
    final tileH = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ tileH;
        final offset = row % 2 == 1 ? tileW ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final isHGap = y % tileH == 0;
        final isVGap = adjustedX % tileW == 0;

        if (isHGap || isVGap) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final tileIdx = (row + adjustedX ~/ tileW + seed) % 3;
          final baseColor = palette.colors[tileIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Shingle roof
class ShingleRoofTile extends TileBase {
  ShingleRoofTile(super.id);

  @override
  String get name => 'Shingle Roof';
  @override
  String get description => 'Asphalt shingle roof';
  @override
  String get iconName => 'roofing';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.asphalt;
  @override
  List<String> get tags => ['roof', 'shingle', 'building'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final shingleH = 3;
    final shingleW = 5;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final row = y ~/ shingleH;
        final offset = row % 2 == 1 ? shingleW ~/ 2 : 0;
        final adjustedX = (x + offset) % width;

        final posInRow = y % shingleH;

        Color baseColor;
        if (posInRow == 0) {
          // Shadow line at bottom of each shingle row
          baseColor = palette.shadow;
        } else if (adjustedX % shingleW == 0) {
          // Vertical gaps
          baseColor = palette.shadow;
        } else {
          final shingleIdx = (row + adjustedX ~/ shingleW + seed) % 3;
          baseColor = palette.colors[shingleIdx];

          // Add texture variation
          final noiseVal = noise2D(x / 2.0 + seed, y / 2.0, 2);
          if (noiseVal > 0.7) {
            baseColor = palette.highlight;
          }
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.04);
      }
    }

    return pixels;
  }
}

// ============================================================================
// PAVING AND FLOOR TILES
// ============================================================================

/// Cobblestone paving
class CobblestonePavingTile extends TileBase {
  final bool irregular;

  CobblestonePavingTile(super.id, {this.irregular = false});

  @override
  String get name => 'Cobblestone Paving';
  @override
  String get description => 'Cobblestone paving stones';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.gravel;
  @override
  List<String> get tags => ['cobblestone', 'paving', 'street', 'stone'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Fill with mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    final stoneSize = irregular ? 3 : 4;

    for (int sy = 0; sy < height; sy += stoneSize) {
      for (int sx = 0; sx < width; sx += stoneSize) {
        final offsetX = irregular ? random.nextInt(2) - 1 : 0;
        final offsetY = irregular ? random.nextInt(2) - 1 : 0;
        final thisSize = irregular ? stoneSize + random.nextInt(2) - 1 : stoneSize;

        final colorIdx = random.nextInt(3);
        final stoneColor = palette.colors[colorIdx];

        for (int dy = 1; dy < thisSize - 1; dy++) {
          for (int dx = 1; dx < thisSize - 1; dx++) {
            final px = sx + dx + offsetX;
            final py = sy + dy + offsetY;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              pixels[py * width + px] = addNoise(stoneColor, random, 0.05);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Checkered floor tiles
class CheckeredFloorTile extends TileBase {
  final int tileSize;

  CheckeredFloorTile(super.id, {this.tileSize = 4});

  @override
  String get name => 'Checkered Floor';
  @override
  String get description => 'Black and white checkered floor';
  @override
  String get iconName => 'grid_on';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.checkeredFloor;
  @override
  List<String> get tags => ['floor', 'checkered', 'tile', 'indoor'];

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
        final tileX = x ~/ tileSize;
        final tileY = y ~/ tileSize;
        final isLight = (tileX + tileY) % 2 == 0;

        // Grout lines
        final isGrout = x % tileSize == 0 || y % tileSize == 0;

        Color baseColor;
        if (isGrout) {
          baseColor = palette.shadow;
        } else if (isLight) {
          baseColor = palette.secondary; // Light tile
        } else {
          baseColor = palette.primary; // Dark tile
        }

        pixels[y * width + x] = addNoise(baseColor, random, 0.02);
      }
    }

    return pixels;
  }
}

/// Square floor tiles
class SquareFloorTile extends TileBase {
  final int tileSize;

  SquareFloorTile(super.id, {this.tileSize = 4});

  @override
  String get name => 'Square Floor Tile';
  @override
  String get description => 'Square floor tiles';
  @override
  String get iconName => 'grid_view';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.concrete;
  @override
  List<String> get tags => ['floor', 'tile', 'square', 'indoor'];

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
        final isGrout = x % tileSize == 0 || y % tileSize == 0;

        if (isGrout) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final tileX = x ~/ tileSize;
          final tileY = y ~/ tileSize;
          final colorIdx = (tileX + tileY + seed) % 3;
          final baseColor = palette.colors[colorIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.03);
        }
      }
    }

    return pixels;
  }
}

/// Herringbone brick pattern
class HerringboneBrickTile extends TileBase {
  HerringboneBrickTile(super.id);

  @override
  String get name => 'Herringbone Brick';
  @override
  String get description => 'Herringbone brick pattern';
  @override
  String get iconName => 'view_quilt';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.redBrick;
  @override
  List<String> get tags => ['brick', 'herringbone', 'paving', 'pattern'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final brickW = 4;
    final brickH = 2;

    // Fill with mortar
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.shadow);
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Determine which brick unit we're in
        final unitX = x ~/ (brickW + brickH);
        final unitY = y ~/ (brickW + brickH);
        final localX = x % (brickW + brickH);
        final localY = y % (brickW + brickH);

        bool inBrick = false;
        int brickIdx = 0;

        // Horizontal brick in top-left
        if (localY < brickH && localX < brickW) {
          inBrick = localY > 0 && localX > 0 && localX < brickW - 1;
          brickIdx = (unitX + unitY) % 3;
        }
        // Vertical brick in bottom-right
        else if (localY >= brickH && localX >= brickH) {
          final vy = localY - brickH;
          final vx = localX - brickH;
          inBrick = vx > 0 && vx < brickH - 1 && vy < brickW - 1;
          brickIdx = (unitX + unitY + 1) % 3;
        }

        if (inBrick) {
          final baseColor = palette.colors[brickIdx];
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Beach sand texture
class BeachSandTile extends TileBase {
  final bool addShells;

  BeachSandTile(super.id, {this.addShells = false});

  @override
  String get name => 'Beach Sand';
  @override
  String get description => 'Fine beach sand';
  @override
  String get iconName => 'beach_access';
  @override
  TileCategory get category => TileCategory.urban;
  @override
  TilePalette get palette => UrbanTilePalettes.beachSand;
  @override
  List<String> get tags => ['sand', 'beach', 'coastal', 'ground'];

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
        final noise1 = noise2D(x / 5.0 + seed * 3, y / 5.0, 2);
        final noise2 = noise2D(x / 10.0 + seed * 7, y / 10.0, 3);
        final combined = noise1 * 0.6 + noise2 * 0.4;

        Color baseColor;
        if (combined < 0.3) {
          baseColor = palette.shadow;
        } else if (combined < 0.5) {
          baseColor = palette.colors[2];
        } else if (combined < 0.7) {
          baseColor = palette.primary;
        } else {
          baseColor = palette.secondary;
        }
        pixels[y * width + x] = addNoise(baseColor, random, 0.03);
      }
    }

    // Add ripple effect
    for (int y = 0; y < height; y++) {
      final ripple = sin(y / 2.0 + seed) * 0.3;
      for (int x = 0; x < width; x++) {
        if (ripple > 0.2 && random.nextDouble() < 0.3) {
          pixels[y * width + x] = colorToInt(palette.highlight);
        }
      }
    }

    // Add shells
    if (addShells) {
      final shellCount = random.nextInt(3);
      for (int i = 0; i < shellCount; i++) {
        final sx = random.nextInt(width);
        final sy = random.nextInt(height);
        pixels[sy * width + sx] = colorToInt(const Color(0xFFF0E0D0));
      }
    }

    return pixels;
  }
}
