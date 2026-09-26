part of 'effects.dart';

/// Spawns hovering spectral spirit skulls and ghostly wisps with hollow glowing
/// eyes and trailing ectoplasm vapor tails circling around the character's upper body.
class LostSoulWispsEffect extends Effect {
  LostSoulWispsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.lostSoulWisps,
          params ??
              {
                'soulCount': 4,
                'wispDistance': 9.0,
                'tailLength': 6.0,
                'spectralPalette': 'ghastlyCyan',
                'eyeGlow': true,
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'soulCount': 4,
        'wispDistance': 9.0,
        'tailLength': 6.0,
        'spectralPalette': 'ghastlyCyan',
        'eyeGlow': true,
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'soulCount': {
          'label': 'Spectral Soul Count',
          'description': 'Number of haunting spirit wisps circling the character.',
          'type': 'slider',
          'min': 2.0,
          'max': 7.0,
          'step': 1.0,
        },
        'wispDistance': {
          'label': 'Orbit Distance',
          'description': 'Orbital radius of spirits circling the head and upper body.',
          'type': 'slider',
          'min': 4.0,
          'max': 18.0,
          'step': 1.0,
        },
        'tailLength': {
          'label': 'Ghost Vapor Tail Length',
          'description': 'Length of undulating ethereal vapor trailing behind each wisp.',
          'type': 'slider',
          'min': 3.0,
          'max': 12.0,
          'step': 0.5,
        },
        'spectralPalette': {
          'label': 'Spectral Wisp Palette',
          'description': 'Ectoplasmic color theme and spirit luminescence.',
          'type': 'dropdown',
          'options': [
            {'value': 'ghastlyCyan', 'label': 'Ghastly Cyan (Pale Ectoplasm / Ghost Cyan / Cobalt Void)'},
            {'value': 'bansheeGreen', 'label': 'Banshee Green (Phantom Lime / Emerald / Abyssal Green)'},
            {'value': 'tormentCrimson', 'label': 'Torment Crimson (Ghost Pink / Torment Scarlet / Blood Void)'},
            {'value': 'phantomPurple', 'label': 'Phantom Nether (Mystic Lavender / Neon Magenta / Warp Void)'},
          ],
        },
        'eyeGlow': {
          'label': 'Hollow Eye Sockets & Mouth',
          'description': 'Carves eerie hollow facial voids and wailing mouths into the skulls.',
          'type': 'bool',
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders spirits strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'soulCount',
          label: 'Spectral Soul Count',
          description: 'Number of haunting spirit wisps circling the character.',
          min: 2.0,
          max: 7.0,
          divisions: 5,
          formatLabel: (v) => '${v.round()} souls',
        ),
        SliderField(
          key: 'wispDistance',
          label: 'Orbit Distance',
          description: 'Orbital radius of spirits circling the head and upper body.',
          min: 4.0,
          max: 18.0,
          divisions: 14,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'tailLength',
          label: 'Ghost Vapor Tail Length',
          description: 'Length of undulating ethereal vapor trailing behind each wisp.',
          min: 3.0,
          max: 12.0,
          divisions: 18,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'spectralPalette',
          label: 'Spectral Wisp Palette',
          description: 'Ectoplasmic color theme and spirit luminescence.',
          options: {
            'ghastlyCyan': 'Ghastly Cyan (Pale Ectoplasm / Ghost Cyan)',
            'bansheeGreen': 'Banshee Green (Phantom Lime / Emerald)',
            'tormentCrimson': 'Torment Crimson (Ghost Pink / Scarlet)',
            'phantomPurple': 'Phantom Nether (Lavender / Neon Magenta)',
          },
        ),
        const BoolField(
          key: 'eyeGlow',
          label: 'Hollow Eye Sockets & Mouth',
          description: 'Carves eerie hollow facial voids and wailing mouths into the skulls.',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders spirits strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final soulCount = ((parameters['soulCount'] as num?)?.toInt() ?? 4).clamp(2, 7);
    final wispDistance = ((parameters['wispDistance'] as num?)?.toDouble() ?? 9.0).clamp(4.0, 18.0);
    final tailLength = ((parameters['tailLength'] as num?)?.toDouble() ?? 6.0).clamp(3.0, 12.0);
    final paletteKey = parameters['spectralPalette'] as String? ?? 'ghastlyCyan';
    final eyeGlow = parameters['eyeGlow'] as bool? ?? true;
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // 1. Identify upper-body / crown centroid
    int minY = height, maxY = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (minY >= maxY) return output;

    // Head center X
    double sumX = 0;
    int countX = 0;
    final upperY = minY + ((maxY - minY) * 0.45).round();
    for (int y = minY; y <= upperY; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          sumX += x;
          countX++;
        }
      }
    }

