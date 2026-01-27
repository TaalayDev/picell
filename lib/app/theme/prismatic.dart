import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildPrismaticTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.prismatic,
    isDark: true,
    // Primary colors - vibrant magenta/fuchsia
    primaryColor: const Color(0xFFFF1493), // Deep pink/magenta
    primaryVariant: const Color(0xFFFF69B4), // Hot pink
    onPrimary: Colors.white,
    // Secondary colors - electric cyan
    accentColor: const Color(0xFF00FFFF), // Electric cyan
    onAccent: Colors.black,
    // Background colors - deep space for holographic contrast
    background: const Color(0xFF0A0A0F), // Very dark purple-black
    surface: const Color(0xFF1A1A2E), // Dark purple-blue
    surfaceVariant: const Color(0xFF16213E), // Darker blue-purple
    // Text colors - bright holographic
    textPrimary: const Color(0xFFFFFFFF), // Pure white for maximum contrast
    textSecondary: const Color(0xFFE0E0FF), // Light purple-white
    textDisabled: const Color(0xFF8A8AAA), // Muted purple-gray
    // UI colors
    divider: const Color(0xFF2A2D47),
    toolbarColor: const Color(0xFF1A1A2E),
    error: const Color(0xFFFF073A), // Bright neon red
    success: const Color(0xFF00FF7F), // Spring green
    warning: const Color(0xFFFFD700), // Gold
    // Grid colors
    gridLine: const Color(0xFF2A2D47),
    gridBackground: const Color(0xFF1A1A2E),
    // Canvas colors
    canvasBackground: const Color(0xFF0A0A0F),
    selectionOutline: const Color(0xFFFF1493), // Match primary
    selectionFill: const Color(0x30FF1493),
    // Icon colors
    activeIcon: const Color(0xFFFF1493), // Bright magenta for active
    inactiveIcon: const Color(0xFFE0E0FF), // Light purple for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w700, // Bold for futuristic feel
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFFFFFFF),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFE0E0FF),
      ),
    ),
    primaryFontWeight: FontWeight.w600, // Bold for high-tech aesthetic
  );
}

class PrismaticBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const PrismaticBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: theme.type.animationDuration);
    final backgroundController = useAnimationController(duration: const Duration(seconds: 20));

    useEffect(() {
      if (enableAnimation) {
        controller.repeat();
        backgroundController.repeat(reverse: true);
      } else {
        controller.stop();
        controller.value = 0.0;
        backgroundController.stop();
        backgroundController.value = 0.0;
      }
      return null;
    }, [enableAnimation]);

    final t = useAnimation(Tween<double>(begin: 0, end: 1).animate(controller));

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.05).animate(backgroundController),
              child: Image.asset(
                'assets/images/prismatic_background.webp',
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _EnhancedPrismaticPainter(
              t: t,
              primaryColor: theme.primaryColor,
              accentColor: theme.accentColor,
              intensity: intensity.clamp(0.3, 2.0),
              animationEnabled: enableAnimation,
            ),
            size: Size.infinite,
            isComplex: true,
            willChange: enableAnimation,
          ),
        ),
      ],
    );
  }
}

class _EnhancedPrismaticPainter extends CustomPainter {
  final double t; // 0..1
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  _EnhancedPrismaticPainter({
    required this.t,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
  });

  // ---- Loop-safe helpers ----
  // All speeds are integers so sin(2π*speed*(t+1)+φ) == sin(2π*speed*t+φ)
  double get _phase => 2 * math.pi * t;
  double _wave(int speed, [double offset = 0]) => math.sin(_phase * speed + offset);
  double _norm(int speed, [double offset = 0]) => 0.5 * (1 + _wave(speed, offset));

  // Hue uses only (integer * t) for time component; other parts are static offsets.
  Color _getRainbowColor(double staticPos, int k, [double offset = 0]) {
    // staticPos in [0,1) from spatial/index offsets; k is integer harmonic.
    final frac = (staticPos + k * t + offset) % 1.0;
    final hue = (frac * 360.0) % 360.0;
    return HSVColor.fromAHSV(1.0, hue, 0.95, 1.0).toColor();
  }

  // Element counts based on intensity
  int get _hologramCount => (8 * intensity).round().clamp(4, 12);
  int get _particleCount => (60 * intensity).round().clamp(30, 90);
  int get _crystalCount => (12 * intensity).round().clamp(6, 18);

  @override
  void paint(Canvas canvas, Size size) {}

