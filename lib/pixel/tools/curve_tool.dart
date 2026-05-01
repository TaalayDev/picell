import 'dart:ui';
import 'dart:math';

import '../pixel_point.dart';
import '../tools.dart';

/// Quadratic-Bézier curve tool.
///
/// Interaction model:
/// 1. Tap to set the **start** point.
/// 2. Tap (or tap-and-drag) to set the **end** point. While the second
///    pointer is down or hovering, the curve preview tracks the cursor as
///    the control point in real time.
/// 3. Final tap commits the curve at the chosen control point.
///
/// At any phase, switching tools or calling [reset] discards the in-progress
/// curve cleanly.
class CurveTool extends Tool {
  List<PixelPoint<int>> _currentPixels = [];

  // Curve state
  Offset? _startPoint;
  Offset? _endPoint;
  Offset? _controlPoint;
  bool _hasStartPoint = false;
  bool _hasEndPoint = false;
  bool _isDefiningCurve = false;

  CurveTool() : super(PixelTool.curve);

  bool get hasStartPoint => _hasStartPoint;
  bool get hasEndPoint => _hasEndPoint;
  bool get isDefiningCurve => _isDefiningCurve;
  Offset? get startPoint => _startPoint;
  Offset? get endPoint => _endPoint;
  Offset? get controlPoint => _controlPoint;

  /// Returns the phase the next [onStart] tap will execute, given the current
  /// state. Useful for callers that need to make decisions before delegating.
  CurveTapPhase get nextTapPhase {
    if (!_hasStartPoint) return CurveTapPhase.start;
    if (!_hasEndPoint) return CurveTapPhase.end;
    return CurveTapPhase.commit;
  }

  @override
  void onStart(PixelDrawDetails details) {
    final position = details.position;

    if (!_hasStartPoint) {
      _startPoint = position;
      _hasStartPoint = true;
      _currentPixels.clear();

      // Show the start anchor as a preview pixel (with stroke width applied
      // so it matches the eventual stroke).
      final pixelPos = details.pixelPosition;
      if (_isValidPoint(pixelPos, details.width, details.height)) {
        _currentPixels = _stampPoint(pixelPos, details);
        details.onPixelsUpdated(_currentPixels);
      }
    } else if (!_hasEndPoint) {
      _endPoint = position;
      _hasEndPoint = true;
      _isDefiningCurve = true;

      // Initialize control point to the midpoint of start→end so the user
      // sees a straight line preview before they move.
      final initialControl = Offset(
        (_startPoint!.dx + position.dx) / 2,
        (_startPoint!.dy + position.dy) / 2,
      );
      _updateCurvePreview(details, initialControl);
    } else {
      // Commit tap. Do NOT reassign the control point — the user has already
      // positioned it via hover/drag. The commit tap is purely a "done" signal
      // and tapping somewhere unrelated should not re-bend the curve.
      _finalizeCurve(details);
    }
  }

  /// Commits the curve at the current control point without changing it.
  /// Used by callers that want to commit on pointer-up after a drag without
  /// going through another [onStart] tap.
  void commit(PixelDrawDetails details) {
    if (!_hasStartPoint || !_hasEndPoint || !_isDefiningCurve) return;
    _finalizeCurve(details);
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (_hasStartPoint && _hasEndPoint && _isDefiningCurve) {
      _updateCurvePreview(details, details.position);
    }
  }

  @override
  void onEnd(PixelDrawDetails details) {}

  /// Aborts an in-progress curve and clears all state without committing.
  void cancel() => _reset();

