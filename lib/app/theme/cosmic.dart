import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildCosmicTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.cosmic,
    isDark: true,
    // Primary colors - vibrant orange like in the image
    primaryColor: const Color(0xFFFF6B35), // Bright orange from the UI
    primaryVariant: const Color(0xFFE55A2B),
    onPrimary: Colors.white,
    // Secondary colors - cyan accent
    accentColor: const Color(0xFF00D9FF), // Bright cyan
    onAccent: Colors.black,
    // Background colors - deep space purple/blue gradient feel
    background: const Color(0xFF1A1B3A), // Deep cosmic purple
    surface: const Color(0xFF252653), // Lighter cosmic purple for surfaces
    surfaceVariant: const Color(0xFF2D2E5F), // Even lighter for variants
    // Text colors - bright and cosmic
    textPrimary: const Color(0xFFE8E9FF), // Almost white with purple tint
    textSecondary: const Color(0xFFB8BADF), // Muted purple-white
    textDisabled: const Color(0xFF7A7BA0), // Darker purple-gray
    // UI colors
    divider: const Color(0xFF3A3C6B),
    toolbarColor: const Color(0xFF252653),
    error: const Color(0xFFFF4757), // Bright red
    success: const Color(0xFF5CE65C), // Bright green
    warning: const Color(0xFFFFA726), // Bright amber
    // Grid colors
    gridLine: const Color(0xFF3A3C6B),
    gridBackground: const Color(0xFF252653),
    // Canvas colors
    canvasBackground: const Color(0xFF1A1B3A),
    selectionOutline: const Color(0xFF00D9FF), // Cyan selection
    selectionFill: const Color(0x3000D9FF),
    // Icon colors
    activeIcon: const Color(0xFFFF6B35), // Orange for active
    inactiveIcon: const Color(0xFFB8BADF), // Muted for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE8E9FF),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE8E9FF),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE8E9FF),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB8BADF),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Cosmic theme background with stars and nebula effects
class CosmicBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CosmicBackground({
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

    final rotationAnimation = useAnimation(
      Tween<double>(begin: 0, end: 2 * math.pi).animate(controller),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.05).animate(controller),
              child: Image.asset(
                'assets/images/cosmic_background.webp',
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
        ),
        CustomPaint(
          painter: _CosmicPainter(
            animation: rotationAnimation,
            primaryColor: theme.primaryColor,
            accentColor: theme.accentColor,
            intensity: intensity.clamp(0.0, 2.0),
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }
}

class _CosmicPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _CosmicPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); // Fixed seed for consistent stars

    // Draw stars
    for (int i = 0; i < (50 * intensity).round(); i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = (random.nextDouble() * 2 + 0.5) * intensity;

      paint.color = Color.lerp(
        primaryColor.withOpacity(0.3),
        accentColor.withOpacity(0.5),
        math.sin(animation + i * 0.1) * 0.5 + 0.5,
      )!;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw floating nebula-like shapes
    for (int i = 0; i < 3; i++) {
      final centerX = size.width * (0.2 + i * 0.3);
      final centerY = size.height * (0.3 + math.sin(animation + i) * 0.2);

      paint.color = Color.lerp(
        primaryColor.withOpacity(0.05),
        accentColor.withOpacity(0.03),
        math.cos(animation + i * 0.5) * 0.5 + 0.5,
      )!;

      canvas.drawCircle(
        Offset(centerX, centerY),
        (30 + math.sin(animation + i) * 10) * intensity,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter oldDelegate) {
    return animationEnabled;
  }
}
