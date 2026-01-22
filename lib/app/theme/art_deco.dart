import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// ART DECO / GATSBY THEME BUILDER
// ============================================================================

AppTheme buildArtDecoTheme() {
  // Using Poiret One for that authentic Art Deco feel
  final baseTextTheme = GoogleFonts.poiretOneTextTheme();
  // Josefin Sans for body text - elegant and readable
  final bodyTextTheme = GoogleFonts.josefinSansTextTheme();

  return AppTheme(
    type: ThemeType.artDeco,
    isDark: true,

    // Primary colors - champagne gold
    primaryColor: const Color(0xFFD4AF37), // Champagne gold
    primaryVariant: const Color(0xFFB8962E), // Deeper gold
    onPrimary: const Color(0xFF0A0A0F), // Near black

    // Secondary colors - jade/teal accent
    accentColor: const Color(0xFF008080), // Teal/jade
    onAccent: const Color(0xFFF5F0E1), // Cream white

    // Background colors - rich black with subtle warmth
    background: const Color(0xFF0A0A0F), // Deep black with hint of blue
    surface: const Color(0xFF141418), // Slightly lighter black
    surfaceVariant: const Color(0xFF1E1E24), // Dark charcoal

    // Text colors - cream and gold tones
    textPrimary: const Color(0xFFF5F0E1), // Warm cream
    textSecondary: const Color(0xFFD4AF37), // Gold for accents
    textDisabled: const Color(0xFF5A5A60), // Muted gray

    // UI colors
    divider: const Color(0xFF2A2A32),
    toolbarColor: const Color(0xFF141418),
    error: const Color(0xFFCF6679), // Muted rose error
    success: const Color(0xFF4A9B7F), // Art deco green
    warning: const Color(0xFFD4AF37), // Gold warning

    // Grid colors
    gridLine: const Color(0xFF2A2A32),
    gridBackground: const Color(0xFF141418),

    // Canvas colors
    canvasBackground: const Color(0xFF0A0A0F),
    selectionOutline: const Color(0xFFD4AF37),
    selectionFill: const Color(0x30D4AF37),

    // Icon colors
    activeIcon: const Color(0xFFD4AF37),
    inactiveIcon: const Color(0xFF8A8A90),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFF5F0E1),
        fontWeight: FontWeight.w400,
        letterSpacing: 4,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFF5F0E1),
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFF5F0E1),
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFF5F0E1),
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF5F0E1),
        fontWeight: FontWeight.w300,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB0AAA0),
        fontWeight: FontWeight.w300,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFD4AF37),
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// ART DECO ANIMATED BACKGROUND
// ============================================================================

class ArtDecoBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const ArtDecoBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Slow animation for rotating geometric patterns
    final slowController = useAnimationController(
      duration: const Duration(seconds: 30),
    );

    // Medium speed for pulsing elements
    final mediumController = useAnimationController(
      duration: const Duration(seconds: 12),
    );

    // Fast animation for sparkles and particles
    final fastController = useAnimationController(
      duration: const Duration(seconds: 6),
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
        painter: _ArtDecoPainter(
          slowAnimation: slowAnim,
          mediumAnimation: mediumAnim,
          fastAnimation: fastAnim,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          backgroundColor: theme.background,
          intensity: intensity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ArtDecoPainter extends CustomPainter {
  final double slowAnimation;
  final double mediumAnimation;
  final double fastAnimation;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final double intensity;

  // Art Deco color palette
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _champagne = Color(0xFFF7E7CE);
  static const Color _teal = Color(0xFF008080);
  static const Color _black = Color(0xFF0A0A0F);
  static const Color _cream = Color(0xFFF5F0E1);
  static const Color _bronze = Color(0xFFCD7F32);
  static const Color _silver = Color(0xFFC0C0C0);

  final math.Random _rng = math.Random(1920); // Seed: The roaring 20s!

  _ArtDecoPainter({
    required this.slowAnimation,
    required this.mediumAnimation,
    required this.fastAnimation,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _rng = math.Random(1920);

    // === LAYER 1: Deep gradient background ===
    _paintBackground(canvas, size);

    // === LAYER 2: Radiating sunburst pattern ===
    _paintSunburst(canvas, size);

    // === LAYER 3: Geometric border frames ===
    _paintBorderFrames(canvas, size);

    // === LAYER 4: Chevron patterns ===
    _paintChevrons(canvas, size);

    // === LAYER 5: Fan/shell motifs ===
    _paintFanMotifs(canvas, size);

    // === LAYER 6: Rotating geometric medallions ===
    _paintMedallions(canvas, size);

    // === LAYER 7: Zigzag/lightning bolt accents ===
    _paintZigzags(canvas, size);

    // === LAYER 8: Floating geometric shapes ===
    _paintFloatingShapes(canvas, size);

    // === LAYER 9: Sparkle/diamond particles ===
    _paintSparkles(canvas, size);

    // === LAYER 10: Light rays ===
    _paintLightRays(canvas, size);

    // === LAYER 11: Vignette ===
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Rich radial gradient emanating from center-top
    final center = Offset(size.width * 0.5, size.height * 0.2);

    final bgGradient = ui.Gradient.radial(
      center,
      size.longestSide * 0.9,
      [
        const Color(0xFF12121A), // Slightly lighter center
        const Color(0xFF0A0A0F), // Deep black
        const Color(0xFF080810), // Darkest edges
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = bgGradient,
    );

    // Subtle noise texture
    final noisePaint = Paint()..color = _cream.withOpacity(0.008 * intensity);
    for (int i = 0; i < (200 * intensity).round(); i++) {
      canvas.drawCircle(
        Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        _rng.nextDouble() * 1.0,
        noisePaint,
      );
    }
  }

  void _paintSunburst(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.15);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rayCount = 24;
    final maxLength = size.height * 1.2;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi + math.pi; // Lower half
      final pulse = math.sin(mediumAnimation * 2 * math.pi + i * 0.3) * 0.15 + 0.85;
      final length = maxLength * pulse;

      // Gradient opacity along ray
      final opacity = (0.04 * intensity * pulse).clamp(0.01, 0.08);

      paint
        ..strokeWidth = (2.0 + i % 3) * intensity
        ..color = _gold.withOpacity(opacity);

      final end = Offset(
        center.dx + math.cos(angle) * length,
        center.dy + math.sin(angle) * length,
      );

      canvas.drawLine(center, end, paint);
    }
  }

  void _paintBorderFrames(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * intensity;

    // Multiple nested rectangular frames with stepped corners
    final margins = [20.0, 40.0, 65.0];
    final opacities = [0.12, 0.08, 0.05];

    for (int f = 0; f < margins.length; f++) {
      final m = margins[f] * intensity;
      final opacity = opacities[f] * intensity;
      final pulse = math.sin(mediumAnimation * 2 * math.pi + f * 0.5) * 0.2 + 0.8;

      paint.color = _gold.withOpacity(opacity * pulse);

      // Art Deco stepped corner frame
      final path = _createSteppedFrame(size, m, 15 * intensity);
      canvas.drawPath(path, paint);
    }
  }

  Path _createSteppedFrame(Size size, double margin, double stepSize) {
    final path = Path();
    final m = margin;
    final s = stepSize;

    // Top-left corner with steps
    path.moveTo(m + s * 2, m);
    path.lineTo(size.width - m - s * 2, m);

    // Top-right corner
    path.lineTo(size.width - m - s * 2, m);
    path.lineTo(size.width - m - s, m + s);
    path.lineTo(size.width - m, m + s);
    path.lineTo(size.width - m, m + s * 2);

    // Right side
    path.lineTo(size.width - m, size.height - m - s * 2);

    // Bottom-right corner
    path.lineTo(size.width - m, size.height - m - s);
    path.lineTo(size.width - m - s, size.height - m - s);
    path.lineTo(size.width - m - s, size.height - m);
    path.lineTo(size.width - m - s * 2, size.height - m);

    // Bottom side
    path.lineTo(m + s * 2, size.height - m);

    // Bottom-left corner
    path.lineTo(m + s, size.height - m);
    path.lineTo(m + s, size.height - m - s);
    path.lineTo(m, size.height - m - s);
    path.lineTo(m, size.height - m - s * 2);

    // Left side
    path.lineTo(m, m + s * 2);

    // Top-left corner completion
    path.lineTo(m, m + s);
    path.lineTo(m + s, m + s);
    path.lineTo(m + s, m);
    path.lineTo(m + s * 2, m);

    path.close();
    return path;
  }

  void _paintChevrons(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * intensity
      ..strokeCap = StrokeCap.round;

    // Left side chevrons
    _drawChevronColumn(canvas, size, Offset(size.width * 0.08, size.height * 0.3), paint, true);

    // Right side chevrons
    _drawChevronColumn(canvas, size, Offset(size.width * 0.92, size.height * 0.3), paint, false);
  }

  void _drawChevronColumn(Canvas canvas, Size size, Offset start, Paint paint, bool pointRight) {
    final chevronCount = 8;
    final chevronHeight = 25.0 * intensity;
    final chevronWidth = 12.0 * intensity;
    final spacing = 35.0 * intensity;

    for (int i = 0; i < chevronCount; i++) {
      final y = start.dy + i * spacing;
      final animOffset = math.sin(mediumAnimation * 2 * math.pi + i * 0.4) * 0.3 + 0.7;
      final opacity = (0.1 * animOffset * intensity).clamp(0.02, 0.15);

      paint.color = i % 2 == 0 ? _gold.withOpacity(opacity) : _teal.withOpacity(opacity * 0.8);

      final direction = pointRight ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(start.dx, y)
        ..lineTo(start.dx + chevronWidth * direction, y + chevronHeight / 2)
        ..lineTo(start.dx, y + chevronHeight);

      canvas.drawPath(path, paint);
    }
  }

  void _paintFanMotifs(Canvas canvas, Size size) {
    final fans = [
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.85),
      Offset(size.width * 0.5, size.height * 0.92),
    ];

    for (int f = 0; f < fans.length; f++) {
      final center = fans[f];
      final radius = (50.0 + f * 10) * intensity;
      final rotation = slowAnimation * 0.1 * math.pi + f * 0.5;
      final pulse = math.sin(mediumAnimation * 2 * math.pi + f * 1.2) * 0.15 + 0.85;

      _drawFan(canvas, center, radius, rotation, pulse, f);
    }
  }

  void _drawFan(Canvas canvas, Offset center, double radius, double rotation, double pulse, int index) {
    final paint = Paint()..style = PaintingStyle.stroke;

    final segments = 7;
    final startAngle = -math.pi; // Start from bottom, fan upward
    final sweepAngle = math.pi; // Half circle

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Draw concentric arcs
    for (int ring = 1; ring <= 4; ring++) {
      final ringRadius = radius * (ring / 4) * pulse;
      final opacity = (0.08 - ring * 0.015) * intensity;

      paint
        ..strokeWidth = (2.0 - ring * 0.3) * intensity
        ..color = index % 2 == 0 ? _gold.withOpacity(opacity) : _teal.withOpacity(opacity);

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw radiating lines
    paint
      ..strokeWidth = 1.0 * intensity
      ..color = _gold.withOpacity(0.06 * intensity);

    for (int i = 0; i <= segments; i++) {
      final angle = startAngle + (i / segments) * sweepAngle;
      final end = Offset(
        math.cos(angle) * radius * pulse,
        math.sin(angle) * radius * pulse,
      );
      canvas.drawLine(Offset.zero, end, paint);
    }

    canvas.restore();
  }

  void _paintMedallions(Canvas canvas, Size size) {
    final medallions = [
      _MedallionDef(0.5, 0.5, 80, 8), // Center large
      _MedallionDef(0.2, 0.25, 45, 6), // Top-left
      _MedallionDef(0.8, 0.25, 45, 6), // Top-right
      _MedallionDef(0.15, 0.6, 35, 5), // Mid-left
      _MedallionDef(0.85, 0.6, 35, 5), // Mid-right
    ];

    for (int m = 0; m < medallions.length; m++) {
      final def = medallions[m];
      final center = Offset(size.width * def.x, size.height * def.y);
      final radius = def.radius * intensity;
      final rotation = slowAnimation * 2 * math.pi * (m % 2 == 0 ? 0.5 : -0.3);
      final pulse = math.sin(mediumAnimation * 2 * math.pi + m * 0.8) * 0.1 + 0.9;

      _drawMedallion(canvas, center, radius, def.sides, rotation, pulse, m);
    }
  }

  void _drawMedallion(
      Canvas canvas, Offset center, double radius, int sides, double rotation, double pulse, int index) {
    final paint = Paint()..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Outer polygon
    paint
      ..strokeWidth = 2.0 * intensity
      ..color = _gold.withOpacity(0.1 * pulse * intensity);
    _drawPolygon(canvas, Offset.zero, radius * pulse, sides, paint);

    // Inner polygon (rotated)
    paint
      ..strokeWidth = 1.5 * intensity
      ..color = _teal.withOpacity(0.08 * pulse * intensity);
    canvas.rotate(math.pi / sides);
    _drawPolygon(canvas, Offset.zero, radius * 0.7 * pulse, sides, paint);

    // Innermost polygon
    paint
      ..strokeWidth = 1.0 * intensity
      ..color = _gold.withOpacity(0.06 * pulse * intensity);
    canvas.rotate(math.pi / sides);
    _drawPolygon(canvas, Offset.zero, radius * 0.4 * pulse, sides, paint);

    // Center circle
    paint
      ..strokeWidth = 1.5 * intensity
      ..color = _gold.withOpacity(0.12 * pulse * intensity);
    canvas.drawCircle(Offset.zero, radius * 0.15 * pulse, paint);

    // Radiating lines from center to vertices
    paint
      ..strokeWidth = 0.8 * intensity
      ..color = _gold.withOpacity(0.05 * intensity);
    for (int i = 0; i < sides; i++) {
      final angle = (i / sides) * 2 * math.pi;
      final end = Offset(
        math.cos(angle) * radius * 0.9 * pulse,
        math.sin(angle) * radius * 0.9 * pulse,
      );
      canvas.drawLine(Offset.zero, end, paint);
    }

    canvas.restore();
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i <= sides; i++) {
      final angle = (i / sides) * 2 * math.pi - math.pi / 2;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintZigzags(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * intensity
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Horizontal zigzag bands
    final bands = [
      size.height * 0.12,
      size.height * 0.88,
    ];

    for (int b = 0; b < bands.length; b++) {
      final y = bands[b];
      final amplitude = 8.0 * intensity;
      final wavelength = 20.0 * intensity;
      final offset = fastAnimation * wavelength * 2;

      final pulse = math.sin(mediumAnimation * 2 * math.pi + b) * 0.2 + 0.8;
      paint.color = _gold.withOpacity(0.08 * pulse * intensity);

      final path = Path();
      var started = false;

      for (double x = -wavelength + (offset % (wavelength * 2)); x < size.width + wavelength; x += wavelength) {
        final zigY = y + (((x / wavelength).floor() % 2 == 0) ? -amplitude : amplitude);
        if (!started) {
          path.moveTo(x, zigY);
          started = true;
        } else {
          path.lineTo(x, zigY);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  void _paintFloatingShapes(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final shapeCount = (20 * intensity).round();

    for (int i = 0; i < shapeCount; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;

      // Gentle floating motion
      final floatX = baseX + math.sin(slowAnimation * 2 * math.pi + i * 0.7) * 15 * intensity;
      final floatY = baseY + math.cos(slowAnimation * 2 * math.pi + i * 0.5) * 10 * intensity;

      final shapeSize = (8 + _rng.nextDouble() * 12) * intensity;
      final rotation = slowAnimation * math.pi * (i % 2 == 0 ? 0.5 : -0.5) + i * 0.3;
      final opacity = (math.sin(mediumAnimation * 2 * math.pi + i * 0.4) * 0.3 + 0.7) * 0.06 * intensity;

      paint
        ..strokeWidth = 1.0 * intensity
        ..color = (i % 3 == 0 ? _gold : (i % 3 == 1 ? _teal : _silver)).withOpacity(opacity);

      canvas.save();
      canvas.translate(floatX, floatY);
      canvas.rotate(rotation);

      switch (i % 4) {
        case 0: // Diamond
          _drawDiamond(canvas, Offset.zero, shapeSize, paint);
          break;
        case 1: // Triangle
          _drawPolygon(canvas, Offset.zero, shapeSize, 3, paint);
          break;
        case 2: // Hexagon
          _drawPolygon(canvas, Offset.zero, shapeSize, 6, paint);
          break;
        case 3: // Circle
          canvas.drawCircle(Offset.zero, shapeSize * 0.6, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.6, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.6, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintSparkles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final sparkleCount = (40 * intensity).round();

    for (int i = 0; i < sparkleCount; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;

      // Twinkling effect
      final twinklePhase = fastAnimation * 2 * math.pi + i * 0.5;
      final twinkle = (math.sin(twinklePhase) + 1) / 2;

      if (twinkle > 0.6) {
        final sparkleSize = (1.5 + twinkle * 2) * intensity;
        final opacity = twinkle * 0.4 * intensity;

        // Draw 4-pointed star sparkle
        paint.color = _champagne.withOpacity(opacity);

        final path = Path();
        // Vertical line
        path.moveTo(x, y - sparkleSize);
        path.lineTo(x, y + sparkleSize);
        // Horizontal line
        path.moveTo(x - sparkleSize, y);
        path.lineTo(x + sparkleSize, y);

        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 * intensity
            ..color = _champagne.withOpacity(opacity),
        );

        // Center glow
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(x, y), sparkleSize * 0.3, paint);
        paint.maskFilter = null;
      }
    }
  }

  void _paintLightRays(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.0);
    final rayCount = 8;

    for (int i = 0; i < rayCount; i++) {
      final baseAngle = (i / rayCount) * math.pi + math.pi * 0.1;
      final wobble = math.sin(slowAnimation * 2 * math.pi + i * 0.8) * 0.05;
      final angle = baseAngle + wobble;

      final pulse = math.sin(mediumAnimation * 2 * math.pi + i * 0.6) * 0.3 + 0.7;
      final opacity = 0.015 * pulse * intensity;

      final rayLength = size.height * 1.2;
      final rayWidth = 60.0 * intensity;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle - 0.05) * rayLength,
        center.dy + math.sin(angle - 0.05) * rayLength,
      );
      path.lineTo(
        center.dx + math.cos(angle + 0.05) * rayLength,
        center.dy + math.sin(angle + 0.05) * rayLength,
      );
      path.close();

      final gradient = ui.Gradient.linear(
        center,
        Offset(
          center.dx + math.cos(angle) * rayLength,
          center.dy + math.sin(angle) * rayLength,
        ),
        [
          _gold.withOpacity(opacity * 2),
          _gold.withOpacity(0),
        ],
      );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = gradient,
      );
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
        Colors.black.withOpacity(0.2 * intensity),
        Colors.black.withOpacity(0.5 * intensity),
      ],
      [0.5, 0.8, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtDecoPainter oldDelegate) {
    return oldDelegate.slowAnimation != slowAnimation ||
        oldDelegate.mediumAnimation != mediumAnimation ||
        oldDelegate.fastAnimation != fastAnimation ||
        oldDelegate.intensity != intensity;
  }

  set _rng(math.Random value) {} // Dart workaround for resetting
}

// ============================================================================
// HELPER CLASS
// ============================================================================

class _MedallionDef {
  final double x;
  final double y;
  final double radius;
  final int sides;

  const _MedallionDef(this.x, this.y, this.radius, this.sides);
}
