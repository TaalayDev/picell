import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/selection_region.dart';
import '../services/selection_service.dart';
import '../tools.dart';

class LassoTool extends Tool {
  LassoTool({
    required this.selectionService,
    this.onSelectionEnd,
  }) : super(PixelTool.lasso);

  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onSelectionEnd;

  List<Offset> _points = [];
  bool _isDrawing = false;
  static const _closeThreshold = 10.0;

  @override
  void onStart(PixelDrawDetails details) {
    if (!_isDrawing) {
      _points = [details.position];
      _isDrawing = true;
    }
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (_isDrawing) {
      final startPoint = _points.first;
      if ((details.position - startPoint).distance <= _closeThreshold && _points.length > 2) {
        _points.add(startPoint);
        _finalizeLasso(details);
      } else {
        _points.add(details.position);
      }
    }
  }

  @override
  void onEnd(PixelDrawDetails details) {
    if (_isDrawing) {
      _finalizeLasso(details);
    }
  }

  void _finalizeLasso(PixelDrawDetails details) {
    _isDrawing = false;
    if (_points.length < 3) {
      _points.clear();
      return;
    }

    // Convert screen-space points to pixel-space
    final pixelWidth = details.size.width / details.width;
    final pixelHeight = details.size.height / details.height;

    final pixelPoints = _points.map((p) => Offset(
      p.dx / pixelWidth,
      p.dy / pixelHeight,
    )).toList();

    final region = selectionService.createLassoSelection(pixelPoints);
    onSelectionEnd?.call(region);

    _points.clear();
  }

  List<Offset> get previewPoints => _points;
  bool get isDrawing => _isDrawing;
}
