import 'dart:ui';

import '../../data/models/selection_region.dart';
import '../services/selection_service.dart';
import '../tools.dart';

/// Rectangle selection tool — drag to create rectangular selection with live preview.
class RectSelectionTool extends Tool {
  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onPreview;
  final void Function(SelectionRegion?)? onConfirm;

  Offset? _startPoint;

  RectSelectionTool({
    required this.selectionService,
    this.onPreview,
    this.onConfirm,
  }) : super(PixelTool.select);

  @override
  void onStart(PixelDrawDetails details) {
    _startPoint = details.position;
    onPreview?.call(null); // clear previous selection on new drag start
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (_startPoint == null) return;
    final region = selectionService.createSelectionFromPoints(
      startPoint: _startPoint!,
      endPoint: details.position,
      canvasSize: details.size,
      gridWidth: details.width,
      gridHeight: details.height,
      shape: SelectionShape.rectangle,
    );
    onPreview?.call(region);
  }

  @override
  void onEnd(PixelDrawDetails details) {
    if (_startPoint == null) return;
    final region = selectionService.createSelectionFromPoints(
      startPoint: _startPoint!,
      endPoint: details.position,
      canvasSize: details.size,
      gridWidth: details.width,
      gridHeight: details.height,
      shape: SelectionShape.rectangle,
    );
    _startPoint = null;
    onConfirm?.call(region);
  }
}

/// Ellipse selection tool — drag to create elliptical selection with live preview.
class EllipseSelectionTool extends Tool {
  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onPreview;
  final void Function(SelectionRegion?)? onConfirm;

  Offset? _startPoint;

  EllipseSelectionTool({
    required this.selectionService,
    this.onPreview,
    this.onConfirm,
  }) : super(PixelTool.ellipseSelect);

  @override
  void onStart(PixelDrawDetails details) {
    _startPoint = details.position;
    onPreview?.call(null);
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (_startPoint == null) return;
    final region = selectionService.createSelectionFromPoints(
      startPoint: _startPoint!,
      endPoint: details.position,
      canvasSize: details.size,
      gridWidth: details.width,
      gridHeight: details.height,
      shape: SelectionShape.ellipse,
    );
    onPreview?.call(region);
  }

  @override
  void onEnd(PixelDrawDetails details) {
    if (_startPoint == null) return;
    final region = selectionService.createSelectionFromPoints(
      startPoint: _startPoint!,
      endPoint: details.position,
      canvasSize: details.size,
      gridWidth: details.width,
      gridHeight: details.height,
      shape: SelectionShape.ellipse,
    );
    _startPoint = null;
    onConfirm?.call(region);
  }
}

/// Lasso selection tool — free-hand draw to create arbitrary selection.
/// Auto-closes when the pointer returns near the starting point.
class LassoSelectionTool extends Tool {
  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onConfirm;

  /// Called on every pointer move with updated screen-space points and drawing state.
  final void Function(List<Offset> points, bool isDrawing)? onLassoUpdate;

  final List<Offset> _screenPoints = [];
  bool _isDrawing = false;

  static const double _closeThreshold = 15.0;
  static const int _minPoints = 3;

  LassoSelectionTool({
    required this.selectionService,
    this.onConfirm,
    this.onLassoUpdate,
  }) : super(PixelTool.lasso);

  @override
  void onStart(PixelDrawDetails details) {
    _screenPoints.clear();
    _screenPoints.add(details.position);
    _isDrawing = true;
    onLassoUpdate?.call(List.unmodifiable(_screenPoints), true);
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (!_isDrawing) return;

    // Auto-close when pointer returns near start
    if (_screenPoints.length > _minPoints &&
        (details.position - _screenPoints.first).distance <= _closeThreshold) {
      _finalize(details);
      return;
    }

    _screenPoints.add(details.position);
    onLassoUpdate?.call(List.unmodifiable(_screenPoints), true);
  }

  @override
  void onEnd(PixelDrawDetails details) {
    if (_isDrawing) {
      _finalize(details);
    }
  }

  void _finalize(PixelDrawDetails details) {
    _isDrawing = false;
    onLassoUpdate?.call(const [], false);

    if (_screenPoints.length < _minPoints) {
      _screenPoints.clear();
      onConfirm?.call(null);
      return;
    }

    // Convert screen-space points to pixel-space
    final pw = details.size.width / details.width;
    final ph = details.size.height / details.height;
    final pixelPoints =
        _screenPoints.map((p) => Offset(p.dx / pw, p.dy / ph)).toList();
    _screenPoints.clear();

    final region = selectionService.createLassoSelection(pixelPoints);
    onConfirm?.call(region.bounds == Rect.zero ? null : region);
  }

  List<Offset> get previewPoints => List.unmodifiable(_screenPoints);
  bool get isDrawing => _isDrawing;
}
