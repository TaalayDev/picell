import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// VOLCANIC LAVA LAMP THEME BUILDER
// ============================================================================

AppTheme buildVolcanicLavaLampTheme() {
  final baseTextTheme = GoogleFonts.spaceGroteskTextTheme();
  final bodyTextTheme = GoogleFonts.interTextTheme();

  return AppTheme(
    type: ThemeType.volcanicLavaLamp,
    isDark: true,

    // Primary colors - molten orange-red
    primaryColor: const Color(0xFFFF4500),
    primaryVariant: const Color(0xFFCC3700),
    onPrimary: const Color(0xFFFFF8F0),

    // Secondary colors - deep purple
    accentColor: const Color(0xFF6B2D8B),
    onAccent: const Color(0xFFF0E8F5),

    // Background colors - near black
    background: const Color(0xFF080408),
    surface: const Color(0xFF120810),
    surfaceVariant: const Color(0xFF1A0C14),

    // Text colors
    textPrimary: const Color(0xFFF5E8E0),
    textSecondary: const Color(0xFFD0A090),
    textDisabled: const Color(0xFF6A5050),

    // UI colors
    divider: const Color(0xFF2A1820),
    toolbarColor: const Color(0xFF120810),
    error: const Color(0xFFFF6B6B),
    success: const Color(0xFF8BC34A),
    warning: const Color(0xFFFFAB00),

    // Grid colors
    gridLine: const Color(0xFF2A1820),
    gridBackground: const Color(0xFF120810),

    // Canvas colors
    canvasBackground: const Color(0xFF080408),
    selectionOutline: const Color(0xFFFF4500),
    selectionFill: const Color(0x30FF4500),

    // Icon colors
    activeIcon: const Color(0xFFFF4500),
    inactiveIcon: const Color(0xFFD0A090),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFF5E8E0),
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFF5E8E0),
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFF5E8E0),
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFF5E8E0),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF5E8E0),
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFD0A090),
        fontWeight: FontWeight.w400,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFFF4500),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// VOLCANIC LAVA LAMP ANIMATED BACKGROUND
// ============================================================================

class VolcanicLavaLampBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const VolcanicLavaLampBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 24),
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
        painter: _LavaLampPainter(
          t: t,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// Blob data for organic movement
class _BlobData {
  final double baseX;
  final double baseY;
  final double baseRadius;
  final double phaseX;
  final double phaseY;
  final double phaseR;
  final double speedX;
  final double speedY;
  final double speedR;
  final int colorIndex;

  const _BlobData({
    required this.baseX,
    required this.baseY,
    required this.baseRadius,
    required this.phaseX,
    required this.phaseY,
    required this.phaseR,
    required this.speedX,
    required this.speedY,
    required this.speedR,
    required this.colorIndex,
  });
}

class _LavaLampPainter extends CustomPainter {
  final double t;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Color palette - molten lava colors
  static const Color _magma = Color(0xFFFF4500);
  static const Color _lava = Color(0xFFFF6020);
  static const Color _ember = Color(0xFFFF8040);
  static const Color _flame = Color(0xFFFFAA30);
  static const Color _purple = Color(0xFF6B2D8B);
  static const Color _deepPurple = Color(0xFF4A1D6B);
  static const Color _violet = Color(0xFF8B4DA8);
  static const Color _black = Color(0xFF080408);

  static const List<Color> _hotColors = [_magma, _lava, _ember, _flame];
  static const List<Color> _coolColors = [_purple, _deepPurple, _violet];

  // Pre-computed blobs - large organic shapes
  static const List<_BlobData> _largeBlobs = [
    _BlobData(
        baseX: 0.3,
        baseY: 0.7,
        baseRadius: 0.18,
        phaseX: 0.0,
        phaseY: 0.5,
        phaseR: 1.0,
        speedX: 0.3,
        speedY: 0.2,
        speedR: 0.4,
        colorIndex: 0),
    _BlobData(
        baseX: 0.7,
        baseY: 0.3,
        baseRadius: 0.15,
        phaseX: 1.5,
        phaseY: 0.0,
        phaseR: 2.0,
        speedX: 0.25,
        speedY: 0.35,
        speedR: 0.3,
        colorIndex: 1),
    _BlobData(
        baseX: 0.5,
        baseY: 0.5,
        baseRadius: 0.20,
        phaseX: 0.8,
        phaseY: 1.2,
        phaseR: 0.5,
        speedX: 0.2,
        speedY: 0.25,
        speedR: 0.35,
        colorIndex: 2),
    _BlobData(
        baseX: 0.2,
        baseY: 0.3,
        baseRadius: 0.12,
        phaseX: 2.0,
        phaseY: 1.8,
        phaseR: 1.5,
        speedX: 0.35,
        speedY: 0.3,
        speedR: 0.25,
        colorIndex: 3),
    _BlobData(
        baseX: 0.8,
        baseY: 0.7,
        baseRadius: 0.14,
        phaseX: 1.0,
        phaseY: 2.5,
        phaseR: 0.8,
        speedX: 0.28,
        speedY: 0.22,
        speedR: 0.32,
        colorIndex: 0),
  ];

  // Medium blobs
  static const List<_BlobData> _mediumBlobs = [
    _BlobData(
        baseX: 0.4,
        baseY: 0.2,
        baseRadius: 0.10,
        phaseX: 0.3,
        phaseY: 1.0,
        phaseR: 1.8,
        speedX: 0.4,
        speedY: 0.35,
        speedR: 0.5,
        colorIndex: 1),
    _BlobData(
        baseX: 0.6,
        baseY: 0.8,
        baseRadius: 0.09,
        phaseX: 1.8,
        phaseY: 0.3,
        phaseR: 0.2,
        speedX: 0.35,
        speedY: 0.4,
        speedR: 0.45,
        colorIndex: 2),
    _BlobData(
        baseX: 0.15,
        baseY: 0.55,
        baseRadius: 0.08,
        phaseX: 2.5,
        phaseY: 1.5,
        phaseR: 2.2,
        speedX: 0.45,
        speedY: 0.38,
        speedR: 0.4,
        colorIndex: 3),
    _BlobData(
        baseX: 0.85,
        baseY: 0.45,
        baseRadius: 0.085,
        phaseX: 0.7,
        phaseY: 2.2,
        phaseR: 1.2,
        speedX: 0.38,
        speedY: 0.42,
        speedR: 0.48,
        colorIndex: 0),
    _BlobData(
        baseX: 0.5,
        baseY: 0.1,
        baseRadius: 0.07,
        phaseX: 1.2,
        phaseY: 0.8,
        phaseR: 2.8,
        speedX: 0.42,
        speedY: 0.3,
        speedR: 0.38,
        colorIndex: 1),
    _BlobData(
        baseX: 0.35,
        baseY: 0.9,
        baseRadius: 0.075,
        phaseX: 2.0,
        phaseY: 1.0,
        phaseR: 0.6,
        speedX: 0.32,
        speedY: 0.45,
        speedR: 0.42,
        colorIndex: 2),
  ];

  // Small accent blobs
  static const List<_BlobData> _smallBlobs = [
    _BlobData(
        baseX: 0.25,
        baseY: 0.4,
        baseRadius: 0.05,
        phaseX: 0.5,
        phaseY: 2.0,
        phaseR: 1.0,
        speedX: 0.5,
        speedY: 0.45,
        speedR: 0.6,
        colorIndex: 0),
    _BlobData(
        baseX: 0.75,
        baseY: 0.6,
        baseRadius: 0.045,
        phaseX: 1.5,
        phaseY: 0.5,
        phaseR: 2.5,
        speedX: 0.48,
        speedY: 0.52,
        speedR: 0.55,
        colorIndex: 1),
    _BlobData(
        baseX: 0.55,
        baseY: 0.35,
        baseRadius: 0.04,
        phaseX: 2.2,
        phaseY: 1.2,
        phaseR: 0.3,
        speedX: 0.55,
        speedY: 0.48,
        speedR: 0.52,
        colorIndex: 2),
    _BlobData(
        baseX: 0.45,
        baseY: 0.65,
        baseRadius: 0.042,
        phaseX: 0.8,
        phaseY: 2.8,
        phaseR: 1.8,
        speedX: 0.52,
        speedY: 0.5,
        speedR: 0.58,
        colorIndex: 3),
    _BlobData(
        baseX: 0.1,
        baseY: 0.75,
        baseRadius: 0.038,
        phaseX: 1.8,
        phaseY: 0.2,
        phaseR: 2.2,
        speedX: 0.58,
        speedY: 0.55,
        speedR: 0.5,
        colorIndex: 0),
    _BlobData(
        baseX: 0.9,
        baseY: 0.25,
        baseRadius: 0.035,
        phaseX: 2.8,
        phaseY: 1.8,
        phaseR: 0.8,
        speedX: 0.5,
        speedY: 0.58,
        speedR: 0.62,
        colorIndex: 1),
    _BlobData(
        baseX: 0.65,
        baseY: 0.15,
        baseRadius: 0.032,
        phaseX: 0.2,
        phaseY: 2.5,
        phaseR: 1.5,
        speedX: 0.6,
        speedY: 0.52,
        speedR: 0.48,
        colorIndex: 2),
    _BlobData(
        baseX: 0.3,
        baseY: 0.85,
        baseRadius: 0.036,
        phaseX: 1.0,
        phaseY: 0.8,
        phaseR: 2.8,
        speedX: 0.55,
        speedY: 0.6,
        speedR: 0.55,
        colorIndex: 3),
  ];

  // Reusable paint objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Path _blobPath = Path();

  _LavaLampPainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  });

  double get _phase => 2 * math.pi * t;
  double _wave(double speed, [double offset = 0]) => math.sin(_phase * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintAmbientGlow(canvas, size);
    _paintBlobLayer(canvas, size, _largeBlobs, 1.0, 0.7);
    _paintBlobLayer(canvas, size, _mediumBlobs, 0.85, 0.6);
    _paintBlobLayer(canvas, size, _smallBlobs, 0.7, 0.5);
    _paintHeatDistortion(canvas, size);
    _paintHighlights(canvas, size);
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Deep gradient background
    final gradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.6),
      size.longestSide * 0.8,
      [
        const Color(0xFF150810), // Warm dark center
        const Color(0xFF0A0408), // Near black
        const Color(0xFF050204), // Deep black edges
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintAmbientGlow(Canvas canvas, Size size) {
    final pulse = _norm(0.3) * 0.3 + 0.7;

    // Bottom heat glow
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 100 * intensity);
    _fillPaint.color = _magma.withOpacity(0.08 * pulse * intensity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 1.1),
        width: size.width * 1.2,
        height: size.height * 0.5,
      ),
      _fillPaint,
    );

    // Top cool glow
    _fillPaint.color = _purple.withOpacity(0.05 * pulse * intensity);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * -0.1),
        width: size.width * 1.0,
        height: size.height * 0.4,
      ),
      _fillPaint,
    );

    _fillPaint.maskFilter = null;
  }

  void _paintBlobLayer(Canvas canvas, Size size, List<_BlobData> blobs, double scale, double baseOpacity) {
    for (final blob in blobs) {
      _drawBlob(canvas, size, blob, scale, baseOpacity);
    }
  }

  void _drawBlob(Canvas canvas, Size size, _BlobData blob, double scale, double baseOpacity) {
    // Calculate animated position
    final moveX = _wave(blob.speedX, blob.phaseX) * 0.15;
    final moveY = _wave(blob.speedY, blob.phaseY) * 0.2;
    final scaleVar = _norm(blob.speedR, blob.phaseR) * 0.3 + 0.85;

    final centerX = (blob.baseX + moveX) * size.width;
    final centerY = (blob.baseY + moveY) * size.height;
    final radius = blob.baseRadius * size.shortestSide * scale * scaleVar * intensity;

    if (radius < 5) return;

    // Get blob color with gradient
    final color = _hotColors[blob.colorIndex];
    final innerColor = Color.lerp(color, _flame, 0.3)!;
    final outerColor = Color.lerp(color, _deepPurple, 0.2)!;

    // Organic blob shape using bezier curves
    _blobPath.reset();
    final points = 8;
    final List<Offset> controlPoints = [];

    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * math.pi;
      // Organic variation per point
      final variation = _wave(0.5 + blob.speedX * 0.5, blob.phaseX + i * 0.8) * 0.25 + 1.0;
      final r = radius * variation;

      controlPoints.add(Offset(
        centerX + math.cos(angle) * r,
        centerY + math.sin(angle) * r,
      ));
    }

    // Create smooth blob using quadratic beziers
    _blobPath.moveTo(
      (controlPoints[0].dx + controlPoints[points - 1].dx) / 2,
      (controlPoints[0].dy + controlPoints[points - 1].dy) / 2,
    );

    for (int i = 0; i < points; i++) {
      final next = (i + 1) % points;
      final midX = (controlPoints[i].dx + controlPoints[next].dx) / 2;
      final midY = (controlPoints[i].dy + controlPoints[next].dy) / 2;

      _blobPath.quadraticBezierTo(
        controlPoints[i].dx,
        controlPoints[i].dy,
        midX,
        midY,
      );
    }
    _blobPath.close();

    // Draw outer glow
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    _fillPaint.color = outerColor.withOpacity(baseOpacity * 0.4 * intensity);
    canvas.drawPath(_blobPath, _fillPaint);

    // Draw main blob with gradient
    _fillPaint.maskFilter = null;
    final blobGradient = ui.Gradient.radial(
      Offset(centerX - radius * 0.2, centerY - radius * 0.2),
      radius * 1.2,
      [
        innerColor.withOpacity(baseOpacity * 0.9 * intensity),
        color.withOpacity(baseOpacity * 0.8 * intensity),
        outerColor.withOpacity(baseOpacity * 0.6 * intensity),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = blobGradient;
    canvas.drawPath(_blobPath, _fillPaint);
    _fillPaint.shader = null;

    // Inner highlight
    final highlightRadius = radius * 0.4;
    final highlightX = centerX - radius * 0.25;
    final highlightY = centerY - radius * 0.25;

    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, highlightRadius * 0.5);
    _fillPaint.color = _flame.withOpacity(baseOpacity * 0.3 * intensity);
    canvas.drawCircle(Offset(highlightX, highlightY), highlightRadius, _fillPaint);
    _fillPaint.maskFilter = null;
  }

  void _paintHeatDistortion(Canvas canvas, Size size) {
    // Subtle heat shimmer lines rising
    final shimmerCount = 6;

    for (int i = 0; i < shimmerCount; i++) {
      final baseX = (i + 0.5) / shimmerCount * size.width;
      final progress = (t * 0.5 + i * 0.15) % 1.0;
      final y = size.height * (1.0 - progress);

      // Wavy path
      final wave = _wave(2.0, i * 1.5) * 15 * intensity;
      final x = baseX + wave;

      final opacity = math.sin(progress * math.pi) * 0.06 * intensity;

      if (opacity > 0.01) {
        _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * intensity);
        _fillPaint.color = _lava.withOpacity(opacity);

        canvas.drawCircle(
          Offset(x, y),
          (3 + _norm(1.0, i.toDouble()) * 4) * intensity,
          _fillPaint,
        );
      }
    }

    _fillPaint.maskFilter = null;
  }

  void _paintHighlights(Canvas canvas, Size size) {
    // Bright hot spots that pulse
    final rng = math.Random(42);

    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;

      final twinkle = _norm(1.2, i * 0.8);
      if (twinkle > 0.6) {
        final brightness = (twinkle - 0.6) * 2.5;
        final spotSize = (2 + brightness * 4) * intensity;

        _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, spotSize * 2);
        _fillPaint.color = _flame.withOpacity(brightness * 0.4 * intensity);
        canvas.drawCircle(Offset(x, y), spotSize, _fillPaint);

        _fillPaint.maskFilter = null;
        _fillPaint.color = Colors.white.withOpacity(brightness * 0.3 * intensity);
        canvas.drawCircle(Offset(x, y), spotSize * 0.3, _fillPaint);
      }
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.7;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        _black.withOpacity(0.4 * intensity),
        _black.withOpacity(0.85 * intensity),
      ],
      const [0.3, 0.7, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _LavaLampPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.intensity != intensity;
  }
}
