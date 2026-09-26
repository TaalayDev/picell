part of 'effects.dart';

/// An effect that procedurally transforms an image into a gritty point-of-sale
/// thermal receipt or 9-pin dot-matrix printout featuring horizontal feed intervals,
/// dithered needle impact marks, thermal paper fading, and micro-crease wear.
class ThermalReceiptEffect extends Effect {
  ThermalReceiptEffect([Map<String, dynamic>? params])
      : super(
          EffectType.thermalReceipt,
          params ??
              {
                'pinDensity': 2.0,
                'thermalBurnStrength': 0.6,
                'paperFadeAge': 0.35,
                'feedLineJitter': 0.3,
                'creaseDistortion': 0.25,
                'receiptTheme': 'posThermalBlack',
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'pinDensity': 2.0,
        'thermalBurnStrength': 0.6,
        'paperFadeAge': 0.35,
        'feedLineJitter': 0.3,
        'creaseDistortion': 0.25,
        'receiptTheme': 'posThermalBlack',
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'pinDensity': {
          'label': 'Pin / Stride Pitch',
          'description': 'Resolution and spacing of the print-head heating pins or matrix needles.',
          'type': 'slider',
          'min': 1.0,
          'max': 4.0,
          'step': 0.5,
        },
        'thermalBurnStrength': {
          'label': 'Thermal Burn Depth',
          'description': 'Heat exposure and dark activation of the leuco dye chemical coating.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'paperFadeAge': {
          'label': 'Thermal Aging Fade',
          'description': 'UV/heat decay causing black dye to fade into dull violet and paper yellow.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'feedLineJitter': {
          'label': 'Roller Feed Stutter',
          'description': 'Horizontal jitter caused by mechanical friction during paper feed advance.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'creaseDistortion': {
          'label': 'Paper Creases & Folds',
          'description': 'Wrinkles, fold ridges, and pocket crinkles across receipt surface.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'receiptTheme': {
          'label': 'Paper & Ink Medium',
          'description': 'Point-of-sale thermal or dot-matrix impact ribbon formula.',
          'type': 'select',
          'options': {
            'posThermalBlack': 'Standard POS Thermal Roll',
            'retroDotMatrix': '9-Pin Purple Impact Ribbon',
            'fadedYellowReceipt': 'Aged Wallet Thermal Slip',
            'cyberpunkSurveillance': 'Cold Carbon Evidence Log',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict thermal printout strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'pinDensity',
          label: 'Pin / Stride Pitch',
          description: 'Resolution and spacing of the print-head heating pins or matrix needles.',
          min: 1.0,
          max: 4.0,
          divisions: 6,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'thermalBurnStrength',
          label: 'Thermal Burn Depth',
          description: 'Heat exposure and dark activation of the leuco dye chemical coating.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'paperFadeAge',
          label: 'Thermal Aging Fade',
          description: 'UV/heat decay causing black dye to fade into dull violet and paper yellow.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'feedLineJitter',
          label: 'Roller Feed Stutter',
          description: 'Horizontal jitter caused by mechanical friction during paper feed advance.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'creaseDistortion',
          label: 'Paper Creases & Folds',
          description: 'Wrinkles, fold ridges, and pocket crinkles across receipt surface.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'receiptTheme',
          label: 'Paper & Ink Medium',
          description: 'Point-of-sale thermal or dot-matrix impact ribbon formula.',
          options: {
            'posThermalBlack': 'Standard POS Thermal Roll',
            'retroDotMatrix': '9-Pin Purple Impact Ribbon',
            'fadedYellowReceipt': 'Aged Wallet Thermal Slip',
            'cyberpunkSurveillance': 'Cold Carbon Evidence Log',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict thermal printout strictly to existing sprite silhouette.',
        ),
      ];

  // 4x4 Bayer Dithering Matrix
  static const List<double> _bayer4 = [
    0.0 / 16.0, 8.0 / 16.0, 2.0 / 16.0, 10.0 / 16.0,
    12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0, 6.0 / 16.0,
    3.0 / 16.0, 11.0 / 16.0, 1.0 / 16.0, 9.0 / 16.0,
    15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0, 5.0 / 16.0,
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double rawPitch = (parameters['pinDensity'] as num?)?.toDouble() ?? 2.0;
    final double pitch = rawPitch.clamp(1.0, 4.0);
    final double burnStrength = ((parameters['thermalBurnStrength'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    final double fadeAge = ((parameters['paperFadeAge'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final double jitter = ((parameters['feedLineJitter'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final double creases = ((parameters['creaseDistortion'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0);
    final String theme = (parameters['receiptTheme'] as String?) ?? 'posThermalBlack';
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // Precalculate luminance map for source pixels
    final Float32List lumaMap = Float32List(width * height);
    for (int i = 0; i < width * height; i++) {
      final int c = pixels[i];
      final int r = (c >> 16) & 0xFF;
      final int g = (c >> 8) & 0xFF;
      final int b = c & 0xFF;
      lumaMap[i] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
    }

    // Paper Base and Burn Pigment configuration
    double paperR;
    double paperG;
    double paperB;
    int burnR;
    int burnG;
    int burnB;

    switch (theme) {
      case 'retroDotMatrix':
        // Purple ink ribbon on cream-tinted micro-perforated fanfold paper
        paperR = 248.0;
        paperG = 249.0;
        paperB = 250.0;
        // Purple impact ink: #422D75 (R:66, G:45, B:117)
        burnR = (66.0 + fadeAge * 45.0).round().clamp(0, 255);
        burnG = (45.0 + fadeAge * 50.0).round().clamp(0, 255);
        burnB = (117.0 + fadeAge * 30.0).round().clamp(0, 255);
        break;

      case 'fadedYellowReceipt':
        // Old yellowed wallet receipt with violet/brown chemical fade
        paperR = 240.0 - fadeAge * 15.0;
        paperG = 232.0 - fadeAge * 22.0;
        paperB = 195.0 - fadeAge * 45.0;
        // Faded leuco dye: #68576E
        burnR = (90.0 + fadeAge * 55.0).round().clamp(0, 255);
        burnG = (75.0 + fadeAge * 60.0).round().clamp(0, 255);
        burnB = (105.0 + fadeAge * 45.0).round().clamp(0, 255);
        break;

      case 'cyberpunkSurveillance':
        // Cold grey-blue evidence paper with dark carbon print
        paperR = 225.0;
        paperG = 233.0;
        paperB = 238.0;
        burnR = 12;
        burnG = 16;
        burnB = 22;
        break;

      case 'posThermalBlack':
      default:
        // Modern thermal roll: Off-white paper with charcoal/black leuco dye
        paperR = 248.0 - fadeAge * 10.0;
        paperG = 247.0 - fadeAge * 15.0;
        paperB = 242.0 - fadeAge * 35.0;
        // Dark burn fading to purplish grey
        burnR = (22.0 + fadeAge * 95.0).round().clamp(0, 255);
        burnG = (22.0 + fadeAge * 90.0).round().clamp(0, 255);
        burnB = (26.0 + fadeAge * 115.0).round().clamp(0, 255);
        break;
    }

    for (int y = 0; y < height; y++) {
      // 1. Horizontal Feed Line Jitter & Stride
      final int strideRow = (y / pitch).floor();
      final double jitterOffset = (jitter > 0.0)
          ? ((_hashInt(strideRow) & 0xFF) / 255.0 - 0.5) * 1.5 * jitter
          : 0.0;

      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        // 2. Paper Creases & Pocket Crinkles
        double creaseDisplaceX = 0.0;
        double creaseDisplaceY = 0.0;
        double creaseShade = 1.0;

        if (creases > 0.02) {
          // Diagonal fold line: (x + 1.5 * y)
          final double foldCoord = (x * 0.707 + y * 0.707) * 0.25;
          final double creaseNoise = _noise1D(foldCoord);
          if (creaseNoise.abs() < 0.12 * creases) {
            // Near fold crease
            final double foldDist = creaseNoise.abs() / (0.12 * creases);
            creaseDisplaceX = (1.0 - foldDist) * 1.2 * creases;
            creaseDisplaceY = (1.0 - foldDist) * -0.8 * creases;
            creaseShade = 0.88 + 0.24 * foldDist; // Dark groove, bright ridge
          }
        }

        // Sample input coordinates with jitter & crease displacement
        final double sampleX = (x + jitterOffset + creaseDisplaceX).clamp(0.0, (width - 1).toDouble());
        final double sampleY = (y + creaseDisplaceY).clamp(0.0, (height - 1).toDouble());

        // Quantize sample to nearest pin stride column and row
        final int pinX = ((sampleX / pitch).round() * pitch).round().clamp(0, width - 1);
        final int pinY = ((sampleY / pitch).round() * pitch).round().clamp(0, height - 1);
        final double sourceLuma = lumaMap[pinY * width + pinX];

        // 3. Uneven Heating Element Streaks & Edge Burn
        // Certain vertical columns have slightly weaker heating pins
        final int pinCol = (pinX / pitch).round();
        final double pinWear = ((_hashInt(pinCol * 7 + 101) & 0xFF) / 255.0);
        final double pinEfficiency = (pinWear > 0.85) ? 0.75 : 1.0;

        // Contrast and burn calculation
        // Inverted: Dark source pixels produce high burn activation (1.0 = heavy black burn)
        final double rawBurn = ((1.0 - sourceLuma) * burnStrength * pinEfficiency * (1.0 - fadeAge * 0.35)).clamp(0.0, 1.0);

        // 4. Ordered Bayer Dithering
        final int bayerX = (x / pitch).floor() % 4;
        final int bayerY = (y / pitch).floor() % 4;
        final double threshold = _bayer4[bayerY * 4 + bayerX];

        // Needle impact shape: center of pin is denser than edges
        final double pinCellX = (sampleX % pitch) - (pitch * 0.5);
        final double pinCellY = (sampleY % pitch) - (pitch * 0.5);
        final double pinDist = math.sqrt(pinCellX * pinCellX + pinCellY * pinCellY);
        final double pinRadialFalloff = (1.0 - (pinDist / (pitch * 0.75))).clamp(0.0, 1.0);

        final bool isBurned = (rawBurn * (0.8 + 0.4 * pinRadialFalloff)) > threshold;

        // 5. Thermal Paper Surface Grain & Crease Integration
        final double paperGrain = (_hashGrain(x, y) - 0.5) * 8.0;
        final double curPaperR = (paperR + paperGrain) * creaseShade;
        final double curPaperG = (paperG + paperGrain) * creaseShade;
        final double curPaperB = (paperB + paperGrain) * creaseShade;

        int finalR;
        int finalG;
        int finalB;

        if (isBurned) {
          // Burn activation with subtle pin core falloff
          final double burnAlpha = (0.75 + 0.25 * pinRadialFalloff).clamp(0.0, 1.0);
          finalR = (curPaperR * (1.0 - burnAlpha) + burnR * burnAlpha).round().clamp(0, 255);
          finalG = (curPaperG * (1.0 - burnAlpha) + burnG * burnAlpha).round().clamp(0, 255);
          finalB = (curPaperB * (1.0 - burnAlpha) + burnB * burnAlpha).round().clamp(0, 255);
        } else {
          // Clean paper with creases and scanline feed interval
          // Slight horizontal scanline tooth along needle row boundaries
          final double lineBand = (y % pitch < 0.8) ? 0.96 : 1.0;
          finalR = (curPaperR * lineBand).round().clamp(0, 255);
          finalG = (curPaperG * lineBand).round().clamp(0, 255);
          finalB = (curPaperB * lineBand).round().clamp(0, 255);
        }

        final int outAlpha = preserveAlpha ? origAlpha : 255;
        result[idx] = (outAlpha << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return result;
  }

  static double _noise1D(double x) {
    final int xi = x.floor();
    final double xf = x - xi;
    final double u = xf * xf * (3.0 - 2.0 * xf);
    final double n0 = (_hashInt(xi) & 0xFF) / 255.0 - 0.5;
    final double n1 = (_hashInt(xi + 1) & 0xFF) / 255.0 - 0.5;
    return n0 + u * (n1 - n0);
  }

  static int _hashInt(int x) {
    int h = x * 374761393 ^ 0x5a5a5a5a;
    h = (h ^ (h >> 13)) * 1274126177;
    return h ^ (h >> 16);
  }

  static double _hashGrain(int x, int y) {
    int h = (x * 1597334677 + y * 3812015801) ^ 0x9e3779b9;
    h = (h ^ (h >> 15)) * 2246822519;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }
}
