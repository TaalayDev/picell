import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// MODULAR/CONNECTABLE PALETTES
// ============================================================================

class ModularPalettes {
  ModularPalettes._();

  static const edgeAware = TilePalette(
    name: 'Edge Aware',
    colors: [
      Color(0xFF37474F), // Dark gray
      Color(0xFF546E7A), // Med gray
      Color(0xFF1DE9B6), // Edge cyan
      Color(0xFF263238), // Deep gray
      Color(0xFFCFD8DC), // Highlight
    ],
  );

  static const puzzle = TilePalette(
    name: 'Puzzle Piece',
    colors: [
      Color(0xFF2196F3), // Blue
      Color(0xFFBBDEFB), // Light blue
      Color(0xFF0D47A1), // Dark blue
      Color(0xFFFFEB3B), // Yellow (tab)
      Color(0xFF000000), // Outline
    ],
  );

  static const tetris = TilePalette(
    name: 'Tetris Block',
    colors: [
      Color(0xFFF44336), // Red block
      Color(0xFF4CAF50), // Green block
      Color(0xFF2196F3), // Blue block
      Color(0xFFFFEB3B), // Yellow block
      Color(0xFFFFFFFF), // Highlight
    ],
  );

  static const connector = TilePalette(
    name: 'Connector Joint',
    colors: [
      Color(0xFF757575), // Metal
      Color(0xFFBDBDBD), // Light metal
      Color(0xFF424242), // Dark metal
      Color(0xFFE91E63), // Core pink
      Color(0xFF1A1A1A), // Background
    ],
  );

  static const rail = TilePalette(
    name: 'Rail Track',
    colors: [
      Color(0xFF8D6E63), // Tie brown
      Color(0xFF757575), // Rail gray
      Color(0xFFBDBDBD), // Rail highlight
      Color(0xFF3E2723), // Deep brown
      Color(0xFF212121), // Ballast
    ],
  );

  static const lego = TilePalette(
    name: 'Lego Brick',
    colors: [
      Color(0xFFFDD835), // Lego yellow
      Color(0xFFF44336), // Lego red
      Color(0xFF1E88E5), // Lego blue
      Color(0xFF43A047), // Lego green
      Color(0xFF1A1A1A), // Shadows
    ],
  );

  static const corridor = TilePalette(
    name: 'Modular Corridor',
    colors: [
      Color(0xFF37474F), // Wall gray
      Color(0xFF455A64), // Panel gray
      Color(0xFF00E5FF), // Light cyan
      Color(0xFF263238), // Inner dark
      Color(0xFF607D8B), // Surface detail
    ],
  );

  static const terrain = TilePalette(
    name: 'Auto-Terrain',
    colors: [
      Color(0xFF4CAF50), // Grass
      Color(0xFF8D6E63), // Dirt
      Color(0xFF5D4037), // Dark dirt
      Color(0xFFFBC02D), // Sand edge
      Color(0xFFC8E6C9), // Light grass
    ],
  );
}

// ============================================================================
// MODULAR/CONNECTABLE TILES
// ============================================================================

class EdgeAwareTile extends TileBase {
  EdgeAwareTile(super.id);

  @override
  String get name => 'Edge Aware';
  @override
  String get description => 'Platform that adapts edges based on neighbors';
  @override
  TileCategory get category => TileCategory.platformer;
  @override
  String get iconName => 'border_outer';
  @override
  TilePalette get palette => ModularPalettes.edgeAware;
  @override
  List<String> get tags => ['edge', 'aware', 'modular', 'smart'];

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
        if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
          pixels[y * width + x] = colorToInt(palette.secondary);
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class PuzzlePieceTile extends TileBase {
  PuzzlePieceTile(super.id);

  @override
  String get name => 'Puzzle Piece';
  @override
  String get description => 'Interlocking puzzle piece tile';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'extension';
  @override
  TilePalette get palette => ModularPalettes.puzzle;
  @override
  List<String> get tags => ['puzzle', 'piece', 'interlocking', 'blue'];

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
        if (sqrt(pow(x - cx, 2) + pow(y, 2)) < 3 || sqrt(pow(x - width, 2) + pow(y - cy, 2)) < 3) {
          pixels[y * width + x] = colorToInt(palette.accent); // Tabs
        } else {
          pixels[y * width + x] = colorToInt(palette.primary);
        }
      }
    }
    return pixels;
  }
}

class TetrisBlockTile extends TileBase {
  TetrisBlockTile(super.id);

