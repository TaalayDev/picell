import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../tilemap/tilemap_notifier.dart';

/// Cache for tile images
class TileImageCache {
  static final Map<String, ui.Image> _cache = {};

  static ui.Image? get(String key) => _cache[key];

  static void set(String key, ui.Image image) {
    _cache[key] = image;
  }

  static void remove(String key) {
    _cache.remove(key)?.dispose();
  }

  static void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  static bool has(String key) => _cache.containsKey(key);
}

/// Create image from pixel data
Future<ui.Image> createImageFromPixels(Uint32List pixels, int width, int height) async {
  final bytes = ByteData(width * height * 4);
  for (int i = 0; i < pixels.length; i++) {
    final color = pixels[i];
    final offset = i * 4;
    bytes.setUint8(offset, (color >> 16) & 0xFF); // R
    bytes.setUint8(offset + 1, (color >> 8) & 0xFF); // G
    bytes.setUint8(offset + 2, color & 0xFF); // B
    bytes.setUint8(offset + 3, (color >> 24) & 0xFF); // A
  }

  final completer = ui.ImmutableBuffer.fromUint8List(bytes.buffer.asUint8List());
  final buffer = await completer;
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return frame.image;
}

/// Background dot pattern painter
class BackgroundPatternPainter extends CustomPainter {
  final ColorScheme colorScheme;

  static ui.Image? _cachedPattern;
  static Color? _cachedColor;
  static const _patternSize = 100.0;

  BackgroundPatternPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final dotColor = colorScheme.outlineVariant.withValues(alpha: 0.3);

    if (_cachedPattern == null || _cachedColor != dotColor) {
      _buildPattern(dotColor);
    }

    if (_cachedPattern != null) {
      final paint = Paint();
      for (double y = 0; y < size.height; y += _patternSize) {
        for (double x = 0; x < size.width; x += _patternSize) {
          canvas.drawImage(_cachedPattern!, Offset(x, y), paint);
        }
      }
    }
  }

  void _buildPattern(Color dotColor) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double y = 0; y < _patternSize; y += spacing) {
      for (double x = 0; x < _patternSize; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }

    final picture = recorder.endRecording();
    _cachedPattern?.dispose();
    _cachedPattern = await picture.toImage(_patternSize.toInt(), _patternSize.toInt());
    _cachedColor = dotColor;
    picture.dispose();
  }

  @override
  bool shouldRepaint(covariant BackgroundPatternPainter oldDelegate) {
    return oldDelegate.colorScheme.outlineVariant != colorScheme.outlineVariant;
  }
}

/// Main tilemap grid painter
class TilemapPainter extends CustomPainter {
  final TileMapState state;
  final TileMapNotifier notifier;
  final double tileSize;
  final (int, int)? hoverCell;
  final ColorScheme colorScheme;
  final bool isModifierPressed;

  static final _bgPaint = Paint()..color = const Color(0xFF1E1E2E);
  static final _lightPaint = Paint()..color = const Color(0xFF2A2A3E);
  static final _darkPaint = Paint()..color = const Color(0xFF252536);

