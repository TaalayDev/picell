import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// NATURE TILE PALETTES
// ============================================================================

class NaturePalettes {
  NaturePalettes._();

  static const oakTree = TilePalette(
    name: 'Oak Tree',
    colors: [
      Color(0xFF5A4A3A), // Trunk brown
      Color(0xFF6A5A4A), // Light bark
      Color(0xFF4A3A2A), // Dark bark
      Color(0xFF7A6A5A), // Highlight
      Color(0xFF3A2A1A), // Shadow
    ],
  );

  static const pineTree = TilePalette(
    name: 'Pine Tree',
    colors: [
      Color(0xFF4A3A2A), // Trunk brown
      Color(0xFF5A4A3A), // Light bark
      Color(0xFF3A2A1A), // Dark bark
      Color(0xFF6A5A4A), // Highlight
      Color(0xFF2A1A0A), // Shadow
    ],
  );

  static const foliageGreen = TilePalette(
    name: 'Foliage Green',
    colors: [
      Color(0xFF3A7A3A), // Base green
      Color(0xFF4A9A4A), // Light green
      Color(0xFF2A5A2A), // Dark green
      Color(0xFF5AAA5A), // Highlight
      Color(0xFF1A3A1A), // Shadow
    ],
  );

  static const autumnFoliage = TilePalette(
    name: 'Autumn Foliage',
    colors: [
      Color(0xFFAA6A2A), // Orange
      Color(0xFFCC8A3A), // Light orange
      Color(0xFF8A4A1A), // Red-brown
      Color(0xFFDDAA4A), // Yellow highlight
      Color(0xFF6A3A0A), // Dark shadow
    ],
  );

  static const cherryBlossom = TilePalette(
    name: 'Cherry Blossom',
    colors: [
      Color(0xFFFFB7C5), // Pink base
      Color(0xFFFFD0DD), // Light pink
      Color(0xFFFF9AAA), // Deep pink
      Color(0xFFFFE0E8), // Highlight
      Color(0xFFDD8899), // Shadow
    ],
  );

  static const flowerRed = TilePalette(
    name: 'Red Flower',
    colors: [
      Color(0xFFCC3333), // Red
      Color(0xFFDD5555), // Light red
      Color(0xFFAA2222), // Dark red
      Color(0xFFFF6666), // Highlight
      Color(0xFF881111), // Shadow
    ],
  );

  static const flowerYellow = TilePalette(
    name: 'Yellow Flower',
    colors: [
      Color(0xFFDDCC33), // Yellow
      Color(0xFFEEDD55), // Light yellow
      Color(0xFFCCBB22), // Dark yellow
      Color(0xFFFFEE77), // Highlight
      Color(0xFFAA9911), // Shadow
    ],
  );

  static const flowerBlue = TilePalette(
    name: 'Blue Flower',
    colors: [
      Color(0xFF5577DD), // Blue
      Color(0xFF7799EE), // Light blue
      Color(0xFF3355BB), // Dark blue
      Color(0xFF99BBFF), // Highlight
      Color(0xFF223399), // Shadow
    ],
  );

  static const flowerPurple = TilePalette(
    name: 'Purple Flower',
    colors: [
      Color(0xFF9955CC), // Purple
      Color(0xFFBB77DD), // Light purple
      Color(0xFF7733AA), // Dark purple
      Color(0xFFDD99EE), // Highlight
      Color(0xFF552288), // Shadow
    ],
  );

  static const mushroom = TilePalette(
    name: 'Mushroom',
    colors: [
      Color(0xFFAA5544), // Cap red-brown
      Color(0xFFCC7766), // Light cap
      Color(0xFF883322), // Dark cap
      Color(0xFFEEDDCC), // Stem/spots
      Color(0xFF662211), // Shadow
    ],
  );

  static const blueMushroomPalette = TilePalette(
    name: 'Blue Mushroom',
    colors: [
      Color(0xFF5588AA), // Cap blue
      Color(0xFF77AACC), // Light cap
      Color(0xFF336688), // Dark cap
      Color(0xFFCCEEFF), // Spots glow
      Color(0xFF224466), // Shadow
    ],
  );

  static const tallGrass = TilePalette(
    name: 'Tall Grass',
    colors: [
      Color(0xFF5A9A4A), // Green
      Color(0xFF7ABA6A), // Light green
      Color(0xFF3A7A2A), // Dark green
      Color(0xFF9ADA8A), // Highlight
      Color(0xFF2A5A1A), // Shadow
    ],
  );

  static const reed = TilePalette(
    name: 'Reed',
    colors: [
      Color(0xFF8A9A6A), // Green-tan
      Color(0xFFAABA8A), // Light
      Color(0xFF6A7A4A), // Dark
      Color(0xFFCCDDAA), // Highlight
      Color(0xFF4A5A2A), // Shadow
    ],
  );

