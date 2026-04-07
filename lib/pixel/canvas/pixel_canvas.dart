import 'package:flutter/material.dart';

import '../../data/models/selection_state.dart';
import '../../pixel/tools.dart';
import '../../data.dart';
import '../pixel_canvas_state.dart';
import 'canvas_gesture_handler.dart';
import 'canvas_host_runtime.dart';
import 'pixel_canvas_callbacks.dart';
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
  final PixelCanvasCallbacks callbacks;
  final SelectionState? selectionState;

  const PixelCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.layers,
    required this.currentLayerIndex,
    required this.currentTool,
    required this.currentColor,
    this.modifier = PixelModifier.none,
    required this.callbacks,
    this.brushSize = 1,
    this.selectionState,
    this.sprayIntensity = 5,
    required this.viewportController,
    this.mirrorAxis = MirrorAxis.vertical,
    this.eventStream,
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
        onStartDrawing: widget.callbacks.onStartDrawing,
        onFinishDrawing: widget.callbacks.onFinishDrawing,
        onDrawShape: widget.callbacks.onDrawShape,
        onSelectionChanged: widget.callbacks.onSelectionChanged,
        onColorPicked: widget.callbacks.onColorPicked,
        onStartPixelDrag: widget.callbacks.onStartPixelDrag,
        onPixelDrag: widget.callbacks.onPixelDrag,
        onPixelDragEnd: widget.callbacks.onPixelDragEnd,
        onUndo: widget.callbacks.onUndo,
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
      onSelectionChanged: widget.callbacks.onSelectionChanged,
      onMoveSelection: widget.callbacks.onMoveSelection,
      onSelectionResize: widget.callbacks.onSelectionResize,
      onSelectionRotate: widget.callbacks.onSelectionRotate,
      onTransformStart: widget.callbacks.onTransformStart,
      onTransformEnd: widget.callbacks.onTransformEnd,
      onAnchorChanged: widget.callbacks.onAnchorChanged,
    );
  }
}
