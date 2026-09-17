part of 'effects.dart';

/// Simulates a vintage CRT monitor with scanlines, screen curvature,
/// RGB phosphor sub-pixel mask, vignette, and phosphor glow.
class CrtEffect extends Effect with UIFieldProvider {
  CrtEffect([Map<String, dynamic>? params])
      : super(
          EffectType.crt,
          params ??
              const {
                'scanlineIntensity': 0.35,
                'scanlineSpacing': 2,
                'rgbSubpixel': 0.25,
                'curvature': 0.12,
                'vignette': 0.3,
                'brightnessBoost': 0.15,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'scanlineIntensity': 0.35,
      'scanlineSpacing': 2,
      'rgbSubpixel': 0.25,
      'curvature': 0.12,
      'vignette': 0.3,
      'brightnessBoost': 0.15,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'scanlineIntensity': {
        'label': 'Scanline Intensity',
        'description': 'Darkening strength of horizontal CRT scanlines.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'scanlineSpacing': {
        'label': 'Scanline Spacing',
        'description': 'Vertical distance between scanlines in pixels.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3,
      },
      'rgbSubpixel': {
        'label': 'RGB Phosphor Mask',
        'description': 'Intensity of vertical red, green, and blue phosphor stripes.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'curvature': {
        'label': 'Screen Curvature',
        'description': 'Barrel distortion simulating the curved glass face of a CRT monitor.',
        'type': 'slider',
        'min': 0.0,
        'max': 0.5,
        'divisions': 50,
      },
      'vignette': {
        'label': 'Corner Vignette',
        'description': 'Edge and corner shading typical of cathode-ray tubes.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'brightnessBoost': {
        'label': 'Phosphor Glow',
        'description': 'Brightness boost to compensate for scanline dimming and simulate phosphor glow.',
        'type': 'slider',
        'min': 0.0,
        'max': 0.5,
        'divisions': 50,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Keep background transparent instead of drawing a black CRT bezel.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'scanlineIntensity',
          label: 'Scanline Intensity',
          description: 'Darkening strength of horizontal CRT scanlines.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'scanlineSpacing',
          label: 'Scanline Spacing',
          description: 'Vertical distance between scanlines in pixels.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'rgbSubpixel',
          label: 'RGB Phosphor Mask',
          description: 'Intensity of vertical red, green, and blue phosphor stripes.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'curvature',
          label: 'Screen Curvature',
          description: 'Barrel distortion simulating the curved glass face of a CRT monitor.',
          min: 0.0,
          max: 0.5,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'vignette',
          label: 'Corner Vignette',
          description: 'Edge and corner shading typical of cathode-ray tubes.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'brightnessBoost',
          label: 'Phosphor Glow',
          description: 'Brightness boost to compensate for scanline dimming and simulate phosphor glow.',
          min: 0.0,
          max: 0.5,
          divisions: 50,
          formatLabel: (v) => '+${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep background transparent instead of drawing a black CRT bezel.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final scanlineIntensity = ((parameters['scanlineIntensity'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final scanlineSpacing = ((parameters['scanlineSpacing'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final rgbSubpixel = ((parameters['rgbSubpixel'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0);
    final curvature = ((parameters['curvature'] as num?)?.toDouble() ?? 0.12).clamp(0.0, 0.5);
    final vignette = ((parameters['vignette'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final brightnessBoost = ((parameters['brightnessBoost'] as num?)?.toDouble() ?? 0.15).clamp(0.0, 0.5);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final result = Uint32List(width * height);
    final centerX = (width - 1) / 2.0;
    final centerY = (height - 1) / 2.0;
    final invCenterX = centerX > 0 ? 1.0 / centerX : 1.0;
    final invCenterY = centerY > 0 ? 1.0 / centerY : 1.0;
    final hasCurvature = curvature > 0.001;

    for (int y = 0; y < height; y++) {
      final ny = (y - centerY) * invCenterY;
      final ny2 = ny * ny;

      // Scanline factor for this row
      final isScanline = (y % scanlineSpacing) == (scanlineSpacing - 1);
      final scanlineFactor = isScanline ? (1.0 - scanlineIntensity * 0.5) : 1.0;

      for (int x = 0; x < width; x++) {
        final outIndex = y * width + x;
        final nx = (x - centerX) * invCenterX;
        final r2 = nx * nx + ny2;

        int srcX = x;
        int srcY = y;
        bool isInsideScreen = true;

        if (hasCurvature) {
          // Barrel distortion: sample outward toward edges
          final distortion = 1.0 + curvature * r2;
          final mappedX = centerX + (x - centerX) * distortion;
          final mappedY = centerY + (y - centerY) * distortion;

          srcX = mappedX.round();
          srcY = mappedY.round();

          if (srcX < 0 || srcX >= width || srcY < 0 || srcY >= height) {
            isInsideScreen = false;
          }
        }

        if (!isInsideScreen) {
          result[outIndex] = preserveAlpha ? 0x00000000 : 0xFF000000;
          continue;
        }

        final inIndex = srcY * width + srcX;
        final pixel = pixels[inIndex];
        final a = (pixel >> 24) & 0xFF;

        if (a == 0 && preserveAlpha) {
          result[outIndex] = 0;
          continue;
        }

        var r = (pixel >> 16) & 0xFF;
        var g = (pixel >> 8) & 0xFF;
        var b = pixel & 0xFF;

        // 1. Scanline darkening
        double rf = r * scanlineFactor;
        double gf = g * scanlineFactor;
        double bf = b * scanlineFactor;

        // 2. RGB Phosphor subpixel mask
        if (rgbSubpixel > 0.001) {
          final phosphorCol = x % 3;
          final boost = 1.0 + rgbSubpixel * 0.25;
          final dim = 1.0 - rgbSubpixel * 0.12;

          if (phosphorCol == 0) {
            rf *= boost;
            gf *= dim;
            bf *= dim;
          } else if (phosphorCol == 1) {
            rf *= dim;
            gf *= boost;
            bf *= dim;
          } else {
            rf *= dim;
            gf *= dim;
            bf *= boost;
          }
        }

        // 3. Vignette (corner darkening)
        if (vignette > 0.001) {
          final vigFactor = (1.0 - (r2 * 0.45 * vignette)).clamp(0.1, 1.0);
          rf *= vigFactor;
          gf *= vigFactor;
          bf *= vigFactor;
        }

        // 4. Phosphor brightness boost
        if (brightnessBoost > 0.001) {
          final boost = 1.0 + brightnessBoost;
          rf *= boost;
          gf *= boost;
          bf *= boost;
        }

        final outR = rf.round().clamp(0, 255);
        final outG = gf.round().clamp(0, 255);
        final outB = bf.round().clamp(0, 255);
        final outA = a == 0 ? 255 : a;

        result[outIndex] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return result;
  }
}
