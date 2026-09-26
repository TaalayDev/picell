part of 'effects.dart';

/// An effect that procedurally renders deep space celestial vistas: multi-octave fractal
/// plasma gas nebulae, stellar nurseries, twinkling star clusters, and a spherical gas giant
/// with illuminated particulate rings and spherical shadow crescent.
class DeepSpaceNebulaEffect extends Effect {
  DeepSpaceNebulaEffect([Map<String, dynamic>? params])
      : super(
          EffectType.deepSpaceNebula,
          params ??
              {
                'nebulaPalette': 'orionViolet',
                'fractalTurbulence': 0.6,
                'starClusterDensity': 35,
                'showGasGiant': true,
                'ringInclination': 20.0,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'nebulaPalette': 'orionViolet',
        'fractalTurbulence': 0.6,
        'starClusterDensity': 35,
        'showGasGiant': true,
        'ringInclination': 20.0,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'nebulaPalette': {
          'label': 'Cosmic Gas Palette',
          'description': 'Ionized emission and reflection nebula color harmony.',
          'type': 'select',
          'options': {
            'orionViolet': 'Orion Magenta & Deep Violet',
            'solarGold': 'Solar Gold & Amber Pillars',
            'emeraldPillars': 'Carina Emerald & Teal Lagoon',
            'deepVoid': 'Abyssal Void & Starlight Cyan',
          },
        },
        'fractalTurbulence': {
          'label': 'Nebula Turbulence',
          'description': 'Density and swirling turbulence of cosmic dust clouds.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'starClusterDensity': {
          'label': 'Starfield Density',
          'description': 'Number of foreground twinkling stars and stellar nurseries.',
          'type': 'slider',
          'min': 0,
          'max': 80,
          'step': 5,
        },
        'showGasGiant': {
          'label': 'Show Gas Giant Planet',
          'description': 'Render spherical gas planet with particulate rings.',
          'type': 'bool',
        },
        'ringInclination': {
          'label': 'Ring Tilt Angle',
          'description': 'Inclination tilt in degrees of the planetary rings.',
          'type': 'slider',
          'min': -45.0,
          'max': 45.0,
          'step': 5.0,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Cosmic cloud drift and star twinkling animation cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict deep space skybox to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'nebulaPalette',
          label: 'Cosmic Gas Palette',
          description: 'Nebula color harmony.',
          options: {
            'orionViolet': 'Orion Magenta & Deep Violet',
            'solarGold': 'Solar Gold & Amber Pillars',
            'emeraldPillars': 'Carina Emerald & Teal Lagoon',
            'deepVoid': 'Abyssal Void & Starlight Cyan',
          },
        ),
        const SliderField(
          key: 'fractalTurbulence',
          label: 'Nebula Turbulence',
          description: 'Cosmic dust cloud density.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
        ),
        const SliderField(
          key: 'starClusterDensity',
          label: 'Starfield Density',
          description: 'Foreground twinkling star count.',
          min: 0,
          max: 80,
          divisions: 16,
          isInteger: true,
        ),
        const BoolField(
          key: 'showGasGiant',
          label: 'Show Gas Giant Planet',
          description: 'Spherical planet with rings.',
        ),
        SliderField(
          key: 'ringInclination',
          label: 'Ring Tilt Angle',
          description: 'Planetary ring angle.',
          min: -45.0,
          max: 45.0,
          divisions: 18,
          formatLabel: (v) => '${v.round()}°',
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Cosmic drift and twinkle loop.',
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

    final nebulaPalette = parameters['nebulaPalette'] as String? ?? 'orionViolet';
    final fractalTurbulence = (parameters['fractalTurbulence'] as num?)?.toDouble() ?? 0.6;
    final starClusterDensity = (parameters['starClusterDensity'] as num?)?.toInt() ?? 35;
    final showGasGiant = parameters['showGasGiant'] as bool? ?? true;
    final ringInclination = (parameters['ringInclination'] as num?)?.toDouble() ?? 20.0;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);

    // Color definitions for nebula gas clouds: [darkVoid, midGas, hotFilament, coreIonized]
    final List<List<int>> palette;
    switch (nebulaPalette) {
      case 'solarGold':
        palette = const [
          [10, 5, 2], // Deep warm void
          [160, 80, 10], // Amber mid-filament
          [240, 160, 20], // Golden plasma gas
          [255, 240, 160], // Core solar white-gold
        ];
        break;
      case 'emeraldPillars':
        palette = const [
          [2, 10, 8], // Deep teal-black void
          [10, 120, 85], // Emerald green gas
          [20, 200, 160], // Cyan ionized filament
          [200, 255, 240], // Radiant stellar core
        ];
        break;
      case 'deepVoid':
        palette = const [
          [2, 3, 8], // Abyssal space black
          [25, 45, 95], // Deep indigo dust
          [0, 180, 230], // Electric cyan ionization
          [230, 245, 255], // Pure starlight
        ];
        break;
      case 'orionViolet':
      default:
        palette = const [
          [8, 4, 16], // Deep cosmic violet-black
          [110, 20, 130], // Magenta mid-gas
          [190, 40, 180], // Hot violet filament
          [255, 210, 255], // Core ionized stellar nursery
        ];
        break;
    }

    final cycleTime = time - time.floorToDouble();
    final ringRad = ringInclination * (math.pi / 180.0);
    final cosRing = math.cos(ringRad);
    final sinRing = math.sin(ringRad);

    // Gas giant position and geometry (positioned in bottom-right corner)
    final planetCx = width * 0.78;
    final planetCy = height * 0.72;
    final planetR = math.max(6.0, math.min(width, height) * 0.28);
    final ringInnerR = planetR * 1.35;
    final ringOuterR = planetR * 2.15;

    // Fixed pseudorandom star positions
    final starRand = math.Random(1337);
    final stars = <_DeepStar>[];
    for (int s = 0; s < starClusterDensity; s++) {
      final sx = starRand.nextInt(width);
      final sy = starRand.nextInt(height);
      final brightness = starRand.nextDouble();
      final phase = starRand.nextDouble();
      final colorType = starRand.nextInt(3); // 0=blue-white, 1=golden, 2=pure white
      stars.add(_DeepStar(sx, sy, brightness, phase, colorType));
    }

    for (int y = 0; y < height; y++) {
      final ny = y / height;
      for (int x = 0; x < width; x++) {
        final nx = x / width;
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // 1. Multi-octave fractal plasma billowing clouds
        // Wave harmonics with slow drift
        final driftX = cycleTime * 0.15;
        final driftY = math.sin(cycleTime * math.pi * 2.0) * 0.05;

        final oct1 = math.sin((nx + driftX) * 4.0 + (ny + driftY) * 3.0) * 0.5 + 0.5;
        final oct2 = math.cos((nx * 8.0 - ny * 6.0) + cycleTime * 0.4) * 0.25 + 0.25;
        final oct3 = math.sin((nx * 16.0 + ny * 14.0) * 0.8) * 0.125 + 0.125;

        final rawNoise = (oct1 + oct2 + oct3) / 0.875;
        final gasIntensity = (rawNoise * fractalTurbulence).clamp(0.0, 1.0);

        int r, g, b;
        if (gasIntensity < 0.3) {
          final t = gasIntensity / 0.3;
          r = (palette[0][0] + (palette[1][0] - palette[0][0]) * t).round();
          g = (palette[0][1] + (palette[1][1] - palette[0][1]) * t).round();
          b = (palette[0][2] + (palette[1][2] - palette[0][2]) * t).round();
        } else if (gasIntensity < 0.7) {
          final t = (gasIntensity - 0.3) / 0.4;
          r = (palette[1][0] + (palette[2][0] - palette[1][0]) * t).round();
          g = (palette[1][1] + (palette[2][1] - palette[1][1]) * t).round();
          b = (palette[1][2] + (palette[2][2] - palette[1][2]) * t).round();
        } else {
          final t = (gasIntensity - 0.7) / 0.3;
          r = (palette[2][0] + (palette[3][0] - palette[2][0]) * t).round();
          g = (palette[2][1] + (palette[3][1] - palette[2][1]) * t).round();
          b = (palette[2][2] + (palette[3][2] - palette[2][2]) * t).round();
        }

        // 2. Gas Giant Planet and Particulate Rings
        if (showGasGiant) {
          final pDx = x - planetCx;
          final pDy = y - planetCy;
          final pDist = math.sqrt(pDx * pDx + pDy * pDy);

          // Rotate coordinate space for ring plane projection
          final rx = pDx * cosRing + pDy * sinRing;
          final ry = (-pDx * sinRing + pDy * cosRing) * 2.8; // Flattened ellipse
          final rDist = math.sqrt(rx * rx + ry * ry);

          final isRingBack = ry < 0; // Behind planet hemisphere
          final isRingFront = ry >= 0; // In front of planet

          // Check Ring Presence
          bool inRing = (rDist >= ringInnerR && rDist <= ringOuterR);
          // Cassini division gap in ring
          if (rDist >= (ringInnerR + ringOuterR) * 0.48 &&
              rDist <= (ringInnerR + ringOuterR) * 0.52) {
            inRing = false;
          }

          // Back half of rings (rendered behind the planet body)
          if (inRing && isRingBack && pDist > planetR) {
            final ringFrac = (rDist - ringInnerR) / (ringOuterR - ringInnerR);
            final ringBands = math.sin(ringFrac * 18.0) * 0.25 + 0.75;
            r = (180 * ringBands).round().clamp(0, 255);
            g = (165 * ringBands).round().clamp(0, 255);
            b = (145 * ringBands).round().clamp(0, 255);
          }

          // Planet Spherical Body
          if (pDist <= planetR) {
            // Spherical illumination: light source from upper-left (-0.6, -0.6)
            const lx = -0.6;
            const ly = -0.6;
            const lz = 0.52;

            final z = math.sqrt(math.max(0.0, planetR * planetR - pDist * pDist));
            final nx3d = pDx / planetR;
            final ny3d = pDy / planetR;
            final nz3d = z / planetR;

            final dot = (nx3d * lx + ny3d * ly + nz3d * lz).clamp(0.0, 1.0);

            // Jupiter/Saturn atmospheric cloud bands
            final bandLat = ((ny3d + 1.0) * 8.0) % 2.0;
            final isDarkBand = bandLat < 1.0;

            final bR = isDarkBand ? 165 : 210;
            final bG = isDarkBand ? 115 : 170;
            final bB = isDarkBand ? 75 : 120;

            // Limb darkening
            final limb = (nz3d).clamp(0.2, 1.0);

            r = (bR * dot * limb).round().clamp(0, 255);
            g = (bG * dot * limb).round().clamp(0, 255);
            b = (bB * dot * limb).round().clamp(0, 255);
          }

          // Front half of rings (rendered over the planet and sky)
          if (inRing && isRingFront) {
            final ringFrac = (rDist - ringInnerR) / (ringOuterR - ringInnerR);
            final ringBands = math.sin(ringFrac * 18.0) * 0.25 + 0.75;

            // Ring shadow cast on planet or translucent over space
            final ringR = (200 * ringBands).round();
            final ringG = (185 * ringBands).round();
            final ringB = (160 * ringBands).round();

            r = ((r * 0.3) + ringR * 0.7).round().clamp(0, 255);
            g = ((g * 0.3) + ringG * 0.7).round().clamp(0, 255);
            b = ((b * 0.3) + ringB * 0.7).round().clamp(0, 255);
          }
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    // 3. Foreground twinkling star clusters and stellar nurseries
    for (final star in stars) {
      if (star.x < 0 || star.x >= width || star.y < 0 || star.y >= height) continue;
      final sIdx = star.y * width + star.x;
      final origA = (pixels[sIdx] >> 24) & 0xFF;
      if (preserveAlpha && origA == 0) continue;

      // Twinkle pulsation
      final twinkle = 0.5 + 0.5 * math.sin(cycleTime * math.pi * 6.0 + star.phase * math.pi * 2.0);
      final sBrightness = (star.baseBrightness * twinkle).clamp(0.2, 1.0);

      int sR, sG, sB;
      if (star.colorType == 0) {
        // Hot O/B-type blue-white star
        sR = (180 * sBrightness).round();
        sG = (220 * sBrightness).round();
        sB = (255 * sBrightness).round();
      } else if (star.colorType == 1) {
        // Warm G-type golden star
        sR = (255 * sBrightness).round();
        sG = (220 * sBrightness).round();
        sB = (140 * sBrightness).round();
      } else {
        // Pure brilliant starlight
        sR = (255 * sBrightness).round();
        sG = (255 * sBrightness).round();
        sB = (255 * sBrightness).round();
      }

      final curPixel = output[sIdx];
      final cR = (curPixel >> 16) & 0xFF;
      final cG = (curPixel >> 8) & 0xFF;
      final cB = curPixel & 0xFF;

      final targetA = preserveAlpha ? origA : 255;
      output[sIdx] = (targetA << 24) |
          (math.max(cR, sR) << 16) |
          (math.max(cG, sG) << 8) |
          math.max(cB, sB);
    }

    return output;
  }
}

class _DeepStar {
  final int x;
  final int y;
  final double baseBrightness;
  final double phase;
  final int colorType;

  const _DeepStar(this.x, this.y, this.baseBrightness, this.phase, this.colorType);
}
