import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// NATURE TILES (Non-terrain natural elements)
// ============================================================================

/// Base class for nature objects (rocks, trees, etc.)
abstract class NatureTile extends TileBase {
  NatureTile(super.id);

  @override
  TileCategory get category => TileCategory.nature;

  @override
  bool get supportsRotation => false;

  @override
  bool get supportsAutoTiling => false;
}

/// Rock/Stone object
class StoneTile extends NatureTile {
  StoneTile(
    super.id, {
    this.addMoss = false,
  });

  final bool addMoss;

  @override
  String get name => 'Stone';

  @override
  String get description => 'Natural rock formations';

  @override
  String get iconName => 'landscape';

  @override
  TilePalette get palette => TilePalettes.stone;

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
    final pal = palette;

    // Clear background (transparent)
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    final cx = width / 2;
    final cy = height / 2;
    final radius = min(width, height) / 2 - 2;

    // Draw irregular rock shape
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));

        // Noise for irregularity
        final edgeNoise = noise2D(x / 5.0, y / 5.0, 5) * 2.0;

        if (dist < radius + edgeNoise) {
          // Shading based on "light" from top-left
          final lightDirX = -0.5;
          final lightDirY = -0.5;

          final dx = (x - cx) / radius;
          final dy = (y - cy) / radius;

          // Simple dot product approximation for lighting
          final light = -(dx * lightDirX + dy * lightDirY);

          var col = pal.primary;
          if (light > 0.4) {
            col = pal.highlight;
          } else if (light > 0.1) {
            col = pal.secondary;
          } else if (light < -0.3) {
            col = pal.shadow;
          }

          pixels[y * width + x] = addNoise(col, random, 0.08);
        } else if (dist < radius + edgeNoise + 1.0) {
          // Outline/Dark edge
          if (y > cy) {
            pixels[y * width + x] = colorToInt(pal.shadow.withValues(alpha: 0.7));
          }
        }
      }
    }

    // Moss overlay
    if (variation == TileVariation.mossy) {
      final mossColor = const TilePalette(
        name: 'Moss',
        colors: [
          Color(0xFF4CAF50), // Primary
          Color(0xFF388E3C), // Secondary
          Color(0xFFC8E6C9), // Accent
          Color(0xFF81C784), // Highlight
          Color(0xFF1B5E20), // Shadow
        ],
      ).primary;

      for (int y = 0; y < height / 2; y++) {
        for (int x = 0; x < width; x++) {
          if (pixels[y * width + x] != 0 && random.nextDouble() < 0.3) {
            // Only place moss on top part of the rock
            pixels[y * width + x] = addNoise(mossColor, random, 0.1);
          }
        }
      }
    }

    return pixels;
  }
}
