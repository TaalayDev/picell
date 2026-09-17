part of 'effects.dart';

/// Simulates retro handheld dot-matrix LCD displays (Original DMG Game Boy,
/// Game Boy Pocket, Game Boy Light, Virtual Boy, Amber LCD) with 4-shade
/// quantization, ordered Bayer dithering, and LCD pixel matrix gap lines.
class LcdMatrixEffect extends Effect with UIFieldProvider {
  LcdMatrixEffect([Map<String, dynamic>? params])
      : super(
          EffectType.lcdMatrix,
          params ??
              const {
                'palette': 'dmg_green',
                'ditherMode': 'bayer2x2',
                'pixelGrid': 0.35,
                'pixelSize': 2,
                'contrast': 0.1,
                'brightness': 0.0,
                'preserveAlpha': true,
              },
        );

  static const Map<String, List<int>> palettes = {
    // Original DMG-01 Game Boy (Darkest to Lightest olive green)
    'dmg_green': [0xFF0F380F, 0xFF306230, 0xFF8BAC0F, 0xFF9BBC0F],
    // Game Boy Pocket / B&W LCD (Darkest to Lightest silver gray)
    'pocket_gray': [0xFF141414, 0xFF545454, 0xFFA0A0A0, 0xFFF8F8F8],
    // Game Boy Light (Electroluminescent teal-green backlight)
    'gb_light': [0xFF003830, 0xFF006554, 0xFF00A58B, 0xFF00FFD5],
    // Virtual Boy (Crimson red LEDs)
    'virtual_boy': [0xFF000000, 0xFF500000, 0xFFA50000, 0xFFFF0000],
    // Amber LCD (Retro digital watch / calculator)
    'amber': [0xFF281400, 0xFF783C00, 0xFFC86400, 0xFFFFAA00],
  };

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'palette': 'dmg_green',
      'ditherMode': 'bayer2x2',
      'pixelGrid': 0.35,
      'pixelSize': 2,
      'contrast': 0.1,
      'brightness': 0.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'palette': {
        'label': 'Color Palette',
        'description': 'Handheld LCD hardware color palette.',
        'type': 'select',
        'options': {
          'dmg_green': 'Game Boy DMG (Green)',
          'pocket_gray': 'Pocket (Silver Gray)',
          'gb_light': 'GB Light (Teal Glow)',
          'virtual_boy': 'Virtual Boy (Crimson)',
          'amber': 'Amber LCD (Digital Watch)',
        },
      },
      'ditherMode': {
        'label': 'Dithering',
        'description': 'Ordered Bayer dithering pattern between the 4 LCD shades.',
        'type': 'select',
        'options': {
          'none': 'None (Solid Quantize)',
          'bayer2x2': 'Bayer 2x2 (Subtle)',
          'bayer4x4': 'Bayer 4x4 (Smooth)',
        },
      },
      'pixelGrid': {
        'label': 'LCD Matrix Grid',
        'description': 'Visibility of the dark grid gaps between LCD subpixels.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'pixelSize': {
        'label': 'LCD Dot Size',
        'description': 'Physical pixel block size for the dot-matrix display.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3,
      },
      'contrast': {
        'label': 'Contrast Adjust',
        'description': 'Contrast tuning before 4-shade quantization.',
        'type': 'slider',
        'min': -0.5,
        'max': 0.5,
        'divisions': 50,
      },
      'brightness': {
        'label': 'Brightness Adjust',
        'description': 'Brightness tuning before 4-shade quantization.',
        'type': 'slider',
        'min': -0.5,
        'max': 0.5,
        'divisions': 50,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Keep background transparent instead of filling with LCD substrate.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'palette',
          label: 'Color Palette',
          description: 'Handheld LCD hardware color palette.',
          options: {
            'dmg_green': 'Game Boy DMG (Green)',
            'pocket_gray': 'Pocket (Silver Gray)',
            'gb_light': 'GB Light (Teal Glow)',
            'virtual_boy': 'Virtual Boy (Crimson)',
            'amber': 'Amber LCD (Digital Watch)',
          },
        ),
        const SelectField(
          key: 'ditherMode',
          label: 'Dithering',
          description: 'Ordered Bayer dithering pattern between the 4 LCD shades.',
          options: {
            'none': 'None (Solid Quantize)',
            'bayer2x2': 'Bayer 2x2 (Subtle)',
            'bayer4x4': 'Bayer 4x4 (Smooth)',
          },
        ),
        SliderField(
          key: 'pixelGrid',
          label: 'LCD Matrix Grid',
          description: 'Visibility of the dark grid gaps between LCD subpixels.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'pixelSize',
          label: 'LCD Dot Size',
          description: 'Physical pixel block size for the dot-matrix display.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'contrast',
          label: 'Contrast Adjust',
          description: 'Contrast tuning before 4-shade quantization.',
          min: -0.5,
          max: 0.5,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'brightness',
          label: 'Brightness Adjust',
          description: 'Brightness tuning before 4-shade quantization.',
          min: -0.5,
          max: 0.5,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep background transparent instead of filling with LCD substrate.',
        ),
      ];

  static const List<List<double>> _bayer2x2 = [
    [-0.375, 0.125],
    [0.375, -0.125],
  ];

  static const List<List<double>> _bayer4x4 = [
    [-0.46875, 0.03125, -0.34375, 0.15625],
    [0.28125, -0.21875, 0.40625, -0.09375],
    [-0.28125, 0.21875, -0.40625, 0.09375],
    [0.46875, -0.03125, 0.34375, -0.15625],
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final paletteKey = parameters['palette'] as String? ?? 'dmg_green';
    final paletteColors = palettes[paletteKey] ?? palettes['dmg_green']!;
    final ditherMode = parameters['ditherMode'] as String? ?? 'bayer2x2';
    final pixelGrid = ((parameters['pixelGrid'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final pixelSize = ((parameters['pixelSize'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final contrast = ((parameters['contrast'] as num?)?.toDouble() ?? 0.1).clamp(-0.5, 0.5);
    final brightness = ((parameters['brightness'] as num?)?.toDouble() ?? 0.0).clamp(-0.5, 0.5);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final result = Uint32List(width * height);

    // Darkest substrate tone for grid line gaps
    final gridBaseColor = paletteColors[0];
    final gridR = (gridBaseColor >> 16) & 0xFF;
    final gridG = (gridBaseColor >> 8) & 0xFF;
    final gridB = gridBaseColor & 0xFF;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final outIndex = y * width + x;

        // If pixelSize > 1, sample the anchor of the block to emulate physical LCD resolution
        final sampleX = pixelSize > 1 ? (x ~/ pixelSize) * pixelSize : x;
        final sampleY = pixelSize > 1 ? (y ~/ pixelSize) * pixelSize : y;
        final sampleIndex = sampleY * width + sampleX;

        final pixel = pixels[sampleIndex];
        final a = (pixel >> 24) & 0xFF;

        if (a == 0 && preserveAlpha) {
          result[outIndex] = 0;
          continue;
        }

        final r = (pixel >> 16) & 0xFF;
        final g = (pixel >> 8) & 0xFF;
        final b = pixel & 0xFF;

        // Rec. 601 Luminance
        var l = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        // Apply brightness and contrast
        l += brightness;
        l = (l - 0.5) * (1.0 + contrast) + 0.5;

        // Dithering offset
        if (ditherMode == 'bayer2x2') {
          final offset = _bayer2x2[y % 2][x % 2] * 0.35;
          l += offset;
        } else if (ditherMode == 'bayer4x4') {
          final offset = _bayer4x4[y % 4][x % 4] * 0.35;
          l += offset;
        }

        // Quantize into 4 shades (0 = darkest, 3 = lightest)
        final shadeIndex = (l * 3.0).round().clamp(0, 3);
        final shadeColor = paletteColors[shadeIndex];

        var outR = (shadeColor >> 16) & 0xFF;
        var outG = (shadeColor >> 8) & 0xFF;
        var outB = shadeColor & 0xFF;

        // Dot-matrix pixel grid gap darkening
        if (pixelGrid > 0.001) {
          final isGridLine = pixelSize > 1
              ? ((x % pixelSize == pixelSize - 1) || (y % pixelSize == pixelSize - 1))
              : ((x % 2 == 1) && (y % 2 == 1));

          if (isGridLine) {
            outR = (outR * (1.0 - pixelGrid * 0.7) + gridR * pixelGrid * 0.7).round().clamp(0, 255);
            outG = (outG * (1.0 - pixelGrid * 0.7) + gridG * pixelGrid * 0.7).round().clamp(0, 255);
            outB = (outB * (1.0 - pixelGrid * 0.7) + gridB * pixelGrid * 0.7).round().clamp(0, 255);
          }
        }

        final outA = a == 0 ? 255 : a;
        result[outIndex] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return result;
  }
}
