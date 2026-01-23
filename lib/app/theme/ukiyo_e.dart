import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// UKIYO-E WAVES THEME BUILDER
// ============================================================================

AppTheme buildUkiyoeWavesTheme() {
  final baseTextTheme = GoogleFonts.notoSerifJpTextTheme();
  final bodyTextTheme = GoogleFonts.notoSansJpTextTheme();

  return AppTheme(
    type: ThemeType.values.firstWhere(
      (t) => t.name == 'ukiyoEWaves',
      orElse: () => ThemeType.ocean,
    ),
    isDark: false,

    // Primary colors - traditional indigo blue
    primaryColor: const Color(0xFF1A4B8C),
    primaryVariant: const Color(0xFF0D3A6E),
    onPrimary: const Color(0xFFF5F0E6),

    // Secondary colors - wave foam white
    accentColor: const Color(0xFFF0E6D2),
    onAccent: const Color(0xFF1A3050),

    // Background colors - aged paper/sky
    background: const Color(0xFFF5EEE0),
    surface: const Color(0xFFFAF6EE),
    surfaceVariant: const Color(0xFFEDE5D5),

    // Text colors
    textPrimary: const Color(0xFF1A2830),
    textSecondary: const Color(0xFF3A5060),
    textDisabled: const Color(0xFF8A9AA5),

    // UI colors
    divider: const Color(0xFFD5CCBB),
    toolbarColor: const Color(0xFFFAF6EE),
    error: const Color(0xFFB85450),
    success: const Color(0xFF5A8A5A),
    warning: const Color(0xFFCCA050),

    // Grid colors
    gridLine: const Color(0xFFD5CCBB),
    gridBackground: const Color(0xFFFAF6EE),

    // Canvas colors
    canvasBackground: const Color(0xFFF5EEE0),
    selectionOutline: const Color(0xFF1A4B8C),
    selectionFill: const Color(0x301A4B8C),

    // Icon colors
    activeIcon: const Color(0xFF1A4B8C),
    inactiveIcon: const Color(0xFF3A5060),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF1A2830),
        fontWeight: FontWeight.w400,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF1A2830),
        fontWeight: FontWeight.w400,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF1A2830),
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF1A2830),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF1A2830),
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF3A5060),
        fontWeight: FontWeight.w400,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFF1A4B8C),
        fontWeight: FontWeight.w500,
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// UKIYO-E WAVES ANIMATED BACKGROUND
// ============================================================================

class UkiyoeWavesBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const UkiyoeWavesBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
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
    final ukiyoState = useMemoized(() => _UkiyoState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnhancedUkiyoePainter(
          repaint: controller,
          state: ukiyoState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for physics and objects
class _UkiyoState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_SprayParticle>? spray;
  List<_PaperGrain>? grain;
}

class _SprayParticle {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;
  double opacity;

  _SprayParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
  });
}

class _PaperGrain {
  double x;
  double y;
  double length;
  double angle;

  _PaperGrain({
    required this.x,
    required this.y,
    required this.length,
    required this.angle,
  });
}

class _EnhancedUkiyoePainter extends CustomPainter {
  final _UkiyoState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Palette
  static const Color _indigoDeep = Color(0xFF0D3260);
  static const Color _indigo = Color(0xFF1A4B8C);
  static const Color _indigoLight = Color(0xFF3A6BA8);
  static const Color _indigoMid = Color(0xFF2A5A98);
  static const Color _foam = Color(0xFFF8F4EC);
  static const Color _paperDark = Color(0xFFE8DCC8);
  static const Color _mountFuji = Color(0xFF4A6080);
  static const Color _snow = Color(0xFFFAF8F5);

  final math.Random _rng = math.Random(888);

  _EnhancedUkiyoePainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Time accumulation
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    // Initialization
    if (state.spray == null) _initWorld(size);

