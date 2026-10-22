import 'dart:typed_data';
import 'dart:ui';

import 'affine2.dart';

/// Draws one rigid part of a rest-pose layer under a transform.
abstract final class PartRasterizer {
  /// Returns a new `width * height` buffer holding [source] moved by
  /// [transform] (rest pixel -> posed pixel), restricted to [mask] when given.
  ///
  /// Uses nearest-neighbour sampling at pixel centres: every output pixel is
  /// a copy of exactly one source pixel, so no new colours appear and
  /// palettes survive. Whole-pixel moves and quarter turns about a pixel
  /// grid point are exact.
  ///
  /// A transform that collapses the image (determinant 0) yields an empty
  /// buffer. [source] and [mask] are never modified.
  static Uint32List rasterize(
    Uint32List source,
    int width,
    int height,
    Affine2 transform, {
    Uint8List? mask,
  }) {
    if (source.length != width * height) {
      throw ArgumentError('source has ${source.length} pixels, expected ${width * height}');
    }
    if (mask != null && mask.length != source.length) {
      throw ArgumentError('mask has ${mask.length} entries, expected ${source.length}');
    }

    final out = Uint32List(source.length);
    final inverse = transform.invert();
    if (inverse == null) return out;

    // Sampling exactly on a pixel edge would make floor() depend on float
    // noise; nudge so edges resolve the same way on every platform.
    const eps = 1e-7;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final src = inverse.apply(Offset(x + 0.5, y + 0.5));
        final sx = (src.dx + eps).floor();
        final sy = (src.dy + eps).floor();
        if (sx < 0 || sy < 0 || sx >= width || sy >= height) continue;
        final i = sy * width + sx;
        if (mask != null && mask[i] == 0) continue;
        out[y * width + x] = source[i];
      }
    }
    return out;
  }
}
