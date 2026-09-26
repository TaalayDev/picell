part of 'effects.dart';

/// Spawns stepped ghost afterimages of the sprite lagging behind along a motion
/// vector with chromatic color shifting, opacity decay, and Bayer dither dissolves.
class ChromaticEchoDashEffect extends Effect {
  ChromaticEchoDashEffect([Map<String, dynamic>? params])
      : super(
          EffectType.chromaticEchoDash,
          params ??
              {
                'motionAngle': 0.0,
                'echoCount': 3.0,
                'trailDistance': 12.0,
                'colorMode': 'chromaticRGB',
                'glowColor': 0xFF00E5FF,
                'ditherFade': true,
                'behindOnly': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'motionAngle': 0.0,
        'echoCount': 3.0,
        'trailDistance': 12.0,
        'colorMode': 'chromaticRGB',
        'glowColor': 0xFF00E5FF,
        'ditherFade': true,
        'behindOnly': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'motionAngle': {
          'label': 'Motion Direction',
          'description': 'Direction of movement in degrees. Ghost echoes trail in the opposite direction.',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'step': 5.0,
        },
        'echoCount': {
          'label': 'Echo Count',
          'description': 'Number of trailing ghost afterimages (1 to 6 echoes).',
          'type': 'slider',
          'min': 1.0,
          'max': 6.0,
          'step': 1.0,
        },
        'trailDistance': {
          'label': 'Trail Span Distance',
          'description': 'Total distance spanned by trailing afterimages in pixels.',
          'type': 'slider',
          'min': 4.0,
          'max': 32.0,
          'step': 1.0,
        },
        'colorMode': {
          'label': 'Echo Color Mode',
          'description': 'Visual appearance of ghost echoes (Chromatic RGB, Source Palette, or Spectral Glow).',
          'type': 'dropdown',
          'options': [
            {'value': 'chromaticRGB', 'label': 'Chromatic Shift (Cyan / Magenta / Amber)'},
            {'value': 'sourceAlpha', 'label': 'Source Palette (Fading Texture)'},
            {'value': 'spectralGlow', 'label': 'Spectral Energy (Monochrome Tint)'},
          ],
        },
        'glowColor': {
          'label': 'Spectral Glow Color',
          'description': 'Tint color when Spectral Energy mode is selected.',
          'type': 'color',
        },
        'ditherFade': {
          'label': 'Bayer Dither Dissolve',
          'description': 'Applies retro Bayer matrix dither dissolve to older trailing echoes.',
          'type': 'bool',
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'Keep sprite in the foreground; echoes only appear behind in empty space.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'motionAngle',
          label: 'Motion Direction',
          description: 'Direction of movement in degrees. Ghost echoes trail in the opposite direction.',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'echoCount',
          label: 'Echo Count',
          description: 'Number of trailing ghost afterimages (1 to 6 echoes).',
          min: 1.0,
          max: 6.0,
          divisions: 5,
          formatLabel: (v) => '${v.round()} ghosts',
        ),
        SliderField(
          key: 'trailDistance',
          label: 'Trail Span Distance',
          description: 'Total distance spanned by trailing afterimages in pixels.',
          min: 4.0,
          max: 32.0,
          divisions: 28,
          formatLabel: (v) => '${v.round()}px',
        ),
        const SelectField(
          key: 'colorMode',
          label: 'Echo Color Mode',
          description: 'Visual appearance of ghost echoes (Chromatic RGB, Source Palette, or Spectral Glow).',
          options: {
            'chromaticRGB': 'Chromatic Shift (Cyan / Magenta / Amber)',
            'sourceAlpha': 'Source Palette (Fading Texture)',
            'spectralGlow': 'Spectral Energy (Monochrome Tint)',
          },
        ),
        const ColorField(
          key: 'glowColor',
          label: 'Spectral Glow Color',
          description: 'Tint color when Spectral Energy mode is selected.',
        ),
        const BoolField(
          key: 'ditherFade',
          label: 'Bayer Dither Dissolve',
          description: 'Applies retro Bayer matrix dither dissolve to older trailing echoes.',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'Keep sprite in the foreground; echoes only appear behind in empty space.',
        ),
      ];

  static const List<int> _bayer4x4 = [
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5,
  ];

  static const List<int> _chromaticColors = [
    0xFF00E5FF, // Cyan
    0xFFFF007F, // Magenta / Rose
    0xFFFFD700, // Gold / Amber
    0xFF9400D3, // Violet
    0xFF00FF7F, // Spring Green
    0xFFFF7F50, // Coral
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double motionAngleDeg = ((parameters['motionAngle'] as num?)?.toDouble() ?? 0.0) % 360.0;
    final int count = ((parameters['echoCount'] as num?)?.toDouble() ?? 3.0).round().clamp(1, 6);
    final double maxDist = ((parameters['trailDistance'] as num?)?.toDouble() ?? 12.0).clamp(4.0, 32.0);
    final String mode = parameters['colorMode'] as String? ?? 'chromaticRGB';
    final int glowVal = (parameters['glowColor'] as num?)?.toInt() ?? 0xFF00E5FF;
    final bool dither = parameters['ditherFade'] as bool? ?? true;
    final bool behindOnly = parameters['behindOnly'] as bool? ?? true;

    final int glowR = (glowVal >> 16) & 0xFF;
    final int glowG = (glowVal >> 8) & 0xFF;
    final int glowB = glowVal & 0xFF;

    // Movement vector
    final double rad = motionAngleDeg * (math.pi / 180.0);
    final double trailX = -math.cos(rad);
    final double trailY = -math.sin(rad);

    // Render echoes from furthest (oldest) to closest (newest)
    for (int k = count; k >= 1; k--) {
      final double progress = k / count.toDouble(); // 1.0 (furthest) down to 1/count (closest)
      final double dist = maxDist * progress;
      final int offX = (trailX * dist).round();
      final int offY = (trailY * dist).round();

      // Decay opacity with distance
      final double alphaScale = (1.0 - progress * 0.65).clamp(0.15, 0.95);

      // Resolve color for this echo
      int echoR = 255;
      int echoG = 255;
      int echoB = 255;

      if (mode == 'chromaticRGB') {
        final int cIdx = (k - 1) % _chromaticColors.length;
        final int cVal = _chromaticColors[cIdx];
        echoR = (cVal >> 16) & 0xFF;
        echoG = (cVal >> 8) & 0xFF;
        echoB = cVal & 0xFF;
      } else if (mode == 'spectralGlow') {
        echoR = glowR;
        echoG = glowG;
        echoB = glowB;
      }

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int srcIdx = y * width + x;
          final int srcPixel = pixels[srcIdx];
          final int srcA = (srcPixel >> 24) & 0xFF;
          if (srcA == 0) continue;

          final int tx = x + offX;
          final int ty = y + offY;
          if (tx < 0 || tx >= width || ty < 0 || ty >= height) continue;

          final int targetIdx = ty * width + tx;

          // If behindOnly is true, do not draw under opaque sprite pixels
          if (behindOnly && ((pixels[targetIdx] >> 24) & 0xFF) > 0) {
            continue;
          }

          // Bayer dither dissolve on older echoes
          if (dither && k >= 2) {
            final int bx = tx & 3;
            final int by = ty & 3;
            final int bVal = _bayer4x4[by * 4 + bx];
            final double ditherThreshold = (1.0 - progress * 0.6) * 16.0;
            if (bVal >= ditherThreshold) {
              continue;
            }
          }

          final int outA = (srcA * alphaScale).round().clamp(10, 255);

          int outR = echoR;
          int outG = echoG;
          int outB = echoB;

          if (mode == 'sourceAlpha') {
            outR = (srcPixel >> 16) & 0xFF;
            outG = (srcPixel >> 8) & 0xFF;
            outB = srcPixel & 0xFF;
          }

          _blendPixel(output, targetIdx, outR, outG, outB, outA);
        }
      }
    }

