part of 'effects.dart';

/// Oil painting made of individual brush dabs with lit impasto.
///
/// The image is repainted as overlapping elongated strokes. Each stroke takes
/// one colour from the artwork under it, has a rounded paint ridge with bristle
/// streaks, and is lit as thick paint. It is artwork-aware:
///  * stroke direction follows the form (edges and silhouette contours) and
///    falls back to `strokeDirection` in flat areas (`followForm`);
///  * strokes prefer pixels of their own colour, so they stop at edges instead
///    of smearing across them (more strictly with higher `detail`);
///  * only opaque pixels are sampled or painted, so the silhouette is kept.
class OilPaintEffect extends Effect {
  OilPaintEffect([Map<String, dynamic>? parameters]) : super(EffectType.oilPaint, {..._defaults, ...?parameters});

  static const _defaults = <String, dynamic>{
    'brushSize': 0.5,
    'detail': 0.6,
    'textureAmount': 0.7,
    'colorBlending': 0.5,
    'strokeDirection': 0.5,
    'followForm': 0.7,
    'gloss': 0.25,
    'lightDirection': 225.0,
    'seed': 42,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('brushSize', 'Brush Size', 'Size of the brush strokes.', 0.0, 1.0),
          ('detail', 'Detail', 'Smaller strokes that hold the original colors and edges.', 0.0, 1.0),
          ('textureAmount', 'Impasto', 'Thickness and bristle texture of the paint.', 0.0, 1.0),
          ('colorBlending', 'Color Blending', 'Wet-on-wet mixing between neighboring strokes.', 0.0, 1.0),
          ('strokeDirection', 'Stroke Direction', 'Base angle of the strokes (0 to 360 degrees).', 0.0, 1.0),
          ('followForm', 'Follow Form', 'Make strokes follow edges and contours instead of one angle.', 0.0, 1.0),
          ('gloss', 'Gloss', 'Wet highlights on the paint ridges.', 0.0, 1.0),
          ('lightDirection', 'Light Direction', null, 0.0, 360.0),
          ('seed', 'Stroke Seed', 'Changes stroke placement.', 0, 9999),
        ])
          spec.$1: {
            'label': spec.$2,
            if (spec.$3 != null) 'description': spec.$3,
            'type': 'slider',
            'min': spec.$4,
            'max': spec.$5,
            'divisions': spec.$4 is int ? (spec.$5 - spec.$4).toInt() : 100,
          },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;

    final brushSize = _number('brushSize', 0, 1);
    final detail = _number('detail', 0, 1);
    final impasto = _number('textureAmount', 0, 1);
    final blending = _number('colorBlending', 0, 1);
    final baseAngle = _number('strokeDirection', 0, 1) * 2 * pi;
    final follow = _number('followForm', 0, 1);
    final gloss = _number('gloss', 0, 1);
    final light = _number('lightDirection', 0, 360) * pi / 180;
    final lx = cos(light), ly = sin(light);
    final seed = _number('seed', 0, 9999).round();

    final count = width * height;
    final solid = Uint8List(count);
    var any = false;
    for (var i = 0; i < count; i++) {
      if ((pixels[i] >>> 24) != 0) {
        solid[i] = 1;
        any = true;
      }
    }
    if (!any) return result;

    // Stroke direction field: structure tensor of luminance and silhouette,
    // pulled toward the base angle where the image is flat.
    final signal = Float32List(count);
    for (var i = 0; i < count; i++) {
      signal[i] = solid[i] == 1 ? 0.2 + 0.6 * _textureLuminance(pixels[i]) : 0.0;
    }
    double sig(int x, int y) => signal[y.clamp(0, height - 1) * width + x.clamp(0, width - 1)];
    final ta = Float32List(count), tb = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final gx = sig(x + 1, y) - sig(x - 1, y), gy = sig(x, y + 1) - sig(x, y - 1);
        final mag = sqrt(gx * gx + gy * gy);
        if (mag < 0.02) continue;
        final w = min(1.0, mag * 4);
        final ux = gx / mag, uy = gy / mag;
        ta[y * width + x] = w * (ux * ux - uy * uy);
        tb[y * width + x] = w * 2 * ux * uy;
      }
    }
    // Wide smoothing carries contour direction into the middle of broad shapes.
    final radius = (1.5 + brushSize * 4.5) * (1.25 - detail * 0.55);
    final reach = (radius * 2.4).round().clamp(3, 10);
    final blurA = _silhouetteBlur(ta, width, height, reach), blurB = _silhouetteBlur(tb, width, height, reach);
    final prior = 0.02 + (1 - follow) * (1 - follow) * 6.0;
    final priorAxis = baseAngle + pi / 2;
    final pa = prior * cos(2 * priorAxis), pb = prior * sin(2 * priorAxis);
    final dirX = Float32List(count), dirY = Float32List(count);
    for (var i = 0; i < count; i++) {
      final a = 0.5 * atan2(blurB[i] + pb, blurA[i] + pa);
      dirX[i] = -sin(a);
      dirY[i] = cos(a);
    }

    // Strokes on a jittered grid.
    final halfLen = radius * 1.7, halfWid = radius * 0.75, spacing = radius * 1.3;
    final cols = (width / spacing).ceil() + 3, rows = (height / spacing).ceil() + 3;
    final strokeCount = cols * rows;
    final sx = Float32List(strokeCount), sy = Float32List(strokeCount);
    final sdx = Float32List(strokeCount), sdy = Float32List(strokeCount);
    final sr = Float32List(strokeCount), sg = Float32List(strokeCount), sb = Float32List(strokeCount);
    final valid = Uint8List(strokeCount);
    final sigma = 30 + (1 - detail) * 50, denom = 2 * sigma * sigma;
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final k = j * cols + i;
        final cx = (i - 1 + 0.5 + (_textureHash(i, j, seed + 1) - 0.5) * 0.8) * spacing;
        final cy = (j - 1 + 0.5 + (_textureHash(j, i, seed + 2) - 0.5) * 0.8) * spacing;
        sx[k] = cx;
        sy[k] = cy;
        final ci = cy.floor().clamp(0, height - 1) * width + cx.floor().clamp(0, width - 1);
        final dx = dirX[ci], dy = dirY[ci];
        sdx[k] = dx;
        sdy[k] = dy;
        // Colour: bilateral average of the artwork along and across the stroke.
        double refR = -1, refG = 0, refB = 0, wr = 0, wg = 0, wb = 0, wt = 0;
        if (solid[ci] == 1) {
          refR = ((pixels[ci] >> 16) & 0xFF).toDouble();
          refG = ((pixels[ci] >> 8) & 0xFF).toDouble();
          refB = (pixels[ci] & 0xFF).toDouble();
        }
        for (var s = -2; s <= 2; s++) {
          for (var a = -1; a <= 1; a++) {
            final x = (cx + dx * s * halfLen * 0.5 - dy * a * halfWid * 0.6).floor();
            final y = (cy + dy * s * halfLen * 0.5 + dx * a * halfWid * 0.6).floor();
            if (x < 0 || y < 0 || x >= width || y >= height || solid[y * width + x] == 0) continue;
            final p = pixels[y * width + x];
            final r = ((p >> 16) & 0xFF).toDouble(), g = ((p >> 8) & 0xFF).toDouble(), b = (p & 0xFF).toDouble();
            if (refR < 0) {
              refR = r;
              refG = g;
              refB = b;
            }
            final dr = r - refR, dg = g - refG, db = b - refB;
            final w = exp(-(dr * dr + dg * dg + db * db) / denom);
            wr += r * w;
            wg += g * w;
            wb += b * w;
            wt += w;
          }
        }
        if (wt > 0) {
          valid[k] = 1;
          // Each stroke carries a slightly different load of paint.
          final jitter = 1 + (_textureHash(i, j, seed + 3) - 0.5) * 0.16 * impasto;
          sr[k] = (wr / wt * jitter).clamp(0.0, 255.0);
          sg[k] = (wg / wt * jitter).clamp(0.0, 255.0);
          sb[k] = (wb / wt * jitter).clamp(0.0, 255.0);
        }
      }
    }

    // Assign every pixel to its best stroke: elongated distance plus a colour
    // penalty, so strokes hug regions of their own colour.
    final penalty = 2 + detail * 10;
    final baseR = Float32List(count), baseG = Float32List(count), baseB = Float32List(count);
    final heightMap = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = y * width + x;
        if (solid[p] == 0) continue;
        final px = x + 0.5, py = y + 0.5;
        final orig = pixels[p];
        final or = ((orig >> 16) & 0xFF).toDouble(), og = ((orig >> 8) & 0xFF).toDouble(), ob = (orig & 0xFF).toDouble();
        final ci = (px / spacing).floor() + 1, cj = (py / spacing).floor() + 1;
        var best = -1, bestScore = double.infinity;
        var bu = 0.0, bv = 0.0;
        for (var j = max(0, cj - 2); j <= min(rows - 1, cj + 2); j++) {
          for (var i = max(0, ci - 2); i <= min(cols - 1, ci + 2); i++) {
            final k = j * cols + i;
            if (valid[k] == 0) continue;
            final ox = px - sx[k], oy = py - sy[k];
            final u = (ox * sdx[k] + oy * sdy[k]) / halfLen, v = (-ox * sdy[k] + oy * sdx[k]) / halfWid;
            final dr = (or - sr[k]) / 255, dg = (og - sg[k]) / 255, db = (ob - sb[k]) / 255;
            final score = u * u + v * v + penalty * (dr * dr + dg * dg + db * db);
            if (score < bestScore) {
              bestScore = score;
              best = k;
              bu = u;
              bv = v;
            }
          }
        }
        if (best < 0) {
          baseR[p] = or;
          baseG[p] = og;
          baseB[p] = ob;
          heightMap[p] = 0.3;
          continue;
        }
        baseR[p] = sr[best];
        baseG[p] = sg[best];
        baseB[p] = sb[best];
        // Impasto profile: a ridge down the stroke, tapering at both ends, with
        // bristle streaks running along it.
        final across = bv.clamp(-1.0, 1.0);
        final dome = 1 - across * across;
        final taper = 1 - min(1.0, bu * bu) * 0.6;
        final bristle = _textureNoise(bv * halfWid * 0.9 + best * 13.7, bu * 0.4, seed + 5);
        heightMap[p] = (0.15 + 0.5 * dome * taper + (bristle - 0.5) * 0.5 * (0.4 + 0.6 * dome)).clamp(0.0, 1.0);
      }
    }

    // Wet-on-wet mixing with neighbouring strokes.
    var mr = baseR, mg = baseG, mb = baseB;
    if (blending > 0) {
      mr = Float32List(count);
      mg = Float32List(count);
      mb = Float32List(count);
      final amount = blending * 0.45;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final p = y * width + x;
          if (solid[p] == 0) continue;
          var ar = 0.0, ag = 0.0, ab = 0.0, n = 0;
          for (final q in [if (x > 0) p - 1, if (x + 1 < width) p + 1, if (y > 0) p - width, if (y + 1 < height) p + width]) {
            if (solid[q] == 0) continue;
            ar += baseR[q];
            ag += baseG[q];
            ab += baseB[q];
            n++;
          }
          mr[p] = n == 0 ? baseR[p] : baseR[p] + (ar / n - baseR[p]) * amount;
          mg[p] = n == 0 ? baseG[p] : baseG[p] + (ag / n - baseG[p]) * amount;
          mb[p] = n == 0 ? baseB[p] : baseB[p] + (ab / n - baseB[p]) * amount;
        }
      }
    }

    double heightAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final q = y * width + x;
      return solid[q] == 1 ? heightMap[q] : fallback;
    }

    // Light the paint and blend back some of the original for detail.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = y * width + x;
        if (solid[p] == 0) continue;
        final orig = pixels[p];
        final h = heightMap[p];
        final relief = -((heightAt(x + 1, y, h) - heightAt(x - 1, y, h)) * lx + (heightAt(x, y + 1, h) - heightAt(x, y - 1, h)) * ly) *
            impasto *
            2.2;
        final shade = 1 + relief.clamp(-0.55, 0.55) * 0.8 + (h - 0.4) * impasto * 0.3;
        final keep = detail * 0.45;
        final spec = gloss > 0 ? max(0.0, relief - 0.3) * gloss * 1.5 : 0.0;
        int channel(double mixed, int shift) {
          final o = (orig >> shift) & 0xFF;
          final c = (mixed + (o - mixed) * keep) * shade;
          return (c + (255 - c) * spec).round().clamp(0, 255);
        }

        result[p] = (orig & 0xFF000000) | (channel(mr[p], 16) << 16) | (channel(mg[p], 8) << 8) | channel(mb[p], 0);
      }
    }
    return result;
  }
}
