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
          animationEnabled: enableAnimation,
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
  int? cachedIntensityKey;
  Size? cachedConnectionSize;
  List<_NodeConnection> nodeConnections = const [];
  final Map<_GlyphCacheKey, TextPainter> glyphCache = {};
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

class _NodeConnection {
  final int fromIndex;
  final int toIndex;
  final double normalizedDistance;

  const _NodeConnection(this.fromIndex, this.toIndex, this.normalizedDistance);
}

class _GlyphCacheKey {
  final int fontSize;
  final int styleTier;
  final int colorType;
  final int charCode;

  const _GlyphCacheKey({
    required this.fontSize,
    required this.styleTier,
    required this.colorType,
    required this.charCode,
  });

  @override
  bool operator ==(Object other) {
    return other is _GlyphCacheKey &&
        other.fontSize == fontSize &&
        other.styleTier == styleTier &&
        other.colorType == colorType &&
        other.charCode == charCode;
  }

  @override
  int get hashCode => Object.hash(fontSize, styleTier, colorType, charCode);
}

class _DataStreamPainter extends CustomPainter {
  final _StreamState state;
  final Color primaryColor;
  final Color accentColor;
  final double intensity;
  final bool animationEnabled;

  // Color palette
  static const Color _green = Color(0xFF00FF88);
  static const Color _greenDark = Color(0xFF00AA55);
  static const Color _greenDim = Color(0xFF005530);
  static const Color _cyan = Color(0xFF00DDFF);
  static const Color _white = Color(0xFFCCFFEE);
  static const Color _black = Color(0xFF000A06);

  // Characters for the stream
  static const String _chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF<>{}[]=/\\';

  // Pre-computed stream columns (reduced for performance)
  static const _columnCount = 18;
  static final List<_StreamColumn> _columns = List.generate(_columnCount, (i) {
    final rng = math.Random(i * 137);
    return _StreamColumn(
      (i + 0.5) / _columnCount, // Normalized x position
      0.3 + rng.nextDouble() * 0.5, // Speed
      rng.nextDouble() * 6.28, // Phase offset
      6 + rng.nextInt(12), // Character count (reduced)
      10 + rng.nextDouble() * 8, // Font size
      rng.nextInt(10) < 7 ? 0 : (rng.nextInt(10) < 8 ? 1 : 2), // Color type
    );
  });

  // Pre-computed nodes for network effect (reduced for performance)
  static final List<_NodeData> _nodes = List.generate(8, (i) {
    final rng = math.Random(i * 293);
    return _NodeData(
      rng.nextDouble(),
      rng.nextDouble(),
      rng.nextDouble() * 6.28,
      3 + rng.nextDouble() * 4,
    );
  });

  // Pre-computed character indices for each column
  static final List<List<int>> _columnChars = List.generate(_columnCount, (col) {
    final rng = math.Random(col * 571);
    return List.generate(20, (_) => rng.nextInt(_chars.length));
  });

  // Maximum glyph cache entries to prevent unbounded growth
  static const _maxGlyphCacheSize = 512;

  // Reusable objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  _DataStreamPainter({
    required Listenable repaint,
    required this.state,
    required this.primaryColor,
    required this.accentColor,
    required this.intensity,
    this.animationEnabled = true,
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

    _prepareCaches(size);

