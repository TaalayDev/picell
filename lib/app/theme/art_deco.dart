import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// ART DECO THEME BUILDER
// ============================================================================

AppTheme buildArtDecoTheme() {
  final baseTextTheme = GoogleFonts.poiretOneTextTheme();
  final bodyTextTheme = GoogleFonts.josefinSansTextTheme();

  return AppTheme(
    type: ThemeType.artDeco,
    isDark: true,

    // Primary colors - rich gold
    primaryColor: const Color(0xFFD4AF37), // Classic gold
    primaryVariant: const Color(0xFFB8960C), // Deeper gold
    onPrimary: const Color(0xFF1A1A1A),

    // Secondary colors - teal accent
    accentColor: const Color(0xFF008080), // Art deco teal
    onAccent: const Color(0xFFF5F5F5),

    // Background colors - deep black with warmth
    background: const Color(0xFF0D0D0D), // Rich black
    surface: const Color(0xFF1A1A1A), // Elevated black
    surfaceVariant: const Color(0xFF262626), // Card surfaces

    // Text colors - cream and gold
    textPrimary: const Color(0xFFF5F0E1), // Warm cream
    textSecondary: const Color(0xFFD4AF37), // Gold accents
    textDisabled: const Color(0xFF666666), // Muted gray

    // UI colors
    divider: const Color(0xFF333333),
    toolbarColor: const Color(0xFF1A1A1A),
    error: const Color(0xFFCF6679),
    success: const Color(0xFF4CAF50),
    warning: const Color(0xFFFFB300),

    // Grid colors
    gridLine: const Color(0xFF333333),
    gridBackground: const Color(0xFF1A1A1A),

    // Canvas colors
    canvasBackground: const Color(0xFF0D0D0D),
    selectionOutline: const Color(0xFFD4AF37),
    selectionFill: const Color(0x30D4AF37),

    // Icon colors
    activeIcon: const Color(0xFFD4AF37),
    inactiveIcon: const Color(0xFFF5F0E1),

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
        color: const Color(0xFFD4AF37),
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
      ),
      titleMedium: bodyTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFF5F0E1),
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF5F0E1),
        letterSpacing: 0.5,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFBDB9AC),
        letterSpacing: 0.5,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFD4AF37),
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
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

    final decoState = useMemoized(() => _ArtDecoState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ArtDecoPainter(
          repaint: controller,
          state: decoState,
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

class _ArtDecoState {
  double time = 0;
  double lastFrameTimestamp = 0;
}

class _ArtDecoPainter extends CustomPainter {
  final _ArtDecoState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Art Deco color palette
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _brightGold = Color(0xFFFFD700);
  static const Color _darkGold = Color(0xFF8B7500);
  static const Color _teal = Color(0xFF008080);
  static const Color _cream = Color(0xFFF5F0E1);
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _charcoal = Color(0xFF1A1A1A);
  static const Color _copper = Color(0xFFB87333);

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _path = Path();

  _ArtDecoPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  double get _slowTime => state.time / 20.0;
  double get _mediumTime => state.time / 10.0;

  double _wave(double speed, [double offset = 0]) => math.sin(state.time * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Layer 1: Deep black background with subtle gradient
    _paintBackground(canvas, size);

    // Layer 2: Geometric sunburst pattern
    _paintSunburst(canvas, size);

    // Layer 3: Chevron patterns
    _paintChevrons(canvas, size);

    // Layer 4: Fan motifs in corners
    _paintFanMotifs(canvas, size);

    // Layer 5: Vertical pillar lines
    _paintPillars(canvas, size);

    // Layer 6: Zigzag borders
    _paintZigzagBorders(canvas, size);

    // Layer 7: Central medallion
    _paintMedallion(canvas, size);

    // Layer 8: Floating geometric particles
    _paintGeometricParticles(canvas, size);

    // Layer 9: Shimmer overlay
    _paintShimmer(canvas, size);

    // Layer 10: Vignette
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final gradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.3),
      size.longestSide * 0.8,
      [
        const Color(0xFF1A1A1A),
        const Color(0xFF0D0D0D),
        const Color(0xFF050505),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;

    // Subtle noise texture
    final rng = math.Random(42);
    _fillPaint.color = _cream.withOpacity(0.008 * intensity);
    for (int i = 0; i < (200 * intensity).round(); i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2,
        _fillPaint,
      );
    }
  }

  void _paintSunburst(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.35);
    final maxRadius = size.longestSide * 0.6;
    final rayCount = 36;

    final pulsePhase = _norm(0.1) * 0.15 + 0.85;

    for (int i = 0; i < rayCount; i++) {
      final angle = i * math.pi * 2 / rayCount - math.pi / 2;
      final nextAngle = (i + 1) * math.pi * 2 / rayCount - math.pi / 2;

      // Alternating ray widths
      final isWide = i % 2 == 0;
      final rayOpacity = isWide ? 0.06 : 0.03;
      final shimmer = _norm(0.15, i * 0.3) * 0.02;

      _path.reset();
      _path.moveTo(center.dx, center.dy);
      _path.lineTo(
        center.dx + math.cos(angle) * maxRadius * pulsePhase,
        center.dy + math.sin(angle) * maxRadius * pulsePhase,
      );
      _path.lineTo(
        center.dx + math.cos(nextAngle) * maxRadius * pulsePhase,
        center.dy + math.sin(nextAngle) * maxRadius * pulsePhase,
      );
      _path.close();

      _fillPaint.color = _gold.withOpacity((rayOpacity + shimmer) * intensity);
      canvas.drawPath(_path, _fillPaint);
    }

    // Central glow
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * intensity);
    _fillPaint.color = _gold.withOpacity(0.08 * pulsePhase * intensity);
    canvas.drawCircle(center, 80 * intensity, _fillPaint);
    _fillPaint.maskFilter = null;
  }

  void _paintChevrons(Canvas canvas, Size size) {
    final chevronCount = 8;
    final chevronHeight = size.height / chevronCount;
    final peakOffset = size.width * 0.12;

    _strokePaint.strokeWidth = 1.5 * intensity;
    _strokePaint.strokeCap = StrokeCap.round;

    for (int i = 0; i < chevronCount; i++) {
      final y = i * chevronHeight + chevronHeight * 0.5;
      final shimmer = _norm(0.2, i * 0.5) * 0.3 + 0.2;

      // Left chevron
      _strokePaint.color = _gold.withOpacity(shimmer * 0.4 * intensity);

      _path.reset();
      _path.moveTo(0, y);
      _path.lineTo(peakOffset, y - chevronHeight * 0.3);
      _path.lineTo(peakOffset * 2, y);
      canvas.drawPath(_path, _strokePaint);

      _path.reset();
      _path.moveTo(0, y + 8 * intensity);
      _path.lineTo(peakOffset, y - chevronHeight * 0.3 + 8 * intensity);
      _path.lineTo(peakOffset * 2, y + 8 * intensity);
      canvas.drawPath(_path, _strokePaint);

      // Right chevron (mirrored)
      _path.reset();
      _path.moveTo(size.width, y);
      _path.lineTo(size.width - peakOffset, y - chevronHeight * 0.3);
      _path.lineTo(size.width - peakOffset * 2, y);
      canvas.drawPath(_path, _strokePaint);

      _path.reset();
      _path.moveTo(size.width, y + 8 * intensity);
      _path.lineTo(size.width - peakOffset, y - chevronHeight * 0.3 + 8 * intensity);
      _path.lineTo(size.width - peakOffset * 2, y + 8 * intensity);
      canvas.drawPath(_path, _strokePaint);
    }
  }

  void _paintFanMotifs(Canvas canvas, Size size) {
    final fanPositions = [
      Offset(0, 0), // Top-left
      Offset(size.width, 0), // Top-right
      Offset(0, size.height), // Bottom-left
      Offset(size.width, size.height), // Bottom-right
    ];

    final startAngles = [0.0, math.pi * 0.5, -math.pi * 0.5, math.pi];

    for (int f = 0; f < fanPositions.length; f++) {
      final origin = fanPositions[f];
      final startAngle = startAngles[f];
      final fanRadius = size.shortestSide * 0.25 * intensity;
      final segments = 7;

      for (int i = 0; i < segments; i++) {
        final angle1 = startAngle + i * (math.pi * 0.5 / segments);
        final angle2 = startAngle + (i + 1) * (math.pi * 0.5 / segments);

        final shimmer = _norm(0.18, f * 1.5 + i * 0.4) * 0.2 + 0.1;
        final isAccent = i % 2 == 0;

        _path.reset();
        _path.moveTo(origin.dx, origin.dy);
        _path.lineTo(
          origin.dx + math.cos(angle1) * fanRadius,
          origin.dy + math.sin(angle1) * fanRadius,
        );
        _path.arcTo(
          Rect.fromCircle(center: origin, radius: fanRadius),
          angle1,
          (angle2 - angle1),
          false,
        );
        _path.close();

        _fillPaint.color = (isAccent ? _gold : _teal).withOpacity(shimmer * intensity);
        canvas.drawPath(_path, _fillPaint);

        // Fan segment outline
        _strokePaint.color = _gold.withOpacity(0.3 * intensity);
        _strokePaint.strokeWidth = 1 * intensity;
        canvas.drawPath(_path, _strokePaint);
      }

      // Concentric arcs
      for (int r = 1; r <= 3; r++) {
        final arcRadius = fanRadius * r / 4;
        _strokePaint.color = _gold.withOpacity(0.2 * intensity);
        _strokePaint.strokeWidth = 1 * intensity;
        canvas.drawArc(
          Rect.fromCircle(center: origin, radius: arcRadius),
          startAngle,
          math.pi * 0.5,
          false,
          _strokePaint,
        );
      }
    }
  }

  void _paintPillars(Canvas canvas, Size size) {
    final pillarCount = 5;
    final pillarWidth = 3.0 * intensity;
    final spacing = size.width / (pillarCount + 1);

    for (int i = 1; i <= pillarCount; i++) {
      final x = spacing * i;
      final shimmer = _norm(0.12, i * 0.8) * 0.3 + 0.15;

      // Main pillar line
      _strokePaint.color = _gold.withOpacity(shimmer * intensity);
      _strokePaint.strokeWidth = pillarWidth;
      canvas.drawLine(
        Offset(x, size.height * 0.15),
        Offset(x, size.height * 0.85),
        _strokePaint,
      );

      // Pillar decorations - top
      _paintPillarCap(canvas, Offset(x, size.height * 0.15), shimmer);

      // Pillar decorations - bottom
      _paintPillarCap(canvas, Offset(x, size.height * 0.85), shimmer);

      // Intermediate decorations
      for (int d = 1; d <= 3; d++) {
        final y = size.height * (0.15 + d * 0.175);
        _paintPillarDiamond(canvas, Offset(x, y), shimmer * 0.7);
      }
    }
  }

  void _paintPillarCap(Canvas canvas, Offset center, double opacity) {
    final capSize = 12.0 * intensity;

    _path.reset();
    _path.moveTo(center.dx, center.dy - capSize);
    _path.lineTo(center.dx + capSize, center.dy);
    _path.lineTo(center.dx, center.dy + capSize);
    _path.lineTo(center.dx - capSize, center.dy);
    _path.close();

    _fillPaint.color = _gold.withOpacity(opacity * 0.5 * intensity);
    canvas.drawPath(_path, _fillPaint);

    _strokePaint.color = _gold.withOpacity(opacity * intensity);
    _strokePaint.strokeWidth = 1.5 * intensity;
    canvas.drawPath(_path, _strokePaint);
  }

  void _paintPillarDiamond(Canvas canvas, Offset center, double opacity) {
    final size = 6.0 * intensity;

    _path.reset();
    _path.moveTo(center.dx, center.dy - size);
    _path.lineTo(center.dx + size * 0.6, center.dy);
    _path.lineTo(center.dx, center.dy + size);
    _path.lineTo(center.dx - size * 0.6, center.dy);
    _path.close();

    _fillPaint.color = _teal.withOpacity(opacity * intensity);
    canvas.drawPath(_path, _fillPaint);
  }

  void _paintZigzagBorders(Canvas canvas, Size size) {
    final zigzagHeight = 15.0 * intensity;
    final zigzagWidth = 20.0 * intensity;

    _strokePaint.strokeWidth = 2 * intensity;
    _strokePaint.strokeCap = StrokeCap.round;
    _strokePaint.strokeJoin = StrokeJoin.round;

    // Top border
    final topShimmer = _norm(0.15) * 0.3 + 0.3;
    _strokePaint.color = _gold.withOpacity(topShimmer * intensity);

    _path.reset();
    _path.moveTo(0, zigzagHeight);
    for (double x = 0; x < size.width; x += zigzagWidth) {
      _path.lineTo(x + zigzagWidth * 0.5, 0);
      _path.lineTo(x + zigzagWidth, zigzagHeight);
    }
    canvas.drawPath(_path, _strokePaint);

    // Bottom border
    final bottomShimmer = _norm(0.15, 2.0) * 0.3 + 0.3;
    _strokePaint.color = _gold.withOpacity(bottomShimmer * intensity);

    _path.reset();
    _path.moveTo(0, size.height - zigzagHeight);
    for (double x = 0; x < size.width; x += zigzagWidth) {
      _path.lineTo(x + zigzagWidth * 0.5, size.height);
      _path.lineTo(x + zigzagWidth, size.height - zigzagHeight);
    }
    canvas.drawPath(_path, _strokePaint);

    // Inner accent lines
    _strokePaint.strokeWidth = 1 * intensity;
    _strokePaint.color = _teal.withOpacity(0.25 * intensity);

    canvas.drawLine(
      Offset(0, zigzagHeight + 5 * intensity),
      Offset(size.width, zigzagHeight + 5 * intensity),
      _strokePaint,
    );
    canvas.drawLine(
      Offset(0, size.height - zigzagHeight - 5 * intensity),
      Offset(size.width, size.height - zigzagHeight - 5 * intensity),
      _strokePaint,
    );
  }

  void _paintMedallion(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.shortestSide * 0.12 * intensity;
    final rotation = _slowTime * math.pi * 2;
    final pulse = _norm(0.1) * 0.1 + 0.9;

    // Outer glow
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * intensity);
    _fillPaint.color = _gold.withOpacity(0.1 * pulse * intensity);
    canvas.drawCircle(center, radius * 1.5, _fillPaint);
    _fillPaint.maskFilter = null;

    // Octagonal frame
    final octagonRadius = radius * 1.2;
    _path.reset();
    for (int i = 0; i < 8; i++) {
      final angle = rotation * 0.1 + i * math.pi / 4 - math.pi / 8;
      final x = center.dx + math.cos(angle) * octagonRadius;
      final y = center.dy + math.sin(angle) * octagonRadius;
      if (i == 0) {
        _path.moveTo(x, y);
      } else {
        _path.lineTo(x, y);
      }
    }
    _path.close();

    _strokePaint.color = _gold.withOpacity(0.6 * pulse * intensity);
    _strokePaint.strokeWidth = 2.5 * intensity;
    canvas.drawPath(_path, _strokePaint);

    // Inner circles
    _strokePaint.strokeWidth = 1.5 * intensity;
    _strokePaint.color = _gold.withOpacity(0.4 * pulse * intensity);
    canvas.drawCircle(center, radius, _strokePaint);
    canvas.drawCircle(center, radius * 0.7, _strokePaint);

    // Radiating lines inside
    for (int i = 0; i < 12; i++) {
      final angle = rotation * 0.2 + i * math.pi / 6;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * radius * 0.3,
          center.dy + math.sin(angle) * radius * 0.3,
        ),
        Offset(
          center.dx + math.cos(angle) * radius * 0.65,
          center.dy + math.sin(angle) * radius * 0.65,
        ),
        _strokePaint,
      );
    }

    // Central diamond
    final diamondSize = radius * 0.25;
    _path.reset();
    _path.moveTo(center.dx, center.dy - diamondSize);
    _path.lineTo(center.dx + diamondSize, center.dy);
    _path.lineTo(center.dx, center.dy + diamondSize);
    _path.lineTo(center.dx - diamondSize, center.dy);
    _path.close();

    _fillPaint.color = _teal.withOpacity(0.6 * pulse * intensity);
    canvas.drawPath(_path, _fillPaint);

    _strokePaint.color = _gold.withOpacity(0.8 * pulse * intensity);
    _strokePaint.strokeWidth = 1.5 * intensity;
    canvas.drawPath(_path, _strokePaint);
  }

  void _paintGeometricParticles(Canvas canvas, Size size) {
    final particleCount = (25 * intensity).round();

    for (int i = 0; i < particleCount; i++) {
      final rng = math.Random(i * 17);
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;

      final floatX = baseX + _wave(0.08, i * 0.7) * 20 * intensity;
      final floatY = baseY + _wave(0.06, i * 0.9 + 1.5) * 15 * intensity;

      final twinkle = _norm(0.2, i * 0.5);
      if (twinkle > 0.4) {
        final opacity = (twinkle - 0.4) * 0.5 * intensity;
        final particleSize = (3 + rng.nextDouble() * 4) * intensity;

        switch (i % 4) {
          case 0: // Diamond
            _path.reset();
            _path.moveTo(floatX, floatY - particleSize);
            _path.lineTo(floatX + particleSize * 0.6, floatY);
            _path.lineTo(floatX, floatY + particleSize);
            _path.lineTo(floatX - particleSize * 0.6, floatY);
            _path.close();
            _fillPaint.color = _gold.withOpacity(opacity);
            canvas.drawPath(_path, _fillPaint);
            break;

          case 1: // Triangle
            _path.reset();
            _path.moveTo(floatX, floatY - particleSize);
            _path.lineTo(floatX + particleSize * 0.866, floatY + particleSize * 0.5);
            _path.lineTo(floatX - particleSize * 0.866, floatY + particleSize * 0.5);
            _path.close();
            _fillPaint.color = _teal.withOpacity(opacity * 0.8);
            canvas.drawPath(_path, _fillPaint);
            break;

          case 2: // Circle
            _fillPaint.color = _gold.withOpacity(opacity * 0.6);
            canvas.drawCircle(Offset(floatX, floatY), particleSize * 0.5, _fillPaint);
            break;

          case 3: // Square
            canvas.save();
            canvas.translate(floatX, floatY);
            canvas.rotate(_slowTime * math.pi);
            _fillPaint.color = _copper.withOpacity(opacity * 0.7);
            canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: particleSize, height: particleSize),
              _fillPaint,
            );
            canvas.restore();
            break;
        }
      }
    }
  }

  void _paintShimmer(Canvas canvas, Size size) {
    // Diagonal shimmer lines
    final shimmerProgress = (state.time * 0.05) % 1.0;
    final shimmerX = -size.width * 0.5 + shimmerProgress * size.width * 2;

    final shimmerGradient = ui.Gradient.linear(
      Offset(shimmerX, 0),
      Offset(shimmerX + size.width * 0.3, size.height),
      [
        Colors.transparent,
        _gold.withOpacity(0.03 * intensity),
        _gold.withOpacity(0.06 * intensity),
        _gold.withOpacity(0.03 * intensity),
        Colors.transparent,
      ],
      const [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    _fillPaint.shader = shimmerGradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.75;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.3 * intensity),
        Colors.black.withOpacity(0.7 * intensity),
      ],
      const [0.4, 0.75, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _ArtDecoPainter oldDelegate) => animationEnabled;
}
