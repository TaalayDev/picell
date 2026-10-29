import 'dart:math' as math;
import 'dart:ui';

import 'selection_handle_geometry.dart';

/// Rotation snaps to this step while Shift is held.
const double selectionRotationSnapStep = math.pi / 12; // 15°

/// [angle] rounded to the nearest [step].
double snapSelectionRotation(double angle, {double step = selectionRotationSnapStep}) =>
    (angle / step).roundToDouble() * step;

/// The bounds of a selection being resized by dragging [handle] by
/// ([dx], [dy]) canvas pixels from [original].
///
/// [keepAspect] (Shift) keeps the original width:height ratio: a corner
/// follows whichever axis changed more, an edge scales the other axis around
/// its middle. [fromCenter] (Alt) resizes symmetrically around the center
/// instead of pinning the opposite edge. Each side stays at least 1 pixel;
/// the result isn't rounded.
Rect resizeSelectionBounds({
  required Rect original,
  required CanvasSelectionHandle handle,
  required double dx,
  required double dy,
  bool keepAspect = false,
  bool fromCenter = false,
}) {
  final movesLeft = handle == CanvasSelectionHandle.topLeft ||
      handle == CanvasSelectionHandle.bottomLeft ||
      handle == CanvasSelectionHandle.leftCenter;
  final movesRight = handle == CanvasSelectionHandle.topRight ||
      handle == CanvasSelectionHandle.bottomRight ||
      handle == CanvasSelectionHandle.rightCenter;
  final movesTop = handle == CanvasSelectionHandle.topLeft ||
      handle == CanvasSelectionHandle.topRight ||
      handle == CanvasSelectionHandle.topCenter;
  final movesBottom = handle == CanvasSelectionHandle.bottomLeft ||
      handle == CanvasSelectionHandle.bottomRight ||
      handle == CanvasSelectionHandle.bottomCenter;
  final movesX = movesLeft || movesRight;
  final movesY = movesTop || movesBottom;
  if (!movesX && !movesY) return original;

  // Pulling one edge out grows the size by the delta; from the center, the
  // opposite edge mirrors it.
  final factor = fromCenter ? 2.0 : 1.0;
  final growX = movesRight ? dx : (movesLeft ? -dx : 0.0);
  final growY = movesBottom ? dy : (movesTop ? -dy : 0.0);
  var width = original.width + growX * factor;
  var height = original.height + growY * factor;

  if (keepAspect && original.width > 0 && original.height > 0) {
    final sx = width / original.width;
    final sy = height / original.height;
    final scale = movesX && movesY
        ? ((sx - 1).abs() >= (sy - 1).abs() ? sx : sy)
        : movesX
            ? sx
            : sy;
    width = original.width * scale;
    height = original.height * scale;
  }
  width = math.max(1, width);
  height = math.max(1, height);

  // Pin the opposite edge, or the center when resizing from it or along an
  // axis the handle doesn't drag.
  final double left;
  if (!fromCenter && movesRight) {
    left = original.left;
  } else if (!fromCenter && movesLeft) {
    left = original.right - width;
  } else {
    left = original.center.dx - width / 2;
  }
  final double top;
  if (!fromCenter && movesBottom) {
    top = original.top;
  } else if (!fromCenter && movesTop) {
    top = original.bottom - height;
  } else {
    top = original.center.dy - height / 2;
  }
  return Rect.fromLTWH(left, top, width, height);
}
