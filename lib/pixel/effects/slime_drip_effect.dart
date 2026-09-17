part of 'effects.dart';

/// Procedural acid, slime, and fluid drip effect with swelling droplet heads,
/// viscous tapering necks, gravity acceleration, and ground impact splatters.
class SlimeDripEffect extends Effect implements UIFieldProvider {
  SlimeDripEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.slimeDrip,
          parameters ??
              const {
                'dripFrequency': 2,
                'viscosity': 0.6,
                'liquidColor': 0xFF76FF03,
                'splashSize': 2,
                'gravity': 1.5,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'dripFrequency': 2,
        'viscosity': 0.6,
        'liquidColor': 0xFF76FF03,
        'splashSize': 2,
        'gravity': 1.5,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'dripFrequency': {
          'label': 'Drip Streams',
          'description': 'Number of active fluid drip nozzles across the sprite bottom.',
          'type': 'slider',
          'min': 1,
          'max': 4,
          'divisions': 3,
        },
        'viscosity': {
          'label': 'Fluid Viscosity',
          'description': 'Resistance to detachment and stretch length of the liquid neck.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'divisions': 16,
        },
        'liquidColor': {
          'label': 'Fluid Ooze Color',
          'description': 'Color of the dripping viscous fluid and impact splatters.',
          'type': 'color',
        },
        'splashSize': {
          'label': 'Impact Splatter Size',
          'description': 'Radius of the ground pool and lateral droplet splash.',
          'type': 'slider',
          'min': 1,
          'max': 4,
          'divisions': 3,
        },
        'gravity': {
          'label': 'Drop Gravity Acceleration',
          'description': 'Downward acceleration of the falling detached droplet.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.5,
          'divisions': 20,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for the complete drip cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Keep background canvas transparent around the dripping fluid.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'dripFrequency',
          label: 'Drip Streams',
          description: 'Number of dripping droplet streams.',
          min: 1,
          max: 4,
          divisions: 3,
          formatLabel: (v) => '${v.round()} streams',
        ),
        SliderField(
          key: 'viscosity',
          label: 'Fluid Viscosity',
          description: 'Stretch length and thickness of the liquid neck.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const ColorField(
          key: 'liquidColor',
          label: 'Liquid Color',
          description: 'Color of the acid, blood, or slime ooze.',
        ),
        SliderField(
          key: 'splashSize',
          label: 'Splatter Pool Size',
          description: 'Radius of the floor splatter pool and splash bursts.',
          min: 1,
          max: 4,
          divisions: 3,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'gravity',
          label: 'Gravity Velocity',
          description: 'Fall acceleration speed of detached droplets.',
          min: 0.5,
          max: 2.5,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}g',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during animation generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Allows droplets to fall cleanly over transparent backgrounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final dripFrequency = ((parameters['dripFrequency'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final viscosity = ((parameters['viscosity'] as num?)?.toDouble() ?? 0.6).clamp(0.2, 1.0);
    final liquidColorInt = (parameters['liquidColor'] as int?) ?? 0xFF76FF03;
    final splashSize = ((parameters['splashSize'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final gravity = ((parameters['gravity'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 2.5);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final liqR = (liquidColorInt >> 16) & 0xFF;
    final liqG = (liquidColorInt >> 8) & 0xFF;
    final liqB = liquidColorInt & 0xFF;

    final result = Uint32List(width * height);
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      const darkDungeon = 0xFF0D120B;
      const bgR = (darkDungeon >> 16) & 0xFF;
      const bgG = (darkDungeon >> 8) & 0xFF;
      const bgB = darkDungeon & 0xFF;
      result.fillRange(0, result.length, darkDungeon);
      for (int i = 0; i < pixels.length; i++) {
        final p = pixels[i];
        final a = (p >> 24) & 0xFF;
        if (a > 0) {
          final na = a / 255.0;
          final pr = (p >> 16) & 0xFF;
          final pg = (p >> 8) & 0xFF;
          final pb = p & 0xFF;
          final outR = (pr * na + bgR * (1.0 - na)).round().clamp(0, 255);
          final outG = (pg * na + bgG * (1.0 - na)).round().clamp(0, 255);
          final outB = (pb * na + bgB * (1.0 - na)).round().clamp(0, 255);
          result[i] = 0xFF000000 | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    void plotLiquid(int px, int py, int r, int g, int b, int alpha) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;

      final existing = result[idx];
      final exA = (existing >> 24) & 0xFF;
      final exR = (existing >> 16) & 0xFF;
      final exG = (existing >> 8) & 0xFF;
      final exB = existing & 0xFF;

      final na = alpha / 255.0;
      final outR = (exR * (1.0 - na) + r * na).round().clamp(0, 255);
      final outG = (exG * (1.0 - na) + g * na).round().clamp(0, 255);
      final outB = (exB * (1.0 - na) + b * na).round().clamp(0, 255);
      final outA = math.max(exA, alpha);

      result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    // 1. Locate Bottom-Most Sprite Protrusions for Drip Spawn Anchors
    final bottomCols = <int, int>{};
    for (int x = 0; x < width; x++) {
      for (int y = height - 1; y >= 0; y--) {
        if ((pixels[y * width + x] >> 24) & 0xFF > 30) {
          bottomCols[x] = y;
          break;
        }
      }
    }

    final spawnPoints = <math.Point<int>>[];
    if (bottomCols.isNotEmpty) {
      final colList = bottomCols.keys.toList()..sort();
      final step = math.max(1, colList.length ~/ dripFrequency);
      for (int i = 0; i < dripFrequency; i++) {
        final colIdx = math.min(colList.length - 1, (i * step) + (step ~/ 2));
        final x = colList[colIdx];
        final y = bottomCols[x]!;
        spawnPoints.add(math.Point(x, y));
      }
    } else {
      // Fallback: spawn evenly along top of canvas
      final step = width / (dripFrequency + 1);
      for (int i = 1; i <= dripFrequency; i++) {
        spawnPoints.add(math.Point((i * step).round(), 1));
      }
    }

    // 2. Animate Viscous Droplet Cycle for Each Stream
    final maxStretch = (viscosity * (height * 0.28)).clamp(2.0, 16.0);
    final floorY = height - 1;

    for (int s = 0; s < spawnPoints.length; s++) {
      final anchor = spawnPoints[s];
      final ax = anchor.x;
      final ay = anchor.y;

      // Cycle progress offset per stream
      final localT = (time + (s / spawnPoints.length)) % 1.0;

      if (localT < 0.35) {
        // Phase 1: Droplet Accumulation / Swelling
        final swell = localT / 0.35;
        plotLiquid(ax, ay + 1, liqR, liqG, liqB, 240);
        if (swell > 0.5) {
          plotLiquid(ax, ay + 2, liqR, liqG, liqB, 255);
          plotLiquid(ax - 1, ay + 1, liqR, liqG, liqB, 180);
          plotLiquid(ax + 1, ay + 1, liqR, liqG, liqB, 180);
        }
      } else if (localT < 0.60) {
        // Phase 2: Viscous Neck Stretching
        final stretchT = (localT - 0.35) / 0.25;
        final currentLen = (maxStretch * stretchT).round();

        // Draw stretched fluid thread
        for (int dy = 1; dy <= currentLen; dy++) {
          final threadAlpha = (240 - (dy / currentLen * 60)).round();
          plotLiquid(ax, ay + dy, liqR, liqG, liqB, threadAlpha);
        }

        // Hanging droplet bulb at bottom of thread
        final bulbY = ay + currentLen;
        plotLiquid(ax, bulbY, liqR, liqG, liqB, 255);
        plotLiquid(ax - 1, bulbY, liqR, liqG, liqB, 200);
        plotLiquid(ax + 1, bulbY, liqR, liqG, liqB, 200);
        plotLiquid(ax, bulbY + 1, liqR, liqG, liqB, 220);
      } else {
        // Phase 3: Detached Free-Fall & Ground Impact Splatter
        final fallT = (localT - 0.60) / 0.40;
        final startY = ay + maxStretch.round();
        final remainingDist = math.max(0, floorY - startY);
        final dropY = (startY + remainingDist * math.pow(fallT, gravity)).round();

        if (dropY < floorY - 1) {
          // In-flight falling teardrop
          plotLiquid(ax, dropY - 1, liqR, liqG, liqB, 160);
          plotLiquid(ax, dropY, 255, 255, 255, 255); // Specular gleam
          plotLiquid(ax, dropY + 1, liqR, liqG, liqB, 255);
          plotLiquid(ax - 1, dropY, liqR, liqG, liqB, 210);
          plotLiquid(ax + 1, dropY, liqR, liqG, liqB, 210);
        } else {
          // Impact Ground Splatter
          final impactProgress = ((dropY - (floorY - 1)) / 2.0).clamp(0.0, 1.0);
          final currentSplash = math.min(splashSize, (1 + impactProgress * (splashSize - 1)).round());

          // Central pool
          for (int dx = -currentSplash; dx <= currentSplash; dx++) {
            plotLiquid(ax + dx, floorY, liqR, liqG, liqB, 230);
          }
          if (floorY > 0) {
            for (int dx = -(currentSplash - 1); dx <= currentSplash - 1; dx++) {
              plotLiquid(ax + dx, floorY - 1, liqR, liqG, liqB, 180);
            }
          }

          // Flying splatter micro-droplets
          plotLiquid(ax - currentSplash - 1, floorY - 1, liqR, liqG, liqB, 200);
          plotLiquid(ax + currentSplash + 1, floorY - 1, liqR, liqG, liqB, 200);
          if (floorY > 2) {
            plotLiquid(ax - currentSplash, floorY - 2, liqR, liqG, liqB, 140);
            plotLiquid(ax + currentSplash, floorY - 2, liqR, liqG, liqB, 140);
          }
        }
      }
    }

    return result;
  }
}
