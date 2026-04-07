import 'package:flutter/material.dart';

import '../../core/utils/cursor_manager.dart';
import '../../data/models/layer.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../../pixel/tools.dart';
import '../../pixel/tools/mirror_modifier.dart';
import '../pixel_point.dart';
import 'canvas_host_runtime.dart';
import 'canvas_runtime_config.dart';

class PixelCanvasWidgetBindings {
  static PixelCanvasHostCallbacks buildHostCallbacks({
    required PixelTool Function() getCurrentTool,
    required VoidCallback onStartDrawing,
    required VoidCallback onFinishDrawing,
    required Function(List<PixelPoint<int>>) onDrawShape,
    Function(SelectionRegion?)? onSelectionChanged,
    Function(Color)? onColorPicked,
    Function(Offset)? onStartPixelDrag,
    Function(Offset)? onPixelDrag,
    Function(Offset)? onPixelDragEnd,
    Function()? onUndo,
  }) {
    return PixelCanvasHostCallbacks(
      getCurrentTool: getCurrentTool,
      onStartDrawing: onStartDrawing,
      onFinishDrawing: onFinishDrawing,
      onDrawShape: onDrawShape,
      onSelectionChanged: onSelectionChanged,
      onColorPicked: onColorPicked,
      onStartPixelDrag: onStartPixelDrag,
      onPixelDrag: onPixelDrag,
      onPixelDragEnd: onPixelDragEnd,
      onUndo: onUndo,
    );
  }

  static PixelCanvasRuntimeConfig buildRuntimeConfig({
    required int width,
    required int height,
    required Layer currentLayer,
    required PixelTool currentTool,
    required Color currentColor,
    required int brushSize,
    required int sprayIntensity,
    required PixelModifier modifier,
    required MirrorAxis mirrorAxis,
    required SelectionState? selectionState,
    required Animation<double> selectionAnimation,
    Function(SelectionRegion?)? onSelectionChanged,
    Function(Offset)? onMoveSelection,
    Function(SelectionRegion, SelectionRegion, Rect, Offset?)? onSelectionResize,
    Function(SelectionRegion, SelectionRegion, double, Offset?)? onSelectionRotate,
    Function(SelectionRegion)? onTransformStart,
    VoidCallback? onTransformEnd,
    Function(Offset)? onAnchorChanged,
  }) {
    final isSelectionTool = _isSelectionInteractionTool(currentTool);

    return PixelCanvasRuntimeConfig(
      width: width,
      height: height,
      currentTool: currentTool,
      currentLayer: currentLayer,
      currentColor: currentColor,
      brushSize: brushSize,
      sprayIntensity: sprayIntensity,
      modifier: _resolveModifier(modifier, mirrorAxis),
      selectionState: selectionState,
      onSelectionChanged: onSelectionChanged,
      onMoveSelection: onMoveSelection,
      onSelectionResize: onSelectionResize,
      onSelectionRotate: onSelectionRotate,
      onTransformStart: onTransformStart,
      onTransformEnd: onTransformEnd,
      onAnchorChanged: onAnchorChanged,
      showSelectionMoveHandle: !isSelectionTool,
      showSelectionTransformHandles: isSelectionTool,
      showSelectionAnchorHandle: isSelectionTool,
      cursor: _resolveCursor(currentTool),
      selectionAnchorPoint: selectionState?.anchorPoint,
      selectionAnimation: selectionAnimation,
    );
  }

  static bool _isSelectionInteractionTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso ||
        tool == PixelTool.smartSelect;
  }

  static Modifier? _resolveModifier(PixelModifier modifier, MirrorAxis mirrorAxis) {
    if (modifier == PixelModifier.mirror) {
      return MirrorModifier(mirrorAxis);
    }
    return null;
  }

  static MouseCursor _resolveCursor(PixelTool tool) {
    return CursorManager.instance.getCursor(tool) ?? tool.cursor;
  }
}
