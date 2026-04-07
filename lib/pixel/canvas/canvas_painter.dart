import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data.dart';
import '../../data/models/selection_region.dart';
import '../pixel_point.dart';
import '../tools.dart';
import 'canvas_controller.dart';
import 'canvas_quad_vertices_buffer.dart';
import 'canvas_runtime_config.dart';
import 'layer_cache_manager.dart';
import 'selection_handle_geometry.dart';

/// Paint delegate for rendering the pixel canvas scene.
class PixelCanvasPaintDelegate {
  static final Paint _srcOverVerticesPaint = Paint();
  static final Paint _clearVerticesPaint = Paint()..blendMode = BlendMode.clear;
  static const int _opaqueHoverAlpha = 0x99;
  static final int _eraserHoverColorValue = Colors.red.withValues(alpha: 0.4).toARGB32();

  PixelCanvasController _controller;
  LayerCacheManager _cacheManager;
  PixelCanvasRuntimeConfig _config;
  PixelCanvasQuadVerticesBuffer _quadVerticesBuffer;
  final Paint _layerSavePaint = Paint();
  final Paint _imagePaint = Paint();
  final Paint _hoverBorderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _gradientPaint = Paint();
  final Paint _selectionOutlineBackgroundPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.black;
  final Paint _selectionOutlineDashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = Colors.white;
  final Paint _handleShadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.2)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _handleFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _handleBorderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _penStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.red;
  final Paint _penPointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;
  final Paint _penCloseIndicatorPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green;
  final Paint _lassoStrokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _lassoPointPaint = Paint()..style = PaintingStyle.fill;
  final Paint _lassoCloseLinePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _lassoCloseFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _curveGuidePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _curvePointPaint = Paint()..style = PaintingStyle.fill;
  final Paint _curveControlPaint = Paint()..style = PaintingStyle.fill;
  final Paint _curveControlLinePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _curvePreviewPaint = Paint()..style = PaintingStyle.stroke;
  final Path _penPath = Path();
  final Path _lassoPath = Path();
  final Path _curvePath = Path();
  final Float64List _selectionScaleTransform = Float64List(16);
  Size? _cachedGradientSize;
  Offset? _cachedGradientStart;
  Offset? _cachedGradientEnd;
  Shader? _cachedGradientShader;
  Rect _cachedGradientRect = Rect.zero;

  PixelCanvasController get controller => _controller;
  LayerCacheManager get cacheManager => _cacheManager;
  PixelCanvasRuntimeConfig get config => _config;
  PixelCanvasQuadVerticesBuffer get quadVerticesBuffer => _quadVerticesBuffer;

  int get width => _config.width;
  int get height => _config.height;
  PixelTool get currentTool => _config.currentTool;
  Color get currentColor => _config.currentColor;
  bool get showSelectionMoveHandle => _config.showSelectionMoveHandle;
  bool get showSelectionTransformHandles => _config.showSelectionTransformHandles;
  bool get showSelectionAnchorHandle => _config.showSelectionAnchorHandle;
  Offset? get selectionAnchorPoint => _config.selectionAnchorPoint;
  double get selectionAnimationValue => _config.selectionAnimation?.value ?? 0.0;

  PixelCanvasPaintDelegate({
    required PixelCanvasController controller,
    required LayerCacheManager cacheManager,
    required PixelCanvasRuntimeConfig config,
    required PixelCanvasQuadVerticesBuffer quadVerticesBuffer,
  })  : _controller = controller,
        _cacheManager = cacheManager,
        _config = config,
        _quadVerticesBuffer = quadVerticesBuffer;

  void update({
    PixelCanvasController? controller,
    LayerCacheManager? cacheManager,
    PixelCanvasRuntimeConfig? config,
    PixelCanvasQuadVerticesBuffer? quadVerticesBuffer,
  }) {
    _controller = controller ?? _controller;
    _cacheManager = cacheManager ?? _cacheManager;
    _config = config ?? _config;
    _quadVerticesBuffer = quadVerticesBuffer ?? _quadVerticesBuffer;
  }

  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    // _drawGrid(canvas, size, pixelWidth, pixelHeight);

    _drawLayers(canvas, size, pixelWidth, pixelHeight);

    // _drawSelectionRect(canvas, pixelWidth, pixelHeight);
    _drawGradient(canvas, size);
    _drawPenPath(canvas);
    _drawCurveGuides(canvas, size);
    _drawLassoPath(canvas, size);

    if (controller.previewPixels.isEmpty && controller.livePreviewImage == null) {
      _drawHoverPreview(canvas, size, pixelWidth, pixelHeight);
    }

    _drawSelectionOutline(canvas, pixelWidth, pixelHeight);
    _drawSelectionHandles(canvas, pixelWidth, pixelHeight);
  }

  void _drawLayers(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    final canvasRect = Offset.zero & size;

    for (int i = 0; i < controller.layers.length; i++) {
      final layer = controller.layers[i];

      if (!layer.isVisible || layer.opacity == 0) continue;
      final isCurrentLayer = i == controller.currentLayerIndex;

      final bool needsSaveLayer = _needsLayerSaveLayer(
        layerIndex: i,
        layer: layer,
      );
      if (needsSaveLayer) {
        _layerSavePaint.color = Colors.white.withValues(alpha: layer.opacity);
        canvas.saveLayer(
          canvasRect,
          _layerSavePaint,
        );
      }

      if (isCurrentLayer && controller.hasFreshLivePreviewImage) {
        _drawCachedLayer(canvas, controller.livePreviewImage!, canvasRect);
      } else {
        final cachedImage = cacheManager.getLayerImage(layer.layerId);

        if (cachedImage != null) {
          _drawCachedLayer(canvas, cachedImage, canvasRect);
        } else {
          _drawLayerPixels(canvas, layer, pixelWidth, pixelHeight);
        }
      }

      if (isCurrentLayer && !controller.hasFreshLivePreviewImage) {
        _drawPreviewPixels(canvas, size, pixelWidth, pixelHeight);
      }

      if (needsSaveLayer) {
        canvas.restore();
      }
    }
  }

  bool _needsLayerSaveLayer({
    required int layerIndex,
    required Layer layer,
  }) {
    if (layer.opacity < 1.0) {
      return true;
    }

    final isCurrentLayer = layerIndex == controller.currentLayerIndex;
    if (!isCurrentLayer) {
      return false;
    }

    // Eraser preview uses BlendMode.clear. Isolate only the current layer so
    // clearing reveals lower layers instead of punching through the whole scene.
    return currentTool == PixelTool.eraser && controller.previewPixels.isNotEmpty;
  }

  void _drawCachedLayer(Canvas canvas, ui.Image image, Rect canvasRect) {
    final imageRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    canvas.drawImageRect(
      image,
      imageRect,
      canvasRect,
      _imagePaint,
    );
  }

  void _drawLayerPixels(Canvas canvas, Layer layer, double pixelWidth, double pixelHeight) {
    final processedPixels = layer.processedPixels;
    quadVerticesBuffer.reset();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index >= processedPixels.length) continue;

        final colorValue = processedPixels[index];
        if (colorValue == 0) continue; // Skip transparent/empty

        if ((colorValue & 0xFF000000) == 0) continue;

        final left = x * pixelWidth;
        final top = y * pixelHeight;
        final right = left + pixelWidth;
        final bottom = top + pixelHeight;

        if (quadVerticesBuffer.isFull) {
          _drawBufferedVertices(canvas, BlendMode.srcOver);
        }
        quadVerticesBuffer.addQuad(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          colorValue: colorValue,
        );
      }
    }

    _drawBufferedVertices(canvas, BlendMode.srcOver);
  }

  void _drawPreviewPixels(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    if (controller.processedPreviewPixels.isNotEmpty && currentTool != PixelTool.eraser) {
      return _drawProcessedPreviewPixels(canvas, size, pixelWidth, pixelHeight);
    }

    final previewPixels = controller.previewPixels;
    if (previewPixels.isEmpty) return;

    _drawPixelsAsVertices(canvas, previewPixels, pixelWidth, pixelHeight);
  }

  void _drawProcessedPreviewPixels(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    final processedPixels = controller.processedPreviewPixels;
    if (processedPixels.isEmpty) return;

    final isErasing = controller.currentTool == PixelTool.eraser;
    quadVerticesBuffer.reset();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index >= processedPixels.length) continue;

        final colorValue = processedPixels[index];
        if (!isErasing && (colorValue & 0xFF000000) == 0) continue;

        final left = x * pixelWidth;
        final top = y * pixelHeight;
        final right = left + pixelWidth;
        final bottom = top + pixelHeight;

        if (quadVerticesBuffer.isFull) {
          _drawBufferedVertices(
            canvas,
            isErasing ? BlendMode.clear : BlendMode.srcOver,
          );
        }
        quadVerticesBuffer.addQuad(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          colorValue: colorValue,
        );
      }
    }

    _drawBufferedVertices(
      canvas,
      isErasing ? BlendMode.clear : BlendMode.srcOver,
    );
  }

  void _drawPixelsAsVertices(
    Canvas canvas,
    List<PixelPoint<int>> pixels,
    double pixelWidth,
    double pixelHeight,
  ) {
    final isErasing = controller.currentTool == PixelTool.eraser;
    quadVerticesBuffer.reset();

    for (final point in pixels) {
      final colorValue = point.color;
      if (!isErasing && (colorValue & 0xFF000000) == 0) {
        continue;
      }

      final left = point.x * pixelWidth;
      final top = point.y * pixelHeight;
      final right = left + pixelWidth;
      final bottom = top + pixelHeight;

      if (quadVerticesBuffer.isFull) {
        _drawBufferedVertices(
          canvas,
          isErasing ? BlendMode.clear : BlendMode.srcOver,
        );
      }
      quadVerticesBuffer.addQuad(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        colorValue: colorValue,
      );
    }

    _drawBufferedVertices(
      canvas,
      isErasing ? BlendMode.clear : BlendMode.srcOver,
    );
  }

  void _drawHoverPreview(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    final hoverPixels = controller.hoverPreviewPixels;
    if (hoverPixels.isEmpty) return;

    final isErasing = controller.currentTool == PixelTool.eraser;
    quadVerticesBuffer.reset();

    for (final point in hoverPixels) {
      final hoverColorValue =
          isErasing ? _eraserHoverColorValue : (point.color & 0x00FFFFFF) | (_opaqueHoverAlpha << 24);

      final left = point.x * pixelWidth;
      final top = point.y * pixelHeight;
      final right = left + pixelWidth;
      final bottom = top + pixelHeight;

      if (quadVerticesBuffer.isFull) {
        _drawBufferedVertices(canvas, BlendMode.srcOver);
      }
      quadVerticesBuffer.addQuad(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        colorValue: hoverColorValue,
      );
    }

    if (!quadVerticesBuffer.isEmpty) {
      _drawBufferedVertices(canvas, BlendMode.srcOver);
      // Add a subtle border for better visibility
      _drawHoverBorder(canvas, hoverPixels, pixelWidth, pixelHeight);
    }
  }

  void _drawBufferedVertices(Canvas canvas, BlendMode blendMode) {
    final vertices = quadVerticesBuffer.buildVertices();
    if (vertices == null) {
      return;
    }

    final paint = switch (blendMode) {
      BlendMode.clear => _clearVerticesPaint,
      _ => _srcOverVerticesPaint,
    };
    canvas.drawVertices(vertices, blendMode, paint);
    quadVerticesBuffer.reset();
  }

  void _drawHoverBorder(Canvas canvas, List<PixelPoint<int>> hoverPixels, double pixelWidth, double pixelHeight) {
    if (hoverPixels.isEmpty) return;

    _hoverBorderPaint
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.0 / controller.zoomLevel;

    int minX = hoverPixels.first.x;
    int maxX = hoverPixels.first.x;
    int minY = hoverPixels.first.y;
    int maxY = hoverPixels.first.y;

    for (final pixel in hoverPixels) {
      minX = minX < pixel.x ? minX : pixel.x;
      maxX = maxX > pixel.x ? maxX : pixel.x;
      minY = minY < pixel.y ? minY : pixel.y;
      maxY = maxY > pixel.y ? maxY : pixel.y;
    }

    final rect = Rect.fromLTWH(
      minX * pixelWidth,
      minY * pixelHeight,
      (maxX - minX + 1) * pixelWidth,
      (maxY - minY + 1) * pixelHeight,
    );

    canvas.drawRect(rect, _hoverBorderPaint);
  }

  void _drawGradient(Canvas canvas, Size size) {
    final gradientStart = controller.gradientStart;
    final gradientEnd = controller.gradientEnd;

    if (gradientStart == null || gradientEnd == null) return;

    if (_cachedGradientSize != size || _cachedGradientStart != gradientStart || _cachedGradientEnd != gradientEnd) {
      _cachedGradientSize = size;
      _cachedGradientStart = gradientStart;
      _cachedGradientEnd = gradientEnd;
      _cachedGradientRect = Rect.fromLTWH(0, 0, size.width, size.height);
      _cachedGradientShader = LinearGradient(
        begin: Alignment(
          gradientStart.dx / size.width,
          gradientStart.dy / size.height,
        ),
        end: Alignment(
          gradientEnd.dx / size.width,
          gradientEnd.dy / size.height,
        ),
        colors: const [Colors.black, Colors.transparent],
      ).createShader(_cachedGradientRect);
    }

    _gradientPaint.shader = _cachedGradientShader;
    canvas.drawRect(_cachedGradientRect, _gradientPaint);
    _gradientPaint.shader = null;
  }

  void _drawSelectionOutline(
    Canvas canvas,
    double pixelWidth,
    double pixelHeight,
  ) {
    final SelectionRegion? selectionRegion = controller.currentSelectionRegion;
    if (selectionRegion == null || selectionRegion.bounds == Rect.zero) {
      return;
    }

    _updateSelectionScaleTransform(pixelWidth, pixelHeight);
    final scaledPath = selectionRegion.path.transform(
      _selectionScaleTransform,
    );

    canvas.drawPath(scaledPath, _selectionOutlineBackgroundPaint);

    const dashLength = 6.0;
    const gapLength = 4.0;
    const totalDash = dashLength + gapLength;
    final offset = selectionAnimationValue * totalDash;

    for (final metric in scaledPath.computeMetrics()) {
      double distance = -offset;
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + dashLength).clamp(0.0, metric.length);
        if (end > start) {
          final extractedPath = metric.extractPath(start, end);
          canvas.drawPath(extractedPath, _selectionOutlineDashPaint);
        }
        distance += totalDash;
      }
    }
  }

  void _drawSelectionHandles(
    Canvas canvas,
    double pixelWidth,
    double pixelHeight,
  ) {
    final SelectionRegion? selectionRegion = controller.currentSelectionRegion;
    if (selectionRegion == null || selectionRegion.bounds == Rect.zero) {
      return;
    }

    final geometry = CanvasSelectionHandleGeometry.compute(
      selectionRegion: selectionRegion,
      canvasSize: Size(pixelWidth * width, pixelHeight * height),
      canvasWidth: width,
      canvasHeight: height,
      showSelectionMoveHandle: showSelectionMoveHandle,
      showSelectionTransformHandles: showSelectionTransformHandles,
      showSelectionAnchorHandle: showSelectionAnchorHandle,
      selectionAnchorPoint: selectionAnchorPoint,
    );
    if (geometry == null) {
      return;
    }

    if (showSelectionTransformHandles) {
      for (final position in geometry.transformHandleCenters) {
        _drawSquareHandle(canvas, position);
      }

      if (geometry.rotationHandleCenter != null) {
        _drawCircleHandle(
          canvas,
          geometry.rotationHandleCenter!,
          CanvasSelectionHandleGeometry.centerHandleRadius,
          Colors.green.shade300,
        );
      }
    }

    if (showSelectionMoveHandle && geometry.moveHandleCenter != null) {
      _drawCircleHandle(
        canvas,
        geometry.moveHandleCenter!,
        CanvasSelectionHandleGeometry.centerHandleRadius,
        Colors.blue.shade400,
      );
    }

    if (showSelectionAnchorHandle && geometry.anchorHandleCenter != null) {
      _drawCircleHandle(
        canvas,
        geometry.anchorHandleCenter!,
        CanvasSelectionHandleGeometry.centerHandleRadius,
        Colors.orange.withValues(alpha: 0.8),
      );
    }
  }

  void _drawSquareHandle(Canvas canvas, Offset position) {
    final rect = Rect.fromCenter(
      center: position,
      width: CanvasSelectionHandleGeometry.handleSize,
      height: CanvasSelectionHandleGeometry.handleSize,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));

    canvas.drawRRect(rrect.shift(const Offset(0, 1)), _handleShadowPaint);

    _handleFillPaint.color = Colors.white;
    canvas.drawRRect(rrect, _handleFillPaint);

    _handleBorderPaint
      ..color = Colors.blue
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, _handleBorderPaint);
  }

  void _drawCircleHandle(
    Canvas canvas,
    Offset center,
    double radius,
    Color fillColor,
  ) {
    canvas.drawCircle(center + const Offset(0, 1), radius, _handleShadowPaint);

    _handleFillPaint.color = fillColor;
    canvas.drawCircle(center, radius, _handleFillPaint);

    _handleBorderPaint
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, _handleBorderPaint);
  }

  void _drawPenPath(Canvas canvas) {
    final penPoints = controller.penPoints;
    if (!controller.isDrawingPenPath || penPoints.isEmpty) return;

    _penStrokePaint.strokeWidth = 1.5 / controller.zoomLevel;
    _penPointPaint.color = Colors.red;
    _penPath.reset();

    if (penPoints.length == 1) {
      // Single point - draw a circle
      canvas.drawCircle(
        penPoints.first,
        2.0 / controller.zoomLevel,
        _penPointPaint,
      );
    } else {
      // Multiple points - draw connected lines
      _penPath.moveTo(penPoints.first.dx, penPoints.first.dy);
      for (int i = 1; i < penPoints.length; i++) {
        _penPath.lineTo(penPoints[i].dx, penPoints[i].dy);
      }

      canvas.drawPath(_penPath, _penStrokePaint);

      // Show closing indicator if near start point
      if (penPoints.length > 2 && (penPoints.last - penPoints.first).distance <= 15) {
        _penCloseIndicatorPaint.strokeWidth = 1.5 / controller.zoomLevel;
        canvas.drawLine(
          penPoints.last,
          penPoints.first,
          _penCloseIndicatorPaint,
        );
      }
    }
  }

  void _drawLassoPath(Canvas canvas, Size size) {
    if (!controller.isDrawingLasso || controller.lassoPreviewPoints.isEmpty) {
      return;
    }

    final points = controller.lassoPreviewPoints;

    _lassoStrokePaint
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..strokeWidth = 2.0 / controller.zoomLevel;
    _lassoPointPaint.color = Colors.blue.withValues(alpha: 0.7);
    _lassoCloseLinePaint
      ..color = Colors.green.withValues(alpha: 0.8)
      ..strokeWidth = 2.0 / controller.zoomLevel;
    _lassoCloseFillPaint.color = Colors.green.withValues(alpha: 0.6);

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        3.0 / controller.zoomLevel,
        _lassoPointPaint..color = Colors.blue,
      );
    } else {
      _lassoPath
        ..reset()
        ..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        _lassoPath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(_lassoPath, _lassoStrokePaint);

      // Closing indicator when near start
      if (points.length > 2 && (points.last - points.first).distance <= 15) {
        canvas.drawLine(
          points.last,
          points.first,
          _lassoCloseLinePaint,
        );
        canvas.drawCircle(
          points.first,
          4.0 / controller.zoomLevel,
          _lassoCloseFillPaint,
        );
      }

      // Dot at each vertex for visibility
      for (final point in points) {
        canvas.drawCircle(
          point,
          1.5 / controller.zoomLevel,
          _lassoPointPaint,
        );
      }
    }
  }

  void _drawCurveGuides(Canvas canvas, Size size) {
    final curveStart = controller.curveStartPoint;
    final curveEnd = controller.curveEndPoint;
    final curveControl = controller.curveControlPoint;

    if (!controller.isDrawingCurve || curveStart == null) return;

    _curveGuidePaint
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..strokeWidth = 1.5 / controller.zoomLevel;
    _curvePointPaint.color = Colors.blue;
    _curveControlPaint.color = Colors.red;
    _curveControlLinePaint
      ..color = Colors.red.withValues(alpha: 0.5)
      ..strokeWidth = 1.0 / controller.zoomLevel;

    // Draw start point
    canvas.drawCircle(
      curveStart,
      3.0 / controller.zoomLevel,
      _curvePointPaint,
    );

    // Draw end point if it exists
    if (curveEnd != null) {
      canvas.drawCircle(
        curveEnd,
        3.0 / controller.zoomLevel,
        _curvePointPaint,
      );

      // Draw line between start and end points
      canvas.drawLine(curveStart, curveEnd, _curveGuidePaint);

      // Draw control point and guides if it exists
      if (curveControl != null) {
        // Draw control point
        canvas.drawCircle(
          curveControl,
          4.0 / controller.zoomLevel,
          _curveControlPaint,
        );

        // Draw control lines
        canvas.drawLine(curveStart, curveControl, _curveControlLinePaint);
        canvas.drawLine(curveEnd, curveControl, _curveControlLinePaint);

        // Draw the actual curve preview
        _drawCurvePreview(canvas, curveStart, curveControl, curveEnd);
      }
    }
  }

  void _drawCurvePreview(Canvas canvas, Offset start, Offset control, Offset end) {
    _curvePreviewPaint
      ..color = currentColor.withValues(alpha: 0.8)
      ..strokeWidth = 2.0 / controller.zoomLevel;

    _curvePath
      ..reset()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    canvas.drawPath(_curvePath, _curvePreviewPaint);
  }

  void _updateSelectionScaleTransform(double pixelWidth, double pixelHeight) {
    _selectionScaleTransform[0] = pixelWidth;
    _selectionScaleTransform[1] = 0.0;
    _selectionScaleTransform[2] = 0.0;
    _selectionScaleTransform[3] = 0.0;
    _selectionScaleTransform[4] = 0.0;
    _selectionScaleTransform[5] = pixelHeight;
    _selectionScaleTransform[6] = 0.0;
    _selectionScaleTransform[7] = 0.0;
    _selectionScaleTransform[8] = 0.0;
    _selectionScaleTransform[9] = 0.0;
    _selectionScaleTransform[10] = 1.0;
    _selectionScaleTransform[11] = 0.0;
    _selectionScaleTransform[12] = 0.0;
    _selectionScaleTransform[13] = 0.0;
    _selectionScaleTransform[14] = 0.0;
    _selectionScaleTransform[15] = 1.0;
  }
}
