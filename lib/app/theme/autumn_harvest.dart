import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildAutumnHarvestTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.autumnHarvest,
    isDark: false,
    // Primary colors - warm amber/pumpkin
    primaryColor: const Color(0xFFE67E22), // Warm pumpkin orange
    primaryVariant: const Color(0xFFD35400), // Deeper burnt orange
    onPrimary: Colors.white,
    // Secondary colors - deep burgundy
    accentColor: const Color(0xFF8B4513), // Saddle brown/burgundy
    onAccent: Colors.white,
    // Background colors - warm and cozy
    background: const Color(0xFFFDF6E3), // Warm cream/seashell
    surface: const Color(0xFFFFFFFF), // Pure white
    surfaceVariant: const Color(0xFFF5E6D3), // Light peach/cream
    // Text colors - deep warm browns
    textPrimary: const Color(0xFF3E2723), // Dark brown
    textSecondary: const Color(0xFF5D4037), // Medium brown
    textDisabled: const Color(0xFFA1887F), // Light brown
    // UI colors
    divider: const Color(0xFFD7CCC8), // Light brown
    toolbarColor: const Color(0xFFF5E6D3),
    error: const Color(0xFFD32F2F), // Red for contrast
    success: const Color(0xFF388E3C), // Forest green
    warning: const Color(0xFFFF9800), // Amber orange
    // Grid colors
    gridLine: const Color(0xFFD7CCC8),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFFE67E22), // Match primary
    selectionFill: const Color(0x30E67E22),
    // Icon colors
    activeIcon: const Color(0xFFE67E22), // Warm orange for active
    inactiveIcon: const Color(0xFF5D4037), // Brown for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF3E2723),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF3E2723),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF3E2723),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF5D4037),
      ),
    ),
    primaryFontWeight: FontWeight.w500, // Comfortable reading weight
  );
}

// Autumn Harvest theme background with falling leaves and warm atmosphere
class AutumnHarvestBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const AutumnHarvestBackground({
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
        controller.value = 0.0;
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(Tween<double>(begin: 0, end: 1).animate(controller));

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(controller),
              child: Image.asset(
                'assets/images/autumn_leaves_background.webp',
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _AutumnHarvestPainter(
              t: t,
              primaryColor: theme.primaryColor,
              accentColor: theme.accentColor,
              intensity: intensity.clamp(0.3, 2.0),
              animationEnabled: enableAnimation,
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _AutumnHarvestPainter(
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
        ),
      ],
    );
  }
}

class _AutumnHarvestPainter extends CustomPainter {
  final double t;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _AutumnHarvestPainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  // Animation helpers for smooth looping
  double get _phase => 2 * math.pi * t;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant _AutumnHarvestPainter oldDelegate) {
    return animationEnabled;
  }
}
