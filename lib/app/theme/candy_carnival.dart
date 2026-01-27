import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// CANDY CARNIVAL THEME BUILDER
// ============================================================================

AppTheme buildCandyCarnivalTheme() {
  final baseTextTheme = GoogleFonts.fredokaTextTheme();
  final bodyTextTheme = GoogleFonts.nunitoTextTheme();

  return AppTheme(
    type: ThemeType.candyCarnival,
    isDark: false,

    // Primary colors - bubblegum and taffy
    primaryColor: const Color(0xFFFF5FA2),
    primaryVariant: const Color(0xFFE03F88),
    onPrimary: Colors.white,

    // Secondary colors - mint soda
    accentColor: const Color(0xFF35D5D0),
    onAccent: const Color(0xFF0E3E3C),

    // Background colors - creamy vanilla
    background: const Color(0xFFFFF6EE),
    surface: const Color(0xFFFFFFFF),
    surfaceVariant: const Color(0xFFFFE8F1),

    // Text colors
    textPrimary: const Color(0xFF3B2847),
    textSecondary: const Color(0xFF6D4F6F),
    textDisabled: const Color(0xFFB39DAE),

    // UI colors
    divider: const Color(0xFFF1D6E3),
    toolbarColor: const Color(0xFFFFF1E9),
    error: const Color(0xFFE5484D),
    success: const Color(0xFF3FB986),
    warning: const Color(0xFFF2A74B),

    // Grid colors
    gridLine: const Color(0xFFF1D6E3),
    gridBackground: const Color(0xFFFFF6EE),

    // Canvas colors
    canvasBackground: const Color(0xFFFFF8F2),
    selectionOutline: const Color(0xFFFF5FA2),
    selectionFill: const Color(0x33FF5FA2),

    // Icon colors
    activeIcon: const Color(0xFFFF5FA2),
    inactiveIcon: const Color(0xFF6D4F6F),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF3B2847),
        fontWeight: FontWeight.w600,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF3B2847),
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF5B3566),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF5B3566),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF3B2847),
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF6D4F6F),
        fontWeight: FontWeight.w500,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFFF5FA2),
        fontWeight: FontWeight.w600,
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

// ============================================================================
// CANDY CARNIVAL ANIMATED BACKGROUND
// ============================================================================

class CandyCarnivalBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CandyCarnivalBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    final candyState = useMemoized(() => _CandyCarnivalState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CandyCarnivalPainter(
          repaint: controller,
          state: candyState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          backgroundColor: theme.background,
          intensity: intensity.clamp(0.0, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CandyCarnivalState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_ConfettiPiece>? confetti;
  List<_CandyBubble>? bubbles;
}

enum _ConfettiShape { square, circle, triangle, stream }

class _ConfettiPiece {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double rotation;
  double rotSpeed;
  double driftPhase;
  Color color;
  _ConfettiShape shape;

  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotSpeed,
    required this.driftPhase,
    required this.color,
    required this.shape,
  });
}

class _CandyBubble {
  double x;
  double y;
  double radius;
  double speedY;
  double wobble;
  double opacity;

  _CandyBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.wobble,
    required this.opacity,
  });
}

class _CandyCarnivalPainter extends CustomPainter {
  final _CandyCarnivalState state;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final double intensity;
  final bool animationEnabled;

  final math.Random _rng = math.Random(428);

  _CandyCarnivalPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.intensity,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    if (state.confetti == null || state.bubbles == null) {
      _initWorld(size);
    }

