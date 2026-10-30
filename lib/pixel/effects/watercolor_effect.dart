part of 'effects.dart';

/// Watercolor wash over the artwork.
///
/// Colours are flattened into soft washes with edge-preserving diffusion, then
/// given the marks of real paint: pigment pooling at wash and silhouette edges,
/// backrun blooms, paper-grain granulation, diluted pigment, and uneven
/// drying. It is artwork-aware:
///  * diffusion only mixes similar colours, so washes bleed but shapes stay;
///  * dark line art stays crisp (`keepLines`), like ink under the paint;
///  * pigment can bloom a pixel or two past the silhouette (`edgeBleed`).
class WatercolorEffect extends Effect {
  WatercolorEffect([Map<String, dynamic>? parameters]) : super(EffectType.watercolor, {..._defaults, ...?parameters});

  static const _defaults = <String, dynamic>{
    'intensity': 0.5,
    'spread': 0.3,
    'texture': 0.2,
    'dilution': 0.15,
    'edgeDarkening': 0.5,
    'blooms': 0.25,
    'variation': 0.3,
    'keepLines': 0.4,
    'edgeBleed': 0.0,
    'paperColor': 0xFFFAF3E3,
    'seed': 42,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('intensity', 'Intensity', 'How strongly the watercolor look replaces the original.', 0.0, 1.0),
          ('spread', 'Color Spread', 'How far similar colors diffuse into each other.', 0.0, 1.0),
          ('dilution', 'Dilution', 'Thins the pigment toward the paper color.', 0.0, 1.0),
          ('edgeDarkening', 'Edge Pooling', 'Pigment gathering along wash and silhouette edges.', 0.0, 1.0),
          ('blooms', 'Blooms', 'Pale backrun blotches with darker rims.', 0.0, 1.0),
          ('variation', 'Wash Variation', 'Uneven drying across the washes.', 0.0, 1.0),
          ('texture', 'Paper Granulation', 'Pigment settling into the paper tooth.', 0.0, 1.0),
          ('keepLines', 'Keep Ink Lines', 'Keep dark, high-contrast lines crisp.', 0.0, 1.0),
          ('edgeBleed', 'Edge Bleed', 'Let pigment bloom just past the silhouette.', 0.0, 1.0),
          ('seed', 'Pattern Seed', 'Changes the random paper and bloom pattern.', 0, 9999),
        ])
          spec.$1: {
            'label': spec.$2,
            'description': spec.$3,
            'type': 'slider',
            'min': spec.$4,
            'max': spec.$5,
            'divisions': spec.$4 is int ? (spec.$5 - spec.$4).toInt() : 100,
          },
        'paperColor': {'label': 'Paper Color', 'type': 'color'},
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;
    final intensity = _number('intensity', 0, 1);
    final spread = _number('spread', 0, 1);
    final texture = _number('texture', 0, 1);
    final dilution = _number('dilution', 0, 1);
    final edgeDarkening = _number('edgeDarkening', 0, 1);
    final blooms = _number('blooms', 0, 1);
    final variation = _number('variation', 0, 1);
    final keepLines = _number('keepLines', 0, 1);
    final edgeBleed = _number('edgeBleed', 0, 1);
    final seed = _number('seed', 0, 9999).round();
    final paperValue = parameters['paperColor'];
    final paper = (paperValue is num ? paperValue.toInt() : (_defaults['paperColor'] as int)) | 0xFF000000;
    if (intensity == 0) return result;

    final count = width * height;
    final solid = Uint8List(count);
    final r = Float32List(count), g = Float32List(count), b = Float32List(count);
    for (var i = 0; i < count; i++) {
      final p = pixels[i];
      if ((p >>> 24) == 0) continue;
      solid[i] = 1;
      r[i] = ((p >> 16) & 0xFF).toDouble();
      g[i] = ((p >> 8) & 0xFF).toDouble();
      b[i] = (p & 0xFF).toDouble();
    }
    final shape = _silhouetteShape(solid, width, height, 0.0, 0.0);

    // Step 1: edge-preserving diffusion. Only similar colours mix, so washes
    // bleed into each other without losing shapes.
    var sr = r, sg = g, sb = b;
    final sigma = 18 + spread * 45;
    final denom = 2 * sigma * sigma;
    final passes = (spread * 4).round();
    for (var pass = 0; pass < passes; pass++) {
      final nr = Float32List(count), ng = Float32List(count), nb = Float32List(count);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (solid[i] == 0) continue;
          var wr = 0.0, wg = 0.0, wb = 0.0, wt = 0.0;
          for (var oy = -1; oy <= 1; oy++) {
            final yy = y + oy;
            if (yy < 0 || yy >= height) continue;
            for (var ox = -1; ox <= 1; ox++) {
              final xx = x + ox;
              if (xx < 0 || xx >= width) continue;
              final j = yy * width + xx;
              if (solid[j] == 0) continue;
              final dr = sr[j] - sr[i], dg = sg[j] - sg[i], db = sb[j] - sb[i];
              final w = (ox == 0 && oy == 0 ? 2.0 : 1.0) * exp(-(dr * dr + dg * dg + db * db) / denom);
              wr += sr[j] * w;
              wg += sg[j] * w;
              wb += sb[j] * w;
              wt += w;
            }
          }
          nr[i] = wr / wt;
          ng[i] = wg / wt;
          nb[i] = wb / wt;
        }
      }
      sr = nr;
      sg = ng;
      sb = nb;
    }

    double lumOf(int i) => (0.299 * sr[i] + 0.587 * sg[i] + 0.114 * sb[i]) / 255;
    double origLum(int i) => _textureLuminance(pixels[i]);

    // Step 2: paint marks per pixel.
    final washR = Float32List(count), washG = Float32List(count), washB = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (solid[i] == 0) continue;
        final px = x + 0.5, py = y + 0.5;
        var color = 0xFF000000 | (sr[i].round().clamp(0, 255) << 16) | (sg[i].round().clamp(0, 255) << 8) | sb[i].round().clamp(0, 255);
        final lum = lumOf(i);

        // Wash edge strength on the diffused image.
        var edge = 0.0;
        if (x + 1 < width && solid[i + 1] == 1) edge = max(edge, (lumOf(i + 1) - lum).abs());
        if (x > 0 && solid[i - 1] == 1) edge = max(edge, (lumOf(i - 1) - lum).abs());
        if (y + 1 < height && solid[i + width] == 1) edge = max(edge, (lumOf(i + width) - lum).abs());
        if (y > 0 && solid[i - width] == 1) edge = max(edge, (lumOf(i - width) - lum).abs());

        // Pigment pools where a wash dries: along colour edges and the silhouette.
        final rim = shape.distance[i] <= 1.5 ? 1.0 : 0.0;
        final pool = edgeDarkening * (_textureStep(0.04, 0.25, edge) * 0.4 + rim * 0.3);
        var shade = 1 - pool;

        // Blooms: pale backrun blotches with a darker, crisp rim.
        if (blooms > 0) {
          final field = _textureFbm(px / 7, py / 7, seed + 17);
          final threshold = 0.66 - blooms * 0.12;
          if (field > threshold) {
            color = _textureBlendColor(color, paper, blooms * 0.32, 255);
            if (field < threshold + 0.035) shade -= blooms * 0.18;
          }
        }

        // Uneven drying: slow lightness drift across the wash.
        if (variation > 0) {
          shade *= 1 + (_textureFbm(px / 12, py / 12, seed + 29) - 0.5) * variation * 0.45;
        }

        // Granulation: pigment settles in the paper's valleys, thins on its peaks.
        final tooth = _textureFbm(px * 0.9, py * 0.9, seed + 41) * 0.6 + _textureHash(x, y, seed + 43) * 0.4;
        if (texture > 0) shade *= 1 + (0.5 - tooth) * texture * (0.35 + 0.65 * (1 - lum)) * 0.9;
        final thin = dilution * (0.55 + 0.9 * tooth);
        if (thin > 0) color = _textureBlendColor(color, paper, thin.clamp(0.0, 0.8), 255);

        // Ink lines under the paint stay crisp.
        if (keepLines > 0) {
          final own = origLum(i);
          if (own < 0.35) {
            var contrast = 0.0;
            for (final j in [if (x > 0) i - 1, if (x + 1 < width) i + 1, if (y > 0) i - width, if (y + 1 < height) i + width]) {
              if (solid[j] == 1) contrast = max(contrast, origLum(j) - own);
            }
            if (contrast > 0.35 - keepLines * 0.27) {
              washR[i] = r[i];
              washG[i] = g[i];
              washB[i] = b[i];
              continue;
            }
          }
        }

        washR[i] = (_textureChannel(color, 16) * shade).clamp(0.0, 255.0);
        washG[i] = (_textureChannel(color, 8) * shade).clamp(0.0, 255.0);
        washB[i] = (_textureChannel(color, 0) * shade).clamp(0.0, 255.0);
      }
    }

    // Step 3: blend with the original and bloom a little past the silhouette.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (solid[i] == 1) {
          final p = pixels[i];
          int mix(double wash, int shift) {
            final o = (p >> shift) & 0xFF;
            return (o + (wash - o) * intensity).round().clamp(0, 255);
          }

          result[i] = (p & 0xFF000000) | (mix(washR[i], 16) << 16) | (mix(washG[i], 8) << 8) | mix(washB[i], 0);
        } else if (edgeBleed > 0) {
          final reach = 1 + (spread * 2).round();
          var wr = 0.0, wg = 0.0, wb = 0.0, n = 0, nearest = reach + 1;
          for (var oy = -reach; oy <= reach; oy++) {
            for (var ox = -reach; ox <= reach; ox++) {
              final xx = x + ox, yy = y + oy;
              if (xx < 0 || yy < 0 || xx >= width || yy >= height) continue;
              final j = yy * width + xx;
              if (solid[j] == 0) continue;
              wr += washR[j];
              wg += washG[j];
              wb += washB[j];
              n++;
              nearest = min(nearest, max(ox.abs(), oy.abs()));
            }
          }
          if (n == 0) continue;
          final chance = edgeBleed * (1.1 - nearest / (reach + 1));
          if (_textureHash(x, y, seed + 59) < chance) {
            final alpha = (150 * intensity * (1.1 - nearest / (reach + 1))).round().clamp(0, 255);
            if (alpha > 0) {
              result[i] = (alpha << 24) |
                  ((wr / n * 0.92).round().clamp(0, 255) << 16) |
                  ((wg / n * 0.92).round().clamp(0, 255) << 8) |
                  (wb / n * 0.92).round().clamp(0, 255);
            }
          }
        }
      }
    }
    return result;
  }
}
