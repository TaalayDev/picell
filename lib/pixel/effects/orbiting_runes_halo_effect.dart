part of 'effects.dart';

/// Spawns mystical 3D perspective elliptical halos, ancient orbiting runic glyph stones,
/// or glowing mana spheres hovering with depth-sorting directly above or around the sprite crown.
class OrbitingRunesHaloEffect extends Effect {
  OrbitingRunesHaloEffect([Map<String, dynamic>? params])
      : super(
          EffectType.orbitingRunesHalo,
          params ??
              {
                'orbitRadiusX': 14.0,
                'orbitRadiusY': 6.0,
                'runeCount': 5.0,
                'haloStyle': 'elderRunes',
                'runePalette': 'celestialGold',
                'heightAboveSprite': 6.0,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'orbitRadiusX': 14.0,
        'orbitRadiusY': 6.0,
        'runeCount': 5.0,
        'haloStyle': 'elderRunes',
        'runePalette': 'celestialGold',
        'heightAboveSprite': 6.0,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'orbitRadiusX': {
          'label': 'Orbit Horizontal Radius',
          'description': 'Horizontal width of the orbital elliptical path.',
          'type': 'slider',
          'min': 6.0,
          'max': 24.0,
          'step': 1.0,
        },
        'orbitRadiusY': {
          'label': 'Orbit Depth (Perspective)',
          'description': 'Vertical foreshortening of the 3D perspective orbital plane.',
          'type': 'slider',
          'min': 3.0,
          'max': 14.0,
          'step': 0.5,
        },
        'runeCount': {
          'label': 'Orbiting Node Count',
          'description': 'Number of floating runes or magical orbs in orbit.',
          'type': 'slider',
          'min': 3.0,
          'max': 8.0,
          'step': 1.0,
        },
        'haloStyle': {
          'label': 'Halo Architecture Style',
          'description': 'Visual structure of the levitating celestial phenomenon.',
          'type': 'dropdown',
          'options': [
            {'value': 'elderRunes', 'label': 'Elder Runes (Carved Ancient Glyph Stones)'},
            {'value': 'angelicRing', 'label': 'Angelic Ring (Continuous Glowing Celestial Halo)'},
            {'value': 'magusOrbs', 'label': 'Magus Orbs (Concentrated Pulsing Mana Spheres)'},
          ],
        },
        'runePalette': {
          'label': 'Celestial Energy Palette',
          'description': 'Coloration of the glyph aura and luminous halo.',
          'type': 'dropdown',
          'options': [
            {'value': 'celestialGold', 'label': 'Holy Gold (Pure White / Radiant Gold / Sun Amber)'},
            {'value': 'arcaneAmethyst', 'label': 'Arcane Mystic (White / Hot Magenta / Amethyst)'},
            {'value': 'etherCyan', 'label': 'Seraphic Ether (White / Electric Cyan / Celestite)'},
            {'value': 'bloodRune', 'label': 'Forbidden Occult (White / Scarlet / Blood Crimson)'},
          ],
        },
        'heightAboveSprite': {
          'label': 'Crown Elevation Height',
          'description': 'Vertical hover elevation above the character head centroid.',
          'type': 'slider',
          'min': 2.0,
          'max': 16.0,
          'step': 1.0,
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'orbitRadiusX',
          label: 'Orbit Horizontal Radius',
          description: 'Horizontal width of the orbital elliptical path.',
          min: 6.0,
          max: 24.0,
          divisions: 18,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'orbitRadiusY',
          label: 'Orbit Depth (Perspective)',
          description: 'Vertical foreshortening of the 3D perspective orbital plane.',
          min: 3.0,
          max: 14.0,
          divisions: 22,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'runeCount',
          label: 'Orbiting Node Count',
          description: 'Number of floating runes or magical orbs in orbit.',
          min: 3.0,
          max: 8.0,
          divisions: 5,
          formatLabel: (v) => '${v.round()} nodes',
        ),
        const SelectField(
          key: 'haloStyle',
          label: 'Halo Architecture Style',
          description: 'Visual structure of the levitating celestial phenomenon.',
          options: {
            'elderRunes': 'Elder Runes (Carved Ancient Glyph Stones)',
            'angelicRing': 'Angelic Ring (Continuous Glowing Celestial Halo)',
            'magusOrbs': 'Magus Orbs (Concentrated Pulsing Mana Spheres)',
          },
        ),
        const SelectField(
          key: 'runePalette',
          label: 'Celestial Energy Palette',
          description: 'Coloration of the glyph aura and luminous halo.',
          options: {
            'celestialGold': 'Holy Gold (Pure White / Radiant Gold / Sun Amber)',
            'arcaneAmethyst': 'Arcane Mystic (White / Hot Magenta / Amethyst)',
            'etherCyan': 'Seraphic Ether (White / Electric Cyan / Celestite)',
            'bloodRune': 'Forbidden Occult (White / Scarlet / Blood Crimson)',
          },
        ),
        SliderField(
          key: 'heightAboveSprite',
          label: 'Crown Elevation Height',
          description: 'Vertical hover elevation above the character head centroid.',
          min: 2.0,
          max: 16.0,
          divisions: 14,
          formatLabel: (v) => '${v.round()}px',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final double rx = ((parameters['orbitRadiusX'] as num?)?.toDouble() ?? 14.0).clamp(6.0, 24.0);
    final double ry = ((parameters['orbitRadiusY'] as num?)?.toDouble() ?? 6.0).clamp(3.0, 14.0);
    final int count = ((parameters['runeCount'] as num?)?.toInt() ?? 5).clamp(3, 8);
    final String style = parameters['haloStyle'] as String? ?? 'elderRunes';
    final String palette = parameters['runePalette'] as String? ?? 'celestialGold';
    final double elev = ((parameters['heightAboveSprite'] as num?)?.toDouble() ?? 6.0).clamp(2.0, 16.0);

    final colors = _getHaloColors(palette);

    // 1. Locate top-quarter head centroid of the sprite
    int minY = height;
    int maxY = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 0) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (minY >= height) {
      return output; // Empty sprite
    }

    // Top quarter bounds
    final int topQuarterY = minY + ((maxY - minY) * 0.3).round();
    double sumX = 0;
    int headCount = 0;

    for (int y = minY; y <= topQuarterY; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 0) {
          sumX += x;
          headCount++;
        }
      }
    }

