import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../tile_base.dart';
import '../tile_palette.dart';

// ============================================================================
// SPECIAL TILES
// ============================================================================

abstract class SpecialTile extends TileBase {
  SpecialTile(super.id);

  @override
  TileCategory get category => TileCategory.special;

  @override
  bool get supportsRotation => true;

  @override
  bool get supportsAutoTiling => false;
}

/// Crystal/Gem tile
class CrystalTile extends SpecialTile {
  CrystalTile(super.id);

  @override
  String get name => 'Crystal';

  @override
  String get description => 'Glowing crystal formation';

  @override
  String get iconName => 'auto_awesome';

  @override
  TilePalette get palette => TilePalettes.crystal;

  @override
  List<String> get tags => ['special', 'gem', 'crystal', 'magic'];

  @override
  bool get animated => true;

  @override
  int get frameCount => 8;

  @override
  int get frameSpeed => 150;

  @override
  Uint32List generate({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
  }) {
    // Generate just one frame by default
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

    // Clear background
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 0x00000000;
    }

    // Crystal structure: a few shards pointing up
    final shards = [
      _Shard(width * 0.5, height.toDouble(), height * 0.8, width * 0.3, 0),
      _Shard(width * 0.3, height.toDouble(), height * 0.6, width * 0.2, -pi / 8),
      _Shard(width * 0.7, height.toDouble(), height * 0.6, width * 0.2, pi / 8),
    ];

    // Glow intensity pulsing
    final t = frameIndex / frameCount;
    final pulse = sin(t * 2 * pi) * 0.5 + 0.5; // 0.0 to 1.0

    for (final shard in shards) {
      _drawShard(pixels, width, height, shard, pal, pulse, random);
    }

    return pixels;
  }

  void _drawShard(Uint32List pixels, int w, int h, _Shard shard, TilePalette pal, double pulse, Random random) {
    // Simple triangle rendering for shard
    // Top point
    final topX = shard.x + sin(shard.angle) * shard.height;
    final topY = shard.y - cos(shard.angle) * shard.height;

    // Base points
    final baseX1 = shard.x - cos(shard.angle) * shard.width / 2;
    final baseY1 = shard.y - sin(shard.angle) * shard.width / 2;
    final baseX2 = shard.x + cos(shard.angle) * shard.width / 2;
    final baseY2 = shard.y + sin(shard.angle) * shard.width / 2;

    // Scanline fill (naive)
    final minX = [topX, baseX1, baseX2].reduce(min).floor().clamp(0, w - 1);
    final maxX = [topX, baseX1, baseX2].reduce(max).ceil().clamp(0, w - 1);
    final minY = [topY, baseY1, baseY2].reduce(min).floor().clamp(0, h - 1);
    final maxY = [topY, baseY1, baseY2].reduce(max).ceil().clamp(0, h - 1);

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        if (_pointInTriangle(x.toDouble(), y.toDouble(), baseX1, baseY1, baseX2, baseY2, topX, topY)) {
          // Inner gradient for "glow"
          final distFromCenter =
              sqrt(pow(x - shard.x, 2) + pow(y - (shard.y - shard.height / 2), 2)) / (shard.height / 2);

          var col = pal.primary;

          if (distFromCenter < 0.3) {
            // Core glow
            col = Color.lerp(pal.highlight, pal.accent, pulse)!;
          } else if (distFromCenter < 0.7) {
            col = pal.secondary;
          } else {
            col = pal.shadow;
          }

          // Add a bit of transparency/sparkle randomly
          if (random.nextDouble() > 0.9) {
            col = pal.highlight;
          }

          pixels[y * w + x] = colorToInt(col);
        }
      }
    }
  }

  bool _pointInTriangle(double px, double py, double x1, double y1, double x2, double y2, double x3, double y3) {
    final d1 = _sign(px, py, x1, y1, x2, y2);
    final d2 = _sign(px, py, x2, y2, x3, y3);
    final d3 = _sign(px, py, x3, y3, x1, y1);

    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return !(hasNeg && hasPos);
  }

  double _sign(double p1x, double p1y, double p2x, double p2y, double p3x, double p3y) {
    return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y);
  }
}

class _Shard {
  final double x, y, height, width, angle;
  _Shard(this.x, this.y, this.height, this.width, this.angle);
}
