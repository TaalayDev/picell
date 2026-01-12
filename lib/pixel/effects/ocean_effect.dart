part of 'effects.dart';

/// Effect that generates a dynamic ocean scene with realistic procedural waves,
/// atmospheric effects, and physically-based water rendering.
class OceanEffect extends Effect {
  OceanEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.ocean,
          parameters ??
              const {
                'waveFrequency': 0.5,
                'waveAmplitude': 0.5,
                'waveDirection': 0.3, // Primary wave direction (0-1 maps to 0-360°)
                'waveComplexity': 0.5, // Number of wave layers
                'foamIntensity': 0.6,
                'foamSpread': 0.4, // How far foam spreads from crests
                'colorScheme': 0,
                'waterClarity': 0.5, // Water transparency/turbidity
                'waterDepth': 0.6, // Perceived depth coloring
                'sunPosition': 0.5,
                'sunElevation': 0.7, // Sun height above horizon (0-1)
                'sunGlare': 0.7,
                'sunSize': 0.3, // Size of sun disk
                'skyGradient': true,
                'horizonLevel': 0.4,
                'horizonHaze': 0.5, // Atmospheric haze near horizon
                'cloudCover': 0.3, // Amount of clouds
                'cloudType': 0, // 0=cumulus, 1=stratus, 2=cirrus
                'windSpeed': 0.5, // Affects wave choppiness and foam
                'storminess': 0.0, // Overall storm intensity
                'timeOfDay': 0.5, // 0=midnight, 0.25=sunrise, 0.5=noon, 0.75=sunset
                'moonPhase': 0.5, // For night scenes
                'randomSeed': 42,
                'time': 0.0,
              },
        );

  // Pre-computed permutation table for noise
  late List<int> _perm;
  late List<List<double>> _gradients;

  void _initNoise(int seed) {
    final random = Random(seed);
    _perm = List<int>.generate(512, (i) => i < 256 ? i : 0);

    for (int i = 255; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _perm[i];
      _perm[i] = _perm[j];
      _perm[j] = temp;
    }
    for (int i = 0; i < 256; i++) {
      _perm[256 + i] = _perm[i];
    }

    // Pre-compute gradient vectors
    _gradients = List.generate(256, (i) {
      final angle = random.nextDouble() * 2 * pi;
      return [cos(angle), sin(angle)];
    });
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'waveFrequency': 0.5,
      'waveAmplitude': 0.5,
      'waveDirection': 0.3,
      'waveComplexity': 0.5,
      'foamIntensity': 0.6,
      'foamSpread': 0.4,
      'colorScheme': 0,
      'waterClarity': 0.5,
      'waterDepth': 0.6,
      'sunPosition': 0.5,
      'sunElevation': 0.7,
      'sunGlare': 0.7,
      'sunSize': 0.3,
      'skyGradient': true,
      'horizonLevel': 0.4,
      'horizonHaze': 0.5,
      'cloudCover': 0.3,
      'cloudType': 0,
      'windSpeed': 0.5,
      'storminess': 0.0,
      'timeOfDay': 0.5,
      'moonPhase': 0.5,
      'randomSeed': 42,
      'time': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'waveFrequency': {
        'label': 'Wave Frequency',
        'description': 'The density and scale of the waves.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waveAmplitude': {
        'label': 'Wave Amplitude',
        'description': 'The height and intensity of the waves.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waveDirection': {
        'label': 'Wave Direction',
        'description': 'Primary direction waves travel from.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waveComplexity': {
        'label': 'Wave Complexity',
        'description': 'Number of overlapping wave patterns.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'foamIntensity': {
        'label': 'Foam Intensity',
        'description': 'The amount of foam on wave crests.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'foamSpread': {
        'label': 'Foam Spread',
        'description': 'How far foam spreads from wave crests.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorScheme': {
        'label': 'Color Scheme',
        'description': 'Color palette for the ocean and sky.',
        'type': 'select',
        'options': {
          0: 'Tropical Paradise',
          1: 'Deep Atlantic',
          2: 'Sunset/Sunrise',
          3: 'Stormy Seas',
          4: 'Arctic',
          5: 'Mediterranean',
          6: 'Night Ocean',
          7: 'Alien World',
        },
      },
      'waterClarity': {
        'label': 'Water Clarity',
        'description': 'How clear or murky the water appears.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waterDepth': {
        'label': 'Water Depth',
        'description': 'Perceived depth affecting color darkness.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunPosition': {
        'label': 'Sun Position',
        'description': 'Horizontal position of the sun.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunElevation': {
        'label': 'Sun Elevation',
        'description': 'Height of the sun above the horizon.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunGlare': {
        'label': 'Sun Glare',
        'description': 'Intensity of sun reflection on water.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunSize': {
        'label': 'Sun Size',
        'description': 'Size of the sun disk.',
        'type': 'slider',
        'min': 0.1,
        'max': 1.0,
        'divisions': 90,
      },
      'skyGradient': {
        'label': 'Sky Gradient',
        'description': 'Enable gradient sky background.',
        'type': 'bool',
      },
      'horizonLevel': {
        'label': 'Horizon Level',
        'description': 'Vertical position of the horizon.',
        'type': 'slider',
        'min': 0.1,
        'max': 0.9,
        'divisions': 80,
      },
      'horizonHaze': {
        'label': 'Horizon Haze',
        'description': 'Atmospheric haze near the horizon.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'cloudCover': {
        'label': 'Cloud Cover',
        'description': 'Amount of clouds in the sky.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'cloudType': {
        'label': 'Cloud Type',
        'description': 'Style of clouds.',
        'type': 'select',
        'options': {
          0: 'Cumulus (Fluffy)',
          1: 'Stratus (Layered)',
          2: 'Cirrus (Wispy)',
          3: 'Cumulonimbus (Storm)',
        },
      },
      'windSpeed': {
        'label': 'Wind Speed',
        'description': 'Affects wave choppiness and foam.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'storminess': {
        'label': 'Storm Intensity',
        'description': 'Overall storm conditions.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'timeOfDay': {
        'label': 'Time of Day',
        'description': 'Affects lighting and colors (0=midnight, 0.5=noon).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'moonPhase': {
        'label': 'Moon Phase',
        'description': 'Moon phase for night scenes.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes wave and cloud patterns.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Animates waves and clouds.',
        'type': 'slider',
        'min': 0.0,
        'max': 100.0,
        'divisions': 1000,
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    // Extract and validate parameters
    final params = _OceanParams(
      waveFrequency: (parameters['waveFrequency'] as double).clamp(0.0, 1.0),
      waveAmplitude: (parameters['waveAmplitude'] as double).clamp(0.0, 1.0),
      waveDirection: (parameters['waveDirection'] as double).clamp(0.0, 1.0),
      waveComplexity: (parameters['waveComplexity'] as double).clamp(0.0, 1.0),
      foamIntensity: (parameters['foamIntensity'] as double).clamp(0.0, 1.0),
      foamSpread: (parameters['foamSpread'] as double).clamp(0.0, 1.0),
      colorScheme: (parameters['colorScheme'] as int).clamp(0, 7),
      waterClarity: (parameters['waterClarity'] as double).clamp(0.0, 1.0),
      waterDepth: (parameters['waterDepth'] as double).clamp(0.0, 1.0),
      sunPosition: (parameters['sunPosition'] as double).clamp(0.0, 1.0),
      sunElevation: (parameters['sunElevation'] as double).clamp(0.0, 1.0),
      sunGlare: (parameters['sunGlare'] as double).clamp(0.0, 1.0),
      sunSize: (parameters['sunSize'] as double).clamp(0.1, 1.0),
      skyGradient: parameters['skyGradient'] as bool,
      horizonLevel: (parameters['horizonLevel'] as double).clamp(0.1, 0.9),
      horizonHaze: (parameters['horizonHaze'] as double).clamp(0.0, 1.0),
      cloudCover: (parameters['cloudCover'] as double).clamp(0.0, 1.0),
      cloudType: (parameters['cloudType'] as int).clamp(0, 3),
      windSpeed: (parameters['windSpeed'] as double).clamp(0.0, 1.0),
      storminess: (parameters['storminess'] as double).clamp(0.0, 1.0),
      timeOfDay: (parameters['timeOfDay'] as double).clamp(0.0, 1.0),
      moonPhase: (parameters['moonPhase'] as double).clamp(0.0, 1.0),
      randomSeed: parameters['randomSeed'] as int,
      time: parameters['time'] as double,
    );

    // Initialize noise
    _initNoise(params.randomSeed);

    final result = Uint32List(pixels.length);
    final colors = _getColorScheme(params.colorScheme, params.timeOfDay, params.storminess);
    final horizonY = (params.horizonLevel * height).round();

    // Pre-calculate wave data for the entire water surface
    final waveMap = _generateWaveMap(width, height, horizonY, params);

    // Render sky
    _renderSky(result, width, height, horizonY, colors, params);

    // Render ocean
    _renderOcean(result, width, height, horizonY, colors, params, waveMap);

    return result;
  }

  /// Generate comprehensive wave height and normal map
  _WaveMap _generateWaveMap(int width, int height, int horizonY, _OceanParams params) {
    final oceanHeight = height - horizonY;
    if (oceanHeight <= 0) {
      return _WaveMap(
        heights: Float32List(0),
        normals: [],
        foam: Float32List(0),
        width: width,
        height: 0,
      );
    }

    final heights = Float32List(width * oceanHeight);
    final normals = List<List<double>>.generate(width * oceanHeight, (_) => [0.0, 0.0, 1.0]);
    final foam = Float32List(width * oceanHeight);

    final waveDir = params.waveDirection * 2 * pi;
    final waveDirX = cos(waveDir);
    final waveDirY = sin(waveDir);

    // Number of wave octaves based on complexity
    final numWaves = 3 + (params.waveComplexity * 5).round();

    for (int localY = 0; localY < oceanHeight; localY++) {
      final y = localY + horizonY;
      // Perspective factor:  waves appear compressed near horizon
      final perspective = localY / oceanHeight;
      final perspectiveScale = 0.1 + perspective * 0.9;

      for (int x = 0; x < width; x++) {
        final index = localY * width + x;

        // Normalized coordinates
        final nx = x / width;
        final ny = perspective;

        // Calculate Gerstner-like wave displacement
        var waveHeight = 0.0;
        var waveDx = 0.0;
        var waveDy = 0.0;

        for (int w = 0; w < numWaves; w++) {
          final waveResult = _calculateGerstnerWave(
            nx,
            ny,
            params.time,
            w,
            waveDirX,
            waveDirY,
            params.waveFrequency,
            params.waveAmplitude * perspectiveScale,
            params.windSpeed,
          );

          waveHeight += waveResult.height;
          waveDx += waveResult.dx;
          waveDy += waveResult.dy;
        }

        // Add detail noise
        final detailNoise = _fbm(
          nx * (10 + params.waveFrequency * 20) + params.time * 0.05,
          ny * (5 + params.waveFrequency * 10),
          4,
          0.5,
          2.0,
          0,
        );
        waveHeight += detailNoise * 0.15 * params.waveAmplitude * perspectiveScale;

        // Wind chop
        if (params.windSpeed > 0.3) {
          final chop = _fbm(
            nx * 50 + params.time * 0.2,
            ny * 30,
            2,
            0.5,
            2.0,
            10,
          );
          waveHeight += chop * 0.1 * (params.windSpeed - 0.3) * perspectiveScale;
        }

        heights[index] = waveHeight.clamp(-1.0, 1.0);

        // Calculate surface normal
        final normalLength = sqrt(waveDx * waveDx + waveDy * waveDy + 1);
        normals[index] = [
          -waveDx / normalLength,
          -waveDy / normalLength,
          1.0 / normalLength,
        ];

        // Calculate foam based on wave steepness and height
        var foamValue = 0.0;

        // Foam on wave crests
        if (waveHeight > 0.3) {
          foamValue = (waveHeight - 0.3) / 0.7;
        }

        // Foam from wave breaking (steepness)
        final steepness = sqrt(waveDx * waveDx + waveDy * waveDy);
        if (steepness > 0.5) {
          foamValue = max(foamValue, (steepness - 0.5) * 2);
        }

        // Wind-driven whitecaps
        if (params.windSpeed > 0.5) {
          final whitecapNoise = _fbm(
            nx * 30 + params.time * 0.15,
            ny * 20,
            2,
            0.5,
            2.0,
            20,
          );
          if (whitecapNoise > 0.6) {
            foamValue = max(foamValue, (whitecapNoise - 0.6) * 2.5 * (params.windSpeed - 0.5) * 2);
          }
        }

        // Foam spread and persistence
        foamValue *= params.foamIntensity;
        foam[index] = foamValue.clamp(0.0, 1.0);
      }
    }

    // Apply foam spread (blur-like effect)
    if (params.foamSpread > 0) {
      _applyFoamSpread(foam, width, oceanHeight, params.foamSpread);
    }

    return _WaveMap(
      heights: heights,
      normals: normals,
      foam: foam,
      width: width,
      height: oceanHeight,
    );
  }

  /// Calculate a single Gerstner wave component
  _WaveResult _calculateGerstnerWave(
    double x,
    double y,
    double time,
    int waveIndex,
    double dirX,
    double dirY,
    double frequency,
    double amplitude,
    double windSpeed,
  ) {
    // Each wave has slightly different parameters
    final seed = waveIndex * 17;
    final freqMod = 1.0 + (seed % 7) * 0.3;
    final ampMod = 1.0 / (1 + waveIndex * 0.5);

    // Rotate direction slightly for each wave
    final angleOffset = (seed % 13) * 0.2 - 0.6;
    final cosA = cos(angleOffset);
    final sinA = sin(angleOffset);
    final wdx = dirX * cosA - dirY * sinA;
    final wdy = dirX * sinA + dirY * cosA;

    // Wave parameters
    final waveFreq = (2 + frequency * 8) * freqMod;
    final waveAmp = amplitude * 0.3 * ampMod;
    final speed = sqrt(9.81 / waveFreq) * (0.5 + windSpeed * 0.5);

    // Phase
    final phase = (x * wdx + y * wdy) * waveFreq - time * speed * 0.1;

    // Gerstner wave calculation
    final sinPhase = sin(phase);
    final cosPhase = cos(phase);

    // Steepness (Q parameter)
    final steepness = 0.5 + windSpeed * 0.4;

    return _WaveResult(
      height: waveAmp * sinPhase,
      dx: steepness * waveAmp * wdx * cosPhase,
      dy: steepness * waveAmp * wdy * cosPhase,
    );
  }

  /// Apply foam spread effect
  void _applyFoamSpread(Float32List foam, int width, int height, double spread) {
    final radius = (spread * 3).round().clamp(1, 5);
    final temp = Float32List.fromList(foam);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var maxFoam = temp[y * width + x];

        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              final dist = sqrt((dx * dx + dy * dy).toDouble());
              final falloff = 1.0 - dist / (radius + 1);
              if (falloff > 0) {
                final neighborFoam = temp[ny * width + nx] * falloff * spread;
                maxFoam = max(maxFoam, neighborFoam);
              }
            }
          }
        }

        foam[y * width + x] = maxFoam;
      }
    }
  }

  /// Render the sky with sun, clouds, and atmospheric effects
  void _renderSky(
    Uint32List pixels,
    int width,
    int height,
    int horizonY,
    OceanColors colors,
    _OceanParams params,
  ) {
    if (horizonY <= 0) return;

    // Sun position in sky
    final sunX = params.sunPosition * width;
    final sunY = horizonY * (1.0 - params.sunElevation * 0.8);
    final sunRadius = params.sunSize * min(width, height) * 0.1;

    // Determine if it's night
    final isNight = params.timeOfDay < 0.25 || params.timeOfDay > 0.75;
    final nightFactor =
        isNight ? (params.timeOfDay < 0.25 ? 1.0 - params.timeOfDay * 4 : (params.timeOfDay - 0.75) * 4) : 0.0;

    for (int y = 0; y < horizonY; y++) {
      final skyT = y / horizonY;

      for (int x = 0; x < width; x++) {
        // Base sky gradient
        Color skyColor;
        if (params.skyGradient) {
          skyColor = Color.lerp(colors.skyTop, colors.skyBottom, skyT)!;
        } else {
          skyColor = colors.skyBottom;
        }

        // Horizon haze
        if (params.horizonHaze > 0 && skyT > 0.7) {
          final hazeFactor = ((skyT - 0.7) / 0.3) * params.horizonHaze;
          skyColor = Color.lerp(skyColor, colors.hazeColor, hazeFactor)!;
        }

        // Sun rendering
        if (!isNight || nightFactor < 0.8) {
          final sunDist = sqrt(pow(x - sunX, 2) + pow(y - sunY, 2));

          // Sun disk
          if (sunDist < sunRadius) {
            final sunEdge = sunDist / sunRadius;
            final sunColor = Color.lerp(colors.sunCore, colors.sunEdge, sunEdge)!;
            final sunIntensity = (1.0 - nightFactor).clamp(0.0, 1.0);
            skyColor = Color.lerp(skyColor, sunColor, sunIntensity * (1.0 - sunEdge * 0.3))!;
          }
          // Sun glow
          else if (sunDist < sunRadius * 4) {
            final glowFactor = 1.0 - (sunDist - sunRadius) / (sunRadius * 3);
            final glowIntensity = glowFactor * glowFactor * params.sunGlare * (1.0 - nightFactor);
            skyColor = Color.lerp(skyColor, colors.sunGlow, glowIntensity * 0.5)!;
          }
        }

        // Moon for night scenes
        if (isNight && nightFactor > 0.3) {
          final moonX = (1.0 - params.sunPosition) * width; // Opposite side from sun
          final moonY = horizonY * 0.3;
          final moonRadius = sunRadius * 0.8;
          final moonDist = sqrt(pow(x - moonX, 2) + pow(y - moonY, 2));

          if (moonDist < moonRadius) {
            final moonPhaseOffset = params.moonPhase * moonRadius * 2 - moonRadius;
            final inLitPart = (x - moonX) > moonPhaseOffset;

            if (inLitPart || params.moonPhase > 0.9 || params.moonPhase < 0.1) {
              final moonEdge = moonDist / moonRadius;
              final moonColor = Color.lerp(
                const Color(0xFFF5F5DC),
                const Color(0xFFD4D4AA),
                moonEdge,
              )!;
              skyColor = Color.lerp(skyColor, moonColor, nightFactor * (1.0 - moonEdge * 0.5))!;
            }
          }
        }

        // Stars for night scenes
        if (nightFactor > 0.5 && params.cloudCover < 0.7) {
          final starNoise = _perlinNoise(x * 0.5, y * 0.5, 100);
          if (starNoise > 0.97) {
            final starBrightness = (starNoise - 0.97) / 0.03 * nightFactor * (1.0 - params.cloudCover);
            final twinkle = sin(params.time * 0.5 + x * 0.1 + y * 0.1) * 0.3 + 0.7;
            skyColor = Color.lerp(skyColor, Colors.white, starBrightness * twinkle)!;
          }
        }

        // Clouds
        if (params.cloudCover > 0) {
          final cloudValue = _calculateClouds(x, y, width, horizonY, params);
          if (cloudValue > 0) {
            // Cloud lighting based on sun position
            final cloudLighting = _calculateCloudLighting(x, y, sunX, sunY, params);
            final litCloudColor = Color.lerp(colors.cloudShadow, colors.cloudHighlight, cloudLighting)!;
            skyColor = Color.lerp(skyColor, litCloudColor, cloudValue * params.cloudCover)!;
          }
        }

        pixels[y * width + x] = skyColor.value;
      }
    }
  }

  /// Calculate cloud density at a point
  double _calculateClouds(int x, int y, int width, int horizonY, _OceanParams params) {
    final nx = x / width;
    final ny = y / horizonY;

    double cloudValue;

    switch (params.cloudType) {
      case 0: // Cumulus (fluffy)
        final baseCloud = _fbm(
          nx * 4 + params.time * 0.01,
          ny * 3,
          5,
          0.5,
          2.0,
          30,
        );
        // Make clouds more defined
        cloudValue = ((baseCloud + 1) / 2);
        cloudValue = pow(cloudValue, 2.0 - params.cloudCover).clamp(0.0, 1.0).toDouble();

        // Cumulus clouds are more prominent in lower sky
        cloudValue *= (ny > 0.3) ? 1.0 : ny / 0.3;
        break;

      case 1: // Stratus (layered)
        final layerNoise = _fbm(
          nx * 8 + params.time * 0.02,
          ny * 1.5,
          3,
          0.6,
          2.0,
          31,
        );
        cloudValue = ((layerNoise + 1) / 2);
        // Horizontal emphasis
        cloudValue *= 0.5 + sin(ny * pi * 3) * 0.5;
        break;

      case 2: // Cirrus (wispy)
        final wispy = _fbm(
          nx * 6 + params.time * 0.03,
          ny * 2,
          4,
          0.7,
          2.5,
          32,
        );
        cloudValue = ((wispy + 1) / 2);
        // Cirrus only in upper sky
        cloudValue *= (ny < 0.5) ? 1.0 - ny * 2 : 0.0;
        // Make wisps thinner
        cloudValue = cloudValue > 0.6 ? (cloudValue - 0.6) * 2.5 : 0.0;
        break;

      case 3: // Cumulonimbus (storm)
        final stormCloud = _fbm(
          nx * 3 + params.time * 0.005,
          ny * 4,
          6,
          0.55,
          2.0,
          33,
        );
        cloudValue = ((stormCloud + 1) / 2);
        // Towering effect
        cloudValue = pow(cloudValue, 1.5 - params.storminess).clamp(0.0, 1.0).toDouble();
        cloudValue *= (1.0 + params.storminess * 0.5);
        break;

      default:
        cloudValue = 0.0;
    }

    return cloudValue.clamp(0.0, 1.0);
  }

  /// Calculate cloud lighting
  double _calculateCloudLighting(int x, int y, double sunX, double sunY, _OceanParams params) {
    final dx = x - sunX;
    final dy = y - sunY;
    final dist = sqrt(dx * dx + dy * dy);

    // Normalize distance
    final maxDist = 500.0;
    final normalizedDist = (dist / maxDist).clamp(0.0, 1.0);

    // Clouds facing the sun are brighter
    var lighting = 1.0 - normalizedDist * 0.6;

    // Add some variation
    final variation = _perlinNoise(x * 0.02, y * 0.02, 40) * 0.2;
    lighting += variation;

    return lighting.clamp(0.2, 1.0);
  }

  /// Render the ocean with waves, foam, and reflections
  void _renderOcean(
    Uint32List pixels,
    int width,
    int height,
    int horizonY,
    OceanColors colors,
    _OceanParams params,
    _WaveMap waveMap,
  ) {
    if (horizonY >= height) return;

    final oceanHeight = height - horizonY;
    final sunX = params.sunPosition;

    for (int localY = 0; localY < oceanHeight; localY++) {
      final y = localY + horizonY;
      final perspective = localY / oceanHeight;

      for (int x = 0; x < width; x++) {
        final nx = x / width;
        final index = localY * waveMap.width + x;

        // Get wave data
        final waveHeight = waveMap.heights[index];
        final normal = waveMap.normals[index];
        final foamAmount = waveMap.foam[index];

        // Base water color with depth
        final depthFactor = perspective * params.waterDepth;
        Color waterColor = Color.lerp(
          colors.waterDeep,
          colors.waterShallow,
          perspective,
        )!;

        // Water clarity affects color saturation
        if (params.waterClarity < 1.0) {
          final turbidity = 1.0 - params.waterClarity;
          waterColor = Color.lerp(waterColor, colors.waterMurky, turbidity * 0.5)!;
        }

        // Apply wave shading (light/dark based on wave slope)
        final slopeFactor = (waveHeight + 1) / 2;
        final shadeFactor = 0.7 + slopeFactor * 0.3;
        waterColor = _adjustBrightness(waterColor, shadeFactor);

        // Fresnel reflection (more reflection at grazing angles)
        final viewAngle = perspective; // Simplified view angle
        final fresnelFactor = pow(1.0 - viewAngle, 3).clamp(0.0, 1.0);

        // Reflect sky color
        final reflectedSkyT = 1.0 - (normal[2] * 0.5 + 0.5);
        final reflectedSky = Color.lerp(colors.skyTop, colors.skyBottom, reflectedSkyT)!;
        waterColor = Color.lerp(waterColor, reflectedSky, fresnelFactor * 0.4 * params.waterClarity)!;

        // Sun glare/specular reflection
        if (params.sunGlare > 0) {
          final sunDist = (nx - sunX).abs();

          // Glare path width decreases with distance from horizon
          final glareWidth = 0.15 * (1.0 - perspective * 0.5);

          if (sunDist < glareWidth) {
            // Calculate specular intensity based on wave normal
            final specular = _calculateSpecular(
              normal,
              nx,
              perspective,
              sunX,
              params.sunElevation,
            );

            if (specular > 0) {
              final glareIntensity = specular * params.sunGlare * (1.0 - sunDist / glareWidth);
              // Sparkle effect from small waves
              final sparkle = _perlinNoise(x * 0.5 + params.time * 0.3, y * 0.3, 50);
              final sparkleBoost = sparkle > 0.7 ? (sparkle - 0.7) * 3 : 0.0;

              waterColor = Color.lerp(
                waterColor,
                colors.sunGlare,
                (glareIntensity + sparkleBoost * glareIntensity).clamp(0.0, 1.0),
              )!;
            }
          }
        }

        // Apply foam
        if (foamAmount > 0) {
          // Foam has bubbles and texture
          final foamTexture = _fbm(
            x * 0.1 + params.time * 0.02,
            y * 0.1,
            2,
            0.5,
            2.0,
            60,
          );
          final texturedFoam = foamAmount * (0.7 + foamTexture * 0.3);

          // Foam color varies slightly
          final foamVariation = _perlinNoise(x * 0.05, y * 0.05, 61) * 0.1;
          final foamColor = _adjustBrightness(colors.foam, 1.0 + foamVariation);

          waterColor = Color.lerp(waterColor, foamColor, texturedFoam.clamp(0.0, 0.95))!;
        }

        // Subsurface scattering (light penetrating water)
        if (params.waterClarity > 0.3 && waveHeight > 0.2) {
          final sssIntensity = (waveHeight - 0.2) * params.waterClarity * 0.3;
          waterColor = Color.lerp(waterColor, colors.subsurface, sssIntensity)!;
        }

        // Horizon haze on water
        if (params.horizonHaze > 0 && perspective < 0.2) {
          final hazeFactor = (1.0 - perspective / 0.2) * params.horizonHaze * 0.5;
          waterColor = Color.lerp(waterColor, colors.hazeColor, hazeFactor)!;
        }

        // Storm darkening
        if (params.storminess > 0) {
          waterColor = _adjustBrightness(waterColor, 1.0 - params.storminess * 0.3);
        }

        pixels[y * width + x] = waterColor.value;
      }
    }
  }

  /// Calculate specular highlight intensity
  double _calculateSpecular(
    List<double> normal,
    double x,
    double y,
    double sunX,
    double sunElevation,
  ) {
    // View direction (looking down at water)
    const viewX = 0.0;
    const viewY = 0.0;
    const viewZ = 1.0;

    // Light direction from sun
    final lightX = sunX - x;
    final lightY = -sunElevation;
    final lightZ = 0.5;
    final lightLen = sqrt(lightX * lightX + lightY * lightY + lightZ * lightZ);
    final lx = lightX / lightLen;
    final ly = lightY / lightLen;
    final lz = lightZ / lightLen;

    // Reflection vector
    final dot = normal[0] * lx + normal[1] * ly + normal[2] * lz;
    final rx = 2 * dot * normal[0] - lx;
    final ry = 2 * dot * normal[1] - ly;
    final rz = 2 * dot * normal[2] - lz;

    // Specular intensity
    final specDot = rx * viewX + ry * viewY + rz * viewZ;
    if (specDot <= 0) return 0.0;

    // Shininess
    return pow(specDot, 32).clamp(0.0, 1.0).toDouble();
  }

  /// Adjust color brightness
  Color _adjustBrightness(Color color, double factor) {
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round().clamp(0, 255),
      (color.green * factor).round().clamp(0, 255),
      (color.blue * factor).round().clamp(0, 255),
    );
  }

  /// Perlin noise implementation
  double _perlinNoise(double x, double y, int seed) {
    x += seed * 17.0;
    y += seed * 31.0;

    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;

    final sx = _smootherstep(x - x0);
    final sy = _smootherstep(y - y0);

    final i00 = _perm[(_perm[x0 & 255] + y0) & 255];
    final i10 = _perm[(_perm[x1 & 255] + y0) & 255];
    final i01 = _perm[(_perm[x0 & 255] + y1) & 255];
    final i11 = _perm[(_perm[x1 & 255] + y1) & 255];

    final g00 = _gradients[i00 & 255];
    final g10 = _gradients[i10 & 255];
    final g01 = _gradients[i01 & 255];
    final g11 = _gradients[i11 & 255];

    final n00 = g00[0] * (x - x0) + g00[1] * (y - y0);
    final n10 = g10[0] * (x - x1) + g10[1] * (y - y0);
    final n01 = g01[0] * (x - x0) + g01[1] * (y - y1);
    final n11 = g11[0] * (x - x1) + g11[1] * (y - y1);

    final nx0 = _lerp(n00, n10, sx);
    final nx1 = _lerp(n01, n11, sy);

    return _lerp(nx0, nx1, sy);
  }

  /// Fractal Brownian Motion
  double _fbm(double x, double y, int octaves, double persistence, double lacunarity, int seed) {
    double total = 0.0;
    double amplitude = 1.0;
    double frequency = 1.0;
    double maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
      total += _perlinNoise(x * frequency, y * frequency, seed + i) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= lacunarity;
    }

    return total / maxValue;
  }

  double _smootherstep(double t) => t * t * t * (t * (t * 6 - 15) + 10);
  double _lerp(double a, double b, double t) => a + t * (b - a);

  /// Get color scheme based on type, time of day, and weather
  OceanColors _getColorScheme(int scheme, double timeOfDay, double storminess) {
    // Base colors for each scheme
    OceanColors baseColors;

    switch (scheme) {
      case 1: // Deep Atlantic
        baseColors = const OceanColors(
          skyTop: Color(0xFF1A237E),
          skyBottom: Color(0xFF5C6BC0),
          waterDeep: Color(0xFF0D1B2A),
          waterShallow: Color(0xFF1B3A5F),
          waterMurky: Color(0xFF2C3E50),
          foam: Color(0xFFE8EAF6),
          sunCore: Color(0xFFFFFDE7),
          sunEdge: Color(0xFFFFEB3B),
          sunGlow: Color(0xFFFFE082),
          sunGlare: Color(0xFFFFFFFF),
          hazeColor: Color(0xFF90A4AE),
          cloudHighlight: Color(0xFFFFFFFF),
          cloudShadow: Color(0xFF78909C),
          subsurface: Color(0xFF4FC3F7),
        );
        break;

      case 2: // Sunset/Sunrise
        baseColors = const OceanColors(
          skyTop: Color(0xFF4A148C),
          skyBottom: Color(0xFFFF8A65),
          waterDeep: Color(0xFF4A148C),
          waterShallow: Color(0xFFAD1457),
          waterMurky: Color(0xFF6A1B4D),
          foam: Color(0xFFFFE0B2),
          sunCore: Color(0xFFFFFFFF),
          sunEdge: Color(0xFFFF5722),
          sunGlow: Color(0xFFFF9800),
          sunGlare: Color(0xFFFFEB3B),
          hazeColor: Color(0xFFFFAB91),
          cloudHighlight: Color(0xFFFFCCBC),
          cloudShadow: Color(0xFF8E24AA),
          subsurface: Color(0xFFFF7043),
        );
        break;

      case 3: // Stormy
        baseColors = const OceanColors(
          skyTop: Color(0xFF1C1C1C),
          skyBottom: Color(0xFF424242),
          waterDeep: Color(0xFF1A1A2E),
          waterShallow: Color(0xFF2D3436),
          waterMurky: Color(0xFF1E272E),
          foam: Color(0xFFB0BEC5),
          sunCore: Color(0xFFBDBDBD),
          sunEdge: Color(0xFF9E9E9E),
          sunGlow: Color(0xFF757575),
          sunGlare: Color(0xFFE0E0E0),
          hazeColor: Color(0xFF616161),
          cloudHighlight: Color(0xFF9E9E9E),
          cloudShadow: Color(0xFF212121),
          subsurface: Color(0xFF455A64),
        );
        break;

      case 4: // Arctic
        baseColors = const OceanColors(
          skyTop: Color(0xFF81D4FA),
          skyBottom: Color(0xFFE1F5FE),
          waterDeep: Color(0xFF0277BD),
          waterShallow: Color(0xFF4DD0E1),
          waterMurky: Color(0xFF4DB6AC),
          foam: Color(0xFFFFFFFF),
          sunCore: Color(0xFFFFFFFF),
          sunEdge: Color(0xFFFFF9C4),
          sunGlow: Color(0xFFFFFFFF),
          sunGlare: Color(0xFFFFFFFF),
          hazeColor: Color(0xFFE0F7FA),
          cloudHighlight: Color(0xFFFFFFFF),
          cloudShadow: Color(0xFFB3E5FC),
          subsurface: Color(0xFF80DEEA),
        );
        break;

      case 5: // Mediterranean
        baseColors = const OceanColors(
          skyTop: Color(0xFF0288D1),
          skyBottom: Color(0xFF81D4FA),
          waterDeep: Color(0xFF006064),
          waterShallow: Color(0xFF00ACC1),
          waterMurky: Color(0xFF00838F),
          foam: Color(0xFFFFFFFF),
          sunCore: Color(0xFFFFFDE7),
          sunEdge: Color(0xFFFFD54F),
          sunGlow: Color(0xFFFFE082),
          sunGlare: Color(0xFFFFFFFF),
          hazeColor: Color(0xFFB2EBF2),
          cloudHighlight: Color(0xFFFFFFFF),
          cloudShadow: Color(0xFF4DD0E1),
          subsurface: Color(0xFF26C6DA),
        );
        break;

      case 6: // Night Ocean
        baseColors = const OceanColors(
          skyTop: Color(0xFF0D0D1A),
          skyBottom: Color(0xFF1A1A3E),
          waterDeep: Color(0xFF0A0A14),
          waterShallow: Color(0xFF141428),
          waterMurky: Color(0xFF0F0F1E),
          foam: Color(0xFF3D3D5C),
          sunCore: Color(0xFFF5F5DC), // Moon color
          sunEdge: Color(0xFFD4D4AA),
          sunGlow: Color(0xFF6B6B8D),
          sunGlare: Color(0xFFE8E8FF),
          hazeColor: Color(0xFF1A1A3E),
          cloudHighlight: Color(0xFF3D3D5C),
          cloudShadow: Color(0xFF0D0D1A),
          subsurface: Color(0xFF1E1E50),
        );
        break;

      case 7: // Alien World
        baseColors = const OceanColors(
          skyTop: Color(0xFF4A0072),
          skyBottom: Color(0xFF7B1FA2),
          waterDeep: Color(0xFF1A237E),
          waterShallow: Color(0xFF7C4DFF),
          waterMurky: Color(0xFF311B92),
          foam: Color(0xFFB388FF),
          sunCore: Color(0xFFE040FB),
          sunEdge: Color(0xFFAA00FF),
          sunGlow: Color(0xFFCE93D8),
          sunGlare: Color(0xFFE1BEE7),
          hazeColor: Color(0xFF9C27B0),
          cloudHighlight: Color(0xFFE1BEE7),
          cloudShadow: Color(0xFF6A1B9A),
          subsurface: Color(0xFF651FFF),
        );
        break;

      case 0: // Tropical Paradise
      default:
        baseColors = const OceanColors(
          skyTop: Color(0xFF0277BD),
          skyBottom: Color(0xFF81D4FA),
          waterDeep: Color(0xFF00695C),
          waterShallow: Color(0xFF26C6DA),
          waterMurky: Color(0xFF00838F),
          foam: Color(0xFFFFFFFF),
          sunCore: Color(0xFFFFFDE7),
          sunEdge: Color(0xFFFFD54F),
          sunGlow: Color(0xFFFFE082),
          sunGlare: Color(0xFFFFFFFF),
          hazeColor: Color(0xFFB2EBF2),
          cloudHighlight: Color(0xFFFFFFFF),
          cloudShadow: Color(0xFF4DD0E1),
          subsurface: Color(0xFF4DD0E1),
        );
    }

    // Apply storm darkening if needed
    if (storminess > 0) {
      return baseColors.withStorminess(storminess);
    }

    return baseColors;
  }
}

/// Parameters for ocean rendering
class _OceanParams {
  final double waveFrequency;
  final double waveAmplitude;
  final double waveDirection;
  final double waveComplexity;
  final double foamIntensity;
  final double foamSpread;
  final int colorScheme;
  final double waterClarity;
  final double waterDepth;
  final double sunPosition;
  final double sunElevation;
  final double sunGlare;
  final double sunSize;
  final bool skyGradient;
  final double horizonLevel;
  final double horizonHaze;
  final double cloudCover;
  final int cloudType;
  final double windSpeed;
  final double storminess;
  final double timeOfDay;
  final double moonPhase;
  final int randomSeed;
  final double time;

  const _OceanParams({
    required this.waveFrequency,
    required this.waveAmplitude,
    required this.waveDirection,
    required this.waveComplexity,
    required this.foamIntensity,
    required this.foamSpread,
    required this.colorScheme,
    required this.waterClarity,
    required this.waterDepth,
    required this.sunPosition,
    required this.sunElevation,
    required this.sunGlare,
    required this.sunSize,
    required this.skyGradient,
    required this.horizonLevel,
    required this.horizonHaze,
    required this.cloudCover,
    required this.cloudType,
    required this.windSpeed,
    required this.storminess,
    required this.timeOfDay,
    required this.moonPhase,
    required this.randomSeed,
    required this.time,
  });
}

/// Wave calculation result
class _WaveResult {
  final double height;
  final double dx;
  final double dy;

  const _WaveResult({
    required this.height,
    required this.dx,
    required this.dy,
  });
}

/// Pre-computed wave map
class _WaveMap {
  final Float32List heights;
  final List<List<double>> normals;
  final Float32List foam;
  final int width;
  final int height;

  const _WaveMap({
    required this.heights,
    required this.normals,
    required this.foam,
    required this.width,
    required this.height,
  });
}

/// Enhanced ocean color palette
class OceanColors {
  final Color skyTop;
  final Color skyBottom;
  final Color waterDeep;
  final Color waterShallow;
  final Color waterMurky;
  final Color foam;
  final Color sunCore;
  final Color sunEdge;
  final Color sunGlow;
  final Color sunGlare;
  final Color hazeColor;
  final Color cloudHighlight;
  final Color cloudShadow;
  final Color subsurface;

  const OceanColors({
    required this.skyTop,
    required this.skyBottom,
    required this.waterDeep,
    required this.waterShallow,
    required this.waterMurky,
    required this.foam,
    required this.sunCore,
    required this.sunEdge,
    required this.sunGlow,
    required this.sunGlare,
    required this.hazeColor,
    required this.cloudHighlight,
    required this.cloudShadow,
    required this.subsurface,
  });

  /// Create a stormier version of this color scheme
  OceanColors withStorminess(double storm) {
    Color darken(Color c, double amount) {
      return Color.fromARGB(
        c.alpha,
        (c.red * (1 - amount)).round().clamp(0, 255),
        (c.green * (1 - amount)).round().clamp(0, 255),
        (c.blue * (1 - amount)).round().clamp(0, 255),
      );
    }

    Color desaturate(Color c, double amount) {
      final gray = (c.red * 0.299 + c.green * 0.587 + c.blue * 0.114).round();
      return Color.fromARGB(
        c.alpha,
        (c.red + (gray - c.red) * amount).round().clamp(0, 255),
        (c.green + (gray - c.green) * amount).round().clamp(0, 255),
        (c.blue + (gray - c.blue) * amount).round().clamp(0, 255),
      );
    }

    final stormDarken = storm * 0.4;
    final stormDesat = storm * 0.3;

    return OceanColors(
      skyTop: desaturate(darken(skyTop, stormDarken), stormDesat),
      skyBottom: desaturate(darken(skyBottom, stormDarken), stormDesat),
      waterDeep: desaturate(darken(waterDeep, stormDarken * 0.5), stormDesat),
      waterShallow: desaturate(darken(waterShallow, stormDarken), stormDesat),
      waterMurky: waterMurky,
      foam: desaturate(foam, stormDesat),
      sunCore: darken(sunCore, stormDarken),
      sunEdge: darken(sunEdge, stormDarken),
      sunGlow: darken(sunGlow, stormDarken),
      sunGlare: darken(sunGlare, stormDarken * 0.5),
      hazeColor: desaturate(darken(hazeColor, stormDarken), stormDesat),
      cloudHighlight: darken(cloudHighlight, stormDarken),
      cloudShadow: darken(cloudShadow, stormDarken),
      subsurface: desaturate(darken(subsurface, stormDarken), stormDesat),
    );
  }
}
