part of 'effects.dart';

/// Simulates progressive wind sway, bending, and foliage wave motions for
/// trees, grass, plants, hair, cloth, and hanging lanterns.
class WindSwayEffect extends Effect with UIFieldProvider {
  WindSwayEffect([Map<String, dynamic>? params])
      : super(
          EffectType.windSway,
          params ??
              const {
                'amplitude': 6.0,
                'speed': 1.0,
                'frequency': 0.8,
                'stiffness': 1.5,
                'anchor': 'bottom',
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'amplitude': 6.0,
      'speed': 1.0,
      'frequency': 0.8,
      'stiffness': 1.5,
      'anchor': 'bottom',
      'time': 0.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'amplitude': {
        'label': 'Wind Amplitude',
        'description': 'Maximum sway displacement in pixels.',
        'type': 'slider',
        'min': 1.0,
        'max': 24.0,
        'divisions': 46,
      },
      'speed': {
        'label': 'Wind Gust Speed',
        'description': 'Speed of the wind oscillation cycles.',
        'type': 'slider',
        'min': 0.2,
        'max': 4.0,
        'divisions': 38,
      },
      'frequency': {
        'label': 'Wave Ripple Frequency',
        'description': 'Secondary wave curvature along the height of the sprite.',
        'type': 'slider',
        'min': 0.0,
        'max': 3.0,
        'divisions': 30,
      },
      'stiffness': {
        'label': 'Bending Stiffness',
        'description': 'Non-linear bend curve (1.0 = linear bend, 2.0 = flexible tip bend).',
        'type': 'slider',
        'min': 1.0,
        'max': 2.5,
        'divisions': 30,
      },
      'anchor': {
        'label': 'Base Anchor',
        'description': 'Fixed root position that does not move in the wind.',
        'type': 'select',
        'options': {
          'bottom': 'Bottom Root (Trees, Plants, Grass)',
          'top': 'Top Anchor (Hanging Vines, Lanterns)',
          'left': 'Left Pole (Flags, Banners)',
          'right': 'Right Pole',
        },
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Timeline progress parameter updated during frame generation.',
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
          key: 'amplitude',
          label: 'Wind Amplitude',
          description: 'Maximum sway displacement in pixels.',
          min: 1.0,
          max: 24.0,
          divisions: 46,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'speed',
          label: 'Wind Gust Speed',
          description: 'Speed of the wind oscillation cycles.',
          min: 0.2,
          max: 4.0,
          divisions: 38,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'frequency',
          label: 'Wave Ripple Frequency',
          description: 'Secondary wave curvature along the height of the sprite.',
          min: 0.0,
          max: 3.0,
          divisions: 30,
          formatLabel: (v) => v.toStringAsFixed(1),
        ),
        SliderField(
          key: 'stiffness',
          label: 'Bending Stiffness',
          description: 'Non-linear bend curve (1.0 = linear bend, 2.0 = flexible tip bend).',
          min: 1.0,
          max: 2.5,
          divisions: 30,
          formatLabel: (v) => v.toStringAsFixed(1),
        ),
        const SelectField(
          key: 'anchor',
          label: 'Base Anchor',
          description: 'Fixed root position that does not move in the wind.',
          options: {
            'bottom': 'Bottom Root (Trees, Plants, Grass)',
            'top': 'Top Anchor (Hanging Vines, Lanterns)',
            'left': 'Left Pole (Flags, Banners)',
            'right': 'Right Pole',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during frame generation.',
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

    final amplitude = ((parameters['amplitude'] as num?)?.toDouble() ?? 6.0).clamp(1.0, 24.0);
    final speed = ((parameters['speed'] as num?)?.toDouble() ?? 1.0).clamp(0.2, 4.0);
    final frequency = ((parameters['frequency'] as num?)?.toDouble() ?? 0.8).clamp(0.0, 3.0);
    final stiffness = ((parameters['stiffness'] as num?)?.toDouble() ?? 1.5).clamp(1.0, 2.5);
    final anchor = parameters['anchor'] as String? ?? 'bottom';
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final result = Uint32List(width * height);
    final phase = time * speed * 2.0 * math.pi;

    final isVertical = (anchor == 'bottom' || anchor == 'top');

    if (isVertical) {
      final maxH = math.max(1, height - 1).toDouble();

      for (int y = 0; y < height; y++) {
        final double distFromRoot = anchor == 'bottom'
            ? (height - 1 - y).toDouble()
            : y.toDouble();
        final h = (distFromRoot / maxH).clamp(0.0, 1.0);
        final bendFactor = math.pow(h, stiffness);
        final displacement = (bendFactor * amplitude * math.sin(phase + h * frequency)).round();

        for (int x = 0; x < width; x++) {
          final srcX = x - displacement;
          if (srcX >= 0 && srcX < width) {
            final p = pixels[y * width + srcX];
            if ((p >> 24) & 0xFF == 0 && preserveAlpha) continue;
            result[y * width + x] = p;
          } else if (!preserveAlpha) {
            result[y * width + x] = 0xFF000000;
          }
        }
      }
    } else {
      // Horizontal cloth/flag wave (left/right anchor)
      final maxW = math.max(1, width - 1).toDouble();

      for (int x = 0; x < width; x++) {
        final double distFromRoot = anchor == 'left'
            ? x.toDouble()
            : (width - 1 - x).toDouble();
        final w = (distFromRoot / maxW).clamp(0.0, 1.0);
        final bendFactor = math.pow(w, stiffness);
        final displacement = (bendFactor * amplitude * math.sin(phase + w * frequency)).round();

        for (int y = 0; y < height; y++) {
          final srcY = y - displacement;
          if (srcY >= 0 && srcY < height) {
            final p = pixels[srcY * width + x];
            if ((p >> 24) & 0xFF == 0 && preserveAlpha) continue;
            result[y * width + x] = p;
          } else if (!preserveAlpha) {
            result[y * width + x] = 0xFF000000;
          }
        }
      }
    }

    return result;
  }
}
