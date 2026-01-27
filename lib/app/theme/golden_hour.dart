import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildGoldenHourTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.goldenHour,
    isDark: false,
    // Primary colors - warm golden amber
    primaryColor: const Color(0xFFD4A574), // Warm golden amber
    primaryVariant: const Color(0xFFB8956A), // Deeper golden
    onPrimary: const Color(0xFF3D2914), // Dark brown for contrast
    // Secondary colors - coral orange
    accentColor: const Color(0xFFED8A63), // Warm coral
    onAccent: Colors.white,
    // Background colors - warm cream tones
    background: const Color(0xFFFDF6E3), // Warm cream
    surface: const Color(0xFFFEFCF6), // Warmer white
    surfaceVariant: const Color(0xFFF4EDD8), // Light golden beige
    // Text colors - warm browns
    textPrimary: const Color(0xFF3D2914), // Dark warm brown
    textSecondary: const Color(0xFF6B4E37), // Medium brown
    textDisabled: const Color(0xFFA08B7A), // Light brown
    // UI colors
    divider: const Color(0xFFE6D3B7), // Light golden
    toolbarColor: const Color(0xFFF4EDD8),
    error: const Color(0xFFD2691E), // Chocolate orange
    success: const Color(0xFF8FBC8F), // Dark sea green
    warning: const Color(0xFFDDAA00), // Dark golden rod
    // Grid colors
    gridLine: const Color(0xFFE6D3B7),
    gridBackground: const Color(0xFFFEFCF6),
    // Canvas colors
    canvasBackground: const Color(0xFFFEFCF6),
    selectionOutline: const Color(0xFFD4A574), // Match primary
    selectionFill: const Color(0x30D4A574),
    // Icon colors
    activeIcon: const Color(0xFFD4A574), // Golden for active
    inactiveIcon: const Color(0xFF6B4E37), // Brown for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF3D2914),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF3D2914),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF3D2914),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF6B4E37),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// Enhanced Golden Hour theme background with cinematic sunset effects
class GoldenHourBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const GoldenHourBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ticker controller - loops forever to drive the frame update
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

    // 2. State for infinite animation - persists across frames
    final goldenState = useMemoized(() => _GoldenState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnhancedGoldenHourPainter(
          repaint: controller,
          state: goldenState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.3, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
        isComplex: true,
        willChange: enableAnimation,
      ),
    );
  }
}

// State class for physics and objects
class _GoldenState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Cloud>? clouds;
  List<_DustParticle>? dust;
  List<_SunRay>? rays;
}

class _Cloud {
  double x;
  double y;
  double speed;
  double size;
  double widthRatio;
  int layer; // 0 is far, 2 is near

  _Cloud({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.widthRatio,
    required this.layer,
  });
}

class _DustParticle {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;
  double shimmerOffset;

  _DustParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.shimmerOffset,
  });
}

class _SunRay {
  double angle;
  double lengthBase;
  double speed;
  double phase;
  double thickness;

  _SunRay({
    required this.angle,
    required this.lengthBase,
    required this.speed,
    required this.phase,
    required this.thickness,
  });
}

class _EnhancedGoldenHourPainter extends CustomPainter {
  final _GoldenState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Golden hour color palette
  static const Color _deepGold = Color(0xFFB8860B);
  static const Color _sunsetOrange = Color(0xFFFF8C00);
  static const Color _warmAmber = Color(0xFFFFBF00);
  static const Color _honeyglow = Color(0xFFFFC649);
  static const Color _peach = Color(0xFFFFDAB9);
  static const Color _rosyGold = Color(0xFFEEC591);
  static const Color _burnishedGold = Color(0xFFCD7F32);
  static const Color _creamGold = Color(0xFFFFF8DC);

  final math.Random _rng = math.Random(123);

  _EnhancedGoldenHourPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Time accumulation logic
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialization
    if (state.clouds == null) _initWorld(size);

