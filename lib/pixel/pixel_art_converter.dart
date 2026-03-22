import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:image/image.dart' as img;

enum PixelArtDithering {
  none,
  floydSteinberg,
  bayer4x4,
  bayer8x8,
}

class PixelArtConversionOptions {
  /// Number of palette colors. 0 = full color (no quantization), otherwise 2–256.
  final int paletteSize;

  /// Dithering algorithm applied after palette quantization.
  /// Ignored when [paletteSize] == 0.
  final PixelArtDithering dithering;

  /// Pixels whose alpha is below this value become fully transparent.
  /// Range 0–255; default 128.
  final int alphaThreshold;

  const PixelArtConversionOptions({
    this.paletteSize = 0,
    this.dithering = PixelArtDithering.none,
    this.alphaThreshold = 128,
  });
}

/// Converts a full-resolution [img.Image] into pixel art (AARRGGBB Uint32List).
///
/// Pipeline:
///   1. Area-average downscale  — accurate color sampling for any scale ratio.
///   2. Alpha thresholding      — pixels below [alphaThreshold] become transparent.
///   3. Median-cut quantization — optional palette reduction.
///   4. Dithering               — Floyd-Steinberg or Bayer ordered matrix.
abstract final class PixelArtConverter {
  // ─── Bayer ordered-dithering matrices ────────────────────────────────────

