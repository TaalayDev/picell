import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picell/core.dart';

import '../../data.dart';
import '../../data/models/selection_region.dart';
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
  Timer? _previewImageUpdateTimer;
  int _previewRevision = 0;
  int _livePreviewRevision = -1;

  List<PixelPoint<int>> _previewPixels = [];
  Uint32List _cachedPixels = Uint32List(0);

  // Drawing state
  SelectionRegion? _currentSelectionRegion;
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

  // Lasso preview state (screen-space points updated during free-hand draw)
  List<Offset> _lassoPreviewPoints = [];
  bool _isDrawingLasso = false;

  PixelCanvasController({
    required this.width,
    required this.height,
    required List<Layer> layers,
    required int currentLayerIndex,
    required this.cacheManager,
  }) : _layers = List.from(layers),
       _currentLayerIndex = currentLayerIndex,
       _cachedPixels = Uint32List(width * height);

  // Getters
  List<Layer> get layers => _layers;
  int get currentLayerIndex => _currentLayerIndex;
  PixelTool get currentTool => _currentTool;
  double get zoomLevel => _zoomLevel;
  Offset get offset => _offset;

  ui.Image? get livePreviewImage => _livePreviewImage;
  bool get hasFreshLivePreviewImage =>
      _livePreviewImage != null && _previewPixels.isNotEmpty && _livePreviewRevision == _previewRevision;

  List<PixelPoint<int>> get previewPixels => _previewPixels;
  Uint32List get cachedPixels => _cachedPixels;

  Offset? get curveStartPoint => _curveStartPoint;
  Offset? get curveEndPoint => _curveEndPoint;
  Offset? get curveControlPoint => _curveControlPoint;
  bool get isDrawingCurve => _isDrawingCurve;

  SelectionRegion? get currentSelectionRegion => _currentSelectionRegion;

  List<Offset> get penPoints => _penPoints;
  bool get isDrawingPenPath => _isDrawingPenPath;
  Offset? get gradientStart => _gradientStart;
  Offset? get gradientEnd => _gradientEnd;

  Uint32List get processedPreviewPixels => _processedPreviewPixels;
  bool get previewEffectsEnabled => _previewEffectsEnabled;

  Offset? get hoverPosition => _hoverPosition;
  List<PixelPoint<int>> get hoverPreviewPixels => _hoverPreviewPixels;

  List<Offset> get lassoPreviewPoints => _lassoPreviewPoints;
  bool get isDrawingLasso => _isDrawingLasso;

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

  /// Atomically updates both zoom and offset in a single [notifyListeners] call,
  /// halving the number of rebuilds per gesture frame compared to calling the
  /// two setters separately.
  void setZoomAndOffset(double zoom, Offset offset) {
    final clamped = zoom.clamp(0.5, 10.0);
    if (_zoomLevel == clamped && _offset == offset) return;
    _zoomLevel = clamped;
    _offset = offset;
    notifyListeners();
  }

  void setPreviewEffectsEnabled(bool enabled) {
    if (_previewEffectsEnabled != enabled) {
      _previewEffectsEnabled = enabled;
      _updatePreviewPixelsWithEffects();
      if (_previewPixels.isNotEmpty) {
        _schedulePreviewImageRebuild(_previewRevision);
      }
      notifyListeners();
    }
  }

  /// Whether the preview must be composited into a merged layer image.
  /// Opaque strokes without effects render identically through the cheap
  /// vertices path in the painter; translucent or erasing previews need the
  /// merged image because vertices would blend over the current layer's
  /// pixels instead of replacing them.
  bool get _needsLivePreviewImage {
    if (_previewPixels.isEmpty) return false;
    if (_previewEffectsEnabled && currentLayer.effects.isNotEmpty) return true;
    return (_previewPixels.last.color >>> 24) != 0xFF;
  }

  void _schedulePreviewImageRebuild(int revision) {
    _previewImageUpdateTimer?.cancel();
    if (!_needsLivePreviewImage) {
      _clearLivePreviewImage();
      return;
    }

    // Effects need a full-buffer pass (possibly in an isolate) — give them a
    // longer debounce so mid-stroke updates don't queue up.
    final hasEffects = _previewEffectsEnabled && currentLayer.effects.isNotEmpty;
    final debounce = Duration(milliseconds: hasEffects ? 33 : 10);

    _previewImageUpdateTimer = Timer(debounce, () async {
      final pixelsForPreview = await _buildPreviewLayerPixels();
      if (revision != _previewRevision || _previewPixels.isEmpty) {
        return;
      }

      final image = await ImageHelper.createImageFromPixels(pixelsForPreview, width, height);

      if (revision != _previewRevision || _previewPixels.isEmpty) {
        image.dispose();
        return;
      }

      _livePreviewImage?.dispose();
      _livePreviewImage = image;
      _livePreviewRevision = revision;
      notifyListeners();
    });
  }

  Future<Uint32List> _buildPreviewLayerPixels() async {
    final mergedPixels = _mergePixelsWithPoints(currentLayer.processedPixels, _previewPixels);

    if (!_previewEffectsEnabled || currentLayer.effects.isEmpty) {
      return mergedPixels;
    }

    return EffectsManager.applyMultipleEffectsAsync(mergedPixels, width, height, currentLayer.effects);
  }

  void _clearLivePreviewImage() {
    _previewImageUpdateTimer?.cancel();
    _livePreviewImage?.dispose();
    _livePreviewImage = null;
    _livePreviewRevision = -1;
  }

  /// Called on stroke end / tool finish – commits preview to layer & cleans up
  void commitPreviewAndClear() {
    // Old code still works (uses _previewPixels list)
    // Provider will apply the points to raw layer pixels via DrawingService

    // Clean up new system
    _clearLivePreviewImage();
    _previewRevision = 0;

    // Keep old clear for now
    _previewPixels = [];
    _processedPreviewPixels = Uint32List(0);

    _updateCurrentLayerCache();
    notifyListeners();
  }

  void clearPreviewPixels() {
    _clearPreviewPixels();
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
    _previewRevision++;
    _updatePreviewPixelsWithEffects();
    _schedulePreviewImageRebuild(_previewRevision);
    notifyListeners();
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
    if (_currentSelectionRegion == null) return pixels;
    final sel = _currentSelectionRegion!;

    return pixels.where((point) => sel.contains(point.x, point.y)).toList();
  }

  // Latest-wins guard for the async effects pass: at most one isolate job in
  // flight; a request arriving mid-job re-runs once at the end.
  bool _previewEffectsJobRunning = false;
  bool _previewEffectsJobPending = false;

  void _updatePreviewPixelsWithEffects() {
    final currentLayer = _layers[_currentLayerIndex];

    if (!_previewEffectsEnabled || _previewPixels.isEmpty || currentLayer.effects.isEmpty) {
      if (_processedPreviewPixels.isNotEmpty) {
        _processedPreviewPixels = Uint32List(0);
      }
      return;
    }

    if (_previewEffectsJobRunning) {
      _previewEffectsJobPending = true;
      return;
    }

    final tempPixels = Uint32List(width * height);

    for (final point in _previewPixels) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < tempPixels.length) {
        tempPixels[index] = point.color;
      }
    }

    final revision = _previewRevision;
    _previewEffectsJobRunning = true;
    EffectsManager.applyMultipleEffectsAsync(tempPixels, width, height, currentLayer.effects).then((result) {
      _previewEffectsJobRunning = false;
      if (revision == _previewRevision && _previewPixels.isNotEmpty) {
        _processedPreviewPixels = result;
        notifyListeners();
      }
      if (_previewEffectsJobPending) {
        _previewEffectsJobPending = false;
        _updatePreviewPixelsWithEffects();
      }
    }).catchError((Object e) {
      _previewEffectsJobRunning = false;
      _previewEffectsJobPending = false;
      debugPrint('Preview effects failed: $e');
    });
  }

  void setSelection(SelectionRegion? region) {
    _currentSelectionRegion = region;
    notifyListeners();
  }

  /// Keeps widget-owned selection state in sync without triggering a rebuild
  /// while the widget tree is already updating.
  void syncSelectionWithoutNotify(SelectionRegion? region) {
    _currentSelectionRegion = region;
  }

  void clearSelection() {
    if (_currentSelectionRegion != null) {
      _currentSelectionRegion = null;
      notifyListeners();
    }
  }

  void updateLassoPreview(List<Offset> points, bool isDrawing) {
    _lassoPreviewPoints = List<Offset>.from(points);
    _isDrawingLasso = isDrawing;
    notifyListeners();
  }

  void clearLassoPreview() {
    if (_lassoPreviewPoints.isNotEmpty || _isDrawingLasso) {
      _lassoPreviewPoints = [];
      _isDrawingLasso = false;
      notifyListeners();
    }
  }

  void setHoverPosition(Offset? position, {List<PixelPoint<int>>? previewPixels}) {
    if (position == null && _hoverPosition == null && _hoverPreviewPixels.isEmpty) {
      return;
    }
    _hoverPosition = position;
    _hoverPreviewPixels = List<PixelPoint<int>>.from(previewPixels ?? const []);
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

    return Point<int>((position.dx / pixelWidth).floor(), (position.dy / pixelHeight).floor());
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
    _clearLivePreviewImage();
    _previewRevision = 0;
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

  Uint32List _mergePixelsWithPoints(Uint32List base, List<PixelPoint<int>> points) {
    final merged = Uint32List.fromList(base);
    for (final point in points) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < merged.length) {
        merged[index] = _currentTool == PixelTool.eraser ? Colors.transparent.toARGB32() : point.color;
      }
    }
    return merged;
  }
}
