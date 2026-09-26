part of 'effects.dart';

/// Spawns a directional booster rocket exhaust and thruster plume originating
/// from the trailing nozzle contour of a sprite with shock diamonds, core heat,
/// customizable propellant palettes, and billowing smoke motes.
class BoosterThrusterEffect extends Effect {
  BoosterThrusterEffect([Map<String, dynamic>? params])
      : super(
          EffectType.boosterThruster,
          params ??
              {
                'thrustAngle': 90.0,
                'flameLength': 24.0,
                'plumeWidth': 0.8,
                'shockDiamonds': true,
                'exhaustPalette': 'rocketOrange',
                'smokeBillow': 0.5,
                'behindOnly': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'thrustAngle': 90.0,
        'flameLength': 24.0,
        'plumeWidth': 0.8,
        'shockDiamonds': true,
        'exhaustPalette': 'rocketOrange',
        'smokeBillow': 0.5,
        'behindOnly': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'thrustAngle': {
          'label': 'Thrust Direction',
          'description': 'Angle of thrust exhaust ejection in degrees (90° = downward rocket liftoff, 180° = thrust left).',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'step': 5.0,
        },
        'flameLength': {
          'label': 'Flame Jet Length',
          'description': 'Maximum distance of the supersonic flame exhaust plume.',
          'type': 'slider',
          'min': 8.0,
          'max': 48.0,
          'step': 2.0,
        },
        'plumeWidth': {
          'label': 'Plume Expansion Width',
          'description': 'Expansion angle and core cone thickness of the exhaust stream.',
          'type': 'slider',
          'min': 0.4,
          'max': 1.8,
          'step': 0.1,
        },
        'shockDiamonds': {
          'label': 'Supersonic Shock Diamonds',
          'description': 'Render periodic supersonic Mach shock diamond nodes along the plume core.',
          'type': 'bool',
        },
        'exhaustPalette': {
          'label': 'Propellant Palette',
          'description': 'Chemical combustion or plasma energy coloration of the thruster jet.',
          'type': 'dropdown',
          'options': [
            {'value': 'rocketOrange', 'label': 'Rocket Kerosene (White / Gold / Orange / Ember)'},
            {'value': 'plasmaBlue', 'label': 'Ion Plasma (White / Cyan / Cobalt / Violet)'},
            {'value': 'toxicGreen', 'label': 'Acid Thruster (Lime / Emerald / Dark Plum)'},
            {'value': 'cyberViolet', 'label': 'Warp Drive (Hot Pink / Magenta / Neon Violet)'},
          ],
        },
        'smokeBillow': {
          'label': 'Smoke Billow Density',
          'description': 'Turbulent smoke motes and billowing ash dispersing at the flame tail.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'Keep sprite in the foreground; thruster flame only trails behind the nozzle.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'thrustAngle',
          label: 'Thrust Direction',
          description: 'Angle of thrust exhaust ejection in degrees (90° = downward rocket liftoff, 180° = thrust left).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'flameLength',
          label: 'Flame Jet Length',
          description: 'Maximum distance of the supersonic flame exhaust plume.',
          min: 8.0,
          max: 48.0,
          divisions: 20,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'plumeWidth',
          label: 'Plume Expansion Width',
          description: 'Expansion angle and core cone thickness of the exhaust stream.',
          min: 0.4,
          max: 1.8,
          divisions: 14,
          formatLabel: (v) => v.toStringAsFixed(1),
        ),
        const BoolField(
          key: 'shockDiamonds',
          label: 'Supersonic Shock Diamonds',
          description: 'Render periodic supersonic Mach shock diamond nodes along the plume core.',
        ),
        const SelectField(
          key: 'exhaustPalette',
          label: 'Propellant Palette',
          description: 'Chemical combustion or plasma energy coloration of the thruster jet.',
          options: {
            'rocketOrange': 'Rocket Kerosene (White / Gold / Orange / Ember)',
            'plasmaBlue': 'Ion Plasma (White / Cyan / Cobalt / Violet)',
            'toxicGreen': 'Acid Thruster (Lime / Emerald / Dark Plum)',
            'cyberViolet': 'Warp Drive (Hot Pink / Magenta / Neon Violet)',
          },
        ),
        SliderField(
          key: 'smokeBillow',
          label: 'Smoke Billow Density',
          description: 'Turbulent smoke motes and billowing ash dispersing at the flame tail.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'Keep sprite in the foreground; thruster flame only trails behind the nozzle.',
        ),
      ];

  static const List<List<int>> _bayer4x4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double thrustAngleDeg = ((parameters['thrustAngle'] as num?)?.toDouble() ?? 90.0) % 360.0;
    final double maxLen = ((parameters['flameLength'] as num?)?.toDouble() ?? 24.0).clamp(8.0, 48.0);
    final double plumeWidth = ((parameters['plumeWidth'] as num?)?.toDouble() ?? 0.8).clamp(0.4, 1.8);
    final bool shockDiamonds = parameters['shockDiamonds'] as bool? ?? true;
    final String palette = parameters['exhaustPalette'] as String? ?? 'rocketOrange';
    final double smokeBillow = ((parameters['smokeBillow'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final bool behindOnly = parameters['behindOnly'] as bool? ?? true;

    final double rad = thrustAngleDeg * (math.pi / 180.0);
    final double dirX = math.cos(rad);
    final double dirY = math.sin(rad);
    final double perpX = -dirY;
    final double perpY = dirX;

    // 1. Locate nozzle contact contour on sprite facing dirX, dirY
    double maxProj = -double.infinity;
    bool hasOpaque = false;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        if (((p >> 24) & 0xFF) > 0) {
          hasOpaque = true;
          final double proj = x * dirX + y * dirY;
          if (proj > maxProj) {
            maxProj = proj;
          }
        }
      }
    }

    if (!hasOpaque) {
      return Uint32List.fromList(pixels);
    }

    // Accumulate nozzle centroid and spread of edge pixels
    double sumX = 0;
    double sumY = 0;
    int contactCount = 0;
    final List<math.Point<int>> contactPoints = [];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        if (((p >> 24) & 0xFF) > 0) {
          final double proj = x * dirX + y * dirY;
          if (proj >= maxProj - 1.5) {
            sumX += x;
            sumY += y;
            contactCount++;
            contactPoints.add(math.Point(x, y));
          }
        }
      }
    }