  static const List<List<int>> _bayer4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
  ];

  static const List<List<int>> _bayer8 = [
    [0, 32, 8, 40, 2, 34, 10, 42],
    [48, 16, 56, 24, 50, 18, 58, 26],
    [12, 44, 4, 36, 14, 46, 6, 38],
    [60, 28, 52, 20, 62, 30, 54, 22],
    [3, 35, 11, 43, 1, 33, 9, 41],
    [51, 19, 59, 27, 49, 17, 57, 25],
    [15, 47, 7, 39, 13, 45, 5, 37],
    [63, 31, 55, 23, 61, 29, 53, 21],
  ];

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Extracts up to [maxColors] dominant colors from a full-resolution [source]
  /// image using area-average downscale + median-cut quantization.
  ///
  /// Suitable for backgrounds or photos where exact pixel-level palette is
  /// unknown. Colors are sorted by hue for a coherent visual order.
  static List<Color> extractPaletteFromImage(
    img.Image source, {
    int maxColors = 32,
  }) {
    // Downscale to a small grid for speed, then build palette
    final thumb = _areaAverageDownscale(source, 64, 64, 1);
    final palette = _medianCutPalette(thumb, maxColors);
    final colors = palette.map((c) => Color(c)).toList();
    _sortByHue(colors);
    return colors;
  }

  /// Extracts unique opaque colors from an already-converted pixel-art
  /// [pixels] buffer (AARRGGBB format). Transparent (alpha == 0) pixels are
  /// skipped. Resulting list is sorted by hue and capped at [maxColors].
  static List<Color> extractPaletteFromPixels(
    Uint32List pixels, {
    int maxColors = 256,
  }) {
    final seen = <int>{};
    for (final p in pixels) {
      if ((p >> 24) & 0xFF > 0) seen.add(p);
    }
    // If there are too many unique colors, quantize down
    List<Color> colors;
    if (seen.length <= maxColors) {
      colors = seen.map((c) => Color(c)).toList();
    } else {
      final quantized = _medianCutPalette(
        Uint32List.fromList(seen.toList()),
        maxColors,
      );
      colors = quantized.map((c) => Color(c)).toList();
    }
    _sortByHue(colors);
    return colors;
  }

  /// Sorts [colors] by HSL hue so the palette renders as a rainbow gradient.
  static void _sortByHue(List<Color> colors) {
    colors.sort((a, b) {
      final ha = _hue(a);
      final hb = _hue(b);
      if (ha != hb) return ha.compareTo(hb);
      // Same hue → sort by lightness (dark → light)
      return _lightness(a).compareTo(_lightness(b));
    });
  }

  static double _hue(Color c) {
    final r = c.r, g = c.g, b = c.b;
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    if (max == min) return 0;
    final d = max - min;
    double h;
    if (max == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return h / 6;
  }

  static double _lightness(Color c) =>
      (math.max(c.r, math.max(c.g, c.b)) +
          math.min(c.r, math.min(c.g, c.b))) /
      2;

  /// Convert [source] image to a [targetWidth]×[targetHeight] pixel-art
  /// AARRGGBB [Uint32List] using [options].
  static Uint32List convert({
    required img.Image source,
    required int targetWidth,
    required int targetHeight,
    PixelArtConversionOptions options = const PixelArtConversionOptions(),
  }) {
    // Step 1: area-average downscale + alpha threshold
    final pixels = _areaAverageDownscale(
      source,
      targetWidth,
      targetHeight,
      options.alphaThreshold,
    );

    // Step 2: optional palette quantization + dithering
    if (options.paletteSize > 0) {
      final palette = _medianCutPalette(pixels, options.paletteSize);
      if (palette.isNotEmpty) {
        return _applyPaletteWithDithering(
          pixels,
          targetWidth,
          targetHeight,
          palette,
          options.dithering,
        );
      }
    }

    return pixels;
  }

  // ─── Step 1: Area-average downscale ──────────────────────────────────────

  /// Each output pixel is the weighted average of all source pixels that fall
  /// within its corresponding source region. This gives much better results
  /// than nearest-neighbour or cubic for large scale-down ratios.
  static Uint32List _areaAverageDownscale(
    img.Image src,
    int dstW,
    int dstH,
    int alphaThreshold,
  ) {
    final out = Uint32List(dstW * dstH);
    final xScale = src.width / dstW;
    final yScale = src.height / dstH;

    for (int dy = 0; dy < dstH; dy++) {
      final srcY1 = dy * yScale;
      final srcY2 = srcY1 + yScale;
      final iy1 = srcY1.floor();
      final iy2 = srcY2.ceil().clamp(iy1 + 1, src.height);

      for (int dx = 0; dx < dstW; dx++) {
        final srcX1 = dx * xScale;
        final srcX2 = srcX1 + xScale;
        final ix1 = srcX1.floor();
        final ix2 = srcX2.ceil().clamp(ix1 + 1, src.width);

        double sumR = 0, sumG = 0, sumB = 0, sumA = 0, totalW = 0;

        for (int sy = iy1; sy < iy2; sy++) {
          final wy =
              math.min(sy + 1.0, srcY2) - math.max(sy.toDouble(), srcY1);
          for (int sx = ix1; sx < ix2; sx++) {
            final wx =
                math.min(sx + 1.0, srcX2) - math.max(sx.toDouble(), srcX1);
            final w = wx * wy;
            final p = src.getPixel(sx, sy);
            sumR += p.r * w;
            sumG += p.g * w;
            sumB += p.b * w;
            sumA += p.a * w;
            totalW += w;
          }
        }

        if (totalW > 0) {
          final a = (sumA / totalW).round().clamp(0, 255);
          if (a < alphaThreshold) {
            out[dy * dstW + dx] = 0; // fully transparent
          } else {
            final r = (sumR / totalW).round().clamp(0, 255);
            final g = (sumG / totalW).round().clamp(0, 255);
            final b = (sumB / totalW).round().clamp(0, 255);
            out[dy * dstW + dx] = (255 << 24) | (r << 16) | (g << 8) | b;
          }
        }
      }
    }

    return out;
  }

  // ─── Step 2: Median-cut palette ──────────────────────────────────────────

  /// Builds a palette of up to [maxColors] entries using the median-cut
  /// algorithm. Transparent pixels are excluded from palette construction.
  static List<int> _medianCutPalette(Uint32List pixels, int maxColors) {
    // Collect all opaque colors
    final colors = [
      for (final p in pixels)
        if ((p >> 24) & 0xFF > 0) p,
    ];
    if (colors.isEmpty) return [];

    var buckets = [colors];

    while (buckets.length < maxColors) {
      // Pick the bucket with the most entries
      int largestIdx = 0;
      for (int i = 1; i < buckets.length; i++) {
        if (buckets[i].length > buckets[largestIdx].length) largestIdx = i;
      }
      final bucket = buckets.removeAt(largestIdx);
      if (bucket.length <= 1) {
        buckets.add(bucket);
        break;
      }

      // Find channel with widest range
      int minR = 255, maxR = 0;
      int minG = 255, maxG = 0;
      int minB = 255, maxB = 0;
      for (final c in bucket) {
        final r = (c >> 16) & 0xFF;
        final g = (c >> 8) & 0xFF;
        final b = c & 0xFF;
        if (r < minR) minR = r;
        if (r > maxR) maxR = r;
        if (g < minG) minG = g;
        if (g > maxG) maxG = g;
        if (b < minB) minB = b;
        if (b > maxB) maxB = b;
      }

      final rangeR = maxR - minR;
      final rangeG = maxG - minG;
      final rangeB = maxB - minB;

      // Sort along the widest channel and split at median
      if (rangeR >= rangeG && rangeR >= rangeB) {
        bucket.sort((a, b) => ((a >> 16) & 0xFF).compareTo((b >> 16) & 0xFF));
      } else if (rangeG >= rangeB) {
        bucket.sort((a, b) => ((a >> 8) & 0xFF).compareTo((b >> 8) & 0xFF));
      } else {
        bucket.sort((a, b) => (a & 0xFF).compareTo(b & 0xFF));
      }

      final mid = bucket.length ~/ 2;
      buckets.add(bucket.sublist(0, mid));
      buckets.add(bucket.sublist(mid));
    }

    // Average each bucket → one palette entry
    return [
      for (final bucket in buckets)
        if (bucket.isEmpty)
          0xFF808080
        else
          () {
            int sumR = 0, sumG = 0, sumB = 0;
            for (final c in bucket) {
              sumR += (c >> 16) & 0xFF;
              sumG += (c >> 8) & 0xFF;
              sumB += c & 0xFF;
            }
            final n = bucket.length;
            return (0xFF << 24) |
                ((sumR ~/ n) << 16) |
                ((sumG ~/ n) << 8) |
                (sumB ~/ n);
          }(),
    ];
  }

  // ─── Step 3: Palette application + dithering ─────────────────────────────

  static Uint32List _applyPaletteWithDithering(
    Uint32List pixels,
    int w,
    int h,
    List<int> palette,
    PixelArtDithering dithering,
  ) {
    switch (dithering) {
      case PixelArtDithering.none:
        return _snapToNearest(pixels, palette);
      case PixelArtDithering.floydSteinberg:
        return _floydSteinberg(pixels, w, h, palette);
      case PixelArtDithering.bayer4x4:
        return _bayer(pixels, w, h, palette, _bayer4, 16);
      case PixelArtDithering.bayer8x8:
        return _bayer(pixels, w, h, palette, _bayer8, 64);
    }
  }

  /// Simple nearest-colour snap — no dithering.
  static Uint32List _snapToNearest(Uint32List pixels, List<int> palette) {
    final out = Uint32List(pixels.length);
    for (int i = 0; i < pixels.length; i++) {
      final p = pixels[i];
      out[i] = (p >> 24) & 0xFF == 0 ? 0 : _nearestColor(p, palette);
    }
    return out;
  }

  /// Floyd-Steinberg error-diffusion dithering.
  static Uint32List _floydSteinberg(
    Uint32List pixels,
    int w,
    int h,
    List<int> palette,
  ) {
    final rErr = List<double>.filled(pixels.length, 0);
    final gErr = List<double>.filled(pixels.length, 0);
    final bErr = List<double>.filled(pixels.length, 0);
    final out = Uint32List(pixels.length);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final i = y * w + x;
        final p = pixels[i];
        if ((p >> 24) & 0xFF == 0) {
          out[i] = 0;
          continue;
        }

        final r = ((p >> 16) & 0xFF) + rErr[i];
        final g = ((p >> 8) & 0xFF) + gErr[i];
        final b = (p & 0xFF) + bErr[i];

        final cr = r.round().clamp(0, 255);
        final cg = g.round().clamp(0, 255);
        final cb = b.round().clamp(0, 255);

        final nearest =
            _nearestColor((0xFF << 24) | (cr << 16) | (cg << 8) | cb, palette);
        out[i] = nearest;

        final nr = (nearest >> 16) & 0xFF;
        final ng = (nearest >> 8) & 0xFF;
        final nb = nearest & 0xFF;
        final er = r - nr;
        final eg = g - ng;
        final eb = b - nb;

        void distribute(int dx, int dy, double factor) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
            final ni = ny * w + nx;
            rErr[ni] += er * factor;
            gErr[ni] += eg * factor;
            bErr[ni] += eb * factor;
          }
        }

        distribute(1, 0, 7 / 16);
        distribute(-1, 1, 3 / 16);
        distribute(0, 1, 5 / 16);
        distribute(1, 1, 1 / 16);
      }
    }

    return out;
  }

  /// Bayer ordered-dithering using the supplied [matrix] and [matrixMax].
  static Uint32List _bayer(
    Uint32List pixels,
    int w,
    int h,
    List<int> palette,
    List<List<int>> matrix,
    int matrixMax,
  ) {
    final size = matrix.length;
    final out = Uint32List(pixels.length);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final i = y * w + x;
        final p = pixels[i];
        if ((p >> 24) & 0xFF == 0) {
          out[i] = 0;
          continue;
        }

        // Spread ±16 around zero so half the palette slots shift up, half down
        final threshold = (matrix[y % size][x % size] / matrixMax - 0.5) * 32;
        final r = ((p >> 16) & 0xFF) + threshold;
        final g = ((p >> 8) & 0xFF) + threshold;
        final b = (p & 0xFF) + threshold;

        final candidate = (0xFF << 24) |
            (r.round().clamp(0, 255) << 16) |
            (g.round().clamp(0, 255) << 8) |
            b.round().clamp(0, 255);

        out[i] = _nearestColor(candidate, palette);
      }
    }

    return out;
  }

  // ─── Utility ──────────────────────────────────────────────────────────────

  /// Returns the palette entry closest to [color] using perceptually-weighted
  /// squared-Euclidean distance (green channel weighted 4×, red 3×, blue 2×).
  static int _nearestColor(int color, List<int> palette) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    int best = palette[0];
    int bestDist = _colorDist(r, g, b, palette[0]);

    for (int i = 1; i < palette.length; i++) {
      final d = _colorDist(r, g, b, palette[i]);
      if (d < bestDist) {
        bestDist = d;
        best = palette[i];
      }
    }

    return best;
  }

  static int _colorDist(int r, int g, int b, int color) {
    final dr = r - ((color >> 16) & 0xFF);
    final dg = g - ((color >> 8) & 0xFF);
    final db = b - (color & 0xFF);
    return dr * dr * 3 + dg * dg * 4 + db * db * 2;
  }
}