  void _updateCurvePreview(PixelDrawDetails details, Offset currentPosition) {
    if (_startPoint == null || _endPoint == null) return;

    _controlPoint = currentPosition;

    final curvePoints = _generatePixelPerfectBezierCurve(
      _startPoint!,
      _controlPoint!,
      _endPoint!,
      details.size,
      details.width,
      details.height,
    );

    List<PixelPoint<int>> finalPixels = details.strokeWidth <= 1
        ? curvePoints.map((p) => PixelPoint(p.x, p.y, color: details.color.value)).toList()
        : _applyStrokeWidth(curvePoints, details);

    if (details.modifier != null) {
      final modifier = details.modifier!;
      final extra = <PixelPoint<int>>[];
      for (final point in finalPixels) {
        extra.addAll(modifier.apply(point, details.width, details.height));
      }
      finalPixels.addAll(extra);
    }

    _currentPixels = finalPixels;
    details.onPixelsUpdated(_currentPixels);
  }

  void _finalizeCurve(PixelDrawDetails details) {
    details.onPixelsUpdated(_currentPixels);
    _reset();
  }

  void _reset() {
    _startPoint = null;
    _endPoint = null;
    _controlPoint = null;
    _hasStartPoint = false;
    _hasEndPoint = false;
    _isDefiningCurve = false;
    _currentPixels = [];
  }

  /// Stamps a point with the current stroke width applied. Used for the
  /// start-anchor preview so the visual matches the eventual stroke.
  List<PixelPoint<int>> _stampPoint(PixelPoint<int> point, PixelDrawDetails details) {
    if (details.strokeWidth <= 1) {
      return [point.copyWith(color: details.color.value)];
    }
    return _applyStrokeWidth(
      [PixelPoint(point.x, point.y, color: details.color.value)],
      details,
    );
  }

  /// Generates pixel-perfect Bézier curve using adaptive sampling and line drawing
  List<PixelPoint<int>> _generatePixelPerfectBezierCurve(
    Offset start,
    Offset control,
    Offset end,
    Size canvasSize,
    int canvasWidth,
    int canvasHeight,
  ) {
    final pixelWidth = canvasSize.width / canvasWidth;
    final pixelHeight = canvasSize.height / canvasHeight;

    final startPixel = _screenToPixel(start, pixelWidth, pixelHeight);
    final controlPixel = _screenToPixel(control, pixelWidth, pixelHeight);
    final endPixel = _screenToPixel(end, pixelWidth, pixelHeight);

    final curvePixels = _adaptiveBezierSampling(startPixel, controlPixel, endPixel);
    final connectedPixels = _connectPixelsWithLines(curvePixels);
    final uniquePixels = _removeDuplicatePixels(connectedPixels);
    return uniquePixels.where((p) => _isValidPoint(p, canvasWidth, canvasHeight)).toList();
  }

  Point<int> _screenToPixel(Offset screenPos, double pixelWidth, double pixelHeight) {
    return Point<int>(
      (screenPos.dx / pixelWidth).round(),
      (screenPos.dy / pixelHeight).round(),
    );
  }

  List<PixelPoint<int>> _adaptiveBezierSampling(
    Point<int> start,
    Point<int> control,
    Point<int> end,
  ) {
    final points = <PixelPoint<int>>[];
    points.add(PixelPoint(start.x, start.y, color: 0));
    _subdivideQuadraticBezier(
      start.x.toDouble(), start.y.toDouble(),
      control.x.toDouble(), control.y.toDouble(),
      end.x.toDouble(), end.y.toDouble(),
      points,
      0.0, 1.0,
      tolerance: 0.5,
      maxDepth: 8,
    );
    return points;
  }