  TilemapPainter({
    required this.state,
    required this.notifier,
    required this.tileSize,
    required this.hoverCell,
    required this.colorScheme,
    required this.isModifierPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _bgPaint);

    _drawCheckerboard(canvas, size);
    _drawLayers(canvas);

    if (state.showGrid) {
      _drawGrid(canvas, size);
    }

    _drawHoverCell(canvas);
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    final checkerSize = tileSize / 2;
    final xCount = (size.width / checkerSize).ceil();
    final yCount = (size.height / checkerSize).ceil();

    for (int yi = 0; yi < yCount; yi++) {
      for (int xi = 0; xi < xCount; xi++) {
        final isLight = (xi + yi) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(xi * checkerSize, yi * checkerSize, checkerSize, checkerSize),
          isLight ? _lightPaint : _darkPaint,
        );
      }
    }
  }

  void _drawLayers(Canvas canvas) {
    for (final layer in state.layers) {
      if (!layer.visible) continue;

      final layerPaint = Paint();
      if (layer.opacity < 1.0) {
        layerPaint.color = Color.fromARGB((layer.opacity * 255).round(), 255, 255, 255);
        layerPaint.blendMode = BlendMode.modulate;
      }

      canvas.saveLayer(null, layerPaint);

      for (int y = 0; y < layer.tileIds.length; y++) {
        final row = layer.tileIds[y];
        for (int x = 0; x < row.length; x++) {
          final tileId = row[x];
          if (tileId == null) continue;

          final tile = notifier.getTileById(tileId);
          if (tile == null) continue;

          _drawTile(canvas, tile, x * tileSize, y * tileSize);
        }
      }

      canvas.restore();
    }
  }

  void _drawTile(Canvas canvas, SavedTile tile, double x, double y) {
    final cacheKey = '${tile.id}_${tile.pixels.hashCode}';
    final cachedImage = TileImageCache.get(cacheKey);

    if (cachedImage != null) {
      canvas.drawImageRect(
        cachedImage,
        Rect.fromLTWH(0, 0, tile.width.toDouble(), tile.height.toDouble()),
        Rect.fromLTWH(x, y, tileSize, tileSize),
        Paint()..filterQuality = FilterQuality.none,
      );
      return;
    }

    // Fallback: draw pixels directly and cache async
    _drawTilePixels(canvas, tile, x, y);
    _cacheTileImage(tile, cacheKey);
  }

  void _drawTilePixels(Canvas canvas, SavedTile tile, double x, double y) {
    final pixelWidth = tileSize / tile.width;
    final pixelHeight = tileSize / tile.height;
    final paint = Paint();

    for (int py = 0; py < tile.height; py++) {
      for (int px = 0; px < tile.width; px++) {
        final index = py * tile.width + px;
        if (index >= tile.pixels.length) continue;

        final color = Color(tile.pixels[index]);
        if (color.alpha == 0) continue;

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            x + px * pixelWidth,
            y + py * pixelHeight,
            pixelWidth + 0.5,
            pixelHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  void _cacheTileImage(SavedTile tile, String cacheKey) async {
    if (TileImageCache.has(cacheKey)) return;
    final image = await createImageFromPixels(tile.pixels, tile.width, tile.height);
    TileImageCache.set(cacheKey, image);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    final path = Path();

    for (int x = 0; x <= state.gridWidth; x++) {
      path.moveTo(x * tileSize, 0);
      path.lineTo(x * tileSize, size.height);
    }

    for (int y = 0; y <= state.gridHeight; y++) {
      path.moveTo(0, y * tileSize);
      path.lineTo(size.width, y * tileSize);
    }

    canvas.drawPath(path, gridPaint);
  }

  void _drawHoverCell(Canvas canvas) {
    if (hoverCell == null) return;

    final (x, y) = hoverCell!;
    final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
    final hoverColor = isModifierPressed ? Colors.orange : colorScheme.primary;

    canvas.drawRect(
      rect,
      Paint()
        ..color = hoverColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      rect.deflate(1),
      Paint()
        ..color = hoverColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (isModifierPressed) {
      canvas.drawCircle(rect.center, 6, Paint()..color = Colors.orange);
    }
  }

  @override
  bool shouldRepaint(TilemapPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.hoverCell != hoverCell ||
        oldDelegate.isModifierPressed != isModifierPressed ||
        oldDelegate.colorScheme.primary != colorScheme.primary;
  }
}

/// Tile preview painter for tile cards
class TilePreviewPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;

  static final _lightPaint = Paint()..color = const Color(0xFFE0E0E0);
  static final _darkPaint = Paint()..color = const Color(0xFFBDBDBD);

  TilePreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;
    final checkerSize = min(pixelWidth, pixelHeight);

    // Checkerboard
    final xCount = (size.width / checkerSize).ceil();
    final yCount = (size.height / checkerSize).ceil();
    for (int yi = 0; yi < yCount; yi++) {
      for (int xi = 0; xi < xCount; xi++) {
        canvas.drawRect(
          Rect.fromLTWH(xi * checkerSize, yi * checkerSize, checkerSize, checkerSize),
          (xi + yi) % 2 == 0 ? _lightPaint : _darkPaint,
        );
      }
    }

    // Pixels
    final paint = Paint();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index >= pixels.length) continue;

        final color = Color(pixels[index]);
        if (color.alpha == 0) continue;

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth,
            y * pixelHeight,
            pixelWidth + 0.5,
            pixelHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TilePreviewPainter oldDelegate) {
    return oldDelegate.width != width || oldDelegate.height != height || !_pixelsEqual(oldDelegate.pixels, pixels);
  }

  bool _pixelsEqual(Uint32List a, Uint32List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Painter for tile editing canvas with pixels
class TilePixelsPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;
  final bool showGrid;

  static final _lightPaint = Paint()..color = const Color(0xFFE0E0E0);
  static final _darkPaint = Paint()..color = const Color(0xFFBDBDBD);

  TilePixelsPainter({
    required this.pixels,
    required this.width,
    required this.height,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    // Checkerboard
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * pixelWidth, y * pixelHeight, pixelWidth, pixelHeight),
          (x + y) % 2 == 0 ? _lightPaint : _darkPaint,
        );
      }
    }

    // Pixels
    final paint = Paint();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index >= pixels.length) continue;

        final color = Color(pixels[index]);
        if (color.alpha == 0) continue;

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth,
            y * pixelHeight,
            pixelWidth + 0.5,
            pixelHeight + 0.5,
          ),
          paint,
        );
      }
    }

    // Grid
    if (showGrid && pixelWidth > 4) {
      final gridPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..strokeWidth = 0.5;

      final path = Path();
      for (int x = 0; x <= width; x++) {
        path.moveTo(x * pixelWidth, 0);
        path.lineTo(x * pixelWidth, size.height);
      }
      for (int y = 0; y <= height; y++) {
        path.moveTo(0, y * pixelHeight);
        path.lineTo(size.width, y * pixelHeight);
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  @override
  bool shouldRepaint(TilePixelsPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.showGrid != showGrid ||
        !_pixelsEqual(oldDelegate.pixels, pixels);
  }

  bool _pixelsEqual(Uint32List a, Uint32List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
