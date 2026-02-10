import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picell/core.dart';

import '../../data.dart';
import '../../pixel/tools.dart';
import '../effects/effects.dart';
import '../pixel_point.dart';
import 'layer_cache_manager.dart';

/// Controls the state and operations of the pixel canvas
class PixelCanvasController extends ChangeNotifier {
  final int width;
  final int height;
  final LayerCacheManager cacheManager;

  // Canvas state
  List<Layer> _layers = [];
  int _currentLayerIndex = 0;
  PixelTool _currentTool = PixelTool.pencil;
  double _zoomLevel = 1.0;
  Offset _offset = Offset.zero;

  ui.Image? _livePreviewImage;
  Uint32List? _strokeSnapshotPixels;
  Timer? _previewImageUpdateTimer;

  List<PixelPoint<int>> _previewPixels = [];
  Uint32List _cachedPixels = Uint32List(0);

  // Drawing state
  List<PixelPoint<int>> _selectionPoints = [];
  List<Offset> _penPoints = [];
  bool _isDrawingPenPath = false;
  Offset? _gradientStart;
  Offset? _gradientEnd;
  Uint32List _processedPreviewPixels = Uint32List(0);
  bool _previewEffectsEnabled = true;

  // Curve state
  Offset? _curveStartPoint;
  Offset? _curveEndPoint;
  Offset? _curveControlPoint;
  bool _isDrawingCurve = false;

  Offset? _hoverPosition;
  List<PixelPoint<int>> _hoverPreviewPixels = [];

  PixelCanvasController({
    required this.width,
    required this.height,
    required List<Layer> layers,
    required int currentLayerIndex,
    required this.cacheManager,
  })  : _layers = List.from(layers),
        _currentLayerIndex = currentLayerIndex,
        _cachedPixels = Uint32List(width * height);

  // Getters
  List<Layer> get layers => _layers;
  int get currentLayerIndex => _currentLayerIndex;
  PixelTool get currentTool => _currentTool;
  double get zoomLevel => _zoomLevel;
  Offset get offset => _offset;

  ui.Image? get livePreviewImage => _livePreviewImage;

  List<PixelPoint<int>> get previewPixels => _previewPixels;
  Uint32List get cachedPixels => _cachedPixels;

  Offset? get curveStartPoint => _curveStartPoint;
  Offset? get curveEndPoint => _curveEndPoint;
  Offset? get curveControlPoint => _curveControlPoint;
  bool get isDrawingCurve => _isDrawingCurve;

  List<PixelPoint<int>> get selectionPoints => _selectionPoints;

  List<Offset> get penPoints => _penPoints;
  bool get isDrawingPenPath => _isDrawingPenPath;
  Offset? get gradientStart => _gradientStart;
  Offset? get gradientEnd => _gradientEnd;

  Uint32List get processedPreviewPixels => _processedPreviewPixels;
  bool get previewEffectsEnabled => _previewEffectsEnabled;

  Offset? get hoverPosition => _hoverPosition;
  List<PixelPoint<int>> get hoverPreviewPixels => _hoverPreviewPixels;

  Layer get currentLayer => _layers[_currentLayerIndex];
  int get currentLayerId => currentLayer.layerId;

  void initialize(List<Layer> layers) {
    _layers = List.from(layers);
    _updateCachedPixels(cacheAll: true);
    notifyListeners();
  }

  void updateLayers(List<Layer> layers) {
    if (!listEquals(_layers, layers)) {
      final bool needsFullCache = _layers.length != layers.length;
      _layers = List.from(layers);
      _updateCachedPixels(cacheAll: needsFullCache);

      scheduleMicrotask(() {
        // Clear preview pixels after canvas is updated
        clearPreviewPixels();
      });
      notifyListeners();
    }
  }

  void setCurrentLayerIndex(int index) {
    if (_currentLayerIndex != index && index >= 0 && index < _layers.length) {
      _currentLayerIndex = index;
      _updateCachedPixels();
      notifyListeners();
    }
  }

  void setCurrentTool(PixelTool tool) {
    if (_currentTool != tool) {
      _currentTool = tool;
      _clearDrawingState();
      notifyListeners();
    }
  }

  void setZoomLevel(double zoom) {
    if (_zoomLevel != zoom) {
      _zoomLevel = zoom.clamp(0.5, 10.0);
      notifyListeners();
    }
  }

  void setOffset(Offset offset) {
    if (_offset != offset) {
      _offset = offset;
      notifyListeners();
    }
  }

  void setPreviewEffectsEnabled(bool enabled) {
    if (_previewEffectsEnabled != enabled) {
      _previewEffectsEnabled = enabled;
      _updatePreviewPixelsWithEffects();
      notifyListeners();
    }
  }

