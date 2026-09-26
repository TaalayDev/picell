part of 'effects.dart';

/// Procedural ancient runic maze & megalithic stele generator.
///
/// Carves intricate antique labyrinth patterns (intertwining Celtic knotwork,
/// classical Greek meanders, and stepped Aztec spirals) into weathered stone
/// with directional chisel relief shading and traveling arcane runic energy pulses.
class RunicMazeEffect extends Effect implements UIFieldProvider {
  RunicMazeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.runicMaze,
          parameters ??
              const {
                'mazeStyle': 'celticKnot',
                'grooveDepth': 0.7,
                'runePulse': true,
                'runeColor': 0xFF00E5FF,
                'weatheringNoise': 0.4,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'mazeStyle': 'celticKnot',
        'grooveDepth': 0.7,
        'runePulse': true,
        'runeColor': 0xFF00E5FF,
        'weatheringNoise': 0.4,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'mazeStyle': {
          'label': 'Labyrinth Pattern',
          'description': 'Ancient cultural maze engraving style.',
          'type': 'select',
          'options': {
            'celticKnot': 'Celtic Ribbon Knotwork',
            'greekMeander': 'Classical Greek Key Meander',
            'aztecStepped': 'Mesoamerican Stepped Spiral',
          },
        },
        'grooveDepth': {
          'label': 'Chisel Relief Depth',
          'description': 'Depth and contrast of the engraved stone channels.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'runePulse': {
          'label': 'Arcane Rune Pulse',
          'description': 'Illuminate grooves with traveling magical energy.',
          'type': 'bool',
        },
        'runeColor': {
          'label': 'Rune Glow Color',
          'description': 'Luminescent color of the flowing runic pulse.',
          'type': 'color',
        },
        'weatheringNoise': {
          'label': 'Stone Weathering',
          'description': 'Ancient erosion, mineral grain, and surface pits.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress of the flowing energy pulse.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine megalithic maze to existing silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'mazeStyle',
          label: 'Labyrinth Pattern',
          description: 'Engraving geometry style.',
          options: {
            'celticKnot': 'Celtic Ribbon Knotwork',
            'greekMeander': 'Classical Greek Key Meander',
            'aztecStepped': 'Mesoamerican Stepped Spiral',
          },
        ),
        SliderField(
          key: 'grooveDepth',
          label: 'Chisel Depth',
          description: 'Relief shadow and bevel strength.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'runePulse',
          label: 'Arcane Rune Pulse',
          description: 'Flowing magical energy current.',
        ),
        const ColorField(
          key: 'runeColor',
          label: 'Rune Color',
          description: 'Magical channel luminescence.',
        ),
        SliderField(
          key: 'weatheringNoise',
          label: 'Stone Weathering',
          description: 'Surface pitting and mineral erosion.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Runic current flow progress.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict stone carving to silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final mazeStyle = parameters['mazeStyle'] as String? ?? 'celticKnot';
    final grooveDepth = (parameters['grooveDepth'] as num?)?.toDouble() ?? 0.7;
    final runePulse = parameters['runePulse'] as bool? ?? true;
    final runeColorInt = (parameters['runeColor'] as num?)?.toInt() ?? 0xFF00E5FF;
    final weatheringNoise = (parameters['weatheringNoise'] as num?)?.toDouble() ?? 0.4;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);

    final rR = (runeColorInt >> 16) & 0xFF;
    final rG = (runeColorInt >> 8) & 0xFF;
    final rB = runeColorInt & 0xFF;

    final cycleTime = time - time.floorToDouble();

    // Base monolithic stone colors (Warm Antique Sandstone/Limestone)
    const baseStoneR = 100;
    const baseStoneG = 95;
    const baseStoneB = 88;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // Mathematical groove distance and channel sequence
        double grooveDist = 0.0;
        double channelParam = 0.0; // Sequence 0.0 -> 1.0 along the maze path

        if (mazeStyle == 'greekMeander') {
          // Classical orthogonal key meander
          final cellW = math.max(6, width ~/ 4);
          final cellH = math.max(6, height ~/ 4);
          final gx = x % cellW;
          final gy = y % cellH;

          // Meander spiral key lines
          final isTopH = (gy == 1 && gx >= 1 && gx <= cellW - 2);
          final isRightV = (gx == cellW - 2 && gy >= 1 && gy <= cellH - 2);
          final isBottomH = (gy == cellH - 2 && gx >= 2 && gx <= cellW - 2);
          final isLeftV = (gx == 2 && gy >= 3 && gy <= cellH - 2);
          final isInnerH = (gy == 3 && gx >= 2 && gx <= cellW - 4);

          final isGroove = isTopH || isRightV || isBottomH || isLeftV || isInnerH;
          grooveDist = isGroove ? 0.0 : 1.0;
          channelParam = ((x / width) * 0.5 + (y / height) * 0.5 + (gx + gy) / (cellW + cellH)) % 1.0;
        } else if (mazeStyle == 'aztecStepped') {
          // Concentric stepped rectangular spirals
          final cx = width / 2.0;
          final cy = height / 2.0;
          final nx = (x - cx).abs();
          final ny = (y - cy).abs();
          final stepTier = math.max(nx, ny);

          // Stepped spiral grooves every 5 pixels
          final modDist = (stepTier % 5.0);
          grooveDist = (modDist < 1.4) ? 0.0 : 1.0;
          channelParam = (stepTier / (math.max(width, height) * 0.5)) % 1.0;
        } else {
          // 'celticKnot': Intertwining sinusoidal ribbons
          final wave1 = math.sin(x * 0.35) * 4.0;
          final wave2 = math.cos(y * 0.35) * 4.0;
          final ribbon1 = ((y + wave1) % 8.0);
          final ribbon2 = ((x + wave2) % 8.0);

          final isRibbonSeam = (ribbon1 < 1.5) || (ribbon2 < 1.5);
          grooveDist = isRibbonSeam ? 0.0 : 1.0;

          // Over/under shadow intersection
          final isIntersection = (ribbon1 < 2.5) && (ribbon2 < 2.5);
          final isUnderRibbon = isIntersection && ((x ~/ 8 + y ~/ 8) % 2 == 0);

          if (isUnderRibbon) {
            grooveDist = 0.5; // Under-ribbon cast shadow
          }
          channelParam = ((x * 0.04 + y * 0.04) % 1.0);
        }

        // Mineral weathering and micro-pit noise
        final stoneNoise = ((x * 47 + y * 89) % 11) - 5;
        final weatheredR = (baseStoneR + stoneNoise * weatheringNoise * 4).round().clamp(0, 255);
        final weatheredG = (baseStoneG + stoneNoise * weatheringNoise * 4).round().clamp(0, 255);
        final weatheredB = (baseStoneB + stoneNoise * weatheringNoise * 3).round().clamp(0, 255);

        int finalR, finalG, finalB;

        if (grooveDist < 0.2) {
          // Inside the deep carved groove
          final depthDarken = 1.0 - (grooveDepth * 0.7);
          finalR = (weatheredR * depthDarken).round();
          finalG = (weatheredG * depthDarken).round();
          finalB = (weatheredB * depthDarken).round();

          // Traveling Arcane Runic Energy Current
          if (runePulse) {
            // Pulse wave traveling through the channel
            final waveDiff = (channelParam - cycleTime).abs();
            final pulseDist = math.min(waveDiff, 1.0 - waveDiff);

            if (pulseDist < 0.18) {
              final pulseFrac = (1.0 - (pulseDist / 0.18)).clamp(0.0, 1.0);
              final isPulseCore = pulseDist < 0.05;

              final glowR = isPulseCore ? 255 : rR;
              final glowG = isPulseCore ? 255 : rG;
              final glowB = isPulseCore ? 255 : rB;

              finalR = (finalR + glowR * pulseFrac).round().clamp(0, 255);
              finalG = (finalG + glowG * pulseFrac).round().clamp(0, 255);
              finalB = (finalB + glowB * pulseFrac).round().clamp(0, 255);
            }
          }
        } else if (grooveDist <= 0.6) {
          // Groove shadow edge / underpass
          finalR = (weatheredR * 0.65).round();
          finalG = (weatheredG * 0.65).round();
          finalB = (weatheredB * 0.65).round();
        } else {
          // Flat megalith stone surface with chisel bevel on top/left edges
          final isTopLeftBevel = (x % 6 <= 1 && y % 6 <= 1);
          if (isTopLeftBevel) {
            // Chisel highlight bevel
            final bevelBoost = (grooveDepth * 35).round();
            finalR = (weatheredR + bevelBoost).clamp(0, 255);
            finalG = (weatheredG + bevelBoost).clamp(0, 255);
            finalB = (weatheredB + bevelBoost).clamp(0, 255);
          } else {
            finalR = weatheredR;
            finalG = weatheredG;
            finalB = weatheredB;
          }
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return output;
  }
}
