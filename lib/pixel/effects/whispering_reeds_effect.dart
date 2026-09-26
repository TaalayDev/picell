part of 'effects.dart';

/// An effect that procedurally renders serene shoreline reeds, cattails, or bamboo
/// gently swaying under wind gusts, paired with expanding concentric water ripples,
/// specular reflection shimmers, and tranquil pond water clarity.
class WhisperingReedsEffect extends Effect {
  WhisperingReedsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.whisperingReeds,
          params ??
              {
                'reedDensity': 14,
                'windGustSpeed': 1.8,
                'rippleFrequency': 5,
                'reflectionShimmer': 0.5,
                'waterClarity': 0.6,
                'reedStyle': 'cattails',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'reedDensity': 14,
        'windGustSpeed': 1.8,
        'rippleFrequency': 5,
        'reflectionShimmer': 0.5,
        'waterClarity': 0.6,
        'reedStyle': 'cattails',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'reedDensity': {
          'label': 'Reed Density',
          'description': 'Number of shoreline reed stalks in the vegetation clusters.',
          'type': 'slider',
          'min': 5,
          'max': 30,
          'step': 1,
        },
        'windGustSpeed': {
          'label': 'Wind Gust Speed',
          'description': 'Oscillation frequency of the swaying stalks.',
          'type': 'slider',
          'min': 0.5,
          'max': 4.0,
          'step': 0.1,
        },
        'rippleFrequency': {
          'label': 'Pond Ripples',
          'description': 'Count of active expanding concentric droplet ripple centers.',
          'type': 'slider',
          'min': 2,
          'max': 10,
          'step': 1,
        },
        'reflectionShimmer': {
          'label': 'Reflection Shimmer',
          'description': 'Luster of specular sky reflections and water highlights.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'waterClarity': {
          'label': 'Water Clarity',
          'description': 'Pond transparency and bottom depth gradient visibility.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'reedStyle': {
          'label': 'Vegetation Type',
          'description': 'Botanical morphology of shoreline plants.',
          'type': 'select',
          'options': {
            'cattails': 'Marsh Cattails',
            'bambooReeds': 'Zen Bamboo Reeds',
            'marshGrass': 'Whispering Grass',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Progress cycle (0.0 to 1.0) driving wind and ripples.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine water ripples and reeds within sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'reedDensity',
          label: 'Reed Density',
          description: 'Number of shoreline reed stalks in the vegetation clusters.',
          min: 5,
          max: 30,
          divisions: 25,
          isInteger: true,
        ),
        SliderField(
          key: 'windGustSpeed',
          label: 'Wind Gust Speed',
          description: 'Oscillation frequency of the swaying stalks.',
          min: 0.5,
          max: 4.0,
          divisions: 35,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const SliderField(
          key: 'rippleFrequency',
          label: 'Pond Ripples',
          description: 'Count of active expanding concentric droplet ripple centers.',
          min: 2,
          max: 10,
          divisions: 8,
          isInteger: true,
        ),
        SliderField(
          key: 'reflectionShimmer',
          label: 'Reflection Shimmer',
          description: 'Luster of specular sky reflections and water highlights.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'waterClarity',
          label: 'Water Clarity',
          description: 'Pond transparency and bottom depth gradient visibility.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).toInt()}%',
        ),
        const SelectField(
          key: 'reedStyle',
          label: 'Vegetation Type',
          description: 'Botanical morphology of shoreline plants.',
          options: {
            'cattails': 'Marsh Cattails',
            'bambooReeds': 'Zen Bamboo Reeds',
            'marshGrass': 'Whispering Grass',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Progress cycle (0.0 to 1.0) driving wind and ripples.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine water ripples and reeds within sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final reedDensity = ((parameters['reedDensity'] as num?)?.toInt() ?? 14).clamp(4, 40);
    final windGustSpeed = (parameters['windGustSpeed'] as num?)?.toDouble() ?? 1.8;
    final rippleFrequency = ((parameters['rippleFrequency'] as num?)?.toInt() ?? 5).clamp(1, 12);
    final reflectionShimmer = ((parameters['reflectionShimmer'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final waterClarity = ((parameters['waterClarity'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    final reedStyle = (parameters['reedStyle'] as String?) ?? 'cattails';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final shorelineY = (height * 0.32).toInt();

    // 1. Render Pond Water Surface & Concentric Expanding Ripples
    for (int y = 0; y < height; y++) {
      final isWater = y >= shorelineY;
      final yNorm = y / height.toDouble();

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        if (!isWater) {
          // Shoreline horizon / distant misty sky
          final skyR = (24 + (1.0 - yNorm) * 20).toInt().clamp(0, 255);
          final skyG = (48 + (1.0 - yNorm) * 28).toInt().clamp(0, 255);
          final skyB = (56 + (1.0 - yNorm) * 36).toInt().clamp(0, 255);
          out[idx] = 0xFF000000 | (skyR << 16) | (skyG << 8) | skyB;
          continue;
        }

        // Base pond water depth gradient
        final depthNorm = (y - shorelineY) / (height - shorelineY).toDouble();
        final waterR = (10 + (1.0 - depthNorm) * 12 * waterClarity).toInt().clamp(0, 255);
        final waterG = (32 + (1.0 - depthNorm) * 24 * waterClarity).toInt().clamp(0, 255);
        final waterB = (44 + (1.0 - depthNorm) * 28 * waterClarity).toInt().clamp(0, 255);
        int baseWater = 0xFF000000 | (waterR << 16) | (waterG << 8) | waterB;

        // Cumulative concentric ripples
        double totalWave = 0.0;
        for (int r = 0; r < rippleFrequency; r++) {
          final seed = r * 61 + 17;
          final rx = (seed % (width - 4)) + 2.0;
          final ry = shorelineY + ((seed * 13) % (height - shorelineY - 4)) + 2.0;

          final phase = (seed % 100) / 100.0;
          final rippleProgress = (time + phase) % 1.0;

          final dx = x - rx;
          final dy = (y - ry) * 1.6; // Perspective squashed ellipses
          final dist = math.sqrt(dx * dx + dy * dy);

          final maxRadius = width * 0.42;
          final currentRadius = rippleProgress * maxRadius;

          final distDiff = (dist - currentRadius).abs();
          if (distDiff < 4.0 && dist > 1.0) {
            // Wave ring profile
            final waveFade = math.exp(-dist * 0.06) * (1.0 - rippleProgress);
            final ring = math.cos(distDiff * math.pi * 0.5) * waveFade;
            totalWave += ring;
          }
        }

        // Apply wave displacement to specular reflections
        if (totalWave.abs() > 0.06) {
          final waveClamped = totalWave.clamp(-1.0, 1.0);
          if (waveClamped > 0.25) {
            // Sun/sky reflection shimmer crest
            final shimmerAlpha = (waveClamped * reflectionShimmer * 230).toInt().clamp(0, 255);
            baseWater = _additiveBlend(baseWater, 0xFF7AE7F2, shimmerAlpha);
          } else if (waveClamped < -0.2) {
            // Trough shadow
            final shadowFactor = (1.0 - (-waveClamped * 0.4)).clamp(0.5, 1.0);
            baseWater = _multiplyColor(baseWater, shadowFactor);
          }
        }

        out[idx] = baseWater;
      }
    }

    // 2. Render Whispering Swaying Reeds / Cattails / Bamboo
    final reedPositions = _generateReedClusters(reedDensity, width, height, shorelineY);

    for (final reed in reedPositions) {
      final rootX = reed.x;
      final rootY = reed.rootY;
      final stalkHeight = reed.height;
      final seed = reed.seed;

      // Stalk curvature bending under wind gusts
      final gustPhase = (time * 2.0 * math.pi * windGustSpeed) + (seed * 0.4);
      final gustAmount = math.sin(gustPhase) + (math.sin(gustPhase * 2.3) * 0.35);

      // Render stalk from root upward to tip
      for (int h = 0; h < stalkHeight; h++) {
        final normH = h / stalkHeight.toDouble();
        final currentY = rootY - h;
        if (currentY < 0 || currentY >= height) continue;

        // Quadratic bending deflection: tip bends significantly more than base
        final bendOffset = (gustAmount * normH * normH * 7.5).round();
        final currentX = rootX + bendOffset;
        if (currentX < 0 || currentX >= width) continue;

        final idx = currentY * width + currentX;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        // Color based on morphology
        int stalkColor;
        switch (reedStyle) {
          case 'cattails':
            if (normH > 0.65 && normH < 0.90) {
              // Cylindrical brown velvet seed head
              stalkColor = 0xFF5C3317; // Rich cattail brown
              // Widen the cattail head horizontally
              final headLeft = currentX - 1;
              final headRight = currentX + 1;
              if (headLeft >= 0 && (!preserveAlpha || (pixels[currentY * width + headLeft] >>> 24) != 0)) {
                out[currentY * width + headLeft] = 0xFF42240F; // Shadow edge
              }
              if (headRight < width && (!preserveAlpha || (pixels[currentY * width + headRight] >>> 24) != 0)) {
                out[currentY * width + headRight] = 0xFF734320; // Highlight edge
              }
            } else if (normH >= 0.90) {
              stalkColor = 0xFF8A9A4A; // Pale tip spike
            } else {
              stalkColor = (seed % 2 == 0) ? 0xFF356E24 : 0xFF43852E; // Green reed stem
            }
            break;

          case 'bambooReeds':
            final isNode = (h % 5 == 0);
            if (isNode) {
              stalkColor = 0xFF2D471C; // Dark bamboo ring node
              // Angled blade leaves branching out at nodes
              if (normH > 0.3) {
                final leafSide = (seed + h) % 2 == 0 ? 1 : -1;
                final leafX = currentX + leafSide;
                if (leafX >= 0 && leafX < width) {
                  final leafIdx = currentY * width + leafX;
                  if (!preserveAlpha || (pixels[leafIdx] >>> 24) != 0) {
                    out[leafIdx] = 0xFF529C2D;
                  }
                }
              }
            } else {
              stalkColor = (seed % 2 == 0) ? 0xFF6AA83B : 0xFF7CB848; // Golden green bamboo
            }
            break;

          case 'marshGrass':
          default:
            final taperFactor = 1.0 - normH * 0.4;
            final g = (100 + (taperFactor * 40)).toInt().clamp(0, 255);
            stalkColor = 0xFF000000 | (45 << 16) | (g << 8) | 28;
            break;
        }

        out[idx] = stalkColor;

        // Render subtle water reflection under root line
        if (normH < 0.25) {
          final reflectY = rootY + (h * 0.75).round();
          if (reflectY < height && reflectY >= shorelineY) {
            final reflectX = rootX - (bendOffset * 0.5).round();
            if (reflectX >= 0 && reflectX < width) {
              final refIdx = reflectY * width + reflectX;
              if (!preserveAlpha || (pixels[refIdx] >>> 24) != 0) {
                out[refIdx] = _alphaBlend(out[refIdx], stalkColor, 90);
              }
            }
          }
        }
      }
    }

    return out;
  }

  // -----------------------------
  // Reed Distribution & Placement
  // -----------------------------

  List<_ReedSpec> _generateReedClusters(int count, int width, int height, int shorelineY) {
    final list = <_ReedSpec>[];

    for (int i = 0; i < count; i++) {
      final seed = i * 43 + 7;

      // Group reeds into two natural shoreline banks (left 35% and right 35%)
      int rx;
      if (i % 2 == 0) {
        // Left shore cluster
        rx = (seed % ((width * 0.35).toInt() + 1));
      } else {
        // Right shore cluster
        rx = ((width * 0.65).toInt() + (seed % ((width * 0.35).toInt() + 1))).clamp(0, width - 1);
      }

      // Rooting depth along shore
      final rootY = shorelineY + (seed % ((height - shorelineY) * 0.55).toInt());
      final h = ((height * 0.35) + ((seed % 100) / 100.0) * (height * 0.32)).toInt();

      list.add(_ReedSpec(x: rx, rootY: rootY, height: h, seed: seed));
    }

    // Sort by rootY so deeper reeds draw in front of back reeds
    list.sort((a, b) => a.rootY.compareTo(b.rootY));
    return list;
  }

  // -----------------------------
  // Color Blending Helpers
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

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }

  int _multiplyColor(int color, double factor) {
    final a = (color >>> 24) & 0xFF;
    final r = (((color >>> 16) & 0xFF) * factor).toInt().clamp(0, 255);
    final g = (((color >>> 8) & 0xFF) * factor).toInt().clamp(0, 255);
    final b = ((color & 0xFF) * factor).toInt().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  int _alphaBlend(int base, int overlay, int alpha) {
    final a = alpha.clamp(0, 255);
    if (a == 0) return base;
    if (a == 255) return overlay;

    final inv = 255 - a;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final oR = (overlay >>> 16) & 0xFF;
    final oG = (overlay >>> 8) & 0xFF;
    final oB = overlay & 0xFF;

    final r = ((bR * inv) + (oR * a)) ~/ 255;
    final g = ((bG * inv) + (oG * a)) ~/ 255;
    final b = ((bB * inv) + (oB * a)) ~/ 255;

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }
}

class _ReedSpec {
  final int x;
  final int rootY;
  final int height;
  final int seed;

  const _ReedSpec({
    required this.x,
    required this.rootY,
    required this.height,
    required this.seed,
  });
}
