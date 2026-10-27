import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Transparency checkerboard backdrop for pixel thumbnails and canvases.
class PvCheckerboard extends StatelessWidget {
  const PvCheckerboard({super.key, this.cell = 8, this.child});

  final double cell;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return CustomPaint(
      painter: _CheckerPainter(pv.checkerA, pv.checkerB, cell),
      child: child,
    );
  }
}

class _CheckerPainter extends CustomPainter {
  _CheckerPainter(this.a, this.b, this.cell);

  final Color a;
  final Color b;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final p = Paint()..color = b;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = (y.isEven ? 0 : 1); x < cols; x += 2) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), p);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => old.a != a || old.b != b || old.cell != cell;
}
