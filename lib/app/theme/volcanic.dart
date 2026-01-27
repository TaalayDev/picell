import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildVolcanicTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.volcanic,
    isDark: true,
    primaryColor: const Color(0xFFFF4500), // Orange red (lava)
    primaryVariant: const Color(0xFFFF6347), // Tomato red
    onPrimary: Colors.white,
    // Secondary colors - molten gold
    accentColor: const Color(0xFFFFD700), // Gold (molten metal)
    onAccent: Colors.black,
    // Background colors - dark volcanic rock
    background: const Color(0xFF1A0F0A), // Very dark brown-black (volcanic rock)
    surface: const Color(0xFF2D1B12), // Dark charcoal brown
    surfaceVariant: const Color(0xFF3D251A), // Lighter volcanic brown
    // Text colors - light against dark volcanic background
    textPrimary: const Color(0xFFFFF8E7), // Warm white
    textSecondary: const Color(0xFFE6D4C1), // Warm beige
    textDisabled: const Color(0xFF9B8371), // Muted brown
    // UI colors
    divider: const Color(0xFF4A3429),
    toolbarColor: const Color(0xFF2D1B12),
    error: const Color(0xFFFF1744), // Bright red
    success: const Color(0xFF4CAF50), // Green for contrast
    warning: const Color(0xFFFF9800), // Orange warning
    // Grid colors
    gridLine: const Color(0xFF4A3429),
    gridBackground: const Color(0xFF2D1B12),
    // Canvas colors
    canvasBackground: const Color(0xFF1A0F0A),
    selectionOutline: const Color(0xFFFF4500), // Match primary
    selectionFill: const Color(0x30FF4500),
    // Icon colors
    activeIcon: const Color(0xFFFF4500), // Lava orange for active
    inactiveIcon: const Color(0xFFE6D4C1), // Warm beige for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFFFF8E7),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFFFF8E7),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFFFF8E7),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFE6D4C1),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Enhanced Volcanic theme background - Inside the volcano perspective
class VolcanicBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const VolcanicBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeIntensity = intensity.clamp(0.2, 2.0);
    final controller = useAnimationController(
      duration: Duration(milliseconds: (24000 / safeIntensity).round()),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat(); // t in [0,1) repeating—now truly seamless
      } else {
        controller.stop();
        controller.value = 0.0;
      }
      return null;
    }, [enableAnimation, safeIntensity]);

    final emberSeeds = useMemoized(
      () => _EmberSeeds.generate(
        count: (48 * safeIntensity).round(),
        randomness: 1337,
      ),
      [safeIntensity],
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = enableAnimation ? controller.value : 0.0; // 0..1
          return CustomPaint(
            painter: _VolcanicPainter(
              theme: theme,
              time: t,
              intensity: safeIntensity,
              emberSeeds: emberSeeds,
              animationEnabled: enableAnimation,
            ),
            isComplex: true,
            willChange: enableAnimation,
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _VolcanicPainter extends CustomPainter {
  final AppTheme theme;
  final double time; // 0..1 loop
  final double intensity;
  final List<_EmberSeed> emberSeeds;
  final bool animationEnabled;

  _VolcanicPainter({
    required this.theme,
    required this.time,
    required this.intensity,
    required this.emberSeeds,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) Basalt base gradient
    final baseGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _mix(theme.background, Colors.black, 0.2),
          theme.surface,
          _mix(theme.surface, theme.surfaceVariant, 0.25),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, baseGrad);

    // 2) Ground glows
    _drawGroundGlow(canvas, size);

    // // 3) Lava rivers (periodic sway)
    _drawLavaRivers(canvas, size);

    // // 4) Embers (integer-harmonic rise/sway)
    _drawEmbers(canvas, size);

    // // 5) Heat shimmer (sine band, perfect loop)
    _drawHeatShimmer(canvas, size);

    // // 6) Vignette
    _drawVignette(canvas, size);
  }

  void _drawGroundGlow(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    final lavaCore = theme.primaryColor;
    final glow1 = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.0, 1.05),
        radius: 0.9,
        colors: [lavaCore.withOpacity(0.22 * intensity), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow1);

    for (final x in [-0.65, 0.65]) {
      final r = math.min(w, h) * 0.65;
      final p = Paint()
        ..shader = RadialGradient(
          center: Alignment(x, 1.15),
          radius: 0.55,
          colors: [
            _mix(lavaCore, theme.accentColor, 0.25).withOpacity(0.18 * intensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(w * (0.5 + x * 0.5), h * 0.95), radius: r),
        );
      canvas.drawRect(Offset.zero & size, p);
    }
  }

  void _drawLavaRivers(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final lavaHot = _mix(theme.accentColor, Colors.white, 0.2);
    final lavaMid = theme.primaryVariant;
    final lavaCool = theme.primaryColor;

    // Integer kCurve ensures perfect loop: sin(2π*(k*t + time) + phase)
    const kCurve = 3; // waviness along path (integer for a closed form)

    final rivers = <_RiverSpec>[
      _RiverSpec(baseX: w * 0.22, amp: w * 0.06, thickness: math.max(6.0, 7.0 * intensity), phase: 0.00),
      _RiverSpec(baseX: w * 0.50, amp: w * 0.08, thickness: math.max(6.0, 8.0 * intensity), phase: 2.33),
      _RiverSpec(baseX: w * 0.78, amp: w * 0.05, thickness: math.max(5.0, 6.5 * intensity), phase: 4.10),
    ];

    for (final river in rivers) {
      final path = Path();
      const segments = 6;
      for (int i = 0; i <= segments; i++) {
        final u = i / segments; // 0..1 along river height
        final y = h * (1.0 - u * 0.9);
        final angle = 2 * math.pi * (kCurve * u + time) + river.phase;
        final x = river.baseX + river.amp * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevU = (i - 1) / segments;
          final prevY = h * (1.0 - prevU * 0.9);
          final prevAngle = 2 * math.pi * (kCurve * prevU + time) + river.phase;
          final prevX = river.baseX + river.amp * math.sin(prevAngle);
          final cx = (prevX + x) / 2.0;
          final cy = (prevY + y) / 2.0;
          path.quadraticBezierTo(prevX, prevY, cx, cy);
        }
      }

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = river.thickness * 2.8
        ..color = lavaCool.withOpacity(0.10 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);

      final midGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = river.thickness * 1.8
        ..color = lavaMid.withOpacity(0.18 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, midGlowPaint);

      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = river.thickness
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lavaHot, lavaMid, lavaCool],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, corePaint);
    }
  }

  void _drawEmbers(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final base = theme.accentColor;
    final emberPaint = Paint()..style = PaintingStyle.fill;

    for (final s in emberSeeds) {
      // Integer harmonic => rise = frac(h*t + phase) loops perfectly at t=1.
      final rise = _frac(s.harmonic * time + s.phase);
      final y = h * (1.05 - rise);
      if (y < -8) continue;

      // Sway: also integer harmonic so it closes at t=1
      final swayAngle = 2 * math.pi * (s.swayHarmonic * time + s.phase);
      final sway = math.sin(swayAngle) * (10.0 + 10.0 * s.sway);

      final x = w * s.x + sway;

      final radius = _lerp(0.8, 2.2, s.radius) * (0.8 + 0.2 * intensity);
      final lifeFade = rise; // fade as it rises
      final alpha = (0.65 - lifeFade * 0.55) * (0.35 + 0.65 * s.alpha) * (0.8 + 0.2 * intensity);

      // soft glow
      emberPaint
        ..color = base.withOpacity(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      canvas.drawCircle(Offset(x, y), radius * 2.4, emberPaint);

      // core
      emberPaint
        ..maskFilter = null
        ..color = _mix(base, theme.primaryColor, 0.35).withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, emberPaint);
    }
  }

  void _drawHeatShimmer(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Use sine-modulated opacity & slight vertical scale—no modulo shifts.
    final s = (math.sin(2 * math.pi * time) + 1) * 0.5; // 0..1 loop
    final alpha = 0.06 * intensity * (0.6 + 0.4 * s);
    final grad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.transparent,
          _mix(theme.primaryColor, theme.accentColor, 0.25).withOpacity(alpha),
          Colors.transparent,
        ],
        stops: const [0.2, 0.5, 0.8],
      ).createShader(rect);

    canvas.drawRect(rect, grad);
  }

  void _drawVignette(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.10),
          Colors.black.withOpacity(0.20),
        ],
        stops: const [0.65, 0.9, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _VolcanicPainter old) {
    return animationEnabled;
  }
}

class _RiverSpec {
  final double baseX;
  final double amp;
  final double thickness;
  final double phase;

  _RiverSpec({
    required this.baseX,
    required this.amp,
    required this.thickness,
    required this.phase,
  });
}

class _EmberSeeds {
  static List<_EmberSeed> generate({required int count, required int randomness}) {
    final rnd = math.Random(randomness);
    return List.generate(count, (_) {
      // Integer harmonics 1..3 for rise and 1..4 for sway (ensures closed motion).
      final harmonic = 1 + rnd.nextInt(3);
      final swayHarmonic = 1 + rnd.nextInt(4);
      return _EmberSeed(
        x: rnd.nextDouble() * 0.96 + 0.02,
        radius: rnd.nextDouble(),
        sway: rnd.nextDouble(),
        alpha: rnd.nextDouble(),
        phase: rnd.nextDouble(), // 0..1
        harmonic: harmonic,
        swayHarmonic: swayHarmonic,
      );
    });
  }
}

class _EmberSeed {
  final double x;
  final double radius; // 0..1
  final double sway; // 0..1
  final double alpha; // 0..1
  final double phase; // 0..1
  final int harmonic; // integer vertical rise harmonic
  final int swayHarmonic; // integer horizontal sway harmonic

  const _EmberSeed({
    required this.x,
    required this.radius,
    required this.sway,
    required this.alpha,
    required this.phase,
    required this.harmonic,
    required this.swayHarmonic,
  });
}

/// Helpers
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _frac(double x) => x - x.floorToDouble();

Color _mix(Color a, Color b, double t) {
  return Color.fromARGB(
    (a.alpha + (b.alpha - a.alpha) * t).round(),
    (a.red + (b.red - a.red) * t).round(),
    (a.green + (b.green - a.green) * t).round(),
    (a.blue + (b.blue - a.blue) * t).round(),
  );
}
