import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'affine2.dart';
import 'part_rasterizer.dart';

/// A part prepared for rotation with the RotSprite approach: the pixels are
/// enlarged with the Scale2x (EPX) edge-preserving rule a few times, rotated
/// at that size with nearest-neighbour sampling, and read back at one sample
/// per output pixel. Diagonal edges and 1px lines survive rotation far better
/// than sampling the original pixels directly, and still no colour that is not
/// already in the art can appear.
///
/// Building the enlarged image is the expensive part, so keep one source per
/// part and call [rasterize] for every pose.
class RotSpriteSource {
  /// [source] is a `width * height` buffer; pixels where [mask] is 0 are left
  /// out (so one layer can be split across bones without colour bleeding
  /// from the neighbour). Neither argument is modified.
  RotSpriteSource(Uint32List source, this.width, this.height, {Uint8List? mask})
      : factor = factorFor(width, height),
        _base = _masked(source, width, height, mask) {
    var hi = _base;
    var w = width, h = height;
    for (var f = 1; f < factor; f *= 2) {
      hi = scale2x(hi, w, h);
      w *= 2;
      h *= 2;
    }
    _hi = hi;
  }

  final int width;
  final int height;

  /// How many times larger the working image is than the part (2, 4 or 8).
  final int factor;

  final Uint32List _base;
  late final Uint32List _hi;

  /// Big canvases get a smaller factor so the working image stays around a
  /// megapixel.
  static int factorFor(int width, int height) {
    final pixels = width * height;
    if (pixels <= 128 * 128) return 8;
    if (pixels <= 256 * 256) return 4;
    return 2;
  }

  static Uint32List _masked(Uint32List source, int w, int h, Uint8List? mask) {
    if (source.length != w * h) throw ArgumentError('source has ${source.length} pixels, expected ${w * h}');
    if (mask == null) return Uint32List.fromList(source);
    if (mask.length != source.length) {
      throw ArgumentError('mask has ${mask.length} entries, expected ${source.length}');
    }
    final out = Uint32List(source.length);
    for (var i = 0; i < out.length; i++) {
      if (mask[i] != 0) out[i] = source[i];
    }
    return out;
  }

  /// Scale2x: each pixel becomes 2x2, and a corner takes a neighbour's colour
  /// when the two neighbours on that side agree and the others do not, which
  /// rounds inside corners without blurring. Edges count as the pixel itself.
  static Uint32List scale2x(Uint32List src, int w, int h) {
    final out = Uint32List(src.length * 4);
    final ow = w * 2;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = src[y * w + x];
        final a = y > 0 ? src[(y - 1) * w + x] : p; // up
        final b = x < w - 1 ? src[y * w + x + 1] : p; // right
        final c = x > 0 ? src[y * w + x - 1] : p; // left
        final d = y < h - 1 ? src[(y + 1) * w + x] : p; // down
        var p1 = p, p2 = p, p3 = p, p4 = p;
        if (c == a && c != d && a != b) p1 = a;
        if (a == b && a != c && b != d) p2 = b;
        if (d == c && d != b && c != a) p3 = c;
        if (b == d && b != a && d != c) p4 = d;
        final o = (y * 2) * ow + x * 2;
        out[o] = p1;
        out[o + 1] = p2;
        out[o + ow] = p3;
        out[o + ow + 1] = p4;
      }
    }
    return out;
  }

  /// Whether [t] maps pixels onto pixels exactly (identity, mirror, quarter
  /// turns): there the original pixels are used untouched, because smoothing
  /// would only change art that did not need to change.
  static bool isAxisAligned(Affine2 t) {
    bool unit(double v) => v.abs() < 1e-9 || (v.abs() - 1).abs() < 1e-9;
    if (!(unit(t.a) && unit(t.b) && unit(t.c) && unit(t.d))) return false;
    return ((t.a.abs() < 1e-9) != (t.b.abs() < 1e-9)) && ((t.c.abs() < 1e-9) != (t.d.abs() < 1e-9));
  }

  /// The part drawn under [transform] (rest pixel -> posed pixel), as a new
  /// `width * height` buffer. A collapsing transform gives an empty buffer.
  Uint32List rasterize(Affine2 transform) {
    if (isAxisAligned(transform)) {
      return PartRasterizer.rasterize(_base, width, height, transform);
    }
    final out = Uint32List(width * height);
    final inverse = transform.invert();
    if (inverse == null) return out;

    final hw = width * factor, hh = height * factor;
    const eps = 1e-7;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final src = inverse.apply(Offset(x + 0.5, y + 0.5));
        final sx = (src.dx * factor + eps).floor();
        final sy = (src.dy * factor + eps).floor();
        if (sx < 0 || sy < 0 || sx >= hw || sy >= hh) continue;
        out[y * width + x] = _hi[sy * hw + sx];
      }
    }
    // The original pixels fill whatever sampling left empty, so thin lines
    // and joints never drop out (see PartRasterizer.fillDropped).
    PartRasterizer.fillDropped(out, _base, width, height, transform);
    return out;
  }
}

/// RotSprite for a free-standing buffer, such as the floating pixels of a
/// canvas selection. Same contract as `PixelUtils.applyRotationWithBounds`:
/// [pixels] is the [srcWidth]×[srcHeight] content of [originalBounds]; the
/// result is it rotated by [angle] radians (clockwise on screen) about
/// [center], laid out for [rotatedBounds]. Both rectangles are in canvas
/// coordinates and may be fractional.
Uint32List rotSpriteWithBounds(
  Uint32List pixels,
  int srcWidth,
  int srcHeight,
  double angle,
  Rect originalBounds,
  Rect rotatedBounds,
  Offset center,
) {
  final targetWidth = rotatedBounds.width.round();
  final targetHeight = rotatedBounds.height.round();
  if (targetWidth <= 0 || targetHeight <= 0 || srcWidth <= 0 || srcHeight <= 0) return Uint32List(0);

  // RotSpriteSource draws into a buffer the size of its source. Give the
  // source and the result their own origins (each rectangle's top-left) in a
  // buffer big enough for either, and fold the offset into the transform.
  final width = srcWidth > targetWidth ? srcWidth : targetWidth;
  final height = srcHeight > targetHeight ? srcHeight : targetHeight;
  final padded = Uint32List(width * height);
  for (var y = 0; y < srcHeight; y++) {
    padded.setRange(y * width, y * width + srcWidth, pixels, y * srcWidth);
  }
  final transform = Affine2.translation(originalBounds.left, originalBounds.top)
      .then(Affine2.rotationAbout(angle * 180 / math.pi, center))
      .thenTranslate(-rotatedBounds.left, -rotatedBounds.top);
  final drawn = RotSpriteSource(padded, width, height).rasterize(transform);

  final out = Uint32List(targetWidth * targetHeight);
  for (var y = 0; y < targetHeight; y++) {
    out.setRange(y * targetWidth, (y + 1) * targetWidth, drawn, y * width);
  }
  return out;
}
