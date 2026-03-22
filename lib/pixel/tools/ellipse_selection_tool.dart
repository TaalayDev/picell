import 'package:flutter/material.dart';

import '../../data/models/selection_region.dart';
import '../services/selection_service.dart';
import '../tools.dart';

class EllipseSelectionTool extends Tool {
  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onSelectionChanged;
  final void Function(SelectionRegion?)? onSelectionEnd;
  final Size Function() getCanvasSize;
  final int gridWidth;
  final int gridHeight;

  Offset? _startPoint;
  SelectionRegion? _previewRegion;

  EllipseSelectionTool({
    required this.selectionService,
    required this.onSelectionChanged,
    required this.onSelectionEnd,
    required this.getCanvasSize,
    required this.gridWidth,
    required this.gridHeight,
  }) : super(PixelTool.ellipseSelect);

  @override
  void onStart(PixelDrawDetails details) {
    _startPoint = details.position;
    _previewRegion = null;
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (_startPoint == null) return;

    _previewRegion = selectionService.createSelectionFromPoints(
      startPoint: _startPoint!,
      endPoint: details.position,
      canvasSize: details.size,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      shape: SelectionShape.ellipse,
    );
    onSelectionChanged?.call(_previewRegion);
  }

  @override
  void onEnd(PixelDrawDetails details) {
    if (_startPoint == null) return;

    final region = selectionService.createSelectionFromPoints(
      startPoint: _startPoint!,
      endPoint: details.position,
      canvasSize: details.size,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      shape: SelectionShape.ellipse,
    );

    _startPoint = null;
    _previewRegion = null;
    onSelectionEnd?.call(region);
  }

  SelectionRegion? get previewRegion => _previewRegion;
}
