import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'flagship/studio_dark_flagship.dart';
import 'theme.dart';

// ============================================================================
// STUDIO DARK THEME BUILDER
// ============================================================================
//
// A flat, minimal, pro-design-tool aesthetic — hairline borders, a single
// bold signal-blue accent, dot-grid canvas texture, and monospace labels
// for precise metadata (dimensions, timestamps). Restrained by design.

AppTheme buildStudioDarkTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme();
  final monoTextTheme = GoogleFonts.jetBrainsMonoTextTheme();

  const primary = Color(0xFF2F80ED);
  const textPrimary = Color(0xFFEDEDF0);
  const textSecondary = Color(0xFF8B8B94);

  return AppTheme(
    type: ThemeType.studioDark,
    isDark: true,

    // Primary — single bold signal-blue accent
    primaryColor: primary,
    primaryVariant: const Color(0xFF1E63C4),
    onPrimary: Colors.white,

    // Secondary — a lighter tint of the same hue, kept restrained
    accentColor: const Color(0xFF7CB3FF),
    onAccent: const Color(0xFF0B0B0D),

    // Background — true neutral graphite, no color tint
    background: const Color(0xFF0B0B0D),
    surface: const Color(0xFF131316),
    surfaceVariant: const Color(0xFF1C1C20),

    // Text
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textDisabled: const Color(0xFF4A4A52),

    // UI colors
    divider: const Color(0xFF232327),
    toolbarColor: const Color(0xFF0F0F12),
    error: const Color(0xFFF2495C),
    success: const Color(0xFF34D399),
    warning: const Color(0xFFFBBF24),

    // Grid colors
    gridLine: const Color(0xFF1E1E22),
    gridBackground: const Color(0xFF131316),

    // Canvas colors
    canvasBackground: const Color(0xFF0B0B0D),
    selectionOutline: primary,
    selectionFill: const Color(0x332F80ED),

    // Icon colors
    activeIcon: primary,
    inactiveIcon: textSecondary,

    // Typography — Inter for body, JetBrains Mono for titles/labels
    textTheme: baseTextTheme.copyWith(
      displayLarge: monoTextTheme.displayLarge!.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: monoTextTheme.displayMedium!.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: monoTextTheme.titleLarge!.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: monoTextTheme.titleMedium!.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(color: textPrimary),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(color: textSecondary),
      labelLarge: monoTextTheme.labelLarge!.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    primaryFontWeight: FontWeight.w600,
    geometry: AppThemeGeometry.studioDark,
    flagship: buildStudioDarkFlagshipConfig(),
  );
}

// ============================================================================
// STUDIO DARK ANIMATED BACKGROUND
// ============================================================================

class StudioDarkBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const StudioDarkBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 18),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(controller);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _StudioDarkPainter(
          progress: t,
          primaryColor: theme.primaryColor,
          backgroundColor: theme.background,
          surfaceColor: theme.surface,
          intensity: intensity.clamp(0.0, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _StudioDarkPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final double intensity;
  final bool animationEnabled;

  const _StudioDarkPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBase(canvas, size);
    _paintDotGrid(canvas, size);
    _paintSheen(canvas, size);
    _paintReticleCorners(canvas, size);
    _paintVignette(canvas, size);
  }

  void _paintBase(Canvas canvas, Size size) {
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [backgroundColor, Color.lerp(backgroundColor, surfaceColor, 0.35)!],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);
  }

  void _paintDotGrid(Canvas canvas, Size size) {
    const spacing = 28.0;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035 * intensity);

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  void _paintSheen(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    final travel = size.width + size.height * 0.6;
    final offset = progress * travel * 1.4 - size.height * 0.4;
    final start = Offset(offset, 0);
    final end = Offset(offset - size.height * 0.6, size.height);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        start,
        end,
        [
          Colors.transparent,
          primaryColor.withValues(alpha: 0.05 * intensity),
          Colors.transparent,
        ],
        const [0.0, 0.5, 1.0],
      );

    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintReticleCorners(Canvas canvas, Size size) {
    final pulse = math.sin(progress * 2 * math.pi) * 0.5 + 0.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = primaryColor.withValues(alpha: (0.16 + pulse * 0.08) * intensity);

    const len = 18.0;
    const inset = 22.0;

    void bracket(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin + Offset(dx * len, 0), paint);
      canvas.drawLine(origin, origin + Offset(0, dy * len), paint);
    }

    bracket(Offset(inset, inset), 1, 1);
    bracket(Offset(size.width - inset, inset), -1, 1);
    bracket(Offset(inset, size.height - inset), 1, -1);
    bracket(Offset(size.width - inset, size.height - inset), -1, -1);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final vignette = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.75,
      [Colors.transparent, Colors.black.withValues(alpha: 0.22 * intensity)],
      const [0.6, 1.0],
    );

    canvas.drawRect(Offset.zero & size, Paint()..shader = vignette);
  }

  @override
  bool shouldRepaint(covariant _StudioDarkPainter oldDelegate) => animationEnabled;
}
