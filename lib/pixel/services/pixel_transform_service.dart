import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:vector_math/vector_math_64.dart';

import '../../data/models/selection_region.dart';

/// Exact (non-interpolated) flips and quarter-turn rotations.
enum PixelTransform {
  flipHorizontal,
  flipVertical,
  rotate90Clockwise,
  rotate90CounterClockwise,
  rotate180,
}

class SelectionTransformResult {
  const SelectionTransformResult({required this.pixels, required this.region});

  final Uint32List pixels;
  final SelectionRegion region;
}

/// Pixel-exact selection transforms.
///
/// A selection's bounding box is mapped onto itself (flips, 180°) or onto a
/// box of swapped size centred on the old one (90° turns). Pixel cells map
/// to pixel cells, so the transformed selection shape still lines up with the
/// moved pixels.
class PixelTransformService {
  const PixelTransformService._();

  static bool swapsDimensions(PixelTransform transform) =>
      transform == PixelTransform.rotate90Clockwise ||
      transform == PixelTransform.rotate90CounterClockwise;

  /// Returns a new pixel buffer and region; [layerPixels] is not modified.
  /// Returns null when the selection is empty.
  static SelectionTransformResult? transformSelection({
    required Uint32List layerPixels,
    required int canvasWidth,
    required int canvasHeight,
    required SelectionRegion region,
    required PixelTransform transform,
  }) {
    final minX = region.bounds.left.floor();
    final minY = region.bounds.top.floor();
    final w = region.bounds.right.ceil() - minX;
    final h = region.bounds.bottom.ceil() - minY;
    if (w <= 0 || h <= 0) return null;

    final swap = swapsDimensions(transform);
    final newW = swap ? h : w;
    final newH = swap ? w : h;

    // When the size changes by an odd amount the centred box lands on a
    // half cell. Rounding down when the box gets taller and up when it gets
    // wider makes opposite turns cancel exactly, so four quarter turns (or a
    // turn and its inverse) return to the starting box.
    int centred(int start, int oldSize, int newSize) {
      final half = (oldSize - newSize) / 2;
      return start + (newH > h ? half.floor() : half.ceil());
    }

    final newMinX = _fit(centred(minX, w, newW), newW, canvasWidth);
    final newMinY = _fit(centred(minY, h, newH), newH, canvasHeight);

    // Maps a local cell (lx, ly) in the old box to a cell in the new box.
    (int, int) mapCell(int lx, int ly) => switch (transform) {
          PixelTransform.flipHorizontal => (w - 1 - lx, ly),
          PixelTransform.flipVertical => (lx, h - 1 - ly),
          PixelTransform.rotate180 => (w - 1 - lx, h - 1 - ly),
          PixelTransform.rotate90Clockwise => (h - 1 - ly, lx),
          PixelTransform.rotate90CounterClockwise => (ly, w - 1 - lx),
        };

    final result = Uint32List.fromList(layerPixels);
    final moved = <(int, int, int)>[];

    final fromX = max(0, minX);
    final toX = min(canvasWidth, minX + w);
    final fromY = max(0, minY);
    final toY = min(canvasHeight, minY + h);

    for (var y = fromY; y < toY; y++) {
      for (var x = fromX; x < toX; x++) {
        if (!region.contains(x, y)) continue;
        final index = y * canvasWidth + x;
        final color = layerPixels[index];
        result[index] = 0;
        if (color == 0) continue;
        final (nx, ny) = mapCell(x - minX, y - minY);
        moved.add((newMinX + nx, newMinY + ny, color));
      }
    }

    for (final (x, y, color) in moved) {
      if (x < 0 || y < 0 || x >= canvasWidth || y >= canvasHeight) continue;
      result[y * canvasWidth + x] = color;
    }

    return SelectionTransformResult(
      pixels: result,
      region: _transformRegion(
        region,
        transform,
        w.toDouble(),
        h.toDouble(),
        minX.toDouble(),
        minY.toDouble(),
        newMinX.toDouble(),
        newMinY.toDouble(),
      ),
    );
  }

