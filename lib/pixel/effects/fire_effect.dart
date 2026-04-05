part of 'effects.dart';

/// An effect that generates a dynamic and animated fire simulation.
///
/// This effect uses Perlin-like noise to create a realistic fire pattern,
/// with customizable parameters for intensity, flare, smoke, and flame height.
/// It's designed to be applied over the existing pixels of an image, creating a fiery overlay.
class FireEffect extends Effect {
  FireEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.fire,
          parameters ??
              const {
                'intensity': 0.8, // How bright and dense the fire is
                'flare': 0.6, // The amount of bright, flaring parts
                'ash': 0.4, // The amount of dark ash/soot particles
                'smoke': 0.5, // The density of the smoke above the fire
                'flameHeight': 0.7, // The vertical reach of the flames
                'time': 0.0, // Animation time for flickering effect
                'animated': true, // Whether the fire is animated
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'intensity': 0.8,
      'flare': 0.6,
      'ash': 0.4,
      'smoke': 0.5,
      'flameHeight': 0.7,
      'time': 0.0,
      'animated': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'intensity': {
        'label': 'Intensity',
        'description': 'Controls the brightness and density of the fire.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'flare': {
        'label': 'Flare',
        'description': 'Adjusts the amount of bright, flaring sections in the fire.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'ash': {
        'label': 'Ash & Soot',
        'description': 'Controls the amount of dark, unburnt particles in the flames.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'smoke': {
        'label': 'Smoke Density',
        'description': 'Adjusts the density of the smoke rising from the fire.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'flameHeight': {
        'label': 'Flame Height',
        'description': 'Determines the vertical reach of the flames.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'animated': {
        'label': 'Animated',
        'description': 'Enables or disables the fire animation.',
        'type': 'bool',
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final intensity = parameters['intensity'] as double;
    final flare = parameters['flare'] as double;
    final ash = parameters['ash'] as double;
    final smoke = parameters['smoke'] as double;
    final flameHeight = parameters['flameHeight'] as double;
    final time = parameters['time'] as double;
    final animated = parameters['animated'] as bool;

    final result = Uint32List.fromList(pixels);
    final random = Random(123); // Seed for ash particles

    // Animation offset for flickering effect
    final animOffset = animated ? time * 5.0 : 0.0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final originalPixel = Color(pixels[index]);

        // The effect is now applied to all pixels, regardless of transparency.

        // Calculate a fire value based on noise and vertical position
        // This creates the classic rising flame shape
        double fireValue = _calculateFireValue(x, y, width, height, animOffset, flameHeight);
        fireValue *= intensity;

        if (fireValue > 0.1) {
          // Get the color for the fire at this point
          Color fireColor = _getFireColor(fireValue, flare, ash, smoke, random);

          // Blend the fire color with the original pixel
          result[index] = _alphaBlend(originalPixel, fireColor).value;
        }
      }
    }

    return result;
  }

  /// Calculates the fire value for a given pixel using Perlin-like noise.
  double _calculateFireValue(int x, int y, int width, int height, double time, double flameHeight) {
    // Invert Y for flames that rise from the bottom
    final invY = height - 1 - y;

    // Use multiple layers of noise for a more detailed fire effect
    final noise1 = _perlinNoise(x * 0.05, invY * 0.05 + time, 1);
    final noise2 = _perlinNoise(x * 0.1, invY * 0.1 - time * 0.8, 2) * 0.5;
    final noise3 = _perlinNoise(x * 0.02, invY * 0.02 + time * 0.3, 3) * 0.7;

    // Combine noise layers
    double combinedNoise = (noise1 + noise2 + noise3) / (1.0 + 0.5 + 0.7);

    // Shape the flames to rise and narrow at the top
    final verticalGradient = pow(invY / (height * (0.5 + flameHeight * 0.5)), 2).toDouble();
    final horizontalGradient = 1.0 - (2.0 * x / width - 1.0).abs();
    final shapeFactor = verticalGradient * horizontalGradient;

    // Modulate noise with the shape
    return (combinedNoise * shapeFactor).clamp(0.0, 1.0);
  }

  /// Determines the color of a fire pixel based on its value.
  Color _getFireColor(double value, double flare, double ash, double smoke, Random random) {
    Color color;
    double alpha = 1.0;

    // Color gradient for the fire: Black -> Red -> Orange -> Yellow -> White
    if (value > 0.9 + (flare * 0.09)) {
      color = Colors.white; // Brightest flare
    } else if (value > 0.8) {
      color = Color.lerp(Colors.yellow, Colors.white, (value - 0.8) / 0.2)!;
    } else if (value > 0.6) {
      color = Color.lerp(Colors.orange, Colors.yellow, (value - 0.6) / 0.2)!;
    } else if (value > 0.3) {
      color = Color.lerp(Colors.red, Colors.orange, (value - 0.3) / 0.3)!;
    } else {
      color = Color.lerp(Colors.black, Colors.red, value / 0.3)!;
    }

    // Add random ash/soot particles
    if (random.nextDouble() < ash * 0.1) {
      final sootAmount = random.nextDouble() * 0.5;
      color = Color.lerp(color, Colors.black, sootAmount)!;
    }

    // Determine alpha based on fire value (makes edges softer)
    alpha = pow(value, 0.8).toDouble();

    // Add smoke at the top (less visible parts of the flame)
    if (value < 0.4) {
      final smokeFactor = (0.4 - value) / 0.4;
      final smokeColor = Color.lerp(Colors.transparent, const Color(0xAA333333), smokeFactor * smoke)!;
      color = _alphaBlend(Color(color.value), smokeColor);
    }

    return color.withValues(alpha: (alpha * 255).clamp(0, 255) / 255.0);
  }

  /// Alpha blends two colors together.
  Color _alphaBlend(Color background, Color foreground) {
    if (background.alpha == 0) return foreground;
    if (foreground.alpha == 0) return background;

    final double alpha = foreground.alpha / 255.0;
    final double invAlpha = 1.0 - alpha;

    final int r = (foreground.red * alpha + background.red * invAlpha).round();
    final int g = (foreground.green * alpha + background.green * invAlpha).round();
    final int b = (foreground.blue * alpha + background.blue * invAlpha).round();
    final int a = (background.alpha).clamp(0, 255);

    return Color.fromARGB(a, r, g, b);
  }

  /// 2D Perlin-like noise function for natural patterns.
  double _perlinNoise(double x, double y, int seed) {
    final intX = x.floor();
    final intY = y.floor();
    final fracX = x - intX;
    final fracY = y - intY;

    final a = _hash2D(intX, intY, seed);
    final b = _hash2D(intX + 1, intY, seed);
    final c = _hash2D(intX, intY + 1, seed);
    final d = _hash2D(intX + 1, intY + 1, seed);

    final u = fracX * fracX * (3 - 2 * fracX); // Smoothstep
    final v = fracY * fracY * (3 - 2 * fracY); // Smoothstep

    return _lerp(_lerp(a, b, u), _lerp(c, d, u), v);
  }

  /// Linear interpolation.
  double _lerp(double a, double b, double t) {
    return a + t * (b - a);
  }

  /// Simple 2D hash function for noise generation.
  double _hash2D(int x, int y, int seed) {
    var h = x * 374761393 + y * 668265263 + seed;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}