    _paintSky(canvas, size);
    _paintMountFuji(canvas, size);
    _paintDistantWaves(canvas, size);
    _paintMidWaves(canvas, size);
    _paintMainWave(canvas, size);
    _paintForegroundWave(canvas, size);
    _updateAndPaintSpray(canvas, size, dt);
    _paintWoodblockTexture(canvas, size);
  }

  void _initWorld(Size size) {
    state.spray = [];
    state.grain = [];
    final rng = math.Random(1234);

    // Init Spray Particles
    for (int i = 0; i < 40; i++) {
      state.spray!.add(_SprayParticle(
        x: size.width * (0.2 + rng.nextDouble() * 0.4),
        y: size.height * (0.4 + rng.nextDouble() * 0.3),
        speedX: (rng.nextDouble() - 0.5) * 50,
        speedY: (rng.nextDouble() - 0.5) * 50,
        size: 1 + rng.nextDouble() * 3,
        opacity: rng.nextDouble(),
      ));
    }

    // Init Static Paper Grain
    for (int i = 0; i < 60; i++) {
      state.grain!.add(_PaperGrain(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        length: 5 + rng.nextDouble() * 15,
        angle: (rng.nextDouble() - 0.5) * 0.1, // Horizontal bias
      ));
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Vintage gradation: Darker blue at top fading to paper color
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height * 0.5),
      [
        const Color(0xFFF0E8D8),
        const Color(0xFFE8DCC8),
        const Color(0xFFDDD0BC),
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  void _paintMountFuji(Canvas canvas, Size size) {
    final fujiCenter = size.width * 0.72;
    final fujiBase = size.height * 0.38;
    final fujiHeight = size.height * 0.28;

    final paint = Paint()..style = PaintingStyle.fill;
    final path = Path();

    // Mountain body
    path.moveTo(fujiCenter - size.width * 0.18, fujiBase);
    path.quadraticBezierTo(
      fujiCenter - size.width * 0.08,
      fujiBase - fujiHeight * 0.6,
      fujiCenter,
      fujiBase - fujiHeight,
    );
    path.quadraticBezierTo(
      fujiCenter + size.width * 0.08,
      fujiBase - fujiHeight * 0.6,
      fujiCenter + size.width * 0.18,
      fujiBase,
    );
    path.close();

    paint.color = _mountFuji.withOpacity(0.5 * intensity);
    canvas.drawPath(path, paint);

    // Snow cap
    final snowPath = Path();
    snowPath.moveTo(fujiCenter - size.width * 0.05, fujiBase - fujiHeight * 0.7);
    snowPath.quadraticBezierTo(
      fujiCenter,
      fujiBase - fujiHeight * 1.02,
      fujiCenter + size.width * 0.05,
      fujiBase - fujiHeight * 0.7,
    );
    // Jagged snow line
    for (double x = fujiCenter + size.width * 0.05; x >= fujiCenter - size.width * 0.05; x -= size.width * 0.015) {
      final jag = math.sin(x * 0.5) * size.height * 0.008;
      snowPath.lineTo(x, fujiBase - fujiHeight * 0.68 + jag);
    }
    snowPath.close();

    paint.color = _snow.withOpacity(0.6 * intensity);
    canvas.drawPath(snowPath, paint);
  }

  void _paintDistantWaves(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Slow rolling background waves
    for (int layer = 0; layer < 3; layer++) {
      final y = size.height * (0.42 + layer * 0.04);
      final waveHeight = (4 + layer * 2) * intensity;
      final waveLength = size.width * (0.08 + layer * 0.02);

      // Continuous phase
      final phase = state.time * (0.5 - layer * 0.1) + layer * 1.5;

      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 4) {
        final waveY = y + math.sin((x / waveLength) * 2 * math.pi + phase) * waveHeight;
        path.lineTo(x, waveY);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final opacity = (0.25 - layer * 0.05) * intensity;
      paint.color = Color.lerp(_indigoLight, _indigo, layer / 3)!.withOpacity(opacity);
      canvas.drawPath(path, paint);
    }
  }

  void _paintMidWaves(Canvas canvas, Size size) {
    // Medium rolling waves
    for (int wave = 0; wave < 2; wave++) {
      final baseY = size.height * (0.52 + wave * 0.12);
      final waveHeight = size.height * (0.06 + wave * 0.02) * intensity;
      // Continuous phase
      final phase = state.time * 0.6 + wave * 2.0;

      _drawUkiyoeWave(
        canvas,
        size,
        baseY: baseY,
        waveHeight: waveHeight,
        wavelength: size.width * (0.35 - wave * 0.05),
        phase: phase,
        color: Color.lerp(_indigo, _indigoDeep, wave / 2)!,
        opacity: (0.6 - wave * 0.1) * intensity,
        foamIntensity: 0.4 + wave * 0.1,
      );
    }
  }

  void _paintMainWave(Canvas canvas, Size size) {
    // The Great Wave - focal wave
    final baseY = size.height * 0.68;
    final waveHeight = size.height * 0.22 * intensity;
    final phase = math.sin(state.time * 0.8); // Gentle heaving

    final path = Path();
    path.moveTo(0, baseY + waveHeight * 0.3);

    // Build up to the crest
    final crestX = size.width * 0.35;
    final crestY = baseY - waveHeight;

    // Leading edge
    path.quadraticBezierTo(
      size.width * 0.1,
      baseY + phase * 10,
      size.width * 0.2,
      baseY - waveHeight * 0.3 + phase * 20,
    );

    // Rising to crest
    path.quadraticBezierTo(
      size.width * 0.28,
      baseY - waveHeight * 0.8,
      crestX,
      crestY + phase * 5,
    );

    // The iconic curling crest
    path.cubicTo(
      crestX + size.width * 0.08,
      crestY - waveHeight * 0.1,
      crestX + size.width * 0.12,
      crestY + waveHeight * 0.2,
      crestX + size.width * 0.06,
      crestY + waveHeight * 0.45,
    );

    // Inner curl
    path.quadraticBezierTo(
      crestX + size.width * 0.02,
      crestY + waveHeight * 0.3,
      crestX - size.width * 0.02,
      crestY + waveHeight * 0.15,
    );

    // Continue wave after curl
    path.quadraticBezierTo(
      size.width * 0.5,
      baseY - waveHeight * 0.4 + phase * 10,
      size.width * 0.65,
      baseY - waveHeight * 0.2 + phase * 15,
    );

    path.quadraticBezierTo(
      size.width * 0.8,
      baseY + phase * 10,
      size.width,
      baseY + waveHeight * 0.2,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Wave gradient
    final waveGradient = ui.Gradient.linear(
      Offset(crestX, crestY),
      Offset(crestX, baseY + waveHeight * 0.5),
      [_indigoDeep, _indigo, _indigoMid],
      const [0.0, 0.4, 1.0],
    );

    final paint = Paint()..shader = waveGradient;
    canvas.drawPath(path, paint);

    _drawWaveFoamAndClaws(canvas, size, crestX, crestY, waveHeight, phase);
  }

  void _drawWaveFoamAndClaws(Canvas canvas, Size size, double crestX, double crestY, double waveHeight, double phase) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _foam
      ..strokeWidth = 3 * intensity
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _foam;

    // Main crest foam line
    final path = Path();
    path.moveTo(size.width * 0.18, crestY + waveHeight * 0.75);
    path.quadraticBezierTo(
      size.width * 0.26,
      crestY + waveHeight * 0.1,
      crestX - size.width * 0.02,
      crestY + phase * 5,
    );
    path.quadraticBezierTo(
      crestX + size.width * 0.06,
      crestY - waveHeight * 0.05,
      crestX + size.width * 0.1,
      crestY + waveHeight * 0.3,
    );

    canvas.drawPath(path, strokePaint);

    // Claws - animated fingers
    final clawCount = 8;
    for (int i = 0; i < clawCount; i++) {
      final progress = i / (clawCount - 1);
      final clawX = crestX - size.width * 0.02 + progress * size.width * 0.14;
      final clawBaseY = crestY + waveHeight * (0.05 + progress * 0.35);

      // Claws curl based on time
      final clawLength = (15 + (1 - progress) * 20) * intensity;
      final clawAngle = -0.3 + progress * 1.2 + math.sin(state.time * 2 + i) * 0.2;

      path.reset();
      path.moveTo(clawX, clawBaseY);

      final tipX = clawX + math.cos(clawAngle) * clawLength;
      final tipY = clawBaseY + math.sin(clawAngle) * clawLength;

      path.quadraticBezierTo(
        clawX + clawLength * 0.3 * math.cos(clawAngle - 0.3),
        clawBaseY + clawLength * 0.3 * math.sin(clawAngle - 0.3),
        tipX,
        tipY,
      );

      strokePaint.strokeWidth = (3 - progress * 1.5) * intensity;
      canvas.drawPath(path, strokePaint);

      // Foam drops at tips
      if (i % 2 == 0) {
        canvas.drawCircle(
          Offset(tipX + 2 * intensity, tipY + 3 * intensity),
          (2 + (1 - progress) * 2) * intensity,
          fillPaint,
        );
      }
    }
  }

  void _paintForegroundWave(Canvas canvas, Size size) {
    // Foreground wave - bottom of screen
    final baseY = size.height * 0.88;
    final waveHeight = size.height * 0.12 * intensity;
    final phase = math.sin(state.time * 0.7 + 1.5);

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseY + phase * 10);

    path.quadraticBezierTo(
      size.width * 0.15,
      baseY - waveHeight * 0.5 + phase * 8,
      size.width * 0.25,
      baseY - waveHeight + phase * 5,
    );

    path.cubicTo(
      size.width * 0.32,
      baseY - waveHeight * 1.1,
      size.width * 0.38,
      baseY - waveHeight * 0.6,
      size.width * 0.35,
      baseY - waveHeight * 0.3,
    );

    path.quadraticBezierTo(
      size.width * 0.5,
      baseY - waveHeight * 0.4 + phase * 10,
      size.width * 0.7,
      baseY - waveHeight * 0.2 + phase * 8,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      baseY + phase * 12,
      size.width,
      baseY + waveHeight * 0.1,
    );

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = _indigoDeep.withOpacity(0.85 * intensity));

    // Foam
    final strokePaint = Paint()
      ..strokeWidth = 2.5 * intensity
      ..style = PaintingStyle.stroke
      ..color = _foam.withOpacity(0.9);

    path.reset();
    path.moveTo(size.width * 0.08, baseY + phase * 8);
    path.quadraticBezierTo(
      size.width * 0.18,
      baseY - waveHeight * 0.6,
      size.width * 0.28,
      baseY - waveHeight * 0.9 + phase * 4,
    );
    path.quadraticBezierTo(
      size.width * 0.35,
      baseY - waveHeight * 0.5,
      size.width * 0.45,
      baseY - waveHeight * 0.35 + phase * 6,
    );

    canvas.drawPath(path, strokePaint);

    // Small claws on foreground wave
    for (int i = 0; i < 5; i++) {
      final clawX = size.width * (0.26 + i * 0.04);
      final clawY = baseY - waveHeight * (0.85 - i * 0.1) + phase * 2;
      final clawLen = (8 + i * 2) * intensity;
      final angle = 0.5 + i * 0.25;

      path.reset();
      path.moveTo(clawX, clawY);
      path.lineTo(
        clawX + math.cos(angle) * clawLen,
        clawY + math.sin(angle) * clawLen,
      );

      strokePaint.strokeWidth = (2.5 - i * 0.3) * intensity;
      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawUkiyoeWave(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double waveHeight,
    required double wavelength,
    required double phase,
    required Color color,
    required double opacity,
    required double foamIntensity,
  }) {
    final path = Path();
    path.moveTo(0, baseY);

    // Stylized wave shape
    for (double x = 0; x <= size.width; x += 3) {
      final normalizedX = x / wavelength;
      final waveY = baseY - math.sin(normalizedX * 2 * math.pi + phase * math.pi) * waveHeight;
      path.lineTo(x, waveY);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));

    // Foam line on crest
    if (foamIntensity > 0) {
      final strokePaint = Paint()
        ..strokeWidth = 2 * intensity * foamIntensity
        ..style = PaintingStyle.stroke
        ..color = _foam.withOpacity(opacity * foamIntensity);

      path.reset();
      var started = false;

      for (double x = 0; x <= size.width; x += 4) {
        final normalizedX = x / wavelength;
        final wavePhase = math.sin(normalizedX * 2 * math.pi + phase * math.pi);

        if (wavePhase > 0.7) {
          final waveY = baseY - wavePhase * waveHeight - 2 * intensity;
          if (!started) {
            path.moveTo(x, waveY);
            started = true;
          } else {
            path.lineTo(x, waveY);
          }
        } else if (started) {
          canvas.drawPath(path, strokePaint);
          path.reset();
          started = false;
        }
      }

      if (started) {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  void _updateAndPaintSpray(Canvas canvas, Size size, double dt) {
    if (state.spray == null) return;

    final paint = Paint()..color = _foam;

    for (var p in state.spray!) {
      // Physics
      p.x += p.speedX * dt * intensity;
      p.y += p.speedY * dt * intensity;
      p.speedY += 100 * dt; // Gravity

      // Reset if out of view
      if (p.y > size.height + 10 || p.x < -10 || p.x > size.width + 10) {
        // Respawn near the main crest
        final crestX = size.width * 0.35;
        final crestY = size.height * 0.46;
        final angle = -math.pi * 0.3 + _rng.nextDouble() * math.pi * 0.6;
        final dist = (10 + _rng.nextDouble() * 40) * intensity;

        p.x = crestX + math.cos(angle) * dist;
        p.y = crestY + math.sin(angle) * dist;
        p.speedX = (math.cos(angle) * 100 + (_rng.nextDouble() - 0.5) * 50);
        p.speedY = (math.sin(angle) * 100 - 50);
        p.opacity = 0.5 + _rng.nextDouble() * 0.5;
      }

      paint.color = _foam.withOpacity(p.opacity * intensity);
      canvas.drawCircle(Offset(p.x, p.y), p.size * intensity, paint);
    }
  }

  void _paintWoodblockTexture(Canvas canvas, Size size) {
    if (state.grain == null) return;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * intensity
      ..color = _paperDark.withOpacity(0.1 * intensity);

    for (var g in state.grain!) {
      final endX = g.x + math.cos(g.angle) * g.length * intensity;
      final endY = g.y + math.sin(g.angle) * g.length * intensity;
      canvas.drawLine(Offset(g.x, g.y), Offset(endX, endY), strokePaint);
    }

    // Edge darkening (like aged print)
    final edgeGradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.5),
      size.longestSide * 0.7,
      [
        Colors.transparent,
        _paperDark.withOpacity(0.15 * intensity),
      ],
    );

    canvas.drawRect(Offset.zero & size, Paint()..shader = edgeGradient);
  }

  @override
  bool shouldRepaint(covariant _EnhancedUkiyoePainter oldDelegate) {
    return true; // Always repaint
  }
}
