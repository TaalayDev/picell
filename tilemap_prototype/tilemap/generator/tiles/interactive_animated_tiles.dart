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
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 120;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
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
    final pixels = Uint32List(width * height);
    // Arrow offset scrolls 2px per frame to simulate belt movement
    final arrowOffset = (frameIndex * 2) % 8;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (y < 2 || y > height - 3) {
          pixels[y * width + x] = colorToInt(palette.accent); // Tracks
        } else {
          pixels[y * width + x] = colorToInt(palette.primary); // Belt
          // Arrow markers scroll with frame
          if (((x + arrowOffset) % 8 < 2) && y > 4 && y < height - 5) {
            pixels[y * width + x] = colorToInt(palette.highlight);
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
    TileOrientation orientation = TileOrientation.none,
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
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 150;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
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
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    final wavePhase = frameIndex * pi / 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final surfaceWave = (sin(x / width * 2 * pi + wavePhase) * height * 0.08).round();
        final surfaceY = (height * 0.15 + surfaceWave).round().clamp(0, height - 1);
        if (y <= surfaceY) {
          pixels[y * width + x] = colorToInt(palette.highlight); // Wave crest
        } else if (y <= surfaceY + 2) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Sub-surface
        } else {
          // Bubble positions shift with frame
          final bubbleSeed = (x * 7 + y * 13 + frameIndex * 31) % 100;
          if (bubbleSeed < 4 && random.nextDouble() < 0.06) {
            pixels[y * width + x] = colorToInt(palette.secondary);
          } else {
            pixels[y * width + x] = colorToInt(palette.primary);
          }
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
  bool get animated => true;

  @override
  int get frameCount => 3;

  @override
  int get frameSpeed => 350;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
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
    final pixels = Uint32List(width * height);
    // LED cycles: 0=idle green, 1=warning yellow, 2=active red
    final ledColors = [palette.colors[4], palette.colors[3], palette.colors[3]];
    final ledColor = ledColors[frameIndex % 3];
    // Brightness pulse (frame 2 is full brightness)
    final ledBright = frameIndex == 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x < 2 || x > width - 3 || y < 2 || y > height - 3) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Border
        } else if (sqrt(pow(x - width ~/ 2, 2) + pow(y - height ~/ 2, 2)) < width ~/ 4) {
          // LED glow — slightly larger when active
          pixels[y * width + x] = colorToInt(ledColor);
        } else if (ledBright && sqrt(pow(x - width ~/ 2, 2) + pow(y - height ~/ 2, 2)) < width ~/ 3) {
          // Glow halo on active frame
          pixels[y * width + x] = colorToInt(Color.lerp(ledColor, palette.primary, 0.6)!);
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
    TileOrientation orientation = TileOrientation.none,
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
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 200;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
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
    // Amber indicator light that orbits the tile edge once per cycle
    final perimeterLen = 2 * (width + height) - 4;
    final ledPos = (frameIndex * (perimeterLen ~/ frameCount)) % perimeterLen;
    int lx, ly;
    if (ledPos < width) {
      lx = ledPos;
      ly = 0;
    } else if (ledPos < width + height - 1) {
      lx = width - 1;
      ly = ledPos - width + 1;
    } else if (ledPos < 2 * width + height - 2) {
      lx = width - 1 - (ledPos - width - height + 2);
      ly = height - 1;
    } else {
      lx = 0;
      ly = height - 1 - (ledPos - 2 * width - height + 3);
    }
    lx = lx.clamp(0, width - 1);
    ly = ly.clamp(0, height - 1);
    pixels[ly * width + lx] = colorToInt(palette.colors[4]);
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
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 250;

  @override
  Uint32List generate({
    required int width,
    required int height,
    TileOrientation orientation = TileOrientation.none,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
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
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    // Base goo fill
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = colorToInt(palette.primary);
    }
    // Drip blobs descend 2px per frame from fixed column positions
    final dripColumns = [width ~/ 5, width * 2 ~/ 5, width * 3 ~/ 5, width * 4 ~/ 5];
    for (int col = 0; col < dripColumns.length; col++) {
      final dripX = dripColumns[col];
      final dripY = (frameIndex * 2 + col * (height ~/ dripColumns.length)) % height;
      for (int dy = 0; dy < 3; dy++) {
        final py = (dripY + dy) % height;
        if (dripX >= 0 && dripX < width) {
          pixels[py * width + dripX] = colorToInt(palette.secondary);
          if (dripX + 1 < width) pixels[py * width + dripX + 1] = colorToInt(palette.secondary);
        }
      }
    }
    // Scattered static goo texture
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (random.nextDouble() < 0.08) {
          pixels[y * width + x] = colorToInt(palette.colors[2]);
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
    TileOrientation orientation = TileOrientation.none,
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
