part of 'effects.dart';

/// Effect that generates atmospheric sky gradients and weather effects
class SkyEffect extends Effect {
  SkyEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.sky,
          parameters ??
              const {
                'skyType': 0, // 0=clear_day, 1=sunset, 2=night, 3=overcast, 4=dawn, 5=stormy
                'horizon': 0.7, // Horizon position (0-1, 0=top, 1=bottom)
                'atmosphericHaze': 0.4, // Atmospheric haze intensity (0-1)
                'gradientIntensity': 0.8, // Sky gradient strength (0-1)
                'weatherIntensity': 0.5, // Weather effect strength (0-1)
                'colorTemperature': 0.5, // Warm to cool color balance (0-1)
                'animated': false, // Whether effects animate
                'randomSeed': 42, // Seed for weather patterns
                'time': 0.0, // Animation time parameter (0-1)
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'skyType': 0,
      'horizon': 0.7,
      'atmosphericHaze': 0.4,
      'gradientIntensity': 0.8,
      'weatherIntensity': 0.5,
      'colorTemperature': 0.5,
      'animated': false,
      'randomSeed': 42,
      'time': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'skyType': {
        'label': 'Sky Type',
        'description': 'Type of sky condition to generate.',
        'type': 'select',
        'options': {
          0: 'Clear Day',
          1: 'Sunset',
          2: 'Night',
          3: 'Overcast',
          4: 'Dawn',
          5: 'Stormy',
        },
      },
      'horizon': {
        'label': 'Horizon Position',
        'description': 'Vertical position of the horizon line.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'atmosphericHaze': {
        'label': 'Atmospheric Haze',
        'description': 'Amount of atmospheric haze and distance effects.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'gradientIntensity': {
        'label': 'Gradient Intensity',
        'description': 'Strength of sky color gradients.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'weatherIntensity': {
        'label': 'Weather Intensity',
        'description': 'Intensity of weather effects (storms, etc.).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorTemperature': {
        'label': 'Color Temperature',
        'description': 'Color balance from warm (0) to cool (1).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'animated': {
        'label': 'Animated',
        'description': 'Enables animated weather effects.',
        'type': 'bool',
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes the random pattern of weather effects.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final skyType = parameters['skyType'] as int;
    final horizon = parameters['horizon'] as double;
    final atmosphericHaze = parameters['atmosphericHaze'] as double;
    final gradientIntensity = parameters['gradientIntensity'] as double;
    final weatherIntensity = parameters['weatherIntensity'] as double;
    final colorTemperature = parameters['colorTemperature'] as double;
    final animated = parameters['animated'] as bool;
    final randomSeed = parameters['randomSeed'] as int;
    final time = parameters['time'] as double;

    final result = Uint32List(pixels.length);
    final random = Random(randomSeed);

    // Get color scheme for this sky type
    final colors = _getSkyColors(skyType, colorTemperature);

    // Calculate horizon line
    final horizonY = (horizon * height).round();

    // Step 1: Fill base sky gradient
    _fillSkyGradient(result, width, height, horizonY, colors, gradientIntensity);

    // Step 2: Add atmospheric effects
    if (atmosphericHaze > 0.1) {
      _addAtmosphericHaze(result, width, height, horizonY, atmosphericHaze, colors);
    }

    // Step 3: Add weather effects
    if (weatherIntensity > 0.1) {
      _addWeatherEffects(result, width, height, skyType, weatherIntensity, animated, time, random);
    }

    // Clear skies also need a visible animation. Shift ambient light through
    // a small cycle even when there are no weather particles to move.
    if (animated) {
      final lightShift = (sin(time * 2 * pi) * 12).round();
      for (var i = 0; i < result.length; i++) {
        final pixel = result[i];
        final alpha = (pixel >> 24) & 0xff;
        if (alpha == 0) continue;
        final red = (((pixel >> 16) & 0xff) + lightShift).clamp(0, 255);
        final green = (((pixel >> 8) & 0xff) + lightShift).clamp(0, 255);
        final blue = ((pixel & 0xff) + lightShift).clamp(0, 255);
        result[i] = (alpha << 24) | (red << 16) | (green << 8) | blue;
      }
    }

    return result;
  }

  /// Get color scheme for different sky types
  _SkyColors _getSkyColors(int skyType, double colorTemperature) {
    switch (skyType) {
      case 0: // Clear day
        return _SkyColors(
          zenith: _adjustColorTemperature(const Color(0xFF4A90E2), colorTemperature),
          horizon: _adjustColorTemperature(const Color(0xFFB3D9FF), colorTemperature),
          haze: const Color(0xFFEFF5FF),
        );

      case 1: // Sunset
        return _SkyColors(
          zenith: _adjustColorTemperature(const Color(0xFF2D1B69), colorTemperature),
          horizon: _adjustColorTemperature(const Color(0xFFFF7F50), colorTemperature),
          haze: const Color(0xFFFFE4B5),
        );

      case 2: // Night
        return _SkyColors(
          zenith: _adjustColorTemperature(const Color(0xFF0D1B2A), colorTemperature),
          horizon: _adjustColorTemperature(const Color(0xFF1B263B), colorTemperature),
          haze: const Color(0xFF34495E),
        );

      case 3: // Overcast
        return _SkyColors(
          zenith: _adjustColorTemperature(const Color(0xFF708090), colorTemperature),
          horizon: _adjustColorTemperature(const Color(0xFF9DA3A8), colorTemperature),
          haze: const Color(0xFFE6E6E6),
        );

      case 4: // Dawn
        return _SkyColors(
          zenith: _adjustColorTemperature(const Color(0xFF483D8B), colorTemperature),
          horizon: _adjustColorTemperature(const Color(0xFFFFA07A), colorTemperature),
          haze: const Color(0xFFF0E68C),
        );

      case 5: // Stormy
        return _SkyColors(
          zenith: _adjustColorTemperature(const Color(0xFF2F2F2F), colorTemperature),
          horizon: _adjustColorTemperature(const Color(0xFF4A4A4A), colorTemperature),
          haze: const Color(0xFF696969),
        );

      default:
        return _getSkyColors(0, colorTemperature);
    }
  }

  /// Adjust color temperature (warm to cool)
  Color _adjustColorTemperature(Color baseColor, double temperature) {
    final hsv = HSVColor.fromColor(baseColor);

    // Shift hue: temperature 0 = warmer (more red/orange), temperature 1 = cooler (more blue)
    final hueShift = (temperature - 0.5) * 30; // ±15 degrees
    final newHue = (hsv.hue + hueShift) % 360;

    return hsv.withHue(newHue).toColor();
  }

  /// Fill base sky gradient
  void _fillSkyGradient(Uint32List pixels, int width, int height, int horizonY, _SkyColors colors, double intensity) {
    for (int y = 0; y < height; y++) {
      // Calculate position relative to horizon
      double t;
      if (y < horizonY) {
        // Above horizon - gradient from zenith to horizon
        t = y / horizonY;
      } else {
        // Below horizon - extend horizon color
        t = 1.0;
      }

      // Apply gradient intensity
      t = pow(t, 1.0 / intensity).toDouble();

      final skyColor = Color.lerp(colors.zenith, colors.horizon, t)!;

      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        pixels[index] = skyColor.value;
      }
    }
  }

  /// Add atmospheric haze
  void _addAtmosphericHaze(
      Uint32List pixels, int width, int height, int horizonY, double intensity, _SkyColors colors) {
    for (int y = 0; y < height; y++) {
      // Haze is strongest near horizon
      final distanceFromHorizon = (y - horizonY).abs();
      final maxDistance = height * 0.3;
      final hazeStrength = intensity * max(0.0, 1.0 - distanceFromHorizon / maxDistance);

      if (hazeStrength > 0.01) {
        for (int x = 0; x < width; x++) {
          final index = y * width + x;
          final hazeColor = Color.fromARGB(
            (255 * hazeStrength * 0.3).round().clamp(0, 255),
            colors.haze.red,
            colors.haze.green,
            colors.haze.blue,
          );
          pixels[index] = _blendColors(pixels[index], hazeColor.value);
        }
      }
    }
  }

  /// Add weather effects
  void _addWeatherEffects(Uint32List pixels, int width, int height, int skyType, double intensity, bool animated,
      double time, Random random) {
    switch (skyType) {
      case 5: // Stormy
        if (animated) {
          _addLightning(pixels, width, height, intensity, time);
        }
        _addRain(pixels, width, height, intensity, random);
        break;
      case 3: // Overcast
        _addLightRain(pixels, width, height, intensity, random);
        break;
    }
  }

  /// Add lightning flash effect
  void _addLightning(Uint32List pixels, int width, int height, double intensity, double time) {
    // Lightning flashes randomly
    final lightningChance = sin(time * 5) > 0.98 ? intensity : 0.0;

    if (lightningChance > 0.5) {
      final flashColor = Color.fromARGB((255 * lightningChance * 0.3).round(), 255, 255, 255);

      // Flash entire sky briefly
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = _blendColors(pixels[i], flashColor.value);
      }
    }
  }

