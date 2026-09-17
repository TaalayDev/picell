part of 'effects.dart';

/// Simulates the core animation principle of Squash & Stretch, creating
/// volume-preserving elasticity for jumps, ground impacts, and idle breathing.
class SquashStretchEffect extends Effect with UIFieldProvider {
  SquashStretchEffect([Map<String, dynamic>? params])
      : super(
          EffectType.squashStretch,
          params ??
              const {
                'amount': 0.2,
                'frequency': 1.0,
                'phase': 0.0,
                'anchor': 'bottom',
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'amount': 0.2,
      'frequency': 1.0,
      'phase': 0.0,
      'anchor': 'bottom',
      'time': 0.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'amount': {
        'label': 'Deformation Amount',
        'description': 'Intensity of the squash and stretch distortion.',
        'type': 'slider',
        'min': 0.05,
        'max': 0.5,
        'divisions': 45,
      },
      'frequency': {
        'label': 'Oscillation Speed',
        'description': 'Speed and cycle frequency of the squash/stretch motion.',
        'type': 'slider',
        'min': 0.5,
        'max': 4.0,
        'divisions': 35,
      },
      'phase': {
        'label': 'Cycle Phase',
        'description': 'Starting phase offset along the oscillation cycle.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'anchor': {
        'label': 'Anchor Pivot',
        'description': 'Ground plane or pivot point that remains fixed during deformation.',
        'type': 'select',
        'options': {
          'bottom': 'Bottom (Ground / Landing)',
          'center': 'Center (Breathing / Flying)',
          'top': 'Top (Hanging / Ceiling)',
        },
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Timeline progress (0 to 1) updated during frame generation.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Leave background pixels transparent.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'amount',
          label: 'Deformation Amount',
          description: 'Intensity of the squash and stretch distortion.',
          min: 0.05,
          max: 0.5,
          divisions: 45,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'frequency',
          label: 'Oscillation Speed',
          description: 'Speed and cycle frequency of the squash/stretch motion.',
          min: 0.5,
          max: 4.0,
          divisions: 35,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'phase',
          label: 'Cycle Phase',
          description: 'Starting phase offset along the oscillation cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'anchor',
          label: 'Anchor Pivot',
          description: 'Ground plane or pivot point that remains fixed during deformation.',
          options: {
            'bottom': 'Bottom (Ground / Landing)',
            'center': 'Center (Breathing / Flying)',
            'top': 'Top (Hanging / Ceiling)',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress (0 to 1) updated during frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Leave background pixels transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final amount = ((parameters['amount'] as num?)?.toDouble() ?? 0.2).clamp(0.05, 0.5);
    final frequency = ((parameters['frequency'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 4.0);
    final phase = ((parameters['phase'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final anchor = parameters['anchor'] as String? ?? 'bottom';
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final angle = (time * frequency + phase) * 2.0 * math.pi;
    final delta = amount * math.sin(angle);

    // Sy: vertical scale, Sx: reciprocal to conserve volume (mass)
    final sy = (1.0 + delta).clamp(0.4, 2.5);
    final sx = (1.0 / sy).clamp(0.4, 2.5);

    double anchorX = (width - 1) / 2.0;
    double anchorY;

    if (anchor == 'bottom') {
      int lowestY = height - 1;
      for (int y = height - 1; y >= 0; y--) {
        bool rowHasPixel = false;
        for (int x = 0; x < width; x++) {
          if (((pixels[y * width + x] >> 24) & 0xFF) > 0) {
            rowHasPixel = true;
            break;
          }
        }
        if (rowHasPixel) {
          lowestY = y;
          break;
        }
      }
      anchorY = lowestY.toDouble();
    } else if (anchor == 'top') {
      int highestY = 0;
      for (int y = 0; y < height; y++) {
        bool rowHasPixel = false;
        for (int x = 0; x < width; x++) {
          if (((pixels[y * width + x] >> 24) & 0xFF) > 0) {
            rowHasPixel = true;
            break;
          }
        }
        if (rowHasPixel) {
          highestY = y;
          break;
        }
      }
      anchorY = highestY.toDouble();
    } else {
      anchorY = (height - 1) / 2.0;
    }

    final result = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      final srcY = (anchorY + (y - anchorY) / sy).round();
      if (srcY < 0 || srcY >= height) continue;

      for (int x = 0; x < width; x++) {
        final srcX = (anchorX + (x - anchorX) / sx).round();
        if (srcX >= 0 && srcX < width) {
          final p = pixels[srcY * width + srcX];
          if ((p >> 24) & 0xFF == 0 && preserveAlpha) {
            continue;
          }
          result[y * width + x] = p;
        } else if (!preserveAlpha) {
          result[y * width + x] = 0xFF000000;
        }
      }
    }

    return result;
  }
}
