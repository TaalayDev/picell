import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// BIOLUMINESCENT BRUTALISM THEME BUILDER
// ============================================================================

AppTheme buildBioluminescentBrutalismTheme() {
  final baseTextTheme = GoogleFonts.spaceMonoTextTheme();

  return AppTheme(
    type: ThemeType.bioluminescentBrutalism,
    isDark: true,
    primaryColor: const Color(0xFF39FF14), // Neon Green
    primaryVariant: const Color(0xFF2EBD12),
    onPrimary: Colors.black,
    accentColor: const Color(0xFF00E5FF), // Neon Cyan
    onAccent: Colors.black,
    background: const Color(0xFF121212), // Very dark grey
    surface: const Color(0xFF1E1E1E), // Dark grey concrete
    surfaceVariant: const Color(0xFF2C2C2C), // Lighter concrete
    textPrimary: const Color(0xFFE0E0E0), // Concrete White
    textSecondary: const Color(0xFFA0A0A0), // Grey
    textDisabled: const Color(0xFF616161),
    divider: const Color(0xFF424242),
    toolbarColor: const Color(0xFF1E1E1E),
    error: const Color(0xFFFF5252),
    success: const Color(0xFF39FF14),
    warning: const Color(0xFFFFAB40),
    gridLine: const Color(0xFF333333),
    gridBackground: const Color(0xFF121212),
    canvasBackground: const Color(0xFF121212),
    selectionOutline: const Color(0xFF39FF14),
    selectionFill: const Color(0x3039FF14),
    activeIcon: const Color(0xFF39FF14),
    inactiveIcon: const Color(0xFF757575),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFE0E0E0),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFE0E0E0),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFE0E0E0),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFA0A0A0),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// BIOLUMINESCENT BRUTALISM ANIMATED BACKGROUND
// ============================================================================

class BioluminescentBrutalismBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const BioluminescentBrutalismBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ticker controller
    final controller = useAnimationController(
      duration: const Duration(seconds: 10), // Slow moving concrete
    );

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [enableAnimation]);

    // 2. State for noise/particles
    final state = useMemoized(() => _BiolumState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _BioluminescentBrutalismPainter(
          repaint: controller,
          state: state,
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

class _BiolumState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_ConcreteBlock>? blocks;
  List<_Spore>? spores;
}

class _ConcreteBlock {
  Rect rect;
  double depth;
  double phase;

  _ConcreteBlock({
    required this.rect,
    required this.depth,
    required this.phase,
  });
}

class _Spore {
  double x;
  double y;
  double size;
  double phase;
  double speedX;
  double speedY;
  Color color;

  _Spore({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speedX,
    required this.speedY,
    required this.color,
  });
}

class _BioluminescentBrutalismPainter extends CustomPainter {
  final _BiolumState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  static const Color _bg = Color(0xFF121212);
  static const Color _concreteDark = Color(0xFF1A1A1A);
  static const Color _concreteLight = Color(0xFF2B2B2B);

  _BioluminescentBrutalismPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    if (state.blocks == null) _initWorld(size);

    // 1. Background
    canvas.drawColor(_bg, BlendMode.src);

    // 2. Concrete Blocks pattern (Brutalist grid)
    _paintConcreteBlocks(canvas, size);

    // 3. Bioluminescent Spores
    _updateAndPaintSpores(canvas, size, dt);

    // 4. Subtle scanline or noise overlay
    _paintScanlines(canvas, size);
  }

  void _initWorld(Size size) {
    state.blocks = [];
    state.spores = [];
    final rng = math.Random(1337);

    // Create a grid of blocks
    final cols = 6;
    final rows = 10;
    final w = size.width / cols;
    final h = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (rng.nextDouble() > 0.7) continue; // Sparse
        state.blocks!.add(_ConcreteBlock(
          rect: Rect.fromLTWH(c * w, r * h, w * 0.9, h * 0.9),
          depth: rng.nextDouble(),
          phase: rng.nextDouble() * math.pi * 2,
        ));
      }
    }

    // Init Spores
    for (int i = 0; i < 30; i++) {
      state.spores!.add(_Spore(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 2 + rng.nextDouble() * 4,
        phase: rng.nextDouble() * math.pi * 2,
        speedX: (rng.nextDouble() - 0.5) * 20,
        speedY: (rng.nextDouble() - 0.5) * 20,
        color: rng.nextBool() ? primaryColor : accentColor,
      ));
    }
  }

  void _paintConcreteBlocks(Canvas canvas, Size size) {
    if (state.blocks == null) return;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var block in state.blocks!) {
      // Pulse effect based on time
      final pulse = math.sin(state.time + block.phase) * 0.5 + 0.5;
      final color = Color.lerp(_concreteDark, _concreteLight, pulse * 0.3 * intensity)!;

      paint.color = color;
      canvas.drawRect(block.rect, paint);

      // 3D-ish edge
      final edgePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.05);

      canvas.drawRect(block.rect, edgePaint);
    }
  }

  void _updateAndPaintSpores(Canvas canvas, Size size, double dt) {
    if (state.spores == null) return;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var spore in state.spores!) {
      spore.x += spore.speedX * dt * intensity;
      spore.y += spore.speedY * dt * intensity;

      if (spore.x < 0) spore.x = size.width;
      if (spore.x > size.width) spore.x = 0;
      if (spore.y < 0) spore.y = size.height;
      if (spore.y > size.height) spore.y = 0;

      final glow = math.sin(state.time * 5 + spore.phase) * 0.5 + 0.5;

      // Core
      paint.color = spore.color.withOpacity(0.8 * intensity);
      canvas.drawCircle(Offset(spore.x, spore.y), spore.size, paint);

      // Glow
      paint.color = spore.color.withOpacity(0.3 * glow * intensity);
      canvas.drawCircle(Offset(spore.x, spore.y), spore.size * 3, paint);
    }
  }

  void _paintScanlines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      if ((y + state.time * 10) % 8 < 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BioluminescentBrutalismPainter oldDelegate) {
    return animationEnabled;
  }
}
