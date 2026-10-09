import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PixelPreviewPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;

  PixelPreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  final _drawPaint = Paint()..style = PaintingStyle.fill;
  final _checkerPaint1 = Paint()..color = Colors.grey.shade200;
  final _checkerPaint2 = Paint()..color = Colors.grey.shade100;

  @override
  void paint(Canvas canvas, Size size) {
    // Create a checkerboard background for transparent areas

    final checkerSize = size.width / 10;
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 10; x++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x * checkerSize,
            y * checkerSize,
            checkerSize,
            checkerSize,
          ),
          (x + y) % 2 == 0 ? _checkerPaint1 : _checkerPaint2,
        );
      }
    }

    // Draw the pixels
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final color = Color(pixels[index]);
          if (color.alpha == 0) continue;

          _drawPaint.color = color;
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelWidth,
              y * pixelHeight,
              pixelWidth,
              pixelHeight,
            ),
            _drawPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelPreviewPainter oldDelegate) {
    return !listEquals(oldDelegate.pixels, pixels) || oldDelegate.width != width || oldDelegate.height != height;
  }
}

class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter({this.squares = 10});

  final int squares;

  static final _checkerPaint1 = Paint()..color = Colors.grey.shade200;
  static final _checkerPaint2 = Paint()..color = Colors.grey.shade100;

  @override
  void paint(Canvas canvas, Size size) {
    final checkerSize = size.width / squares;
    for (int y = 0; y < squares; y++) {
      for (int x = 0; x < squares; x++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x * checkerSize,
            y * checkerSize,
            checkerSize,
            checkerSize,
          ),
          (x + y) % 2 == 0 ? _checkerPaint1 : _checkerPaint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
