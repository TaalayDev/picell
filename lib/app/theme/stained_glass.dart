import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// STAINED GLASS THEME BUILDER
// ============================================================================

AppTheme buildStainedGlassTheme() {
  final baseTextTheme = GoogleFonts.cinzelTextTheme();
  final bodyTextTheme = GoogleFonts.latoTextTheme();

  return AppTheme(
    type: ThemeType.stainedGlass,
    isDark: true,

    // Primary: Deep Ruby Red (The "Rose" in Rose Window)
    primaryColor: const Color(0xFFD90429),
    // Variant: Darker Crimson
    primaryVariant: const Color(0xFF8D0801),
    onPrimary: Colors.white,

    // Accent: Illuminated Gold (Divine Light)
    accentColor: const Color(0xFFFFD700),
    onAccent: Colors.black,

    // Backgrounds: The "Lead" and "Night" outside
    background: const Color(0xFF050505), // Pure black soot/lead
    surface: const Color(0xFF161618), // Dark iron
    surfaceVariant: const Color(0xFF242426), // Lighter graphite

    // Text: Illuminated parchment style
    textPrimary: const Color(0xFFF4F1DE), // Antique White
    textSecondary: const Color(0xFF9CAEA9), // Muted Sage/Silver
    textDisabled: const Color(0xFF525252),

    // UI Colors
    divider: const Color(0xFF3D405B), // Dark lead/slate
    toolbarColor: const Color(0xFF0D0D0D),
    error: const Color(0xFF9B2226), // Blood red
    success: const Color(0xFF2D6A4F), // Bottle green
    warning: const Color(0xFFE9C46A), // Muted Gold

    // Grid
    gridLine: const Color(0xFF222222),
    gridBackground: const Color(0xFF080808),

    // Canvas
    canvasBackground: const Color(0xFF030303),
    selectionOutline: const Color(0xFFFFD700),
    selectionFill: const Color(0x33FFD700),

    // Icons
    activeIcon: const Color(0xFFFFD700),
    inactiveIcon: const Color(0xFF5F6C7B),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFF4F1DE),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        shadows: [
          const Shadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFF4F1DE),
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFFFD700),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFF4F1DE),
        fontSize: 16,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF9CAEA9),
      ),
    ),
    primaryFontWeight: FontWeight.w600,
  );
}

// ============================================================================
// STAINED GLASS ANIMATED BACKGROUND
// ============================================================================

class StainedGlassBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const StainedGlassBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Light Source Animation (Slow drift behind glass)
    final lightController = useAnimationController(
      duration: const Duration(seconds: 20),
    );

    // 2. Pulse Animation (Subtle breathing of light intensity)
    final pulseController = useAnimationController(
      duration: const Duration(seconds: 6),
    );

    // 3. Dust/Particle Animation (Continuous flow)
    final particleController = useAnimationController(
      duration: const Duration(seconds: 30),
    );

    useEffect(() {
      if (enableAnimation) {
        lightController.repeat();
        pulseController.repeat(reverse: true);
        particleController.repeat();
      } else {
        lightController.stop();
        pulseController.stop();
        particleController.stop();
      }
      return null;
    }, [enableAnimation]);

    // Use explicit value access to avoid type inference issues
    useListenable(lightController);
    useListenable(pulseController);
    useListenable(particleController);

    final double lightProgress = lightController.value;
    final double pulseProgress = pulseController.value;
    final double particleProgress = particleController.value;

    // Use a geometry cache to avoid static state and regeneration issues
    final geometryCache = useMemoized(() => _GeometryCache());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _StainedGlassPainter(
          lightProgress: lightProgress,
          pulseProgress: pulseProgress,
          particleProgress: particleProgress,
          intensity: intensity,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          geometryCache: geometryCache,
          animationEnabled: enableAnimation,
        ),
        size: Size.infinite,
        isComplex: true,
        willChange: enableAnimation,
      ),
    );
  }
}

class _GeometryCache {
  List<_Shard> shards = [];
  List<_DustMote> dust = [];
  Size? size;
}

class _StainedGlassPainter extends CustomPainter {
  final double lightProgress;
  final double pulseProgress;
  final double particleProgress;
  final double intensity;
  final Color primaryColor;
  final Color accentColor;
  final _GeometryCache geometryCache;
  final bool animationEnabled;

  // Reuse Paint objects for performance
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _leadPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _rayPaint = Paint()..style = PaintingStyle.fill;

  _StainedGlassPainter({
    required this.lightProgress,
    required this.pulseProgress,
    required this.particleProgress,
    required this.intensity,
    required this.primaryColor,
    required this.accentColor,
    required this.geometryCache,
    this.animationEnabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Regenerate geometry if size changes
    if (geometryCache.size != size || geometryCache.shards.isEmpty) {
      _generateGeometry(size);
      _generateDust(size);
      geometryCache.size = size;
    }

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF020202),
    );

