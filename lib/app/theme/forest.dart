import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// FOREST THEME BUILDER
// ============================================================================

AppTheme buildForestTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.forest,
    isDark: false,
    primaryColor: const Color(0xFF2E7D32),
    primaryVariant: const Color(0xFF388E3C),
    onPrimary: Colors.white,
    accentColor: const Color(0xFFD3B047),
    onAccent: Colors.black,
    background: const Color(0xFFEFF4ED),
    surface: Colors.white,
    surfaceVariant: const Color(0xFFE1ECD8),
    textPrimary: const Color(0xFF1E3725),
    textSecondary: const Color(0xFF5C745F),
    textDisabled: const Color(0xFFA5B8A7),
    divider: const Color(0xFFD4E2CD),
    toolbarColor: const Color(0xFFE1ECD8),
    error: const Color(0xFFB71C1C),
    success: const Color(0xFF2E7D32),
    warning: const Color(0xFFF9A825),
    gridLine: const Color(0xFFD4E2CD),
    gridBackground: Colors.white,
    canvasBackground: Colors.white,
    selectionOutline: const Color(0xFF2E7D32),
    selectionFill: const Color(0x302E7D32),
    activeIcon: const Color(0xFF2E7D32),
    inactiveIcon: const Color(0xFF5C745F),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF1E3725),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF1E3725),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF1E3725),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF5C745F),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// FOREST ANIMATED BACKGROUND
// ============================================================================

class ForestBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const ForestBackground({
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
        painter: _EnhancedForestPainter(
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
  List<_Tree>? trees;
  List<_Leaf>? leaves;
  List<_Firefly>? fireflies;

  // Persistent RNG – avoids creating a new Random() on every frame
  final math.Random rng = math.Random();

  // Cached size-dependent GPU shaders
  Size? lastSize;
  ui.Shader? cachedSkyShader;

  // Pre-computed determinstic positions for undergrowth and dapples
  List<double>? undergrowthX;
  List<double>? undergrowthH;
  List<bool>? undergrowthColor; // true = leafGreen
  List<double>? dappleX;
  List<double>? dappleY;
  List<double>? dappleS;

  // Pre-computed layer colors (avoids Color.lerp every frame)
  static const List<Color> trunkColors = [
    Color(0xFF3E2F2A), // layer 0: lerp(richBrown, deepForest, 0.5)
    Color(0xFF5D4037), // layer 1: warmBrown
    Color(0xFF3E2723), // layer 2: richBrown
  ];
  static const List<Color> leafColors = [
    Color(0xFF1B5E20), // layer 0: deepForest
    Color(0xFF2E7D32), // layer 1: midForest
    Color(0xFF8BC34A), // layer 2: leafGreen
  ];
  static const List<double> layerOpacity = [0.6, 0.8, 1.0];
}

class _Tree {
  double x;
  final double width;
  final double height;
  final int layer; // 0=far, 1=mid, 2=close
  final int seed;

  _Tree({
    required this.x,
    required this.width,
    required this.height,
    required this.layer,
    required this.seed,
  });
}

class _Leaf {
  double x;
  double y;
  double rotation;
  double rotSpeed;
  double speedY;
  double swayAmp;
  double swayFreq;
  double phase;
  Color color;
  double size;

  _Leaf({
    required this.x,
    required this.y,
    required this.rotation,
    required this.rotSpeed,
    required this.speedY,
    required this.swayAmp,
    required this.swayFreq,
    required this.phase,
    required this.color,
    required this.size,
  });
}

class _Firefly {
  double x;
  double y;
  double size;
  double phase;
  double speedX;
  double speedY;

  _Firefly({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speedX,
    required this.speedY,
  });
}

class _EnhancedForestPainter extends CustomPainter {
  final _ForestState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Forest color palette
  static const Color _midForest = Color(0xFF2E7D32);
  static const Color _lightForest = Color(0xFF4CAF50);
  static const Color _sunlight = Color(0xFFFFF8E1);
  static const Color _warmBrown = Color(0xFF5D4037);
  static const Color _leafGreen = Color(0xFF8BC34A);
  static const Color _dappleLight = Color(0xFFFFE082);

  // Reusable Paint objects – avoids per-frame heap allocation and GC pressure
  final _skyPaint = Paint();
  final _rayPaint = Paint()..style = PaintingStyle.fill;
  final _treePaint = Paint()..style = PaintingStyle.fill;
  final _canopyHighlightPaint = Paint();
  final _mistPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20); // reduced from 30
  final _undergrowthPaint = Paint()..style = PaintingStyle.fill;
  final _leafPaint = Paint()..style = PaintingStyle.fill;
  final _fireflyPaint = Paint()..style = PaintingStyle.fill;
  final _dapplePaint = Paint()..style = PaintingStyle.fill;

  _EnhancedForestPainter({
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

    // Invalidate size-dependent caches on resize
    if (state.lastSize != size) {
      state.lastSize = size;
      state.cachedSkyShader = null;
      state.trees = null; // re-init so tree heights scale properly
    }

    // Initialization
    if (state.trees == null) _initWorld(size);

    // 1. Sky & Atmosphere
    _paintForestSky(canvas, size);
    _paintSunlightRays(canvas, size);

    // 2. Layered Trees
    _paintTrees(canvas, size, 0); // Background (Far)
    _paintMist(canvas, size, 0.3); // Far Mist

    _paintTrees(canvas, size, 1); // Midground
    _paintMist(canvas, size, 0.15); // Mid Mist

    _paintTrees(canvas, size, 2); // Foreground
    _paintUndergrowth(canvas, size);

    // 3. Particles
    _updateAndPaintLeaves(canvas, size, dt);
    _updateAndPaintFireflies(canvas, size, dt);

    // 4. Lighting overlays
    _paintLightDapples(canvas, size);
  }

  void _initWorld(Size size) {
    state.trees = [];
    state.leaves = [];
    state.fireflies = [];
    final rng = math.Random(999);

    // Init Trees
    // Far Layer
    for (int i = 0; i < 8; i++) {
      state.trees!.add(_Tree(
        x: rng.nextDouble() * size.width,
        width: 30 + rng.nextDouble() * 20,
        height: size.height * (0.35 + rng.nextDouble() * 0.15),
        layer: 0,
        seed: rng.nextInt(10000),
      ));
    }
    // Mid Layer
    for (int i = 0; i < 5; i++) {
      state.trees!.add(_Tree(
        x: rng.nextDouble() * size.width,
        width: 50 + rng.nextDouble() * 30,
        height: size.height * (0.5 + rng.nextDouble() * 0.2),
        layer: 1,
        seed: rng.nextInt(10000),
      ));
    }
    // Foreground Layer (Edges mostly)
    for (int i = 0; i < 3; i++) {
      state.trees!.add(_Tree(
        x: (i == 1) ? size.width * 0.5 + (rng.nextDouble() - 0.5) * 100 : (i == 0 ? 0 : size.width),
        width: 80 + rng.nextDouble() * 40,
        height: size.height * 0.85,
        layer: 2,
        seed: rng.nextInt(10000),
      ));
    }
    // Sort so painting order is correct (though we paint by layer ID anyway)
    state.trees!.sort((a, b) => a.layer.compareTo(b.layer));

    // Init Leaves
    for (int i = 0; i < 40; i++) {
      state.leaves!.add(_Leaf(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        rotation: rng.nextDouble() * math.pi * 2,
        rotSpeed: (rng.nextDouble() - 0.5) * 3.0,
        speedY: 20 + rng.nextDouble() * 30,
        swayAmp: 10 + rng.nextDouble() * 20,
        swayFreq: 1 + rng.nextDouble() * 2,
        phase: rng.nextDouble() * math.pi * 2,
        color: [_leafGreen, accentColor, _warmBrown, Color.lerp(_leafGreen, _warmBrown, 0.5)!][rng.nextInt(4)],
        size: 3 + rng.nextDouble() * 4,
      ));
    }

    // Init Fireflies/Dust
    for (int i = 0; i < 25; i++) {
      state.fireflies!.add(_Firefly(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 1 + rng.nextDouble() * 2,
        phase: rng.nextDouble() * math.pi * 2,
        speedX: (rng.nextDouble() - 0.5) * 10,
        speedY: (rng.nextDouble() - 0.5) * 10,
      ));
    }
  }

  void _paintForestSky(Canvas canvas, Size size) {
    // Sky shader is cached and rebuilt only when size changes
    state.cachedSkyShader ??= ui.Gradient.linear(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      const [
        Color(0xFFFFF8E1), // _sunlight
        Color(0xFFD4E8A0), // lerp(_sunlight, _leafGreen, 0.3)
        Color(0xFF4B8C3F), // lerp(_leafGreen, _midForest, 0.2)
        Color(0xFF2A6E2E), // lerp(_midForest, _deepForest, 0.1)
      ],
      [0.0, 0.25, 0.7, 1.0],
    );
    _skyPaint.shader = state.cachedSkyShader;
    canvas.drawRect(Offset.zero & size, _skyPaint);
  }

  void _paintSunlightRays(Canvas canvas, Size size) {
    final rayTime = state.time * 0.1;
    final widthTop = 20 * intensity;
    final widthBottom = 80 * intensity;
    final length = size.height * 0.9;
    final path = Path(); // reused across rays

    for (int i = 0; i < 6; i++) {
      final rayBaseX = size.width * (0.2 + i * 0.15);
      final sway = math.sin(rayTime + i) * 30 * intensity;
      final rayStartX = rayBaseX + sway;
      const rayStartY = -50.0;

      final angle = (15 + i * 5) * math.pi / 180;
      final endX = rayStartX + math.sin(angle) * length;
      final endY = rayStartY + math.cos(angle) * length;

      path.reset();
      path.moveTo(rayStartX - widthTop / 2, rayStartY);
      path.lineTo(rayStartX + widthTop / 2, rayStartY);
      path.lineTo(endX + widthBottom / 2, endY);
      path.lineTo(endX - widthBottom / 2, endY);
      path.close();

      final beamAlpha = (0.3 + 0.2 * math.sin(rayTime * 2 + i)) * intensity;

      // Gradient recreated each frame only because start point shifts with sway;
      // acceptable cost compared to creating a new Paint per ray.
      _rayPaint.shader = ui.Gradient.linear(
        Offset(rayStartX, rayStartY),
        Offset(endX, endY),
        [
          _sunlight.withOpacity(0.4 * beamAlpha),
          _sunlight.withOpacity(0.1 * beamAlpha),
          Colors.transparent,
        ],
        [0.0, 0.6, 1.0],
      );

      canvas.drawPath(path, _rayPaint);
    }
    _rayPaint.shader = null;
  }

  void _paintTrees(Canvas canvas, Size size, int layer) {
    if (state.trees == null) return;

    // Layer colors pre-computed in _ForestState – no Color.lerp per frame
    final trunkColor = _ForestState.trunkColors[layer];
    final leafColor = _ForestState.leafColors[layer];
    final opacity = _ForestState.layerOpacity[layer];
    final swayTime = state.time * (0.5 + layer * 0.2);

    for (var tree in state.trees!) {
      if (tree.layer != layer) continue;

      final sway = math.sin(swayTime + tree.seed) * (5 + layer * 3) * intensity;
      final trunkBase = Offset(tree.x, size.height);
      final trunkTop = Offset(tree.x + sway, size.height - tree.height);

      _drawTreeTrunk(canvas, trunkBase, trunkTop, tree.width * intensity, trunkColor.withOpacity(opacity));
      _drawCanopyClusters(canvas, trunkTop, tree.width * intensity, tree.height, leafColor.withOpacity(opacity), tree.seed);
    }
  }

  void _drawTreeTrunk(Canvas canvas, Offset base, Offset top, double width, Color color) {
    final path = Path();
    path.moveTo(base.dx - width / 2, base.dy);
    path.quadraticBezierTo(base.dx - width * 0.4, base.dy - (base.dy - top.dy) * 0.5, top.dx - width * 0.2, top.dy);
    path.lineTo(top.dx + width * 0.2, top.dy);
    path.quadraticBezierTo(base.dx + width * 0.4, base.dy - (base.dy - top.dy) * 0.5, base.dx + width / 2, base.dy);
    path.close();

    _treePaint.color = color;
    canvas.drawPath(path, _treePaint);

    // Bark texture – step 20px instead of 10px (half the draw calls)
    _treePaint.color = const Color(0x1A000000); // Colors.black.withOpacity(0.1)
    for (double y = top.dy; y < base.dy; y += 20.0) {
      final progress = (y - top.dy) / (base.dy - top.dy);
      final w = width * (0.2 + 0.8 * progress);
      final x = base.dx + (top.dx - base.dx) * (1 - progress);
      canvas.drawRect(Rect.fromLTWH(x - w * 0.3, y, w * 0.1, 4), _treePaint);
    }
  }

  void _drawCanopyClusters(
      Canvas canvas, Offset center, double treeWidth, double treeHeight, Color color, int seed) {
    // math.Random(seed) produces the same sequence for the same seed each call –
    // this is intentional so cluster positions stay deterministic across frames.
    final rng = math.Random(seed);
    _treePaint.color = color;
    _canopyHighlightPaint.color = _lightForest.withOpacity(color.opacity * 0.3);

    final clusters = 5 + (treeWidth / 10).round();

    for (int i = 0; i < clusters; i++) {
      final offsetX = (rng.nextDouble() - 0.5) * treeWidth * 3.0;
      final offsetY = (rng.nextDouble() - 0.5) * treeHeight * 0.4;
      final r = treeWidth * (0.8 + rng.nextDouble() * 0.6);

      canvas.drawCircle(center + Offset(offsetX, offsetY), r, _treePaint);

      // Highlight on every other cluster (avoids per-iteration branch + Paint alloc)
      if (rng.nextBool()) {
        canvas.drawCircle(center + Offset(offsetX - r * 0.2, offsetY - r * 0.2), r * 0.5, _canopyHighlightPaint);
      }
    }
  }

  void _paintMist(Canvas canvas, Size size, double baseOpacity) {
    // Reuse _mistPaint (blur MaskFilter set at construction, radius 20 not 30)
    _mistPaint.color = _sunlight.withOpacity(baseOpacity * 0.5 * intensity);
    final time = state.time;

    for (int i = 0; i < 3; i++) {
      final scroll = (time * 20 + i * 100) % (size.width + 200) - 100;
      final y = size.height * 0.6 + math.sin(time * 0.5 + i) * 50;
      canvas.drawOval(Rect.fromCenter(center: Offset(scroll, y), width: 300, height: 100), _mistPaint);
    }
  }

  void _paintUndergrowth(Canvas canvas, Size size) {
    // Undergrowth positions are deterministic and cached in state after first build
    if (state.undergrowthX == null) {
      final rng = math.Random(123);
      state.undergrowthX = [];
      state.undergrowthH = [];
      state.undergrowthColor = [];
      for (double x = 0; x < size.width; x += 15) {
        state.undergrowthX!.add(x);
        state.undergrowthH!.add(10 + rng.nextDouble() * 20);
        state.undergrowthColor!.add(rng.nextBool());
      }
    }

    final path = Path(); // reused per blade
    final leafGreenAlpha = _leafGreen.withOpacity(0.8 * intensity);
    final midForestAlpha = _midForest.withOpacity(0.8 * intensity);

    for (int idx = 0; idx < state.undergrowthX!.length; idx++) {
      final x = state.undergrowthX![idx];
      final height = state.undergrowthH![idx];
      final sway = math.sin(state.time * 2 + x * 0.1) * 3 * intensity;

      path.reset();
      path.moveTo(x, size.height);
      path.quadraticBezierTo(x + sway, size.height - height * 0.5, x + sway * 1.5, size.height - height);
      path.quadraticBezierTo(x + sway + 3, size.height - height * 0.5, x + 6, size.height);
      path.close();

      _undergrowthPaint.color = state.undergrowthColor![idx] ? leafGreenAlpha : midForestAlpha;
      canvas.drawPath(path, _undergrowthPaint);
    }
  }

  void _updateAndPaintLeaves(Canvas canvas, Size size, double dt) {
    if (state.leaves == null) return;

    final path = Path(); // reused per leaf

    for (var leaf in state.leaves!) {
      leaf.y += leaf.speedY * dt * intensity;
      leaf.phase += leaf.swayFreq * dt;
      leaf.x += math.sin(leaf.phase) * leaf.swayAmp * dt * intensity;
      leaf.rotation += leaf.rotSpeed * dt;

      // Wrap – use state.rng instead of _rng field on painter
      if (leaf.y > size.height + 10) {
        leaf.y = -10;
        leaf.x = state.rng.nextDouble() * size.width;
      }
      if (leaf.x < -10) leaf.x = size.width + 10;
      if (leaf.x > size.width + 10) leaf.x = -10;

      _leafPaint.color = leaf.color.withOpacity(0.9 * intensity);

      canvas.save();
      canvas.translate(leaf.x, leaf.y);
      canvas.rotate(leaf.rotation);

      path.reset();
      path.moveTo(0, -leaf.size);
      path.quadraticBezierTo(leaf.size, 0, 0, leaf.size);
      path.quadraticBezierTo(-leaf.size, 0, 0, -leaf.size);
      path.close();

      canvas.drawPath(path, _leafPaint);
      canvas.restore();
    }
  }

  void _updateAndPaintFireflies(Canvas canvas, Size size, double dt) {
    if (state.fireflies == null) return;

    for (var fly in state.fireflies!) {
      fly.x += fly.speedX * dt * intensity;
      fly.y += fly.speedY * dt * intensity;

      if (fly.x < 0 || fly.x > size.width) fly.speedX *= -1;
      if (fly.y < size.height * 0.4 || fly.y > size.height) fly.speedY *= -1;

      final glow = math.sin(state.time * 3 + fly.phase) * 0.5 + 0.5;

      if (glow > 0.1) {
        _fireflyPaint.color = _dappleLight.withOpacity(glow * 0.6 * intensity);
        canvas.drawCircle(Offset(fly.x, fly.y), fly.size, _fireflyPaint);

        _fireflyPaint.color = _dappleLight.withOpacity(glow * 0.2 * intensity);
        canvas.drawCircle(Offset(fly.x, fly.y), fly.size * 3, _fireflyPaint);
      }
    }
  }

  void _paintLightDapples(Canvas canvas, Size size) {
    // Dapple positions are deterministic – cache them so we don't re-create
    // Random(444) and call nextDouble() 30 times per frame.
    if (state.dappleX == null) {
      final rng = math.Random(444);
      state.dappleX = [];
      state.dappleY = [];
      state.dappleS = [];
      for (int i = 0; i < 10; i++) {
        state.dappleX!.add(rng.nextDouble() * size.width);
        state.dappleY!.add(size.height * (0.7 + rng.nextDouble() * 0.3));
        state.dappleS!.add(20 + rng.nextDouble() * 40);
      }
    }

    for (int i = 0; i < 10; i++) {
      final x = state.dappleX![i];
      final y = state.dappleY![i];
      final s = state.dappleS![i];
      final flicker = math.sin(state.time + i) * 0.5 + 0.5;

      _dapplePaint.shader = ui.Gradient.radial(
        Offset(x, y),
        s,
        [
          _dappleLight.withOpacity(0.2 * flicker * intensity),
          Colors.transparent,
        ],
      );
      canvas.drawRect(Rect.fromCircle(center: Offset(x, y), radius: s), _dapplePaint);
    }
    _dapplePaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _EnhancedForestPainter oldDelegate) {
    return animationEnabled ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.intensity != intensity;
  }
}
