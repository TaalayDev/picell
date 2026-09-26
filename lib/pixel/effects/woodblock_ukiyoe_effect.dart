part of 'effects.dart';

/// An effect that procedurally transforms an image into a traditional Japanese
/// woodblock print (ukiyo-e) featuring carved dark relief keyline contours,
/// fibrous washi paper grain, and delicate bokashi color wipe fades.
class WoodblockUkiyoeEffect extends Effect {
  WoodblockUkiyoeEffect([Map<String, dynamic>? params])
      : super(
          EffectType.woodblockUkiyoe,
          params ??
              {
                'keylineThickness': 1.2,
                'bokashiFade': 0.5,
                'paperGrainIntensity': 0.35,
                'pigmentPalette': 'traditionalEdo',
                'woodcutRelief': 0.4,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'keylineThickness': 1.2,
        'bokashiFade': 0.5,
        'paperGrainIntensity': 0.35,
        'pigmentPalette': 'traditionalEdo',
        'woodcutRelief': 0.4,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'keylineThickness': {
          'label': 'Keyline Relief',
          'description': 'Thickness of the carved dark sumi ink woodcut contours.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.1,
        },
        'bokashiFade': {
          'label': 'Bokashi Fade',
          'description': 'Degree of hand-wiped pigment gradient blending between color blocks.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'paperGrainIntensity': {
          'label': 'Washi Paper Grain',
          'description': 'Tactile texture of mulberry paper fibers and bark flecks.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'pigmentPalette': {
          'label': 'Pigment Palette',
          'description': 'Traditional mineral and organic Japanese woodblock inks.',
          'type': 'select',
          'options': {
            'traditionalEdo': 'Traditional Edo Heritage',
            'greatWaveIndigo': 'Great Wave Indigo & Cyan',
            'vermilionSunset': 'Vermilion & Sunset Ochre',
            'sumiMonochrome': 'Sumi-e Ink Brush Monochrome',
          },
        },
        'woodcutRelief': {
          'label': 'Wood Relief',
          'description': 'Subtle embossed shadow and highlight along carved block edges.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict print contours and pigments to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'keylineThickness',
          label: 'Keyline Relief',
          description: 'Thickness of the carved dark sumi ink woodcut contours.',
          min: 0.5,
          max: 3.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'bokashiFade',
          label: 'Bokashi Fade',
          description: 'Degree of hand-wiped pigment gradient blending between color blocks.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'paperGrainIntensity',
          label: 'Washi Paper Grain',
          description: 'Tactile texture of mulberry paper fibers and bark flecks.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'pigmentPalette',
          label: 'Pigment Palette',
          description: 'Traditional mineral and organic Japanese woodblock inks.',
          options: {
            'traditionalEdo': 'Traditional Edo Heritage',
            'greatWaveIndigo': 'Great Wave Indigo & Cyan',
            'vermilionSunset': 'Vermilion & Sunset Ochre',
            'sumiMonochrome': 'Sumi-e Ink Brush Monochrome',
          },
        ),
        SliderField(
          key: 'woodcutRelief',
          label: 'Wood Relief',
          description: 'Subtle embossed shadow and highlight along carved block edges.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict print contours and pigments to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final keylineThickness = ((parameters['keylineThickness'] as num?)?.toDouble() ?? 1.2).clamp(0.5, 4.0);
    final bokashiFade = ((parameters['bokashiFade'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final paperGrainIntensity = ((parameters['paperGrainIntensity'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final pigmentPalette = (parameters['pigmentPalette'] as String?) ?? 'traditionalEdo';
    final woodcutRelief = ((parameters['woodcutRelief'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final palette = _getUkiyoePalette(pigmentPalette);

    // Compute luminance map for edge analysis and color quantization
    final lum = Float64List(width * height);
    for (int i = 0; i < pixels.length; i++) {
      final p = pixels[i];
      if ((p >>> 24) == 0) {
        lum[i] = 0.95; // Treat transparent as bright paper
      } else {
        final r = (p >>> 16) & 0xFF;
        final g = (p >>> 8) & 0xFF;
        final b = p & 0xFF;
        lum[i] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      }
    }

    // 1. Sobel Edge Gradient Magnitude for Carved Keylines
    final edges = Float64List(width * height);
    final edgeThreshold = (0.22 / keylineThickness).clamp(0.06, 0.45);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;

        // Horizontal Sobel
        final gx = (lum[(y - 1) * width + (x + 1)] + 2.0 * lum[y * width + (x + 1)] + lum[(y + 1) * width + (x + 1)]) -
            (lum[(y - 1) * width + (x - 1)] + 2.0 * lum[y * width + (x - 1)] + lum[(y + 1) * width + (x - 1)]);

        // Vertical Sobel
        final gy = (lum[(y + 1) * width + (x - 1)] + 2.0 * lum[(y + 1) * width + x] + lum[(y + 1) * width + (x + 1)]) -
            (lum[(y - 1) * width + (x - 1)] + 2.0 * lum[(y - 1) * width + x] + lum[(y - 1) * width + (x + 1)]);

        edges[idx] = math.sqrt(gx * gx + gy * gy);
      }
    }

    // 2. Render Ukiyo-e Woodblock Printing
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        final original = pixels[idx];
        final l = lum[idx];
        final edgeVal = edges[idx];

        // Is this a carved wood relief keyline?
        final isKeyline = edgeVal > edgeThreshold;

        int finalColor;

        if (isKeyline) {
          // Dark sumi ink keyline contour
          final sumiInk = palette.sumiKeyline;

          // Subtle woodcut relief highlight along top-left of keyline
          if (woodcutRelief > 0.05 && x > 0 && y > 0) {
            final prevL = lum[(y - 1) * width + (x - 1)];
            if (l < prevL - 0.1) {
              finalColor = _additiveBlend(sumiInk, 0xFF4A3E31, (woodcutRelief * 180).toInt());
            } else {
              finalColor = sumiInk;
            }
          } else {
            finalColor = sumiInk;
          }
        } else {
          // Woodblock ink block mapping with Bokashi wipe
          final quantized = _mapToUkiyoePigment(original, l, palette);

          if (bokashiFade > 0.05) {
            // Sample neighbors vertically to create directional bokashi wiping
            final botY = math.min(height - 1, y + 1);
            final neighborColor = _mapToUkiyoePigment(pixels[botY * width + x], lum[botY * width + x], palette);

            if (neighborColor != quantized) {
              final fadeWeight = (bokashiFade * 0.45 * (y % 3 == 0 ? 1.0 : 0.6)).clamp(0.0, 0.5);
              finalColor = _alphaBlend(quantized, neighborColor, (fadeWeight * 255).toInt());
            } else {
              finalColor = quantized;
            }
          } else {
            finalColor = quantized;
          }
        }

        // Apply fibrous washi paper grain & bark flecks
        if (paperGrainIntensity > 0.02) {
          final grain = _noise2D(x * 0.6, y * 0.6, 91);
          final fiberFleck = _hash2D(x * 7, y * 13, 211);

          // Paper fiber variation
          if (grain > 0.25) {
            finalColor = _multiplyColor(finalColor, 1.0 - (paperGrainIntensity * 0.12));
          } else if (grain < -0.25) {
            finalColor = _additiveBlend(finalColor, palette.paperBase, (paperGrainIntensity * 40).toInt());
          }

          // Rare organic bark inclusion / fleck
          if (fiberFleck > 0.88 && !isKeyline) {
            finalColor = _alphaBlend(finalColor, 0xFF4D3826, (paperGrainIntensity * 140).toInt());
          }
        }

        out[idx] = finalColor;
      }
    }

    return out;
  }

  // -----------------------------
  // Traditional Pigment Mapping
  // -----------------------------

  int _mapToUkiyoePigment(int color, double lum, _UkiyoePalette palette) {
    if ((color >>> 24) == 0) return palette.paperBase;

    final r = (color >>> 16) & 0xFF;
    final g = (color >>> 8) & 0xFF;
    final b = color & 0xFF;

    // Check color saturation vs monochrome threshold
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final sat = maxC == 0 ? 0.0 : (maxC - minC) / maxC.toDouble();

    if (sat < 0.15) {
      // Neutral tones mapped to washi / sumi washes
      if (lum > 0.78) return palette.paperBase;
      if (lum > 0.55) return palette.lightWash;
      if (lum > 0.32) return palette.midWash;
      return palette.darkWash;
    }

    // Chromatic mapping based on dominant hue
    if (b > r && b > g) {
      // Blues -> Prussian Indigo & Azure
      return lum > 0.5 ? palette.cyanAzure : palette.prussianBlue;
    } else if (r > g && r > b) {
      // Reds / Oranges -> Vermilion & Ochre
      return lum > 0.5 ? palette.ochreGold : palette.vermilionRed;
    } else {
      // Greens -> Pine Green / Bamboo
      return lum > 0.5 ? palette.bambooGreen : palette.pineGreen;
    }
  }

  _UkiyoePalette _getUkiyoePalette(String key) {
    switch (key) {
      case 'greatWaveIndigo':
        return const _UkiyoePalette(
          sumiKeyline: 0xFF0A131F, // Deep ink contour
          paperBase: 0xFFEDE3CE, // Aged ivory washi
          lightWash: 0xFFD8D2C2, // Pale mist wash
          midWash: 0xFF79A9B8, // Seafoam wash
          darkWash: 0xFF1E527D, // Mid ocean azure
          prussianBlue: 0xFF0E2742, // Prussian navy
          cyanAzure: 0xFF2A6B9C, // Coastal blue
          vermilionRed: 0xFFB23A22, // Distant Mt. Fuji red
          ochreGold: 0xFFD4A256, // Shore sand
          pineGreen: 0xFF234433, // Dark coastal pine
          bambooGreen: 0xFF4D7553, // Pale moss
        );
      case 'vermilionSunset':
        return const _UkiyoePalette(
          sumiKeyline: 0xFF1A0E14, // Deep plum sumi
          paperBase: 0xFFFBF0E6, // Warm peach washi
          lightWash: 0xFFF2D7C8, // Rose tint wash
          midWash: 0xFFE07A5F, // Coral dusk wash
          darkWash: 0xFF8B2635, // Deep carmine
          prussianBlue: 0xFF2B3A67, // Twilight indigo
          cyanAzure: 0xFF496594, // Lavender sky
          vermilionRed: 0xFFD83A1E, // Vivid vermilion
          ochreGold: 0xFFF4A236, // Sunset amber
          pineGreen: 0xFF3D4A3E, // Evening foliage
          bambooGreen: 0xFF708B75, // Muted bamboo
        );
      case 'sumiMonochrome':
        return const _UkiyoePalette(
          sumiKeyline: 0xFF0D0D0D, // Pitch sumi ink
          paperBase: 0xFFF5F2E8, // Mulberry washi paper
          lightWash: 0xFFD6D3C8, // Pale sumi wash
          midWash: 0xFF9E9B91, // Medium silver wash
          darkWash: 0xFF4A4944, // Heavy charcoal wash
          prussianBlue: 0xFF2B2A27, // Dark ink
          cyanAzure: 0xFF787670, // Cool gray wash
          vermilionRed: 0xFF52504B, // Dense slate
          ochreGold: 0xFFBFBCAE, // Warm paper tone
          pineGreen: 0xFF3D3C38, // Forest gray
          bambooGreen: 0xFF8A887E, // Soft gray wash
        );
      case 'traditionalEdo':
      default:
        return const _UkiyoePalette(
          sumiKeyline: 0xFF171717, // Traditional sumi block keyline
          paperBase: 0xFFF4EDE0, // Natural unbleached washi
          lightWash: 0xFFE2D8C6, // Soft tea wash
          midWash: 0xFFBFAFA0, // Earth wash
          darkWash: 0xFF4A4036, // Dark umber wash
          prussianBlue: 0xFF183D5D, // Genuine Prussian indigo
          cyanAzure: 0xFF3D7EA6, // Mineral azurite
          vermilionRed: 0xFFC93B2B, // Cinnabar vermilion
          ochreGold: 0xFFD99E32, // Raw turmeric ochre
          pineGreen: 0xFF2F5438, // Malachite pine
          bambooGreen: 0xFF628B54, // Young bamboo
        );
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

class _UkiyoePalette {
  final int sumiKeyline;
  final int paperBase;
  final int lightWash;
  final int midWash;
  final int darkWash;
  final int prussianBlue;
  final int cyanAzure;
  final int vermilionRed;
  final int ochreGold;
  final int pineGreen;
  final int bambooGreen;

  const _UkiyoePalette({
    required this.sumiKeyline,
    required this.paperBase,
    required this.lightWash,
    required this.midWash,
    required this.darkWash,
    required this.prussianBlue,
    required this.cyanAzure,
    required this.vermilionRed,
    required this.ochreGold,
    required this.pineGreen,
    required this.bambooGreen,
  });
}
