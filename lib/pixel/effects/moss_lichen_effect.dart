part of 'effects.dart';

/// Moss cushions and crustose lichen rosettes grown over the artwork.
///
/// Growth follows the surface the way it does outdoors:
///  * moss gathers on up-facing silhouette edges (`gravity`), at the base where
///    damp rises, in the artwork's dark crevices (`crevice`), and along edges
///    (`edgeGrowth`);
///  * moss forms lit, rounded cushions; lichen forms ringed discs on the
///    surfaces moss leaves free;
///  * with `preserveAlpha` off, moss can overhang the silhouette by a pixel.
class MossLichenEffect extends Effect {
  MossLichenEffect([Map<String, dynamic>? params]) : super(EffectType.mossLichen, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'coverage': 0.42,
    'scale': 10,
    'edgeGrowth': 0.6,
    'lichenMix': 0.38,
    'gravity': 0.5,
    'crevice': 0.5,
    'fuzz': 0.5,
    'lightDirection': 225.0,
    'seed': 42,
    'mossColor': 0xFF4F772D,
    'lichenColor': 0xFFA7C957,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('coverage', 'Growth Coverage', null, 0.0, 1.0),
          ('scale', 'Cluster Scale', null, 3, 28),
          ('edgeGrowth', 'Edge Preference', 'Encourage growth beside silhouettes.', 0.0, 1.0),
          ('gravity', 'Top & Base Bias', 'Favor up-facing edges and the damp base.', 0.0, 1.0),
          ('crevice', 'Crevice Growth', 'Grow in the artwork\'s dark, recessed areas.', 0.0, 1.0),
          ('lichenMix', 'Lichen Amount', null, 0.0, 1.0),
          ('fuzz', 'Fuzzy Edges', 'Breaks up cushion outlines.', 0.0, 1.0),
          ('lightDirection', 'Light Direction', null, 0.0, 360.0),
          ('seed', 'Pattern Seed', null, 0, 9999),
        ])
          spec.$1: {
            'label': spec.$2,
            if (spec.$3 != null) 'description': spec.$3,
            'type': 'slider',
            'min': spec.$4,
            'max': spec.$5,
            'divisions': spec.$4 is int ? (spec.$5 - spec.$4).toInt() : 100,
          },
        'mossColor': {'label': 'Moss Color', 'type': 'color'},
        'lichenColor': {'label': 'Lichen Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  int _color(String key) {
    final value = parameters[key];
    return (value is num ? value.toInt() : (_defaults[key] as int)) | 0xFF000000;
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;
    final coverage = _number('coverage', 0, 1);
    if (coverage == 0) return result;

    final scale = _number('scale', 3, 28).round();
    final edgeGrowth = _number('edgeGrowth', 0, 1);
    final lichenMix = _number('lichenMix', 0, 1);
    final gravity = _number('gravity', 0, 1);
    final crevice = _number('crevice', 0, 1);
    final fuzz = _number('fuzz', 0, 1);
    final seed = _number('seed', 0, 9999).round();
    final angle = _number('lightDirection', 0, 360) * pi / 180;
    final lx = cos(angle), ly = sin(angle);
    final moss = _color('mossColor'), lichen = _color('lichenColor');
    final preserve = parameters['preserveAlpha'] != false;

    final count = width * height;
    final solid = Uint8List(count);
    var minY = height, maxY = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if ((pixels[y * width + x] >>> 24) == 0) continue;
        solid[y * width + x] = 1;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    if (minY > maxY) return result;
    final shape = _silhouetteShape(solid, width, height, 0.0, 0.0);
    bool isSolid(int x, int y) => x >= 0 && y >= 0 && x < width && y < height && solid[y * width + x] == 1;

    // Eligible pixels: the artwork, plus a one-pixel overhang when not preserving alpha.
    final eligible = Uint8List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (solid[i] == 1) {
          eligible[i] = 1;
        } else if (!preserve &&
            (isSolid(x - 1, y) || isSolid(x + 1, y) || isSolid(x, y - 1) || isSolid(x, y + 1))) {
          eligible[i] = 2;
        }
      }
    }

    double lumAt(int x, int y) => _textureLuminance(pixels[y * width + x]);

    // Pass 1: moss suitability above threshold, shaped into a cushion height.
    final threshold = 0.95 - coverage * 0.6;
    final mossAmount = Float32List(count), mossHeight = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (eligible[i] == 0) continue;
        var rim = 1.0, up = 0.0, lum = 0.5, cavity = 0.0;
        if (eligible[i] == 1) {
          rim = 1 - (min(shape.distance[i], 5.0) - 1) / 4;
          up = max(0.0, -shape.normalY[i]);
          lum = lumAt(x, y);
          var sum = 0.0, n = 0;
          for (var oy = -1; oy <= 1; oy++) {
            for (var ox = -1; ox <= 1; ox++) {
              if ((ox != 0 || oy != 0) && isSolid(x + ox, y + oy)) {
                sum += lumAt(x + ox, y + oy);
                n++;
              }
            }
          }
          if (n > 0) cavity = max(0.0, sum / n - lum);
        } else {
          up = isSolid(x, y + 1) ? 1.0 : 0.0; // moss draped over a top edge
        }
        final baseRise = _textureStep(0.7, 1.0, (y - minY) / max(1, maxY - minY));
        final suitability = _textureFbm(x / scale, y / scale, seed + 401) * 0.85 +
            edgeGrowth * rim * 0.22 +
            gravity * rim * up * 0.25 +
            gravity * baseRise * 0.3 +
            crevice * ((1 - lum) * 0.12 + cavity * 1.2);
        var m = suitability - threshold;
        if (m <= 0) continue;
        // Fuzzy rim: sparse pixels where the cushion fades out.
        final fade = fuzz * 0.06;
        if (fade > 0 && m < fade && _textureHash(x, y, seed + 431) > m / fade) continue;
        mossAmount[i] = m;
        final clump = _textureCell(x / (scale * 0.3), y / (scale * 0.3), seed + 411, 0.9);
        mossHeight[i] = (_textureStep(0.0, 0.25, m) * (0.6 + 0.4 * (1 - clump.f1 / 0.6).clamp(0.0, 1.0))).clamp(0.0, 1.0);
      }
    }

    double heightAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final j = y * width + x;
      return mossAmount[j] > 0 ? mossHeight[j] : 0.0;
    }

    final darkMoss = _textureBlendColor(moss, 0xFF000000, 0.45, 255);
    final lightMoss = _textureBlendColor(moss, lichen, 0.4, 255);
    int mossRamp(double t) => t < 0.5
        ? _textureBlendColor(darkMoss, moss, t * 2, 255)
        : _textureBlendColor(moss, lightMoss, (t - 0.5) * 2, 255);

    // Pass 2: lichen rosettes on free surface, moss cushions on top.
    final lichenField = lichenMix * coverage;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (eligible[i] == 0) continue;
        final source = pixels[i];
        final alpha = source >>> 24;
        var color = source;
        var changed = false;

        if (lichenField > 0 && eligible[i] == 1) {
          final cell = _textureCell(x / (scale * 0.4 + 1), y / (scale * 0.4 + 1), seed + 503, 0.8);
          final host = _textureFbm(x / (scale * 1.6), y / (scale * 1.6), seed + 509) > 0.62 - lichenField * 0.3;
          if (host && cell.id < 0.25 + lichenField * 0.55) {
            final radius = 0.28 + cell.id * 0.2;
            if (cell.f1 < radius) {
              final tint = _textureBlendColor(lichen, moss, cell.id * 0.5, 255);
              final ring = cell.f1 > radius - 0.09;
              final lit = _textureHash(x, y, seed + 521) > 0.6;
              color = ring
                  ? _textureBlendColor(tint, 0xFF000000, 0.3, 255)
                  : _textureBlendColor(tint, 0xFFFFFFFF, lit ? 0.22 : 0.06, 255);
              color = _textureBlendColor(source, color, 0.9, 255);
              changed = true;
            }
          }
        }

        if (mossAmount[i] > 0) {
          final h = mossHeight[i];
          final relief = -((heightAt(x + 1, y, h) - heightAt(x - 1, y, h)) * lx +
                  (heightAt(x, y + 1, h) - heightAt(x, y - 1, h)) * ly) *
              0.9;
          final tone = (0.3 + h * 0.4 + relief + (_textureHash(x, y, seed + 439) - 0.5) * 0.2).clamp(0.0, 1.0);
          color = _textureBlendColor(source, mossRamp(tone), 0.9, 255);
          changed = true;
        }

        if (changed) {
          result[i] = (color & 0x00FFFFFF) | ((preserve ? alpha : 255) << 24);
        }
      }
    }
    return result;
  }
}
