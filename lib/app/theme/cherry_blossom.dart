import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildCherryBlossomTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.cherryBlossom,
    isDark: false,
    // Primary colors - soft sakura pink
    primaryColor: const Color(0xFFFFB7C5), // Soft sakura pink
    primaryVariant: const Color(0xFFFF91A4), // Slightly deeper pink
    onPrimary: const Color(0xFF5D2C2F), // Dark rose for contrast
    // Secondary colors - fresh spring green
    accentColor: const Color(0xFF98D8C8), // Soft mint green
    onAccent: const Color(0xFF2D5016), // Dark green for contrast
    // Background colors - very light and airy
    background: const Color(0xFFFDF8F9), // Very light pink-white
    surface: const Color(0xFFFFFFFF), // Pure white
    surfaceVariant: const Color(0xFFF7F0F2), // Light pink-gray
    // Text colors - soft but readable
    textPrimary: const Color(0xFF3E2723), // Dark brown with warmth
    textSecondary: const Color(0xFF795548), // Medium brown
    textDisabled: const Color(0xFFBCAAA4), // Light brown-pink
    // UI colors
    divider: const Color(0xFFE8DDDF), // Very light pink-gray
    toolbarColor: const Color(0xFFF7F0F2),
    error: const Color(0xFFD32F2F), // Traditional red
    success: const Color(0xFF4CAF50), // Fresh green
    warning: const Color(0xFFFF9800), // Warm orange
    // Grid colors
    gridLine: const Color(0xFFE8DDDF),
    gridBackground: const Color(0xFFFFFFFF),
    // Canvas colors
    canvasBackground: const Color(0xFFFFFFFF),
    selectionOutline: const Color(0xFFFFB7C5), // Match primary
    selectionFill: const Color(0x30FFB7C5),
    // Icon colors
    activeIcon: const Color(0xFFFFB7C5), // Sakura pink for active
    inactiveIcon: const Color(0xFF795548), // Brown for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF3E2723),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF3E2723),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF3E2723),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF795548),
      ),
    ),
    primaryFontWeight: FontWeight.w400, // Light weight for elegant feel
  );
}

