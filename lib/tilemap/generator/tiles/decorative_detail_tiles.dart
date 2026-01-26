import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// DECORATIVE/DETAIL PALETTES
// ============================================================================

class DecorativePalettes {
  DecorativePalettes._();

  static const graffiti = TilePalette(
    name: 'Graffiti',
    colors: [
      Color(0xFFFF1744), // Red
      Color(0xFF00E676), // Green
      Color(0xFF2979FF), // Blue
      Color(0xFFD500F9), // Purple
      Color(0xFFFFFFFF), // White tags
    ],
  );

  static const chain = TilePalette(
    name: 'Chain/Rope',
    colors: [
      Color(0xFF757575), // Gray metal
      Color(0xFF9E9E9E), // Light gray
      Color(0xFF424242), // Dark gray
      Color(0xFF8D6E63), // Rope brown
      Color(0xFFA1887F), // Light rope
    ],
  );

  static const neonSign = TilePalette(
    name: 'Neon Sign',
    colors: [
      Color(0xFFFF00FF), // Magenta
      Color(0xFF00FFFF), // Cyan
      Color(0xFFFFFF00), // Yellow
      Color(0xFFFFFFFF), // Glow
      Color(0xFF212121), // Background
    ],
  );

  static const brickWall = TilePalette(
    name: 'Brick Wall',
    colors: [
      Color(0xFFB71C1C), // Deep red brick
      Color(0xFFC62828), // Red brick
      Color(0xFFD32F2F), // Light brick
      Color(0xFFE0E0E0), // Mortar
      Color(0xFF757575), // Dark accents
    ],
  );

  static const pipeSystem = TilePalette(
    name: 'Pipe System',
    colors: [
      Color(0xFF607D8B), // Steel blue
      Color(0xFF78909C), // Light steel
      Color(0xFF455A64), // Dark steel
      Color(0xFFF44336), // Valve red
      Color(0xFFFFEB3B), // Hazard yellow
    ],
  );

  static const stainedGlass = TilePalette(
    name: 'Stained Glass',
    colors: [
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFFFEB3B), // Yellow
    ],
  );

  static const ancientRuins = TilePalette(
    name: 'Ancient Ruins',
    colors: [
      Color(0xFFBDBDBD), // Ancient stone
      Color(0xFFE0E0E0), // Light stone
      Color(0xFF9E9E9E), // Dark stone
      Color(0xFF4E342E), // Dirt/roots
      Color(0xFF33691E), // Moss
    ],
  );

  static const circuitBoard = TilePalette(
    name: 'Circuit Board',
    colors: [
      Color(0xFF1B5E20), // Green board
      Color(0xFF4CAF50), // Light green
      Color(0xFFFFD600), // Gold traces
      Color(0xFFBDBDBD), // Solder
      Color(0xFF212121), // Chips
    ],
  );
}

// ============================================================================
// DECORATIVE/DETAIL TILES
// ============================================================================

class GraffitiTile extends TileBase {
  GraffitiTile(super.id);

  @override
  String get name => 'Graffiti';
  @override
  String get description => 'Street art style decoration';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'brush';
  @override
  TilePalette get palette => DecorativePalettes.graffiti;
  @override
  List<String> get tags => ['graffiti', 'art', 'urban', 'colors'];

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
      int y = random.nextInt(height);
      Color c = palette.colors[random.nextInt(palette.colors.length)];
      for (int r = 0; r < 4; r++) {
        int px = x + random.nextInt(5) - 2;
        int py = y + random.nextInt(5) - 2;
        if (px >= 0 && px < width && py >= 0 && py < height) {
          pixels[py * width + px] = colorToInt(c);
        }
      }
    }
    return pixels;
  }
}

class ChainTile extends TileBase {
  ChainTile(super.id);

  @override
  String get name => 'Chain';
  @override
  String get description => 'Hanging chain or rope decoration';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'link';
  @override
  TilePalette get palette => DecorativePalettes.chain;
  @override
  List<String> get tags => ['chain', 'rope', 'hanging', 'metal'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    int cx = width ~/ 2;
    for (int y = 0; y < height; y++) {
      if (y % 4 < 2) {
        pixels[y * width + cx] = colorToInt(palette.primary);
        if (cx + 1 < width) pixels[y * width + cx + 1] = colorToInt(palette.secondary);
      } else {
        pixels[y * width + cx] = colorToInt(palette.secondary);
      }
    }
    return pixels;
  }
}

