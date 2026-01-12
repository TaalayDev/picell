part of 'effects.dart';

/// Generates realistic stone and rock surface textures.
class StoneEffect extends Effect {
  StoneEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.stone,
          parameters ??
              const {
                'stoneType': 1,
                'scale': 0.5,
                'roughness': 0.5,
                'cracks': 0.3,
                'variation': 0.4,
                'weathering': 0.2,
                'seed': 42,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'stoneType': 1,
        'scale': 0.5,
        'roughness': 0.5,
        'cracks': 0.3,
        'variation': 0.4,
        'weathering': 0.2,
        'seed': 42,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'stoneType': {
          'label': 'Stone Type',
          'description': 'Type of stone texture.',
          'type': 'select',
          'options': {
            0: 'Marble',
            1: 'Granite',
            2: 'Sandstone',
            3: 'Slate',
            4: 'Limestone',
            5: 'Obsidian',
            6: 'Cobblestone',
          },
        },
        'scale': {
          'label': 'Pattern Scale',
          'description': 'Size of the stone pattern.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'roughness': {
          'label': 'Roughness',
          'description': 'Surface texture roughness.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'cracks': {
          'label': 'Cracks',
          'description': 'Amount of cracks and fissures.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'variation': {
          'label': 'Color Variation',
          'description': 'Natural color variation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'weathering': {
          'label': 'Weathering',
          'description': 'Surface erosion and aging.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'seed': {
          'label': 'Seed',
          'description': 'Random pattern seed.',
          'type': 'slider',
          'min': 1,
          'max': 999,
          'divisions': 998,
        },
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final stoneType = (parameters['stoneType'] as int).clamp(0, 6);
    final scale = (parameters['scale'] as double).clamp(0.1, 1.0);
    final roughness = (parameters['roughness'] as double).clamp(0.0, 1.0);
    final cracks = (parameters['cracks'] as double).clamp(0.0, 1.0);
    final variation = (parameters['variation'] as double).clamp(0.0, 1.0);
    final weathering = (parameters['weathering'] as double).clamp(0.0, 1.0);
    final seed = parameters['seed'] as int;

    final result = Uint32List(pixels.length);
    final palette = _getPalette(stoneType);
    final rng = _StoneRandom(seed);

    // Pattern scale factor
    final ps = 0.02 + (1.0 - scale) * 0.08;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final alpha = (pixels[idx] >> 24) & 0xFF;

        // Skip transparent pixels
        if (alpha == 0) {
          result[idx] = 0;
          continue;
        }

        // Generate stone color
        int color;
        switch (stoneType) {
          case 0:
            color = _marble(x, y, ps, palette, variation, rng);
            break;
          case 1:
            color = _granite(x, y, ps, palette, variation, rng);
            break;
          case 2:
            color = _sandstone(x, y, ps, palette, variation, rng);
            break;
          case 3:
            color = _slate(x, y, ps, palette, variation, rng);
            break;
          case 4:
            color = _limestone(x, y, ps, palette, variation, rng);
            break;
          case 5:
            color = _obsidian(x, y, ps, palette, variation, rng);
            break;
          case 6:
            color = _cobblestone(x, y, width, height, ps, palette, variation, rng);
            break;
          default:
            color = palette.base;
        }

        // Apply roughness
        if (roughness > 0) {
          color = _applyRoughness(color, x, y, roughness, seed);
        }

        // Apply cracks
        if (cracks > 0) {
          color = _applyCracks(color, x, y, cracks, palette.dark, seed);
        }

        // Apply weathering
        if (weathering > 0) {
          color = _applyWeathering(color, x, y, weathering, seed);
        }

        // Preserve original alpha
        result[idx] = (alpha << 24) | (color & 0x00FFFFFF);
      }
    }

    return result;
  }

  /// Marble: flowing veins on light base
  int _marble(int x, int y, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Turbulent veining
    final vein1 = _turbulence(x * s, y * s * 3, 3, seed: rng.seed);
    final vein2 = _turbulence(x * s * 2, y * s, 2, seed: rng.seed + 100);
    final combined = (vein1 + vein2 * 0.5) / 1.5;

    // Create veins
    final veinStrength = sin(combined * pi * 4) * 0.5 + 0.5;

    if (veinStrength < 0.2) {
      return _lerp(p.dark, p.base, veinStrength / 0.2);
    } else if (veinStrength > 0.85) {
      return _lerp(p.base, p.light, (veinStrength - 0.85) / 0.15);
    }
    return p.base;
  }

  /// Granite: speckled crystals
  int _granite(int x, int y, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Base texture
    final base = _noise(x * s, y * s, rng.seed) * 0.5 + 0.5;

    // Crystal speckles at different scales
    final speckle1 = _noise(x * s * 8, y * s * 8, rng.seed + 200);
    final speckle2 = _noise(x * s * 12, y * s * 12, rng.seed + 300);

    int color = _lerp(p.dark, p.base, base);

    // Add light crystals (feldspar)
    if (speckle1 > 0.6) {
      color = _lerp(color, p.light, (speckle1 - 0.6) * 2);
    }

    // Add dark crystals (mica)
    if (speckle2 < -0.5) {
      color = _lerp(color, p.dark, (-speckle2 - 0.5) * 1.5);
    }

    // Occasional accent (quartz)
    if (speckle1 > 0.8 && speckle2 > 0.3) {
      color = _lerp(color, p.accent, 0.4);
    }

    return color;
  }

  /// Sandstone: horizontal layers with grain
  int _sandstone(int x, int y, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Horizontal banding
    final band = sin(y * s * 15 + _noise(x * s * 2, y * s * 0.5, rng.seed) * 2) * 0.5 + 0.5;

    // Fine grain texture
    final grain = _noise(x * s * 20, y * s * 20, rng.seed + 400) * 0.15;

    final t = (band + grain).clamp(0.0, 1.0);
    return _lerp(p.dark, p.light, t);
  }

  /// Slate: diagonal cleavage planes
  int _slate(int x, int y, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Diagonal layering
    final angle = x * 0.7 + y;
    final layer = sin(angle * s * 12) * 0.4 + 0.5;

    // Fine parallel lines
    final lines = sin(angle * s * 40) * 0.1;

    // Subtle variation
    final vary = _noise(x * s * 3, y * s * 3, rng.seed + 500) * 0.15 * v;

    final t = (layer + lines + vary).clamp(0.0, 1.0);
    return _lerp(p.dark, p.light, t);
  }

  /// Limestone: fossiliferous texture
  int _limestone(int x, int y, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Base texture
    final base = _turbulence(x * s * 2, y * s * 2, 2, seed: rng.seed + 600) * 0.5 + 0.5;

    // Fossil-like spots
    final spots = _cellNoise(x * s * 4, y * s * 4, rng.seed + 700);

    int color = _lerp(p.dark, p.light, base);

    // Add lighter fossil areas
    if (spots > 0.7) {
      color = _lerp(color, p.light, (spots - 0.7) * 2);
    }

    return color;
  }

  /// Obsidian: glassy with flow patterns
  int _obsidian(int x, int y, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Flow banding
    final flow = sin(_turbulence(x * s, y * s * 2, 3, seed: rng.seed + 800) * pi * 3);
    final flowT = flow * 0.15 + 0.5;

    // Glassy reflection
    final reflect = _noise(x * s * 0.5, y * s * 0.5, rng.seed + 900) * 0.1;

    final t = (flowT + reflect).clamp(0.0, 1.0);
    int color = _lerp(p.dark, p.base, t);

    // Occasional sheen
    if (reflect > 0.05) {
      color = _lerp(color, p.light, reflect * 2);
    }

    return color;
  }

  /// Cobblestone: rounded individual stones
  int _cobblestone(int x, int y, int w, int h, double s, _StonePalette p, double v, _StoneRandom rng) {
    // Cell noise for stone boundaries
    final cell = _voronoiDist(x * s * 6, y * s * 6, rng.seed + 1000);

    // Each cell gets its own color variation
    final cellId = _voronoiId(x * s * 6, y * s * 6, rng.seed + 1000);
    final stoneHue = _hash(cellId) * v * 0.3;

    // Base stone color with variation
    int color = _lerp(p.dark, p.light, 0.4 + stoneHue);

    // Mortar between stones (cell edges)
    if (cell < 0.1) {
      color = _lerp(color, p.dark, (0.1 - cell) * 5);
    }

    // Rounded highlight on stones
    if (cell > 0.4) {
      final highlight = (cell - 0.4) * 0.3;
      color = _adjustBrightness(color, highlight);
    }

    return color;
  }

  int _applyRoughness(int color, int x, int y, double amount, int seed) {
    final noise = _noise(x * 0.2, y * 0.2, seed + 2000) * amount * 0.2;
    return _adjustBrightness(color, noise);
  }

  int _applyCracks(int color, int x, int y, double amount, int darkColor, int seed) {
    // Generate crack pattern
    final crack1 = _noise(x * 0.05, y * 0.3, seed + 3000).abs();
    final crack2 = _noise(x * 0.3, y * 0.05, seed + 3100).abs();
    final crack = max(crack1, crack2);

    // Threshold for crack visibility
    final threshold = 1.0 - amount * 0.15;
    if (crack > threshold) {
      final strength = (crack - threshold) / (1.0 - threshold);
      return _lerp(color, darkColor, strength * 0.7);
    }
    return color;
  }

  int _applyWeathering(int color, int x, int y, double amount, int seed) {
    final weather = _turbulence(x * 0.03, y * 0.03, 2, seed: seed + 4000);

    if (weather > 0.5) {
      // Weathered areas: lighter, less saturated
      final strength = (weather - 0.5) * 2 * amount;
      return _desaturate(_adjustBrightness(color, strength * 0.15), strength * 0.3);
    }
    return color;
  }

  // ============ Noise Functions ============

  double _noise(double x, double y, int seed) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    final u = fx * fx * (3 - 2 * fx);
    final v = fy * fy * (3 - 2 * fy);

    final a = _hash2(ix, iy, seed);
    final b = _hash2(ix + 1, iy, seed);
    final c = _hash2(ix, iy + 1, seed);
    final d = _hash2(ix + 1, iy + 1, seed);

    return a + u * (b - a) + v * (c - a) + u * v * (a - b - c + d);
  }

  double _turbulence(double x, double y, int octaves, {required int seed}) {
    double value = 0;
    double amp = 1;
    double freq = 1;
    double maxAmp = 0;

    for (int i = 0; i < octaves; i++) {
      value += _noise(x * freq, y * freq, seed + i * 100).abs() * amp;
      maxAmp += amp;
      amp *= 0.5;
      freq *= 2;
    }
    return value / maxAmp;
  }

  double _cellNoise(double x, double y, int seed) {
    final ix = x.floor();
    final iy = y.floor();
    double minDist = 999.0;

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final cx = ix + dx + _hash2(ix + dx, iy + dy, seed);
        final cy = iy + dy + _hash2(ix + dx, iy + dy, seed + 50);
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        minDist = min(minDist, dist);
      }
    }
    return minDist.clamp(0.0, 1.0);
  }

  double _voronoiDist(double x, double y, int seed) {
    return _cellNoise(x, y, seed);
  }

  int _voronoiId(double x, double y, int seed) {
    final ix = x.floor();
    final iy = y.floor();
    double minDist = 999.0;
    int cellId = 0;

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final cx = ix + dx + _hash2(ix + dx, iy + dy, seed);
        final cy = iy + dy + _hash2(ix + dx, iy + dy, seed + 50);
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        if (dist < minDist) {
          minDist = dist;
          cellId = (ix + dx) * 73856093 ^ (iy + dy) * 19349663;
        }
      }
    }
    return cellId;
  }

  double _hash2(int x, int y, int seed) {
    var h = x * 374761393 + y * 668265263 + seed;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h & 0x7FFFFFFF) / 0x7FFFFFFF;
  }

  double _hash(int n) {
    var x = n;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    return (x & 0xFFFFFF) / 0xFFFFFF;
  }

  // ============ Color Functions ============

  int _lerp(int a, int b, double t) {
    t = t.clamp(0.0, 1.0);
    final aR = (a >> 16) & 0xFF;
    final aG = (a >> 8) & 0xFF;
    final aB = a & 0xFF;
    final bR = (b >> 16) & 0xFF;
    final bG = (b >> 8) & 0xFF;
    final bB = b & 0xFF;

    final r = (aR + (bR - aR) * t).round();
    final g = (aG + (bG - aG) * t).round();
    final bl = (aB + (bB - aB) * t).round();

    return 0xFF000000 | (r << 16) | (g << 8) | bl;
  }

  int _adjustBrightness(int color, double amount) {
    var r = (color >> 16) & 0xFF;
    var g = (color >> 8) & 0xFF;
    var b = color & 0xFF;

    r = (r + amount * 255).round().clamp(0, 255);
    g = (g + amount * 255).round().clamp(0, 255);
    b = (b + amount * 255).round().clamp(0, 255);

    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  int _desaturate(int color, double amount) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    final gray = (r * 0.299 + g * 0.587 + b * 0.114).round();

    final nr = (r + (gray - r) * amount).round().clamp(0, 255);
    final ng = (g + (gray - g) * amount).round().clamp(0, 255);
    final nb = (b + (gray - b) * amount).round().clamp(0, 255);

    return 0xFF000000 | (nr << 16) | (ng << 8) | nb;
  }

  _StonePalette _getPalette(int type) {
    switch (type) {
      case 0: // Marble
        return const _StonePalette(
          base: 0xFFF0EDE8,
          dark: 0xFF7A7570,
          light: 0xFFFFFEFC,
          accent: 0xFFD4C5A9,
        );
      case 1: // Granite
        return const _StonePalette(
          base: 0xFF6B6B6B,
          dark: 0xFF2D2D2D,
          light: 0xFFB8B8B8,
          accent: 0xFFE8D0B8,
        );
      case 2: // Sandstone
        return const _StonePalette(
          base: 0xFFD4A574,
          dark: 0xFF8B6914,
          light: 0xFFF5E6D3,
          accent: 0xFFC47D32,
        );
      case 3: // Slate
        return const _StonePalette(
          base: 0xFF4A5568,
          dark: 0xFF1A202C,
          light: 0xFF718096,
          accent: 0xFF5A6B7A,
        );
      case 4: // Limestone
        return const _StonePalette(
          base: 0xFFE8DCC8,
          dark: 0xFFB8A888,
          light: 0xFFF8F4EC,
          accent: 0xFFD4C4A8,
        );
      case 5: // Obsidian
        return const _StonePalette(
          base: 0xFF1A1A1A,
          dark: 0xFF050505,
          light: 0xFF3A3A3A,
          accent: 0xFF2A2A3A,
        );
      case 6: // Cobblestone
        return const _StonePalette(
          base: 0xFF808080,
          dark: 0xFF404040,
          light: 0xFFA8A8A8,
          accent: 0xFF6B7B6B,
        );
      default:
        return _getPalette(0);
    }
  }
}

class _StonePalette {
  final int base;
  final int dark;
  final int light;
  final int accent;

  const _StonePalette({
    required this.base,
    required this.dark,
    required this.light,
    required this.accent,
  });
}

class _StoneRandom {
  final int seed;

  _StoneRandom(this.seed);
}