    final double headCenterX = headCount > 0 ? sumX / headCount : width / 2.0;
    final double headCenterY = minY.toDouble();
    final double orbitCenterX = headCenterX;
    final double orbitCenterY = (headCenterY - elev).clamp(0.0, height - 1.0);

    // 2. Render Halo / Runes based on style
    if (style == 'angelicRing') {
      // Continuous glowing elliptical halo torus
      const int steps = 140;
      for (int s = 0; s < steps; s++) {
        final double theta = (s / steps) * math.pi * 2.0;
        final double px = orbitCenterX + rx * math.cos(theta);
        final double py = orbitCenterY + ry * math.sin(theta);
        final double z = math.sin(theta); // z > 0: behind, z <= 0: in front

        final int ix = px.round();
        final int iy = py.round();

        if (ix >= 0 && ix < width && iy >= 0 && iy < height) {
          final int idx = iy * width + ix;
          final bool isSpriteOpaque = ((pixels[idx] >> 24) & 0xFF) > 0;

          // If behind sprite, don't overwrite sprite
          if (z > 0.0 && isSpriteOpaque) continue;

          final int ringA = z <= 0.0 ? 255 : 180;
          _blendPixel(output, idx, 0xFFFFFFFF, ringA);

          // Glow sheath
          for (final o in const [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
            final int gx = ix + o[0];
            final int gy = iy + o[1];
            if (gx >= 0 && gx < width && gy >= 0 && gy < height) {
              final int gIdx = gy * width + gx;
              if (z > 0.0 && ((pixels[gIdx] >> 24) & 0xFF) > 0) continue;
              _blendPixel(output, gIdx, colors.primary, (ringA * 0.55).round());
            }
          }
        }
      }
    } else {
      // Orbiting discrete runes or magus orbs with 3D depth-sorting
      for (int i = 0; i < count; i++) {
        final double theta = (i / count) * math.pi * 2.0;
        final double px = orbitCenterX + rx * math.cos(theta);
        final double py = orbitCenterY + ry * math.sin(theta);
        final double z = math.sin(theta); // z > 0: behind, z <= 0: in front

        final int cx = px.round();
        final int cy = py.round();

        final bool isBehind = z > 0.0;
        final double depthScale = isBehind ? 0.75 : 1.0;
        final int alphaScale = isBehind ? 170 : 255;

        if (style == 'magusOrbs') {
          _drawManaOrb(output, pixels, width, height, cx, cy, colors, isBehind, alphaScale, depthScale);
        } else {
          _drawElderRune(output, pixels, width, height, cx, cy, colors, isBehind, alphaScale, i);
        }
      }
    }

    return output;
  }

