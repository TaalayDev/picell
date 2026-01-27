import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildArcticAuroraTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.arcticAurora,
    isDark: false,
    // Primary colors - aurora green
    primaryColor: const Color(0xFF00E5A0), // Bright aurora green
    primaryVariant: const Color(0xFF00B87C), // Deeper green
    onPrimary: Colors.white,
    // Secondary colors - electric blue
    accentColor: const Color(0xFF00D4FF), // Electric arctic blue
    onAccent: Colors.white,
    // Background colors - pristine arctic white
    background: const Color(0xFFF8FFFE), // Pure arctic white
    surface: const Color(0xFFFFFFFF), // Snow white
    surfaceVariant: const Color(0xFFF0FAFA), // Slight blue tint
    // Text colors - deep arctic blue
    textPrimary: const Color(0xFF003D5C), // Deep arctic blue
    textSecondary: const Color(0xFF2D5A7A), // Medium arctic blue
    textDisabled: const Color(0xFF7FB3CC), // Light arctic blue
    // UI colors
    divider: const Color(0xFFE0F4F7), // Very light arctic blue
    toolbarColor: const Color(0xFFF0FAFA),
    error: const Color(0xFFE74C3C), // Bright red for contrast
    success: const Color(0xFF27AE60), // Fresh green
    warning: const Color(0xFFF39C12), // Warm orange
    // Grid colors
    gridLine: const Color(0xFFE0F4F7),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFF00E5A0), // Match primary
    selectionFill: const Color(0x3000E5A0),
    // Icon colors
    activeIcon: const Color(0xFF00E5A0), // Aurora green for active
    inactiveIcon: const Color(0xFF2D5A7A), // Arctic blue for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF003D5C),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF003D5C),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF003D5C),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF2D5A7A),
      ),
    ),
    primaryFontWeight: FontWeight.w500, // Clean, crisp weight
  );
}

class ArcticAuroraBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const ArcticAuroraBackground({
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
        controller.repeat(reverse: true);
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    final auroraAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
    );

    return CustomPaint(
      painter: _ArcticAuroraPainter(
        animation: auroraAnimation,
        primaryColor: theme.primaryColor,
        accentColor: theme.accentColor,
        intensity: intensity,
        animationEnabled: enableAnimation,
      ),
      size: Size.infinite,
    );
  }
}

class _ArcticAuroraPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _ArcticAuroraPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(147); // Fixed seed for consistent aurora

    // Draw aurora waves
    for (int i = 0; i < 4; i++) {
      final path = Path();
      final waveHeight = (30 + i * 10) * intensity;
      final baseY = size.height * (0.15 + i * 0.08);
      final phase = animation * 2 * math.pi + i * math.pi / 2;

      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 8) {
        final primaryWave = math.sin(x / 120 + phase) * waveHeight;
        final secondaryWave = math.sin(x / 80 + phase * 1.3) * waveHeight * 0.5;
        final y = baseY + primaryWave + secondaryWave;
        path.lineTo(x, y);
      }

      // Create flowing aurora effect
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final auroraIntensity = math.sin(animation * 3 * math.pi + i * 0.7) * 0.3 + 0.7;
      paint.color = Color.lerp(
        primaryColor.withOpacity(0.08 * auroraIntensity * intensity),
        accentColor.withOpacity(0.06 * auroraIntensity * intensity),
        i / 3.0,
      )!;

      canvas.drawPath(path, paint);
    }

    // Draw aurora light beams
    for (int i = 0; i < (8 * intensity).round(); i++) {
      final beamX = (i / 8) * size.width + math.sin(animation * 2 * math.pi + i) * 30 * intensity;
      final beamHeight = size.height * (0.4 + math.cos(animation * math.pi + i * 0.5) * 0.2);

      final beamIntensity = math.sin(animation * 4 * math.pi + i * 0.8) * 0.5 + 0.5;

      if (beamIntensity > 0.3) {
        paint.color = Color.lerp(
          primaryColor.withOpacity(0.05 * beamIntensity * intensity),
          accentColor.withOpacity(0.04 * beamIntensity * intensity),
          math.sin(animation * math.pi + i) * 0.5 + 0.5,
        )!;

        canvas.drawRect(
          Rect.fromLTWH(beamX - 2 * intensity, 0, 4 * intensity, beamHeight),
          paint,
        );
      }
    }

    // Draw ice crystals floating
    for (int i = 0; i < (15 * intensity).round(); i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final floatX = baseX + math.sin(animation * 1.5 * math.pi + i * 0.4) * 12 * intensity;
      final floatY = baseY + math.cos(animation * math.pi + i * 0.6) * 8 * intensity;

      final crystalSize = (2 + random.nextDouble() * 4) * intensity;
      final sparkleIntensity = math.sin(animation * 5 * math.pi + i * 0.9) * 0.5 + 0.5;

      if (sparkleIntensity > 0.6) {
        paint.color = Color.lerp(
          primaryColor.withOpacity(0.4 * sparkleIntensity),
          accentColor.withOpacity(0.5 * sparkleIntensity),
          sparkleIntensity,
        )!;

        canvas.drawCircle(Offset(floatX, floatY), crystalSize * sparkleIntensity, paint);
      }
    }

    // Draw aurora reflections on "ice"
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1 * intensity;

    for (int i = 0; i < 3; i++) {
      final reflectionY = size.height * (0.7 + i * 0.1);
      final path = Path();

      path.moveTo(0, reflectionY);
      for (double x = 0; x <= size.width; x += 15) {
        final waveOffset = math.sin((x / 60) + animation * 3 * math.pi + i) * 4 * intensity;
        path.lineTo(x, reflectionY + waveOffset);
      }

      final reflectionIntensity = math.sin(animation * 2 * math.pi + i * 1.1) * 0.3 + 0.4;
      paint.color = primaryColor.withOpacity(0.03 * reflectionIntensity * intensity);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => animationEnabled;
}
