import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// ICE CRYSTAL THEME BUILDER
// ============================================================================

AppTheme buildIceCrystalTheme() {
  // Exo 2 has a futuristic, geometric look suitable for crystals
  final baseTextTheme = GoogleFonts.exo2TextTheme();

  return AppTheme(
    type: ThemeType.iceCrystal,
    isDark: true, // Switched to Dark for better crystal glowing effects

    // Primary colors - icy blue
    primaryColor: const Color(0xFF00E5FF), // Cyan Accent
    primaryVariant: const Color(0xFF00B8D4), // Teal-ish
    onPrimary: const Color(0xFF001519),

    // Secondary colors - crystal white/purple tint
    accentColor: const Color(0xFFE0F7FA), // Very light cyan
    onAccent: const Color(0xFF006064),

    // Background colors - deep ice cave
    background: const Color(0xFF0A1929), // Deep dark blue
    surface: const Color(0xFF132F4C), // Lighter dark blue
    surfaceVariant: const Color(0xFF173A5E),

    // Text colors - high contrast
    textPrimary: const Color(0xFFE3F2FD),
    textSecondary: const Color(0xFF90CAF9),
    textDisabled: const Color(0xFF546E7A),

    // UI colors
    divider: const Color(0xFF1E4976),
    toolbarColor: const Color(0xFF0A1929),
    error: const Color(0xFFFF5252),
    success: const Color(0xFF69F0AE),
    warning: const Color(0xFFFFAB40),

    // Grid colors
    gridLine: const Color(0xFF1E4976),
    gridBackground: const Color(0xFF0A1929),

    // Canvas colors
    canvasBackground: const Color(0xFF050F1A),
    selectionOutline: const Color(0xFF00E5FF),
    selectionFill: const Color(0x3300E5FF),

    // Icon colors
    activeIcon: const Color(0xFF00E5FF),
    inactiveIcon: const Color(0xFF546E7A),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFE0F7FA),
        fontWeight: FontWeight.w300,
        letterSpacing: 1.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFE0F7FA),
        fontWeight: FontWeight.w300,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF00E5FF),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFB3E5FC),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF81D4FA),
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// ICE CRYSTAL ANIMATED BACKGROUND
// ============================================================================

class IceCrystalBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const IceCrystalBackground({
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
    final iceState = useMemoized(() => _IceState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _IceCrystalPainter(
          repaint: controller,
          state: iceState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          backgroundColor: theme.background,
          intensity: intensity.clamp(0.0, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for physics and objects
class _IceState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_CrystalShard>? shards;
  List<_SnowParticle>? snow;
}

class _CrystalShard {
  double x;
  double y;
  final double z; // Depth 0.0 (far) to 1.0 (near)
  final double size;
  final double rotation;
  final double rotationSpeed;
  final int points;
  final List<double> vertices; // Radii for irregular shape

  _CrystalShard({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.points,
    required this.vertices,
  });
}

class _SnowParticle {
  double x;
  double y;
  final double size;
  final double speedY;
  final double wobbleFreq;
  final double wobbleAmp;
  double wobblePhase;

  _SnowParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.wobbleFreq,
    required this.wobbleAmp,
    required this.wobblePhase,
  });
}

class _IceCrystalPainter extends CustomPainter {
  final _IceState state;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final double intensity;
  final bool animationEnabled;

  _IceCrystalPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
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
    if (state.shards == null) _initShards(size);
    if (state.snow == null) _initSnow(size);

    // 1. Background (Deep Ice Cave)
    _paintBackground(canvas, size);

    // 2. Far Crystals (Blurred, Slow)
    _updateAndPaintShards(canvas, size, dt, true);

    // 3. Snow/Dust
    _updateAndPaintSnow(canvas, size, dt);

    // 4. Near Crystals (Sharp, Fast)
    _updateAndPaintShards(canvas, size, dt, false);

    // 5. Frost/Vignette Overlay
    _paintFrostVignette(canvas, size);
  }

  void _initShards(Size size) {
    final rng = math.Random(456);
    state.shards = [];

    // Generate clusters of crystals
    for (int i = 0; i < 25; i++) {
      final z = rng.nextDouble(); // Depth
      final sizeBase = 20 + rng.nextDouble() * 60;
      final points = 3 + rng.nextInt(4); // Triangles to Hexagons

      // Irregular vertices for "shard" look
      final vertices = List.generate(points, (_) => 0.7 + rng.nextDouble() * 0.6);

      state.shards!.add(_CrystalShard(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        z: z,
        size: sizeBase,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.5,
        points: points,
        vertices: vertices,
      ));
    }
  }

  void _initSnow(Size size) {
    final rng = math.Random(789);
    state.snow = List.generate(50, (_) {
      return _SnowParticle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 1 + rng.nextDouble() * 2,
        speedY: 10 + rng.nextDouble() * 30,
        wobbleFreq: 1 + rng.nextDouble() * 3,
        wobbleAmp: 5 + rng.nextDouble() * 10,
        wobblePhase: rng.nextDouble() * math.pi * 2,
      );
    });
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Deep radial gradient mimicking looking out of an ice cave or into deep ice
    final gradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.3),
      size.longestSide * 0.8,
      [
        const Color(0xFF1E3A5F), // Lighter center
        backgroundColor, // Dark mid
        const Color(0xFF020812), // Very dark edges
      ],
      [0.0, 0.6, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient);

    // Subtle Aurora streaks
    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40 * intensity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    for (int i = 0; i < 3; i++) {
      final t = state.time * 0.2 + i * 2.0;
      final y = size.height * (0.2 + i * 0.25) + math.sin(t) * 50;

      streakPaint.color = accentColor.withOpacity(0.05 * intensity);

      final path = Path();
      path.moveTo(0, y);
      path.cubicTo(
          size.width * 0.3, y - 50 * math.cos(t * 0.7), size.width * 0.7, y + 50 * math.sin(t * 0.8), size.width, y);

      canvas.drawPath(path, streakPaint);
    }
  }

  void _updateAndPaintShards(Canvas canvas, Size size, double dt, bool backgroundLayer) {
    if (state.shards == null) return;

    for (var shard in state.shards!) {
      // Filter based on depth (z)
      // Background layer: z < 0.5. Foreground: z >= 0.5
      if (backgroundLayer && shard.z >= 0.5) continue;
      if (!backgroundLayer && shard.z < 0.5) continue;

      // Update position
      // Slow float upwards/rotation
      shard.y -= (5 + shard.z * 15) * dt * intensity;

      // Wrap around
      if (shard.y < -shard.size * 2) {
        shard.y = size.height + shard.size;
        shard.x = math.Random().nextDouble() * size.width;
      }

      final drawSize = shard.size * (0.5 + shard.z) * intensity;
      final opacity = (0.2 + shard.z * 0.4) * intensity;
      final currentRotation = shard.rotation + state.time * shard.rotationSpeed;

      // Prepare paints
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = primaryColor.withOpacity(opacity * 0.3);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 + shard.z) * intensity
        ..color = accentColor.withOpacity(opacity);

      // Create Shard Path
      final path = Path();
      for (int i = 0; i < shard.points; i++) {
        final angle = (i * 2 * math.pi / shard.points) + currentRotation;
        final r = drawSize * shard.vertices[i];
        final px = shard.x + math.cos(angle) * r;
        final py = shard.y + math.sin(angle) * r;
        if (i == 0)
          path.moveTo(px, py);
        else
          path.lineTo(px, py);
      }
      path.close();

      // Draw Shard
      canvas.save();
      // Apply blur to background shards for depth of field
      if (backgroundLayer) {
        fillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      }

      // Gradient fill to simulate refraction
      fillPaint.shader = ui.Gradient.linear(
        Offset(shard.x - drawSize, shard.y - drawSize),
        Offset(shard.x + drawSize, shard.y + drawSize),
        [
          primaryColor.withOpacity(opacity * 0.1),
          Colors.white.withOpacity(opacity * 0.4),
          primaryColor.withOpacity(opacity * 0.1),
        ],
        [0.0, 0.5 + math.sin(state.time + shard.x) * 0.2, 1.0], // Shimmer effect
      );

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);

      // Draw internal facet lines
      borderPaint.strokeWidth = 0.5 * intensity;
      borderPaint.color = Colors.white.withOpacity(opacity * 0.5);
      for (int i = 0; i < shard.points; i++) {
        final angle = (i * 2 * math.pi / shard.points) + currentRotation;
        final r = drawSize * shard.vertices[i];
        final px = shard.x + math.cos(angle) * r;
        final py = shard.y + math.sin(angle) * r;
        canvas.drawLine(Offset(shard.x, shard.y), Offset(px, py), borderPaint);
      }

      canvas.restore();
    }
  }

  void _updateAndPaintSnow(Canvas canvas, Size size, double dt) {
    if (state.snow == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var flake in state.snow!) {
      // Update
      flake.y += flake.speedY * dt * intensity;
      flake.wobblePhase += flake.wobbleFreq * dt;
      final dx = math.sin(flake.wobblePhase) * flake.wobbleAmp * dt * 2;
      flake.x += dx * intensity;

      // Wrap
      if (flake.y > size.height) {
        flake.y = -5;
        flake.x = math.Random().nextDouble() * size.width;
      }
      if (flake.x < 0) flake.x += size.width;
      if (flake.x > size.width) flake.x -= size.width;

      // Draw
      final alpha = (0.3 + 0.7 * math.sin(flake.wobblePhase)) * intensity;
      paint.color = Colors.white.withOpacity(alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(flake.x, flake.y), flake.size * intensity, paint);
    }
  }

  void _paintFrostVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.7,
      [
        Colors.transparent,
        primaryColor.withOpacity(0.1 * intensity),
        primaryColor.withOpacity(0.3 * intensity),
      ],
      [0.6, 0.85, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.screen; // Adds glow

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _IceCrystalPainter oldDelegate) {
    return animationEnabled;
  }
}
