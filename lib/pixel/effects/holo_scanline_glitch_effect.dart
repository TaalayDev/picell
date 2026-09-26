part of 'effects.dart';

/// Applies horizontal holographic phosphor scanlines, pseudo-random slice
/// displacement jitter, chromatic aberration color splitting, and holographic tinting.
class HoloScanlineGlitchEffect extends Effect {
  HoloScanlineGlitchEffect([Map<String, dynamic>? params])
      : super(
          EffectType.holoScanlineGlitch,
          params ??
              {
                'scanlineGap': 2.0,
                'scanlineOpacity': 0.35,
                'glitchIntensity': 3.0,
                'chromaticSplit': true,
                'holoPalette': 'holoCyan',
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'scanlineGap': 2.0,
        'scanlineOpacity': 0.35,
        'glitchIntensity': 3.0,
        'chromaticSplit': true,
        'holoPalette': 'holoCyan',
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'scanlineGap': {
          'label': 'Scanline Interval',
          'description': 'Vertical spacing in pixels between holographic scanlines.',
          'type': 'slider',
          'min': 2.0,
          'max': 6.0,
          'step': 1.0,
        },
        'scanlineOpacity': {
          'label': 'Scanline Depth',
          'description': 'Darkness of the horizontal CRT/holographic scanline grooves.',
          'type': 'slider',
          'min': 0.1,
          'max': 0.8,
          'step': 0.05,
        },
        'glitchIntensity': {
          'label': 'Glitch Shift Shear',
          'description': 'Maximum horizontal displacement distance of corrupted glitch slices.',
          'type': 'slider',
          'min': 0.0,
          'max': 8.0,
          'step': 1.0,
        },
        'chromaticSplit': {
          'label': 'Chromatic Aberration',
          'description': 'Splits RGB color channels horizontally on jittered slice bands.',
          'type': 'bool',
        },
        'holoPalette': {
          'label': 'Holo Phosphor Theme',
          'description': 'Holographic projection tint and phosphor glow palette.',
          'type': 'select',
          'options': {
            'holoCyan': 'Holo Cyan (Cyber Blue)',
            'vividMagenta': 'Vivid Magenta (Neon Violet)',
            'terminalAmber': 'Terminal Amber (CRT Orange)',
            'ghostEmerald': 'Ghost Emerald (Matrix Green)',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Silhouette',
          'description': 'Restricts all holographic distortion strictly to active sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'scanlineGap',
          label: 'Scanline Interval',
          min: 2.0,
          max: 6.0,
        ),
        SliderField(
          key: 'scanlineOpacity',
          label: 'Scanline Depth',
          min: 0.1,
          max: 0.8,
        ),
        SliderField(
          key: 'glitchIntensity',
          label: 'Glitch Shift Shear',
          min: 0.0,
          max: 8.0,
        ),
        BoolField(
          key: 'chromaticSplit',
          label: 'Chromatic Aberration',
        ),
        SelectField(
          key: 'holoPalette',
          label: 'Holo Phosphor Theme',
          options: <String, String>{
            'holoCyan': 'Holo Cyan (Cyber Blue)',
            'vividMagenta': 'Vivid Magenta (Neon Violet)',
            'terminalAmber': 'Terminal Amber (CRT Orange)',
            'ghostEmerald': 'Ghost Emerald (Matrix Green)',
          },
        ),
        BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Silhouette',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final scanlineGap = (parameters['scanlineGap'] as num?)?.toInt().clamp(2, 8) ?? 2;
    final scanlineOpacity = (parameters['scanlineOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.35;
    final glitchIntensity = (parameters['glitchIntensity'] as num?)?.toInt().clamp(0, 16) ?? 3;
    final chromaticSplit = parameters['chromaticSplit'] as bool? ?? true;
    final holoPalette = parameters['holoPalette'] as String? ?? 'holoCyan';
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List(width * height);

    // Phosphor tint RGB components
    final int tintR;
    final int tintG;
    final int tintB;

    switch (holoPalette) {
      case 'vividMagenta':
        tintR = 255;
        tintG = 30;
        tintB = 200;
        break;
      case 'terminalAmber':
        tintR = 255;
        tintG = 176;
        tintB = 0;
        break;
      case 'ghostEmerald':
        tintR = 20;
        tintG = 255;
        tintB = 110;
        break;
      case 'holoCyan':
      default:
        tintR = 0;
        tintG = 240;
        tintB = 255;
        break;
    }

    int getSourcePixel(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return 0;
      return pixels[y * width + x];
    }

    for (int y = 0; y < height; y++) {
      // Deterministic pseudo-random row hash for slice jitter
      final rowHash = ((y * 2654435761) ^ (y >> 2)) & 0xFFFFFFFF;
      final bool isGlitchRow = glitchIntensity > 0 && ((rowHash % 13) < 3);

      int shift = 0;
      if (isGlitchRow) {
        final rawShift = (rowHash % (glitchIntensity * 2 + 1)) - glitchIntensity;
        shift = rawShift == 0 ? (rowHash % 2 == 0 ? 1 : -1) : rawShift;
      }

      final bool isScanline = (y % scanlineGap) == 0;
      final scanDim = 1.0 - scanlineOpacity;

      final rowOffset = y * width;

      for (int x = 0; x < width; x++) {
        final originalPx = pixels[rowOffset + x];
        final origA = (originalPx >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[rowOffset + x] = 0;
          continue;
        }

        // Horizontal sample coordinates with shift
        final sampleX = x - shift;

        int finalR;
        int finalG;
        int finalB;
        int finalA;

        if (chromaticSplit && isGlitchRow) {
          // Chromatic aberration: split Red to the right and Blue to the left
          final redPx = getSourcePixel(sampleX + 1, y);
          final greenPx = getSourcePixel(sampleX, y);
          final bluePx = getSourcePixel(sampleX - 1, y);

          final rA = (redPx >> 24) & 0xFF;
          final gA = (greenPx >> 24) & 0xFF;
          final bA = (bluePx >> 24) & 0xFF;

          finalR = (redPx >> 16) & 0xFF;
          finalG = (greenPx >> 8) & 0xFF;
          finalB = bluePx & 0xFF;
          finalA = ((rA + gA + bA) ~/ 3).clamp(0, 255);
        } else {
          final centerPx = getSourcePixel(sampleX, y);
          finalA = (centerPx >> 24) & 0xFF;
          finalR = (centerPx >> 16) & 0xFF;
          finalG = (centerPx >> 8) & 0xFF;
          finalB = centerPx & 0xFF;
        }

        if (finalA == 0) {
          output[rowOffset + x] = 0;
          continue;
        }

        // Apply holographic phosphor tint (15% tint blend)
        final blendedR = ((finalR * 85 + tintR * 15) ~/ 100).clamp(0, 255);
        final blendedG = ((finalG * 85 + tintG * 15) ~/ 100).clamp(0, 255);
        final blendedB = ((finalB * 85 + tintB * 15) ~/ 100).clamp(0, 255);

        // Apply scanline dimming
        int outR = blendedR;
        int outG = blendedG;
        int outB = blendedB;

        if (isScanline) {
          outR = (blendedR * scanDim).round().clamp(0, 255);
          outG = (blendedG * scanDim).round().clamp(0, 255);
          outB = (blendedB * scanDim).round().clamp(0, 255);
        }

        // Subtle micro noise dropout on glitch rows
        if (isGlitchRow && ((x + y * 7) % 11 == 0)) {
          outR = (outR * 1.3).round().clamp(0, 255);
          outG = (outG * 1.3).round().clamp(0, 255);
          outB = (outB * 1.3).round().clamp(0, 255);
        }

        output[rowOffset + x] = (finalA << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return output;
  }
}
