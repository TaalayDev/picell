part of 'effects.dart';

/// Applies directional motion blur along a velocity angle vector with
/// configurable trailing/symmetric/leading profiles while strictly preserving
/// layer transparency boundaries when [preserveAlpha] is enabled.
class DirectionalMotionBlurEffect extends Effect {
  DirectionalMotionBlurEffect([Map<String, dynamic>? params])
      : super(
          EffectType.directionalMotionBlur,
          params ??
              {
                'blurLength': 6.0,
                'angle': 0.0,
                'blurProfile': 'trailing',
                'intensity': 0.75,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'blurLength': 6.0,
        'angle': 0.0,
        'blurProfile': 'trailing',
        'intensity': 0.75,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'blurLength': {
          'label': 'Blur Streak Length',
          'description': 'Distance of velocity streak in pixels (1 to 24px).',
          'type': 'slider',
          'min': 1.0,
          'max': 24.0,
          'step': 1.0,
        },
        'angle': {
          'label': 'Motion Angle',
          'description': 'Direction of motion velocity in degrees (0° to 360°).',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'step': 5.0,
        },
        'blurProfile': {
          'label': 'Blur Profile',
          'description': 'Shape of the motion blur streak (trailing tail, symmetric, or leading head).',
          'type': 'dropdown',
          'options': [
            {'value': 'trailing', 'label': 'Trailing Tail (Sharp Front)'},
            {'value': 'symmetric', 'label': 'Symmetric (Centered)'},
            {'value': 'leading', 'label': 'Leading Head (Sharp Back)'},
          ],
        },
        'intensity': {
          'label': 'Streak Intensity',
          'description': 'Blend strength between original pixel and velocity blur.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine velocity streaks strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'blurLength',
          label: 'Blur Streak Length',
          description: 'Distance of velocity streak in pixels (1 to 24px).',
          min: 1.0,
          max: 24.0,
          divisions: 23,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'angle',
          label: 'Motion Angle',
          description: 'Direction of motion velocity in degrees (0° to 360°).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        const SelectField(
          key: 'blurProfile',
          label: 'Blur Profile',
          description: 'Shape of the motion blur streak (trailing tail, symmetric, or leading head).',
          options: {
            'trailing': 'Trailing Tail (Sharp Front)',
            'symmetric': 'Symmetric (Centered)',
            'leading': 'Leading Head (Sharp Back)',
          },
        ),
        SliderField(
          key: 'intensity',
          label: 'Streak Intensity',
          description: 'Blend strength between original pixel and velocity blur.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine velocity streaks strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final int length = ((parameters['blurLength'] as num?)?.toDouble() ?? 6.0).round().clamp(1, 24);
    final double angleDeg = ((parameters['angle'] as num?)?.toDouble() ?? 0.0) % 360.0;
    final String profile = parameters['blurProfile'] as String? ?? 'trailing';
    final double intensity = ((parameters['intensity'] as num?)?.toDouble() ?? 0.75).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final double rad = angleDeg * (math.pi / 180.0);
    final double dirX = math.cos(rad);
    final double dirY = math.sin(rad);

    // Precompute sample offsets and weights based on profile
    final List<double> stepOffsets = [];
    final List<double> stepWeights = [];

    if (profile == 'symmetric') {
      final int half = length ~/ 2;
      for (int s = -half; s <= half; s++) {
        stepOffsets.add(s.toDouble());
        final double dist = s.abs().toDouble();
        final double w = 1.0 - (dist / (half + 1.0));
        stepWeights.add(math.max(0.1, w));
      }
    } else if (profile == 'leading') {
      // Forward velocity streak
      for (int s = 0; s <= length; s++) {
        stepOffsets.add(s.toDouble());
        final double w = 1.0 - (s / (length + 1.0)) * 0.85;
        stepWeights.add(math.max(0.1, w));
      }
    } else {
      // 'trailing': sample backwards along motion vector so front stays crisp and drags tail
      for (int s = 0; s <= length; s++) {
        stepOffsets.add(-s.toDouble());
        final double w = 1.0 - (s / (length + 1.0)) * 0.85;
        stepWeights.add(math.max(0.1, w));
      }
    }

    final int numSamples = stepOffsets.length;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        double sumR = 0.0;
        double sumG = 0.0;
        double sumB = 0.0;
        double sumA = 0.0;
        double totalWeight = 0.0;

        for (int i = 0; i < numSamples; i++) {
          final double offset = stepOffsets[i];
          final double weight = stepWeights[i];

          final int sampleX = (x + dirX * offset).round();
          final int sampleY = (y + dirY * offset).round();

          if (sampleX >= 0 && sampleX < width && sampleY >= 0 && sampleY < height) {
            final int p = pixels[sampleY * width + sampleX];
            final int a = (p >> 24) & 0xFF;
            if (a > 0) {
              final double effectiveWeight = weight * (a / 255.0);
              sumR += ((p >> 16) & 0xFF) * effectiveWeight;
              sumG += ((p >> 8) & 0xFF) * effectiveWeight;
              sumB += (p & 0xFF) * effectiveWeight;
              sumA += a * weight;
              totalWeight += effectiveWeight;
            }
          }
        }

        if (totalWeight <= 0.001) {
          output[idx] = origPixel;
          continue;
        }

        final double blurredR = sumR / totalWeight;
        final double blurredG = sumG / totalWeight;
        final double blurredB = sumB / totalWeight;
        final double blurredA = sumA / stepWeights.reduce((a, b) => a + b);

        final int finalR = (origR * (1.0 - intensity) + blurredR * intensity).clamp(0.0, 255.0).round();
        final int finalG = (origG * (1.0 - intensity) + blurredG * intensity).clamp(0.0, 255.0).round();
        final int finalB = (origB * (1.0 - intensity) + blurredB * intensity).clamp(0.0, 255.0).round();

        int finalA;
        if (preserveAlpha) {
          finalA = origA;
        } else {
          finalA = (origA * (1.0 - intensity) + blurredA * intensity).clamp(0.0, 255.0).round();
        }

        if (finalA == 0) {
          output[idx] = 0;
        } else {
          output[idx] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
        }
      }
    }

    return output;
  }
}
