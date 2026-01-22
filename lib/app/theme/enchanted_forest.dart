import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// ENCHANTED FOREST THEME BUILDER
// ============================================================================

AppTheme buildEnchantedForestTheme() {
  final baseTextTheme = GoogleFonts.cormorantGaramondTextTheme();
  final bodyTextTheme = GoogleFonts.latoTextTheme();

  return AppTheme(
    type: ThemeType.enchantedForest,
    isDark: true,

    // Primary colors - magical gold
    primaryColor: const Color(0xFFD4A855),
    primaryVariant: const Color(0xFFB8923D),
    onPrimary: const Color(0xFF1A2615),

    // Secondary colors - forest green
    accentColor: const Color(0xFF4A7C59),
    onAccent: const Color(0xFFF0EBD8),

    // Background colors - deep forest
    background: const Color(0xFF0C1A0F),
    surface: const Color(0xFF142318),
    surfaceVariant: const Color(0xFF1C2E20),

    // Text colors
    textPrimary: const Color(0xFFF0EBD8),
    textSecondary: const Color(0xFFB8C4A8),
    textDisabled: const Color(0xFF5A6B52),

    // UI colors
    divider: const Color(0xFF2A3D2E),
    toolbarColor: const Color(0xFF142318),
    error: const Color(0xFFD4726A),
    success: const Color(0xFF7AB87A),
    warning: const Color(0xFFD4A855),

    // Grid colors
    gridLine: const Color(0xFF2A3D2E),
    gridBackground: const Color(0xFF142318),

    // Canvas colors
    canvasBackground: const Color(0xFF0C1A0F),
    selectionOutline: const Color(0xFFD4A855),
    selectionFill: const Color(0x30D4A855),

    // Icon colors
    activeIcon: const Color(0xFFD4A855),
    inactiveIcon: const Color(0xFFB8C4A8),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFF0EBD8),
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFF0EBD8),
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFF0EBD8),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFF0EBD8),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF0EBD8),
        fontWeight: FontWeight.w300,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB8C4A8),
        fontWeight: FontWeight.w300,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFD4A855),
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// ENCHANTED FOREST ANIMATED BACKGROUND
// ============================================================================

class EnchantedForestBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const EnchantedForestBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 16),
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
        controller.value = 0;
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(controller);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _EnchantedForestPainter(
          t: t,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// Pre-computed data structures
class _FireflyData {
  final double x;
  final double y;
  final double size;
  final double phaseOffset;
  final double speed;
  final double wanderRadius;

  const _FireflyData(this.x, this.y, this.size, this.phaseOffset, this.speed, this.wanderRadius);
}

class _TreeData {
  final double x;
  final double scale;
  final double darkness;
  final int variant;

  const _TreeData(this.x, this.scale, this.darkness, this.variant);
}

class _LeafData {
  final double x;
  final double y;
  final double size;
  final double phaseOffset;
  final double rotSpeed;
  final int colorIndex;

  const _LeafData(this.x, this.y, this.size, this.phaseOffset, this.rotSpeed, this.colorIndex);
}

class _MushroomData {
  final double x;
  final double y;
  final double size;
  final double glowPhase;
  final int colorIndex;

  const _MushroomData(this.x, this.y, this.size, this.glowPhase, this.colorIndex);
}

class _EnchantedForestPainter extends CustomPainter {
  final double t;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Color palette
  static const Color _gold = Color(0xFFD4A855);
  static const Color _goldBright = Color(0xFFFFE4A0);
  static const Color _forestDeep = Color(0xFF0C1A0F);
  static const Color _forestMid = Color(0xFF1A3020);
  static const Color _forestLight = Color(0xFF2A4830);
  static const Color _moss = Color(0xFF4A7050);
  static const Color _mist = Color(0xFF8AA888);
  static const Color _moonlight = Color(0xFFE8F0E0);
  static const Color _mushroom1 = Color(0xFF88DDAA);
  static const Color _mushroom2 = Color(0xFFAADD88);
  static const Color _mushroom3 = Color(0xFF66CCAA);
  static const Color _bark = Color(0xFF2A1F18);
  static const Color _leaf1 = Color(0xFF3A5A30);
  static const Color _leaf2 = Color(0xFF4A6A35);
  static const Color _leaf3 = Color(0xFF5A7A40);

  static const List<Color> _leafColors = [_leaf1, _leaf2, _leaf3, _moss];
  static const List<Color> _mushroomColors = [_mushroom1, _mushroom2, _mushroom3];

  // Pre-computed fireflies
  static final List<_FireflyData> _fireflies = List.generate(25, (i) {
    final rng = math.Random(i * 123);
    return _FireflyData(
      rng.nextDouble(),
      0.2 + rng.nextDouble() * 0.6,
      1.5 + rng.nextDouble() * 2.5,
      rng.nextDouble() * 6.28,
      0.3 + rng.nextDouble() * 0.7,
      15 + rng.nextDouble() * 25,
    );
  });

  // Pre-computed background trees (far)
  static const List<_TreeData> _farTrees = [
    _TreeData(0.05, 0.6, 0.85, 0),
    _TreeData(0.15, 0.75, 0.8, 1),
    _TreeData(0.25, 0.55, 0.9, 2),
    _TreeData(0.35, 0.7, 0.82, 0),
    _TreeData(0.45, 0.5, 0.88, 1),
    _TreeData(0.55, 0.65, 0.84, 2),
    _TreeData(0.65, 0.72, 0.86, 0),
    _TreeData(0.75, 0.58, 0.9, 1),
    _TreeData(0.85, 0.68, 0.83, 2),
    _TreeData(0.95, 0.62, 0.87, 0),
  ];

  // Mid-ground trees
  static const List<_TreeData> _midTrees = [
    _TreeData(0.0, 0.9, 0.6, 1),
    _TreeData(0.12, 1.1, 0.55, 2),
    _TreeData(0.3, 0.85, 0.65, 0),
    _TreeData(0.5, 1.0, 0.58, 1),
    _TreeData(0.7, 0.95, 0.62, 2),
    _TreeData(0.88, 1.05, 0.57, 0),
    _TreeData(1.0, 0.9, 0.63, 1),
  ];

  // Foreground trees (sides only)
  static const List<_TreeData> _nearTrees = [
    _TreeData(-0.05, 1.4, 0.3, 0),
    _TreeData(0.08, 1.25, 0.35, 1),
    _TreeData(0.92, 1.3, 0.32, 2),
    _TreeData(1.05, 1.35, 0.28, 0),
  ];

  // Floating leaves
  static final List<_LeafData> _leaves = List.generate(12, (i) {
    final rng = math.Random(i * 456);
    return _LeafData(
      rng.nextDouble(),
      rng.nextDouble(),
      3 + rng.nextDouble() * 5,
      rng.nextDouble() * 6.28,
      0.5 + rng.nextDouble() * 1.0,
      i % 4,
    );
  });

  // Glowing mushrooms
  static final List<_MushroomData> _mushrooms = List.generate(8, (i) {
    final rng = math.Random(i * 789);
    return _MushroomData(
      0.1 + rng.nextDouble() * 0.8,
      0.85 + rng.nextDouble() * 0.1,
      8 + rng.nextDouble() * 12,
      rng.nextDouble() * 6.28,
      i % 3,
    );
  });

  // Reusable objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _path = Path();

  _EnchantedForestPainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  });

  double get _phase => 2 * math.pi * t;
  double _wave(double speed, [double offset = 0]) => math.sin(_phase * speed + offset);
  double _norm(double speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintMoonGlow(canvas, size);
    _paintMist(canvas, size, 0.3, 0.08); // Far mist
    _paintTreeLayer(canvas, size, _farTrees, 0.4);
    _paintMist(canvas, size, 0.5, 0.06); // Mid mist
    _paintTreeLayer(canvas, size, _midTrees, 0.65);
    _paintMushrooms(canvas, size);
    _paintGroundFoliage(canvas, size);
    _paintTreeLayer(canvas, size, _nearTrees, 1.0);
    _paintMist(canvas, size, 0.75, 0.04); // Near mist
    _paintFireflies(canvas, size);
    _paintFloatingLeaves(canvas, size);
    _paintMagicParticles(canvas, size);
    _paintVignette(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      const [
        Color(0xFF0A1510), // Deep forest sky
        Color(0xFF0C1A0F), // Forest canopy
        Color(0xFF0E1E12), // Mid
        Color(0xFF101F14), // Ground level
      ],
      const [0.0, 0.3, 0.7, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintMoonGlow(Canvas canvas, Size size) {
    final pulse = _norm(0.3) * 0.2 + 0.8;
    final moonCenter = Offset(size.width * 0.75, size.height * 0.12);

    // Outer glow
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 60 * intensity);
    _fillPaint.color = _moonlight.withOpacity(0.06 * pulse * intensity);
    canvas.drawCircle(moonCenter, 80 * intensity, _fillPaint);

    // Inner glow
    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * intensity);
    _fillPaint.color = _moonlight.withOpacity(0.1 * pulse * intensity);
    canvas.drawCircle(moonCenter, 40 * intensity, _fillPaint);

    // Moon disc (partially obscured)
    _fillPaint.maskFilter = null;
    _fillPaint.color = _moonlight.withOpacity(0.15 * pulse * intensity);
    canvas.drawCircle(moonCenter, 18 * intensity, _fillPaint);

    _fillPaint.maskFilter = null;
  }

  void _paintMist(Canvas canvas, Size size, double yPos, double baseOpacity) {
    final drift = _wave(0.2) * 20 * intensity;
    final pulse = _norm(0.15) * 0.3 + 0.7;

    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * intensity);

    // Multiple mist layers
    for (int i = 0; i < 3; i++) {
      final y = size.height * (yPos + i * 0.05);
      final xOffset = drift + i * 30;
      final opacity = baseOpacity * pulse * intensity * (1 - i * 0.2);

      _fillPaint.color = _mist.withOpacity(opacity);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.3 + xOffset, y),
          width: size.width * 0.8,
          height: size.height * 0.15,
        ),
        _fillPaint,
      );

      _fillPaint.color = _mist.withOpacity(opacity * 0.7);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.7 - xOffset * 0.5, y + 20),
          width: size.width * 0.6,
          height: size.height * 0.12,
        ),
        _fillPaint,
      );
    }

    _fillPaint.maskFilter = null;
  }

  void _paintTreeLayer(Canvas canvas, Size size, List<_TreeData> trees, double layerScale) {
    for (final tree in trees) {
      final sway = _wave(0.25, tree.x * 10) * 3 * intensity * (1 - tree.darkness);
      _drawTree(
        canvas,
        Offset(tree.x * size.width + sway, size.height),
        size.height * 0.5 * tree.scale * layerScale,
        tree.darkness,
        tree.variant,
      );
    }
  }

  void _drawTree(Canvas canvas, Offset base, double height, double darkness, int variant) {
    final trunkWidth = height * 0.08;
    final trunkHeight = height * 0.4;

    // Trunk color based on depth
    final trunkColor = Color.lerp(_bark, _forestDeep, darkness)!;

    // Draw trunk
    _path.reset();
    _path.moveTo(base.dx - trunkWidth, base.dy);
    _path.lineTo(base.dx - trunkWidth * 0.6, base.dy - trunkHeight);
    _path.lineTo(base.dx + trunkWidth * 0.6, base.dy - trunkHeight);
    _path.lineTo(base.dx + trunkWidth, base.dy);
    _path.close();

    _fillPaint.color = trunkColor.withOpacity(0.9 - darkness * 0.3);
    canvas.drawPath(_path, _fillPaint);

    // Draw canopy layers
    final canopyBase = base.dy - trunkHeight * 0.8;
    final canopyHeight = height * 0.7;

    for (int layer = 0; layer < 3; layer++) {
      final layerY = canopyBase - layer * canopyHeight * 0.25;
      final layerWidth = height * (0.4 - layer * 0.08);
      final layerH = canopyHeight * (0.4 - layer * 0.05);

      final canopyColor = Color.lerp(
        _forestLight,
        _forestDeep,
        darkness + layer * 0.1,
      )!;

      _path.reset();
      _path.moveTo(base.dx, layerY - layerH);
      _path.quadraticBezierTo(
        base.dx - layerWidth * 1.2,
        layerY - layerH * 0.3,
        base.dx - layerWidth,
        layerY,
      );
      _path.quadraticBezierTo(
        base.dx - layerWidth * 0.5,
        layerY + layerH * 0.1,
        base.dx,
        layerY,
      );
      _path.quadraticBezierTo(
        base.dx + layerWidth * 0.5,
        layerY + layerH * 0.1,
        base.dx + layerWidth,
        layerY,
      );
      _path.quadraticBezierTo(
        base.dx + layerWidth * 1.2,
        layerY - layerH * 0.3,
        base.dx,
        layerY - layerH,
      );
      _path.close();

      _fillPaint.color = canopyColor.withOpacity(0.95 - darkness * 0.4);
      canvas.drawPath(_path, _fillPaint);
    }
  }

  void _paintMushrooms(Canvas canvas, Size size) {
    for (final m in _mushrooms) {
      final glow = _norm(0.6, m.glowPhase) * 0.5 + 0.5;
      final x = m.x * size.width;
      final y = m.y * size.height;
      final mushroomSize = m.size * intensity;

      // Glow
      _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * intensity);
      _fillPaint.color = _mushroomColors[m.colorIndex].withOpacity(0.15 * glow * intensity);
      canvas.drawCircle(Offset(x, y - mushroomSize * 0.5), mushroomSize * 1.5, _fillPaint);
      _fillPaint.maskFilter = null;

      // Stem
      _fillPaint.color = const Color(0xFFE8E0D0).withOpacity(0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y - mushroomSize * 0.3),
            width: mushroomSize * 0.3,
            height: mushroomSize * 0.6,
          ),
          Radius.circular(mushroomSize * 0.1),
        ),
        _fillPaint,
      );

      // Cap
      _path.reset();
      _path.moveTo(x - mushroomSize * 0.6, y - mushroomSize * 0.5);
      _path.quadraticBezierTo(
        x - mushroomSize * 0.7,
        y - mushroomSize * 1.1,
        x,
        y - mushroomSize * 1.2,
      );
      _path.quadraticBezierTo(
        x + mushroomSize * 0.7,
        y - mushroomSize * 1.1,
        x + mushroomSize * 0.6,
        y - mushroomSize * 0.5,
      );
      _path.close();

      _fillPaint.color = _mushroomColors[m.colorIndex].withOpacity(0.7 + glow * 0.2);
      canvas.drawPath(_path, _fillPaint);

      // Cap spots
      _fillPaint.color = Colors.white.withOpacity(0.4 * glow);
      canvas.drawCircle(Offset(x - mushroomSize * 0.2, y - mushroomSize * 0.9), mushroomSize * 0.1, _fillPaint);
      canvas.drawCircle(Offset(x + mushroomSize * 0.15, y - mushroomSize * 0.85), mushroomSize * 0.08, _fillPaint);
    }
  }

  void _paintGroundFoliage(Canvas canvas, Size size) {
    // Ground gradient
    final groundGradient = ui.Gradient.linear(
      Offset(0, size.height * 0.85),
      Offset(0, size.height),
      [
        Colors.transparent,
        _forestDeep.withOpacity(0.5),
        _forestDeep.withOpacity(0.8),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = groundGradient;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      _fillPaint,
    );
    _fillPaint.shader = null;

    // Grass tufts
    final rng = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * (0.88 + rng.nextDouble() * 0.1);
      final grassHeight = (8 + rng.nextDouble() * 15) * intensity;
      final sway = _wave(0.4, i * 0.3) * 2 * intensity;

      _strokePaint.strokeWidth = 1.5 * intensity;
      _strokePaint.color = _leafColors[i % 4].withOpacity(0.5);

      for (int blade = 0; blade < 3; blade++) {
        final bladeX = x + (blade - 1) * 3 * intensity;
        final bladeAngle = (blade - 1) * 0.2 + sway * 0.1;

        _path.reset();
        _path.moveTo(bladeX, y);
        _path.quadraticBezierTo(
          bladeX + bladeAngle * grassHeight,
          y - grassHeight * 0.6,
          bladeX + sway + bladeAngle * grassHeight * 1.5,
          y - grassHeight,
        );

        canvas.drawPath(_path, _strokePaint);
      }
    }
  }

  void _paintFireflies(Canvas canvas, Size size) {
    for (final f in _fireflies) {
      // Complex wandering motion
      final wanderX = math.sin(_phase * f.speed + f.phaseOffset) * f.wanderRadius;
      final wanderY = math.cos(_phase * f.speed * 0.7 + f.phaseOffset * 1.3) * f.wanderRadius * 0.6;

      final x = f.x * size.width + wanderX * intensity;
      final y = f.y * size.height + wanderY * intensity;

      // Pulsing glow
      final pulse = _norm(1.2, f.phaseOffset);
      final glowIntensity = pulse * pulse; // Sharper falloff

      if (glowIntensity > 0.3) {
        final adjustedIntensity = (glowIntensity - 0.3) / 0.7;
        final glowSize = f.size * intensity * (0.8 + adjustedIntensity * 0.4);

        // Outer glow
        _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * intensity);
        _fillPaint.color = _gold.withOpacity(0.3 * adjustedIntensity * intensity);
        canvas.drawCircle(Offset(x, y), glowSize * 3, _fillPaint);

        // Middle glow
        _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * intensity);
        _fillPaint.color = _goldBright.withOpacity(0.5 * adjustedIntensity * intensity);
        canvas.drawCircle(Offset(x, y), glowSize * 1.5, _fillPaint);

        // Core
        _fillPaint.maskFilter = null;
        _fillPaint.color = _goldBright.withOpacity(0.9 * adjustedIntensity * intensity);
        canvas.drawCircle(Offset(x, y), glowSize * 0.4, _fillPaint);
      }
    }
  }

  void _paintFloatingLeaves(Canvas canvas, Size size) {
    for (final leaf in _leaves) {
      // Gentle falling and drifting motion
      final fallProgress = (t * 0.3 + leaf.phaseOffset / 6.28) % 1.0;
      final x = leaf.x * size.width + math.sin(_phase * 0.4 + leaf.phaseOffset) * 30 * intensity;
      final y = fallProgress * size.height * 1.2 - size.height * 0.1;

      if (y < 0 || y > size.height) continue;

      final rotation = _phase * leaf.rotSpeed + leaf.phaseOffset;
      final flutter = math.sin(_phase * 2 + leaf.phaseOffset) * 0.3;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(1.0, 0.6 + flutter * 0.4); // Flutter effect

      // Simple leaf shape
      _path.reset();
      final leafSize = leaf.size * intensity;
      _path.moveTo(0, -leafSize);
      _path.quadraticBezierTo(leafSize * 0.8, -leafSize * 0.3, 0, leafSize);
      _path.quadraticBezierTo(-leafSize * 0.8, -leafSize * 0.3, 0, -leafSize);
      _path.close();

      _fillPaint.color = _leafColors[leaf.colorIndex].withOpacity(0.6);
      canvas.drawPath(_path, _fillPaint);

      // Leaf vein
      _strokePaint.strokeWidth = 0.5 * intensity;
      _strokePaint.color = _leafColors[leaf.colorIndex].withOpacity(0.3);
      canvas.drawLine(Offset(0, -leafSize * 0.8), Offset(0, leafSize * 0.8), _strokePaint);

      canvas.restore();
    }
  }

  void _paintMagicParticles(Canvas canvas, Size size) {
    final rng = math.Random(999);

    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * intensity);

    for (int i = 0; i < 15; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;

      // Gentle floating
      final floatX = baseX + math.sin(_phase * 0.5 + i * 0.7) * 15 * intensity;
      final floatY = baseY + math.cos(_phase * 0.4 + i * 0.5) * 10 * intensity;

      // Rise slowly
      final rise = (t * 0.2 + i * 0.1) % 1.0;
      final adjustedY = floatY - rise * 50 * intensity;

      final twinkle = _norm(1.0, i * 0.5);
      if (twinkle > 0.5) {
        final sparkOpacity = (twinkle - 0.5) * 2 * 0.4 * intensity;
        final particleSize = (1 + twinkle * 2) * intensity;

        _fillPaint.color = _goldBright.withOpacity(sparkOpacity);
        canvas.drawCircle(Offset(floatX, adjustedY), particleSize, _fillPaint);
      }
    }

    _fillPaint.maskFilter = null;
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.8;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        _forestDeep.withOpacity(0.4 * intensity),
        _forestDeep.withOpacity(0.85 * intensity),
      ],
      const [0.4, 0.75, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _EnchantedForestPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.intensity != intensity;
  }
}
