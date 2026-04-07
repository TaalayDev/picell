import 'package:flutter/material.dart';

import 'canvas_surface_image_resolver.dart';

class PixelCanvasSurfacePaintDelegate {
  PixelCanvasSurfacePaintDelegate({
    required int gridWidth,
    required int gridHeight,
    required PixelCanvasSurfaceImageResolver imageResolver,
    required double backgroundOpacity,
    required double backgroundScale,
    required Offset backgroundOffset,
  }) : _gridWidth = gridWidth,
       _gridHeight = gridHeight,
       _imageResolver = imageResolver,
       _backgroundOpacity = backgroundOpacity,
       _backgroundScale = backgroundScale,
       _backgroundOffset = backgroundOffset;

  int _gridWidth;
  int _gridHeight;
  PixelCanvasSurfaceImageResolver _imageResolver;
  double _backgroundOpacity;
  double _backgroundScale;
  Offset _backgroundOffset;

  final Paint _baseFillPaint = Paint()..color = Colors.white;
  final Paint _borderPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke;
  final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  final Paint _backgroundPaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _onionSkinPaint = Paint()..filterQuality = FilterQuality.none;

  void update({
    int? gridWidth,
    int? gridHeight,
    PixelCanvasSurfaceImageResolver? imageResolver,
    double? backgroundOpacity,
    double? backgroundScale,
    Offset? backgroundOffset,
  }) {
    _gridWidth = gridWidth ?? _gridWidth;
    _gridHeight = gridHeight ?? _gridHeight;
    _imageResolver = imageResolver ?? _imageResolver;
    _backgroundOpacity = backgroundOpacity ?? _backgroundOpacity;
    _backgroundScale = backgroundScale ?? _backgroundScale;
    _backgroundOffset = backgroundOffset ?? _backgroundOffset;
  }

  void paint(Canvas canvas, Rect rect) {
    if (rect.isEmpty) {
      return;
    }

    _paintBaseFill(canvas, rect);
    _paintGrid(canvas, rect);
    _paintBackgroundImage(canvas, rect);
    _paintOnionSkinFrames(canvas, rect);
    _paintBorder(canvas, rect);
  }

  void _paintBaseFill(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _baseFillPaint);
  }

  void _paintBorder(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _borderPaint);
  }

  void _paintGrid(Canvas canvas, Rect rect) {
    if (_gridWidth <= 0 || _gridHeight <= 0) {
      return;
    }

    _gridPaint.color = Colors.grey.withValues(alpha: 0.2);

    final cellWidth = rect.width / _gridWidth;
    final cellHeight = rect.height / _gridHeight;

    for (var column = 0; column <= _gridWidth; column++) {
      final x = rect.left + column * cellWidth;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), _gridPaint);
    }

    for (var row = 0; row <= _gridHeight; row++) {
      final y = rect.top + row * cellHeight;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), _gridPaint);
    }
  }

  void _paintBackgroundImage(Canvas canvas, Rect rect) {
    final image = _imageResolver.backgroundImage;
    if (image == null || _backgroundOpacity <= 0) {
      return;
    }

    final outputSize = rect.size;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, imageSize, outputSize);
    final sourceRect = Alignment.center.inscribe(fitted.source, Offset.zero & imageSize);

    final offsetDelta = Offset(_backgroundOffset.dx * rect.width, _backgroundOffset.dy * rect.height);

    _backgroundPaint
      ..color = Colors.white.withValues(alpha: _backgroundOpacity)
      ..filterQuality = FilterQuality.none;

    canvas.save();
    canvas.clipRect(rect);
    canvas.translate(rect.center.dx + offsetDelta.dx, rect.center.dy + offsetDelta.dy);
    canvas.scale(_backgroundScale);
    canvas.drawImageRect(
      image,
      sourceRect,
      Rect.fromCenter(center: Offset.zero, width: fitted.destination.width, height: fitted.destination.height),
      _backgroundPaint,
    );
    canvas.restore();
  }

  void _paintOnionSkinFrames(Canvas canvas, Rect rect) {
    final onionSkinFrames = _imageResolver.onionSkinFrames;
    if (onionSkinFrames.isEmpty) {
      return;
    }

    for (final frame in onionSkinFrames) {
      final sourceRect = Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble());
      _onionSkinPaint.color = Colors.white.withValues(alpha: frame.opacity);
      canvas.drawImageRect(frame.image, sourceRect, rect, _onionSkinPaint);
    }
  }
}