    _paintBackground(canvas, size);
    _paintGridLines(canvas, size);
    _paintNetworkNodes(canvas, size);
    _paintDataStreams(canvas, size);
    _paintScanLine(canvas, size);
    _paintGlowEffects(canvas, size);
    _paintVignette(canvas, size);
  }

  void _prepareCaches(Size size) {
    final intensityKey = (intensity * 100).round();
    if (state.cachedIntensityKey != intensityKey) {
      state.cachedIntensityKey = intensityKey;
      state.glyphCache.clear();
    }

    if (state.cachedConnectionSize != size) {
      state.cachedConnectionSize = size;
      state.nodeConnections = _buildNodeConnections(size);
    }
  }

  List<_NodeConnection> _buildNodeConnections(Size size) {
    final connections = <_NodeConnection>[];
    final maxDistance = size.width * 0.25;
    final maxDistanceSquared = maxDistance * maxDistance;

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final nodeX = node.x * size.width;
      final nodeY = node.y * size.height;

      for (int j = i + 1; j < _nodes.length; j++) {
        final other = _nodes[j];
        final otherX = other.x * size.width;
        final otherY = other.y * size.height;

        final dx = nodeX - otherX;
        final dy = nodeY - otherY;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared >= maxDistanceSquared) continue;

        final normalizedDistance = math.sqrt(distanceSquared) / maxDistance;
        connections.add(_NodeConnection(i, j, normalizedDistance));
      }
    }

    return connections;
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

    // Horizontal grid lines (reduced count)
    const hLineCount = 12;
    for (int i = 0; i < hLineCount; i++) {
      final y = (i / hLineCount) * size.height;
      final opacity = (0.03 + math.sin(_phase * 2 * math.pi + i * 0.5) * 0.015) * intensity;

      _strokePaint.color = _greenDim.withValues(alpha: opacity);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _strokePaint);
    }

    // Vertical grid lines (reduced count)
    const vLineCount = 16;
    for (int i = 0; i < vLineCount; i++) {
      final x = (i / vLineCount) * size.width;
      final opacity = (0.02 + math.sin(_phase * 2 * math.pi + i * 0.35) * 0.01) * intensity;

      _strokePaint.color = _greenDim.withValues(alpha: opacity);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _strokePaint);
    }
  }

  void _paintNetworkNodes(Canvas canvas, Size size) {
    final nodeOffsets = <Offset>[
      for (final node in _nodes) Offset(node.x * size.width, node.y * size.height),
    ];

    // Draw connections first
    _strokePaint.strokeWidth = 1 * intensity;

    for (final connection in state.nodeConnections) {
      final node = _nodes[connection.fromIndex];
      final other = _nodes[connection.toIndex];
      final nodeOffset = nodeOffsets[connection.fromIndex];
      final otherOffset = nodeOffsets[connection.toIndex];

      final pulse = math.sin(
                _phase * 2 * math.pi * 2 + node.pulseOffset + other.pulseOffset,
              ) *
              0.5 +
          0.5;
      final opacity = (0.08 * (1 - connection.normalizedDistance) * pulse) * intensity;

      _strokePaint.color = _greenDark.withValues(alpha: opacity);
      canvas.drawLine(nodeOffset, otherOffset, _strokePaint);

      if (pulse > 0.7) {
        final packetProgress = (_phase * 3 + connection.fromIndex * 0.1 + connection.toIndex * 0.05) % 1.0;
        final packetX = nodeOffset.dx + (otherOffset.dx - nodeOffset.dx) * packetProgress;
        final packetY = nodeOffset.dy + (otherOffset.dy - nodeOffset.dy) * packetProgress;

        _fillPaint.color = _green.withValues(alpha: 0.6 * intensity);
        canvas.drawCircle(Offset(packetX, packetY), 2 * intensity, _fillPaint);
      }
    }

    // Draw nodes (no blur for performance)
    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final offset = nodeOffsets[i];
      final pulse = math.sin(_phase * 2 * math.pi * 1.5 + node.pulseOffset) * 0.3 + 0.7;
      final nodeSize = node.size * intensity * pulse;

      // Outer halo (no blur)
      _fillPaint.color = _green.withValues(alpha: 0.08 * pulse * intensity);
      canvas.drawCircle(offset, nodeSize * 2.5, _fillPaint);

      // Core
      _fillPaint.color = _green.withValues(alpha: 0.4 * pulse * intensity);
      canvas.drawCircle(offset, nodeSize, _fillPaint);

      // Center bright point
      _fillPaint.color = _white.withValues(alpha: 0.6 * pulse * intensity);
      canvas.drawCircle(offset, nodeSize * 0.3, _fillPaint);
    }
  }

  void _paintDataStreams(Canvas canvas, Size size) {
    for (int col = 0; col < _columns.length; col++) {
      final column = _columns[col];
      final x = column.x * size.width;
      final fontSize = (column.fontSize * intensity).roundToDouble();
      final charHeight = fontSize * 1.2;

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

        // Character changes over time (slowed to reduce cache thrashing)
        final charIndex =
            (_columnChars[col][i % _columnChars[col].length] + ((_phase * 5 + i * 0.3).floor())) % _chars.length;
        final char = _chars[charIndex];
        final textPainter = _getGlyphPainter(
          char: char,
          fontSize: fontSize,
          colorType: column.colorType,
          rowIndex: i,
          charCount: column.charCount,
          baseColor: baseColor,
        );
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
      }

      // Subtle glow on leading character (no blur for performance)
      final leadY = startY;
      if (leadY > -charHeight && leadY < size.height + charHeight) {
        _fillPaint.color = baseColor.withValues(alpha: 0.15 * intensity);
        canvas.drawCircle(Offset(x, leadY + charHeight / 2), column.fontSize * 1.2 * intensity, _fillPaint);
      }
    }
  }

  TextPainter _getGlyphPainter({
    required String char,
    required double fontSize,
    required int colorType,
    required int rowIndex,
    required int charCount,
    required Color baseColor,
  }) {
    final styleTier = _styleTierForRow(rowIndex, charCount);
    final key = _GlyphCacheKey(
      fontSize: fontSize.round(),
      styleTier: styleTier,
      colorType: colorType,
      charCode: char.codeUnitAt(0),
    );

    final cachedPainter = state.glyphCache[key];
    if (cachedPainter != null) {
      return cachedPainter;
    }

    // Evict cache when it grows too large
    if (state.glyphCache.length >= _maxGlyphCacheSize) {
      state.glyphCache.clear();
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: _colorForStyleTier(styleTier, baseColor),
          fontSize: fontSize,
          fontFamily: 'JetBrains Mono',
          fontWeight: _weightForStyleTier(styleTier),
        ),
      ),
    )..layout();

    state.glyphCache[key] = textPainter;
    return textPainter;
  }

  int _styleTierForRow(int rowIndex, int charCount) {
    if (rowIndex == 0) return 0;
    if (rowIndex == 1) return 1;
    if (rowIndex == 2) return 2;

    final positionInStream = rowIndex / charCount;
    return 3 + (positionInStream * 4).floor().clamp(0, 3);
  }

  FontWeight _weightForStyleTier(int styleTier) {
    switch (styleTier) {
      case 0:
        return FontWeight.bold;
      case 1:
      case 2:
        return FontWeight.w500;
      default:
        return FontWeight.normal;
    }
  }

  Color _colorForStyleTier(int styleTier, Color baseColor) {
    final opacity = switch (styleTier) {
      0 => 1.0,
      1 => 0.9,
      2 => 0.8,
      3 => 0.6,
      4 => 0.45,
      5 => 0.3,
      _ => 0.15,
    };

    if (styleTier == 0) {
      return _white.withValues(alpha: opacity * intensity);
    }

    return baseColor.withValues(alpha: opacity * intensity);
  }

  void _paintScanLine(Canvas canvas, Size size) {
    // Horizontal scan line moving down infinitely
    final scanY = (_phase * 2 % 1.0) * size.height;

    final scanGradient = ui.Gradient.linear(
      Offset(0, scanY - 30 * intensity),
      Offset(0, scanY + 30 * intensity),
      [
        Colors.transparent,
        _green.withValues(alpha: 0.1 * intensity),
        _green.withValues(alpha: 0.2 * intensity),
        _green.withValues(alpha: 0.1 * intensity),
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
    _strokePaint.color = _green.withValues(alpha: 0.4 * intensity);
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), _strokePaint);
  }

  void _paintGlowEffects(Canvas canvas, Size size) {
    // Corner accent glows (no blur, using larger radii with low opacity instead)
    final cornerGlow = math.sin(_phase * 2 * math.pi) * 0.3 + 0.7;

    _fillPaint.color = _green.withValues(alpha: 0.03 * cornerGlow * intensity);
    canvas.drawCircle(const Offset(0, 0), 140 * intensity, _fillPaint);
    canvas.drawCircle(Offset(size.width, size.height), 120 * intensity, _fillPaint);

    _fillPaint.color = _cyan.withValues(alpha: 0.02 * cornerGlow * intensity);
    canvas.drawCircle(Offset(size.width, 0), 100 * intensity, _fillPaint);
    canvas.drawCircle(Offset(0, size.height), 90 * intensity, _fillPaint);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.75;

    final vignette = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.transparent,
        _black.withValues(alpha: 0.4 * intensity),
        _black.withValues(alpha: 0.85 * intensity),
      ],
      const [0.3, 0.7, 1.0],
    );

    _fillPaint.shader = vignette;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _fillPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _DataStreamPainter oldDelegate) {
    return oldDelegate.animationEnabled != animationEnabled ||
        oldDelegate.intensity != intensity ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
