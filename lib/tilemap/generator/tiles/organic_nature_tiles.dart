import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// ORGANIC/NATURE PALETTES
// ============================================================================

class OrganicNaturePalettes {
  OrganicNaturePalettes._();

  static const vineOvergrown = TilePalette(
    name: 'Vine Overgrown',
    colors: [
      Color(0xFF2E4D23), // Deep green
      Color(0xFF4A773C), // Vine green
      Color(0xFF6B9E54), // Leaf green
      Color(0xFF8FBC8F), // Light moss
      Color(0xFF3B2F2F), // Dark wood
    ],
  );

  static const mushroom = TilePalette(
    name: 'Mushroom',
    colors: [
      Color(0xFFB22222), // Firebrick red
      Color(0xFFCD5C5C), // Indian red
      Color(0xFFF0F8FF), // Alice blue (stem)
      Color(0xFFFFE4E1), // Misty rose (spots)
      Color(0xFF8B4513), // Saddle brown
    ],
  );

  static const coralReef = TilePalette(
    name: 'Coral Reef',
    colors: [
      Color(0xFFFF7F50), // Coral
      Color(0xFFFF6347), // Tomato
      Color(0xFFFFDAB9), // Peach puff
      Color(0xFF20B2AA), // Light sea green
      Color(0xFF1E90FF), // Dodger blue
    ],
  );

  static const crystalGeode = TilePalette(
    name: 'Crystal Geode',
    colors: [
      Color(0xFF4B0082), // Indigo
      Color(0xFF9400D3), // Dark violet
      Color(0xFFBA55D3), // Medium orchid
      Color(0xFFE6E6FA), // Lavender
      Color(0xFF2F4F4F), // Dark slate gray (outer)
    ],
  );

  static const treeBark = TilePalette(
    name: 'Tree Bark',
    colors: [
      Color(0xFF3D2B1F), // Dark bark
      Color(0xFF5D4037), // Brown bark
      Color(0xFF795548), // Light bark
      Color(0xFF8D6E63), // Surface highlights
      Color(0xFF382C2C), // Deep crevices
    ],
  );

  static const mossStone = TilePalette(
    name: 'Mossy Stone',
    colors: [
      Color(0xFF556B2F), // Dark olive green
      Color(0xFF6B8E23), // Olive drab
      Color(0xFF808080), // Gray stone
      Color(0xFFA9A9A9), // Dark gray
      Color(0xFF2F4F4F), // Shadows
    ],
  );

  static const honeycomb = TilePalette(
    name: 'Honeycomb',
    colors: [
      Color(0xFFFFA500), // Orange
      Color(0xFFFFD700), // Gold
      Color(0xFFFFEC8B), // Light yellow
      Color(0xFF8B4513), // Saddle brown (walls)
      Color(0xFFCD853F), // Peru
    ],
  );

  static const autumnLeaves = TilePalette(
    name: 'Autumn Leaves',
    colors: [
      Color(0xFF8B0000), // Dark red
      Color(0xFFD2691E), // Chocolate
      Color(0xFFFF8C00), // Dark orange
      Color(0xFFDAA520), // Goldenrod
      Color(0xFF556B2F), // Dark olive green
    ],
  );
}

// ============================================================================
// ORGANIC/NATURE TILES
// ============================================================================

class VineOvergrownTile extends TileBase {
  VineOvergrownTile(super.id);

  @override
  String get name => 'Vine Overgrown';
  @override
  String get description => 'Platform covered with hanging vines and ivy';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.vineOvergrown;
  @override
  List<String> get tags => ['vine', 'nature', 'overgrown', 'green'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y * width + x] = colorToInt(palette.accent); // Wood base
      }
    }

    final vineCount = width ~/ 4;
    for (int v = 0; v < vineCount; v++) {
      int x = random.nextInt(width);
      int vineLen = height - random.nextInt(height ~/ 2);
      for (int y = 0; y < vineLen; y++) {
        if (x >= 0 && x < width) {
          pixels[y * width + x] = colorToInt(palette.primary);
          if (random.nextDouble() < 0.3) {
            // Leaf
            int lx = x + (random.nextBool() ? 1 : -1);
            if (lx >= 0 && lx < width) {
              pixels[y * width + lx] = colorToInt(palette.secondary);
            }
          }
        }
        x += (random.nextDouble() > 0.5 ? 1 : -1);
        x = x.clamp(0, width - 1);
      }
    }

    return pixels;
  }
}

class MushroomPlatformTile extends TileBase {
  MushroomPlatformTile(super.id);