    // Painting sequence
    _paintGoldenSky(canvas, size);
    _paintSun(canvas, size);
    _updateAndPaintSunRays(canvas, size);
    _updateAndPaintClouds(canvas, size, dt);
    _paintAtmosphericHaze(canvas, size);
    _updateAndPaintFloatingDust(canvas, size, dt);
    _paintLensFlares(canvas, size);
    _paintWarmGlow(canvas, size);
  }

  void _initWorld(Size size) {
    state.clouds = [];
    state.dust = [];
    state.rays = [];
    final rng = math.Random(999);

    // Init Clouds
    for (int i = 0; i < 15; i++) {
      final layer = rng.nextInt(3);
      state.clouds!.add(_Cloud(
        x: rng.nextDouble() * size.width,
        y: size.height * (0.1 + rng.nextDouble() * 0.4),
        speed: 10 + layer * 15 + rng.nextDouble() * 10,
        size: 40 + layer * 20 + rng.nextDouble() * 30,
        widthRatio: 1.5 + rng.nextDouble(),
        layer: layer,
      ));
    }

    // Init Dust
    for (int i = 0; i < 60; i++) {
      state.dust!.add(_DustParticle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        speedX: 5 + rng.nextDouble() * 10,
        speedY: (rng.nextDouble() - 0.5) * 5,
        size: 1 + rng.nextDouble() * 3,
        shimmerOffset: rng.nextDouble() * math.pi * 2,
      ));
    }

    // Init Sun Rays
    for (int i = 0; i < 36; i++) {
      state.rays!.add(_SunRay(
        angle: (i / 36.0) * 2 * math.pi,
        lengthBase: 120 + rng.nextDouble() * 100,
        speed: (rng.nextDouble() - 0.5) * 0.2, // Rotation speed
        phase: rng.nextDouble() * math.pi * 2,
        thickness: 2 + rng.nextDouble() * 4,
      ));
    }
  }

  void _paintGoldenSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final skyGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          _creamGold.withOpacity(0.3), // High sky
          _peach.withOpacity(0.4), // Upper atmosphere
          _honeyglow.withOpacity(0.6), // Mid sky
          primaryColor.withOpacity(0.7), // Lower atmosphere
          accentColor.withOpacity(0.5), // Horizon area
          _burnishedGold.withOpacity(0.3), // Ground level
        ],
        [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      );

    canvas.drawRect(rect, skyGradient);
  }

  void _paintSun(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.82, size.height * 0.22);
    final sunRadius = 45 * intensity;

    // Slow breathing pulse based on accumulated time
    final sunPulse = 0.95 + 0.05 * math.sin(state.time * 0.5);

    // Sun's corona/outer glow
    final coronaPaint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        sunRadius * 3,
        [
          _warmAmber.withOpacity(0.4 * intensity),
          _honeyglow.withOpacity(0.25 * intensity),
          _sunsetOrange.withOpacity(0.1 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.3, 0.6, 1.0],
      );

    canvas.drawCircle(sunCenter, sunRadius * 3 * sunPulse, coronaPaint);

    // Sun's main glow
    final sunGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        sunRadius * 2,
        [
          Colors.white.withOpacity(0.9),
          _warmAmber.withOpacity(0.8),
          _sunsetOrange.withOpacity(0.6),
          accentColor.withOpacity(0.3),
        ],
        [0.0, 0.4, 0.7, 1.0],
      );

    canvas.drawCircle(sunCenter, sunRadius * 1.8 * sunPulse, sunGlowPaint);

    // Sun's core
    final sunCorePaint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        sunRadius,
        [
          Colors.white.withOpacity(0.95),
          _warmAmber.withOpacity(0.9),
          _deepGold.withOpacity(0.7),
        ],
        [0.0, 0.6, 1.0],
      );

    canvas.drawCircle(sunCenter, sunRadius * sunPulse, sunCorePaint);
  }

  void _updateAndPaintSunRays(Canvas canvas, Size size) {
    if (state.rays == null) return;

    final sunPosition = Offset(size.width * 0.82, size.height * 0.22);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var ray in state.rays!) {
      // Rotate slowly based on constant speed
      ray.angle += ray.speed * 0.01;

      // Shimmer intensity
      final rayIntensity = 0.5 + 0.5 * math.sin(state.time * 2 + ray.phase);
      final rayLength = (ray.lengthBase + math.sin(state.time + ray.phase) * 20) * intensity;
      final rayOpacity = (0.15 + rayIntensity * 0.15) * intensity;

      if (rayOpacity > 0.05) {
        final endPoint = Offset(
          sunPosition.dx + math.cos(ray.angle) * rayLength,
          sunPosition.dy + math.sin(ray.angle) * rayLength,
        );

        paint
          ..strokeWidth = ray.thickness * intensity
          ..shader = ui.Gradient.linear(
            sunPosition,
            endPoint,
            [
              _warmAmber.withOpacity(rayOpacity),
              _honeyglow.withOpacity(rayOpacity * 0.6),
              Colors.transparent,
            ],
            [0.0, 0.7, 1.0],
          );

        canvas.drawLine(sunPosition, endPoint, paint);
      }
    }
  }

  void _updateAndPaintClouds(Canvas canvas, Size size, double dt) {
    if (state.clouds == null) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final sunPosition = Offset(size.width * 0.82, size.height * 0.22);

    for (var cloud in state.clouds!) {
      // Move clouds continuously
      cloud.x += cloud.speed * dt * intensity;

      // Wrap smoothly around screen
      if (cloud.x > size.width + 200) {
        cloud.x = -200;
        cloud.y = size.height * (0.1 + math.Random().nextDouble() * 0.4);
      }

      // Determine lighting based on sun position
      final cloudCenter = Offset(cloud.x, cloud.y);
      final dist = (cloudCenter - sunPosition).distance;
      final sunInfluence = math.max(0.0, 1.0 - (dist / (size.width * 0.6)));

      // Colors shift based on proximity to sun
      final cloudColor = Color.lerp(Color.lerp(_peach, _rosyGold, 0.5)!, _creamGold, sunInfluence)!;

      final opacity = (0.1 + sunInfluence * 0.2 + cloud.layer * 0.05) * intensity;

      paint.color = cloudColor.withOpacity(opacity);

      // Draw cloud shape
      _drawCloudShape(canvas, paint, cloudCenter, cloud.size * intensity, cloud.size * 0.6 * intensity);
    }
  }

  void _drawCloudShape(Canvas canvas, Paint paint, Offset center, double width, double height) {
    // Main body
    canvas.drawOval(Rect.fromCenter(center: center, width: width * 1.5, height: height), paint);
    // Puffs
    canvas.drawCircle(center + Offset(-width * 0.4, height * 0.1), height * 0.6, paint);
    canvas.drawCircle(center + Offset(width * 0.3, -height * 0.2), height * 0.7, paint);
  }

  void _paintAtmosphericHaze(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      // Gently shifting haze
      final hazeY = size.height * (0.5 + i * 0.12) + math.sin(state.time * 0.2 + i) * 10 * intensity;
      final hazeWidth = size.width * (0.8 + i * 0.1);
      final hazeHeight = (40 + i * 10) * intensity;

      final hazeColors = [_peach, _honeyglow, _warmAmber, _rosyGold];
      paint.color = hazeColors[i % hazeColors.length].withOpacity(0.05 * intensity);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, hazeY),
          width: hazeWidth,
          height: hazeHeight,
        ),
        paint,
      );
    }
  }

  void _updateAndPaintFloatingDust(Canvas canvas, Size size, double dt) {
    if (state.dust == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in state.dust!) {
      // Update position
      particle.x += particle.speedX * dt * intensity;
      particle.y += particle.speedY * dt * intensity;

      // Wrap
      if (particle.x > size.width) particle.x = 0;
      if (particle.y > size.height) particle.y = 0;
      if (particle.y < 0) particle.y = size.height;

      // Shimmer based on time and offset
      final shimmer = 0.5 + 0.5 * math.sin(state.time * 2 + particle.shimmerOffset);

      if (shimmer > 0.4) {
        final lightIntensity = (shimmer - 0.4) / 0.6;
        final pSize = particle.size * intensity;

        paint.color = _creamGold.withOpacity(0.4 * lightIntensity * intensity);
        canvas.drawCircle(Offset(particle.x, particle.y), pSize, paint);

        if (lightIntensity > 0.8) {
          paint.color = Colors.white.withOpacity(0.6 * lightIntensity * intensity);
          canvas.drawCircle(Offset(particle.x, particle.y), pSize * 0.5, paint);
        }
      }
    }
  }

  void _paintLensFlares(Canvas canvas, Size size) {
    final sunPosition = Offset(size.width * 0.82, size.height * 0.22);
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    // Vector from sun to center
    final dx = center.dx - sunPosition.dx;
    final dy = center.dy - sunPosition.dy;

    // Draw flares along this line extending past center
    final count = 6;
    for (int i = 0; i < count; i++) {
      final dist = (i + 1) * 0.4; // Distance multiplier
      final pos = Offset(sunPosition.dx + dx * dist, sunPosition.dy + dy * dist);

      final size = (5 + i * 4) * intensity;
      final opacity = 0.1 + 0.05 * math.sin(state.time + i); // Slight shimmer

      if (i % 2 == 0) {
        paint.color = _honeyglow.withOpacity(opacity);
        canvas.drawCircle(pos, size, paint);
      } else {
        paint.color = _peach.withOpacity(opacity);
        // Hexagon shape
        _drawHexagon(canvas, paint, pos, size);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintWarmGlow(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Overall warm atmospheric glow
    final warmGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.75, size.height * 0.3),
        size.width * 0.9,
        [
          _warmAmber.withOpacity(0.06 * intensity),
          _honeyglow.withOpacity(0.04 * intensity),
          _peach.withOpacity(0.02 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.4, 0.7, 1.0],
      );

    canvas.drawRect(rect, warmGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _EnhancedGoldenHourPainter oldDelegate) {
    return animationEnabled;
  }
}
