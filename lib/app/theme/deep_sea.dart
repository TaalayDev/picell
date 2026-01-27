import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildDeepSeaTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.deepSea,
    isDark: true,
    // Primary colors - bioluminescent teal
    primaryColor: const Color(0xFF00FFCC), // Bright bioluminescent teal
    primaryVariant: const Color(0xFF00D4AA), // Deeper teal
    onPrimary: Colors.black,
    // Secondary colors - electric blue
    accentColor: const Color(0xFF00AAFF), // Electric deep blue
    onAccent: Colors.white,
    // Background colors - deep ocean depths
    background: const Color(0xFF0A0F1C), // Very dark navy (deep ocean)
    surface: const Color(0xFF0F1A2A), // Dark blue-black (ocean depths)
    surfaceVariant: const Color(0xFF1A2635), // Slightly lighter depths
    // Text colors - light for deep water contrast
    textPrimary: const Color(0xFFE0F4F7), // Light cyan-white
    textSecondary: const Color(0xFFB3D9E0), // Medium cyan
    textDisabled: const Color(0xFF6B8E9B), // Muted blue-gray
    // UI colors
    divider: const Color(0xFF2A3A4A),
    toolbarColor: const Color(0xFF0F1A2A),
    error: const Color(0xFFFF4757), // Bright red for visibility
    success: const Color(0xFF00FFCC), // Match primary bioluminescent
    warning: const Color(0xFFFFD700), // Bright gold warning
    // Grid colors
    gridLine: const Color(0xFF2A3A4A),
    gridBackground: const Color(0xFF0F1A2A),
    // Canvas colors
    canvasBackground: const Color(0xFF0A0F1C),
    selectionOutline: const Color(0xFF00FFCC), // Bioluminescent selection
    selectionFill: const Color(0x3000FFCC),
    // Icon colors
    activeIcon: const Color(0xFF00FFCC), // Bioluminescent teal for active
    inactiveIcon: const Color(0xFFB3D9E0), // Light blue for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE0F4F7),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE0F4F7),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE0F4F7),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB3D9E0),
      ),
    ),
    primaryFontWeight: FontWeight.w400, // Light weight for fluid feel
  );
}

// Enhanced Deep Sea theme background with bioluminescent creatures and ocean depths
class DeepSeaBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const DeepSeaBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: theme.type.animationDuration);

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
        controller.value = 0.0;
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(Tween<double>(begin: 0, end: 1).animate(controller));

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnhancedDeepSeaPainter(
          t: t,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.3, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
        isComplex: true,
        willChange: enableAnimation,
      ),
    );
  }
}

class _EnhancedDeepSeaPainter extends CustomPainter {
  final double t;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _EnhancedDeepSeaPainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  // Animation helpers for smooth looping
  double get _phase => 2 * math.pi * t;
  double _wave(double speed, [double offset = 0]) => math.sin(_phase * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  // Deep sea color palette
  late final Color _abyssal = const Color(0xFF000B1A); // Deepest depths
  late final Color _bathyal = const Color(0xFF0A1529); // Deep water
  late final Color _mesopelagic = const Color(0xFF152238); // Twilight zone
  late final Color _biolumBlue = const Color(0xFF00CCFF); // Bioluminescent blue

  // Element counts based on intensity
  int get _currentLayers => (6 * intensity).round().clamp(3, 9);

  @override
  void paint(Canvas canvas, Size size) {
    _paintAbyssalDepths(canvas, size);
    _paintOceanCurrents(canvas, size);
    _paintPressureDistortions(canvas, size);
    _paintMarineSediment(canvas, size);
    _paintAbyssalGlow(canvas, size);
  }

  void _paintAbyssalDepths(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Multi-layered depth gradient representing ocean zones
    final depthGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          _mesopelagic.withOpacity(0.4), // Twilight zone remnant
          _bathyal.withOpacity(0.8), // Bathyal zone
          _abyssal.withOpacity(0.95), // Abyssal depths
          const Color(0xFF000000), // True abyss
        ],
        [0.0, 0.3, 0.8, 1.0],
      );

    canvas.drawRect(rect, depthGradient);

    // Pressure gradient effects
    for (int i = 0; i < 4; i++) {
      final pressureY = size.height * (0.2 + i * 0.2);
      final pressureIntensity = _norm(0.03, i * 0.8);

      final pressurePaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, pressureY - 30),
          Offset(0, pressureY + 30),
          [
            Colors.transparent,
            _bathyal.withOpacity(0.1 * pressureIntensity * intensity),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );

