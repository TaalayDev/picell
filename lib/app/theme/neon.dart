import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildNeonTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.neon,
    isDark: true,
    primaryColor: const Color(0xFF00FF9C),
    primaryVariant: const Color(0xFF00CC7D),
    onPrimary: Colors.black,
    accentColor: const Color(0xFFFF00FF),
    onAccent: Colors.white,
    background: const Color(0xFF0F1020),
    surface: const Color(0xFF191B36),
    surfaceVariant: const Color(0xFF242757),
    textPrimary: const Color(0xFFCDFFF9),
    textSecondary: const Color(0xFF9BBDB7),
    textDisabled: const Color(0xFF5C7D78),
    divider: const Color(0xFF242757),
    toolbarColor: const Color(0xFF191B36),
    error: const Color(0xFFFF004C),
    success: const Color(0xFF00FF9C),
    warning: const Color(0xFFFFDF00),
    gridLine: const Color(0xFF242757),
    gridBackground: const Color(0xFF191B36),
    canvasBackground: const Color(0xFF0F1020),
    selectionOutline: const Color(0xFF00FF9C),
    selectionFill: const Color(0x3000FF9C),
    activeIcon: const Color(0xFF00FF9C),
    inactiveIcon: const Color(0xFF9BBDB7),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFCDFFF9),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFCDFFF9),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFCDFFF9),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF9BBDB7),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Neon theme background with electric effects
class NeonBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const NeonBackground({
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

    final pulseAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    return CustomPaint(
      painter: _NeonPainter(
        animation: pulseAnimation,
        primaryColor: theme.primaryColor,
        accentColor: theme.accentColor,
        intensity: intensity,
        animationEnabled: enableAnimation,
      ),
      size: Size.infinite,
    );
  }
}

class _NeonPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _NeonPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Draw electric grid lines
    final gridSpacing = 100.0 * intensity;
    final pulseIntensity = (math.sin(animation * 2 * math.pi) * 0.5 + 0.5) * intensity;

    paint.strokeWidth = 1;
    paint.color = primaryColor.withOpacity(0.1 * pulseIntensity);

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw pulsing nodes at intersections
    paint.style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        final nodeIntensity = math.sin(animation * 4 * math.pi + x * 0.01 + y * 0.01) * 0.5 + 0.5;
        paint.color = Color.lerp(
          primaryColor.withOpacity(0.05),
          accentColor.withOpacity(0.1),
          nodeIntensity,
        )!;

        canvas.drawCircle(
          Offset(x, y),
          3 * intensity * nodeIntensity,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeonPainter oldDelegate) {
    return animationEnabled;
  }
}
