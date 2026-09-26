part of 'effects.dart';

/// An effect that procedurally transforms an image into a dusty, textured
/// charcoal or soft French pastel drawing with directional blending smudges,
/// raw textured paper tooth peaks, and friable chalk dust granules.
class ChalkPastelEffect extends Effect {
  ChalkPastelEffect([Map<String, dynamic>? params])
      : super(
          EffectType.chalkPastel,
          params ??
              {
                'smudgeRadius': 3.0,
                'charcoalSoftness': 0.5,
                'paperToothRoughness': 0.4,
                'chalkPalette': 'charcoalMonochrome',
                'dustGrainDensity': 0.35,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'smudgeRadius': 3.0,
        'charcoalSoftness': 0.5,
        'paperToothRoughness': 0.4,
        'chalkPalette': 'charcoalMonochrome',
        'dustGrainDensity': 0.35,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'smudgeRadius': {
          'label': 'Smudge Blend Radius',
          'description': 'Distance of directional tortillon / blending stump smudging.',
          'type': 'slider',
          'min': 1.0,
          'max': 8.0,
          'step': 0.5,
        },
        'charcoalSoftness': {
          'label': 'Charcoal Softness',
          'description': 'Friability and blending softness of the chalk or vine charcoal stick.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'paperToothRoughness': {
          'label': 'Paper Tooth Roughness',
          'description': 'Height and grain of raw cold-press laid paper catching pigment.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'chalkPalette': {
          'label': 'Chalk Medium',
          'description': 'Traditional drawing medium and pigment formulation.',
          'type': 'select',
          'options': {
            'charcoalMonochrome': 'Vine & Willow Charcoal',
            'sepiaConte': 'Sepia Conté Crayon',
            'frenchPastel': 'Soft French Pastel',
            'sanguineChalk': 'Renaissance Sanguine Chalk',
          },
        },
        'dustGrainDensity': {
          'label': 'Chalk Dust Grain',
          'description': 'Stochastic spatter of powdery chalk particles around contours.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict chalk and paper tooth strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'smudgeRadius',
          label: 'Smudge Blend Radius',
          description: 'Distance of directional tortillon / blending stump smudging.',
          min: 1.0,
          max: 8.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'charcoalSoftness',
          label: 'Charcoal Softness',
          description: 'Friability and blending softness of the chalk or vine charcoal stick.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'paperToothRoughness',
          label: 'Paper Tooth Roughness',
          description: 'Height and grain of raw cold-press laid paper catching pigment.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'chalkPalette',
          label: 'Chalk Medium',
          description: 'Traditional drawing medium and pigment formulation.',
          options: {
            'charcoalMonochrome': 'Vine & Willow Charcoal',
            'sepiaConte': 'Sepia Conté Crayon',
            'frenchPastel': 'Soft French Pastel',
            'sanguineChalk': 'Renaissance Sanguine Chalk',
          },
        ),
        SliderField(
          key: 'dustGrainDensity',
          label: 'Chalk Dust Grain',
          description: 'Stochastic spatter of powdery chalk particles around contours.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict chalk and paper tooth strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double rawRadius = (parameters['smudgeRadius'] as num?)?.toDouble() ?? 3.0;
    final double smudgeR = rawRadius.clamp(1.0, 8.0);
    final double softness = ((parameters['charcoalSoftness'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final double toothRoughness = ((parameters['paperToothRoughness'] as num?)?.toDouble() ?? 0.4).clamp(0.1, 1.0);
    final String medium = (parameters['chalkPalette'] as String?) ?? 'charcoalMonochrome';
    final double dustDensity = ((parameters['dustGrainDensity'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // Compute luminance map and gradient vectors for directional smudge flow
    final Float32List lumaMap = Float32List(width * height);
    for (int i = 0; i < width * height; i++) {
      final int c = pixels[i];
      final int r = (c >> 16) & 0xFF;
      final int g = (c >> 8) & 0xFF;
      final int b = c & 0xFF;
      lumaMap[i] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
    }

    // Step 1: Flow-Field Directional Tangent Smudge
    final List<int> smudgedR = List<int>.filled(width * height, 0);
    final List<int> smudgedG = List<int>.filled(width * height, 0);
    final List<int> smudgedB = List<int>.filled(width * height, 0);
    final Float32List edgeIntensity = Float32List(width * height);

    final int sampleSteps = math.max(2, smudgeR.round());

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;

        // Sobel gradient approximation
        final int xm = (x - 1).clamp(0, width - 1);
        final int xp = (x + 1).clamp(0, width - 1);
        final int ym = (y - 1).clamp(0, height - 1);
        final int yp = (y + 1).clamp(0, height - 1);

        final double gx = (lumaMap[y * width + xp] - lumaMap[y * width + xm]);
        final double gy = (lumaMap[yp * width + x] - lumaMap[ym * width + x]);
        final double gradLen = math.sqrt(gx * gx + gy * gy);
        edgeIntensity[idx] = gradLen.clamp(0.0, 1.0);

        // Tangent perpendicular to gradient: (-gy, gx)
        double tx = -gy;
        double ty = gx;
        if (gradLen > 0.001) {
          tx /= gradLen;
          ty /= gradLen;
        } else {
          // Default horizontal smudge in flat zones
          tx = 1.0;
          ty = 0.0;
        }

        // Directional smudge sampling along tangent vector
        double accR = 0.0;
        double accG = 0.0;
        double accB = 0.0;
        double weightTotal = 0.0;

        for (int s = -sampleSteps; s <= sampleSteps; s++) {
          final double dist = s * (smudgeR / sampleSteps);
          final int sx = (x + (tx * dist).round()).clamp(0, width - 1);
          final int sy = (y + (ty * dist).round()).clamp(0, height - 1);
          final int sCol = pixels[sy * width + sx];

          final double w = math.exp(-(dist * dist) / (2.0 * smudgeR * smudgeR));
          accR += ((sCol >> 16) & 0xFF) * w;
          accG += ((sCol >> 8) & 0xFF) * w;
          accB += (sCol & 0xFF) * w;
          weightTotal += w;
        }

        final int origCol = pixels[idx];
        final int or = (origCol >> 16) & 0xFF;
        final int og = (origCol >> 8) & 0xFF;
        final int ob = origCol & 0xFF;

        final double blend = softness * 0.75;
        smudgedR[idx] = ((1.0 - blend) * or + blend * (accR / weightTotal)).round().clamp(0, 255);
        smudgedG[idx] = ((1.0 - blend) * og + blend * (accG / weightTotal)).round().clamp(0, 255);
        smudgedB[idx] = ((1.0 - blend) * ob + blend * (accB / weightTotal)).round().clamp(0, 255);
      }
    }

    // Step 2 & 3: Paper Tooth Adherence & Friable Dust Granules
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        int r = smudgedR[idx];
        int g = smudgedG[idx];
        int b = smudgedB[idx];
        final double baseLuma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        // Paper tooth heightfield simulation (combines high-frequency grain & laid lines)
        final double toothNoise = _paperNoise(x.toDouble(), y.toDouble());
        final double laidLine = math.sin(y * 1.5) * 0.15;
        final double toothHeight = (toothNoise + laidLine).clamp(0.0, 1.0);

        // Chalk adheres to paper tooth peaks; deep valleys retain raw paper background
        // Chalk deposit factor: high when toothHeight is high or when drawing is dark/dense
        final double deposit = (toothHeight * 0.85 + (1.0 - baseLuma) * 0.4 * toothRoughness).clamp(0.0, 1.0);
        final double toothModulation = 1.0 - (toothRoughness * (1.0 - deposit) * 0.65);

        // Stochastic chalk dust spatter near high-contrast edges
        double dustSpatter = 0.0;
        if (dustDensity > 0.0) {
          final double localEdge = edgeIntensity[idx];
          if (localEdge > 0.08) {
            final double grainRand = _hashGrain(x, y);
            if (grainRand < dustDensity * (localEdge * 1.8)) {
              // Chalk dust grain: powdered micro fleck
              dustSpatter = (grainRand * 0.6) * softness;
            }
          }
        }

        // Color mapping based on chalk medium palette
        int finalR;
        int finalG;
        int finalB;

        switch (medium) {
          case 'charcoalMonochrome':
            // Vine & willow charcoal: rich velvety soot blacks, warm greys, off-white laid paper
            // Paper base: #F2EFE9 (R:242, G:239, B:233)
            // Charcoal core: #181818 (R:24, G:24, B:24)
            final double tone = (baseLuma * toothModulation + dustSpatter * 0.25).clamp(0.0, 1.0);
            finalR = (24.0 + (242.0 - 24.0) * tone).round().clamp(0, 255);
            finalG = (24.0 + (239.0 - 24.0) * tone).round().clamp(0, 255);
            finalB = (24.0 + (233.0 - 24.0) * tone).round().clamp(0, 255);
            break;

          case 'sepiaConte':
            // Sepia Conté Crayon: deep warm umber, walnut shadows, cream paper
            // Paper base: #F5EEDB (R:245, G:238, B:219)
            // Sepia core: #382012 (R:56, G:32, B:18)
            final double sTone = (baseLuma * toothModulation + dustSpatter * 0.2).clamp(0.0, 1.0);
            finalR = (56.0 + (245.0 - 56.0) * sTone).round().clamp(0, 255);
            finalG = (32.0 + (238.0 - 32.0) * sTone).round().clamp(0, 255);
            finalB = (18.0 + (219.0 - 18.0) * sTone).round().clamp(0, 255);
            break;

          case 'sanguineChalk':
            // Renaissance Sanguine: rich terracotta red chalk on antique parchment
            // Paper base: #EFE6D4 (R:239, G:230, B:212)
            // Sanguine core: #86261A (R:134, G:38, B:26)
            final double sangTone = (baseLuma * toothModulation + dustSpatter * 0.2).clamp(0.0, 1.0);
            finalR = (134.0 + (239.0 - 134.0) * sangTone).round().clamp(0, 255);
            finalG = (38.0 + (230.0 - 38.0) * sangTone).round().clamp(0, 255);
            finalB = (26.0 + (212.0 - 26.0) * sangTone).round().clamp(0, 255);
            break;

          case 'frenchPastel':
          default:
            // Soft French Pastel: powdery, velvety soft colors with chalk bloom
            // Lightens and softens shadows with pastel chalk bloom
            final double pastelFactor = toothModulation * (1.0 + dustSpatter * 0.35);
            finalR = ((r * 0.85 + 40.0) * pastelFactor).round().clamp(0, 255);
            finalG = ((g * 0.85 + 40.0) * pastelFactor).round().clamp(0, 255);
            finalB = ((b * 0.85 + 40.0) * pastelFactor).round().clamp(0, 255);
            break;
        }

        final int outAlpha = preserveAlpha ? origAlpha : 255;
        result[idx] = (outAlpha << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return result;
  }

  static double _paperNoise(double x, double y) {
    // 2-octave high frequency noise for paper tooth
    final double n1 = _valNoise(x * 0.75, y * 0.75);
    final double n2 = _valNoise(x * 1.8, y * 1.8);
    return n1 * 0.65 + n2 * 0.35;
  }

  static double _valNoise(double x, double y) {
    final int xi = x.floor();
    final int yi = y.floor();
    final double xf = x - xi;
    final double yf = y - yi;

    final double u = xf * xf * (3.0 - 2.0 * xf);
    final double v = yf * yf * (3.0 - 2.0 * yf);

    final double n00 = _hashGrain(xi, yi);
    final double n10 = _hashGrain(xi + 1, yi);
    final double n01 = _hashGrain(xi, yi + 1);
    final double n11 = _hashGrain(xi + 1, yi + 1);

    final double x1 = n00 + u * (n10 - n00);
    final double x2 = n01 + u * (n11 - n01);
    return x1 + v * (x2 - x1);
  }

  static double _hashGrain(int x, int y) {
    int h = (x * 1597334677 + y * 3812015801) ^ 0x9e3779b9;
    h = (h ^ (h >> 15)) * 2246822519;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }
}
