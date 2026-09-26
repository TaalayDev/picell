part of 'effects.dart';

/// An effect that procedurally renders vertical multi-stream waterfall cascades
/// plunging over rock tiers with fluid acceleration physics, white foaming impact
/// shelves, ballistic spray droplet particles, and rising plunge pool mist billows.
class WaterfallCascadeEffect extends Effect {
  WaterfallCascadeEffect([Map<String, dynamic>? params])
      : super(
          EffectType.waterfallCascade,
          params ??
              {
                'flowSpeed': 2.0,
                'cascadeWidth': 0.6,
                'foamTurbulence': 0.5,
                'sprayDroplets': 30,
                'mistRisingDensity': 0.4,
                'rockTiers': 2,
                'waterPalette': 'mountainGlacier',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'flowSpeed': 2.0,
        'cascadeWidth': 0.6,
        'foamTurbulence': 0.5,
        'sprayDroplets': 30,
        'mistRisingDensity': 0.4,
        'rockTiers': 2,
        'waterPalette': 'mountainGlacier',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'flowSpeed': {
          'label': 'Flow Speed',
          'description': 'Downward acceleration and fluid torrent velocity.',
          'type': 'slider',
          'min': 0.5,
          'max': 5.0,
          'step': 0.1,
        },
        'cascadeWidth': {
          'label': 'Cascade Width',
          'description': 'Fraction of canvas width occupied by the water torrent.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'foamTurbulence': {
          'label': 'Foam Froth',
          'description': 'Turbulence and density of white water froth and collision crests.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'sprayDroplets': {
          'label': 'Spray Droplets',
          'description': 'Count of bouncing ballistic spray particles.',
          'type': 'slider',
          'min': 10,
          'max': 80,
          'step': 1,
        },
        'mistRisingDensity': {
          'label': 'Plunge Mist',
          'description': 'Density of soft rising vapor billows from impact basins.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'rockTiers': {
          'label': 'Rock Tiers',
          'description': 'Number of intermediate rock shelves breaking the fall.',
          'type': 'slider',
          'min': 1,
          'max': 4,
          'step': 1,
        },
        'waterPalette': {
          'label': 'Water Palette',
          'description': 'Atmospheric biome color grading.',
          'type': 'select',
          'options': {
            'mountainGlacier': 'Glacial Alpine',
            'tropicalLagoon': 'Tropical Lagoon',
            'muddyCanyon': 'Canyon Sediment',
            'mysticArcane': 'Mystic Arcane',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Progress cycle (0.0 to 1.0) driving flow and particles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict waterfall and spray to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'flowSpeed',
          label: 'Flow Speed',
          description: 'Downward acceleration and fluid torrent velocity.',
          min: 0.5,
          max: 5.0,
          divisions: 45,
          formatLabel: (v) => v.toStringAsFixed(1),
        ),
        SliderField(
          key: 'cascadeWidth',
          label: 'Cascade Width',
          description: 'Fraction of canvas width occupied by the water torrent.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).toInt()}%',
        ),
        SliderField(
          key: 'foamTurbulence',
          label: 'Foam Froth',
          description: 'Turbulence and density of white water froth and collision crests.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SliderField(
          key: 'sprayDroplets',
          label: 'Spray Droplets',
          description: 'Count of bouncing ballistic spray particles.',
          min: 10,
          max: 80,
          divisions: 70,
          isInteger: true,
        ),
        SliderField(
          key: 'mistRisingDensity',
          label: 'Plunge Mist',
          description: 'Density of soft rising vapor billows from impact basins.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SliderField(
          key: 'rockTiers',
          label: 'Rock Tiers',
          description: 'Number of intermediate rock shelves breaking the fall.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
        ),
        const SelectField(
          key: 'waterPalette',
          label: 'Water Palette',
          description: 'Atmospheric biome color grading.',
          options: {
            'mountainGlacier': 'Glacial Alpine',
            'tropicalLagoon': 'Tropical Lagoon',
            'muddyCanyon': 'Canyon Sediment',
            'mysticArcane': 'Mystic Arcane',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Progress cycle (0.0 to 1.0) driving flow and particles.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict waterfall and spray to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final flowSpeed = (parameters['flowSpeed'] as num?)?.toDouble() ?? 2.0;
    final cascadeWidth = ((parameters['cascadeWidth'] as num?)?.toDouble() ?? 0.6).clamp(0.2, 1.0);
    final foamTurbulence = ((parameters['foamTurbulence'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final sprayDroplets = ((parameters['sprayDroplets'] as num?)?.toInt() ?? 30).clamp(5, 120);
    final mistRisingDensity = ((parameters['mistRisingDensity'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final rockTiers = ((parameters['rockTiers'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final waterPalette = (parameters['waterPalette'] as String?) ?? 'mountainGlacier';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final palette = _getWaterfallPalette(waterPalette);

    final cWidth = width * cascadeWidth;
    final leftX = (width - cWidth) / 2.0;
    final rightX = leftX + cWidth;

    // Calculate rock tier Y positions
    final tierYs = <int>[];
    for (int t = 1; t <= rockTiers; t++) {
      tierYs.add(((t / (rockTiers + 1.2)) * height).toInt());
    }

    final basinY = (height * 0.82).toInt();

    // 1. Render Cliff Background & Water Streams
    for (int y = 0; y < height; y++) {
      final yNorm = y / height;
      final isBasin = y >= basinY;

      // Downward velocity acceleration with gravity
      final streamYOffset = (time * flowSpeed * 36.0) + (yNorm * yNorm * 18.0 * flowSpeed);

      // Check if this row is near a rock shelf tier
      bool isShelfRow = false;
      bool isShelfCrest = false;
      for (final ty in tierYs) {
        if (y == ty) {
          isShelfRow = true;
          break;
        } else if (y == ty + 1 || y == ty + 2) {
          isShelfCrest = true;
          break;
        }
      }

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        // Distance from waterfall center
        final distFromLeft = x - leftX;
        final distFromRight = rightX - x;
        final inWaterColumn = distFromLeft >= 0 && distFromRight >= 0;

        int finalColor;

        if (isBasin) {
          // Bottom plunge pool / river basin
          final wavePhase = math.sin((x * 0.25) + (time * 2.0 * math.pi) + (y * 0.4));
          final basinNoise = _noise2D(x * 0.2, (y * 0.3) - (time * 1.5), 101);
          final frothing = (basinNoise + wavePhase * 0.4).clamp(-1.0, 1.0);

          if (inWaterColumn && (y <= basinY + 2 || frothing > 0.35 - (foamTurbulence * 0.25))) {
            // Impact crash foam
            finalColor = palette.foamCrest;
          } else if (frothing > 0.1) {
            finalColor = palette.lightWater;
          } else {
            finalColor = palette.deepWater;
          }
        } else if (isShelfRow && inWaterColumn) {
          // Wet rock ledge under waterfall
          final shelfNoise = _noise2D(x * 0.4, y * 0.2, 53);
          finalColor = shelfNoise > 0.1 ? palette.wetRock : palette.darkRock;
        } else if (isShelfCrest && inWaterColumn) {
          // Foaming water shelf crest
          final foamNoise = _noise2D(x * 0.6, (y * 0.5) - (time * 3.0), 79);
          finalColor = foamNoise > -0.2 ? palette.foamCrest : palette.lightWater;
        } else if (inWaterColumn) {
          // Falling torrent streams
          final edgeFactor = math.min(distFromLeft, distFromRight) / (cWidth * 0.2);
          final edgeClamped = edgeFactor.clamp(0.0, 1.0);

          // Fast vertical noise representing multi-stream fluid filaments
          final streamNoise1 = _noise2D((x * 0.5), (y * 0.15) - streamYOffset, 31);
          final streamNoise2 = _noise2D((x * 0.8) + 17.0, (y * 0.35) - (streamYOffset * 1.4), 97);
          final turbulenceVal = (streamNoise1 * 0.6 + streamNoise2 * 0.4) * (1.0 + foamTurbulence * 0.5);

          if (turbulenceVal > 0.45) {
            // Aerated white froth stream
            finalColor = palette.foamCrest;
          } else if (turbulenceVal > 0.0) {
            // Mid-tier clear flowing water
            finalColor = palette.lightWater;
          } else {
            // Deep volume torrent core
            finalColor = palette.deepWater;
          }

          // Edge spray tapering
          if (edgeClamped < 0.3) {
            final edgeNoise = _noise2D(x * 0.8, y * 0.3, 113);
            if (edgeNoise < -0.1) {
              finalColor = palette.darkRock;
            }
          }
        } else {
          // Surrounding cliff walls
          final cliffNoise = _noise2D(x * 0.15, y * 0.12, 17);
          final strata = math.sin((y * 0.4) + cliffNoise * 3.0);
          final mossNoise = _noise2D(x * 0.22, y * 0.22, 223);

          if (mossNoise > 0.4) {
            finalColor = palette.mossFoliage;
          } else if (strata > 0.3) {
            finalColor = palette.wetRock;
          } else {
            finalColor = palette.darkRock;
          }
        }

        // Apply rising mist billow overlay
        if (mistRisingDensity > 0.05) {
          final mistY = (height - y) / height.toDouble();
          final mistCurling = math.sin((y * 0.1) + (time * 2.0 * math.pi) + (x * 0.12));
          final mistNoise = _noise2D((x * 0.1) + mistCurling, (y * 0.08) + (time * 2.5), 337);

          if (mistNoise > 0.0) {
            final mistAlpha = (mistNoise * mistRisingDensity * math.pow(mistY, 0.75) * 220).toInt().clamp(0, 180);
            if (mistAlpha > 15) {
              finalColor = _alphaBlend(finalColor, palette.mistColor, mistAlpha);
            }
          }
        }

        out[idx] = finalColor;
      }
    }

    // 2. Render Ballistic Spray Droplets
    for (int i = 0; i < sprayDroplets; i++) {
      final seed = i * 47 + 13;
      final tierIndex = i % (rockTiers + 1);

      double originY;
      if (tierIndex < rockTiers) {
        originY = tierYs[tierIndex].toDouble() + 1.0;
      } else {
        originY = basinY.toDouble();
      }

      // Origin X across waterfall width
      final normX = ((seed % 100) / 100.0);
      final originX = leftX + (cWidth * normX);

      // Trajectory kinematics
      final angle = (((seed % 60) - 30) * math.pi / 180.0) - (math.pi / 2.0); // Upward cone
      final speed = 3.0 + ((seed % 40) / 10.0);
      final vx = math.cos(angle) * speed;
      final vy0 = math.sin(angle) * speed;

      final phaseOffset = (seed % 1000) / 1000.0;
      final tau = (time + phaseOffset) % 1.0;

      final dropX = (originX + vx * tau * 8.0).round();
      final dropY = (originY + vy0 * tau * 7.0 + 0.5 * 9.8 * tau * tau * 4.0).round();

      if (dropX >= 0 && dropX < width && dropY >= 0 && dropY < height) {
        final dropIdx = dropY * width + dropX;
        if (!preserveAlpha || (pixels[dropIdx] >>> 24) != 0) {
          final dropAlpha = ((1.0 - tau) * 255).toInt().clamp(0, 255);
          out[dropIdx] = _alphaBlend(out[dropIdx], palette.foamCrest, dropAlpha);
        }
      }
    }

    return out;
  }

  // -----------------------------
  // Waterfall Color Grading
  // -----------------------------

  _WaterfallPalette _getWaterfallPalette(String key) {
    switch (key) {
      case 'tropicalLagoon':
        return const _WaterfallPalette(
          deepWater: 0xFF0B4D3C, // Deep emerald
          lightWater: 0xFF1ED6A4, // Bright turquoise
          foamCrest: 0xFFE0FFF4, // Seafoam white
          darkRock: 0xFF1E2818, // Dense jungle cliff
          wetRock: 0xFF2F3E26, // Wet mossy slate
          mossFoliage: 0xFF3E7324, // Vivid jungle moss
          mistColor: 0xFFD8F7EE, // Lagoon mist
        );
      case 'muddyCanyon':
        return const _WaterfallPalette(
          deepWater: 0xFF4D2B12, // Sediment brown
          lightWater: 0xFFA6682E, // Ochre torrent
          foamCrest: 0xFFFFEBD6, // Sandstone tan froth
          darkRock: 0xFF3D1D12, // Red rock canyon
          wetRock: 0xFF5C291A, // Wet sandstone
          mossFoliage: 0xFF6E5629, // Dry canyon shrub
          mistColor: 0xFFF2E2D0, // Warm canyon dust mist
        );
      case 'mysticArcane':
        return const _WaterfallPalette(
          deepWater: 0xFF280B4D, // Abyssal violet
          lightWater: 0xFF883DF2, // Neon amethyst
          foamCrest: 0xFFF5E6FF, // Arcane lavender white
          darkRock: 0xFF120B1A, // Obsidian rock
          wetRock: 0xFF221433, // Wet arcane basalt
          mossFoliage: 0xFF2DF2DC, // Glowing cyan lichen
          mistColor: 0xFFE2C9FF, // Luminous purple haze
        );
      case 'mountainGlacier':
      default:
        return const _WaterfallPalette(
          deepWater: 0xFF003852, // Deep glacial cyan
          lightWater: 0xFF1B82AA, // Alpine azure
          foamCrest: 0xFFF0FAFF, // Sparkling glacier froth
          darkRock: 0xFF22282C, // Cold dark granite
          wetRock: 0xFF3B444B, // Wet stone ledge
          mossFoliage: 0xFF334B2E, // Mountain lichen
          mistColor: 0xFFE4F3FA, // Crisp mountain vapor
        );
    }
  }

  // -----------------------------
  // Procedural Noise & Blending
  // -----------------------------

  double _noise2D(double x, double y, int seed) {
    final xi = x.floor();
    final yi = y.floor();
    final xf = x - xi;
    final yf = y - yi;

    final u = xf * xf * (3.0 - 2.0 * xf);
    final v = yf * yf * (3.0 - 2.0 * yf);

    final g00 = _hash2D(xi, yi, seed);
    final g10 = _hash2D(xi + 1, yi, seed);
    final g01 = _hash2D(xi, yi + 1, seed);
    final g11 = _hash2D(xi + 1, yi + 1, seed);

    final x1 = g00 + (g10 - g00) * u;
    final x2 = g01 + (g11 - g01) * u;
    return x1 + (x2 - x1) * v;
  }

  double _hash2D(int x, int y, int seed) {
    int h = seed ^ (x * 374761393) ^ (y * 668265263);
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h & 0x7FFFFFFF) / 1073741824.0) - 1.0;
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

class _WaterfallPalette {
  final int deepWater;
  final int lightWater;
  final int foamCrest;
  final int darkRock;
  final int wetRock;
  final int mossFoliage;
  final int mistColor;

  const _WaterfallPalette({
    required this.deepWater,
    required this.lightWater,
    required this.foamCrest,
    required this.darkRock,
    required this.wetRock,
    required this.mossFoliage,
    required this.mistColor,
  });
}
