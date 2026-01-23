import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// POINTILLISM THEME BUILDER
// ============================================================================

AppTheme buildPointillismTheme() {
  final baseTextTheme = GoogleFonts.playfairDisplayTextTheme();
  final bodyTextTheme = GoogleFonts.sourceSerif4TextTheme();

  return AppTheme(
    type: ThemeType.pointillism,
    isDark: false,

    // Primary colors - impressionist blue
    primaryColor: const Color(0xFF4A6FA5), // Seurat blue
    primaryVariant: const Color(0xFF2E4A7D), // Deeper blue
    onPrimary: Colors.white,

    // Secondary colors - complementary orange
    accentColor: const Color(0xFFE07B39), // Warm orange
    onAccent: Colors.white,

    // Background colors - warm canvas cream
    background: const Color(0xFFF5F0E6), // Canvas cream
    surface: const Color(0xFFFAF7F2), // Lighter cream
    surfaceVariant: const Color(0xFFEFEAE0), // Slightly darker

    // Text colors - rich darks
    textPrimary: const Color(0xFF2C2416), // Warm black
    textSecondary: const Color(0xFF5C5347), // Warm gray
    textDisabled: const Color(0xFF9C9488), // Muted

    // UI colors
    divider: const Color(0xFFD9D4C8),
    toolbarColor: const Color(0xFFFAF7F2),
    error: const Color(0xFFB84A4A),
    success: const Color(0xFF5A8F5A),
    warning: const Color(0xFFD4953A),

    // Grid colors
    gridLine: const Color(0xFFD9D4C8),
    gridBackground: const Color(0xFFFAF7F2),

    // Canvas colors
    canvasBackground: const Color(0xFFF5F0E6),
    selectionOutline: const Color(0xFF4A6FA5),
    selectionFill: const Color(0x304A6FA5),

    // Icon colors
    activeIcon: const Color(0xFF4A6FA5),
    inactiveIcon: const Color(0xFF5C5347),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF2C2416),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF2C2416),
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF2C2416),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: bodyTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF2C2416),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF2C2416),
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF5C5347),
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFF4A6FA5),
        fontWeight: FontWeight.w600,
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// POINTILLISM ANIMATED BACKGROUND
// ============================================================================

class PointillismBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const PointillismBackground({
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

    final pointState = useMemoized(() => _PointillismState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _PointillismPainter(
          repaint: controller,
          state: pointState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PointillismState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_DotCluster>? clusters;
  List<_FloatingDot>? floatingDots;
}

class _DotCluster {
  final double centerX;
  final double centerY;
  final double radius;
  final List<_Dot> dots;
  final int colorScheme;
  final double phase;

  const _DotCluster({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.dots,
    required this.colorScheme,
    required this.phase,
  });
}

class _Dot {
  final double relX;
  final double relY;
  final double size;
  final int colorIndex;
  final double phase;

  const _Dot({
    required this.relX,
    required this.relY,
    required this.size,
    required this.colorIndex,
    required this.phase,
  });
}

class _FloatingDot {
  double x;
  double y;
  double size;
  int colorIndex;
  double speedX;
  double speedY;
  double phase;

  _FloatingDot({
    required this.x,
    required this.y,
    required this.size,
    required this.colorIndex,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });
}

class _PointillismPainter extends CustomPainter {
  final _PointillismState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Seurat/Signac inspired palette - pure spectral colors
  static const List<Color> _blueFamily = [
    Color(0xFF4A6FA5), // Ultramarine
    Color(0xFF6B8FC5), // Light blue
    Color(0xFF3A5A8A), // Deep blue
    Color(0xFF7BA3D0), // Sky blue
    Color(0xFF5578A8), // Medium blue
  ];

  static const List<Color> _orangeFamily = [
    Color(0xFFE07B39), // Orange
    Color(0xFFD4953A), // Golden orange
    Color(0xFFE89B5A), // Light orange
    Color(0xFFC86830), // Deep orange
    Color(0xFFF0A860), // Pale orange
  ];

  static const List<Color> _greenFamily = [
    Color(0xFF6A9B5A), // Grass green
    Color(0xFF8AB87A), // Light green
    Color(0xFF4A7A4A), // Deep green
    Color(0xFF9AC88A), // Pale green
    Color(0xFF5A8A5A), // Medium green
  ];

  static const List<Color> _yellowFamily = [
    Color(0xFFE8C84A), // Cadmium yellow
    Color(0xFFF0D86A), // Light yellow
    Color(0xFFD0B030), // Deep yellow
    Color(0xFFF8E88A), // Pale yellow
    Color(0xFFE0D050), // Medium yellow
  ];

  static const List<Color> _violetFamily = [
    Color(0xFF8A6AA0), // Violet
    Color(0xFFA888B8), // Light violet
    Color(0xFF6A4A80), // Deep violet
    Color(0xFFB898C8), // Pale violet
    Color(0xFF7A5A90), // Medium violet
  ];

  static const List<Color> _redFamily = [
    Color(0xFFC85050), // Vermillion
    Color(0xFFE87070), // Light red
    Color(0xFFA83030), // Deep red
    Color(0xFFF89090), // Pale red
    Color(0xFFD86060), // Medium red
  ];

  static const Color _canvasCream = Color(0xFFF5F0E6);

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  _PointillismPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  }) : super(repaint: repaint);

  double _wave(double speed, [double offset = 0]) => math.sin(state.time * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  List<Color> _getColorFamily(int scheme) {
    switch (scheme % 6) {
      case 0:
        return _blueFamily;
      case 1:
        return _orangeFamily;
      case 2:
        return _greenFamily;
      case 3:
        return _yellowFamily;
      case 4:
        return _violetFamily;
      case 5:
        return _redFamily;
      default:
        return _blueFamily;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialize dot structures
    state.clusters ??= _generateClusters(size);
    state.floatingDots ??= _generateFloatingDots(size);

    // Update floating dots
    _updateFloatingDots(size, dt);

    // Layer 1: Canvas background
    _paintCanvas(canvas, size);

    // Layer 2: Background dot texture (canvas grain)
    _paintCanvasGrain(canvas, size);

    // Layer 3: Sky region - blue/violet dots
    _paintSkyRegion(canvas, size);

    // Layer 4: Landscape forms - clustered dots
    _paintLandscapeClusters(canvas, size);

    // Layer 5: Water/reflection region
    _paintWaterRegion(canvas, size);

    // Layer 6: Foliage accents
    _paintFoliageAccents(canvas, size);

    // Layer 7: Light shimmer dots
    _paintShimmerDots(canvas, size);

    // Layer 8: Floating animated dots
    _paintFloatingDots(canvas, size);

    // Layer 9: Highlight dots
    _paintHighlightDots(canvas, size);

    // Layer 10: Subtle vignette
    _paintVignette(canvas, size);
  }

  List<_DotCluster> _generateClusters(Size size) {
    final clusters = <_DotCluster>[];
    final rng = math.Random(42);

    // Generate organic cluster positions
    final clusterCount = 25;
    for (int c = 0; c < clusterCount; c++) {
      final cx = rng.nextDouble();
      final cy = rng.nextDouble();
      final radius = 0.08 + rng.nextDouble() * 0.15;
      final dotCount = 40 + rng.nextInt(60);
      final colorScheme = rng.nextInt(6);

      final dots = <_Dot>[];
      for (int d = 0; d < dotCount; d++) {
        // Gaussian-like distribution within cluster
        final angle = rng.nextDouble() * math.pi * 2;
        final dist = rng.nextDouble() * rng.nextDouble(); // Bias toward center
        final relX = math.cos(angle) * dist;
        final relY = math.sin(angle) * dist;

        dots.add(_Dot(
          relX: relX,
          relY: relY,
          size: 2 + rng.nextDouble() * 4,
          colorIndex: rng.nextInt(5),
          phase: rng.nextDouble() * math.pi * 2,
        ));
      }

      clusters.add(_DotCluster(
        centerX: cx,
        centerY: cy,
        radius: radius,
        dots: dots,
        colorScheme: colorScheme,
        phase: rng.nextDouble() * math.pi * 2,
      ));
    }

    return clusters;
  }

  List<_FloatingDot> _generateFloatingDots(Size size) {
    final dots = <_FloatingDot>[];
    final rng = math.Random(123);

    for (int i = 0; i < 50; i++) {
      dots.add(_FloatingDot(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2 + rng.nextDouble() * 5,
        colorIndex: rng.nextInt(30), // Will be mapped to color families
        speedX: (rng.nextDouble() - 0.5) * 0.01,
        speedY: (rng.nextDouble() - 0.5) * 0.008,
        phase: rng.nextDouble() * math.pi * 2,
      ));
    }

    return dots;
  }

  void _updateFloatingDots(Size size, double dt) {
    for (final dot in state.floatingDots!) {
      // Gentle drifting motion
      dot.x += dot.speedX * dt * 60 * intensity;
      dot.y += dot.speedY * dt * 60 * intensity;

      // Add subtle wave motion
      dot.x += _wave(0.2, dot.phase) * 0.0003 * intensity;
      dot.y += _wave(0.15, dot.phase + 1) * 0.0002 * intensity;

      // Wrap around edges
      if (dot.x < -0.05) dot.x = 1.05;
      if (dot.x > 1.05) dot.x = -0.05;
      if (dot.y < -0.05) dot.y = 1.05;
      if (dot.y > 1.05) dot.y = -0.05;
    }
  }

  void _paintCanvas(Canvas canvas, Size size) {
    // Warm cream base
    _fillPaint.color = _canvasCream;
    canvas.drawRect(Offset.zero & size, _fillPaint);

    // Subtle warm gradient
    final warmGradient = ui.Gradient.radial(
      Offset(size.width * 0.3, size.height * 0.3),
      size.longestSide * 0.8,
      [
        const Color(0xFFFAF5EA),
        _canvasCream,
        const Color(0xFFF0EBE0),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = warmGradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintCanvasGrain(Canvas canvas, Size size) {
    final rng = math.Random(789);
    final grainColors = [
      const Color(0xFFE8E3D8),
      const Color(0xFFF0EBE0),
      const Color(0xFFE0DBD0),
    ];

    for (int i = 0; i < (400 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final dotSize = 1 + rng.nextDouble() * 2;

      _fillPaint.color = grainColors[rng.nextInt(grainColors.length)].withOpacity(0.4 + rng.nextDouble() * 0.3);
      canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
    }
  }

  void _paintSkyRegion(Canvas canvas, Size size) {
    final rng = math.Random(456);
    final skyBottom = size.height * 0.45;

    // Blue and violet dots for sky
    for (int i = 0; i < (300 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * skyBottom;

      // Gradient: more violet at top, more blue at bottom
      final verticalRatio = y / skyBottom;
      final useViolet = rng.nextDouble() > verticalRatio * 0.7;

      final colors = useViolet ? _violetFamily : _blueFamily;
      final color = colors[rng.nextInt(colors.length)];

      final dotSize = 2 + rng.nextDouble() * 4;
      final opacity = 0.5 + rng.nextDouble() * 0.4;

      // Subtle animation
      final pulse = _norm(0.1, i * 0.1) * 0.2 + 0.8;

      _fillPaint.color = color.withOpacity(opacity * pulse * intensity);
      canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
    }

    // Yellow/orange sun glow area
    final sunX = size.width * 0.7;
    final sunY = size.height * 0.25;

    for (int i = 0; i < (80 * intensity).round(); i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * size.width * 0.15;
      final x = sunX + math.cos(angle) * dist;
      final y = sunY + math.sin(angle) * dist * 0.6;

      final colors = dist < size.width * 0.08 ? _yellowFamily : _orangeFamily;
      final color = colors[rng.nextInt(colors.length)];
      final dotSize = 2 + rng.nextDouble() * 5;
      final opacity = 0.6 - (dist / (size.width * 0.15)) * 0.3;

      final pulse = _norm(0.15, i * 0.2) * 0.15 + 0.85;

      _fillPaint.color = color.withOpacity(opacity * pulse * intensity);
      canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
    }
  }

  void _paintLandscapeClusters(Canvas canvas, Size size) {
    for (final cluster in state.clusters!) {
      final colors = _getColorFamily(cluster.colorScheme);
      final pulse = _norm(0.08, cluster.phase) * 0.15 + 0.85;

      for (final dot in cluster.dots) {
        final x = (cluster.centerX + dot.relX * cluster.radius) * size.width;
        final y = (cluster.centerY + dot.relY * cluster.radius) * size.height;

        // Skip if outside visible area
        if (x < -10 || x > size.width + 10 || y < -10 || y > size.height + 10) {
          continue;
        }

        final color = colors[dot.colorIndex];
        final dotPulse = _norm(0.12, dot.phase) * 0.1 + 0.9;
        final opacity = 0.6 + _norm(0.1, dot.phase + cluster.phase) * 0.3;

        _fillPaint.color = color.withOpacity(opacity * pulse * dotPulse * intensity);
        canvas.drawCircle(Offset(x, y), dot.size * intensity, _fillPaint);
      }
    }
  }

  void _paintWaterRegion(Canvas canvas, Size size) {
    final rng = math.Random(321);
    final waterTop = size.height * 0.65;

    // Blue reflections with horizontal stretching
    for (int i = 0; i < (250 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = waterTop + rng.nextDouble() * (size.height - waterTop);

      // Ripple animation
      final ripple = _wave(0.2, x * 0.01 + y * 0.005) * 3;

      final colors = rng.nextDouble() > 0.3 ? _blueFamily : _violetFamily;
      final color = colors[rng.nextInt(colors.length)];

      // Horizontal elongation for water effect
      final dotWidth = (3 + rng.nextDouble() * 6) * intensity;
      final dotHeight = (2 + rng.nextDouble() * 3) * intensity;
      final opacity = 0.4 + rng.nextDouble() * 0.35;

      final pulse = _norm(0.15, i * 0.08) * 0.2 + 0.8;

      _fillPaint.color = color.withOpacity(opacity * pulse * intensity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + ripple, y),
          width: dotWidth,
          height: dotHeight,
        ),
        _fillPaint,
      );
    }

    // Light reflections on water
    for (int i = 0; i < (40 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = waterTop + rng.nextDouble() * (size.height - waterTop) * 0.5;

      final shimmer = _norm(0.25, i * 0.3) * 0.5 + 0.5;
      final colors = _yellowFamily;
      final color = colors[rng.nextInt(colors.length)];

      _fillPaint.color = color.withOpacity(0.3 * shimmer * intensity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 4 * intensity,
          height: 2 * intensity,
        ),
        _fillPaint,
      );
    }
  }

  void _paintFoliageAccents(Canvas canvas, Size size) {
    final rng = math.Random(654);

    // Tree/foliage areas on sides
    final foliageAreas = [
      Rect.fromLTWH(0, size.height * 0.3, size.width * 0.25, size.height * 0.4),
      Rect.fromLTWH(size.width * 0.8, size.height * 0.35, size.width * 0.2, size.height * 0.35),
    ];

    for (final area in foliageAreas) {
      for (int i = 0; i < (120 * intensity).round(); i++) {
        final x = area.left + rng.nextDouble() * area.width;
        final y = area.top + rng.nextDouble() * area.height;

        // Mix of greens and darker accents
        final useGreen = rng.nextDouble() > 0.2;
        final colors = useGreen ? _greenFamily : _violetFamily;
        final color = colors[rng.nextInt(colors.length)];

        final dotSize = 2 + rng.nextDouble() * 5;
        final opacity = 0.5 + rng.nextDouble() * 0.4;

        final pulse = _norm(0.1, i * 0.15 + x * 0.01) * 0.15 + 0.85;

        _fillPaint.color = color.withOpacity(opacity * pulse * intensity);
        canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
      }
    }

    // Grass/ground accents
    final groundTop = size.height * 0.55;
    final groundBottom = size.height * 0.68;

    for (int i = 0; i < (150 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = groundTop + rng.nextDouble() * (groundBottom - groundTop);

      final useGreen = rng.nextDouble() > 0.15;
      final colors = useGreen ? _greenFamily : _yellowFamily;
      final color = colors[rng.nextInt(colors.length)];

      final dotSize = 2 + rng.nextDouble() * 4;
      final opacity = 0.5 + rng.nextDouble() * 0.35;

      _fillPaint.color = color.withOpacity(opacity * intensity);
      canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
    }
  }

  void _paintShimmerDots(Canvas canvas, Size size) {
    final rng = math.Random(987);

    // Scattered light shimmer across entire canvas
    for (int i = 0; i < (60 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;

      final shimmer = _norm(0.3, i * 0.4 + x * 0.005);
      if (shimmer < 0.6) continue;

      final brightness = (shimmer - 0.6) * 2.5;
      final colors = [_yellowFamily, _orangeFamily][rng.nextInt(2)];
      final color = colors[rng.nextInt(colors.length)];

      final dotSize = 2 + rng.nextDouble() * 3;

      _fillPaint.color = color.withOpacity(brightness * 0.6 * intensity);
      canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
    }
  }

  void _paintFloatingDots(Canvas canvas, Size size) {
    final allColors = [
      ..._blueFamily,
      ..._orangeFamily,
      ..._greenFamily,
      ..._yellowFamily,
      ..._violetFamily,
      ..._redFamily,
    ];

    for (final dot in state.floatingDots!) {
      final x = dot.x * size.width;
      final y = dot.y * size.height;

      final color = allColors[dot.colorIndex % allColors.length];
      final pulse = _norm(0.2, dot.phase) * 0.3 + 0.7;

      _fillPaint.color = color.withOpacity(0.7 * pulse * intensity);
      canvas.drawCircle(Offset(x, y), dot.size * intensity, _fillPaint);
    }
  }

  void _paintHighlightDots(Canvas canvas, Size size) {
    final rng = math.Random(111);

    // Bright white/cream highlight dots
    for (int i = 0; i < (30 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;

      final twinkle = _norm(0.4, i * 0.5);
      if (twinkle < 0.7) continue;

      final brightness = (twinkle - 0.7) * 3.33;
      final dotSize = 1.5 + rng.nextDouble() * 2;

      _fillPaint.color = Colors.white.withOpacity(brightness * 0.5 * intensity);
      canvas.drawCircle(Offset(x, y), dotSize * intensity, _fillPaint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.85;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        const Color(0xFF3A3028).withOpacity(0.08 * intensity),
        const Color(0xFF3A3028).withOpacity(0.2 * intensity),
      ],
      const [0.5, 0.8, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _PointillismPainter oldDelegate) => true;
}
