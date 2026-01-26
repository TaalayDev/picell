import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// INTERACTIVE/ANIMATED PALETTES
// ============================================================================

class InteractivePalettes {
  InteractivePalettes._();

  static const conveyor = TilePalette(
    name: 'Conveyor Belt',
    colors: [
      Color(0xFF424242), // Dark gray
      Color(0xFF616161), // Med gray
      Color(0xFF757575), // Light gray
      Color(0xFFFFD600), // Warning yellow
      Color(0xFF212121), // Shadow
    ],
  );

  static const crumbling = TilePalette(
    name: 'Crumbling Platform',
    colors: [
      Color(0xFF8D6E63), // Brown
      Color(0xFFA1887F), // Light brown
      Color(0xFF5D4037), // Dark brown
      Color(0xFF3E2723), // Cracks
      Color(0xFFBDBDBD), // Dust
    ],
  );

  static const bouncyGel = TilePalette(
    name: 'Bouncy Gel',
    colors: [
      Color(0xFF00E5FF), // Cyan
      Color(0xFF18FFFF), // Bright cyan
      Color(0xFF00B8D4), // Dark cyan
      Color(0xFFFFFFFF), // Highlights
      Color(0xFF0091EA), // Deep blue
    ],
  );

  static const pressurePlate = TilePalette(
    name: 'Pressure Plate',
    colors: [
      Color(0xFF9E9E9E), // Steel
      Color(0xFFBDBDBD), // Light steel
      Color(0xFF757575), // Dark steel
      Color(0xFFFF5252), // Active red
      Color(0xFF4CAF50), // Idle green
    ],
  );

  static const ice = TilePalette(
    name: 'Ice Platform',
    colors: [
      Color(0xFFE1F5FE), // Very light blue
      Color(0xFFB3E5FC), // Light blue
      Color(0xFF81D4FA), // Med blue
      Color(0xFFFFFFFF), // Frost
      Color(0xFF01579B), // Deep ice
    ],
  );

  static const movingPlatform = TilePalette(
    name: 'Moving Platform',
    colors: [
      Color(0xFF455A64), // Blue gray
      Color(0xFF607D8B), // Light blue gray
      Color(0xFFB0BEC5), // Highlights
      Color(0xFF263238), // Dark shadows
      Color(0xFFFFC107), // Amber marks
    ],
  );

  static const stickyGoo = TilePalette(
    name: 'Sticky Goo',
    colors: [
      Color(0xFF64DD17), // Lime goo
      Color(0xFF76FF03), // Bright lime
      Color(0xFF33691E), // Dark goo
      Color(0xFFAEEA00), // Highlights
      Color(0xFF1B5E20), // Deep slime
    ],
  );

  static const breakableCrate = TilePalette(
    name: 'Breakable Crate',
    colors: [
      Color(0xFF795548), // Wood brown
      Color(0xFF8D6E63), // Light wood
      Color(0xFF5D4037), // Dark wood
      Color(0xFF3E2723), // Reinforcements
      Color(0xFFA52A2A), // Inside dark
    ],
  );
}

// ============================================================================
// INTERACTIVE/ANIMATED TILES
// ============================================================================

class ConveyorBeltTile extends TileBase {
  ConveyorBeltTile(super.id);

  @override
  String get name => 'Conveyor Belt';
  @override
  String get description => 'Moving conveyor with directional arrows';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'linear_scale';
  @override
  TilePalette get palette => InteractivePalettes.conveyor;
  @override
  List<String> get tags => ['conveyor', 'mechanical', 'trap', 'moving'];

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
        if (y < 2 || y > height - 3) {
          pixels[y * width + x] = colorToInt(palette.accent); // Tracks
        } else {
          pixels[y * width + x] = colorToInt(palette.primary); // Belt
          if ((x % 8 == 0) && y > 4 && y < height - 5) {
            pixels[y * width + x] = colorToInt(palette.highlight); // Arrows
          }
        }
      }
    }
    return pixels;
  }
}

class CrumblingPlatformTile extends TileBase {
  CrumblingPlatformTile(super.id);