  static const bush = TilePalette(
    name: 'Bush',
    colors: [
      Color(0xFF4A8A3A), // Green
      Color(0xFF5AAA4A), // Light green
      Color(0xFF3A6A2A), // Dark green
      Color(0xFF6ACA5A), // Highlight
      Color(0xFF2A4A1A), // Shadow
    ],
  );

  static const berryBush = TilePalette(
    name: 'Berry Bush',
    colors: [
      Color(0xFF4A8A3A), // Green
      Color(0xFF5AAA4A), // Light green
      Color(0xFFAA3333), // Berries red
      Color(0xFF6ACA5A), // Highlight
      Color(0xFF2A4A1A), // Shadow
    ],
  );

  static const grayRock = TilePalette(
    name: 'Gray Rock',
    colors: [
      Color(0xFF7A7A7A), // Base gray
      Color(0xFF9A9A9A), // Light
      Color(0xFF5A5A5A), // Dark
      Color(0xFFBABABA), // Highlight
      Color(0xFF3A3A3A), // Shadow
    ],
  );

  static const brownRock = TilePalette(
    name: 'Brown Rock',
    colors: [
      Color(0xFF7A6A5A), // Base brown
      Color(0xFF9A8A7A), // Light
      Color(0xFF5A4A3A), // Dark
      Color(0xFFBAAA9A), // Highlight
      Color(0xFF3A2A1A), // Shadow
    ],
  );

  static const mossyRock = TilePalette(
    name: 'Mossy Rock',
    colors: [
      Color(0xFF6A7A6A), // Green-gray
      Color(0xFF8A9A8A), // Light
      Color(0xFF4A5A4A), // Dark
      Color(0xFF5A8A4A), // Moss highlight
      Color(0xFF3A4A3A), // Shadow
    ],
  );

  static const crystal = TilePalette(
    name: 'Crystal',
    colors: [
      Color(0xFFAADDFF), // Ice blue
      Color(0xFFCCEEFF), // Light
      Color(0xFF88BBDD), // Medium
      Color(0xFFFFFFFF), // Highlight
      Color(0xFF6699BB), // Shadow
    ],
  );

  static const amethyst = TilePalette(
    name: 'Amethyst',
    colors: [
      Color(0xFF9955CC), // Purple
      Color(0xFFBB88DD), // Light
      Color(0xFF7733AA), // Dark
      Color(0xFFDDBBEE), // Highlight
      Color(0xFF552277), // Shadow
    ],
  );

  static const emerald = TilePalette(
    name: 'Emerald',
    colors: [
      Color(0xFF33AA55), // Green
      Color(0xFF55CC77), // Light
      Color(0xFF228844), // Dark
      Color(0xFF88DDAA), // Highlight
      Color(0xFF115533), // Shadow
    ],
  );

  static const log = TilePalette(
    name: 'Log',
    colors: [
      Color(0xFF6A5A4A), // Bark brown
      Color(0xFF8A7A6A), // Light
      Color(0xFF4A3A2A), // Dark
      Color(0xFFAA9A8A), // Inner wood
      Color(0xFF3A2A1A), // Shadow
    ],
  );

  static const stump = TilePalette(
    name: 'Stump',
    colors: [
      Color(0xFF5A4A3A), // Brown
      Color(0xFF7A6A5A), // Light rings
      Color(0xFF3A2A1A), // Dark
      Color(0xFFAA9A7A), // Center
      Color(0xFF2A1A0A), // Shadow
    ],
  );

  static const lilyPad = TilePalette(
    name: 'Lily Pad',
    colors: [
      Color(0xFF4A9A5A), // Green
      Color(0xFF6ABA7A), // Light green
      Color(0xFF2A7A3A), // Dark green
      Color(0xFFFFAACC), // Flower pink
      Color(0xFF1A5A2A), // Shadow
    ],
  );

  static const cattail = TilePalette(
    name: 'Cattail',
    colors: [
      Color(0xFF7A9A6A), // Stalk green
      Color(0xFF9ABA8A), // Light
      Color(0xFF5A7A4A), // Dark
      Color(0xFF6A4A3A), // Brown head
      Color(0xFF3A5A2A), // Shadow
    ],
  );

  static const vine = TilePalette(
    name: 'Vine',
    colors: [
      Color(0xFF4A7A4A), // Green
      Color(0xFF5A9A5A), // Light
      Color(0xFF3A5A3A), // Dark
      Color(0xFF6AAA6A), // Highlight
      Color(0xFF2A4A2A), // Shadow
    ],
  );
}

// ============================================================================
// NATURE TILES BASE
// ============================================================================

/// Base class for nature objects (rocks, trees, plants, etc.)
abstract class NatureTile extends TileBase {
  NatureTile(super.id);

  @override
  TileCategory get category => TileCategory.nature;

  @override
  bool get supportsRotation => false;

  @override
  bool get supportsAutoTiling => false;
}

