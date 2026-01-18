import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../tilemap/tilemap_notifier.dart';

/// Background dot pattern painter
class BackgroundPatternPainter extends CustomPainter {
  final ColorScheme colorScheme;

  BackgroundPatternPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Main tilemap grid painter
class TilemapPainter extends CustomPainter {
  final TileMapState state;
  final TileMapNotifier notifier;
  final double tileSize;
  final (int, int)? hoverCell;
  final ColorScheme colorScheme;
  final bool isModifierPressed;

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
    final bgPaint = Paint()..color = const Color(0xFF1E1E2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawCheckerboard(canvas, size);

    for (final layer in state.layers) {
      if (!layer.visible) continue;
      _drawLayer(canvas, layer);
    }

    if (state.showGrid) {
      _drawGrid(canvas, size);
    }

    _drawHoverCell(canvas);
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = const Color(0xFF2A2A3E);
    final darkPaint = Paint()..color = const Color(0xFF252536);
    final checkerSize = tileSize / 2;

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isLight = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  void _drawLayer(Canvas canvas, TilemapLayer layer) {
    for (int y = 0; y < layer.tileIds.length; y++) {
      for (int x = 0; x < layer.tileIds[y].length; x++) {
        final tileId = layer.tileIds[y][x];
        if (tileId == null) continue;

        final tile = notifier.getTileById(tileId);
        if (tile == null) continue;

        _drawTile(canvas, tile, x * tileSize, y * tileSize, layer.opacity);
      }
    }
  }

  void _drawTile(Canvas canvas, SavedTile tile, double x, double y, double opacity) {
    final pixelWidth = tileSize / tile.width;
    final pixelHeight = tileSize / tile.height;

    for (int py = 0; py < tile.height; py++) {
      for (int px = 0; px < tile.width; px++) {
        final index = py * tile.width + px;
        if (index < tile.pixels.length) {
          final color = Color(tile.pixels[index]);
          if (color.alpha > 0) {
            final paint = Paint()..color = color.withValues(alpha: color.a * opacity);
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
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    for (int x = 0; x <= state.gridWidth; x++) {
      canvas.drawLine(
        Offset(x * tileSize, 0),
        Offset(x * tileSize, size.height),
        gridPaint,
      );
    }

    for (int y = 0; y <= state.gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * tileSize),
        Offset(size.width, y * tileSize),
        gridPaint,
      );
    }
  }

  void _drawHoverCell(Canvas canvas) {
    if (hoverCell == null) return;

    final (x, y) = hoverCell!;
    final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);

    final hoverColor = isModifierPressed ? Colors.orange : colorScheme.primary;

    final hoverPaint = Paint()
      ..color = hoverColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, hoverPaint);

    final borderPaint = Paint()
      ..color = hoverColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(1), borderPaint);

    if (isModifierPressed) {
      final iconPaint = Paint()..color = Colors.orange;
      final center = rect.center;
      canvas.drawCircle(center, 6, iconPaint);
    }
  }

  @override
  bool shouldRepaint(TilemapPainter oldDelegate) => true;
}

/// Tile preview painter for tile cards
class TilePreviewPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;

  TilePreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    final lightPaint = Paint()..color = const Color(0xFFE0E0E0);
    final darkPaint = Paint()..color = const Color(0xFFBDBDBD);
    final checkerSize = min(pixelWidth, pixelHeight);

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isLight = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final color = Color(pixels[index]);
          if (color.alpha > 0) {
            final paint = Paint()..color = color;
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
    }
  }

  @override
  bool shouldRepaint(TilePreviewPainter oldDelegate) {
    return oldDelegate.pixels != pixels || oldDelegate.width != width || oldDelegate.height != height;
  }
}

/// Painter for tile editing canvas with pixels
class TilePixelsPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;
  final bool showGrid;

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
    final lightPaint = Paint()..color = const Color(0xFFE0E0E0);
    final darkPaint = Paint()..color = const Color(0xFFBDBDBD);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isLight = (x + y) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x * pixelWidth, y * pixelHeight, pixelWidth, pixelHeight),
          isLight ? lightPaint : darkPaint,
        );
      }
    }

    // Pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final color = Color(pixels[index]);
          if (color.alpha > 0) {
            final paint = Paint()..color = color;
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
    }

    // Grid
    if (showGrid && pixelWidth > 4) {
      final gridPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..strokeWidth = 0.5;

      for (int x = 0; x <= width; x++) {
        canvas.drawLine(
          Offset(x * pixelWidth, 0),
          Offset(x * pixelWidth, size.height),
          gridPaint,
        );
      }
      for (int y = 0; y <= height; y++) {
        canvas.drawLine(
          Offset(0, y * pixelHeight),
          Offset(size.width, y * pixelHeight),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TilePixelsPainter oldDelegate) {
    return oldDelegate.pixels != pixels ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.showGrid != showGrid;
  }
}
