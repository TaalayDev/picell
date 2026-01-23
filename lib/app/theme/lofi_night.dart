import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// LOFI NIGHT THEME BUILDER
// ============================================================================

AppTheme buildLofiNightTheme() {
  // Typewriter or Retro Terminal style fonts common in Lofi aesthetics
  final baseTextTheme = GoogleFonts.vt323TextTheme();
  final bodyTextTheme = GoogleFonts.spaceMonoTextTheme();

  return AppTheme(
    type: ThemeType.values.firstWhere(
      (t) => t.name == 'lofiNight',
      orElse: () => ThemeType.midnight, // Fallback
    ),
    isDark: true,

    // Primary: Muted Purple/Indigo
    primaryColor: const Color(0xFF6C5CE7),
    // Variant: Soft Lavender
    primaryVariant: const Color(0xFFA29BFE),
    onPrimary: Colors.white,

    // Accent: Warm Window Light (Orange/Yellow)
    accentColor: const Color(0xFFFDCB6E),
    onAccent: const Color(0xFF2D3436),

    // Backgrounds: Deep Rainy Night
    background: const Color(0xFF2D3436), // Dark Slate
    surface: const Color(0xFF353B48), // Slightly lighter slate
    surfaceVariant: const Color(0xFF404857),

    // Text: Terminal Green or Soft White
    textPrimary: const Color(0xFFDFE6E9),
    textSecondary: const Color(0xFFB2BEC3),
    textDisabled: const Color(0xFF636E72),

    // UI Colors
    divider: const Color(0xFF636E72),
    toolbarColor: const Color(0xFF2D3436),
    error: const Color(0xFFFF7675), // Pastel Red
    success: const Color(0xFF55EFC4), // Pastel Mint
    warning: const Color(0xFFFFEAA7), // Pastel Yellow

    // Grid
    gridLine: const Color(0xFF353B48),
    gridBackground: const Color(0xFF2D3436),

    // Canvas
    canvasBackground: const Color(0xFF1E272E),
    selectionOutline: const Color(0xFF6C5CE7),
    selectionFill: const Color(0x336C5CE7),

    // Icons
    activeIcon: const Color(0xFFFDCB6E), // Glowing windows
    inactiveIcon: const Color(0xFF636E72),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFFDFE6E9),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFFDFE6E9),
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFFFDCB6E), // Accent title
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFFDFE6E9),
        fontSize: 14,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFFB2BEC3),
        fontSize: 12,
      ),
    ),
    primaryFontWeight: FontWeight.w500,
  );
}

// ============================================================================
// LOFI NIGHT ANIMATED BACKGROUND
// ============================================================================

class LofiNightBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const LofiNightBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Controller acts as ticker
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

    // 2. Persist state for smooth infinite animation
    final lofiState = useMemoized(() => _LofiState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _LofiNightPainter(
          repaint: controller,
          state: lofiState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class for accumulated time
class _LofiState {
  double time = 0;
  double lastFrameTimestamp = 0;
  // Cache buildings to ensure they stay consistent as they scroll
  List<_Building>? cityLayer1;
  List<_Building>? cityLayer2;
  List<_RainDrop>? rainDrops;
}

// Data structures
class _Building {
  double x;
  final double width;
  final double height;
  final List<Offset> windows; // Relative coordinates 0..1
  final bool hasAntenna;

  _Building({
    required this.x,
    required this.width,
    required this.height,
    required this.windows,
    this.hasAntenna = false,
  });
}

class _RainDrop {
  double x;
  double y;
  double speed;
  double length;
  double alpha;

  _RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.alpha,
  });
}

class _LofiNightPainter extends CustomPainter {
  final _LofiState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Visual constants
  static const Color _skyTop = Color(0xFF0F0C29);
  static const Color _skyBottom = Color(0xFF302B63);
  static const Color _buildingColor1 = Color(0xFF14131F); // Foreground
  static const Color _buildingColor2 = Color(0xFF24243E); // Background
  static const Color _windowLight = Color(0xFFFFD54F); // Warm yellow

