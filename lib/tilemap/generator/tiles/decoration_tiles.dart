import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// DECORATION TILE PALETTES
// ============================================================================

class DecorationPalettes {
  DecorationPalettes._();

  // Furniture Palettes
  static const woodFurniture = TilePalette(
    name: 'Wood Furniture',
    colors: [
      Color(0xFF8B6914), // Base wood
      Color(0xFFAA8832), // Light wood
      Color(0xFF6A4A10), // Dark wood
      Color(0xFFCC9944), // Highlight
      Color(0xFF4A3008), // Shadow
    ],
  );

  static const metalFurniture = TilePalette(
    name: 'Metal Furniture',
    colors: [
      Color(0xFF7A7A8A), // Base metal
      Color(0xFF9A9AAA), // Light
      Color(0xFF5A5A6A), // Dark
      Color(0xFFBABACA), // Highlight
      Color(0xFF3A3A4A), // Shadow
    ],
  );

  // Container Palettes
  static const woodenCrate = TilePalette(
    name: 'Wooden Crate',
    colors: [
      Color(0xFF8B7355), // Base wood
      Color(0xFFA08868), // Light
      Color(0xFF6A5A45), // Dark
      Color(0xFFBBA080), // Highlight
      Color(0xFF4A3A25), // Shadow/nails
    ],
  );

  static const barrel = TilePalette(
    name: 'Barrel',
    colors: [
      Color(0xFF7A5A3A), // Wood
      Color(0xFF9A7A5A), // Light wood
      Color(0xFF5A4A2A), // Dark wood
      Color(0xFF4A4A5A), // Metal band
      Color(0xFF3A3A4A), // Dark band
    ],
  );

  static const chest = TilePalette(
    name: 'Chest',
    colors: [
      Color(0xFF6A4A2A), // Wood
      Color(0xFF8A6A4A), // Light wood
      Color(0xFFDAA520), // Gold trim
      Color(0xFFFFD700), // Gold highlight
      Color(0xFF3A2A1A), // Shadow
    ],
  );

  // Lighting Palettes
  static const torch = TilePalette(
    name: 'Torch',
    colors: [
      Color(0xFF5A4A3A), // Handle wood
      Color(0xFFFF6600), // Flame orange
      Color(0xFFFFAA00), // Flame yellow
      Color(0xFFFFDD66), // Flame highlight
      Color(0xFFCC3300), // Flame red
    ],
  );

  static const lantern = TilePalette(
    name: 'Lantern',
    colors: [
      Color(0xFF4A4A5A), // Metal frame
      Color(0xFFFFDD88), // Light glow
      Color(0xFFFFCC44), // Inner glow
      Color(0xFF6A6A7A), // Metal highlight
      Color(0xFF2A2A3A), // Shadow
    ],
  );

  static const candle = TilePalette(
    name: 'Candle',
    colors: [
      Color(0xFFEEDDCC), // Wax white
      Color(0xFFFFEEDD), // Light wax
      Color(0xFFFFAA44), // Flame
      Color(0xFFFFDD88), // Flame highlight
      Color(0xFFCCBBAA), // Wax shadow
    ],
  );

  // Decorative Objects
  static const pottery = TilePalette(
    name: 'Pottery',
    colors: [
      Color(0xFFAA6644), // Terra cotta
      Color(0xFFCC8866), // Light
      Color(0xFF884422), // Dark
      Color(0xFFEEAA88), // Highlight
      Color(0xFF662211), // Shadow
    ],
  );

  static const bookshelf = TilePalette(
    name: 'Bookshelf',
    colors: [
      Color(0xFF6A4A2A), // Wood
      Color(0xFF8A6A4A), // Light wood
      Color(0xFF4A2A0A), // Dark wood
      Color(0xFFCC4444), // Red book
      Color(0xFF4444AA), // Blue book
    ],
  );

  static const painting = TilePalette(
    name: 'Painting',
    colors: [
      Color(0xFF5A4A3A), // Frame
      Color(0xFF7A6A5A), // Light frame
      Color(0xFF3A2A1A), // Dark frame
      Color(0xFFDDAA66), // Gold frame
      Color(0xFFEEDDCC), // Canvas
    ],
  );

  static const rug = TilePalette(
    name: 'Rug',
    colors: [
      Color(0xFF8B2222), // Deep red
      Color(0xFFAA4444), // Light red
      Color(0xFF661111), // Dark red
      Color(0xFFDDAA44), // Gold pattern
      Color(0xFF4A1111), // Shadow
    ],
  );

  static const curtain = TilePalette(
    name: 'Curtain',
    colors: [
      Color(0xFF884422), // Burgundy
      Color(0xFFAA6644), // Light
      Color(0xFF662211), // Dark
      Color(0xFFDDAA66), // Gold trim
      Color(0xFF441100), // Shadow
    ],
  );

  // Signs and Labels
  static const woodSign = TilePalette(
    name: 'Wood Sign',
    colors: [
      Color(0xFF7A5A3A), // Wood
      Color(0xFF9A7A5A), // Light
      Color(0xFF5A3A1A), // Dark
      Color(0xFF2A2A2A), // Text
      Color(0xFF3A3A3A), // Post
    ],
  );

  static const metalSign = TilePalette(
    name: 'Metal Sign',
    colors: [
      Color(0xFF6A6A7A), // Metal
      Color(0xFF8A8A9A), // Light
      Color(0xFF4A4A5A), // Dark
      Color(0xFFFFFFFF), // Text
      Color(0xFF3A3A4A), // Post
    ],
  );

  // Weapons and Tools
  static const sword = TilePalette(
    name: 'Sword',
    colors: [
      Color(0xFFAABBCC), // Blade
      Color(0xFFCCDDEE), // Blade highlight
      Color(0xFF6A4A2A), // Handle
      Color(0xFFFFDD44), // Gold guard
      Color(0xFF4A5A6A), // Shadow
    ],
  );

  static const shield = TilePalette(
    name: 'Shield',
    colors: [
      Color(0xFF6A4A2A), // Wood base
      Color(0xFF8A6A4A), // Light wood
      Color(0xFF4A4A5A), // Metal rim
      Color(0xFFCC2222), // Emblem red
      Color(0xFF3A3A4A), // Shadow
    ],
  );

  // Food Items
  static const food = TilePalette(
    name: 'Food',
    colors: [
      Color(0xFFDDAA66), // Bread/pastry
      Color(0xFFEECC88), // Light
      Color(0xFFAA7744), // Crust
      Color(0xFFCC4444), // Fruit red
      Color(0xFF44AA44), // Vegetable green
    ],
  );

  // Bones and Skulls
  static const bones = TilePalette(
    name: 'Bones',
    colors: [
      Color(0xFFDDCCBB), // Bone white
      Color(0xFFEEDDCC), // Light
      Color(0xFFBBAA99), // Dark
      Color(0xFFFFEEDD), // Highlight
      Color(0xFF887766), // Shadow
    ],
  );

  // Gems and Treasures
  static const gems = TilePalette(
    name: 'Gems',
    colors: [
      Color(0xFFCC4444), // Ruby
      Color(0xFF44CC44), // Emerald
      Color(0xFF4444CC), // Sapphire
      Color(0xFFFFDD44), // Gold
      Color(0xFFCC44CC), // Amethyst
    ],
  );

  static const coins = TilePalette(
    name: 'Coins',
    colors: [
      Color(0xFFDDAA22), // Gold
      Color(0xFFFFCC44), // Gold highlight
      Color(0xFFAA8811), // Gold shadow
      Color(0xFFCCCCCC), // Silver
      Color(0xFFCC8844), // Copper
    ],
  );
}

// ============================================================================
// DECORATION TILE BASE
// ============================================================================

abstract class DecorationTile extends TileBase {
  DecorationTile(super.id);

  @override
  TileCategory get category => TileCategory.decoration;

  @override
  bool get supportsRotation => false;

  @override
  bool get supportsAutoTiling => false;
}

// ============================================================================
// CONTAINER TILES
// ============================================================================

/// Wooden crate
class WoodenCrateTile extends DecorationTile {
  final bool open;

  WoodenCrateTile(super.id, {this.open = false});

  @override
  String get name => open ? 'Open Crate' : 'Wooden Crate';
  @override
  String get description => 'Storage crate';
  @override
  String get iconName => 'inventory_2';
  @override
  TilePalette get palette => DecorationPalettes.woodenCrate;
  @override
  List<String> get tags => ['container', 'crate', 'storage', 'wood'];

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

    final margin = 1;
    final plankHeight = (height - margin * 2) ~/ 3;

    for (int y = margin; y < height - margin; y++) {
      for (int x = margin; x < width - margin; x++) {
        final isGap = (y - margin) % plankHeight == 0;
        final isVerticalBrace = x == width ~/ 2 || x == margin || x == width - margin - 1;

        if (isGap && !isVerticalBrace) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else if (isVerticalBrace) {
          pixels[y * width + x] = colorToInt(palette.colors[2]);
        } else {
          final noise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          final baseColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(baseColor, random, 0.05);
        }
      }
    }

