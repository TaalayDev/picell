import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'pixel_utils.dart';

/// RotSprite rotation for pixel art: the source is upscaled 8× with Scale2x
/// (three passes), rotated with nearest-neighbour sampling, and sampled back
/// down at each destination pixel's centre. Lines stay one pixel wide and
/// diagonals stay clean, with no blended colours, unlike plain
/// nearest-neighbour (jagged, gappy) or bilinear (blurry) rotation.
///
/// Same contract as [PixelUtils.applyRotationWithBounds]: [pixels] is the
/// [srcWidth]×[srcHeight] content of [originalBounds]; the result is laid out
/// for [rotatedBounds], rotated by [angle] radians around [center]. Quarter
/// turns are exact and skip the upscale.
Uint32List rotSpriteWithBounds(
  Uint32List pixels,
  int srcWidth,
  int srcHeight,
  double angle,
  Rect originalBounds,
  Rect rotatedBounds,
  Offset center,
) {
  if (_isQuarterTurn(angle)) {
    return PixelUtils.applyRotationWithBounds(
        pixels, srcWidth, srcHeight, angle, originalBounds, rotatedBounds, center, 0, 0);
  }
  final targetWidth = rotatedBounds.width.round();
  final targetHeight = rotatedBounds.height.round();
  if (targetWidth <= 0 || targetHeight <= 0 || srcWidth <= 0 || srcHeight <= 0) return Uint32List(0);

  var big = pixels;
  var bigWidth = srcWidth, bigHeight = srcHeight;
  for (var pass = 0; pass < 3; pass++) {
    big = scale2x(big, bigWidth, bigHeight);
    bigWidth *= 2;
    bigHeight *= 2;
  }
  const scale = 8;

  final result = Uint32List(targetWidth * targetHeight);
  final cosA = math.cos(-angle);
  final sinA = math.sin(-angle);
  for (var y = 0; y < targetHeight; y++) {
    for (var x = 0; x < targetWidth; x++) {
      // Destination pixel centre, mapped back into the source.
      final dx = rotatedBounds.left + x + 0.5 - center.dx;
      final dy = rotatedBounds.top + y + 0.5 - center.dy;
      final sourceX = center.dx + dx * cosA - dy * sinA - originalBounds.left;
      final sourceY = center.dy + dx * sinA + dy * cosA - originalBounds.top;
      final bx = (sourceX * scale).floor();
      final by = (sourceY * scale).floor();
      if (bx < 0 || by < 0 || bx >= bigWidth || by >= bigHeight) continue;
      result[y * targetWidth + x] = big[by * bigWidth + bx];
    }
  }
  return result;
}

bool _isQuarterTurn(double angle) {
  final turns = angle / (math.pi / 2);
  return (turns - turns.roundToDouble()).abs() < 1e-9;
}

/// Scale2x (EPX): doubles [pixels] while rounding off staircase corners.
/// Pixels outside the image count as transparent.
Uint32List scale2x(Uint32List pixels, int width, int height) {
  final out = Uint32List(width * height * 4);
  final outWidth = width * 2;
  int at(int x, int y) => x < 0 || y < 0 || x >= width || y >= height ? 0 : pixels[y * width + x];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = pixels[y * width + x];
      final a = at(x, y - 1), b = at(x + 1, y), c = at(x - 1, y), d = at(x, y + 1);
      final o = (y * 2) * outWidth + x * 2;
      out[o] = c == a && c != d && a != b ? a : p;
      out[o + 1] = a == b && a != c && b != d ? b : p;
      out[o + outWidth] = d == c && d != b && c != a ? c : p;
      out[o + outWidth + 1] = b == d && b != a && d != c ? d : p;
    }
  }
  return out;
}
