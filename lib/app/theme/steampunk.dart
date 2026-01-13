import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// STEAMPUNK THEME BUILDER
// ============================================================================

AppTheme buildSteampunkTheme() {
  final baseTextTheme = GoogleFonts.cinzelDecorativeTextTheme();
  final bodyTextTheme = GoogleFonts.spectralTextTheme();

  return AppTheme(
    type: ThemeType.steampunk,
    isDark: true,

    // Primary colors - aged brass and gold
    primaryColor: const Color(0xFFD4AF37), // Old gold
    primaryVariant: const Color(0xFFAA8C2C), // Antique brass
    onPrimary: const Color(0xFF1A1410),

    // Secondary colors - copper highlights
    accentColor: const Color(0xFFB87333), // Copper
    onAccent: Colors.white,

    // Background colors - dark mahogany and iron
    background: const Color(0xFF0D0B09), // Deep dark brown-black
    surface: const Color(0xFF1A1612), // Dark wood tone
    surfaceVariant: const Color(0xFF252019), // Lighter wood

    // Text colors - parchment and brass
    textPrimary: const Color(0xFFF5E6C8), // Parchment
    textSecondary: const Color(0xFFCDB891), // Aged paper
    textDisabled: const Color(0xFF6B5D4D), // Faded ink

    // UI colors
    divider: const Color(0xFF3D352B),
    toolbarColor: const Color(0xFF1A1612),
    error: const Color(0xFFB22222), // Firebrick
    success: const Color(0xFF8B9A46), // Olive brass
    warning: const Color(0xFFCD853F), // Peru (warm warning)

    // Grid colors
    gridLine: const Color(0xFF2A241D),
    gridBackground: const Color(0xFF1A1612),

    // Canvas colors
    canvasBackground: const Color(0xFF0D0B09),
    selectionOutline: const Color(0xFFD4AF37),
    selectionFill: const Color(0x30D4AF37),

    // Icon colors
    activeIcon: const Color(0xFFD4AF37),
    inactiveIcon: const Color(0xFFCDB891),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFF5E6C8),
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFF5E6C8),
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFF5E6C8),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFF5E6C8),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF5E6C8),
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFCDB891),
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFFD4AF37),
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

// ============================================================================
// STEAMPUNK ANIMATED BACKGROUND
// ============================================================================

class SteampunkBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const SteampunkBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Slow rotation for massive background gears
    final slowController = useAnimationController(
      duration: const Duration(seconds: 60),
    );

    // Medium speed for mid-layer mechanisms
    final mediumController = useAnimationController(
      duration: const Duration(seconds: 20),
    );

    // Fast animation for particles and steam
    final fastController = useAnimationController(
      duration: const Duration(seconds: 8),
    );

    useEffect(() {
      if (enableAnimation) {
        slowController.repeat();
        mediumController.repeat();
        fastController.repeat();
      } else {
        slowController.stop();
        mediumController.stop();
        fastController.stop();
      }
      return null;
    }, [enableAnimation]);

    final slowAnim = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(slowController),
    );
    final mediumAnim = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(mediumController),
    );
    final fastAnim = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(fastController),
    );

    return RepaintBoundary(
      child: CustomPaint(
        painter: _SteampunkPainter(
          slowAnimation: slowAnim,
          mediumAnimation: mediumAnim,
          fastAnimation: fastAnim,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          backgroundColor: theme.background,
          surfaceColor: theme.surface,
          intensity: intensity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SteampunkPainter extends CustomPainter {
  final double slowAnimation;
  final double mediumAnimation;
  final double fastAnimation;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final double intensity;

  // Color constants
  static const Color _brass = Color(0xFFD4AF37);
  static const Color _copper = Color(0xFFB87333);
  static const Color _bronze = Color(0xFFCD7F32);
  static const Color _iron = Color(0xFF3D3D3D);
  static const Color _steam = Color(0xFFE8E4D9);
  static const Color _rust = Color(0xFF8B4513);
  static const Color _verdigris = Color(0xFF40826D);
  static const Color _fireGlow = Color(0xFFFF6B35);
  static const Color _parchment = Color(0xFFF5E6C8);

  final math.Random _rng = math.Random(42);

  _SteampunkPainter({
    required this.slowAnimation,
    required this.mediumAnimation,
    required this.fastAnimation,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _rng = math.Random(42); // Reset for consistent positioning

    // === LAYER 1: Deep industrial background ===
    _paintBackground(canvas, size);

    // === LAYER 2: Distant factory silhouettes ===
    _paintFactorySilhouettes(canvas, size);

    // === LAYER 3: Massive background gears ===
    _paintBackgroundGears(canvas, size);

    // === LAYER 4: Pipe network ===
    _paintPipeNetwork(canvas, size);

    // === LAYER 5: Mid-layer clockwork ===
    _paintClockwork(canvas, size);

    // === LAYER 6: Interlocking gear systems ===
    _paintGearSystems(canvas, size);

    // === LAYER 7: Pressure vessels and boilers ===
    _paintBoilers(canvas, size);

    // === LAYER 8: Gauges and dials ===
    _paintGauges(canvas, size);

    // === LAYER 9: Chain drives ===
    _paintChainDrives(canvas, size);

    // === LAYER 10: Steam and smoke ===
    _paintSteamEffects(canvas, size);

    // === LAYER 11: Sparks and embers ===
    _paintSparks(canvas, size);

    // === LAYER 12: Floating debris ===
    _paintFloatingDebris(canvas, size);

    // === LAYER 13: Light rays and atmosphere ===
    _paintAtmosphere(canvas, size);

    // === LAYER 14: Vignette ===
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Rich radial gradient with warm industrial tones
    final center = Offset(size.width * 0.3, size.height * 0.2);

    final bgGradient = ui.Gradient.radial(
      center,
      size.longestSide,
      [
        const Color(0xFF1A1510), // Warm dark center
        const Color(0xFF0F0D0A), // Rich black-brown
        const Color(0xFF080604), // Deep shadow
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = bgGradient,
    );

    // Subtle grain texture
    final grainPaint = Paint()..color = _parchment.withOpacity(0.008 * intensity);
    for (int i = 0; i < (300 * intensity).round(); i++) {
      canvas.drawCircle(
        Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        _rng.nextDouble() * 1.5,
        grainPaint,
      );
    }
  }

  void _paintFactorySilhouettes(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0A0908).withOpacity(0.6 * intensity);

    // Factory 1 - left side
    final factory1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.05, size.height * 0.65)
      ..lineTo(size.width * 0.05, size.height * 0.4) // Smokestack
      ..lineTo(size.width * 0.08, size.height * 0.4)
      ..lineTo(size.width * 0.08, size.height * 0.6)
      ..lineTo(size.width * 0.15, size.height * 0.55)
      ..lineTo(size.width * 0.15, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.75)
      ..lineTo(size.width * 0.2, size.height)
      ..close();

    canvas.drawPath(factory1, paint);

    // Factory 2 - right side
    final factory2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width * 0.92, size.height * 0.55)
      ..lineTo(size.width * 0.92, size.height * 0.3) // Tall smokestack
      ..lineTo(size.width * 0.88, size.height * 0.3)
      ..lineTo(size.width * 0.88, size.height * 0.5)
      ..lineTo(size.width * 0.82, size.height * 0.45)
      ..lineTo(size.width * 0.82, size.height * 0.65)
      ..lineTo(size.width * 0.75, size.height * 0.7)
      ..lineTo(size.width * 0.75, size.height)
      ..close();

    canvas.drawPath(factory2, paint);
  }

  void _paintBackgroundGears(Canvas canvas, Size size) {
    final gears = [
      _GearDef(0.0, 0.3, 180, 36, 1.0),
      _GearDef(1.0, 0.2, 150, 30, -0.7),
      _GearDef(0.5, 0.0, 200, 40, 0.5),
      _GearDef(0.2, 1.0, 160, 32, -0.8),
      _GearDef(0.85, 0.9, 140, 28, 0.6),
    ];

    for (final gear in gears) {
      final center = Offset(
        size.width * gear.x,
        size.height * gear.y,
      );
      final rotation = slowAnimation * 2 * math.pi * gear.speed;
      final opacity = 0.03 * intensity;

      _drawMassiveGear(
        canvas,
        center,
        gear.radius * intensity,
        gear.teeth,
        rotation,
        _brass.withOpacity(opacity),
      );
    }
  }

  void _drawMassiveGear(
    Canvas canvas,
    Offset center,
    double radius,
    int teeth,
    double rotation,
    Color color,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * intensity
      ..color = color;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Outer ring with teeth
    final toothDepth = radius * 0.12;
    final toothPath = Path();

    for (int i = 0; i < teeth; i++) {
      final angle = i * 2 * math.pi / teeth;
      final nextAngle = (i + 1) * 2 * math.pi / teeth;
      final midAngle = (angle + nextAngle) / 2;

      final innerStart = Offset(
        math.cos(angle) * (radius - toothDepth),
        math.sin(angle) * (radius - toothDepth),
      );
      final outerStart = Offset(
        math.cos(angle + 0.03) * radius,
        math.sin(angle + 0.03) * radius,
      );
      final peak = Offset(
        math.cos(midAngle) * (radius + toothDepth),
        math.sin(midAngle) * (radius + toothDepth),
      );
      final outerEnd = Offset(
        math.cos(nextAngle - 0.03) * radius,
        math.sin(nextAngle - 0.03) * radius,
      );
      final innerEnd = Offset(
        math.cos(nextAngle) * (radius - toothDepth),
        math.sin(nextAngle) * (radius - toothDepth),
      );

      if (i == 0) toothPath.moveTo(innerStart.dx, innerStart.dy);
      toothPath.lineTo(outerStart.dx, outerStart.dy);
      toothPath.lineTo(peak.dx, peak.dy);
      toothPath.lineTo(outerEnd.dx, outerEnd.dy);
      toothPath.lineTo(innerEnd.dx, innerEnd.dy);
    }
    toothPath.close();
    canvas.drawPath(toothPath, paint);

    // Inner rings
    canvas.drawCircle(Offset.zero, radius * 0.75, paint);
    canvas.drawCircle(Offset.zero, radius * 0.5, paint);
    canvas.drawCircle(Offset.zero, radius * 0.2, paint);

    // Spokes with decorative cutouts
    paint.strokeWidth = 3 * intensity;
    for (int i = 0; i < 8; i++) {
      final spokeAngle = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(spokeAngle) * radius * 0.25, math.sin(spokeAngle) * radius * 0.25),
        Offset(math.cos(spokeAngle) * radius * 0.7, math.sin(spokeAngle) * radius * 0.7),
        paint,
      );

      // Decorative holes
      final holeAngle = spokeAngle + math.pi / 8;
      final holeCenter = Offset(
        math.cos(holeAngle) * radius * 0.6,
        math.sin(holeAngle) * radius * 0.6,
      );
      canvas.drawCircle(holeCenter, radius * 0.08, paint);
    }

    canvas.restore();
  }

  void _paintPipeNetwork(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pipes = [
      // Horizontal pipes
      [Offset(0, size.height * 0.35), Offset(size.width * 0.4, size.height * 0.35)],
      [Offset(size.width * 0.6, size.height * 0.25), Offset(size.width, size.height * 0.25)],
      // Vertical pipes
      [Offset(size.width * 0.4, size.height * 0.35), Offset(size.width * 0.4, size.height * 0.8)],
      [Offset(size.width * 0.6, size.height * 0.25), Offset(size.width * 0.6, size.height * 0.6)],
      // Diagonal pipes
      [Offset(size.width * 0.4, size.height * 0.8), Offset(size.width * 0.6, size.height * 0.6)],
    ];

    for (int i = 0; i < pipes.length; i++) {
      final pipe = pipes[i];
      final pulseOpacity = 0.08 + math.sin(mediumAnimation * 2 * math.pi + i) * 0.02;

      // Pipe shadow
      paint.strokeWidth = 14 * intensity;
      paint.color = Colors.black.withOpacity(0.2 * intensity);
      canvas.drawLine(pipe[0] + const Offset(3, 3), pipe[1] + const Offset(3, 3), paint);

      // Main pipe body
      paint.strokeWidth = 12 * intensity;
      paint.color = _iron.withOpacity(pulseOpacity * intensity);
      canvas.drawLine(pipe[0], pipe[1], paint);

      // Pipe highlight
      paint.strokeWidth = 3 * intensity;
      paint.color = _brass.withOpacity(pulseOpacity * 0.3 * intensity);
      canvas.drawLine(
        pipe[0] + const Offset(-2, -2),
        pipe[1] + const Offset(-2, -2),
        paint,
      );

      // Pipe joints
      _drawPipeJoint(canvas, pipe[0], pulseOpacity);
      _drawPipeJoint(canvas, pipe[1], pulseOpacity);
    }
  }

  void _drawPipeJoint(Canvas canvas, Offset center, double opacity) {
    final paint = Paint()..color = _brass.withOpacity(opacity * 0.6 * intensity);

    // Flange
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2 * intensity;
    canvas.drawCircle(center, 16 * intensity, paint);

    // Bolts
    paint.style = PaintingStyle.fill;
    paint.color = _brass.withOpacity(opacity * 0.4 * intensity);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final boltPos = center +
          Offset(
            math.cos(angle) * 12 * intensity,
            math.sin(angle) * 12 * intensity,
          );
      canvas.drawCircle(boltPos, 2 * intensity, paint);
    }
  }

  void _paintClockwork(Canvas canvas, Size size) {
    final clocks = [
      Offset(size.width * 0.25, size.height * 0.45),
      Offset(size.width * 0.7, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.75),
    ];

    for (int i = 0; i < clocks.length; i++) {
      final center = clocks[i];
      final radius = (35 + i * 8) * intensity;
      final rotation = mediumAnimation * 2 * math.pi * (i % 2 == 0 ? 1 : -0.7);
      final opacity = 0.08 + math.sin(mediumAnimation * 3 * math.pi + i * 1.2) * 0.02;

      _drawClockFace(canvas, center, radius, rotation, opacity);
    }
  }

  void _drawClockFace(Canvas canvas, Offset center, double radius, double rotation, double opacity) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * intensity
      ..color = _brass.withOpacity(opacity * intensity);

    // Outer decorative ring
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.92, paint);

    // Ornate border pattern
    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final isHour = i % 2 == 0;
      final length = isHour ? radius * 0.12 : radius * 0.06;

      canvas.drawLine(
        center +
            Offset(
              math.cos(angle) * (radius * 0.78),
              math.sin(angle) * (radius * 0.78),
            ),
        center +
            Offset(
              math.cos(angle) * (radius * 0.78 + length),
              math.sin(angle) * (radius * 0.78 + length),
            ),
        paint,
      );
    }

    // Roman numeral positions (simplified as decorative marks)
    paint.strokeWidth = 3 * intensity;
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final markPos = center +
          Offset(
            math.cos(angle) * radius * 0.65,
            math.sin(angle) * radius * 0.65,
          );

      if (i % 3 == 0) {
        // Major hour marks
        canvas.drawCircle(markPos, 3 * intensity, paint);
      }
    }

    // Clock hands
    paint.strokeWidth = 2.5 * intensity;

    // Hour hand
    final hourAngle = rotation * 0.08 - math.pi / 2;
    canvas.drawLine(
      center,
      center +
          Offset(
            math.cos(hourAngle) * radius * 0.35,
            math.sin(hourAngle) * radius * 0.35,
          ),
      paint,
    );

    // Minute hand
    final minuteAngle = rotation - math.pi / 2;
    paint.strokeWidth = 1.5 * intensity;
    canvas.drawLine(
      center,
      center +
          Offset(
            math.cos(minuteAngle) * radius * 0.55,
            math.sin(minuteAngle) * radius * 0.55,
          ),
      paint,
    );

    // Second hand (fast)
    final secondAngle = fastAnimation * 2 * math.pi - math.pi / 2;
    paint.strokeWidth = 1 * intensity;
    paint.color = _copper.withOpacity(opacity * intensity);
    canvas.drawLine(
      center,
      center +
          Offset(
            math.cos(secondAngle) * radius * 0.5,
            math.sin(secondAngle) * radius * 0.5,
          ),
      paint,
    );

    // Center hub
    final hubPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _brass.withOpacity(opacity * 0.6 * intensity);
    canvas.drawCircle(center, 5 * intensity, hubPaint);
  }

  void _paintGearSystems(Canvas canvas, Size size) {
    // Gear cluster configurations
    final clusters = [
      // Top-left cluster
      [
        _GearDef(0.15, 0.2, 40, 12, 1.0),
        _GearDef(0.22, 0.13, 28, 8, -1.43),
        _GearDef(0.08, 0.26, 22, 7, 1.82),
      ],
      // Right cluster
      [
        _GearDef(0.85, 0.45, 45, 14, -0.8),
        _GearDef(0.92, 0.38, 30, 9, 1.2),
        _GearDef(0.78, 0.52, 25, 8, -1.44),
      ],
      // Bottom cluster
      [
        _GearDef(0.35, 0.85, 35, 10, 1.0),
        _GearDef(0.28, 0.78, 25, 7, -1.4),
        _GearDef(0.42, 0.92, 28, 8, -1.25),
      ],
    ];

    for (final cluster in clusters) {
      for (int i = 0; i < cluster.length; i++) {
        final gear = cluster[i];
        final center = Offset(size.width * gear.x, size.height * gear.y);
        final radius = gear.radius * intensity;
        final rotation = mediumAnimation * 2 * math.pi * gear.speed;

        final breathe = math.sin(mediumAnimation * 4 * math.pi + i * 1.5) * 0.03 + 0.1;
        final color = Color.lerp(_brass, _copper, i / cluster.length)!.withOpacity(breathe * intensity);

        _drawDetailedGear(canvas, center, radius, gear.teeth, rotation, color);
      }
    }
  }

  void _drawDetailedGear(
    Canvas canvas,
    Offset center,
    double radius,
    int teeth,
    double rotation,
    Color color,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * intensity
      ..color = color;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final toothHeight = radius * 0.2;
    final innerRadius = radius * 0.6;
    final hubRadius = radius * 0.2;

    // Gear teeth
    final teethPath = Path();
    for (int i = 0; i < teeth; i++) {
      final angle = i * 2 * math.pi / teeth;
      final midAngle = angle + math.pi / teeth;
      final nextAngle = (i + 1) * 2 * math.pi / teeth;

      final base1 = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final peak = Offset(math.cos(midAngle) * (radius + toothHeight), math.sin(midAngle) * (radius + toothHeight));
      final base2 = Offset(math.cos(nextAngle) * radius, math.sin(nextAngle) * radius);

      if (i == 0) teethPath.moveTo(base1.dx, base1.dy);
      teethPath.lineTo(peak.dx, peak.dy);
      teethPath.lineTo(base2.dx, base2.dy);
    }
    teethPath.close();
    canvas.drawPath(teethPath, paint);

    // Inner ring
    canvas.drawCircle(Offset.zero, innerRadius, paint);

    // Hub
    canvas.drawCircle(Offset.zero, hubRadius, paint);

    // Spokes
    final spokeCount = math.min(teeth ~/ 2, 6);
    for (int i = 0; i < spokeCount; i++) {
      final angle = i * 2 * math.pi / spokeCount;
      canvas.drawLine(
        Offset(math.cos(angle) * hubRadius, math.sin(angle) * hubRadius),
        Offset(math.cos(angle) * innerRadius, math.sin(angle) * innerRadius),
        paint,
      );
    }

    // Center bolt
    final boltPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(color.opacity * 0.5);
    canvas.drawCircle(Offset.zero, hubRadius * 0.5, boltPaint);

    canvas.restore();
  }

  void _paintBoilers(Canvas canvas, Size size) {
    final boilers = [
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.9, size.height * 0.7),
    ];

    for (int i = 0; i < boilers.length; i++) {
      final center = boilers[i];
      final width = 50.0 * intensity;
      final height = 70.0 * intensity;

      final heatGlow = math.sin(fastAnimation * 3 * math.pi + i * 2) * 0.3 + 0.7;
      final opacity = 0.08 * intensity;

      final paint = Paint()..style = PaintingStyle.stroke;

      // Boiler body
      paint.strokeWidth = 3 * intensity;
      paint.color = _iron.withOpacity(opacity);
      final boilerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: width, height: height),
        Radius.circular(width * 0.3),
      );
      canvas.drawRRect(boilerRect, paint);

      // Rivets along edges
      paint.style = PaintingStyle.fill;
      paint.color = _brass.withOpacity(opacity * 0.6);
      for (int r = 0; r < 6; r++) {
        final rivetY = center.dy - height * 0.4 + r * height * 0.16;
        canvas.drawCircle(Offset(center.dx - width * 0.4, rivetY), 2 * intensity, paint);
        canvas.drawCircle(Offset(center.dx + width * 0.4, rivetY), 2 * intensity, paint);
      }

      // Heat glow at bottom
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
        ..color = _fireGlow.withOpacity(0.05 * heatGlow * intensity);
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, height * 0.4),
          width: width * 0.8,
          height: height * 0.3,
        ),
        glowPaint,
      );

      // Pressure release valve on top
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2 * intensity;
      paint.color = _brass.withOpacity(opacity);
      final valveBase = center - Offset(0, height * 0.5);
      canvas.drawLine(valveBase, valveBase - Offset(0, 15 * intensity), paint);
      canvas.drawCircle(valveBase - Offset(0, 20 * intensity), 6 * intensity, paint);
    }
  }

  void _paintGauges(Canvas canvas, Size size) {
    final gauges = [
      Offset(size.width * 0.2, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.15),
      Offset(size.width * 0.8, size.height * 0.08),
      Offset(size.width * 0.15, size.height * 0.9),
      Offset(size.width * 0.85, size.height * 0.85),
    ];

    for (int i = 0; i < gauges.length; i++) {
      final center = gauges[i];
      final radius = (15 + i * 2) * intensity;

      // Pressure varies over time
      final pressure = (math.sin(fastAnimation * 4 * math.pi + i * 1.8) + 1) / 2;
      final opacity = 0.1 + pressure * 0.05;

      _drawPressureGauge(canvas, center, radius, pressure, opacity);
    }
  }

  void _drawPressureGauge(
    Canvas canvas,
    Offset center,
    double radius,
    double pressure,
    double opacity,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * intensity
      ..color = _brass.withOpacity(opacity * intensity);

    // Gauge housing
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.88, paint);

    // Danger zone (red arc)
    final dangerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * intensity
      ..color = _fireGlow.withOpacity(0.15 * intensity);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.7),
      -math.pi * 0.2,
      math.pi * 0.4,
      false,
      dangerPaint,
    );

    // Tick marks
    paint.strokeWidth = 1 * intensity;
    for (int j = 0; j < 11; j++) {
      final angle = -math.pi * 0.75 + j * math.pi * 1.5 / 10;
      final inner = j % 2 == 0 ? radius * 0.7 : radius * 0.75;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * radius * 0.85, math.sin(angle) * radius * 0.85),
        paint,
      );
    }

    // Needle
    final needleAngle = -math.pi * 0.75 + pressure * math.pi * 1.5;
    paint.strokeWidth = 2 * intensity;
    paint.color = Color.lerp(_brass, _fireGlow, pressure)!.withOpacity(opacity * 1.2 * intensity);
    canvas.drawLine(
      center,
      center +
          Offset(
            math.cos(needleAngle) * radius * 0.6,
            math.sin(needleAngle) * radius * 0.6,
          ),
      paint,
    );

    // Center cap
    final capPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _brass.withOpacity(opacity * 0.5 * intensity);
    canvas.drawCircle(center, 3 * intensity, capPaint);
  }

  void _paintChainDrives(Canvas canvas, Size size) {
    final chains = [
      [Offset(size.width * 0.3, size.height * 0.3), Offset(size.width * 0.5, size.height * 0.5)],
      [Offset(size.width * 0.6, size.height * 0.7), Offset(size.width * 0.8, size.height * 0.5)],
    ];

    for (int c = 0; c < chains.length; c++) {
      final start = chains[c][0];
      final end = chains[c][1];

      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      final linkCount = (length / (8 * intensity)).round();

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * intensity;

      final chainOffset = fastAnimation * 20 * intensity;

      for (int i = 0; i < linkCount; i++) {
        final t = ((i + chainOffset / 8) % linkCount) / linkCount;
        final x = start.dx + dx * t;
        final y = start.dy + dy * t;

        final opacity = 0.06 + math.sin(fastAnimation * 6 * math.pi + i * 0.5) * 0.02;
        paint.color = _iron.withOpacity(opacity * intensity);

        // Draw chain link
        final linkRect = Rect.fromCenter(
          center: Offset(x, y),
          width: 6 * intensity,
          height: 4 * intensity,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(linkRect, Radius.circular(2 * intensity)),
          paint,
        );
      }

      // Sprockets at ends
      final sprocketPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * intensity
        ..color = _brass.withOpacity(0.08 * intensity);

      canvas.drawCircle(start, 12 * intensity, sprocketPaint);
      canvas.drawCircle(end, 10 * intensity, sprocketPaint);
    }
  }

  void _paintSteamEffects(Canvas canvas, Size size) {
    final vents = [
      Offset(size.width * 0.05, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.8),
      Offset(size.width * 0.92, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.6),
    ];

    for (int v = 0; v < vents.length; v++) {
      final vent = vents[v];

      for (int p = 0; p < 6; p++) {
        final progress = (fastAnimation + p * 0.15 + v * 0.1) % 1.0;
        final rise = progress * size.height * 0.25;
        final drift = math.sin(progress * math.pi * 3 + v) * 25 * intensity;
        final expand = 10 + progress * 35;

        final steamOpacity = math.max(0.0, (1 - progress * progress) * 0.06 * intensity);

        if (steamOpacity > 0.005) {
          final pos = vent + Offset(drift, -rise);

          final steamPaint = Paint()
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

          // Main puff
          steamPaint.color = _steam.withOpacity(steamOpacity);
          canvas.drawCircle(pos, expand * intensity, steamPaint);

          // Secondary wisps
          steamPaint.color = _steam.withOpacity(steamOpacity * 0.5);
          canvas.drawCircle(pos + Offset(-expand * 0.5, expand * 0.3), expand * 0.6 * intensity, steamPaint);
          canvas.drawCircle(pos + Offset(expand * 0.4, -expand * 0.2), expand * 0.5 * intensity, steamPaint);
        }
      }
    }
  }

  void _paintSparks(Canvas canvas, Size size) {
    final sparkSources = [
      Offset(size.width * 0.1, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.9),
    ];

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int s = 0; s < sparkSources.length; s++) {
      final source = sparkSources[s];

      for (int i = 0; i < 8; i++) {
        final progress = (fastAnimation * 2 + i * 0.1 + s * 0.15) % 1.0;

        // Sparks fly up and out
        final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * math.pi * 0.8;
        final distance = progress * 80 * intensity;
        final gravity = progress * progress * 40 * intensity;

        final x = source.dx + math.cos(angle) * distance;
        final y = source.dy + math.sin(angle) * distance + gravity;

        final sparkOpacity = math.max(0.0, (1 - progress) * 0.5 * intensity);

        if (sparkOpacity > 0.05 && y < size.height) {
          // Core spark
          paint.color = _fireGlow.withOpacity(sparkOpacity);
          canvas.drawCircle(Offset(x, y), 2 * intensity, paint);

          // Hot core
          paint.color = Colors.white.withOpacity(sparkOpacity * 0.5);
          canvas.drawCircle(Offset(x, y), 1 * intensity, paint);
        }
      }
    }
  }

  void _paintFloatingDebris(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final debrisCount = (40 * intensity).round();

    for (int i = 0; i < debrisCount; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;

      final floatX = baseX + math.sin(fastAnimation * 2 * math.pi + i * 0.5) * 15 * intensity;
      final floatY = baseY + math.cos(fastAnimation * 1.5 * math.pi + i * 0.7) * 12 * intensity;

      final twinkle = math.sin(fastAnimation * 5 * math.pi + i * 0.9) * 0.5 + 0.5;

      if (twinkle > 0.25) {
        final particleOpacity = twinkle * 0.2 * intensity;
        paint.color = Color.lerp(_brass, _copper, _rng.nextDouble())!.withOpacity(particleOpacity);

        switch (i % 6) {
          case 0: // Spark
            paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
            canvas.drawCircle(Offset(floatX, floatY), 2.5 * intensity * twinkle, paint);
            paint.maskFilter = null;
            break;

          case 1: // Hex nut
            _drawHexagon(canvas, paint, Offset(floatX, floatY), 3 * intensity * twinkle);
            break;

          case 2: // Gear fragment
            final path = Path()
              ..moveTo(floatX - 3 * intensity, floatY)
              ..lineTo(floatX, floatY - 4 * intensity)
              ..lineTo(floatX + 3 * intensity, floatY)
              ..lineTo(floatX, floatY + 3 * intensity)
              ..close();
            canvas.drawPath(path, paint);
            break;

          case 3: // Rivet head
            canvas.drawCircle(Offset(floatX, floatY), 2 * intensity * twinkle, paint);
            paint.color = paint.color.withOpacity(particleOpacity * 0.4);
            canvas.drawCircle(Offset(floatX, floatY), 1 * intensity * twinkle, paint);
            break;

          case 4: // Screw
            canvas.drawCircle(Offset(floatX, floatY), 2 * intensity * twinkle, paint);
            paint.style = PaintingStyle.stroke;
            paint.strokeWidth = 0.5 * intensity;
            canvas.drawLine(
              Offset(floatX - 1.5 * intensity, floatY),
              Offset(floatX + 1.5 * intensity, floatY),
              paint,
            );
            paint.style = PaintingStyle.fill;
            break;

          case 5: // Metal shard
            final shardPath = Path()
              ..moveTo(floatX, floatY - 4 * intensity)
              ..lineTo(floatX + 2 * intensity, floatY + 3 * intensity)
              ..lineTo(floatX - 1.5 * intensity, floatY + 1.5 * intensity)
              ..close();
            canvas.drawPath(shardPath, paint);
            break;
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintAtmosphere(Canvas canvas, Size size) {
    // Warm light from upper left (like gas lamps)
    final warmLight = ui.Gradient.radial(
      Offset(size.width * 0.15, size.height * 0.1),
      size.longestSide * 0.7,
      [
        _brass.withOpacity(0.04 * intensity),
        Colors.transparent,
      ],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = warmLight,
    );

    // Fire glow from bottom (furnace/boiler light)
    final fireGlow = ui.Gradient.linear(
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.5, size.height * 0.6),
      [
        _fireGlow.withOpacity(0.03 * intensity),
        Colors.transparent,
      ],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = fireGlow,
    );

    // Subtle dust in light beams
    final dustPaint = Paint()
      ..color = _parchment.withOpacity(0.015 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    final beamPath = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.2, size.height * 0.6)
      ..close();

    canvas.drawPath(beamPath, dustPaint);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.85;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.25 * intensity),
        Colors.black.withOpacity(0.5 * intensity),
      ],
      [0.4, 0.75, 1.0],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette,
    );
  }

  @override
  bool shouldRepaint(covariant _SteampunkPainter oldDelegate) {
    return oldDelegate.slowAnimation != slowAnimation ||
        oldDelegate.mediumAnimation != mediumAnimation ||
        oldDelegate.fastAnimation != fastAnimation ||
        oldDelegate.intensity != intensity;
  }

  set _rng(math.Random value) {} // Dart workaround for resetting
}

// ============================================================================
// HELPER CLASS
// ============================================================================

class _GearDef {
  final double x;
  final double y;
  final double radius;
  final int teeth;
  final double speed;

  const _GearDef(this.x, this.y, this.radius, this.teeth, this.speed);
}
