import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/canvas/selection_handle_geometry.dart';
import 'package:picell/pixel/canvas/selection_transform_modifiers.dart';

void main() {
  // 10×5 selection at (10, 10).
  const original = Rect.fromLTWH(10, 10, 10, 5);

  Rect resize(CanvasSelectionHandle handle, double dx, double dy, {bool aspect = false, bool center = false}) =>
      resizeSelectionBounds(
        original: original,
        handle: handle,
        dx: dx,
        dy: dy,
        keepAspect: aspect,
        fromCenter: center,
      );

  group('resizeSelectionBounds', () {
    test('without modifiers the dragged edges follow and the opposite ones stay', () {
      expect(resize(CanvasSelectionHandle.bottomRight, 4, 3), const Rect.fromLTRB(10, 10, 24, 18));
      expect(resize(CanvasSelectionHandle.topLeft, -2, -1), const Rect.fromLTRB(8, 9, 20, 15));
      expect(resize(CanvasSelectionHandle.rightCenter, 5, 9), const Rect.fromLTRB(10, 10, 25, 15));
    });

    test('Shift keeps the aspect ratio from the axis that changed more', () {
      // Width doubles (+10), height +1: the width wins, height follows.
      expect(resize(CanvasSelectionHandle.bottomRight, 10, 1, aspect: true), const Rect.fromLTRB(10, 10, 30, 20));
      // Pinned at the bottom-right corner when dragging the top-left one.
      expect(resize(CanvasSelectionHandle.topLeft, 5, 0, aspect: true), const Rect.fromLTRB(15, 12.5, 20, 15));
    });

    test('Shift on an edge scales the other axis around its middle', () {
      final r = resize(CanvasSelectionHandle.rightCenter, 10, 0, aspect: true);
      expect(r, const Rect.fromLTRB(10, 7.5, 30, 17.5));
      expect(r.center.dy, original.center.dy);
    });

    test('Alt resizes around the center', () {
      final r = resize(CanvasSelectionHandle.bottomRight, 2, 1, center: true);
      expect(r, const Rect.fromLTRB(8, 9, 22, 16));
      expect(r.center, original.center);
      expect(resize(CanvasSelectionHandle.leftCenter, -3, 0, center: true), const Rect.fromLTRB(7, 10, 23, 15));
    });

    test('Shift and Alt together scale uniformly around the center', () {
      final r = resize(CanvasSelectionHandle.topRight, 5, 0, aspect: true, center: true);
      expect(r.size, const Size(20, 10));
      expect(r.center, original.center);
    });

    test('sides never shrink below one pixel', () {
      final r = resize(CanvasSelectionHandle.bottomRight, -50, -50);
      expect(r.width, 1);
      expect(r.height, 1);
      expect(r.topLeft, original.topLeft);
    });

    test('non-resize handles leave the bounds alone', () {
      expect(resize(CanvasSelectionHandle.move, 5, 5), original);
      expect(resize(CanvasSelectionHandle.rotate, 5, 5), original);
    });
  });

  group('snapSelectionRotation', () {
    test('rounds to the nearest 15°', () {
      const deg = math.pi / 180;
      expect(snapSelectionRotation(7 * deg), closeTo(0, 1e-9));
      expect(snapSelectionRotation(8 * deg), closeTo(15 * deg, 1e-9));
      expect(snapSelectionRotation(-50 * deg), closeTo(-45 * deg, 1e-9));
      expect(snapSelectionRotation(91 * deg), closeTo(90 * deg, 1e-9));
    });
  });
}
