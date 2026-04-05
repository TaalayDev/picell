import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final int width;
  final int height;
  final double scale;
  final Offset offset;

  GridPainter({
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cellWidth = size.width / width;
    final cellHeight = size.height / height;

    for (int i = 0; i <= width; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i <= height; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is GridPainter &&
        (oldDelegate.width != width ||
            oldDelegate.height != height ||
            oldDelegate.scale != scale ||
            oldDelegate.offset != offset);
  }
}
