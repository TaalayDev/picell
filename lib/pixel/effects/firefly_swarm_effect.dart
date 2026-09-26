part of 'effects.dart';

/// An effect that procedurally renders wandering phosphorescent fireflies drifting
/// in smooth 3D harmonic Brownian flight paths with asynchronous or synchronized
/// bio-luminescent pulsation, soft radial glow halos, and an ambient twilight meadow.
class FireflySwarmEffect extends Effect {
  FireflySwarmEffect([Map<String, dynamic>? params])
      : super(
          EffectType.fireflySwarm,
          params ??
              {
                'fireflyCount': 25,
                'blinkFrequency': 1.5,
                'glowRadius': 2.5,
                'swarmWanderRadius': 0.6,
                'synchronousBlink': false,
                'lightColor': 'phosphorGreen',
                'twilightTint': true,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'fireflyCount': 25,
        'blinkFrequency': 1.5,
        'glowRadius': 2.5,
        'swarmWanderRadius': 0.6,
        'synchronousBlink': false,
        'lightColor': 'phosphorGreen',
        'twilightTint': true,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'fireflyCount': {
          'label': 'Firefly Count',
          'description': 'Number of active glowing fireflies in the swarm.',
          'type': 'slider',
          'min': 5,
          'max': 60,
          'step': 1,
        },
        'blinkFrequency': {
          'label': 'Blink Speed',
          'description': 'Frequency of the rhythmic bioluminescent pulses.',
          'type': 'slider',
          'min': 0.5,
          'max': 5.0,
          'step': 0.1,
        },
        'glowRadius': {
          'label': 'Glow Radius',
          'description': 'Halo emission radius for individual firefly lanterns.',
          'type': 'slider',
          'min': 1.0,
          'max': 6.0,
          'step': 0.25,
        },
        'swarmWanderRadius': {
          'label': 'Wander Radius',
          'description': 'Spatial dispersion and orbital roaming radius.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'synchronousBlink': {
          'label': 'Synchronous Flash',
          'description': 'Harmonize firefly blink rhythms into unified pulses.',
          'type': 'bool',
        },
        'lightColor': {
          'label': 'Lantern Color',
          'description': 'Phosphorescent glow color scheme.',
          'type': 'select',
          'options': {
            'phosphorGreen': 'Phosphor Green',
            'goldenAmber': 'Golden Amber',
            'fairyBlue': 'Fairy Azure',
            'spectralCyan': 'Spectral Cyan',
          },
        },
        'twilightTint': {
          'label': 'Twilight Meadow',
          'description': 'Render twilight dusk sky and dark meadow silhouettes.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Progress cycle (0.0 to 1.0) advancing flight and pulses.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Constrain firefly glow within sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'fireflyCount',
          label: 'Firefly Count',
          description: 'Number of active glowing fireflies in the swarm.',
          min: 5,
          max: 60,
          divisions: 55,
          isInteger: true,
        ),
        SliderField(
          key: 'blinkFrequency',
          label: 'Blink Speed',
          description: 'Frequency of the rhythmic bioluminescent pulses.',
          min: 0.5,
          max: 5.0,
          divisions: 45,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'glowRadius',
          label: 'Glow Radius',
          description: 'Halo emission radius for individual firefly lanterns.',
          min: 1.0,
          max: 6.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'swarmWanderRadius',
          label: 'Wander Radius',
          description: 'Spatial dispersion and orbital roaming radius.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).toInt()}%',
        ),
        const BoolField(
          key: 'synchronousBlink',
          label: 'Synchronous Flash',
          description: 'Harmonize firefly blink rhythms into unified pulses.',
        ),
        const SelectField(
          key: 'lightColor',
          label: 'Lantern Color',
          description: 'Phosphorescent glow color scheme.',
          options: {
            'phosphorGreen': 'Phosphor Green',
            'goldenAmber': 'Golden Amber',
            'fairyBlue': 'Fairy Azure',
            'spectralCyan': 'Spectral Cyan',
          },
        ),
        const BoolField(
          key: 'twilightTint',
          label: 'Twilight Meadow',
          description: 'Render twilight dusk sky and dark meadow silhouettes.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Progress cycle (0.0 to 1.0) advancing flight and pulses.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Constrain firefly glow within sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final fireflyCount = ((parameters['fireflyCount'] as num?)?.toInt() ?? 25).clamp(3, 80);
    final blinkFrequency = (parameters['blinkFrequency'] as num?)?.toDouble() ?? 1.5;
    final glowRadius = ((parameters['glowRadius'] as num?)?.toDouble() ?? 2.5).clamp(1.0, 8.0);
    final swarmWanderRadius = ((parameters['swarmWanderRadius'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.2);
    final synchronousBlink = (parameters['synchronousBlink'] as bool?) ?? false;
    final lightColor = (parameters['lightColor'] as String?) ?? 'phosphorGreen';
    final twilightTint = (parameters['twilightTint'] as bool?) ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final theme = _getFireflyTheme(lightColor);

    // 1. Optional Twilight Meadow Background
    if (!preserveAlpha && twilightTint) {
      final meadowY = (height * 0.82).toInt();

      for (int y = 0; y < height; y++) {
        final normY = y / height.toDouble();

        // Sky gradient: deep indigo to dusky violet
        final skyR = (12 + normY * 36).toInt().clamp(0, 255);
        final skyG = (16 + normY * 20).toInt().clamp(0, 255);
        final skyB = (38 + normY * 28).toInt().clamp(0, 255);
        final skyColor = 0xFF000000 | (skyR << 16) | (skyG << 8) | skyB;

        for (int x = 0; x < width; x++) {
          final idx = y * width + x;

          if (y >= meadowY) {
            // Meadow grass blades silhouette
            final grassPhase = math.sin((x * 0.45) + (math.sin(x * 0.12) * 2.0));
            final bladeHeight = ((grassPhase + 1.0) * 0.5 * (height - meadowY)).toInt();

            if (y >= height - bladeHeight - 2) {
              out[idx] = (x % 3 == 0) ? 0xFF050C07 : 0xFF0A160E; // Dark silhouettes of blades
            } else {
              out[idx] = skyColor;
            }
          } else {
            out[idx] = skyColor;
          }
        }
      }
    }

    // 2. Compute 3D Brownian Wandering & Lighting for each Firefly
    for (int i = 0; i < fireflyCount; i++) {
      final seed = i * 79 + 23;

      // Base spatial anchor
      final anchorX = ((seed * 17) % width).toDouble();
      final anchorY = ((seed * 31) % (height * 0.75)).toDouble() + (height * 0.08);

      // Wander amplitudes
      final wanderX = width * swarmWanderRadius * 0.32;
      final wanderY = height * swarmWanderRadius * 0.28;

      // Harmonized 3D Lissajous flight curves
      final f1 = 1.0 + ((seed % 5) * 0.25);
      final f2 = 1.5 + (((seed + 3) % 7) * 0.2);
      final phaseX = ((seed % 100) / 100.0) * 2.0 * math.pi;
      final phaseY = (((seed + 41) % 100) / 100.0) * 2.0 * math.pi;

      final posX = anchorX + (math.sin(time * 2.0 * math.pi * f1 + phaseX) * wanderX) +
          (math.cos(time * 2.0 * math.pi * f2 + phaseY) * (wanderX * 0.35));
      final posY = anchorY + (math.cos(time * 2.0 * math.pi * f1 + phaseY) * wanderY) +
          (math.sin(time * 2.0 * math.pi * f2 + phaseX) * (wanderY * 0.35));

      // Depth modulation (pseudo-Z: -1 to 1)
      final pseudoZ = math.sin(time * 2.0 * math.pi * 0.8 + phaseX);
      final depthScale = 0.75 + (pseudoZ * 0.25); // 0.5 to 1.0

      // Bioluminescent Blink Phase
      final blinkPhaseOffset = synchronousBlink ? 0.0 : (((seed * 53) % 100) / 100.0);
      final blinkCycle = ((time * blinkFrequency * 3.5) + blinkPhaseOffset) % 1.0;

      // Asymmetric phosphorescent pulse curve
      final double pulse;
      if (blinkCycle < 0.25) {
        // Fast organic ramp up
        pulse = math.pow(math.sin((blinkCycle / 0.25) * (math.pi / 2.0)), 2.0).toDouble();
      } else {
        // Exponential decay glow
        final decay = (blinkCycle - 0.25) / 0.75;
        pulse = math.exp(-decay * 4.2);
      }

      if (pulse < 0.04) continue; // Firefly lantern is dark

      final effectiveRadius = glowRadius * depthScale;
      final radCeil = (effectiveRadius + 1.5).ceil();

      final cx = posX.round();
      final cy = posY.round();

      // Render radial phosphorescent glow
      for (int dy = -radCeil; dy <= radCeil; dy++) {
        final py = cy + dy;
        if (py < 0 || py >= height) continue;

        for (int dx = -radCeil; dx <= radCeil; dx++) {
          final px = cx + dx;
          if (px < 0 || px >= width) continue;

          final idx = py * width + px;

          if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
            continue;
          }

          final distSq = (dx * dx + dy * dy).toDouble();
          final dist = math.sqrt(distSq);

          if (dist > effectiveRadius + 1.0) continue;

          // Gaussian halo attenuation
          final normDist = dist / effectiveRadius;
          final haloFactor = math.exp(-normDist * normDist * 2.5);
          final haloAlpha = (pulse * haloFactor * 255).toInt().clamp(0, 255);

          if (haloAlpha <= 2) continue;

          if (dx == 0 && dy == 0) {
            // Bright white/pale luminous core
            out[idx] = _additiveBlend(out[idx], theme.coreColor, (pulse * 255).toInt().clamp(0, 255));
          } else if (dist <= 1.2) {
            // Phosphorescent body lantern
            out[idx] = _additiveBlend(out[idx], theme.bodyColor, haloAlpha);
          } else {
            // Soft atmospheric outer halo
            out[idx] = _additiveBlend(out[idx], theme.haloColor, haloAlpha);
          }
        }
      }
    }

    return out;
  }

  // -----------------------------
  // Theme Color Grading
  // -----------------------------

  _FireflyTheme _getFireflyTheme(String key) {
    switch (key) {
      case 'goldenAmber':
        return const _FireflyTheme(
          coreColor: 0xFFFFFBE8, // Warm incandescent core
          bodyColor: 0xFFFFC933, // Golden amber lantern
          haloColor: 0xFFD48208, // Soft dusk amber glow
        );
      case 'fairyBlue':
        return const _FireflyTheme(
          coreColor: 0xFFEBFBFF, // Icy starlight core
          bodyColor: 0xFF42DBFF, // Fairy azure lantern
          haloColor: 0xFF148FC4, // Cyan mist halo
        );
      case 'spectralCyan':
        return const _FireflyTheme(
          coreColor: 0xFFE0FFF8, // Pale turquoise core
          bodyColor: 0xFF21F5B8, // Spectral cyan lantern
          haloColor: 0xFF0DA375, // Swamp wisp glow
        );
      case 'phosphorGreen':
      default:
        return const _FireflyTheme(
          coreColor: 0xFFF5FFE8, // Pale phosphor core
          bodyColor: 0xFF99FF33, // Vivid bio-luminescent lime
          haloColor: 0xFF54CC0E, // Soft meadow emerald halo
        );
    }
  }

  // -----------------------------
  // Additive Color Blending
  // -----------------------------

  int _additiveBlend(int base, int light, int alpha) {
    final a = alpha.clamp(0, 255) / 255.0;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final lR = (light >>> 16) & 0xFF;
    final lG = (light >>> 8) & 0xFF;
    final lB = light & 0xFF;

    final r = math.min(255, bR + (lR * a).toInt());
    final g = math.min(255, bG + (lG * a).toInt());
    final b = math.min(255, bB + (lB * a).toInt());

    final finalAlpha = math.max(bA, (alpha * 0.9).toInt().clamp(0, 255));
    return (finalAlpha << 24) | (r << 16) | (g << 8) | b;
  }
}

class _FireflyTheme {
  final int coreColor;
  final int bodyColor;
  final int haloColor;

  const _FireflyTheme({
    required this.coreColor,
    required this.bodyColor,
    required this.haloColor,
  });
}
