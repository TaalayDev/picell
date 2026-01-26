import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// FANTASY/MAGIC PALETTES
// ============================================================================

class FantasyPalettes {
  FantasyPalettes._();

  static const runeCircle = TilePalette(
    name: 'Rune Circle',
    colors: [
      Color(0xFF6200EA), // Deep purple
      Color(0xFF7C4DFF), // Light purple
      Color(0xFFB39DDB), // Very light purple
      Color(0xFF00E5FF), // Magic cyan
      Color(0xFF212121), // Void
    ],
  );

  static const crystalGlow = TilePalette(
    name: 'Crystal Glow',
    colors: [
      Color(0xFF2979FF), // Bright blue
      Color(0xFF82B1FF), // Light blue
      Color(0xFFFFFFFF), // Glow
      Color(0xFF1A237E), // Deep sea blue
      Color(0xFF4FC3F7), // Crystal rim
    ],
  );

  static const elementalFire = TilePalette(
    name: 'Elemental Fire',
    colors: [
      Color(0xFFFF3D00), // Deep orange
      Color(0xFFFF9100), // Orange
      Color(0xFFFFEA00), // Yellow
      Color(0xFFBF360C), // Dark red
      Color(0xFF3E2723), // Embers
    ],
  );

  static const mysticPortal = TilePalette(
    name: 'Mystic Portal',
    colors: [
      Color(0xFF00B0FF), // Pure blue
      Color(0xFF00E5FF), // Bright cyan
      Color(0xFF18FFFF), // Lightest cyan
      Color(0xFF000000), // Center void
      Color(0xFF6236FF), // Edge transition
    ],
  );

  static const enchantedVines = TilePalette(
    name: 'Enchanted Vines',
    colors: [
      Color(0xFF00C853), // Magic green
      Color(0xFFB2FF59), // Light magic green
      Color(0xFFE91E63), // Glow pink
      Color(0xFF1B5E20), // Dark vine
      Color(0xFF00E676), // Bloom
    ],
  );

  static const dragonScale = TilePalette(
    name: 'Dragon Scale',
    colors: [
      Color(0xFF37474F), // Slate gray scale
      Color(0xFF546E7A), // Med scale
      Color(0xFF78909C), // Highlight
      Color(0xFF263238), // Dark shadow
      Color(0xFFBF360C), // Secondary color (belly)
    ],
  );

  static const holyLight = TilePalette(
    name: 'Holy Light',
    colors: [
      Color(0xFFFFD600), // Gold
      Color(0xFFFFF176), // Light gold
      Color(0xFFFFFFFF), // Pure light
      Color(0xFFFBC02D), // Dark gold
      Color(0xFF8D6E63), // Sacred stone
    ],
  );

  static const shadowRealm = TilePalette(
    name: 'Shadow Realm',
    colors: [
      Color(0xFF212121), // Black
      Color(0xFF424242), // Dark gray
      Color(0xFF616161), // Med gray
      Color(0xFF311B92), // Deep purple shadow
      Color(0xFF000000), // Void
    ],
  );
}

// ============================================================================
// FANTASY/MAGIC TILES
// ============================================================================

class MagicRuneCircleTile extends TileBase {
  MagicRuneCircleTile(super.id);

  @override
  String get name => 'Magic Rune Circle';
  @override
  String get description => 'Mystical rune circle with glowing symbols';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'auto_fix_high';
  @override
  TilePalette get palette => FantasyPalettes.runeCircle;
  @override
  List<String> get tags => ['rune', 'magic', 'circle', 'purple'];

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
    int r = width ~/ 3;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double d = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        if ((d - r).abs() < 1.0) {
          pixels[y * width + x] = colorToInt(palette.primary);
        } else if (d < r - 2 && random.nextDouble() < 0.1) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Rune markings
        } else {
          pixels[y * width + x] = colorToInt(palette.accent);
        }
      }
    }
    return pixels;
  }
}

class CrystalGlowTile extends TileBase {
  CrystalGlowTile(super.id);

  @override
  String get name => 'Crystal Glow';
  @override
  String get description => 'Glowing crystal formation';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'diamond';
  @override
  TilePalette get palette => FantasyPalettes.crystalGlow;
  @override
  List<String> get tags => ['crystal', 'glow', 'magic', 'blue'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    for (int i = 0; i < 3; i++) {
      int x = random.nextInt(width);
      int h = height ~/ 2 + random.nextInt(height ~/ 2);
      for (int y = height - 1; y > height - h; y--) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          pixels[y * width + x] = colorToInt(palette.primary);
          if (x + 1 < width) pixels[y * width + x + 1] = colorToInt(palette.secondary);
        }
      }
    }
    return pixels;
  }
}

