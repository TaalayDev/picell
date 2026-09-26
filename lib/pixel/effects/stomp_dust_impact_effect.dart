part of 'effects.dart';

/// Spawns bilateral billows of kicking dust puffs, floating soil motes, and ground
/// fracture crack lines erupting outward from the bottom contact pixels of the sprite.
class StompDustImpactEffect extends Effect {
  StompDustImpactEffect([Map<String, dynamic>? params])
      : super(
          EffectType.stompDustImpact,
          params ??
              {
                'plumeWidth': 12.0,
                'plumeHeight': 6.0,
                'dustDensity': 0.7,
                'groundCracks': true,
                'dustPalette': 'desertSand',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'plumeWidth': 12.0,
        'plumeHeight': 6.0,
        'dustDensity': 0.7,
        'groundCracks': true,
        'dustPalette': 'desertSand',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'plumeWidth': {
          'label': 'Plume Horizontal Spread',
          'description': 'Lateral distance dust plumes billow outward to the sides.',
          'type': 'slider',
          'min': 4.0,
          'max': 24.0,
          'step': 1.0,
        },
        'plumeHeight': {
          'label': 'Plume Billow Height',
          'description': 'Vertical height of the rising kicking dust clouds.',
          'type': 'slider',
          'min': 2.0,
          'max': 12.0,
          'step': 0.5,
        },
        'dustDensity': {
          'label': 'Dust Density & Opacity',
          'description': 'Compactness of dust puff clusters and motes.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'groundCracks': {
          'label': 'Ground Impact Cracks',
          'description': 'Renders jagged fracture lines radiating along the floor baseline.',
          'type': 'bool',
        },
        'dustPalette': {
          'label': 'Dust Mineral Palette',
          'description': 'Coloration of the soil, ash, or rock debris.',
          'type': 'dropdown',
          'options': [
            {'value': 'desertSand', 'label': 'Desert Sand (Warm Ochre / Tan / Sun White / Deep Earth)'},
            {'value': 'volcanicAsh', 'label': 'Volcanic Ash (Charcoal / Smoke Gray / Ash / Fire Ember)'},
            {'value': 'dungeonStone', 'label': 'Dungeon Stone (Slate Gray / Chipped Limestone / Shadow)'},
            {'value': 'toxicSpore', 'label': 'Toxic Spores (Bile Yellow / Swamp Slime / Acid Mist)'},
          ],
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders dust strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'plumeWidth',
          label: 'Plume Horizontal Spread',
          description: 'Lateral distance dust plumes billow outward to the sides.',
          min: 4.0,
          max: 24.0,
          divisions: 20,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'plumeHeight',
          label: 'Plume Billow Height',
          description: 'Vertical height of the rising kicking dust clouds.',
          min: 2.0,
          max: 12.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'dustDensity',
          label: 'Dust Density & Opacity',
          description: 'Compactness of dust puff clusters and motes.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'groundCracks',
          label: 'Ground Impact Cracks',
          description: 'Renders jagged fracture lines radiating along the floor baseline.',
        ),
        const SelectField(
          key: 'dustPalette',
          label: 'Dust Mineral Palette',
          description: 'Coloration of the soil, ash, or rock debris.',
          options: {
            'desertSand': 'Desert Sand (Warm Ochre / Sun Tan / Earth)',
            'volcanicAsh': 'Volcanic Ash (Charcoal / Smoke Gray / Ember)',
            'dungeonStone': 'Dungeon Stone (Slate Gray / Limestone)',
            'toxicSpore': 'Toxic Spores (Bile Yellow / Swamp Slime)',
          },
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders dust strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final plumeWidth = ((parameters['plumeWidth'] as num?)?.toDouble() ?? 12.0).clamp(4.0, 24.0);
    final plumeHeight = ((parameters['plumeHeight'] as num?)?.toDouble() ?? 6.0).clamp(2.0, 12.0);
    final dustDensity = ((parameters['dustDensity'] as num?)?.toDouble() ?? 0.7).clamp(0.2, 1.0);
    final groundCracks = parameters['groundCracks'] as bool? ?? true;
    final paletteKey = parameters['dustPalette'] as String? ?? 'desertSand';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // 1. Identify bottom-most contact baseline and contact points
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

    if (maxY == -1) {
      return output;
    }

    // Find contact pixels on bottom 2 rows
    final contactXs = <int>[];
    for (int y = math.max(0, maxY - 1); y <= maxY; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          contactXs.add(x);
        }
      }
    }

    if (contactXs.isEmpty) return output;

    contactXs.sort();
    final leftX = contactXs.first.toDouble();
    final rightX = contactXs.last.toDouble();
    final baselineY = maxY.toDouble();

    final colors = _getDustColors(paletteKey);

    const bayer4x4 = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5],
    ];

    // 2. Define billowing circular lobes for left and right dust plumes
    final lobes = <_DustLobe>[
      // Left plumes (heading -X)
      _DustLobe(
        cx: leftX - 1.0,
        cy: baselineY - plumeHeight * 0.25,
        radius: plumeHeight * 0.65,
      ),
      _DustLobe(
        cx: leftX - plumeWidth * 0.45,
        cy: baselineY - plumeHeight * 0.55,
        radius: plumeHeight * 0.52,
      ),
      _DustLobe(
        cx: leftX - plumeWidth * 0.85,
        cy: baselineY - plumeHeight * 0.35,
        radius: plumeHeight * 0.42,
      ),

      // Right plumes (heading +X)
      _DustLobe(
        cx: rightX + 1.0,
        cy: baselineY - plumeHeight * 0.25,
        radius: plumeHeight * 0.65,
      ),
      _DustLobe(
        cx: rightX + plumeWidth * 0.45,
        cy: baselineY - plumeHeight * 0.55,
        radius: plumeHeight * 0.52,
      ),
      _DustLobe(
        cx: rightX + plumeWidth * 0.85,
        cy: baselineY - plumeHeight * 0.35,
        radius: plumeHeight * 0.42,
      ),
    ];

    // Render dust puff lobes
    for (final lobe in lobes) {
      final minX = (lobe.cx - lobe.radius - 1).floor().clamp(0, width - 1);
      final maxX = (lobe.cx + lobe.radius + 1).ceil().clamp(0, width - 1);
      final minY = (lobe.cy - lobe.radius - 1).floor().clamp(0, height - 1);
      final maxY = (lobe.cy + lobe.radius + 1).ceil().clamp(0, height - 1);

      for (int py = minY; py <= maxY; py++) {
        for (int px = minX; px <= maxX; px++) {
          final idx = py * width + px;
          final orig = pixels[idx];
          if (behindOnly && ((orig >> 24) & 0xFF) > 30) {
            continue;
          }

          final dx = px - lobe.cx;
          final dy = py - lobe.cy;
          final dist = math.sqrt(dx * dx + dy * dy);

          if (dist <= lobe.radius) {
            final normDist = dist / lobe.radius;
            final alphaFalloff = (1.0 - normDist).clamp(0.0, 1.0);
            final bayerVal = bayer4x4[py % 4][px % 4] / 16.0;

            if (alphaFalloff * dustDensity > bayerVal * 0.8) {
              int dustColor;

              // Shading: upper crest is highlight, lower is shadow
              if (dist >= lobe.radius - 1.1) {
                dustColor = colors.highlight;
              } else if (dy < -lobe.radius * 0.2) {
                dustColor = colors.highlight;
              } else if (dy > lobe.radius * 0.25) {
                dustColor = colors.shadow;
              } else {
                dustColor = colors.primary;
              }

              final dustAlpha = (235 * alphaFalloff * dustDensity).toInt().clamp(0, 255);
              final tinted = (dustAlpha << 24) | (dustColor & 0x00FFFFFF);
              output[idx] = _blendPixel(output[idx], tinted);
            }
          }
        }
      }
    }

    // 3. Floating drifting dust motes / embers
    final motes = [
      math.Point(leftX - plumeWidth * 0.6, baselineY - plumeHeight * 1.05),
      math.Point(leftX - plumeWidth * 0.95, baselineY - plumeHeight * 0.75),
      math.Point(leftX - plumeWidth * 1.15, baselineY - plumeHeight * 0.45),
      math.Point(rightX + plumeWidth * 0.6, baselineY - plumeHeight * 1.05),
      math.Point(rightX + plumeWidth * 0.95, baselineY - plumeHeight * 0.75),
      math.Point(rightX + plumeWidth * 1.15, baselineY - plumeHeight * 0.45),
    ];

    for (final mote in motes) {
      final mx = mote.x.round();
      final my = mote.y.round();
      if (mx >= 0 && mx < width && my >= 0 && my < height) {
        final idx = my * width + mx;
        if (!behindOnly || ((pixels[idx] >> 24) & 0xFF) <= 30) {
          final moteAlpha = (210 * dustDensity).toInt().clamp(0, 255);
          final tinted = (moteAlpha << 24) | (colors.spark & 0x00FFFFFF);
          output[idx] = _blendPixel(output[idx], tinted);
        }
      }
    }

    // 4. Ground impact fissures / cracks
    if (groundCracks) {
      final startCrackX = (leftX - plumeWidth * 0.75).round().clamp(0, width - 1);
      final endCrackX = (rightX + plumeWidth * 0.75).round().clamp(0, width - 1);
      final crackY = (baselineY + 1.0).round().clamp(0, height - 1);

      for (int x = startCrackX; x <= endCrackX; x++) {
        // Pseudo-random crack jitter
        final hash = ((x * 127 + crackY * 311) ^ 0x5DEECE66) & 0x7FFFFFFF;
        final step = (hash % 5 == 0) ? 1 : 0;
        final py = (crackY + step).clamp(0, height - 1);
        final idx = py * width + x;

        if (!behindOnly || ((pixels[idx] >> 24) & 0xFF) <= 30) {
          if (hash % 7 != 0) {
            // Jagged fracture pixel
            final tinted = (220 << 24) | (colors.crack & 0x00FFFFFF);
            output[idx] = _blendPixel(output[idx], tinted);
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

  _DustColors _getDustColors(String palette) {
    switch (palette) {
      case 'volcanicAsh':
        return const _DustColors(
          highlight: 0xFFBDBDBD,
          primary: 0xFF757575,
          shadow: 0xFF212121,
          spark: 0xFFFF5722,
          crack: 0xFF151515,
        );
      case 'dungeonStone':
        return const _DustColors(
          highlight: 0xFFECEFF1,
          primary: 0xFF90A4AE,
          shadow: 0xFF455A64,
          spark: 0xFFCFD8DC,
          crack: 0xFF263238,
        );
      case 'toxicSpore':
        return const _DustColors(
          highlight: 0xFFF0F4C3,
          primary: 0xFFCDDC39,
          shadow: 0xFF689F38,
          spark: 0xFFEEFF41,
          crack: 0xFF33691E,
        );
      case 'desertSand':
      default:
        return const _DustColors(
          highlight: 0xFFFFF8E1,
          primary: 0xFFD7CCC8,
          shadow: 0xFF8D6E63,
          spark: 0xFFFFE082,
          crack: 0xFF4E342E,
        );
    }
  }
}

class _DustLobe {
  final double cx;
  final double cy;
  final double radius;

  const _DustLobe({
    required this.cx,
    required this.cy,
    required this.radius,
  });
}

class _DustColors {
  final int highlight;
  final int primary;
  final int shadow;
  final int spark;
  final int crack;

  const _DustColors({
    required this.highlight,
    required this.primary,
    required this.shadow,
    required this.spark,
    required this.crack,
  });
}
