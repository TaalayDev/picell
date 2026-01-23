import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// LAVA LAMP THEME BUILDER
// ============================================================================

AppTheme buildLavaLampTheme() {
  final baseTextTheme = GoogleFonts.righteousTextTheme();
  final bodyTextTheme = GoogleFonts.quicksandTextTheme();

  return AppTheme(
    type: ThemeType.lavaLamp,
    isDark: true,

    // Primary colors - psychedelic orange
    primaryColor: const Color(0xFFFF6B35), // Warm orange
    primaryVariant: const Color(0xFFE85D04), // Deep orange
    onPrimary: Colors.white,

    // Secondary colors - groovy purple
    accentColor: const Color(0xFF9D4EDD), // Vibrant purple
    onAccent: Colors.white,

    // Background colors - deep purple-black
    background: const Color(0xFF10002B), // Deep purple-black
    surface: const Color(0xFF1A0536), // Slightly lighter
    surfaceVariant: const Color(0xFF240046), // Card surfaces

    // Text colors - warm and psychedelic
    textPrimary: const Color(0xFFFFF0F5), // Lavender blush
    textSecondary: const Color(0xFFE0AAFF), // Light purple
    textDisabled: const Color(0xFF7B5E7B), // Muted purple

    // UI colors
    divider: const Color(0xFF3C096C),
    toolbarColor: const Color(0xFF1A0536),
    error: const Color(0xFFFF6B6B),
    success: const Color(0xFF7AE582),
    warning: const Color(0xFFFFE66D),

    // Grid colors
    gridLine: const Color(0xFF3C096C),
    gridBackground: const Color(0xFF1A0536),

    // Canvas colors
    canvasBackground: const Color(0xFF10002B),
    selectionOutline: const Color(0xFFFF6B35),
    selectionFill: const Color(0x30FF6B35),

    // Icon colors
    activeIcon: const Color(0xFFFF6B35),
    inactiveIcon: const Color(0xFFE0AAFF),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFFFF0F5),
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFFFF0F5),
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFFF6B35),
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
      ),
      titleMedium: bodyTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFFFF0F5),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFFFF0F5),
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFE0AAFF),
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFFF6B35),
        fontWeight: FontWeight.w600,
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// LAVA LAMP ANIMATED BACKGROUND
// ============================================================================

class LavaLampBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const LavaLampBackground({
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

    final lavaState = useMemoized(() => _LavaLampState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _LavaLampPainter(
          repaint: controller,
          state: lavaState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _LavaLampState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_LavaBlob>? blobs;
}

class _LavaBlob {
  double x;
  double y;
  double radius;
  double vx;
  double vy;
  double phase;
  int colorIndex;
  double morphSpeed;
  double morphPhase;

  _LavaBlob({
    required this.x,
    required this.y,
    required this.radius,
    required this.vx,
    required this.vy,
    required this.phase,
    required this.colorIndex,
    required this.morphSpeed,
    required this.morphPhase,
  });
}

class _LavaLampPainter extends CustomPainter {
  final _LavaLampState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Psychedelic color palette
  static const List<Color> _lavaColors = [
    Color(0xFFFF6B35), // Orange
    Color(0xFFFF006E), // Hot pink
    Color(0xFF9D4EDD), // Purple
    Color(0xFFFFBE0B), // Yellow
    Color(0xFF3A86FF), // Blue
    Color(0xFFF72585), // Magenta
  ];

  static const Color _glassTop = Color(0xFF2D0A4E);
  static const Color _glassBottom = Color(0xFF0D0221);
  static const Color _metalCap = Color(0xFF4A4A4A);
  static const Color _metalHighlight = Color(0xFF6A6A6A);

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _path = Path();

  _LavaLampPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  }) : super(repaint: repaint);

  double _wave(double speed, [double offset = 0]) => math.sin(state.time * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialize blobs
    state.blobs ??= _generateBlobs(size);

    // Update blob positions
    _updateBlobs(size, dt);

    // Layer 1: Deep background
    _paintBackground(canvas, size);

    // Layer 2: Lamp glass container
    _paintLampGlass(canvas, size);

    // Layer 3: Lava blobs with metaball effect
    _paintLavaBlobs(canvas, size);

    // Layer 4: Glass reflections
    _paintGlassReflections(canvas, size);

    // Layer 5: Lamp cap and base
    _paintLampHardware(canvas, size);

    // Layer 6: Ambient glow
    _paintAmbientGlow(canvas, size);

    // Layer 7: Light bloom
    _paintLightBloom(canvas, size);

    // Layer 8: Vignette
    _paintVignette(canvas, size);
  }

  List<_LavaBlob> _generateBlobs(Size size) {
    final blobs = <_LavaBlob>[];
    final rng = math.Random(42);
    final blobCount = 8;

    for (int i = 0; i < blobCount; i++) {
      blobs.add(_LavaBlob(
        x: 0.3 + rng.nextDouble() * 0.4,
        y: 0.2 + rng.nextDouble() * 0.6,
        radius: 0.06 + rng.nextDouble() * 0.08,
        vx: (rng.nextDouble() - 0.5) * 0.02,
        vy: (rng.nextDouble() - 0.5) * 0.015,
        phase: rng.nextDouble() * math.pi * 2,
        colorIndex: rng.nextInt(_lavaColors.length),
        morphSpeed: 0.5 + rng.nextDouble() * 0.5,
        morphPhase: rng.nextDouble() * math.pi * 2,
      ));
    }

    return blobs;
  }

  void _updateBlobs(Size size, double dt) {
    final lampLeft = 0.25;
    final lampRight = 0.75;
    final lampTop = 0.12;
    final lampBottom = 0.88;

    for (final blob in state.blobs!) {
      // Heat rises effect - blobs tend to rise, then cool and sink
      final heatCycle = _wave(0.08, blob.phase);
      final buoyancy = heatCycle * 0.008;

      blob.vy += buoyancy * dt * 60;

      // Horizontal drift
      blob.vx += _wave(0.1, blob.phase + 1.5) * 0.0002 * dt * 60;

      // Apply velocity
      blob.x += blob.vx * dt * 60;
      blob.y += blob.vy * dt * 60;

      // Damping
      blob.vx *= 0.995;
      blob.vy *= 0.995;

      // Bounce off walls with soft collision
      if (blob.x - blob.radius < lampLeft) {
        blob.x = lampLeft + blob.radius;
        blob.vx = blob.vx.abs() * 0.6;
      }
      if (blob.x + blob.radius > lampRight) {
        blob.x = lampRight - blob.radius;
        blob.vx = -blob.vx.abs() * 0.6;
      }
      if (blob.y - blob.radius < lampTop) {
        blob.y = lampTop + blob.radius;
        blob.vy = blob.vy.abs() * 0.6;
      }
      if (blob.y + blob.radius > lampBottom) {
        blob.y = lampBottom - blob.radius;
        blob.vy = -blob.vy.abs() * 0.6;
      }

      // Blob radius morphing
      blob.radius = (0.06 + _norm(blob.morphSpeed, blob.morphPhase) * 0.06) * intensity;
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final gradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.5),
      size.longestSide * 0.7,
      const [
        Color(0xFF1A0536),
        Color(0xFF10002B),
        Color(0xFF0A0015),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintLampGlass(Canvas canvas, Size size) {
    final lampRect = Rect.fromLTRB(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.75,
      size.height * 0.9,
    );

    // Lamp shape - tapered cylinder
    _path.reset();
    _path.moveTo(lampRect.left + lampRect.width * 0.1, lampRect.top);
    _path.quadraticBezierTo(
      lampRect.left - lampRect.width * 0.05,
      lampRect.top + lampRect.height * 0.3,
      lampRect.left,
      lampRect.top + lampRect.height * 0.5,
    );
    _path.quadraticBezierTo(
      lampRect.left - lampRect.width * 0.03,
      lampRect.top + lampRect.height * 0.7,
      lampRect.left + lampRect.width * 0.05,
      lampRect.bottom,
    );
    _path.lineTo(lampRect.right - lampRect.width * 0.05, lampRect.bottom);
    _path.quadraticBezierTo(
      lampRect.right + lampRect.width * 0.03,
      lampRect.top + lampRect.height * 0.7,
      lampRect.right,
      lampRect.top + lampRect.height * 0.5,
    );
    _path.quadraticBezierTo(
      lampRect.right + lampRect.width * 0.05,
      lampRect.top + lampRect.height * 0.3,
      lampRect.right - lampRect.width * 0.1,
      lampRect.top,
    );
    _path.close();

    // Glass gradient
    final glassGradient = ui.Gradient.linear(
      Offset(lampRect.left, lampRect.top),
      Offset(lampRect.left, lampRect.bottom),
      [
        _glassTop.withOpacity(0.85),
        _glassBottom.withOpacity(0.9),
      ],
    );

    _fillPaint.shader = glassGradient;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;

    // Glass edge highlight
    _strokePaint.color = Colors.white.withOpacity(0.08 * intensity);
    _strokePaint.strokeWidth = 2 * intensity;
    canvas.drawPath(_path, _strokePaint);
  }

  void _paintLavaBlobs(Canvas canvas, Size size) {
    // Sort blobs by y for depth
    final sortedBlobs = List<_LavaBlob>.from(state.blobs!)..sort((a, b) => a.y.compareTo(b.y));

    for (final blob in sortedBlobs) {
      final centerX = blob.x * size.width;
      final centerY = blob.y * size.height;
      final radius = blob.radius * size.shortestSide;

      // Morphing shape using multiple sine waves
      final morphAmount = 0.2 * intensity;
      final points = <Offset>[];
      final segments = 32;

      for (int i = 0; i < segments; i++) {
        final angle = i * 2 * math.pi / segments;
        final morph1 = _wave(blob.morphSpeed, blob.morphPhase + angle * 2) * morphAmount;
        final morph2 = _wave(blob.morphSpeed * 1.5, blob.morphPhase + angle * 3 + 1) * morphAmount * 0.5;
        final r = radius * (1 + morph1 + morph2);

        points.add(Offset(
          centerX + math.cos(angle) * r,
          centerY + math.sin(angle) * r,
        ));
      }

      // Draw blob with smooth curve
      _path.reset();
      _path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length; i++) {
        final p0 = points[i];
        final p1 = points[(i + 1) % points.length];
        final p2 = points[(i + 2) % points.length];

        final ctrl1 = Offset(
          p0.dx + (p1.dx - points[(i - 1 + points.length) % points.length].dx) / 4,
          p0.dy + (p1.dy - points[(i - 1 + points.length) % points.length].dy) / 4,
        );
        final ctrl2 = Offset(
          p1.dx - (p2.dx - p0.dx) / 4,
          p1.dy - (p2.dy - p0.dy) / 4,
        );

        _path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
      }

      _path.close();

      // Blob color with glow
      final baseColor = _lavaColors[blob.colorIndex];
      final glowPulse = _norm(0.3, blob.phase) * 0.3 + 0.7;

      // Outer glow
      _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
      _fillPaint.color = baseColor.withOpacity(0.4 * glowPulse * intensity);
      canvas.drawPath(_path, _fillPaint);
      _fillPaint.maskFilter = null;

      // Inner gradient
      final blobGradient = ui.Gradient.radial(
        Offset(centerX - radius * 0.2, centerY - radius * 0.2),
        radius * 1.2,
        [
          Color.lerp(baseColor, Colors.white, 0.4)!,
          baseColor,
          Color.lerp(baseColor, Colors.black, 0.3)!,
        ],
        const [0.0, 0.5, 1.0],
      );

      _fillPaint.shader = blobGradient;
      canvas.drawPath(_path, _fillPaint);
      _fillPaint.shader = null;

      // Highlight
      _fillPaint.color = Colors.white.withOpacity(0.3 * glowPulse * intensity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX - radius * 0.3, centerY - radius * 0.3),
          width: radius * 0.4,
          height: radius * 0.25,
        ),
        _fillPaint,
      );
    }
  }

  void _paintGlassReflections(Canvas canvas, Size size) {
    final lampLeft = size.width * 0.25;
    final lampTop = size.height * 0.1;
    final lampWidth = size.width * 0.5;
    final lampHeight = size.height * 0.8;

    // Left edge reflection
    final leftReflection = ui.Gradient.linear(
      Offset(lampLeft, lampTop),
      Offset(lampLeft + lampWidth * 0.15, lampTop),
      [
        Colors.white.withOpacity(0.12 * intensity),
        Colors.transparent,
      ],
    );

    _path.reset();
    _path.moveTo(lampLeft + lampWidth * 0.1, lampTop);
    _path.quadraticBezierTo(
      lampLeft - lampWidth * 0.02,
      lampTop + lampHeight * 0.3,
      lampLeft + lampWidth * 0.02,
      lampTop + lampHeight * 0.5,
    );
    _path.lineTo(lampLeft + lampWidth * 0.12, lampTop + lampHeight * 0.5);
    _path.quadraticBezierTo(
      lampLeft + lampWidth * 0.08,
      lampTop + lampHeight * 0.3,
      lampLeft + lampWidth * 0.12,
      lampTop,
    );
    _path.close();

    _fillPaint.shader = leftReflection;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;

    // Top curved reflection
    _fillPaint.color = Colors.white.withOpacity(0.08 * intensity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.45, lampTop + lampHeight * 0.08),
        width: lampWidth * 0.3,
        height: lampHeight * 0.04,
      ),
      _fillPaint,
    );
  }

  void _paintLampHardware(Canvas canvas, Size size) {
    final lampCenterX = size.width * 0.5;

    // Top cap
    final capTop = size.height * 0.08;
    final capHeight = size.height * 0.04;
    final capWidth = size.width * 0.35;

    final capGradient = ui.Gradient.linear(
      Offset(lampCenterX - capWidth * 0.5, capTop),
      Offset(lampCenterX + capWidth * 0.5, capTop),
      [
        _metalCap,
        _metalHighlight,
        _metalCap,
      ],
      const [0.0, 0.4, 1.0],
    );

    _fillPaint.shader = capGradient;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(lampCenterX, capTop + capHeight * 0.5),
          width: capWidth,
          height: capHeight,
        ),
        Radius.circular(capHeight * 0.3),
      ),
      _fillPaint,
    );
    _fillPaint.shader = null;

    // Base
    final baseBottom = size.height * 0.94;
    final baseHeight = size.height * 0.05;
    final baseWidth = size.width * 0.45;

    final baseGradient = ui.Gradient.linear(
      Offset(lampCenterX - baseWidth * 0.5, baseBottom - baseHeight),
      Offset(lampCenterX + baseWidth * 0.5, baseBottom - baseHeight),
      [
        _metalCap,
        _metalHighlight,
        _metalCap,
      ],
      const [0.0, 0.35, 1.0],
    );

    _path.reset();
    _path.moveTo(lampCenterX - baseWidth * 0.35, baseBottom - baseHeight);
    _path.lineTo(lampCenterX - baseWidth * 0.5, baseBottom);
    _path.lineTo(lampCenterX + baseWidth * 0.5, baseBottom);
    _path.lineTo(lampCenterX + baseWidth * 0.35, baseBottom - baseHeight);
    _path.close();

    _fillPaint.shader = baseGradient;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;

    // Base highlight line
    _strokePaint.color = _metalHighlight.withOpacity(0.5 * intensity);
    _strokePaint.strokeWidth = 1.5 * intensity;
    canvas.drawLine(
      Offset(lampCenterX - baseWidth * 0.4, baseBottom - baseHeight * 0.3),
      Offset(lampCenterX + baseWidth * 0.3, baseBottom - baseHeight * 0.3),
      _strokePaint,
    );
  }

  void _paintAmbientGlow(Canvas canvas, Size size) {
    // Colored ambient light from the lamp
    for (final blob in state.blobs!) {
      final color = _lavaColors[blob.colorIndex];
      final glowPulse = _norm(0.2, blob.phase) * 0.3 + 0.3;

      _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 60 * intensity);
      _fillPaint.color = color.withOpacity(0.06 * glowPulse * intensity);

      canvas.drawCircle(
        Offset(blob.x * size.width, blob.y * size.height),
        size.shortestSide * 0.2,
        _fillPaint,
      );
    }

    _fillPaint.maskFilter = null;
  }

  void _paintLightBloom(Canvas canvas, Size size) {
    // Overall warm bloom from lamp
    final bloomCenter = Offset(size.width * 0.5, size.height * 0.5);
    final bloomPulse = _norm(0.08) * 0.2 + 0.8;

    final bloomGradient = ui.Gradient.radial(
      bloomCenter,
      size.shortestSide * 0.6,
      [
        primaryColor.withOpacity(0.08 * bloomPulse * intensity),
        accentColor.withOpacity(0.04 * bloomPulse * intensity),
        Colors.transparent,
      ],
      const [0.0, 0.4, 1.0],
    );

    _fillPaint.shader = bloomGradient;
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * intensity);
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.maskFilter = null;
    _fillPaint.shader = null;
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.8;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.4 * intensity),
        Colors.black.withOpacity(0.8 * intensity),
      ],
      const [0.3, 0.7, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _LavaLampPainter oldDelegate) => true;
}
