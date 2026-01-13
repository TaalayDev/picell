import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// GOTHIC THEME BUILDER
// ============================================================================

AppTheme buildGothicTheme() {
  final displayTextTheme = GoogleFonts.cinzelTextTheme();
  final bodyTextTheme = GoogleFonts.crimsonTextTextTheme();

  return AppTheme(
    type: ThemeType.gothic,
    isDark: true,

    // Primary colors - deep burgundy and blood red
    primaryColor: const Color(0xFF8B0000), // Dark red
    primaryVariant: const Color(0xFF5C0000), // Deeper burgundy
    onPrimary: const Color(0xFFF5F0E6),

    // Accent colors - antique gold and candlelight
    accentColor: const Color(0xFFCFB53B), // Old gold
    onAccent: const Color(0xFF1A1A1A),

    // Background colors - midnight and shadow
    background: const Color(0xFF0A0A0C), // Near black with blue tint
    surface: const Color(0xFF141418), // Dark surface
    surfaceVariant: const Color(0xFF1E1E24), // Lighter variant

    // Text colors - aged parchment and silver
    textPrimary: const Color(0xFFE8E4DC), // Antique white
    textSecondary: const Color(0xFFB8B4AC), // Aged silver
    textDisabled: const Color(0xFF5A5854), // Faded stone

    // UI colors
    divider: const Color(0xFF2A2A30),
    toolbarColor: const Color(0xFF141418),
    error: const Color(0xFFB22222), // Firebrick
    success: const Color(0xFF4A6741), // Dark forest
    warning: const Color(0xFFB8860B), // Dark goldenrod

    // Grid colors
    gridLine: const Color(0xFF1E1E24),
    gridBackground: const Color(0xFF141418),

    // Canvas colors
    canvasBackground: const Color(0xFF0A0A0C),
    selectionOutline: const Color(0xFF8B0000),
    selectionFill: const Color(0x308B0000),

    // Icon colors
    activeIcon: const Color(0xFFCFB53B),
    inactiveIcon: const Color(0xFFB8B4AC),

    // Typography - elegant serif fonts
    textTheme: displayTextTheme.copyWith(
      displayLarge: displayTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFE8E4DC),
        fontWeight: FontWeight.w400,
        letterSpacing: 4,
      ),
      displayMedium: displayTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFE8E4DC),
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
      ),
      titleLarge: displayTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE8E4DC),
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
      titleMedium: displayTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE8E4DC),
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE8E4DC),
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB8B4AC),
        fontSize: 14,
        height: 1.5,
      ),
      labelLarge: displayTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFCFB53B),
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// GOTHIC ANIMATED BACKGROUND
// ============================================================================

class GothicBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const GothicBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Slow ambient animation
    final slowController = useAnimationController(
      duration: const Duration(seconds: 40),
    );

    // Medium for mist and candles
    final mediumController = useAnimationController(
      duration: const Duration(seconds: 15),
    );

    // Fast for particles and ravens
    final fastController = useAnimationController(
      duration: const Duration(seconds: 8),
    );

    useEffect(() {
      if (enableAnimation) {
        slowController.repeat();
        mediumController.repeat();
        fastController.repeat();
      } else {
        slowController.stop();
        mediumController.stop();
        fastController.stop();
      }
      return null;
    }, [enableAnimation]);

    final slowAnim = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(slowController),
    );
    final mediumAnim = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(mediumController),
    );
    final fastAnim = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(fastController),
    );

    return RepaintBoundary(
      child: CustomPaint(
        painter: _GothicPainter(
          slowAnimation: slowAnim,
          mediumAnimation: mediumAnim,
          fastAnimation: fastAnim,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GothicPainter extends CustomPainter {
  final double slowAnimation;
  final double mediumAnimation;
  final double fastAnimation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Gothic color palette
  static const Color _midnight = Color(0xFF0A0A0C);
  static const Color _shadow = Color(0xFF141418);
  static const Color _stone = Color(0xFF2A2A30);
  static const Color _bloodRed = Color(0xFF8B0000);
  static const Color _burgundy = Color(0xFF5C0000);
  static const Color _gold = Color(0xFFCFB53B);
  static const Color _candleLight = Color(0xFFFFD700);
  static const Color _candleGlow = Color(0xFFFF8C00);
  static const Color _moonlight = Color(0xFFE8E4DC);
  static const Color _mist = Color(0xFF9090A0);
  static const Color _ravenBlack = Color(0xFF0D0D0F);
  static const Color _stainedGlass = Color(0xFF4A0080);

  math.Random _rng = math.Random(666);

  _GothicPainter({
    required this.slowAnimation,
    required this.mediumAnimation,
    required this.fastAnimation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _rng = math.Random(666);

    // === LAYER 1: Deep midnight background ===
    _paintBackground(canvas, size);

    // === LAYER 2: Moon and moonlight ===
    _paintMoon(canvas, size);

    // === LAYER 3: Distant cathedral silhouette ===
    _paintCathedralSilhouette(canvas, size);

    // === LAYER 4: Gothic arches ===
    _paintGothicArches(canvas, size);

    // === LAYER 5: Stained glass windows ===
    _paintStainedGlass(canvas, size);

    // === LAYER 6: Stone columns ===
    _paintColumns(canvas, size);

    // === LAYER 7: Iron gates and fencing ===
    _paintIronwork(canvas, size);

    // === LAYER 8: Gravestones and crosses ===
    _paintGraveyard(canvas, size);

    // === LAYER 9: Candelabras and flames ===
    _paintCandles(canvas, size);

    // === LAYER 10: Ravens ===
    _paintRavens(canvas, size);

    // === LAYER 11: Bats ===
    _paintBats(canvas, size);

    // === LAYER 12: Mist and fog ===
    _paintMist(canvas, size);

    // === LAYER 13: Floating particles (dust, ash) ===
    _paintParticles(canvas, size);

    // === LAYER 14: Rose petals ===
    _paintRosePetals(canvas, size);

    // === LAYER 15: Cobwebs ===
    _paintCobwebs(canvas, size);

    // === LAYER 16: Light rays through windows ===
    _paintLightRays(canvas, size);

    // === LAYER 17: Vignette ===
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Deep gradient with subtle blue undertones
    final bgGradient = ui.Gradient.radial(
      Offset(size.width * 0.7, size.height * 0.15),
      size.longestSide * 1.2,
      [
        const Color(0xFF12121A), // Slight blue tint near moon
        const Color(0xFF0A0A0C), // Deep midnight
        const Color(0xFF060608), // Absolute dark
      ],
      [0.0, 0.4, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = bgGradient,
    );

    // Stone texture overlay
    final stonePaint = Paint()..color = _stone.withOpacity(0.015 * intensity);
    for (int i = 0; i < (400 * intensity).round(); i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), _rng.nextDouble() * 2, stonePaint);
    }
  }

  void _paintMoon(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.78, size.height * 0.12);
    final moonRadius = 45.0 * intensity;

    // Outer glow
    final glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Large atmospheric glow
    glowPaint.color = _moonlight.withOpacity(0.03 * intensity);
    canvas.drawCircle(moonCenter, moonRadius * 4, glowPaint);

    // Medium glow
    glowPaint.color = _moonlight.withOpacity(0.05 * intensity);
    canvas.drawCircle(moonCenter, moonRadius * 2.5, glowPaint);

    // Inner glow
    glowPaint.color = _moonlight.withOpacity(0.08 * intensity);
    canvas.drawCircle(moonCenter, moonRadius * 1.5, glowPaint);

    // Moon body with slight animation (breathing)
    final breathe = math.sin(slowAnimation * 2 * math.pi) * 0.02 + 1.0;
    final moonGradient = ui.Gradient.radial(
      moonCenter - Offset(moonRadius * 0.3, moonRadius * 0.3),
      moonRadius * breathe,
      [
        _moonlight.withOpacity(0.15 * intensity),
        _moonlight.withOpacity(0.08 * intensity),
        _moonlight.withOpacity(0.03 * intensity),
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      moonCenter,
      moonRadius * breathe,
      Paint()..shader = moonGradient,
    );

    // Moon craters (subtle)
    final craterPaint = Paint()
      ..color = _shadow.withOpacity(0.1 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(moonCenter + Offset(moonRadius * 0.2, -moonRadius * 0.1), moonRadius * 0.15, craterPaint);
    canvas.drawCircle(moonCenter + Offset(-moonRadius * 0.3, moonRadius * 0.2), moonRadius * 0.12, craterPaint);
    canvas.drawCircle(moonCenter + Offset(moonRadius * 0.1, moonRadius * 0.35), moonRadius * 0.08, craterPaint);
  }

  void _paintCathedralSilhouette(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _ravenBlack.withOpacity(0.7 * intensity);

    // Main cathedral body - distant
    final cathedral = Path()
      ..moveTo(size.width * 0.3, size.height)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      // Left tower
      ..lineTo(size.width * 0.32, size.height * 0.5)
      ..lineTo(size.width * 0.32, size.height * 0.25)
      ..lineTo(size.width * 0.34, size.height * 0.15) // Spire
      ..lineTo(size.width * 0.36, size.height * 0.25)
      ..lineTo(size.width * 0.36, size.height * 0.5)
      // Main roof with rose window
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.35)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      // Right tower
      ..lineTo(size.width * 0.54, size.height * 0.5)
      ..lineTo(size.width * 0.54, size.height * 0.28)
      ..lineTo(size.width * 0.56, size.height * 0.18) // Spire
      ..lineTo(size.width * 0.58, size.height * 0.28)
      ..lineTo(size.width * 0.58, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height)
      ..close();

    canvas.drawPath(cathedral, paint);

    // Flying buttresses hint
    paint.color = _ravenBlack.withOpacity(0.5 * intensity);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.55),
      Paint()
        ..color = _ravenBlack.withOpacity(0.4 * intensity)
        ..strokeWidth = 3 * intensity,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.55),
      Paint()
        ..color = _ravenBlack.withOpacity(0.4 * intensity)
        ..strokeWidth = 3 * intensity,
    );
  }

  void _paintGothicArches(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * intensity;

    // Foreground gothic arches (window frames)
    final arches = [
      Rect.fromLTWH(size.width * 0.02, size.height * 0.1, size.width * 0.12, size.height * 0.5),
      Rect.fromLTWH(size.width * 0.86, size.height * 0.15, size.width * 0.12, size.height * 0.45),
    ];

    for (int i = 0; i < arches.length; i++) {
      final rect = arches[i];
      final opacity = 0.08 + math.sin(slowAnimation * 2 * math.pi + i) * 0.02;
      paint.color = _stone.withOpacity(opacity * intensity);

      // Pointed arch
      final archPath = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + rect.height * 0.4)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.center.dx,
          rect.top,
        )
        ..quadraticBezierTo(
          rect.right,
          rect.top,
          rect.right,
          rect.top + rect.height * 0.4,
        )
        ..lineTo(rect.right, rect.bottom);

      canvas.drawPath(archPath, paint);

      // Inner arch tracery
      paint.strokeWidth = 1.5 * intensity;
      final innerRect = rect.deflate(rect.width * 0.15);
      final innerPath = Path()
        ..moveTo(innerRect.left, innerRect.bottom)
        ..lineTo(innerRect.left, innerRect.top + innerRect.height * 0.4)
        ..quadraticBezierTo(
          innerRect.left,
          innerRect.top,
          innerRect.center.dx,
          innerRect.top,
        )
        ..quadraticBezierTo(
          innerRect.right,
          innerRect.top,
          innerRect.right,
          innerRect.top + innerRect.height * 0.4,
        )
        ..lineTo(innerRect.right, innerRect.bottom);

      canvas.drawPath(innerPath, paint);

      // Vertical mullion
      canvas.drawLine(
        Offset(rect.center.dx, rect.top + rect.height * 0.1),
        Offset(rect.center.dx, rect.bottom),
        paint,
      );
    }
  }

  void _paintStainedGlass(Canvas canvas, Size size) {
    // Rose window in cathedral silhouette
    final roseCenter = Offset(size.width * 0.45, size.height * 0.42);
    final roseRadius = 25.0 * intensity;

    final glowIntensity = math.sin(slowAnimation * 2 * math.pi) * 0.15 + 0.85;

    // Outer glow
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = _stainedGlass.withOpacity(0.08 * glowIntensity * intensity);
    canvas.drawCircle(roseCenter, roseRadius * 1.8, glowPaint);

    // Rose window segments
    final segmentPaint = Paint()..style = PaintingStyle.fill;

    final colors = [_bloodRed, _stainedGlass, const Color(0xFF1E3A5F), _burgundy];

    for (int i = 0; i < 8; i++) {
      final startAngle = i * math.pi / 4;
      final color = colors[i % colors.length];

      segmentPaint.color = color.withOpacity(0.15 * glowIntensity * intensity);
      canvas.drawArc(
        Rect.fromCircle(center: roseCenter, radius: roseRadius),
        startAngle,
        math.pi / 4,
        true,
        segmentPaint,
      );
    }

    // Rose window frame
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * intensity
      ..color = _stone.withOpacity(0.1 * intensity);

    canvas.drawCircle(roseCenter, roseRadius, framePaint);
    canvas.drawCircle(roseCenter, roseRadius * 0.6, framePaint);

    // Radial spokes
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        roseCenter,
        roseCenter + Offset(math.cos(angle) * roseRadius, math.sin(angle) * roseRadius),
        framePaint,
      );
    }
  }

  void _paintColumns(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Foreground columns
    final columns = [
      Offset(size.width * 0.0, size.height),
      Offset(size.width * 0.15, size.height),
      Offset(size.width * 0.85, size.height),
      Offset(size.width * 1.0, size.height),
    ];

    for (int i = 0; i < columns.length; i++) {
      final base = columns[i];
      final columnHeight = size.height * (0.7 + _rng.nextDouble() * 0.2);
      final columnWidth = 20.0 * intensity;

      final opacity = 0.06 + math.sin(slowAnimation * math.pi + i * 0.8) * 0.02;

      // Column shadow
      paint.strokeWidth = columnWidth + 4;
      paint.color = Colors.black.withOpacity(0.15 * intensity);
      canvas.drawLine(
        base + const Offset(3, 0),
        Offset(base.dx + 3, base.dy - columnHeight),
        paint,
      );

      // Main column
      paint.strokeWidth = columnWidth;
      paint.color = _stone.withOpacity(opacity * intensity);
      canvas.drawLine(
        base,
        Offset(base.dx, base.dy - columnHeight),
        paint,
      );

      // Column highlight
      paint.strokeWidth = 3 * intensity;
      paint.color = _moonlight.withOpacity(opacity * 0.3 * intensity);
      canvas.drawLine(
        Offset(base.dx - columnWidth * 0.3, base.dy),
        Offset(base.dx - columnWidth * 0.3, base.dy - columnHeight),
        paint,
      );

      // Capital (top decoration)
      final capitalY = base.dy - columnHeight;
      paint.strokeWidth = 2 * intensity;
      paint.color = _stone.withOpacity(opacity * 1.2 * intensity);

      // Simple gothic capital
      canvas.drawLine(
        Offset(base.dx - columnWidth * 0.8, capitalY),
        Offset(base.dx + columnWidth * 0.8, capitalY),
        paint,
      );
      canvas.drawLine(
        Offset(base.dx - columnWidth * 0.6, capitalY - 5 * intensity),
        Offset(base.dx + columnWidth * 0.6, capitalY - 5 * intensity),
        paint,
      );
    }
  }

  void _paintIronwork(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Iron fence at bottom
    final fenceY = size.height * 0.92;
    final fenceHeight = size.height * 0.12;

    // Horizontal rails
    paint.strokeWidth = 3 * intensity;
    paint.color = _ravenBlack.withOpacity(0.15 * intensity);
    canvas.drawLine(
      Offset(0, fenceY),
      Offset(size.width, fenceY),
      paint,
    );
    canvas.drawLine(
      Offset(0, fenceY - fenceHeight * 0.3),
      Offset(size.width, fenceY - fenceHeight * 0.3),
      paint,
    );

    // Vertical bars with spear points
    paint.strokeWidth = 2 * intensity;
    final barSpacing = 25.0 * intensity;
    final barCount = (size.width / barSpacing).ceil();

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing;
      final barTop = fenceY - fenceHeight;

      // Main bar
      canvas.drawLine(
        Offset(x, fenceY + 10),
        Offset(x, barTop + 10 * intensity),
        paint,
      );

      // Spear point
      final spearPath = Path()
        ..moveTo(x - 4 * intensity, barTop + 10 * intensity)
        ..lineTo(x, barTop)
        ..lineTo(x + 4 * intensity, barTop + 10 * intensity);
      canvas.drawPath(spearPath, paint);
    }

    // Decorative scrollwork
    paint.strokeWidth = 1.5 * intensity;
    paint.color = _ravenBlack.withOpacity(0.1 * intensity);

    for (int i = 0; i < barCount - 1; i++) {
      final x = i * barSpacing + barSpacing / 2;
      final scrollY = fenceY - fenceHeight * 0.5;

      // Simple scroll
      final scrollPath = Path()
        ..moveTo(x - barSpacing * 0.3, scrollY)
        ..quadraticBezierTo(x, scrollY - 8 * intensity, x + barSpacing * 0.3, scrollY);
      canvas.drawPath(scrollPath, paint);
    }
  }

  void _paintGraveyard(Canvas canvas, Size size) {
    final gravestones = [
      Offset(size.width * 0.2, size.height * 0.88),
      Offset(size.width * 0.35, size.height * 0.9),
      Offset(size.width * 0.65, size.height * 0.89),
      Offset(size.width * 0.8, size.height * 0.87),
    ];

    for (int i = 0; i < gravestones.length; i++) {
      final base = gravestones[i];
      final stoneHeight = (30 + _rng.nextDouble() * 20) * intensity;
      final stoneWidth = (15 + _rng.nextDouble() * 10) * intensity;

      final opacity = 0.08 + math.sin(slowAnimation * math.pi + i * 1.2) * 0.02;
      final paint = Paint()..color = _stone.withOpacity(opacity * intensity);

      if (i % 2 == 0) {
        // Regular gravestone
        final stonePath = Path()
          ..moveTo(base.dx - stoneWidth / 2, base.dy)
          ..lineTo(base.dx - stoneWidth / 2, base.dy - stoneHeight * 0.7)
          ..quadraticBezierTo(
            base.dx - stoneWidth / 2,
            base.dy - stoneHeight,
            base.dx,
            base.dy - stoneHeight,
          )
          ..quadraticBezierTo(
            base.dx + stoneWidth / 2,
            base.dy - stoneHeight,
            base.dx + stoneWidth / 2,
            base.dy - stoneHeight * 0.7,
          )
          ..lineTo(base.dx + stoneWidth / 2, base.dy)
          ..close();

        canvas.drawPath(stonePath, paint);
      } else {
        // Cross gravestone
        final crossWidth = stoneWidth * 0.3;
        final crossPath = Path()
          // Vertical beam
          ..addRect(Rect.fromCenter(
            center: Offset(base.dx, base.dy - stoneHeight * 0.5),
            width: crossWidth,
            height: stoneHeight,
          ))
          // Horizontal beam
          ..addRect(Rect.fromCenter(
            center: Offset(base.dx, base.dy - stoneHeight * 0.7),
            width: stoneWidth * 0.8,
            height: crossWidth,
          ));

        canvas.drawPath(crossPath, paint);
      }
    }
  }

  void _paintCandles(Canvas canvas, Size size) {
    final candles = [
      Offset(size.width * 0.08, size.height * 0.55),
      Offset(size.width * 0.12, size.height * 0.58),
      Offset(size.width * 0.88, size.height * 0.52),
      Offset(size.width * 0.92, size.height * 0.56),
      Offset(size.width * 0.5, size.height * 0.7),
    ];

    for (int i = 0; i < candles.length; i++) {
      final base = candles[i];
      final candleHeight = (25 + i * 5) * intensity;
      final candleWidth = 4.0 * intensity;

      // Flame flicker
      final flicker = math.sin(fastAnimation * 8 * math.pi + i * 2.3) * 0.3 + 0.7;
      final sway = math.sin(fastAnimation * 6 * math.pi + i * 1.7) * 3 * intensity;

      // Candle body
      final candlePaint = Paint()..color = const Color(0xFFF5F0E0).withOpacity(0.12 * intensity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            base.dx - candleWidth / 2,
            base.dy - candleHeight,
            candleWidth,
            candleHeight,
          ),
          Radius.circular(candleWidth / 4),
        ),
        candlePaint,
      );

      // Flame glow (large)
      final flameTop = base.dy - candleHeight - 15 * intensity;
      final glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

      glowPaint.color = _candleGlow.withOpacity(0.06 * flicker * intensity);
      canvas.drawCircle(
        Offset(base.dx + sway, flameTop + 5 * intensity),
        30 * intensity,
        glowPaint,
      );

      // Flame glow (medium)
      glowPaint.color = _candleLight.withOpacity(0.1 * flicker * intensity);
      canvas.drawCircle(
        Offset(base.dx + sway, flameTop + 3 * intensity),
        15 * intensity,
        glowPaint,
      );

      // Flame body
      final flamePath = Path()
        ..moveTo(base.dx - 3 * intensity + sway * 0.5, base.dy - candleHeight)
        ..quadraticBezierTo(
          base.dx - 5 * intensity + sway,
          flameTop + 8 * intensity,
          base.dx + sway,
          flameTop,
        )
        ..quadraticBezierTo(
          base.dx + 5 * intensity + sway,
          flameTop + 8 * intensity,
          base.dx + 3 * intensity + sway * 0.5,
          base.dy - candleHeight,
        )
        ..close();

      // Flame gradient
      final flameGradient = ui.Gradient.linear(
        Offset(base.dx, base.dy - candleHeight),
        Offset(base.dx + sway, flameTop),
        [
          _candleGlow.withOpacity(0.4 * flicker * intensity),
          _candleLight.withOpacity(0.6 * flicker * intensity),
          Colors.white.withOpacity(0.3 * flicker * intensity),
        ],
        [0.0, 0.5, 1.0],
      );

      canvas.drawPath(
        flamePath,
        Paint()..shader = flameGradient,
      );
    }
  }

  void _paintRavens(Canvas canvas, Size size) {
    final ravens = [
      _RavenDef(0.25, 0.2, 1.0, 0.0),
      _RavenDef(0.7, 0.15, -0.8, 0.3),
      _RavenDef(0.15, 0.35, 0.6, 0.5),
    ];

    for (int i = 0; i < ravens.length; i++) {
      final raven = ravens[i];
      final baseX = size.width * raven.x;
      final baseY = size.height * raven.y;

      // Subtle gliding motion
      final glideX = math.sin(slowAnimation * 2 * math.pi + raven.phase) * 30 * intensity * raven.direction;
      final glideY = math.cos(slowAnimation * math.pi + raven.phase) * 15 * intensity;

      final x = baseX + glideX;
      final y = baseY + glideY;

      // Wing flap
      final wingFlap = math.sin(mediumAnimation * 4 * math.pi + raven.phase) * 0.3 + 0.7;
      final ravenSize = 20.0 * intensity;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _ravenBlack.withOpacity(0.25 * intensity);

      // Raven body
      final bodyPath = Path()
        ..moveTo(x - ravenSize, y)
        ..quadraticBezierTo(x - ravenSize * 0.3, y - ravenSize * 0.3, x + ravenSize * 0.5, y)
        ..quadraticBezierTo(x - ravenSize * 0.3, y + ravenSize * 0.2, x - ravenSize, y);
      canvas.drawPath(bodyPath, paint);

      // Wings
      final leftWingY = y - ravenSize * 0.5 * wingFlap;
      final rightWingY = y - ravenSize * 0.4 * wingFlap;

      final leftWing = Path()
        ..moveTo(x - ravenSize * 0.5, y)
        ..quadraticBezierTo(x - ravenSize * 1.2, leftWingY, x - ravenSize * 1.5, y + ravenSize * 0.2)
        ..lineTo(x - ravenSize * 0.3, y);
      canvas.drawPath(leftWing, paint);

      final rightWing = Path()
        ..moveTo(x + ravenSize * 0.2, y)
        ..quadraticBezierTo(x + ravenSize * 0.8, rightWingY, x + ravenSize, y + ravenSize * 0.3)
        ..lineTo(x + ravenSize * 0.1, y);
      canvas.drawPath(rightWing, paint);

      // Head
      canvas.drawCircle(Offset(x + ravenSize * 0.4, y - ravenSize * 0.1), ravenSize * 0.2, paint);

      // Beak
      canvas.drawLine(
        Offset(x + ravenSize * 0.55, y - ravenSize * 0.1),
        Offset(x + ravenSize * 0.75, y),
        Paint()
          ..color = _ravenBlack.withOpacity(0.2 * intensity)
          ..strokeWidth = 2 * intensity,
      );
    }
  }

  void _paintBats(Canvas canvas, Size size) {
    final batCount = (8 * intensity).round();

    for (int i = 0; i < batCount; i++) {
      // Erratic flight pattern
      final baseX = (_rng.nextDouble() * 0.6 + 0.2) * size.width;
      final baseY = (_rng.nextDouble() * 0.3 + 0.1) * size.height;

      final flyX = math.sin(fastAnimation * 3 * math.pi + i * 1.5) * 40 * intensity;
      final flyY = math.cos(fastAnimation * 2 * math.pi + i * 1.8) * 25 * intensity;

      final x = baseX + flyX;
      final y = baseY + flyY;

      final wingFlap = math.sin(fastAnimation * 12 * math.pi + i * 2.5);
      final batSize = (6 + _rng.nextDouble() * 4) * intensity;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _ravenBlack.withOpacity(0.2 * intensity);

      // Simple bat silhouette
      final batPath = Path()
        // Body
        ..addOval(Rect.fromCenter(center: Offset(x, y), width: batSize, height: batSize * 0.6))
        // Left wing
        ..moveTo(x - batSize * 0.3, y)
        ..quadraticBezierTo(
          x - batSize * 1.5,
          y - batSize * wingFlap,
          x - batSize * 2,
          y + batSize * 0.3,
        )
        ..lineTo(x - batSize * 0.3, y)
        // Right wing
        ..moveTo(x + batSize * 0.3, y)
        ..quadraticBezierTo(
          x + batSize * 1.5,
          y - batSize * wingFlap,
          x + batSize * 2,
          y + batSize * 0.3,
        )
        ..lineTo(x + batSize * 0.3, y);

      canvas.drawPath(batPath, paint);
    }
  }

  void _paintMist(Canvas canvas, Size size) {
    final mistPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    // Ground mist layers
    for (int layer = 0; layer < 4; layer++) {
      final layerY = size.height * (0.75 + layer * 0.08);
      final drift = math.sin(mediumAnimation * 2 * math.pi + layer * 0.8) * 50 * intensity;
      final opacity = (0.04 - layer * 0.008) * intensity;

      for (int i = 0; i < 5; i++) {
        final x = (i * size.width / 4) + drift + _rng.nextDouble() * 50;
        final mistWidth = (150 + _rng.nextDouble() * 100) * intensity;
        final mistHeight = (40 + _rng.nextDouble() * 30) * intensity;

        mistPaint.color = _mist.withOpacity(opacity);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, layerY),
            width: mistWidth,
            height: mistHeight,
          ),
          mistPaint,
        );
      }
    }

    // Rising wisps
    for (int i = 0; i < 6; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final progress = (mediumAnimation + i * 0.15) % 1.0;
      final y = size.height * (0.9 - progress * 0.4);
      final x = baseX + math.sin(progress * math.pi * 2) * 30 * intensity;
      final opacity = math.sin(progress * math.pi) * 0.03 * intensity;

      if (opacity > 0.005) {
        mistPaint.color = _mist.withOpacity(opacity);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 80 * intensity,
            height: 30 * intensity,
          ),
          mistPaint,
        );
      }
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final particleCount = (50 * intensity).round();

    for (int i = 0; i < particleCount; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;

      // Gentle floating
      final floatX = baseX + math.sin(mediumAnimation * 2 * math.pi + i * 0.4) * 20 * intensity;
      final floatY = baseY + math.cos(mediumAnimation * 1.5 * math.pi + i * 0.6) * 15 * intensity;

      final twinkle = math.sin(fastAnimation * 4 * math.pi + i * 0.7) * 0.5 + 0.5;

      if (twinkle > 0.3) {
        // Dust motes
        if (i % 3 == 0) {
          paint.color = _moonlight.withOpacity(0.15 * twinkle * intensity);
          canvas.drawCircle(Offset(floatX, floatY), 1.5 * intensity, paint);
        }
        // Ash particles
        else if (i % 3 == 1) {
          paint.color = _stone.withOpacity(0.1 * twinkle * intensity);
          canvas.drawCircle(Offset(floatX, floatY), 2 * intensity, paint);
        }
        // Embers (near candles)
        else if (floatY > size.height * 0.5) {
          paint.color = _candleGlow.withOpacity(0.2 * twinkle * intensity);
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawCircle(Offset(floatX, floatY), 1.5 * intensity, paint);
          paint.maskFilter = null;
        }
      }
    }
  }

  void _paintRosePetals(Canvas canvas, Size size) {
    final petalCount = (12 * intensity).round();

    for (int i = 0; i < petalCount; i++) {
      // Falling motion
      final progress = (slowAnimation + i * 0.08) % 1.0;
      final startX = _rng.nextDouble() * size.width;

      final x = startX + math.sin(progress * math.pi * 3 + i) * 60 * intensity;
      final y = progress * size.height * 1.2 - size.height * 0.1;

      final rotation = progress * math.pi * 2 + i;
      final opacity = math.sin(progress * math.pi) * 0.15 * intensity;

      if (opacity > 0.02 && y > 0 && y < size.height) {
        final petalSize = (4 + _rng.nextDouble() * 3) * intensity;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);

        // Petal shape
        final petalPath = Path()
          ..moveTo(0, -petalSize)
          ..quadraticBezierTo(petalSize, -petalSize * 0.5, petalSize * 0.8, petalSize * 0.3)
          ..quadraticBezierTo(0, petalSize, -petalSize * 0.8, petalSize * 0.3)
          ..quadraticBezierTo(-petalSize, -petalSize * 0.5, 0, -petalSize);

        canvas.drawPath(
          petalPath,
          Paint()..color = _bloodRed.withOpacity(opacity),
        );

        canvas.restore();
      }
    }
  }

  void _paintCobwebs(Canvas canvas, Size size) {
    final webLocations = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height * 0.3),
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * intensity;

    for (int w = 0; w < webLocations.length; w++) {
      final origin = webLocations[w];
      final webSize = 80.0 * intensity;
      final opacity = 0.04 + math.sin(slowAnimation * math.pi + w) * 0.01;

      paint.color = _moonlight.withOpacity(opacity * intensity);

      // Radial threads
      final threadCount = 8;
      for (int i = 0; i < threadCount; i++) {
        final angle = (w == 1 ? math.pi : 0) + i * math.pi / (threadCount * 2);
        final endX = origin.dx + math.cos(angle) * webSize;
        final endY = origin.dy + math.sin(angle) * webSize;

        canvas.drawLine(origin, Offset(endX, endY), paint);
      }

      // Spiral threads
      for (int ring = 1; ring <= 4; ring++) {
        final ringRadius = webSize * ring / 5;
        final startAngle = w == 1 ? math.pi : 0;
        final sweepAngle = math.pi / 2;

        canvas.drawArc(
          Rect.fromCircle(center: origin, radius: ringRadius),
          startAngle.toDouble(),
          sweepAngle,
          false,
          paint,
        );
      }
    }
  }

  void _paintLightRays(Canvas canvas, Size size) {
    // Moonlight rays through windows
    final rayPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    final rayOpacity = 0.02 + math.sin(slowAnimation * math.pi) * 0.01;

    // Ray from moon area
    final moonRayPath = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.85, 0)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..close();

    rayPaint.color = _moonlight.withOpacity(rayOpacity * intensity);
    canvas.drawPath(moonRayPath, rayPaint);

    // Candle light rays (warm)
    final candleRayOpacity = 0.015 * intensity;
    rayPaint.color = _candleGlow.withOpacity(candleRayOpacity);

    // Left candle area
    final leftRay = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftRay, rayPaint);

    // Right candle area
    final rightRay = Path()
      ..moveTo(size.width, size.height * 0.48)
      ..lineTo(size.width * 0.8, size.height * 0.48)
      ..lineTo(size.width * 0.7, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(rightRay, rayPaint);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.9;

    // Heavy vignette for gothic mood
    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.3 * intensity),
        Colors.black.withOpacity(0.6 * intensity),
      ],
      [0.3, 0.7, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette,
    );

    // Additional corner darkness
    final cornerPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
      ..color = Colors.black.withOpacity(0.4 * intensity);

    canvas.drawCircle(Offset.zero, size.width * 0.3, cornerPaint);
    canvas.drawCircle(Offset(size.width, 0), size.width * 0.3, cornerPaint);
    canvas.drawCircle(Offset(0, size.height), size.width * 0.3, cornerPaint);
    canvas.drawCircle(Offset(size.width, size.height), size.width * 0.3, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _GothicPainter oldDelegate) {
    return oldDelegate.slowAnimation != slowAnimation ||
        oldDelegate.mediumAnimation != mediumAnimation ||
        oldDelegate.fastAnimation != fastAnimation ||
        oldDelegate.intensity != intensity;
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class _RavenDef {
  final double x;
  final double y;
  final double direction;
  final double phase;

  const _RavenDef(this.x, this.y, this.direction, this.phase);
}