  /// Add rain effect
  void _addRain(Uint32List pixels, int width, int height, double intensity, Random random) {
    final rainDrops = (width * intensity * 0.1).round();

    for (int i = 0; i < rainDrops; i++) {
      final x = random.nextInt(width);
      final rainHeight = 3 + random.nextInt(8);

      for (int j = 0; j < rainHeight; j++) {
        final y = random.nextInt(height - rainHeight) + j;
        if (x < width && y < height) {
          final index = y * width + x;
          pixels[index] = _blendColors(pixels[index], 0x60708090); // Semi-transparent gray
        }
      }
    }
  }

  /// Add light rain effect
  void _addLightRain(Uint32List pixels, int width, int height, double intensity, Random random) {
    final rainDrops = (width * intensity * 0.05).round();

    for (int i = 0; i < rainDrops; i++) {
      final x = random.nextInt(width);
      final y = random.nextInt(height);

      if (x < width && y < height) {
        final index = y * width + x;
        pixels[index] = _blendColors(pixels[index], 0x30A0A0A0); // Very light gray
      }
    }
  }

  /// Blend two colors
  int _blendColors(int base, int overlay) {
    final baseColor = Color(base);
    final overlayColor = Color(overlay);
    final alpha = overlayColor.alpha / 255.0;

    final r = (baseColor.red * (1 - alpha) + overlayColor.red * alpha).round();
    final g = (baseColor.green * (1 - alpha) + overlayColor.green * alpha).round();
    final b = (baseColor.blue * (1 - alpha) + overlayColor.blue * alpha).round();

    return Color.fromARGB(baseColor.alpha, r, g, b).value;
  }
}

/// Sky color palette
class _SkyColors {
  final Color zenith;
  final Color horizon;
  final Color haze;

  const _SkyColors({
    required this.zenith,
    required this.horizon,
    required this.haze,
  });
}
