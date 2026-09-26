part of 'effects.dart';

/// Spawns flickering tongues of flame licking upward from the head, shoulders,
/// weapon contours, or silhouette perimeter of the sprite, complete with
/// multi-tier heat palettes and floating ember motes.
class CrownSoulFireEffect extends Effect {
  CrownSoulFireEffect([Map<String, dynamic>? params])
      : super(
          EffectType.crownSoulFire,
          params ??
              {
                'fireHeight': 12.0,
                'flameTurbulence': 0.5,
                'firePalette': 'hellfireCrimson',
                'emberRate': 0.4,
                'anchorMode': 'topEdgesOnly',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'fireHeight': 12.0,
        'flameTurbulence': 0.5,
        'firePalette': 'hellfireCrimson',
        'emberRate': 0.4,
        'anchorMode': 'topEdgesOnly',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'fireHeight': {
          'label': 'Flame Spire Height',
          'description': 'Maximum vertical reach of the upward licking flame tongues.',
          'type': 'slider',
          'min': 4.0,
          'max': 24.0,
          'step': 1.0,
        },
        'flameTurbulence': {
          'label': 'Flame Turbulence & Sway',
          'description': 'Horizontal curl, flicker sway, and turbulent tongue oscillation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'firePalette': {
          'label': 'Elemental Flame Palette',
          'description': 'Combustion core coloration and thermal heat gradient.',
          'type': 'dropdown',
          'options': [
            {'value': 'hellfireCrimson', 'label': 'Hellfire Crimson (White / Yellow / Orange / Crimson)'},
            {'value': 'soulBlue', 'label': 'Soul Fire (White / Cyan / Cobalt / Violet)'},
            {'value': 'holyGold', 'label': 'Holy Fire (White / Radiant Gold / Amber / Sunset)'},
            {'value': 'necroGreen', 'label': 'Necromantic Flame (White / Neon Lime / Emerald / Dark Green)'},
          ],
        },
        'emberRate': {
          'label': 'Floating Ember Density',
          'description': 'Frequency of detached drifting sparks and embers rising above flames.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'anchorMode': {
          'label': 'Emitter Anchor Mode',
          'description': 'Contour surfaces that sprout flame tongues.',
          'type': 'dropdown',
          'options': [
            {'value': 'topEdgesOnly', 'label': 'Top Edges (Head, Shoulders & Crown)'},
            {'value': 'fullSilhouette', 'label': 'Full Silhouette (Entire Perimeter Aura)'},
          ],
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'Keep sprite in front; flame licks only sprout behind into empty space.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'fireHeight',
          label: 'Flame Spire Height',
          description: 'Maximum vertical reach of the upward licking flame tongues.',
          min: 4.0,
          max: 24.0,
          divisions: 20,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'flameTurbulence',
          label: 'Flame Turbulence & Sway',
          description: 'Horizontal curl, flicker sway, and turbulent tongue oscillation.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'firePalette',
          label: 'Elemental Flame Palette',
          description: 'Combustion core coloration and thermal heat gradient.',
          options: {
            'hellfireCrimson': 'Hellfire Crimson (White / Yellow / Orange / Crimson)',
            'soulBlue': 'Soul Fire (White / Cyan / Cobalt / Violet)',
            'holyGold': 'Holy Fire (White / Radiant Gold / Amber / Sunset)',
            'necroGreen': 'Necromantic Flame (White / Neon Lime / Emerald / Dark Green)',
          },
        ),
        SliderField(
          key: 'emberRate',
          label: 'Floating Ember Density',
          description: 'Frequency of detached drifting sparks and embers rising above flames.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'anchorMode',
          label: 'Emitter Anchor Mode',
          description: 'Contour surfaces that sprout flame tongues.',
          options: {
            'topEdgesOnly': 'Top Edges (Head, Shoulders & Crown)',
            'fullSilhouette': 'Full Silhouette (Entire Perimeter Aura)',
          },
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'Keep sprite in front; flame licks only sprout behind into empty space.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    // Initial blit of sprite
    output.setAll(0, pixels);

    final double maxH = ((parameters['fireHeight'] as num?)?.toDouble() ?? 12.0).clamp(4.0, 24.0);
    final double turbulence = ((parameters['flameTurbulence'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final String palette = parameters['firePalette'] as String? ?? 'hellfireCrimson';
    final double emberRate = ((parameters['emberRate'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final String anchorMode = parameters['anchorMode'] as String? ?? 'topEdgesOnly';
    final bool behindOnly = parameters['behindOnly'] as bool? ?? false;

    // Buffer to accumulate fire so behindOnly can be strictly applied if desired
    final fireBuffer = Uint32List(width * height);

    // Scan contour anchor points
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        final int a = (p >> 24) & 0xFF;
        if (a == 0) continue;

        bool isAnchor = false;
        if (anchorMode == 'topEdgesOnly') {
          // Top-facing edge: y-1 is out of bounds or transparent
          if (y == 0 || ((pixels[(y - 1) * width + x] >> 24) & 0xFF) == 0) {
            isAnchor = true;
          }
        } else {
          // Full silhouette perimeter: any 4-neighbor is transparent or out of bounds
          if (y == 0 || ((pixels[(y - 1) * width + x] >> 24) & 0xFF) == 0 ||
              y == height - 1 || ((pixels[(y + 1) * width + x] >> 24) & 0xFF) == 0 ||
              x == 0 || ((pixels[y * width + (x - 1)] >> 24) & 0xFF) == 0 ||
              x == width - 1 || ((pixels[y * width + (x + 1)] >> 24) & 0xFF) == 0) {
            isAnchor = true;
          }
        }

        if (!isAnchor) continue;

        // Modulate tongue height by noise
        final double hNoise = _hash(x * 73 + y * 31 + 17);
        final double curH = maxH * (0.45 + 0.55 * hNoise);
        final int steps = curH.round();

        // Ray-cast upward flame tongue
        for (int s = 1; s <= steps; s++) {
          final double t = s / curH; // 0.0 (root) to 1.0 (tip)
          final double curl = math.sin(s * 0.65 + _hash(x * 19 + 7) * math.pi * 2.0) * turbulence * t * 2.8;
          final int fx = (x + curl).round();
          final int fy = y - s;

          if (fy < 0 || fy >= height || fx < 0 || fx >= width) break;

          final double heat = (1.0 - t * 0.9).clamp(0.0, 1.0);
          final int color = _getFlameColor(palette, heat);
          final int alpha = ((1.0 - t * 0.55) * 255.0).round().clamp(0, 255);

          final int fIdx = fy * width + fx;
          _blendPixel(fireBuffer, fIdx, color, alpha);

          // Broaden base if t < 0.4
          if (t < 0.4 && maxH >= 8.0) {
            final int baseA = (alpha * 0.6).round();
            if (fx > 0) _blendPixel(fireBuffer, fy * width + (fx - 1), color, baseA);
            if (fx < width - 1) _blendPixel(fireBuffer, fy * width + (fx + 1), color, baseA);
          }
        }

        // Drifting ember specks
        if (emberRate > 0.05) {
          final double eHash = _hash(x * 109 + y * 53 + 83);
          if (eHash < emberRate * 0.4) {
            final double emberDist = curH + 1.0 + _hash(x * 41 + y * 67 + 29) * 8.0;
            final double emberDrift = (_hash(x * 37 + y * 97 + 11) - 0.5) * turbulence * 6.0;
            final int ex = (x + emberDrift).round();
            final int ey = (y - emberDist).round();

            if (ex >= 0 && ex < width && ey >= 0 && ey < height) {
              final int sparkColor = _getFlameColor(palette, 0.7);
              _blendPixel(fireBuffer, ey * width + ex, sparkColor, 230);
            }
          }
        }
      }
    }

    // Composite fireBuffer into output
    for (int i = 0; i < output.length; i++) {
      final int fireP = fireBuffer[i];
      final int fireA = (fireP >> 24) & 0xFF;
      if (fireA == 0) continue;

      final int srcP = pixels[i];
      final int srcA = (srcP >> 24) & 0xFF;

      if (behindOnly) {
        if (srcA == 0) {
          output[i] = fireP;
        }
      } else {
        if (srcA == 0) {
          output[i] = fireP;
        } else {
          // Flame licks blend gracefully over the boundary of the sprite
          final double fa = (fireA / 255.0) * 0.8;
          final int sr = (srcP >> 16) & 0xFF;
          final int sg = (srcP >> 8) & 0xFF;
          final int sb = srcP & 0xFF;

          final int fr = (fireP >> 16) & 0xFF;
          final int fg = (fireP >> 8) & 0xFF;
          final int fb = fireP & 0xFF;

          final int r = (fr * fa + sr * (1.0 - fa)).round().clamp(0, 255);
          final int g = (fg * fa + sg * (1.0 - fa)).round().clamp(0, 255);
          final int b = (fb * fa + sb * (1.0 - fa)).round().clamp(0, 255);

          output[i] = (srcA << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static int _getFlameColor(String palette, double heat) {
    switch (palette) {
      case 'soulBlue':
        if (heat > 0.8) return 0xFFFFFFFF; // Pure white root
        if (heat > 0.55) return 0xFF00E5FF; // Electric cyan
        if (heat > 0.3) return 0xFF0066FF; // Cobalt blue
        return 0xFF7C4DFF; // Deep violet flame tip

      case 'holyGold':
        if (heat > 0.8) return 0xFFFFFFFF; // Radiant white
        if (heat > 0.55) return 0xFFFFD700; // Brilliant gold
        if (heat > 0.3) return 0xFFFF9100; // Warm amber
        return 0xFFFF3D00; // Deep sun orange tip

      case 'necroGreen':
        if (heat > 0.8) return 0xFFF0FFF0; // Pale white root
        if (heat > 0.55) return 0xFF76FF03; // Hyper neon lime
        if (heat > 0.3) return 0xFF00C853; // Radiant emerald
        return 0xFF004D20; // Dark abyssal green tip

      case 'hellfireCrimson':
      default:
        if (heat > 0.8) return 0xFFFFFFFF; // White-hot root
        if (heat > 0.55) return 0xFFFFEB3B; // Lemon yellow
        if (heat > 0.3) return 0xFFFF6D00; // Fiery orange
        return 0xFFD50000; // Crimson flame tip
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
      final int curR = (curP >> 16) & 0xFF;
      final int curG = (curP >> 8) & 0xFF;
      final int curB = curP & 0xFF;

      final double na = a / 255.0;
      final int outR = math.max(curR, (r * na).round());
      final int outG = math.max(curG, (g * na).round());
      final int outB = math.max(curB, (b * na).round());
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