  static void _drawManaOrb(
    Uint32List output,
    Uint32List pixels,
    int width,
    int height,
    int cx,
    int cy,
    _HaloPalette colors,
    bool isBehind,
    int alpha,
    double scale,
  ) {
    // 3x3 circular sphere with white core
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final int x = cx + dx;
        final int y = cy + dy;
        if (x < 0 || x >= width || y < 0 || y >= height) continue;

        final int idx = y * width + x;
        if (isBehind && ((pixels[idx] >> 24) & 0xFF) > 0) continue;

        if (dx == 0 && dy == 0) {
          _blendPixel(output, idx, 0xFFFFFFFF, alpha);
        } else if ((dx.abs() + dy.abs()) == 1) {
          _blendPixel(output, idx, colors.primary, (alpha * 0.85).round());
        }
      }
    }
  }

  static void _drawElderRune(
    Uint32List output,
    Uint32List pixels,
    int width,
    int height,
    int cx,
    int cy,
    _HaloPalette colors,
    bool isBehind,
    int alpha,
    int runeIndex,
  ) {
    // Authentic 3x3 pixel-art runic glyph sigil
    const runePatterns = [
      // Cross Rune
      [
        [0, 1, 0],
        [1, 2, 1],
        [0, 1, 0],
      ],
      // Diamond Rune
      [
        [0, 1, 0],
        [1, 0, 1],
        [0, 1, 0],
      ],
      // Ankh / Eye Rune
      [
        [1, 1, 1],
        [0, 2, 0],
        [0, 1, 0],
      ],
      // Chevron Rune
      [
        [1, 0, 1],
        [0, 2, 0],
        [1, 0, 1],
      ],
    ];

    final pattern = runePatterns[runeIndex % runePatterns.length];

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final int val = pattern[dy + 1][dx + 1];
        if (val == 0) continue;

        final int x = cx + dx;
        final int y = cy + dy;
        if (x < 0 || x >= width || y < 0 || y >= height) continue;

        final int idx = y * width + x;
        if (isBehind && ((pixels[idx] >> 24) & 0xFF) > 0) continue;

        final int col = val == 2 ? 0xFFFFFFFF : colors.primary;
        _blendPixel(output, idx, col, alpha);
      }
    }
  }

  static _HaloPalette _getHaloColors(String palette) {
    switch (palette) {
      case 'arcaneAmethyst':
        return const _HaloPalette(
          primary: 0xFFE040FB, // Bright orchid magenta
          secondary: 0xFF7C4DFF, // Mystic amethyst
        );
      case 'etherCyan':
        return const _HaloPalette(
          primary: 0xFF00E5FF, // Radiant cyan
          secondary: 0xFF0091EA, // Celestite blue
        );
      case 'bloodRune':
        return const _HaloPalette(
          primary: 0xFFFF1744, // Bright scarlet
          secondary: 0xFFB71C1C, // Dark blood crimson
        );
      case 'celestialGold':
      default:
        return const _HaloPalette(
          primary: 0xFFFFD700, // Brilliant holy gold
          secondary: 0xFFFF9100, // Sun halo amber
        );
    }
  }

  static void _blendPixel(Uint32List buffer, int idx, int color, int a) {
    final int curP = buffer[idx];
    final int curA = (curP >> 24) & 0xFF;

    final int r = (color >> 16) & 0xFF;
    final int g = (color >> 8) & 0xFF;
    final int b = color & 0xFF;

    if (curA == 0) {
      buffer[idx] = (a << 24) | (r << 16) | (g << 8) | b;
    } else {
      final double na = a / 255.0;
      final int curR = (curP >> 16) & 0xFF;
      final int curG = (curP >> 8) & 0xFF;
      final int curB = curP & 0xFF;

      final int outR = math.max(curR, (r * na).round());
      final int outG = math.max(curG, (g * na).round());
      final int outB = math.max(curB, (b * na).round());
      final int outA = math.max(curA, a);

      buffer[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }
  }
}

class _HaloPalette {
  final int primary;
  final int secondary;

  const _HaloPalette({
    required this.primary,
    required this.secondary,
  });
}
