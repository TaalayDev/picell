import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildMonochromeTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.monochrome,
    isDark: true,
    primaryColor: const Color(0xFFBBBBBB),
    primaryVariant: const Color(0xFF999999),
    onPrimary: Colors.black,
    accentColor: Colors.white,
    onAccent: Colors.black,
    background: const Color(0xFF121212),
    surface: const Color(0xFF212121),
    surfaceVariant: const Color(0xFF292929),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFFBBBBBB),
    textDisabled: const Color(0xFF777777),
    divider: const Color(0xFF3D3D3D),
    toolbarColor: const Color(0xFF292929),
    error: const Color(0xFFE0E0E0),
    success: const Color(0xFFBBBBBB),
    warning: const Color(0xFF999999),
    gridLine: const Color(0xFF3D3D3D),
    gridBackground: const Color(0xFF212121),
    canvasBackground: const Color(0xFF121212),
    selectionOutline: Colors.white,
    selectionFill: const Color(0x50FFFFFF),
    activeIcon: Colors.white,
    inactiveIcon: const Color(0xFFBBBBBB),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: Colors.white,
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFBBBBBB),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Monochrome theme background with minimal geometric patterns
class MonochromeBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const MonochromeBackground({
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

    final rotationAnimation = useAnimation(
      Tween<double>(begin: 0, end: 2 * math.pi).animate(controller),
    );

    return CustomPaint(
      painter: _MonochromePainter(
        animation: rotationAnimation,
        primaryColor: theme.primaryColor,
        intensity: intensity,
        animationEnabled: enableAnimation,
      ),
      size: Size.infinite,
    );
  }
}

class _MonochromePainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final double intensity;
  final bool animationEnabled;

  _MonochromePainter({
    required this.animation,
    required this.primaryColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * intensity;

    // Draw rotating geometric shapes
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.3;

    for (int i = 0; i < 3; i++) {
      final shapeRadius = radius * (0.3 + i * 0.2);
      final sides = 3 + i * 2;
      final rotation = animation * (i.isEven ? 1 : -1) + i * math.pi / 6;

      paint.color = primaryColor.withOpacity(0.05 * intensity * (1 - i * 0.2));

      final path = Path();
      for (int j = 0; j < sides; j++) {
        final angle = (j / sides) * 2 * math.pi + rotation;
        final x = center.dx + math.cos(angle) * shapeRadius;
        final y = center.dy + math.sin(angle) * shapeRadius;

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonochromePainter oldDelegate) {
    return animationEnabled;
  }
}
