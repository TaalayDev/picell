part of 'effects.dart';

/// Procedural underwater caustics and liquid wobble effect featuring
/// refractive wave interference networks, water tinting, and buoyancy sway.
class UnderwaterCausticsEffect extends Effect implements UIFieldProvider {
  UnderwaterCausticsEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.underwaterCaustics,
          parameters ??
              const {
                'causticScale': 1.5,
                'rippleSpeed': 1.5,
                'waterTint': 0xFF00E5FF,
                'tintStrength': 0.4,
                'buoyancySway': 1.2,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'causticScale': 1.5,
        'rippleSpeed': 1.5,
        'waterTint': 0xFF00E5FF,
        'tintStrength': 0.4,
        'buoyancySway': 1.2,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'causticScale': {
          'label': 'Caustic Mesh Scale',
          'description': 'Scale and frequency of the refractive sunlight mesh.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'rippleSpeed': {
          'label': 'Caustic Ripple Speed',
          'description': 'Speed of the shimmering surface light pattern movement.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'waterTint': {
          'label': 'Aquatic Water Tint',
          'description': 'Color filter of the surrounding liquid volume.',
          'type': 'color',
        },
        'tintStrength': {
          'label': 'Water Tint Intensity',
          'description': 'Depth of the chromatic aquatic tint overlay.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'buoyancySway': {
          'label': 'Buoyancy Liquid Sway',
          'description': 'Horizontal sinusoidal liquid wobble distortion amplitude.',
          'type': 'slider',
          'min': 0.0,
          'max': 3.0,
          'divisions': 30,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for fluid wave movement.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Allow water shimmer to float cleanly over transparent background.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'causticScale',
          label: 'Caustic Scale',
          description: 'Grid density of the refractive sunlight web.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'rippleSpeed',
          label: 'Ripple Speed',
          description: 'Undulation velocity of dancing light caustics.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'waterTint',
          label: 'Water Depth Color',
          description: 'Color of the submerged water immersion filter.',
        ),
        SliderField(
          key: 'tintStrength',
          label: 'Water Tint Depth',
          description: 'Opacity of the underwater color immersion.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'buoyancySway',
          label: 'Buoyancy Sway',
          description: 'Horizontal wobble distortion amplitude.',
          min: 0.0,
          max: 3.0,
          divisions: 30,
          formatLabel: (v) => '${v.toStringAsFixed(1)} px',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter for looping animation frames.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'When enabled, caustics apply over transparent canvas.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final causticScale = ((parameters['causticScale'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final rippleSpeed = ((parameters['rippleSpeed'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final waterTintInt = (parameters['waterTint'] as int?) ?? 0xFF00E5FF;
    final tintStrength = ((parameters['tintStrength'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final buoyancySway = ((parameters['buoyancySway'] as num?)?.toDouble() ?? 1.2).clamp(0.0, 3.0);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final tintR = (waterTintInt >> 16) & 0xFF;
    final tintG = (waterTintInt >> 8) & 0xFF;
    final tintB = waterTintInt & 0xFF;

    final result = Uint32List(width * height);
    final waveTime = time * 2.0 * math.pi * rippleSpeed;

    for (int y = 0; y < height; y++) {
      // Horizontal buoyancy sway offset
      final sway = math.sin(y * 0.18 + waveTime) * buoyancySway;

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        // Sample with sway distortion
        int srcPixel;
        if (buoyancySway > 0.01) {
          final sx = (x - sway).round().clamp(0, width - 1);
          srcPixel = pixels[y * width + sx];
        } else {
          srcPixel = pixels[idx];
        }

        final srcA = (srcPixel >> 24) & 0xFF;
        if (srcA == 0 && preserveAlpha) {
          result[idx] = 0x00000000;
          continue;
        }

        int curR = (srcPixel >> 16) & 0xFF;
        int curG = (srcPixel >> 8) & 0xFF;
        int curB = srcPixel & 0xFF;
        int curA = srcA;

        // If not preserving alpha, generate deep aquatic background
        if (srcA == 0 && !preserveAlpha) {
          final depthFactor = (y / math.max(1, height)).clamp(0.0, 1.0);
          curA = 255;
          curR = ((tintR * 0.1) * (1.0 - depthFactor)).round();
          curG = ((tintG * 0.35) * (1.0 - depthFactor) + 15).round();
          curB = ((tintB * 0.55) * (1.0 - depthFactor) + 40).round();
        } else if (tintStrength > 0.01) {
          // Apply aquatic water tint
          curR = (curR * (1.0 - tintStrength) + tintR * tintStrength).round().clamp(0, 255);
          curG = (curG * (1.0 - tintStrength) + tintG * tintStrength).round().clamp(0, 255);
          curB = (curB * (1.0 - tintStrength) + tintB * tintStrength).round().clamp(0, 255);
        }

        // 3-Wave Interference Caustic Light Mesh
        final u = x * 0.16 * causticScale;
        final v = y * 0.16 * causticScale;

        final w1 = math.sin(u * 1.2 + v * 0.7 + waveTime);
        final w2 = math.sin(u * 0.6 - v * 1.4 + waveTime * 1.25);
        final w3 = math.cos(u * 1.1 + v * 1.1 - waveTime * 0.85);

        final sum = (w1 + w2 + w3) / 3.0;
        final causticVal = math.pow(sum.abs(), 3.5).toDouble(); // Narrow bright light ridges

        if (causticVal > 0.05) {
          final highlight = (causticVal * 200).round().clamp(0, 255);
          // Additive sunlit caustic highlight
          curR = math.min(255, curR + highlight);
          curG = math.min(255, curG + highlight);
          curB = math.min(255, curB + math.min(255, highlight + 30));
        }

        result[idx] = (curA << 24) | (curR << 16) | (curG << 8) | curB;
      }
    }

    return result;
  }
}