      canvas.drawRect(
        Rect.fromLTWH(0, pressureY - 30, size.width, 60),
        pressurePaint,
      );
    }
  }

  void _paintOceanCurrents(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int layer = 0; layer < _currentLayers; layer++) {
      final currentY = size.height * (0.1 + layer * 0.15);
      final currentSpeed = 0.05 + layer * 0.01;
      final phase = _phase * currentSpeed + layer * math.pi / 3;

      final path = Path();
      path.moveTo(0, currentY);

      // Create flowing current lines
      for (double x = 0; x <= size.width; x += 8) {
        final primaryFlow = math.sin(x / 150 + phase) * 20 * intensity;
        final secondaryFlow = math.sin(x / 100 + phase * 1.3) * 12 * intensity;
        final microFlow = math.sin(x / 50 + phase * 2.1) * 6 * intensity;

        final y = currentY + primaryFlow + secondaryFlow + microFlow;
        path.lineTo(x, y);
      }

      final currentIntensity = 0.3 + 0.4 * _norm(0.08, layer * 0.6);
      paint.strokeWidth = (1 + layer * 0.5) * intensity;
      paint.color = Color.lerp(
        primaryColor.withOpacity(0.15 * currentIntensity * intensity),
        accentColor.withOpacity(0.12 * currentIntensity * intensity),
        layer / (_currentLayers - 1),
      )!;

      canvas.drawPath(path, paint);

      // Current particle trails
      if (layer % 2 == 0) {
        _paintCurrentParticles(canvas, size, currentY, phase, layer);
      }
    }
  }

  void _paintCurrentParticles(Canvas canvas, Size size, double currentY, double phase, int layer) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final particleProgress = (phase * 0.1 + i * 0.15) % 1.0;
      final particleX = particleProgress * size.width * 1.2 - size.width * 0.1;
      final particleY = currentY + math.sin(particleProgress * 4 * math.pi) * 10 * intensity;

      final particleSize = (1.5 + layer * 0.5) * intensity;
      final particleOpacity = math.max(0.0, (1.0 - particleProgress) * 0.6) * intensity;

      paint.color = primaryColor.withOpacity(particleOpacity);
      canvas.drawCircle(Offset(particleX, particleY), particleSize, paint);
    }
  }

  void _paintPressureDistortions(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Pressure wave distortions
    for (int i = 0; i < 4; i++) {
      final distortionX = size.width * (0.2 + i * 0.2);
      final distortionY = size.height * (0.3 + _wave(0.02, i.toDouble()) * 0.4);

      final distortionSize = (40 + i * 15 + _wave(0.08, i * 0.8) * 10) * intensity;
      final pressureIntensity = _norm(0.06, i * 0.7);

      // Create pressure wave rings
      for (int ring = 0; ring < 3; ring++) {
        final ringSize = distortionSize * (1 + ring * 0.3);
        final ringOpacity = (0.03 - ring * 0.01) * pressureIntensity * intensity;

        paint.color = accentColor.withOpacity(ringOpacity);
        canvas.drawCircle(Offset(distortionX, distortionY), ringSize, paint);
      }
    }
  }

  void _paintMarineSediment(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Floating marine sediment particles
    final random = math.Random(333);
    for (int i = 0; i < (20 * intensity).round(); i++) {
      final sedimentX = random.nextDouble() * size.width + _wave(0.01, i * 0.2) * 30 * intensity;
      final sedimentY = random.nextDouble() * size.height + _wave(0.015, i * 0.3) * 20 * intensity;

      final sedimentSize = (0.5 + random.nextDouble() * 1.5) * intensity;
      final sedimentOpacity = (0.2 + random.nextDouble() * 0.3) * intensity;

      paint.color = const Color(0xFF4A5568).withOpacity(sedimentOpacity);
      canvas.drawCircle(Offset(sedimentX, sedimentY), sedimentSize, paint);
    }
  }

  void _paintAbyssalGlow(Canvas canvas, Size size) {
    // Final atmospheric glow effects
    final rect = Offset.zero & size;

    // Deep sea ambient glow
    final abyssalGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.8),
        size.width * 0.6,
        [
          primaryColor.withOpacity(0.05 * intensity),
          _biolumBlue.withOpacity(0.03 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      );

    canvas.drawRect(rect, abyssalGlow);

    // Depth pressure effect
    final pressureGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.6),
        Offset(0, size.height),
        [
          Colors.transparent,
          _abyssal.withOpacity(0.3 * intensity),
        ],
        [0.0, 1.0],
      );

    canvas.drawRect(rect, pressureGradient);
  }

  @override
  bool shouldRepaint(covariant _EnhancedDeepSeaPainter oldDelegate) {
    return animationEnabled;
  }
}