class ElementalFireTile extends TileBase {
  ElementalFireTile(super.id);

  @override
  String get name => 'Elemental Fire';
  @override
  String get description => 'Burning elemental fire platform';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'fireplace';
  @override
  TilePalette get palette => FantasyPalettes.elementalFire;
  @override
  List<String> get tags => ['fire', 'elemental', 'burn', 'red'];

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
        double heat = (height - y) / height;
        if (random.nextDouble() < heat) {
          pixels[y * width + x] = colorToInt(palette.colors[random.nextInt(3)]);
        } else {
          pixels[y * width + x] = colorToInt(palette.accent);
        }
      }
    }
    return pixels;
  }
}

class MysticPortalTile extends TileBase {
  MysticPortalTile(super.id);

  @override
  String get name => 'Mystic Portal';
  @override
  String get description => 'Swirling magical portal';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'cyclone';
  @override
  TilePalette get palette => FantasyPalettes.mysticPortal;
  @override
  List<String> get tags => ['portal', 'mystic', 'gate', 'cyan'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    int cx = width ~/ 2;
    int cy = height ~/ 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double angle = atan2(y - cy, x - cx);
        double d = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        if (sin(d * 0.5 + angle).abs() < 0.2) {
          pixels[y * width + x] = colorToInt(palette.primary);
        } else {
          pixels[y * width + x] = colorToInt(palette.shadow);
        }
      }
    }
    return pixels;
  }
}

class EnchantedVinesTile extends TileBase {
  EnchantedVinesTile(super.id);

  @override
  String get name => 'Enchanted Vines';
  @override
  String get description => 'Magical glowing vines';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'nature';
  @override
  TilePalette get palette => FantasyPalettes.enchantedVines;
  @override
  List<String> get tags => ['vines', 'magic', 'enchanted', 'green'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    for (int i = 0; i < 4; i++) {
      int x = random.nextInt(width);
      for (int y = 0; y < height; y++) {
        if (x >= 0 && x < width) {
          pixels[y * width + x] = colorToInt(palette.primary);
          if (random.nextDouble() < 0.2) pixels[y * width + x] = colorToInt(palette.secondary); // Glow
        }
        x += random.nextInt(3) - 1;
        x = x.clamp(0, width - 1);
      }
    }
    return pixels;
  }
}

class DragonScaleTile extends TileBase {
  DragonScaleTile(super.id);

  @override
  String get name => 'Dragon Scale';
  @override
  String get description => 'Armored dragon scale pattern';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'layers';
  @override
  TilePalette get palette => FantasyPalettes.dragonScale;
  @override
  List<String> get tags => ['scales', 'dragon', 'armored', 'pattern'];

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
        int sx = x % 8;
        int sy = y % 8;
        if (sqrt(pow(sx - 4, 2) + pow(sy, 2)) < 4) {
          pixels[y * width + x] = colorToInt(palette.primary);
        } else {
          pixels[y * width + x] = colorToInt(palette.secondary);
        }
      }
    }
    return pixels;
  }
}

class HolyLightTile extends TileBase {
  HolyLightTile(super.id);

  @override
  String get name => 'Holy Light';
  @override
  String get description => 'Divine radiant light';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'wb_sunny';
  @override
  TilePalette get palette => FantasyPalettes.holyLight;
  @override
  List<String> get tags => ['light', 'holy', 'divine', 'gold'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    int cx = width ~/ 2;
    int cy = height ~/ 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double d = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        if (d < width ~/ 4) {
          pixels[y * width + x] = colorToInt(palette.highlight);
        } else if (((x - cx) - (y - cy)).abs() < 2 || ((x - cx) + (y - cy)).abs() < 2) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Rays
        } else {
          pixels[y * width + x] = colorToInt(palette.accent);
        }
      }
    }
    return pixels;
  }
}

class ShadowRealmTile extends TileBase {
  ShadowRealmTile(super.id);

  @override
  String get name => 'Shadow Realm';
  @override
  String get description => 'Dark shadow realm energy';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'brightness_3';
  @override
  TilePalette get palette => FantasyPalettes.shadowRealm;
  @override
  List<String> get tags => ['shadow', 'realm', 'dark', 'void'];

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
        if (random.nextDouble() < 0.2) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Wisps
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}
