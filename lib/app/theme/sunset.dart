import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildSunsetTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.sunset,
    isDark: false,
    primaryColor: const Color(0xFFFF6F00),
    primaryVariant: const Color(0xFFE65100),
    onPrimary: Colors.white,
    accentColor: const Color(0xFF304FFE),
    onAccent: Colors.white,
    background: const Color(0xFFFFF9F0),
    surface: Colors.white,
    surfaceVariant: const Color(0xFFFFEED3),
    textPrimary: const Color(0xFF33261D),
    textSecondary: const Color(0xFF7A6058),
    textDisabled: const Color(0xFFBBA79E),
    divider: const Color(0xFFFFD8B0),
    toolbarColor: const Color(0xFFFFEED3),
    error: const Color(0xFFB71C1C),
    success: const Color(0xFF388E3C),
    warning: const Color(0xFFFFB300),
    gridLine: const Color(0xFFFFD8B0),
    gridBackground: Colors.white,
    canvasBackground: Colors.white,
    selectionOutline: const Color(0xFFFF6F00),
    selectionFill: const Color(0x30FF6F00),
    activeIcon: const Color(0xFFFF6F00),
    inactiveIcon: const Color(0xFF7A6058),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF33261D),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF33261D),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF33261D),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF7A6058),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Sunset theme background with warm gradient shifts
class SunsetBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const SunsetBackground({
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
        controller.forward();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    final sunAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    return CustomPaint(
      painter: _SunsetPainter(
        animation: sunAnimation,
        primaryColor: theme.primaryColor,
        accentColor: theme.accentColor,
        intensity: intensity,
        animationEnabled: enableAnimation,
      ),
      size: Size.infinite,
    );
  }
}

class _SunsetPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _SunsetPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw sun rays
    final sunCenter = Offset(size.width * 0.8, size.height * 0.3);
    final rayCount = (12 * intensity).round();

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + animation * math.pi / 4;
      final length = (50 + math.sin(animation * 2 * math.pi + i) * 20) * intensity;

      final startOffset = Offset(
        sunCenter.dx + math.cos(angle) * 20,
        sunCenter.dy + math.sin(angle) * 20,
      );
      final endOffset = Offset(
        sunCenter.dx + math.cos(angle) * length,
        sunCenter.dy + math.sin(angle) * length,
      );

      paint.color = primaryColor.withOpacity(0.05 * intensity);
      paint.strokeWidth = 2 * intensity;
      paint.style = PaintingStyle.stroke;

      canvas.drawLine(startOffset, endOffset, paint);
    }

    // Draw warm glow circles
    for (int i = 0; i < 3; i++) {
      final radius = (30 + i * 20 + math.sin(animation * 2 * math.pi) * 10) * intensity;
      paint.style = PaintingStyle.fill;
      paint.color = Color.lerp(
        primaryColor.withOpacity(0.02),
        accentColor.withOpacity(0.01),
        i / 2.0,
      )!;

      canvas.drawCircle(sunCenter, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunsetPainter oldDelegate) {
    return animationEnabled;
  }
}
