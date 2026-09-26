part of 'effects.dart';

/// An effect that procedurally transforms an image into a 19th-century photographic
/// cyanotype sun print, featuring rich Prussian and royal indigo blues, ghostly
/// silhouette photograms, sun-bleached solarization, and watercolor paper tooth.
class CyanotypePrintEffect extends Effect {
  CyanotypePrintEffect([Map<String, dynamic>? params])
      : super(
          EffectType.cyanotypePrint,
          params ??
              {
                'exposureDepth': 1.2,
                'prussianHueShift': 0.0,
                'edgeVignetteBleach': 0.45,
                'paperToothTexture': 0.4,
                'solarizationCurve': 0.3,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'exposureDepth': 1.2,
        'prussianHueShift': 0.0,
        'edgeVignetteBleach': 0.45,
        'paperToothTexture': 0.4,
        'solarizationCurve': 0.3,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'exposureDepth': {
          'label': 'Exposure Depth',
          'description': 'Sunlight chemical reaction exposure depth and shadow density.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.5,
          'step': 0.1,
        },
        'prussianHueShift': {
          'label': 'Prussian Hue',
          'description': 'Tonal shift between turquoise cyan, classic Prussian blue, and deep indigo.',
          'type': 'slider',
          'min': -0.2,
          'max': 0.2,
          'step': 0.02,
        },
        'edgeVignetteBleach': {
          'label': 'Emulsion Wash Edge',
          'description': 'Chemical brush wash fading and sun-bleached border vignette.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'paperToothTexture': {
          'label': 'Watercolor Paper Tooth',
          'description': 'Tactile cold-press cotton rag paper tooth and grain.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'solarizationCurve': {
          'label': 'Solarization Inversion',
          'description': 'Sun-bleached chalky inversion in overexposed highlights.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict cyanotype exposure to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'exposureDepth',
          label: 'Exposure Depth',
          description: 'Sunlight chemical reaction exposure depth and shadow density.',
          min: 0.5,
          max: 2.5,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'prussianHueShift',
          label: 'Prussian Hue',
          description: 'Tonal shift between turquoise cyan, classic Prussian blue, and deep indigo.',
          min: -0.2,
          max: 0.2,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'edgeVignetteBleach',
          label: 'Emulsion Wash Edge',
          description: 'Chemical brush wash fading and sun-bleached border vignette.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'paperToothTexture',
          label: 'Watercolor Paper Tooth',
          description: 'Tactile cold-press cotton rag paper tooth and grain.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'solarizationCurve',
          label: 'Solarization Inversion',
          description: 'Sun-bleached chalky inversion in overexposed highlights.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict cyanotype exposure to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final exposureDepth = ((parameters['exposureDepth'] as num?)?.toDouble() ?? 1.2).clamp(0.4, 3.0);
    final prussianHueShift = ((parameters['prussianHueShift'] as num?)?.toDouble() ?? 0.0).clamp(-0.25, 0.25);
    final edgeVignetteBleach = ((parameters['edgeVignetteBleach'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final paperToothTexture = ((parameters['paperToothTexture'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final solarizationCurve = ((parameters['solarizationCurve'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final centerX = width / 2.0;
    final centerY = height / 2.0;
    final maxDist = math.sqrt(centerX * centerX + centerY * centerY);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        final original = pixels[idx];

        // 1. Calculate Optical Luminance
        double lum;
        if ((original >>> 24) == 0) {
          lum = 1.0; // Unexposed pure paper
        } else {
          final r = (original >>> 16) & 0xFF;
          final g = (original >>> 8) & 0xFF;
          final b = original & 0xFF;
          lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        }

        // Apply Exposure depth power curve
        double expVal = math.pow(lum, exposureDepth).toDouble();

        // 2. Solarization Inversion in Extreme Highlights
        if (solarizationCurve > 0.05 && expVal > 0.82) {
          final overexposure = (expVal - 0.82) / 0.18;
          // Inverts slightly to chalky sun-bleached cream
          expVal -= (overexposure * solarizationCurve * 0.22);
        }

        // 3. Modulate with Watercolor Paper Tooth Grain
        if (paperToothTexture > 0.02) {
          final toothNoise = _noise2D(x * 0.7, y * 0.7, 149);
          expVal = (expVal + (toothNoise * paperToothTexture * 0.12)).clamp(0.0, 1.0);
        }

        // 4. Map to Ferric Ammonium Prussian Blue Color Gradient
        int color = _evaluatePrussianCurve(expVal, prussianHueShift);

        // 5. Chemical Emulsion Edge Wash Vignette
        if (edgeVignetteBleach > 0.05) {
          final dx = (x - centerX).abs();
          final dy = (y - centerY).abs();
          final dist = math.sqrt(dx * dx + dy * dy);
          final normDist = dist / maxDist;

          // Brush stroke irregular border
          final brushJitter = _noise2D(x * 0.2, y * 0.2, 331) * 0.15;
          final edgeFactor = ((normDist + brushJitter - 0.65) / 0.35).clamp(0.0, 1.0);

          if (edgeFactor > 0.0) {
            final bleachAlpha = (edgeFactor * edgeVignetteBleach * 255).toInt().clamp(0, 255);
            // Bleaches to unexposed watercolor paper
            color = _alphaBlend(color, 0xFFF5FAF8, bleachAlpha);
          }
        }

        out[idx] = color;
      }
    }

    return out;
  }

  // -----------------------------
  // Prussian Blue Reaction Curve
  // -----------------------------

  int _evaluatePrussianCurve(double normL, double hueShift) {
    // normL: 0.0 = deep shadow (intense Prussian blue), 1.0 = paper white (no pigment)
    final shadowR = (8 + (hueShift * 15)).toInt().clamp(2, 40);
    final shadowG = (28 + (hueShift * 25)).toInt().clamp(8, 70);
    final shadowB = (68 + (hueShift * -30)).toInt().clamp(40, 110);

    final midR = (30 + (hueShift * 20)).toInt().clamp(10, 65);
    final midG = (90 + (hueShift * 35)).toInt().clamp(50, 140);
    final midB = (150 + (hueShift * -40)).toInt().clamp(110, 195);

    const paperR = 245;
    const paperG = 250;
    const paperB = 248;

    int r, g, b;

    if (normL < 0.45) {
      // Shadow to Midtone
      final t = normL / 0.45;
      r = (shadowR + (midR - shadowR) * t).toInt();
      g = (shadowG + (midG - shadowG) * t).toInt();
      b = (shadowB + (midB - shadowB) * t).toInt();
    } else {
      // Midtone to Paper
      final t = (normL - 0.45) / 0.55;
      r = (midR + (paperR - midR) * t).toInt();
      g = (midG + (paperG - midG) * t).toInt();
      b = (midB + (paperB - midB) * t).toInt();
    }

    return 0xFF000000 | (r.clamp(0, 255) << 16) | (g.clamp(0, 255) << 8) | b.clamp(0, 255);
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
}
