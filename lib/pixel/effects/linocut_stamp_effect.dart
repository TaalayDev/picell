part of 'effects.dart';

/// An effect that procedurally transforms an image into an expressive relief print
/// (linocut or woodblock stamp) with sharp chiseled gouge marks, negative space
/// brayer roller "chatter" noise, and rich tactile ink coverage.
class LinocutStampEffect extends Effect {
  LinocutStampEffect([Map<String, dynamic>? params])
      : super(
          EffectType.linocutStamp,
          params ??
              {
                'chiselGougeAngle': 45.0,
                'inkPressure': 1.0,
                'chatterNoise': 0.4,
                'inkColor': 'carbonBlack',
                'paperColor': 'warmWhite',
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'chiselGougeAngle': 45.0,
        'inkPressure': 1.0,
        'chatterNoise': 0.4,
        'inkColor': 'carbonBlack',
        'paperColor': 'warmWhite',
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'chiselGougeAngle': {
          'label': 'Chisel Angle',
          'description': 'Directional angle of the carved linoleum gouge strokes.',
          'type': 'slider',
          'min': 0.0,
          'max': 180.0,
          'step': 5.0,
        },
        'inkPressure': {
          'label': 'Ink Pressure',
          'description': 'Roller brayer ink coverage and relief surface fill density.',
          'type': 'slider',
          'min': 0.2,
          'max': 2.0,
          'step': 0.1,
        },
        'chatterNoise': {
          'label': 'Brayer Chatter',
          'description': 'Residual ink lines picked up from shallow carved negative spaces.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'inkColor': {
          'label': 'Ink Color',
          'description': 'Printmaking block ink formulation.',
          'type': 'select',
          'options': {
            'carbonBlack': 'Carbon Black',
            'prussianBlue': 'Prussian Blue',
            'vermilionRed': 'Vermilion Red',
            'burntUmber': 'Burnt Umber',
          },
        },
        'paperColor': {
          'label': 'Paper Stock',
          'description': 'Printmaking paper stock substrate.',
          'type': 'select',
          'options': {
            'warmWhite': 'Warm White Rag',
            'kraftPaper': 'Raw Kraft Paper',
            'newsprintYellow': 'Aged Newsprint',
            'bleachedWhite': 'Bleached Bristol',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine linocut relief to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'chiselGougeAngle',
          label: 'Chisel Angle',
          description: 'Directional angle of the carved linoleum gouge strokes.',
          min: 0.0,
          max: 180.0,
          divisions: 36,
          formatLabel: (v) => '${v.toInt()}°',
        ),
        SliderField(
          key: 'inkPressure',
          label: 'Ink Pressure',
          description: 'Roller brayer ink coverage and relief surface fill density.',
          min: 0.2,
          max: 2.0,
          divisions: 18,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'chatterNoise',
          label: 'Brayer Chatter',
          description: 'Residual ink lines picked up from shallow carved negative spaces.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'inkColor',
          label: 'Ink Color',
          description: 'Printmaking block ink formulation.',
          options: {
            'carbonBlack': 'Carbon Black',
            'prussianBlue': 'Prussian Blue',
            'vermilionRed': 'Vermilion Red',
            'burntUmber': 'Burnt Umber',
          },
        ),
        const SelectField(
          key: 'paperColor',
          label: 'Paper Stock',
          description: 'Printmaking paper stock substrate.',
          options: {
            'warmWhite': 'Warm White Rag',
            'kraftPaper': 'Raw Kraft Paper',
            'newsprintYellow': 'Aged Newsprint',
            'bleachedWhite': 'Bleached Bristol',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine linocut relief to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final chiselGougeAngle = (parameters['chiselGougeAngle'] as num?)?.toDouble() ?? 45.0;
    final inkPressure = ((parameters['inkPressure'] as num?)?.toDouble() ?? 1.0).clamp(0.2, 2.5);
    final chatterNoise = ((parameters['chatterNoise'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final inkColorKey = (parameters['inkColor'] as String?) ?? 'carbonBlack';
    final paperColorKey = (parameters['paperColor'] as String?) ?? 'warmWhite';
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final inkColor = _getInkColor(inkColorKey);
    final paperColor = _getPaperColor(paperColorKey);

    final rad = (chiselGougeAngle * math.pi) / 180.0;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    // Relief binarization threshold modulated by ink pressure
    final threshold = (0.52 * inkPressure).clamp(0.20, 0.85);

    // 1. First Pass: Compute Luminance
    final lum = Float64List(width * height);
    for (int i = 0; i < pixels.length; i++) {
      final p = pixels[i];
      if ((p >>> 24) == 0) {
        lum[i] = 1.0; // Transparent = uncarved/carved white paper
      } else {
        final r = (p >>> 16) & 0xFF;
        final g = (p >>> 8) & 0xFF;
        final b = p & 0xFF;
        lum[i] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      }
    }

    // 2. Second Pass: Render Linocut Print
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        final l = lum[idx];

        // Is this a solid inked relief surface or a carved negative space?
        final isRelief = l < threshold;

        int finalColor;

        if (isRelief) {
          // Solid inked block area
          final brayerTexture = _noise2D(x * 0.4, y * 0.4, 71);
          // Subtle roller pressure grain
          if (brayerTexture > 0.4 && inkPressure < 1.3) {
            finalColor = _alphaBlend(inkColor, paperColor, 25);
          } else {
            finalColor = inkColor;
          }
        } else {
          // Carved linoleum negative space showing paper
          finalColor = paperColor;

          // Check for negative space "chatter" noise (residual ink on shallow gouge ridges)
          if (chatterNoise > 0.05) {
            // Projected coordinate along chisel gouge angle
            final u = x * cosA + y * sinA;
            final v = -x * sinA + y * cosA;

            // Directional gouge ridge lines
            final gougeRidge = math.sin(v * 0.9 + _noise2D(u * 0.15, v * 0.15, 101) * 3.0);
            final gougeTexture = _noise2D(u * 0.35, v * 0.1, 163);

            // Near relief borders, chatter is more frequent
            final distToEdge = (threshold - l).abs();
            final chatterThreshold = 1.0 - (chatterNoise * 0.55) - ((1.0 - distToEdge) * 0.15);

            if (gougeRidge > 0.65 && gougeTexture > chatterThreshold - 0.25) {
              final chatterAlpha = (chatterNoise * 220).toInt().clamp(0, 240);
              finalColor = _alphaBlend(finalColor, inkColor, chatterAlpha);
            }
          }
        }

        // Apply tactile paper texture
        final paperGrain = _noise2D(x * 0.8, y * 0.8, 239);
        if (paperGrain > 0.3) {
          finalColor = _multiplyColor(finalColor, 0.96);
        } else if (paperGrain < -0.3) {
          finalColor = _additiveBlend(finalColor, 0xFFFFFFFF, 12);
        }

        out[idx] = finalColor;
      }
    }

    return out;
  }

  // -----------------------------
  // Inks & Paper Substrates
  // -----------------------------

  int _getInkColor(String key) {
    switch (key) {
      case 'prussianBlue':
        return 0xFF0C2038; // Rich midnight Prussian blue
      case 'vermilionRed':
        return 0xFFBA2218; // Vibrant woodcut vermilion
      case 'burntUmber':
        return 0xFF3D2115; // Deep earthy umber
      case 'carbonBlack':
      default:
        return 0xFF141414; // Dense carbon relief ink
    }
  }

  int _getPaperColor(String key) {
    switch (key) {
      case 'kraftPaper':
        return 0xFFCDB18B; // Fibrous tan kraft paper
      case 'newsprintYellow':
        return 0xFFF0E5BE; // Aged yellowed pulp newsprint
      case 'bleachedWhite':
        return 0xFFFAFAFA; // Clean bleached printmaking paper
      case 'warmWhite':
      default:
        return 0xFFFBF7EF; // Traditional warm cotton rag
    }
  }

  // -----------------------------
  // Noise & Blending Utilities
  // -----------------------------

  double _noise2D(double x, double y, int seed) {
    final xi = x.floor();
    final yi = y.floor();
    final xf = x - xi;
    final yf = y - yi;

    final u = xf * xf * (3.0 - 2.0 * xf);
    final v = yf * yf * (3.0 - 2.0 * yf);

    final g00 = _hash2D(xi, yi, seed);
    final g10 = _hash2D(xi + 1, yi, seed);
    final g01 = _hash2D(xi, yi + 1, seed);
    final g11 = _hash2D(xi + 1, yi + 1, seed);

    final x1 = g00 + (g10 - g00) * u;
    final x2 = g01 + (g11 - g01) * u;
    return x1 + (x2 - x1) * v;
  }

  double _hash2D(int x, int y, int seed) {
    int h = seed ^ (x * 374761393) ^ (y * 668265263);
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h & 0x7FFFFFFF) / 1073741824.0) - 1.0;
  }

  int _alphaBlend(int base, int overlay, int alpha) {
    final a = alpha.clamp(0, 255);
    if (a == 0) return base;
    if (a == 255) return overlay;

    final inv = 255 - a;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final oR = (overlay >>> 16) & 0xFF;
    final oG = (overlay >>> 8) & 0xFF;
    final oB = overlay & 0xFF;

    final r = ((bR * inv) + (oR * a)) ~/ 255;
    final g = ((bG * inv) + (oG * a)) ~/ 255;
    final b = ((bB * inv) + (oB * a)) ~/ 255;

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }

  int _additiveBlend(int base, int light, int alpha) {
    final a = alpha.clamp(0, 255) / 255.0;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final lR = (light >>> 16) & 0xFF;
    final lG = (light >>> 8) & 0xFF;
    final lB = light & 0xFF;

    final r = math.min(255, bR + (lR * a).toInt());
    final g = math.min(255, bG + (lG * a).toInt());
    final b = math.min(255, bB + (lB * a).toInt());

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }

  int _multiplyColor(int color, double factor) {
    final a = (color >>> 24) & 0xFF;
    final r = (((color >>> 16) & 0xFF) * factor).toInt().clamp(0, 255);
    final g = (((color >>> 8) & 0xFF) * factor).toInt().clamp(0, 255);
    final b = ((color & 0xFF) * factor).toInt().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}
