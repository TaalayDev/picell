part of 'effects.dart';

/// Alters the brightness of pixels
class BrightnessEffect extends Effect {
  BrightnessEffect([Map<String, dynamic>? params]) : super(EffectType.brightness, params ?? {'value': 0.0});

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final value = parameters['value'] as double;
    final result = Uint32List(pixels.length);

    for (int i = 0; i < pixels.length; i++) {
      final a = (pixels[i] >> 24) & 0xFF;
      if (a == 0) {
        result[i] = 0; // Keep fully transparent pixels unchanged
        continue;
      }

      final r = (pixels[i] >> 16) & 0xFF;
      final g = (pixels[i] >> 8) & 0xFF;
      final b = pixels[i] & 0xFF;

      // Apply brightness adjustment
      final newR = (r + value * 255).clamp(0, 255).toInt();
      final newG = (g + value * 255).clamp(0, 255).toInt();
      final newB = (b + value * 255).clamp(0, 255).toInt();

      result[i] = (a << 24) | (newR << 16) | (newG << 8) | newB;
    }

    return result;
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {'value': 0.0}; // Range: -1.0 to 1.0
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'value': {
        'label': 'Brightness',
        'description':
            'Adjusts the brightness of pixels. Positive values make the image brighter, negative values make it darker.',
        'type': 'slider',
        'min': -1.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'value',
          label: 'Brightness',
          description:
              'Adjusts the brightness of pixels. Positive values make the image brighter, negative values make it darker.',
          min: -1.0,
          max: 1.0,
          divisions: 100,
        ),
      ];
}
