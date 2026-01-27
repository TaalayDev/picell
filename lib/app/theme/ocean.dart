import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildOceanTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.ocean,
    isDark: false,
    primaryColor: const Color(0xFF0288D1),
    primaryVariant: const Color(0xFF006DB3),
    onPrimary: Colors.white,
    accentColor: const Color(0xFFFF6D00),
    onAccent: Colors.white,
    background: const Color(0xFFECF8FD),
    surface: Colors.white,
    surfaceVariant: const Color(0xFFD4F0FB),
    textPrimary: const Color(0xFF004466),
    textSecondary: const Color(0xFF4D748A),
    textDisabled: const Color(0xFF9EBFD1),
    divider: const Color(0xFFB3E3F5),
    toolbarColor: const Color(0xFFD4F0FB),
    error: const Color(0xFFB71C1C),
    success: const Color(0xFF2E7D32),
    warning: const Color(0xFFF9A825),
    gridLine: const Color(0xFFB3E3F5),
    gridBackground: Colors.white,
    canvasBackground: Colors.white,
    selectionOutline: const Color(0xFF0288D1),
    selectionFill: const Color(0x300288D1),
    activeIcon: const Color(0xFF0288D1),
    inactiveIcon: const Color(0xFF4D748A),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF004466),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF004466),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF004466),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF4D748A),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Ocean theme background with wave effects
class OceanBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const OceanBackground({
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
      }
      return null;
    }, [enableAnimation]);

    final waveAnimation = useAnimation(
      Tween<double>(begin: 0, end: 2 * math.pi).animate(controller),
    );

    return CustomPaint(
      painter: _OceanPainter(
        animation: waveAnimation,
        primaryColor: theme.primaryColor,
        accentColor: theme.accentColor,
        intensity: intensity,
        animationEnabled: enableAnimation,
      ),
      size: Size.infinite,
    );
  }
}

class _OceanPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _OceanPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw wave layers
    for (int i = 0; i < 4; i++) {
      final path = Path();
      final waveHeight = (15 + i * 5) * intensity;
      final baseY = size.height - (50 + i * 20) * intensity;
      final phase = animation + i * math.pi / 4;

      path.moveTo(0, baseY);

      for (double x = 0; x <= size.width; x += 10) {
        final y = baseY + math.sin(x / 100 + phase) * waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.color = Color.lerp(
        primaryColor.withOpacity(0.03 + i * 0.01),
        accentColor.withOpacity(0.02 + i * 0.01),
        math.sin(phase) * 0.5 + 0.5,
      )!;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => animationEnabled;
}