  void _subdivideQuadraticBezier(
    double x0, double y0,
    double x1, double y1,
    double x2, double y2,
    List<PixelPoint<int>> points,
    double t0, double t1, {
    required double tolerance,
    required int maxDepth,
  }) {
    if (maxDepth <= 0) {
      points.add(PixelPoint(x2.round(), y2.round(), color: 0));
      return;
    }

    final tMid = (t0 + t1) / 2;
    final midPoint = _evaluateQuadraticBezier(x0, y0, x1, y1, x2, y2, tMid);
    final linearMid = Point<double>((x0 + x2) / 2, (y0 + y2) / 2);
    final deviation = sqrt(pow(midPoint.x - linearMid.x, 2) + pow(midPoint.y - linearMid.y, 2));

    if (deviation <= tolerance) {
      points.add(PixelPoint(x2.round(), y2.round(), color: 0));
    } else {
      // De Casteljau split
      final q1 = Point<double>((x0 + x1) / 2, (y0 + y1) / 2);
      final q2 = Point<double>((x1 + x2) / 2, (y1 + y2) / 2);
      final r0 = Point<double>((q1.x + q2.x) / 2, (q1.y + q2.y) / 2);

      _subdivideQuadraticBezier(
        x0, y0, q1.x, q1.y, r0.x, r0.y,
        points, t0, tMid,
        tolerance: tolerance, maxDepth: maxDepth - 1,
      );
      _subdivideQuadraticBezier(
        r0.x, r0.y, q2.x, q2.y, x2, y2,
        points, tMid, t1,
        tolerance: tolerance, maxDepth: maxDepth - 1,
      );
    }
  }

  Point<double> _evaluateQuadraticBezier(
    double x0, double y0, double x1, double y1, double x2, double y2, double t,
  ) {
    final oneMinusT = 1 - t;
    final x = oneMinusT * oneMinusT * x0 + 2 * oneMinusT * t * x1 + t * t * x2;
    final y = oneMinusT * oneMinusT * y0 + 2 * oneMinusT * t * y1 + t * t * y2;
    return Point<double>(x, y);
  }

  List<PixelPoint<int>> _connectPixelsWithLines(List<PixelPoint<int>> curvePixels) {
    if (curvePixels.length <= 1) return curvePixels;

    final connected = <PixelPoint<int>>[curvePixels.first];
    for (int i = 1; i < curvePixels.length; i++) {
      final linePixels = _getBresenhamLine(curvePixels[i - 1], curvePixels[i]);
      for (int j = 1; j < linePixels.length; j++) {
        connected.add(linePixels[j]);
      }
    }
    return connected;
  }

  List<PixelPoint<int>> _getBresenhamLine(PixelPoint<int> start, PixelPoint<int> end) {
    final points = <PixelPoint<int>>[];
    int x0 = start.x, y0 = start.y, x1 = end.x, y1 = end.y;
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;

    while (true) {
      points.add(PixelPoint(x0, y0, color: 0));
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }
    return points;
  }

  List<PixelPoint<int>> _removeDuplicatePixels(List<PixelPoint<int>> pixels) {
    final seen = <int>{};
    final unique = <PixelPoint<int>>[];
    for (final p in pixels) {
      // Pack into a single int for cheap hashing.
      final key = (p.x << 20) ^ p.y;
      if (seen.add(key)) unique.add(p);
    }
    return unique;
  }

  List<PixelPoint<int>> _applyStrokeWidth(
    List<PixelPoint<int>> curvePoints,
    PixelDrawDetails details,
  ) {
    final out = <PixelPoint<int>>[];
    final added = <int>{};
    final halfStroke = details.strokeWidth ~/ 2;
    final radiusSq = halfStroke * halfStroke;
    final color = details.color.value;

    for (final point in curvePoints) {
      for (int dx = -halfStroke; dx <= halfStroke; dx++) {
        for (int dy = -halfStroke; dy <= halfStroke; dy++) {
          // Round brush — produces a smoother thick stroke than the square one.
          if (dx * dx + dy * dy > radiusSq) continue;
          final newX = point.x + dx;
          final newY = point.y + dy;
          final key = (newX << 20) ^ newY;
          if (!added.add(key)) continue;
          if (newX < 0 || newX >= details.width || newY < 0 || newY >= details.height) continue;
          out.add(PixelPoint(newX, newY, color: color));
        }
      }
    }
    return out;
  }

  bool _isValidPoint(PixelPoint<int> point, int width, int height) {
    return point.x >= 0 && point.x < width && point.y >= 0 && point.y < height;
  }
}

/// Phases of the curve-tool tap interaction.
enum CurveTapPhase { start, end, commit }