    // Add nails at intersections
    for (int y = margin; y < height - margin; y += plankHeight) {
      pixels[y * width + margin + 1] = colorToInt(palette.shadow);
      pixels[y * width + width ~/ 2] = colorToInt(palette.shadow);
      pixels[y * width + width - margin - 2] = colorToInt(palette.shadow);
    }

    // Open crate shows dark inside
    if (open && height > 4) {
      for (int y = margin + 1; y < height ~/ 2; y++) {
        for (int x = margin + 2; x < width - margin - 2; x++) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        }
      }
    }

    return pixels;
  }
}

/// Barrel
class BarrelTile extends DecorationTile {
  final bool sideways;

  BarrelTile(super.id, {this.sideways = false});

  @override
  String get name => sideways ? 'Barrel (Sideways)' : 'Barrel';
  @override
  String get description => 'Wooden barrel';
  @override
  String get iconName => 'liquor';
  @override
  TilePalette get palette => DecorationPalettes.barrel;
  @override
  List<String> get tags => ['container', 'barrel', 'storage', 'wood'];

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

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double radiusX, radiusY;

        if (sideways) {
          // Horizontal barrel
          radiusX = width * 0.48;
          radiusY = height * 0.35 + sin((x - cx) / width * pi) * height * 0.1;
        } else {
          // Vertical barrel - bulge in middle
          radiusX = width * 0.35 + sin((y - cy) / height * pi) * width * 0.1;
          radiusY = height * 0.48;
        }

        final dx = (x - cx) / radiusX;
        final dy = (y - cy) / radiusY;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 1.0) {
          // Metal bands
          final bandPositions = sideways ? [0.15, 0.85] : [0.2, 0.8];
          final normPos = sideways ? (x / width) : (y / height);
          final isBand = bandPositions.any((bp) => (normPos - bp).abs() < 0.08);

          if (isBand) {
            final bandShade = dist < 0.7 ? palette.colors[3] : palette.colors[4];
            pixels[y * width + x] = colorToInt(bandShade);
          } else {
            // Wood planks
            final plankNoise = noise2D(x / 2.0 + seed, y / 3.0, 2);
            final woodColor = plankNoise > 0.5 ? palette.primary : palette.secondary;

            // 3D shading
            final light = -dx * 0.5 - dy * 0.3;
            Color finalColor;
            if (light > 0.3) {
              finalColor = palette.secondary;
            } else if (light < -0.3) {
              finalColor = palette.colors[2];
            } else {
              finalColor = woodColor;
            }

            pixels[y * width + x] = addNoise(finalColor, random, 0.05);
          }
        }
      }
    }

    return pixels;
  }
}

/// Treasure chest
class TreasureChestTile extends DecorationTile {
  final bool open;
  final bool mimic;

  TreasureChestTile(super.id, {this.open = false, this.mimic = false});

  @override
  String get name => mimic ? 'Mimic Chest' : (open ? 'Open Chest' : 'Treasure Chest');
  @override
  String get description => mimic ? 'A suspicious chest...' : 'Treasure container';
  @override
  String get iconName => 'cases';
  @override
  TilePalette get palette => DecorationPalettes.chest;
  @override
  List<String> get tags => ['container', 'chest', 'treasure', 'loot'];

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

    final lidHeight = open ? height ~/ 4 : height ~/ 3;
    final bodyTop = open ? 2 : lidHeight;

    // Draw body
    for (int y = bodyTop; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final isEdge = x == 1 || x == width - 2 || y == height - 2;
        if (isEdge) {
          pixels[y * width + x] = colorToInt(palette.shadow);
        } else {
          final noise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(woodColor, random, 0.04);
        }
      }
    }

    // Draw lid
    if (open) {
      // Lid is raised/tilted back
      for (int y = 0; y < lidHeight; y++) {
        for (int x = 2; x < width - 2; x++) {
          final noise = noise2D(x / 2.0 + seed * 2, y / 2.0, 2);
          final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(woodColor, random, 0.04);
        }
      }
      // Show gold inside
      for (int y = bodyTop + 1; y < bodyTop + 3; y++) {
        for (int x = 3; x < width - 3; x++) {
          if (y < height - 2) {
            pixels[y * width + x] = addNoise(palette.colors[3], random, 0.1);
          }
        }
      }
    } else {
      // Closed lid with curve
      for (int y = 0; y < lidHeight; y++) {
        final progress = y / lidHeight;
        final curveInset = (progress * progress * 2).toInt();
        for (int x = 1 + curveInset; x < width - 1 - curveInset; x++) {
          if (y == 0 || y == lidHeight - 1) {
            pixels[y * width + x] = colorToInt(palette.shadow);
          } else {
            final noise = noise2D(x / 2.0 + seed * 2, y / 2.0, 2);
            final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
            pixels[y * width + x] = addNoise(woodColor, random, 0.04);
          }
        }
      }
    }

    // Gold trim/lock
    final lockY = open ? bodyTop : lidHeight;
    pixels[lockY * width + width ~/ 2] = colorToInt(palette.colors[2]);
    pixels[lockY * width + width ~/ 2 - 1] = colorToInt(palette.colors[3]);
    pixels[lockY * width + width ~/ 2 + 1] = colorToInt(palette.colors[3]);

    // Mimic teeth
    if (mimic && open) {
      for (int x = 3; x < width - 3; x += 2) {
        pixels[bodyTop * width + x] = colorToInt(const Color(0xFFFFFFFF));
      }
    }

    return pixels;
  }
}

/// Pot/Vase
class PotTile extends DecorationTile {
  final bool broken;

  PotTile(super.id, {this.broken = false});

  @override
  String get name => broken ? 'Broken Pot' : 'Pot';
  @override
  String get description => 'Clay pottery';
  @override
  String get iconName => 'emoji_food_beverage';
  @override
  TilePalette get palette => DecorationPalettes.pottery;
  @override
  List<String> get tags => ['decoration', 'pot', 'pottery', 'container'];

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

    for (int y = 0; y < height; y++) {
      final progress = y / height;

      // Vase shape - narrow top, wide middle, narrow bottom
      double radiusMultiplier;
      if (progress < 0.15) {
        // Rim
        radiusMultiplier = 0.3;
      } else if (progress < 0.3) {
        // Neck
        radiusMultiplier = 0.25 + (progress - 0.15) * 2;
      } else if (progress < 0.7) {
        // Body
        radiusMultiplier = 0.55 + sin((progress - 0.3) / 0.4 * pi) * 0.15;
      } else {
        // Base
        radiusMultiplier = 0.5 - (progress - 0.7) * 1.2;
      }

      final radius = width * radiusMultiplier / 2;

      for (int x = 0; x < width; x++) {
        final dist = (x - cx).abs();

        if (dist < radius) {
          // 3D shading
          final normDist = dist / radius;
          Color col;
          if (normDist < 0.3) {
            col = palette.highlight;
          } else if (normDist < 0.6) {
            col = palette.secondary;
          } else if (normDist < 0.85) {
            col = palette.primary;
          } else {
            col = palette.colors[2];
          }

          // Broken effect
          if (broken && y < height * 0.4) {
            final breakNoise = noise2D(x / 2.0 + seed * 5, y / 2.0, 3);
            if (breakNoise > 0.5) continue;
          }

          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    }

    // Add rim highlight
    for (int x = 0; x < width; x++) {
      if (pixels[1 * width + x] != 0) {
        pixels[1 * width + x] = colorToInt(palette.highlight);
      }
    }

    return pixels;
  }
}

// ============================================================================
// LIGHTING TILES
// ============================================================================

/// Wall torch
class TorchTile extends DecorationTile {
  final bool lit;

  TorchTile(super.id, {this.lit = true});

  @override
  String get name => lit ? 'Torch (Lit)' : 'Torch (Unlit)';
  @override
  String get description => 'Wall-mounted torch';
  @override
  String get iconName => 'local_fire_department';
  @override
  TilePalette get palette => DecorationPalettes.torch;
  @override
  List<String> get tags => ['light', 'torch', 'fire', 'wall'];

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
    final handleTop = height ~/ 3;
    final handleWidth = max(2, width ~/ 4);

    // Draw handle
    for (int y = handleTop; y < height; y++) {
      for (int x = cx - handleWidth ~/ 2; x <= cx + handleWidth ~/ 2; x++) {
        if (x >= 0 && x < width) {
          final noise = noise2D(x.toDouble() + seed, y / 2.0, 2);
          final woodColor = noise > 0.5 ? palette.primary : palette.colors[2];
          pixels[y * width + x] = addNoise(woodColor, random, 0.05);
        }
      }
    }

