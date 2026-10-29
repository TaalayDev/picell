import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/pixel/canvas/selection_handle_geometry.dart';

void main() {
  const bounds = Rect.fromLTWH(4, 4, 8, 8);
  final region = SelectionRegion(path: Path()..addRect(bounds), bounds: bounds, shape: SelectionShape.rectangle);

  CanvasSelectionHandleGeometry compute(double handleScale) {
    return CanvasSelectionHandleGeometry.compute(
      selectionRegion: region,
      canvasSize: const Size(160, 160),
      canvasWidth: 16,
      canvasHeight: 16,
      showSelectionMoveHandle: true,
      showSelectionTransformHandles: true,
      showSelectionAnchorHandle: true,
      handleScale: handleScale,
    )!;
  }

  group('CanvasSelectionHandleGeometry handleScale', () {
    test('defaults to the unscaled handle sizes', () {
      final geometry = compute(1.0);
      final topLeft = geometry.transformHandleRects[CanvasSelectionHandle.topLeft]!;

      expect(topLeft.width, CanvasSelectionHandleGeometry.handleSize);
      expect(geometry.rotationHandleCenter!.dy, 40 - CanvasSelectionHandleGeometry.rotationHandleDistance);
    });

    test('shrinks handles, offsets and hit radius in canvas space when zoomed in', () {
      const zoom = 4.0;
      final geometry = compute(1 / zoom);
      final topLeft = geometry.transformHandleRects[CanvasSelectionHandle.topLeft]!;

      expect(topLeft.width, CanvasSelectionHandleGeometry.handleSize / zoom);
      expect(topLeft.center, const Offset(40, 40));
      expect(geometry.rotationHandleCenter!.dy, 40 - CanvasSelectionHandleGeometry.rotationHandleDistance / zoom);
      expect(geometry.scaledCenterHandleRadius, CanvasSelectionHandleGeometry.centerHandleRadius / zoom);

      // A point just outside the scaled radius no longer hits the anchor.
      final anchor = geometry.anchorHandleCenter!;
      expect(geometry.hitTest(anchor), CanvasSelectionHandle.anchor);
      expect(geometry.hitTest(anchor + Offset(geometry.scaledCenterHandleRadius + 0.5, 0)), isNull);
    });
  });
}
