part of 'effects.dart';

/// Spawns expanding perspective concentric water ripples and a dithered inverted
/// reflection shimmer beneath the sprite's feet in shallow water.
class WaterRippleWakeEffect extends Effect {
  WaterRippleWakeEffect([Map<String, dynamic>? params])
      : super(
          EffectType.waterRippleWake,
          params ??
              {
                'rippleRadius': 12.0,
                'waveCount': 3,
                'reflectionDepth': 4.0,
                'waterPalette': 'springWater',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'rippleRadius': 12.0,
        'waveCount': 3,
        'reflectionDepth': 4.0,
        'waterPalette': 'springWater',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'rippleRadius': {
          'label': 'Ripple Expansion Radius',
          'description': 'Horizontal reach of the outermost water ripple ring.',
          'type': 'slider',
          'min': 4.0,
          'max': 24.0,
          'step': 1.0,
        },
        'waveCount': {
          'label': 'Concentric Wave Rings',
          'description': 'Number of concentric ripples expanding from the feet.',
          'type': 'slider',
          'min': 1.0,
          'max': 6.0,
          'step': 1.0,
        },
        'reflectionDepth': {
          'label': 'Mirror Reflection Depth',
          'description': 'Vertical depth of the inverted shimmering foot reflection.',
          'type': 'slider',
          'min': 0.0,
          'max': 8.0,
          'step': 0.5,
        },
        'waterPalette': {
          'label': 'Water Basin Palette',
          'description': 'Color frequency and clarity of the water pool.',
          'type': 'dropdown',
          'options': [
            {'value': 'springWater', 'label': 'Spring Water (Pure Cyan / Azure / Deep Cobalt)'},
            {'value': 'toxicSwamp', 'label': 'Toxic Swamp (Murky Jade / Slime Green / Dark Muck)'},
            {'value': 'bloodPool', 'label': 'Blood Pool (Crimson Crest / Deep Wine / Dark Clot)'},
            {'value': 'abyssalVoid', 'label': 'Abyssal Void (Ethereal Violet / Indigo / Cosmic Dark)'},
          ],
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders ripples strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'rippleRadius',
          label: 'Ripple Expansion Radius',
          description: 'Horizontal reach of the outermost water ripple ring.',
          min: 4.0,
          max: 24.0,
          divisions: 20,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'waveCount',
          label: 'Concentric Wave Rings',
          description: 'Number of concentric ripples expanding from the feet.',
          min: 1.0,
          max: 6.0,
          divisions: 5,
          formatLabel: (v) => '${v.round()} rings',
        ),
        SliderField(
          key: 'reflectionDepth',
          label: 'Mirror Reflection Depth',
          description: 'Vertical depth of the inverted shimmering foot reflection.',
          min: 0.0,
          max: 8.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'waterPalette',
          label: 'Water Basin Palette',
          description: 'Color frequency and clarity of the water pool.',
          options: {
            'springWater': 'Spring Water (Cyan / Azure / Deep Cobalt)',
            'toxicSwamp': 'Toxic Swamp (Murky Jade / Slime Green)',
            'bloodPool': 'Blood Pool (Crimson / Deep Wine / Clot)',
            'abyssalVoid': 'Abyssal Void (Violet / Indigo / Cosmic)',
          },
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders ripples strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final rippleRadius = ((parameters['rippleRadius'] as num?)?.toDouble() ?? 12.0).clamp(4.0, 24.0);
    final waveCount = ((parameters['waveCount'] as num?)?.toInt() ?? 3).clamp(1, 6);
    final reflectionDepth = ((parameters['reflectionDepth'] as num?)?.toDouble() ?? 4.0).clamp(0.0, 8.0);
    final paletteKey = parameters['waterPalette'] as String? ?? 'springWater';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // 1. Locate bottom baseline and foot center
    int maxY = -1;
    for (int y = height - 1; y >= 0; y--) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          maxY = y;
          break;
        }
      }
      if (maxY != -1) break;
    }

    if (maxY == -1) return output;