  @override
  String get name => 'Crumbling Platform';
  @override
  String get description => 'Platform with cracks that breaks';
  @override
  TileCategory get category => TileCategory.platformer;
  @override
  String get iconName => 'broken_image';
  @override
  TilePalette get palette => InteractivePalettes.crumbling;
  @override
  List<String> get tags => ['crumbling', 'broken', 'trap', 'stone'];

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
        if (random.nextDouble() < 0.1) {
          pixels[y * width + x] = colorToInt(palette.accent); // Cracks
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class BouncyGelTile extends TileBase {
  BouncyGelTile(super.id);

  @override
  String get name => 'Bouncy Gel';
  @override
  String get description => 'Gel platform that bounces the player';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'bubble_chart';
  @override
  TilePalette get palette => InteractivePalettes.bouncyGel;
  @override
  List<String> get tags => ['gel', 'bouncy', 'slime', 'blue'];

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
        double dist = (y / height);
        if (dist < 0.2) {
          pixels[y * width + x] = colorToInt(palette.highlight); // Top glow
        } else if (random.nextDouble() < 0.05) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Bubbles
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class PressurePlateTile extends TileBase {
  PressurePlateTile(super.id);

  @override
  String get name => 'Pressure Plate';
  @override
  String get description => 'Activates when stepped on';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'radio_button_checked';
  @override
  TilePalette get palette => InteractivePalettes.pressurePlate;
  @override
  List<String> get tags => ['plate', 'switch', 'trap', 'metal'];

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
        if (x < 2 || x > width - 3 || y < 2 || y > height - 3) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Border
        } else if (sqrt(pow(x - width ~/ 2, 2) + pow(y - height ~/ 2, 2)) < width ~/ 4) {
          pixels[y * width + x] = colorToInt(palette.accent); // Light/LED
        } else {
          pixels[y * width + x] = colorToInt(palette.primary); // Plate
        }
      }
    }
    return pixels;
  }
}

class IcePlatformTile extends TileBase {
  IcePlatformTile(super.id);

  @override
  String get name => 'Ice Platform';
  @override
  String get description => 'Slippery ice surface';
  @override
  TileCategory get category => TileCategory.platformer;
  @override
  String get iconName => 'ac_unit';
  @override
  TilePalette get palette => InteractivePalettes.ice;
  @override
  List<String> get tags => ['ice', 'slippery', 'frozen', 'blue'];

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
        if (random.nextDouble() < 0.05) {
          pixels[y * width + x] = colorToInt(palette.shadow); // Inner cracks
        } else if (random.nextDouble() < 0.2) {
          pixels[y * width + x] = colorToInt(palette.highlight); // Frost
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class MovingPlatformTile extends TileBase {
  MovingPlatformTile(super.id);

  @override
  String get name => 'Moving Platform';
  @override
  String get description => 'Mechanized moving platform';
  @override
  TileCategory get category => TileCategory.platformer;
  @override
  String get iconName => 'settings';
  @override
  TilePalette get palette => InteractivePalettes.movingPlatform;
  @override
  List<String> get tags => ['moving', 'mechanical', 'platform', 'metal'];

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
        if (x % 4 == 0 || y % 4 == 0) {
          pixels[y * width + x] = colorToInt(palette.shadow); // Panel lines
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class StickyGooTile extends TileBase {
  StickyGooTile(super.id);

  @override
  String get name => 'Sticky Goo';
  @override
  String get description => 'Sticky substance that slows movement';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'opacity';
  @override
  TilePalette get palette => InteractivePalettes.stickyGoo;
  @override
  List<String> get tags => ['sticky', 'goo', 'slime', 'green'];

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
        if (random.nextDouble() < 0.3) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Goo drops
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class BreakableCrateTile extends TileBase {
  BreakableCrateTile(super.id);

  @override
  String get name => 'Breakable Crate';
  @override
  String get description => 'Wooden crate that breaks';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'inventory_2';
  @override
  TilePalette get palette => InteractivePalettes.breakableCrate;
  @override
  List<String> get tags => ['crate', 'wood', 'breakable', 'decoration'];

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
        if (x < 2 || x > width - 3 || y < 2 || y > height - 3 || x == y || x == width - y) {
          pixels[y * width + x] = colorToInt(palette.shadow); // Framing/Brace
        } else {
          pixels[y * width + x] = colorToInt(palette.primary); // Wood
        }
      }
    }
    return pixels;
  }
}
