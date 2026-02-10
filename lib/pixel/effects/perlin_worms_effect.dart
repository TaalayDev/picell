part of 'effects.dart';

/// Creates a decorative pattern of worms/paths driven by Perlin noise
class PerlinWormsEffect extends Effect {
  PerlinWormsEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.perlinWorms,
          parameters ??
              const {
                'wormCount': 5,
                'wormLength': 60,
                'thickness': 2,
                'noiseScale': 20.0,
                'color1': 0xFF0a0a12,
                'color2': 0xFF1a1528,
                'color3': 0xFF3a2848,
                'color4': 0xFF5a4870,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'wormCount': 5,
      'wormLength': 60,
      'thickness': 2,
      'noiseScale': 20.0,
      'color1': 0xFF0a0a12, // Background
      'color2': 0xFF1a1528,
      'color3': 0xFF3a2848,
      'color4': 0xFF5a4870,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'wormCount': {
        'label': 'Worm Count',
        'description': 'Number of worm paths to generate.',
        'type': 'slider',
        'min': 1,
        'max': 30,
        'divisions': 29,
      },
      'wormLength': {
        'label': 'Worm Length',
        'description': 'Length of each worm path in steps.',
        'type': 'slider',
        'min': 10,
        'max': 500,
        'divisions': 98,
      },
      'thickness': {
        'label': 'Thickness',
        'description': 'Thickness of the worm paths.',
        'type': 'slider',
        'min': 1,
        'max': 8,
        'divisions': 7,
      },
      'noiseScale': {
        'label': 'Noise Scale',
        'description': 'Scale of the Perlin noise that drives worm movement.',
        'type': 'slider',
        'min': 2.0,
        'max': 100.0,
        'divisions': 98,
      },
      'color1': {
        'label': 'Background Color',
        'description': 'Background color for the pattern.',
        'type': 'color',
      },
      'color2': {
        'label': 'Color 2',
        'description': 'Second color in the palette.',
        'type': 'color',
      },
      'color3': {
        'label': 'Color 3',
        'description': 'Third color in the palette.',
        'type': 'color',
      },
      'color4': {
        'label': 'Color 4',
        'description': 'Fourth color in the palette.',
        'type': 'color',
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    // Get parameters
    final wormCount = ((parameters['wormCount'] as int?) ?? 5).clamp(1, 30);
    final wormLength = ((parameters['wormLength'] as int?) ?? 60).clamp(10, 500);
    final thickness = ((parameters['thickness'] as int?) ?? 2).clamp(1, 8);
    final noiseScale = ((parameters['noiseScale'] as num?)?.toDouble() ?? 20.0).clamp(2.0, 100.0);

    // Get palette colors
    final color1 = (parameters['color1'] as int?) ?? 0xFF0a0a12;
    final color2 = (parameters['color2'] as int?) ?? 0xFF1a1528;
    final color3 = (parameters['color3'] as int?) ?? 0xFF3a2848;
    final color4 = (parameters['color4'] as int?) ?? 0xFF5a4870;

    final palette = [color1, color2, color3, color4];

    // Start with existing pixels
    final result = Uint32List.fromList(pixels);

    // Fixed seed for consistent results
    final seed = 77777;

    // Draw each worm
    for (int wi = 0; wi < wormCount; wi++) {
      // Initialize worm position using hash
      double x = _hash2f(wi, 0, seed) * width;
      double y = _hash2f(wi, 1, seed) * height;

      // Select color for this worm (skip background color)
      final colorIdx = 1 + (wi % (palette.length - 1));
      final wormColor = Color(palette[colorIdx]);

      // Draw worm path
      for (int step = 0; step < wormLength; step++) {
        // Calculate direction using Perlin noise
        final angle = _valueNoise2D(x, y, width.toDouble(), noiseScale, seed + wi * 100) * pi * 4;

        // Draw thick point at current position
        for (int dy = -thickness; dy <= thickness; dy++) {
          for (int dx = -thickness; dx <= thickness; dx++) {
            // Use circular brush
            if (dx * dx + dy * dy > thickness * thickness) continue;

            final px = ((x + dx).floor() % width + width) % width;
            final py = ((y + dy).floor() % height + height) % height;
            final index = py * width + px;

            // Get original pixel
            final originalPixel = Color(result[index]);

            // Only draw on non-transparent pixels, preserve alpha
            if (originalPixel.alpha > 0) {
              result[index] = (wormColor.value & 0x00FFFFFF) | (originalPixel.alpha << 24);
            }
          }
        }

        // Move to next position
        x += cos(angle) * 1.5;
        y += sin(angle) * 1.5;

        // Wrap around edges
        x = (x % width + width) % width;
        y = (y % height + height) % height;
      }
    }

    return result;
  }

  /// Value noise function using Perlin-like approach
  double _valueNoise2D(double x, double y, double width, double scale, int seed) {
    final nx = x / scale;
    final ny = y / scale;

    return _perlinNoise(nx, ny, seed);
  }

  /// 2D Perlin-like noise function
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

  /// Linear interpolation
  double _lerp(double a, double b, double t) {
    return a + t * (b - a);
  }

  /// 2D hash function for noise
  double _hash2D(int x, int y, int seed) {
    var h = x * 374761393 + y * 668265263 + seed;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0x7FFFFFFF) / 0x7FFFFFFF;
  }

  /// Hash to float for initialization
  double _hash2f(int a, int b, int seed) {
    var h = a * 374761393 + b * 668265263 + seed;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0x7FFFFFFF) / 0x7FFFFFFF.toDouble();
  }
}
