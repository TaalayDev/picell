import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// WINTER WONDERLAND THEME BUILDER
// ============================================================================

AppTheme buildWinterWonderlandTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.winterWonderland,
    isDark: false,
    // Primary colors - soft winter blue
    primaryColor: const Color(0xFF7FB8E5), // Soft winter sky blue
    primaryVariant: const Color(0xFF5A9BD4), // Deeper winter blue
    onPrimary: Colors.white,
    // Secondary colors - warm winter accent
    accentColor: const Color(0xFF8EC5E8), // Light blue accent
    onAccent: const Color(0xFF2C3E50), // Dark blue-gray for contrast
    // Background colors - gentle winter whites
    background: const Color(0xFFFAFCFF), // Very soft blue-white
    surface: const Color(0xFFFFFFFF), // Pure white like fresh snow
    surfaceVariant: const Color(0xFFF0F6FC), // Light blue-gray
    // Text colors - warm and readable against snow
    textPrimary: const Color(0xFF2C3E50), // Dark blue-gray
    textSecondary: const Color(0xFF546E7A), // Medium blue-gray
    textDisabled: const Color(0xFF90A4AE), // Light blue-gray
    // UI colors
    divider: const Color(0xFFE1EAF0), // Very light blue-gray
    toolbarColor: const Color(0xFFF0F6FC),
    error: const Color(0xFFE74C3C), // Warm red for contrast
    success: const Color(0xFF27AE60), // Fresh green
    warning: const Color(0xFFF39C12), // Warm orange
    // Grid colors
    gridLine: const Color(0xFFE1EAF0),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFF7FB8E5), // Match primary
    selectionFill: const Color(0x307FB8E5),
    // Icon colors
    activeIcon: const Color(0xFF7FB8E5), // Winter blue for active
    inactiveIcon: const Color(0xFF546E7A), // Medium gray for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF2C3E50),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF546E7A),
      ),
    ),
    primaryFontWeight: FontWeight.w500, // Clean, readable weight
  );
}

// ============================================================================
// WINTER WONDERLAND ANIMATED BACKGROUND
// ============================================================================

class WinterWonderlandBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const WinterWonderlandBackground({
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
    final winterState = useMemoized(() => _WinterState());

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/winter_background.webp',
            fit: BoxFit.cover,
          ),
        ),
        // Overlay for snow
        RepaintBoundary(
          child: CustomPaint(
            painter: _EnhancedWinterPainter(
              repaint: controller,
              state: winterState,
              primaryColor: theme.primaryColor,
              accentColor: theme.accentColor,
              intensity: intensity.clamp(0.0, 2.0),
            ),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

// State class for physics and objects
class _WinterState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Snowflake>? snowflakes;
}

class _Snowflake {
  double x;
  double y;
  double z; // Depth 0.0 (far) to 1.0 (near)
  double size;
  double rotation;
  double rotSpeed;
  double swayPhase;
  double swaySpeed;

  _Snowflake({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.swayPhase,
    required this.swaySpeed,
  });
}

class _EnhancedWinterPainter extends CustomPainter {
  final _WinterState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Palette
  static const Color _snowWhite = Color(0xFFFFFFFF);

  final math.Random _rng = math.Random(101);

  _EnhancedWinterPainter({
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
    if (state.snowflakes == null) _initWorld(size);

    _updateAndPaintSnow(canvas, size, dt);
    _paintVignette(canvas, size);
  }

  void _initWorld(Size size) {
    state.snowflakes = [];

    final rng = math.Random(42);

    // Init Snowflakes
    int snowCount = (100 * intensity).round().clamp(50, 300);
    for (int i = 0; i < snowCount; i++) {
      state.snowflakes!.add(_Snowflake(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        z: rng.nextDouble(),
        size: 1 + rng.nextDouble() * 3,
        rotation: rng.nextDouble() * math.pi * 2,
        rotSpeed: (rng.nextDouble() - 0.5) * 2.0,
        swayPhase: rng.nextDouble() * math.pi * 2,
        swaySpeed: 1 + rng.nextDouble() * 2,
      ));
    }
  }

  void _updateAndPaintSnow(Canvas canvas, Size size, double dt) {
    if (state.snowflakes == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var flake in state.snowflakes!) {
      // Physics
      // Speed depends on z (depth) - Slow falling
      double fallSpeed = (10 + 40 * flake.z) * intensity;
      flake.y += fallSpeed * dt;

      // Wind sway
      flake.swayPhase += flake.swaySpeed * dt;
      flake.x += math.sin(flake.swayPhase) * 15 * dt * intensity; // Gentle sway
      flake.x += 5 * dt * intensity; // Very slight global wind

      // Rotation
      flake.rotation += flake.rotSpeed * dt;

      // Wrap
      if (flake.y > size.height + 10) {
        flake.y = -10;
        flake.x = _rng.nextDouble() * size.width;
      }
      if (flake.x > size.width + 10) {
        flake.x = -10;
      }

      // Draw
      double drawSize = flake.size * (0.5 + 0.5 * flake.z);
      double opacity = (0.4 + 0.6 * flake.z) * intensity;

      paint.color = _snowWhite.withOpacity(opacity);

      // Simple flake or detailed based on size
      if (drawSize < 2.0) {
        canvas.drawCircle(Offset(flake.x, flake.y), drawSize, paint);
      } else {
        _drawSnowflakeStar(canvas, paint, Offset(flake.x, flake.y), drawSize, flake.rotation);
      }
    }
  }

  void _drawSnowflakeStar(Canvas canvas, Paint paint, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = math.cos(angle) * size;
      final y = math.sin(angle) * size;

      // Main arm
      canvas.drawLine(
          Offset.zero,
          Offset(x, y),
          Paint()
            ..color = paint.color
            ..strokeWidth = size * 0.2
            ..strokeCap = StrokeCap.round);

      // Tiny branches
      if (size > 3.0) {
        final midX = x * 0.6;
        final midY = y * 0.6;
        final branchLen = size * 0.3;
        final branchAngle1 = angle + 0.8;
        final branchAngle2 = angle - 0.8;

        canvas.drawLine(
            Offset(midX, midY),
            Offset(midX + math.cos(branchAngle1) * branchLen, midY + math.sin(branchAngle1) * branchLen),
            Paint()
              ..color = paint.color
              ..strokeWidth = size * 0.1);
        canvas.drawLine(
            Offset(midX, midY),
            Offset(midX + math.cos(branchAngle2) * branchLen, midY + math.sin(branchAngle2) * branchLen),
            Paint()
              ..color = paint.color
              ..strokeWidth = size * 0.1);
      }
    }
    canvas.restore();
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.8,
      [
        Colors.transparent,
        Colors.white.withOpacity(0.1 * intensity),
        Colors.white.withOpacity(0.3 * intensity), // Frosty edges
      ],
      [0.6, 0.85, 1.0],
    );

    canvas.drawRect(
        rect,
        Paint()
          ..shader = gradient
          ..blendMode = BlendMode.softLight);
  }

  @override
  bool shouldRepaint(covariant _EnhancedWinterPainter oldDelegate) {
    return true; // Infinite animation
  }
}
