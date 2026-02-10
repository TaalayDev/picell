import 'dart:math';
import 'dart:ui';
import 'package:picell/pixel/tools.dart';

import '../pixel_point.dart';

class GlowModifier extends Modifier {
  final int radius;
  final double intensity;

  const GlowModifier({
    this.radius = 2,
    this.intensity = 0.5,
  }) : super(PixelModifier.glow);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    final points = <PixelPoint<int>>[];

    // Add the original point first
    points.add(point);

    // Calculate glow effect
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        // Skip the center point as we already added it
        if (dx == 0 && dy == 0) continue;

        // Calculate distance from center
        final distance = sqrt(dx * dx + dy * dy);
        if (distance > radius) continue;

        // Calculate new position
        final newX = point.x + dx;
        final newY = point.y + dy;

        // Check bounds
        if (newX < 0 || newX >= width || newY < 0 || newY >= height) continue;

        // Calculate alpha based on distance
        final originalColor = Color(point.color);

        final shifted = Color(0xFFFF0000);

        points.add(PixelPoint(
          newX,
          newY,
          color: shifted.value,
        ));
      }
    }

    return points;
  }

  @override
  bool get isNone => false;

  @override
  bool get isMirror => false;

  GlowModifier copyWith({
    int? radius,
    double? intensity,
  }) {
    return GlowModifier(
      radius: radius ?? this.radius,
      intensity: intensity ?? this.intensity,
    );
  }
}