    double sumX = 0;
    int countX = 0;
    for (int y = math.max(0, maxY - 1); y <= maxY; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          sumX += x;
          countX++;
        }
      }
    }

    if (countX == 0) return output;

    final centerX = sumX / countX;
    final baseY = maxY.toDouble() + 1.0;
    final colors = _getWaterColors(paletteKey);

    const bayer4x4 = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5],
    ];

    // Elliptical perspective aspect ratio for ground water plane
    const aspectY = 0.35;
    final radiusY = rippleRadius * aspectY;

    // 2. Render concentric ripples on ground plane
    final minPy = (baseY - radiusY).floor().clamp(0, height - 1);
    final maxPy = (baseY + radiusY + 1).ceil().clamp(0, height - 1);
    final minPx = (centerX - rippleRadius - 1).floor().clamp(0, width - 1);
    final maxPx = (centerX + rippleRadius + 1).ceil().clamp(0, width - 1);

    for (int py = minPy; py <= maxPy; py++) {
      for (int px = minPx; px <= maxPx; px++) {
        final idx = py * width + px;
        final orig = pixels[idx];
        if (behindOnly && ((orig >> 24) & 0xFF) > 30) {
          continue;
        }

        final dx = px - centerX;
        final dy = (py - baseY) / aspectY;
        final r = math.sqrt(dx * dx + dy * dy);

        if (r <= rippleRadius) {
          final normR = r / rippleRadius;
          final env = (1.0 - normR).clamp(0.0, 1.0);

          // Sine oscillation for concentric ripple crests and troughs
          final phase = normR * waveCount * 2.0 * math.pi;
          final sineVal = math.sin(phase);

          int waveColor;
          int waveAlpha = 0;

          if (sineVal > 0.55) {
            // Luminous ripple crest highlight
            waveColor = (sineVal > 0.85) ? colors.specular : colors.crest;
            waveAlpha = (220 * env * ((sineVal - 0.55) / 0.45)).toInt();
          } else if (sineVal < -0.55) {
            // Deep trough shadow
            waveColor = colors.trough;
            waveAlpha = (180 * env * ((-sineVal - 0.55) / 0.45)).toInt();
          } else {
            // Soft mid-water sheen
            waveColor = colors.body;
            waveAlpha = (70 * env).toInt();
          }

          if (waveAlpha > 15) {
            final tinted = (waveAlpha.clamp(0, 255) << 24) | (waveColor & 0x00FFFFFF);
            output[idx] = _blendPixel(output[idx], tinted);
          }
        }
      }
    }

    // 3. Inverted shimmering mirror reflection beneath feet
    if (reflectionDepth > 0.0) {
      final maxReflectY = (baseY + reflectionDepth).round().clamp(0, height - 1);

      for (int py = (baseY).round(); py <= maxReflectY; py++) {
        final distY = py - maxY;
        final sampleY = (maxY - distY).clamp(0, height - 1);

        // Sinusoidal water ripple displacement
        final rippleShift = (math.sin(py * 1.5) * 1.1).round();

        for (int px = 0; px < width; px++) {
          final sampleX = (px + rippleShift).clamp(0, width - 1);
          final sprPixel = pixels[sampleY * width + sampleX];
          final sprAlpha = (sprPixel >> 24) & 0xFF;

          if (sprAlpha > 20) {
            final idx = py * width + px;
            if (behindOnly && ((pixels[idx] >> 24) & 0xFF) > 30) {
              continue;
            }

            final bayerVal = bayer4x4[py % 4][px % 4] / 16.0;
            final reflectFalloff = 1.0 - (distY / (reflectionDepth + 1.0));

            if (reflectFalloff * 0.7 > bayerVal * 0.5) {
              // Blend sprite color with water tint
              final sr = (sprPixel >> 16) & 0xFF;
              final sg = (sprPixel >> 8) & 0xFF;
              final sb = sprPixel & 0xFF;

              final wr = (colors.body >> 16) & 0xFF;
              final wg = (colors.body >> 8) & 0xFF;
              final wb = colors.body & 0xFF;

              final mr = ((sr * 0.5 + wr * 0.5)).round().clamp(0, 255);
              final mg = ((sg * 0.5 + wg * 0.5)).round().clamp(0, 255);
              final mb = ((sb * 0.5 + wb * 0.5)).round().clamp(0, 255);
              final ma = (160 * reflectFalloff).round().clamp(0, 255);

              final reflected = (ma << 24) | (mr << 16) | (mg << 8) | mb;
              output[idx] = _blendPixel(output[idx], reflected);
            }
          }
        }
      }
    }

    return output;
  }

  int _blendPixel(int dst, int src) {
    final sa = (src >> 24) & 0xFF;
    if (sa == 0) return dst;
    if (sa == 255) return src;
    final da = (dst >> 24) & 0xFF;
    if (da == 0) return src;

    final sf = sa / 255.0;
    final df = (da / 255.0) * (1.0 - sf);
    final outA = sf + df;
    if (outA <= 0.0) return 0;

    final sr = (src >> 16) & 0xFF;
    final sg = (src >> 8) & 0xFF;
    final sb = src & 0xFF;

    final dr = (dst >> 16) & 0xFF;
    final dg = (dst >> 8) & 0xFF;
    final db = dst & 0xFF;

    final r = ((sr * sf + dr * df) / outA).round().clamp(0, 255);
    final g = ((sg * sf + dg * df) / outA).round().clamp(0, 255);
    final b = ((sb * sf + db * df) / outA).round().clamp(0, 255);
    final a = (outA * 255.0).round().clamp(0, 255);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  _WaterColors _getWaterColors(String palette) {
    switch (palette) {
      case 'toxicSwamp':
        return const _WaterColors(
          specular: 0xFFCCFF90,
          crest: 0xFF00E676,
          body: 0xFF1B5E20,
          trough: 0xFF003300,
        );
      case 'bloodPool':
        return const _WaterColors(
          specular: 0xFFFFCDD2,
          crest: 0xFFFF1744,
          body: 0xFF880E4F,
          trough: 0xFF310008,
        );
      case 'abyssalVoid':
        return const _WaterColors(
          specular: 0xFFEDE7F6,
          crest: 0xFFBA68C8,
          body: 0xFF311B92,
          trough: 0xFF0A001A,
        );
      case 'springWater':
      default:
        return const _WaterColors(
          specular: 0xFFFFFFFF,
          crest: 0xFFE0F7FA,
          body: 0xFF29B6F6,
          trough: 0xFF0277BD,
        );
    }
  }
}

class _WaterColors {
  final int specular;
  final int crest;
  final int body;
  final int trough;

  const _WaterColors({
    required this.specular,
    required this.crest,
    required this.body,
    required this.trough,
  });
}
