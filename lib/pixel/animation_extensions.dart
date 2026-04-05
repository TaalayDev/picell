import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../core/extensions/offset_extensions.dart';
import '../data.dart';
import 'pixel_canvas_state.dart';
import 'pixel_point.dart';
import 'tools.dart';

// Animation effect extensions
extension AnimationEffects on AnimationFrame {
  /// Create a motion blur effect for the frame
  AnimationFrame withMotionBlur({
    required Offset direction,
    double intensity = 1.0,
    required int width,
    required int height,
  }) {
    final blurredLayers = layers.map((layer) {
      return layer.copyWith(
        pixels: _applyMotionBlur(
          layer.pixels,
          width: width,
          height: height,
          direction: direction,
          intensity: intensity,
        ),
      );
    }).toList();

    return copyWith(layers: blurredLayers);
  }

  /// Apply fade effect to the frame
  AnimationFrame withFade(double opacity) {
    final fadedLayers = layers.map((layer) {
      return layer.copyWith(
        pixels: _applyFade(layer.pixels, opacity),
      );
    }).toList();

    return copyWith(layers: fadedLayers);
  }

  /// Apply scale effect to the frame
  AnimationFrame withScale({
    required double scaleX,
    required double scaleY,
    required int width,
    required int height,
  }) {
    final scaledLayers = layers.map((layer) {
      return layer.copyWith(
        pixels: _applyScale(
          layer.pixels,
          width: width,
          height: height,
          scaleX: scaleX,
          scaleY: scaleY,
        ),
      );
    }).toList();

    return copyWith(layers: scaledLayers);
  }

  Uint32List _applyMotionBlur(
    Uint32List pixels, {
    required int width,
    required int height,
    required Offset direction,
    required double intensity,
  }) {
    final blurredPixels = Uint32List(pixels.length);
    final blurLength = (intensity * 3).round();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final originalPixel = pixels[index];

        if (originalPixel != 0) {
          int totalR = 0, totalG = 0, totalB = 0, totalA = 0;
          int count = 0;

          for (int i = 0; i <= blurLength; i++) {
            final sampleX = x + (direction.dx * i / blurLength).round();
            final sampleY = y + (direction.dy * i / blurLength).round();

            if (sampleX >= 0 && sampleX < width && sampleY >= 0 && sampleY < height) {
              final sampleIndex = sampleY * width + sampleX;
              final samplePixel = pixels[sampleIndex];

              if (samplePixel != 0) {
                final color = Color(samplePixel);
                totalR += color.red;
                totalG += color.green;
                totalB += color.blue;
                totalA += color.alpha;
                count++;
              }
            }
          }

          if (count > 0) {
            final avgColor = Color.fromARGB(
              totalA ~/ count,
              totalR ~/ count,
              totalG ~/ count,
              totalB ~/ count,
            );
            blurredPixels[index] = avgColor.value;
          } else {
            blurredPixels[index] = originalPixel;
          }
        }
      }
    }

    return blurredPixels;
  }

  Uint32List _applyFade(Uint32List pixels, double opacity) {
    final fadedPixels = Uint32List(pixels.length);

    for (int i = 0; i < pixels.length; i++) {
      final pixel = pixels[i];
      if (pixel != 0) {
        final color = Color(pixel);
        final fadedColor = color.withValues(alpha: color.opacity * opacity);
        fadedPixels[i] = fadedColor.value;
      }
    }

    return fadedPixels;
  }

  Uint32List _applyScale(
    Uint32List pixels, {
    required int width,
    required int height,
    required double scaleX,
    required double scaleY,
  }) {
    final scaledPixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final sourceX = (x / scaleX).floor();
        final sourceY = (y / scaleY).floor();

        if (sourceX >= 0 && sourceX < width && sourceY >= 0 && sourceY < height) {
          final sourceIndex = sourceY * width + sourceX;
          final targetIndex = y * width + x;
          scaledPixels[targetIndex] = pixels[sourceIndex];
        }
      }
    }

    return scaledPixels;
  }
}

// Custom animation curves
class CustomCurves {
  static const Curve swing = _SwingCurve();
  static const Curve wobble = _WobbleCurve();
  static const Curve pulse = _PulseCurve();
  static const Curve shake = _ShakeCurve();
}

class _SwingCurve extends Curve {
  const _SwingCurve();

  @override
  double transformInternal(double t) {
    return 0.5 * (1 + math.sin((t * math.pi) - math.pi / 2));
  }
}

class _WobbleCurve extends Curve {
  const _WobbleCurve();

  @override
  double transformInternal(double t) {
    return math.sin(t * math.pi * 4) * math.exp(-t * 2);
  }
}

class _PulseCurve extends Curve {
  const _PulseCurve();

  @override
  double transformInternal(double t) {
    return 0.5 * (1 + math.sin(t * math.pi * 8));
  }
}

class _ShakeCurve extends Curve {
  const _ShakeCurve();

  @override
  double transformInternal(double t) {
    return math.sin(t * math.pi * 16) * (1 - t);
  }
}

