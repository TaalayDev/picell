import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// ADVANCED NATURE PALETTES
// ============================================================================

class AdvancedNaturePalettes {
  static const desert = TilePalette(
    name: 'Desert Cacti',
    colors: [
      Color(0xFF2d4a1c), // Deep Green (Shadow)
      Color(0xFF4a7c23), // Base Green
      Color(0xFF6b9e31), // Highlight Green
      Color(0xFFe8d5a3), // Sand Background
      Color(0xFFb8a676), // Sand Shadow
    ],
  );

  static const bamboo = TilePalette(
    name: 'Bamboo Forest',
    colors: [
      Color(0xFF334d26), // Dark Stalk
      Color(0xFF558033), // Base Stalk
      Color(0xFF7aa34f), // Highlight Stalk
      Color(0xFF1a2613), // Deep Shadow/Background
      Color(0xFF2d401a), // Leaf Dark
    ],
  );

  static const mushroomRed = TilePalette(
    name: 'Mushroom Red',
    colors: [
      Color(0xFF8a1c1c), // Dark Red
      Color(0xFFc42c2c), // Base Red
      Color(0xFFe65c5c), // Light Red
      Color(0xFFf0f0f0), // Spots (White)
      Color(0xFFd9c2b2), // Stalk/Gill
    ],
  );

  static const coralReef = TilePalette(
    name: 'Coral Reef',
    colors: [
      Color(0xFF006994), // Ocean Blue
      Color(0xFFff6b8a), // Coral Pink
      Color(0xFFffb347), // Coral Orange
      Color(0xFF98ff98), // Coral Green
      Color(0xFF003366), // Deep Water
    ],
  );
}

// ============================================================================
// CACTUS TILE
// ============================================================================

/// Generates Saguaro-style cacti with ribbed shading and spines
class CactusTile extends TileBase {
  final double density;

  CactusTile(String id, {this.density = 0.4}) : super(id);

  @override
  String get name => 'Cactus';
  @override
  String get description => 'Desert terrain with ribbed cacti';
  @override
  String get iconName => 'nature';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  TilePalette get palette => AdvancedNaturePalettes.desert;
  @override
  List<String> get tags => ['desert', 'plant', 'nature', 'cactus'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // 1. Draw Sand Background with Ripples
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double noise = noise2D(x / 10.0, y / 5.0 + seed, 2);
        Color sand = (noise > 0.4) ? palette.colors[3] : palette.colors[4];
        pixels[y * width + x] = addNoise(sand, random, 0.03);
      }
    }

    // 2. Draw Cacti
    int count = (width * density).toInt();
    for (int i = 0; i < count; i++) {
      int cx = random.nextInt(width);
      int cy = random.nextInt(height ~/ 2) + (height ~/ 2); // Foreground
      int w = random.nextInt(4) + 4; // Thickness
      int h = random.nextInt(height ~/ 2) + 6;

      if (cx + w < width && cy - h > 0) {
        _drawCactusBody(pixels, width, cx, cy, w, h, random);
      }
    }

    return pixels;
  }

  void _drawCactusBody(Uint32List pixels, int imgW, int x, int bottomY, int w, int h, Random r) {
    for (int dy = 0; dy < h; dy++) {
      int y = bottomY - dy;
      for (int dx = 0; dx < w; dx++) {
        int px = x + dx;

        // Skip corners for rounded top
        if (dy > h - 3) {
          if (dx == 0 || dx == w - 1) continue;
        }

        if (px >= 0 && px < imgW && y >= 0) {
          // Ribbed Texture Logic
          // We create vertical strips of light/dark to simulate ribs
          double ribPos = (dx / w) * 3.0; // 3 ribs across width
          double ribHeight = sin(ribPos * pi); // 0..1 curve

          Color c;
          if (ribHeight > 0.8)
            c = palette.colors[2]; // Highlight
          else if (ribHeight > 0.4)
            c = palette.primary; // Base
          else
            c = palette.colors[0]; // Shadow (groove)

          pixels[y * imgW + px] = colorToInt(c);

          // Spines (Random dots)
          if (r.nextDouble() > 0.95 && dx == 0 || dx == w - 1) {
            pixels[y * imgW + px] = colorToInt(Color(0xFFdddddd)); // Spine
          }
        }
      }
    }
  }
}

// ============================================================================
// BAMBOO FOREST TILE
// ============================================================================

/// Generates bamboo stalks with segmented nodes and cylindrical shading
class BambooTile extends TileBase {
  BambooTile(String id) : super(id);

