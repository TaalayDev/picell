import 'dart:math';
import '../pixel_point.dart';
import '../tools.dart';

/// Real-time directional drop-shadow modifier.
class ShadowModifier extends Modifier {
  final int offsetX;
  final int offsetY;
  final double intensity;
  final int spread;
  final bool softShadow;
  final int? shadowColor;

  const ShadowModifier({
    this.offsetX = 1,
    this.offsetY = 1,
    this.intensity = 0.5,
    this.spread = 0,
    this.softShadow = false,
    this.shadowColor,
  }) : super(PixelModifier.shadow);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    final points = <PixelPoint<int>>[];
    final sx = point.x + offsetX;
    final sy = point.y + offsetY;
    final baseColor = shadowColor ?? _computeShadowColor(point.color);

    if (!softShadow || spread <= 0) {
      if (sx >= 0 && sx < width && sy >= 0 && sy < height) {
        points.add(PixelPoint(sx, sy, color: baseColor));
      }
      return points;
    }

    for (int dy = -spread; dy <= spread; dy++) {
      for (int dx = -spread; dx <= spread; dx++) {
        final nx = sx + dx;
        final ny = sy + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > spread) continue;
        final alphaFactor = 1.0 - (dist / (spread + 1.0));
        final color = _tintAlpha(baseColor, alphaFactor * intensity);
        points.add(PixelPoint(nx, ny, color: color));
      }
    }

    return points;
  }

  int _computeShadowColor(int sourceColor) {
    final r = ((sourceColor >> 16) & 0xFF) ~/ 3;
    final g = ((sourceColor >> 8) & 0xFF) ~/ 3;
    final b = (sourceColor & 0xFF) ~/ 3;
    final a = (255 * intensity).round().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  int _tintAlpha(int color, double factor) {
    final curAlpha = (color >> 24) & 0xFF;
    final newAlpha = (curAlpha * factor).round().clamp(0, 255);
    return (newAlpha << 24) | (color & 0x00FFFFFF);
  }

  ShadowModifier copyWith({
    int? offsetX,
    int? offsetY,
    double? intensity,
    int? spread,
    bool? softShadow,
    int? shadowColor,
  }) {
    return ShadowModifier(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      intensity: intensity ?? this.intensity,
      spread: spread ?? this.spread,
      softShadow: softShadow ?? this.softShadow,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }
}
