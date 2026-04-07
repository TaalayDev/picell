import 'package:flutter/material.dart';

import '../../data.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../pixel_canvas_state.dart';
import '../tools.dart';
import 'canvas_host_runtime.dart';
import 'canvas_render_layer.dart';
import 'canvas_widget_bindings.dart';

class PixelCanvasRenderHost extends StatelessWidget {
  const PixelCanvasRenderHost({
    super.key,
    required this.runtime,
    required this.width,
    required this.height,
    required this.currentLayer,
    required this.currentTool,
    required this.currentColor,
    required this.brushSize,
    required this.sprayIntensity,
    required this.modifier,
    required this.mirrorAxis,
    required this.selectionState,
    required this.selectionAnimation,
    this.eventStream,
    this.onSelectionChanged,
    this.onMoveSelection,
    this.onSelectionResize,
    this.onSelectionRotate,
    this.onTransformStart,
    this.onTransformEnd,
    this.onAnchorChanged,
  });

  final PixelCanvasHostRuntime runtime;
  final int width;
  final int height;
  final Layer currentLayer;
  final PixelTool currentTool;
  final Color currentColor;
  final int brushSize;
  final int sprayIntensity;
  final PixelModifier modifier;
  final MirrorAxis mirrorAxis;
  final SelectionState? selectionState;
  final Animation<double> selectionAnimation;
  final Stream<PixelDrawEvent>? eventStream;
  final Function(SelectionRegion?)? onSelectionChanged;
  final Function(Offset)? onMoveSelection;
  final Function(SelectionRegion, SelectionRegion, Rect, Offset?)?
      onSelectionResize;
  final Function(SelectionRegion, SelectionRegion, double, Offset?)?
      onSelectionRotate;
  final Function(SelectionRegion)? onTransformStart;
  final VoidCallback? onTransformEnd;
  final Function(Offset)? onAnchorChanged;

  @override
  Widget build(BuildContext context) {
    final config = PixelCanvasWidgetBindings.buildRuntimeConfig(
      width: width,
      height: height,
      currentLayer: currentLayer,
      currentTool: currentTool,
      currentColor: currentColor,
      brushSize: brushSize,
      sprayIntensity: sprayIntensity,
      modifier: modifier,
      mirrorAxis: mirrorAxis,
      selectionState: selectionState,
      selectionAnimation: selectionAnimation,
      onSelectionChanged: onSelectionChanged,
      onMoveSelection: onMoveSelection,
      onSelectionResize: onSelectionResize,
      onSelectionRotate: onSelectionRotate,
      onTransformStart: onTransformStart,
      onTransformEnd: onTransformEnd,
      onAnchorChanged: onAnchorChanged,
    );

    return RepaintBoundary(
      child: PixelCanvasRenderLayer(
        controller: runtime.controller,
        cacheManager: runtime.cacheManager,
        gestureHandler: runtime.gestureHandler,
        toolManager: runtime.toolManager,
        config: config,
        eventStream: eventStream,
      ),
    );
  }
}
