part of 'effects.dart';

/// An effect that procedurally renders exotic coral reefs: convoluted Turing reaction-diffusion
/// brain coral labyrinths, branching fan corals, and undulating bioluminescent polyps anchored to sea sediment.
class CoralReefEffect extends Effect {
  CoralReefEffect([Map<String, dynamic>? params])
      : super(
          EffectType.coralReef,
          params ??
              {
                'coralPattern': 'turingBrain',
                'bioluminescenceGlow': 0.6,
                'polypDensity': 25,
                'waterDepthTint': 'tropicalLagoon',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'coralPattern': 'turingBrain',
        'bioluminescenceGlow': 0.6,
        'polypDensity': 25,
        'waterDepthTint': 'tropicalLagoon',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'coralPattern': {
          'label': 'Coral Morphology',
          'description': 'Biological growth structure and labyrinth pattern.',
          'type': 'select',
          'options': {
            'turingBrain': 'Turing Reaction-Diffusion Brain Coral',
            'branchingFan': 'Branching Sea Fan Gorgonian',
            'tubeSponge': 'Bioluminescent Tube Sponge Spire',
          },
        },
        'bioluminescenceGlow': {
          'label': 'Bioluminescence Glow',
          'description': 'Intensity of glowing living polyp tentacles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'polypDensity': {
          'label': 'Polyp Cluster Count',
          'description': 'Number of glowing living polyp nodes.',
          'type': 'slider',
          'min': 0,
          'max': 50,
          'step': 5,
        },
        'waterDepthTint': {
          'label': 'Aquatic Depth Tint',
          'description': 'Subaquatic ambient water column light absorption.',
          'type': 'select',
          'options': {
            'tropicalLagoon': 'Tropical Lagoon Turquoise',
            'abyssalDeep': 'Abyssal Deep Ocean Indigo',
            'bioluminescentTrench': 'Bioluminescent Mariana Trench Violet',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Undulating polyp pulse and subaquatic current sway.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict coral reef to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'coralPattern',
          label: 'Coral Morphology',
          description: 'Coral growth structure.',
          options: {
            'turingBrain': 'Turing Reaction-Diffusion Brain Coral',
            'branchingFan': 'Branching Sea Fan Gorgonian',
            'tubeSponge': 'Bioluminescent Tube Sponge Spire',
          },
        ),
        const SliderField(
          key: 'bioluminescenceGlow',
          label: 'Bioluminescence Glow',
          description: 'Glowing polyp intensity.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
        const SliderField(
          key: 'polypDensity',
          label: 'Polyp Cluster Count',
          description: 'Luminescent polyp count.',
          min: 0,
          max: 50,
          divisions: 10,
          isInteger: true,
        ),
        const SelectField(
          key: 'waterDepthTint',
          label: 'Aquatic Depth Tint',
          description: 'Ambient water column color.',
          options: {
            'tropicalLagoon': 'Tropical Lagoon Turquoise',
            'abyssalDeep': 'Abyssal Deep Ocean Indigo',
            'bioluminescentTrench': 'Bioluminescent Mariana Trench Violet',
          },
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Subaquatic sway & polyp pulse.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return pixels;

    final coralPattern = parameters['coralPattern'] as String? ?? 'turingBrain';
    final bioluminescenceGlow = (parameters['bioluminescenceGlow'] as num?)?.toDouble() ?? 0.6;
    final polypDensity = (parameters['polypDensity'] as num?)?.toInt() ?? 25;
    final waterDepthTint = parameters['waterDepthTint'] as String? ?? 'tropicalLagoon';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);
    final cycleTime = time - time.floorToDouble();

    // Ambient water column base color: [waterBase, waterHighlight, sedimentGround]
    final List<List<int>> waterCol;
    switch (waterDepthTint) {
      case 'abyssalDeep':
        waterCol = const [
          [4, 18, 48], // Abyssal indigo
          [10, 35, 85], // Caustic blue
          [12, 16, 28], // Silt bed
        ];
        break;
      case 'bioluminescentTrench':
        waterCol = const [
          [18, 5, 42], // Deep violet trench
          [45, 12, 95], // Fluorescent purple
          [22, 10, 30], // Volcanic sediment
        ];
        break;
      case 'tropicalLagoon':
      default:
        waterCol = const [
          [8, 52, 68], // Turquoise lagoon
          [18, 110, 130], // Sunlit shallows
          [58, 52, 42], // Carbonate sand
        ];
        break;
    }

    // Fixed pseudorandom polyp positions
    final rand = math.Random(777);
    final polyps = <_ReefPolyp>[];
    for (int p = 0; p < polypDensity; p++) {
      final px = rand.nextInt(width);
      final py = rand.nextInt(height);
      final pColorType = rand.nextInt(3); // 0=neon cyan, 1=electric magenta, 2=bio lime
      final phase = rand.nextDouble();
      polyps.add(_ReefPolyp(px, py, pColorType, phase));
    }

    for (int y = 0; y < height; y++) {
      final ny = y / height;
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // Subaquatic ambient current sway
        final sway = math.sin(cycleTime * math.pi * 2.0 + ny * 3.5) * 1.5;
        final sx = x + sway;

        // Water depth gradient (darker towards bottom)
        final depthFrac = (ny).clamp(0.0, 1.0);
        int r = (waterCol[1][0] * (1.0 - depthFrac) + waterCol[0][0] * depthFrac).round();
        int g = (waterCol[1][1] * (1.0 - depthFrac) + waterCol[0][1] * depthFrac).round();
        int b = (waterCol[1][2] * (1.0 - depthFrac) + waterCol[0][2] * depthFrac).round();

        // Sea floor sediment at bottom 15%
        if (ny > 0.85) {
          final sedT = (ny - 0.85) / 0.15;
          r = (r * (1.0 - sedT) + waterCol[2][0] * sedT).round();
          g = (g * (1.0 - sedT) + waterCol[2][1] * sedT).round();
          b = (b * (1.0 - sedT) + waterCol[2][2] * sedT).round();
        }

        // Coral morphology computation
        bool isCoral = false;
        bool isRidge = false;
        int cR = 0, cG = 0, cB = 0;

        if (coralPattern == 'branchingFan') {
          // Gorgonian sea fan: radial upward branches with micro-pinnules
          final baseCx = width / 2.0;
          final baseCy = height.toDouble();
          final fanDx = sx - baseCx;
          final fanDy = baseCy - y;

          if (fanDy > 4) {
            final fanAngle = math.atan2(fanDx, fanDy); // Angle from vertical
            final angleSpread = fanAngle.abs();

            if (angleSpread < 1.05) {
              // Subdivided branch ribs
              final branchRib = math.sin(fanAngle * 12.0);
              final isStem = branchRib.abs() > 0.65;
              final crossLattice = (math.sqrt(fanDx * fanDx + fanDy * fanDy) % 6.0) < 1.4;

              if (isStem || crossLattice) {
                isCoral = true;
                isRidge = isStem;
                // Gorgonian scarlet and sea-fan purple
                cR = 210;
                cG = 45;
                cB = 85;
              }
            }
          }
        } else if (coralPattern == 'tubeSponge') {
          // Vertical tube sponge chimneys
          final tubeX = (sx % 10.0);
          final inTube = (tubeX >= 3.0 && tubeX <= 7.0) && (y > height * 0.35);
          final isTubeRim = inTube && (tubeX == 3.0 || tubeX == 7.0 || y.toInt() == (height * 0.35).toInt());

          if (inTube) {
            isCoral = true;
            isRidge = isTubeRim;
            // Azure tube sponge with electric yellow rim
            if (isTubeRim) {
              cR = 255;
              cG = 230;
              cB = 60;
            } else {
              cR = 30;
              cG = 120;
              cB = 195;
            }
          }
        } else {
          // 'turingBrain': Reaction-diffusion labyrinth ridges
          // Approximated via sum of trigonometric spatial standing waves
          final w1 = math.sin(sx * 0.45 + math.cos(y * 0.45));
          final w2 = math.cos(y * 0.45 + math.sin(sx * 0.45));
          final w3 = math.sin((sx + y) * 0.35);
          final turingVal = w1 + w2 + w3;

          final inRidge = turingVal.abs() < 0.6;
          final isRidgePeak = turingVal.abs() < 0.2;

          if (inRidge) {
            isCoral = true;
            isRidge = isRidgePeak;
            // Brain coral warm coral-pink with emerald grooves
            if (isRidgePeak) {
              cR = 255;
              cG = 125;
              cB = 120;
            } else {
              cR = 190;
              cG = 65;
              cB = 85;
            }
          }
        }

        if (isCoral) {
          final blendFactor = isRidge ? 0.95 : 0.75;
          r = (r * (1.0 - blendFactor) + cR * blendFactor).round().clamp(0, 255);
          g = (g * (1.0 - blendFactor) + cG * blendFactor).round().clamp(0, 255);
          b = (b * (1.0 - blendFactor) + cB * blendFactor).round().clamp(0, 255);
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    // Living bioluminescent polyp clusters with radial halo
    if (bioluminescenceGlow > 0.05) {
      for (final polyp in polyps) {
        if (polyp.x < 0 || polyp.x >= width || polyp.y < 0 || polyp.y >= height) continue;

        // Polyp respiration pulsation
        final pulse = 0.5 + 0.5 * math.sin(cycleTime * math.pi * 4.0 + polyp.phase * math.pi * 2.0);
        final glowStrength = bioluminescenceGlow * pulse;

        int pR, pG, pB;
        if (polyp.colorType == 0) {
          // Neon electric cyan
          pR = 0;
          pG = 240;
          pB = 255;
        } else if (polyp.colorType == 1) {
          // Fluorescent neon magenta
          pR = 255;
          pG = 30;
          pB = 210;
        } else {
          // Bio acid green
          pR = 118;
          pG = 255;
          pB = 3;
        }

        // Draw polyp core and radial aura
        for (int dy = -2; dy <= 2; dy++) {
          final py = polyp.y + dy;
          if (py < 0 || py >= height) continue;
          for (int dx = -2; dx <= 2; dx++) {
            final px = polyp.x + dx;
            if (px < 0 || px >= width) continue;

            final pIdx = py * width + px;
            final origA = (pixels[pIdx] >> 24) & 0xFF;
            if (preserveAlpha && origA == 0) continue;

            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist <= 2.2) {
              final falloff = (1.0 - dist / 2.2) * glowStrength;
              final cur = output[pIdx];
              final cR = (cur >> 16) & 0xFF;
              final cG = (cur >> 8) & 0xFF;
              final cB = cur & 0xFF;

              final targetR = (cR + pR * falloff).round().clamp(0, 255);
              final targetG = (cG + pG * falloff).round().clamp(0, 255);
              final targetB = (cB + pB * falloff).round().clamp(0, 255);
              final targetA = preserveAlpha ? origA : 255;

              output[pIdx] = (targetA << 24) | (targetR << 16) | (targetG << 8) | targetB;
            }
          }
        }
      }
    }

    return output;
  }
}

class _ReefPolyp {
  final int x;
  final int y;
  final int colorType;
  final double phase;

  const _ReefPolyp(this.x, this.y, this.colorType, this.phase);
}
