part of 'effects.dart';

/// Spawns thick, bubbling viscous goo clinging to the top contours of a sprite
/// with convex fluid surface tension, specular gloss bubbles, and hanging acid droplets
/// stretching and dripping downward off lower overhangs.
class ViscousSlimeEffect extends Effect {
  ViscousSlimeEffect([Map<String, dynamic>? params])
      : super(
          EffectType.viscousSlime,
          params ??
              {
                'slimeViscosity': 0.6,
                'dripFrequency': 0.5,
                'slimeHeight': 3.5,
                'slimePalette': 'toxicLime',
                'specularGloss': 0.75,
                'hangDripLength': 8.0,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'slimeViscosity': 0.6,
        'dripFrequency': 0.5,
        'slimeHeight': 3.5,
        'slimePalette': 'toxicLime',
        'specularGloss': 0.75,
        'hangDripLength': 8.0,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'slimeViscosity': {
          'label': 'Fluid Viscosity',
          'description': 'Stretch resistance and cohesion of hanging fluid filaments.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'dripFrequency': {
          'label': 'Drip Spout Frequency',
          'description': 'Density of dripping slime strands along downward overhangs.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'slimeHeight': {
          'label': 'Top Slime Cap Thickness',
          'description': 'Convex depth of fluid layer coating the top surface of the sprite.',
          'type': 'slider',
          'min': 1.5,
          'max': 8.0,
          'step': 0.5,
        },
        'slimePalette': {
          'label': 'Slime Fluid Palette',
          'description': 'Chemical composition and toxic coloration of the ooze.',
          'type': 'dropdown',
          'options': [
            {'value': 'toxicLime', 'label': 'Radioactive Acid (Neon Lime / Emerald Slime / Deep Shadow)'},
            {'value': 'eldritchPurple', 'label': 'Eldritch Goo (Bright Orchid / Deep Amethyst / Abyssal)'},
            {'value': 'magmaOrange', 'label': 'Molten Slag (Incandescent Yellow / Lava Orange / Basalt)'},
            {'value': 'bloodCrimson', 'label': 'Viscous Blood (Fresh Crimson / Wine Red / Dried Clot)'},
          ],
        },
        'specularGloss': {
          'label': 'Specular Gloss & Bubbles',
          'description': 'Reflective shine bubbles and liquid surface tension highlights.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'hangDripLength': {
          'label': 'Droplet Stretch Length',
          'description': 'Maximum distance of stretched dripping fluid teardrops.',
          'type': 'slider',
          'min': 4.0,
          'max': 20.0,
          'step': 1.0,
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'slimeViscosity',
          label: 'Fluid Viscosity',
          description: 'Stretch resistance and cohesion of hanging fluid filaments.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'dripFrequency',
          label: 'Drip Spout Frequency',
          description: 'Density of dripping slime strands along downward overhangs.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'slimeHeight',
          label: 'Top Slime Cap Thickness',
          description: 'Convex depth of fluid layer coating the top surface of the sprite.',
          min: 1.5,
          max: 8.0,
          divisions: 13,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'slimePalette',
          label: 'Slime Fluid Palette',
          description: 'Chemical composition and toxic coloration of the ooze.',
          options: {
            'toxicLime': 'Radioactive Acid (Neon Lime / Emerald Slime / Deep Shadow)',
            'eldritchPurple': 'Eldritch Goo (Bright Orchid / Deep Amethyst / Abyssal)',
            'magmaOrange': 'Molten Slag (Incandescent Yellow / Lava Orange / Basalt)',
            'bloodCrimson': 'Viscous Blood (Fresh Crimson / Wine Red / Dried Clot)',
          },
        ),
        SliderField(
          key: 'specularGloss',
          label: 'Specular Gloss & Bubbles',
          description: 'Reflective shine bubbles and liquid surface tension highlights.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'hangDripLength',
          label: 'Droplet Stretch Length',
          description: 'Maximum distance of stretched dripping fluid teardrops.',
          min: 4.0,
          max: 20.0,
          divisions: 16,
          formatLabel: (v) => '${v.round()}px',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final double viscosity = ((parameters['slimeViscosity'] as num?)?.toDouble() ?? 0.6).clamp(0.2, 1.0);
    final double frequency = ((parameters['dripFrequency'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final double capHeight = ((parameters['slimeHeight'] as num?)?.toDouble() ?? 3.5).clamp(1.5, 8.0);
    final String palette = parameters['slimePalette'] as String? ?? 'toxicLime';
    final double gloss = ((parameters['specularGloss'] as num?)?.toDouble() ?? 0.75).clamp(0.0, 1.0);
    final double maxDripLen = ((parameters['hangDripLength'] as num?)?.toDouble() ?? 8.0).clamp(4.0, 20.0);

    final colors = _getSlimeColors(palette);

    // 1. Top Edge Pass: Viscous Slime Cap
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        final int a = (p >> 24) & 0xFF;
        if (a == 0) continue;

        // Upward-facing edge
        final bool isTop = y == 0 || ((pixels[(y - 1) * width + x] >> 24) & 0xFF) == 0;
        if (!isTop) continue;

        // Organic bulbous cap profile modulated by sinusoids
        final double capProfile = math.sin(x * 0.75 + _hash(x * 37) * 2.0).abs();
        final int curCapH = (capHeight * (0.65 + 0.45 * capProfile)).round().clamp(1, 8);

        // Fill fluid cap above top edge
        for (int ch = 1; ch <= curCapH; ch++) {
          final int cy = y - ch;
          if (cy < 0) break;
          final int cIdx = cy * width + x;

          // Don't overwrite opaque sprite pixels
          if (((pixels[cIdx] >> 24) & 0xFF) > 0) continue;

          final int col = (ch == curCapH) ? colors.highlight : colors.body;
          _blendPixel(output, cIdx, col, 245);
        }

        // Specular gloss shine dot on top of cap
        if (gloss > 0.1) {
          final double gHash = _hash(x * 71 + y * 29 + 17);
          if (gHash < gloss * 0.4) {
            final int topRidgeY = (y - curCapH).clamp(0, height - 1);
            final int rIdx = topRidgeY * width + x;
            if (((pixels[rIdx] >> 24) & 0xFF) == 0) {
              _blendPixel(output, rIdx, colors.specular, 255);
            }
          }
        }

        // Slight meniscus darkening onto sprite top edge
        _blendPixel(output, y * width + x, colors.shadow, 140);
      }
    }

    // 2. Bottom Overhang Pass: Viscous Dripping Strands & Teardrops
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        final int a = (p >> 24) & 0xFF;
        if (a == 0) continue;

        // Downward overhang lip
        final bool isOverhang = y == height - 1 || ((pixels[(y + 1) * width + x] >> 24) & 0xFF) == 0;
        if (!isOverhang) continue;

        // Space out drip nozzles along overhangs
        final double dHash = _hash(x * 83 + y * 139 + 41);
        if (dHash > frequency * 0.45) continue;

        final double lenHash = _hash(x * 167 + y * 97 + 19);
        final double curLen = maxDripLen * (0.45 + 0.55 * lenHash);
        final int steps = curLen.round();

        // Ray-cast viscous drip downward
        for (int s = 1; s <= steps; s++) {
          final int dy = y + s;
          if (dy >= height) break;

          final int dIdx = dy * width + x;
          if (((pixels[dIdx] >> 24) & 0xFF) > 0) break; // Reached another sprite surface

          final bool isMeniscus = s <= 2;
          final bool isTeardrop = s >= steps - 2;

          if (isMeniscus) {
            // Flared upper attachment meniscus
            _blendPixel(output, dIdx, colors.body, 240);
            if (x > 0 && ((pixels[dy * width + (x - 1)] >> 24) & 0xFF) == 0) {
              _blendPixel(output, dy * width + (x - 1), colors.shadow, 180);
            }
            if (x < width - 1 && ((pixels[dy * width + (x + 1)] >> 24) & 0xFF) == 0) {
              _blendPixel(output, dy * width + (x + 1), colors.shadow, 180);
            }
          } else if (isTeardrop) {
            // Bulbous swollen droplet head
            _blendPixel(output, dIdx, colors.body, 255);
            if (x > 0 && ((pixels[dy * width + (x - 1)] >> 24) & 0xFF) == 0) {
              _blendPixel(output, dy * width + (x - 1), colors.body, 220);
            }
            if (x < width - 1 && ((pixels[dy * width + (x + 1)] >> 24) & 0xFF) == 0) {
              _blendPixel(output, dy * width + (x + 1), colors.body, 220);
            }

            // Specular gloss glint on teardrop bulb
            if (gloss > 0.2 && s == steps - 1) {
              _blendPixel(output, dIdx, colors.specular, 255);
            }
          } else {
            // Stretched fluid filament neck
            final int neckAlpha = (180.0 + viscosity * 60.0).round().clamp(0, 255);
            _blendPixel(output, dIdx, colors.shadow, neckAlpha);
          }
        }

        // Detached falling drip droplet
        final int dropY = y + steps + 2;
        if (dropY < height && ((pixels[dropY * width + x] >> 24) & 0xFF) == 0) {
          _blendPixel(output, dropY * width + x, colors.highlight, 240);
        }
      }
    }

    return output;
  }

  static _SlimePalette _getSlimeColors(String palette) {
    switch (palette) {
      case 'eldritchPurple':
        return const _SlimePalette(
          specular: 0xFFFFFFFF,
          highlight: 0xFFEA80FC, // Bright orchid
          body: 0xFFAA00FF, // Deep amethyst purple
          shadow: 0xFF4A148C, // Abyssal violet
        );
      case 'magmaOrange':
        return const _SlimePalette(
          specular: 0xFFFFFFFF,
          highlight: 0xFFFFEB3B, // Incandescent yellow
          body: 0xFFFF6D00, // Lava fire orange
          shadow: 0xFFBF360C, // Basalt crust ember
        );
      case 'bloodCrimson':
        return const _SlimePalette(
          specular: 0xFFFFFFFF,
          highlight: 0xFFFF5252, // Fresh arterial crimson
          body: 0xFFD50000, // Rich wine red
          shadow: 0xFF4A0000, // Dried clot burgundy
        );
      case 'toxicLime':
      default:
        return const _SlimePalette(
          specular: 0xFFFFFFFF,
          highlight: 0xFFCCFF90, // Radiant lime gloss
          body: 0xFF76FF03, // Radioactive neon green
          shadow: 0xFF007E33, // Dark toxic emerald shadow
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

class _SlimePalette {
  final int specular;
  final int highlight;
  final int body;
  final int shadow;

  const _SlimePalette({
    required this.specular,
    required this.highlight,
    required this.body,
    required this.shadow,
  });
}
