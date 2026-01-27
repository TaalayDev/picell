import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildCyberpunkTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.cyberpunk,
    isDark: true,
    // Primary colors - electric cyan
    primaryColor: const Color(0xFF00F5FF), // Electric cyan
    primaryVariant: const Color(0xFF00BFFF), // Deep sky blue
    onPrimary: Colors.black,
    // Secondary colors - neon magenta
    accentColor: const Color(0xFFFF073A), // Neon red/magenta
    onAccent: Colors.white,
    // Background colors - deep dark with tech undertones
    background: const Color(0xFF0A0A0A), // Almost black
    surface: const Color(0xFF1A1A1A), // Dark gray
    surfaceVariant: const Color(0xFF2A2A2A), // Lighter dark gray
    // Text colors - bright neon
    textPrimary: const Color(0xFF00F5FF), // Bright cyan text
    textSecondary: const Color(0xFF8BB8FF), // Light blue
    textDisabled: const Color(0xFF4A5568), // Dark gray
    // UI colors
    divider: const Color(0xFF2D3748),
    toolbarColor: const Color(0xFF1A1A1A),
    error: const Color(0xFFFF073A), // Bright red error
    success: const Color(0xFF39FF14), // Electric lime success
    warning: const Color(0xFFFFFF00), // Electric yellow warning
    // Grid colors
    gridLine: const Color(0xFF2D3748),
    gridBackground: const Color(0xFF1A1A1A),
    // Canvas colors
    canvasBackground: const Color(0xFF0A0A0A),
    selectionOutline: const Color(0xFF00F5FF), // Cyan selection
    selectionFill: const Color(0x3000F5FF),
    // Icon colors
    activeIcon: const Color(0xFF00F5FF), // Electric cyan for active
    inactiveIcon: const Color(0xFF8BB8FF), // Light blue for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF00F5FF),
        fontWeight: FontWeight.w700, // Extra bold for cyberpunk feel
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF00F5FF),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF00F5FF),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF8BB8FF),
      ),
    ),
    primaryFontWeight: FontWeight.w600, // Bold for tech aesthetic
  );
}

// Cyberpunk theme background with digital matrix effects
class CyberpunkBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CyberpunkBackground({
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

    final matrixAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/cyberpunk_background.webp',
            fit: BoxFit.cover,
            colorBlendMode: BlendMode.darken,
          ),
        ),
        CustomPaint(
          painter: _CyberpunkPainter(
            animation: matrixAnimation,
            primaryColor: theme.primaryColor,
            accentColor: theme.accentColor,
            intensity: intensity,
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }
}

class _CyberpunkPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _CyberpunkPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Simplified: Just a few subtle matrix streams
    final streamCount = math.max(1, (3 * intensity).round());
    for (int i = 0; i < streamCount; i++) {
      final streamX = (i / streamCount) * size.width;
      final charProgress = (animation * 0.2 + i * 0.3) % 1.2;
      final charY = charProgress * (size.height + 50) - 25;

      if (charY > -10 && charY < size.height + 10) {
        final opacity = math.max(0.0, (1.0 - charProgress) * 0.08) * intensity;
        paint.color = primaryColor.withOpacity(opacity);

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(streamX, charY),
            width: 2 * intensity,
            height: 8 * intensity,
          ),
          paint,
        );
      }
    }

    // Simple scanning line
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1 * intensity;
    final scanY = (animation * size.height * 0.3) % size.height;
    paint.color = primaryColor.withOpacity(0.05 * intensity);
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), paint);
  }

  @override
  bool shouldRepaint(covariant _CyberpunkPainter oldDelegate) {
    return animationEnabled;
  }
}
