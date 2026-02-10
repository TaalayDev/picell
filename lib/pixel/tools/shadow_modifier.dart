import 'dart:math';
import 'package:flutter/material.dart';
import 'package:picell/pixel/tools.dart';

import '../pixel_point.dart';

class ShadowModifier extends Modifier {
  final int offsetX;
  final int offsetY;
  final double intensity;
  final int spread;
  final bool softShadow;

  const ShadowModifier({
    this.offsetX = 1,
    this.offsetY = 1,
    this.intensity = 0.5,
    this.spread = 1,
    this.softShadow = true,
  }) : super(PixelModifier.shadow);

  @override
  List<PixelPoint<int>> apply(PixelPoint<int> point, int width, int height) {
    final points = <PixelPoint<int>>[];

    // Add the original pixel first
    points.add(point);

    // Calculate base shadow position
    final shadowX = point.x + offsetX;
    final shadowY = point.y + offsetY;

    // If out of bounds, just return original point
    if (shadowX < 0 || shadowX >= width || shadowY < 0 || shadowY >= height) {
      return points;
    }

    if (softShadow) {
      // Create soft shadow with spread
      for (int dy = -spread; dy <= spread; dy++) {
        for (int dx = -spread; dx <= spread; dx++) {
          final newX = shadowX + dx;
          final newY = shadowY + dy;

          // Skip if out of bounds
          if (newX < 0 || newX >= width || newY < 0 || newY >= height) {
            continue;
          }

          // Calculate distance from shadow center for alpha
          final distance = sqrt(dx * dx + dy * dy);
          if (distance > spread) continue;

          // Create shadow pixel with calculated alpha
          points.add(PixelPoint(
            newX,
            newY,
            color: _createShadowColor(),
          ));
        }
      }
    } else {
      points.add(PixelPoint(
        shadowX,
        shadowY,
        color: _createShadowColor(),
      ));
    }

    return points;
  }

  int _createShadowColor() {
    return Colors.black.value;
  }

  @override
  bool get isNone => false;

  @override
  bool get isMirror => false;

  ShadowModifier copyWith({
    int? offsetX,
    int? offsetY,
    double? intensity,
    int? spread,
    bool? softShadow,
  }) {
    return ShadowModifier(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      intensity: intensity ?? this.intensity,
      spread: spread ?? this.spread,
      softShadow: softShadow ?? this.softShadow,
    );
  }
}

/// Extension to add shadow-specific utilities for colors
extension ShadowColorUtils on int {
  /// Creates a shadow version of the color
  int toShadowColor(double opacity) {
    final alpha = (opacity * 255).round().clamp(0, 255);
    return (alpha << 24); // Black color with specified alpha
  }

  /// Darkens the color by a specified amount
  int darken(double amount) {
    final r = ((this >> 16) & 0xFF);
    final g = ((this >> 8) & 0xFF);
    final b = (this & 0xFF);

    final newR = (r * (1 - amount)).round().clamp(0, 255);
    final newG = (g * (1 - amount)).round().clamp(0, 255);
    final newB = (b * (1 - amount)).round().clamp(0, 255);

    return (0xFF << 24) | (newR << 16) | (newG << 8) | newB;
  }
}