// ============================================================================
// TREE TILES
// ============================================================================

/// Tree trunk tile (vertical log)
class TreeTrunkTile extends NatureTile {
  final bool oak;

  TreeTrunkTile(super.id, {this.oak = true});

  @override
  String get name => oak ? 'Oak Trunk' : 'Pine Trunk';
  @override
  String get description => 'Tree trunk section';
  @override
  String get iconName => 'park';
  @override
  TilePalette get palette => oak ? NaturePalettes.oakTree : NaturePalettes.pineTree;
  @override
  List<String> get tags => ['nature', 'tree', 'trunk', 'wood'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Clear to transparent
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final trunkWidth = width * 0.6;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final distFromCenter = (x - cx).abs();
        if (distFromCenter < trunkWidth / 2) {
          // Bark texture
          final barkNoise = noise2D(x / 2.0 + seed, y / 3.0, 3);

          Color col;
          if (distFromCenter < trunkWidth / 4) {
            // Center lighter
            col = barkNoise > 0.5 ? palette.secondary : palette.primary;
          } else {
            // Edges darker
            col = barkNoise > 0.6 ? palette.primary : palette.colors[2];
          }

          // Add vertical striations
          if ((x + seed) % 3 == 0 && random.nextDouble() < 0.3) {
            col = palette.shadow;
          }

          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Tree foliage/canopy tile
class TreeFoliageTile extends NatureTile {
  final bool autumn;
  final bool cherry;

  TreeFoliageTile(super.id, {this.autumn = false, this.cherry = false});

  @override
  String get name => autumn ? 'Autumn Foliage' : (cherry ? 'Cherry Blossom' : 'Tree Foliage');
  @override
  String get description => 'Tree canopy leaves';
  @override
  String get iconName => 'forest';
  @override
  TilePalette get palette =>
      autumn ? NaturePalettes.autumnFoliage : (cherry ? NaturePalettes.cherryBlossom : NaturePalettes.foliageGreen);
  @override
  List<String> get tags => ['nature', 'tree', 'foliage', 'leaves'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height / 2;
    final radius = min(width, height) / 2 - 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        final edgeNoise = noise2D(x / 3.0 + seed, y / 3.0, 4) * 3;

        if (dist < radius + edgeNoise) {
          final leafNoise = noise2D(x / 2.0 + seed * 3, y / 2.0, 3);

          Color col;
          if (leafNoise < 0.25) {
            col = palette.shadow;
          } else if (leafNoise < 0.45) {
            col = palette.colors[2];
          } else if (leafNoise < 0.65) {
            col = palette.primary;
          } else if (leafNoise < 0.85) {
            col = palette.secondary;
          } else {
            col = palette.highlight;
          }

          // Add gaps/transparency for organic feel
          if (random.nextDouble() < 0.08) {
            continue;
          }

          pixels[y * width + x] = addNoise(col, random, 0.08);
        }
      }
    }

    return pixels;
  }
}

/// Pine tree shape
class PineTreeTile extends NatureTile {
  final bool snow;

  PineTreeTile(super.id, {this.snow = false});

