import 'package:flutter/material.dart';

import '../../../pixel/canvas/pixel_canvas_callbacks.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../pixel/tools.dart';

class PixelPainterBindings {
  static PixelCanvasCallbacks buildCanvasCallbacks({
    required PixelCanvasNotifier notifier,
    required PixelTool currentTool,
    Function(PixelTool)? onToolAutoSwitch,
  }) {
    return PixelCanvasCallbacks(
      onStartDrawing: notifier.startDrawing,
      onFinishDrawing: notifier.endDrawing,
      onDrawShape: notifier.fillPixels,
      onSelectionChanged: (region) {
        if (region == null) {
          notifier.clearSelection();
        } else {
          notifier.setSelection(region);
        }
      },
      onMoveSelection: notifier.moveSelection,
      onSelectionResize: (newRegion, oldRegion, newBounds, center) {
        notifier.resizeSelectionNew(
          newRegion.bounds,
          region: newRegion,
        );
      },
      onSelectionRotate: (newRegion, oldRegion, angle, center) {
        notifier.rotateSelectionNew(
          angle,
          pivot: center,
          region: newRegion,
        );
      },
      onTransformStart: notifier.startTransformSelection,
      onTransformEnd: notifier.endTransformSelection,
      onAnchorChanged: notifier.setAnchorPoint,
      onColorPicked: (color) {
        notifier.currentColor =
            color == Colors.transparent ? Colors.white : color;
        onToolAutoSwitch?.call(PixelTool.pencil);
      },
      onGradientApplied: notifier.applyGradient,
      onStartPixelDrag: (_) {
        if (currentTool == PixelTool.drag) {
          notifier.startDrag();
        }
      },
      onPixelDrag: (offset) {
        if (currentTool == PixelTool.drag) {
          notifier.dragPixels(offset);
        }
      },
      onPixelDragEnd: (_) {
        if (currentTool == PixelTool.drag) {
          notifier.endDrag();
        }
      },
    );
  }
}
