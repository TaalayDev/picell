import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// ART NOUVEAU THEME BUILDER
// ============================================================================

AppTheme buildArtNouveauTheme() {
  // Elegant, decorative serif fonts suited for the era
  final baseTextTheme = GoogleFonts.playfairDisplayTextTheme();
  final bodyTextTheme = GoogleFonts.aliceTextTheme();

  return AppTheme(
    type: ThemeType.artNouveau,
    isDark: false,

    // Primary: Muted Gold / Ochre
    primaryColor: const Color(0xFFC5A059),
    // Variant: Darker Antique Gold
    primaryVariant: const Color(0xFF9C7C38),
    onPrimary: const Color(0xFF2C241B),

    // Accent: Dusty Rose / Peacock Blue
    accentColor: const Color(0xFF2E5E68), // Peacock Blue
    onAccent: const Color(0xFFFDF5E6),

    // Backgrounds: Parchment / Cream
    background: const Color(0xFFFDF5E6), // Old Lace
    surface: const Color(0xFFF3EAC2), // Parchment
    surfaceVariant: const Color(0xFFE6D6A9),

    // Text: Dark Sepia / Charcoal
    textPrimary: const Color(0xFF2C241B),
    textSecondary: const Color(0xFF5D4E40),
    textDisabled: const Color(0xFFA89F91),

    // UI Colors
    divider: const Color(0xFFC5A059),
    toolbarColor: const Color(0xFFFDF5E6),
    error: const Color(0xFFB76E79), // Muted Rose Red
    success: const Color(0xFF6B8C42), // Olive Green
    warning: const Color(0xFFE3A857), // Amber

    // Grid
    gridLine: const Color(0xFFDCC8A0),
    gridBackground: const Color(0xFFFDF5E6),

    // Canvas
    canvasBackground: const Color(0xFFFAF0DC),
    selectionOutline: const Color(0xFFC5A059),
    selectionFill: const Color(0x22C5A059),

    // Icons
    activeIcon: const Color(0xFFC5A059),
    inactiveIcon: const Color(0xFF8B7355),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF2C241B),
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF2C241B),
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF2E5E68),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF2C241B),
        fontSize: 16,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF5D4E40),
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// ART NOUVEAU ANIMATED BACKGROUND
// ============================================================================

class ArtNouveauBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const ArtNouveauBackground({
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

    final state = useMemoized(() => _NouveauState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ArtNouveauPainter(
          repaint: controller,
          state: state,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          backgroundColor: theme.background,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State for infinite animation
class _NouveauState {
  double time = 0;
  double lastFrameTimestamp = 0;
  List<_Vine>? vines;
  List<_DustMote>? dust;
}

class _Vine {
  // Base properties
  final double startX;
  final double width;
  final double height;
  final bool isLeft; // Curving left or right dominant

  // Animation offsets
  final double phase;
  final double speed;

  // Visuals
  final Color color;
  final int complexity; // Number of curves

  _Vine({
    required this.startX,
    required this.width,
    required this.height,
    required this.isLeft,
    required this.phase,
    required this.speed,
    required this.color,
    required this.complexity,
  });
}

class _DustMote {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;
  double alpha;

  _DustMote({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.alpha,
  });
}

class _ArtNouveauPainter extends CustomPainter {
  final _NouveauState state;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final double intensity;

  // Palette
  static const Color _sageGreen = Color(0xFF8FA87B);
  static const Color _dustyRose = Color(0xFFB76E79);
  static const Color _gold = Color(0xFFC5A059);
  static const Color _cream = Color(0xFFFDF5E6);

  final math.Random _rng = math.Random(1890); // Art Nouveau era start approx

  _ArtNouveauPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.intensity,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Time accumulation
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    if (state.vines == null) _initWorld(size);

    // 1. Background Texture
    _paintBackground(canvas, size);

    // 2. Animated Vines (Back layer)
    _paintVines(canvas, size, true);

    // 3. Floating Dust/Pollen
    _updateAndPaintDust(canvas, size, dt);

    // 4. Animated Vines (Front layer)
    _paintVines(canvas, size, false);

    // 5. Ornamental Frame
    _paintFrame(canvas, size);
  }

  void _initWorld(Size size) {
    state.vines = [];
    state.dust = [];
    final rng = math.Random(999);

    // Generate Vines
    // Background layer
    for (int i = 0; i < 6; i++) {
      state.vines!.add(_Vine(
        startX: size.width * (0.1 + i * 0.15),
        width: 30 + rng.nextDouble() * 40,
        height: size.height * (0.6 + rng.nextDouble() * 0.4),
        isLeft: i % 2 == 0,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 0.5 + rng.nextDouble() * 0.5,
        color: _sageGreen.withOpacity(0.3),
        complexity: 3 + rng.nextInt(2),
      ));
    }

    // Foreground layer
    for (int i = 0; i < 4; i++) {
      state.vines!.add(_Vine(
        startX: size.width * (0.05 + i * 0.25),
        width: 40 + rng.nextDouble() * 50,
        height: size.height * (0.8 + rng.nextDouble() * 0.2),
        isLeft: i % 2 != 0,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 0.7 + rng.nextDouble() * 0.5,
        color: _gold.withOpacity(0.8), // Foreground darker/richer
        complexity: 4,
      ));
    }

    // Init Dust
    for (int i = 0; i < 40; i++) {
      state.dust!.add(_DustMote(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        speedX: (rng.nextDouble() - 0.5) * 10,
        speedY: (rng.nextDouble() - 0.5) * 10,
        size: 1 + rng.nextDouble() * 3,
        alpha: 0.2 + rng.nextDouble() * 0.3,
      ));
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..color = backgroundColor;
    canvas.drawRect(rect, paint);

    // Subtle paper grain
    final grainPaint = Paint()..style = PaintingStyle.stroke;
    final rng = math.Random(1); // Fixed seed for texture

    for (int i = 0; i < 1000; i++) {
      grainPaint.color = Colors.brown.withOpacity(0.03 * intensity);
      grainPaint.strokeWidth = rng.nextDouble();
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, grainPaint);
    }
  }

  void _paintVines(Canvas canvas, Size size, bool backgroundLayer) {
    if (state.vines == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var vine in state.vines!) {
      // Filter layers
      bool isBgVine = vine.color.opacity < 0.5;
      if (backgroundLayer != isBgVine) continue;

      paint.color = vine.color.withOpacity(vine.color.opacity * intensity);
      // Width tapers at top? No, Art Nouveau lines often keep uniform or taper elegantly.
      // We'll vary width slightly.

      final path = Path();
      final startY = size.height;
      final startX = vine.startX;

      path.moveTo(startX, startY);

      // Construct "Whiplash" curve
      double currentX = startX;
      double currentY = startY;

      for (int i = 0; i < vine.complexity; i++) {
        final t = state.time * vine.speed + vine.phase + i;

        // Sway calculation
        final sway = math.sin(t) * 30 * intensity;
        final sway2 = math.cos(t * 0.7) * 20 * intensity;

        final segmentHeight = vine.height / vine.complexity;
        final targetY = currentY - segmentHeight;

        // Control points for S-curve
        final cp1X = currentX + (vine.isLeft ? -1 : 1) * vine.width + sway;
        final cp1Y = currentY - segmentHeight * 0.3;

        final cp2X = currentX + (vine.isLeft ? 1 : -1) * (vine.width * 0.5) + sway2;
        final cp2Y = currentY - segmentHeight * 0.7;

        // End point drifts slightly
        final endX = vine.startX + math.sin(t * 0.5) * 50 * intensity;

        path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, endX, targetY);

        currentX = endX;
        currentY = targetY;

        // Draw leaves/flowers at segment joints
        if (!backgroundLayer && i < vine.complexity - 1) {
          _drawStylizedLeaf(canvas, Offset(currentX, currentY), t, vine.isLeft);
        }
      }

      // Variable stroke width for elegance
      paint.strokeWidth = (isBgVine ? 2.0 : 4.0) * intensity;
      canvas.drawPath(path, paint);

      // Top flower/bud
      if (!backgroundLayer) {
        _drawNouveauFlower(canvas, Offset(currentX, currentY), state.time * vine.speed + vine.phase);
      }
    }
  }

  void _drawStylizedLeaf(Canvas canvas, Offset pos, double anglePhase, bool isLeft) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _sageGreen.withOpacity(0.8 * intensity);

    final size = 15.0 * intensity;
    final sway = math.sin(anglePhase) * 0.2;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate((isLeft ? -0.5 : 0.5) + sway);

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size, -size * 0.5, size * 1.5, 0);
    path.quadraticBezierTo(size, size * 0.5, 0, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawNouveauFlower(Canvas canvas, Offset pos, double time) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _dustyRose.withOpacity(0.9 * intensity);

    final size = 12.0 * intensity;
    final breathe = 1.0 + 0.1 * math.sin(time * 2);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(breathe);

    // Stylized tulip/bud shape
    final path = Path();
    path.moveTo(0, 0);
    // Left petal
    path.quadraticBezierTo(-size, -size, 0, -size * 2);
    // Right petal
    path.quadraticBezierTo(size, -size, 0, 0);

    canvas.drawPath(path, paint);

    // Center detail
    paint.color = _gold;
    canvas.drawCircle(Offset(0, -size * 1.2), size * 0.2, paint);

    canvas.restore();
  }

  void _updateAndPaintDust(Canvas canvas, Size size, double dt) {
    if (state.dust == null) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var d in state.dust!) {
      d.x += d.speedX * dt * intensity;
      d.y += d.speedY * dt * intensity;

      // Wrap
      if (d.x < 0) d.x = size.width;
      if (d.x > size.width) d.x = 0;
      if (d.y < 0) d.y = size.height;
      if (d.y > size.height) d.y = 0;

      final shimmer = 0.5 + 0.5 * math.sin(state.time + d.x);

      paint.color = _gold.withOpacity(d.alpha * shimmer * intensity);
      canvas.drawCircle(Offset(d.x, d.y), d.size, paint);
    }
  }

  void _paintFrame(Canvas canvas, Size size) {
    // Ornamental Art Nouveau Frame corners
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = primaryColor.withOpacity(0.5 * intensity)
      ..strokeWidth = 2.0 * intensity;

    final cornerSize = 100.0 * intensity;

    // Top Left
    _drawCorner(canvas, paint, Offset(0, 0), cornerSize, 1, 1);
    // Top Right
    _drawCorner(canvas, paint, Offset(size.width, 0), cornerSize, -1, 1);
    // Bottom Left
    _drawCorner(canvas, paint, Offset(0, size.height), cornerSize, 1, -1);
    // Bottom Right
    _drawCorner(canvas, paint, Offset(size.width, size.height), cornerSize, -1, -1);
  }

  void _drawCorner(Canvas canvas, Paint paint, Offset corner, double size, double scaleX, double scaleY) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.scale(scaleX, scaleY);

    final path = Path();
    // Whiplash corner motif
    path.moveTo(0, size);
    path.cubicTo(0, size * 0.5, size * 0.1, size * 0.1, size, 0);
    // Inner loop
    path.moveTo(0, size * 0.8);
    path.cubicTo(size * 0.2, size * 0.8, size * 0.5, size * 0.5, size * 0.8, 0);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArtNouveauPainter oldDelegate) {
    return true; // Infinite animation
  }
}
