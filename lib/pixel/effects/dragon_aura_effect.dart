part of 'effects.dart';

/// Procedural supercharged dragon aura & limit break eruption effect.
///
/// Features energetic rising plasma flames enveloping the sprite silhouette,
/// shooting jagged upward energy spikes, internal core supercharging luminance,
/// and crackling miniature static lightning bolts.
class DragonAuraEffect extends Effect implements UIFieldProvider {
  DragonAuraEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.dragonAura,
          parameters ??
              const {
                'auraColor': 0xFFFFD600,
                'spikiness': 0.7,
                'riseSpeed': 1.5,
                'coreLuminance': 0.6,
                'miniArcs': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'auraColor': 0xFFFFD600,
        'spikiness': 0.7,
        'riseSpeed': 1.5,
        'coreLuminance': 0.6,
        'miniArcs': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'auraColor': {
          'label': 'Aura Color',
          'description': 'Luminescent color of the raging plasma energy flames.',
          'type': 'color',
        },
        'spikiness': {
          'label': 'Flame Spikiness',
          'description': 'Height and sharpness of jagged erupting flame spikes.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'riseSpeed': {
          'label': 'Rise Velocity',
          'description': 'Upward velocity of ascending plasma currents.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.1,
        },
        'coreLuminance': {
          'label': 'Core Supercharge',
          'description': 'Internal power surge illuminating the sprite body.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'miniArcs': {
          'label': 'Static Lightning Arcs',
          'description': 'Discharge crackling miniature electricity arcs.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the flame eruption cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine aura energy within character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const ColorField(
          key: 'auraColor',
          label: 'Aura Color',
          description: 'Color of the supercharged limit break plasma.',
        ),
        SliderField(
          key: 'spikiness',
          label: 'Flame Spikiness',
          description: 'Height of jagged erupting energy spikes.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'riseSpeed',
          label: 'Rise Velocity',
          description: 'Upward speed of rising plasma flames.',
          min: 0.5,
          max: 3.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'coreLuminance',
          label: 'Core Supercharge',
          description: 'Internal brightness power surge.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'miniArcs',
          label: 'Static Lightning Arcs',
          description: 'Crackling miniature static electricity.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Aura eruption timeline progress.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict aura within character silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final auraColorInt = (parameters['auraColor'] as num?)?.toInt() ?? 0xFFFFD600;
    final spikiness = (parameters['spikiness'] as num?)?.toDouble() ?? 0.7;
    final riseSpeed = (parameters['riseSpeed'] as num?)?.toDouble() ?? 1.5;
    final coreLuminance = (parameters['coreLuminance'] as num?)?.toDouble() ?? 0.6;
    final miniArcs = parameters['miniArcs'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final aA = (auraColorInt >> 24) & 0xFF;
    final aR = (auraColorInt >> 16) & 0xFF;
    final aG = (auraColorInt >> 8) & 0xFF;
    final aB = auraColorInt & 0xFF;

    // Detect subject bounding box & top/bottom contour
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    final topRowPerCol = List<int>.filled(width, -1);
    final bottomRowPerCol = List<int>.filled(width, -1);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = pixels[y * width + x];
        if (((pixel >> 24) & 0xFF) > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;

          if (topRowPerCol[x] == -1 || y < topRowPerCol[x]) {
            topRowPerCol[x] = y;
          }
          if (bottomRowPerCol[x] == -1 || y > bottomRowPerCol[x]) {
            bottomRowPerCol[x] = y;
          }
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      minX = 0;
      minY = 0;
      maxX = width - 1;
      maxY = height - 1;
    }

    final boxW = (maxX - minX + 1).toDouble();
    final boxH = (maxY - minY + 1).toDouble();
    final cycleTime = time - time.floorToDouble();

    void blendPixel(
      int px,
      int py,
      int colorR,
      int colorG,
      int colorB,
      double alphaFrac, {
      bool isAdditive = false,
    }) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final effAlpha = alphaFrac.clamp(0.0, 1.0);
      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      int newR, newG, newB;
      if (isAdditive) {
        newR = (oR + colorR * effAlpha).round().clamp(0, 255);
        newG = (oG + colorG * effAlpha).round().clamp(0, 255);
        newB = (oB + colorB * effAlpha).round().clamp(0, 255);
      } else {
        newR = (oR * (1.0 - effAlpha) + colorR * effAlpha).round().clamp(0, 255);
        newG = (oG * (1.0 - effAlpha) + colorG * effAlpha).round().clamp(0, 255);
        newB = (oB * (1.0 - effAlpha) + colorB * effAlpha).round().clamp(0, 255);
      }

      final targetA = (effAlpha * aA).round();
      final newA = preserveAlpha ? origA : math.max(origA, targetA);

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    // 1. Core supercharge internal illumination
    if (coreLuminance > 0.01) {
      final pulse = 0.75 + 0.25 * math.sin(cycleTime * math.pi * 2.0 * riseSpeed * 1.5);
      final lumFactor = coreLuminance * pulse;

      for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {
          final idx = y * width + x;
          final origPixel = pixels[idx];
          if (((origPixel >> 24) & 0xFF) > 10) {
            blendPixel(x, y, aR, aG, aB, lumFactor * 0.45, isAdditive: true);
            // Incandescent highlight center
            final centerDist = ((x - (minX + boxW / 2.0)).abs() + (y - (minY + boxH / 2.0)).abs()) / (boxW + boxH);
            if (centerDist < 0.25) {
              blendPixel(x, y, 255, 255, 255, lumFactor * 0.35, isAdditive: true);
            }
          }
        }
      }
    }

    // 2. Rising jagged flame spikes shooting upward from silhouette
    final maxSpikeH = boxH * 0.55 * spikiness;

    for (int x = minX; x <= maxX; x++) {
      final topY = topRowPerCol[x];
      if (topY == -1) continue;

      // Complex multi-harmonic flame heights
      final wave1 = math.sin((x * 0.4) - (cycleTime * 35.0 * riseSpeed));
      final wave2 = math.cos((x * 0.9) - (cycleTime * 55.0 * riseSpeed));
      final waveCombined = (wave1 * 0.65 + wave2 * 0.35).abs();

      final currentSpikeH = (maxSpikeH * waveCombined).round();

      for (int h = 1; h <= currentSpikeH; h++) {
        final flameY = topY - h;
        if (flameY < 0) break;

        final tNorm = h / (currentSpikeH + 0.001); // 0.0 at base, 1.0 at tip
        final flameAlpha = (1.0 - tNorm * tNorm) * 0.85;

        // Base of flame is incandescent white/yellow, tip is colored
        if (tNorm < 0.35) {
          blendPixel(x, flameY, 255, 255, 255, flameAlpha, isAdditive: true);
        } else {
          blendPixel(x, flameY, aR, aG, aB, flameAlpha, isAdditive: true);
        }

        // Lateral flame spread
        if (tNorm < 0.5) {
          blendPixel(x - 1, flameY, aR, aG, aB, flameAlpha * 0.5, isAdditive: true);
          blendPixel(x + 1, flameY, aR, aG, aB, flameAlpha * 0.5, isAdditive: true);
        }
      }
    }

    // 3. Crackling static electricity arcs
    if (miniArcs) {
      const arcCount = 4;
      for (int a = 0; a < arcCount; a++) {
        // High-frequency temporal flicker for lightning snap
        final arcPhase = (cycleTime * 12.0 + a * 3.7);
        final arcStep = arcPhase.floor();
        final arcFrac = arcPhase - arcStep;

        // Only flash arcs on certain frames for rapid crackle
        if (arcFrac < 0.35) {
          final arcSeedX = minX + (0.1 + 0.8 * math.sin(arcStep * 23.3 + a).abs()) * boxW;
          final arcSeedY = minY + (0.1 + 0.7 * math.cos(arcStep * 31.7 + a).abs()) * boxH;

          double curX = arcSeedX;
          double curY = arcSeedY;
          final arcSegments = 3 + (a % 3);

          for (int seg = 0; seg < arcSegments; seg++) {
            final nextX = curX + (math.sin(seg * 13.1 + arcStep) * 4.0);
            final nextY = curY - (3.0 + math.cos(seg * 17.3 + a).abs() * 3.0);

            // Draw line segment
            final x0 = curX.round();
            final y0 = curY.round();
            final x1 = nextX.round();
            final y1 = nextY.round();

            blendPixel(x0, y0, 255, 255, 255, 0.9, isAdditive: true);
            blendPixel((x0 + x1) ~/ 2, (y0 + y1) ~/ 2, 255, 255, 255, 0.95, isAdditive: true);
            blendPixel(x1, y1, aR, aG, aB, 0.8, isAdditive: true);

            curX = nextX;
            curY = nextY;
          }
        }
      }
    }

    return output;
  }
}
