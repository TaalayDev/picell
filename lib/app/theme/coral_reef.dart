import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// CORAL REEF THEME BUILDER
// ============================================================================

AppTheme buildCoralReefTheme() {
  final baseTextTheme = GoogleFonts.quicksandTextTheme();
  final bodyTextTheme = GoogleFonts.openSansTextTheme();

  return AppTheme(
    type: ThemeType.coralReef,
    isDark: false, // Bright and colorful

    // Primary: Coral / Salmon
    primaryColor: const Color(0xFFFF7F50),
    // Variant: Darker Red/Orange
    primaryVariant: const Color(0xFFE55050),
    onPrimary: Colors.white,

    // Accent: Turquoise / Teal
    accentColor: const Color(0xFF40E0D0),
    onAccent: const Color(0xFF004D40),

    // Backgrounds: Ocean Blue gradients handled by painter, but set defaults
    background: const Color(0xFF2890B0), // Deep blue
    surface: const Color(0xFFE0F7FA), // Very light cyan
    surfaceVariant: const Color(0xFFB2EBF2),

    // Text: Dark Blue/Teal for contrast
    textPrimary: const Color(0xFF006064),
    textSecondary: const Color(0xFF00838F),
    textDisabled: const Color(0xFF80DEEA),

    // UI Colors
    divider: const Color(0xFF4DD0E1),
    toolbarColor: const Color(0xFF2890B0),
    error: const Color(0xFFD32F2F),
    success: const Color(0xFF388E3C),
    warning: const Color(0xFFFFA000),

    // Grid
    gridLine: const Color(0xFF80DEEA),
    gridBackground: const Color(0xFFE0F7FA),

    // Canvas
    canvasBackground: const Color(0xFFF0FCFF),
    selectionOutline: const Color(0xFFFF7F50),
    selectionFill: const Color(0x33FF7F50),

    // Icons
    activeIcon: const Color(0xFFFF7F50),
    inactiveIcon: const Color(0xFF0097A7),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF006064),
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF006064),
        fontWeight: FontWeight.bold,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF00838F),
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF004D40),
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF00695C),
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

// ============================================================================
// CORAL REEF ANIMATED BACKGROUND
// ============================================================================

class CoralReefBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CoralReefBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Controller acts as a ticker
    final controller = useAnimationController(
      duration: const Duration(seconds: 20),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    // 2. Persist state for smooth infinite time accumulation
    final reefState = useMemoized(() => _ReefState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CoralReefPainter(
          repaint: controller,
          state: reefState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class to hold accumulated time
class _ReefState {
  double time = 0;
  double lastFrameTimestamp = 0;
}

// Data structures
class _CoralData {
  final double x;
  final double baseY;
  final double height;
  final double width;
  final int colorIndex;
  final int type;
  final double phaseOffset;

  const _CoralData(this.x, this.baseY, this.height, this.width, this.colorIndex, this.type, this.phaseOffset);
}

class _FishData {
  final double baseX;
  final double baseY;
  final double size;
  final double speed;
  final double phaseOffset;
  final int colorIndex;
  final bool facingRight;

  const _FishData(this.baseX, this.baseY, this.size, this.speed, this.phaseOffset, this.colorIndex, this.facingRight);
}

class _BubbleData {
  final double x;
  final double size;
  final double speed;
  final double phaseOffset;
  final double wobbleSpeed;

  const _BubbleData(this.x, this.size, this.speed, this.phaseOffset, this.wobbleSpeed);
}

class _SeaweedData {
  final double x;
  final double height;
  final double phaseOffset;
  final int colorIndex;

  const _SeaweedData(this.x, this.height, this.phaseOffset, this.colorIndex);
}

class _CoralReefPainter extends CustomPainter {
  final _ReefState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Color palette
  static const Color _coral = Color(0xFFFF7F50);
  static const Color _coralPink = Color(0xFFFF9999);
  static const Color _coralRed = Color(0xFFE55050);
  static const Color _turquoise = Color(0xFF40E0D0);
  static const Color _seafoam = Color(0xFF70F0E0);
  static const Color _deepBlue = Color(0xFF1E90B0);
  static const Color _yellow = Color(0xFFFFE066);
  static const Color _purple = Color(0xFFAA77DD);
  static const Color _green = Color(0xFF66CC88);
  static const Color _sand = Color(0xFFF5E6C8);
  static const Color _white = Color(0xFFFFFFFF);

  static const List<Color> _coralColors = [_coral, _coralPink, _coralRed, _purple, _yellow, _turquoise];
  static const List<Color> _fishColors = [_yellow, _coral, _turquoise, _purple, _coralPink, _seafoam];
  static const List<Color> _seaweedColors = [_green, _seafoam, _turquoise];

  // Pre-computed data
  static const List<_CoralData> _corals = [
    _CoralData(0.06, 0.94, 0.20, 0.10, 0, 0, 0.0),
    _CoralData(0.16, 0.96, 0.14, 0.14, 1, 1, 0.5),
    _CoralData(0.26, 0.92, 0.24, 0.09, 2, 2, 1.0),
    _CoralData(0.38, 0.95, 0.16, 0.12, 3, 0, 1.5),
    _CoralData(0.50, 0.90, 0.28, 0.07, 4, 3, 2.0),
    _CoralData(0.62, 0.94, 0.15, 0.13, 5, 1, 2.5),
    _CoralData(0.74, 0.91, 0.22, 0.10, 0, 2, 3.0),
    _CoralData(0.84, 0.95, 0.17, 0.11, 1, 0, 3.5),
    _CoralData(0.94, 0.93, 0.19, 0.08, 2, 3, 4.0),
  ];

  static const List<_FishData> _fish = [
    _FishData(0.2, 0.28, 0.045, 0.10, 0.0, 0, true), // Reduced speeds slightly since we use seconds now
    _FishData(0.5, 0.18, 0.04, 0.08, 1.0, 1, false),
    _FishData(0.7, 0.38, 0.05, 0.12, 2.0, 2, true),
    _FishData(0.3, 0.48, 0.035, 0.09, 3.0, 3, false),
    _FishData(0.8, 0.22, 0.042, 0.11, 4.0, 4, true),
    _FishData(0.15, 0.42, 0.048, 0.07, 5.0, 5, false),
  ];

  static final List<_BubbleData> _bubbles = List.generate(18, (i) {
    final rng = math.Random(i * 111);
    return _BubbleData(
      rng.nextDouble(),
      2 + rng.nextDouble() * 5,
      0.05 + rng.nextDouble() * 0.1, // Adjusted speed for seconds
      rng.nextDouble() * 6.28,
      1.2 + rng.nextDouble() * 1.5,
    );
  });

  static const List<_SeaweedData> _seaweed = [
    _SeaweedData(0.04, 0.16, 0.0, 0),
    _SeaweedData(0.12, 0.20, 0.5, 1),
    _SeaweedData(0.22, 0.14, 1.0, 2),
    _SeaweedData(0.44, 0.22, 1.5, 0),
    _SeaweedData(0.58, 0.15, 2.0, 1),
    _SeaweedData(0.76, 0.18, 2.5, 2),
    _SeaweedData(0.88, 0.14, 3.0, 0),
    _SeaweedData(0.96, 0.17, 3.5, 1),
  ];

  // Reusable objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _path = Path();

  _CoralReefPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  }) : super(repaint: repaint);

  // Helper methods using accumulated time from state
  double _wave(double speed, [double offset = 0]) => math.sin(state.time * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    // Time Accumulation Logic
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    _paintWaterGradient(canvas, size);
    _paintCausticLight(canvas, size);
    _paintLightRays(canvas, size);
    _paintDistantFish(canvas, size);
    _paintSeaweed(canvas, size);
    _paintCorals(canvas, size);
    _paintSandyBottom(canvas, size);
    _paintFish(canvas, size);
    _paintBubbles(canvas, size);
    _paintWaterSurface(canvas, size);
    _paintParticles(canvas, size);
  }

  void _paintWaterGradient(Canvas canvas, Size size) {
    final gradient = ui.Gradient.linear(
      Offset.zero,
      Offset(0, size.height),
      const [
        Color(0xFFA8E8F0), // Bright surface
        Color(0xFF78D0E8), // Light blue
        Color(0xFF50C0D8), // Mid blue
        Color(0xFF38A8C8), // Deeper
        Color(0xFF2890B0), // Near bottom
      ],
      const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintCausticLight(Canvas canvas, Size size) {
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 25 * intensity);

    // Animated caustic patterns
    for (int i = 0; i < 8; i++) {
      final baseX = (i + 0.5) / 8 * size.width;
      final wobbleX = _wave(1.2, i * 1.5) * 30 * intensity;
      final wobbleY = _wave(0.9, i * 1.2 + 1.0) * 20 * intensity;
      final x = baseX + wobbleX;

      final pulse = _norm(1.5, i * 0.9) * 0.5 + 0.5;
      final causticSize = (40 + pulse * 30) * intensity;

      // Organic caustic shape
      _fillPaint.color = _white.withOpacity(0.12 * pulse * intensity);

      for (int j = 0; j < 3; j++) {
        final offsetX = _wave(1.8, i * 2 + j * 1.5) * 20 * intensity;
        final offsetY = _wave(1.4, i * 1.8 + j * 2.0) * 15 * intensity;
        final y = size.height * (0.15 + j * 0.2) + wobbleY + offsetY;

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + offsetX, y),
            width: causticSize * (1.2 - j * 0.2),
            height: causticSize * (0.6 - j * 0.1),
          ),
          _fillPaint,
        );
      }
    }

    _fillPaint.maskFilter = null;
  }

  void _paintLightRays(Canvas canvas, Size size) {
    for (int i = 0; i < 5; i++) {
      final baseX = size.width * (0.1 + i * 0.2);
      final sway = _wave(0.8, i * 1.0) * 25 * intensity;
      final pulse = _norm(0.6, i * 1.4) * 0.4 + 0.6;

      final x = baseX + sway;
      final rayWidth = (30 + i * 5) * intensity;

      _path.reset();
      _path.moveTo(x - rayWidth, 0);
      _path.lineTo(x + rayWidth, 0);
      _path.lineTo(x + rayWidth * 2.5 + sway, size.height * 0.75);
      _path.lineTo(x - rayWidth * 1.5 + sway, size.height * 0.75);
      _path.close();

      final gradient = ui.Gradient.linear(
        Offset(x, 0),
        Offset(x + sway, size.height * 0.75),
        [
          _white.withOpacity(0.1 * pulse * intensity),
          _white.withOpacity(0.03 * pulse * intensity),
        ],
      );

      _fillPaint.shader = gradient;
      canvas.drawPath(_path, _fillPaint);
    }

    _fillPaint.shader = null;
  }

  void _paintDistantFish(Canvas canvas, Size size) {
    // Deterministic random using loop index
    for (int i = 0; i < 10; i++) {
      // Create consistent random properties
      final r1 = ((i * 132.0) % 100) / 100.0;
      final r2 = ((i * 45.0) % 100) / 100.0;
      final r3 = ((i * 99.0) % 100) / 100.0;

      final baseX = r1;
      final y = size.height * (0.12 + r2 * 0.35);
      final fishSize = (5 + r3 * 8) * intensity;
      final speed = 0.05 + r1 * 0.05; // speed in screen-widths per second

      // Infinite wrapping position
      final swimProgress = (state.time * speed + i * 0.1) % 1.0;
      final x = (baseX + swimProgress) % 1.0 * size.width;

      _fillPaint.color = _deepBlue.withOpacity(0.18 * intensity);
      _drawSimpleFish(canvas, Offset(x, y), fishSize, i % 2 == 0);
    }
  }

  void _paintSeaweed(Canvas canvas, Size size) {
    for (final sw in _seaweed) {
      final baseX = sw.x * size.width;
      final height = sw.height * size.height * intensity;
      final color = _seaweedColors[sw.colorIndex];

      for (int blade = 0; blade < 4; blade++) {
        final x = baseX + (blade - 1.5) * 6 * intensity;
        final bladeHeight = height * (0.65 + blade * 0.12);
        // Sway uses accumulated time
        final sway = _wave(1.2, sw.phaseOffset + blade * 0.4) * 15 * intensity;
        final sway2 = _wave(1.8, sw.phaseOffset + blade * 0.6 + 1.0) * 8 * intensity;

        _path.reset();
        _path.moveTo(x - 2.5 * intensity, size.height);

        // Curved seaweed with multiple control points
        _path.cubicTo(
          x + sway * 0.3,
          size.height - bladeHeight * 0.33,
          x + sway * 0.7 + sway2 * 0.3,
          size.height - bladeHeight * 0.66,
          x + sway + sway2,
          size.height - bladeHeight,
        );

        _path.cubicTo(
          x + sway * 0.7 + sway2 * 0.3 + 3 * intensity,
          size.height - bladeHeight * 0.66,
          x + sway * 0.3 + 3 * intensity,
          size.height - bladeHeight * 0.33,
          x + 2.5 * intensity,
          size.height,
        );

        _path.close();

        final seaweedGradient = ui.Gradient.linear(
          Offset(x, size.height),
          Offset(x + sway, size.height - bladeHeight),
          [
            color.withOpacity(0.75),
            Color.lerp(color, _white, 0.2)!.withOpacity(0.6),
          ],
        );

        _fillPaint.shader = seaweedGradient;
        canvas.drawPath(_path, _fillPaint);
      }
    }

    _fillPaint.shader = null;
  }

  void _paintCorals(Canvas canvas, Size size) {
    for (final coral in _corals) {
      final x = coral.x * size.width;
      final baseY = coral.baseY * size.height;
      final height = coral.height * size.height * intensity;
      final width = coral.width * size.width * intensity;
      final color = _coralColors[coral.colorIndex];
      final sway = _wave(0.8, coral.phaseOffset) * 4 * intensity;

      switch (coral.type) {
        case 0:
          _drawBranchingCoral(canvas, Offset(x + sway, baseY), height, width, color);
          break;
        case 1:
          _drawBrainCoral(canvas, Offset(x, baseY), height * 0.7, width * 1.2, color);
          break;
        case 2:
          _drawFanCoral(canvas, Offset(x + sway, baseY), height, width, color);
          break;
        case 3:
          _drawTubeCoral(canvas, Offset(x + sway * 0.5, baseY), height, width * 1.3, color);
          break;
      }
    }
  }

  void _drawBranchingCoral(Canvas canvas, Offset base, double height, double width, Color color) {
    void drawBranch(Offset start, double length, double angle, double thickness, int depth) {
      if (depth > 4 || length < 5) return;

      final end = Offset(
        start.dx + math.sin(angle) * length,
        start.dy - math.cos(angle) * length,
      );

      _strokePaint.strokeWidth = thickness * intensity;
      _strokePaint.strokeCap = StrokeCap.round;
      _strokePaint.color = Color.lerp(color, _white, depth * 0.08)!;
      canvas.drawLine(start, end, _strokePaint);

      // Sub-branches
      if (depth < 4) {
        drawBranch(end, length * 0.7, angle - 0.4 - depth * 0.1, thickness * 0.7, depth + 1);
        drawBranch(end, length * 0.65, angle + 0.35 + depth * 0.08, thickness * 0.65, depth + 1);
      }
    }

    // Main trunk and branches
    drawBranch(base, height * 0.5, 0, 5, 0);
    drawBranch(base, height * 0.4, -0.3, 4, 1);
    drawBranch(base, height * 0.45, 0.25, 4.5, 1);
  }

  void _drawBrainCoral(Canvas canvas, Offset base, double height, double width, Color color) {
    final centerY = base.dy - height * 0.5;

    // Main dome with gradient
    final domeGradient = ui.Gradient.radial(
      Offset(base.dx - width * 0.2, centerY - height * 0.2),
      width * 0.8,
      [
        Color.lerp(color, _white, 0.3)!,
        color,
        Color.lerp(color, Colors.black, 0.15)!,
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = domeGradient;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx, centerY), width: width, height: height),
      _fillPaint,
    );
    _fillPaint.shader = null;

    // Meandering grooves
    _strokePaint.strokeWidth = 1.8 * intensity;
    _strokePaint.strokeCap = StrokeCap.round;
    _strokePaint.color = Color.lerp(color, Colors.black, 0.25)!.withOpacity(0.6);

    for (int i = 0; i < 6; i++) {
      final grooveY = centerY - height * 0.35 + i * height * 0.12;
      final grooveWidth = width * (0.75 - (i - 2.5).abs() * 0.12);

      _path.reset();
      _path.moveTo(base.dx - grooveWidth * 0.45, grooveY);

      for (double p = 0; p <= 1.0; p += 0.2) {
        final px = base.dx - grooveWidth * 0.45 + grooveWidth * 0.9 * p;
        final py = grooveY + math.sin(p * math.pi * 3 + i) * 4 * intensity;
        _path.lineTo(px, py);
      }

      canvas.drawPath(_path, _strokePaint);
    }
  }

  void _drawFanCoral(Canvas canvas, Offset base, double height, double width, Color color) {
    final segments = 16;

    // Fan shape with gradient
    _path.reset();
    _path.moveTo(base.dx, base.dy);

    for (int i = 0; i <= segments; i++) {
      final progress = i / segments;
      final angle = -math.pi * 0.42 + progress * math.pi * 0.84;
      final r = height * (0.85 + math.sin(progress * math.pi) * 0.15);

      final x = base.dx + math.sin(angle) * width * 0.9;
      final y = base.dy - math.cos(angle) * r;

      _path.lineTo(x, y);
    }

    _path.close();

    final fanGradient = ui.Gradient.linear(
      Offset(base.dx, base.dy),
      Offset(base.dx, base.dy - height),
      [
        Color.lerp(color, Colors.black, 0.1)!,
        color,
        Color.lerp(color, _white, 0.15)!,
      ],
      const [0.0, 0.4, 1.0],
    );

    _fillPaint.shader = fanGradient;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;

    // Delicate ribs
    _strokePaint.strokeWidth = 0.8 * intensity;
    _strokePaint.color = Color.lerp(color, _white, 0.25)!.withOpacity(0.5);

    for (int i = 1; i < segments; i += 2) {
      final progress = i / segments;
      final angle = -math.pi * 0.42 + progress * math.pi * 0.84;
      final r = height * 0.92;

      canvas.drawLine(
        base,
        Offset(
          base.dx + math.sin(angle) * width * 0.8,
          base.dy - math.cos(angle) * r * 0.92,
        ),
        _strokePaint,
      );
    }
  }

  void _drawTubeCoral(Canvas canvas, Offset base, double height, double width, Color color) {
    final tubes = 5;

    for (int i = 0; i < tubes; i++) {
      final tubeX = base.dx - width * 0.4 + i * width / (tubes - 1);
      final tubeHeight = height * (0.5 + ((i + 1) % 3) * 0.25);
      final tubeWidth = width / tubes * 0.7;

      // Tube body with gradient
      final tubeGradient = ui.Gradient.linear(
        Offset(tubeX - tubeWidth * 0.5, 0),
        Offset(tubeX + tubeWidth * 0.5, 0),
        [
          Color.lerp(color, Colors.black, 0.15)!,
          Color.lerp(color, _white, 0.1)!,
          color,
        ],
        const [0.0, 0.3, 1.0],
      );

      _fillPaint.shader = tubeGradient;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tubeX - tubeWidth * 0.5, base.dy - tubeHeight, tubeWidth, tubeHeight),
          Radius.circular(tubeWidth * 0.5),
        ),
        _fillPaint,
      );
      _fillPaint.shader = null;

      // Opening with depth
      _fillPaint.color = Color.lerp(color, Colors.black, 0.5)!;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tubeX, base.dy - tubeHeight + 2 * intensity),
          width: tubeWidth * 0.85,
          height: tubeWidth * 0.35,
        ),
        _fillPaint,
      );

      // Rim highlight
      _strokePaint.strokeWidth = 1.5 * intensity;
      _strokePaint.color = Color.lerp(color, _white, 0.3)!;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tubeX, base.dy - tubeHeight),
          width: tubeWidth,
          height: tubeWidth * 0.4,
        ),
        _strokePaint,
      );
    }
  }

  void _paintSandyBottom(Canvas canvas, Size size) {
    // Sandy floor
    _path.reset();
    _path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += size.width / 20) {
      final dune = math.sin(x * 0.02 + 1.5) * 8 * intensity + math.sin(x * 0.05) * 4 * intensity;
      _path.lineTo(x, size.height * 0.88 + dune);
    }

    _path.lineTo(size.width, size.height);
    _path.close();

    final sandGradient = ui.Gradient.linear(
      Offset(0, size.height * 0.85),
      Offset(0, size.height),
      [
        _sand.withOpacity(0.5 * intensity),
        _sand.withOpacity(0.7 * intensity),
      ],
    );

    _fillPaint.shader = sandGradient;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;

    // Sand texture
    final rng = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * (0.9 + rng.nextDouble() * 0.1);
      final particleSize = (1 + rng.nextDouble() * 2) * intensity;

      _fillPaint.color = Color.lerp(_sand, _white, rng.nextDouble() * 0.3)!.withOpacity(0.5 * intensity);
      canvas.drawCircle(Offset(x, y), particleSize, _fillPaint);
    }
  }

  void _paintFish(Canvas canvas, Size size) {
    for (final fish in _fish) {
      // swimProgress = (time * speed + offset) % 1.0 -> creates sawtooth 0..1
      final swimProgress = (state.time * fish.speed + fish.phaseOffset / 6.28) % 1.0;

      double x;
      if (fish.facingRight) {
        x = (-0.15 + swimProgress * 1.3) * size.width;
      } else {
        x = (1.15 - swimProgress * 1.3) * size.width;
      }

      final wobbleY = _wave(1.8, fish.phaseOffset) * 8 * intensity;
      final y = fish.baseY * size.height + wobbleY;

      final fishSize = fish.size * size.shortestSide;
      final color = _fishColors[fish.colorIndex];

      _drawFish(canvas, Offset(x, y), fishSize, fish.facingRight, color);
    }
  }

  void _drawFish(Canvas canvas, Offset center, double size, bool facingRight, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!facingRight) canvas.scale(-1, 1);

    // Tail fin
    _path.reset();
    _path.moveTo(-size * 0.9, 0);
    _path.lineTo(-size * 1.35, -size * 0.45);
    _path.quadraticBezierTo(-size * 1.1, 0, -size * 1.35, size * 0.45);
    _path.close();

    _fillPaint.color = Color.lerp(color, Colors.black, 0.1)!.withOpacity(0.85);
    canvas.drawPath(_path, _fillPaint);

    // Body
    _path.reset();
    _path.moveTo(-size * 0.85, 0);
    _path.quadraticBezierTo(-size * 0.4, -size * 0.5, size * 0.4, -size * 0.22);
    _path.quadraticBezierTo(size * 0.6, 0, size * 0.4, size * 0.22);
    _path.quadraticBezierTo(-size * 0.4, size * 0.5, -size * 0.85, 0);
    _path.close();

    final bodyGradient = ui.Gradient.linear(
      Offset(0, -size * 0.45),
      Offset(0, size * 0.45),
      [
        Color.lerp(color, _white, 0.35)!,
        color,
        Color.lerp(color, Colors.black, 0.15)!,
      ],
      const [0.0, 0.4, 1.0],
    );

    _fillPaint.shader = bodyGradient;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;

    // Dorsal fin
    _path.reset();
    _path.moveTo(-size * 0.2, -size * 0.22);
    _path.quadraticBezierTo(size * 0.05, -size * 0.55, size * 0.25, -size * 0.18);
    _path.close();

    _fillPaint.color = Color.lerp(color, Colors.black, 0.05)!.withOpacity(0.8);
    canvas.drawPath(_path, _fillPaint);

    // Pectoral fin
    _path.reset();
    _path.moveTo(-size * 0.1, size * 0.1);
    _path.quadraticBezierTo(size * 0.1, size * 0.35, -size * 0.2, size * 0.25);
    _path.close();

    _fillPaint.color = color.withOpacity(0.7);
    canvas.drawPath(_path, _fillPaint);

    // Eye
    _fillPaint.color = _white;
    canvas.drawCircle(Offset(size * 0.22, -size * 0.05), size * 0.11, _fillPaint);
    _fillPaint.color = Colors.black;
    canvas.drawCircle(Offset(size * 0.25, -size * 0.05), size * 0.055, _fillPaint);

    // Eye highlight
    _fillPaint.color = _white.withOpacity(0.8);
    canvas.drawCircle(Offset(size * 0.23, -size * 0.08), size * 0.025, _fillPaint);

    canvas.restore();
  }

  void _drawSimpleFish(Canvas canvas, Offset center, double size, bool facingRight) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!facingRight) canvas.scale(-1, 1);

    // Simple silhouette
    _path.reset();
    _path.moveTo(-size * 0.8, 0);
    _path.quadraticBezierTo(0, -size * 0.4, size * 0.5, 0);
    _path.quadraticBezierTo(0, size * 0.4, -size * 0.8, 0);

    // Tail
    _path.moveTo(-size * 0.8, 0);
    _path.lineTo(-size * 1.3, -size * 0.35);
    _path.lineTo(-size * 1.3, size * 0.35);
    _path.close();

    canvas.drawPath(_path, _fillPaint);
    canvas.restore();
  }

  void _paintBubbles(Canvas canvas, Size size) {
    for (final bubble in _bubbles) {
      final progress = (state.time * bubble.speed + bubble.phaseOffset / 6.28) % 1.0;
      final y = size.height * (1.05 - progress * 1.1);
      final wobbleX = _wave(bubble.wobbleSpeed, bubble.phaseOffset) * 12 * intensity;
      final x = bubble.x * size.width + wobbleX;

      if (y < 0 || y > size.height) continue;

      final bubbleSize = bubble.size * intensity * (0.8 + progress * 0.4);

      // Bubble body
      _strokePaint.strokeWidth = 1.2 * intensity;
      _strokePaint.color = _white.withOpacity(0.5 * intensity);
      canvas.drawCircle(Offset(x, y), bubbleSize, _strokePaint);

      // Inner highlight
      _fillPaint.color = _white.withOpacity(0.25 * intensity);
      canvas.drawCircle(
        Offset(x - bubbleSize * 0.3, y - bubbleSize * 0.3),
        bubbleSize * 0.3,
        _fillPaint,
      );

      // Small highlight dot
      _fillPaint.color = _white.withOpacity(0.5 * intensity);
      canvas.drawCircle(
        Offset(x - bubbleSize * 0.35, y - bubbleSize * 0.35),
        bubbleSize * 0.12,
        _fillPaint,
      );
    }
  }

  void _paintWaterSurface(Canvas canvas, Size size) {
    // Animated wavy surface
    _path.reset();
    _path.moveTo(0, 0);

    for (double x = 0; x <= size.width + 10; x += 8) {
      final wave1 = _wave(1.2, x * 0.015) * 4 * intensity;
      final wave2 = _wave(0.8, x * 0.025 + 2.0) * 3 * intensity;
      final waveY = wave1 + wave2 + 10 * intensity;
      _path.lineTo(x, waveY);
    }

    _path.lineTo(size.width, 0);
    _path.close();

    final surfaceGradient = ui.Gradient.linear(
      Offset.zero,
      Offset(0, 20 * intensity),
      [
        _white.withOpacity(0.5 * intensity),
        const Color(0xFFA8E8F0).withOpacity(0.3 * intensity),
      ],
    );

    _fillPaint.shader = surfaceGradient;
    canvas.drawPath(_path, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintParticles(Canvas canvas, Size size) {
    // Floating plankton/particles
    // Deterministic random
    for (int i = 0; i < 25; i++) {
      // Pseudo random seeds
      final r1 = ((i * 12.3) % 1.0);
      final r2 = ((i * 45.6) % 1.0);

      final baseX = r1 * size.width;
      final baseY = r2 * size.height * 0.8;

      final floatX = baseX + _wave(0.4, i * 0.5) * 10 * intensity;
      final floatY = baseY + _wave(0.35, i * 0.7 + 1.0) * 8 * intensity;

      final twinkle = _norm(0.8, i * 0.6);
      if (twinkle > 0.4) {
        final particleSize = (1 + twinkle * 1.5) * intensity;
        final opacity = (twinkle - 0.4) * 0.5 * intensity;

        _fillPaint.color = _white.withOpacity(opacity);
        canvas.drawCircle(Offset(floatX, floatY), particleSize, _fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoralReefPainter oldDelegate) {
    // Always repaint for animation
    return true;
  }
}
