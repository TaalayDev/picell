import '../pixel_point.dart';
import '../tools.dart';

class EraserTool extends Tool {
  List<PixelPoint<int>> _currentPixels = [];
  PixelPoint<int>? _previousPoint;

  EraserTool() : super(PixelTool.eraser);

  @override
  void onStart(PixelDrawDetails details) {
    _currentPixels = [];
    _previousPoint = null;

    // Create eraser pixel with transparent color but mark it specially
    final point = details.pixelPosition.copyWith(color: 0x00000000); // Transparent
    if (_isValidPoint(point, details.width, details.height)) {
      _addPoint(point, details);
      _previousPoint = point;
      details.onPixelsUpdated(_currentPixels);
    }
  }

  @override
  void onMove(PixelDrawDetails details) {
    final point = details.pixelPosition.copyWith(color: 0x00000000); // Transparent

    if (_isValidPoint(point, details.width, details.height)) {
      if (_previousPoint != null) {
        final linePoints = _getLinePoints(_previousPoint!, point);
        for (final p in linePoints) {
          _addPixelPoints(p, details);
        }
      } else {
        _addPixelPoints(point, details);
      }
      _previousPoint = point;
    }
  }

  @override
  void onEnd(PixelDrawDetails details) {
    final point = details.pixelPosition.copyWith(color: 0x00000000);
    if (_previousPoint != null &&
        _previousPoint != point &&
        _isValidPoint(point, details.width, details.height)) {
      final linePoints = _getLinePoints(_previousPoint!, point);
      for (final p in linePoints) {
        _addPixelPoints(p, details);
      }
    }

    _currentPixels = [];
    _previousPoint = null;
  }

  bool _isValidPoint(PixelPoint<int> point, int width, int height) {
    return point.x >= 0 && point.x < width && point.y >= 0 && point.y < height;
  }

  void _addPixelPoints(PixelPoint<int> point, PixelDrawDetails details) {
    if (details.strokeWidth == 1) {
      _addPoint(point, details);
      details.onPixelsUpdated(_currentPixels);
    } else {
      final halfStroke = details.strokeWidth ~/ 2;
      for (var x = -halfStroke; x < halfStroke; x++) {
        for (var y = -halfStroke; y < halfStroke; y++) {
          final p = PixelPoint(
            point.x + x,
            point.y + y,
            color: 0x00000000, // Transparent for eraser
          );
          if (_isValidPoint(p, details.width, details.height)) {
            _addPoint(p, details);
          }
        }
      }
      details.onPixelsUpdated(_currentPixels);
    }
  }

  void _addPoint(PixelPoint<int> point, PixelDrawDetails details) {
    if (!_currentPixels.contains(point)) {
      _currentPixels.add(point);

      // Handle modifier
      if (details.modifier != null) {
        final modifier = details.modifier!;
        final modPoints = modifier.apply(
          point,
          details.width,
          details.height,
        );
        // Make sure modifier points are also transparent
        final eraserModPoints = modPoints.map((p) => PixelPoint(p.x, p.y, color: 0x00000000)).toList();
        _currentPixels.addAll(eraserModPoints);
      }
    }
  }

  List<PixelPoint<int>> _getLinePoints(
    PixelPoint<int> start,
    PixelPoint<int> end,
  ) {
    final points = <PixelPoint<int>>[];

    int x0 = start.x;
    int y0 = start.y;
    int x1 = end.x;
    int y1 = end.y;

    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;

    while (true) {
      points.add(PixelPoint(x0, y0, color: 0x00000000)); // Transparent

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
}
