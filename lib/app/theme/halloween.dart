import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

/// Halloween theme with spooky colors and eerie atmosphere
AppTheme buildHalloweenTheme() {
  // Spooky color palette
  const primaryOrange = Color(0xFFFF6B35); // Pumpkin orange
  const deepPurple = Color(0xFF6A4C93); // Dark purple
  const ghostWhite = Color(0xFFE8E8E8); // Ghost white
  const darkBg = Color(0xFF1A0F2E); // Very dark purple
  const surfaceDark = Color(0xFF2D1B3D); // Dark purple surface
  const toxicGreen = Color(0xFF39FF14); // Toxic/spooky green
  const bloodRed = Color(0xFF8B0000); // Dark blood red

  return AppTheme(
    type: ThemeType.halloween,
    isDark: true,
    primaryColor: primaryOrange,
    primaryVariant: deepPurple,
    onPrimary: darkBg,
    accentColor: toxicGreen,
    onAccent: darkBg,
    background: darkBg,
    surface: surfaceDark,
    surfaceVariant: Color.lerp(surfaceDark, Colors.black, 0.3)!,
    textPrimary: ghostWhite,
    textSecondary: Color.lerp(ghostWhite, primaryOrange, 0.3)!,
    textDisabled: Color.lerp(ghostWhite, Colors.black, 0.5)!,
    divider: deepPurple.withOpacity(0.3),
    toolbarColor: Color.lerp(surfaceDark, Colors.black, 0.2)!,
    error: bloodRed,
    success: toxicGreen,
    warning: primaryOrange,
    gridLine: deepPurple.withOpacity(0.4),
    gridBackground: Color.lerp(darkBg, surfaceDark, 0.3)!,
    canvasBackground: darkBg,
    selectionOutline: primaryOrange,
    selectionFill: primaryOrange.withOpacity(0.2),
    activeIcon: primaryOrange,
    inactiveIcon: Color.lerp(ghostWhite, deepPurple, 0.5)!,
    textTheme: GoogleFonts.creepsterTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ).apply(
        bodyColor: ghostWhite,
        displayColor: ghostWhite,
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

/// Animated Halloween background with floating ghosts, bats, and glowing pumpkins
class HalloweenBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const HalloweenBackground({
    super.key,
    required this.theme,
    required this.intensity,
    required this.enableAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 8),
    );

    final fastController = useAnimationController(
      duration: const Duration(seconds: 3),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
        fastController.repeat();
      } else {
        controller.stop();
        fastController.stop();
      }
      return null;
    }, [enableAnimation]);

    final slowAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    final fastAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(fastController),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/halloween_background.webp',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3 * intensity),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        // Fog/mist layer
        CustomPaint(
          painter: _FogPainter(
            animation: slowAnimation,
            color: theme.primaryVariant.withOpacity(0.1 * intensity),
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
        // Flying bats
        CustomPaint(
          painter: _BatPainter(
            animation: fastAnimation,
            color: Colors.black.withOpacity(0.6 * intensity),
            intensity: intensity,
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
        // Floating ghosts
        CustomPaint(
          painter: _GhostPainter(
            animation: slowAnimation,
            color: Colors.white.withOpacity(0.15 * intensity),
            intensity: intensity,
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
        // Glowing pumpkins
        CustomPaint(
          painter: _PumpkinGlowPainter(
            animation: fastAnimation,
            primaryColor: theme.primaryColor,
            accentColor: theme.accentColor,
            intensity: intensity,
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
        // Cobweb corners
        CustomPaint(
          painter: _CobwebPainter(
            color: Colors.white.withOpacity(0.08 * intensity),
            animationEnabled: enableAnimation,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }
}

/// Paints floating fog/mist effect
class _FogPainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool animationEnabled;

  _FogPainter({
    required this.animation,
    required this.color,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!animationEnabled) return; // Don't paint if animation is disabled

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final random = math.Random(123);

    for (int i = 0; i < 8; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = size.height * 0.2 + random.nextDouble() * size.height * 0.3;

      final offset = math.sin(animation * 2 * math.pi + i * 0.5) * 30;
      final x = baseX + offset;
      final y = baseY;

      final width = 100 + random.nextDouble() * 150;
      final height = 40 + random.nextDouble() * 60;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        const Radius.circular(30),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Paints floating ghosts
class _GhostPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double intensity;
  final bool animationEnabled;

  _GhostPainter({
    required this.animation,
    required this.color,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final random = math.Random(789);

    for (int i = 0; i < (5 * intensity).round(); i++) {
      final baseX = random.nextDouble() * size.width;
      final progress = (animation + i * 0.2) % 1.0;
      final y = size.height * progress;

      final floatOffset = math.sin(animation * 4 * math.pi + i) * 20;
      final x = baseX + floatOffset;

      final ghostSize = 25 + random.nextDouble() * 20;

      // Draw ghost shape (rounded top with wavy bottom)
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x, y - ghostSize * 0.6);
      path.quadraticBezierTo(
        x,
        y - ghostSize,
        x + ghostSize * 0.5,
        y - ghostSize,
      );
      path.quadraticBezierTo(
        x + ghostSize,
        y - ghostSize,
        x + ghostSize,
        y - ghostSize * 0.6,
      );
      path.lineTo(x + ghostSize, y);

      // Wavy bottom
      path.quadraticBezierTo(
        x + ghostSize * 0.75,
        y - ghostSize * 0.15,
        x + ghostSize * 0.5,
        y,
      );
      path.quadraticBezierTo(
        x + ghostSize * 0.25,
        y - ghostSize * 0.15,
        x,
        y,
      );

      canvas.drawPath(path, paint);

      // Ghost eyes
      final eyePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withOpacity(0.5);

      canvas.drawCircle(
        Offset(x + ghostSize * 0.3, y - ghostSize * 0.65),
        ghostSize * 0.08,
        eyePaint,
      );
      canvas.drawCircle(
        Offset(x + ghostSize * 0.7, y - ghostSize * 0.65),
        ghostSize * 0.08,
        eyePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GhostPainter oldDelegate) {
    return animationEnabled ||
        oldDelegate.animation != animation ||
        oldDelegate.animationEnabled != animationEnabled ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color;
  }
}

/// Paints flying bats
class _BatPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double intensity;
  final bool animationEnabled;

  _BatPainter({
    required this.animation,
    required this.color,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final random = math.Random(456);

    for (int i = 0; i < (6 * intensity).round(); i++) {
      final progress = (animation + i * 0.15) % 1.0;
      final x = size.width * progress;
      final baseY = random.nextDouble() * size.height * 0.5;
      final y = baseY + math.sin(animation * 6 * math.pi + i) * 40;

      final batSize = 12 + random.nextDouble() * 8;
      final wingFlap = math.sin(animation * 10 * math.pi + i) * 0.3 + 0.7;

      // Draw bat silhouette
      final path = Path();

      // Body
      path.addOval(Rect.fromCenter(
        center: Offset(x, y),
        width: batSize * 0.4,
        height: batSize * 0.3,
      ));

      // Left wing
      path.moveTo(x, y);
      path.quadraticBezierTo(
        x - batSize * 0.5 * wingFlap,
        y - batSize * 0.3,
        x - batSize * wingFlap,
        y,
      );
      path.quadraticBezierTo(
        x - batSize * 0.6 * wingFlap,
        y + batSize * 0.2,
        x,
        y,
      );

      // Right wing
      path.moveTo(x, y);
      path.quadraticBezierTo(
        x + batSize * 0.5 * wingFlap,
        y - batSize * 0.3,
        x + batSize * wingFlap,
        y,
      );
      path.quadraticBezierTo(
        x + batSize * 0.6 * wingFlap,
        y + batSize * 0.2,
        x,
        y,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BatPainter oldDelegate) {
    return animationEnabled ||
        oldDelegate.animation != animation ||
        oldDelegate.animationEnabled != animationEnabled ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color;
  }
}

/// Paints glowing pumpkin effects
class _PumpkinGlowPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _PumpkinGlowPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(321);

    for (int i = 0; i < (8 * intensity).round(); i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final pulse = math.sin(animation * 3 * math.pi + i * 0.7) * 0.3 + 0.7;
      final radius = (20 + random.nextDouble() * 40) * intensity * pulse;

      final gradient = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.15 * intensity),
          primaryColor.withOpacity(0.05 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Add green accent glows occasionally
      if (i % 3 == 0) {
        final accentGradient = RadialGradient(
          colors: [
            accentColor.withOpacity(0.1 * intensity),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        );

        final accentPaint = Paint()..shader = accentGradient.createShader(rect);
        canvas.drawCircle(Offset(x, y), radius * 0.6, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PumpkinGlowPainter oldDelegate) {
    return animationEnabled ||
        oldDelegate.animation != animation ||
        oldDelegate.animationEnabled != animationEnabled ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.intensity != intensity;
  }
}

/// Paints cobwebs in corners
class _CobwebPainter extends CustomPainter {
  final Color color;
  final bool animationEnabled;

  _CobwebPainter({required this.color, this.animationEnabled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 1.0;

    // Top-left cobweb
    _drawCobweb(canvas, const Offset(0, 0), 100, paint);

    // Top-right cobweb
    _drawCobweb(canvas, Offset(size.width, 0), 100, paint, flipX: true);

    // Bottom-left cobweb
    _drawCobweb(canvas, Offset(0, size.height), 80, paint, flipY: true);

    // Bottom-right cobweb
    _drawCobweb(
      canvas,
      Offset(size.width, size.height),
      80,
      paint,
      flipX: true,
      flipY: true,
    );
  }

  void _drawCobweb(
    Canvas canvas,
    Offset corner,
    double size,
    Paint paint, {
    bool flipX = false,
    bool flipY = false,
  }) {
    final xDir = flipX ? -1 : 1;
    final yDir = flipY ? -1 : 1;

    // Radial threads
    for (int i = 0; i < 5; i++) {
      final angle = (i / 4) * math.pi / 2;
      final endX = corner.dx + math.cos(angle) * size * xDir;
      final endY = corner.dy + math.sin(angle) * size * yDir;
      canvas.drawLine(corner, Offset(endX, endY), paint);
    }

    // Concentric arcs
    for (int i = 1; i <= 3; i++) {
      final arcSize = size * i / 3;
      final rect = Rect.fromCenter(
        center: corner,
        width: arcSize * 2,
        height: arcSize * 2,
      );

      final startAngle = flipX ? (flipY ? math.pi : math.pi * 1.5) : (flipY ? math.pi * 0.5 : 0);
      canvas.drawArc(rect, startAngle.toDouble(), math.pi / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CobwebPainter oldDelegate) {
    return animationEnabled;
  }
}
