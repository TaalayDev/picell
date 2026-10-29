import 'package:flutter/widgets.dart';

import '../../data/models/selection_region.dart';

enum CanvasSelectionHandle {
  move,
  rotate,
  anchor,
  topLeft,
  topCenter,
  topRight,
  rightCenter,
  bottomRight,
  bottomCenter,
  bottomLeft,
  leftCenter,
}

class CanvasSelectionHandleGeometry {
  const CanvasSelectionHandleGeometry({
    required this.selectionRect,
    required this.transformHandleRects,
    this.rotationHandleCenter,
    this.moveHandleCenter,
    this.anchorHandleCenter,
    this.handleScale = 1.0,
  });

  static const double centerHandleSize = 18.0;
  static const double handleSize = 12.0;
  static const double rotationHandleDistance = 30.0;
  static const double moveHandleDistance = 30.0;
  static const double moveHandleOffsetX = 28.0;

  final Rect selectionRect;
  final Map<CanvasSelectionHandle, Rect> transformHandleRects;
  final Offset? rotationHandleCenter;
  final Offset? moveHandleCenter;
  final Offset? anchorHandleCenter;

  /// Converts the screen-space handle constants into the canvas-local space
  /// the handles live in. Pass `1 / zoomLevel` so handles keep a constant
  /// on-screen size regardless of canvas zoom.
  final double handleScale;

  double get scaledCenterHandleRadius => centerHandleRadius * handleScale;

  double get scaledHandleSize => handleSize * handleScale;

  Iterable<Offset> get transformHandleCenters => transformHandleRects.values.map((rect) => rect.center);

  static double get centerHandleRadius => centerHandleSize / 2;

  static Rect? selectionScreenRect({
    required SelectionRegion selectionRegion,
    required Size canvasSize,
    required int canvasWidth,
    required int canvasHeight,
  }) {
    if (canvasSize == Size.zero || canvasWidth <= 0 || canvasHeight <= 0) {
      return null;
    }

    final pixelWidth = canvasSize.width / canvasWidth;
    final pixelHeight = canvasSize.height / canvasHeight;
    final bounds = selectionRegion.bounds;

    return Rect.fromLTWH(
      bounds.left * pixelWidth,
      bounds.top * pixelHeight,
      bounds.width * pixelWidth,
      bounds.height * pixelHeight,
    );
  }

  static Offset pixelToScreen({
    required Offset pixelPosition,
    required Size canvasSize,
    required int canvasWidth,
    required int canvasHeight,
  }) {
    return Offset(
      pixelPosition.dx * canvasSize.width / canvasWidth,
      pixelPosition.dy * canvasSize.height / canvasHeight,
    );
  }

  static Offset screenToPixel({
    required Offset screenPosition,
    required Size canvasSize,
    required int canvasWidth,
    required int canvasHeight,
  }) {
    return Offset(
      screenPosition.dx / (canvasSize.width / canvasWidth),
      screenPosition.dy / (canvasSize.height / canvasHeight),
    );
  }

  static CanvasSelectionHandleGeometry? compute({
    required SelectionRegion selectionRegion,
    required Size canvasSize,
    required int canvasWidth,
    required int canvasHeight,
    required bool showSelectionMoveHandle,
    required bool showSelectionTransformHandles,
    required bool showSelectionAnchorHandle,
    Offset? selectionAnchorPoint,
    double handleScale = 1.0,
  }) {
    final selectionRect = selectionScreenRect(
      selectionRegion: selectionRegion,
      canvasSize: canvasSize,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );

    if (selectionRect == null) {
      return null;
    }

    final size = handleSize * handleScale;
    final transformHandleRects = <CanvasSelectionHandle, Rect>{};
    Offset? rotationHandleCenter;
    Offset? moveHandleCenter;
    Offset? anchorHandleCenter;

    if (showSelectionTransformHandles) {
      transformHandleRects.addAll({
        CanvasSelectionHandle.topLeft: Rect.fromCenter(
          center: selectionRect.topLeft,
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.topRight: Rect.fromCenter(
          center: selectionRect.topRight,
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.bottomLeft: Rect.fromCenter(
          center: selectionRect.bottomLeft,
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.bottomRight: Rect.fromCenter(
          center: selectionRect.bottomRight,
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.topCenter: Rect.fromCenter(
          center: Offset(selectionRect.center.dx, selectionRect.top),
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.bottomCenter: Rect.fromCenter(
          center: Offset(selectionRect.center.dx, selectionRect.bottom),
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.leftCenter: Rect.fromCenter(
          center: Offset(selectionRect.left, selectionRect.center.dy),
          width: size,
          height: size,
        ),
        CanvasSelectionHandle.rightCenter: Rect.fromCenter(
          center: Offset(selectionRect.right, selectionRect.center.dy),
          width: size,
          height: size,
        ),
      });

      rotationHandleCenter = Offset(selectionRect.center.dx, selectionRect.top - rotationHandleDistance * handleScale);
    }

    if (showSelectionMoveHandle) {
      moveHandleCenter = Offset(
        selectionRect.center.dx - moveHandleOffsetX * handleScale,
        selectionRect.top - moveHandleDistance * handleScale,
      );
    }

    if (showSelectionAnchorHandle) {
      final anchorPixel = selectionAnchorPoint ?? selectionRegion.bounds.center;
      anchorHandleCenter = pixelToScreen(
        pixelPosition: anchorPixel,
        canvasSize: canvasSize,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
      );
    }

    return CanvasSelectionHandleGeometry(
      selectionRect: selectionRect,
      transformHandleRects: transformHandleRects,
      rotationHandleCenter: rotationHandleCenter,
      moveHandleCenter: moveHandleCenter,
      anchorHandleCenter: anchorHandleCenter,
      handleScale: handleScale,
    );
  }

  CanvasSelectionHandle? hitTest(Offset localPosition) {
    final centerHandleRadius = scaledCenterHandleRadius;
    if (anchorHandleCenter != null && (localPosition - anchorHandleCenter!).distance <= centerHandleRadius) {
      return CanvasSelectionHandle.anchor;
    }

    if (rotationHandleCenter != null && (localPosition - rotationHandleCenter!).distance <= centerHandleRadius) {
      return CanvasSelectionHandle.rotate;
    }

    for (final entry in transformHandleRects.entries) {
      if (entry.value.contains(localPosition)) {
        return entry.key;
      }
    }

    if (moveHandleCenter != null && (localPosition - moveHandleCenter!).distance <= centerHandleRadius) {
      return CanvasSelectionHandle.move;
    }

    return null;
  }
}
