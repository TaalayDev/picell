import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

/// Gradient shapes. Persisted by index, so new values go at the end.
enum GradientType {
  /// Bands perpendicular to start → end.
  linear,

  /// Circles around start; end sets the radius.
  radial,

  /// Linear mirrored around start: end colour on both sides.
  reflected,

  /// Squares (rotated to the drag direction) around start.
  diamond,

  /// Sweeps once around start, beginning in the drag direction.
  angle,
}

enum GradientDither {
  none(0),
  bayer2(2),
  bayer4(4),
  bayer8(8);

  /// Side length of the Bayer matrix (0 = no dithering).
  final int size;

  const GradientDither(this.size);
}

enum GradientBlend {
  /// Gradient pixels overwrite the layer, including alpha.
  replace,

  /// Gradient is alpha-composited over the existing pixels.
  over,

  /// Like [over], but only on opaque-ish pixels and keeping their alpha.
  lockAlpha,
}

/// Immutable description of one gradient application.
///
/// [start] / [end] are in canvas pixel coordinates; pixel (x, y) is sampled
/// at its centre (x + 0.5, y + 0.5).
class GradientSpec {
  final GradientType type;
  final Offset start;
  final Offset end;

  /// ARGB colour stops, evenly spaced from start (t = 0) to end (t = 1).
  final List<int> stops;

  /// Number of solid colour bands, or null for a smooth gradient.
  ///
  /// When [steps] equals `stops.length` the stops are used as the bands
  /// verbatim (palette ramp), so no new colours are introduced.
  final int? steps;

  final GradientDither dither;

  /// Fraction (0..1) of each band transition that is dithered. 1 dithers the
  /// whole distance between band centres; smaller values keep solid bands
  /// with a narrow dithered seam. Ignored when [dither] is none.
  final double ditherSpread;

  final GradientBlend blend;

  const GradientSpec({
    required this.start,
    required this.end,
    required this.stops,
    this.type = GradientType.linear,
    this.steps,
    this.dither = GradientDither.none,
    this.ditherSpread = 1.0,
    this.blend = GradientBlend.replace,
  })  : assert(steps == null || steps >= 2),
        assert(ditherSpread >= 0 && ditherSpread <= 1);

  bool get isSmooth => steps == null;
}

/// Pure pixel-buffer gradient renderer — no Flutter widgets, no `Color`
/// allocations per pixel.
class GradientRenderer {
  const GradientRenderer._();

  /// Returns a copy of [base] with the gradient applied to every pixel where
  /// [mask] is non-zero (null mask = whole buffer).
  static Uint32List render({
    required Uint32List base,
    required int width,
    required int height,
    required GradientSpec spec,
    Uint8List? mask,
  }) {
    assert(base.length == width * height);
    assert(mask == null || mask.length == base.length);
    final out = Uint32List.fromList(base);
    if (spec.stops.isEmpty) return out;

    final bands = spec.isSmooth ? null : bandColors(spec.stops, spec.steps!);
    final ditherSize = bands == null ? 0 : spec.dither.size;
    final bayer = ditherSize == 0 ? null : _bayer(ditherSize);
    final bayerCells = ditherSize * ditherSize;

    final sx = spec.start.dx, sy = spec.start.dy;
    final dx = spec.end.dx - sx, dy = spec.end.dy - sy;
    final lenSq = dx * dx + dy * dy;
    final len = sqrt(lenSq);

    for (int y = 0; y < height; y++) {
      final cy = y + 0.5 - sy;
      final row = y * width;
      for (int x = 0; x < width; x++) {
        final i = row + x;
        if (mask != null && mask[i] == 0) continue;

        final dst = base[i];
        if (spec.blend == GradientBlend.lockAlpha && (dst >>> 24) == 0) {
          continue;
        }

        final cx = x + 0.5 - sx;
        double t;
        if (lenSq == 0) {
          t = 0;
        } else {
          t = switch (spec.type) {
            GradientType.linear => (cx * dx + cy * dy) / lenSq,
            GradientType.radial => sqrt(cx * cx + cy * cy) / len,
            GradientType.reflected => ((cx * dx + cy * dy) / lenSq).abs(),
            // |along| + |across| in units of the drag length.
            GradientType.diamond => ((cx * dx + cy * dy).abs() + (cx * dy - cy * dx).abs()) / lenSq,
            GradientType.angle => _sweep(cx, cy, dx, dy),
          };
        }
        t = t.clamp(0.0, 1.0);

        final int src;
        if (bands == null) {
          src = sampleRamp(spec.stops, t);
        } else {
          final threshold =
              bayer == null ? 0.5 : (bayer[(y % ditherSize) * ditherSize + (x % ditherSize)] + 0.5) / bayerCells;
          src = bands[bandIndex(
            t,
            bands.length,
            threshold: threshold,
            spread: bayer == null ? 0 : spec.ditherSpread,
          )];
        }

        out[i] = switch (spec.blend) {
          GradientBlend.replace => src,
          GradientBlend.over => blendOver(src, dst),
          GradientBlend.lockAlpha => (blendOver(src, dst) & 0x00FFFFFF) | (dst & 0xFF000000),
        };
      }
    }
    return out;
  }

