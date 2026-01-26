part of 'effects.dart';

class OpacityEffect extends Effect {
  OpacityEffect([Map<String, dynamic>? parameters]) : super(EffectType.opacity, parameters ?? {'opacity': 0.5});

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final opacity = (parameters['opacity'] as num?)?.toDouble() ?? 0.5;

    if (opacity >= 1.0) return Uint32List.fromList(pixels);

    final result = Uint32List.fromList(pixels);

    for (int i = 0; i < result.length; i++) {
      final pixel = result[i];
      if (pixel == 0) continue;

      int a = (pixel >> 24) & 0xFF;
      int r = (pixel >> 16) & 0xFF;
      int g = (pixel >> 8) & 0xFF;
      int b = pixel & 0xFF;

      // Apply multiplier to existing alpha
      a = (a * opacity).round().clamp(0, 255);

      result[i] = (a << 24) | (r << 16) | (g << 8) | b;
    }

    return result;
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'opacity': 0.5,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'opacity': {'min': 0.0, 'max': 1.0, 'label': 'Opacity'},
    };
  }
}
