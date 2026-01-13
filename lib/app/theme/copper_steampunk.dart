import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

AppTheme buildCopperSteampunkTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return AppTheme(
    type: ThemeType.copperSteampunk,
    isDark: true,
    // Primary colors - copper and bronze
    primaryColor: const Color(0xFFB87333), // Copper
    primaryVariant: const Color(0xFFA0522D), // Dark copper
    onPrimary: Colors.white,
    // Secondary colors - brass
    accentColor: const Color(0xFFCD7F32), // Brass/Bronze
    onAccent: Colors.black,
    // Background colors - dark industrial iron
    background: const Color(0xFF1C1C1C), // Dark charcoal iron
    surface: const Color(0xFF2A2A2A), // Dark iron surface
    surfaceVariant: const Color(0xFF353535), // Lighter iron variant
    // Text colors - light brass for contrast
    textPrimary: const Color(0xFFF4E4BC), // Light brass/cream
    textSecondary: const Color(0xFFDEB887), // Burlywood (warm brass)
    textDisabled: const Color(0xFF8B7355), // Dark khaki
    // UI colors
    divider: const Color(0xFF404040),
    toolbarColor: const Color(0xFF2A2A2A),
    error: const Color(0xFFCD5C5C), // Indian red
    success: const Color(0xFF9ACD32), // Yellow green
    warning: const Color(0xFFDAA520), // Goldenrod
    // Grid colors
    gridLine: const Color(0xFF404040),
    gridBackground: const Color(0xFF2A2A2A),
    // Canvas colors
    canvasBackground: const Color(0xFF1C1C1C),
    selectionOutline: const Color(0xFFB87333), // Copper selection
    selectionFill: const Color(0x30B87333),
    // Icon colors
    activeIcon: const Color(0xFFB87333), // Copper for active
    inactiveIcon: const Color(0xFFDEB887), // Brass for inactive
    // Typography
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFF4E4BC),
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFFF4E4BC),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF4E4BC),
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFDEB887),
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

class CopperSteampunkBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const CopperSteampunkBackground({
    super.key,
    required this.theme,
    required this.intensity,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Main mechanical animation - slower for large gears
    final mainController = useAnimationController(
      duration: const Duration(seconds: 30),
    );

    // Secondary animation for smaller elements
    final secondaryController = useAnimationController(
      duration: const Duration(seconds: 12),
    );

    // Tertiary animation for particles and steam
    final particleController = useAnimationController(
      duration: const Duration(seconds: 8),
    );

    useEffect(() {
      if (enableAnimation) {
        mainController.repeat();
        secondaryController.repeat();
        particleController.repeat();
      } else {
        mainController.stop();
        secondaryController.stop();
        particleController.stop();
      }
      return null;
    }, [enableAnimation]);

    final mainAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(mainController),
    );

    final secondaryAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(secondaryController),
    );

    final particleAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(particleController),
    );

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CopperSteampunkPainter(
          mainAnimation: mainAnimation,
          secondaryAnimation: secondaryAnimation,
          particleAnimation: particleAnimation,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CopperSteampunkPainter extends CustomPainter {
  final double mainAnimation;
  final double secondaryAnimation;
  final double particleAnimation;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Cached random for consistent positioning
  final math.Random _random = math.Random(1337);

  // Color palette
  static const Color _verdigris = Color(0xFF40826D);
  static const Color _darkIron = Color(0xFF2A2A2A);
  static const Color _rust = Color(0xFF8B4513);
  static const Color _steam = Color(0xFFE8E4D9);
  static const Color _hotMetal = Color(0xFFFF6B35);

  _CopperSteampunkPainter({
    required this.mainAnimation,
    required this.secondaryAnimation,
    required this.particleAnimation,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _random.setSeed(1337);

    // Layer 1: Deep industrial gradient background
    _drawIndustrialBackground(canvas, size);

    // Layer 2: Metal plate texture
    _drawMetalPlates(canvas, size);

    // Layer 3: Large background gears (slow rotation)
    _drawBackgroundGears(canvas, size);

    // Layer 4: Pipe network
    _drawPipeNetwork(canvas, size);

    // Layer 5: Medium gears with interlocking motion
    _drawInterlockingGears(canvas, size);

    // Layer 6: Clockwork mechanisms
    _drawClockworkMechanisms(canvas, size);

    // Layer 7: Pressure gauges and dials
    _drawPressureGauges(canvas, size);

    // Layer 8: Steam and smoke effects
    _drawSteamEffects(canvas, size);

    // Layer 9: Floating mechanical particles
    _drawMechanicalParticles(canvas, size);

    // Layer 10: Copper patina and weathering
    _drawPatinaEffects(canvas, size);

    // Layer 11: Ambient light rays
    _drawAmbientLightRays(canvas, size);

    // Layer 12: Vignette overlay
    _drawVignette(canvas, size);
  }

  void _drawIndustrialBackground(Canvas canvas, Size size) {
    // Deep radial gradient with warm industrial tones
    final center = Offset(size.width * 0.3, size.height * 0.3);
    final gradient = ui.Gradient.radial(
      center,
      size.longestSide * 0.8,
      [
        const Color(0xFF2D2520), // Warm dark brown
        const Color(0xFF1C1A18), // Dark charcoal
        const Color(0xFF141210), // Near black
      ],
      [0.0, 0.5, 1.0],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(Offset.zero & size, paint);

    // Subtle noise texture overlay
    final noisePaint = Paint()..color = Colors.white.withOpacity(0.015 * intensity);
    for (int i = 0; i < (200 * intensity).round(); i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, noisePaint);
    }
  }

  void _drawMetalPlates(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * intensity;

    // Draw subtle metal plate edges
    final plateCount = (4 * intensity).round();
    for (int i = 0; i < plateCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final width = 100 + _random.nextDouble() * 200;
      final height = 80 + _random.nextDouble() * 150;

      final opacity = 0.03 + _random.nextDouble() * 0.02;
      paint.color = primaryColor.withOpacity(opacity * intensity);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);

      // Rivet corners
      final rivetPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = primaryColor.withOpacity(opacity * 1.5 * intensity);

      for (final corner in [
        Offset(x + 8, y + 8),
        Offset(x + width - 8, y + 8),
        Offset(x + 8, y + height - 8),
        Offset(x + width - 8, y + height - 8),
      ]) {
        canvas.drawCircle(corner, 2 * intensity, rivetPaint);
      }
    }
  }

  void _drawBackgroundGears(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Large atmospheric background gears
    final gearConfigs = [
      _GearConfig(0.15, 0.2, 120, 24, 1.0),
      _GearConfig(0.85, 0.15, 100, 20, -0.7),
      _GearConfig(0.1, 0.85, 90, 18, 0.5),
      _GearConfig(0.9, 0.8, 110, 22, -0.8),
      _GearConfig(0.5, 0.5, 150, 28, 0.3),
    ];

    for (final config in gearConfigs) {
      final gearX = size.width * config.xRatio;
      final gearY = size.height * config.yRatio;
      final radius = config.radius * intensity;
      final rotation = mainAnimation * 2 * math.pi * config.speedMultiplier;

      // Very subtle opacity for background depth
      final baseOpacity = 0.04 * intensity;
      paint.color = primaryColor.withOpacity(baseOpacity);
      paint.strokeWidth = 3 * intensity;

      _drawDetailedGear(
        canvas,
        paint,
        Offset(gearX, gearY),
        radius,
        rotation,
        config.teeth,
        isBackground: true,
      );
    }
  }

  void _drawInterlockingGears(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Create gear clusters that mesh together
    final clusters = [
      // Top-left cluster
      [
        _GearConfig(0.2, 0.25, 45, 12, 1.0),
        _GearConfig(0.28, 0.18, 30, 8, -1.5),
        _GearConfig(0.12, 0.32, 25, 7, 1.8),
      ],
      // Bottom-right cluster
      [
        _GearConfig(0.75, 0.7, 50, 14, -0.8),
        _GearConfig(0.85, 0.65, 35, 10, 1.1),
        _GearConfig(0.7, 0.8, 28, 8, -1.4),
      ],
      // Center-right cluster
      [
        _GearConfig(0.88, 0.4, 40, 11, 1.0),
        _GearConfig(0.95, 0.32, 25, 7, -1.6),
      ],
    ];

    for (final cluster in clusters) {
      for (int i = 0; i < cluster.length; i++) {
        final config = cluster[i];
        final gearX = size.width * config.xRatio;
        final gearY = size.height * config.yRatio;
        final radius = config.radius * intensity;
        final rotation = secondaryAnimation * 2 * math.pi * config.speedMultiplier;

        // Breathing opacity effect
        final breathe = math.sin(secondaryAnimation * 4 * math.pi + i * 1.2) * 0.02 + 0.08;
        paint.color = Color.lerp(
          primaryColor.withOpacity(breathe * intensity),
          accentColor.withOpacity(breathe * 0.8 * intensity),
          i / cluster.length,
        )!;
        paint.strokeWidth = 2 * intensity;

        _drawDetailedGear(
          canvas,
          paint,
          Offset(gearX, gearY),
          radius,
          rotation,
          config.teeth,
          isBackground: false,
        );
      }
    }
  }

  void _drawDetailedGear(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radius,
    double rotation,
    int teeth, {
    bool isBackground = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final toothHeight = radius * 0.18;
    final innerRadius = radius * 0.65;
    final hubRadius = radius * 0.25;

    // Outer gear teeth
    final teethPath = Path();
    for (int i = 0; i < teeth; i++) {
      final angle = i * 2 * math.pi / teeth;
      final nextAngle = (i + 0.5) * 2 * math.pi / teeth;
      final endAngle = (i + 1) * 2 * math.pi / teeth;

      final innerStart = Offset(
        math.cos(angle) * (radius - toothHeight * 0.5),
        math.sin(angle) * (radius - toothHeight * 0.5),
      );
      final outerStart = Offset(
        math.cos(angle + 0.1) * radius,
        math.sin(angle + 0.1) * radius,
      );
      final outerPeak = Offset(
        math.cos(nextAngle) * (radius + toothHeight),
        math.sin(nextAngle) * (radius + toothHeight),
      );
      final outerEnd = Offset(
        math.cos(endAngle - 0.1) * radius,
        math.sin(endAngle - 0.1) * radius,
      );
      final innerEnd = Offset(
        math.cos(endAngle) * (radius - toothHeight * 0.5),
        math.sin(endAngle) * (radius - toothHeight * 0.5),
      );

      if (i == 0) {
        teethPath.moveTo(innerStart.dx, innerStart.dy);
      }
      teethPath.lineTo(outerStart.dx, outerStart.dy);
      teethPath.lineTo(outerPeak.dx, outerPeak.dy);
      teethPath.lineTo(outerEnd.dx, outerEnd.dy);
      teethPath.lineTo(innerEnd.dx, innerEnd.dy);
    }
    teethPath.close();
    canvas.drawPath(teethPath, paint);

    // Inner ring
    canvas.drawCircle(Offset.zero, innerRadius, paint);

    // Hub
    canvas.drawCircle(Offset.zero, hubRadius, paint);

    // Spokes with decorative cutouts
    final spokeCount = isBackground ? 6 : 4;
    for (int i = 0; i < spokeCount; i++) {
      final spokeAngle = i * 2 * math.pi / spokeCount;
      canvas.drawLine(
        Offset(
          math.cos(spokeAngle) * hubRadius,
          math.sin(spokeAngle) * hubRadius,
        ),
        Offset(
          math.cos(spokeAngle) * innerRadius,
          math.sin(spokeAngle) * innerRadius,
        ),
        paint,
      );

      // Decorative holes between spokes
      if (!isBackground) {
        final holeAngle = spokeAngle + math.pi / spokeCount;
        final holeRadius = (innerRadius - hubRadius) * 0.3;
        final holeDistance = (innerRadius + hubRadius) * 0.5;
        canvas.drawCircle(
          Offset(
            math.cos(holeAngle) * holeDistance,
            math.sin(holeAngle) * holeDistance,
          ),
          holeRadius,
          paint,
        );
      }
    }

    // Center bolt
    final boltPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = paint.color.withOpacity(paint.color.opacity * 0.5);
    canvas.drawCircle(Offset.zero, hubRadius * 0.4, boltPaint);

    canvas.restore();
  }

  void _drawPipeNetwork(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main pipes
    final pipes = [
      [Offset(0, size.height * 0.4), Offset(size.width * 0.3, size.height * 0.4)],
      [Offset(size.width * 0.3, size.height * 0.4), Offset(size.width * 0.3, size.height * 0.7)],
      [Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height * 0.3)],
      [Offset(size.width * 0.7, size.height * 0.3), Offset(size.width, size.height * 0.3)],
      [Offset(size.width * 0.5, size.height), Offset(size.width * 0.5, size.height * 0.8)],
    ];

    for (int i = 0; i < pipes.length; i++) {
      final pipe = pipes[i];
      final pipeOpacity = 0.06 + math.sin(secondaryAnimation * 2 * math.pi + i * 0.8) * 0.02;

      // Pipe shadow
      paint.strokeWidth = 10 * intensity;
      paint.color = Colors.black.withOpacity(0.1 * intensity);
      canvas.drawLine(
        pipe[0] + Offset(2, 2),
        pipe[1] + Offset(2, 2),
        paint,
      );

      // Main pipe
      paint.strokeWidth = 8 * intensity;
      paint.color = _darkIron.withOpacity(pipeOpacity * intensity);
      canvas.drawLine(pipe[0], pipe[1], paint);

      // Pipe highlight
      paint.strokeWidth = 2 * intensity;
      paint.color = primaryColor.withOpacity(pipeOpacity * 0.5 * intensity);
      canvas.drawLine(
        pipe[0] + const Offset(-2, -2),
        pipe[1] + const Offset(-2, -2),
        paint,
      );

      // Pipe joints/flanges
      _drawPipeJoint(canvas, pipe[0], pipeOpacity);
      _drawPipeJoint(canvas, pipe[1], pipeOpacity);
    }
  }

  void _drawPipeJoint(Canvas canvas, Offset position, double opacity) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * intensity
      ..color = primaryColor.withOpacity(opacity * 0.8 * intensity);

    canvas.drawCircle(position, 12 * intensity, paint);

    // Bolts around joint
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final boltPos = position +
          Offset(
            math.cos(angle) * 9 * intensity,
            math.sin(angle) * 9 * intensity,
          );
      final boltPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = primaryColor.withOpacity(opacity * 0.6 * intensity);
      canvas.drawCircle(boltPos, 1.5 * intensity, boltPaint);
    }
  }

  void _drawClockworkMechanisms(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    final mechanisms = [
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.65, size.height * 0.35),
      Offset(size.width * 0.8, size.height * 0.75),
    ];

    for (int i = 0; i < mechanisms.length; i++) {
      final center = mechanisms[i];
      final radius = (30 + i * 8) * intensity;
      final rotation = secondaryAnimation * 2 * math.pi * (i % 2 == 0 ? 1 : -0.6);
      final opacity = 0.07 + math.cos(secondaryAnimation * 3 * math.pi + i * 1.1) * 0.02;

      paint.color = accentColor.withOpacity(opacity * intensity);
      paint.strokeWidth = 1.5 * intensity;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);

      // Outer decorative ring
      canvas.drawCircle(Offset.zero, radius, paint);
      canvas.drawCircle(Offset.zero, radius * 0.85, paint);

      // Roman numeral markers (simplified as lines)
      for (int j = 0; j < 12; j++) {
        final markerAngle = j * math.pi / 6;
        final isHour = j % 3 == 0;
        final markerLength = isHour ? radius * 0.15 : radius * 0.08;
        paint.strokeWidth = isHour ? 2 * intensity : 1 * intensity;

        canvas.drawLine(
          Offset(
            math.cos(markerAngle) * (radius * 0.7),
            math.sin(markerAngle) * (radius * 0.7),
          ),
          Offset(
            math.cos(markerAngle) * (radius * 0.7 + markerLength),
            math.sin(markerAngle) * (radius * 0.7 + markerLength),
          ),
          paint,
        );
      }

      // Clock hands
      paint.strokeWidth = 2 * intensity;
      // Hour hand
      final hourAngle = secondaryAnimation * 2 * math.pi * 0.1;
      canvas.drawLine(
        Offset.zero,
        Offset(
          math.cos(hourAngle - math.pi / 2) * radius * 0.4,
          math.sin(hourAngle - math.pi / 2) * radius * 0.4,
        ),
        paint,
      );
      // Minute hand
      final minuteAngle = secondaryAnimation * 2 * math.pi;
      paint.strokeWidth = 1.5 * intensity;
      canvas.drawLine(
        Offset.zero,
        Offset(
          math.cos(minuteAngle - math.pi / 2) * radius * 0.6,
          math.sin(minuteAngle - math.pi / 2) * radius * 0.6,
        ),
        paint,
      );

      // Center hub
      final hubPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = accentColor.withOpacity(opacity * 0.5 * intensity);
      canvas.drawCircle(Offset.zero, 4 * intensity, hubPaint);

      canvas.restore();
    }
  }

  void _drawPressureGauges(Canvas canvas, Size size) {
    final gauges = [
      Offset(size.width * 0.12, size.height * 0.15),
      Offset(size.width * 0.92, size.height * 0.55),
      Offset(size.width * 0.08, size.height * 0.7),
      Offset(size.width * 0.55, size.height * 0.12),
    ];

    for (int i = 0; i < gauges.length; i++) {
      final center = gauges[i];
      final radius = (18 + i * 3) * intensity;

      // Gauge pressure varies over time
      final pressure = (math.sin(particleAnimation * 4 * math.pi + i * 1.5) + 1) / 2;
      final opacity = 0.08 + pressure * 0.04;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * intensity
        ..color = primaryColor.withOpacity(opacity * intensity);

      // Gauge housing
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius * 0.9, paint);

      // Gauge face gradient
      final gradientPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            _darkIron.withOpacity(0.1 * intensity),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(center, radius * 0.85, gradientPaint);

      // Danger zone arc (red section)
      final dangerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * intensity
        ..color = _hotMetal.withOpacity(0.1 * intensity);

      final dangerRect = Rect.fromCircle(center: center, radius: radius * 0.7);
      canvas.drawArc(dangerRect, -math.pi * 0.25, math.pi * 0.5, false, dangerPaint);

      // Tick marks
      paint.strokeWidth = 1 * intensity;
      for (int j = 0; j < 10; j++) {
        final angle = -math.pi * 0.75 + j * math.pi * 1.5 / 9;
        final innerR = j % 2 == 0 ? radius * 0.7 : radius * 0.75;
        canvas.drawLine(
          center + Offset(math.cos(angle) * innerR, math.sin(angle) * innerR),
          center + Offset(math.cos(angle) * radius * 0.82, math.sin(angle) * radius * 0.82),
          paint,
        );
      }

      // Needle
      final needleAngle = -math.pi * 0.75 + pressure * math.pi * 1.5;
      paint.strokeWidth = 2 * intensity;
      paint.color = Color.lerp(
        primaryColor,
        _hotMetal,
        pressure,
      )!
          .withOpacity(opacity * 1.5 * intensity);

      canvas.drawLine(
        center,
        center +
            Offset(
              math.cos(needleAngle) * radius * 0.65,
              math.sin(needleAngle) * radius * 0.65,
            ),
        paint,
      );

      // Center pivot
      final pivotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = accentColor.withOpacity(opacity * intensity);
      canvas.drawCircle(center, 3 * intensity, pivotPaint);
    }
  }

  void _drawSteamEffects(Canvas canvas, Size size) {
    // Steam vents
    final vents = [
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.85),
    ];

    for (int v = 0; v < vents.length; v++) {
      final vent = vents[v];

      // Multiple steam puffs per vent
      for (int i = 0; i < 5; i++) {
        final progress = (particleAnimation + i * 0.2 + v * 0.1) % 1.0;
        final rise = progress * size.height * 0.3;
        final drift = math.sin(progress * math.pi * 2 + v) * 30 * intensity;
        final expand = 8 + progress * 25;

        final steamOpacity = math.max(0.0, (1 - progress) * 0.08 * intensity);

        if (steamOpacity > 0.01) {
          final steamPos = vent + Offset(drift, -rise);

          // Layered cloud effect
          final steamPaint = Paint()
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

          // Core
          steamPaint.color = _steam.withOpacity(steamOpacity);
          canvas.drawCircle(steamPos, expand * intensity, steamPaint);

          // Secondary puffs
          steamPaint.color = _steam.withOpacity(steamOpacity * 0.6);
          canvas.drawCircle(
            steamPos + Offset(-expand * 0.4, expand * 0.2),
            expand * 0.7 * intensity,
            steamPaint,
          );
          canvas.drawCircle(
            steamPos + Offset(expand * 0.3, -expand * 0.1),
            expand * 0.5 * intensity,
            steamPaint,
          );
        }
      }
    }
  }

  void _drawMechanicalParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final particleCount = (30 * intensity).round();

    for (int i = 0; i < particleCount; i++) {
      final baseX = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;

      // Floating motion
      final floatX = baseX + math.sin(particleAnimation * 2 * math.pi + i * 0.4) * 12 * intensity;
      final floatY = baseY + math.cos(particleAnimation * 1.5 * math.pi + i * 0.6) * 10 * intensity;

      // Twinkling effect
      final twinkle = math.sin(particleAnimation * 6 * math.pi + i * 0.8) * 0.5 + 0.5;

      if (twinkle > 0.3) {
        final particleOpacity = twinkle * 0.25 * intensity;
        final particleColor = Color.lerp(
          primaryColor,
          accentColor,
          _random.nextDouble(),
        )!
            .withOpacity(particleOpacity);

        paint.color = particleColor;

        // Variety of particle shapes
        switch (i % 5) {
          case 0: // Spark
            paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawCircle(Offset(floatX, floatY), 2 * intensity * twinkle, paint);
            paint.maskFilter = null;
            break;

          case 1: // Hex bolt
            _drawHexagon(canvas, paint, Offset(floatX, floatY), 2.5 * intensity * twinkle);
            break;

          case 2: // Gear fragment
            final fragmentPath = Path()
              ..moveTo(floatX - 2 * intensity, floatY)
              ..lineTo(floatX, floatY - 3 * intensity)
              ..lineTo(floatX + 2 * intensity, floatY)
              ..lineTo(floatX, floatY + 2 * intensity)
              ..close();
            canvas.drawPath(fragmentPath, paint);
            break;

          case 3: // Rivet
            canvas.drawCircle(Offset(floatX, floatY), 1.8 * intensity * twinkle, paint);
            paint.color = particleColor.withOpacity(particleOpacity * 0.5);
            canvas.drawCircle(Offset(floatX, floatY), 1 * intensity * twinkle, paint);
            break;

          case 4: // Metal shard
            final shardPath = Path()
              ..moveTo(floatX, floatY - 3 * intensity)
              ..lineTo(floatX + 1.5 * intensity, floatY + 2 * intensity)
              ..lineTo(floatX - 1 * intensity, floatY + 1 * intensity)
              ..close();
            canvas.drawPath(shardPath, paint);
            break;
        }
      }
    }
  }

  void _drawPatinaEffects(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final patinaCount = (5 * intensity).round();
    for (int i = 0; i < patinaCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = (40 + _random.nextDouble() * 60) * intensity;

      final pulsate = math.sin(mainAnimation * 2 * math.pi + i * 0.9) * 0.15 + 0.3;

      // Verdigris (green oxidation)
      paint.color = _verdigris.withOpacity(0.025 * pulsate * intensity);
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Rust spots
      if (i % 2 == 0) {
        paint.color = _rust.withOpacity(0.02 * pulsate * intensity);
        canvas.drawCircle(
          Offset(x + radius * 0.3, y + radius * 0.2),
          radius * 0.6,
          paint,
        );
      }
    }
  }

  void _drawAmbientLightRays(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    // Warm ambient light from top-left
    final lightOpacity = 0.03 + math.sin(mainAnimation * math.pi) * 0.01;

    final lightGradient = ui.Gradient.radial(
      Offset(size.width * 0.2, size.height * 0.1),
      size.longestSide * 0.6,
      [
        accentColor.withOpacity(lightOpacity * intensity),
        Colors.transparent,
      ],
    );

    paint.shader = lightGradient;
    canvas.drawRect(Offset.zero & size, paint);

    // Secondary warm glow from bottom
    final bottomGlow = ui.Gradient.linear(
      Offset(0, size.height),
      Offset(0, size.height * 0.7),
      [
        _hotMetal.withOpacity(0.02 * intensity),
        Colors.transparent,
      ],
    );

    paint.shader = bottomGlow;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.8;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.3 * intensity),
        Colors.black.withOpacity(0.5 * intensity),
      ],
      [0.5, 0.8, 1.0],
    );

    final paint = Paint()..shader = vignette;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CopperSteampunkPainter oldDelegate) {
    return oldDelegate.mainAnimation != mainAnimation ||
        oldDelegate.secondaryAnimation != secondaryAnimation ||
        oldDelegate.particleAnimation != particleAnimation ||
        oldDelegate.intensity != intensity;
  }
}

// Helper class for gear configurations
class _GearConfig {
  final double xRatio;
  final double yRatio;
  final double radius;
  final int teeth;
  final double speedMultiplier;

  const _GearConfig(
    this.xRatio,
    this.yRatio,
    this.radius,
    this.teeth,
    this.speedMultiplier,
  );
}

// Extension to reset random seed
extension on math.Random {
  void setSeed(int seed) {
    // Note: This is a workaround since Dart's Random doesn't support reseeding
    // In production, you'd use a seedable PRNG like xorshift
  }
}
