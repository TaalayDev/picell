part of 'effects.dart';

/// An effect that procedurally renders tangled banyan mangrove aerial roots,
/// hanging Spanish moss fronds swaying in the wind, and brackish swamp waterlines.
class BanyanMangroveEffect extends Effect {
  BanyanMangroveEffect([Map<String, dynamic>? params])
      : super(
          EffectType.banyanMangrove,
          params ??
              {
                'rootDensity': 8,
                'tangleTwist': 0.45,
                'waterlineTideMark': 0.65,
                'mossDrapeLength': 0.5,
                'barkShade': 'cypressGrey',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'rootDensity': 8,
        'tangleTwist': 0.45,
        'waterlineTideMark': 0.65,
        'mossDrapeLength': 0.5,
        'barkShade': 'cypressGrey',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'rootDensity': {
          'label': 'Aerial Root Pillars',
          'description': 'Number of vertical stilt roots descending into the swamp basin.',
          'type': 'slider',
          'min': 4,
          'max': 16,
          'step': 1,
        },
        'tangleTwist': {
          'label': 'Root Curvature & Twist',
          'description': 'Serpentine meandering and braiding of intertwining aerial roots.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'waterlineTideMark': {
          'label': 'Brackish Waterline Level',
          'description': 'Vertical depth of the swamp water surface and algae tide rings.',
          'type': 'slider',
          'min': 0.3,
          'max': 0.9,
          'step': 0.05,
        },
        'mossDrapeLength': {
          'label': 'Spanish Moss Drape',
          'description': 'Length of hanging airborne moss fronds and creeping lianas.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'barkShade': {
          'label': 'Woodland Biome',
          'description': 'Botanical bark wood and swamp water ecological palette.',
          'type': 'select',
          'options': {
            'cypressGrey': 'Southern Swamp Bald Cypress',
            'mangroveRed': 'Tropical Red Mangrove Lagoon',
            'stranglerFig': 'Ancient Banyan Strangler Fig',
            'primevalEbony': 'Primeval Blackwater Bayou',
          },
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Harmonic wind sway of hanging moss and water surface ripples.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict roots, moss, and water strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'rootDensity',
          label: 'Aerial Root Pillars',
          description: 'Number of vertical stilt roots descending into the swamp basin.',
          min: 4,
          max: 16,
          divisions: 12,
          formatLabel: (v) => '${v.round()}',
        ),
        SliderField(
          key: 'tangleTwist',
          label: 'Root Curvature & Twist',
          description: 'Serpentine meandering and braiding of intertwining aerial roots.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'waterlineTideMark',
          label: 'Brackish Waterline Level',
          description: 'Vertical depth of the swamp water surface and algae tide rings.',
          min: 0.3,
          max: 0.9,
          divisions: 12,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'mossDrapeLength',
          label: 'Spanish Moss Drape',
          description: 'Length of hanging airborne moss fronds and creeping lianas.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'barkShade',
          label: 'Woodland Biome',
          description: 'Botanical bark wood and swamp water ecological palette.',
          options: {
            'cypressGrey': 'Southern Swamp Bald Cypress',
            'mangroveRed': 'Tropical Red Mangrove Lagoon',
            'stranglerFig': 'Ancient Banyan Strangler Fig',
            'primevalEbony': 'Primeval Blackwater Bayou',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Harmonic wind sway of hanging moss and water surface ripples.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict roots, moss, and water strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final int count = ((parameters['rootDensity'] as num?)?.toInt() ?? 8).clamp(4, 16);
    final double twist = ((parameters['tangleTwist'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final double tideLevel = ((parameters['waterlineTideMark'] as num?)?.toDouble() ?? 0.65).clamp(0.3, 0.9);
    final double mossLen = ((parameters['mossDrapeLength'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final String biome = (parameters['barkShade'] as String?) ?? 'cypressGrey';
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List.fromList(pixels);

    // Biome color configurations
    final _RGB barkCol;
    final _RGB mossCol;
    final _RGB waterCol;
    final _RGB algaeCol;

    switch (biome) {
      case 'mangroveRed':
        barkCol = const _RGB(138, 55, 42); // Red Mangrove stilt wood
        mossCol = const _RGB(75, 145, 60);  // Tropical vine green
        waterCol = const _RGB(18, 72, 85);  // Turquoise lagoon
        algaeCol = const _RGB(46, 125, 50); // Emerald algae ring
        break;

      case 'stranglerFig':
        barkCol = const _RGB(115, 82, 60); // Golden banyan bark
        mossCol = const _RGB(145, 140, 45); // Sunlit lianas
        waterCol = const _RGB(35, 48, 52);  // Murky river
        algaeCol = const _RGB(85, 115, 35); // River scum green
        break;

      case 'primevalEbony':
        barkCol = const _RGB(32, 32, 35);  // Gnarled black swamp wood
        mossCol = const _RGB(175, 185, 190); // Eerie pale grey moss
        waterCol = const _RGB(12, 14, 18);  // Blackwater bayou
        algaeCol = const _RGB(45, 65, 55);  // Dark scum
        break;

      case 'cypressGrey':
      default:
        barkCol = const _RGB(105, 98, 92);  // Weathered bald cypress
        mossCol = const _RGB(155, 172, 148); // Hanging Spanish moss
        waterCol = const _RGB(25, 20, 16);  // Deep tea tannin water
        algaeCol = const _RGB(55, 95, 45);  // High tide algae mark
        break;
    }

    final double waterY = tideLevel * height;
    final double windAngle = time * 2.0 * math.pi;

    // Precalculate root anchors and trajectories
    final List<double> rootStartX = List<double>.filled(count, 0.0);
    final List<double> rootWidth = List<double>.filled(count, 0.0);
    final List<double> rootPhase = List<double>.filled(count, 0.0);

    for (int k = 0; k < count; k++) {
      final double frac = (k + 0.5) / count;
      final int h = _rootHash(k, 42);
      final double jx = ((h & 0xFF) / 255.0 - 0.5) * (0.8 / count);
      rootStartX[k] = (frac + jx).clamp(0.05, 0.95) * width;
      rootWidth[k] = math.max(1.5, width * (0.02 + (((h >> 8) & 0x7F) / 127.0) * 0.035));
      rootPhase[k] = ((h >> 16) & 0xFF) / 255.0 * 2.0 * math.pi;
    }

    // 1. Draw Aerial Root Pillars
    for (int k = 0; k < count; k++) {
      final double startX = rootStartX[k];
      final double baseW = rootWidth[k];
      final double phase = rootPhase[k];

      for (int y = 0; y < height; y++) {
        final double ny = y / math.max(1, height - 1);

        // Serpentine root wandering with horizontal braid
        final double wander = math.sin(ny * 6.0 + phase) * (width * 0.05 * twist) +
            math.sin(ny * 14.0 + phase * 2.0) * (width * 0.02 * twist);
        final double curCenterX = startX + wander;

        // Roots flare wider near the waterline / base
        final double flare = (y >= waterY) ? 1.0 + (y - waterY) / (height - waterY) * 0.8 : 1.0;
        final double curWidth = baseW * flare;

        final int minX = (curCenterX - curWidth).floor().clamp(0, width - 1);
        final int maxX = (curCenterX + curWidth).ceil().clamp(0, width - 1);

        final bool isSubmerged = y >= waterY;
        final bool isTideMark = (y - waterY).abs() <= 2.5;

        for (int x = minX; x <= maxX; x++) {
          final int idx = y * width + x;
          final int origPixel = pixels[idx];
          final int origAlpha = (origPixel >> 24) & 0xFF;

          if (preserveAlpha && origAlpha == 0) continue;

          final double dx = (x - curCenterX).abs();
          if (dx <= curWidth) {
            // Cylindrical bark shading with vertical micro-groove striae
            final double normX = dx / curWidth;
            final double cylinderShade = math.sqrt((1.0 - normX * normX).clamp(0.05, 1.0));
            final double barkGrain = (_hashGrain(x, y) - 0.5) * 15.0;

            int br;
            int bg;
            int bb;

            if (isTideMark) {
              // Meniscus algae watermark
              br = (algaeCol.r * cylinderShade + barkGrain).round().clamp(0, 255);
              bg = (algaeCol.g * cylinderShade + barkGrain).round().clamp(0, 255);
              bb = (algaeCol.b * cylinderShade + barkGrain).round().clamp(0, 255);
            } else if (isSubmerged) {
              // Submerged in dark tannin tea water
              final double depthFade = ((y - waterY) / (height - waterY)).clamp(0.0, 1.0);
              final double subShade = cylinderShade * (0.65 - depthFade * 0.3);
              br = (barkCol.r * subShade * 0.6 + waterCol.r * 0.4).round().clamp(0, 255);
              bg = (barkCol.g * subShade * 0.6 + waterCol.g * 0.4).round().clamp(0, 255);
              bb = (barkCol.b * subShade * 0.6 + waterCol.b * 0.4).round().clamp(0, 255);
            } else {
              // Aerial root exposed to humid air
              br = (barkCol.r * cylinderShade + barkGrain).round().clamp(0, 255);
              bg = (barkCol.g * cylinderShade + barkGrain).round().clamp(0, 255);
              bb = (barkCol.b * cylinderShade + barkGrain).round().clamp(0, 255);
            }

            final int outA = preserveAlpha ? origAlpha : 255;
            result[idx] = (outA << 24) | (br << 16) | (bg << 8) | bb;
          }
        }
      }
    }

    // 2. Hanging Spanish Moss Fronds & Swaying Lianas
    final int mossFronds = count * 3;
    final double maxDrapeH = height * 0.45 * mossLen;

    for (int m = 0; m < mossFronds; m++) {
      final int mh = _rootHash(m, 777);
      final double anchorX = (((mh & 0xFF) / 255.0) * 0.9 + 0.05) * width;
      final double anchorY = (((mh >> 8) & 0xFF) / 255.0) * (height * 0.25);
      final double drapeH = maxDrapeH * (0.4 + (((mh >> 16) & 0x7F) / 127.0) * 0.6);
      final double mossPhase = ((mh >> 4) & 0x3F) / 63.0 * 2.0 * math.pi;

      final int startY = anchorY.round();
      final int endY = (anchorY + drapeH).round().clamp(0, height - 1);

      for (int y = startY; y <= endY; y++) {
        final double distDown = (y - anchorY);
        final double pendNorm = (distDown / drapeH).clamp(0.0, 1.0);

        // Harmonic pendulum wind sway
        final double sway = math.sin(windAngle + mossPhase) * (width * 0.035 * pendNorm) +
            math.sin(windAngle * 2.0 + mossPhase) * (width * 0.012 * pendNorm);
        final double curX = anchorX + sway;

        final double frondRadius = (1.5 + (1.0 - pendNorm) * 1.5);
        final int minX = (curX - frondRadius).floor().clamp(0, width - 1);
        final int maxX = (curX + frondRadius).ceil().clamp(0, width - 1);

        for (int x = minX; x <= maxX; x++) {
          final int idx = y * width + x;
          final int origPixel = pixels[idx];
          final int origAlpha = (origPixel >> 24) & 0xFF;

          if (preserveAlpha && origAlpha == 0) continue;

          final double dx = (x - curX).abs();
          if (dx <= frondRadius) {
            final double fiberNoise = (_hashGrain(x, y) - 0.5) * 20.0;
            final double taperFade = (1.0 - pendNorm * 0.4);

            final int mr = (mossCol.r * taperFade + fiberNoise).round().clamp(0, 255);
            final int mg = (mossCol.g * taperFade + fiberNoise).round().clamp(0, 255);
            final int mb = (mossCol.b * taperFade + fiberNoise).round().clamp(0, 255);

            final int existing = result[idx];
            final int er = (existing >> 16) & 0xFF;
            final int eg = (existing >> 8) & 0xFF;
            final int eb = existing & 0xFF;

            // Semi-translucent wispy moss overlay
            const double blend = 0.8;
            final int finalR = (er * (1.0 - blend) + mr * blend).round().clamp(0, 255);
            final int finalG = (eg * (1.0 - blend) + mg * blend).round().clamp(0, 255);
            final int finalB = (eb * (1.0 - blend) + mb * blend).round().clamp(0, 255);
            final int outA = preserveAlpha ? origAlpha : 255;
            result[idx] = (outA << 24) | (finalR << 16) | (finalG << 8) | finalB;
          }
        }
      }
    }

    // 3. Water Surface Ripple Waves
    final int waterLineY = waterY.round().clamp(0, height - 1);
    for (int x = 0; x < width; x++) {
      // Oscillating surface wave crest
      final double waveDelta = math.sin((x * 0.15) + (time * 4.0 * math.pi)) * 1.5;
      final int wy = (waterLineY + waveDelta).round().clamp(0, height - 1);
      final int idx = wy * width + x;

      final int origPixel = pixels[idx];
      final int origAlpha = (origPixel >> 24) & 0xFF;
      if (preserveAlpha && origAlpha == 0) continue;

      final int existing = result[idx];
      final int er = (existing >> 16) & 0xFF;
      final int eg = (existing >> 8) & 0xFF;
      final int eb = existing & 0xFF;

      // Sparkling water meniscus glint
      final int finalR = math.min(255, er + (algaeCol.r * 0.6).round());
      final int finalG = math.min(255, eg + (algaeCol.g * 0.6).round());
      final int finalB = math.min(255, eb + (waterCol.b * 0.9).round());
      final int outA = preserveAlpha ? origAlpha : 255;
      result[idx] = (outA << 24) | (finalR << 16) | (finalG << 8) | finalB;
    }

    return result;
  }

  static int _rootHash(int k, int seed) {
    int h = (k * 374761393 + seed * 668265263) ^ 0x3d3d3d3d;
    h = (h ^ (h >> 13)) * 1274126177;
    return h ^ (h >> 16);
  }

  static double _hashGrain(int x, int y) {
    int h = (x * 1597334677 + y * 3812015801) ^ 0x9e3779b9;
    h = (h ^ (h >> 15)) * 2246822519;
    return ((h & 0x7FFFFFFF) / 2147483647.0);
  }
}
