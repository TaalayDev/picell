import 'dart:typed_data';

import '../../data/models/selection_region.dart';
import 'gradient_options.dart';

/// Builds the paint mask (1 = paint) for a gradient, or null when every
/// pixel may be painted.
class GradientMask {
  const GradientMask._();

  static Uint8List? build({
    required Uint32List pixels,
    required int width,
    required int height,
    required GradientTarget target,
    required int seedX,
    required int seedY,
    SelectionRegion? selection,
  }) {
    final selectionMask = selection == null ? null : fromSelection(selection, width, height);
    if (target == GradientTarget.layer) return selectionMask;

    final area = contiguous(pixels, width, height, seedX, seedY);
    if (selectionMask != null) {
      for (int i = 0; i < area.length; i++) {
        area[i] &= selectionMask[i];
      }
    }
    return area;
  }

  /// Rasterises [selection] at pixel centres, visiting only its bounds.
  static Uint8List fromSelection(
    SelectionRegion selection,
    int width,
    int height,
  ) {
    final mask = Uint8List(width * height);
    final b = selection.bounds;
    final x0 = b.left.floor().clamp(0, width);
    final y0 = b.top.floor().clamp(0, height);
    final x1 = b.right.ceil().clamp(0, width);
    final y1 = b.bottom.ceil().clamp(0, height);
    for (int y = y0; y < y1; y++) {
      for (int x = x0; x < x1; x++) {
        if (selection.contains(x, y)) mask[y * width + x] = 1;
      }
    }
    return mask;
  }

  /// 4-connected area with exactly the seed pixel's colour. A seed outside
  /// the canvas yields an empty mask.
  static Uint8List contiguous(
    Uint32List pixels,
    int width,
    int height,
    int seedX,
    int seedY,
  ) {
    final mask = Uint8List(width * height);
    if (seedX < 0 || seedY < 0 || seedX >= width || seedY >= height) {
      return mask;
    }
    final target = pixels[seedY * width + seedX];
    final stack = Int32List(width * height);
    var top = 0;
    final seed = seedY * width + seedX;
    mask[seed] = 1;
    stack[top++] = seed;
    while (top > 0) {
      final i = stack[--top];
      final x = i % width;
      void visit(int j) {
        if (mask[j] == 0 && pixels[j] == target) {
          mask[j] = 1;
          stack[top++] = j;
        }
      }

      if (x > 0) visit(i - 1);
      if (x < width - 1) visit(i + 1);
      if (i >= width) visit(i - width);
      if (i < width * (height - 1)) visit(i + width);
    }
    return mask;
  }
}
