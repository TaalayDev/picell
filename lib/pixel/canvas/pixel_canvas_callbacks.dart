import 'package:flutter/material.dart';

import '../../data/models/selection_region.dart';
import '../pixel_point.dart';

class PixelCanvasCallbacks {
  const PixelCanvasCallbacks({
    required this.onStartDrawing,
    required this.onFinishDrawing,
    required this.onDrawShape,
    this.onSelectionChanged,
    this.onMoveSelection,
    this.onSelectionResize,
    this.onSelectionRotate,
    this.onTransformStart,
    this.onTransformEnd,
    this.onAnchorChanged,
    this.onColorPicked,
    this.onGradientApplied,
    this.onStartPixelDrag,
    this.onPixelDrag,
    this.onPixelDragEnd,
    this.onUndo,
  });

  final VoidCallback onStartDrawing;
  final VoidCallback onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(SelectionRegion?)? onSelectionChanged;
  final Function(Offset)? onMoveSelection;
  final Function(SelectionRegion, SelectionRegion, Rect, Offset?)?
      onSelectionResize;
  final Function(SelectionRegion, SelectionRegion, double, Offset?)?
      onSelectionRotate;
  final Function(SelectionRegion)? onTransformStart;
  final VoidCallback? onTransformEnd;
  final Function(Offset)? onAnchorChanged;
  final Function(Color)? onColorPicked;
  final Function(List<Color>)? onGradientApplied;
  final Function(Offset)? onStartPixelDrag;
  final Function(Offset)? onPixelDrag;
  final Function(Offset)? onPixelDragEnd;
  final VoidCallback? onUndo;
}