  @override
  String get name => 'Bamboo Forest';
  @override
  String get description => 'Dense bamboo stalks with leaves';
  @override
  String get iconName => 'grass';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  TilePalette get palette => AdvancedNaturePalettes.bamboo;
  @override
  List<String> get tags => ['forest', 'plant', 'nature', 'bamboo', 'asian'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Background (Deep Forest Shadow)
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(palette.colors[3], random, 0.05);
    }

    // Generate 4-6 stalks
    int stalks = random.nextInt(3) + 4;
    for (int i = 0; i < stalks; i++) {
      int x = random.nextInt(width);
      int thickness = random.nextInt(3) + 3;

      _drawBambooStalk(pixels, width, height, x, thickness, random);
    }

    return pixels;
  }

  void _drawBambooStalk(Uint32List pixels, int imgW, int imgH, int cx, int w, Random r) {
    int segmentHeight = r.nextInt(6) + 6;
    int currentY = imgH;
    int nodeY = currentY - segmentHeight;

    for (int y = imgH - 1; y >= 0; y--) {
      // Check for Node (Segment connector)
      bool isNode = (y - nodeY).abs() < 2;
      if (y < nodeY) {
        nodeY -= (r.nextInt(6) + 6);
      }

      for (int dx = 0; dx < w; dx++) {
        int px = cx + dx;
        if (px >= 0 && px < imgW) {
          Color c;

          if (isNode) {
            c = palette.colors[0]; // Dark node ring
            // Occasionally sprout a leaf at a node
            if (dx == w - 1 && r.nextDouble() < 0.1) {
              _drawLeaf(pixels, imgW, imgH, px, y, true);
            }
          } else {
            // Cylindrical Shading: Dark -> Light -> Dark
            double shade = dx / (w - 1); // 0.0 to 1.0
            if (shade < 0.3)
              c = palette.colors[0]; // Left Edge Shadow
            else if (shade < 0.7)
              c = palette.colors[2]; // Center Highlight
            else
              c = palette.primary; // Right Edge Base
          }

          pixels[y * imgW + px] = colorToInt(c);
        }
      }
    }
  }

  void _drawLeaf(Uint32List pixels, int w, int h, int x, int y, bool right) {
    int dir = right ? 1 : -1;
    for (int i = 0; i < 5; i++) {
      int px = x + (i * dir);
      int py = y - (i ~/ 2); // Angle up slightly
      if (px >= 0 && px < w && py >= 0 && py < h) {
        pixels[py * w + px] = colorToInt(palette.colors[4]); // Leaf Dark color
      }
    }
  }
}

// ============================================================================
// GIANT MUSHROOM CAP TILE
// ============================================================================

/// Generates a top-down view of a giant mushroom cap with spots and curvature
class GiantMushroomTile extends TileBase {
  final TilePalette mushroomPalette;

  GiantMushroomTile(String id, {this.mushroomPalette = AdvancedNaturePalettes.mushroomRed}) : super(id);

  @override
  String get name => 'Giant Mushroom';
  @override
  String get description => 'Large mushroom cap top view';
  @override
  String get iconName => 'circle';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  TilePalette get palette => mushroomPalette;
  @override
  List<String> get tags => ['mushroom', 'fantasy', 'nature', 'fungus'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Transparent/Dirt corners (background)
    final bgColor = Color(0xFF3e2723); // Dark dirt
    for (int i = 0; i < pixels.length; i++) pixels[i] = colorToInt(bgColor);

    // Mushroom Geometry
    double cx = width / 2.0;
    double cy = height / 2.0;
    double radius = min(width, height) / 2.0 - 1;

    // Spots generation (Simple Voronoi centers)
    List<Point<double>> spots = [];
    int numSpots = random.nextInt(5) + 4;
    for (int i = 0; i < numSpots; i++) {
      spots.add(Point(random.nextDouble() * width, random.nextDouble() * height));
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double dx = x - cx;
        double dy = y - cy;
        double dist = sqrt(dx * dx + dy * dy);

        if (dist <= radius) {
          // 1. Base Curvature Shading (Darker at edges)
          double normalZ = sqrt(max(0, radius * radius - dist * dist)) / radius; // 1.0 at center, 0.0 at edge

          Color base;
          if (normalZ > 0.8)
            base = palette.colors[2]; // Highlight (Top)
          else if (normalZ > 0.4)
            base = palette.primary; // Mid
          else
            base = palette.colors[0]; // Edge Shadow

          // 2. Spots
          bool isSpot = false;
          for (var spot in spots) {
            double sdx = x - spot.x;
            double sdy = y - spot.y;
            // Distort spots slightly for organic look
            if (sqrt(sdx * sdx + sdy * sdy) < (3.0 + normalZ * 2)) {
              isSpot = true;
              break;
            }
          }

          if (isSpot) {
            // White spots (also shaded by curvature slightly)
            pixels[y * width + x] = colorToInt(Color.lerp(palette.colors[3], Colors.grey, 1.0 - normalZ)!);
          } else {
            pixels[y * width + x] = addNoise(base, random, 0.04);
          }
        }
      }
    }
    return pixels;
  }
}