    final double nozzleX = contactCount > 0 ? sumX / contactCount : width / 2.0;
    final double nozzleY = contactCount > 0 ? sumY / contactCount : height / 2.0;

    // Calculate nozzle radius from perpendicular spread
    double maxPerpSpread = 1.0;
    for (final pt in contactPoints) {
      final double perpDist = ((pt.x - nozzleX) * perpX + (pt.y - nozzleY) * perpY).abs();
      if (perpDist > maxPerpSpread) {
        maxPerpSpread = perpDist;
      }
    }
    final double nozzleRadius = maxPerpSpread.clamp(1.5, 7.0);

    // 2. Render Flame Plume
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final double vx = x - nozzleX;
        final double vy = y - nozzleY;

        final double distAlong = vx * dirX + vy * dirY;
        final double distPerp = (vx * perpX + vy * perpY).abs();

        if (distAlong < -0.5 || distAlong > maxLen * 1.25) {
          continue;
        }

        final double t = (distAlong / maxLen).clamp(0.0, 1.25);

        // Core flame envelope radius at progress t
        final double envelope = nozzleRadius * (1.0 - 0.45 * t) +
            (maxLen * 0.32 * plumeWidth) * math.sin(t * math.pi) * (1.0 + 0.35 * t);
        final double effectiveRadius = math.max(1.0, envelope);