class NeonSignTile extends TileBase {
  NeonSignTile(super.id);

  @override
  String get name => 'Neon Sign';
  @override
  String get description => 'Glowing neon sign decoration';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'lightbulb';
  @override
  TilePalette get palette => DecorativePalettes.neonSign;
  @override
  List<String> get tags => ['neon', 'glow', 'light', 'sign'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    Color c = palette.colors[random.nextInt(3)];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x == 4 || x == width - 5 || y == 4 || y == height - 5) {
          pixels[y * width + x] = colorToInt(c);
        } else {
          pixels[y * width + x] = colorToInt(palette.accent); // Backing
        }
      }
    }
    return pixels;
  }
}

class BrickWallTile extends TileBase {
  BrickWallTile(super.id);

  @override
  String get name => 'Brick Wall';
  @override
  String get description => 'Classic brick wall pattern';
  @override
  TileCategory get category => TileCategory.structure;
  @override
  String get iconName => 'grid_on';
  @override
  TilePalette get palette => DecorativePalettes.brickWall;
  @override
  List<String> get tags => ['brick', 'wall', 'structure', 'red'];

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
        bool isMortar = (y % 4 == 0) || ((x + (y ~/ 4 % 2) * 4) % 8 == 0);
        if (isMortar) {
          pixels[y * width + x] = colorToInt(palette.highlight);
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class PipeSystemTile extends TileBase {
  PipeSystemTile(super.id);

  @override
  String get name => 'Pipe System';
  @override
  String get description => 'Industrial pipe decoration';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'reorder';
  @override
  TilePalette get palette => DecorativePalettes.pipeSystem;
  @override
  List<String> get tags => ['pipe', 'industrial', 'metal', 'steam'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    int py = height ~/ 2;
    for (int x = 0; x < width; x++) {
      pixels[py * width + x] = colorToInt(palette.primary);
      if (py > 0) pixels[(py - 1) * width + x] = colorToInt(palette.secondary);
      if (py < height - 1) pixels[(py + 1) * width + x] = colorToInt(palette.secondary);
      if (x == width ~/ 2) {
        pixels[py * width + x] = colorToInt(palette.accent); // Valve
      }
    }
    return pixels;
  }
}

class StainedGlassTile extends TileBase {
  StainedGlassTile(super.id);

  @override
  String get name => 'Stained Glass';
  @override
  String get description => 'Colorful stained glass window';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'border_all';
  @override
  TilePalette get palette => DecorativePalettes.stainedGlass;
  @override
  List<String> get tags => ['glass', 'stained', 'church', 'colors'];

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
        if (x % 5 == 0 || y % 5 == 0) {
          pixels[y * width + x] = 0xFF000000; // Leading
        } else {
          pixels[y * width + x] = colorToInt(palette.colors[random.nextInt(5)]);
        }
      }
    }
    return pixels;
  }
}

class AncientRuinsTile extends TileBase {
  AncientRuinsTile(super.id);

  @override
  String get name => 'Ancient Ruins';
  @override
  String get description => 'Weathered ancient stone blocks';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  String get iconName => 'temple_hindu';
  @override
  TilePalette get palette => DecorativePalettes.ancientRuins;
  @override
  List<String> get tags => ['ruins', 'ancient', 'stone', 'moss'];

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
          pixels[y * width + x] = colorToInt(palette.accent); // Moss
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class DetailCircuitBoardTile extends TileBase {
  DetailCircuitBoardTile(super.id);

  @override
  String get name => 'Circuit Board';
  @override
  String get description => 'Electronic circuit board pattern';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  String get iconName => 'memory';
  @override
  TilePalette get palette => DecorativePalettes.circuitBoard;
  @override
  List<String> get tags => ['circuit', 'board', 'scifi', 'electronics'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    for (int i = 0; i < pixels.length; i++) pixels[i] = colorToInt(palette.primary);
    for (int i = 0; i < 5; i++) {
      int x = random.nextInt(width);
      int y = random.nextInt(height);
      for (int j = 0; j < width ~/ 2; j++) {
        if (x + j < width) pixels[y * width + x + j] = colorToInt(palette.highlight); // Traces
      }
    }
    return pixels;
  }
}