  // ---------- 1) Background sky (loop-safe) ----------
  void _paintHolographicSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base vertical gradient (static)
    final baseSky = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        const [
          Color(0xFF0A0A1F),
          Color(0xFF1A1A3E),
          Color(0xFF2A1A5E),
          Color(0xFF0A0A1F),
        ],
        const [0.0, 0.3, 0.7, 1.0],
      );
    canvas.drawRect(rect, baseSky);

    // Three soft radial overlays; hue animation uses k=1 (integer)
    for (int i = 0; i < 3; i++) {
      final overlayIntensity = _norm(1, i * 0.7);
      final overlayColor = _getRainbowColor(i * 0.21, 1); // k=1 => 1 cycle per loop

      final overlayPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * (0.3 + i * 0.2), size.height * (0.2 + i * 0.3)),
          size.width * (0.6 + i * 0.2),
          [
            overlayColor.withOpacity(0.05 * overlayIntensity * intensity),
            Colors.transparent,
          ],
          const [0.0, 1.0],
        );
      canvas.drawRect(rect, overlayPaint);
    }
  }

  // ---------- 2) Particles (loop-safe) ----------
  void _paintHolographicParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(777); // deterministic

    for (int i = 0; i < _particleCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;

      // Integer harmonics for motion variability
      final h1 = 1 + (i % 3); // 1..3
      final h2 = 2 + (i % 3); // 2..4

      final floatX = baseX + _wave(h1, i * 0.2) * 25 * intensity + _wave(h2, i * 0.4) * 12 * intensity;
      final floatY = baseY + _wave(h1, i * 0.3) * 18 * intensity + _wave(h2, i * 0.6) * 8 * intensity;

      final particleSize = (2 + rng.nextDouble() * 6) * intensity;
      final glowCycle = _norm(1, i * 0.13); // k=1 => perfect loop
      final staticPos = (i * 0.05) % 1.0; // only static offset
      final colorK = 1; // hue cycles once per loop

      if (glowCycle > 0.3) {
        final g = (glowCycle - 0.3) / 0.7;

        // Spectrum color (core)
        paint.color = _getRainbowColor(staticPos, colorK).withOpacity(0.9 * g * intensity);
        canvas.drawCircle(Offset(floatX, floatY), particleSize * g, paint);

        // Shimmer rings (static positions, same k=1 animation)
        for (int ring = 1; ring <= 3; ring++) {
          final ringOpacity = g * (0.4 - ring * 0.1);
          final ringPos = (staticPos + ring * 0.15) % 1.0;
          paint.color = _getRainbowColor(ringPos, colorK).withOpacity(ringOpacity * intensity);
          canvas.drawCircle(Offset(floatX, floatY), particleSize * g * (1 + ring * 0.8), paint);
        }

        // Bright core
        if (g > 0.7) {
          paint.color = Colors.white.withOpacity(0.9 * g * intensity);
          canvas.drawCircle(Offset(floatX, floatY), particleSize * 0.4, paint);
        }
      }
    }
  }

  // ---------- 3) Interference rings (loop-safe) ----------
  void _paintQuantumInterference(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _hologramCount; i++) {
      final cx = size.width * (0.15 + (i / _hologramCount) * 0.7);
      final cy = size.height * (0.25 + _wave(1, i * 0.8) * 0.05); // tiny vertical drift

      final baseSize = (30 + i * 8 + _wave(1, i * 0.5) * 15) * intensity;
      final kPhase = 1 + (i % 3); // integer phase harmonic 1..3
      final phi = i * math.pi / 3; // static offset

      for (int ring = 0; ring < 4; ring++) {
        final rr = baseSize * (0.3 + ring * 0.25);
        final ringIntensity = _norm(kPhase, phi + ring * 0.5);
        if (ringIntensity <= 0.4) continue;

        final pos1 = (i * 0.12 + ring * 0.2) % 1.0;
        final pos2 = (pos1 + 0.5) % 1.0;
        final c1 = _getRainbowColor(pos1, 1);
        final c2 = _getRainbowColor(pos2, 1);
        final mixed = Color.lerp(c1, c2, 0.5)!;

        paint.color = mixed.withOpacity(0.15 * ringIntensity * intensity);

        // 12 points around the ring; subtle radius modulation with k=1 (loop-safe)
        for (int seg = 0; seg < 12; seg++) {
          final a = seg * math.pi / 6;
          final mod = 1.0 + 0.20 * _wave(1, seg + phi);
          final r2 = rr * mod;
          final x = cx + math.cos(a) * r2;
          final y = cy + math.sin(a) * r2;
          canvas.drawCircle(Offset(x, y), 3 * intensity * ringIntensity, paint);
        }
      }
    }
  }

  // ---------- 4) Crystals (loop-safe) ----------
  void _paintCrystalFormations(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(333);

    for (int i = 0; i < _crystalCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final crystalSize = (15 + rng.nextDouble() * 25) * intensity;

      // Rotation with integer harmonic: alternate direction by index
      final kRot = (i % 2 == 0) ? 1 : 2;
      final rot = _phase * kRot + i * 0.8;
      final bright = _norm(1, i * 0.6);

      if (bright <= 0.4) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      for (int facet = 0; facet < 3; facet++) {
        final fSize = crystalSize * (1 - facet * 0.2);
        final fRot = facet * math.pi / 3;
        final pos = ((i * 0.15) + facet * 0.3) % 1.0;

        canvas.save();
        canvas.rotate(fRot);

        final path = Path();
        for (int v = 0; v < 6; v++) {
          final a = v * math.pi / 3;
          final px = math.cos(a) * fSize;
          final py = math.sin(a) * fSize;
          if (v == 0)
            path.moveTo(px, py);
          else
            path.lineTo(px, py);
        }
        path.close();

        paint
          ..strokeWidth = (3 - facet) * intensity
          ..color = _getRainbowColor(pos, 1).withOpacity(0.6 * bright * intensity);
        canvas.drawPath(path, paint);

        if (facet == 0) {
          paint.strokeWidth = 1 * intensity;
          for (int v = 0; v < 6; v++) {
            final a = v * math.pi / 3;
            canvas.drawLine(Offset.zero, Offset(math.cos(a) * fSize * 0.6, math.sin(a) * fSize * 0.6), paint);
          }
        }
        canvas.restore();
      }

      canvas.restore();
    }
  }

  // ---------- 5) Grid (loop-safe) ----------
  void _paintHolographicGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * intensity;

    final spacing = 80.0 * intensity;
    final distort = 15 * intensity;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Integer-harmonic distortions
        final dx = _wave(1, x * 0.01 + y * 0.005) * distort;
        final dy = _wave(2, y * 0.008 + x * 0.006) * distort * 0.7;

        final gx = x + dx;
        final gy = y + dy;

        // Static spatial color position + k=1 animation
        final pos = ((x * 0.003 + y * 0.002) % 1.0);
        final gInt = _norm(1, x * 0.02 + y * 0.015);

        if (gInt > 0.3) {
          paint.color = _getRainbowColor(pos, 1).withOpacity(0.12 * gInt * intensity);

          canvas.drawRect(
            Rect.fromLTWH(gx, gy, spacing * 0.8, spacing * 0.8),
            paint,
          );

          if (gInt > 0.6) {
            final cx = gx + spacing * 0.4;
            final cy = gy + spacing * 0.4;
            final s = spacing * 0.2;
            paint.strokeWidth = 0.5 * intensity;
            canvas.drawLine(Offset(cx - s, cy), Offset(cx + s, cy), paint);
            canvas.drawLine(Offset(cx, cy - s), Offset(cx, cy + s), paint);
            paint.strokeWidth = 1 * intensity;
          }
        }
      }
    }
  }

  // ---------- 6) Vortex (loop-safe) ----------
  void _paintPrismaticVortex(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final cy = size.height * 0.4;
    final vI = _norm(1); // k=1

    if (vI > 0.4) {
      for (int s = 0; s < 3; s++) {
        final kSpiral = 1 + s; // 1,2,3 cycles per loop
        final phase = _phase * kSpiral + s * (2 * math.pi / 3);

        final path = Path();
        bool first = true;

        for (double r = 5; r < 80 * intensity; r += 3) {
          final a = phase + r * 0.08;
          final rm = r * (0.9 + 0.1 * _wave(1, r * 0.02)); // subtle pulsation
          final x = cx + math.cos(a) * rm;
          final y = cy + math.sin(a) * rm;
          if (first) {
            path.moveTo(x, y);
            first = false;
          } else {
            path.lineTo(x, y);
          }
        }

        final pos = (s * 0.33) % 1.0;
        paint
          ..strokeWidth = (4 - s) * intensity
          ..color = _getRainbowColor(pos, 1).withOpacity(0.8 * vI * intensity);
        canvas.drawPath(path, paint);
      }

      // Core
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.9 * vI * intensity);
      canvas.drawCircle(Offset(cx, cy), 4 * intensity * vI, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedPrismaticPainter old) {
    return animationEnabled;
  }
}
