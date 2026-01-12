part of 'effects.dart';

/// Effect that transforms pixels to look like realistic tree bark textures
class TreeBarkEffect extends Effect {
  TreeBarkEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.treeBark,
          parameters ??
              const {
                'barkType': 0,
                'roughness': 0.7,
                'grooving': 0.6,
                'colorVariation': 0.5,
                'scale': 0.5,
                'weathering': 0.4,
                'mossAmount': 0.1,
                'crackiness': 0.3,
                'lightDirection': 0.5, // New: lighting angle (0-1 maps to 0-360°)
                'depth': 0.5, // New: 3D depth perception
                'peeling': 0.0, // New: bark peeling effect
              },
        );

  // Permutation table for improved Perlin noise
  late List<int> _perm;

  // Gradient vectors for 2D Perlin noise
  static const List<List<double>> _gradients = [
    [1.0, 0.0],
    [0.0, 1.0],
    [-1.0, 0.0],
    [0.0, -1.0],
    [0.7071, 0.7071],
    [-0.7071, 0.7071],
    [0.7071, -0.7071],
    [-0.7071, -0.7071],
  ];

  void _initPermutationTable(int seed) {
    final random = Random(seed);
    _perm = List<int>.generate(512, (i) => i < 256 ? i : 0);
    // Shuffle first 256 entries
    for (int i = 255; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _perm[i];
      _perm[i] = _perm[j];
      _perm[j] = temp;
    }
    // Duplicate for overflow handling
    for (int i = 0; i < 256; i++) {
      _perm[256 + i] = _perm[i];
    }
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'barkType': 0,
      'roughness': 0.7,
      'grooving': 0.6,
      'colorVariation': 0.5,
      'scale': 0.5,
      'weathering': 0.4,
      'mossAmount': 0.1,
      'crackiness': 0.3,
      'lightDirection': 0.5,
      'depth': 0.5,
      'peeling': 0.0,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'barkType': {
        'label': 'Bark Type',
        'description': 'Select the type of tree bark texture.',
        'type': 'select',
        'options': {
          0: 'Oak (Rough)',
          1: 'Birch (Smooth)',
          2: 'Pine (Plated)',
          3: 'Redwood (Fibrous)',
          4: 'Willow (Furrowed)',
          5: 'Palm (Ringed)',
          6: 'Cherry (Horizontal Lenticels)',
          7: 'Eucalyptus (Peeling)',
        },
      },
      'roughness': {
        'label': 'Surface Roughness',
        'description': 'Controls how rough and bumpy the bark surface appears.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'grooving': {
        'label': 'Vertical Grooves',
        'description': 'Controls the depth and prominence of vertical bark grooves.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorVariation': {
        'label': 'Color Variation',
        'description': 'Amount of natural color variation in the bark.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'scale': {
        'label': 'Texture Scale',
        'description': 'Size of bark texture features.  Smaller values create finer detail.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'weathering': {
        'label': 'Weathering',
        'description': 'Age and weathering effects on the bark surface.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'mossAmount': {
        'label': 'Moss & Lichen',
        'description': 'Amount of moss and lichen growth on the bark.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'crackiness': {
        'label': 'Cracks & Fissures',
        'description': 'Amount of cracks and deep fissures in the bark.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'lightDirection': {
        'label': 'Light Direction',
        'description': 'Direction of simulated light for 3D depth effect.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'depth': {
        'label': 'Depth Intensity',
        'description': 'Intensity of the 3D depth/shadow effect.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'peeling': {
        'label': 'Bark Peeling',
        'description': 'Amount of peeling bark effect (works best with Birch/Eucalyptus).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    // Initialize permutation table for consistent noise
    _initPermutationTable(42);

    // Get parameters
    final barkType = (parameters['barkType'] as int).clamp(0, 7);
    final roughness = (parameters['roughness'] as double).clamp(0.0, 1.0);
    final grooving = (parameters['grooving'] as double).clamp(0.0, 1.0);
    final colorVariation = (parameters['colorVariation'] as double).clamp(0.0, 1.0);
    final scale = (parameters['scale'] as double).clamp(0.01, 1.0);
    final weathering = (parameters['weathering'] as double).clamp(0.0, 1.0);
    final mossAmount = (parameters['mossAmount'] as double).clamp(0.0, 1.0);
    final crackiness = (parameters['crackiness'] as double).clamp(0.0, 1.0);
    final lightDirection = (parameters['lightDirection'] as double).clamp(0.0, 1.0);
    final depth = (parameters['depth'] as double).clamp(0.0, 1.0);
    final peeling = (parameters['peeling'] as double).clamp(0.0, 1.0);

    // Create result buffer
    final result = Uint32List(pixels.length);

    // Get bark colors based on type
    final barkColors = _getBarkColors(barkType);

    // Pre-calculate light vector
    final lightAngle = lightDirection * 2 * pi;
    final lightX = cos(lightAngle);
    final lightY = sin(lightAngle);

    // Calculate texture scale factor
    final textureScale = 0.05 / (scale + 0.05);

    // Pre-compute height map for lighting calculations
    final heightMap = _generateHeightMap(width, height, textureScale, barkType, grooving, roughness);

    // Process each pixel
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final originalPixel = pixels[index];

        // Skip transparent pixels
        final originalAlpha = (originalPixel >> 24) & 0xFF;
        if (originalAlpha == 0) {
          result[index] = 0;
          continue;
        }

        // Calculate bark texture for this pixel
        final barkColor = _calculateBarkTexture(
          x: x,
          y: y,
          width: width,
          height: height,
          colors: barkColors,
          barkType: barkType,
          roughness: roughness,
          grooving: grooving,
          colorVariation: colorVariation,
          textureScale: textureScale,
          weathering: weathering,
          mossAmount: mossAmount,
          crackiness: crackiness,
          lightX: lightX,
          lightY: lightY,
          depth: depth,
          peeling: peeling,
          heightMap: heightMap,
        );

        // Preserve original alpha
        final finalColor = (originalAlpha << 24) | (barkColor & 0x00FFFFFF);
        result[index] = finalColor;
      }
    }

    return result;
  }

  // Generate height map for normal/lighting calculations
  List<double> _generateHeightMap(
    int width,
    int height,
    double scale,
    int barkType,
    double grooving,
    double roughness,
  ) {
    final heightMap = List<double>.filled(width * height, 0.0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;

        // Base height from bark noise
        var heightValue = _fbm(x * scale, y * scale, 4, 0.5, 2.0, 0);

        // Add groove contribution
        if (grooving > 0) {
          final grooveHeight = _calculateGrooveHeight(x.toDouble(), y.toDouble(), scale, barkType);
          heightValue += grooveHeight * grooving;
        }

        // Add roughness detail
        if (roughness > 0) {
          final roughnessHeight = _fbm(x * scale * 4, y * scale * 4, 2, 0.5, 2.0, 1);
          heightValue += roughnessHeight * roughness * 0.3;
        }

        heightMap[index] = heightValue;
      }
    }

    return heightMap;
  }

  // Improved Perlin noise implementation
  double _perlinNoise(double x, double y, int seed) {
    // Offset by seed for variation
    x += seed * 17.0;
    y += seed * 31.0;

    // Grid cell coordinates
    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;

    // Interpolation weights
    final sx = _smootherstep(x - x0);
    final sy = _smootherstep(y - y0);

    // Get gradient indices
    final i00 = _perm[(_perm[x0 & 255] + y0) & 255] & 7;
    final i10 = _perm[(_perm[x1 & 255] + y0) & 255] & 7;
    final i01 = _perm[(_perm[x0 & 255] + y1) & 255] & 7;
    final i11 = _perm[(_perm[x1 & 255] + y1) & 255] & 7;

    // Compute dot products
    final n00 = _dot(_gradients[i00], x - x0, y - y0);
    final n10 = _dot(_gradients[i10], x - x1, y - y0);
    final n01 = _dot(_gradients[i01], x - x0, y - y1);
    final n11 = _dot(_gradients[i11], x - x1, y - y1);

    // Bilinear interpolation
    final nx0 = _lerp(n00, n10, sx);
    final nx1 = _lerp(n01, n11, sx);

    return _lerp(nx0, nx1, sy);
  }

  // Fractal Brownian Motion for natural-looking noise
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

  // Ridged multifractal noise for cracks
  double _ridgedNoise(double x, double y, int octaves, double persistence, double lacunarity, int seed) {
    double total = 0.0;
    double amplitude = 1.0;
    double frequency = 1.0;
    double maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
      final noise = _perlinNoise(x * frequency, y * frequency, seed + i);
      // Ridge transformation:  1 - |noise|
      total += (1.0 - noise.abs()) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= lacunarity;
    }

    return total / maxValue;
  }

  // Voronoi/Worley noise for cellular patterns (useful for some bark types)
  double _voronoiNoise(double x, double y, int seed) {
    final ix = x.floor();
    final iy = y.floor();

    double minDist = double.infinity;

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final cx = ix + dx;
        final cy = iy + dy;

        // Pseudo-random point position within cell
        final hash = _perm[(_perm[(cx & 255)] + (cy & 255)) & 255];
        final px = cx + (hash / 255.0);
        final py = cy + (_perm[(hash + seed) & 255] / 255.0);

        final dist = sqrt(pow(x - px, 2) + pow(y - py, 2));
        minDist = min(minDist, dist);
      }
    }

    return minDist;
  }

  double _smootherstep(double t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  double _lerp(double a, double b, double t) {
    return a + t * (b - a);
  }

  double _dot(List<double> g, double x, double y) {
    return g[0] * x + g[1] * y;
  }

  // Get color palette for different bark types
  _BarkColors _getBarkColors(int barkType) {
    switch (barkType) {
      case 0: // Oak - Dark, rough bark
        return _BarkColors(
          baseColor: const Color(0xFF5D4037),
          darkColor: const Color(0xFF3E2723),
          lightColor: const Color(0xFF8D6E63),
          accentColor: const Color(0xFF6D4C41),
          highlightColor: const Color(0xFFA1887F),
          shadowColor: const Color(0xFF2E1B12),
        );
      case 1: // Birch - Light, smooth bark with dark horizontal lines
        return _BarkColors(
          baseColor: const Color(0xFFF5F5DC),
          darkColor: const Color(0xFF2E2E2E),
          lightColor: const Color(0xFFFFFFFF),
          accentColor: const Color(0xFFE8E8D0),
          highlightColor: const Color(0xFFFFFFFF),
          shadowColor: const Color(0xFFBDBDAA),
        );
      case 2: // Pine - Orange-brown plated bark
        return _BarkColors(
          baseColor: const Color(0xFFD4A574),
          darkColor: const Color(0xFF8B4513),
          lightColor: const Color(0xFFF4E4BC),
          accentColor: const Color(0xFFCD853F),
          highlightColor: const Color(0xFFFFE4C4),
          shadowColor: const Color(0xFF5D3A1A),
        );
      case 3: // Redwood - Reddish fibrous bark
        return _BarkColors(
          baseColor: const Color(0xFFA0522D),
          darkColor: const Color(0xFF6B1C1C),
          lightColor: const Color(0xFFDEB887),
          accentColor: const Color(0xFFB22222),
          highlightColor: const Color(0xFFE6A88C),
          shadowColor: const Color(0xFF4A1010),
        );
      case 4: // Willow - Gray-brown furrowed bark
        return _BarkColors(
          baseColor: const Color(0xFF696969),
          darkColor: const Color(0xFF2F4F4F),
          lightColor: const Color(0xFFA9A9A9),
          accentColor: const Color(0xFF708090),
          highlightColor: const Color(0xFFC0C0C0),
          shadowColor: const Color(0xFF1C3030),
        );
      case 5: // Palm - Ringed texture
        return _BarkColors(
          baseColor: const Color(0xFF8B7355),
          darkColor: const Color(0xFF654321),
          lightColor: const Color(0xFFDEB887),
          accentColor: const Color(0xFFBC9A6A),
          highlightColor: const Color(0xFFF5DEB3),
          shadowColor: const Color(0xFF3D2914),
        );
      case 6: // Cherry - Horizontal lenticels
        return _BarkColors(
          baseColor: const Color(0xFF8B4513),
          darkColor: const Color(0xFF5D2906),
          lightColor: const Color(0xFFCD853F),
          accentColor: const Color(0xFFA0522D),
          highlightColor: const Color(0xFFDEB887),
          shadowColor: const Color(0xFF3D1F0D),
        );
      case 7: // Eucalyptus - Smooth, peeling, multicolored
        return _BarkColors(
          baseColor: const Color(0xFFC4B7A6),
          darkColor: const Color(0xFF6B8E6B),
          lightColor: const Color(0xFFF5F5DC),
          accentColor: const Color(0xFFE6D5B8),
          highlightColor: const Color(0xFFFFFFE0),
          shadowColor: const Color(0xFF8B7355),
        );
      default:
        return _getBarkColors(0);
    }
  }

  // Calculate groove height for height map
  double _calculateGrooveHeight(double x, double y, double scale, int barkType) {
    switch (barkType) {
      case 0: // Oak - irregular vertical grooves
        final noise = _fbm(x * scale * 0.3, y * scale * 0.1, 2, 0.5, 2.0, 20);
        final groove = sin((x + noise * 15) * scale * 0.8);
        return pow(groove.abs(), 0.5) - 0.5;

      case 1: // Birch - minimal grooves, horizontal emphasis
        return _fbm(x * scale * 0.1, y * scale * 0.5, 2, 0.5, 2.0, 21) * 0.2;

      case 2: // Pine - plated grooves
        final plateX = _voronoiNoise(x * scale * 0.3, y * scale * 0.15, 22);
        return plateX * 2 - 1;

      case 3: // Redwood - deep vertical furrows
        final furrow = sin(x * scale * 0.5) * 0.7;
        final variation = _fbm(x * scale * 0.2, y * scale * 2, 2, 0.5, 2.0, 23) * 0.3;
        return furrow + variation;

      case 4: // Willow - deep irregular furrows
        final noise = _fbm(x * scale * 0.2, y * scale * 0.3, 3, 0.5, 2.0, 24);
        final furrow = sin((x + noise * 20) * scale * 0.4);
        return pow(furrow.abs(), 0.3) - 0.5;

      case 5: // Palm - horizontal rings
        final ring = sin(y * scale * 1.5);
        return ring * 0.5;

      case 6: // Cherry - subtle horizontal bands
        final band = sin(y * scale * 0.8) * 0.3;
        return band;

      case 7: // Eucalyptus - smooth with peeling edges
        return _fbm(x * scale * 0.2, y * scale * 0.2, 2, 0.5, 2.0, 27) * 0.3;

      default:
        return 0.0;
    }
  }

  // Calculate the bark texture for a specific pixel
  int _calculateBarkTexture({
    required int x,
    required int y,
    required int width,
    required int height,
    required _BarkColors colors,
    required int barkType,
    required double roughness,
    required double grooving,
    required double colorVariation,
    required double textureScale,
    required double weathering,
    required double mossAmount,
    required double crackiness,
    required double lightX,
    required double lightY,
    required double depth,
    required double peeling,
    required List<double> heightMap,
  }) {
    final fx = x.toDouble();
    final fy = y.toDouble();

    // Generate base bark pattern
    final barkPattern = _generateBarkPattern(fx, fy, textureScale, barkType);

    // Calculate cracks using ridged noise
    double crackPattern = 0.0;
    if (crackiness > 0) {
      crackPattern = _calculateCrackPattern(fx, fy, textureScale, crackiness);
    }

    // Calculate peeling effect
    double peelingPattern = 0.0;
    if (peeling > 0) {
      peelingPattern = _calculatePeelingPattern(fx, fy, textureScale, barkType, peeling);
    }

    // Calculate normal from height map for lighting
    final normal = _calculateNormal(x, y, width, height, heightMap);

    // Calculate lighting intensity
    final lightIntensity = _calculateLighting(normal, lightX, lightY, depth);

    // Combine patterns to determine base color
    var pattern = barkPattern;

    // Darken cracks significantly
    if (crackPattern > 0.7) {
      pattern *= (1.0 - (crackPattern - 0.7) * 3.0).clamp(0.1, 1.0);
    }

    // Select base color based on pattern
    Color baseColor = _selectBaseColor(colors, pattern, barkType);

    // Apply bark-type specific effects
    baseColor = _applyBarkTypeEffects(baseColor, fx, fy, barkType, textureScale, colors);

    // Apply peeling effect (lighter exposed wood underneath)
    if (peelingPattern > 0.6 && peeling > 0) {
      final peelIntensity = ((peelingPattern - 0.6) * 2.5 * peeling).clamp(0.0, 1.0);
      baseColor = Color.lerp(baseColor, colors.lightColor, peelIntensity)!;
    }

    // Apply color variation using low-frequency noise
    if (colorVariation > 0) {
      baseColor = _applyColorVariation(baseColor, fx, fy, colorVariation);
    }

    // Apply weathering (desaturation and lightening)
    if (weathering > 0) {
      baseColor = _applyWeathering(baseColor, fx, fy, textureScale, weathering);
    }

    // Apply moss and lichen
    if (mossAmount > 0) {
      baseColor = _applyMoss(baseColor, fx, fy, textureScale, mossAmount);
    }

    // Apply lighting
    baseColor = _applyLighting(baseColor, lightIntensity, colors);

    return baseColor.value;
  }

  // Generate base bark pattern using appropriate noise for bark type
  double _generateBarkPattern(double x, double y, double scale, int barkType) {
    switch (barkType) {
      case 0: // Oak - Rough, irregular
        final noise1 = _fbm(x * scale * 2, y * scale * 0.5, 4, 0.5, 2.0, 0);
        final noise2 = _fbm(x * scale * 4, y * scale * 1, 3, 0.5, 2.0, 1);
        return ((noise1 * 0.6 + noise2 * 0.4) + 1) * 0.5;

      case 1: // Birch - Smooth with horizontal features
        final horizontal = sin(y * scale * 15) * 0.2;
        final noise = _fbm(x * scale * 0.3, y * scale * 1.5, 3, 0.5, 2.0, 0);
        return ((noise * 0.8 + horizontal) + 1) * 0.5;

      case 2: // Pine - Plated, scaly pattern
        final plate = _voronoiNoise(x * scale * 0.4, y * scale * 0.2, 0);
        final detail = _fbm(x * scale * 3, y * scale * 1.5, 3, 0.5, 2.0, 1);
        return (plate * 0.7 + detail * 0.3).clamp(0.0, 1.0);

      case 3: // Redwood - Fibrous, strong vertical emphasis
        final vertical = _fbm(x * scale * 0.2, y * scale * 4, 4, 0.6, 2.0, 0);
        final fiber = _fbm(x * scale * 1, y * scale * 8, 3, 0.5, 2.0, 1);
        return ((vertical * 0.5 + fiber * 0.5) + 1) * 0.5;

      case 4: // Willow - Deep furrows
        final noise = _fbm(x * scale * 0.3, y * scale * 0.5, 3, 0.5, 2.0, 0);
        final furrow = sin((x + noise * 20) * scale * 0.6);
        return (pow(furrow.abs(), 0.4) + noise * 0.3).clamp(0.0, 1.0);

      case 5: // Palm - Horizontal rings
        final ring = sin(y * scale * 2) * 0.5 + 0.5;
        final noise = _fbm(x * scale * 0.5, y * scale * 0.3, 2, 0.5, 2.0, 0);
        return (ring * 0.7 + noise * 0.3).clamp(0.0, 1.0);

      case 6: // Cherry - Smooth with horizontal lenticels
        final base = _fbm(x * scale * 0.2, y * scale * 0.2, 3, 0.5, 2.0, 0);
        final lenticel = _calculateLenticels(x, y, scale);
        return ((base + 1) * 0.5 * 0.8 + lenticel * 0.2).clamp(0.0, 1.0);

      case 7: // Eucalyptus - Smooth, multicolored patches
        final patch = _voronoiNoise(x * scale * 0.15, y * scale * 0.15, 0);
        final smooth = _fbm(x * scale * 0.1, y * scale * 0.1, 2, 0.5, 2.0, 1);
        return (patch * 0.6 + smooth * 0.4).clamp(0.0, 1.0);

      default:
        return (_fbm(x * scale, y * scale, 4, 0.5, 2.0, 0) + 1) * 0.5;
    }
  }

  // Calculate horizontal lenticels for cherry bark
  double _calculateLenticels(double x, double y, double scale) {
    final spacing = 8.0 / scale;
    final yMod = y % spacing;
    final noise = _perlinNoise(x * scale * 0.5, y * scale * 0.1, 50);

    // Create horizontal dash pattern
    final dashPhase = (x + noise * 10) * scale * 0.3;
    final inDash = (sin(dashPhase) > 0.3) ? 1.0 : 0.0;

    // Narrow horizontal band
    final bandWidth = 1.5;
    final inBand = (yMod < bandWidth) ? 1.0 : 0.0;

    return inDash * inBand;
  }

  // Calculate crack pattern using ridged noise
  double _calculateCrackPattern(double x, double y, double scale, double intensity) {
    final crack1 = _ridgedNoise(x * scale * 0.3, y * scale * 1.5, 3, 0.5, 2.0, 30);
    final crack2 = _ridgedNoise(x * scale * 0.8, y * scale * 0.4, 2, 0.5, 2.0, 31);

    final crackValue = (crack1 * 0.7 + crack2 * 0.3);

    // Threshold to create distinct cracks
    return crackValue > (1.0 - intensity * 0.5) ? crackValue : 0.0;
  }

  // Calculate peeling bark pattern
  double _calculatePeelingPattern(double x, double y, double scale, int barkType, double intensity) {
    // Peeling tends to happen in patches with curled edges
    final patchNoise = _voronoiNoise(x * scale * 0.2, y * scale * 0.1, 40);
    final edgeNoise = _fbm(x * scale * 0.5, y * scale * 0.3, 3, 0.5, 2.0, 41);

    // Create peeling edge effect
    final peelEdge = (patchNoise + edgeNoise * 0.3);

    return peelEdge * intensity;
  }

  // Calculate surface normal from height map
  List<double> _calculateNormal(int x, int y, int width, int height, List<double> heightMap) {
    // Sample neighboring heights
    final left = x > 0 ? heightMap[y * width + (x - 1)] : heightMap[y * width + x];
    final right = x < width - 1 ? heightMap[y * width + (x + 1)] : heightMap[y * width + x];
    final up = y > 0 ? heightMap[(y - 1) * width + x] : heightMap[y * width + x];
    final down = y < height - 1 ? heightMap[(y + 1) * width + x] : heightMap[y * width + x];

    // Calculate gradient
    final dx = right - left;
    final dy = down - up;

    // Normal vector (simplified - not fully normalized for performance)
    final length = sqrt(dx * dx + dy * dy + 1);
    return [-dx / length, -dy / length, 1.0 / length];
  }

  // Calculate lighting based on normal and light direction
  double _calculateLighting(List<double> normal, double lightX, double lightY, double depth) {
    if (depth <= 0) return 0.5;

    // Light vector (coming from above at an angle)
    final lightZ = 0.7;
    final lightLength = sqrt(lightX * lightX + lightY * lightY + lightZ * lightZ);
    final lx = lightX / lightLength;
    final ly = lightY / lightLength;
    final lz = lightZ / lightLength;

    // Dot product for diffuse lighting
    final diffuse = (normal[0] * lx + normal[1] * ly + normal[2] * lz).clamp(0.0, 1.0);

    // Combine ambient and diffuse
    final ambient = 0.3;
    final lighting = ambient + (1.0 - ambient) * diffuse;

    // Apply depth intensity
    return 0.5 + (lighting - 0.5) * depth;
  }

  // Select base color based on pattern value
  Color _selectBaseColor(_BarkColors colors, double pattern, int barkType) {
    if (pattern < 0.25) {
      return Color.lerp(colors.shadowColor, colors.darkColor, pattern / 0.25)!;
    } else if (pattern < 0.5) {
      return Color.lerp(colors.darkColor, colors.baseColor, (pattern - 0.25) / 0.25)!;
    } else if (pattern < 0.75) {
      return Color.lerp(colors.baseColor, colors.accentColor, (pattern - 0.5) / 0.25)!;
    } else {
      return Color.lerp(colors.accentColor, colors.lightColor, (pattern - 0.75) / 0.25)!;
    }
  }

  // Apply bark-type specific visual effects
  Color _applyBarkTypeEffects(Color baseColor, double x, double y, int barkType, double scale, _BarkColors colors) {
    switch (barkType) {
      case 1: // Birch - Dark horizontal marks and peeling hints
        final horizontalLines = sin(y * scale * 20);
        final lineNoise = _perlinNoise(x * scale * 0.5, y * scale * 0.1, 100);
        if (horizontalLines > 0.75 + lineNoise * 0.2) {
          return Color.lerp(baseColor, colors.darkColor, 0.85)!;
        }
        break;

      case 2: // Pine - Reddish tint in plate centers
        final plateCenter = _voronoiNoise(x * scale * 0.4, y * scale * 0.2, 0);
        if (plateCenter < 0.3) {
          final hsv = HSVColor.fromColor(baseColor);
          final newHue = (hsv.hue + 8).clamp(0.0, 360.0);
          final newSat = (hsv.saturation * 1.2).clamp(0.0, 1.0);
          return hsv.withHue(newHue).withSaturation(newSat).toColor();
        }
        break;

      case 3: // Redwood - Enhanced reddish fibers
        final fiberEffect = _fbm(x * scale * 0.3, y * scale * 5, 2, 0.5, 2.0, 110);
        if (fiberEffect > 0.3) {
          return Color.lerp(baseColor, colors.accentColor, 0.4)!;
        }
        break;

      case 6: // Cherry - Shiny lenticels
        final lenticel = _calculateLenticels(x, y, scale);
        if (lenticel > 0.5) {
          return Color.lerp(baseColor, colors.darkColor, 0.6)!;
        }
        break;

      case 7: // Eucalyptus - Multicolored patches
        final colorPatch = _voronoiNoise(x * scale * 0.12, y * scale * 0.12, 120);
        if (colorPatch < 0.4) {
          // Green-gray patches (exposed inner bark)
          return Color.lerp(baseColor, const Color(0xFF8FAF8F), 0.4)!;
        } else if (colorPatch < 0.6) {
          // Tan/orange patches
          return Color.lerp(baseColor, const Color(0xFFDEB887), 0.3)!;
        }
        break;
    }

    return baseColor;
  }

  // Apply color variation
  Color _applyColorVariation(Color baseColor, double x, double y, double intensity) {
    final variation = _fbm(x * 0.02, y * 0.02, 2, 0.5, 2.0, 200);

    final hsv = HSVColor.fromColor(baseColor);
    final valueChange = variation * intensity * 0.25;
    final satChange = variation * intensity * 0.1;
    final hueChange = variation * intensity * 5;

    return hsv
        .withValue((hsv.value + valueChange).clamp(0.0, 1.0))
        .withSaturation((hsv.saturation + satChange).clamp(0.0, 1.0))
        .withHue((hsv.hue + hueChange) % 360)
        .toColor();
  }

  // Apply weathering effects
  Color _applyWeathering(Color baseColor, double x, double y, double scale, double intensity) {
    final weatherNoise = _fbm(x * scale * 0.3, y * scale * 0.2, 3, 0.5, 2.0, 210);
    final weatherAmount = ((weatherNoise + 1) * 0.5 * intensity).clamp(0.0, 1.0);

    // Weathering desaturates and lightens
    final hsv = HSVColor.fromColor(baseColor);
    final newSat = hsv.saturation * (1.0 - weatherAmount * 0.5);
    final newValue = hsv.value + weatherAmount * 0.1;

    return hsv.withSaturation(newSat.clamp(0.0, 1.0)).withValue(newValue.clamp(0.0, 1.0)).toColor();
  }

  // Apply moss and lichen
  Color _applyMoss(Color baseColor, double x, double y, double scale, double amount) {
    // Moss grows in patches
    final mossNoise = _fbm(x * scale * 0.25, y * scale * 0.25, 3, 0.5, 2.0, 220);
    final lichNoise = _fbm(x * scale * 0.4, y * scale * 0.4, 2, 0.5, 2.0, 221);

    final mossThreshold = 1.0 - amount;

    if (mossNoise > mossThreshold) {
      final mossIntensity = ((mossNoise - mossThreshold) / amount).clamp(0.0, 0.8);
      final mossColor = Color.fromARGB(255, 70, 100, 50); // Dark green moss
      baseColor = Color.lerp(baseColor, mossColor, mossIntensity)!;
    }

    if (lichNoise > mossThreshold + 0.1) {
      final lichIntensity = ((lichNoise - mossThreshold - 0.1) / amount).clamp(0.0, 0.5);
      final lichColor = Color.fromARGB(255, 180, 190, 150); // Pale green-gray lichen
      baseColor = Color.lerp(baseColor, lichColor, lichIntensity * amount)!;
    }

    return baseColor;
  }

  // Apply lighting to final color
  Color _applyLighting(Color baseColor, double lightIntensity, _BarkColors colors) {
    if (lightIntensity < 0.5) {
      // In shadow
      final shadowAmount = (0.5 - lightIntensity) * 2;
      return Color.lerp(baseColor, colors.shadowColor, shadowAmount * 0.5)!;
    } else {
      // In light
      final highlightAmount = (lightIntensity - 0.5) * 2;
      return Color.lerp(baseColor, colors.highlightColor, highlightAmount * 0.3)!;
    }
  }
}

// Enhanced bark color palette
class _BarkColors {
  final Color baseColor;
  final Color darkColor;
  final Color lightColor;
  final Color accentColor;
  final Color highlightColor;
  final Color shadowColor;

  _BarkColors({
    required this.baseColor,
    required this.darkColor,
    required this.lightColor,
    required this.accentColor,
    required this.highlightColor,
    required this.shadowColor,
  });
}