  @override
  String get name => snow ? 'Snowy Pine' : 'Pine Tree';
  @override
  String get description => 'Triangular pine tree';
  @override
  String get iconName => 'park';
  @override
  TilePalette get palette => NaturePalettes.foliageGreen;
  @override
  List<String> get tags => ['nature', 'tree', 'pine', 'evergreen'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final trunkPal = NaturePalettes.pineTree;

    // Draw trunk at bottom
    final trunkWidth = 2;
    final trunkHeight = height ~/ 4;
    for (int y = height - trunkHeight; y < height; y++) {
      for (int x = (cx - trunkWidth / 2).toInt(); x < (cx + trunkWidth / 2).toInt(); x++) {
        if (x >= 0 && x < width) {
          pixels[y * width + x] = addNoise(trunkPal.primary, random, 0.05);
        }
      }
    }

    // Draw triangular foliage
    final foliageHeight = height - trunkHeight;
    for (int y = 0; y < foliageHeight; y++) {
      final progress = y / foliageHeight;
      final layerWidth = (progress * width * 0.8).toInt();

      for (int x = (cx - layerWidth / 2).toInt(); x < (cx + layerWidth / 2).toInt(); x++) {
        if (x >= 0 && x < width) {
          final noise = noise2D(x / 2.0 + seed, y / 2.0, 2);

          Color col;
          if (noise < 0.3) {
            col = palette.shadow;
          } else if (noise < 0.6) {
            col = palette.primary;
          } else {
            col = palette.secondary;
          }

          // Add snow on top
          if (snow && y < foliageHeight / 3 && random.nextDouble() < 0.4) {
            col = const Color(0xFFFFFFFF);
          }

          pixels[y * width + x] = addNoise(col, random, 0.06);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// FLOWER TILES
// ============================================================================

/// Small flower
class FlowerTile extends NatureTile {
  final TilePalette flowerPalette;

  FlowerTile(super.id, {TilePalette? colorPalette}) : flowerPalette = colorPalette ?? NaturePalettes.flowerRed;

  @override
  String get name => 'Flower';
  @override
  String get description => 'Small decorative flower';
  @override
  String get iconName => 'local_florist';
  @override
  TilePalette get palette => flowerPalette;
  @override
  List<String> get tags => ['nature', 'flower', 'plant', 'decoration'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width ~/ 2;
    final cy = height ~/ 2;

    // Draw stem
    final stemPal = NaturePalettes.tallGrass;
    for (int y = cy + 1; y < height; y++) {
      pixels[y * width + cx] = addNoise(stemPal.primary, random, 0.05);
    }

    // Draw petals in cross pattern
    final petalSize = min(width, height) ~/ 4;
    final directions = [
      [0, -1], [0, 1], [-1, 0], [1, 0], // Cardinal
      [-1, -1], [1, -1], [-1, 1], [1, 1], // Diagonal (smaller)
    ];

    for (int i = 0; i < directions.length; i++) {
      final dx = directions[i][0];
      final dy = directions[i][1];
      final size = i < 4 ? petalSize : petalSize - 1;

      for (int d = 1; d <= size; d++) {
        final px = cx + dx * d;
        final py = cy + dy * d;
        if (px >= 0 && px < width && py >= 0 && py < height) {
          final col = d == size ? palette.secondary : palette.primary;
          pixels[py * width + px] = addNoise(col, random, 0.05);
        }
      }
    }

    // Draw center
    pixels[cy * width + cx] = colorToInt(palette.highlight);

    return pixels;
  }
}

/// Flower patch (multiple small flowers)
class FlowerPatchTile extends NatureTile {
  final TilePalette flowerPalette;
  final int flowerCount;

  FlowerPatchTile(super.id, {TilePalette? colorPalette, this.flowerCount = 3})
      : flowerPalette = colorPalette ?? NaturePalettes.flowerRed;

  @override
  String get name => 'Flower Patch';
  @override
  String get description => 'Patch of small flowers';
  @override
  String get iconName => 'local_florist';
  @override
  TilePalette get palette => flowerPalette;
  @override
  List<String> get tags => ['nature', 'flower', 'plant', 'patch'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    // Draw grass base
    final grassPal = NaturePalettes.tallGrass;
    for (int y = height ~/ 2; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (random.nextDouble() < 0.5) {
          pixels[y * width + x] = addNoise(grassPal.primary, random, 0.08);
        }
      }
    }

    // Draw flowers
    for (int f = 0; f < flowerCount; f++) {
      final fx = random.nextInt(width - 2) + 1;
      final fy = random.nextInt(height ~/ 2) + height ~/ 4;

      // Stem
      for (int y = fy + 1; y < min(fy + 4, height); y++) {
        pixels[y * width + fx] = colorToInt(grassPal.shadow);
      }

      // Petals
      pixels[fy * width + fx] = colorToInt(palette.highlight); // Center
      if (fx > 0) pixels[fy * width + fx - 1] = colorToInt(palette.primary);
      if (fx < width - 1) pixels[fy * width + fx + 1] = colorToInt(palette.primary);
      if (fy > 0) pixels[(fy - 1) * width + fx] = colorToInt(palette.primary);
    }

    return pixels;
  }
}

// ============================================================================
// GRASS AND VEGETATION TILES
// ============================================================================

/// Tall grass tuft
class TallGrassTile extends NatureTile {
  final bool dense;

  TallGrassTile(super.id, {this.dense = false});

  @override
  String get name => dense ? 'Dense Grass' : 'Tall Grass';
  @override
  String get description => 'Tall grass blades';
  @override
  String get iconName => 'grass';
  @override
  TilePalette get palette => NaturePalettes.tallGrass;
  @override
  List<String> get tags => ['nature', 'grass', 'vegetation'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final bladeCount = dense ? width : width ~/ 2;

    for (int b = 0; b < bladeCount; b++) {
      final bx = random.nextInt(width);
      final bladeHeight = random.nextInt(height ~/ 2) + height ~/ 2;
      var x = bx;
      final sway = random.nextInt(3) - 1;

      for (int y = height - 1; y >= height - bladeHeight; y--) {
        if (x >= 0 && x < width && y >= 0) {
          final progress = (height - y) / bladeHeight;
          Color col;
          if (progress < 0.3) {
            col = palette.shadow;
          } else if (progress < 0.7) {
            col = palette.primary;
          } else {
            col = palette.secondary;
          }
          pixels[y * width + x] = addNoise(col, random, 0.08);
        }

        // Add sway at top
        if (random.nextDouble() < 0.2) {
          x += sway;
        }
      }
    }

    return pixels;
  }
}

/// Reed/cattail
class ReedTile extends NatureTile {
  final bool cattail;

  ReedTile(super.id, {this.cattail = false});

  @override
  String get name => cattail ? 'Cattail' : 'Reed';
  @override
  String get description => cattail ? 'Cattail plant' : 'Water reed';
  @override
  String get iconName => 'grass';
  @override
  TilePalette get palette => cattail ? NaturePalettes.cattail : NaturePalettes.reed;
  @override
  List<String> get tags => ['nature', 'reed', 'water', 'plant'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final stalkCount = 2 + random.nextInt(2);

    for (int s = 0; s < stalkCount; s++) {
      final sx = (width / (stalkCount + 1) * (s + 1)).toInt();
      var x = sx;

      // Draw stalk
      for (int y = height - 1; y >= 2; y--) {
        if (x >= 0 && x < width) {
          pixels[y * width + x] = addNoise(palette.primary, random, 0.05);
        }
        if (random.nextDouble() < 0.1) x += random.nextInt(3) - 1;
      }

      // Draw cattail head
      if (cattail) {
        final headHeight = 3 + random.nextInt(2);
        for (int y = 2; y < 2 + headHeight; y++) {
          if (y < height) {
            pixels[y * width + sx] = colorToInt(palette.colors[3]); // Brown head
            if (sx > 0) pixels[y * width + sx - 1] = addNoise(palette.colors[3], random, 0.1);
          }
        }
      }
    }

    return pixels;
  }
}

/// Bush/shrub
class BushTile extends NatureTile {
  final bool berries;

  BushTile(super.id, {this.berries = false});

  @override
  String get name => berries ? 'Berry Bush' : 'Bush';
  @override
  String get description => berries ? 'Bush with berries' : 'Small shrub';
  @override
  String get iconName => 'park';
  @override
  TilePalette get palette => berries ? NaturePalettes.berryBush : NaturePalettes.bush;
  @override
  List<String> get tags => ['nature', 'bush', 'shrub', 'plant'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height * 0.6;
    final radiusX = width * 0.45;
    final radiusY = height * 0.4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / radiusX;
        final dy = (y - cy) / radiusY;
        final dist = sqrt(dx * dx + dy * dy);

        final noise = noise2D(x / 2.0 + seed, y / 2.0, 3) * 0.3;

        if (dist < 1.0 + noise) {
          final leafNoise = noise2D(x / 1.5 + seed * 3, y / 1.5, 2);

          Color col;
          if (leafNoise < 0.25) {
            col = palette.shadow;
          } else if (leafNoise < 0.5) {
            col = palette.colors[2];
          } else if (leafNoise < 0.75) {
            col = palette.primary;
          } else {
            col = palette.secondary;
          }

          pixels[y * width + x] = addNoise(col, random, 0.08);
        }
      }
    }

    // Add berries
    if (berries) {
      final berryCount = 4 + random.nextInt(4);
      for (int b = 0; b < berryCount; b++) {
        final bx = random.nextInt(width - 4) + 2;
        final by = random.nextInt(height ~/ 2) + height ~/ 4;
        if (pixels[by * width + bx] != 0) {
          pixels[by * width + bx] = colorToInt(palette.colors[2]); // Red berries
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// MUSHROOM TILES
// ============================================================================

/// Mushroom
class MushroomTile extends NatureTile {
  final bool glowing;
  final bool cluster;

  MushroomTile(super.id, {this.glowing = false, this.cluster = false});

  @override
  String get name => glowing ? 'Glowing Mushroom' : (cluster ? 'Mushroom Cluster' : 'Mushroom');
  @override
  String get description => glowing ? 'Bioluminescent mushroom' : 'Forest mushroom';
  @override
  String get iconName => 'spa';
  @override
  TilePalette get palette => glowing ? NaturePalettes.blueMushroomPalette : NaturePalettes.mushroom;
  @override
  List<String> get tags => ['nature', 'mushroom', 'fungus', 'plant'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    void drawMushroom(int cx, int baseY, int capRadius, int stemHeight) {
      // Draw stem
      final stemWidth = max(1, capRadius ~/ 2);
      for (int y = baseY - stemHeight; y < baseY; y++) {
        for (int x = cx - stemWidth ~/ 2; x <= cx + stemWidth ~/ 2; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            pixels[y * width + x] = colorToInt(palette.colors[3]); // Stem color
          }
        }
      }

      // Draw cap
      final capY = baseY - stemHeight;
      for (int y = capY - capRadius; y <= capY; y++) {
        for (int x = cx - capRadius; x <= cx + capRadius; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final dx = (x - cx).abs();
            final dy = (y - capY).abs();
            if (dx * dx + dy * 2 * dy <= capRadius * capRadius) {
              final isTop = y < capY - capRadius / 2;
              Color col;
              if (isTop) {
                col = palette.secondary;
              } else {
                col = palette.primary;
              }

              // Add spots
              if ((x + y + seed) % 4 == 0 && random.nextDouble() < 0.3) {
                col = palette.colors[3];
              }

              pixels[y * width + x] = addNoise(col, random, 0.06);
            }
          }
        }
      }
    }

    if (cluster) {
      drawMushroom(width ~/ 4, height - 1, 3, 4);
      drawMushroom(width ~/ 2, height - 2, 4, 5);
      drawMushroom(3 * width ~/ 4, height - 1, 2, 3);
    } else {
      drawMushroom(width ~/ 2, height - 1, min(width, height) ~/ 3, height ~/ 2);
    }

    return pixels;
  }
}

// ============================================================================
// ROCK AND STONE TILES
// ============================================================================

/// Improved rock/stone object with better shading
class StoneTile extends NatureTile {
  final bool addMoss;
  final bool large;
  final TilePalette? rockPalette;

  StoneTile(super.id, {this.addMoss = false, this.large = false, this.rockPalette});

  @override
  String get name => large ? 'Large Rock' : 'Rock';
  @override
  String get description => 'Natural rock formation';
  @override
  String get iconName => 'landscape';
  @override
  TilePalette get palette => rockPalette ?? NaturePalettes.grayRock;
  @override
  List<String> get tags => ['nature', 'rock', 'stone', 'obstacle'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height * 0.55; // Slightly lower center
    final radiusX = width * (large ? 0.48 : 0.42);
    final radiusY = height * (large ? 0.45 : 0.38);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / radiusX;
        final dy = (y - cy) / radiusY;
        final dist = sqrt(dx * dx + dy * dy);

        // Multi-octave noise for irregular edge
        final edgeNoise = noise2D(x / 4.0 + seed, y / 4.0, 4) * 0.25 + noise2D(x / 2.0 + seed * 3, y / 2.0, 2) * 0.15;

        if (dist < 1.0 + edgeNoise) {
          // 3D shading - light from top-left
          final lightX = -0.6;
          final lightY = -0.6;
          final normalX = dx;
          final normalY = dy;
          final light = -(normalX * lightX + normalY * lightY);

          // Surface texture
          final texNoise = noise2D(x / 2.0 + seed * 5, y / 2.0, 3);

          Color col;
          if (light > 0.35) {
            col = texNoise > 0.7 ? palette.highlight : palette.secondary;
          } else if (light > 0.0) {
            col = texNoise > 0.6 ? palette.secondary : palette.primary;
          } else if (light > -0.3) {
            col = texNoise > 0.4 ? palette.primary : palette.colors[2];
          } else {
            col = palette.shadow;
          }

          pixels[y * width + x] = addNoise(col, random, 0.06);

          // Edge darkening for depth
          if (dist > 0.85 + edgeNoise * 0.5) {
            pixels[y * width + x] = addNoise(palette.shadow, random, 0.08);
          }
        }
      }
    }

    // Add moss on top portion
    if (addMoss || variation == TileVariation.mossy) {
      final mossPal = NaturePalettes.mossyRock;
      for (int y = 0; y < height ~/ 2; y++) {
        for (int x = 0; x < width; x++) {
          if (pixels[y * width + x] != 0) {
            final mossNoise = noise2D(x / 2.0 + seed * 7, y / 2.0, 2);
            if (mossNoise > 0.5 && random.nextDouble() < 0.5) {
              pixels[y * width + x] = addNoise(mossPal.colors[3], random, 0.1);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Rock pile/cluster
class RockPileTile extends NatureTile {
  RockPileTile(super.id);

  @override
  String get name => 'Rock Pile';
  @override
  String get description => 'Cluster of small rocks';
  @override
  String get iconName => 'landscape';
  @override
  TilePalette get palette => NaturePalettes.grayRock;
  @override
  List<String> get tags => ['nature', 'rock', 'pile', 'debris'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    // Generate several small rocks
    final rockCount = 4 + random.nextInt(3);
    for (int r = 0; r < rockCount; r++) {
      final rx = random.nextInt(width - 4) + 2;
      final ry = random.nextInt(height ~/ 2) + height ~/ 2;
      final rsize = 2 + random.nextInt(3);

      final colorIdx = random.nextInt(3);
      final rockColor = palette.colors[colorIdx];

      for (int dy = -rsize ~/ 2; dy <= rsize ~/ 2; dy++) {
        for (int dx = -rsize ~/ 2; dx <= rsize ~/ 2; dx++) {
          final px = rx + dx;
          final py = ry + dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            final dist = sqrt(dx * dx + dy * dy);
            if (dist < rsize / 2) {
              final isHighlight = dy < 0 && dx < 0;
              final col = isHighlight ? palette.secondary : rockColor;
              pixels[py * width + px] = addNoise(col, random, 0.08);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Boulder (large rock)
class BoulderTile extends NatureTile {
  final bool cracked;

  BoulderTile(super.id, {this.cracked = false});

  @override
  String get name => cracked ? 'Cracked Boulder' : 'Boulder';
  @override
  String get description => 'Large boulder';
  @override
  String get iconName => 'terrain';
  @override
  TilePalette get palette => NaturePalettes.brownRock;
  @override
  List<String> get tags => ['nature', 'rock', 'boulder', 'large'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height * 0.55;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Slightly squashed ellipse
        final dx = (x - cx) / (width * 0.48);
        final dy = (y - cy) / (height * 0.42);
        final dist = sqrt(dx * dx + dy * dy);

        final edgeNoise = noise2D(x / 5.0 + seed, y / 5.0, 3) * 0.2;

        if (dist < 1.0 + edgeNoise) {
          // Lighting
          final light = -(dx * -0.5 + dy * -0.6);
          final texNoise = noise2D(x / 3.0 + seed * 4, y / 3.0, 3);

          Color col;
          if (light > 0.3) {
            col = texNoise > 0.6 ? palette.highlight : palette.secondary;
          } else if (light > 0) {
            col = palette.primary;
          } else {
            col = texNoise < 0.4 ? palette.shadow : palette.colors[2];
          }

          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    }

    // Add cracks
    if (cracked || variation == TileVariation.cracked) {
      final crackCount = 2 + random.nextInt(2);
      for (int c = 0; c < crackCount; c++) {
        var cx2 = width ~/ 3 + random.nextInt(width ~/ 3);
        var cy2 = random.nextInt(height ~/ 3) + height ~/ 4;
        for (int i = 0; i < height ~/ 2; i++) {
          if (cx2 >= 0 && cx2 < width && cy2 >= 0 && cy2 < height) {
            if (pixels[cy2 * width + cx2] != 0) {
              pixels[cy2 * width + cx2] = colorToInt(palette.shadow);
            }
          }
          cy2++;
          cx2 += random.nextInt(3) - 1;
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// CRYSTAL TILES
// ============================================================================

/// Crystal formation
class NatureCrystalTile extends NatureTile {
  final TilePalette? crystalPalette;

  NatureCrystalTile(super.id, {this.crystalPalette});

  @override
  String get name => 'Crystal';
  @override
  String get description => 'Crystalline formation';
  @override
  String get iconName => 'diamond';
  @override
  TilePalette get palette => crystalPalette ?? NaturePalettes.crystal;
  @override
  List<String> get tags => ['nature', 'crystal', 'gem', 'mineral'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    // Draw crystal shards
    final shardCount = 3 + random.nextInt(2);
    for (int s = 0; s < shardCount; s++) {
      final baseX = (width / (shardCount + 1) * (s + 1)).toInt() + random.nextInt(3) - 1;
      final baseY = height - 1;
      final shardHeight = height ~/ 2 + random.nextInt(height ~/ 3);
      final shardWidth = 2 + random.nextInt(2);

      for (int y = baseY; y > baseY - shardHeight; y--) {
        final progress = (baseY - y) / shardHeight;
        final currentWidth = (shardWidth * (1 - progress * 0.8)).toInt();

        for (int dx = -currentWidth; dx <= currentWidth; dx++) {
          final x = baseX + dx;
          if (x >= 0 && x < width && y >= 0) {
            // Faceted look
            final isEdge = dx.abs() == currentWidth;
            final isHighlight = dx < 0 && progress > 0.5;

            Color col;
            if (isEdge) {
              col = palette.shadow;
            } else if (isHighlight) {
              col = palette.highlight;
            } else if (progress > 0.7) {
              col = palette.secondary;
            } else {
              col = palette.primary;
            }

            pixels[y * width + x] = addNoise(col, random, 0.04);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// LOG AND WOOD TILES
// ============================================================================

/// Fallen log
class LogTile extends NatureTile {
  final bool mossy;

  LogTile(super.id, {this.mossy = false});

  @override
  String get name => mossy ? 'Mossy Log' : 'Log';
  @override
  String get description => 'Fallen tree log';
  @override
  String get iconName => 'horizontal_rule';
  @override
  TilePalette get palette => NaturePalettes.log;
  @override
  List<String> get tags => ['nature', 'log', 'wood', 'fallen'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cy = height ~/ 2;
    final logRadius = height ~/ 3;

    for (int y = cy - logRadius; y <= cy + logRadius; y++) {
      for (int x = 0; x < width; x++) {
        if (y >= 0 && y < height) {
          final dy = (y - cy).abs();
          final isTop = y < cy;

          // Bark texture
          final barkNoise = noise2D(x / 3.0 + seed, y / 2.0, 2);

          Color col;
          if (dy == logRadius) {
            col = palette.shadow;
          } else if (isTop) {
            col = barkNoise > 0.5 ? palette.secondary : palette.primary;
          } else {
            col = barkNoise > 0.6 ? palette.primary : palette.colors[2];
          }

          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    }

    // Add moss
    if (mossy || variation == TileVariation.mossy) {
      final mossPal = NaturePalettes.mossyRock;
      for (int x = 0; x < width; x++) {
        for (int y = cy - logRadius; y < cy; y++) {
          if (y >= 0 && random.nextDouble() < 0.3) {
            pixels[y * width + x] = colorToInt(mossPal.colors[3]);
          }
        }
      }
    }

    return pixels;
  }
}

/// Tree stump
class StumpTile extends NatureTile {
  StumpTile(super.id);

  @override
  String get name => 'Tree Stump';
  @override
  String get description => 'Cut tree stump with rings';
  @override
  String get iconName => 'blur_circular';
  @override
  TilePalette get palette => NaturePalettes.stump;
  @override
  List<String> get tags => ['nature', 'stump', 'wood', 'tree'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height / 2;
    final radius = min(width, height) / 2 - 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));

        if (dist < radius) {
          // Tree rings
          final ringDist = dist % 3;
          Color col;
          if (ringDist < 1) {
            col = palette.colors[3]; // Light ring
          } else if (ringDist < 2) {
            col = palette.primary;
          } else {
            col = palette.colors[2];
          }

          // Darken edge (bark)
          if (dist > radius - 2) {
            col = palette.shadow;
          }

          pixels[y * width + x] = addNoise(col, random, 0.06);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// WATER PLANT TILES
// ============================================================================

/// Lily pad
class NatureLilyPadTile extends NatureTile {
  final bool withFlower;

  NatureLilyPadTile(super.id, {this.withFlower = false});

  @override
  String get name => withFlower ? 'Lily Pad with Flower' : 'Lily Pad';
  @override
  String get description => 'Floating lily pad';
  @override
  String get iconName => 'spa';
  @override
  TilePalette get palette => NaturePalettes.lilyPad;
  @override
  List<String> get tags => ['nature', 'water', 'lily', 'plant'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height / 2;
    final radius = min(width, height) / 2 - 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);

        // Create notch in lily pad
        final angle = atan2(dy, dx);
        final notchAngle = -pi / 4; // Notch position
        final inNotch = (angle - notchAngle).abs() < 0.3 && dist > radius * 0.3;

        if (dist < radius && !inNotch) {
          final noise = noise2D(x / 3.0 + seed, y / 3.0, 2);

          Color col;
          if (dist > radius - 1.5) {
            col = palette.shadow;
          } else if (noise > 0.6) {
            col = palette.secondary;
          } else {
            col = palette.primary;
          }

          // Add vein pattern
          if (((x - cx.toInt()).abs() < 1 || (y - cy.toInt()).abs() < 1) && dist < radius - 2) {
            col = palette.colors[2];
          }

          pixels[y * width + x] = addNoise(col, random, 0.06);
        }
      }
    }

    // Add flower
    if (withFlower) {
      final fx = cx.toInt() - 1;
      final fy = cy.toInt() - 1;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final px = fx + dx;
          final py = fy + dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            pixels[py * width + px] = colorToInt(palette.colors[3]); // Pink flower
          }
        }
      }
    }

    return pixels;
  }
}

/// Vine/ivy
class VineTile extends NatureTile {
  final bool hanging;

  VineTile(super.id, {this.hanging = true});

  @override
  String get name => hanging ? 'Hanging Vine' : 'Climbing Vine';
  @override
  String get description => hanging ? 'Hanging vine tendrils' : 'Wall-climbing vine';
  @override
  String get iconName => 'eco';
  @override
  TilePalette get palette => NaturePalettes.vine;
  @override
  List<String> get tags => ['nature', 'vine', 'plant', 'climbing'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final vineCount = 2 + random.nextInt(2);

    for (int v = 0; v < vineCount; v++) {
      var x = (width / (vineCount + 1) * (v + 1)).toInt();
      final startY = hanging ? 0 : height - 1;
      final endY = hanging ? height : -1;
      final step = hanging ? 1 : -1;

      for (int y = startY; y != endY; y += step) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          pixels[y * width + x] = addNoise(palette.shadow, random, 0.05);

          // Add leaves
          if (random.nextDouble() < 0.35) {
            final leafDir = random.nextBool() ? 1 : -1;
            final leafX = x + leafDir;
            if (leafX >= 0 && leafX < width) {
              pixels[y * width + leafX] = colorToInt(palette.primary);
              if (random.nextDouble() < 0.4) {
                final leaf2 = x + leafDir * 2;
                if (leaf2 >= 0 && leaf2 < width) {
                  pixels[y * width + leaf2] = colorToInt(palette.secondary);
                }
              }
            }
          }
        }

        // Vine sway
        if (random.nextDouble() < 0.2) {
          x += random.nextInt(3) - 1;
        }
      }
    }

    return pixels;
  }
}
