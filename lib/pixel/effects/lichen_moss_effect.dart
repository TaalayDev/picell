part of 'effects.dart';

/// An effect that procedurally grows multi-tier crustose/foliose lichen rings,
/// creeping moss tendrils, and micro-spores across stone crevices and surfaces.
class LichenMossEffect extends Effect {
  LichenMossEffect([Map<String, dynamic>? params])
      : super(
          EffectType.lichenMoss,
          params ??
              {
                'lichenCoverage': 0.5,
                'growthPattern': 'crustoseRings',
                'sporePustules': 0.4,
                'lichenPalette': 'arcticOrange',
                'edgeCreepDepth': 3.5,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'lichenCoverage': 0.5,
        'growthPattern': 'crustoseRings',
        'sporePustules': 0.4,
        'lichenPalette': 'arcticOrange',
        'edgeCreepDepth': 3.5,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'lichenCoverage': {
          'label': 'Lichen Coverage',
          'description': 'Proportion of surface colonized by living lichen and moss.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'growthPattern': {
          'label': 'Botanical Growth Pattern',
          'description': 'Colony morphology: concentric rings, creeping tendrils, or velvet cushions.',
          'type': 'select',
          'options': {
            'crustoseRings': 'Concentric Crustose Rings',
            'creepingMoss': 'Creeping Tendril Moss',
            'velvetPatches': 'Velvet Cushion Moss',
          },
        },
        'sporePustules': {
          'label': 'Fruiting Apothecia & Spores',
          'description': 'Density of raised spore discs and powdery micro-pustules.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'lichenPalette': {
          'label': 'Lichen & Moss Species',
          'description': 'Botanical pigmentation of the symbiotic thallus.',
          'type': 'select',
          'options': {
            'arcticOrange': 'Golden Sun Lichen (Xanthoria)',
            'deepForestEmerald': 'Deep Forest Velvet Moss',
            'alpineWhite': 'Alpine Shield Lichen (Parmelia)',
            'desertRust': 'Desert Rust Rock Lichen',
          },
        },
        'edgeCreepDepth': {
          'label': 'Edge & Crevice Creep',
          'description': 'Tendency to preferentially colonize sprite contours and dark crevices.',
          'type': 'slider',
          'min': 1.0,
          'max': 8.0,
          'step': 0.5,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Cyclic respiration pulse and moisture dew shimmer.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict lichen growth strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'lichenCoverage',
          label: 'Lichen Coverage',
          description: 'Proportion of surface colonized by living lichen and moss.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'growthPattern',
          label: 'Botanical Growth Pattern',
          description: 'Colony morphology: concentric rings, creeping tendrils, or velvet cushions.',
          options: {
            'crustoseRings': 'Concentric Crustose Rings',
            'creepingMoss': 'Creeping Tendril Moss',
            'velvetPatches': 'Velvet Cushion Moss',
          },
        ),
        SliderField(
          key: 'sporePustules',
          label: 'Fruiting Apothecia & Spores',
          description: 'Density of raised spore discs and powdery micro-pustules.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'lichenPalette',
          label: 'Lichen & Moss Species',
          description: 'Botanical pigmentation of the symbiotic thallus.',
          options: {
            'arcticOrange': 'Golden Sun Lichen (Xanthoria)',
            'deepForestEmerald': 'Deep Forest Velvet Moss',
            'alpineWhite': 'Alpine Shield Lichen (Parmelia)',
            'desertRust': 'Desert Rust Rock Lichen',
          },
        ),
        SliderField(
          key: 'edgeCreepDepth',
          label: 'Edge & Crevice Creep',
          description: 'Tendency to preferentially colonize sprite contours and dark crevices.',
          min: 1.0,
          max: 8.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Cyclic respiration pulse and moisture dew shimmer.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict lichen growth strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double coverage = ((parameters['lichenCoverage'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final String pattern = (parameters['growthPattern'] as String?) ?? 'crustoseRings';
    final double spores = ((parameters['sporePustules'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final String palette = (parameters['lichenPalette'] as String?) ?? 'arcticOrange';
    final double rawCreep = (parameters['edgeCreepDepth'] as num?)?.toDouble() ?? 3.5;
    final double edgeCreep = rawCreep.clamp(1.0, 8.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // Compute luminance map and detect crevices/silhouette edges
    final Float32List lumaMap = Float32List(width * height);
    final Float32List edgeCreepScore = Float32List(width * height);

    for (int i = 0; i < width * height; i++) {
      final int c = pixels[i];
      final int a = (c >> 24) & 0xFF;
      final int r = (c >> 16) & 0xFF;
      final int g = (c >> 8) & 0xFF;
      final int b = c & 0xFF;
      lumaMap[i] = (a == 0) ? 0.0 : (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
    }

    final int searchR = math.max(1, edgeCreep.round());
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int a = (pixels[idx] >> 24) & 0xFF;
        if (a == 0) continue;

        // Check proximity to transparent edge or dark crevice
        double minAlphaDist = 1e9;
        for (int dy = -searchR; dy <= searchR; dy++) {
          final int sy = (y + dy).clamp(0, height - 1);
          for (int dx = -searchR; dx <= searchR; dx++) {
            final int sx = (x + dx).clamp(0, width - 1);
            final int sa = (pixels[sy * width + sx] >> 24) & 0xFF;
            if (sa == 0) {
              final double d = math.sqrt((dx * dx + dy * dy).toDouble());
              if (d < minAlphaDist) minAlphaDist = d;
            }
          }
        }

        final double edgeFactor = (minAlphaDist <= edgeCreep)
            ? (1.0 - (minAlphaDist / edgeCreep))
            : 0.0;
        final double creviceFactor = (1.0 - lumaMap[idx]).clamp(0.0, 1.0);
        edgeCreepScore[idx] = (edgeFactor * 0.7 + creviceFactor * 0.3).clamp(0.0, 1.0);
      }
    }

    // Cyclic respiration pulse: subtle colony expansion and spore dew glint
    final double timePhase = time * 2.0 * math.pi;
    final double breathMod = 1.0 + 0.06 * math.sin(timePhase);
    final double dewGlint = 0.5 + 0.5 * math.sin(timePhase * 2.0);

    // Colony seed centers for crustose rings
    const int colonyCount = 8;
    final List<double> colonyX = [0.22, 0.65, 0.45, 0.82, 0.15, 0.75, 0.35, 0.55];
    final List<double> colonyY = [0.25, 0.30, 0.60, 0.75, 0.70, 0.18, 0.85, 0.40];

    for (int y = 0; y < height; y++) {
      final int rowOffset = y * width;
      final double ny = y / math.max(1, height - 1);

      for (int x = 0; x < width; x++) {
        final int idx = rowOffset + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        final double nx = x / math.max(1, width - 1);
        final double creepBoost = edgeCreepScore[idx];

        // 1. Growth Pattern Evaluation
        double lichenField = 0.0;
        double ringZone = 0.0; // 0.0: edge margin, 0.5: thallus body, 1.0: central apothecia

        switch (pattern) {
          case 'creepingMoss':
            // Branching tendril noise flowing across crevices
            final double n1 = _fbmNoise(x * 0.12, y * 0.12);
            final double n2 = _fbmNoise(x * 0.28, y * 0.28);
            final double tendril = math.sin((n1 * 4.0 + n2 * 2.0) * math.pi).abs();
            lichenField = (1.0 - tendril) * 0.8 + creepBoost * 0.4;
            ringZone = (n2 > 0.55) ? 1.0 : 0.4;
            break;

          case 'velvetPatches':
            // Soft velvet cushion mounds with plush micro-pile
            final double mound = _fbmNoise(x * 0.08, y * 0.08);
            final double microPile = (_hashGrain(x, y) - 0.5) * 0.18;
            lichenField = (mound + microPile + creepBoost * 0.3);
            ringZone = ((mound - 0.3) / 0.5).clamp(0.0, 1.0);
            break;

          case 'crustoseRings':
          default:
            // Concentric crustose circular colonies with lobed margins
            double minColonyDist = 1e9;
            for (int k = 0; k < colonyCount; k++) {
              final double dx = (nx - colonyX[k]) * width;
              final double dy = (ny - colonyY[k]) * height;
              final double dist = math.sqrt(dx * dx + dy * dy);
              if (dist < minColonyDist) minColonyDist = dist;
            }

            final double colonyRadius = math.min(width, height) * (0.2 + 0.3 * coverage) * breathMod;
            final double lobeNoise = (_fbmNoise(x * 0.15, y * 0.15) - 0.5) * 16.0;
            final double effectiveDist = minColonyDist + lobeNoise;

            if (effectiveDist < colonyRadius) {
              final double normDist = (effectiveDist / colonyRadius).clamp(0.0, 1.0);
              lichenField = (1.0 - normDist) + creepBoost * 0.35;
              ringZone = 1.0 - normDist;
            } else {
              lichenField = creepBoost * 0.5;
              ringZone = 0.1;
            }
            break;
        }

        // Coverage thresholding
        final double threshold = 1.05 - coverage * 0.85;
        final bool hasLichen = lichenField > threshold;

        if (!hasLichen) {
          result[idx] = origPixel;
          continue;
        }

        // 2. Pigment Palette Synthesis
        final double sporeChance = _hashGrain(x, y);
        final bool isApothecia = (spores > 0.0) && (ringZone > 0.65) && (sporeChance < spores * 0.65);

        final _RGB col = _sampleLichenColor(palette, ringZone, isApothecia, dewGlint);

        // Lichen velvet surface shading
        final double velvetLight = 0.85 + 0.25 * (_fbmNoise(x * 0.3, y * 0.3));
        int r = (col.r * velvetLight).round().clamp(0, 255);
        int g = (col.g * velvetLight).round().clamp(0, 255);
        int b = (col.b * velvetLight).round().clamp(0, 255);

        // Blend onto original pixel along fringe
        final double blend = ((lichenField - threshold) / 0.15).clamp(0.0, 1.0);
        final int or = (origPixel >> 16) & 0xFF;
        final int og = (origPixel >> 8) & 0xFF;
        final int ob = origPixel & 0xFF;

        final int finalR = (or * (1.0 - blend) + r * blend).round().clamp(0, 255);
        final int finalG = (og * (1.0 - blend) + g * blend).round().clamp(0, 255);
        final int finalB = (ob * (1.0 - blend) + b * blend).round().clamp(0, 255);
        final int outAlpha = preserveAlpha ? origAlpha : 255;

        result[idx] = (outAlpha << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return result;
  }

  static _RGB _sampleLichenColor(String palette, double ringZone, bool isApothecia, double dewGlint) {
    switch (palette) {
      case 'deepForestEmerald':
        // Deep moss: charcoal base -> deep forest green -> bright emerald -> chartreuse apothecia
        if (isApothecia) {
          final int dew = (dewGlint * 45.0).round();
          return _RGB(175 + dew, 235 + dew, 50); // Chartreuse spores
        } else if (ringZone > 0.4) {
          return const _RGB(46, 125, 50); // Lush Emerald
        } else if (ringZone > 0.15) {
          return const _RGB(27, 77, 46); // Forest Green
        } else {
          return const _RGB(15, 35, 20); // Dark border margin
        }

      case 'alpineWhite':
        // Alpine shield lichen: slate border -> sage green -> pale mint -> powdery white apothecia
        if (isApothecia) {
          return const _RGB(240, 248, 245); // Powdery white spore disc
        } else if (ringZone > 0.4) {
          return const _RGB(180, 215, 185); // Pale mint
        } else if (ringZone > 0.15) {
          return const _RGB(120, 160, 130); // Sage thallus
        } else {
          return const _RGB(50, 65, 60); // Slate edge
        }

      case 'desertRust':
        // Desert Caloplaca: dark sandstone border -> olive green -> ochre -> vivid terracotta apothecia
        if (isApothecia) {
          return const _RGB(220, 68, 25); // Terracotta red apothecia
        } else if (ringZone > 0.4) {
          return const _RGB(225, 160, 20); // Amber ochre
        } else if (ringZone > 0.15) {
          return const _RGB(130, 145, 60); // Olive body
        } else {
          return const _RGB(60, 40, 30); // Sandstone margin
        }

      case 'arcticOrange':
      default:
        // Xanthoria parietina: charcoal border -> olive-sage -> lemon thallus -> golden orange apothecia
        if (isApothecia) {
          final int dew = (dewGlint * 35.0).round();
          return _RGB(255, 145 + dew, 10); // Luminous golden orange
        } else if (ringZone > 0.4) {
          return const _RGB(245, 195, 45); // Sun Gold thallus
        } else if (ringZone > 0.15) {
          return const _RGB(125, 145, 65); // Olive undertone
        } else {
          return const _RGB(30, 32, 28); // Dark crustose margin
        }
    }
  }

  static double _fbmNoise(double x, double y) {
    double total = 0.0;
    double amp = 0.6;
    double freq = 1.0;
    for (int i = 0; i < 3; i++) {
      total += _valNoise(x * freq, y * freq) * amp;
      amp *= 0.5;
      freq *= 2.0;
    }
    return total;
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
    int h = (x * 1597334677 + y * 3812015801) ^ 0x6e2b8349;
    h = (h ^ (h >> 15)) * 2246822519;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }
}
