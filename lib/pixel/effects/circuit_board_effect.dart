part of 'effects.dart';

/// An effect that procedurally generates PCB motherboard traces, conducting bus lines,
/// circular solder vias, SMD chips, and traveling glowing electronic data pulses.
class CircuitBoardEffect extends Effect {
  CircuitBoardEffect([Map<String, dynamic>? params])
      : super(
          EffectType.circuitBoard,
          params ??
              {
                'traceDensity': 6,
                'substrateColor': 'cyberEmerald',
                'solderPadRatio': 0.5,
                'activeGlowTraces': true,
                'glowColor': 0xFF00E5FF,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'traceDensity': 6,
        'substrateColor': 'cyberEmerald',
        'solderPadRatio': 0.5,
        'activeGlowTraces': true,
        'glowColor': 0xFF00E5FF,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'traceDensity': {
          'label': 'Trace Density',
          'description': 'Number of routed copper/gold bus conduits.',
          'type': 'slider',
          'min': 2,
          'max': 10,
          'step': 1,
        },
        'substrateColor': {
          'label': 'Substrate Mask',
          'description': 'Base PCB solder mask color style.',
          'type': 'select',
          'options': {
            'cyberEmerald': 'Cyber Emerald Green',
            'matteBlack': 'Stealth Matte Black',
            'industrialNavy': 'Industrial Navy Blue',
            'solarGold': 'Solar Gold Core',
          },
        },
        'solderPadRatio': {
          'label': 'Solder Pad & SMD Ratio',
          'description': 'Frequency of circular vias and surface-mount components.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'activeGlowTraces': {
          'label': 'Active Signal Pulses',
          'description': 'Animate glowing electronic signal packets along traces.',
          'type': 'bool',
        },
        'glowColor': {
          'label': 'Signal Glow Color',
          'description': 'Color of traveling digital data packets.',
          'type': 'color',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Data transmission cycle along copper channels.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict circuit board pattern to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'traceDensity',
          label: 'Trace Density',
          description: 'Bus channel conduits.',
          min: 2,
          max: 10,
          divisions: 8,
          isInteger: true,
        ),
        const SelectField(
          key: 'substrateColor',
          label: 'Substrate Mask',
          description: 'PCB board color theme.',
          options: {
            'cyberEmerald': 'Cyber Emerald Green',
            'matteBlack': 'Stealth Matte Black',
            'industrialNavy': 'Industrial Navy Blue',
            'solarGold': 'Solar Gold Core',
          },
        ),
        const SliderField(
          key: 'solderPadRatio',
          label: 'Solder Pad & SMD Ratio',
          description: 'Vias and chip density.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
        const BoolField(
          key: 'activeGlowTraces',
          label: 'Active Signal Pulses',
          description: 'Animate traveling electronic pulses.',
        ),
        const ColorField(
          key: 'glowColor',
          label: 'Signal Glow Color',
          description: 'Data packet pulse tint.',
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Signal transmission loop.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict to existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return pixels;

    final traceDensity = (parameters['traceDensity'] as num?)?.toInt() ?? 6;
    final substrateColor = parameters['substrateColor'] as String? ?? 'cyberEmerald';
    final solderPadRatio = (parameters['solderPadRatio'] as num?)?.toDouble() ?? 0.5;
    final activeGlowTraces = parameters['activeGlowTraces'] as bool? ?? true;
    final glowColorInt = (parameters['glowColor'] as num?)?.toInt() ?? 0xFF00E5FF;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);

    // Substrate palette definitions: [baseSubstrate, darkTracerRecess, copperTrace, goldPlating, viaHole]
    final List<List<int>> palette;
    switch (substrateColor) {
      case 'matteBlack':
        palette = const [
          [24, 25, 28], // Dark carbon black
          [14, 15, 18], // Etched channel recess
          [160, 165, 175], // Silver tinned copper
          [220, 225, 230], // White-gold pads
          [5, 5, 8], // Micro-drill hole
        ];
        break;
      case 'industrialNavy':
        palette = const [
          [15, 30, 55], // Deep PCB Navy
          [8, 18, 35], // Recessed trace
          [205, 127, 50], // Rosin copper
          [255, 215, 0], // Gold flash pad
          [4, 8, 16], // Dark via
        ];
        break;
      case 'solarGold':
        palette = const [
          [50, 40, 20], // Amber-gold substrate
          [30, 24, 10], // Deep amber recess
          [240, 175, 45], // Polished gold trace
          [255, 240, 150], // Brilliant gold pad
          [15, 10, 5], // Via hole
        ];
        break;
      case 'cyberEmerald':
      default:
        palette = const [
          [12, 58, 32], // Classic solder mask green
          [6, 36, 18], // Dark etched copper trench
          [184, 115, 51], // Polished copper trace
          [255, 215, 0], // Gold immersion pad
          [3, 18, 8], // Dark via drill
        ];
        break;
    }

    final glowR = (glowColorInt >> 16) & 0xFF;
    final glowG = (glowColorInt >> 8) & 0xFF;
    final glowB = glowColorInt & 0xFF;

    final cycleTime = time - time.floorToDouble();

    // Deterministic procedural routing:
    // Generate trace highways (orthogonal and 45-degree angled paths)
    final gridSpacing = math.max(4, width ~/ (traceDensity + 1));
    final busLines = <_PCBTrace>[];

    for (int i = 1; i <= traceDensity; i++) {
      final startY = (i * gridSpacing) % height;
      final elbowX = ((i * 17) % (width - 8)) + 4;
      final angleLen = math.min(width - elbowX, height - startY);
      final isUpward = (i % 2 == 0);
      final endY = isUpward
          ? math.max(2, startY - angleLen ~/ 2)
          : math.min(height - 3, startY + angleLen ~/ 2);

      busLines.add(_PCBTrace(
        id: i,
        startX: 1,
        startY: startY,
        elbowX: elbowX,
        endX: width - 2,
        endY: endY,
      ));
    }

    // Identify solder pad locations at endpoints and intersections
    final viaPads = <math.Point<int>>[];
    for (final trace in busLines) {
      if (solderPadRatio > 0.1) {
        viaPads.add(math.Point<int>(trace.elbowX, trace.startY));
        viaPads.add(math.Point<int>(trace.endX, trace.endY));
        if (solderPadRatio > 0.5) {
          viaPads.add(math.Point<int>(trace.startX + 2, trace.startY));
        }
      }
    }

    // Render PCB canvas
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // Base substrate with micro fiberglass weaving texture
        final weave = ((x ^ y) & 1) == 0 ? 3 : -3;
        int r = (palette[0][0] + weave).clamp(0, 255);
        int g = (palette[0][1] + weave).clamp(0, 255);
        int b = (palette[0][2] + weave).clamp(0, 255);

        // Check if on a bus trace line
        bool onTrace = false;
        bool isTraceCore = false;
        double traceProgress = 0.0;
        int traceId = 0;

        for (final trace in busLines) {
          // Horizontal segment
          if (y == trace.startY && x >= trace.startX && x <= trace.elbowX) {
            onTrace = true;
            isTraceCore = true;
            traceProgress = (x - trace.startX) / (width * 1.4);
            traceId = trace.id;
            break;
          } else if ((y - trace.startY).abs() == 1 && x >= trace.startX && x <= trace.elbowX) {
            onTrace = true; // Recessed trench outline
            break;
          }

          // 45-degree or angled segment from elbow to end
          final dx = x - trace.elbowX;
          final targetDy = trace.endY - trace.startY;
          final segLen = (trace.endX - trace.elbowX).abs();

          if (dx >= 0 && segLen > 0) {
            final expectedY = trace.startY + ((dx * targetDy) ~/ segLen);
            if (y == expectedY) {
              onTrace = true;
              isTraceCore = true;
              traceProgress = (trace.elbowX - trace.startX + dx) / (width * 1.4);
              traceId = trace.id;
              break;
            } else if ((y - expectedY).abs() == 1) {
              onTrace = true; // Recessed channel edge
              break;
            }
          }
        }

        // SMD ceramic capacitors / rectangular microchips
        final isSmdBlock = (solderPadRatio > 0.3) &&
            ((x % 14 >= 10 && x % 14 <= 13) && (y % 12 >= 8 && y % 12 <= 10));

        if (isSmdBlock) {
          // Ceramic chip body with tin solder end caps
          final isEndCap = (x % 14 == 10 || x % 14 == 13);
          if (isEndCap) {
            r = palette[3][0];
            g = palette[3][1];
            b = palette[3][2];
          } else {
            // Dark ceramic capacitor center
            r = 75;
            g = 68;
            b = 58;
          }
        } else if (onTrace) {
          if (isTraceCore) {
            // Conducting copper / gold trace
            r = palette[2][0];
            g = palette[2][1];
            b = palette[2][2];

            // Active electronic signal packet wave
            if (activeGlowTraces) {
              final packetOffset = (cycleTime + traceId * 0.22) % 1.0;
              final dist = (traceProgress - packetOffset).abs();
              final cyclicDist = math.min(dist, 1.0 - dist);

              if (cyclicDist < 0.12) {
                final glowFrac = (1.0 - cyclicDist / 0.12);
                final isPulseHead = cyclicDist < 0.03;

                final pR = isPulseHead ? 255 : glowR;
                final pG = isPulseHead ? 255 : glowG;
                final pB = isPulseHead ? 255 : glowB;

                r = (r + pR * glowFrac).round().clamp(0, 255);
                g = (g + pG * glowFrac).round().clamp(0, 255);
                b = (b + pB * glowFrac).round().clamp(0, 255);
              }
            }
          } else {
            // Recessed channel shadow
            r = palette[1][0];
            g = palette[1][1];
            b = palette[1][2];
          }
        }

        // Circular solder vias with central drill hole
        for (final pad in viaPads) {
          final dx = (x - pad.x).abs();
          final dy = (y - pad.y).abs();
          if (dx <= 1 && dy <= 1) {
            if (dx == 0 && dy == 0) {
              // Dark central via drill hole
              r = palette[4][0];
              g = palette[4][1];
              b = palette[4][2];
            } else {
              // Gold plated annular ring
              r = palette[3][0];
              g = palette[3][1];
              b = palette[3][2];
            }
            break;
          }
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return output;
  }
}

class _PCBTrace {
  final int id;
  final int startX;
  final int startY;
  final int elbowX;
  final int endX;
  final int endY;

  const _PCBTrace({
    required this.id,
    required this.startX,
    required this.startY,
    required this.elbowX,
    required this.endX,
    required this.endY,
  });
}