    // Draw flame if lit
    if (lit) {
      final flameHeight = handleTop;
      final flameCx = cx.toDouble();

      for (int y = 0; y < flameHeight; y++) {
        final progress = y / flameHeight;
        final flameWidth = (1 - progress) * width * 0.4;

        for (int x = 0; x < width; x++) {
          final dist = (x - flameCx).abs();
          if (dist < flameWidth) {
            final flameNoise = noise2D(x / 2.0 + seed * 3, y / 2.0, 3);

            Color flameColor;
            if (progress < 0.3) {
              flameColor = palette.colors[3]; // White-yellow tip
            } else if (progress < 0.6) {
              flameColor = palette.colors[2]; // Yellow middle
            } else {
              flameColor = flameNoise > 0.5 ? palette.colors[1] : palette.colors[4]; // Orange/red base
            }

            if (flameNoise > 0.3) {
              pixels[y * width + x] = addNoise(flameColor, random, 0.1);
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Hanging lantern
class LanternTile extends DecorationTile {
  final bool lit;

  LanternTile(super.id, {this.lit = true});

  @override
  String get name => lit ? 'Lantern (Lit)' : 'Lantern (Unlit)';
  @override
  String get description => 'Hanging lantern';
  @override
  String get iconName => 'lightbulb';
  @override
  TilePalette get palette => DecorationPalettes.lantern;
  @override
  List<String> get tags => ['light', 'lantern', 'hanging'];

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

    // Hanging chain/hook
    for (int y = 0; y < height ~/ 4; y++) {
      pixels[y * width + cx] = colorToInt(palette.primary);
    }

    // Lantern body
    final lanternTop = height ~/ 4;
    final lanternBottom = height - 2;
    final lanternWidth = width * 0.6;

    for (int y = lanternTop; y < lanternBottom; y++) {
      final progress = (y - lanternTop) / (lanternBottom - lanternTop);

      // Tapered shape
      double widthMult;
      if (progress < 0.1) {
        widthMult = 0.5; // Top cap
      } else if (progress > 0.9) {
        widthMult = 0.6; // Bottom
      } else {
        widthMult = 1.0; // Body
      }

      final halfW = (lanternWidth * widthMult / 2).toInt();

      for (int x = cx - halfW; x <= cx + halfW; x++) {
        if (x >= 0 && x < width) {
          final isFrame = x == cx - halfW || x == cx + halfW || progress < 0.1 || progress > 0.9;

          if (isFrame) {
            pixels[y * width + x] = colorToInt(palette.primary);
          } else if (lit) {
            // Glowing interior
            final dist = (x - cx).abs() / halfW.toDouble();
            final glowColor = dist < 0.5 ? palette.colors[2] : palette.colors[1];
            pixels[y * width + x] = addNoise(glowColor, random, 0.08);
          } else {
            pixels[y * width + x] = colorToInt(palette.shadow);
          }
        }
      }
    }

    return pixels;
  }
}

/// Candle
class CandleTile extends DecorationTile {
  final bool inHolder;
  final bool lit;

  CandleTile(super.id, {this.inHolder = false, this.lit = true});

  @override
  String get name => inHolder ? 'Candle in Holder' : 'Candle';
  @override
  String get description => 'Wax candle';
  @override
  String get iconName => 'whatshot';
  @override
  TilePalette get palette => DecorationPalettes.candle;
  @override
  List<String> get tags => ['light', 'candle', 'flame'];

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
    final candleWidth = max(2, width ~/ 3);
    final candleTop = lit ? height ~/ 3 : height ~/ 4;
    final holderHeight = inHolder ? height ~/ 5 : 0;

    // Draw holder
    if (inHolder) {
      for (int y = height - holderHeight; y < height; y++) {
        final holderWidth = candleWidth + 2;
        for (int x = cx - holderWidth ~/ 2; x <= cx + holderWidth ~/ 2; x++) {
          if (x >= 0 && x < width) {
            pixels[y * width + x] = colorToInt(const Color(0xFF6A5A4A));
          }
        }
      }
    }

    // Draw candle body
    for (int y = candleTop; y < height - holderHeight; y++) {
      for (int x = cx - candleWidth ~/ 2; x <= cx + candleWidth ~/ 2; x++) {
        if (x >= 0 && x < width) {
          final isEdge = x == cx - candleWidth ~/ 2 || x == cx + candleWidth ~/ 2;
          final waxColor = isEdge ? palette.colors[4] : palette.primary;
          pixels[y * width + x] = addNoise(waxColor, random, 0.03);
        }
      }
    }

    // Draw wick
    pixels[candleTop * width + cx] = colorToInt(const Color(0xFF2A2A2A));

    // Draw flame
    if (lit && candleTop > 2) {
      final flameHeight = candleTop - 1;
      for (int y = 1; y < flameHeight; y++) {
        final progress = y / flameHeight;
        final flameWidth = max(1, ((1 - progress) * 3).toInt());

        for (int dx = -flameWidth; dx <= flameWidth; dx++) {
          final x = cx + dx;
          if (x >= 0 && x < width) {
            Color flameColor;
            if (progress < 0.4) {
              flameColor = palette.colors[3]; // Bright top
            } else if (progress < 0.7) {
              flameColor = palette.colors[2]; // Orange middle
            } else {
              flameColor = const Color(0xFFFF6600); // Red base
            }
            pixels[y * width + x] = colorToInt(flameColor);
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// FURNITURE TILES
// ============================================================================

/// Table
class TableTile extends DecorationTile {
  final bool small;

  TableTile(super.id, {this.small = false});

  @override
  String get name => small ? 'Small Table' : 'Table';
  @override
  String get description => 'Wooden table';
  @override
  String get iconName => 'table_restaurant';
  @override
  TilePalette get palette => DecorationPalettes.woodFurniture;
  @override
  List<String> get tags => ['furniture', 'table', 'wood'];

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

    final topHeight = max(2, height ~/ 4);
    final legWidth = max(1, width ~/ 6);

    // Table top
    for (int y = 0; y < topHeight; y++) {
      for (int x = 0; x < width; x++) {
        final isEdge = y == 0 || y == topHeight - 1;
        final noise = noise2D(x / 3.0 + seed, y.toDouble(), 2);
        Color woodColor;
        if (isEdge) {
          woodColor = palette.shadow;
        } else if (noise > 0.6) {
          woodColor = palette.highlight;
        } else if (noise > 0.3) {
          woodColor = palette.secondary;
        } else {
          woodColor = palette.primary;
        }
        pixels[y * width + x] = addNoise(woodColor, random, 0.04);
      }
    }

    // Table legs
    for (int y = topHeight; y < height; y++) {
      // Left leg
      for (int x = 1; x < 1 + legWidth; x++) {
        if (x < width) {
          pixels[y * width + x] = addNoise(palette.colors[2], random, 0.04);
        }
      }
      // Right leg
      for (int x = width - 1 - legWidth; x < width - 1; x++) {
        if (x >= 0) {
          pixels[y * width + x] = addNoise(palette.colors[2], random, 0.04);
        }
      }
    }

    return pixels;
  }
}

/// Chair
class ChairTile extends DecorationTile {
  ChairTile(super.id);

  @override
  String get name => 'Chair';
  @override
  String get description => 'Wooden chair';
  @override
  String get iconName => 'chair';
  @override
  TilePalette get palette => DecorationPalettes.woodFurniture;
  @override
  List<String> get tags => ['furniture', 'chair', 'wood', 'seat'];

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

    final backHeight = height ~/ 2;
    final seatY = backHeight;
    final seatHeight = 2;

    // Chair back
    for (int y = 0; y < backHeight; y++) {
      for (int x = 1; x < width - 1; x++) {
        final isFrame = x == 1 || x == width - 2 || y == 0;
        if (isFrame || (x > 2 && x < width - 3)) {
          final noise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(woodColor, random, 0.04);
        }
      }
    }

    // Seat
    for (int y = seatY; y < seatY + seatHeight; y++) {
      for (int x = 0; x < width; x++) {
        final noise = noise2D(x / 3.0 + seed, y.toDouble(), 2);
        final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
        pixels[y * width + x] = addNoise(woodColor, random, 0.04);
      }
    }

    // Legs
    for (int y = seatY + seatHeight; y < height; y++) {
      // Front legs
      pixels[y * width + 1] = addNoise(palette.colors[2], random, 0.04);
      pixels[y * width + width - 2] = addNoise(palette.colors[2], random, 0.04);
    }

    return pixels;
  }
}

/// Bookshelf
class BookshelfTile extends DecorationTile {
  BookshelfTile(super.id);

  @override
  String get name => 'Bookshelf';
  @override
  String get description => 'Shelf full of books';
  @override
  String get iconName => 'menu_book';
  @override
  TilePalette get palette => DecorationPalettes.bookshelf;
  @override
  List<String> get tags => ['furniture', 'bookshelf', 'books', 'library'];

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

    final shelfCount = 3;
    final shelfHeight = height ~/ shelfCount;

    // Draw frame
    for (int y = 0; y < height; y++) {
      pixels[y * width] = colorToInt(palette.colors[2]);
      pixels[y * width + width - 1] = colorToInt(palette.colors[2]);
    }

    // Draw shelves and books
    for (int shelf = 0; shelf < shelfCount; shelf++) {
      final shelfY = (shelf + 1) * shelfHeight - 1;

      // Shelf board
      if (shelfY < height) {
        for (int x = 0; x < width; x++) {
          pixels[shelfY * width + x] = colorToInt(palette.primary);
        }
      }

      // Books on shelf
      final bookStartY = shelf * shelfHeight + 1;
      final bookEndY = shelfY - 1;

      for (int x = 2; x < width - 2; x++) {
        final bookHeight = bookEndY - bookStartY - random.nextInt(2);
        final bookColor = random.nextBool() ? palette.colors[3] : palette.colors[4];

        for (int y = bookEndY - bookHeight; y < bookEndY; y++) {
          if (y >= 0 && y < height) {
            pixels[y * width + x] = addNoise(bookColor, random, 0.1);
          }
        }

        // Book spine line
        if (random.nextDouble() < 0.3 && bookEndY - 2 >= 0) {
          pixels[(bookEndY - 2) * width + x] = colorToInt(palette.highlight);
        }
      }
    }

    return pixels;
  }
}

/// Bed
class BedTile extends DecorationTile {
  BedTile(super.id);

  @override
  String get name => 'Bed';
  @override
  String get description => 'Comfortable bed';
  @override
  String get iconName => 'bed';
  @override
  TilePalette get palette => DecorationPalettes.rug;
  @override
  List<String> get tags => ['furniture', 'bed', 'sleep'];

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

    final headboardHeight = height ~/ 4;
    final bedHeight = height - headboardHeight;
    final pillowHeight = bedHeight ~/ 3;

    // Headboard
    for (int y = 0; y < headboardHeight; y++) {
      for (int x = 1; x < width - 1; x++) {
        final woodPal = DecorationPalettes.woodFurniture;
        final noise = noise2D(x / 2.0 + seed, y / 2.0, 2);
        final woodColor = noise > 0.5 ? woodPal.primary : woodPal.secondary;
        pixels[y * width + x] = addNoise(woodColor, random, 0.04);
      }
    }

    // Mattress/blanket
    for (int y = headboardHeight; y < height - 1; y++) {
      for (int x = 0; x < width; x++) {
        final isPillow = y < headboardHeight + pillowHeight && x > 1 && x < width - 2;

        if (isPillow) {
          pixels[y * width + x] = addNoise(const Color(0xFFEEEEDD), random, 0.03);
        } else {
          final noise = noise2D(x / 3.0 + seed, y / 3.0, 2);
          final blanketColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(blanketColor, random, 0.04);
        }
      }
    }

    // Bed frame bottom
    for (int x = 0; x < width; x++) {
      pixels[(height - 1) * width + x] = colorToInt(DecorationPalettes.woodFurniture.shadow);
    }

    return pixels;
  }
}

// ============================================================================
// WALL DECORATION TILES
// ============================================================================

/// Painting/Picture frame
class PaintingTile extends DecorationTile {
  final int style;

  PaintingTile(super.id, {this.style = 0});

  @override
  String get name => 'Painting';
  @override
  String get description => 'Framed artwork';
  @override
  String get iconName => 'image';
  @override
  TilePalette get palette => DecorationPalettes.painting;
  @override
  List<String> get tags => ['decoration', 'painting', 'art', 'wall'];

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

    final frameWidth = 2;

    // Draw frame
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isFrame = x < frameWidth || x >= width - frameWidth || y < frameWidth || y >= height - frameWidth;

        if (isFrame) {
          final isOuter = x == 0 || x == width - 1 || y == 0 || y == height - 1;
          final frameColor = isOuter ? palette.shadow : palette.colors[3];
          pixels[y * width + x] = colorToInt(frameColor);
        } else {
          // Canvas content based on style
          final cx = (x - frameWidth) / (width - frameWidth * 2);
          final cy = (y - frameWidth) / (height - frameWidth * 2);

          Color canvasColor;
          final paintSeed = seed + style;

          switch (style % 4) {
            case 0: // Landscape
              if (cy < 0.4) {
                canvasColor = const Color(0xFF87CEEB); // Sky
              } else if (cy < 0.5) {
                canvasColor = const Color(0xFF228B22); // Tree line
              } else {
                canvasColor = const Color(0xFF90EE90); // Grass
              }
              break;
            case 1: // Portrait (abstract face)
              final dist = sqrt(pow(cx - 0.5, 2) + pow(cy - 0.4, 2));
              if (dist < 0.3) {
                canvasColor = const Color(0xFFFFDAAA); // Face
              } else {
                canvasColor = const Color(0xFF8B4513); // Background
              }
              break;
            case 2: // Abstract
              final noise = noise2D(x / 3.0 + paintSeed, y / 3.0, 3);
              canvasColor = Color.lerp(
                const Color(0xFFFF6B6B),
                const Color(0xFF4ECDC4),
                noise,
              )!;
              break;
            default: // Still life
              canvasColor = palette.colors[4]; // Canvas base
          }

          pixels[y * width + x] = addNoise(canvasColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

/// Wall banner/tapestry
class BannerTile extends DecorationTile {
  final Color? bannerColor;

  BannerTile(super.id, {this.bannerColor});

  @override
  String get name => 'Banner';
  @override
  String get description => 'Hanging banner';
  @override
  String get iconName => 'flag';
  @override
  TilePalette get palette => DecorationPalettes.curtain;
  @override
  List<String> get tags => ['decoration', 'banner', 'flag', 'wall'];

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

    final mainColor = bannerColor ?? palette.primary;
    final cx = width / 2;

    // Hanging rod
    for (int x = 1; x < width - 1; x++) {
      pixels[x] = colorToInt(DecorationPalettes.metalFurniture.primary);
    }

    // Banner body with tapered bottom
    for (int y = 1; y < height; y++) {
      final progress = y / height;
      final taperAmount = progress > 0.7 ? (progress - 0.7) / 0.3 * width * 0.3 : 0;

      for (int x = 0; x < width; x++) {
        final distFromCenter = (x - cx).abs();

        if (distFromCenter < width / 2 - taperAmount) {
          // Wave effect
          final wave = sin(y / 3.0 + seed) * 0.1;
          final shade = distFromCenter / (width / 2) + wave;

          Color col;
          if (shade < 0.3) {
            col = Color.lerp(mainColor, Colors.white, 0.2)!;
          } else if (shade > 0.7) {
            col = Color.lerp(mainColor, Colors.black, 0.3)!;
          } else {
            col = mainColor;
          }

          pixels[y * width + x] = addNoise(col, random, 0.04);
        }
      }
    }

    // Gold trim
    for (int y = 1; y < height - 2; y++) {
      if (pixels[y * width + 1] != 0) {
        pixels[y * width + 1] = colorToInt(palette.colors[3]);
      }
      if (pixels[y * width + width - 2] != 0) {
        pixels[y * width + width - 2] = colorToInt(palette.colors[3]);
      }
    }

    return pixels;
  }
}

/// Rug/carpet
class RugTile extends DecorationTile {
  final bool ornate;

  RugTile(super.id, {this.ornate = false});

  @override
  String get name => ornate ? 'Ornate Rug' : 'Rug';
  @override
  String get description => 'Floor rug';
  @override
  String get iconName => 'dashboard';
  @override
  TilePalette get palette => DecorationPalettes.rug;
  @override
  List<String> get tags => ['decoration', 'rug', 'carpet', 'floor'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    final borderWidth = ornate ? 2 : 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final distFromEdge = [x, width - 1 - x, y, height - 1 - y].reduce(min);

        Color col;
        if (distFromEdge < borderWidth) {
          col = palette.colors[3]; // Gold border
        } else if (ornate && distFromEdge == borderWidth) {
          col = palette.shadow; // Inner border line
        } else {
          // Pattern
          if (ornate) {
            final patternX = (x - borderWidth) % 4;
            final patternY = (y - borderWidth) % 4;
            if ((patternX == 1 || patternX == 2) && (patternY == 1 || patternY == 2)) {
              col = palette.colors[3]; // Diamond pattern
            } else {
              col = palette.primary;
            }
          } else {
            final noise = noise2D(x / 2.0 + seed, y / 2.0, 2);
            col = noise > 0.5 ? palette.primary : palette.secondary;
          }
        }

        pixels[y * width + x] = addNoise(col, random, 0.04);
      }
    }

    return pixels;
  }
}

// ============================================================================
// SIGN TILES
// ============================================================================

/// Wooden sign
class WoodSignTile extends DecorationTile {
  final bool hanging;

  WoodSignTile(super.id, {this.hanging = false});

  @override
  String get name => hanging ? 'Hanging Sign' : 'Wood Sign';
  @override
  String get description => 'Wooden signpost';
  @override
  String get iconName => 'signpost';
  @override
  TilePalette get palette => DecorationPalettes.woodSign;
  @override
  List<String> get tags => ['sign', 'wood', 'text'];

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

    if (hanging) {
      // Chain/rope at top
      final cx = width ~/ 2;
      for (int y = 0; y < height ~/ 4; y++) {
        pixels[y * width + cx] = colorToInt(palette.colors[4]);
      }

      // Sign board
      final signTop = height ~/ 4;
      for (int y = signTop; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final noise = noise2D(x / 3.0 + seed, y / 2.0, 2);
          final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(woodColor, random, 0.05);
        }
      }

      // Border
      for (int x = 1; x < width - 1; x++) {
        pixels[signTop * width + x] = colorToInt(palette.colors[2]);
        pixels[(height - 2) * width + x] = colorToInt(palette.colors[2]);
      }
    } else {
      // Standing sign with post
      final signHeight = height * 2 ~/ 3;
      final postWidth = max(2, width ~/ 4);
      final cx = width ~/ 2;

      // Post
      for (int y = signHeight; y < height; y++) {
        for (int x = cx - postWidth ~/ 2; x <= cx + postWidth ~/ 2; x++) {
          if (x >= 0 && x < width) {
            pixels[y * width + x] = colorToInt(palette.colors[4]);
          }
        }
      }

      // Sign board
      for (int y = 1; y < signHeight; y++) {
        for (int x = 0; x < width; x++) {
          final noise = noise2D(x / 3.0 + seed, y / 2.0, 2);
          final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
          pixels[y * width + x] = addNoise(woodColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// TREASURE AND LOOT TILES
// ============================================================================

/// Coin pile
class CoinPileTile extends DecorationTile {
  final bool large;

  CoinPileTile(super.id, {this.large = false});

  @override
  String get name => large ? 'Large Coin Pile' : 'Coin Pile';
  @override
  String get description => 'Pile of gold coins';
  @override
  String get iconName => 'paid';
  @override
  TilePalette get palette => DecorationPalettes.coins;
  @override
  List<String> get tags => ['treasure', 'coins', 'gold', 'loot'];

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

    final pileHeight = large ? height * 0.7 : height * 0.5;
    final cx = width / 2;

    // Draw pile shape
    for (int y = 0; y < height; y++) {
      final fromBottom = height - y;
      if (fromBottom > pileHeight) continue;

      final progress = fromBottom / pileHeight;
      final pileWidth = progress * width * 0.9;

      for (int x = 0; x < width; x++) {
        final dist = (x - cx).abs();
        if (dist < pileWidth / 2) {
          // Draw coins
          final coinNoise = noise2D(x / 2.0 + seed, y / 2.0, 3);
          Color coinColor;

          if (coinNoise > 0.7) {
            coinColor = palette.colors[1]; // Highlight
          } else if (coinNoise > 0.4) {
            coinColor = palette.primary; // Gold
          } else if (coinNoise > 0.2) {
            coinColor = palette.colors[2]; // Shadow
          } else if (random.nextDouble() < 0.1) {
            coinColor = palette.colors[3]; // Silver
          } else {
            coinColor = palette.primary;
          }

          pixels[y * width + x] = addNoise(coinColor, random, 0.08);
        }
      }
    }

    return pixels;
  }
}

/// Gem/jewel
class GemTile extends DecorationTile {
  final int gemType; // 0=ruby, 1=emerald, 2=sapphire, 3=amethyst

  GemTile(super.id, {this.gemType = 0});

  @override
  String get name {
    switch (gemType) {
      case 0:
        return 'Ruby';
      case 1:
        return 'Emerald';
      case 2:
        return 'Sapphire';
      case 3:
        return 'Amethyst';
      default:
        return 'Gem';
    }
  }

  @override
  String get description => 'Precious gemstone';
  @override
  String get iconName => 'diamond';
  @override
  TilePalette get palette => DecorationPalettes.gems;
  @override
  List<String> get tags => ['treasure', 'gem', 'jewel', 'loot'];

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

    final baseColor = palette.colors[gemType];
    final cx = width / 2;
    final cy = height / 2;

    // Diamond/gem shape
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Create octagonal gem shape
        final dx = (x - cx).abs();
        final dy = (y - cy).abs();
        final dist = dx + dy;

        if (dist < (width + height) / 4) {
          // Faceted shading
          final facetAngle = atan2(y - cy, x - cx);
          final facetIdx = ((facetAngle + pi) / (pi / 4)).floor() % 8;

          Color gemColor;
          if (facetIdx % 2 == 0) {
            gemColor = Color.lerp(baseColor, Colors.white, 0.3)!;
          } else {
            gemColor = Color.lerp(baseColor, Colors.black, 0.2)!;
          }

          // Central highlight
          if (dx < width / 6 && dy < height / 6) {
            gemColor = Color.lerp(baseColor, Colors.white, 0.5)!;
          }

          pixels[y * width + x] = addNoise(gemColor, random, 0.05);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// BONES AND REMAINS TILES
// ============================================================================

/// Skull
class SkullTile extends DecorationTile {
  SkullTile(super.id);

  @override
  String get name => 'Skull';
  @override
  String get description => 'Skeletal skull';
  @override
  String get iconName => 'sentiment_very_dissatisfied';
  @override
  TilePalette get palette => DecorationPalettes.bones;
  @override
  List<String> get tags => ['bones', 'skull', 'skeleton', 'death'];

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
    final cy = height * 0.45;

    // Skull shape (oval)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / (width * 0.4);
        final dy = (y - cy) / (height * 0.45);
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 1.0) {
          // Bone color with shading
          final light = -dx * 0.5 - dy * 0.3;
          Color boneColor;
          if (light > 0.3) {
            boneColor = palette.highlight;
          } else if (light > 0) {
            boneColor = palette.secondary;
          } else if (light > -0.3) {
            boneColor = palette.primary;
          } else {
            boneColor = palette.colors[2];
          }

          pixels[y * width + x] = addNoise(boneColor, random, 0.04);
        }
      }
    }

    // Eye sockets
    final eyeY = (cy - height * 0.1).toInt();
    final eyeSpacing = width ~/ 4;
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final leftEyeX = (cx - eyeSpacing).toInt() + dx;
        final rightEyeX = (cx + eyeSpacing).toInt() + dx;
        final ey = eyeY + dy;
        if (ey >= 0 && ey < height) {
          if (leftEyeX >= 0 && leftEyeX < width) {
            pixels[ey * width + leftEyeX] = colorToInt(palette.shadow);
          }
          if (rightEyeX >= 0 && rightEyeX < width) {
            pixels[ey * width + rightEyeX] = colorToInt(palette.shadow);
          }
        }
      }
    }

    // Nose hole
    final noseY = (cy + height * 0.05).toInt();
    if (noseY < height && cx.toInt() < width) {
      pixels[noseY * width + cx.toInt()] = colorToInt(palette.shadow);
    }

    // Teeth
    final teethY = (cy + height * 0.25).toInt();
    if (teethY < height) {
      for (int x = (cx - width * 0.2).toInt(); x < (cx + width * 0.2).toInt(); x++) {
        if (x >= 0 && x < width && x % 2 == 0) {
          pixels[teethY * width + x] = colorToInt(palette.highlight);
        }
      }
    }

    return pixels;
  }
}

/// Bone pile
class BonePileTile extends DecorationTile {
  BonePileTile(super.id);

  @override
  String get name => 'Bone Pile';
  @override
  String get description => 'Scattered bones';
  @override
  String get iconName => 'pets';
  @override
  TilePalette get palette => DecorationPalettes.bones;
  @override
  List<String> get tags => ['bones', 'skeleton', 'pile', 'death'];

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

    // Draw scattered bones
    final boneCount = 5 + random.nextInt(4);
    for (int b = 0; b < boneCount; b++) {
      final bx = random.nextInt(width - 4) + 2;
      final by = random.nextInt(height ~/ 2) + height ~/ 2;
      final boneLen = 3 + random.nextInt(3);
      final horizontal = random.nextBool();

      for (int i = 0; i < boneLen; i++) {
        int px, py;
        if (horizontal) {
          px = bx + i;
          py = by;
        } else {
          px = bx;
          py = by - i;
        }

        if (px >= 0 && px < width && py >= 0 && py < height) {
          final boneColor = random.nextDouble() < 0.3 ? palette.highlight : palette.primary;
          pixels[py * width + px] = addNoise(boneColor, random, 0.05);

          // Bone ends (knobs)
          if (i == 0 || i == boneLen - 1) {
            if (horizontal) {
              if (py > 0) pixels[(py - 1) * width + px] = addNoise(palette.secondary, random, 0.05);
              if (py < height - 1) pixels[(py + 1) * width + px] = addNoise(palette.secondary, random, 0.05);
            } else {
              if (px > 0) pixels[py * width + px - 1] = addNoise(palette.secondary, random, 0.05);
              if (px < width - 1) pixels[py * width + px + 1] = addNoise(palette.secondary, random, 0.05);
            }
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// WEAPON RACK TILES
// ============================================================================

/// Weapon rack with swords
class WeaponRackTile extends DecorationTile {
  WeaponRackTile(super.id);

  @override
  String get name => 'Weapon Rack';
  @override
  String get description => 'Rack holding weapons';
  @override
  String get iconName => 'construction';
  @override
  TilePalette get palette => DecorationPalettes.sword;
  @override
  List<String> get tags => ['weapon', 'rack', 'sword', 'armory'];

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

    final woodPal = DecorationPalettes.woodFurniture;

    // Back board
    for (int y = 0; y < height; y++) {
      for (int x = 1; x < width - 1; x++) {
        final noise = noise2D(x / 3.0 + seed, y / 2.0, 2);
        final woodColor = noise > 0.5 ? woodPal.primary : woodPal.secondary;
        pixels[y * width + x] = addNoise(woodColor, random, 0.04);
      }
    }

    // Horizontal pegs
    final pegY1 = height ~/ 3;
    final pegY2 = 2 * height ~/ 3;
    for (int x = 2; x < width - 2; x++) {
      pixels[pegY1 * width + x] = colorToInt(woodPal.shadow);
      pixels[pegY2 * width + x] = colorToInt(woodPal.shadow);
    }

    // Swords (vertical)
    final swordCount = 2;
    for (int s = 0; s < swordCount; s++) {
      final sx = width ~/ 3 + s * width ~/ 3;

      // Blade
      for (int y = 2; y < height - 2; y++) {
        if (y < pegY2) {
          pixels[y * width + sx] = addNoise(palette.primary, random, 0.03);
        }
      }

      // Handle
      for (int y = pegY2; y < height - 1; y++) {
        pixels[y * width + sx] = colorToInt(palette.colors[2]);
      }

      // Guard
      if (pegY2 - 1 >= 0 && pegY2 - 1 < height) {
        if (sx > 0) pixels[(pegY2 - 1) * width + sx - 1] = colorToInt(palette.colors[3]);
        if (sx < width - 1) pixels[(pegY2 - 1) * width + sx + 1] = colorToInt(palette.colors[3]);
      }
    }

    return pixels;
  }
}

/// Shield on wall
class WallShieldTile extends DecorationTile {
  WallShieldTile(super.id);

  @override
  String get name => 'Wall Shield';
  @override
  String get description => 'Shield mounted on wall';
  @override
  String get iconName => 'shield';
  @override
  TilePalette get palette => DecorationPalettes.shield;
  @override
  List<String> get tags => ['weapon', 'shield', 'wall', 'armor'];

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

    // Shield shape (pointed oval)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / (width * 0.45);
        final dy = (y - cy) / (height * 0.5);

        // Pointed bottom
        final pointFactor = y > cy ? 1.0 + (y - cy) / height * 0.5 : 1.0;
        final dist = sqrt(dx * dx * pointFactor + dy * dy);

        if (dist < 1.0) {
          // Metal rim
          if (dist > 0.85) {
            pixels[y * width + x] = colorToInt(palette.colors[2]);
          } else {
            // Wood base with emblem
            final emblemDist = sqrt(pow(dx, 2) + pow(dy + 0.1, 2));
            if (emblemDist < 0.3) {
              pixels[y * width + x] = colorToInt(palette.colors[3]); // Red emblem
            } else {
              final noise = noise2D(x / 3.0 + seed, y / 3.0, 2);
              final woodColor = noise > 0.5 ? palette.primary : palette.secondary;
              pixels[y * width + x] = addNoise(woodColor, random, 0.04);
            }
          }
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// FOOD AND CONSUMABLE TILES
// ============================================================================

/// Food plate
class FoodPlateTile extends DecorationTile {
  FoodPlateTile(super.id);

  @override
  String get name => 'Food Plate';
  @override
  String get description => 'Plate with food';
  @override
  String get iconName => 'restaurant';
  @override
  TilePalette get palette => DecorationPalettes.food;
  @override
  List<String> get tags => ['food', 'plate', 'tavern'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height / 2;

    // Plate (ellipse)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = (x - cx) / (width * 0.45);
        final dy = (y - cy) / (height * 0.35);
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 1.0) {
          // Plate rim
          if (dist > 0.8) {
            pixels[y * width + x] = colorToInt(const Color(0xFFCCCCCC));
          } else {
            // Food items
            final foodNoise = noise2D(x / 2.0 + seed, y / 2.0, 3);
            if (foodNoise > 0.6) {
              pixels[y * width + x] = colorToInt(palette.colors[3]); // Meat/red
            } else if (foodNoise > 0.4) {
              pixels[y * width + x] = colorToInt(palette.primary); // Bread
            } else if (foodNoise > 0.2) {
              pixels[y * width + x] = colorToInt(palette.colors[4]); // Vegetable
            } else {
              pixels[y * width + x] = colorToInt(const Color(0xFFEEEEEE)); // Plate
            }
          }
        }
      }
    }

    return pixels;
  }
}

/// Mug/tankard
class MugTile extends DecorationTile {
  final bool full;

  MugTile(super.id, {this.full = true});

  @override
  String get name => full ? 'Full Mug' : 'Empty Mug';
  @override
  String get description => 'Drinking mug';
  @override
  String get iconName => 'local_bar';
  @override
  TilePalette get palette => DecorationPalettes.woodFurniture;
  @override
  List<String> get tags => ['drink', 'mug', 'tavern'];

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

    final mugWidth = width * 0.6;
    final mugLeft = (width - mugWidth) ~/ 2;
    final mugRight = mugLeft + mugWidth.toInt();

    // Mug body
    for (int y = 1; y < height - 1; y++) {
      for (int x = mugLeft; x < mugRight; x++) {
        if (x >= 0 && x < width) {
          final isEdge = x == mugLeft || x == mugRight - 1;
          final mugColor = isEdge ? palette.colors[2] : palette.primary;
          pixels[y * width + x] = addNoise(mugColor, random, 0.05);
        }
      }
    }

    // Rim
    for (int x = mugLeft; x < mugRight; x++) {
      if (x >= 0 && x < width) {
        pixels[x] = colorToInt(palette.highlight);
      }
    }

    // Handle
    final handleX = mugRight;
    if (handleX < width) {
      for (int y = height ~/ 4; y < 3 * height ~/ 4; y++) {
        pixels[y * width + handleX] = colorToInt(palette.colors[2]);
      }
    }

    // Liquid if full
    if (full) {
      for (int y = 2; y < height - 2; y++) {
        for (int x = mugLeft + 1; x < mugRight - 1; x++) {
          if (x >= 0 && x < width) {
            pixels[y * width + x] = colorToInt(const Color(0xFF8B4513)); // Brown liquid
          }
        }
      }
      // Foam
      for (int x = mugLeft + 1; x < mugRight - 1; x++) {
        if (x >= 0 && x < width) {
          pixels[2 * width + x] = colorToInt(const Color(0xFFFFFFDD));
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// CURTAIN AND DRAPE TILES
// ============================================================================

/// Window curtain
class CurtainTile extends DecorationTile {
  final bool open;

  CurtainTile(super.id, {this.open = false});

  @override
  String get name => open ? 'Open Curtain' : 'Curtain';
  @override
  String get description => 'Window curtain';
  @override
  String get iconName => 'vertical_split';
  @override
  TilePalette get palette => DecorationPalettes.curtain;
  @override
  List<String> get tags => ['curtain', 'drape', 'window'];

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

    // Curtain rod
    for (int x = 0; x < width; x++) {
      pixels[x] = colorToInt(DecorationPalettes.metalFurniture.primary);
    }

    if (open) {
      // Bunched on sides
      for (int y = 1; y < height; y++) {
        final bunchWidth = width ~/ 4;
        // Left bunch
        for (int x = 0; x < bunchWidth; x++) {
          final foldNoise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          final col = foldNoise > 0.5 ? palette.primary : palette.colors[2];
          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
        // Right bunch
        for (int x = width - bunchWidth; x < width; x++) {
          final foldNoise = noise2D(x / 2.0 + seed, y / 2.0, 2);
          final col = foldNoise > 0.5 ? palette.primary : palette.colors[2];
          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    } else {
      // Full curtain with folds
      for (int y = 1; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Vertical fold pattern
          final foldPhase = sin(x / 2.0 + seed) * 0.5 + 0.5;
          Color col;
          if (foldPhase > 0.7) {
            col = palette.secondary;
          } else if (foldPhase > 0.3) {
            col = palette.primary;
          } else {
            col = palette.colors[2];
          }
          pixels[y * width + x] = addNoise(col, random, 0.04);
        }
      }

      // Gold trim at bottom
      for (int x = 0; x < width; x++) {
        pixels[(height - 1) * width + x] = colorToInt(palette.colors[3]);
      }
    }

    return pixels;
  }
}

// ============================================================================
// CLOCK AND TIME TILES
// ============================================================================

/// Wall clock
class ClockTile extends DecorationTile {
  ClockTile(super.id);

  @override
  String get name => 'Wall Clock';
  @override
  String get description => 'Decorative wall clock';
  @override
  String get iconName => 'schedule';
  @override
  TilePalette get palette => DecorationPalettes.woodFurniture;
  @override
  List<String> get tags => ['clock', 'time', 'wall', 'decoration'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height / 2;
    final radius = min(width, height) * 0.45;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < radius) {
          // Clock face
          if (dist > radius - 2) {
            // Frame
            pixels[y * width + x] = colorToInt(palette.colors[2]);
          } else {
            // White face
            pixels[y * width + x] = colorToInt(const Color(0xFFEEEEDD));
          }
        }
      }
    }

    // Clock hands
    // Hour hand
    final hourAngle = -pi / 2 + (seed % 12) * pi / 6;
    for (int i = 0; i < radius * 0.4; i++) {
      final hx = cx + cos(hourAngle) * i;
      final hy = cy + sin(hourAngle) * i;
      if (hx >= 0 && hx < width && hy >= 0 && hy < height) {
        pixels[hy.toInt() * width + hx.toInt()] = colorToInt(const Color(0xFF2A2A2A));
      }
    }

    // Minute hand
    final minAngle = -pi / 2 + (seed * 7 % 60) * pi / 30;
    for (int i = 0; i < radius * 0.6; i++) {
      final mx = cx + cos(minAngle) * i;
      final my = cy + sin(minAngle) * i;
      if (mx >= 0 && mx < width && my >= 0 && my < height) {
        pixels[my.toInt() * width + mx.toInt()] = colorToInt(const Color(0xFF2A2A2A));
      }
    }

    // Center dot
    pixels[cy.toInt() * width + cx.toInt()] = colorToInt(const Color(0xFF4A4A4A));

    return pixels;
  }
}

// ============================================================================
// TROPHY AND DISPLAY TILES
// ============================================================================

/// Trophy
class TrophyTile extends DecorationTile {
  final bool gold;

  TrophyTile(super.id, {this.gold = true});

  @override
  String get name => gold ? 'Gold Trophy' : 'Silver Trophy';
  @override
  String get description => 'Award trophy';
  @override
  String get iconName => 'emoji_events';
  @override
  TilePalette get palette => DecorationPalettes.coins;
  @override
  List<String> get tags => ['trophy', 'award', 'decoration'];

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

    final metalColor = gold ? palette.primary : palette.colors[3];
    final metalHighlight = gold ? palette.colors[1] : const Color(0xFFEEEEEE);
    final metalShadow = gold ? palette.colors[2] : const Color(0xFF999999);
    final cx = width ~/ 2;

    // Cup bowl (top part)
    final cupTop = 1;
    final cupBottom = height * 2 ~/ 3;
    for (int y = cupTop; y < cupBottom; y++) {
      final progress = (y - cupTop) / (cupBottom - cupTop);
      final bowlWidth = (width * 0.4 * (1 - progress * 0.5)).toInt();

      for (int x = cx - bowlWidth; x <= cx + bowlWidth; x++) {
        if (x >= 0 && x < width) {
          final distFromCenter = (x - cx).abs() / bowlWidth.toDouble();
          Color col;
          if (distFromCenter < 0.3) {
            col = metalHighlight;
          } else if (distFromCenter < 0.7) {
            col = metalColor;
          } else {
            col = metalShadow;
          }
          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    }

    // Handles
    for (int y = cupTop + 2; y < cupBottom - 2; y++) {
      final handleLeft = cx - (width * 0.35).toInt();
      final handleRight = cx + (width * 0.35).toInt();
      if (handleLeft >= 0) pixels[y * width + handleLeft] = colorToInt(metalShadow);
      if (handleRight < width) pixels[y * width + handleRight] = colorToInt(metalShadow);
    }

    // Stem
    final stemTop = cupBottom;
    final stemBottom = height - 2;
    for (int y = stemTop; y < stemBottom; y++) {
      pixels[y * width + cx] = colorToInt(metalColor);
      if (cx > 0) pixels[y * width + cx - 1] = colorToInt(metalShadow);
    }

    // Base
    final baseWidth = width ~/ 3;
    for (int x = cx - baseWidth; x <= cx + baseWidth; x++) {
      if (x >= 0 && x < width) {
        pixels[(height - 2) * width + x] = colorToInt(metalColor);
        pixels[(height - 1) * width + x] = colorToInt(metalShadow);
      }
    }

    return pixels;
  }
}

/// Statue/bust
class StatueTile extends DecorationTile {
  StatueTile(super.id);

  @override
  String get name => 'Statue';
  @override
  String get description => 'Decorative statue';
  @override
  String get iconName => 'accessibility_new';
  @override
  TilePalette get palette => DecorationPalettes.metalFurniture;
  @override
  List<String> get tags => ['statue', 'sculpture', 'decoration'];

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

    // Head
    final headCy = height * 0.2;
    final headRadius = width * 0.2;
    for (int y = 0; y < height ~/ 3; y++) {
      for (int x = 0; x < width; x++) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - headCy, 2));
        if (dist < headRadius) {
          final shade = -((x - cx) / headRadius) * 0.3;
          final col = shade > 0 ? palette.secondary : palette.primary;
          pixels[y * width + x] = addNoise(col, random, 0.04);
        }
      }
    }

    // Body/torso
    for (int y = height ~/ 3; y < 2 * height ~/ 3; y++) {
      final progress = (y - height ~/ 3) / (height ~/ 3);
      final bodyWidth = width * 0.3 * (1 + progress * 0.3);
      for (int x = (cx - bodyWidth).toInt(); x < (cx + bodyWidth).toInt(); x++) {
        if (x >= 0 && x < width) {
          final shade = (x - cx) / bodyWidth;
          final col = shade < -0.3 ? palette.shadow : (shade > 0.3 ? palette.secondary : palette.primary);
          pixels[y * width + x] = addNoise(col, random, 0.04);
        }
      }
    }

    // Base/pedestal
    final baseTop = 2 * height ~/ 3;
    for (int y = baseTop; y < height; y++) {
      final baseWidth = width * 0.4;
      for (int x = (cx - baseWidth).toInt(); x < (cx + baseWidth).toInt(); x++) {
        if (x >= 0 && x < width) {
          pixels[y * width + x] = colorToInt(palette.colors[2]);
        }
      }
    }

    return pixels;
  }
}

// ============================================================================
// MISCELLANEOUS DECORATIONS
// ============================================================================

/// Anvil
class AnvilTile extends DecorationTile {
  AnvilTile(super.id);

  @override
  String get name => 'Anvil';
  @override
  String get description => 'Blacksmith anvil';
  @override
  String get iconName => 'hardware';
  @override
  TilePalette get palette => DecorationPalettes.metalFurniture;
  @override
  List<String> get tags => ['anvil', 'blacksmith', 'metal', 'forge'];

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

    // Top surface (horn and face)
    final topY = height ~/ 4;
    for (int y = topY; y < topY + 3; y++) {
      // Horn (left side taper)
      for (int x = 1; x < width - 1; x++) {
        final isHorn = x < width ~/ 3;
        final hornTaper = isHorn ? (width ~/ 3 - x) ~/ 3 : 0;
        if (y >= topY + hornTaper) {
          pixels[y * width + x] = addNoise(palette.secondary, random, 0.04);
        }
      }
    }

    // Body
    final bodyTop = topY + 3;
    final bodyBottom = height - 3;
    final bodyWidth = width * 0.6;
    for (int y = bodyTop; y < bodyBottom; y++) {
      for (int x = (cx - bodyWidth / 2).toInt(); x < (cx + bodyWidth / 2).toInt(); x++) {
        if (x >= 0 && x < width) {
          final isEdge = x == (cx - bodyWidth / 2).toInt() || x == (cx + bodyWidth / 2).toInt() - 1;
          final col = isEdge ? palette.shadow : palette.primary;
          pixels[y * width + x] = addNoise(col, random, 0.04);
        }
      }
    }

    // Base (wider)
    for (int y = bodyBottom; y < height; y++) {
      for (int x = 2; x < width - 2; x++) {
        pixels[y * width + x] = colorToInt(palette.shadow);
      }
    }

    return pixels;
  }
}

/// Brazier/fire pit
class BrazierTile extends DecorationTile {
  final bool lit;

  BrazierTile(super.id, {this.lit = true});

  @override
  String get name => lit ? 'Lit Brazier' : 'Brazier';
  @override
  String get description => 'Metal fire brazier';
  @override
  String get iconName => 'outdoor_grill';
  @override
  TilePalette get palette => DecorationPalettes.metalFurniture;
  @override
  List<String> get tags => ['brazier', 'fire', 'light', 'metal'];

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
    final bowlTop = lit ? height ~/ 3 : height ~/ 4;
    final bowlBottom = 2 * height ~/ 3;

    // Fire if lit
    if (lit) {
      for (int y = 0; y < bowlTop + 2; y++) {
        for (int x = 0; x < width; x++) {
          final flameWidth = (1 - y / (bowlTop + 2)) * width * 0.35;
          if ((x - cx).abs() < flameWidth) {
            final flameNoise = noise2D(x / 2.0 + seed, y / 2.0, 3);
            if (flameNoise > 0.3) {
              Color flameColor;
              final progress = y / (bowlTop + 2);
              if (progress < 0.3) {
                flameColor = const Color(0xFFFFDD66);
              } else if (progress < 0.6) {
                flameColor = const Color(0xFFFFAA00);
              } else {
                flameColor = const Color(0xFFFF6600);
              }
              pixels[y * width + x] = colorToInt(flameColor);
            }
          }
        }
      }
    }

    // Bowl
    for (int y = bowlTop; y < bowlBottom; y++) {
      final progress = (y - bowlTop) / (bowlBottom - bowlTop);
      final bowlWidth = width * 0.3 + progress * width * 0.15;
      for (int x = (cx - bowlWidth).toInt(); x <= (cx + bowlWidth).toInt(); x++) {
        if (x >= 0 && x < width) {
          final isRim = y == bowlTop;
          final isEdge = x == (cx - bowlWidth).toInt() || x == (cx + bowlWidth).toInt();
          Color col;
          if (isRim) {
            col = palette.highlight;
          } else if (isEdge) {
            col = palette.shadow;
          } else {
            col = palette.primary;
          }
          pixels[y * width + x] = addNoise(col, random, 0.04);
        }
      }
    }

    // Stand/legs
    for (int y = bowlBottom; y < height; y++) {
      // Three legs
      pixels[y * width + width ~/ 4] = colorToInt(palette.shadow);
      pixels[y * width + width ~/ 2] = colorToInt(palette.shadow);
      pixels[y * width + 3 * width ~/ 4] = colorToInt(palette.shadow);
    }

    return pixels;
  }
}

/// Rope coil
class RopeCoilTile extends DecorationTile {
  RopeCoilTile(super.id);

  @override
  String get name => 'Rope Coil';
  @override
  String get description => 'Coiled rope';
  @override
  String get iconName => 'all_inclusive';
  @override
  TilePalette get palette => DecorationPalettes.woodenCrate;
  @override
  List<String> get tags => ['rope', 'coil', 'supplies'];

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

    // Draw concentric rope rings
    for (int ring = 0; ring < 3; ring++) {
      final innerR = ring * 2 + 2;
      final outerR = innerR + 2;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
          if (dist >= innerR && dist < outerR) {
            // Rope texture
            final angle = atan2(y - cy, x - cx);
            final ropePhase = sin(angle * 8 + ring * 2) * 0.5 + 0.5;
            Color ropeColor;
            if (ropePhase > 0.6) {
              ropeColor = palette.secondary;
            } else if (ropePhase > 0.3) {
              ropeColor = palette.primary;
            } else {
              ropeColor = palette.colors[2];
            }
            pixels[y * width + x] = addNoise(ropeColor, random, 0.06);
          }
        }
      }
    }

    return pixels;
  }
}

/// Sack/bag
class SackTile extends DecorationTile {
  final bool open;

  SackTile(super.id, {this.open = false});

  @override
  String get name => open ? 'Open Sack' : 'Sack';
  @override
  String get description => 'Burlap sack';
  @override
  String get iconName => 'inventory';
  @override
  TilePalette get palette => DecorationPalettes.woodenCrate;
  @override
  List<String> get tags => ['sack', 'bag', 'storage', 'supplies'];

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
    final neckTop = open ? height ~/ 5 : height ~/ 6;
    final bodyTop = height ~/ 3;

    // Neck/opening
    for (int y = neckTop; y < bodyTop; y++) {
      final neckWidth = width * 0.25;
      for (int x = (cx - neckWidth).toInt(); x < (cx + neckWidth).toInt(); x++) {
        if (x >= 0 && x < width) {
          if (open && y < neckTop + 2) {
            // Dark opening
            pixels[y * width + x] = colorToInt(palette.shadow);
          } else {
            pixels[y * width + x] = addNoise(palette.primary, random, 0.06);
          }
        }
      }
    }

    // Tied part
    if (!open) {
      for (int x = (cx - 1).toInt(); x <= (cx + 1).toInt(); x++) {
        if (x >= 0 && x < width) {
          pixels[(neckTop - 1) * width + x] = colorToInt(palette.colors[2]);
        }
      }
    }

    // Body (bulging)
    for (int y = bodyTop; y < height - 1; y++) {
      final progress = (y - bodyTop) / (height - 1 - bodyTop);
      final bulge = sin(progress * pi) * 0.15;
      final bodyWidth = width * (0.35 + bulge);

      for (int x = (cx - bodyWidth).toInt(); x < (cx + bodyWidth).toInt(); x++) {
        if (x >= 0 && x < width) {
          final distFromCenter = (x - cx).abs() / bodyWidth;
          Color col;
          if (distFromCenter > 0.8) {
            col = palette.colors[2];
          } else if (distFromCenter > 0.4) {
            col = palette.primary;
          } else {
            col = palette.secondary;
          }

          // Burlap texture
          final textureNoise = noise2D(x / 1.5 + seed, y / 1.5, 2);
          if (textureNoise > 0.7) {
            col = Color.lerp(col, palette.colors[2], 0.2)!;
          }

          pixels[y * width + x] = addNoise(col, random, 0.06);
        }
      }
    }

    return pixels;
  }
}

/// Spider web
class SpiderWebTile extends DecorationTile {
  SpiderWebTile(super.id);

