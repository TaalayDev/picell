part of 'effects.dart';

/// Spawns dendritic crystalline frost creeping across top-facing surfaces of a sprite,
/// with needle-sharp icicle spikes hanging downward from overhangs, specular glints,
/// and suspended dripping water beads.
class HangingIciclesEffect extends Effect {
  HangingIciclesEffect([Map<String, dynamic>? params])
      : super(
          EffectType.hangingIcicles,
          params ??
              {
                'frostCoverage': 0.6,
                'icicleLength': 10.0,
                'iceOpacity': 0.85,
                'crystalPalette': 'arcticCyan',
                'drippingDrops': true,
                'glintSparkles': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'frostCoverage': 0.6,
        'icicleLength': 10.0,
        'iceOpacity': 0.85,
        'crystalPalette': 'arcticCyan',
        'drippingDrops': true,
        'glintSparkles': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'frostCoverage': {
          'label': 'Top Frost Coverage',
          'description': 'Density and surface penetration of dendritic crystalline frost rime.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'icicleLength': {
          'label': 'Icicle Spike Length',
          'description': 'Maximum downward reach of hanging icicles from lower overhangs.',
          'type': 'slider',
          'min': 4.0,
          'max': 24.0,
          'step': 1.0,
        },
        'iceOpacity': {
          'label': 'Ice Glaze Opacity',
          'description': 'Translucency of the crystalline ice body.',
          'type': 'slider',
          'min': 0.3,
          'max': 1.0,
          'step': 0.05,
        },
        'crystalPalette': {
          'label': 'Glacial Palette',
          'description': 'Coloration of the ice crystal formation and rime frost.',
          'type': 'dropdown',
          'options': [
            {'value': 'arcticCyan', 'label': 'Arctic Glacial (Pure White / Cyan / Ice Blue / Navy)'},
            {'value': 'glacialNavy', 'label': 'Deep Glacial (Pale Frost / Navy / Sapphire / Indigo)'},
            {'value': 'frozenLilac', 'label': 'Rime & Aurora (White Frost / Lilac / Frozen Violet)'},
          ],
        },
        'drippingDrops': {
          'label': 'Melted Dripping Drops',
          'description': 'Render suspended water droplets dangling beneath icicle tips.',
          'type': 'bool',
        },
        'glintSparkles': {
          'label': 'Specular Glints',
          'description': 'Render bright diamond specular glint highlights at icicle tips.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'frostCoverage',
          label: 'Top Frost Coverage',
          description: 'Density and surface penetration of dendritic crystalline frost rime.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'icicleLength',
          label: 'Icicle Spike Length',
          description: 'Maximum downward reach of hanging icicles from lower overhangs.',
          min: 4.0,
          max: 24.0,
          divisions: 20,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'iceOpacity',
          label: 'Ice Glaze Opacity',
          description: 'Translucency of the crystalline ice body.',
          min: 0.3,
          max: 1.0,
          divisions: 14,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'crystalPalette',
          label: 'Glacial Palette',
          description: 'Coloration of the ice crystal formation and rime frost.',
          options: {
            'arcticCyan': 'Arctic Glacial (Pure White / Cyan / Ice Blue / Navy)',
            'glacialNavy': 'Deep Glacial (Pale Frost / Navy / Sapphire / Indigo)',
            'frozenLilac': 'Rime & Aurora (White Frost / Lilac / Frozen Violet)',
          },
        ),
        const BoolField(
          key: 'drippingDrops',
          label: 'Melted Dripping Drops',
          description: 'Render suspended water droplets dangling beneath icicle tips.',
        ),
        const BoolField(
          key: 'glintSparkles',
          label: 'Specular Glints',
          description: 'Render bright diamond specular glint highlights at icicle tips.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final double coverage = ((parameters['frostCoverage'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final double maxLen = ((parameters['icicleLength'] as num?)?.toDouble() ?? 10.0).clamp(4.0, 24.0);
    final double opacity = ((parameters['iceOpacity'] as num?)?.toDouble() ?? 0.85).clamp(0.3, 1.0);
    final String palette = parameters['crystalPalette'] as String? ?? 'arcticCyan';
    final bool dripping = parameters['drippingDrops'] as bool? ?? true;
    final bool glints = parameters['glintSparkles'] as bool? ?? true;

    final iceColors = _getIceColors(palette);

    // 1. Top Edge Pass: Crystalline Frost Crust & Surface Rime
    if (coverage > 0.05) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int p = pixels[y * width + x];
          final int a = (p >> 24) & 0xFF;
          if (a == 0) continue;

          // Check if upward-facing surface
          final bool isTop = y == 0 || ((pixels[(y - 1) * width + x] >> 24) & 0xFF) == 0;
          if (!isTop) continue;

          final double h = _hash(x * 61 + y * 97 + 13);
          if (h > coverage) continue;

          // Crystalline frost crust above top edge (in empty space)
          if (y > 0) {
            final int crustIdx = (y - 1) * width + x;
            if (((pixels[crustIdx] >> 24) & 0xFF) == 0) {
              final int crustAlpha = (opacity * 210.0 * (0.6 + 0.4 * _hash(x * 23 + 47))).round().clamp(0, 255);
              _blendPixel(output, crustIdx, iceColors.highlight, crustAlpha);
            }
          }

          // Translucent rime penetration onto top sprite pixels
          final int rimeAlpha = (opacity * 130.0 * coverage).round().clamp(0, 255);
          _blendPixel(output, y * width + x, iceColors.core, rimeAlpha);

          // Deep penetration for high coverage
          if (coverage > 0.6 && y < height - 1) {
            final int subIdx = (y + 1) * width + x;
            if (((pixels[subIdx] >> 24) & 0xFF) > 0) {
              _blendPixel(output, subIdx, iceColors.core, (rimeAlpha * 0.5).round());
            }
          }
        }
      }
    }

