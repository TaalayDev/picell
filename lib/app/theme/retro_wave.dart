import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildRetroWaveTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.retroWave,
    isDark: true,
    // Primary colors - hot pink/magenta
    primaryColor: const Color(0xFFFF0080), // Hot pink/magenta
    primaryVariant: const Color(0xFFE91E63), // Deep pink
    onPrimary: Colors.white,
    // Secondary colors - electric cyan/blue
    accentColor: const Color(0xFF00FFFF), // Electric cyan
    onAccent: Colors.black,
    // Background colors - dark with purple gradients
    background: const Color(0xFF0A0A1A), // Very dark blue-purple
    surface: const Color(0xFF1A1A2E), // Dark purple-blue
    surfaceVariant: const Color(0xFF16213E), // Darker blue
    // Text colors - bright neon
    textPrimary: const Color(0xFF00FFFF), // Bright cyan text
    textSecondary: const Color(0xFFFF0080), // Hot pink secondary text
    textDisabled: const Color(0xFF666B85), // Muted blue-gray
    // UI colors
    divider: const Color(0xFF2A2D47),
    toolbarColor: const Color(0xFF1A1A2E),
    error: const Color(0xFFFF073A), // Bright neon red
    success: const Color(0xFF39FF14), // Electric lime
    warning: const Color(0xFFFFFF00), // Electric yellow
    // Grid colors
    gridLine: const Color(0xFF2A2D47),
    gridBackground: const Color(0xFF1A1A2E),
    // Canvas colors
    canvasBackground: const Color(0xFF0A0A1A),
    selectionOutline: const Color(0xFFFF0080), // Hot pink selection
    selectionFill: const Color(0x30FF0080),
    // Icon colors
    activeIcon: const Color(0xFFFF0080), // Hot pink for active
    inactiveIcon: const Color(0xFF00FFFF), // Cyan for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF00FFFF),
        fontWeight: FontWeight.w700, // Bold for retro feel
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF00FFFF),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF00FFFF),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFFF0080),
      ),
    ),
    primaryFontWeight: FontWeight.w600, // Bold for 80s aesthetic
  );
}

// Retro Wave theme background with 80s synthwave effects
class RetroWaveBackground extends HookWidget {
  final AppTheme theme;

  /// Controls the visual complexity and movement.
  /// Recommended range: 0.0 to 1.0. Clamped between 0.0 and 2.0.
  final double intensity;

  /// Toggles the animation on or off.
  final bool enableAnimation;

