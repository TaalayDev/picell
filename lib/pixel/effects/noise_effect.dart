part of 'effects.dart';

/// Adds random noise to pixels
class NoiseEffect extends Effect {
  NoiseEffect([Map<String, dynamic>? params]) : super(EffectType.noise, params ?? {'amount': 0.1});

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final amount = parameters['amount'] as double;
    final result = Uint32List(pixels.length);
    final random = Random(42);

    for (int i = 0; i < pixels.length; i++) {
      // Consume values for transparent pixels too, so adding a new pixel does
      // not change the noise pattern on pixels that were already painted.
      final noiseR = (random.nextDouble() * 2 - 1) * amount * 255;
      final noiseG = (random.nextDouble() * 2 - 1) * amount * 255;
      final noiseB = (random.nextDouble() * 2 - 1) * amount * 255;
      final a = (pixels[i] >> 24) & 0xFF;
      if (a == 0) {
        result[i] = 0; // Keep fully transparent pixels unchanged
        continue;
      }

      final r = (pixels[i] >> 16) & 0xFF;
      final g = (pixels[i] >> 8) & 0xFF;
      final b = pixels[i] & 0xFF;

      // Apply noise
      final newR = (r + noiseR).round().clamp(0, 255);
      final newG = (g + noiseG).round().clamp(0, 255);
      final newB = (b + noiseB).round().clamp(0, 255);

      result[i] = (a << 24) | (newR << 16) | (newG << 8) | newB;
    }

    return result;
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {'amount': 0.1}; // Range: 0.0 to 1.0
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'amount': {
        'label': 'Amount',
        'description': 'Controls the strength of the noise effect. 0 = no noise, 1 = maximum noise.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }
}
