import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildPurpleRainTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.purpleRain,
    isDark: true,
    // Primary colors - deep royal purple
    primaryColor: const Color(0xFF6A0DAD), // Deep royal purple
    primaryVariant: const Color(0xFF4B0082), // Indigo
    onPrimary: Colors.white,
    // Secondary colors - bright violet
    accentColor: const Color(0xFF9932CC), // Dark orchid
    onAccent: Colors.white,
    // Background colors - dark with purple undertones
    background: const Color(0xFF1A0B2E), // Very dark purple
    surface: const Color(0xFF2D1B4E), // Dark purple surface
    surfaceVariant: const Color(0xFF3D2B5E), // Lighter purple variant
    // Text colors - light with purple tints
    textPrimary: const Color(0xFFE6E0FF), // Light lavender
    textSecondary: const Color(0xFFB8A9DB), // Muted lavender
    textDisabled: const Color(0xFF7D6B9B), // Darker muted purple
    // UI colors
    divider: const Color(0xFF4A3B6B),
    toolbarColor: const Color(0xFF2D1B4E),
    error: const Color(0xFFFF6B9D), // Pink-purple error
    success: const Color(0xFF8A2BE2), // Blue violet success
    warning: const Color(0xFFDA70D6), // Orchid warning
    // Grid colors
    gridLine: const Color(0xFF4A3B6B),
    gridBackground: const Color(0xFF2D1B4E),
    // Canvas colors
    canvasBackground: const Color(0xFF1A0B2E),
    selectionOutline: const Color(0xFF9932CC), // Bright violet selection
    selectionFill: const Color(0x309932CC),
    // Icon colors
    activeIcon: const Color(0xFF9932CC), // Bright violet for active
    inactiveIcon: const Color(0xFFB8A9DB), // Muted for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE6E0FF),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE6E0FF),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE6E0FF),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB8A9DB),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ===================== CALM PURPLE RAIN =====================
class PurpleRainBackground extends HookWidget {
  final AppTheme theme;
  final double intensity; // overall look; 0.5–1.0 recommended for calm
  final bool enableAnimation;

  /// Extra controls for calmness
  final double motion; // 0..1 how much things move (default calm)
  final double density; // 0..1 how many elements are drawn (default calm)
  final bool showLightning; // off by default
  final bool showSplashes; // off by default

  const PurpleRainBackground({
    super.key,
    required this.theme,
    this.intensity = 0.9,
    this.enableAnimation = true,
    this.motion = 0.5,
    this.density = 0.6,
    this.showLightning = false,
    this.showSplashes = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ticker controller
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    // Respect system "reduce motion" if available
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final motionScale = (reduceMotion || !enableAnimation) ? 0.0 : motion.clamp(0.0, 1.0);
    final densityScale = density.clamp(0.2, 1.0);

    useEffect(() {
      if (motionScale > 0) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [motionScale]);

    // 2. State for infinite animation
    final rainState = useMemoized(() => _RainState());

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        isComplex: true,
        willChange: motionScale > 0,
        painter: _CalmPurpleRainPainter(
          repaint: controller,
          state: rainState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.3, 1.2),
          motion: motionScale,
          density: densityScale,
          showLightning: showLightning,
          showSplashes: showSplashes,
          animationEnabled: enableAnimation,
        ),
      ),
    );
  }
}

// State class for physics and objects
class _RainState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Drop>? drops;
  List<_MistCloud>? mist;
  List<_Splash>? splashes;
  double lightningTimer = 0;
  double lightningFlash = 0;
}

class _Drop {
  double x;
  double y;
  double z; // Depth: 0 (far) -> 1 (near)
  double speed;
  double length;

  _Drop({
    required this.x,
    required this.y,
    required this.z,
    required this.speed,
    required this.length,
  });
}

class _MistCloud {
  double x;
  double y;
  double w;
  double h;
  double speed;

  _MistCloud({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.speed,
  });
}

class _Splash {
  double x;
  double y;
  double life; // 1.0 -> 0.0
  double maxRadius;

  _Splash({
    required this.x,
    required this.y,
    required this.life,
    required this.maxRadius,
  });
}

class _CalmPurpleRainPainter extends CustomPainter {
  final _RainState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity; // visual strength (colors/widths)
  final double motion; // 0..1 animation amount
  final double density; // 0..1 element counts
  final bool showLightning;
  final bool showSplashes;
  final bool animationEnabled;

  _CalmPurpleRainPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    required this.motion,
    required this.density,
    required this.showLightning,
    required this.showSplashes,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  // Palette
  final Color _deepPurple = const Color(0xFF2D0A4B);
  final Color _royalPurple = const Color(0xFF4B0082);
  final Color _brightViolet = const Color(0xFF8A2BE2);
  final Color _electricPurple = const Color(0xFF9932CC);
  final Color _amethyst = const Color(0xFF9966CC);
  final Color _lavender = const Color(0xFFB19CD9);

  @override
  void paint(Canvas canvas, Size size) {
    // Time accumulation
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt * motion;

    // Initialize
    if (state.drops == null) _initWorld(size);

    _updatePhysics(size, dt);

    _paintSky(canvas, size);
    _paintMist(canvas, size);
    _paintRain(canvas, size);
    if (showSplashes) _paintSplashes(canvas, size);
    _paintVignette(canvas, size);
  }