  @override
  String get name => 'Mushroom Platform';
  @override
  String get description => 'Mushroom cap platform with spots';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.mushroom;
  @override
  List<String> get tags => ['mushroom', 'fungus', 'organic', 'platform'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    int capHeight = height * 2 ~/ 3;

    // Stem
    int stemWidth = width ~/ 3;
    int stemX = (width - stemWidth) ~/ 2;
    for (int y = capHeight; y < height; y++) {
      for (int x = stemX; x < stemX + stemWidth; x++) {
        pixels[y * width + x] = colorToInt(palette.highlight);
      }
    }

    // Cap
    for (int y = 0; y < capHeight; y++) {
      double t = y / capHeight;
      int w = (width * sin(t * pi)).toInt().clamp(2, width);
      int startX = (width - w) ~/ 2;
      for (int x = startX; x < startX + w; x++) {
        if (random.nextDouble() < 0.15) {
          pixels[y * width + x] = colorToInt(palette.accent); // Spots
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }

    return pixels;
  }
}

class CoralReefTile extends TileBase {
  CoralReefTile(super.id);

  @override
  String get name => 'Coral Reef';
  @override
  String get description => 'Underwater coral formation';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.coralReef;
  @override
  List<String> get tags => ['coral', 'reef', 'underwater', 'ocean'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    for (int i = 0; i < 5; i++) {
      int x = random.nextInt(width);
      int y = height - 1;
      Color c = palette.colors[random.nextInt(3)];

      for (int j = 0; j < 20; j++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          pixels[y * width + x] = colorToInt(c);
        }
        x += random.nextInt(3) - 1;
        y -= random.nextInt(2);
      }
    }

    return pixels;
  }
}

class CrystalGeodeTile extends TileBase {
  CrystalGeodeTile(super.id);

  @override
  String get name => 'Crystal Geode';
  @override
  String get description => 'Geode interior with crystals';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.crystalGeode;
  @override
  List<String> get tags => ['geode', 'crystal', 'gem', 'stone'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    int cx = width ~/ 2;
    int cy = height ~/ 2;
    int radius = min(width, height) ~/ 2 - 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double d = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        if (d > radius) {
          pixels[y * width + x] = colorToInt(palette.accent); // Outer rock
        } else if (d > radius - 2) {
          pixels[y * width + x] = colorToInt(palette.highlight); // Inner rim
        } else {
          if (random.nextDouble() < 0.4) {
            pixels[y * width + x] = colorToInt(palette.primary); // Dark crystals
          } else {
            pixels[y * width + x] = colorToInt(palette.secondary); // Light crystals
          }
        }
      }
    }

    return pixels;
  }
}

class TreeBarkTile extends TileBase {
  TreeBarkTile(super.id);

  @override
  String get name => 'Tree Bark';
  @override
  String get description => 'Natural wood bark texture';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.treeBark;
  @override
  List<String> get tags => ['bark', 'tree', 'wood', 'nature'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    for (int x = 0; x < width; x++) {
      double noise = 0;
      for (int y = 0; y < height; y++) {
        noise = (sin(x * 0.5) + random.nextDouble() * 0.5);
        if (noise > 0.8) {
          pixels[y * width + x] = colorToInt(palette.accent);
        } else if (noise > 0.4) {
          pixels[y * width + x] = colorToInt(palette.secondary);
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }

    return pixels;
  }
}

class MossStoneTile extends TileBase {
  MossStoneTile(super.id);

  @override
  String get name => 'Mossy Stone';
  @override
  String get description => 'Ancient stone covered with moss';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.mossStone;
  @override
  List<String> get tags => ['moss', 'stone', 'ancient', 'nature'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double n = random.nextDouble();
        if (n < 0.3) {
          pixels[y * width + x] = colorToInt(palette.primary); // Moss
        } else if (n < 0.6) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Light moss
        } else {
          pixels[y * width + x] = colorToInt(palette.highlight); // Stone
        }
      }
    }

    return pixels;
  }
}

class OrganicHoneycombTile extends TileBase {
  OrganicHoneycombTile(super.id);

  @override
  String get name => 'Honeycomb';
  @override
  String get description => 'Hexagonal honeycomb pattern';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.honeycomb;
  @override
  List<String> get tags => ['honeycomb', 'bee', 'organic', 'pattern'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Simple hex grid approximation
        if ((x % 4 == 0) || (y % 4 == 0)) {
          pixels[y * width + x] = colorToInt(palette.accent); // Outlines
        } else {
          pixels[y * width + x] = colorToInt(palette.secondary); // Honey
        }
      }
    }

    return pixels;
  }
}

class AutumnLeavesTile extends TileBase {
  AutumnLeavesTile(super.id);

  @override
  String get name => 'Autumn Leaves';
  @override
  String get description => 'Scattered autumn leaves';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => OrganicNaturePalettes.autumnLeaves;
  @override
  List<String> get tags => ['leaves', 'autumn', 'fall', 'nature'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);

    for (int i = 0; i < 30; i++) {
      int lx = random.nextInt(width);
      int ly = random.nextInt(height);
      Color c = palette.colors[random.nextInt(palette.colors.length)];

      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          int px = lx + dx;
          int py = ly + dy;
          if (px >= 0 && px < width && py >= 0 && py < height) {
            pixels[py * width + px] = colorToInt(c);
          }
        }
      }
    }

    return pixels;
  }
}