    // Finally, draw original sprite on top
    for (int i = 0; i < pixels.length; i++) {
      final int p = pixels[i];
      final int a = (p >> 24) & 0xFF;
      if (a > 0) {
        if (behindOnly || a == 255) {
          output[i] = p;
        } else {
          final double srcA = a / 255.0;
          final int bgP = output[i];
          final int bgR = (bgP >> 16) & 0xFF;
          final int bgG = (bgP >> 8) & 0xFF;
          final int bgB = bgP & 0xFF;
          final int bgA = (bgP >> 24) & 0xFF;

          final int r = (((p >> 16) & 0xFF) * srcA + bgR * (1.0 - srcA)).round();
          final int g = (((p >> 8) & 0xFF) * srcA + bgG * (1.0 - srcA)).round();
          final int b = ((p & 0xFF) * srcA + bgB * (1.0 - srcA)).round();
          final int outA = math.max(a, bgA);
          output[i] = (outA << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static void _blendPixel(Uint32List buffer, int idx, int r, int g, int b, int a) {
    final int curP = buffer[idx];
    final int curA = (curP >> 24) & 0xFF;
    if (curA == 0) {
      buffer[idx] = (a << 24) | (r << 16) | (g << 8) | b;
    } else {
      final int curR = (curP >> 16) & 0xFF;
      final int curG = (curP >> 8) & 0xFF;
      final int curB = curP & 0xFF;

      final double na = a / 255.0;
      final int outR = ((curR * (1.0 - na * 0.7)) + (r * na)).round().clamp(0, 255);
      final int outG = ((curG * (1.0 - na * 0.7)) + (g * na)).round().clamp(0, 255);
      final int outB = ((curB * (1.0 - na * 0.7)) + (b * na)).round().clamp(0, 255);
      final int outA = math.max(curA, a);

      buffer[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }
  }
}
