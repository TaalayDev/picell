import 'package:flutter/material.dart';

import '../../data/models/layer.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../tools.dart';

class PixelCanvasRuntimeConfig {
  const PixelCanvasRuntimeConfig({
    required this.width,
    required this.height,
    required this.currentTool,
    required this.currentLayer,
    required this.currentColor,
    required this.brushSize,
    required this.sprayIntensity,
    required this.modifier,
    required this.selectionState,
    required this.showSelectionMoveHandle,
    required this.showSelectionTransformHandles,
    required this.showSelectionAnchorHandle,
    this.cursor = MouseCursor.defer,
    this.selectionAnchorPoint,
    this.selectionAnimation,
    this.onSelectionChanged,
    this.onMoveSelection,
    this.onSelectionResize,
    this.onSelectionRotate,
    this.onTransformStart,
    this.onTransformEnd,
    this.onAnchorChanged,
  });

  final int width;
  final int height;
  final PixelTool currentTool;
  final Layer currentLayer;
  final Color currentColor;
  final int brushSize;
  final int sprayIntensity;
  final Modifier? modifier;
  final SelectionState? selectionState;
  final bool showSelectionMoveHandle;
  final bool showSelectionTransformHandles;
  final bool showSelectionAnchorHandle;
  final MouseCursor cursor;
  final Offset? selectionAnchorPoint;
  final Animation<double>? selectionAnimation;
  final Function(SelectionRegion?)? onSelectionChanged;
  final Function(Offset)? onMoveSelection;
  final Function(SelectionRegion, SelectionRegion, Rect, Offset?)?
      onSelectionResize;
  final Function(SelectionRegion, SelectionRegion, double, Offset?)?
      onSelectionRotate;
  final Function(SelectionRegion)? onTransformStart;
  final VoidCallback? onTransformEnd;
  final Function(Offset)? onAnchorChanged;
}
