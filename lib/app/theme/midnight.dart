import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// MIDNIGHT THEME BUILDER
// ============================================================================

AppTheme buildMidnightTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.midnight,
    isDark: true,
    primaryColor: const Color(0xFF6A3DE8),
    primaryVariant: const Color(0xFF8056EA),
    onPrimary: Colors.white,
    accentColor: const Color(0xFF03DAC6),
    onAccent: Colors.black,
    background: const Color(0xFF0A1021),
    surface: const Color(0xFF162041),
    surfaceVariant: const Color(0xFF1D2A59),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFFB8C7E0),
    textDisabled: const Color(0xFF6987B7),
    divider: const Color(0xFF2B3966),
    toolbarColor: const Color(0xFF162041),
    error: const Color(0xFFF45E89),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFF9AE59),
    gridLine: const Color(0xFF2B3966),
    gridBackground: const Color(0xFF1D2A59),
    canvasBackground: const Color(0xFF0A1021),
    selectionOutline: const Color(0xFF03DAC6),
    selectionFill: const Color(0x3003DAC6),
    activeIcon: const Color(0xFF6A3DE8),
    inactiveIcon: const Color(0xFFB8C7E0),
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
        color: const Color(0xFFB8C7E0),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// MIDNIGHT ANIMATED BACKGROUND
// ============================================================================

class MidnightBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const MidnightBackground({
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
    final midnightState = useMemoized(() => _MidnightState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnhancedMidnightPainter(
          repaint: controller,
          state: midnightState,
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
class _MidnightState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Star>? stars;
  List<_ShootingStar> shootingStars = [];
  // Cache mountain paths to keep them static while everything else moves
  List<Path>? mountainPaths;
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinklePhase;
  final double twinkleSpeed;
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.color,
  });
}

class _ShootingStar {
  double x;
  double y;
  double speedX;
  double speedY;
  double length;
  double life; // 1.0 to 0.0

  _ShootingStar({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.length,
    required this.life,
  });
}

class _EnhancedMidnightPainter extends CustomPainter {
  final _MidnightState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Midnight color palette
  static const Color _deepPurple = Color(0xFF4A148C);
  static const Color _mysticalBlue = Color(0xFF1A237E);
  static const Color _starWhite = Color(0xFFF8F8FF);
  static const Color _moonSilver = Color(0xFFE8E8E8);
  static const Color _auroraGreen = Color(0xFF00E676);
  static const Color _auroraViolet = Color(0xFF7C4DFF);

  final math.Random _rng = math.Random(42);

  _EnhancedMidnightPainter({
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
    if (state.stars == null) _initWorld(size);

    // 1. Night Sky Background
    _paintNightSky(canvas, size);

    // 2. Aurora Borealis
    _paintAurora(canvas, size);

    // 3. Stars (Twinkling)
    _paintStarField(canvas, size);

    // 4. Shooting Stars (Dynamic)
    _updateAndPaintShootingStars(canvas, size, dt);

    // 5. Moon
    _paintMoon(canvas, size);

    // 6. Mountains (Static Landscape)
    _paintDistantMountains(canvas, size);
  }

  void _initWorld(Size size) {
    state.stars = [];
    final rng = math.Random(1234);

    // Generate Stars
    int starCount = (100 * intensity).round().clamp(50, 200);
    for (int i = 0; i < starCount; i++) {
      Color starColor;
      final type = rng.nextDouble();
      if (type < 0.7) {
        starColor = _starWhite;
      } else if (type < 0.85) {
        starColor = Color.lerp(_starWhite, primaryColor, 0.3)!;
      } else {
        starColor = Color.lerp(_starWhite, accentColor, 0.2)!;
      }

      state.stars!.add(_Star(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height * 0.8, // Keep slightly above bottom
        size: (0.5 + rng.nextDouble() * 2.0) * intensity,
        twinklePhase: rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 1.0 + rng.nextDouble() * 3.0,
        color: starColor,
      ));
    }
  }

  void _paintNightSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Deep space gradient
    final skyGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          const Color(0xFF050510), // Deepest space
          const Color(0xFF101025),
          _mysticalBlue.withOpacity(0.6),
          _deepPurple.withOpacity(0.3),
        ],
        [0.0, 0.4, 0.8, 1.0],
      );

    canvas.drawRect(rect, skyGradient);

    // Nebula clouds (slowly rotating)
    final nebulaPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final t = state.time * 0.1;

    nebulaPaint.color = primaryColor.withOpacity(0.05 * intensity);
    canvas.drawCircle(
      Offset(size.width * 0.8 + math.sin(t) * 50, size.height * 0.2 + math.cos(t) * 30),
      size.width * 0.4,
      nebulaPaint,
    );

    nebulaPaint.color = accentColor.withOpacity(0.03 * intensity);
    canvas.drawCircle(
      Offset(size.width * 0.2 - math.sin(t * 0.8) * 40, size.height * 0.4),
      size.width * 0.5,
      nebulaPaint,
    );
  }

  void _paintAurora(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Draw swaying aurora curtains
    for (int i = 0; i < 3; i++) {
      final t = state.time * 0.5 + i;
      final path = Path();

      final startY = size.height * (0.3 + i * 0.1);
      path.moveTo(0, startY);

      for (double x = 0; x <= size.width; x += 20) {
        final y = startY + math.sin(x * 0.01 + t) * 30 + math.sin(x * 0.03 - t * 0.5) * 20;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, 0); // Close to top
      path.lineTo(0, 0);
      path.close();

      final gradient = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height * 0.6),
        [
          (i % 2 == 0 ? _auroraGreen : _auroraViolet).withOpacity(0.0),
          (i % 2 == 0 ? _auroraGreen : _auroraViolet).withOpacity(0.15 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

      paint.shader = gradient;
      canvas.drawPath(path, paint);
    }
  }

  void _paintStarField(Canvas canvas, Size size) {
    if (state.stars == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in state.stars!) {
      // Twinkle logic
      final twinkle = math.sin(state.time * star.twinkleSpeed + star.twinklePhase);
      final alpha = 0.5 + 0.5 * twinkle; // 0.0 to 1.0

      if (alpha < 0.1) continue;

      paint.color = star.color.withOpacity(alpha * 0.8);
      canvas.drawCircle(Offset(star.x, star.y), star.size, paint);

      // Major stars have glare
      if (star.size > 2.0 && alpha > 0.8) {
        paint.strokeWidth = 0.5;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(Offset(star.x - star.size * 2, star.y), Offset(star.x + star.size * 2, star.y), paint);
        canvas.drawLine(Offset(star.x, star.y - star.size * 2), Offset(star.x, star.y + star.size * 2), paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  void _updateAndPaintShootingStars(Canvas canvas, Size size, double dt) {
    final rng = math.Random();

    // Spawn new shooting stars randomly
    if (rng.nextDouble() < 0.02 * intensity) {
      // 2% chance per frame approx
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height * 0.5;

      state.shootingStars.add(_ShootingStar(
        x: startX,
        y: startY,
        speedX: 300 + rng.nextDouble() * 200, // Move right
        speedY: 100 + rng.nextDouble() * 100, // Move down
        length: 50 + rng.nextDouble() * 50,
        life: 1.0,
      ));
    }

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2 * intensity;

    for (int i = state.shootingStars.length - 1; i >= 0; i--) {
      final s = state.shootingStars[i];

      // Update
      s.x += s.speedX * dt;
      s.y += s.speedY * dt;
      s.life -= dt * 1.5; // Fade out speed

      if (s.life <= 0 || s.x > size.width || s.y > size.height) {
        state.shootingStars.removeAt(i);
        continue;
      }

      // Draw trail
      final tailX = s.x - (s.speedX * 0.15); // Simple trail calculation
      final tailY = s.y - (s.speedY * 0.15);

      paint.shader = ui.Gradient.linear(
        Offset(tailX, tailY),
        Offset(s.x, s.y),
        [Colors.transparent, Colors.white.withOpacity(s.life)],
      );

      canvas.drawLine(Offset(tailX, tailY), Offset(s.x, s.y), paint);

      // Head
      final headPaint = Paint()..color = Colors.white.withOpacity(s.life);
      canvas.drawCircle(Offset(s.x, s.y), 1.5 * intensity, headPaint);
    }
  }

  void _paintMoon(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.85, size.height * 0.2);
    final moonRadius = 30 * intensity;

    final moonPaint = Paint()..style = PaintingStyle.fill;

    // Outer Glow
    moonPaint
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..color = _moonSilver.withOpacity(0.2 * intensity);
    canvas.drawCircle(moonCenter, moonRadius * 3, moonPaint);

    // Moon Body
    moonPaint
      ..maskFilter = null
      ..color = _moonSilver.withOpacity(0.95);
    canvas.drawCircle(moonCenter, moonRadius, moonPaint);

    // Craters (Static details)
    moonPaint.color = const Color(0xFFB0B0B0).withOpacity(0.3);
    canvas.drawCircle(moonCenter + Offset(-moonRadius * 0.3, moonRadius * 0.2), moonRadius * 0.15, moonPaint);
    canvas.drawCircle(moonCenter + Offset(moonRadius * 0.4, -moonRadius * 0.1), moonRadius * 0.1, moonPaint);
    canvas.drawCircle(moonCenter + Offset(moonRadius * 0.1, moonRadius * 0.5), moonRadius * 0.08, moonPaint);
  }

  void _paintDistantMountains(Canvas canvas, Size size) {
    // Generate paths once to keep mountains static
    if (state.mountainPaths == null || state.mountainPaths!.isEmpty) {
      state.mountainPaths = [];
      final rng = math.Random(999); // Deterministic seed for mountains

      for (int layer = 0; layer < 3; layer++) {
        final path = Path();
        final mountainHeight = size.height * (0.15 + layer * 0.08);
        final baseY = size.height;

        path.moveTo(0, baseY);

        // Generate jagged peaks based on x coordinate
        for (double x = 0; x <= size.width; x += 5) {
          // Perlin-like noise using sum of sines
          final noise = math.sin(x * 0.01 + layer) * 20 + math.sin(x * 0.03 + layer * 2) * 10 + math.sin(x * 0.1) * 2;

          // Layer 0 is furthest (smoother), Layer 2 is closest (more jagged)
          final height = mountainHeight + noise * (1.0 + layer * 0.5);
          path.lineTo(x, baseY - height);
        }

        path.lineTo(size.width, baseY);
        path.close();
        state.mountainPaths!.add(path);
      }
    }

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw cached paths
    for (int i = 0; i < state.mountainPaths!.length; i++) {
      // Atmospheric perspective: Further mountains are lighter/bluer
      // Layer 0 (Back), Layer 1 (Mid), Layer 2 (Front)
      // Actually we want back layer first.

      // Let's assume layer 0 is front? No, usually painters algo.
      // Re-reading init: loops 0 to 2.
      // We should draw typically back to front.
      // Let's assign colors assuming i=0 is furthest.

      final opacity = (0.3 + i * 0.2) * intensity;
      paint.color = Color.lerp(
        const Color(0xFF0D1B2A), // Dark base
        _mysticalBlue,
        0.5 - i * 0.15, // Closer layers get darker/more contrast
      )!
          .withOpacity(opacity);

      canvas.drawPath(state.mountainPaths![i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedMidnightPainter oldDelegate) {
    return animationEnabled;
  }
}
