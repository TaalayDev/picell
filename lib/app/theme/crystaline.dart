import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// CRYSTALLINE / GEODE THEME BUILDER
// ============================================================================

AppTheme buildCrystallineTheme() {
  final baseTextTheme = GoogleFonts.quicksandTextTheme();
  final bodyTextTheme = GoogleFonts.latoTextTheme();

  return AppTheme(
    type: ThemeType.crystalline,
    isDark: true,

    // Primary colors - amethyst purple
    primaryColor: const Color(0xFF9966CC),
    primaryVariant: const Color(0xFF7B4FA2),
    onPrimary: const Color(0xFFF0E6FF),

    // Secondary colors - crystal white/silver
    accentColor: const Color(0xFFE8E8F0),
    onAccent: const Color(0xFF2A1F3D),

    // Background colors - deep purple-black cave
    background: const Color(0xFF0D0A14),
    surface: const Color(0xFF16121F),
    surfaceVariant: const Color(0xFF1E1928),

    // Text colors
    textPrimary: const Color(0xFFE8E0F0),
    textSecondary: const Color(0xFFB8A8D0),
    textDisabled: const Color(0xFF5A4A6A),

    // UI colors
    divider: const Color(0xFF2A2438),
    toolbarColor: const Color(0xFF16121F),
    error: const Color(0xFFE57373),
    success: const Color(0xFF81C784),
    warning: const Color(0xFFFFB74D),

    // Grid colors
    gridLine: const Color(0xFF2A2438),
    gridBackground: const Color(0xFF16121F),

    // Canvas colors
    canvasBackground: const Color(0xFF0D0A14),
    selectionOutline: const Color(0xFF9966CC),
    selectionFill: const Color(0x309966CC),

    // Icon colors
    activeIcon: const Color(0xFF9966CC),
    inactiveIcon: const Color(0xFFB8A8D0),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFE8E0F0),
        fontWeight: FontWeight.w300,
        letterSpacing: 2,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFE8E0F0),
        fontWeight: FontWeight.w300,
        letterSpacing: 1.5,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE8E0F0),
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE8E0F0),
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE8E0F0),
        fontWeight: FontWeight.w300,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB8A8D0),
        fontWeight: FontWeight.w300,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFF9966CC),
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// CRYSTALLINE ANIMATED BACKGROUND - OPTIMIZED
// ============================================================================

class CrystallineBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CrystallineBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 20),
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
        painter: _CrystallinePainter(
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

// Pre-computed crystal data for performance
class _CrystalData {
  final double x;
  final double y;
  final double height;
  final double angle;
  final int colorIndex;
  final double phaseOffset;

  const _CrystalData(this.x, this.y, this.height, this.angle, this.colorIndex, this.phaseOffset);
}

class _SparkleData {
  final double x;
  final double y;
  final double phaseOffset;
  final int colorIndex;

  const _SparkleData(this.x, this.y, this.phaseOffset, this.colorIndex);
}

class _CrystallinePainter extends CustomPainter {
  final double t;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Color palette
  static const Color _amethyst = Color(0xFF9966CC);
  static const Color _amethystDeep = Color(0xFF5A3D7A);
  static const Color _amethystLight = Color(0xFFBB99DD);
  static const Color _crystal = Color(0xFFE8E8F0);
  static const Color _rose = Color(0xFFD4A0B0);
  static const Color _aqua = Color(0xFF88DDCC);
  static const Color _gold = Color(0xFFDDCC88);

  static const List<Color> _crystalColors = [_amethyst, _amethystLight, _crystal, _rose, _aqua];
  static const List<Color> _sparkleColors = [_crystal, _amethystLight, _aqua, _rose, _gold];

  // Pre-computed crystal formations
  static const List<_CrystalData> _bottomCrystals = [
    _CrystalData(0.50, 0.98, 1.0, -1.57, 0, 0.0),
    _CrystalData(0.44, 0.99, 0.75, -1.45, 1, 0.3),
    _CrystalData(0.56, 0.99, 0.80, -1.68, 2, 0.6),
    _CrystalData(0.38, 0.98, 0.55, -1.35, 0, 0.9),
    _CrystalData(0.62, 0.98, 0.60, -1.78, 1, 1.2),
    _CrystalData(0.12, 0.95, 0.70, -1.30, 0, 0.2),
    _CrystalData(0.08, 0.97, 0.50, -1.20, 2, 0.5),
    _CrystalData(0.16, 0.98, 0.45, -1.50, 1, 0.8),
    _CrystalData(0.88, 0.95, 0.65, -1.80, 0, 0.4),
    _CrystalData(0.92, 0.97, 0.48, -1.90, 1, 0.7),
    _CrystalData(0.84, 0.98, 0.52, -1.65, 2, 1.0),
  ];

  static const List<_CrystalData> _topCrystals = [
    _CrystalData(0.30, 0.02, 0.50, 1.57, 0, 0.1),
    _CrystalData(0.35, 0.01, 0.35, 1.45, 1, 0.4),
    _CrystalData(0.70, 0.02, 0.55, 1.60, 0, 0.7),
    _CrystalData(0.65, 0.01, 0.38, 1.70, 2, 1.0),
    _CrystalData(0.50, 0.03, 0.30, 1.55, 1, 1.3),
  ];

  static const List<_CrystalData> _sideCrystals = [
    _CrystalData(0.02, 0.35, 0.45, 0.3, 0, 0.2),
    _CrystalData(0.01, 0.50, 0.35, 0.4, 1, 0.6),
    _CrystalData(0.03, 0.65, 0.40, 0.25, 2, 1.0),
    _CrystalData(0.98, 0.40, 0.42, 2.85, 0, 0.3),
    _CrystalData(0.99, 0.55, 0.38, 2.75, 1, 0.8),
    _CrystalData(0.97, 0.70, 0.45, 2.90, 2, 1.2),
  ];

  // Pre-computed sparkles and particles
  static final List<_SparkleData> _sparkles = List.generate(35, (i) {
    final rng = math.Random(i * 777);
    return _SparkleData(rng.nextDouble(), rng.nextDouble(), rng.nextDouble() * 6.28, i % 5);
  });

  static final List<_SparkleData> _particles = List.generate(20, (i) {
    final rng = math.Random(i * 333);
    return _SparkleData(rng.nextDouble(), rng.nextDouble(), rng.nextDouble() * 6.28, i % 5);
  });

  // Reusable paint objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _crystalPath = Path();
  final Path _highlightPath = Path();

  _CrystallinePainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  double get _phase => 2 * math.pi * t;
  double _wave(double speed, [double offset = 0]) => math.sin(_phase * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintAmbientGlow(canvas, size);
    _paintCrystalFormations(canvas, size);
    _paintPrismaticRays(canvas, size);
    _paintFloatingParticles(canvas, size);
    _paintSparkles(canvas, size);
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgGradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.35),
      size.longestSide * 0.85,
      const [
        Color(0xFF1A1428),
        Color(0xFF100C18),
        Color(0xFF080510),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = bgGradient;
    canvas.drawRect(rect, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintAmbientGlow(Canvas canvas, Size size) {
    final pulse = _norm(0.5) * 0.3 + 0.7;

    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 80 * intensity);
    _fillPaint.color = _amethyst.withOpacity(0.08 * pulse * intensity);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.shortestSide * 0.35,
      _fillPaint,
    );

    _fillPaint.color = _amethystLight.withOpacity(0.06 * pulse * intensity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.88),
        width: size.width * 0.7,
        height: size.height * 0.25,
      ),
      _fillPaint,
    );

    _fillPaint.color = _aqua.withOpacity(0.03 * pulse * intensity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.08),
        width: size.width * 0.5,
        height: size.height * 0.15,
      ),
      _fillPaint,
    );

    _fillPaint.maskFilter = null;
  }

  void _paintCrystalFormations(Canvas canvas, Size size) {
    // Background layer
    for (final c in _sideCrystals) {
      final shimmer = _norm(0.3, c.phaseOffset) * 0.2 + 0.8;
      _drawCrystal(
        canvas,
        Offset(c.x * size.width, c.y * size.height),
        c.height * 55 * intensity * shimmer,
        c.angle,
        _crystalColors[c.colorIndex].withOpacity(0.15 * intensity * shimmer),
        isBackground: true,
      );
    }

    // Top crystals
    for (final c in _topCrystals) {
      final shimmer = _norm(0.4, c.phaseOffset) * 0.15 + 0.85;
      _drawCrystal(
        canvas,
        Offset(c.x * size.width, c.y * size.height),
        c.height * 80 * intensity * shimmer,
        c.angle,
        _crystalColors[c.colorIndex].withOpacity(0.25 * intensity * shimmer),
        isBackground: false,
      );
    }

    // Main bottom crystals
    for (final c in _bottomCrystals) {
      final shimmer = _norm(0.5, c.phaseOffset) * 0.15 + 0.85;
      final grow = _norm(0.2, c.phaseOffset) * 0.05 + 0.95;
      _drawCrystal(
        canvas,
        Offset(c.x * size.width, c.y * size.height),
        c.height * 110 * intensity * shimmer * grow,
        c.angle,
        _crystalColors[c.colorIndex].withOpacity(0.35 * intensity * shimmer),
        isBackground: false,
      );
    }
  }

  void _drawCrystal(Canvas canvas, Offset base, double height, double angle, Color color,
      {required bool isBackground}) {
    if (height < 5) return;

    final width = height * 0.22;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle + math.pi / 2);

    _crystalPath.reset();
    _crystalPath.moveTo(0, 0);
    _crystalPath.lineTo(-width, height * 0.12);
    _crystalPath.lineTo(-width * 0.75, height * 0.75);
    _crystalPath.lineTo(0, height);
    _crystalPath.lineTo(width * 0.75, height * 0.75);
    _crystalPath.lineTo(width, height * 0.12);
    _crystalPath.close();

    final gradient = ui.Gradient.linear(
      Offset(-width, 0),
      Offset(width, 0),
      [
        color.withOpacity(color.opacity * 0.6),
        color,
        color.withOpacity(color.opacity * 0.7),
      ],
      const [0.0, 0.4, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawPath(_crystalPath, _fillPaint);
    _fillPaint.shader = null;

    _strokePaint.strokeWidth = (isBackground ? 0.8 : 1.2) * intensity;
    _strokePaint.color = _crystal.withOpacity(color.opacity * 0.4);
    canvas.drawPath(_crystalPath, _strokePaint);

    if (!isBackground) {
      _highlightPath.reset();
      _highlightPath.moveTo(-width * 0.4, height * 0.15);
      _highlightPath.lineTo(-width * 0.55, height * 0.45);
      _highlightPath.lineTo(-width * 0.25, height * 0.70);
      _highlightPath.lineTo(0, height * 0.35);
      _highlightPath.close();

      _fillPaint.color = Colors.white.withOpacity(color.opacity * 0.15);
      canvas.drawPath(_highlightPath, _fillPaint);

      _strokePaint.strokeWidth = 0.8 * intensity;
      _strokePaint.color = _crystal.withOpacity(color.opacity * 0.2);
      canvas.drawLine(Offset(0, height * 0.08), Offset(0, height * 0.92), _strokePaint);

      _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * intensity);
      _fillPaint.color = Colors.white.withOpacity(color.opacity * 0.3);
      canvas.drawCircle(Offset(0, height * 0.95), 3 * intensity, _fillPaint);
      _fillPaint.maskFilter = null;
    }

    canvas.restore();
  }

  void _paintPrismaticRays(Canvas canvas, Size size) {
    final sources = [
      Offset(size.width * 0.5, size.height * 0.45),
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.75, size.height * 0.50),
    ];

    final rayColors = [_rose, _aqua, _gold, _amethystLight];

    for (int s = 0; s < sources.length; s++) {
      final source = sources[s];
      final basePulse = _norm(0.4, s * 1.2) * 0.4 + 0.6;

      for (int r = 0; r < 4; r++) {
        final rayAngle = t * math.pi * 0.3 + s * 2.1 + r * 0.8;
        final rayLength = (60 + r * 25) * intensity * basePulse;
        const spreadAngle = 0.06;

        final endCenter = source +
            Offset(
              math.cos(rayAngle) * rayLength,
              math.sin(rayAngle) * rayLength,
            );

        final gradient = ui.Gradient.linear(
          source,
          endCenter,
          [
            rayColors[r].withOpacity(0.12 * basePulse * intensity),
            rayColors[r].withOpacity(0.0),
          ],
        );

        final rayPath = Path()
          ..moveTo(source.dx, source.dy)
          ..lineTo(
            source.dx + math.cos(rayAngle - spreadAngle) * rayLength,
            source.dy + math.sin(rayAngle - spreadAngle) * rayLength,
          )
          ..lineTo(
            source.dx + math.cos(rayAngle + spreadAngle) * rayLength,
            source.dy + math.sin(rayAngle + spreadAngle) * rayLength,
          )
          ..close();

        _fillPaint.shader = gradient;
        canvas.drawPath(rayPath, _fillPaint);
      }
    }
    _fillPaint.shader = null;
  }

  void _paintFloatingParticles(Canvas canvas, Size size) {
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * intensity);

    for (final p in _particles) {
      final floatX = p.x * size.width + math.sin(_phase * 0.3 + p.phaseOffset) * 25 * intensity;
      final floatY = p.y * size.height + math.cos(_phase * 0.25 + p.phaseOffset) * 20 * intensity;

      final twinkle = _norm(0.8, p.phaseOffset) * 0.5 + 0.5;
      final particleSize = (2.5 + twinkle * 2) * intensity;

      _fillPaint.color = _crystalColors[p.colorIndex].withOpacity(0.35 * twinkle * intensity);
      canvas.drawCircle(Offset(floatX, floatY), particleSize, _fillPaint);
    }

    _fillPaint.maskFilter = null;
  }

  void _paintSparkles(Canvas canvas, Size size) {
    for (final s in _sparkles) {
      final twinkle = _norm(1.5, s.phaseOffset);

      if (twinkle > 0.55) {
        final x = s.x * size.width;
        final y = s.y * size.height;
        final sparkleIntensity = (twinkle - 0.55) * 2.2;
        final sparkleSize = (1.5 + sparkleIntensity * 3) * intensity;
        final opacity = sparkleIntensity * 0.9 * intensity;

        _strokePaint.strokeWidth = 1.0 * intensity;
        _strokePaint.color = _sparkleColors[s.colorIndex].withOpacity(opacity);

        canvas.drawLine(Offset(x - sparkleSize, y), Offset(x + sparkleSize, y), _strokePaint);
        canvas.drawLine(Offset(x, y - sparkleSize), Offset(x, y + sparkleSize), _strokePaint);

        if (sparkleIntensity > 0.6) {
          final diagSize = sparkleSize * 0.6;
          _strokePaint.color = _sparkleColors[s.colorIndex].withOpacity(opacity * 0.5);
          canvas.drawLine(Offset(x - diagSize, y - diagSize), Offset(x + diagSize, y + diagSize), _strokePaint);
          canvas.drawLine(Offset(x + diagSize, y - diagSize), Offset(x - diagSize, y + diagSize), _strokePaint);
        }

        _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * intensity);
        _fillPaint.color = Colors.white.withOpacity(opacity * 0.7);
        canvas.drawCircle(Offset(x, y), sparkleSize * 0.25, _fillPaint);
        _fillPaint.maskFilter = null;
      }
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.75;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        const Color(0xFF0D0A14).withOpacity(0.35 * intensity),
        const Color(0xFF0D0A14).withOpacity(0.75 * intensity),
      ],
      const [0.45, 0.78, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _CrystallinePainter oldDelegate) {
    return animationEnabled;
  }
}
