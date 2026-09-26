part of 'effects.dart';

/// An effect that procedurally transforms an image into a waxy, thick pigment
/// impasto with scratched-through sgraffito incisions revealing an underlying
/// vibrant multi-colored wax layer beneath a dark topcoat pigment.
class WaxSgraffitoEffect extends Effect {
  WaxSgraffitoEffect([Map<String, dynamic>? params])
      : super(
          EffectType.waxSgraffito,
          params ??
              {
                'sgraffitoScratchDensity': 0.45,
                'waxThickImpasto': 0.5,
                'scratchStrokeLength': 5.0,
                'underlayerPalette': 'rainbowSpectrum',
                'waxRoughness': 0.35,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'sgraffitoScratchDensity': 0.45,
        'waxThickImpasto': 0.5,
        'scratchStrokeLength': 5.0,
        'underlayerPalette': 'rainbowSpectrum',
        'waxRoughness': 0.35,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'sgraffitoScratchDensity': {
          'label': 'Scratch Density',
          'description': 'Frequency of stylus needle sgraffito incisions carving the topcoat.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'waxThickImpasto': {
          'label': 'Waxy Impasto Relief',
          'description': 'Thick wax bevel and raised pigment ridges along scratch borders.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'scratchStrokeLength': {
          'label': 'Stroke Length',
          'description': 'Length of directional etched scratch segments.',
          'type': 'slider',
          'min': 2.0,
          'max': 12.0,
          'step': 0.5,
        },
        'underlayerPalette': {
          'label': 'Undercoat Palette',
          'description': 'Vibrant chromatic wax spectrum exposed beneath the dark topcoat.',
          'type': 'select',
          'options': {
            'rainbowSpectrum': 'Prismatic Rainbow Spectrum',
            'neonGlow': 'Electric Neon Glow',
            'solarAmber': 'Solar Flare Gold & Amber',
            'auroraBorealis': 'Aurora Borealis Emerald',
          },
        },
        'waxRoughness': {
          'label': 'Wax Surface Tooth',
          'description': 'Melted oil crayon micro-roughness and tactile texture.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict wax layers and scratches strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'sgraffitoScratchDensity',
          label: 'Scratch Density',
          description: 'Frequency of stylus needle sgraffito incisions carving the topcoat.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'waxThickImpasto',
          label: 'Waxy Impasto Relief',
          description: 'Thick wax bevel and raised pigment ridges along scratch borders.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'scratchStrokeLength',
          label: 'Stroke Length',
          description: 'Length of directional etched scratch segments.',
          min: 2.0,
          max: 12.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'underlayerPalette',
          label: 'Undercoat Palette',
          description: 'Vibrant chromatic wax spectrum exposed beneath the dark topcoat.',
          options: {
            'rainbowSpectrum': 'Prismatic Rainbow Spectrum',
            'neonGlow': 'Electric Neon Glow',
            'solarAmber': 'Solar Flare Gold & Amber',
            'auroraBorealis': 'Aurora Borealis Emerald',
          },
        ),
        SliderField(
          key: 'waxRoughness',
          label: 'Wax Surface Tooth',
          description: 'Melted oil crayon micro-roughness and tactile texture.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict wax layers and scratches strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double density = ((parameters['sgraffitoScratchDensity'] as num?)?.toDouble() ?? 0.45).clamp(0.1, 1.0);
    final double impasto = ((parameters['waxThickImpasto'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final double rawLen = (parameters['scratchStrokeLength'] as num?)?.toDouble() ?? 5.0;
    final double strokeLen = rawLen.clamp(2.0, 12.0);
    final String palette = (parameters['underlayerPalette'] as String?) ?? 'rainbowSpectrum';
    final double roughness = ((parameters['waxRoughness'] as num?)?.toDouble() ?? 0.35).clamp(0.1, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // Compute luminance map and Sobel edges for contour incisions
    final Float32List lumaMap = Float32List(width * height);
    for (int i = 0; i < width * height; i++) {
      final int c = pixels[i];
      final int r = (c >> 16) & 0xFF;
      final int g = (c >> 8) & 0xFF;
      final int b = c & 0xFF;
      lumaMap[i] = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
    }

    final Float32List edgeMap = Float32List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int xm = (x - 1).clamp(0, width - 1);
        final int xp = (x + 1).clamp(0, width - 1);
        final int ym = (y - 1).clamp(0, height - 1);
        final int yp = (y + 1).clamp(0, height - 1);

        final double gx = lumaMap[y * width + xp] - lumaMap[y * width + xm];
        final double gy = lumaMap[yp * width + x] - lumaMap[ym * width + x];
        edgeMap[y * width + x] = math.sqrt(gx * gx + gy * gy).clamp(0.0, 1.0);
      }
    }

    // Directional light vector for waxy impasto ridge highlights
    const double lightX = -0.707;
    const double lightY = -0.707;

    // Carving angle around 45°
    const double angleRad = math.pi * 0.25;
    final double cosA = math.cos(angleRad);
    final double sinA = math.sin(angleRad);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        final double luma = lumaMap[idx];
        final double edge = edgeMap[idx];

        // 1. Underlayer Vibrant Chromatic Wax Generation
        final _RGB underColor = _computeUnderlayerColor(
          x,
          y,
          width,
          height,
          palette,
          origPixel,
        );

        // 2. Sgraffito Scratch Incision Evaluation
        // Two components:
        // A) Contour scratching: Contours are carved along sharp edges
        final double contourScratch = (edge > 0.15) ? ((edge - 0.15) * 2.2).clamp(0.0, 1.0) : 0.0;

        // B) Shading crosshatch & directional etching strokes in bright & midtone regions
        final double waveNoise = (_noise2D(x * 0.25, y * 0.25) - 0.5) * 1.5;

        final double coordU = (x * cosA + y * sinA) + waveNoise;
        final double coordV = (-x * sinA + y * cosA);

        // Spacing scales inversely with density (dense = smaller spacing)
        final double strokeSpacing = math.max(2.0, 10.0 - density * 7.5);
        final double uMod = (coordU % strokeSpacing);
        final double distToStrokeCenter = (uMod - (strokeSpacing * 0.5)).abs();

        // Stroke segment hashing along V coordinate based on strokeLen
        final int vSegment = (coordV / strokeLen).floor();
        final double segRand = _hashStroke(x ~/ strokeSpacing, vSegment);

        // Determine if scratch incision cuts here:
        // High density or high original luminance increases scratch activation probability
        final double activationThreshold = 1.0 - (density * (0.4 + 0.6 * luma));
        final bool isStrokeActive = segRand > activationThreshold.clamp(0.05, 0.95);

        double hatchScratch = 0.0;
        if (isStrokeActive) {
          final double scratchWidth = 0.9 + density * 0.3;
          if (distToStrokeCenter < scratchWidth) {
            hatchScratch = 1.0 - (distToStrokeCenter / scratchWidth);
          }
        }

        // Combine contour carving and hatch scratching
        final double scratchTotal = math.max(contourScratch, hatchScratch).clamp(0.0, 1.0);

        // 3. Thick Wax Impasto Relief (Ridge Bevel)
        // Edges of scratch incisions build up raised wax ridges catching light
        final double ridgeProximity = (scratchTotal > 0.05 && scratchTotal < 0.85)
            ? math.sin(scratchTotal * math.pi)
            : 0.0;

        final double ridgeLight = (cosA * lightX + sinA * lightY).abs();
        final double impastoHighlight = ridgeProximity * impasto * (0.3 + 0.7 * ridgeLight);

        // 4. Matte Dark Topcoat Pastel Layer
        // Dark matte charcoal/midnight black layer
        final double waxTooth = (_noise2D(x * 1.2, y * 1.2) - 0.5) * roughness * 30.0;
        final int topcoatBase = (22.0 + waxTooth + (luma * 15.0)).round().clamp(10, 60);

        // 5. Final Composite (Incised Scratches reveal radiant underlayer)
        int finalR;
        int finalG;
        int finalB;

        if (scratchTotal > 0.1) {
          // Scratched open: reveals radiant underlayer wax with impasto edge glint
          final double revealFactor = ((scratchTotal - 0.1) / 0.9).clamp(0.0, 1.0);
          final double shine = 1.0 + impastoHighlight * 1.2;

          finalR = ((1.0 - revealFactor) * topcoatBase + revealFactor * (underColor.r * shine)).round().clamp(0, 255);
          finalG = ((1.0 - revealFactor) * topcoatBase + revealFactor * (underColor.g * shine)).round().clamp(0, 255);
          finalB = ((1.0 - revealFactor) * topcoatBase + revealFactor * (underColor.b * shine)).round().clamp(0, 255);
        } else {
          // Uncarved dark topcoat with subtle impasto sheen on borders
          final int topHighlight = (impastoHighlight * 70.0).round();
          finalR = (topcoatBase + topHighlight).clamp(0, 255);
          finalG = (topcoatBase + topHighlight).clamp(0, 255);
          finalB = (topcoatBase + (topHighlight * 1.2).round()).clamp(0, 255);
        }

        final int outAlpha = preserveAlpha ? origAlpha : 255;
        result[idx] = (outAlpha << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return result;
  }

  static _RGB _computeUnderlayerColor(
    int x,
    int y,
    int width,
    int height,
    String palette,
    int origPixel,
  ) {
    final double nx = x / math.max(1, width - 1);
    final double ny = y / math.max(1, height - 1);
    final double diagonal = (nx + ny) * 0.5;

    switch (palette) {
      case 'neonGlow':
        // Electric neon cyan, magenta, electric lime, hot amber
        final double t = (diagonal * 3.0) % 1.0;
        if (t < 0.25) {
          return const _RGB(255, 0, 130); // Neon Magenta
        } else if (t < 0.5) {
          return const _RGB(0, 240, 255); // Electric Cyan
        } else if (t < 0.75) {
          return const _RGB(60, 255, 40); // Fluorescent Lime
        } else {
          return const _RGB(255, 230, 0); // Neon Gold
        }

      case 'solarAmber':
        // Solar flare gold, flame vermilion, ruby magenta
        final double t = (diagonal * 2.5) % 1.0;
        if (t < 0.4) {
          return const _RGB(255, 215, 0); // Solar Gold
        } else if (t < 0.75) {
          return const _RGB(255, 87, 34); // Cadmium Orange
        } else {
          return const _RGB(233, 30, 99); // Ruby Red
        }

      case 'auroraBorealis':
        // Aurora emerald, celestial turquoise, violet
        final double t = (diagonal * 2.8) % 1.0;
        if (t < 0.35) {
          return const _RGB(0, 255, 140); // Aurora Green
        } else if (t < 0.7) {
          return const _RGB(40, 215, 255); // Turquoise Sky
        } else {
          return const _RGB(138, 43, 226); // Blue Violet
        }

      case 'rainbowSpectrum':
      default:
        // Prismatic Rainbow Spectrum: Red -> Orange -> Yellow -> Green -> Cyan -> Blue -> Violet
        final double hue = (diagonal * 360.0) % 360.0;
        return _hsvToRgb(hue, 0.95, 0.98);
    }
  }

  static _RGB _hsvToRgb(double h, double s, double v) {
    final double c = v * s;
    final double x = c * (1.0 - (((h / 60.0) % 2.0) - 1.0).abs());
    final double m = v - c;

    double r1 = 0.0, g1 = 0.0, b1 = 0.0;
    if (h < 60) {
      r1 = c; g1 = x; b1 = 0;
    } else if (h < 120) {
      r1 = x; g1 = c; b1 = 0;
    } else if (h < 180) {
      r1 = 0; g1 = c; b1 = x;
    } else if (h < 240) {
      r1 = 0; g1 = x; b1 = c;
    } else if (h < 300) {
      r1 = x; g1 = 0; b1 = c;
    } else {
      r1 = c; g1 = 0; b1 = x;
    }

    return _RGB(
      ((r1 + m) * 255.0).round().clamp(0, 255),
      ((g1 + m) * 255.0).round().clamp(0, 255),
      ((b1 + m) * 255.0).round().clamp(0, 255),
    );
  }

  static double _noise2D(double x, double y) {
    final int xi = x.floor();
    final int yi = y.floor();
    final double xf = x - xi;
    final double yf = y - yi;

    final double u = xf * xf * (3.0 - 2.0 * xf);
    final double v = yf * yf * (3.0 - 2.0 * yf);

    final double n00 = _hash2D(xi, yi);
    final double n10 = _hash2D(xi + 1, yi);
    final double n01 = _hash2D(xi, yi + 1);
    final double n11 = _hash2D(xi + 1, yi + 1);

    final double x1 = n00 + u * (n10 - n00);
    final double x2 = n01 + u * (n11 - n01);
    return x1 + v * (x2 - x1);
  }

  static double _hash2D(int x, int y) {
    int h = (x * 1234567 + y * 7654321) ^ 0x5a5a5a5a;
    h = (h ^ (h >> 13)) * 16777619;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }

  static double _hashStroke(int u, int v) {
    int h = (u * 374761393 + v * 668265263) ^ 0x3d3d3d3d;
    h = (h ^ (h >> 15)) * 2246822519;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }
}

class _RGB {
  final int r;
  final int g;
  final int b;
  const _RGB(this.r, this.g, this.b);
}
