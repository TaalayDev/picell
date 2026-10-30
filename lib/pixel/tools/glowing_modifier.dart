import 'dart:math';
import '../pixel_point.dart';
import '../tools.dart';

class GlowModifier extends Modifier {
  final int radius;
  final double intensity;
  final int? glowColor;

  const GlowModifier({
    this.radius = 2,
    this.intensity = 0.5,
    this.glowColor,
  }) : super(PixelModifier.glow);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    final points = <PixelPoint<int>>[];
    final baseColor = glowColor ?? point.color;
    final r = (baseColor >> 16) & 0xFF;
    final g = (baseColor >> 8) & 0xFF;
    final b = baseColor & 0xFF;
    final a = (baseColor >> 24) & 0xFF;

    // Calculate glow effect around the center point (excluding the center point itself)
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx == 0 && dy == 0) continue;

        // Calculate distance from center
        final distance = sqrt(dx * dx + dy * dy);
        if (distance > radius) continue;

        final newX = point.x + dx;
        final newY = point.y + dy;

        // Bounds check
        if (newX < 0 || newX >= width || newY < 0 || newY >= height) continue;

        // Radial falloff: closest to center gets highest intensity
        final falloff = (1.0 - (distance / (radius + 1.0))) * intensity;
        final alpha = (a * falloff).round().clamp(0, 255);
        if (alpha <= 0) continue;

        final color = (alpha << 24) | (r << 16) | (g << 8) | b;
        points.add(PixelPoint(newX, newY, color: color));
      }
    }

    return points;
  }

  GlowModifier copyWith({
    int? radius,
    double? intensity,
    int? glowColor,
  }) {
    return GlowModifier(
      radius: radius ?? this.radius,
      intensity: intensity ?? this.intensity,
      glowColor: glowColor ?? this.glowColor,
    );
  }
}