  _LofiNightPainter({
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
    if (state.cityLayer1 == null) _initCity(size);
    if (state.rainDrops == null) _initRain(size);

    // 1. Draw Sky (Gradient + Moon)
    _paintSky(canvas, size);

    // 2. Draw Background City Layer (Slow parallax)
    _updateAndPaintCity(canvas, size, state.cityLayer2!, _buildingColor2, 10.0 * intensity);

    // 3. Draw Foreground City Layer (Faster parallax)
    _updateAndPaintCity(canvas, size, state.cityLayer1!, _buildingColor1, 25.0 * intensity);

    // 4. Draw Rain
    _updateAndPaintRain(canvas, size, dt);

    // 5. Draw Vignette/Noise Overlay
    _paintVignette(canvas, size);
  }

  void _initCity(Size size) {
    final rng = math.Random(1234);

    List<_Building> generateLayer(int count, double minH, double maxH) {
      List<_Building> buildings = [];
      double currentX = 0;
      for (int i = 0; i < count; i++) {
        final w = 40.0 + rng.nextDouble() * 60.0;
        final h = minH + rng.nextDouble() * (maxH - minH);

        // Generate windows
        List<Offset> windows = [];
        int rows = (h / 15).floor();
        int cols = (w / 12).floor();
        for (int r = 1; r < rows; r++) {
          for (int c = 1; c < cols; c++) {
            if (rng.nextDouble() > 0.6) {
              // Random lit windows
              windows.add(Offset(c / cols, r / rows));
            }
          }
        }

        buildings.add(_Building(
          x: currentX,
          width: w,
          height: h,
          windows: windows,
          hasAntenna: rng.nextDouble() > 0.7,
        ));
        currentX += w;
      }
      return buildings;
    }

    // We generate enough width to cover screen + buffer
    // For simplicity, we just generate a fixed number that loops
    state.cityLayer2 = generateLayer(20, size.height * 0.1, size.height * 0.4); // Far
    state.cityLayer1 = generateLayer(15, size.height * 0.2, size.height * 0.6); // Near
  }

  void _initRain(Size size) {
    final rng = math.Random();
    state.rainDrops = List.generate(100, (index) {
      return _RainDrop(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        speed: 300 + rng.nextDouble() * 200,
        length: 10 + rng.nextDouble() * 20,
        alpha: 0.1 + rng.nextDouble() * 0.4,
      );
    });
  }

  void _paintSky(Canvas canvas, Size size) {
    // Gradient
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [_skyTop, _skyBottom],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);

    // Moon
    final moonCenter = Offset(size.width * 0.8, size.height * 0.2);
    final moonRadius = 40.0 * intensity;

    // Moon Glow
    canvas.drawCircle(
        moonCenter,
        moonRadius * 2.5,
        Paint()
          ..color = accentColor.withOpacity(0.1 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    // Moon Body
    canvas.drawCircle(moonCenter, moonRadius, Paint()..color = const Color(0xFFFEFCD7));
  }

  void _updateAndPaintCity(Canvas canvas, Size size, List<_Building> buildings, Color color, double speed) {
    // Calculate scroll offset based on accumulated time
    // We loop the buildings. To do this seamlessly, we assume the list covers the screen width.
    // A simplified approach for infinite scrolling:
    // Move x by speed * dt. If x + width < 0, move to end of line.

    // Calculate total width of the layer to determine wrap-around point
    double totalWidth = buildings.fold(0.0, (sum, b) => math.max(sum, b.x + b.width));
    // Ensure total width is at least screen width + buffer
    if (totalWidth < size.width * 2) totalWidth = size.width * 2;

    final paint = Paint()..color = color;
    final windowPaint = Paint()..color = _windowLight.withOpacity(0.6 * intensity);
    final antennaPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dt = state.time; // Use total time to calculate offset relative to initial state?
    // No, better to update state positions incrementally to handle variable speeds easily or just use phase.
    // Let's use phase logic based on time.

    double scrollOffset = (state.time * speed) % totalWidth;

    for (var b in buildings) {
      // Current position wrapping around totalWidth
      double drawX = (b.x - scrollOffset) % totalWidth;
      // If it wrapped to the very end (huge positive), bring it back to visual range
      if (drawX > size.width) drawX -= totalWidth;
      // If it's way behind (huge negative), bring it forward
      if (drawX + b.width < 0) drawX += totalWidth;

      // Draw if visible
      if (drawX < size.width && drawX + b.width > 0) {
        // Building body
        final rect = Rect.fromLTWH(drawX, size.height - b.height, b.width, b.height);
        canvas.drawRect(rect, paint);

        // Windows
        for (var w in b.windows) {
          // Flickering windows
          // Slowed down from * 5 to * 1.5 for a chiller vibe
          final flicker = math.sin(state.time * 0.2 + w.dx * 10 + w.dy * 10);
          if (flicker > 0.8) continue; // Randomly "off"

          final wx = drawX + w.dx * b.width;
          final wy = (size.height - b.height) + w.dy * b.height;
          // Simple rect window
          canvas.drawRect(Rect.fromLTWH(wx, wy, 4, 6), windowPaint);
        }

        // Antenna
        if (b.hasAntenna) {
          canvas.drawLine(Offset(drawX + b.width / 2, size.height - b.height),
              Offset(drawX + b.width / 2, size.height - b.height - 20), antennaPaint);
          // Red blinking light
          final blink = (math.sin(state.time * 2 + b.x) + 1) / 2;
          canvas.drawCircle(Offset(drawX + b.width / 2, size.height - b.height - 20), 2 * blink,
              Paint()..color = Colors.red.withOpacity(blink));
        }
      }
    }
  }

  void _updateAndPaintRain(Canvas canvas, Size size, double dt) {
    if (state.rainDrops == null) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (var drop in state.rainDrops!) {
      // Update
      drop.y += drop.speed * dt * intensity;
      drop.x -= 10 * dt * intensity; // Slight wind to left

      // Reset if out of bounds
      if (drop.y > size.height || drop.x < 0) {
        drop.y = -drop.length - math.Random().nextDouble() * 100;
        // Random x across screen width + slight buffer for wind
        drop.x = math.Random().nextDouble() * (size.width + 50);
      }

      // Draw
      paint.color = Colors.white.withOpacity(drop.alpha * 0.5 * intensity);
      canvas.drawLine(Offset(drop.x, drop.y), Offset(drop.x - 2, drop.y + drop.length), paint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    // 1. Dark corners
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.longestSide * 0.8,
      [
        Colors.transparent,
        Colors.black.withOpacity(0.3 * intensity),
        Colors.black.withOpacity(0.8 * intensity),
      ],
      [0.6, 0.85, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);

    // 2. Scanlines (Subtle retro feel)
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.05 * intensity)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LofiNightPainter oldDelegate) {
    // Always repaint for animation
    return true;
  }
}