  @override
  String get name => 'Spider Web';
  @override
  String get description => 'Dusty spider web';
  @override
  String get iconName => 'blur_on';
  @override
  TilePalette get palette => DecorationPalettes.bones;
  @override
  List<String> get tags => ['web', 'spider', 'dungeon', 'decoration'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final pixels = Uint32List(width * height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final webColor = const Color(0x99DDDDDD);

    // Corner anchor
    final anchorX = 0;
    final anchorY = 0;

    // Radial threads
    final threadCount = 6;
    for (int t = 0; t < threadCount; t++) {
      final angle = t * pi / 2 / (threadCount - 1);
      for (int i = 0; i < max(width, height); i++) {
        final x = anchorX + (cos(angle) * i).toInt();
        final y = anchorY + (sin(angle) * i).toInt();
        if (x >= 0 && x < width && y >= 0 && y < height) {
          pixels[y * width + x] = colorToInt(webColor);
        }
      }
    }

    // Spiral threads
    for (int ring = 2; ring < min(width, height) - 1; ring += 2) {
      for (int t = 0; t < threadCount - 1; t++) {
        final angle1 = t * pi / 2 / (threadCount - 1);
        final angle2 = (t + 1) * pi / 2 / (threadCount - 1);

        // Draw arc between radials
        final steps = 5;
        for (int s = 0; s < steps; s++) {
          final angle = angle1 + (angle2 - angle1) * s / steps;
          final x = anchorX + (cos(angle) * ring).toInt();
          final y = anchorY + (sin(angle) * ring).toInt();
          if (x >= 0 && x < width && y >= 0 && y < height) {
            pixels[y * width + x] = colorToInt(webColor);
          }
        }
      }
    }

    return pixels;
  }
}

/// Lever/switch
class LeverTile extends DecorationTile {
  final bool activated;

