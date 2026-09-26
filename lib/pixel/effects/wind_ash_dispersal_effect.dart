part of 'effects.dart';

/// An effect that procedurally dissolves sprite contours into blowing sand grains
/// and burning ash motes drifting downwind along a directional wind trajectory.
class WindAshDispersalEffect extends Effect {
  WindAshDispersalEffect([Map<String, dynamic>? params])
      : super(
          EffectType.windAshDispersal,
          params ??
              {
                'disperseProgress': 0.4,
                'windAngle': 20.0,
                'scatterSpread': 0.5,
                'particleDensity': 0.65,
                'driftDistance': 10.0,
                'emberGlow': 0.5,
                'ashPalette': 'volcanicAsh',
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'disperseProgress': 0.4,
        'windAngle': 20.0,
        'scatterSpread': 0.5,
        'particleDensity': 0.65,
        'driftDistance': 10.0,
        'emberGlow': 0.5,
        'ashPalette': 'volcanicAsh',
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'disperseProgress': {
          'label': 'Dispersal Progress',
          'description': 'How much of the sprite body has dissolved into ash motes.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'windAngle': {
          'label': 'Wind Angle',
          'description': 'Direction of wind blowing the particles (-60° downward to +60° upward).',
          'type': 'slider',
          'min': -60.0,
          'max': 60.0,
          'step': 5.0,
        },
        'scatterSpread': {
          'label': 'Turbulence Spread',
          'description': 'Vertical jitter and dispersion spread of drifting particles.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'particleDensity': {
          'label': 'Particle Density',
          'description': 'Abundance and frequency of airborne ash and sand grains.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'driftDistance': {
          'label': 'Drift Distance',
          'description': 'Maximum distance particles travel downwind before dissolving.',
          'type': 'slider',
          'min': 2.0,
          'max': 25.0,
          'step': 1.0,
        },
        'emberGlow': {
          'label': 'Burning Ember Glow',
          'description': 'Incandescent heated glow along the erosion front and hot motes.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'ashPalette': {
          'label': 'Ash & Dust Palette',
          'description': 'Material and mineral tone of the dissolved grains.',
          'type': 'select',
          'options': {
            'volcanicAsh': 'Volcanic Charcoal & Fire Embers',
            'desertSand': 'Desert Golden Sand & Ochre Dust',
            'spiritEctoplasm': 'Ethereal Spectral Cyan & Soul Motes',
            'charcoalBlack': 'Charcoal Soot & Black Ash',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine particles strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'disperseProgress',
          label: 'Dispersal Progress',
          description: 'How much of the sprite body has dissolved into ash motes.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'windAngle',
          label: 'Wind Angle',
          description: 'Direction of wind blowing the particles.',
          min: -60.0,
          max: 60.0,
          divisions: 24,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'scatterSpread',
          label: 'Turbulence Spread',
          description: 'Vertical jitter and dispersion spread of drifting particles.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'particleDensity',
          label: 'Particle Density',
          description: 'Abundance and frequency of airborne ash and sand grains.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'driftDistance',
          label: 'Drift Distance',
          description: 'Maximum distance particles travel downwind before dissolving.',
          min: 2.0,
          max: 25.0,
          divisions: 23,
          formatLabel: (v) => '${v.toStringAsFixed(0)}px',
        ),
        SliderField(
          key: 'emberGlow',
          label: 'Burning Ember Glow',
          description: 'Incandescent heated glow along the erosion front and hot motes.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'ashPalette',
          label: 'Ash & Dust Palette',
          description: 'Material and mineral tone of the dissolved grains.',
          options: {
            'volcanicAsh': 'Volcanic Charcoal & Fire Embers',
            'desertSand': 'Desert Golden Sand & Ochre Dust',
            'spiritEctoplasm': 'Ethereal Spectral Cyan & Soul Motes',
            'charcoalBlack': 'Charcoal Soot & Black Ash',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine particles strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double progress = ((parameters['disperseProgress'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final double angleDeg = ((parameters['windAngle'] as num?)?.toDouble() ?? 20.0).clamp(-85.0, 85.0);
    final double spread = ((parameters['scatterSpread'] as num?)?.toDouble() ?? 0.5).clamp(0.05, 1.5);
    final double density = ((parameters['particleDensity'] as num?)?.toDouble() ?? 0.65).clamp(0.05, 1.0);
    final double maxDrift = ((parameters['driftDistance'] as num?)?.toDouble() ?? 10.0).clamp(1.0, 40.0);
    final double glow = ((parameters['emberGlow'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final String paletteKey = parameters['ashPalette'] as String? ?? 'volcanicAsh';
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final palette = _getAshPalette(paletteKey);

    // Wind direction unit vector (positive angle tilts upward on screen)
    final double angleRad = angleDeg * (math.pi / 180.0);
    final double windX = math.cos(angleRad);
    final double windY = -math.sin(angleRad);
    // Perpendicular vector for turbulent scatter
    final double perpX = -windY;
    final double perpY = windX;

    // Find bounding projection along wind axis to normalize erosion front
    double minProj = 1e9;
    double maxProj = -1e9;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double p = x * windX + y * windY;
        if (p < minProj) minProj = p;
        if (p > maxProj) maxProj = p;
      }
    }
    final double projRange = math.max(1.0, maxProj - minProj);

    // Erosion threshold based on progress
    final double threshold = progress * 1.25;

    // First pass: render intact sprite pixels (with burning edge glow)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        if (origA == 0) continue;

        final double proj = (x * windX + y * windY - minProj) / projRange;
        // Multi-frequency noise for organic jagged frayed erosion edge
        final double n1 = math.sin(x * 0.45 + y * 0.3) * math.cos(y * 0.4 - x * 0.25);
        final double n2 = math.sin(x * 1.1 - y * 0.9) * 0.5;
        final double erosionVal = proj + (n1 + n2) * 0.18;

        if (erosionVal >= threshold) {
          // Pixel is intact
          final int origR = (origPixel >> 16) & 0xFF;
          final int origG = (origPixel >> 8) & 0xFF;
          final int origB = origPixel & 0xFF;

          // Heated ember glow near dissolving threshold line
          final double distToFront = erosionVal - threshold;
          if (distToFront < 0.12 && glow > 0.05) {
            final double glowT = (1.0 - distToFront / 0.12) * glow;
            final int rOut = (origR * (1.0 - glowT * 0.5) + palette.ember.r * glowT).clamp(0, 255).round();
            final int gOut = (origG * (1.0 - glowT * 0.5) + palette.ember.g * glowT).clamp(0, 255).round();
            final int bOut = (origB * (1.0 - glowT * 0.5) + palette.ember.b * glowT).clamp(0, 255).round();
            output[idx] = (origA << 24) | (rOut << 16) | (gOut << 8) | bOut;
          } else {
            output[idx] = origPixel;
          }
        }
      }
    }

    // Second pass: spawn and drift airborne ash motes & sand grains from eroded pixels
    if (progress > 0.02) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int idx = y * width + x;
          final int origPixel = pixels[idx];
          final int origA = (origPixel >> 24) & 0xFF;
          if (origA == 0) continue;

          final double proj = (x * windX + y * windY - minProj) / projRange;
          final double n1 = math.sin(x * 0.45 + y * 0.3) * math.cos(y * 0.4 - x * 0.25);
          final double n2 = math.sin(x * 1.1 - y * 0.9) * 0.5;
          final double erosionVal = proj + (n1 + n2) * 0.18;

          // Only eroded pixels within active drift distance spawn particles
          if (erosionVal < threshold && erosionVal >= threshold - 0.35) {
            final double h1 = _hash(x * 47 + y * 139 + 17);
            if (h1 > density) continue;

            final double h2 = _hash(x * 31 + y * 83 + 59);
            final double h3 = _hash(x * 79 + y * 53 + 107);

            final double erodedDepth = (threshold - erosionVal) / 0.35;
            final double travelDist = (erodedDepth + h2 * 0.35) * maxDrift;
            final double scatterOffset = (h3 - 0.5) * spread * travelDist * 0.8;

            final double targetX = x + windX * travelDist + perpX * scatterOffset;
            final double targetY = y + windY * travelDist + perpY * scatterOffset;

            final int tx = targetX.round();
            final int ty = targetY.round();

            if (tx < 0 || tx >= width || ty < 0 || ty >= height) continue;

            final int targetIdx = ty * width + tx;

            // Strict alpha isolation check
            if (preserveAlpha && (pixels[targetIdx] >> 24) == 0) {
              continue;
            }

            final int origR = (origPixel >> 16) & 0xFF;
            final int origG = (origPixel >> 8) & 0xFF;
            final int origB = origPixel & 0xFF;

            // Particle color blending: transition from ember to cool ash
            final double particleAge = erodedDepth.clamp(0.0, 1.0);
            final double emberBlend = (1.0 - particleAge) * glow;

            final int rP = (origR * 0.3 + palette.ash.r * 0.4 + palette.ember.r * emberBlend * 0.6).clamp(0, 255).round();
            final int gP = (origG * 0.3 + palette.ash.g * 0.4 + palette.ember.g * emberBlend * 0.6).clamp(0, 255).round();
            final int bP = (origB * 0.3 + palette.ash.b * 0.4 + palette.ember.b * emberBlend * 0.6).clamp(0, 255).round();

            final int particleAlpha = ((1.0 - particleAge * 0.6) * origA).round().clamp(40, 255);

            // Composite particle into target cell
            final int currentPixel = output[targetIdx];
            final int curA = (currentPixel >> 24) & 0xFF;
            if (curA == 0) {
              output[targetIdx] = (particleAlpha << 24) | (rP << 16) | (gP << 8) | bP;
            } else {
              // Additive/screen shimmer blend with underlying pixel
              final int curR = (currentPixel >> 16) & 0xFF;
              final int curG = (currentPixel >> 8) & 0xFF;
              final int curB = currentPixel & 0xFF;
              final double na = particleAlpha / 255.0;
              final int outR = (curR * (1.0 - na * 0.6) + rP * na).clamp(0, 255).round();
              final int gOut = (curG * (1.0 - na * 0.6) + gP * na).clamp(0, 255).round();
              final int bOut = (curB * (1.0 - na * 0.6) + bP * na).clamp(0, 255).round();
              final int aOut = math.max(curA, particleAlpha);
              output[targetIdx] = (aOut << 24) | (outR << 16) | (gOut << 8) | bOut;
            }
          }
        }
      }
    }

    return output;
  }

  static _AshPalette _getAshPalette(String palette) {
    switch (palette) {
      case 'desertSand':
        return const _AshPalette(
          ash: _RGB(212, 175, 115),
          ember: _RGB(255, 235, 170),
        );
      case 'spiritEctoplasm':
        return const _AshPalette(
          ash: _RGB(100, 220, 235),
          ember: _RGB(190, 255, 250),
        );
      case 'charcoalBlack':
        return const _AshPalette(
          ash: _RGB(55, 55, 60),
          ember: _RGB(120, 120, 130),
        );
      case 'volcanicAsh':
      default:
        return const _AshPalette(
          ash: _RGB(90, 75, 70),
          ember: _RGB(255, 105, 30),
        );
    }
  }

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}

class _AshPalette {
  final _RGB ash;
  final _RGB ember;
  const _AshPalette({required this.ash, required this.ember});
}
