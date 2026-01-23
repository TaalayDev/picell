import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

// ============================================================================
// DATA STREAM THEME BUILDER
// ============================================================================

AppTheme buildDataStreamTheme() {
  final baseTextTheme = GoogleFonts.jetBrainsMonoTextTheme();
  final bodyTextTheme = GoogleFonts.firaCodeTextTheme();

  return AppTheme(
    type: ThemeType.dataStream,
    isDark: true,

    // Primary colors - electric green
    primaryColor: const Color(0xFF00FF88),
    primaryVariant: const Color(0xFF00CC6A),
    onPrimary: const Color(0xFF001A0D),

    // Secondary colors - cyan accent
    accentColor: const Color(0xFF00DDFF),
    onAccent: const Color(0xFF001A1F),

    // Background colors - deep black
    background: const Color(0xFF000A06),
    surface: const Color(0xFF001A10),
    surfaceVariant: const Color(0xFF002818),

    // Text colors
    textPrimary: const Color(0xFF00FF88),
    textSecondary: const Color(0xFF00AA60),
    textDisabled: const Color(0xFF005530),

    // UI colors
    divider: const Color(0xFF003820),
    toolbarColor: const Color(0xFF001A10),
    error: const Color(0xFFFF4060),
    success: const Color(0xFF00FF88),
    warning: const Color(0xFFFFAA00),

    // Grid colors
    gridLine: const Color(0xFF003820),
    gridBackground: const Color(0xFF001A10),

    // Canvas colors
    canvasBackground: const Color(0xFF000A06),
    selectionOutline: const Color(0xFF00FF88),
    selectionFill: const Color(0x3000FF88),

    // Icon colors
    activeIcon: const Color(0xFF00FF88),
    inactiveIcon: const Color(0xFF00AA60),

    // Typography
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        color: const Color(0xFF00FF88),
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        color: const Color(0xFF00FF88),
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        color: const Color(0xFF00FF88),
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        color: const Color(0xFF00FF88),
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyTextTheme.bodyLarge!.copyWith(
        color: const Color(0xFF00FF88),
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: bodyTextTheme.bodyMedium!.copyWith(
        color: const Color(0xFF00AA60),
        fontWeight: FontWeight.w400,
      ),
      labelLarge: bodyTextTheme.labelLarge!.copyWith(
        color: const Color(0xFF00DDFF),
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    ),
    primaryFontWeight: FontWeight.w400,
  );
}

// ============================================================================
// DATA STREAM ANIMATED BACKGROUND
// ============================================================================

class DataStreamBackground extends HookWidget {
  final AppTheme theme;
  final double intensity;
  final bool enableAnimation;

  const DataStreamBackground({
    super.key,
    required this.theme,
    this.intensity = 1.0,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Controller acts as a ticker
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

    // 2. Persist state for smooth infinite time accumulation
    final streamState = useMemoized(() => _StreamState());

    return RepaintBoundary(
      child: CustomPaint(
        painter: _DataStreamPainter(
          repaint: controller,
          state: streamState,
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          intensity: intensity.clamp(0.0, 2.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// State class to hold accumulated time
class _StreamState {
  double time = 0;
  double lastFrameTimestamp = 0;
}

// Pre-computed stream column data
class _StreamColumn {
  final double x;
  final double speed;
  final double phaseOffset;
  final int charCount;
  final double fontSize;
  final int colorType; // 0=green, 1=cyan, 2=white

  const _StreamColumn(this.x, this.speed, this.phaseOffset, this.charCount, this.fontSize, this.colorType);
}

// Pre-computed node data for network visualization
class _NodeData {
  final double x;
  final double y;
  final double pulseOffset;
  final double size;

  const _NodeData(this.x, this.y, this.pulseOffset, this.size);
}

class _DataStreamPainter extends CustomPainter {
  final _StreamState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;

  // Color palette
  static const Color _green = Color(0xFF00FF88);
  static const Color _greenDark = Color(0xFF00AA55);
  static const Color _greenDim = Color(0xFF005530);
  static const Color _cyan = Color(0xFF00DDFF);
  static const Color _white = Color(0xFFCCFFEE);
  static const Color _black = Color(0xFF000A06);

  // Characters for the stream
  static const String _chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF<>{}[]=/\\';

  // Pre-computed stream columns
  static final List<_StreamColumn> _columns = List.generate(35, (i) {
    final rng = math.Random(i * 137);
    return _StreamColumn(
      (i + 0.5) / 35, // Normalized x position
      0.3 + rng.nextDouble() * 0.5, // Speed
      rng.nextDouble() * 6.28, // Phase offset
      8 + rng.nextInt(20), // Character count
      10 + rng.nextDouble() * 8, // Font size
      rng.nextInt(10) < 7 ? 0 : (rng.nextInt(10) < 8 ? 1 : 2), // Color type
    );
  });

  // Pre-computed nodes for network effect
  static final List<_NodeData> _nodes = List.generate(15, (i) {
    final rng = math.Random(i * 293);
    return _NodeData(
      rng.nextDouble(),
      rng.nextDouble(),
      rng.nextDouble() * 6.28,
      3 + rng.nextDouble() * 4,
    );
  });

  // Pre-computed character indices for each column
  static final List<List<int>> _columnChars = List.generate(35, (col) {
    final rng = math.Random(col * 571);
    return List.generate(30, (_) => rng.nextInt(_chars.length));
  });

  // Reusable objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  _DataStreamPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
  }) : super(repaint: repaint);

  // Scaled time to match original speed (original was 0-1 over 10s, so rate was 0.1/s)
  double get _phase => state.time * 0.1;

  @override
  void paint(Canvas canvas, Size size) {
    // Time Accumulation Logic
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dt = (state.lastFrameTimestamp == 0) ? 0.016 : (now - state.lastFrameTimestamp);
    state.lastFrameTimestamp = now;
    state.time += dt;

    _paintBackground(canvas, size);
    _paintGridLines(canvas, size);
    _paintNetworkNodes(canvas, size);
    _paintDataStreams(canvas, size);
    _paintScanLine(canvas, size);
    _paintGlowEffects(canvas, size);
    _paintVignette(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Deep black with subtle gradient
    final gradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.3),
      size.longestSide * 0.8,
      [
        const Color(0xFF001510),
        const Color(0xFF000A06),
        const Color(0xFF000502),
      ],
      const [0.0, 0.5, 1.0],
    );

    _fillPaint.shader = gradient;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  void _paintGridLines(Canvas canvas, Size size) {
    _strokePaint.strokeWidth = 0.5 * intensity;

    // Horizontal grid lines
    final hLineCount = 30;
    for (int i = 0; i < hLineCount; i++) {
      final y = (i / hLineCount) * size.height;
      final opacity = (0.03 + math.sin(_phase * 2 * math.pi + i * 0.2) * 0.015) * intensity;

      _strokePaint.color = _greenDim.withOpacity(opacity);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _strokePaint);
    }

    // Vertical grid lines
    final vLineCount = 40;
    for (int i = 0; i < vLineCount; i++) {
      final x = (i / vLineCount) * size.width;
      final opacity = (0.02 + math.sin(_phase * 2 * math.pi + i * 0.15) * 0.01) * intensity;

      _strokePaint.color = _greenDim.withOpacity(opacity);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _strokePaint);
    }
  }

  void _paintNetworkNodes(Canvas canvas, Size size) {
    // Draw connections first
    _strokePaint.strokeWidth = 1 * intensity;

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final nodeX = node.x * size.width;
      final nodeY = node.y * size.height;

      // Connect to nearby nodes
      for (int j = i + 1; j < _nodes.length; j++) {
        final other = _nodes[j];
        final otherX = other.x * size.width;
        final otherY = other.y * size.height;

        final distance = math.sqrt(math.pow(nodeX - otherX, 2) + math.pow(nodeY - otherY, 2));

        if (distance < size.width * 0.25) {
          final pulse = math.sin(_phase * 2 * math.pi * 2 + node.pulseOffset + other.pulseOffset) * 0.5 + 0.5;
          final opacity = (0.08 * (1 - distance / (size.width * 0.25)) * pulse) * intensity;

          _strokePaint.color = _greenDark.withOpacity(opacity);
          canvas.drawLine(Offset(nodeX, nodeY), Offset(otherX, otherY), _strokePaint);

          // Data packet traveling along connection
          if (pulse > 0.7) {
            final packetProgress = (_phase * 3 + i * 0.1 + j * 0.05) % 1.0;
            final packetX = nodeX + (otherX - nodeX) * packetProgress;
            final packetY = nodeY + (otherY - nodeY) * packetProgress;

            _fillPaint.color = _green.withOpacity(0.6 * intensity);
            canvas.drawCircle(Offset(packetX, packetY), 2 * intensity, _fillPaint);
          }
        }
      }
    }

    // Draw nodes
    for (final node in _nodes) {
      final x = node.x * size.width;
      final y = node.y * size.height;
      final pulse = math.sin(_phase * 2 * math.pi * 1.5 + node.pulseOffset) * 0.3 + 0.7;
      final nodeSize = node.size * intensity * pulse;

      // Outer glow
      _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * intensity);
      _fillPaint.color = _green.withOpacity(0.15 * pulse * intensity);
      canvas.drawCircle(Offset(x, y), nodeSize * 2, _fillPaint);

      // Core
      _fillPaint.maskFilter = null;
      _fillPaint.color = _green.withOpacity(0.4 * pulse * intensity);
      canvas.drawCircle(Offset(x, y), nodeSize, _fillPaint);

      // Center bright point
      _fillPaint.color = _white.withOpacity(0.6 * pulse * intensity);
      canvas.drawCircle(Offset(x, y), nodeSize * 0.3, _fillPaint);
    }
  }

  void _paintDataStreams(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int col = 0; col < _columns.length; col++) {
      final column = _columns[col];
      final x = column.x * size.width;
      final charHeight = column.fontSize * 1.2;

      // Calculate stream position (falling effect) using infinite time phase
      // The modulo ensures it wraps around screen space seamlessly
      final streamProgress = (_phase * column.speed + column.phaseOffset / 6.28) % 1.0;
      final startY =
          -column.charCount * charHeight + streamProgress * (size.height + column.charCount * charHeight * 2);

      // Determine base color
      Color baseColor;
      switch (column.colorType) {
        case 1:
          baseColor = _cyan;
          break;
        case 2:
          baseColor = _white;
          break;
        default:
          baseColor = _green;
      }

      for (int i = 0; i < column.charCount; i++) {
        final y = startY + i * charHeight;

        // Skip if outside visible area
        if (y < -charHeight || y > size.height + charHeight) continue;

        // Character changes over time
        final charIndex =
            (_columnChars[col][i % _columnChars[col].length] + ((_phase * 20 + i * 0.5).floor())) % _chars.length;
        final char = _chars[charIndex];

        // Fade based on position in stream (head is brightest)
        final positionInStream = i / column.charCount;
        double opacity;

        if (i == 0) {
          // Leading character - brightest, white
          opacity = 1.0;
          textPainter.text = TextSpan(
            text: char,
            style: TextStyle(
              color: _white.withOpacity(opacity * intensity),
              fontSize: column.fontSize * intensity,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          );
        } else if (i < 3) {
          // Near head - bright
          opacity = 0.9 - i * 0.1;
          textPainter.text = TextSpan(
            text: char,
            style: TextStyle(
              color: baseColor.withOpacity(opacity * intensity),
              fontSize: column.fontSize * intensity,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w500,
            ),
          );
        } else {
          // Trail - fading
          opacity = (0.6 * (1 - positionInStream)).clamp(0.05, 0.6);
          textPainter.text = TextSpan(
            text: char,
            style: TextStyle(
              color: baseColor.withOpacity(opacity * intensity),
              fontSize: column.fontSize * intensity,
              fontFamily: 'JetBrains Mono',
            ),
          );
        }

        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
      }

      // Glow effect on leading character
      final leadY = startY;
      if (leadY > -charHeight && leadY < size.height + charHeight) {
        _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * intensity);
        _fillPaint.color = baseColor.withOpacity(0.3 * intensity);
        canvas.drawCircle(Offset(x, leadY + charHeight / 2), column.fontSize * 0.8 * intensity, _fillPaint);
        _fillPaint.maskFilter = null;
      }
    }
  }

  void _paintScanLine(Canvas canvas, Size size) {
    // Horizontal scan line moving down infinitely
    final scanY = (_phase * 2 % 1.0) * size.height;

    final scanGradient = ui.Gradient.linear(
      Offset(0, scanY - 30 * intensity),
      Offset(0, scanY + 30 * intensity),
      [
        Colors.transparent,
        _green.withOpacity(0.1 * intensity),
        _green.withOpacity(0.2 * intensity),
        _green.withOpacity(0.1 * intensity),
        Colors.transparent,
      ],
      const [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    _fillPaint.shader = scanGradient;
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 30 * intensity, size.width, 60 * intensity),
      _fillPaint,
    );
    _fillPaint.shader = null;

    // Bright scan line
    _strokePaint.strokeWidth = 1.5 * intensity;
    _strokePaint.color = _green.withOpacity(0.4 * intensity);
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), _strokePaint);
  }

  void _paintGlowEffects(Canvas canvas, Size size) {
    // Random flicker highlights
    final rng = math.Random((_phase * 100).floor());

    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * intensity);

    for (int i = 0; i < 5; i++) {
      if (rng.nextDouble() > 0.7) {
        final x = rng.nextDouble() * size.width;
        final y = rng.nextDouble() * size.height;
        final glowSize = (20 + rng.nextDouble() * 30) * intensity;

        _fillPaint.color = _green.withOpacity(0.08 * intensity);
        canvas.drawCircle(Offset(x, y), glowSize, _fillPaint);
      }
    }

    _fillPaint.maskFilter = null;

    // Corner accent glows
    final cornerGlow = math.sin(_phase * 2 * math.pi) * 0.3 + 0.7;

    _fillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 50 * intensity);
    _fillPaint.color = _green.withOpacity(0.05 * cornerGlow * intensity);

    canvas.drawCircle(Offset(0, 0), 100 * intensity, _fillPaint);
    canvas.drawCircle(Offset(size.width, size.height), 80 * intensity, _fillPaint);

    _fillPaint.color = _cyan.withOpacity(0.03 * cornerGlow * intensity);
    canvas.drawCircle(Offset(size.width, 0), 70 * intensity, _fillPaint);
    canvas.drawCircle(Offset(0, size.height), 60 * intensity, _fillPaint);

    _fillPaint.maskFilter = null;
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.75;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        _black.withOpacity(0.4 * intensity),
        _black.withOpacity(0.85 * intensity),
      ],
      const [0.3, 0.7, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _DataStreamPainter oldDelegate) {
    // Always repaint for animation
    return true;
  }
}
