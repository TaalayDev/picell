part of 'effects.dart';

/// Spawns a miniature black hole singularity with an event horizon void core,
/// glowing photon ring, and swirling relativistic accretion disk arms.
class GravitySingularityEffect extends Effect {
  GravitySingularityEffect([Map<String, dynamic>? params])
      : super(
          EffectType.gravitySingularity,
          params ??
              {
                'singularityRadius': 4.5,
                'diskRadius': 10.0,
                'swirlTwist': 2.5,
                'singularityPalette': 'cosmicVoid',
                'distortionStrength': 0.5,
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'singularityRadius': 4.5,
        'diskRadius': 10.0,
        'swirlTwist': 2.5,
        'singularityPalette': 'cosmicVoid',
        'distortionStrength': 0.5,
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'singularityRadius': {
          'label': 'Event Horizon Radius',
          'description': 'Radius of the central pitch-black void event horizon core.',
          'type': 'slider',
          'min': 2.0,
          'max': 10.0,
          'step': 0.5,
        },
        'diskRadius': {
          'label': 'Accretion Disk Radius',
          'description': 'Outer reach of swirling relativistic celestial matter.',
          'type': 'slider',
          'min': 4.0,
          'max': 18.0,
          'step': 1.0,
        },
        'swirlTwist': {
          'label': 'Singularity Swirl Twist',
          'description': 'Angular spiral curvature rate of the accretion arms.',
          'type': 'slider',
          'min': 0.5,
          'max': 5.0,
          'step': 0.25,
        },
        'singularityPalette': {
          'label': 'Celestial Singularity Palette',
          'description': 'Color spectrum of the accretion disk and photon ring.',
          'type': 'dropdown',
          'options': [
            {'value': 'cosmicVoid', 'label': 'Cosmic Void (Electric Cyan / Neon Magenta / Void Core)'},
            {'value': 'solarAccretion', 'label': 'Solar Accretion (Radiant Gold / Solar Orange / Crimson)'},
            {'value': 'neutronCyan', 'label': 'Neutron Star (Pure White / Hyper Blue / Deep Cobalt)'},
            {'value': 'antimatterNegative', 'label': 'Antimatter Flare (Neon Lime / Emerald / Abyssal Teal)'},
          ],
        },
        'distortionStrength': {
          'label': 'Gravitational Lensing Pull',
          'description': 'Relativistic inward warp distortion on nearby sprite pixels.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders the accretion disk behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'singularityRadius',
          label: 'Event Horizon Radius',
          description: 'Radius of the central pitch-black void event horizon core.',
          min: 2.0,
          max: 10.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'diskRadius',
          label: 'Accretion Disk Radius',
          description: 'Outer reach of swirling relativistic celestial matter.',
          min: 4.0,
          max: 18.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'swirlTwist',
          label: 'Singularity Swirl Twist',
          description: 'Angular spiral curvature rate of the accretion arms.',
          min: 0.5,
          max: 5.0,
          divisions: 18,
          formatLabel: (v) => '${v.toStringAsFixed(2)}x',
        ),
        const SelectField(
          key: 'singularityPalette',
          label: 'Celestial Singularity Palette',
          description: 'Color spectrum of the accretion disk and photon ring.',
          options: {
            'cosmicVoid': 'Cosmic Void (Cyan / Magenta / Void)',
            'solarAccretion': 'Solar Accretion (Gold / Orange / Crimson)',
            'neutronCyan': 'Neutron Star (White / Hyper Blue / Cobalt)',
            'antimatterNegative': 'Antimatter Flare (Neon Lime / Teal)',
          },
        ),
        SliderField(
          key: 'distortionStrength',
          label: 'Gravitational Lensing Pull',
          description: 'Relativistic inward warp distortion on nearby sprite pixels.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders the accretion disk behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final singularityRadius = ((parameters['singularityRadius'] as num?)?.toDouble() ?? 4.5).clamp(2.0, 10.0);
    final diskRadius = ((parameters['diskRadius'] as num?)?.toDouble() ?? 10.0).clamp(4.0, 18.0);
    final swirlTwist = ((parameters['swirlTwist'] as num?)?.toDouble() ?? 2.5).clamp(0.5, 5.0);
    final paletteKey = parameters['singularityPalette'] as String? ?? 'cosmicVoid';
    final distortion = ((parameters['distortionStrength'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // Calculate sprite center of mass
    double sumX = 0, sumY = 0;
    int solidCount = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final a = (pixels[y * width + x] >> 24) & 0xFF;
        if (a > 20) {
          sumX += x;
          sumY += y;
          solidCount++;
        }
      }
    }

    if (solidCount == 0) {
      return output;
    }

    final centerX = sumX / solidCount;
    final centerY = sumY / solidCount;
    final colors = _getSingularityColors(paletteKey);

    const bayer4x4 = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5],
    ];

    // Elliptical perspective compression for accretion disk
    const aspectY = 0.65;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final isSpritePixel = ((origPixel >> 24) & 0xFF) > 30;

        if (behindOnly && isSpritePixel) {
          continue;
        }

        final dx = x - centerX;
        final dy = (y - centerY) / aspectY;
        final r = math.sqrt(dx * dx + dy * dy);

        if (r > diskRadius + 1.5) {
          continue;
        }

        final theta = math.atan2(dy, dx);

        if (r <= singularityRadius - 0.75) {
          // Inside event horizon void core
          output[idx] = colors.voidCore;
        } else if ((r - singularityRadius).abs() <= 0.85) {
          // Luminous 1px photon sphere ring
          final ringAlpha = (255 * (1.0 - ((r - singularityRadius).abs() / 0.85))).toInt().clamp(0, 255);
          final tinted = (ringAlpha << 24) | (colors.photonRing & 0x00FFFFFF);
          output[idx] = _blendPixel(output[idx], tinted);
        } else if (r <= diskRadius) {
          // Swirling relativistic accretion disk
          final phi = theta + swirlTwist * (diskRadius / (r + 1.0));
          final spiralArm = (math.cos(2.0 * phi) * 0.5 + 0.5);

          // Radial falloff from photon ring to outer rim
          final radialNorm = (r - singularityRadius) / math.max(0.1, diskRadius - singularityRadius);
          final envelope = (1.0 - radialNorm).clamp(0.0, 1.0);
          final intensity = (spiralArm * 0.7 + 0.3) * envelope;

          final bayerVal = bayer4x4[y % 4][x % 4] / 16.0;

          if (intensity > 0.1) {
            int diskColor;
            if (intensity > 0.65) {
              diskColor = colors.innerHot;
            } else if (intensity > 0.35) {
              diskColor = colors.mid;
            } else {
              diskColor = colors.outer;
            }

            final diskAlpha = (220 * intensity).toInt().clamp(0, 255);

            // Dither fringe near boundary
            if (intensity < 0.3 && bayerVal > (intensity / 0.3)) {
              continue;
            }

            int effectivePixel = origPixel;
            // Gravitational lensing warp on sprite pixels inside disk
            if (distortion > 0.05 && isSpritePixel) {
              final pull = (1.0 - radialNorm) * distortion * 2.0;
              final sampleX = (x - (dx / (r + 0.01)) * pull).round().clamp(0, width - 1);
              final sampleY = (y - (dy * aspectY / (r + 0.01)) * pull).round().clamp(0, height - 1);
              effectivePixel = pixels[sampleY * width + sampleX];
            }

            final tinted = (diskAlpha << 24) | (diskColor & 0x00FFFFFF);
            output[idx] = _blendPixel(effectivePixel, tinted);
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

  _SingularityColors _getSingularityColors(String key) {
    switch (key) {
      case 'solarAccretion':
        return const _SingularityColors(
          voidCore: 0xFF1A0000,
          photonRing: 0xFFFFF9C4,
          innerHot: 0xFFFFD700,
          mid: 0xFFFF6D00,
          outer: 0xFFB71C1C,
        );
      case 'neutronCyan':
        return const _SingularityColors(
          voidCore: 0xFF000814,
          photonRing: 0xFFFFFFFF,
          innerHot: 0xFF00E5FF,
          mid: 0xFF2979FF,
          outer: 0xFF0D47A1,
        );
      case 'antimatterNegative':
        return const _SingularityColors(
          voidCore: 0xFF001A0A,
          photonRing: 0xFFCCFF90,
          innerHot: 0xFF76FF03,
          mid: 0xFF00E676,
          outer: 0xFF004D40,
        );
      case 'cosmicVoid':
      default:
        return const _SingularityColors(
          voidCore: 0xFF050014,
          photonRing: 0xFFE0FFFF,
          innerHot: 0xFF00E5FF,
          mid: 0xFFE040FB,
          outer: 0xFF4A0E4E,
        );
    }
  }
}

class _SingularityColors {
  final int voidCore;
  final int photonRing;
  final int innerHot;
  final int mid;
  final int outer;

  const _SingularityColors({
    required this.voidCore,
    required this.photonRing,
    required this.innerHot,
    required this.mid,
    required this.outer,
  });
}