  void updatePreviewPixels(List<PixelPoint<int>> newPoints) {
    if (newPoints.isEmpty) return;

    // Start stroke snapshot if needed (first points of a stroke)
    _strokeSnapshotPixels ??= Uint32List.fromList(currentLayer.processedPixels);

    // Incrementally apply new points to snapshot (fast, no list bloat)
    for (final point in newPoints) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < _strokeSnapshotPixels!.length) {
        _strokeSnapshotPixels![index] = point.color;
      }
    }

    // Keep old list for now (used by commit logic in provider)
    _previewPixels.addAll(newPoints);

    // Debounced image rebuild – feels instant but caps CPU/GPU load
    _schedulePreviewImageUpdate();
    notifyListeners();
  }

  void _schedulePreviewImageUpdate({bool immediate = false}) async {
    if (_strokeSnapshotPixels == null) return;

    _previewImageUpdateTimer?.cancel();
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 10);

    Uint32List pixelsForPreview = Uint32List.fromList(_strokeSnapshotPixels!);

    // Optional: skip heavy effects during active drawing for extra speed
    // Remove this block if you want full effects live (still fast with compute)
    if (currentLayer.effects.isNotEmpty && previewEffectsEnabled == false) {
      // use raw snapshot – super fast
    } else {
      pixelsForPreview = EffectsManager.applyMultipleEffects(
        _strokeSnapshotPixels!,
        width,
        height,
        currentLayer.effects,
      );
    }

    final image = await ImageHelper.createImageFromPixels(
      pixelsForPreview,
      width,
      height,
    );
    _livePreviewImage?.dispose();
    _livePreviewImage = image;
    notifyListeners();
  }

  static Future<ui.Image> _createImageFromPixels(List<dynamic> args) async {
    final Uint32List pixels = args[0];
    final int w = args[1];
    final int h = args[2];

    return ImageHelper.createImageFromPixels(pixels, w, h);
  }

  /// Called on stroke end / tool finish – commits preview to layer & cleans up
  void commitPreviewAndClear() {
    // Old code still works (uses _previewPixels list)
    // Provider will apply the points to raw layer pixels via DrawingService

    // Clean up new system
    _strokeSnapshotPixels = null;
    _livePreviewImage?.dispose();
    _livePreviewImage = null;
    _previewImageUpdateTimer?.cancel();

    // Keep old clear for now
    _previewPixels = [];
    _processedPreviewPixels = Uint32List(0);

    _updateCurrentLayerCache();
    notifyListeners();
  }

  void clearPreviewPixels() {
    if (_strokeSnapshotPixels != null) {
      _strokeSnapshotPixels = null;
      _livePreviewImage?.dispose();
      _livePreviewImage = null;
      _previewImageUpdateTimer?.cancel();
    }

    _previewPixels = [];
    _processedPreviewPixels = Uint32List(0);
    notifyListeners();
  }

  void _updateCachedPixels({bool cacheAll = false}) {
    // Existing implementation unchanged for now
    // Later phases (composite cache) will replace this entirely
    _cachedPixels = Uint32List(width * height);

    for (var i = 0; i < _layers.length; i++) {
      final layer = _layers[i];
      if (!layer.isVisible) {
        cacheManager.removeLayer(layer.layerId);
        continue;
      }

      final processedPixels = layer.processedPixels;
      _cachedPixels = _mergePixels(_cachedPixels, processedPixels);

      if (i == _currentLayerIndex || cacheAll) {
        cacheManager.updateLayer(layer.layerId, processedPixels, width, height);
      }
    }

    // Old preview merge (kept temporarily)
    if (_previewPixels.isNotEmpty) {
      _cachedPixels = _mergePixelsWithPoints(_cachedPixels, _previewPixels);
    }
  }

  void setPreviewPixels(List<PixelPoint<int>> pixels) {
    _previewPixels = List<PixelPoint<int>>.from(filterPixelsInSelection(pixels));
    // _updateCurrentLayerCache();
    _updatePreviewPixelsWithEffects();
    notifyListeners();

    // updatePreviewPixels(pixels);
  }

  // void clearPreviewPixels() {
  //   _clearPreviewPixels();
  //   notifyListeners();
  // }

  void applyLayerCache() {
    _updateCurrentLayerCache();
  }

  void setCurvePoints(Offset? start, Offset? end, Offset? control) {
    _curveStartPoint = start;
    _curveEndPoint = end;
    _curveControlPoint = control;
    _isDrawingCurve = start != null;
    notifyListeners();
  }

  void clearCurvePoints() {
    _curveStartPoint = null;
    _curveEndPoint = null;
    _curveControlPoint = null;
    _isDrawingCurve = false;
    notifyListeners();
  }

  List<PixelPoint<int>> filterPixelsInSelection(List<PixelPoint<int>> pixels) {
    if (_selectionPoints.isEmpty) return pixels;

    final minX = _selectionPoints.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final minY = _selectionPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxX = _selectionPoints.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final maxY = _selectionPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    final selectedPixels = <PixelPoint<int>>[];
    for (final point in pixels) {
      if (point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY) {
        selectedPixels.add(point);
      }
    }
    return selectedPixels;
  }

  void _updatePreviewPixelsWithEffects() {
    final currentLayer = _layers[_currentLayerIndex];

    if (!_previewEffectsEnabled || _previewPixels.isEmpty || currentLayer.effects.isEmpty) {
      if (_processedPreviewPixels.isNotEmpty) {
        _processedPreviewPixels = Uint32List(0);
      }
      return;
    }

    final tempPixels = Uint32List(width * height);

    for (final point in _previewPixels) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < tempPixels.length) {
        tempPixels[index] = point.color;
      }
    }

    _processedPreviewPixels = EffectsManager.applyMultipleEffects(tempPixels, width, height, currentLayer.effects);
  }

  void setSelection(List<PixelPoint<int>>? selection) {
    _selectionPoints = selection?.isNotEmpty == true ? List<PixelPoint<int>>.from(selection ?? []) : [];
    notifyListeners();
  }

  void clearSelection() {
    if (_selectionPoints.isNotEmpty) {
      _selectionPoints = [];
      notifyListeners();
    }
  }

  void setHoverPosition(
    Offset? position, {
    List<PixelPoint<int>>? previewPixels,
  }) {
    _hoverPosition = position;
    _hoverPreviewPixels = List<PixelPoint<int>>.from(previewPixels ?? []);
    notifyListeners();
  }

  void setPenPoints(List<Offset> points) {
    _penPoints = points;
    notifyListeners();
  }

  void setDrawingPenPath(bool isDrawing) {
    _isDrawingPenPath = isDrawing;
    notifyListeners();
  }

  void setGradient(Offset? start, Offset? end) {
    _gradientStart = start;
    _gradientEnd = end;
    notifyListeners();
  }

  /// Transform screen position to canvas coordinates
  Offset transformPosition(Offset screenPosition) {
    return (screenPosition - _offset) / _zoomLevel;
  }

  /// Transform canvas coordinates to screen position
  Offset transformToScreen(Offset canvasPosition) {
    return canvasPosition * _zoomLevel + _offset;
  }

  /// Check if a point is within canvas bounds
  bool isValidPoint(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  /// Convert screen offset to pixel coordinates
  Point<int> getPixelCoordinates(Offset position, Size canvasSize) {
    final pixelWidth = canvasSize.width / width;
    final pixelHeight = canvasSize.height / height;

    return Point<int>(
      (position.dx / pixelWidth).floor(),
      (position.dy / pixelHeight).floor(),
    );
  }

  // void _updateCachedPixels({bool cacheAll = false}) {
  //   _cachedPixels = Uint32List(width * height);

  //   for (var i = 0; i < _layers.length; i++) {
  //     final layer = _layers[i];
  //     if (!layer.isVisible) {
  //       cacheManager.removeLayer(layer.layerId);
  //       continue;
  //     }

  //     final processedPixels = layer.processedPixels;
  //     _cachedPixels = _mergePixels(_cachedPixels, processedPixels);

  //     if (i == _currentLayerIndex || cacheAll) {
  //       cacheManager.updateLayer(layer.layerId, processedPixels, width, height);
  //     }
  //   }

  //   if (_previewPixels.isNotEmpty) {
  //     _cachedPixels = _mergePixelsWithPoints(_cachedPixels, _previewPixels);
  //   }
  // }

  void _updateCurrentLayerCache() {
    if (_currentLayerIndex < _layers.length) {
      final layer = _layers[_currentLayerIndex];
      final processedPixels = layer.processedPixels;
      cacheManager.updateLayer(layer.layerId, processedPixels, width, height);
    }
  }

  void _clearPreviewPixels() {
    _previewPixels = [];
    _processedPreviewPixels = Uint32List(0);
    _gradientStart = null;
  }

  void _clearDrawingState() {
    _clearPreviewPixels();
    _penPoints = [];
    _isDrawingPenPath = false;
    _gradientStart = null;
    _gradientEnd = null;

    _curveStartPoint = null;
    _curveEndPoint = null;
    _curveControlPoint = null;
    _isDrawingCurve = false;
  }

  Uint32List _mergePixels(Uint32List base, Uint32List overlay) {
    final merged = Uint32List.fromList(base);
    for (int i = 0; i < overlay.length && i < merged.length; i++) {
      if (overlay[i] != 0) {
        merged[i] = overlay[i];
      }
    }
    return merged;
  }

  Uint32List _mergePixelsWithPoints(
    Uint32List base,
    List<PixelPoint<int>> points,
  ) {
    final merged = Uint32List.fromList(base);
    for (final point in points) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < merged.length) {
        merged[index] = _currentTool == PixelTool.eraser ? Colors.transparent.value : point.color;
      }
    }
    return merged;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