  /// Transforms a whole layer about the canvas centre. Flips and 180° are
  /// exact; a 90° turn on a non-square canvas rotates about the centre and
  /// clips what no longer fits.
  static Uint32List transformLayerPixels({
    required Uint32List pixels,
    required int width,
    required int height,
    required PixelTransform transform,
  }) {
    final result = Uint32List(pixels.length);
    final cwX = (width + height - 2) ~/ 2;
    final cwY = ((height - width) / 2).floor();
    final ccwX = ((width - height) / 2).floor();
    final ccwY = (width + height - 2) ~/ 2;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final color = pixels[y * width + x];
        if (color == 0) continue;
        final (nx, ny) = switch (transform) {
          PixelTransform.flipHorizontal => (width - 1 - x, y),
          PixelTransform.flipVertical => (x, height - 1 - y),
          PixelTransform.rotate180 => (width - 1 - x, height - 1 - y),
          PixelTransform.rotate90Clockwise => (cwX - y, cwY + x),
          PixelTransform.rotate90CounterClockwise => (ccwX + y, ccwY - x),
        };
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
        result[ny * width + nx] = color;
      }
    }
    return result;
  }

  /// Maps a continuous canvas position (e.g. a layer anchor) like
  /// [transformLayerPixels] maps pixels.
  static Offset transformPoint({
    required Offset point,
    required int width,
    required int height,
    required PixelTransform transform,
  }) {
    final w = width.toDouble();
    final h = height.toDouble();
    return switch (transform) {
      PixelTransform.flipHorizontal => Offset(w - point.dx, point.dy),
      PixelTransform.flipVertical => Offset(point.dx, h - point.dy),
      PixelTransform.rotate180 => Offset(w - point.dx, h - point.dy),
      PixelTransform.rotate90Clockwise =>
        Offset((w + h) / 2 - point.dy, (h - w) / 2 + point.dx),
      PixelTransform.rotate90CounterClockwise =>
        Offset((w - h) / 2 + point.dy, (w + h) / 2 - point.dx),
    };
  }

  /// Keeps a box of [size] inside [canvas]; boxes larger than the canvas are
  /// left where they are (their overflow is clipped).
  static int _fit(int start, int size, int canvas) =>
      size >= canvas ? start : start.clamp(0, canvas - size);

  static SelectionRegion _transformRegion(
    SelectionRegion region,
    PixelTransform transform,
    double w,
    double h,
    double minX,
    double minY,
    double newMinX,
    double newMinY,
  ) {
    // Continuous mapping of the old box (local coords) to the new box.
    final (a, b, c, d, tx, ty) = switch (transform) {
      PixelTransform.flipHorizontal => (-1.0, 0.0, 0.0, 1.0, w, 0.0),
      PixelTransform.flipVertical => (1.0, 0.0, 0.0, -1.0, 0.0, h),
      PixelTransform.rotate180 => (-1.0, 0.0, 0.0, -1.0, w, h),
      PixelTransform.rotate90Clockwise => (0.0, 1.0, -1.0, 0.0, h, 0.0),
      PixelTransform.rotate90CounterClockwise => (0.0, -1.0, 1.0, 0.0, 0.0, w),
    };
    // x' = a*x + c*y + tx, y' = b*x + d*y + ty on local coordinates;
    // composed as newMin + local-map(p - min).
    final matrix = Matrix4.identity()
      ..translateByDouble(newMinX, newMinY, 0, 1)
      ..multiply(Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1))
      ..translateByDouble(-minX, -minY, 0, 1);

    final transformed = region.transformed(matrix);
    final keepsShape = region.shape == SelectionShape.rectangle ||
        region.shape == SelectionShape.ellipse;
    return keepsShape ? transformed.copyWith(shape: region.shape) : transformed;
  }
}
