import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// TOXIC WASTE THEME BUILDER
// ============================================================================

AppTheme buildToxicWasteTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.toxicWaste,
    isDark: true,
    // Primary colors - radioactive green
    primaryColor: const Color(0xFF39FF14), // Electric lime/radioactive green
    primaryVariant: const Color(0xFF32CD32), // Lime green
    onPrimary: Colors.black,
    // Secondary colors - toxic yellow
    accentColor: const Color(0xFFCCFF00), // Bright toxic yellow
    onAccent: Colors.black,
    // Background colors - dark industrial/chemical
    background: const Color(0xFF0F1419), // Very dark green-gray
    surface: const Color(0xFF1A2520), // Dark toxic green
    surfaceVariant: const Color(0xFF263529), // Slightly lighter toxic
    // Text colors - bright for contrast
    textPrimary: const Color(0xFFE8FFE8), // Very light green
    textSecondary: const Color(0xFFB8FFB8), // Light toxic green
    textDisabled: const Color(0xFF6B8E6B), // Muted green
    // UI colors
    divider: const Color(0xFF3A4F3A),
    toolbarColor: const Color(0xFF1A2520),
    error: const Color(0xFFFF4757), // Bright red warning
    success: const Color(0xFF39FF14), // Match primary for success
    warning: const Color(0xFFFFD700), // Bright gold warning
    // Grid colors
    gridLine: const Color(0xFF3A4F3A),
    gridBackground: const Color(0xFF1A2520),
    // Canvas colors
    canvasBackground: const Color(0xFF0F1419),
    selectionOutline: const Color(0xFF39FF14), // Radioactive green
    selectionFill: const Color(0x3039FF14),
    // Icon colors
    activeIcon: const Color(0xFF39FF14), // Radioactive green for active
    inactiveIcon: const Color(0xFFB8FFB8), // Light green for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE8FFE8),
        fontWeight: FontWeight.w700, // Bold for industrial feel
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE8FFE8),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE8FFE8),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB8FFB8),
      ),
    ),
    primaryFontWeight: FontWeight.w600, // Bold for toxic aesthetic
  );
}

// ============================================================================
// TOXIC WASTE ANIMATED BACKGROUND
// ============================================================================

class ToxicWasteBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const ToxicWasteBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ticker controller
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    // 2. State for infinite animation
    final toxicState = useMemoized(() => _ToxicState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnhancedToxicWastePainter(
          repaint: controller,
          state: toxicState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for physics and objects
class _ToxicState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Bubble>? bubbles;
  List<_Drip>? drips;
  List<_HazardParticle>? particles;
}

class _Bubble {
  double x;
  double y;
  double speed;
  double size;
  double wobblePhase;
  double wobbleSpeed;

  _Bubble({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.wobblePhase,
    required this.wobbleSpeed,
  });
}

class _Drip {
  double x;
  double y; // Length/Progress
  double speed;
  double maxLength;
  double delay; // Time until drip starts

  _Drip({
    required this.x,
    required this.y,
    required this.speed,
    required this.maxLength,
    required this.delay,
  });
}

class _HazardParticle {
  double x;
  double y;
  double rotation;
  double rotSpeed;
  double dx;
  double dy;
  double size;
  bool isSymbol; // true = hazard symbol, false = dust

  _HazardParticle({
    required this.x,
    required this.y,
    required this.rotation,
    required this.rotSpeed,
    required this.dx,
    required this.dy,
    required this.size,
    required this.isSymbol,
  });
}

class _EnhancedToxicWastePainter extends CustomPainter {
  final _ToxicState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  final math.Random _rng = math.Random(666);

  _EnhancedToxicWastePainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Time accumulation
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialization
    if (state.bubbles == null) _initWorld(size);

    _paintBackground(canvas, size);
    _paintSludge(canvas, size);
    _updateAndPaintBubbles(canvas, size, dt);
    _updateAndPaintDrips(canvas, size, dt);
    _updateAndPaintParticles(canvas, size, dt);
    _paintVignette(canvas, size);
  }

  void _initWorld(Size size) {
    state.bubbles = [];
    state.drips = [];
    state.particles = [];
    final rng = math.Random(666);

    // Init Rising Bubbles
    for (int i = 0; i < 20; i++) {
      state.bubbles!.add(_Bubble(
        x: rng.nextDouble() * size.width,
        y: size.height + rng.nextDouble() * 200, // Start below
        speed: 20 + rng.nextDouble() * 40,
        size: 5 + rng.nextDouble() * 15,
        wobblePhase: rng.nextDouble() * math.pi * 2,
        wobbleSpeed: 2 + rng.nextDouble() * 4,
      ));
    }

    // Init Ceiling Drips
    for (int i = 0; i < 8; i++) {
      state.drips!.add(_Drip(
        x: (i / 8) * size.width + rng.nextDouble() * 40,
        y: 0,
        speed: 50 + rng.nextDouble() * 50,
        maxLength: 50 + rng.nextDouble() * 150,
        delay: rng.nextDouble() * 5,
      ));
    }

    // Init Particles/Symbols
    for (int i = 0; i < 15; i++) {
      state.particles!.add(_HazardParticle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        rotation: rng.nextDouble() * math.pi * 2,
        rotSpeed: (rng.nextDouble() - 0.5) * 1.0,
        dx: (rng.nextDouble() - 0.5) * 20,
        dy: (rng.nextDouble() - 0.5) * 20,
        size: 5 + rng.nextDouble() * 10,
        isSymbol: rng.nextDouble() > 0.7, // 30% chance for symbol
      ));
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Dark industrial gradient
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [
        const Color(0xFF0A0F0A),
        const Color(0xFF141F14),
        const Color(0xFF0F2010),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  void _paintSludge(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.7),
        Offset(0, size.height),
        [
          primaryColor.withOpacity(0.3 * intensity),
          primaryColor.withOpacity(0.6 * intensity),
        ],
        [0.0, 1.0], // Explicit stops to fix error
      );

    final path = Path();
    final liquidLevel = size.height * 0.85;

    path.moveTo(0, size.height);
    path.lineTo(0, liquidLevel);

    // Layered waves
    for (double x = 0; x <= size.width; x += 10) {
      final y1 = math.sin(x * 0.01 + state.time * 1.5) * 10;
      final y2 = math.sin(x * 0.03 - state.time * 2.0) * 5;
      path.lineTo(x, liquidLevel + y1 + y2);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Top "scum" line
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * intensity
      ..color = accentColor.withOpacity(0.6 * intensity);

    canvas.drawPath(path, borderPaint);
  }

  void _updateAndPaintBubbles(Canvas canvas, Size size, double dt) {
    if (state.bubbles == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var bubble in state.bubbles!) {
      // Physics
      bubble.y -= bubble.speed * dt * intensity;
      bubble.wobblePhase += bubble.wobbleSpeed * dt;
      final wobbleX = math.sin(bubble.wobblePhase) * 5 * intensity;

      // Reset
      if (bubble.y < -bubble.size * 2) {
        bubble.y = size.height + bubble.size + _rng.nextDouble() * 100;
        bubble.x = _rng.nextDouble() * size.width;
      }

      // Draw
      final bx = bubble.x + wobbleX;
      final by = bubble.y;

      // Bubble body
      paint.color = primaryColor.withOpacity(0.3 * intensity);
      canvas.drawCircle(Offset(bx, by), bubble.size * intensity, paint);

      // Highlight
      paint.color = Colors.white.withOpacity(0.4 * intensity);
      canvas.drawCircle(Offset(bx - bubble.size * 0.3, by - bubble.size * 0.3), bubble.size * 0.25 * intensity, paint);

      // Toxic outline
      paint.color = accentColor.withOpacity(0.5 * intensity);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.0 * intensity;
      canvas.drawCircle(Offset(bx, by), bubble.size * intensity, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  void _updateAndPaintDrips(Canvas canvas, Size size, double dt) {
    if (state.drips == null) return;

    final paint = Paint()
      ..color = primaryColor.withOpacity(0.7 * intensity)
      ..style = PaintingStyle.fill;

    for (var drip in state.drips!) {
      // Delay logic
      if (drip.delay > 0) {
        drip.delay -= dt;
        continue;
      }

      // Physics
      drip.y += drip.speed * dt * intensity;

      // Reset
      if (drip.y > drip.maxLength) {
        drip.y = 0;
        drip.delay = _rng.nextDouble() * 2; // Random delay before next drip
        drip.maxLength = 50 + _rng.nextDouble() * 200;
        drip.speed = 50 + _rng.nextDouble() * 50;
      }

      // Draw
      final dripWidth = (3 + math.sin(drip.y * 0.1) * 1) * intensity;

      // Trail
      final path = Path();
      path.moveTo(drip.x - dripWidth / 2, 0);
      path.lineTo(drip.x + dripWidth / 2, 0);
      path.lineTo(drip.x + dripWidth / 4, drip.y);
      path.lineTo(drip.x - dripWidth / 4, drip.y);
      path.close();
      canvas.drawPath(path, paint);

      // Bulb at bottom
      canvas.drawCircle(Offset(drip.x, drip.y), dripWidth * 1.5, paint);
    }
  }

  void _updateAndPaintParticles(Canvas canvas, Size size, double dt) {
    if (state.particles == null) return;

    final paint = Paint()..style = PaintingStyle.stroke;

    for (var p in state.particles!) {
      // Physics
      p.x += p.dx * dt * intensity;
      p.y += p.dy * dt * intensity;
      p.rotation += p.rotSpeed * dt;

      // Bounce/Wrap
      if (p.x < 0 || p.x > size.width) p.dx *= -1;
      if (p.y < 0 || p.y > size.height) p.dy *= -1;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isSymbol) {
        // Draw Biohazard-ish symbol (3 circles)
        paint.color = accentColor.withOpacity(0.4 * intensity);
        paint.strokeWidth = 2 * intensity;
        double r = p.size * intensity;

        for (int k = 0; k < 3; k++) {
          final a = k * (math.pi * 2 / 3);
          canvas.drawCircle(Offset(math.cos(a) * r, math.sin(a) * r), r * 0.6, paint);
        }
        canvas.drawCircle(
            Offset.zero,
            r * 0.3,
            Paint()
              ..color = primaryColor.withOpacity(0.5)
              ..style = PaintingStyle.fill);
      } else {
        // Dust speck
        paint.style = PaintingStyle.fill;
        paint.color = primaryColor.withOpacity(0.3 * intensity);
        canvas.drawCircle(Offset.zero, p.size * 0.5 * intensity, paint);
      }

      canvas.restore();
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.7,
      [
        Colors.transparent,
        const Color(0xFF0A150A).withOpacity(0.4 * intensity),
        const Color(0xFF000000).withOpacity(0.8 * intensity),
      ],
      [0.5, 0.8, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(covariant _EnhancedToxicWastePainter oldDelegate) {
    return animationEnabled;
  }
}