  @override
  String get name => 'Tetris Block';
  @override
  String get description => 'Classic Tetris-style block';
  @override
  TileCategory get category => TileCategory.platformer;
  @override
  String get iconName => 'grid_view';
  @override
  TilePalette get palette => ModularPalettes.tetris;
  @override
  List<String> get tags => ['tetris', 'block', 'retro', 'colors'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    Color c = palette.colors[random.nextInt(4)];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x < 1 || x >= width - 1 || y < 1 || y >= height - 1) {
          pixels[y * width + x] = 0xFF000000;
        } else if (x < 3 && y < 3) {
          pixels[y * width + x] = colorToInt(palette.highlight); // Bevel
        } else {
          pixels[y * width + x] = colorToInt(c);
        }
      }
    }
    return pixels;
  }
}

class ConnectorJointTile extends TileBase {
  ConnectorJointTile(super.id);

  @override
  String get name => 'Connector Joint';
  @override
  String get description => 'Modular connector joint';
  @override
  TileCategory get category => TileCategory.special;
  @override
  String get iconName => 'hub';
  @override
  TilePalette get palette => ModularPalettes.connector;
  @override
  List<String> get tags => ['connector', 'joint', 'hub', 'metal'];

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
        if (sqrt(pow(x - cx, 2) + pow(y - cy, 2)) < 4) {
          pixels[y * width + x] = colorToInt(palette.primary);
        } else if (x == cx || y == cy) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Arms
        } else {
          pixels[y * width + x] = colorToInt(palette.accent);
        }
      }
    }
    return pixels;
  }
}

class RailTrackTile extends TileBase {
  RailTrackTile(super.id);

  @override
  String get name => 'Rail Track';
  @override
  String get description => 'Modular rail track system';
  @override
  TileCategory get category => TileCategory.platformer;
  @override
  String get iconName => 'railway_alert';
  @override
  TilePalette get palette => ModularPalettes.rail;
  @override
  List<String> get tags => ['rail', 'track', 'train', 'mining'];

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
        if (x == 4 || x == width - 5) {
          pixels[y * width + x] = colorToInt(palette.secondary); // Rails
        } else if (y % 6 == 0) {
          pixels[y * width + x] = colorToInt(palette.primary); // Ties
        } else {
          pixels[y * width + x] = colorToInt(palette.accent);
        }
      }
    }
    return pixels;
  }
}

class LegoBrickTile extends TileBase {
  LegoBrickTile(super.id);

  @override
  String get name => 'Lego Brick';
  @override
  String get description => 'Lego-style brick with studs';
  @override
  TileCategory get category => TileCategory.decoration;
  @override
  String get iconName => 'apps';
  @override
  TilePalette get palette => ModularPalettes.lego;
  @override
  List<String> get tags => ['lego', 'brick', 'toy', 'colors'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);
    final random = Random(seed);
    Color c = palette.colors[random.nextInt(4)];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (y < 3 && (x % 8 > 2 && x % 8 < 6)) {
          pixels[y * width + x] = colorToInt(c); // Studs
        } else if (y >= 3) {
          pixels[y * width + x] = colorToInt(c);
        } else {
          pixels[y * width + x] = 0x00000000;
        }
      }
    }
    return pixels;
  }
}

class ModularCorridorTile extends TileBase {
  ModularCorridorTile(super.id);

  @override
  String get name => 'Modular Corridor';
  @override
  String get description => 'Sci-fi modular corridor section';
  @override
  TileCategory get category => TileCategory.scifi;
  @override
  String get iconName => 'meeting_room';
  @override
  TilePalette get palette => ModularPalettes.corridor;
  @override
  List<String> get tags => ['corridor', 'scifi', 'panel', 'interior'];

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
        if (x < 2 || x >= width - 2 || y < 2 || y >= height - 2) {
          pixels[y * width + x] = colorToInt(palette.primary);
        } else {
          pixels[y * width + x] = colorToInt(palette.secondary);
        }
      }
    }
    return pixels;
  }
}

class AutoTilingTerrainTile extends TileBase {
  AutoTilingTerrainTile(super.id);

  @override
  String get name => 'Auto-Terrain';
  @override
  String get description => 'Smart terrain tile with auto-edges';
  @override
  TileCategory get category => TileCategory.terrain;
  @override
  String get iconName => 'landscape';
  @override
  TilePalette get palette => ModularPalettes.terrain;
  @override
  List<String> get tags => ['terrain', 'auto', 'smart', 'ground'];

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
        if (y < height ~/ 2) {
          pixels[y * width + x] = colorToInt(palette.primary); // Grass
        } else {
          pixels[y * width + x] = colorToInt(palette.secondary); // Dirt
        }
      }
    }
    return pixels;
  }
}
