import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Matrix4;

import 'theme.dart';

// ============================================================================
// ORIGAMI PAPER THEME BUILDER
// ============================================================================

AppTheme buildOrigamiTheme() {
  // Clean, geometric fonts to match the folding style
  final baseTextTheme = GoogleFonts.quicksandTextTheme();
  final bodyTextTheme = GoogleFonts.mulishTextTheme();

  return AppTheme(
    type: ThemeType.origami,
    isDark: false, // Bright and airy

    // Primary: Muted Sage Green
    primaryColor: const Color(0xFF8DA399),
    // Variant: Darker Moss
    primaryVariant: const Color(0xFF5F756C),
    onPrimary: Colors.white,

    // Accent: Soft Coral / Salmon
    accentColor: const Color(0xFFE6AAC4),
    onAccent: const Color(0xFF4A3B3C),

    // Backgrounds: Textured Paper (Washi)
    background: const Color(0xFFF9F7F2), // Creamy off-white
    surface: const Color(0xFFFFFFFF), // Pure white
    surfaceVariant: const Color(0xFFF0EBE0), // Beige tint

    // Text: Charcoal / Soft Ink
    textPrimary: const Color(0xFF4A4540),
    textSecondary: const Color(0xFF8A8580),
    textDisabled: const Color(0xFFC0BAB5),

    // UI Colors
    divider: const Color(0xFFE0D8D0),
    toolbarColor: const Color(0xFFF9F7F2),
    error: const Color(0xFFD97D7D), // Muted Red
    success: const Color(0xFF95BFA3), // Muted Mint
    warning: const Color(0xFFEBCB8B), // Muted Gold

    // Grid
    gridLine: const Color(0xFFEBE5DD),
    gridBackground: const Color(0xFFF9F7F2),

    // Canvas
    canvasBackground: const Color(0xFFFCFAF7),
    selectionOutline: const Color(0xFFE6AAC4),
    selectionFill: const Color(0x33E6AAC4),

    // Icons
    activeIcon: const Color(0xFF8DA399),
    inactiveIcon: const Color(0xFFACA59E),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF4A4540),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF4A4540),
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF5F756C),
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF4A4540),
        fontSize: 16,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF6D6660),
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

// ============================================================================
// ORIGAMI ANIMATED BACKGROUND
// ============================================================================

class OrigamiBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const OrigamiBackground({
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
    final paperState = useMemoized(() => _OrigamiState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _OrigamiPainter(
          repaint: controller,
          state: paperState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          backgroundColor: theme.background,
          intensity: intensity.clamp(0.0, 2.0),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for physics and objects
class _OrigamiState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_PaperShape>? shapes;
  List<_DustParticle>? dust;
}

enum _ShapeType { crane, plane, boat, diamond }

class _PaperShape {
  double x;
  double y;
  double z; // Depth
  double size;

  // Rotation (Euler angles)
  double rx;
  double ry;
  double rz;

  // Rotation Speeds
  double rSpeedX;
  double rSpeedY;
  double rSpeedZ;

  // Movement
  double speedX;
  double speedY;

  _ShapeType type;
  Color color;

  _PaperShape({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.rx,
    required this.ry,
    required this.rz,
    required this.rSpeedX,
    required this.rSpeedY,
    required this.rSpeedZ,
    required this.speedX,
    required this.speedY,
    required this.type,
    required this.color,
  });
}

class _DustParticle {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;
  double opacity;

  _DustParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
  });
}

class _OrigamiPainter extends CustomPainter {
  final _OrigamiState state;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final double intensity;
  final bool animationEnabled;

  // Palette
  static const Color _paperWhite = Color(0xFFFFFFFF);
  static const Color _paperShadow = Color(0xFFE0E0E0);
  static const Color _softBlue = Color(0xFFA8C8E6);
  static const Color _softPink = Color(0xFFE6AAC4);
  static const Color _softYellow = Color(0xFFE6D6AA);

  final math.Random _rng = math.Random(1337);

  _OrigamiPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
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

    if (state.shapes == null) _initWorld(size);

    _paintBackground(canvas, size);
    _paintPaperTexture(canvas, size);
    _updateAndPaintShapes(canvas, size, dt);
    _updateAndPaintDust(canvas, size, dt);
    _paintVignette(canvas, size);
  }

  void _initWorld(Size size) {
    state.shapes = [];
    state.dust = [];
    final rng = math.Random(42);

    // Init Floating Paper Shapes
    int shapeCount = (12 * intensity).round().clamp(5, 20);
    for (int i = 0; i < shapeCount; i++) {
      final typeVal = rng.nextInt(4);
      final type = _ShapeType.values[typeVal];

      Color color;
      switch (typeVal) {
        case 0:
          color = _softPink;
          break;
        case 1:
          color = _softBlue;
          break;
        case 2:
          color = _paperWhite;
          break;
        default:
          color = _softYellow;
      }

      state.shapes!.add(_PaperShape(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        z: 0.2 + rng.nextDouble() * 0.8,
        size: 30 + rng.nextDouble() * 40,
        rx: rng.nextDouble() * math.pi * 2,
        ry: rng.nextDouble() * math.pi * 2,
        rz: rng.nextDouble() * math.pi * 2,
        rSpeedX: (rng.nextDouble() - 0.5) * 1.0,
        rSpeedY: (rng.nextDouble() - 0.5) * 1.0,
        rSpeedZ: (rng.nextDouble() - 0.5) * 0.5,
        speedX: (rng.nextDouble() - 0.5) * 20,
        speedY: (rng.nextDouble() - 0.5) * 20,
        type: type,
        color: color,
      ));
    }

    // Init Dust
    for (int i = 0; i < 50; i++) {
      state.dust!.add(_DustParticle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        speedX: (rng.nextDouble() - 0.5) * 15,
        speedY: (rng.nextDouble() - 0.5) * 15,
        size: 1 + rng.nextDouble() * 2,
        opacity: 0.3 + rng.nextDouble() * 0.4,
      ));
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Subtle warmth
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.width, size.height),
      [
        backgroundColor,
        Color.lerp(backgroundColor, const Color(0xFFF0EBE0), 0.5)!,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  void _paintPaperTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.02 * intensity)
      ..style = PaintingStyle.fill;

    final rng = math.Random(1);
    for (int i = 0; i < 500; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 2 + rng.nextDouble() * 4;
      final h = 1 + rng.nextDouble() * 2;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }
  }

  void _updateAndPaintShapes(Canvas canvas, Size size, double dt) {
    if (state.shapes == null) return;

    // Sort by Z for correct depth
    state.shapes!.sort((a, b) => a.z.compareTo(b.z));

    for (var shape in state.shapes!) {
      // Update Physics
      shape.x += shape.speedX * dt * intensity;
      shape.y += shape.speedY * dt * intensity;
      shape.rx += shape.rSpeedX * dt * intensity;
      shape.ry += shape.rSpeedY * dt * intensity;
      shape.rz += shape.rSpeedZ * dt * intensity;

      // Wrap around
      if (shape.x < -100) shape.x = size.width + 100;
      if (shape.x > size.width + 100) shape.x = -100;
      if (shape.y < -100) shape.y = size.height + 100;
      if (shape.y > size.height + 100) shape.y = -100;

      // Draw
      _draw3DShape(canvas, shape);
    }
  }

  void _draw3DShape(Canvas canvas, _PaperShape shape) {
    canvas.save();
    canvas.translate(shape.x, shape.y);

    // Scale by Z (depth)
    final scale = shape.z * intensity;
    canvas.scale(scale);

    // Apply 3D rotation projection
    // Simple isometric-like projection logic
    // We simulate 3D faces by calculating normal vectors and lighting

    final Matrix4 matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(shape.rx)
      ..rotateY(shape.ry)
      ..rotateZ(shape.rz);

    // Transform faces based on shape type
    switch (shape.type) {
      case _ShapeType.crane:
        _drawCrane(canvas, shape.color, shape.size, matrix);
        break;
      case _ShapeType.plane:
        _drawPlane(canvas, shape.color, shape.size, matrix);
        break;
      case _ShapeType.boat:
        _drawBoat(canvas, shape.color, shape.size, matrix);
        break;
      case _ShapeType.diamond:
        _drawDiamond(canvas, shape.color, shape.size, matrix);
        break;
    }

    canvas.restore();
  }

  // Helper to draw a single 3D triangle face with lighting
  void _drawFace(Canvas canvas, List<Offset> points, Matrix4 transform, Color baseColor) {
    // Transform points
    final List<Offset> transformed = points.map((p) {
      final vec = transform.perspectiveTransform(Vector3(p.dx, p.dy, 0.0));
      return Offset(vec.x, vec.y);
    }).toList();

    // Calculate normal (cross product of two edges) to determine facing and lighting
    // Edge 1
    final dx1 = transformed[1].dx - transformed[0].dx;
    final dy1 = transformed[1].dy - transformed[0].dy;
    // Edge 2
    final dx2 = transformed[2].dx - transformed[0].dx;
    final dy2 = transformed[2].dy - transformed[0].dy;

    // Z component of cross product (2D equivalent for winding order)
    final crossZ = dx1 * dy2 - dy1 * dx2;

    // Back-face culling (if rotating) or just use it for shading
    // A positive CrossZ usually means facing towards camera in standard winding

    // Lighting calculation based on "normal"
    // We simulate a light source from top-left
    // Simplified: adjust lightness based on rotation

    final path = Path()
      ..moveTo(transformed[0].dx, transformed[0].dy)
      ..lineTo(transformed[1].dx, transformed[1].dy)
      ..lineTo(transformed[2].dx, transformed[2].dy)
      ..close();

    Color faceColor = baseColor;

    // If facing away, make it darker (back of paper)
    if (crossZ < 0) {
      faceColor = Color.lerp(baseColor, Colors.black, 0.3)!;
    } else {
      // Front facing, apply varying light
      // We can use the transformed position variance to fake lighting
      // Or simply use the Z order we calculated?
      // Actually crossZ magnitude roughly relates to how "flat" it is to camera
      // Let's keep it simple: flat colors with clear "back" side
    }

    // Shadow
    canvas.drawPath(
        path.shift(const Offset(2, 2)),
        Paint()
          ..color = Colors.black.withOpacity(0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Main Face
    canvas.drawPath(
        path,
        Paint()
          ..color = faceColor
          ..style = PaintingStyle.fill);

    // Fold Crease
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
  }

  void _drawDiamond(Canvas canvas, Color color, double s, Matrix4 m) {
    // Two triangles back to back
    // Top
    _drawFace(canvas, [Offset(0, -s), Offset(s * 0.6, 0), Offset(-s * 0.6, 0)], m, color);
    // Bottom
    _drawFace(canvas, [Offset(-s * 0.6, 0), Offset(s * 0.6, 0), Offset(0, s)], m, color);
  }

  void _drawPlane(Canvas canvas, Color color, double s, Matrix4 m) {
    // Body
    _drawFace(canvas, [Offset(0, -s), Offset(s * 0.2, s), Offset(-s * 0.2, s)], m, color);
    // Left Wing
    _drawFace(canvas, [Offset(0, -s * 0.2), Offset(-s, s * 0.5), Offset(0, s * 0.2)], m, color);
    // Right Wing
    _drawFace(canvas, [Offset(0, -s * 0.2), Offset(0, s * 0.2), Offset(s, s * 0.5)], m, color);
  }

  void _drawBoat(Canvas canvas, Color color, double s, Matrix4 m) {
    // Hull
    _drawFace(canvas, [Offset(-s, 0), Offset(s, 0), Offset(s * 0.5, s * 0.5)], m, color);
    _drawFace(canvas, [Offset(-s, 0), Offset(s * 0.5, s * 0.5), Offset(-s * 0.5, s * 0.5)], m, color);
    // Sail
    _drawFace(canvas, [Offset(0, -s), Offset(s * 0.5, 0), Offset(0, 0)], m, color);
  }

  void _drawCrane(Canvas canvas, Color color, double s, Matrix4 m) {
    // Body
    _drawFace(canvas, [Offset(0, 0), Offset(s * 0.5, s * 0.2), Offset(0, s * 0.5)], m, color);
    // Neck/Head
    _drawFace(canvas, [Offset(0, 0), Offset(-s * 0.5, -s * 0.5), Offset(0, s * 0.2)], m, color);
    // Wing 1
    _drawFace(canvas, [Offset(0, 0), Offset(s, -s * 0.2), Offset(s * 0.5, s * 0.2)], m, color);
    // Wing 2
    _drawFace(canvas, [Offset(0, 0), Offset(s * 0.2, s * 0.2), Offset(s * 0.8, -s * 0.4)], m, color);
  }

  void _updateAndPaintDust(Canvas canvas, Size size, double dt) {
    if (state.dust == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var d in state.dust!) {
      d.x += d.speedX * dt * intensity;
      d.y += d.speedY * dt * intensity;

      if (d.x < 0) d.x = size.width;
      if (d.x > size.width) d.x = 0;
      if (d.y < 0) d.y = size.height;
      if (d.y > size.height) d.y = 0;

      paint.color = primaryColor.withOpacity(d.opacity * 0.3 * intensity);
      canvas.drawCircle(Offset(d.x, d.y), d.size, paint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.7,
      [
        Colors.transparent,
        Colors.white.withOpacity(0.4 * intensity),
      ],
      [0.6, 1.0],
    );

    canvas.drawRect(
        rect,
        Paint()
          ..shader = gradient
          ..blendMode = BlendMode.softLight);
  }

  @override
  bool shouldRepaint(covariant _OrigamiPainter oldDelegate) {
    return animationEnabled;
  }
}

// Vector3 Shim for Matrix4
// class Vector3 {
//   final double x;
//   final double y;
//   final double z;
//   Vector3(this.x, this.y, this.z);
// }