  const RetroWaveBackground({
    super.key,
    required this.theme,
    this.intensity = 0.8,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: theme.type.animationDuration,
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
        controller.value = 0;
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(controller);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _RetroWavePainter(
          t: t,
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

class _RetroWavePainter extends CustomPainter {
  final double t; // The master animation progress, from 0.0 to 1.0.
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  final Paint _paint;
  final List<Offset> _stars;
  final List<double> _starOpacities;

  _RetroWavePainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  })  : _paint = Paint(),
        _stars = List.generate(50, (index) {
          final random = math.Random(index);
          return Offset(random.nextDouble(), random.nextDouble());
        }),
        _starOpacities = List.generate(50, (index) {
          final random = math.Random(index * 2);
          return random.nextDouble();
        });

  // --- Aesthetic & Animation constants ---
  static const _bgTop = Color(0xFF0B0E2A);
  static const _bgBottom = Color(0xFF160C2C);

  // To ensure a perfect loop, all periodic animations must complete an
  // integer number of cycles over the animation duration `t`.
  static const _sunPulseCycles = 2;
  static const _gridPulseCycles = 1;
  static const _gridDriftCycles = 1;
  static const _particleCycles = 3;

  // --- Animation Helper Functions ---
  double get _phase => 2 * math.pi * t;

  /// Creates a periodic wave using sine, oscillating between -1.0 and 1.0.
  /// [cycles] determines how many full waves occur during the animation loop.
  double _wave(double cycles, [double offset = 0]) => math.sin(cycles * _phase + offset);

  /// Normalizes the wave function to oscillate between 0.0 and 1.0.
  double _norm(double cycles, [double offset = 0]) => 0.5 * (1 + _wave(cycles, offset));

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    final double horizonY = size.height * 0.72; // Lowered for a calmer feel.
    final double vanishingX = size.width * 0.5;

    _paintGrid(canvas, size, horizonY, vanishingX);
    _paintSun(canvas, size, horizonY, vanishingX);
    _paintScanLines(canvas, size);
    _drawStars(canvas, size, horizonY);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_bgTop, _bgBottom],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);
  }

  /// Paints the perspective grid.
  ///
  /// The grid is stabilized by simplifying the perspective calculation and
  /// using a very subtle, slow shimmer instead of a fast wobble.
  void _paintGrid(Canvas canvas, Size size, double horizonY, double vanishingX) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final baseAlpha = (0.23 * intensity).clamp(0.08, 0.23);
    final strokeW = (1.1 * intensity).clamp(0.6, 1.5);

    // --- Horizontal Lines ---
    // These lines are distributed quadratically to appear closer near the horizon.
    const rows = 10;
    for (int i = 0; i <= rows; i++) {
      final u = i / rows;
      final y = horizonY + (size.height - horizonY) * u * u;
      final pulse = _norm(_gridPulseCycles.toDouble(), i * 0.1);

      paint
        ..strokeWidth = strokeW
        ..color = Color.lerp(
          primaryColor.withOpacity(baseAlpha * 0.9),
          accentColor.withOpacity(baseAlpha * 0.7),
          0.6,
        )!
            .withOpacity(baseAlpha * (0.85 + 0.15 * pulse));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // --- Vertical Lines ---
    const colsEachSide = 9;
    final spacing = size.width * 0.045;
    // Controls how much the vertical lines spread out at the bottom.
    const perspectiveFactor = 1.8;

    for (int i = -colsEachSide; i <= colsEachSide; i++) {
      if (i == 0) continue; // Skip the center line.

      // A subtle, slow shimmer for the lines.
      final drift = 1.0 * intensity * _wave(_gridDriftCycles.toDouble(), i * 0.2);
      final xTop = vanishingX + i * spacing + drift;

      final p1 = Offset(xTop, horizonY);

      // Project the bottom point based on the top point's distance from center.
      final xBottom = vanishingX + (xTop - vanishingX) * perspectiveFactor;
      final p2 = Offset(xBottom, size.height);

      final side = (i.abs() / colsEachSide).clamp(0.0, 1.0);
      paint
        ..strokeWidth = strokeW
        ..color = Color.lerp(
          primaryColor.withOpacity(baseAlpha * (0.65 + 0.25 * (1 - side))),
          accentColor.withOpacity(baseAlpha * (0.45 + 0.25 * side)),
          0.4,
        )!;
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _paintSun(Canvas canvas, Size size, double horizonY, double vanishingX) {
    final center = Offset(vanishingX, horizonY);
    final baseR = 110.0 * (0.8 + 0.2 * intensity);
    final radius = baseR * (0.95 + 0.05 * _wave(_sunPulseCycles.toDouble()));

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    final glowColor = Color.lerp(primaryColor, accentColor, 0.35)!.withOpacity((0.22 * intensity).clamp(0.06, 0.22));
    glowPaint.color = glowColor;
    canvas.drawCircle(center.translate(0, -radius * 0.05), radius * 1.45, glowPaint);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));

    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Color.lerp(primaryColor, accentColor, 0.25)!.withOpacity(0.95),
          Color.lerp(primaryColor, accentColor, 0.25)!.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.0 * intensity).clamp(1.0, 3.0)
      ..color = Colors.black.withOpacity(0.18);
    for (int i = -4; i <= 4; i++) {
      final y = center.dy - radius * 0.85 + (i + 4) * (radius * 0.22);
      final halfW = math.sqrt(math.max(0, radius * radius - (y - center.dy) * (y - center.dy)));
      canvas.drawLine(Offset(center.dx - halfW, y), Offset(center.dx + halfW, y), stripePaint);
    }

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.8 * intensity).clamp(1.2, 2.2)
      ..color = Color.lerp(primaryColor, accentColor, 0.25)!.withOpacity(0.9);
    canvas.drawCircle(center, radius, outlinePaint);

    canvas.restore();

    final horizonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.2 * intensity).clamp(0.8, 1.6)
      ..color = Color.lerp(primaryColor, accentColor, 0.35)!.withOpacity(0.35);
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);
  }

  /// Paints sweeping scan lines that loop perfectly.
  void _paintScanLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.2 * intensity).clamp(0.8, 1.5);

    // Use modulo arithmetic for a seamless top-to-bottom sweep.
    final sweep1 = (t + 0.0) % 1.0;
    final sweep2 = (t + 0.5) % 1.0; // Second line is offset by half the screen.

    final y1 = sweep1 * size.height;
    final y2 = sweep2 * size.height;

    paint.color = primaryColor.withOpacity((0.12 * intensity).clamp(0.05, 0.14));
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);

    paint.color = accentColor.withOpacity((0.10 * intensity).clamp(0.04, 0.12));
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  void _drawStars(Canvas canvas, Size size, double horizonY) {
    _paint.style = PaintingStyle.fill;
    for (int i = 0; i < _stars.length; i++) {
      final starPos = _stars[i];
      final opacity = _starOpacities[i];

      final animOffset = t + opacity;
      final twinkle = math.sin(animOffset * 2 * math.pi);

      if (twinkle > 0.5) {
        _paint.color = Colors.white.withOpacity(twinkle * 0.8);
        canvas.drawCircle(
          Offset(starPos.dx * size.width, starPos.dy * horizonY),
          (twinkle * 0.8) * intensity,
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RetroWavePainter oldDelegate) {
    return animationEnabled;
  }
}
