part of 'effects.dart';

/// Procedural hologram glitch and projection flicker effect featuring horizontal
/// scanline raster, slice jitter displacement, beam luminosity flicker, and phosphor tinting.
class HologramGlitchEffect extends Effect implements UIFieldProvider {
  HologramGlitchEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.hologramGlitch,
          parameters ??
              const {
                'holoColor': 0xFF00E5FF,
                'colorIntensity': 0.75,
                'scanlineDensity': 2,
                'flickerInterval': 1.5,
                'glitchDropout': 0.3,
                'jitterSpread': 2,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'holoColor': 0xFF00E5FF,
        'colorIntensity': 0.75,
        'scanlineDensity': 2,
        'flickerInterval': 1.5,
        'glitchDropout': 0.3,
        'jitterSpread': 2,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'holoColor': {
          'label': 'Holo Phosphor Color',
          'description': 'Monochromatic phosphor hue of the projection beam.',
          'type': 'color',
        },
        'colorIntensity': {
          'label': 'Phosphor Tint Depth',
          'description': 'Depth of conversion from original colors to hologram beam.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 18,
        },
        'scanlineDensity': {
          'label': 'Scanline Pitch',
          'description': 'Row interval of the holographic CRT raster lines.',
          'type': 'slider',
          'min': 2,
          'max': 6,
          'divisions': 4,
        },
        'flickerInterval': {
          'label': 'Beam Flicker Rate',
          'description': 'Speed of projection luminosity flutter and power drops.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'glitchDropout': {
          'label': 'Glitch Dropout & Tears',
          'description': 'Frequency of signal corruption, dropouts, and slice tearing.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'jitterSpread': {
          'label': 'Slice Jitter Amplitude',
          'description': 'Maximum horizontal displacement of glitching raster lines.',
          'type': 'slider',
          'min': 0,
          'max': 6,
          'divisions': 6,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for flicker and glitch cycles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Keep background transparent around the holographic silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const ColorField(
          key: 'holoColor',
          label: 'Hologram Color',
          description: 'Color of the projection laser beam.',
        ),
        SliderField(
          key: 'colorIntensity',
          label: 'Phosphor Tint',
          description: 'Intensity of holographic monochrome tint.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'scanlineDensity',
          label: 'Scanline Pitch',
          description: 'Row spacing of raster lines.',
          min: 2,
          max: 6,
          divisions: 4,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'flickerInterval',
          label: 'Flicker Frequency',
          description: 'Speed of projector flutter.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'glitchDropout',
          label: 'Glitch Rate',
          description: 'Rate of horizontal tear disruptions.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'jitterSpread',
          label: 'Jitter Offset',
          description: 'Maximum horizontal shift of teared slices.',
          min: 0,
          max: 6,
          divisions: 6,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the hologram flutter cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep transparency outside the projection contour.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final holoColorInt = (parameters['holoColor'] as num?)?.toInt() ?? 0xFF00E5FF;
    final colorIntensity = (parameters['colorIntensity'] as num?)?.toDouble() ?? 0.75;
    final scanlineDensity = (parameters['scanlineDensity'] as num?)?.toInt() ?? 2;
    final flickerInterval = (parameters['flickerInterval'] as num?)?.toDouble() ?? 1.5;
    final glitchDropout = (parameters['glitchDropout'] as num?)?.toDouble() ?? 0.3;
    final jitterSpread = (parameters['jitterSpread'] as num?)?.toInt() ?? 2;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List(width * height);

    final hA = (holoColorInt >> 24) & 0xFF;
    final hR = (holoColorInt >> 16) & 0xFF;
    final hG = (holoColorInt >> 8) & 0xFF;
    final hB = holoColorInt & 0xFF;

    // Temporal beam flicker: combination of macro oscillation and high-frequency flutter
    final flickerSin = math.sin(time * math.pi * 2.0 * flickerInterval * 3.0);
    final microFlutter = math.sin(time * 61.43 + 3.14) * 0.15;
    final beamBrightness = (0.85 + 0.15 * flickerSin + microFlutter).clamp(0.4, 1.3);

    // Frame quantum for glitch steps (changes ~15 times per unit time)
    final glitchFrame = (time * 15.0).floor();

    // Traveling vertical beam raster bar
    final rollOffset = (time * height * 1.5).round() % height;

    for (int y = 0; y < height; y++) {
      // Check if this row undergoes horizontal jitter slice tear
      int rowShift = 0;
      bool isDropoutRow = false;

      if (glitchDropout > 0.01 && jitterSpread > 0) {
        final rowSeed = (y * 17 + glitchFrame * 131) % 1000;
        final glitchThreshold = (1.0 - glitchDropout * 0.4) * 1000;
        if (rowSeed > glitchThreshold) {
          final sign = (rowSeed % 2 == 0) ? 1 : -1;
          rowShift = sign * (1 + (rowSeed % jitterSpread));
          if (rowSeed > glitchThreshold + 150) {
            isDropoutRow = true;
          }
        }
      }

      // Scanline attenuation
      final isScanline = (y % scanlineDensity) == 0;
      final scanlineMul = isScanline ? 0.6 : 1.0;

      // Soft vertical raster roll bar
      final distFromRoll = ((y - rollOffset).abs() % height).toDouble();
      final rollGlow = distFromRoll < 3 ? (1.0 - distFromRoll / 3.0) * 0.25 : 0.0;

      for (int x = 0; x < width; x++) {
        final outIdx = y * width + x;

        // Sample with slice jitter displacement
        final srcX = (x - rowShift).clamp(0, width - 1);
        final srcIdx = y * width + srcX;
        final origPixel = pixels[srcIdx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[outIdx] = 0x00000000;
          continue;
        }

        if (isDropoutRow && ((x + glitchFrame) % 3 == 0)) {
          // Pixel dropout
          output[outIdx] = preserveAlpha ? 0x00000000 : 0x00000000;
          continue;
        }

        final oR = (origPixel >> 16) & 0xFF;
        final oG = (origPixel >> 8) & 0xFF;
        final oB = origPixel & 0xFF;

        // Luminance calculation
        final lum = 0.299 * oR + 0.587 * oG + 0.114 * oB;

        // Tinted phosphor values
        final phosphorR = ((lum / 255.0) * hR).clamp(0.0, 255.0);
        final phosphorG = ((lum / 255.0) * hG).clamp(0.0, 255.0);
        final phosphorB = ((lum / 255.0) * hB).clamp(0.0, 255.0);

        // Blend between original and holo phosphor
        final blendedR = oR * (1.0 - colorIntensity) + phosphorR * colorIntensity;
        final blendedG = oG * (1.0 - colorIntensity) + phosphorG * colorIntensity;
        final blendedB = oB * (1.0 - colorIntensity) + phosphorB * colorIntensity;

        // Apply scanline multiplier, beam flicker, and roll glow
        final finalR = ((blendedR * scanlineMul * beamBrightness) + 255 * rollGlow).round().clamp(0, 255);
        final finalG = ((blendedG * scanlineMul * beamBrightness) + 255 * rollGlow).round().clamp(0, 255);
        final finalB = ((blendedB * scanlineMul * beamBrightness) + 255 * rollGlow).round().clamp(0, 255);

        final finalA = preserveAlpha
            ? (origA * beamBrightness).round().clamp(0, 255)
            : (math.max(origA, (hA * 0.15).round()) * beamBrightness).round().clamp(0, 255);

        output[outIdx] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return output;
  }
}
