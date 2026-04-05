import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft crossfade with a gentle scale, plus floating petal particles
/// that bloom over the screen at the start of the transition.
class CherryPetalTransition extends StatefulWidget {
  const CherryPetalTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  static Widget builder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CherryPetalTransition(animation: animation, child: child);
  }

  @override
  State<CherryPetalTransition> createState() => _CherryPetalTransitionState();
}

class _CherryPetalTransitionState extends State<CherryPetalTransition> {
  static final _rng = math.Random(42);
  late final List<_PetalData> _petals = List.generate(
    12,
    (i) => _PetalData(
      x: _rng.nextDouble(),
      startY: _rng.nextDouble() * 0.4,
      size: 8 + _rng.nextDouble() * 10,
      speed: 0.6 + _rng.nextDouble() * 0.4,
      angle: _rng.nextDouble() * math.pi,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeInOutSine,
    );
    final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curved);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: curved,
              child: ScaleTransition(scale: scale, child: child),
            ),
            // Petal particles — visible in first 60% of transition
            if (curved.value < 0.6)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PetalPainter(
                      petals: _petals,
                      progress: curved.value / 0.6,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _PetalData {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double angle;

  _PetalData({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

class _PetalPainter extends CustomPainter {
  final List<_PetalData> petals;
  final double progress; // 0..1

  _PetalPainter({required this.petals, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB7C5).withValues(alpha: (1 - progress) * 0.7)
      ..style = PaintingStyle.fill;

    for (final p in petals) {
      final x = p.x * size.width + math.sin(progress * math.pi * 2) * 20;
      final y = (p.startY + progress * p.speed) * size.height;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + progress * math.pi);
      paint.color = const Color(0xFFFFB7C5).withValues(alpha: opacity * 0.8);

      // Draw a simple oval petal shape
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => old.progress != progress;
}