    final centerX = countX > 0 ? (sumX / countX) : (width * 0.5);
    final centerY = minY + (maxY - minY) * 0.3;

    final colors = _getSoulColors(paletteKey);

    void setSoulPixel(int x, int y, int color) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (behindOnly && ((pixels[idx] >> 24) & 0xFF) > 30) return;
      output[idx] = _blendPixel(output[idx], color);
    }

    // 2. Position and render each wandering soul wisp
    final stepAngle = (2.0 * math.pi) / soulCount;
    final rx = wispDistance * 1.15;
    final ry = wispDistance * 0.75;

    for (int i = 0; i < soulCount; i++) {
      final angle = i * stepAngle - 0.45;
      final hx = (centerX + math.cos(angle) * rx).round();
      final hy = (centerY + math.sin(angle) * ry).round();

      // Tangent vector for tail direction (orbiting counter-clockwise)
      final tx = -math.sin(angle);
      final ty = math.cos(angle);

      // A. Undulating trailing ectoplasm vapor tail
      final tailSteps = tailLength.round();
      for (int t = 1; t <= tailSteps; t++) {
        final progress = t / tailSteps;
        final waveOffset = math.sin(t * 0.9 + i) * 0.8;
        // Tail trails in opposite tangent direction
        final px = (hx - tx * t * 1.1 + ty * waveOffset).round();
        final py = (hy - ty * t * 1.1 - tx * waveOffset - (t * 0.2)).round();

        final alpha = (190 * (1.0 - progress)).toInt().clamp(0, 255);
        if (alpha > 20) {
          setSoulPixel(px, py, (alpha << 24) | (colors.tail & 0x00FFFFFF));
          if (progress < 0.6) {
            setSoulPixel(px + 1, py, ((alpha * 0.6).toInt() << 24) | (colors.halo & 0x00FFFFFF));
          }
        }
      }

      // B. Spirit skull head (circular disc of radius ~2px)
      for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          final distSq = dx * dx + dy * dy;
          if (distSq <= 5) {
            final isEdge = distSq >= 4;
            final headColor = isEdge ? colors.halo : colors.core;
            final headAlpha = isEdge ? 210 : 255;
            setSoulPixel(hx + dx, hy + dy, (headAlpha << 24) | (headColor & 0x00FFFFFF));
          }
        }
      }

      // C. Hollow facial voids (eyes and wailing mouth)
      if (eyeGlow) {
        // Left eye
        setSoulPixel(hx - 1, hy - 0, (255 << 24) | (colors.voidHole & 0x00FFFFFF));
        // Right eye
        setSoulPixel(hx + 1, hy - 0, (255 << 24) | (colors.voidHole & 0x00FFFFFF));
        // Open mouth
        setSoulPixel(hx, hy + 1, (240 << 24) | (colors.voidHole & 0x00FFFFFF));
        // Specular spark on crown
        setSoulPixel(hx, hy - 2, (255 << 24) | (colors.sparkle & 0x00FFFFFF));
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

  _SoulColors _getSoulColors(String palette) {
    switch (palette) {
      case 'bansheeGreen':
        return const _SoulColors(
          core: 0xFFCCFF90,
          halo: 0xFF00E676,
          tail: 0xFF1B5E20,
          voidHole: 0xFF001505,
          sparkle: 0xFFFFFFFF,
        );
      case 'tormentCrimson':
        return const _SoulColors(
          core: 0xFFFFCDD2,
          halo: 0xFFFF1744,
          tail: 0xFF880E4F,
          voidHole: 0xFF200005,
          sparkle: 0xFFFFFFFF,
        );
      case 'phantomPurple':
        return const _SoulColors(
          core: 0xFFEDE7F6,
          halo: 0xFFD500F9,
          tail: 0xFF4A148C,
          voidHole: 0xFF120020,
          sparkle: 0xFFFFFFFF,
        );
      case 'ghastlyCyan':
      default:
        return const _SoulColors(
          core: 0xFFE0F7FA,
          halo: 0xFF00E5FF,
          tail: 0xFF0277BD,
          voidHole: 0xFF001020,
          sparkle: 0xFFFFFFFF,
        );
    }
  }
}

class _SoulColors {
  final int core;
  final int halo;
  final int tail;
  final int voidHole;
  final int sparkle;

  const _SoulColors({
    required this.core,
    required this.halo,
    required this.tail,
    required this.voidHole,
    required this.sparkle,
  });
}
