import 'dart:ui';

import 'gradient_renderer.dart';

/// Which pixels a gradient may paint (always intersected with the selection).
enum GradientTarget {
  /// Every pixel of the layer.
  layer,

  /// The 4-connected same-colour area under the gradient start point.
  contiguous,
}

/// User-facing gradient tool settings. Combined with the primary colour and
/// the drag endpoints to produce a [GradientSpec].
class GradientOptions {
  final GradientType type;
  final GradientTarget target;

  /// Colour the ramp ends on; the ramp starts on the primary colour.
  final Color endColor;

  /// Optional explicit ramp (e.g. palette colours) replacing
  /// primary → [endColor].
  final List<Color>? stops;

  final int? steps;
  final GradientDither dither;
  final double ditherSpread;
  final GradientBlend blend;

  const GradientOptions({
    this.type = GradientType.linear,
    this.target = GradientTarget.layer,
    this.endColor = const Color(0x00000000),
    this.stops,
    this.steps,
    this.dither = GradientDither.none,
    this.ditherSpread = 1.0,
    this.blend = GradientBlend.over,
  });

  GradientSpec toSpec({
    required Offset start,
    required Offset end,
    required Color primary,
  }) {
    final ramp = stops ?? [primary, endColor];
    return GradientSpec(
      type: type,
      start: start,
      end: end,
      stops: [for (final c in ramp) c.toARGB32()],
      steps: steps,
      dither: dither,
      ditherSpread: ditherSpread,
      blend: blend,
    );
  }

  GradientOptions copyWith({
    GradientType? type,
    GradientTarget? target,
    Color? endColor,
    List<Color>? stops,
    bool clearStops = false,
    int? steps,
    bool smooth = false,
    GradientDither? dither,
    double? ditherSpread,
    GradientBlend? blend,
  }) {
    return GradientOptions(
      type: type ?? this.type,
      target: target ?? this.target,
      endColor: endColor ?? this.endColor,
      stops: clearStops ? null : (stops ?? this.stops),
      steps: smooth ? null : (steps ?? this.steps),
      dither: dither ?? this.dither,
      ditherSpread: ditherSpread ?? this.ditherSpread,
      blend: blend ?? this.blend,
    );
  }
}
