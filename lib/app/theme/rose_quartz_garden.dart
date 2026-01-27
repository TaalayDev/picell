import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// ROSE QUARTZ GARDEN THEME BUILDER
// ============================================================================

AppTheme buildRoseQuartzGardenTheme() {
  final baseTextTheme = GoogleFonts.cormorantGaramondTextTheme();
  final bodyTextTheme = GoogleFonts.montserratTextTheme();

  return AppTheme(
    type: ThemeType.roseQuartzGarden,
    isDark: false, // Bright, airy, and soft

    // Primary colors - soft rose quartz pink
    primaryColor: const Color(0xFFF7CAC9), // Rose Quartz
    primaryVariant: const Color(0xFFE0A8A9), // Deeper Rose
    onPrimary: const Color(0xFF5D2C2F), // Dark Burgundy Text

    // Secondary colors - serenity blue / sage green hints
    accentColor: const Color(0xFFB9E2D6), // Soft Sage/Mint
    onAccent: const Color(0xFF2C3E50),

    // Background colors - gentle and soft
    background: const Color(0xFFFFF0F5), // Lavender Blush
    surface: const Color(0xFFFFFFFF), // Pure white
    surfaceVariant: const Color(0xFFFCE4EC), // Pink laccery

    // Text colors - warm and readable
    textPrimary: const Color(0xFF4A3B3C), // Deep warm gray/brown
    textSecondary: const Color(0xFF8D6E63), // Cocoa
    textDisabled: const Color(0xFFD7CCC8),

    // UI colors
    divider: const Color(0xFFF8BBD0),
    toolbarColor: const Color(0xFFFFF0F5),
    error: const Color(0xFFE57373),
    success: const Color(0xFF81C784),
    warning: const Color(0xFFFFB74D),

    // Grid colors
    gridLine: const Color(0xFFF8BBD0),
    gridBackground: const Color(0xFFFFF0F5),

    // Canvas colors
    canvasBackground: const Color(0xFFFAFAFA),
    selectionOutline: const Color(0xFFF48FB1),
    selectionFill: const Color(0x30F48FB1),

    // Icon colors
    activeIcon: const Color(0xFFEC407A),
    inactiveIcon: const Color(0xFFA1887F),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF4A3B3C),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF4A3B3C),
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF880E4F),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF4A3B3C),
        fontSize: 16,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF5D4037),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// ROSE QUARTZ ANIMATED BACKGROUND
// ============================================================================

class RoseQuartzGardenBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const RoseQuartzGardenBackground({
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
    final gardenState = useMemoized(() => _GardenState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _RoseQuartzGardenPainter(
          repaint: controller,
          state: gardenState,
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
class _GardenState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_CrystalCluster>? crystals;
  List<_Petal>? petals;
  List<_Sparkle>? sparkles;
}

class _CrystalCluster {
  double x;
  double y;
  final double z; // Depth 0.0 (back) to 1.0 (front)
  final double size;
  final double rotation;
  final int facets;
  final List<Color> facetColors;

  _CrystalCluster({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.rotation,
    required this.facets,
    required this.facetColors,
  });
}

class _Petal {
  double x;
  double y;
  double z;
  final double size;
  double rotation;
  double rotationSpeed;
  double fallSpeed;
  double swayFreq;
  double swayAmp;
  double swayPhase;

  _Petal({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.swayFreq,
    required this.swayAmp,
    required this.swayPhase,
  });
}

class _Sparkle {
  double x;
  double y;
  double phase;
  double speed;
  double size;

  _Sparkle({
    required this.x,
    required this.y,
    required this.phase,
    required this.speed,
    required this.size,
  });
}

class _RoseQuartzGardenPainter extends CustomPainter {
  final _GardenState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Palette
  static const Color _softPink = Color(0xFFFFCDD2);
  static const Color _deepRose = Color(0xFFF48FB1);
  static const Color _quartzWhite = Color(0xFFFFF8E1); // Slight gold tint
  static const Color _mistColor = Color(0xFFFCE4EC);

  final math.Random _rng = math.Random(1337);

  _RoseQuartzGardenPainter({
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
    if (state.crystals == null) _initWorld(size);

    // 1. Atmospheric Background
    _paintAtmosphere(canvas, size);

    // 2. Background Elements (Mist, Far Crystals)
    _paintMist(canvas, size, 0.2);
    _paintCrystals(canvas, size, true); // Far

    // 3. Middle Elements
    _updateAndPaintPetals(canvas, size, dt, true); // Far petals

    // 4. Foreground Elements
    _paintCrystals(canvas, size, false); // Near
    _updateAndPaintPetals(canvas, size, dt, false); // Near petals
    _paintSparkles(canvas, size, dt);

    // 5. Vignette/Glow
    _paintGlow(canvas, size);
  }

  void _initWorld(Size size) {
    state.crystals = [];
    state.petals = [];
    state.sparkles = [];
    final rng = math.Random(42);

    // Generate Crystals
    for (int i = 0; i < 15; i++) {
      final z = rng.nextDouble();
      final sizeBase = 40 + rng.nextDouble() * 80;
      final facets = 5 + rng.nextInt(3);

      List<Color> colors = [];
      for (int f = 0; f < facets; f++) {
        colors.add(Color.lerp(_softPink, _deepRose, rng.nextDouble())!);
      }

      state.crystals!.add(_CrystalCluster(
        x: rng.nextDouble() * size.width,
        y: size.height * (0.6 + rng.nextDouble() * 0.4), // Bottom half
        z: z,
        size: sizeBase,
        rotation: (rng.nextDouble() - 0.5) * 0.3,
        facets: facets,
        facetColors: colors,
      ));
    }

    // Generate Petals
    for (int i = 0; i < 40; i++) {
      state.petals!.add(_Petal(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        z: rng.nextDouble(),
        size: 5 + rng.nextDouble() * 10,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 2.0,
        fallSpeed: 20 + rng.nextDouble() * 40,
        swayFreq: 1 + rng.nextDouble() * 2,
        swayAmp: 10 + rng.nextDouble() * 30,
        swayPhase: rng.nextDouble() * math.pi * 2,
      ));
    }

    // Generate Sparkles
    for (int i = 0; i < 30; i++) {
      state.sparkles!.add(_Sparkle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 2 + rng.nextDouble() * 3,
        size: 2 + rng.nextDouble() * 4,
      ));
    }
  }

  void _paintAtmosphere(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft dawn gradient
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [
        const Color(0xFFFBE4EB), // Light pink sky
        const Color(0xFFF8BBD0), // Rose middle
        const Color(0xFFF06292), // Darker pink bottom
      ],
      [0.0, 0.6, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient);

    // Sun/Light source glow
    final sunPaint = Paint()
      ..color = _quartzWhite.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 100, sunPaint);
  }

  void _paintMist(Canvas canvas, Size size, double opacity) {
    final paint = Paint()
      ..color = _mistColor.withOpacity(opacity * 0.5 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final time = state.time;

    for (int i = 0; i < 3; i++) {
      final y = size.height * 0.7 + math.sin(time * 0.2 + i) * 50;
      final path = Path();
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width * 0.5, y - 50 * math.cos(time * 0.3 + i), size.width, y + 30);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  void _paintCrystals(Canvas canvas, Size size, bool backgroundLayer) {
    if (state.crystals == null) return;

    // Sorting not strictly necessary if we split lists, but z-filtering works too
    for (var crystal in state.crystals!) {
      if (backgroundLayer && crystal.z >= 0.5) continue;
      if (!backgroundLayer && crystal.z < 0.5) continue;

      final sway = math.sin(state.time * 0.5 + crystal.x) * 5 * intensity;
      final drawX = crystal.x + sway * (1 - crystal.z); // Far crystals sway less
      final drawY = crystal.y;

      final scale = crystal.size * (0.5 + 0.5 * crystal.z) * intensity;
      final opacity = (0.4 + 0.6 * crystal.z) * intensity;

      canvas.save();
      canvas.translate(drawX, drawY);
      canvas.rotate(crystal.rotation);
      if (backgroundLayer) {
        // Blur distant crystals
        // Note: keeping paint clean for performance, gradient handles look
      }

      // Draw volumetric crystal shards
      final paint = Paint()..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.3 * opacity);

      for (int i = 0; i < crystal.facets; i++) {
        final angle1 = (i / crystal.facets) * math.pi * 2;
        final angle2 = ((i + 1) / crystal.facets) * math.pi * 2;

        final path = Path();
        path.moveTo(0, -scale); // Tip
        path.lineTo(math.cos(angle1) * scale * 0.6, math.sin(angle1) * scale * 0.6 + scale * 0.2);
        path.lineTo(0, scale * 0.5); // Base center
        path.lineTo(math.cos(angle2) * scale * 0.6, math.sin(angle2) * scale * 0.6 + scale * 0.2);
        path.close();

        // Gradient for volume
        paint.shader = ui.Gradient.linear(
          Offset(0, -scale),
          Offset(0, scale * 0.5),
          [
            Colors.white.withOpacity(0.8 * opacity),
            crystal.facetColors[i].withOpacity(0.6 * opacity),
            crystal.facetColors[i].withOpacity(0.9 * opacity),
          ],
          [0.0, 0.5, 1.0], // Added stops to fix error
        );

        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
      }

      canvas.restore();
    }
  }

  void _updateAndPaintPetals(Canvas canvas, Size size, double dt, bool backgroundLayer) {
    if (state.petals == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var petal in state.petals!) {
      if (backgroundLayer && petal.z >= 0.5) continue;
      if (!backgroundLayer && petal.z < 0.5) continue;

      // Update
      petal.swayPhase += petal.swayFreq * dt;
      petal.x += math.sin(petal.swayPhase) * petal.swayAmp * dt * intensity;
      petal.y += petal.fallSpeed * dt * intensity;
      petal.rotation += petal.rotationSpeed * dt;

      // Wrap
      if (petal.y > size.height + 20) {
        petal.y = -20;
        petal.x = _rng.nextDouble() * size.width;
      }
      if (petal.x > size.width + 20) petal.x = -20;
      if (petal.x < -20) petal.x = size.width + 20;

      // Draw
      final pSize = petal.size * (0.5 + 0.5 * petal.z) * intensity;
      final opacity = (0.4 + 0.6 * petal.z) * intensity;

      paint.color = (petal.z > 0.7 ? _softPink : _deepRose).withOpacity(opacity * 0.8);

      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.rotation);

      // Simple petal shape
      final path = Path();
      path.moveTo(0, -pSize);
      path.quadraticBezierTo(pSize, -pSize * 0.5, 0, pSize);
      path.quadraticBezierTo(-pSize, -pSize * 0.5, 0, -pSize);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _paintSparkles(Canvas canvas, Size size, double dt) {
    if (state.sparkles == null) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    for (var sparkle in state.sparkles!) {
      final t = state.time * sparkle.speed + sparkle.phase;
      final brightness = (math.sin(t) + 1) / 2; // 0 to 1

      if (brightness < 0.1) continue;

      final sSize = sparkle.size * brightness * intensity;
      final glowOpacity = brightness * 0.8 * intensity;

      // Core
      paint.color = Colors.white.withOpacity(glowOpacity);
      canvas.drawCircle(Offset(sparkle.x, sparkle.y), sSize, paint);

      // Glow
      paint.color = _quartzWhite.withOpacity(glowOpacity * 0.3);
      canvas.drawCircle(Offset(sparkle.x, sparkle.y), sSize * 3, paint);

      // Cross
      paint.strokeWidth = 1.0;
      paint.style = PaintingStyle.stroke;
      paint.color = Colors.white.withOpacity(glowOpacity * 0.5);
      canvas.drawLine(Offset(sparkle.x - sSize * 2, sparkle.y), Offset(sparkle.x + sSize * 2, sparkle.y), paint);
      canvas.drawLine(Offset(sparkle.x, sparkle.y - sSize * 2), Offset(sparkle.x, sparkle.y + sSize * 2), paint);
      paint.style = PaintingStyle.fill;
    }
  }

  void _paintGlow(Canvas canvas, Size size) {
    // Bottom volumetric light/fog
    final rect = Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4);
    final gradient = ui.Gradient.linear(
      Offset(0, size.height * 0.6),
      Offset(0, size.height),
      [
        Colors.transparent,
        _softPink.withOpacity(0.2 * intensity),
        _deepRose.withOpacity(0.4 * intensity),
      ],
      [0.0, 0.5, 1.0], // Added stops to fix error
    );

    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(covariant _RoseQuartzGardenPainter oldDelegate) {
    return animationEnabled;
  }
}