        // Check if inside flame or outer smoke billow
        if (distPerp <= effectiveRadius) {
          final double normR = (distPerp / effectiveRadius).clamp(0.0, 1.0);
          double heat = math.pow((1.0 - t * 0.85).clamp(0.0, 1.0), 0.7).toDouble() *
              (1.0 - math.pow(normR, 1.6)).clamp(0.0, 1.0);

          // Supersonic shock diamonds along core axis
          if (shockDiamonds && t >= 0.08 && t <= 0.8) {
            final double diamondPhase = t * 4.0 * math.pi;
            final double diamondCos = math.cos(diamondPhase);
            if (diamondCos > 0.35 && distPerp < effectiveRadius * 0.4 * (1.0 - t * 0.4)) {
              final double diamondFactor = (diamondCos - 0.35) / 0.65;
              final double diamondWeight = (1.0 - distPerp / (effectiveRadius * 0.4));
              heat = (heat + diamondFactor * diamondWeight * 0.45).clamp(0.0, 1.0);
            }
          }

          // Bayer 4x4 dither near outer edges
          if (normR > 0.7 || t > 0.8) {
            final int threshold = _bayer4x4[y % 4][x % 4];
            if ((heat * 16.0) < threshold * 0.9) {
              continue;
            }
          }

          // Color calculation based on heat
          final int flameColor = _getPlumeColor(palette, heat);
          int flameAlpha = ((1.0 - t * 0.4) * (1.0 - normR * 0.45) * 255.0).round().clamp(0, 255);
          if (t > 0.85) {
            flameAlpha = (flameAlpha * (1.0 - (t - 0.85) / 0.4)).round().clamp(0, 255);
          }

          if (flameAlpha > 0) {
            if (!behindOnly || ((pixels[idx] >> 24) & 0xFF) == 0) {
              final int r = (flameColor >> 16) & 0xFF;
              final int g = (flameColor >> 8) & 0xFF;
              final int b = flameColor & 0xFF;
              _blendPixel(output, idx, r, g, b, flameAlpha);
            }
          }
        } else if (smokeBillow > 0.05 && distAlong >= maxLen * 0.5 && distAlong <= maxLen * 1.35) {
          // Billowing smoke motes at the plume tail
          final double smokeMaxRadius = effectiveRadius + (smokeBillow * 8.0 * ((distAlong - maxLen * 0.5) / (maxLen * 0.85)));
          if (distPerp <= smokeMaxRadius) {
            final double smokeNoise = _hash(x * 103 + y * 199 + 71);
            if (smokeNoise > 0.38) {
              final double smokeT = (distAlong - maxLen * 0.5) / (maxLen * 0.85);
              final double smokePerpNorm = distPerp / smokeMaxRadius;
              final int smokeThreshold = _bayer4x4[y % 4][x % 4];

              if ((smokeNoise * 16.0) > smokeThreshold) {
                final int smokeColor = _getSmokeColor(palette, smokeT);
                final int smokeA = (smokeBillow * (1.0 - smokePerpNorm) * 160.0).round().clamp(0, 255);

                if (smokeA > 15) {
                  if (!behindOnly || ((pixels[idx] >> 24) & 0xFF) == 0) {
                    final int r = (smokeColor >> 16) & 0xFF;
                    final int g = (smokeColor >> 8) & 0xFF;
                    final int b = smokeColor & 0xFF;
                    _blendPixel(output, idx, r, g, b, smokeA);
                  }
                }
              }
            }
          }
        }
      }
    }

    // 3. Composite original sprite on top
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

  static int _getPlumeColor(String palette, double heat) {
    switch (palette) {
      case 'plasmaBlue':
        if (heat > 0.82) return 0xFFFFFFFF; // Pure Core White
        if (heat > 0.58) return 0xFF00F5FF; // Electric Cyan
        if (heat > 0.35) return 0xFF0066FF; // Cobalt Plasma Blue
        if (heat > 0.15) return 0xFF6200EA; // Deep Neon Violet
        return 0xFF1A004D; // Dark Abyss Purple

      case 'toxicGreen':
        if (heat > 0.82) return 0xFFF0FFF0; // Radiant White
        if (heat > 0.58) return 0xFF76FF03; // Acid Lime
        if (heat > 0.35) return 0xFF00C853; // Emerald Green
        if (heat > 0.15) return 0xFF004D20; // Toxic Forest
        return 0xFF2A0D38; // Dark Acidic Plum

      case 'cyberViolet':
        if (heat > 0.82) return 0xFFFFFFFF; // Pure White Core
        if (heat > 0.58) return 0xFFFF1493; // Deep Pink
        if (heat > 0.35) return 0xFFC51162; // Vivid Magenta
        if (heat > 0.15) return 0xFF7B1FA2; // Cyber Purple
        return 0xFF260033; // Dark Synthwave Indigo

      case 'rocketOrange':
      default:
        if (heat > 0.82) return 0xFFFFFFFF; // Supersonic Core White
        if (heat > 0.58) return 0xFFFFD700; // Bright Gold / Yellow
        if (heat > 0.35) return 0xFFFF5500; // Vivid Fire Orange
        if (heat > 0.15) return 0xFFC81000; // Crimson Burn
        return 0xFF4A1005; // Dark Ember Smoke
    }
  }

  static int _getSmokeColor(String palette, double t) {
    switch (palette) {
      case 'plasmaBlue':
        return t > 0.6 ? 0xFF1C2230 : 0xFF2D3B54;
      case 'toxicGreen':
        return t > 0.6 ? 0xFF1A241C : 0xFF263829;
      case 'cyberViolet':
        return t > 0.6 ? 0xFF231829 : 0xFF382342;
      case 'rocketOrange':
      default:
        return t > 0.6 ? 0xFF2B2828 : 0xFF453D3D;
    }
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
