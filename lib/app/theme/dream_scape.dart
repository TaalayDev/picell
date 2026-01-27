import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// DREAMSCAPE THEME BUILDER
// ============================================================================

AppTheme buildDreamscapeTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.dreamscape,
    isDark: false,
    // Primary colors - dreamy lavender
    primaryColor: const Color(0xFF9B59B6), // Rich lavender
    primaryVariant: const Color(0xFF8E44AD), // Deeper purple
    onPrimary: Colors.white,
    // Secondary colors - soft rose
    accentColor: const Color(0xFFE91E63), // Soft rose pink
    onAccent: Colors.white,
    // Background colors - cloud white with hints
    background: const Color(0xFFFAF8FF), // Very light lavender white
    surface: const Color(0xFFFFFFFF), // Pure white clouds
    surfaceVariant: const Color(0xFFF5F0FF), // Light lavender
    // Text colors - deep dream purple
    textPrimary: const Color(0xFF4A4458), // Deep dreamy purple
    textSecondary: const Color(0xFF6A5D7B), // Medium dream purple
    textDisabled: const Color(0xFFB8A9C9), // Light dreamy purple
    // UI colors
    divider: const Color(0xFFE8E0F0), // Very light purple
    toolbarColor: const Color(0xFFF5F0FF),
    error: const Color(0xFFE74C3C), // Bright red for contrast
    success: const Color(0xFF27AE60), // Fresh green
    warning: const Color(0xFFF39C12), // Warm orange
    // Grid colors
    gridLine: const Color(0xFFE8E0F0),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFF9B59B6), // Match primary
    selectionFill: const Color(0x309B59B6),
    // Icon colors
    activeIcon: const Color(0xFF9B59B6), // Dreamy purple for active
    inactiveIcon: const Color(0xFF6A5D7B), // Medium purple for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF4A4458),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF4A4458),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF4A4458),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF6A5D7B),
      ),
    ),
    primaryFontWeight: FontWeight.w400, // Light weight for dreamy feel
  );
}

// ============================================================================
// DREAMSCAPE ANIMATED BACKGROUND
// ============================================================================

class DreamscapeBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const DreamscapeBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ticker controller
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

    // 2. State for infinite animation
    final dreamState = useMemoized(() => _DreamState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnhancedDreamscapePainter(
          repaint: controller,
          state: dreamState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for physics and objects
class _DreamState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_DreamCloud>? clouds;
  List<_DreamBubble>? bubbles;
  List<_DreamStar>? stars;
}

class _DreamCloud {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  _DreamCloud({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _DreamBubble {
  double x;
  double y;
  double speedY;
  double size;
  double wobblePhase;
  double wobbleSpeed;
  Color color;

  _DreamBubble({
    required this.x,
    required this.y,
    required this.speedY,
    required this.size,
    required this.wobblePhase,
    required this.wobbleSpeed,
    required this.color,
  });
}

class _DreamStar {
  double x;
  double y;
  double size;
  double twinklePhase;
  double twinkleSpeed;

  _DreamStar({
    required this.x,
    required this.y,
    required this.size,
    required this.twinklePhase,
    required this.twinkleSpeed,
  });
}

class _EnhancedDreamscapePainter extends CustomPainter {
  final _DreamState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  final math.Random _rng = math.Random(999);

  _EnhancedDreamscapePainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Time accumulation
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialization
    if (state.clouds == null) _initWorld(size);

    _paintBackground(canvas, size);
    _paintStars(canvas, size);
    _paintMist(canvas, size);
    _updateAndPaintClouds(canvas, size, dt);
    _paintRibbons(canvas, size);
    _updateAndPaintBubbles(canvas, size, dt);
    _paintVignette(canvas, size);
  }

  void _initWorld(Size size) {
    state.clouds = [];
    state.bubbles = [];
    state.stars = [];
    final rng = math.Random(1234);

    // Init Clouds
    for (int i = 0; i < 12; i++) {
      state.clouds!.add(_DreamCloud(
        x: rng.nextDouble() * size.width,
        y: size.height * (0.1 + rng.nextDouble() * 0.5),
        speed: 10 + rng.nextDouble() * 15,
        size: 40 + rng.nextDouble() * 60,
        opacity: 0.1 + rng.nextDouble() * 0.2,
      ));
    }

    // Init Stars
    for (int i = 0; i < 40; i++) {
      state.stars!.add(_DreamStar(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 1 + rng.nextDouble() * 3,
        twinklePhase: rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 1 + rng.nextDouble() * 3,
      ));
    }

    // Init Bubbles
    for (int i = 0; i < 20; i++) {
      state.bubbles!.add(_DreamBubble(
        x: rng.nextDouble() * size.width,
        y: size.height + rng.nextDouble() * 100,
        speedY: 15 + rng.nextDouble() * 25,
        size: 5 + rng.nextDouble() * 15,
        wobblePhase: rng.nextDouble() * math.pi * 2,
        wobbleSpeed: 1 + rng.nextDouble() * 2,
        color: i % 2 == 0 ? primaryColor : accentColor,
      ));
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [
        const Color(0xFFE6E6FA).withOpacity(0.5), // Lavender Mist
        const Color(0xFFF8F8FF), // Ghost White
        const Color(0xFFFFE4E1).withOpacity(0.5), // Misty Rose
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  void _paintStars(Canvas canvas, Size size) {
    if (state.stars == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in state.stars!) {
      final twinkle = math.sin(state.time * star.twinkleSpeed + star.twinklePhase) * 0.5 + 0.5;

      paint.color = primaryColor.withOpacity(0.3 * twinkle * intensity);
      canvas.drawCircle(Offset(star.x, star.y), star.size * intensity, paint);

      // Star cross shimmer
      if (twinkle > 0.7) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.5 * intensity;
        paint.color = accentColor.withOpacity(0.4 * twinkle * intensity);

        final len = star.size * 2 * intensity;
        canvas.drawLine(Offset(star.x - len, star.y), Offset(star.x + len, star.y), paint);
        canvas.drawLine(Offset(star.x, star.y - len), Offset(star.x, star.y + len), paint);

        paint.style = PaintingStyle.fill;
      }
    }
  }

  void _paintMist(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.05 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    for (int i = 0; i < 3; i++) {
      final t = state.time * 0.2 + i;
      final x = size.width * 0.5 + math.sin(t) * size.width * 0.3;
      final y = size.height * (0.3 + i * 0.2) + math.cos(t * 0.7) * 50;

      canvas.drawCircle(Offset(x, y), 100 * intensity, paint);
    }
  }

  void _updateAndPaintClouds(Canvas canvas, Size size, double dt) {
    if (state.clouds == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var cloud in state.clouds!) {
      // Update
      cloud.x += cloud.speed * dt * intensity;

      // Wrap
      if (cloud.x > size.width + cloud.size * 2) {
        cloud.x = -cloud.size * 2;
        cloud.y = size.height * (0.1 + _rng.nextDouble() * 0.5);
      }

      // Draw
      paint.color = Colors.white.withOpacity(cloud.opacity);

      // Cloud Shape (Cluster of circles)
      canvas.drawCircle(Offset(cloud.x, cloud.y), cloud.size * intensity, paint);
      canvas.drawCircle(
          Offset(cloud.x - cloud.size * 0.5, cloud.y + cloud.size * 0.2), cloud.size * 0.7 * intensity, paint);
      canvas.drawCircle(
          Offset(cloud.x + cloud.size * 0.5, cloud.y + cloud.size * 0.1), cloud.size * 0.8 * intensity, paint);
    }
  }

  void _paintRibbons(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * intensity
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startY = size.height * (0.4 + i * 0.15);

      path.moveTo(0, startY);

      for (double x = 0; x <= size.width; x += 20) {
        final y = startY +
            math.sin(x * 0.01 + state.time * 0.5 + i) * 30 * intensity +
            math.cos(x * 0.02 - state.time * 0.3) * 15 * intensity;
        path.lineTo(x, y);
      }

      final alpha = 0.3 + 0.2 * math.sin(state.time + i);

      paint.shader = ui.Gradient.linear(Offset(0, 0), Offset(size.width, 0), [
        primaryColor.withOpacity(0.0),
        primaryColor.withOpacity(0.1 * alpha * intensity),
        accentColor.withOpacity(0.1 * alpha * intensity),
        accentColor.withOpacity(0.0),
      ], [
        0.0,
        0.4,
        0.6,
        1.0
      ]);

      canvas.drawPath(path, paint);
    }
    paint.shader = null;
  }

  void _updateAndPaintBubbles(Canvas canvas, Size size, double dt) {
    if (state.bubbles == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var bubble in state.bubbles!) {
      // Update
      bubble.y -= bubble.speedY * dt * intensity;
      bubble.wobblePhase += bubble.wobbleSpeed * dt;
      final wobbleX = math.sin(bubble.wobblePhase) * 10 * intensity;

      // Wrap
      if (bubble.y < -bubble.size * 2) {
        bubble.y = size.height + bubble.size + _rng.nextDouble() * 50;
        bubble.x = _rng.nextDouble() * size.width;
      }

      // Draw
      final bx = bubble.x + wobbleX;
      final by = bubble.y;

      final alpha = 0.4 + 0.2 * math.sin(state.time * 2 + bubble.x);

      // Main Bubble
      paint.color = bubble.color.withOpacity(0.2 * alpha * intensity);
      canvas.drawCircle(Offset(bx, by), bubble.size * intensity, paint);

      // Rim
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1 * intensity;
      paint.color = bubble.color.withOpacity(0.4 * alpha * intensity);
      canvas.drawCircle(Offset(bx, by), bubble.size * intensity, paint);

      // Highlight
      paint.style = PaintingStyle.fill;
      paint.color = Colors.white.withOpacity(0.3 * alpha * intensity);
      canvas.drawCircle(Offset(bx - bubble.size * 0.3, by - bubble.size * 0.3), bubble.size * 0.25 * intensity, paint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.8,
      [
        Colors.transparent,
        Colors.white.withOpacity(0.3 * intensity),
        primaryColor.withOpacity(0.1 * intensity),
      ],
      [0.6, 0.9, 1.0],
    );

    canvas.drawRect(
        rect,
        Paint()
          ..shader = gradient
          ..blendMode = BlendMode.softLight);
  }

  @override
  bool shouldRepaint(covariant _EnhancedDreamscapePainter oldDelegate) {
    return animationEnabled;
  }
}