  void _initWorld(Size size) {
    final rng = math.Random(1234);
    state.drops = [];
    state.mist = [];
    state.splashes = [];

    // Rain Drops
    int dropCount = (200 * density * intensity).round().clamp(50, 400);
    for (int i = 0; i < dropCount; i++) {
      state.drops!.add(_Drop(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        z: rng.nextDouble(),
        speed: 300 + rng.nextDouble() * 500,
        length: 20 + rng.nextDouble() * 30,
      ));
    }

    // Mist Clouds
    int mistCount = (4 * density).round().clamp(2, 8);
    for (int i = 0; i < mistCount; i++) {
      state.mist!.add(_MistCloud(
        x: rng.nextDouble() * size.width,
        y: size.height * (0.6 + rng.nextDouble() * 0.4),
        w: size.width * (0.4 + rng.nextDouble() * 0.4),
        h: 20 + rng.nextDouble() * 40,
        speed: 10 + rng.nextDouble() * 20,
      ));
    }
  }

  void _updatePhysics(Size size, double dt) {
    final rng = math.Random();

    // Update drops
    for (var drop in state.drops!) {
      drop.y += drop.speed * drop.z * dt * motion;
      // Slight wind
      drop.x += 20 * drop.z * dt * motion;

      if (drop.y > size.height + drop.length) {
        drop.y = -drop.length - rng.nextDouble() * 100;
        drop.x = rng.nextDouble() * size.width;

        // Chance to create splash on reset if near bottom (simulating ground hit logic visually)
        if (showSplashes && rng.nextDouble() < 0.2 * density) {
          // This logic is simplified; splashes usually happen at bottom
        }
      }
      if (drop.x > size.width) drop.x = 0;
    }

    // Update Splashes
    if (showSplashes) {
      // Spawn new splashes
      if (rng.nextDouble() < 0.1 * density * motion) {
        state.splashes!.add(_Splash(
          x: rng.nextDouble() * size.width,
          y: size.height * (0.9 + rng.nextDouble() * 0.1),
          life: 1.0,
          maxRadius: 5 + rng.nextDouble() * 15 * intensity,
        ));
      }

      for (int i = state.splashes!.length - 1; i >= 0; i--) {
        final s = state.splashes![i];
        s.life -= dt * 2.0 * motion;
        if (s.life <= 0) {
          state.splashes!.removeAt(i);
        }
      }
    }

    // Update Mist
    for (var cloud in state.mist!) {
      cloud.x += cloud.speed * dt * motion;
      if (cloud.x > size.width + cloud.w) {
        cloud.x = -cloud.w;
      }
    }

    // Lightning logic
    if (showLightning) {
      if (state.lightningFlash > 0) {
        state.lightningFlash -= dt * 2.0;
        if (state.lightningFlash < 0) state.lightningFlash = 0;
      } else {
        state.lightningTimer -= dt;
        if (state.lightningTimer <= 0) {
          if (rng.nextDouble() < 0.01) {
            // Random trigger
            state.lightningFlash = 1.0;
            state.lightningTimer = 5 + rng.nextDouble() * 10;
          }
        }
      }
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final flash = state.lightningFlash * 0.4;

    final g = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          Color.lerp(_deepPurple, Colors.white, flash * 0.5)!.withOpacity(0.95),
          _royalPurple.withOpacity(0.72),
          primaryColor.withOpacity(0.5),
          Color.lerp(_deepPurple, Colors.black, 0.35)!,
        ],
        const [0.0, 0.4, 0.75, 1.0],
      );
    canvas.drawRect(rect, g);
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var drop in state.drops!) {
      paint.strokeWidth = (1.0 + drop.z) * intensity;
      // Closer drops are brighter/more distinct
      final color = drop.z > 0.7 ? _brightViolet : (drop.z > 0.4 ? _amethyst : _lavender);
      final alpha = (0.1 + drop.z * 0.2) * intensity;

      paint.color = color.withOpacity(alpha.clamp(0.0, 1.0));

      final tailY = drop.y - drop.length * drop.z;
      canvas.drawLine(Offset(drop.x, drop.y), Offset(drop.x - 2 * drop.z, tailY), paint);
    }
  }

  void _paintSplashes(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _lavender.withOpacity(0.2 * intensity);

    for (var s in state.splashes!) {
      paint.strokeWidth = s.life * intensity;
      paint.color = _lavender.withOpacity(s.life * 0.3 * intensity);

      final radius = s.maxRadius * (1 - s.life);
      // Oval splash on ground
      canvas.drawOval(Rect.fromCenter(center: Offset(s.x, s.y), width: radius * 3, height: radius), paint);
    }
  }

  void _paintMist(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < state.mist!.length; i++) {
      final cloud = state.mist![i];
      final opacity = (0.03 + 0.01 * (i % 2)) * intensity;

      paint.color = _royalPurple.withOpacity(opacity);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cloud.x, cloud.y, cloud.w, cloud.h),
        const Radius.circular(20),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final flash = state.lightningFlash;
    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5),
        size.longestSide * 0.78,
        [
          Colors.transparent,
          _deepPurple.withOpacity(0.10 + 0.05 * flash),
          _deepPurple.withOpacity(0.16 + 0.07 * flash),
        ],
        const [0.0, 0.82, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _CalmPurpleRainPainter old) {
    return animationEnabled;
  }
}