    // Calculate moving light source position
    // Moves in a figure-8 pattern behind the glass
    final lightX = size.width * 0.5 + math.cos(lightProgress * 2 * math.pi) * size.width * 0.35;
    final lightY = size.height * 0.4 + math.sin(lightProgress * 4 * math.pi) * size.height * 0.15;
    final lightPos = Offset(lightX, lightY);

    // 1. Draw Volumetric "God Rays" (Behind the glass)
    _paintGodRays(canvas, size, lightPos);

    // 2. Draw Glass Shards
    _paintGlassLayer(canvas, size, lightPos);

    // 3. Draw Lead Lines (Cames) with 3D effect
    _paintLeadLines(canvas);

    // 4. Draw Floating Dust Motes (In front of glass)
    _paintDustMotes(canvas, size, lightPos);

    // 5. Vignette
    _paintVignette(canvas, size);
  }

  void _paintGodRays(Canvas canvas, Size size, Offset lightPos) {
    if (intensity < 0.1) return;

    // Draw rotating beams
    final count = 5;
    canvas.save();
    canvas.translate(lightPos.dx, lightPos.dy);
    // Rotate the entire ray system slowly
    canvas.rotate(lightProgress * math.pi * 0.2);

    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi * i) / count;
      final rayIntensity = (math.sin(pulseProgress * math.pi + i) + 1) / 2;

      final rayGradient = ui.Gradient.radial(
        Offset.zero,
        size.longestSide * 0.8,
        [
          accentColor.withOpacity(0.05 * rayIntensity * intensity),
          Colors.transparent,
        ],
        [0.0, 0.7],
      );

      _rayPaint.shader = rayGradient;

      // Draw a wide wedge
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle - 0.3) * size.longestSide, math.sin(angle - 0.3) * size.longestSide)
        ..lineTo(math.cos(angle + 0.3) * size.longestSide, math.sin(angle + 0.3) * size.longestSide)
        ..close();

      canvas.drawPath(path, _rayPaint);
    }
    canvas.restore();
  }

  void _paintGlassLayer(Canvas canvas, Size size, Offset lightPos) {
    final maxDist = size.longestSide;

    for (final shard in geometryCache.shards) {
      // Distance to light source affects brightness and color
      final dist = (shard.center - lightPos).distance;
      // 0.0 = far, 1.0 = directly on top
      final proximity = (1.0 - (dist / (maxDist * 0.6))).clamp(0.0, 1.0);

      // Base opacity varies by shard + light proximity
      double alpha = shard.baseOpacity + (proximity * 0.6);
      // Breathing effect
      alpha += (pulseProgress * 0.1 * shard.pulseOffset);
      alpha = alpha.clamp(0.0, 0.95) * intensity;

      if (alpha < 0.01) continue;

      Color color = _getShardColor(shard.type);

      // If very close to light, wash out the color towards white (overexposure)
      if (proximity > 0.7) {
        final wash = (proximity - 0.7) * 3.33; // 0.0 to 1.0
        color = Color.lerp(color, Colors.white, wash * 0.8)!;
      }

      // Use a radial gradient to simulate glass thickness
      // Center is lighter/more transparent, edges are deeper/richer
      final glassGradient = ui.Gradient.radial(
        shard.center,
        shard.radius * 1.5,
        [
          color.withOpacity(alpha), // Center
          color.withOpacity(alpha * 0.6), // Edge (darker in appearance due to background)
        ],
        [0.1, 1.0],
      );

      _fillPaint.shader = glassGradient;
      canvas.drawPath(shard.path, _fillPaint);
    }
  }

  Color _getShardColor(int type) {
    switch (type) {
      case 0:
        return primaryColor; // Ruby
      case 1:
        return const Color(0xFF1B4965); // Deep Blue
      case 2:
        return accentColor; // Gold
      case 3:
        return const Color(0xFF386641); // Bottle Green
      case 4:
        return const Color(0xFF7209B7); // Amethyst
      case 5:
        return const Color(0xFFF77F00); // Amber
      default:
        return Colors.grey;
    }
  }

  void _paintLeadLines(Canvas canvas) {
    // 1. Draw the thick black lead
    _leadPaint.color = const Color(0xFF080808);
    _leadPaint.strokeWidth = 3.0 * intensity;
    _leadPaint.shader = null;

    for (final shard in geometryCache.shards) {
      canvas.drawPath(shard.path, _leadPaint);
    }

    // 2. Draw a subtle highlight to give the lead 3D volume
    // We offset this path slightly up and left
    if (intensity > 0.5) {
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * intensity
        ..color = Colors.white.withOpacity(0.15 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

      canvas.save();
      canvas.translate(-1.0, -1.0); // Shift for top-left light source simulation on metal
      for (final shard in geometryCache.shards) {
        canvas.drawPath(shard.path, highlightPaint);
      }
      canvas.restore();
    }
  }

  void _paintDustMotes(Canvas canvas, Size size, Offset lightPos) {
    final pPaint = Paint()..style = PaintingStyle.fill;

    for (final mote in geometryCache.dust) {
      // Animate position
      final dy = (mote.y + particleProgress * size.height * mote.speedY) % size.height;
      final dx = (mote.x + math.sin(particleProgress * 2 * math.pi + mote.id) * 20);

      final pos = Offset(dx, dy);

      // Dust glows when near the light source
      final dist = (pos - lightPos).distance;
      final proximity = (1.0 - (dist / (size.longestSide * 0.4))).clamp(0.0, 1.0);

      if (proximity > 0) {
        final alpha = proximity * mote.baseAlpha * intensity;
        pPaint.color = accentColor.withOpacity(alpha);
        canvas.drawCircle(pos, mote.size * intensity, pPaint);
      }
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.4 * intensity),
        Colors.black.withOpacity(0.9 * intensity),
      ],
      stops: const [0.4, 0.8, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // ==========================================================================
  // GEOMETRY GENERATION
  // ==========================================================================

  void _generateGeometry(Size size) {
    geometryCache.shards.clear();
    final rng = math.Random(777); // Fixed seed

    // Using a jittered grid with some merged cells for variety
    const cols = 7;
    const rows = 12;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    List<Offset> points = [];

    // Generate perturbed grid points
    for (int y = 0; y <= rows; y++) {
      for (int x = 0; x <= cols; x++) {
        double dx = 0;
        double dy = 0;
        // Don't perturb edges to keep screen covered
        if (x > 0 && x < cols) dx = (rng.nextDouble() - 0.5) * cellW * 0.6;
        if (y > 0 && y < rows) dy = (rng.nextDouble() - 0.5) * cellH * 0.6;
        points.add(Offset(x * cellW + dx, y * cellH + dy));
      }
    }

    // Create Shards
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final tl = y * (cols + 1) + x;
        final tr = tl + 1;
        final bl = (y + 1) * (cols + 1) + x;
        final br = bl + 1;

        final poly = [points[tl], points[tr], points[br], points[bl]];

        // Randomly decide shape:
        // 0: Two triangles (split TL-BR)
        // 1: Two triangles (split TR-BL)
        // 2: One quad (rarer, for bigger glass pieces)

        final shapeType = rng.nextDouble();

        if (shapeType > 0.85) {
          // Quad
          _addShard(rng, poly);
        } else if (rng.nextBool()) {
          // Split 1
          _addShard(rng, [points[tl], points[tr], points[br]]);
          _addShard(rng, [points[tl], points[br], points[bl]]);
        } else {
          // Split 2
          _addShard(rng, [points[tr], points[br], points[bl]]);
          _addShard(rng, [points[tl], points[tr], points[bl]]);
        }
      }
    }
  }

  void _addShard(math.Random rng, List<Offset> polyPoints) {
    final path = Path()..moveTo(polyPoints[0].dx, polyPoints[0].dy);
    for (int i = 1; i < polyPoints.length; i++) {
      path.lineTo(polyPoints[i].dx, polyPoints[i].dy);
    }
    path.close();

    // Calculate approximate center and radius for gradient usage
    double cx = 0, cy = 0;
    for (var p in polyPoints) {
      cx += p.dx;
      cy += p.dy;
    }
    final center = Offset(cx / polyPoints.length, cy / polyPoints.length);

    // Approximate radius
    double maxR = 0;
    for (var p in polyPoints) {
      final r = (p - center).distance;
      if (r > maxR) maxR = r;
    }

    geometryCache.shards.add(_Shard(
      path: path,
      center: center,
      radius: maxR,
      type: rng.nextInt(6),
      baseOpacity: 0.2 + rng.nextDouble() * 0.4,
      pulseOffset: rng.nextDouble(),
    ));
  }

  void _generateDust(Size size) {
    geometryCache.dust.clear();
    final rng = math.Random(123);
    for (int i = 0; i < 60; i++) {
      geometryCache.dust.add(_DustMote(
        id: i,
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 1.0 + rng.nextDouble() * 2.0,
        speedY: 0.05 + rng.nextDouble() * 0.1, // Moving down slowly
        baseAlpha: 0.4 + rng.nextDouble() * 0.6,
      ));
    }
  }

  @override
  bool shouldRepaint(covariant _StainedGlassPainter oldDelegate) {
    return animationEnabled;
  }
}

class _Shard {
  final Path path;
  final Offset center;
  final double radius;
  final int type;
  final double baseOpacity;
  final double pulseOffset;

  _Shard({
    required this.path,
    required this.center,
    required this.radius,
    required this.type,
    required this.baseOpacity,
    required this.pulseOffset,
  });
}

class _DustMote {
  final int id;
  final double x;
  final double y;
  final double size;
  final double speedY;
  final double baseAlpha;

  _DustMote({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.baseAlpha,
  });
}