// Animation path generators
class AnimationPath {
  static List<Offset> generateCircularPath({
    required Offset center,
    required double radius,
    required int steps,
    double startAngle = 0,
  }) {
    final points = <Offset>[];

    for (int i = 0; i < steps; i++) {
      final angle = startAngle + (i / steps) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      points.add(Offset(x, y));
    }

    return points;
  }

  static List<Offset> generateSpiralPath({
    required Offset center,
    required double startRadius,
    required double endRadius,
    required int steps,
    required double turns,
  }) {
    final points = <Offset>[];

    for (int i = 0; i < steps; i++) {
      final t = i / (steps - 1);
      final angle = t * turns * 2 * math.pi;
      final radius = startRadius + (endRadius - startRadius) * t;

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      points.add(Offset(x, y));
    }

    return points;
  }

  static List<Offset> generateWavePath({
    required Offset start,
    required Offset end,
    required double amplitude,
    required double frequency,
    required int steps,
  }) {
    final points = <Offset>[];
    final direction = end - start;
    final perpendicular = Offset(-direction.dy, direction.dx).normalized();

    for (int i = 0; i < steps; i++) {
      final t = i / (steps - 1);
      final basePoint = start + direction * t;
      final waveOffset = amplitude * math.sin(t * frequency * 2 * math.pi);
      final point = basePoint + perpendicular * waveOffset;
      points.add(point);
    }

    return points;
  }

  static List<Offset> generateBezierPath({
    required Offset start,
    required Offset control1,
    required Offset control2,
    required Offset end,
    required int steps,
  }) {
    final points = <Offset>[];

    for (int i = 0; i < steps; i++) {
      final t = i / (steps - 1);
      final point = _evaluateCubicBezier(start, control1, control2, end, t);
      points.add(point);
    }

    return points;
  }

  static Offset _evaluateCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final oneMinusT = 1 - t;
    final oneMinusT2 = oneMinusT * oneMinusT;
    final oneMinusT3 = oneMinusT2 * oneMinusT;
    final t2 = t * t;
    final t3 = t2 * t;

    return p0 * oneMinusT3 + p1 * (3 * oneMinusT2 * t) + p2 * (3 * oneMinusT * t2) + p3 * t3;
  }
}

// Animation presets
class AnimationPreset {
  final String name;
  final String description;
  final Curve curve;
  final int defaultFrameCount;
  final List<AnimationKeyframe> keyframes;

  const AnimationPreset({
    required this.name,
    required this.description,
    required this.curve,
    required this.defaultFrameCount,
    required this.keyframes,
  });

  static const List<AnimationPreset> presets = [
    AnimationPreset(
      name: 'Fade In',
      description: 'Gradually appears',
      curve: Curves.easeIn,
      defaultFrameCount: 10,
      keyframes: [
        AnimationKeyframe(time: 0.0, opacity: 0.0),
        AnimationKeyframe(time: 1.0, opacity: 1.0),
      ],
    ),
    AnimationPreset(
      name: 'Slide In',
      description: 'Slides in from the left',
      curve: Curves.easeOut,
      defaultFrameCount: 12,
      keyframes: [
        AnimationKeyframe(time: 0.0, translateX: -100.0),
        AnimationKeyframe(time: 1.0, translateX: 0.0),
      ],
    ),
    AnimationPreset(
      name: 'Scale Up',
      description: 'Grows from small to normal size',
      curve: Curves.elasticOut,
      defaultFrameCount: 15,
      keyframes: [
        AnimationKeyframe(time: 0.0, scaleX: 0.0, scaleY: 0.0),
        AnimationKeyframe(time: 1.0, scaleX: 1.0, scaleY: 1.0),
      ],
    ),
    AnimationPreset(
      name: 'Rotate',
      description: 'Full 360 degree rotation',
      curve: Curves.linear,
      defaultFrameCount: 24,
      keyframes: [
        AnimationKeyframe(time: 0.0, rotation: 0.0),
        AnimationKeyframe(time: 1.0, rotation: 2 * math.pi),
      ],
    ),
    AnimationPreset(
      name: 'Bounce',
      description: 'Bouncing animation',
      curve: Curves.bounceOut,
      defaultFrameCount: 20,
      keyframes: [
        AnimationKeyframe(time: 0.0, translateY: -50.0),
        AnimationKeyframe(time: 1.0, translateY: 0.0),
      ],
    ),
    AnimationPreset(
      name: 'Wobble',
      description: 'Shaky wobble effect',
      curve: CustomCurves.wobble,
      defaultFrameCount: 16,
      keyframes: [
        AnimationKeyframe(time: 0.0, rotation: -0.1),
        AnimationKeyframe(time: 1.0, rotation: 0.0),
      ],
    ),
  ];
}

class AnimationKeyframe {
  final double time; // 0.0 to 1.0
  final double? translateX;
  final double? translateY;
  final double? scaleX;
  final double? scaleY;
  final double? rotation;
  final double? opacity;

  const AnimationKeyframe({
    required this.time,
    this.translateX,
    this.translateY,
    this.scaleX,
    this.scaleY,
    this.rotation,
    this.opacity,
  });
}
