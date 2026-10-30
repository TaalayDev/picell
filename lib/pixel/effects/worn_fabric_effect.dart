part of 'effects.dart';

/// Woven cloth laid over the artwork: lit over/under threads, fading and
/// abrasion, grime in the weave gaps, worn-through holes, and fringed edges.
///
/// It keeps the artwork's colours and is shape-aware:
///  * wear concentrates along the silhouette and on the artwork's highlights
///    (raised folds), as real cloth does;
///  * fraying unravels whole threads at the silhouette, each to its own length;
///  * grime gathers near edges and in the gaps between threads.
class WornFabricEffect extends Effect {
  WornFabricEffect([Map<String, dynamic>? params]) : super(EffectType.wornFabric, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'pattern': 0,
    'threadSpacing': 3,
    'weaveStrength': 0.42,
    'wear': 0.3,
    'fray': 0.18,
    'dirt': 0.25,
    'holes': 0.0,
    'edgeWear': 0.5,
    'lightDirection': 225.0,
    'seed': 42,
    'threadColor': 0xFFD7D2C8,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'pattern': {
          'label': 'Weave',
          'description': 'Plain, twill, or basket weave.',
          'type': 'select',
          'options': {0: 'Plain', 1: 'Twill', 2: 'Basket'},
        },
        'threadSpacing': {'label': 'Thread Spacing', 'type': 'slider', 'min': 2, 'max': 8, 'divisions': 6},
        for (final spec in [
          ('weaveStrength', 'Weave Relief', 0.0, 1.0),
          ('wear', 'Wear & Fading', 0.0, 1.0),
          ('edgeWear', 'Smart Edge Wear', 0.0, 1.0),
          ('dirt', 'Grime', 0.0, 1.0),
          ('holes', 'Worn-Through Holes', 0.0, 1.0),
          ('fray', 'Edge Fraying', 0.0, 1.0),
          ('lightDirection', 'Light Direction', 0.0, 360.0),
          ('seed', 'Pattern Seed', 0, 9999),
        ])
          spec.$1: {
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'threadColor': {'label': 'Exposed Fiber', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;

    final pattern = _number('pattern', 0, 2).round();
    final s = _number('threadSpacing', 2, 8).round();
    final strength = _number('weaveStrength', 0, 1);
    final wear = _number('wear', 0, 1);
    final fray = _number('fray', 0, 1);
    final dirt = _number('dirt', 0, 1);
    final holes = _number('holes', 0, 1);
    final edgeWear = _number('edgeWear', 0, 1);
    final seed = _number('seed', 0, 9999).round();
    final angle = _number('lightDirection', 0, 360) * pi / 180;
    final lx = cos(angle), ly = sin(angle);
    final fiber = (parameters['threadColor'] as num?)?.toInt() ?? (_defaults['threadColor'] as int);
    final preserve = parameters['preserveAlpha'] != false;

    final count = width * height;
    final inside = Uint8List(count);
    for (var i = 0; i < count; i++) {
      inside[i] = !preserve || (pixels[i] >>> 24) != 0 ? 1 : 0;
    }
    final shape = _silhouetteShape(inside, width, height, 2.0, 0.0);

    // Pass 1: thread height map and per-thread tone.
    final heightMap = Float32List(count), toneMap = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final cx = x ~/ s, cy = y ~/ s;
        final fx = (x % s + 0.5) / s, fy = (y % s + 0.5) / s;
        final verticalTop = switch (pattern) {
          1 => (cx + cy) % 3 != 0, // twill: warp floats over two, under one
          2 => (cx ~/ 2 + cy ~/ 2).isEven, // basket: 2x2 blocks
          _ => (cx + cy).isEven, // plain
        };
        // Top thread is a rounded cylinder across its width that dips where it
        // passes under at the cell ends.
        final across = verticalTop ? fx : fy, along = verticalTop ? fy : fx;
        final round = 1 - pow(2 * across - 1, 2).toDouble();
        final dip = 1 - pow(2 * along - 1, 4).toDouble();
        heightMap[i] = ((0.25 + 0.75 * round * (0.55 + 0.45 * dip)) * (verticalTop ? 1.0 : 0.88)).clamp(0.0, 1.0);
        final thread = verticalTop ? cx : cy;
        final slub = _textureNoise(x * 0.18, y * 0.18, seed + 5);
        toneMap[i] = (_textureHash(thread, verticalTop ? 1 : 2, seed + 3) - 0.5) * 0.14 + (slub - 0.5) * 0.12;
      }
    }

    double heightAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final j = y * width + x;
      return inside[j] == 1 ? heightMap[j] : fallback;
    }

    // Pass 2: fray, wear, grime, lighting.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final source = pixels[i];
        final alpha = source >>> 24;
        final h = heightMap[i];
        final dist = shape.distance[i];

        // Fray: unravel whole threads at the silhouette, each to its own length.
        if (preserve && fray > 0 && dist < 8) {
          final nx = shape.normalX[i], ny = shape.normalY[i];
          if (nx != 0 || ny != 0) {
            final vertical = ny.abs() > nx.abs();
            final thread = vertical ? x ~/ s : y ~/ s;
            final length = _textureHash(thread, vertical ? 7 : 8, seed + 11) * fray * s * 2.4;
            if (dist <= length) {
              result[i] = 0;
              continue;
            }
          }
        }

        final lum = _textureLuminance(source);
        final cavity = 1 - h;

        // Wear is strongest along the silhouette and on the artwork's highlights.
        final edge = edgeWear * (1 - min(dist, 6.0) / 6) * 0.35;
        final field = _textureFbm(x / 9.0, y / 7.0, seed + 23) + edge + (lum - 0.5) * 0.25;
        final worn = _textureStep(0.76 - wear * 0.38, 1.0 - wear * 0.38, field);

        // Worn-through holes leave only the deeper thread gaps' lattice behind.
        if (preserve && holes > 0 && _textureFbm(x / 5.0, y / 5.0, seed + 29) + edge * 0.6 > 1.0 - holes * 0.38 && h < 0.72) {
          result[i] = 0;
          continue;
        }

        var color = source;
        // Worn tops fade toward the exposed fiber; gaps keep the colour.
        final fade = (worn * (0.35 + 0.5 * wear) + wear * 0.06) * (0.4 + 0.6 * h);
        if (fade > 0) {
          final fib = _textureBlendColor(fiber, 0xFF000000, (0.12 - toneMap[i]).clamp(0.0, 0.5), 255);
          color = _textureBlendColor(color, fib, fade.clamp(0.0, 0.85), 255);
        }
        if (dirt > 0) {
          final grime = dirt * (pow(cavity, 1.5).toDouble() * 0.4 + (1 - min(dist, 5.0) / 5) * 0.25);
          color = _textureBlendColor(color, 0xFF1C1814, grime.clamp(0.0, 0.7), 255);
        }

        final relief = -((heightAt(x + 1, y, h) - heightAt(x - 1, y, h)) * lx +
                (heightAt(x, y + 1, h) - heightAt(x, y - 1, h)) * ly) *
            strength;
        final shade = (1.0 + relief.clamp(-0.5, 0.5) * 1.2 + (h - 0.5) * strength * 0.5 + toneMap[i] * strength).clamp(0.35, 1.6);

        int channel(int shift) => (_textureChannel(color, shift) * shade).round().clamp(0, 255);
        final outAlpha = preserve ? alpha : 255;
        result[i] = (outAlpha << 24) | (channel(16) << 16) | (channel(8) << 8) | channel(0);
      }
    }
    return result;
  }
}