  /// Clockwise (in screen space) turn from the drag direction, 0..1.
  static double _sweep(double cx, double cy, double dx, double dy) {
    if (cx == 0 && cy == 0) return 0;
    final a = atan2(dx * cy - dy * cx, dx * cx + dy * cy) / (2 * pi);
    return a < 0 ? a + 1 : a;
  }

  /// Picks a band for position [t] in [0, 1] across [count] equal-width bands.
  ///
  /// Band k is centred at (k + 0.5) / count. Between two band centres the
  /// fractional position is compared against [threshold] (0.5 = hard edge,
  /// Bayer values = ordered dither). [spread] narrows the dithered zone
  /// around each band edge.
  static int bandIndex(
    double t,
    int count, {
    double threshold = 0.5,
    double spread = 0,
  }) {
    final v = (t * count - 0.5).clamp(0.0, (count - 1).toDouble());
    final k = v.floor();
    if (k >= count - 1) return count - 1;
    var f = v - k;
    if (spread <= 0) {
      f = f >= 0.5 ? 1 : 0;
    } else if (spread < 1) {
      f = ((f - 0.5) / spread + 0.5).clamp(0.0, 1.0);
    }
    // f in [0, 1], threshold in (0, 1): f = 0 → k, f = 1 → k + 1.
    return f + threshold >= 1 ? k + 1 : k;
  }

  /// The solid colours for [steps] bands. Uses [stops] directly when the
  /// counts match, otherwise samples the ramp at evenly spaced positions.
  static List<int> bandColors(List<int> stops, int steps) {
    if (stops.length == steps) return List<int>.of(stops);
    return List<int>.generate(
      steps,
      (i) => sampleRamp(stops, i / (steps - 1)),
    );
  }

  /// Interpolates the evenly spaced [stops] at [t] in premultiplied space, so
  /// fading to transparent keeps the opaque stop's hue instead of darkening.
  static int sampleRamp(List<int> stops, double t) {
    if (stops.length == 1) return stops[0];
    final pos = t.clamp(0.0, 1.0) * (stops.length - 1);
    final k = min(pos.floor(), stops.length - 2);
    return lerpPremultiplied(stops[k], stops[k + 1], pos - k);
  }

  static int lerpPremultiplied(int a, int b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    final aa = (a >>> 24) / 255.0, ba = (b >>> 24) / 255.0;
    final alpha = aa + (ba - aa) * t;
    if (alpha <= 0) return 0;
    int ch(int shift) {
      final ca = ((a >>> shift) & 0xFF) * aa;
      final cb = ((b >>> shift) & 0xFF) * ba;
      return ((ca + (cb - ca) * t) / alpha).round().clamp(0, 255);
    }

    return ((alpha * 255).round() << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  /// Bit-exact port of `Color.alphaBlend` on ARGB ints (straight alpha, src
  /// over dst), without allocating `Color`s.
  static int blendOver(int src, int dst) {
    final fa = src >>> 24;
    if (fa == 0xFF) return src;
    if (fa == 0) return dst;
    final alpha = fa / 255.0;
    final backAlpha = (dst >>> 24) / 255.0 * (1 - alpha);
    final outAlpha = alpha + backAlpha;
    int ch(int shift) {
      final f = ((src >>> shift) & 0xFF) / 255.0;
      final b = ((dst >>> shift) & 0xFF) / 255.0;
      return ((f * alpha + b * backAlpha) / outAlpha * 255.0).round() & 0xFF;
    }

    return (((outAlpha * 255.0).round() & 0xFF) << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  static final Map<int, Uint8List> _bayerCache = {};

  /// Row-major Bayer index matrix of side [size] (a power of two), values
  /// 0 .. size² - 1.
  static Uint8List _bayer(int size) => _bayerCache.putIfAbsent(size, () {
        var m = Uint8List.fromList([0]);
        var n = 1;
        while (n < size) {
          final next = Uint8List(4 * n * n);
          final n2 = n * 2;
          for (int y = 0; y < n; y++) {
            for (int x = 0; x < n; x++) {
              final v = 4 * m[y * n + x];
              next[y * n2 + x] = v;
              next[y * n2 + x + n] = v + 2;
              next[(y + n) * n2 + x] = v + 3;
              next[(y + n) * n2 + x + n] = v + 1;
            }
          }
          m = next;
          n = n2;
        }
        return m;
      });

  /// Exposed for tests.
  static Uint8List bayerMatrix(int size) => _bayer(size);
}
