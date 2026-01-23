import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// PETRICHOR (RAINY WINDOW) THEME BUILDER
// ============================================================================

AppTheme buildPetrichorTheme() {
  final baseTextTheme = GoogleFonts.loraTextTheme();
  final bodyTextTheme = GoogleFonts.interTextTheme();

  return AppTheme(
    type: ThemeType.petrichor,
    isDark: true,

    // Primary colors - muted steel blue
    primaryColor: const Color(0xFF6B8FA3), // Steel blue
    primaryVariant: const Color(0xFF4A6E82), // Deeper steel
    onPrimary: Colors.white,

    // Secondary colors - warm amber (distant lights)
    accentColor: const Color(0xFFD4A574), // Warm amber
    onAccent: const Color(0xFF2C2C2C),

    // Background colors - deep slate
    background: const Color(0xFF1C2127), // Deep slate
    surface: const Color(0xFF252B33), // Slightly lighter slate
    surfaceVariant: const Color(0xFF2E353E), // Card surfaces

    // Text colors - soft and muted
    textPrimary: const Color(0xFFE8ECF0), // Soft white
    textSecondary: const Color(0xFFA0AAB4), // Muted gray-blue
    textDisabled: const Color(0xFF5C6670), // Dark gray

    // UI colors
    divider: const Color(0xFF3A424C),
    toolbarColor: const Color(0xFF252B33),
    error: const Color(0xFFCF6679),
    success: const Color(0xFF81C784),
    warning: const Color(0xFFFFB74D),

    // Grid colors
    gridLine: const Color(0xFF3A424C),
    gridBackground: const Color(0xFF252B33),

    // Canvas colors
    canvasBackground: const Color(0xFF1C2127),
    selectionOutline: const Color(0xFF6B8FA3),
    selectionFill: const Color(0x306B8FA3),

    // Icon colors
    activeIcon: const Color(0xFF6B8FA3),
    inactiveIcon: const Color(0xFFA0AAB4),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFE8ECF0),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFE8ECF0),
        fontWeight: FontWeight.w400,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE8ECF0),
        fontWeight: FontWeight.w500,
      ),
      titleMedium: bodyTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE8ECF0),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE8ECF0),
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFA0AAB4),
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFF6B8FA3),
        fontWeight: FontWeight.w600,
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// PETRICHOR ANIMATED BACKGROUND
// ============================================================================

class PetrichorBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const PetrichorBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
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

    final rainState = useMemoized(() => _PetrichorState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _PetrichorPainter(
          repaint: controller,
          state: rainState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PetrichorState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Raindrop>? drops;
  List<_StreamingDrop>? streams;
  List<_DistantLight>? lights;
  List<_Ripple>? ripples;
  double nextDropTime = 0;
  double nextRippleTime = 0;
}

class _Raindrop {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  bool isStreaming;
  double streamLength;
  double wobble;
  double wobbleSpeed;

  _Raindrop({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    this.isStreaming = false,
    this.streamLength = 0,
    required this.wobble,
    required this.wobbleSpeed,
  });
}

class _StreamingDrop {
  double x;
  double y;
  double targetY;
  double speed;
  double size;
  double opacity;
  List<Offset> trail;
  double wobblePhase;
  bool merging;
  double mergeProgress;

  _StreamingDrop({
    required this.x,
    required this.y,
    required this.targetY,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.trail,
    required this.wobblePhase,
    this.merging = false,
    this.mergeProgress = 0,
  });
}

class _DistantLight {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double flickerSpeed;
  final double flickerPhase;

  const _DistantLight({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.flickerSpeed,
    required this.flickerPhase,
  });
}

class _Ripple {
  double x;
  double y;
  double radius;
  double maxRadius;
  double opacity;
  double speed;

  _Ripple({
    required this.x,
    required this.y,
    required this.radius,
    required this.maxRadius,
    required this.opacity,
    required this.speed,
  });
}

class _PetrichorPainter extends CustomPainter {
  final _PetrichorState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Color palette
  static const Color _slateDeep = Color(0xFF1C2127);
  static const Color _slateMid = Color(0xFF2E353E);
  static const Color _slateLight = Color(0xFF4A545E);
  static const Color _rainBlue = Color(0xFF6B8FA3);
  static const Color _waterHighlight = Color(0xFFB8D4E8);
  static const Color _warmLight = Color(0xFFD4A574);
  static const Color _coldLight = Color(0xFF8FB8D4);
  static const Color _fogGray = Color(0xFF5C6670);

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _path = Path();
  final math.Random _rng = math.Random();

  _PetrichorPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  }) : super(repaint: repaint);

  double _wave(double speed, [double offset = 0]) => math.sin(state.time * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialize elements
    state.drops ??= _generateDrops(size);
    state.streams ??= _generateStreams(size);
    state.lights ??= _generateLights(size);
    state.ripples ??= [];

    // Update animations
    _updateDrops(size, dt);
    _updateStreams(size, dt);
    _updateRipples(dt);
    _spawnNewDrops(size, dt);

    // Layer 1: Blurred cityscape/background through window
    _paintDistantScene(canvas, size);

    // Layer 2: Distant blurred lights
    _paintDistantLights(canvas, size);

    // Layer 3: Fog/mist layer
    _paintFogLayer(canvas, size);

    // Layer 4: Window glass tint
    _paintGlassTint(canvas, size);

    // Layer 5: Water film distortion
    _paintWaterFilm(canvas, size);

    // Layer 6: Streaming water drops
    _paintStreamingDrops(canvas, size);

    // Layer 7: Static/sliding raindrops
    _paintRaindrops(canvas, size);

    // Layer 8: Ripples from impacts
    _paintRipples(canvas, size);

    // Layer 9: Falling rain in foreground
    _paintFallingRain(canvas, size);

    // Layer 10: Glass reflections
    _paintGlassReflections(canvas, size);

    // Layer 11: Condensation texture
    _paintCondensation(canvas, size);

    // Layer 12: Vignette
    _paintVignette(canvas, size);
  }

  List<_Raindrop> _generateDrops(Size size) {
    final drops = <_Raindrop>[];
    final rng = math.Random(42);

    for (int i = 0; i < 40; i++) {
      drops.add(_Raindrop(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 3 + rng.nextDouble() * 8,
        speed: 0.02 + rng.nextDouble() * 0.04,
        opacity: 0.4 + rng.nextDouble() * 0.4,
        wobble: rng.nextDouble() * math.pi * 2,
        wobbleSpeed: 0.5 + rng.nextDouble() * 1.5,
      ));
    }

    return drops;
  }

  List<_StreamingDrop> _generateStreams(Size size) {
    final streams = <_StreamingDrop>[];
    final rng = math.Random(123);

    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble();
      streams.add(_StreamingDrop(
        x: x,
        y: rng.nextDouble() * 0.3,
        targetY: 0.7 + rng.nextDouble() * 0.3,
        speed: 0.08 + rng.nextDouble() * 0.12,
        size: 4 + rng.nextDouble() * 6,
        opacity: 0.5 + rng.nextDouble() * 0.3,
        trail: [],
        wobblePhase: rng.nextDouble() * math.pi * 2,
      ));
    }

    return streams;
  }

  List<_DistantLight> _generateLights(Size size) {
    final lights = <_DistantLight>[];
    final rng = math.Random(456);

    final lightColors = [
      _warmLight,
      _coldLight,
      const Color(0xFFE8B4B4), // Soft pink
      const Color(0xFFB4E8B4), // Soft green
      const Color(0xFFE8E4B4), // Soft yellow
    ];

    for (int i = 0; i < 15; i++) {
      lights.add(_DistantLight(
        x: rng.nextDouble(),
        y: 0.2 + rng.nextDouble() * 0.5,
        size: 15 + rng.nextDouble() * 40,
        color: lightColors[rng.nextInt(lightColors.length)],
        flickerSpeed: 0.5 + rng.nextDouble() * 2,
        flickerPhase: rng.nextDouble() * math.pi * 2,
      ));
    }

    return lights;
  }

  void _updateDrops(Size size, double dt) {
    for (final drop in state.drops!) {
      // Gravity pulls drops down slowly
      drop.y += drop.speed * dt * intensity;

      // Slight horizontal wobble
      drop.x += math.sin(state.time * drop.wobbleSpeed + drop.wobble) * 0.0005 * intensity;

      // Reset when off screen
      if (drop.y > 1.1) {
        drop.y = -0.1;
        drop.x = _rng.nextDouble();
        drop.size = 3 + _rng.nextDouble() * 8;
      }

      // Keep x in bounds
      drop.x = drop.x.clamp(0.0, 1.0);
    }
  }

  void _updateStreams(Size size, double dt) {
    for (final stream in state.streams!) {
      if (stream.merging) {
        stream.mergeProgress += dt * 2;
        if (stream.mergeProgress >= 1.0) {
          stream.merging = false;
          stream.mergeProgress = 0;
          stream.y = _rng.nextDouble() * 0.2;
          stream.x = _rng.nextDouble();
          stream.trail.clear();
        }
        continue;
      }

      final prevY = stream.y;

      // Move down with variable speed
      final speedVariation = 1 + _wave(0.5, stream.wobblePhase) * 0.3;
      stream.y += stream.speed * dt * speedVariation * intensity;

      // Horizontal wobble as it slides
      final wobble = _wave(1.5, stream.wobblePhase + stream.y * 10) * 0.008;
      stream.x += wobble * intensity;

      // Add to trail
      if ((stream.y - prevY).abs() > 0.005) {
        stream.trail.add(Offset(stream.x, stream.y));
        if (stream.trail.length > 25) {
          stream.trail.removeAt(0);
        }
      }

      // Check if reached target or bottom
      if (stream.y >= stream.targetY || stream.y > 1.0) {
        stream.merging = true;
        stream.mergeProgress = 0;
      }

      stream.x = stream.x.clamp(0.05, 0.95);
    }
  }

  void _updateRipples(double dt) {
    state.ripples!.removeWhere((ripple) {
      ripple.radius += ripple.speed * dt * 60;
      ripple.opacity -= dt * 1.5;
      return ripple.opacity <= 0 || ripple.radius > ripple.maxRadius;
    });
  }

  void _spawnNewDrops(Size size, double dt) {
    state.nextDropTime -= dt;
    state.nextRippleTime -= dt;

    if (state.nextDropTime <= 0) {
      state.nextDropTime = 0.1 + _rng.nextDouble() * 0.3;

      // Occasionally spawn a new static drop
      if (state.drops!.length < 60 && _rng.nextDouble() > 0.7) {
        state.drops!.add(_Raindrop(
          x: _rng.nextDouble(),
          y: -0.05,
          size: 3 + _rng.nextDouble() * 8,
          speed: 0.02 + _rng.nextDouble() * 0.04,
          opacity: 0.4 + _rng.nextDouble() * 0.4,
          wobble: _rng.nextDouble() * math.pi * 2,
          wobbleSpeed: 0.5 + _rng.nextDouble() * 1.5,
        ));
      }
    }

    if (state.nextRippleTime <= 0) {
      state.nextRippleTime = 0.3 + _rng.nextDouble() * 0.8;

      // Spawn ripple
      state.ripples!.add(_Ripple(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 0,
        maxRadius: 20 + _rng.nextDouble() * 30,
        opacity: 0.3 + _rng.nextDouble() * 0.2,
        speed: 0.8 + _rng.nextDouble() * 0.4,
      ));
    }
  }

  void _paintDistantScene(Canvas canvas, Size size) {
    // Blurred cityscape gradient
    final sceneGradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [
        const Color(0xFF2A3540), // Dark sky
        const Color(0xFF1E2832), // Mid
        const Color(0xFF151C24), // Ground
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = sceneGradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;

    // Abstract building shapes
    _fillPaint.color = const Color(0xFF0F1419).withOpacity(0.6);
    final rng = math.Random(789);

    for (int i = 0; i < 8; i++) {
      final buildingX = i * size.width / 7 - size.width * 0.05;
      final buildingW = size.width * (0.08 + rng.nextDouble() * 0.1);
      final buildingH = size.height * (0.2 + rng.nextDouble() * 0.4);
      final buildingY = size.height - buildingH;

      canvas.drawRect(
        Rect.fromLTWH(buildingX, buildingY, buildingW, buildingH),
        _fillPaint,
      );
    }
  }

  void _paintDistantLights(Canvas canvas, Size size) {
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 25 * intensity);

    for (final light in state.lights!) {
      final flicker = _norm(light.flickerSpeed, light.flickerPhase) * 0.4 + 0.6;
      final x = light.x * size.width;
      final y = light.y * size.height;

      // Outer glow
      _fillPaint.color = light.color.withOpacity(0.15 * flicker * intensity);
      canvas.drawCircle(Offset(x, y), light.size * 1.5 * intensity, _fillPaint);

      // Inner core
      _fillPaint.color = light.color.withOpacity(0.25 * flicker * intensity);
      canvas.drawCircle(Offset(x, y), light.size * 0.8 * intensity, _fillPaint);
    }

    _fillPaint.maskFilter = null;
  }

  void _paintFogLayer(Canvas canvas, Size size) {
    // Animated fog layers
    for (int layer = 0; layer < 3; layer++) {
      final yOffset = _wave(0.1, layer * 2) * 20 * intensity;
      final xOffset = _wave(0.08, layer * 1.5 + 1) * 30 * intensity;

      final fogGradient = ui.Gradient.linear(
        Offset(xOffset, size.height * (0.3 + layer * 0.15) + yOffset),
        Offset(size.width + xOffset, size.height * (0.5 + layer * 0.15) + yOffset),
        [
          Colors.transparent,
          _fogGray.withOpacity(0.06 * intensity),
          _fogGray.withOpacity(0.08 * intensity),
          _fogGray.withOpacity(0.04 * intensity),
          Colors.transparent,
        ],
        const [0.0, 0.2, 0.5, 0.8, 1.0],
      );

      _fillPaint.shader = fogGradient;
      canvas.drawRect(Offset.zero & size, _fillPaint);
      _fillPaint.shader = null;
    }
  }

  void _paintGlassTint(Canvas canvas, Size size) {
    // Subtle blue-gray glass tint
    _fillPaint.color = _rainBlue.withOpacity(0.08 * intensity);
    canvas.drawRect(Offset.zero & size, _fillPaint);
  }

  void _paintWaterFilm(Canvas canvas, Size size) {
    // Subtle water film with distortion effect
    final filmPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    // Organic water film patches
    final rng = math.Random(321);
    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 50 + rng.nextDouble() * 150;
      final h = 30 + rng.nextDouble() * 80;

      final wobbleX = _wave(0.2, i * 0.5) * 10;
      final wobbleY = _wave(0.15, i * 0.7 + 1) * 8;

      filmPaint.color = _waterHighlight.withOpacity(0.02 * intensity);

      _path.reset();
      _path.addOval(Rect.fromCenter(
        center: Offset(x + wobbleX, y + wobbleY),
        width: w,
        height: h,
      ));
      canvas.drawPath(_path, filmPaint);
    }
  }

  void _paintStreamingDrops(Canvas canvas, Size size) {
    for (final stream in state.streams!) {
      if (stream.trail.isEmpty) continue;

      final opacity = stream.merging ? stream.opacity * (1 - stream.mergeProgress) : stream.opacity;

      // Draw trail
      if (stream.trail.length > 1) {
        _path.reset();
        final firstPoint = stream.trail.first;
        _path.moveTo(firstPoint.dx * size.width, firstPoint.dy * size.height);

        for (int i = 1; i < stream.trail.length; i++) {
          final point = stream.trail[i];
          final prevPoint = stream.trail[i - 1];

          final ctrl = Offset(
            (point.dx + prevPoint.dx) / 2 * size.width,
            (point.dy + prevPoint.dy) / 2 * size.height,
          );

          _path.quadraticBezierTo(
            ctrl.dx,
            ctrl.dy,
            point.dx * size.width,
            point.dy * size.height,
          );
        }

        // Trail stroke with gradient effect
        _strokePaint.strokeWidth = stream.size * 0.6 * intensity;
        _strokePaint.strokeCap = StrokeCap.round;
        _strokePaint.color = _waterHighlight.withOpacity(opacity * 0.3 * intensity);
        canvas.drawPath(_path, _strokePaint);
      }

      // Draw drop head
      final headX = stream.x * size.width;
      final headY = stream.y * size.height;
      final dropSize = stream.size * intensity;

      // Drop shadow/refraction
      _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, dropSize * 0.5);
      _fillPaint.color = _slateDeep.withOpacity(0.3 * opacity * intensity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headX + 2, headY + 2),
          width: dropSize * 1.2,
          height: dropSize * 1.8,
        ),
        _fillPaint,
      );
      _fillPaint.maskFilter = null;

      // Drop body - elongated
      final dropGradient = ui.Gradient.radial(
        Offset(headX - dropSize * 0.2, headY - dropSize * 0.3),
        dropSize,
        [
          _waterHighlight.withOpacity(opacity * 0.7 * intensity),
          _rainBlue.withOpacity(opacity * 0.4 * intensity),
          _rainBlue.withOpacity(opacity * 0.2 * intensity),
        ],
        const [0.0, 0.4, 1.0],
      );

      _fillPaint.shader = dropGradient;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headX, headY),
          width: dropSize * 1.0,
          height: dropSize * 1.6,
        ),
        _fillPaint,
      );
      _fillPaint.shader = null;

      // Highlight
      _fillPaint.color = Colors.white.withOpacity(opacity * 0.5 * intensity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headX - dropSize * 0.2, headY - dropSize * 0.4),
          width: dropSize * 0.3,
          height: dropSize * 0.2,
        ),
        _fillPaint,
      );
    }
  }

  void _paintRaindrops(Canvas canvas, Size size) {
    for (final drop in state.drops!) {
      final x = drop.x * size.width;
      final y = drop.y * size.height;
      final dropSize = drop.size * intensity;

      // Drop refraction shadow
      _fillPaint.color = _slateDeep.withOpacity(0.25 * drop.opacity * intensity);
      canvas.drawCircle(Offset(x + 1.5, y + 1.5), dropSize * 0.9, _fillPaint);

      // Main drop body
      final dropGradient = ui.Gradient.radial(
        Offset(x - dropSize * 0.25, y - dropSize * 0.25),
        dropSize,
        [
          _waterHighlight.withOpacity(drop.opacity * 0.6 * intensity),
          _rainBlue.withOpacity(drop.opacity * 0.3 * intensity),
          _rainBlue.withOpacity(drop.opacity * 0.15 * intensity),
        ],
        const [0.0, 0.5, 1.0],
      );

      _fillPaint.shader = dropGradient;
      canvas.drawCircle(Offset(x, y), dropSize, _fillPaint);
      _fillPaint.shader = null;

      // Bright highlight
      _fillPaint.color = Colors.white.withOpacity(drop.opacity * 0.6 * intensity);
      canvas.drawCircle(
        Offset(x - dropSize * 0.3, y - dropSize * 0.3),
        dropSize * 0.25,
        _fillPaint,
      );

      // Secondary highlight
      _fillPaint.color = Colors.white.withOpacity(drop.opacity * 0.25 * intensity);
      canvas.drawCircle(
        Offset(x + dropSize * 0.2, y + dropSize * 0.2),
        dropSize * 0.15,
        _fillPaint,
      );
    }
  }

  void _paintRipples(Canvas canvas, Size size) {
    _strokePaint.strokeWidth = 1.5 * intensity;

    for (final ripple in state.ripples!) {
      final x = ripple.x * size.width;
      final y = ripple.y * size.height;

      _strokePaint.color = _waterHighlight.withOpacity(ripple.opacity * intensity);
      canvas.drawCircle(Offset(x, y), ripple.radius * intensity, _strokePaint);

      // Inner ripple
      if (ripple.radius > 5) {
        _strokePaint.color = _waterHighlight.withOpacity(ripple.opacity * 0.5 * intensity);
        canvas.drawCircle(Offset(x, y), ripple.radius * 0.6 * intensity, _strokePaint);
      }
    }
  }

  void _paintFallingRain(Canvas canvas, Size size) {
    _strokePaint.strokeCap = StrokeCap.round;

    final rng = math.Random(654);
    final rainCount = (30 * intensity).round();

    for (int i = 0; i < rainCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final speed = 0.5 + rng.nextDouble() * 0.5;
      final length = 15 + rng.nextDouble() * 25;

      // Animate position
      final progress = (state.time * speed + i * 0.1) % 1.2;
      final y = progress * size.height * 1.2 - length;
      final x = baseX + _wave(0.3, i * 0.5) * 5;

      if (y > -length && y < size.height) {
        final opacity = 0.15 + rng.nextDouble() * 0.15;
        _strokePaint.strokeWidth = (1 + rng.nextDouble()) * intensity;
        _strokePaint.color = _waterHighlight.withOpacity(opacity * intensity);

        canvas.drawLine(
          Offset(x, y),
          Offset(x - 2, y + length * intensity),
          _strokePaint,
        );
      }
    }
  }

  void _paintGlassReflections(Canvas canvas, Size size) {
    // Subtle window frame reflection
    _strokePaint.strokeWidth = 1 * intensity;
    _strokePaint.color = Colors.white.withOpacity(0.03 * intensity);

    // Horizontal reflection line
    final reflectY = size.height * 0.3 + _wave(0.05) * 10;
    canvas.drawLine(
      Offset(0, reflectY),
      Offset(size.width, reflectY + 5),
      _strokePaint,
    );

    // Corner light reflection
    final cornerGlow = ui.Gradient.radial(
      Offset(size.width * 0.9, size.height * 0.1),
      size.width * 0.3,
      [
        Colors.white.withOpacity(0.04 * intensity),
        Colors.transparent,
      ],
    );

    _fillPaint.shader = cornerGlow;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintCondensation(Canvas canvas, Size size) {
    // Fine condensation droplets
    final rng = math.Random(987);
    _fillPaint.color = _waterHighlight.withOpacity(0.08 * intensity);

    for (int i = 0; i < (80 * intensity).round(); i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.5 + rng.nextDouble() * 1.5;

      canvas.drawCircle(Offset(x, y), r * intensity, _fillPaint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.75;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.3 * intensity),
        Colors.black.withOpacity(0.6 * intensity),
      ],
      const [0.4, 0.75, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _PetrichorPainter oldDelegate) => true;
}
