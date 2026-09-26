part of 'effects.dart';

/// Procedural autumn wind and foliage vortex effect featuring tumbling sakura petals,
/// maple leaves, and ginkgo leaves with aerodynamic gusts, 3D tumbling, and swirl currents.
class AutumnWindEffect extends Effect implements UIFieldProvider {
  AutumnWindEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.autumnWind,
          parameters ??
              const {
                'foliageType': 'maple',
                'leafCount': 25,
                'windStrength': 1.2,
                'gustFrequency': 1.5,
                'swirlVortex': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'foliageType': 'maple',
        'leafCount': 25,
        'windStrength': 1.2,
        'gustFrequency': 1.5,
        'swirlVortex': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'foliageType': {
          'label': 'Foliage Specimen',
          'description': 'Botanical particle shape and autumnal chromatic palette.',
          'type': 'select',
          'options': {
            'sakura': 'Cherry Blossom Petals (Sakura)',
            'maple': 'Autumn Scarlet Maple (Momiji)',
            'ginkgo': 'Golden Fan Ginkgo (Icho)',
          },
        },
        'leafCount': {
          'label': 'Foliage Density',
          'description': 'Quantity of tumbling leaves or petals caught in the wind.',
          'type': 'slider',
          'min': 10,
          'max': 60,
          'divisions': 50,
        },
        'windStrength': {
          'label': 'Wind Gale Velocity',
          'description': 'Horizontal and vertical drift speed of the atmospheric current.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'gustFrequency': {
          'label': 'Sinusoidal Gust Flutter',
          'description': 'Rate of undulating air turbulence and tumbling flutter.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'swirlVortex': {
          'label': 'Helical Swirl Vortex',
          'description': 'Form spiraling mini dust-devils and curling leaf vortices.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for looping leaf flight cycles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine foliage within sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'foliageType',
          label: 'Foliage Type',
          description: 'Type of windborne leaves or flower petals.',
          options: {
            'sakura': 'Cherry Blossom Petals (Sakura)',
            'maple': 'Autumn Scarlet Maple (Momiji)',
            'ginkgo': 'Golden Fan Ginkgo (Icho)',
          },
        ),
        SliderField(
          key: 'leafCount',
          label: 'Leaf Count',
          description: 'Number of swirling foliage particles.',
          min: 10,
          max: 60,
          divisions: 50,
          formatLabel: (v) => '${v.round()} leaves',
        ),
        SliderField(
          key: 'windStrength',
          label: 'Wind Strength',
          description: 'Drift velocity of the breeze current.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'gustFrequency',
          label: 'Gust Frequency',
          description: 'Rate of undulating wind gusts.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const BoolField(
          key: 'swirlVortex',
          label: 'Swirl Vortex',
          description: 'Curling mini vortex in the wind stream.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the wind cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep transparency around sprite bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final foliageType = parameters['foliageType']?.toString() ?? 'maple';
    final leafCount = (parameters['leafCount'] as num?)?.toInt() ?? 25;
    final windStrength = (parameters['windStrength'] as num?)?.toDouble() ?? 1.2;
    final gustFrequency = (parameters['gustFrequency'] as num?)?.toDouble() ?? 1.5;
    final swirlVortex = parameters['swirlVortex'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    void setPixel(int px, int py, int color) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final cA = (color >> 24) & 0xFF;
      final cR = (color >> 16) & 0xFF;
      final cG = (color >> 8) & 0xFF;
      final cB = color & 0xFF;

      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      final alphaFrac = cA / 255.0;
      final newR = (oR * (1.0 - alphaFrac) + cR * alphaFrac).round().clamp(0, 255);
      final newG = (oG * (1.0 - alphaFrac) + cG * alphaFrac).round().clamp(0, 255);
      final newB = (oB * (1.0 - alphaFrac) + cB * alphaFrac).round().clamp(0, 255);
      final newA = preserveAlpha ? origA : math.max(origA, cA);

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    final cycleTime = time - time.floorToDouble();
    final timeRad = cycleTime * math.pi * 2.0;

    for (int i = 0; i < leafCount; i++) {
      // Deterministic trajectory seed
      final seedX = ((i * 137.5) % (width + 60)) - 30.0;
      final seedY = ((i * 93.7) % (height + 60)) - 30.0;
      final speedVar = 0.8 + 0.4 * (((i * 47 + 11) % 100) / 100.0);
      final phaseOffset = ((i * 61 + 23) % 100) / 100.0;

      final p = (cycleTime * speedVar + phaseOffset) % 1.0;

      // Base linear drift across screen
      final driftX = p * (width + 80) * windStrength * 0.7;
      final driftY = p * (height + 50) * windStrength * 0.35;

      // Sinusoidal wind gust fluttering
      final gustX = math.sin(timeRad * gustFrequency + i * 0.6) * 10.0;
      final gustY = math.cos(timeRad * gustFrequency * 1.3 + i * 0.9) * 6.0;

      // Helical vortex swirl
      double vortexX = 0.0;
      double vortexY = 0.0;
      if (swirlVortex) {
        final vortexPhase = (timeRad * 2.0 + i * 1.2);
        final vortexRadius = 6.0 + 4.0 * math.sin(i * 1.7);
        vortexX = math.cos(vortexPhase) * vortexRadius;
        vortexY = math.sin(vortexPhase) * vortexRadius * 0.5;
      }

      var leafX = (seedX + driftX + gustX + vortexX);
      var leafY = (seedY + driftY + gustY + vortexY);

      // Wrap cleanly around canvas
      leafX = (leafX + 30) % (width + 60) - 30;
      leafY = (leafY + 30) % (height + 60) - 30;

      final lx = leafX.round();
      final ly = leafY.round();

      if (lx < -4 || lx > width + 4 || ly < -4 || ly > height + 4) continue;

      // Pseudo-3D tumbling rotation
      final tumblePhase = timeRad * (2.0 + (i % 3) * 0.8) + i * 1.5;
      final scaleX = math.cos(tumblePhase);
      final isFlipped = scaleX < 0;
      final absScaleX = scaleX.abs();

      // Render based on foliage specimen
      switch (foliageType) {
        case 'sakura':
          // Cherry blossom petal (delicate soft pinks)
          final cCore = isFlipped ? 0xFFF06292 : 0xFFFF80AB;
          const cEdge = 0xFFF8BBD0;

          if (absScaleX > 0.4) {
            setPixel(lx, ly, cCore);
            setPixel(lx + (isFlipped ? -1 : 1), ly, cEdge);
            setPixel(lx, ly - 1, cEdge);
            setPixel(lx + (isFlipped ? 1 : -1), ly + 1, cCore);
          } else {
            // Edge-on tumble sliver
            setPixel(lx, ly, cCore);
            setPixel(lx, ly - 1, cEdge);
          }
          break;

        case 'ginkgo':
          // Golden fan ginkgo (golden yellows)
          final cGold = isFlipped ? 0xFFFFC107 : 0xFFFFD600;
          const cLight = 0xFFFFEA00;
          const cStem = 0xFFFFA000;

          if (absScaleX > 0.45) {
            setPixel(lx, ly, cGold);
            setPixel(lx - 1, ly - 1, cLight);
            setPixel(lx, ly - 1, cLight);
            setPixel(lx + 1, ly - 1, cLight);
            setPixel(lx, ly + 1, cStem);
          } else {
            // Edge-on sliver
            setPixel(lx, ly, cGold);
            setPixel(lx, ly - 1, cLight);
            setPixel(lx, ly + 1, cStem);
          }
          break;

        case 'maple':
        default:
          // Autumn scarlet maple (vibrant scarlet, crimson, amber)
          final cMain = isFlipped ? 0xFFD84315 : 0xFFFF5722;
          const cBright = 0xFFFF7043;
          const cTip = 0xFFFFAB00;
          const cStem = 0xFFBF360C;

          if (absScaleX > 0.5) {
            setPixel(lx, ly, cMain);
            setPixel(lx, ly - 1, cBright);
            setPixel(lx - 1, ly, cTip);
            setPixel(lx + 1, ly, cTip);
            setPixel(lx, ly + 1, cStem);
          } else if (absScaleX > 0.25) {
            setPixel(lx, ly, cMain);
            setPixel(lx, ly - 1, cBright);
            setPixel(lx, ly + 1, cStem);
          } else {
            // Pure vertical tumbling sliver
            setPixel(lx, ly, cMain);
            setPixel(lx, ly - 1, cBright);
          }
          break;
      }
    }

    return output;
  }
}
