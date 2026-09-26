part of 'effects.dart';

/// Applies radial zoom and shock focus blur radiating from a focal center with
/// a configurable crisp deadzone, multi-tap ray sampling, and layer alpha confinement.
class RadialZoomBlurEffect extends Effect {
  RadialZoomBlurEffect([Map<String, dynamic>? params])
      : super(
          EffectType.radialZoomBlur,
          params ??
              {
                'focalCenterX': 0.5,
                'focalCenterY': 0.5,
                'zoomStrength': 0.45,
                'deadzoneRadius': 0.15,
                'blurDirection': 'zoomOut',
                'sampleCount': 10.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'focalCenterX': 0.5,
        'focalCenterY': 0.5,
        'zoomStrength': 0.45,
        'deadzoneRadius': 0.15,
        'blurDirection': 'zoomOut',
        'sampleCount': 10.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'focalCenterX': {
          'label': 'Focal Center X',
          'description': 'Horizontal origin of the radial blur burst.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'focalCenterY': {
          'label': 'Focal Center Y',
          'description': 'Vertical origin of the radial blur burst.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'zoomStrength': {
          'label': 'Zoom Strength',
          'description': 'Magnitude of the radial ray displacement and blur streak.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'deadzoneRadius': {
          'label': 'Focus Deadzone',
          'description': 'Central clear zone where details remain 100% crisp without blur.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.5,
          'step': 0.02,
        },
        'blurDirection': {
          'label': 'Blur Direction',
          'description': 'Direction of the radial streaks (zoom out, zoom in, or bidirectional).',
          'type': 'dropdown',
          'options': [
            {'value': 'zoomOut', 'label': 'Zoom Out (Explosive Burst)'},
            {'value': 'zoomIn', 'label': 'Zoom In (Vortex Pull)'},
            {'value': 'bidirectional', 'label': 'Bidirectional (Centered Burst)'},
          ],
        },
        'sampleCount': {
          'label': 'Ray Samples',
          'description': 'Number of ray-blur taps sampled along the radial vector.',
          'type': 'slider',
          'min': 4.0,
          'max': 20.0,
          'step': 1.0,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine radial blur strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'focalCenterX',
          label: 'Focal Center X',
          description: 'Horizontal origin of the radial blur burst.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'focalCenterY',
          label: 'Focal Center Y',
          description: 'Vertical origin of the radial blur burst.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'zoomStrength',
          label: 'Zoom Strength',
          description: 'Magnitude of the radial ray displacement and blur streak.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'deadzoneRadius',
          label: 'Focus Deadzone',
          description: 'Central clear zone where details remain 100% crisp without blur.',
          min: 0.0,
          max: 0.5,
          divisions: 25,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'blurDirection',
          label: 'Blur Direction',
          description: 'Direction of the radial streaks (zoom out, zoom in, or bidirectional).',
          options: {
            'zoomOut': 'Zoom Out (Explosive Burst)',
            'zoomIn': 'Zoom In (Vortex Pull)',
            'bidirectional': 'Bidirectional (Centered Burst)',
          },
        ),
        SliderField(
          key: 'sampleCount',
          label: 'Ray Samples',
          description: 'Number of ray-blur taps sampled along the radial vector.',
          min: 4.0,
          max: 20.0,
          divisions: 16,
          formatLabel: (v) => '${v.round()} taps',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine radial blur strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double fcXNorm = ((parameters['focalCenterX'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final double fcYNorm = ((parameters['focalCenterY'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final double strength = ((parameters['zoomStrength'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final double deadzone = ((parameters['deadzoneRadius'] as num?)?.toDouble() ?? 0.15).clamp(0.0, 0.5);
    final String direction = parameters['blurDirection'] as String? ?? 'zoomOut';
    final int samples = ((parameters['sampleCount'] as num?)?.toDouble() ?? 10.0).round().clamp(4, 20);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final double fcX = fcXNorm * width;
    final double fcY = fcYNorm * height;
    final double maxRadius = 0.5 * math.sqrt(width * width + height * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        final double dx = x - fcX;
        final double dy = y - fcY;
        final double dist = math.sqrt(dx * dx + dy * dy);
        final double normDist = (dist / math.max(1.0, maxRadius)).clamp(0.0, 1.0);

        // Deadzone check: inside deadzone, keep original pixel with 0 blur
        if (normDist <= deadzone || strength <= 0.001) {
          output[idx] = origPixel;
          continue;
        }

        // Ramp blur factor from deadzone edge to outer edge
        final double ramp = ((normDist - deadzone) / (1.0 - deadzone)).clamp(0.0, 1.0);
        final double blurAmount = ramp * strength * 0.45;

        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        double sumR = 0.0;
        double sumG = 0.0;
        double sumB = 0.0;
        double sumA = 0.0;
        double totalWeight = 0.0;

        for (int i = 0; i < samples; i++) {
          final double t = (i / (samples - 1.0));
          double rayScale;

          if (direction == 'zoomIn') {
            // Sampling outwards from pixel away from focal center
            rayScale = 1.0 + t * blurAmount;
          } else if (direction == 'bidirectional') {
            // Symmetrically straddling pixel
            rayScale = 1.0 + (t - 0.5) * blurAmount * 2.0;
          } else {
            // 'zoomOut': sampling inwards towards focal center (creates outward explosive blur)
            rayScale = 1.0 - t * blurAmount;
          }

          final int sampleX = (fcX + dx * rayScale).round();
          final int sampleY = (fcY + dy * rayScale).round();

          final double weight = 1.0 - t * 0.55;

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
        final double blurredA = sumA / (samples * 0.725);

        final double blend = (ramp * strength).clamp(0.0, 1.0);
        final int finalR = (origR * (1.0 - blend) + blurredR * blend).clamp(0.0, 255.0).round();
        final int finalG = (origG * (1.0 - blend) + blurredG * blend).clamp(0.0, 255.0).round();
        final int finalB = (origB * (1.0 - blend) + blurredB * blend).clamp(0.0, 255.0).round();

        int finalA;
        if (preserveAlpha) {
          finalA = origA;
        } else {
          finalA = (origA * (1.0 - blend) + blurredA * blend).clamp(0.0, 255.0).round();
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