// Cherry Blossom theme background with falling sakura petals
class CherryBlossomBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CherryBlossomBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: theme.type.animationDuration);

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
      } else {
        controller.stop();
        controller.value = 0.0; // exact loop start
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(Tween<double>(begin: 0, end: 1).animate(controller));

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CherryBlossomPainter(
          t: t,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.5, 1.8),
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CherryBlossomPainter extends CustomPainter {
  final double t; // 0..1
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _CherryBlossomPainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  // Loop helpers
  double get _phase => 2 * math.pi * t;
  double _wave(double speed, [double off = 0]) => math.sin(_phase * speed + off);
  double _norm(double speed, [double off = 0]) => 0.5 * (1 + _wave(speed, off));

  // Palette (derived to keep theme-compatible pinks)
  late final Color _petal = Color.lerp(primaryColor, const Color(0xFFFFC1D9), 0.6)!;
  late final Color _petalDeep = Color.lerp(accentColor, const Color(0xFFEE6A9E), 0.5)!;
  late final Color _skyTop = Color.lerp(const Color(0xFFEFF7FF), _petal.withOpacity(1), 0.18)!;
  late final Color _skyBottom = Color.lerp(const Color(0xFFFFF1F6), _petal.withOpacity(1), 0.35)!;

  // Counts
  int get _backCount => (18 * intensity).round(); // blurred background petals
  int get _midCount => (28 * intensity).round(); // main layer
  int get _foreCount => (10 * intensity).round(); // big, crisp foreground petals
  int get _blossoms => (4 * intensity).round().clamp(2, 6);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintBlossoms(canvas, size); // stationary blossoms near edges
    _paintFallingPetals(canvas, size); // layered falling petals
    _paintVignette(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBottom],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    // Soft bokeh hints (very subtle)
    final bokeh = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final cx = size.width * (0.1 + 0.16 * i);
      final cy = size.height * (0.18 + 0.08 * _wave(0.15, i.toDouble()));
      bokeh
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..color = Colors.white.withOpacity(0.05);
      canvas.drawCircle(Offset(cx, cy), 24 + 6.0 * i, bokeh);
    }
  }

  // --- Shapes ---------------------------------------------------------------

  /// Sakura petal path in local space (base at (0,0), tip at (0,h))
  Path _petalPath(double w, double h, {double notch = 0.18}) {
    final p = Path();
    p.moveTo(0, 0);
    // left side up to near tip
    p.cubicTo(-w * 0.65, h * 0.15, -w * 0.75, h * 0.65, -w * 0.15, h * 0.90);
    // small notch at the tip
    p.quadraticBezierTo(-w * notch, h * 0.98, 0, h);
    p.quadraticBezierTo(w * notch, h * 0.98, w * 0.15, h * 0.90);
    // right side back to base
    p.cubicTo(w * 0.75, h * 0.65, w * 0.65, h * 0.15, 0, 0);
    p.close();
    return p;
  }

  void _drawPetal(Canvas canvas, Offset pos, double w, double h, double rotation, double flip, Color fill,
      {double outline = 0.5, double blur = 0}) {
    final paintFill = Paint()..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outline
      ..color = _petalDeep.withOpacity(0.18);

    if (blur > 0) {
      paintFill.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      paintStroke.maskFilter = MaskFilter.blur(BlurStyle.normal, blur * 0.6);
    }

    final path = _petalPath(w, h, notch: 0.16);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    canvas.scale(flip, 1); // flip anim for “fluttering”
    // fill
    paintFill.color = fill;
    canvas.drawPath(path, paintFill);
    // edge
    canvas.drawPath(path, paintStroke);
    // soft highlight near base
    final hl = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = Colors.white.withOpacity(0.10);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, h * 0.25), width: w * 0.8, height: h * 0.45), hl);
    canvas.restore();
  }

  void _drawBlossom(Canvas canvas, Offset center, double r, double rot, {double opacity = 1}) {
    final petalColor = Color.lerp(_petal, Colors.white, 0.25)!.withOpacity(0.92 * opacity);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (0.8 + r * 0.02).clamp(0.8, 2.0)
      ..color = _petalDeep.withOpacity(0.25 * opacity);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    // 5 petals
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * (2 * math.pi / 5));
      _drawPetal(
        canvas,
        Offset(0, 0),
        r * 0.85,
        r * 1.2,
        -math.pi / 2, // point outward
        1.0,
        petalColor,
        outline: stroke.strokeWidth,
      );
      canvas.restore();
    }

    // center
    final core = Paint()..color = Colors.white.withOpacity(0.85 * opacity);
    canvas.drawCircle(Offset.zero, r * 0.4, core);

    // stamens (tiny yellow dots)
    final stamenPaint = Paint()..color = const Color(0xFFFFE27A).withOpacity(0.9 * opacity);
    for (int i = 0; i < 10; i++) {
      final a = i * (2 * math.pi / 10) + 0.2 * _wave(0.3, i.toDouble());
      final rr = r * (0.5 + 0.08 * _norm(0.4, i.toDouble()));
      canvas.drawCircle(Offset(math.cos(a) * rr, math.sin(a) * rr), r * 0.07, stamenPaint);
    }

    canvas.restore();
  }

  // --- Layers ---------------------------------------------------------------

  void _paintBlossoms(Canvas canvas, Size size) {
    // A few anchored blossoms near edges (parallax sway)
    final rng = math.Random(913);
    for (int i = 0; i < _blossoms; i++) {
      final side = (i % 2 == 0) ? -1.0 : 1.0;
      final x = side < 0
          ? size.width * (0.08 + 0.06 * i) + 8 * _wave(0.12, i.toDouble())
          : size.width * (0.92 - 0.06 * i) + 8 * _wave(0.12, i.toDouble());
      final y = size.height * (0.18 + 0.15 * (i / _blossoms)) + 6 * _wave(0.18, i * 0.7);
      final r = (16.0 + rng.nextDouble() * 12.0) * (0.9 + 0.3 * intensity);
      _drawBlossom(canvas, Offset(x, y), r, _wave(0.06, i.toDouble()) * 0.4, opacity: 0.9);
    }
  }

  double _smoothstep(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  void _paintFallingPetals(Canvas canvas, Size size) {
    final rng = math.Random(555); // stable seed -> deterministic per index
    final wind = 16.0 * intensity * _wave(0.05); // gentle global sway
    final fallMargin = 80.0; // travel beyond bounds for clean entry/exit
    final travel = size.height + 2 * fallMargin; // total vertical travel

    void drawLayer(int count, double sizeMin, double sizeMax, double blur, double alphaMul) {
      for (int i = 0; i < count; i++) {
        // Stable per-petal params (same order every frame)
        final baseX = rng.nextDouble() * size.width;
        final speed = 0.25 + rng.nextDouble() * 0.35; // fall speed factor
        final amp = 14.0 + rng.nextDouble() * 10.0; // horizontal sway
        final flipSpd = 0.9 + rng.nextDouble() * 1.4;
        final rotSpd = 0.3 + rng.nextDouble() * 0.6;
        final off = i * 0.113 + rng.nextDouble() * 2.0; // phase offset (stagger)

        // Seamless life progress 0..1 (NO random baseY anymore)
        final s = (t * speed + off) % 1.0;

        // Always start above screen and exit below
        final y = -fallMargin + s * travel;

        // Horizontal path: wind + flutter sway (periodic => seamless)
        final x = baseX + wind + math.sin(_phase * 0.7 + off) * 4.0 + math.sin(s * 2 * math.pi * 1.2 + off) * amp;

        // Size & orientation
        final sz = sizeMin + rng.nextDouble() * (sizeMax - sizeMin);
        final w = sz * (0.9 + 0.2 * rng.nextDouble());
        final h = sz * (1.2 + 0.25 * rng.nextDouble());
        final rotation = _phase * rotSpd + off;
        final flip = 0.75 + 0.25 * math.sin(_phase * flipSpd + off); // 0.5..1.0

        // Soft fade near top/bottom to avoid popping
        final fadeIn = _smoothstep(-fallMargin, 0.0, y);
        final fadeOut = 1.0 - _smoothstep(size.height, size.height + fallMargin, y);
        final edgeFade = (fadeIn * fadeOut).clamp(0.0, 1.0);

        // Color/opacity
        final baseCol = Color.lerp(_petal, Colors.white, 0.25 + 0.35 * rng.nextDouble())!;
        final opacity = (0.65 * edgeFade) * alphaMul; // stronger base, modulated by edge fade
        final fill = baseCol.withOpacity(opacity.clamp(0.0, 1.0));

        if (opacity <= 0) continue;

        _drawPetal(
          canvas,
          Offset(x, y),
          w,
          h,
          rotation,
          flip,
          fill,
          outline: 0.6,
          blur: blur,
        );
      }
    }

    // Layers: back (blurred), mid, foreground
    drawLayer(_backCount, 6, 10, 3.5, 0.55);
    drawLayer(_midCount, 8, 14, 0.0, 0.75);
    drawLayer(_foreCount, 12, 20, 0.0, 0.9);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.16),
        ],
        stops: const [0.82, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.55),
        radius: size.longestSide * 0.85,
      ));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _CherryBlossomPainter old) {
    return animationEnabled;
  }
}