  LeverTile(super.id, {this.activated = false});

  @override
  String get name => activated ? 'Lever (On)' : 'Lever (Off)';
  @override
  String get description => 'Wall lever switch';
  @override
  String get iconName => 'toggle_on';
  @override
  TilePalette get palette => DecorationPalettes.metalFurniture;
  @override
  List<String> get tags => ['lever', 'switch', 'mechanism', 'interactive'];

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
    final baseY = 2 * height ~/ 3;

    // Base plate
    for (int y = baseY - 1; y < height - 1; y++) {
      for (int x = width ~/ 4; x < 3 * width ~/ 4; x++) {
        pixels[y * width + x] = addNoise(palette.shadow, random, 0.04);
      }
    }

    // Pivot point
    pixels[baseY * width + cx] = colorToInt(palette.primary);

    // Lever arm
    final leverLen = height ~/ 2;
    final angle = activated ? -pi / 4 : pi / 4;
    for (int i = 0; i < leverLen; i++) {
      final lx = cx + (sin(angle) * i).toInt();
      final ly = baseY - (cos(angle) * i).toInt();
      if (lx >= 0 && lx < width && ly >= 0 && ly < height) {
        pixels[ly * width + lx] = colorToInt(palette.primary);
      }
    }

    // Handle
    final handleX = cx + (sin(angle) * leverLen).toInt();
    final handleY = baseY - (cos(angle) * leverLen).toInt();
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final hx = handleX + dx;
        final hy = handleY + dy;
        if (hx >= 0 && hx < width && hy >= 0 && hy < height) {
          pixels[hy * width + hx] = colorToInt(activated ? const Color(0xFF44AA44) : const Color(0xFFAA4444));
        }
      }
    }

