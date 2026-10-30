import '../pixel_point.dart';
import '../tools.dart';

/// Real-time 1px contour outline modifier.
class OutlineModifier extends Modifier {
  final int outlineColor;
  final bool includeCorners;

  const OutlineModifier({
    this.outlineColor = 0xFF000000,
    this.includeCorners = false,
  }) : super(PixelModifier.outline);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    final points = <PixelPoint<int>>[];
    const offsets = [
      (0, -1),
      (0, 1),
      (-1, 0),
      (1, 0),
    ];
    const cornerOffsets = [
      (-1, -1),
      (1, -1),
      (-1, 1),
      (1, 1),
    ];

    for (final (dx, dy) in offsets) {
      final nx = point.x + dx;
      final ny = point.y + dy;
      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        points.add(PixelPoint(nx, ny, color: outlineColor));
      }
    }

    if (includeCorners) {
      for (final (dx, dy) in cornerOffsets) {
        final nx = point.x + dx;
        final ny = point.y + dy;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          points.add(PixelPoint(nx, ny, color: outlineColor));
        }
      }
    }

    return points;
  }
}
