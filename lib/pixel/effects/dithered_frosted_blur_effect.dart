part of 'effects.dart';

/// Applies dithered dispersion and frosted glass blurring using ordered Bayer
/// matrices, stochastic jitter, and channel quantization to soften pixel art
/// without producing blurry non-palette bilinear artifacts.
class DitheredFrostedBlurEffect extends Effect {
  DitheredFrostedBlurEffect([Map<String, dynamic>? params])
      : super(
          EffectType.ditheredFrostedBlur,
          params ??
              {
                'diffusionRadius': 3.0,
                'ditherPattern': 'bayer4x4',
                'colorQuantization': 8.0,
                'intensity': 0.8,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'diffusionRadius': 3.0,
        'ditherPattern': 'bayer4x4',
        'colorQuantization': 8.0,
        'intensity': 0.8,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'diffusionRadius': {
          'label': 'Diffusion Radius',
          'description': 'Maximum distance of dithered pixel scattering.',
          'type': 'slider',
          'min': 1.0,
          'max': 8.0,
          'step': 0.5,
        },
        'ditherPattern': {
          'label': 'Dither Pattern',
          'description': 'Dispersion algorithm: Bayer matrix, blue-noise stochastic, or crosshatch.',
          'type': 'dropdown',
          'options': [
            {'value': 'bayer4x4', 'label': 'Ordered Bayer 4x4 (Retro Halftone)'},
            {'value': 'stochasticNoise', 'label': 'Stochastic Jitter (Frosted Glass)'},
            {'value': 'crosshatch', 'label': 'Diagonal Crosshatch (Wax Rubbing)'},
          ],
        },
        'colorQuantization': {
          'label': 'Color Quantization',
          'description': 'Number of tonal steps per color channel to retain crisp palette integrity.',
          'type': 'slider',
          'min': 2.0,
          'max': 32.0,
          'step': 1.0,
        },
        'intensity': {
          'label': 'Diffusion Intensity',
          'description': 'Strength of the frosted scattering blend.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine dither diffusion strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'diffusionRadius',
          label: 'Diffusion Radius',
          description: 'Maximum distance of dithered pixel scattering.',
          min: 1.0,
          max: 8.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'ditherPattern',
          label: 'Dither Pattern',
          description: 'Dispersion algorithm: Bayer matrix, blue-noise stochastic, or crosshatch.',
          options: {
            'bayer4x4': 'Ordered Bayer 4x4 (Retro Halftone)',
            'stochasticNoise': 'Stochastic Jitter (Frosted Glass)',
            'crosshatch': 'Diagonal Crosshatch (Wax Rubbing)',
          },
        ),
        SliderField(
          key: 'colorQuantization',
          label: 'Color Quantization',
          description: 'Number of tonal steps per color channel to retain crisp palette integrity.',
          min: 2.0,
          max: 32.0,
          divisions: 30,
          formatLabel: (v) => '${v.round()} steps',
        ),
        SliderField(
          key: 'intensity',
          label: 'Diffusion Intensity',
          description: 'Strength of the frosted scattering blend.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine dither diffusion strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  static const List<int> _bayer4x4 = [
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5,
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double radius = ((parameters['diffusionRadius'] as num?)?.toDouble() ?? 3.0).clamp(1.0, 8.0);
    final String pattern = parameters['ditherPattern'] as String? ?? 'bayer4x4';
    final int quantSteps = ((parameters['colorQuantization'] as num?)?.toDouble() ?? 8.0).round().clamp(2, 32);
    final double intensity = ((parameters['intensity'] as num?)?.toDouble() ?? 0.8).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final double quantStepSize = 255.0 / (quantSteps - 1.0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        int offsetX = 0;
        int offsetY = 0;

        if (pattern == 'crosshatch') {
          // 45-degree alternating diagonal lattice
          final int phase = (x + y) & 3;
          final int rInt = radius.round().clamp(1, 8);
          switch (phase) {
            case 0:
              offsetX = rInt;
              offsetY = rInt;
              break;
            case 1:
              offsetX = -rInt;
              offsetY = rInt;
              break;
            case 2:
              offsetX = -rInt;
              offsetY = -rInt;
              break;
            case 3:
              offsetX = rInt;
              offsetY = -rInt;
              break;
          }
        } else if (pattern == 'stochasticNoise') {
          // Blue-noise jitter
          final double h1 = _hash(x * 43 + y * 97 + 19);
          final double h2 = _hash(x * 89 + y * 53 + 137);
          final double theta = h1 * 2.0 * math.pi;
          final double r = math.sqrt(h2) * radius;
          offsetX = (r * math.cos(theta)).round();
          offsetY = (r * math.sin(theta)).round();
        } else {
          // 'bayer4x4' ordered matrix
          final int bx = x & 3;
          final int by = y & 3;
          final int bVal = _bayer4x4[by * 4 + bx];
          final double normB = (bVal / 15.0) - 0.5; // -0.5 to +0.5
          final double theta = bVal * (math.pi / 8.0);
          final double r = normB.abs() * 2.0 * radius;
          offsetX = (r * math.cos(theta)).round();
          offsetY = (r * math.sin(theta)).round();
        }

        final int sampleX = (x + offsetX).clamp(0, width - 1);
        final int sampleY = (y + offsetY).clamp(0, height - 1);
        final int samplePixel = pixels[sampleY * width + sampleX];
        final int sampleA = (samplePixel >> 24) & 0xFF;

        int finalR;
        int finalG;
        int finalB;
        int finalA;

        if (sampleA == 0 && preserveAlpha) {
          // Sampled an empty pixel; fallback to original pixel
          finalR = (origPixel >> 16) & 0xFF;
          finalG = (origPixel >> 8) & 0xFF;
          finalB = origPixel & 0xFF;
          finalA = origA;
        } else {
          final int origR = (origPixel >> 16) & 0xFF;
          final int origG = (origPixel >> 8) & 0xFF;
          final int origB = origPixel & 0xFF;

          final int sR = (samplePixel >> 16) & 0xFF;
          final int sG = (samplePixel >> 8) & 0xFF;
          final int sB = samplePixel & 0xFF;

          final double blendedR = origR * (1.0 - intensity) + sR * intensity;
          final double blendedG = origG * (1.0 - intensity) + sG * intensity;
          final double blendedB = origB * (1.0 - intensity) + sB * intensity;

          // Color quantization to preserve retro pixel-art palette feel
          finalR = ((blendedR / quantStepSize).round() * quantStepSize).round().clamp(0, 255);
          finalG = ((blendedG / quantStepSize).round() * quantStepSize).round().clamp(0, 255);
          finalB = ((blendedB / quantStepSize).round() * quantStepSize).round().clamp(0, 255);

          if (preserveAlpha) {
            finalA = origA;
          } else {
            final double blendedA = origA * (1.0 - intensity) + sampleA * intensity;
            finalA = ((blendedA / quantStepSize).round() * quantStepSize).round().clamp(0, 255);
          }
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

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}
