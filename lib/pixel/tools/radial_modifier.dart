import '../pixel_point.dart';
import '../tools.dart';

enum RadialSymmetryMode { fourFold, eightFold }

/// Multi-fold radial and kaleidoscope symmetry modifier.
class RadialModifier extends Modifier {
  final RadialSymmetryMode mode;

  const RadialModifier({this.mode = RadialSymmetryMode.eightFold})
      : super(PixelModifier.radial);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    final points = <PixelPoint<int>>[];
    final visited = <int>{point.y * width + point.x};

    void tryAdd(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      if (visited.add(y * width + x)) {
        points.add(PixelPoint(x, y, color: point.color));
      }
    }

    final mx = width - 1 - point.x;
    final my = height - 1 - point.y;

    // 4-fold cross reflection (horizontal, vertical, opposite quadrant)
    tryAdd(mx, point.y);
    tryAdd(point.x, my);
    tryAdd(mx, my);

    if (mode == RadialSymmetryMode.eightFold) {
      // 8-fold radial symmetry around the center of the canvas
      final cx = (width - 1) / 2.0;
      final cy = (height - 1) / 2.0;
      final dx = point.x - cx;
      final dy = point.y - cy;

      tryAdd((cx + dy).round(), (cy + dx).round());
      tryAdd((cx - dy).round(), (cy - dx).round());
      tryAdd((cx + dy).round(), (cy - dx).round());
      tryAdd((cx - dy).round(), (cy + dx).round());
    }

    return points;
  }
}
