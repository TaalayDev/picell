part of 'effects.dart';

/// Dithering effect (for pixel art)
class DitheringEffect extends Effect {
  DitheringEffect([Map<String, dynamic>? params])
      : super(
            EffectType.dithering,
            params ??
                {
                  'pattern': 0,
                  'intensity': 0.5,
                });

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final pattern = parameters['pattern'] as int;
    final intensity = parameters['intensity'] as double;
    final result = Uint32List(pixels.length);

    // Copy original pixels
    for (int i = 0; i < pixels.length; i++) {
      result[i] = pixels[i];
    }

    // Apply dithering based on pattern
    switch (pattern) {
      case 0: // Bayer 2x2
        _applyBayerDithering(result, width, height, intensity, 2);
        break;
      case 1: // Bayer 4x4
        _applyBayerDithering(result, width, height, intensity, 4);
        break;
      case 2: // Ordered 8x8
        _applyBayerDithering(result, width, height, intensity, 8);
        break;
      case 3: // Floyd-Steinberg
        _applyFloydSteinbergDithering(result, width, height, intensity);
        break;
    }

    return result;
  }

  void _applyBayerDithering(Uint32List pixels, int width, int height, double intensity, int matrixSize) {
    // Bayer matrices for different sizes
    final bayerMatrix2x2 = [
      [0, 2],
      [3, 1]
    ];

    final bayerMatrix4x4 = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5]
    ];

    final bayerMatrix8x8 = [
      [0, 32, 8, 40, 2, 34, 10, 42],
      [48, 16, 56, 24, 50, 18, 58, 26],
      [12, 44, 4, 36, 14, 46, 6, 38],
      [60, 28, 52, 20, 62, 30, 54, 22],
      [3, 35, 11, 43, 1, 33, 9, 41],
      [51, 19, 59, 27, 49, 17, 57, 25],
      [15, 47, 7, 39, 13, 45, 5, 37],
      [63, 31, 55, 23, 61, 29, 53, 21]
    ];

    // Scale factor for the matrix values
    final scaleFactor = 1.0 / (matrixSize * matrixSize);
    final effectStrength = intensity * 50; // Adjust for visible effect

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = pixels[index];
        final a = (pixel >> 24) & 0xFF;

        if (a == 0) continue; // Skip transparent pixels

        final r = (pixel >> 16) & 0xFF;
        final g = (pixel >> 8) & 0xFF;
        final b = pixel & 0xFF;

        // Get threshold from the appropriate Bayer matrix
        int thresholdValue;
        if (matrixSize == 2) {
          thresholdValue = bayerMatrix2x2[y % 2][x % 2];
        } else if (matrixSize == 4) {
          thresholdValue = bayerMatrix4x4[y % 4][x % 4];
        } else {
          thresholdValue = bayerMatrix8x8[y % 8][x % 8];
        }

        // Normalize threshold to 0-1 range
        final threshold = thresholdValue * scaleFactor;

        // Apply threshold with intensity
        final dither = (threshold - 0.5) * effectStrength;

        // Apply dithering to each channel
        final newR = (r + dither).clamp(0, 255).toInt();
        final newG = (g + dither).clamp(0, 255).toInt();
        final newB = (b + dither).clamp(0, 255).toInt();

        pixels[index] = (a << 24) | (newR << 16) | (newG << 8) | newB;
      }
    }
  }

  void _applyFloydSteinbergDithering(Uint32List pixels, int width, int height, double intensity) {
    // Create error arrays for each color channel
    final List<List<double>> errorR = List.generate(height, (_) => List.filled(width, 0.0));
    final List<List<double>> errorG = List.generate(height, (_) => List.filled(width, 0.0));
    final List<List<double>> errorB = List.generate(height, (_) => List.filled(width, 0.0));

    // Reduced color palette (for a more visible effect)
    final levels = (2 + intensity * 5).round(); // 2-7 levels based on intensity
    final divisor = 255 / (levels - 1);

    // Apply Floyd-Steinberg dithering
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = pixels[index];
        final a = (pixel >> 24) & 0xFF;

        if (a == 0) continue; // Skip transparent pixels

        // Get original RGB values plus accumulated error
        var r = ((pixel >> 16) & 0xFF) + errorR[y][x];
        var g = ((pixel >> 8) & 0xFF) + errorG[y][x];
        var b = (pixel & 0xFF) + errorB[y][x];

        // Quantize to reduced palette
        final newR = (((r / divisor).round() * divisor).clamp(0, 255)).toInt();
        final newG = (((g / divisor).round() * divisor).clamp(0, 255)).toInt();
        final newB = (((b / divisor).round() * divisor).clamp(0, 255)).toInt();

        // Calculate quantization error
        final errR = r - newR;
        final errG = g - newG;
        final errB = b - newB;

        // Update pixel
        pixels[index] = (a << 24) | (newR << 16) | (newG << 8) | newB;

        // Distribute error to neighboring pixels (Floyd-Steinberg pattern)
        if (x + 1 < width) {
          errorR[y][x + 1] += errR * 7 / 16 * intensity;
          errorG[y][x + 1] += errG * 7 / 16 * intensity;
          errorB[y][x + 1] += errB * 7 / 16 * intensity;
        }

        if (y + 1 < height) {
          if (x > 0) {
            errorR[y + 1][x - 1] += errR * 3 / 16 * intensity;
            errorG[y + 1][x - 1] += errG * 3 / 16 * intensity;
            errorB[y + 1][x - 1] += errB * 3 / 16 * intensity;
          }

          errorR[y + 1][x] += errR * 5 / 16 * intensity;
          errorG[y + 1][x] += errG * 5 / 16 * intensity;
          errorB[y + 1][x] += errB * 5 / 16 * intensity;

          if (x + 1 < width) {
            errorR[y + 1][x + 1] += errR * 1 / 16 * intensity;
            errorG[y + 1][x + 1] += errG * 1 / 16 * intensity;
            errorB[y + 1][x + 1] += errB * 1 / 16 * intensity;
          }
        }
      }
    }
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      // 0: Bayer 2x2, 1: Bayer 4x4, 2: Bayer 8x8, 3: Floyd-Steinberg
      'pattern': 0,
      // Range: 0.0 to 1.0
      'intensity': 0.5,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'pattern': {
        'label': 'Dithering Pattern',
        'description': 'Select the dithering pattern to apply.',
        'type': 'select',
        'options': {
          0: 'Bayer 2x2',
          1: 'Bayer 4x4',
          2: 'Bayer 8x8',
          3: 'Floyd-Steinberg',
        },
      },
      'intensity': {
        'label': 'Intensity',
        'description': 'Controls the strength of the dithering effect. '
            'Higher values create more pronounced dithering.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SelectField<int>(
          key: 'pattern',
          label: 'Dithering Pattern',
          description: 'Select the dithering pattern to apply.',
          options: {
            0: 'Bayer 2x2',
            1: 'Bayer 4x4',
            2: 'Bayer 8x8',
            3: 'Floyd-Steinberg',
          },
        ),
        const SliderField(
          key: 'intensity',
          label: 'Intensity',
          description: 'Controls the strength of the dithering effect. '
              'Higher values create more pronounced dithering.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
      ];
}
