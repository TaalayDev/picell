import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// EMERALD FOREST THEME BUILDER
// ============================================================================

AppTheme buildEmeraldForestTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.emeraldForest,
    isDark: false,
    // Primary colors - rich emerald green
    primaryColor: const Color(0xFF50C878), // Emerald green
    primaryVariant: const Color(0xFF2E8B57), // Sea green
    onPrimary: Colors.white,
    // Secondary colors - forest gold
    accentColor: const Color(0xFFDAA520), // Goldenrod
    onAccent: Colors.black,
    // Background colors - soft natural tones
    background: const Color(0xFFF0F8F0), // Honeydew (very light green)
    surface: const Color(0xFFFFFFFF), // Pure white
    surfaceVariant: const Color(0xFFE8F5E8), // Light mint green
    // Text colors - deep forest tones
    textPrimary: const Color(0xFF1C3A1C), // Dark forest green
    textSecondary: const Color(0xFF2F5233), // Medium forest green
    textDisabled: const Color(0xFF8FBC8F), // Light sea green
    // UI colors
    divider: const Color(0xFFD4E6D4), // Very light green
    toolbarColor: const Color(0xFFE8F5E8),
    error: const Color(0xFFB22222), // Fire brick red
    success: const Color(0xFF228B22), // Forest green
    warning: const Color(0xFFFF8C00), // Dark orange
    // Grid colors
    gridLine: const Color(0xFFD4E6D4),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFF50C878), // Match primary
    selectionFill: const Color(0x3050C878),
    // Icon colors
    activeIcon: const Color(0xFF50C878), // Emerald for active
    inactiveIcon: const Color(0xFF2F5233), // Forest green for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF1C3A1C),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF1C3A1C),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF1C3A1C),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF2F5233),
      ),
    ),
    primaryFontWeight: FontWeight.w500, // Natural, readable weight
  );
}

// ============================================================================
// EMERALD FOREST ANIMATED BACKGROUND
// ============================================================================

class EmeraldForestBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const EmeraldForestBackground({
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
    final forestState = useMemoized(() => _ForestState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EmeraldForestPainter(
          repaint: controller,
          state: forestState,
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
class _ForestState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Leaf>? leaves;
  List<_Sprite>? sprites;
}

class _Leaf {
  double x;
  double y;
  double size;
  double rotation;
  double rotSpeed;
  double swayFreq;
  double swayAmp;
  double fallSpeed;
  double swayPhase;

  _Leaf({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.swayFreq,
    required this.swayAmp,
    required this.fallSpeed,
    required this.swayPhase,
  });
}

class _Sprite {
  double x;
  double y;
  double size;
  double dx;
  double dy;
  double pulsePhase;

  _Sprite({
    required this.x,
    required this.y,
    required this.size,
    required this.dx,
    required this.dy,
    required this.pulsePhase,
  });
}

class _EmeraldForestPainter extends CustomPainter {
  final _ForestState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _EmeraldForestPainter({
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
    if (state.leaves == null) _initWorld(size);

    _paintCanopyLayers(canvas, size);
    _paintSunbeams(canvas, size);
    _paintMushrooms(canvas, size);
    _updateAndPaintLeaves(canvas, size, dt);
    _updateAndPaintSprites(canvas, size, dt);
  }

  void _initWorld(Size size) {
    final rng = math.Random(333);
    state.leaves = [];
    state.sprites = [];

    // Init Leaves
    for (int i = 0; i < 30; i++) {
      state.leaves!.add(_Leaf(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 3 + rng.nextDouble() * 6,
        rotation: rng.nextDouble() * math.pi * 2,
        rotSpeed: (rng.nextDouble() - 0.5) * 2.0,
        swayFreq: 1.0 + rng.nextDouble() * 2.0,
        swayAmp: 20 + rng.nextDouble() * 30,
        fallSpeed: 20 + rng.nextDouble() * 30,
        swayPhase: rng.nextDouble() * math.pi * 2,
      ));
    }

    // Init Sprites (Fireflies)
    for (int i = 0; i < 20; i++) {
      state.sprites!.add(_Sprite(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 1.5 + rng.nextDouble() * 2.5,
        dx: (rng.nextDouble() - 0.5) * 15,
        dy: (rng.nextDouble() - 0.5) * 15,
        pulsePhase: rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _paintCanopyLayers(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw forest canopy layers (depth effect)
    for (int layer = 0; layer < 4; layer++) {
      final canopyY = size.height * (0.1 + layer * 0.15);
      final layerOpacity = (0.02 + layer * 0.01) * intensity;

      final path = Path();
      path.moveTo(0, canopyY);

      // Create organic canopy shapes
      for (double x = 0; x <= size.width; x += 15) {
        // Use continuous time for waves
        final canopyWave = math.sin(x / 100 + state.time * 0.2 + layer * 0.5) * 20 * intensity;
        final leafVariation = math.sin(x / 40 + state.time * 0.5 + layer) * 8 * intensity;
        final y = canopyY + canopyWave + leafVariation;
        path.lineTo(x, y);
      }

      // Complete the canopy fill
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();

      paint.color = Color.lerp(
        primaryColor.withOpacity(layerOpacity),
        const Color(0xFF228B22).withOpacity(layerOpacity * 0.8), // Forest green mix
        layer / 3.0,
      )!;

      canvas.drawPath(path, paint);
    }
  }

  void _updateAndPaintLeaves(Canvas canvas, Size size, double dt) {
    if (state.leaves == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var leaf in state.leaves!) {
      // Update
      leaf.swayPhase += leaf.swayFreq * dt;
      leaf.x += math.sin(leaf.swayPhase) * leaf.swayAmp * dt * 0.1 * intensity;
      leaf.y += leaf.fallSpeed * dt * intensity;
      leaf.rotation += leaf.rotSpeed * dt;

      // Wrap
      if (leaf.y > size.height + 20) {
        leaf.y = -20;
        leaf.x = math.Random().nextDouble() * size.width;
      }
      if (leaf.x > size.width + 20) leaf.x = -20;
      if (leaf.x < -20) leaf.x = size.width + 20;

      // Draw
      canvas.save();
      canvas.translate(leaf.x, leaf.y);
      canvas.rotate(leaf.rotation);

      // Leaf shape
      final leafPath = Path();
      leafPath.moveTo(0, -leaf.size);
      leafPath.quadraticBezierTo(leaf.size * 0.6, -leaf.size * 0.3, leaf.size * 0.8, 0);
      leafPath.quadraticBezierTo(leaf.size * 0.4, leaf.size * 0.8, 0, leaf.size);
      leafPath.quadraticBezierTo(-leaf.size * 0.4, leaf.size * 0.8, -leaf.size * 0.8, 0);
      leafPath.quadraticBezierTo(-leaf.size * 0.6, -leaf.size * 0.3, 0, -leaf.size);
      leafPath.close();

      final shimmer = math.sin(state.time * 2 + leaf.x) * 0.5 + 0.5;

      paint.color = Color.lerp(
        primaryColor.withOpacity(0.4),
        const Color(0xFF9ACD32).withOpacity(0.5), // Yellow green
        shimmer,
      )!;

      canvas.drawPath(leafPath, paint);

      // Vein
      final veinPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * intensity
        ..color = paint.color.withOpacity(0.6);

      canvas.drawLine(Offset(0, -leaf.size * 0.8), Offset(0, leaf.size * 0.8), veinPaint);

      canvas.restore();
    }
  }

  void _updateAndPaintSprites(Canvas canvas, Size size, double dt) {
    if (state.sprites == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var sprite in state.sprites!) {
      // Update
      sprite.x += sprite.dx * dt * intensity;
      sprite.y += sprite.dy * dt * intensity;

      // Bounce/Wrap
      if (sprite.x < 0 || sprite.x > size.width) sprite.dx *= -1;
      if (sprite.y < 0 || sprite.y > size.height) sprite.dy *= -1;

      // Draw
      final pulse = math.sin(state.time * 3 + sprite.pulsePhase) * 0.5 + 0.5;
      if (pulse > 0.2) {
        final glowRadius = (2 + pulse * 4) * intensity;

        // Core
        paint.color = accentColor.withOpacity(0.8 * pulse);
        canvas.drawCircle(Offset(sprite.x, sprite.y), sprite.size, paint);

        // Glow
        paint.color = accentColor.withOpacity(0.2 * pulse);
        canvas.drawCircle(Offset(sprite.x, sprite.y), glowRadius, paint);
      }
    }
  }

  void _paintMushrooms(Canvas canvas, Size size) {
    // Static positions based on seeded random, but glowing animation
    final rng = math.Random(333);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < (8 * intensity).round(); i++) {
      final mushroomX = (i / 8.0) * size.width + rng.nextDouble() * 40 - 20;
      final mushroomY = size.height * (0.85 + rng.nextDouble() * 0.1);
      final mushroomSize = (6 + rng.nextDouble() * 8) * intensity;

      final mushroomGlow = math.sin(state.time * 2 + i * 0.8) * 0.3 + 0.4;

      // Mushroom cap (dome)
      paint.color = Color.lerp(
        primaryColor.withOpacity(0.15 * mushroomGlow),
        const Color(0xFF8B4513).withOpacity(0.1 * mushroomGlow), // Saddle brown
        mushroomGlow,
      )!;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(mushroomX, mushroomY - mushroomSize * 0.3),
          width: mushroomSize * 2,
          height: mushroomSize,
        ),
        0,
        math.pi,
        true,
        paint,
      );

      // Mushroom stem
      paint.color = const Color(0xFFF5F5DC).withOpacity(0.1 * mushroomGlow); // Beige
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(mushroomX, mushroomY),
          width: mushroomSize * 0.3,
          height: mushroomSize * 0.8,
        ),
        paint,
      );
    }
  }

  void _paintSunbeams(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * intensity;

    for (int i = 0; i < (6 * intensity).round(); i++) {
      final rayX = size.width * (0.1 + i * 0.15);
      final rayAngle = (15 + i * 5) * math.pi / 180;
      final rayLength = (80 + math.sin(state.time * 0.5 + i) * 20) * intensity;

      final rayEndX = rayX + math.cos(rayAngle) * rayLength;
      final rayEndY = math.sin(rayAngle) * rayLength;

      final rayIntensity = math.sin(state.time + i * 0.7) * 0.3 + 0.4;

      // Gradient beam
      paint.shader = ui.Gradient.linear(
        Offset(rayX, 0),
        Offset(rayEndX, rayEndY),
        [
          accentColor.withOpacity(0.08 * rayIntensity * intensity),
          accentColor.withOpacity(0.02 * rayIntensity * intensity),
          Colors.transparent,
        ],
        [0.0, 0.6, 1.0], // Fixed stops
      );

      canvas.drawLine(Offset(rayX, 0), Offset(rayEndX, rayEndY), paint);
    }
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _EmeraldForestPainter oldDelegate) {
    return animationEnabled;
  }
}
