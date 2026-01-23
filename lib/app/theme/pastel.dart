import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// PASTEL THEME BUILDER
// ============================================================================

AppTheme buildPastelTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.pastel,
    isDark: false,
    // Primary colors - soft lavender
    primaryColor: const Color(0xFFB4A7D6), // Soft lavender
    primaryVariant: const Color(0xFF9C8DC1), // Slightly deeper lavender
    onPrimary: Colors.white,
    // Secondary colors - soft pink
    accentColor: const Color(0xFFEBB2B8), // Soft pink
    onAccent: const Color(0xFF5D4037), // Warm brown for contrast
    // Background colors - very light and soft
    background: const Color(0xFFFBF9F7), // Warm off-white
    surface: const Color(0xFFFFFFFF), // Pure white
    surfaceVariant: const Color(0xFFF5F2F0), // Very light beige
    // Text colors - soft but readable
    textPrimary: const Color(0xFF4A4458), // Soft dark purple-gray
    textSecondary: const Color(0xFF857A8C), // Muted purple-gray
    textDisabled: const Color(0xFFC4BDC9), // Light purple-gray
    // UI colors
    divider: const Color(0xFFE8E2E6), // Very light purple-gray
    toolbarColor: const Color(0xFFF5F2F0),
    error: const Color(0xFFE8A2A2), // Soft coral
    success: const Color(0xFFA8D5BA), // Soft mint green
    warning: const Color(0xFFFDD4A3), // Soft peach
    // Grid colors
    gridLine: const Color(0xFFE8E2E6),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFFB4A7D6), // Match primary
    selectionFill: const Color(0x30B4A7D6),
    // Icon colors
    activeIcon: const Color(0xFFB4A7D6), // Soft lavender for active
    inactiveIcon: const Color(0xFF857A8C), // Muted for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF4A4458),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF4A4458),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF4A4458),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF857A8C),
      ),
    ),
    primaryFontWeight: FontWeight.w400, // Lighter weight for softer feel
  );
}

// ============================================================================
// PASTEL ANIMATED BACKGROUND
// ============================================================================

class PastelBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const PastelBackground({
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
    final pastelState = useMemoized(() => _PastelState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ScenicPastelPainter(
          repaint: controller,
          state: pastelState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.3, 1.5),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for physics and objects
class _PastelState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Cloud>? clouds;
  List<_Flower>? flowers;
  List<_Tree>? trees;
  List<_Pollen>? pollen;
  // Cache hill paths to keep them static
  List<Path>? hillPaths;
}

class _Cloud {
  double x;
  double y;
  double speed;
  double size;
  double puffiness; // Variance in cloud shape

  _Cloud({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.puffiness,
  });
}

class _Flower {
  double x;
  double y;
  double size;
  double swayOffset;
  double swaySpeed;
  Color color;

  _Flower({
    required this.x,
    required this.y,
    required this.size,
    required this.swayOffset,
    required this.swaySpeed,
    required this.color,
  });
}

class _Tree {
  double x;
  double y;
  double size;
  double swayOffset;

  _Tree({
    required this.x,
    required this.y,
    required this.size,
    required this.swayOffset,
  });
}

class _Pollen {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;
  double phase;

  _Pollen({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.phase,
  });
}

class _ScenicPastelPainter extends CustomPainter {
  final _PastelState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Pastel landscape palette
  static const Color _skyBlue = Color(0xFFE6F3FF); // Very light blue
  static const Color _softMint = Color(0xFFB8E6B8); // Soft mint green
  static const Color _softPeach = Color(0xFFFFDAB9); // Soft peach
  static const Color _lavenderMist = Color(0xFFE6E6FA); // Lavender
  static const Color _hillGreen = Color(0xFFC8E6C9); // Light sage green
  static const Color _sunYellow = Color(0xFFFFFACD); // Lemon chiffon
  static const Color _flowerPink = Color(0xFFFFB6C1); // Light pink

  final math.Random _rng = math.Random(777);

  _ScenicPastelPainter({
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
    if (state.clouds == null) _initWorld(size);

    _paintSky(canvas, size);
    _paintSun(canvas, size);
    _updateAndPaintClouds(canvas, size, dt);
    _paintDistantHills(canvas, size);
    _paintTrees(canvas, size);
    _paintMeadow(canvas, size);
    _paintFlowers(canvas, size);
    _updateAndPaintPollen(canvas, size, dt);
    _paintAtmosphere(canvas, size);
  }

  void _initWorld(Size size) {
    final rng = math.Random(1234);
    state.clouds = [];
    state.flowers = [];
    state.trees = [];
    state.pollen = [];
    state.hillPaths = [];

    // Init Clouds
    int cloudCount = (5 * intensity).round().clamp(3, 8);
    for (int i = 0; i < cloudCount; i++) {
      state.clouds!.add(_Cloud(
        x: rng.nextDouble() * size.width,
        y: size.height * (0.05 + rng.nextDouble() * 0.25),
        speed: 10 + rng.nextDouble() * 20,
        size: 40 + rng.nextDouble() * 40,
        puffiness: 0.8 + rng.nextDouble() * 0.4,
      ));
    }

    // Init Trees
    int treeCount = (8 * intensity).round().clamp(4, 12);
    for (int i = 0; i < treeCount; i++) {
      state.trees!.add(_Tree(
        x: size.width * (0.1 + i * 0.1) + (rng.nextDouble() - 0.5) * 50,
        y: size.height * (0.6 + (i % 3) * 0.05),
        size: 12 + i * 2.0,
        swayOffset: rng.nextDouble() * math.pi * 2,
      ));
    }

    // Init Flowers
    int flowerCount = (20 * intensity).round().clamp(10, 40);
    for (int i = 0; i < flowerCount; i++) {
      final colors = [_flowerPink, accentColor, primaryColor, _softPeach];
      state.flowers!.add(_Flower(
        x: rng.nextDouble() * size.width,
        y: size.height * (0.75 + rng.nextDouble() * 0.2),
        size: 2 + rng.nextDouble() * 4,
        swayOffset: rng.nextDouble() * math.pi * 2,
        swaySpeed: 1 + rng.nextDouble(),
        color: colors[rng.nextInt(colors.length)],
      ));
    }

    // Init Pollen
    int pollenCount = (30 * intensity).round().clamp(10, 50);
    for (int i = 0; i < pollenCount; i++) {
      state.pollen!.add(_Pollen(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        speedX: 5 + rng.nextDouble() * 10,
        speedY: 2 + rng.nextDouble() * 5,
        size: 1 + rng.nextDouble() * 2,
        phase: rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyGradient = Paint()
      ..shader = ui.Gradient.linear(
        Alignment.topCenter.withinRect(rect),
        Alignment.bottomCenter.withinRect(rect),
        [
          _skyBlue.withOpacity(0.6),
          _lavenderMist.withOpacity(0.4),
          _softPeach.withOpacity(0.3),
          Colors.white.withOpacity(0.8),
        ],
        [0.0, 0.3, 0.6, 1.0],
      );
    canvas.drawRect(rect, skyGradient);
  }

  void _paintSun(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.75, size.height * 0.25);
    final sunRadius = 40 * intensity;
    // Gentle breathing sun
    final sunPulse = 0.95 + 0.05 * math.sin(state.time * 0.5);

    final paint = Paint()..style = PaintingStyle.fill;

    // Sun glow
    paint
      ..color = _sunYellow.withOpacity(0.6 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(sunCenter, sunRadius * 2.5 * sunPulse, paint);

    // Sun body
    paint
      ..color = _sunYellow.withOpacity(0.8 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(sunCenter, sunRadius * sunPulse, paint);

    // Sun core
    paint
      ..color = Colors.white.withOpacity(0.9 * intensity)
      ..maskFilter = null;
    canvas.drawCircle(sunCenter, sunRadius * 0.6 * sunPulse, paint);
  }

  void _updateAndPaintClouds(Canvas canvas, Size size, double dt) {
    if (state.clouds == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var cloud in state.clouds!) {
      // Update
      cloud.x += cloud.speed * dt * intensity;

      // Wrap
      if (cloud.x > size.width + cloud.size * 2) {
        cloud.x = -cloud.size * 2;
        cloud.y = size.height * (0.05 + _rng.nextDouble() * 0.25);
      }

      // Paint
      paint.color = Colors.white.withOpacity(0.8);
      _drawCloud(canvas, paint, Offset(cloud.x, cloud.y), cloud.size * intensity, cloud.puffiness);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double size, double puffiness) {
    // Main cloud body with multiple overlapping circles
    // Use consistent offsets to avoid jitter
    canvas.drawCircle(center, size, paint);
    canvas.drawCircle(center + Offset(-size * 0.4 * puffiness, -size * 0.2), size * 0.8, paint);
    canvas.drawCircle(center + Offset(size * 0.3 * puffiness, -size * 0.1), size * 0.7, paint);
    canvas.drawCircle(center + Offset(size * 0.1, size * 0.3 * puffiness), size * 0.6, paint);
    canvas.drawCircle(center + Offset(-size * 0.2, size * 0.2), size * 0.5, paint);
  }

  void _paintDistantHills(Canvas canvas, Size size) {
    // Generate paths once to ensure hills don't jitter
    if (state.hillPaths!.isEmpty) {
      int hillLayers = (4 * intensity).round().clamp(2, 6);
      final rng = math.Random(12345);

      for (int layer = 0; layer < hillLayers; layer++) {
        final hillHeight = size.height * (0.3 + layer * 0.1);
        final baseY = size.height - hillHeight;
        final path = Path();
        path.moveTo(0, size.height);
        path.lineTo(0, baseY);

        // Create rolling hills
        for (int i = 0; i <= 10; i++) {
          final x = (i / 10) * size.width;
          final noise = math.sin(i * 0.8 + layer) * 40 * intensity + math.cos(i * 0.3) * 20 * intensity;
          final y = baseY + noise;

          if (i == 0) {
            path.lineTo(x, y);
          } else {
            final prevX = ((i - 1) / 10) * size.width;
            final prevNoise =
                math.sin((i - 1) * 0.8 + layer) * 40 * intensity + math.cos((i - 1) * 0.3) * 20 * intensity;
            final prevY = baseY + prevNoise;

            final controlX = (prevX + x) / 2;
            final controlY = (prevY + y) / 2 - 10;
            path.quadraticBezierTo(controlX, controlY, x, y);
          }
        }
        path.lineTo(size.width, size.height);
        path.close();
        state.hillPaths!.add(path);
      }
    }

    final paint = Paint()..style = PaintingStyle.fill;

    for (int layer = 0; layer < state.hillPaths!.length; layer++) {
      final hillOpacity = (0.6 - layer * 0.1) * intensity;
      final hillColors = [_hillGreen, _softMint, primaryColor.withOpacity(0.3), _lavenderMist];
      paint.color = hillColors[layer % hillColors.length].withOpacity(hillOpacity);

      canvas.drawPath(state.hillPaths![layer], paint);
    }
  }

  void _paintTrees(Canvas canvas, Size size) {
    if (state.trees == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    int i = 0;
    for (var tree in state.trees!) {
      final treeX = tree.x;
      final treeY = tree.y;

      // Gentle tree sway based on continuous time
      final swayX = treeX + math.sin(state.time * 0.8 + tree.swayOffset) * 3 * intensity;

      final treeOpacity = (0.5 + 0.2 * math.sin(tree.swayOffset)) * intensity;

      // Tree colors
      final treeColors = [_hillGreen, _softMint, primaryColor.withOpacity(0.4)];
      paint.color = treeColors[i % treeColors.length].withOpacity(treeOpacity);

      // Simple tree shape
      _drawSimpleTree(canvas, paint, Offset(swayX, treeY), tree.size * intensity);
      i++;
    }
  }

  void _drawSimpleTree(Canvas canvas, Paint paint, Offset base, double size) {
    // Tree crown (circle)
    canvas.drawCircle(base + Offset(0, -size), size * 0.8, paint);

    // Tree trunk
    paint.color = const Color(0xFFD2B48C).withOpacity(0.3 * intensity); // Tan
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, -size * 0.3),
        width: size * 0.2,
        height: size * 0.6,
      ),
      paint,
    );
  }

  void _paintMeadow(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Ground layer
    final meadowY = size.height * 0.75;
    final meadowRect = Rect.fromLTWH(0, meadowY, size.width, size.height - meadowY);

    paint.color = _softMint.withOpacity(0.3 * intensity);
    canvas.drawRect(meadowRect, paint);

    // Grass texture with gentle waves
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1 * intensity;

    for (int i = 0; i < (size.width / 8).round(); i++) {
      final x = i * 8.0;
      final grassHeight = 10 + math.sin(i * 0.2) * 5 * intensity;
      // Waving grass
      final grassSway = math.sin(state.time + i * 0.1) * 3 * intensity;
      final grassY = meadowY + math.sin(i * 0.1) * 3 * intensity;

      paint.color = _hillGreen.withOpacity(0.4 * intensity);

      // Draw bent grass blade
      final path = Path();
      path.moveTo(x, grassY);
      path.quadraticBezierTo(x + grassSway, grassY + grassHeight * 0.5, x + grassSway * 1.5, grassY + grassHeight);

      canvas.drawPath(path, paint);
    }
  }

  void _paintFlowers(Canvas canvas, Size size) {
    if (state.flowers == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var flower in state.flowers!) {
      // Gentle flower sway
      final swayX = flower.x + math.sin(state.time * flower.swaySpeed + flower.swayOffset) * 2 * intensity;

      final bloom = 0.5 * (1 + math.sin(state.time * 0.5 + flower.swayOffset)); // 0..1 pulse

      if (bloom > 0.3) {
        paint.color = flower.color.withOpacity(0.6 * bloom * intensity);

        // Simple flower (small circle)
        canvas.drawCircle(Offset(swayX, flower.y), flower.size * bloom * intensity, paint);

        // Flower center
        paint.color = _sunYellow.withOpacity(0.8 * bloom * intensity);
        canvas.drawCircle(Offset(swayX, flower.y), flower.size * 0.3 * bloom * intensity, paint);
      }
    }
  }

  void _updateAndPaintPollen(Canvas canvas, Size size, double dt) {
    if (state.pollen == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in state.pollen!) {
      // Update
      particle.x += particle.speedX * dt * intensity;
      particle.y += math.sin(state.time + particle.phase) * particle.speedY * dt * intensity;

      // Wrap
      if (particle.x > size.width) particle.x = 0;
      if (particle.y > size.height) particle.y = 0;
      if (particle.y < 0) particle.y = size.height;

      // Draw
      final alpha = 0.3 + 0.2 * math.sin(state.time * 2 + particle.phase);
      paint.color = Colors.white.withOpacity(alpha * intensity);
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  void _paintAtmosphere(Canvas canvas, Size size) {
    // Soft atmospheric haze
    final rect = Offset.zero & size;

    final atmosphereGradient = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, 0), // Top center
        size.height,
        [
          Colors.white.withOpacity(0.2 * intensity),
          _lavenderMist.withOpacity(0.1 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.6, 1.0],
      );

    canvas.drawRect(rect, atmosphereGradient);

    // Gentle morning mist balls drifting
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (int i = 0; i < 3; i++) {
      // Slow scrolling mist
      final mistX = (size.width * (0.2 + i * 0.3) + state.time * 10) % (size.width + 200) - 100;
      final mistY = size.height * (0.6 + i * 0.1);
      final mistSize = (60 + i * 20) * intensity;

      canvas.drawCircle(Offset(mistX, mistY), mistSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenicPastelPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}