// ============================================================================
// CORAL REEF TILE
// ============================================================================

/// Organic branching structures for underwater biomes
class CoralTile extends TileBase {
  CoralTile(String id) : super(id);

  @override
  String get name => 'Coral Reef';
  @override
  String get description => 'Colorful organic underwater structure';
  @override
  String get iconName => 'bubble_chart';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  TilePalette get palette => AdvancedNaturePalettes.coralReef;
  @override
  List<String> get tags => ['water', 'ocean', 'nature', 'coral'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final waterColor = palette.colors[4]; // Deep blue

    // Base Water
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = addNoise(waterColor, random, 0.02);
    }

    // Organic Growth using Noise Thresholds
    // We use two noise layers: one for shape, one for color type
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double shapeNoise = noise2D(x / 5.0 + seed, y / 5.0, 3);

        // If noise is high, draw coral
        if (shapeNoise > 0.4) {
          // Use another noise value to determine color (Pink vs Orange vs Green)
          double typeNoise = noise2D(x / 10.0, y / 10.0 + seed * 2, 2);

          Color c;
          if (typeNoise < 0.4)
            c = palette.colors[1]; // Pink
          else if (typeNoise < 0.7)
            c = palette.colors[2]; // Orange
          else
            c = palette.colors[3]; // Green

          // Add texture/pores
          if (random.nextDouble() > 0.8) {
            c = Color.lerp(c, Colors.black, 0.2)!; // Pore
          }

          pixels[y * width + x] = colorToInt(c);
        }
      }
    }
    return pixels;
  }
}

// ============================================================================
// FLOWERING VINES TILE
// ============================================================================

/// Vines that can overlay other tiles (transparent background conceptual)
class FloweringVineTile extends TileBase {
  FloweringVineTile(String id) : super(id);

  @override
  String get name => 'Flowering Vines';
  @override
  String get description => 'Twisting vines with flower buds';
  @override
  String get iconName => 'eco';
  @override
  TileCategory get category => TileCategory.nature;
  @override
  TilePalette get palette => TilePalettes.forest; // Use standard forest
  @override
  List<String> get tags => ['vine', 'plant', 'nature', 'flower'];

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);

    // Ideally transparent, but here we use a dark tint to show it's an overlay
    // In a real engine, you'd use 0x00000000
    final bgColor = Color(0xFF2a332a);
    for (int i = 0; i < pixels.length; i++) pixels[i] = colorToInt(bgColor);

    // Generate 3-4 vines
    int vines = 4;
    for (int i = 0; i < vines; i++) {
      _drawVine(pixels, width, height, random, i);
    }

    return pixels;
  }

  void _drawVine(Uint32List pixels, int w, int h, Random r, int index) {
    // Sine wave movement down the tile
    double phase = r.nextDouble() * pi * 2;
    double freq = 0.2 + r.nextDouble() * 0.3;
    int centerX = r.nextInt(w);

    for (int y = 0; y < h; y++) {
      int dx = (sin(y * freq + phase) * 3.0).round();
      int x = centerX + dx;

      if (x >= 0 && x < w) {
        // Vine Stem
        pixels[y * w + x] = colorToInt(palette.colors[1]); // Light Green
        if (x + 1 < w) pixels[y * w + (x + 1)] = colorToInt(palette.colors[2]); // Dark Green Shadow

        // Occasional Leaf
        if (r.nextDouble() < 0.1) {
          if (x - 1 >= 0) pixels[y * w + (x - 1)] = colorToInt(palette.primary);
        }

        // Occasional Flower
        if (r.nextDouble() < 0.05) {
          _drawTinyFlower(pixels, w, h, x, y, r);
        }
      }
    }
  }

  void _drawTinyFlower(Uint32List pixels, int w, int h, int cx, int cy, Random r) {
    Color flowerColor = r.nextBool() ? Color(0xFFFF69B4) : Color(0xFFFFFF00); // Hot Pink or Yellow

    // 3x3 flower pattern
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if ((dx.abs() + dy.abs()) == 1) {
          // Cross shape
          int px = cx + dx;
          int py = cy + dy;
          if (px >= 0 && px < w && py >= 0 && py < h) {
            pixels[py * w + px] = colorToInt(flowerColor);
          }
        }
      }
    }
    pixels[cy * w + cx] = colorToInt(Colors.white); // Center
  }
}