    return pixels;
  }
}

/// Key
class KeyTile extends DecorationTile {
  final bool golden;

  KeyTile(super.id, {this.golden = false});

  @override
  String get name => golden ? 'Golden Key' : 'Key';
  @override
  String get description => 'A key';
  @override
  String get iconName => 'vpn_key';
  @override
  TilePalette get palette => golden ? DecorationPalettes.coins : DecorationPalettes.metalFurniture;
  @override
  List<String> get tags => ['key', 'item', 'interactive'];

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
    final keyColor = golden ? palette.primary : palette.primary;
    final keyHighlight = golden ? palette.colors[1] : palette.secondary;

    // Bow (round part)
    final bowCy = height * 0.25;
    final bowRadius = min(width, height) * 0.2;
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width; x++) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - bowCy, 2));
        if (dist < bowRadius && dist > bowRadius - 2) {
          final shade = (x - cx) / bowRadius;
          final col = shade > 0 ? keyHighlight : keyColor;
          pixels[y * width + x] = addNoise(col, random, 0.05);
        }
      }
    }

    // Shaft
    final shaftTop = (bowCy + bowRadius - 1).toInt();
    final shaftBottom = height - 2;
    for (int y = shaftTop; y < shaftBottom; y++) {
      pixels[y * width + cx.toInt()] = addNoise(keyColor, random, 0.05);
    }

    // Teeth
    for (int y = shaftBottom - 3; y < shaftBottom; y++) {
      if (y % 2 == 0) {
        pixels[y * width + cx.toInt() + 1] = addNoise(keyColor, random, 0.05);
        pixels[y * width + cx.toInt() + 2] = addNoise(keyColor, random, 0.05);
      }
    }

    return pixels;
  }
}