    // 2. Bottom Overhang Pass: Hanging Icicles & Dripping Beads
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        final int a = (p >> 24) & 0xFF;
        if (a == 0) continue;

        // Downward-facing overhang: neighbor y+1 is transparent or out of bounds
        final bool isOverhang = y == height - 1 || ((pixels[(y + 1) * width + x] >> 24) & 0xFF) == 0;
        if (!isOverhang) continue;

        // Space out icicle nucleation sites
        final double nHash = _hash(x * 131 + y * 47 + 59);
        if (nHash > 0.42) continue;

        final double lenHash = _hash(x * 89 + y * 179 + 31);
        final double curLen = maxLen * (0.35 + 0.65 * lenHash);
        final int steps = curLen.round();

        // Ray-cast icicle spike downward
        for (int s = 1; s <= steps; s++) {
          final int iy = y + s;
          if (iy >= height) break;

          final double t = s / curLen; // 0.0 at base to 1.0 at tip

          // If hitting opaque sprite below, stop spike
          if (((pixels[iy * width + x] >> 24) & 0xFF) > 0) break;

          final int stepAlpha = (opacity * 255.0 * (1.0 - t * 0.25)).round().clamp(0, 255);
          final int col = t < 0.4
              ? iceColors.core
              : (t < 0.8 ? iceColors.shadow : iceColors.highlight);

          // Central needle spine
          _blendPixel(output, iy * width + x, col, stepAlpha);

          // Base widening at the top of the icicle
          if (t < 0.35 && maxLen >= 8.0) {
            final int flankAlpha = (stepAlpha * 0.55).round();
            if (x > 0 && ((pixels[iy * width + (x - 1)] >> 24) & 0xFF) == 0) {
              _blendPixel(output, iy * width + (x - 1), iceColors.shadow, flankAlpha);
            }
            if (x < width - 1 && ((pixels[iy * width + (x + 1)] >> 24) & 0xFF) == 0) {
              _blendPixel(output, iy * width + (x + 1), iceColors.shadow, flankAlpha);
            }
          }
        }

        final int tipY = (y + steps).clamp(0, height - 1);

        // Specular diamond glint at the needle tip
        if (glints && tipY < height && ((pixels[tipY * width + x] >> 24) & 0xFF) == 0) {
          _blendPixel(output, tipY * width + x, 0xFFFFFFFF, 255);
        }

        // Dripping water droplet beads beneath icicle tip
        if (dripping && tipY + 2 < height) {
          final int dropY = tipY + 2;
          if (((pixels[dropY * width + x] >> 24) & 0xFF) == 0) {
            _blendPixel(output, dropY * width + x, iceColors.highlight, (opacity * 200).round().clamp(0, 255));
          }
        }
      }
    }

    return output;
  }

  static _IciclePalette _getIceColors(String palette) {
    switch (palette) {
      case 'glacialNavy':
        return const _IciclePalette(
          highlight: 0xFFE1F5FE, // Pale frost
          core: 0xFF4FC3F7, // Glacial cyan
          shadow: 0xFF0277BD, // Deep navy
        );
      case 'frozenLilac':
        return const _IciclePalette(
          highlight: 0xFFEDE7F6, // Rime white
          core: 0xFFB39DDB, // Lavender lilac
          shadow: 0xFF5E35B1, // Deep frozen violet
        );
      case 'arcticCyan':
      default:
        return const _IciclePalette(
          highlight: 0xFFFFFFFF, // Pure crystal white
          core: 0xFF80D8FF, // Electric arctic cyan
          shadow: 0xFF0091EA, // Deep ice blue
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

      final int outR = (r * na + curR * (1.0 - na)).round().clamp(0, 255);
      final int outG = (g * na + curG * (1.0 - na)).round().clamp(0, 255);
      final int outB = (b * na + curB * (1.0 - na)).round().clamp(0, 255);
      final int outA = math.max(curA, a);

      buffer[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }
  }

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}

class _IciclePalette {
  final int highlight;
  final int core;
  final int shadow;

  const _IciclePalette({
    required this.highlight,
    required this.core,
    required this.shadow,
  });
}
