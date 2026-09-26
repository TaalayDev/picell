part of 'effects.dart';

/// Simulates layered spot-color risograph printing.
class RisographPrintEffect extends Effect with UIFieldProvider {
  RisographPrintEffect([Map<String, dynamic>? params])
      : super(
          EffectType.risographPrint,
          params ??
              const {
                'palette': 0,
                'inkCount': 2,
                'registrationOffset': 1,
                'grain': 0.18,
                'inkStrength': 0.9,
                'paperColor': 0xFFFFF4DC,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'palette': 0,
        'inkCount': 2,
        'registrationOffset': 1,
        'grain': 0.18,
        'inkStrength': 0.9,
        'paperColor': 0xFFFFF4DC,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'palette': {
          'label': 'Ink Palette',
          'description': 'Choose a set of traditional spot-printing inks.',
          'type': 'select',
          'options': {
            0: 'Coral & Blue',
            1: 'Pink & Teal',
            2: 'Red & Black',
            3: 'Green & Violet',
          },
        },
        'inkCount': {
          'label': 'Ink Layers',
          'description': 'Print with two or three overlapping spot inks.',
          'type': 'slider',
          'min': 2,
          'max': 3,
          'divisions': 1,
        },
        'registrationOffset': {
          'label': 'Misregistration',
          'description': 'Offset the ink plates by this many pixels.',
          'type': 'slider',
          'min': 0,
          'max': 4,
          'divisions': 4,
        },
        'grain': {
          'label': 'Paper Grain',
          'description': 'Add deterministic flecks and uneven ink coverage.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.6,
          'divisions': 60,
        },
        'inkStrength': {
          'label': 'Ink Strength',
          'description': 'Control the density of the printed inks.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'divisions': 80,
        },
        'paperColor': {
          'label': 'Paper Color',
          'description': 'Color of the paper beneath the ink layers.',
          'type': 'color',
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Keep transparent sprite pixels transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SelectField<int>(
          key: 'palette',
          label: 'Ink Palette',
          description: 'Choose a set of traditional spot-printing inks.',
          options: {
            0: 'Coral & Blue',
            1: 'Pink & Teal',
            2: 'Red & Black',
            3: 'Green & Violet',
          },
        ),
        SliderField(
          key: 'inkCount',
          label: 'Ink Layers',
          description: 'Print with two or three overlapping spot inks.',
          min: 2,
          max: 3,
          divisions: 1,
          isInteger: true,
        ),
        SliderField(
          key: 'registrationOffset',
          label: 'Misregistration',
          description: 'Offset the ink plates by this many pixels.',
          min: 0,
          max: 4,
          divisions: 4,
          isInteger: true,
        ),
        SliderField(
          key: 'grain',
          label: 'Paper Grain',
          description: 'Add deterministic flecks and uneven ink coverage.',
          min: 0.0,
          max: 0.6,
          divisions: 60,
        ),
        SliderField(
          key: 'inkStrength',
          label: 'Ink Strength',
          description: 'Control the density of the printed inks.',
          min: 0.2,
          max: 1.0,
          divisions: 80,
        ),
        ColorField(
          key: 'paperColor',
          label: 'Paper Color',
          description: 'Color of the paper beneath the ink layers.',
        ),
        BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep transparent sprite pixels transparent.',
        ),
      ];

  static const _palettes = <List<int>>[
    [0xFFFF5A5F, 0xFF0077B6, 0xFFFFC857],
    [0xFFFF48B0, 0xFF008F8C, 0xFFFFD23F],
    [0xFFE63946, 0xFF252422, 0xFF457B9D],
    [0xFF3A7D44, 0xFF69306D, 0xFFF28F3B],
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }

    final paletteIndex = ((parameters['palette'] as num?)?.toInt() ?? 0)
        .clamp(0, _palettes.length - 1);
    final inkCount =
        ((parameters['inkCount'] as num?)?.toInt() ?? 2).clamp(2, 3);
    final offset =
        ((parameters['registrationOffset'] as num?)?.toInt() ?? 1).clamp(0, 4);
    final grain =
        ((parameters['grain'] as num?)?.toDouble() ?? 0.18).clamp(0.0, 0.6);
    final strength = ((parameters['inkStrength'] as num?)?.toDouble() ?? 0.9)
        .clamp(0.2, 1.0);
    final paper = (parameters['paperColor'] as int?) ?? 0xFFFFF4DC;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final inks = _palettes[paletteIndex];
    final result = Uint32List(width * height);

    final paperR = (paper >> 16) & 0xff;
    final paperG = (paper >> 8) & 0xff;
    final paperB = paper & 0xff;
    const shifts = <(int, int)>[(1, 0), (-1, 1), (0, -1)];

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final sourceAlpha = (pixels[index] >> 24) & 0xff;
        if (preserveAlpha && sourceAlpha == 0) {
          continue;
        }

        double outR = paperR.toDouble();
        double outG = paperG.toDouble();
        double outB = paperB.toDouble();

        for (var plate = 0; plate < inkCount; plate++) {
          final shift = shifts[plate];
          final sx = x + shift.$1 * offset;
          final sy = y + shift.$2 * offset;
          if (sx < 0 || sx >= width || sy < 0 || sy >= height) continue;

          final sample = pixels[sy * width + sx];
          final sampleA = ((sample >> 24) & 0xff) / 255.0;
          if (sampleA == 0) continue;
          final r = ((sample >> 16) & 0xff) / 255.0;
          final g = ((sample >> 8) & 0xff) / 255.0;
          final b = (sample & 0xff) / 255.0;
          final darkness = 1.0 - (0.299 * r + 0.587 * g + 0.114 * b);

          final separation = switch (plate) {
            0 => 0.58 * (1.0 - r) + 0.42 * darkness,
            1 => 0.58 * (1.0 - b) + 0.42 * darkness,
            _ => 0.58 * (1.0 - g) + 0.42 * darkness,
          };
          final noise = _hashNoise(x, y, plate) - 0.5;
          final coverage =
              (separation * strength * sampleA + noise * grain).clamp(0.0, 1.0);
          final ink = inks[plate];
          final inkR = (ink >> 16) & 0xff;
          final inkG = (ink >> 8) & 0xff;
          final inkB = ink & 0xff;

          outR = outR * (1.0 - coverage) + inkR * coverage;
          outG = outG * (1.0 - coverage) + inkG * coverage;
          outB = outB * (1.0 - coverage) + inkB * coverage;
        }

        final alpha = preserveAlpha ? sourceAlpha : 255;
        result[index] = (alpha << 24) |
            (outR.round().clamp(0, 255) << 16) |
            (outG.round().clamp(0, 255) << 8) |
            outB.round().clamp(0, 255);
      }
    }
    return result;
  }

  double _hashNoise(int x, int y, int plate) {
    var hash = x * 374761393 + y * 668265263 + plate * 1442695041;
    hash = (hash ^ (hash >> 13)) * 1274126177;
    return ((hash ^ (hash >> 16)) & 0xffff) / 65535.0;
  }
}