    _paintTaffySwirls(canvas, size);
    _paintRibbons(canvas, size);
    _updateAndPaintBubbles(canvas, size, dt);
    _updateAndPaintConfetti(canvas, size, dt);
    _paintVignette(canvas, size);
  }

  void _initWorld(Size size) {
    state.confetti = [];
    state.bubbles = [];

    final palette = [
      primaryColor,
      accentColor,
      const Color(0xFFFFD166),
      const Color(0xFF7AE7C7),
      const Color(0xFFFF8E72),
      const Color(0xFF9B8CFF),
    ];

    final confettiCount = math.max(18, (42 * intensity).round());
    for (int i = 0; i < confettiCount; i++) {
      state.confetti!.add(_ConfettiPiece(
        x: _rng.nextDouble() * size.width,
        y: _rng.nextDouble() * size.height,
        size: 4 + _rng.nextDouble() * 7,
        speedX: (_rng.nextDouble() - 0.5) * 16,
        speedY: 10 + _rng.nextDouble() * 22,
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 2.2,
        driftPhase: _rng.nextDouble() * math.pi * 2,
        color: palette[_rng.nextInt(palette.length)],
        shape: _ConfettiShape.values[_rng.nextInt(_ConfettiShape.values.length)],
      ));
    }

    final bubbleCount = math.max(6, (10 * intensity).round());
    for (int i = 0; i < bubbleCount; i++) {
      state.bubbles!.add(_CandyBubble(
        x: _rng.nextDouble() * size.width,
        y: size.height * (0.4 + _rng.nextDouble() * 0.6),
        radius: size.width * (0.04 + _rng.nextDouble() * 0.06),
        speedY: 6 + _rng.nextDouble() * 8,
        wobble: _rng.nextDouble() * math.pi * 2,
        opacity: 0.04 + _rng.nextDouble() * 0.06,
      ));
    }
  }

  void _paintTaffySwirls(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final drift = math.sin(state.time * 0.2) * size.width * 0.03;

    final wash = ui.Gradient.linear(
      Offset(drift, 0),
      Offset(size.width + drift, size.height),
      [
        backgroundColor,
        Color.lerp(backgroundColor, primaryColor, 0.08)!,
        Color.lerp(backgroundColor, accentColor, 0.06)!,
      ],
      [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = wash);

    final swirls = [
      _SwirlSpec(
        center: Offset(size.width * 0.2, size.height * 0.25),
        radius: size.width * 0.38,
        color: primaryColor.withOpacity(0.08 * intensity),
        phase: 0.0,
      ),
      _SwirlSpec(
        center: Offset(size.width * 0.85, size.height * 0.18),
        radius: size.width * 0.28,
        color: accentColor.withOpacity(0.07 * intensity),
        phase: 1.6,
      ),
      _SwirlSpec(
        center: Offset(size.width * 0.7, size.height * 0.6),
        radius: size.width * 0.42,
        color: primaryColor.withOpacity(0.05 * intensity),
        phase: 3.1,
      ),
    ];

    for (final swirl in swirls) {
      final offset = Offset(
        math.cos(state.time * 0.18 + swirl.phase) * size.width * 0.02,
        math.sin(state.time * 0.16 + swirl.phase) * size.height * 0.02,
      );
      final center = swirl.center + offset;
      final shader = ui.Gradient.radial(
        center,
        swirl.radius,
        [swirl.color, Colors.transparent],
      );
      canvas.drawCircle(center, swirl.radius, Paint()..shader = shader);
    }
  }

  void _paintRibbons(Canvas canvas, Size size) {
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final baseY = size.height * (0.12 + i * 0.18);
      final amp = size.height * (0.015 + i * 0.006) * intensity;
      final wavelength = size.width * (0.45 + i * 0.08);
      final phase = state.time * (0.4 + i * 0.12);

      ribbonPaint
        ..strokeWidth = 2.0 + i * 0.6
        ..color = Color.lerp(primaryColor, accentColor, i / 2)!.withOpacity(0.2 - i * 0.04);

      final path = Path();
      for (double x = 0; x <= size.width; x += 6) {
        final y = baseY + math.sin((x / wavelength) * 2 * math.pi + phase) * amp;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, ribbonPaint);
    }
  }

  void _updateAndPaintBubbles(Canvas canvas, Size size, double dt) {
    if (state.bubbles == null) return;

    final paint = Paint()..style = PaintingStyle.fill;
    for (final bubble in state.bubbles!) {
      bubble.y -= bubble.speedY * dt * intensity;
      final wobble = math.sin(state.time * 0.6 + bubble.wobble) * size.width * 0.01;
      if (bubble.y + bubble.radius < 0) {
        bubble.y = size.height + bubble.radius * 2;
        bubble.x = _rng.nextDouble() * size.width;
      }

      final center = Offset(bubble.x + wobble, bubble.y);
      final shader = ui.Gradient.radial(
        center,
        bubble.radius,
        [
          accentColor.withOpacity(bubble.opacity * 1.2),
          Colors.transparent,
        ],
      );
      paint.shader = shader;
      canvas.drawCircle(center, bubble.radius, paint);
    }
  }

  void _updateAndPaintConfetti(Canvas canvas, Size size, double dt) {
    if (state.confetti == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final piece in state.confetti!) {
      piece.x += (piece.speedX + math.sin(state.time + piece.driftPhase) * 8) * dt * intensity;
      piece.y += piece.speedY * dt * intensity;
      piece.rotation += piece.rotSpeed * dt;

      if (piece.y - piece.size > size.height) {
        piece.y = -piece.size;
        piece.x = _rng.nextDouble() * size.width;
      }
      if (piece.x < -20) {
        piece.x = size.width + 20;
      } else if (piece.x > size.width + 20) {
        piece.x = -20;
      }

      paint.color = piece.color.withOpacity(0.85);

      canvas.save();
      canvas.translate(piece.x, piece.y);
      canvas.rotate(piece.rotation);

      switch (piece.shape) {
        case _ConfettiShape.square:
          final rect = Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(piece.size * 0.2)),
            paint,
          );
          break;
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, piece.size * 0.55, paint);
          break;
        case _ConfettiShape.triangle:
          final path = Path()
            ..moveTo(-piece.size * 0.5, piece.size * 0.45)
            ..lineTo(0, -piece.size * 0.55)
            ..lineTo(piece.size * 0.5, piece.size * 0.45)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case _ConfettiShape.stream:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: piece.size * 1.6,
            height: piece.size * 0.5,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(piece.size * 0.4)),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final vignette = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.5),
      size.longestSide * 0.8,
      [
        Colors.transparent,
        primaryColor.withOpacity(0.08 * intensity),
      ],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = vignette);
  }

  @override
  bool shouldRepaint(covariant _CandyCarnivalPainter oldDelegate) {
    return animationEnabled;
  }
}

class _SwirlSpec {
  final Offset center;
  final double radius;
  final Color color;
  final double phase;

  const _SwirlSpec({
    required this.center,
    required this.radius,
    required this.color,
    required this.phase,
  });
}
