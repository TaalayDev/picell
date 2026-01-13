import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// LIQUID TILES
// ============================================================================

/// Base class for liquid tiles
abstract class LiquidTile extends TileBase {
  LiquidTile(super.id);

  @override
  TileCategory get category => TileCategory.liquid;

  @override
  bool get supportsRotation => true;

  @override
  bool get supportsAutoTiling => true;
}

/// Water tile with wave animations
class WaterTile extends LiquidTile {
  @override
  String get name => 'Water';

  @override
  String get description => 'Flowing water surface';

  @override
  String get iconName => 'water_drop';

  @override
  TilePalette get palette => TilePalettes.water;

  @override
  List<String> get tags => ['liquid', 'water', 'ocean', 'river'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 4;

  @override
  int get frameSpeed => 200;

  final bool deep;

  WaterTile(super.id, {this.deep = false});

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    // Generate just one frame by default (frame 0)
    // For animated display, the UI will request generateFrame
    return generateFrame(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
      frameIndex: 0,
    );
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed);
    final pixels = Uint32List(width * height);
    final pal = palette;

    // Base color
    final baseColor = deep ? pal.shadow : pal.primary;

    // Movement offset based on frame
    final offset = frameIndex * (width / 4);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Wave pattern
        final wave = sin(((x + offset) / width.toDouble()) * 2 * pi) * 1.5;
        final wave2 = cos(((y + offset / 2) / height.toDouble()) * 4 * pi) * 1.5;

        // Apply wave brightness
        final brightness = (wave + wave2) / 6.0;

        Color pixelColor = baseColor;

        if (brightness > 0.3) {
          pixelColor = pal.highlight; // Foam/Sparkle
        } else if (brightness > 0.1) {
          pixelColor = pal.secondary;
        } else if (brightness < -0.2) {
          pixelColor = pal.shadow;
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.05);
      }
    }

    return pixels;
  }
}

/// Lava tile with bubbling animation
class LavaTile extends LiquidTile {
  LavaTile(super.id);

  @override
  String get name => 'Lava';

  @override
  String get description => 'Molten lava surface';

  @override
  String get iconName => 'local_fire_department';

  @override
  TilePalette get palette => TilePalettes.lava;

  @override
  List<String> get tags => ['liquid', 'lava', 'fire', 'danger'];

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
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    return generateFrame(width: width, height: height, seed: seed, variation: variation, frameIndex: 0);
  }

  @override
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    final random = Random(seed + frameIndex);
    final pixels = Uint32List(width * height);
    final pal = palette;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Heat blobs
        final blob1 = sin((x / width * 3 * pi) + frameIndex * 0.5) * cos(y / height * pi);
        final blob2 = sin((y / height * 3 * pi) - frameIndex * 0.3) * cos(x / width * pi);
        final heat = (blob1 + blob2) / 2.0;

        Color pixelColor;

        if (heat > 0.6) {
          pixelColor = pal.highlight; // Hot spots
        } else if (heat > 0.3) {
          pixelColor = pal.accent; // Bright orange
        } else if (heat > -0.2) {
          pixelColor = pal.primary; // Base red
        } else {
          pixelColor = pal.shadow; // Cooled crust
        }

        pixels[y * width + x] = addNoise(pixelColor, random, 0.05);
      }
    }

    // Occasional bubbles
    final bubbleCount = random.nextInt(3);
    for (int i = 0; i < bubbleCount; i++) {
      final bx = random.nextInt(width - 2) + 1;
      final by = random.nextInt(height - 2) + 1;
      pixels[by * width + bx] = colorToInt(pal.highlight);
      pixels[(by - 1) * width + bx] = colorToInt(pal.secondary);
      pixels[(by + 1) * width + bx] = colorToInt(pal.shadow);
    }

    return pixels;
  }
}
