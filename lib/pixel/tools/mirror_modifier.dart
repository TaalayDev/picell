import '../pixel_point.dart';
import '../tools.dart';

class MirrorModifier extends Modifier {
  final MirrorAxis axis;

  MirrorModifier(this.axis) : super(PixelModifier.mirror);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    switch (axis) {
      case MirrorAxis.horizontal:
        final mirrorY = height - 1 - point.y;
        return [PixelPoint(point.x, mirrorY, color: point.color)];

      case MirrorAxis.vertical:
        final mirrorX = width - 1 - point.x;
        return [PixelPoint(mirrorX, point.y, color: point.color)];

      case MirrorAxis.both:
        final mirrorX = width - 1 - point.x;
        final mirrorY = height - 1 - point.y;
        return [
          PixelPoint(mirrorX, point.y, color: point.color),
          PixelPoint(point.x, mirrorY, color: point.color),
          PixelPoint(mirrorX, mirrorY, color: point.color),
        ];
    }
  }
}
