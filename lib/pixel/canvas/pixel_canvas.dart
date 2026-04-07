import 'package:flutter/material.dart';

import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../../pixel/tools.dart';
import '../../data.dart';
import '../pixel_canvas_state.dart';
import '../pixel_point.dart';
import 'canvas_gesture_handler.dart';
import 'canvas_host_runtime.dart';
import 'canvas_render_host.dart';
import 'canvas_widget_bindings.dart';
import 'pixel_viewport_controller.dart';

class PixelCanvas extends StatefulWidget {
  final int width;
  final int height;
  final List<Layer> layers;
  final int currentLayerIndex;
  final PixelTool currentTool;
  final Color currentColor;
  final PixelModifier modifier;
  final int brushSize;
  final int sprayIntensity;
  final MirrorAxis mirrorAxis;
  final PixelViewportController viewportController;

  final Stream<PixelDrawEvent>? eventStream;

  final GestureInputMode inputMode;
  final bool twoFingerUndoEnabled;
  final bool enableMultiTouchViewportNavigation;

  // Callbacks
  final Function(int x, int y) onTapPixel;
  final Function() onStartDrawing;
  final Function() onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(SelectionRegion?)? onSelectionChanged;
  final Function(Offset)? onMoveSelection;
  final Function(SelectionRegion, SelectionRegion, Rect, Offset?)?
      onSelectionResize;
  final Function(SelectionRegion, SelectionRegion, double, Offset?)?
      onSelectionRotate;
  final Function(SelectionRegion)? onTransformStart;
  final Function()? onTransformEnd;
  final Function(Offset)? onAnchorChanged;
  final SelectionState? selectionState;
  final Function(Color)? onColorPicked;
  final Function(List<Color>)? onGradientApplied;
  final Function(double, Offset)? onStartDrag;
  final Function(double, Offset)? onDrag;
  final Function(double, Offset)? onDragEnd;
  final Function()? onUndo;

  const PixelCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.layers,
    required this.currentLayerIndex,
    required this.onTapPixel,
    required this.currentTool,
    required this.currentColor,
    this.modifier = PixelModifier.none,
    required this.onDrawShape,
    required this.onStartDrawing,
    required this.onFinishDrawing,
    this.onColorPicked,
    this.brushSize = 1,
    this.onSelectionChanged,
    this.onMoveSelection,
    this.onSelectionResize,
    this.onSelectionRotate,
    this.onTransformStart,
    this.onTransformEnd,
    this.onAnchorChanged,
    this.selectionState,
    this.onGradientApplied,
    this.sprayIntensity = 5,
    required this.viewportController,
    this.mirrorAxis = MirrorAxis.vertical,
    this.eventStream,
    this.onStartDrag,
    this.onDrag,
    this.onDragEnd,
    this.onUndo,
    this.inputMode = GestureInputMode.standard,
    this.twoFingerUndoEnabled = true,
    this.enableMultiTouchViewportNavigation = true,
  });

  @override
  State<PixelCanvas> createState() => _PixelCanvasState();
}

class _PixelCanvasState extends State<PixelCanvas>
    with SingleTickerProviderStateMixin {
  late final PixelCanvasHostRuntime _runtime;
  late final AnimationController _selectionAnimationController;

  @override
  void initState() {
    super.initState();
    _runtime = PixelCanvasHostRuntime.create(
      width: widget.width,
      height: widget.height,
      layers: widget.layers,
      currentLayerIndex: widget.currentLayerIndex,
      currentTool: widget.currentTool,
      viewportController: widget.viewportController,
      inputMode: widget.inputMode,
      twoFingerUndoEnabled: widget.twoFingerUndoEnabled,
      enableMultiTouchViewportNavigation:
          widget.enableMultiTouchViewportNavigation,
      selectionState: widget.selectionState,
      callbacks: PixelCanvasWidgetBindings.buildHostCallbacks(
        getCurrentTool: () => widget.currentTool,
        onStartDrawing: () => widget.onStartDrawing(),
        onFinishDrawing: () => widget.onFinishDrawing(),
        onDrawShape: (points) => widget.onDrawShape(points),
        onSelectionChanged: (region) => widget.onSelectionChanged?.call(region),
        onColorPicked: (color) => widget.onColorPicked?.call(color),
        onStartDrag: (scale, offset) => widget.onStartDrag?.call(scale, offset),
        onDrag: (scale, offset) => widget.onDrag?.call(scale, offset),
        onDragEnd: (scale, offset) => widget.onDragEnd?.call(scale, offset),
        onUndo: () => widget.onUndo?.call(),
      ),
    );
    _selectionAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PixelCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runtime.update(
      layers: widget.layers,
      currentLayerIndex: widget.currentLayerIndex,
      currentTool: widget.currentTool,
      viewportController: widget.viewportController,
      inputMode: widget.inputMode,
      twoFingerUndoEnabled: widget.twoFingerUndoEnabled,
      enableMultiTouchViewportNavigation:
          widget.enableMultiTouchViewportNavigation,
      selectionState: widget.selectionState,
    );
  }

  @override
  void dispose() {
    _selectionAnimationController.dispose();
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PixelCanvasRenderHost(
      runtime: _runtime,
      width: widget.width,
      height: widget.height,
      currentLayer: widget.layers[widget.currentLayerIndex],
      currentTool: widget.currentTool,
      currentColor: widget.currentColor,
      brushSize: widget.brushSize,
      sprayIntensity: widget.sprayIntensity,
      modifier: widget.modifier,
      mirrorAxis: widget.mirrorAxis,
      selectionState: widget.selectionState,
      selectionAnimation: _selectionAnimationController,
      eventStream: widget.eventStream,
      onSelectionChanged: widget.onSelectionChanged,
      onMoveSelection: widget.onMoveSelection,
      onSelectionResize: widget.onSelectionResize,
      onSelectionRotate: widget.onSelectionRotate,
      onTransformStart: widget.onTransformStart,
      onTransformEnd: widget.onTransformEnd,
      onAnchorChanged: widget.onAnchorChanged,
    );
  }
}
