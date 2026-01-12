part of 'effects.dart';

// Helper class to store texture data
class _GroundTexture {
  final String name;
  final int size; // a square texture, so size x size
  final List<int> data; // color data in 0xAARRGGBB format
  final bool hasDepth; // whether to apply depth/height variation
  final double defaultScale; // recommended scale for this texture

  const _GroundTexture(
    this.name,
    this.size,
    this.data, {
    this.hasDepth = false,
    this.defaultScale = 16.0,
  });
}

/// Effect that applies a predefined ground texture to the image.
class GroundTextureEffect extends Effect {
  GroundTextureEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.groundTexture,
          parameters ??
              const {
                'textureType': 0,
                'scale': 16.0,
                'blend': 0.75,
                'blendMode': 0,
                'offsetX': 0.0,
                'offsetY': 0.0,
                'noiseAmount': 0.1,
                'rotation': 0,
                'depthIntensity': 0.3,
                'colorTint': 0,
                'seamlessBlend': true,
              },
        );

  // Static map holding all available textures
  static final Map<int, _GroundTexture> _textures = {
    0: const _GroundTexture('Dirt & Rocks', 8, _enhancedDirtAndRocks, hasDepth: true),
    1: const _GroundTexture('Mossy Stone', 8, _enhancedMossyStone, hasDepth: true),
    2: const _GroundTexture('Rich Sand', 8, _richSand),
    3: const _GroundTexture('Pebble Gravel', 8, _pebbleGravel, hasDepth: true),
    4: const _GroundTexture('Terracotta Clay', 8, _terracottaClay),
    5: const _GroundTexture('Red Bricks', 8, _redBricks, hasDepth: true, defaultScale: 24.0),
    6: const _GroundTexture('Stone Blocks', 8, _stoneBlocks, hasDepth: true, defaultScale: 24.0),
    7: const _GroundTexture('Cracked Ice', 8, _crackedIce, hasDepth: true),
    8: const _GroundTexture('Dark Cobblestone', 8, _darkCobblestone, hasDepth: true),
    9: const _GroundTexture('Sandy Gravel', 8, _sandyGravel),
    10: const _GroundTexture('Volcanic Rock', 8, _volcanicRock, hasDepth: true),
    // New textures
    11: const _GroundTexture('Grass', 8, _grassTexture, hasDepth: true),
    12: const _GroundTexture('Wood Planks', 8, _woodPlanks, hasDepth: true, defaultScale: 20.0),
    13: const _GroundTexture('Water/Waves', 8, _waterTexture, defaultScale: 12.0),
    14: const _GroundTexture('Snow', 8, _snowTexture),
    15: const _GroundTexture('Marble', 8, _marbleTexture, hasDepth: true),
    16: const _GroundTexture('Concrete', 8, _concreteTexture, hasDepth: true),
    17: const _GroundTexture('Mud', 8, _mudTexture, hasDepth: true),
    18: const _GroundTexture('Autumn Leaves', 8, _autumnLeavesTexture),
    19: const _GroundTexture('Metal Grate', 8, _metalGrateTexture, hasDepth: true, defaultScale: 16.0),
    20: const _GroundTexture('Hex Tiles', 8, _hexTilesTexture, hasDepth: true, defaultScale: 24.0),
  };

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'textureType': 0,
      'scale': 16.0,
      'blend': 0.75,
      'blendMode': 0,
      'offsetX': 0.0,
      'offsetY': 0.0,
      'noiseAmount': 0.1,
      'rotation': 0,
      'depthIntensity': 0.3,
      'colorTint': 0,
      'seamlessBlend': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'textureType': {
        'label': 'Texture Type',
        'description': 'Selects the ground texture to apply.',
        'type': 'select',
        'options': {for (var entry in _textures.entries) entry.key: entry.value.name},
      },
      'scale': {
        'label': 'Scale',
        'description': 'Controls the size of the texture pattern.',
        'type': 'slider',
        'min': 2.0,
        'max': 64.0,
        'divisions': 62,
      },
      'blend': {
        'label': 'Blend Intensity',
        'description': 'How much the texture is blended with the original image.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'blendMode': {
        'label': 'Blend Mode',
        'description': 'How the texture combines with the original.',
        'type': 'select',
        'options': {
          0: 'Normal',
          1: 'Multiply',
          2: 'Overlay',
          3: 'Soft Light',
          4: 'Hard Light',
          5: 'Color Burn',
          6: 'Screen',
        },
      },
      'offsetX': {
        'label': 'Offset X',
        'description': 'Horizontal offset of the texture pattern.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'offsetY': {
        'label': 'Offset Y',
        'description': 'Vertical offset of the texture pattern.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'noiseAmount': {
        'label': 'Noise/Variation',
        'description': 'Adds random variation to break up tiling patterns.',
        'type': 'slider',
        'min': 0.0,
        'max': 0.5,
        'divisions': 50,
      },
      'rotation': {
        'label': 'Rotation',
        'description': 'Rotates the texture pattern.',
        'type': 'select',
        'options': {
          0: '0°',
          1: '45°',
          2: '90°',
          3: '135°',
          4: '180°',
        },
      },
      'depthIntensity': {
        'label': 'Depth/Relief',
        'description': 'Intensity of 3D depth effect on textured surfaces.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorTint': {
        'label': 'Color Tint',
        'description': 'Apply a color tint to the texture.',
        'type': 'select',
        'options': {
          0: 'None',
          1: 'Warm',
          2: 'Cool',
          3: 'Sepia',
          4: 'Green',
          5: 'Blue',
        },
      },
      'seamlessBlend': {
        'label': 'Seamless Edges',
        'description': 'Smoothly blend texture at tile edges to reduce visible seams.',
        'type': 'toggle',
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final textureType = (parameters['textureType'] as num).toInt();
    final scale = (parameters['scale'] as num).toDouble().clamp(1.0, 256.0);
    final blend = (parameters['blend'] as num).toDouble().clamp(0.0, 1.0);
    final blendMode = (parameters['blendMode'] as num?)?.toInt() ?? 0;
    final offsetX = (parameters['offsetX'] as num?)?.toDouble() ?? 0.0;
    final offsetY = (parameters['offsetY'] as num?)?.toDouble() ?? 0.0;
    final noiseAmount = (parameters['noiseAmount'] as num?)?.toDouble() ?? 0.1;
    final rotation = (parameters['rotation'] as num?)?.toInt() ?? 0;
    final depthIntensity = (parameters['depthIntensity'] as num?)?.toDouble() ?? 0.3;
    final colorTint = (parameters['colorTint'] as num?)?.toInt() ?? 0;
    final seamlessBlend = (parameters['seamlessBlend'] as bool?) ?? true;

    final result = Uint32List.fromList(pixels);
    final texture = _textures[textureType];

    if (texture == null) {
      return result;
    }

    final textureData = texture.data;
    final textureSize = texture.size;

    // Precompute rotation values
    final rotationRad = rotation * pi / 4; // 0, 45, 90, 135, 180 degrees
    final cosR = cos(rotationRad);
    final sinR = sin(rotationRad);

    // Center point for rotation
    final centerX = width / 2;
    final centerY = height / 2;

    // Precompute offset in texture space
    final texOffsetX = (offsetX * textureSize).round();
    final texOffsetY = (offsetY * textureSize).round();

    // Create noise lookup for variation (seeded for consistency)
    final noiseMap = _generateNoiseMap(width, height, textureType);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final originalPixel = pixels[index];

        // Skip transparent pixels to preserve image shapes
        if (((originalPixel >> 24) & 0xFF) == 0) {
          continue;
        }

        // Apply rotation around center
        double rotX = x.toDouble();
        double rotY = y.toDouble();
        if (rotation != 0) {
          final dx = x - centerX;
          final dy = y - centerY;
          rotX = centerX + dx * cosR - dy * sinR;
          rotY = centerY + dx * sinR + dy * cosR;
        }

        // Calculate texture coordinates with offset
        int texX = ((rotX / scale * textureSize).floor() + texOffsetX) % textureSize;
        int texY = ((rotY / scale * textureSize).floor() + texOffsetY) % textureSize;

        // Handle negative modulo
        if (texX < 0) texX += textureSize;
        if (texY < 0) texY += textureSize;

        // Get texture pixel with optional seamless blending
        int texturePixel;
        if (seamlessBlend) {
          texturePixel = _getSeamlessTexturePixel(
            textureData,
            textureSize,
            rotX / scale * textureSize + texOffsetX,
            rotY / scale * textureSize + texOffsetY,
          );
        } else {
          texturePixel = textureData[texY * textureSize + texX];
        }

        // Apply noise variation
        if (noiseAmount > 0) {
          final noise = noiseMap[index];
          texturePixel = _applyNoise(texturePixel, noise, noiseAmount);
        }

        // Apply color tint
        if (colorTint > 0) {
          texturePixel = _applyColorTint(texturePixel, colorTint);
        }

        // Extract color components
        final origA = (originalPixel >> 24) & 0xFF;
        final origR = (originalPixel >> 16) & 0xFF;
        final origG = (originalPixel >> 8) & 0xFF;
        final origB = originalPixel & 0xFF;

        final texR = (texturePixel >> 16) & 0xFF;
        final texG = (texturePixel >> 8) & 0xFF;
        final texB = texturePixel & 0xFF;

        // Apply blend mode
        int blendedR, blendedG, blendedB;
        switch (blendMode) {
          case 1: // Multiply
            blendedR = (origR * texR / 255).round();
            blendedG = (origG * texG / 255).round();
            blendedB = (origB * texB / 255).round();
            break;
          case 2: // Overlay
            blendedR = _overlayBlend(origR, texR);
            blendedG = _overlayBlend(origG, texG);
            blendedB = _overlayBlend(origB, texB);
            break;
          case 3: // Soft Light
            blendedR = _softLightBlend(origR, texR);
            blendedG = _softLightBlend(origG, texG);
            blendedB = _softLightBlend(origB, texB);
            break;
          case 4: // Hard Light
            blendedR = _hardLightBlend(origR, texR);
            blendedG = _hardLightBlend(origG, texG);
            blendedB = _hardLightBlend(origB, texB);
            break;
          case 5: // Color Burn
            blendedR = _colorBurnBlend(origR, texR);
            blendedG = _colorBurnBlend(origG, texG);
            blendedB = _colorBurnBlend(origB, texB);
            break;
          case 6: // Screen
            blendedR = 255 - ((255 - origR) * (255 - texR) / 255).round();
            blendedG = 255 - ((255 - origG) * (255 - texG) / 255).round();
            blendedB = 255 - ((255 - origB) * (255 - texB) / 255).round();
            break;
          case 0: // Normal
          default:
            blendedR = texR;
            blendedG = texG;
            blendedB = texB;
            break;
        }

        // Apply depth effect if texture supports it
        if (texture.hasDepth && depthIntensity > 0) {
          final depthFactor = _calculateDepth(textureData, textureSize, texX, texY);
          final depthAdjust = ((depthFactor - 0.5) * depthIntensity * 60).round();
          blendedR = (blendedR + depthAdjust).clamp(0, 255);
          blendedG = (blendedG + depthAdjust).clamp(0, 255);
          blendedB = (blendedB + depthAdjust).clamp(0, 255);
        }

        // Final blend with original
        final newR = (origR * (1 - blend) + blendedR * blend).round().clamp(0, 255);
        final newG = (origG * (1 - blend) + blendedG * blend).round().clamp(0, 255);
        final newB = (origB * (1 - blend) + blendedB * blend).round().clamp(0, 255);

        result[index] = (origA << 24) | (newR << 16) | (newG << 8) | newB;
      }
    }

    return result;
  }

  /// Generate a noise map for variation
  List<double> _generateNoiseMap(int width, int height, int seed) {
    final random = Random(seed * 12345);
    return List.generate(width * height, (_) => random.nextDouble());
  }

  /// Get texture pixel with bilinear interpolation for seamless blending
  int _getSeamlessTexturePixel(List<int> textureData, int textureSize, double x, double y) {
    // Wrap coordinates
    x = x % textureSize;
    y = y % textureSize;
    if (x < 0) x += textureSize;
    if (y < 0) y += textureSize;

    final x0 = x.floor() % textureSize;
    final y0 = y.floor() % textureSize;
    final x1 = (x0 + 1) % textureSize;
    final y1 = (y0 + 1) % textureSize;

    final fx = x - x.floor();
    final fy = y - y.floor();

    final c00 = textureData[y0 * textureSize + x0];
    final c10 = textureData[y0 * textureSize + x1];
    final c01 = textureData[y1 * textureSize + x0];
    final c11 = textureData[y1 * textureSize + x1];

    return _bilinearInterpolate(c00, c10, c01, c11, fx, fy);
  }

  /// Bilinear interpolation between four colors
  int _bilinearInterpolate(int c00, int c10, int c01, int c11, double fx, double fy) {
    final r00 = (c00 >> 16) & 0xFF;
    final g00 = (c00 >> 8) & 0xFF;
    final b00 = c00 & 0xFF;

    final r10 = (c10 >> 16) & 0xFF;
    final g10 = (c10 >> 8) & 0xFF;
    final b10 = c10 & 0xFF;

    final r01 = (c01 >> 16) & 0xFF;
    final g01 = (c01 >> 8) & 0xFF;
    final b01 = c01 & 0xFF;

    final r11 = (c11 >> 16) & 0xFF;
    final g11 = (c11 >> 8) & 0xFF;
    final b11 = c11 & 0xFF;

    final r = _bilerp(r00, r10, r01, r11, fx, fy).round().clamp(0, 255);
    final g = _bilerp(g00, g10, g01, g11, fx, fy).round().clamp(0, 255);
    final b = _bilerp(b00, b10, b01, b11, fx, fy).round().clamp(0, 255);

    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  double _bilerp(int v00, int v10, int v01, int v11, double fx, double fy) {
    final top = v00 * (1 - fx) + v10 * fx;
    final bottom = v01 * (1 - fx) + v11 * fx;
    return top * (1 - fy) + bottom * fy;
  }

  /// Apply noise variation to a color
  int _applyNoise(int color, double noise, double amount) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    final noiseOffset = ((noise - 0.5) * 2 * amount * 50).round();

    final newR = (r + noiseOffset).clamp(0, 255);
    final newG = (g + noiseOffset).clamp(0, 255);
    final newB = (b + noiseOffset).clamp(0, 255);

    return 0xFF000000 | (newR << 16) | (newG << 8) | newB;
  }

  /// Apply color tint to texture
  int _applyColorTint(int color, int tintType) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    int newR = r, newG = g, newB = b;

    switch (tintType) {
      case 1: // Warm
        newR = min(255, r + 15);
        newG = min(255, g + 5);
        newB = max(0, b - 10);
        break;
      case 2: // Cool
        newR = max(0, r - 10);
        newG = min(255, g + 5);
        newB = min(255, b + 15);
        break;
      case 3: // Sepia
        newR = min(255, (r * 0.393 + g * 0.769 + b * 0.189).round());
        newG = min(255, (r * 0.349 + g * 0.686 + b * 0.168).round());
        newB = min(255, (r * 0.272 + g * 0.534 + b * 0.131).round());
        break;
      case 4: // Green
        newR = max(0, r - 15);
        newG = min(255, g + 20);
        newB = max(0, b - 10);
        break;
      case 5: // Blue
        newR = max(0, r - 15);
        newG = max(0, g - 5);
        newB = min(255, b + 25);
        break;
    }

    return 0xFF000000 | (newR << 16) | (newG << 8) | newB;
  }

  /// Calculate depth factor based on neighboring pixels
  double _calculateDepth(List<int> textureData, int textureSize, int x, int y) {
    // Simple height map based on luminance differences
    final current = _getLuminance(textureData[y * textureSize + x]);

    final left = _getLuminance(textureData[y * textureSize + ((x - 1 + textureSize) % textureSize)]);
    final right = _getLuminance(textureData[y * textureSize + ((x + 1) % textureSize)]);
    final top = _getLuminance(textureData[((y - 1 + textureSize) % textureSize) * textureSize + x]);
    final bottom = _getLuminance(textureData[((y + 1) % textureSize) * textureSize + x]);

    // Calculate gradient for fake lighting
    final dx = (right - left) / 2;
    final dy = (bottom - top) / 2;

    // Light from top-left
    return 0.5 + (dx * 0.7 - dy * 0.7);
  }

  double _getLuminance(int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
  }

  // Blend mode helpers
  int _overlayBlend(int base, int blend) {
    if (base < 128) {
      return (2 * base * blend / 255).round().clamp(0, 255);
    } else {
      return (255 - 2 * (255 - base) * (255 - blend) / 255).round().clamp(0, 255);
    }
  }

  int _softLightBlend(int base, int blend) {
    if (blend < 128) {
      return (base - (255 - 2 * blend) * base * (255 - base) / 255 / 255).round().clamp(0, 255);
    } else {
      final d = base < 64 ? ((16 * base - 12) * base + 4) * base / 255 : sqrt(base / 255) * 255;
      return (base + (2 * blend - 255) * (d - base) / 255).round().clamp(0, 255);
    }
  }

  int _hardLightBlend(int base, int blend) {
    return _overlayBlend(blend, base);
  }

  int _colorBurnBlend(int base, int blend) {
    if (blend == 0) return 0;
    return max(0, 255 - ((255 - base) * 255 / blend).round());
  }
}

// --- Texture Data Definitions (8x8 ARGB patterns) ---

// Enhanced Dirt and Rocks - more contrast and clearer rock shapes
const List<int> _enhancedDirtAndRocks = [
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF8A7A6A,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF514235,
  0xFF8A7A6A,
  0xFF4A3A2C,
  0xFF8A7A6A,
  0xFF514235,
  0xFF4A3A2C,
  0xFF5C4739,
  0xFF514235,
  0xFF8A7A6A,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF4A3A2C,
  0xFF5C4739,
  0xFF514235,
  0xFF8A7A6A,
  0xFF4A3A2C,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF514235,
  0xFF514235,
  0xFF8A7A6A,
  0xFF4A3A2C,
  0xFF5C4739,
  0xFF514235,
  0xFF4A3A2C,
  0xFF8A7A6A,
  0xFF5C4739,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF8A7A6A,
  0xFF514235,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF514235,
  0xFF8A7A6A,
  0xFF4A3A2C,
  0xFF514235,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF8A7A6A,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF514235,
  0xFF8A7A6A,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF514235,
  0xFF4A3A2C,
  0xFF8A7A6A,
  0xFF5C4739,
  0xFF4A3A2C,
  0xFF514235,
  0xFF4A3A2C,
  0xFF5C4739,
  0xFF8A7A6A,
  0xFF514235,
  0xFF4A3A2C,
  0xFF5C4739,
  0xFF8A7A6A,
];

// Enhanced Mossy Stone - more defined moss patches
const List<int> _enhancedMossyStone = [
  0xFF4A5A40,
  0xFF5A6B50,
  0xFF696969,
  0xFF505050,
  0xFF4A5A40,
  0xFF696969,
  0xFF505050,
  0xFF696969,
  0xFF5A6B50,
  0xFF3C4D35,
  0xFF4A5A40,
  0xFF696969,
  0xFF505050,
  0xFF4A5A40,
  0xFF3C4D35,
  0xFF505050,
  0xFF696969,
  0xFF4A5A40,
  0xFF5A6B50,
  0xFF505050,
  0xFF696969,
  0xFF505050,
  0xFF4A5A40,
  0xFF696969,
  0xFF505050,
  0xFF696969,
  0xFF3C4D35,
  0xFF4A5A40,
  0xFF505050,
  0xFF696969,
  0xFF5A6B50,
  0xFF505050,
  0xFF4A5A40,
  0xFF505050,
  0xFF696969,
  0xFF5A6B50,
  0xFF3C4D35,
  0xFF505050,
  0xFF696969,
  0xFF4A5A40,
  0xFF696969,
  0xFF4A5A40,
  0xFF505050,
  0xFF696969,
  0xFF5A6B50,
  0xFF4A5A40,
  0xFF505050,
  0xFF3C4D35,
  0xFF505050,
  0xFF3C4D35,
  0xFF4A5A40,
  0xFF5A6B50,
  0xFF696969,
  0xFF505050,
  0xFF4A5A40,
  0xFF696969,
  0xFF696969,
  0xFF505050,
  0xFF696969,
  0xFF4A5A40,
  0xFF505050,
  0xFF3C4D35,
  0xFF5A6B50,
  0xFF505050,
];

// Rich Sand - warmer tones with subtle highlights
const List<int> _richSand = [
  0xFFF0E0A0,
  0xFFE8D89C,
  0xFFD9C98E,
  0xFFF5E6A8,
  0xFFE4D396,
  0xFFF0E0A0,
  0xFFD9C98E,
  0xFFE8D89C,
  0xFFE8D89C,
  0xFFF5E6A8,
  0xFFE4D396,
  0xFFD9C98E,
  0xFFF0E0A0,
  0xFFE8D89C,
  0xFFF5E6A8,
  0xFFD9C98E,
  0xFFD9C98E,
  0xFFE4D396,
  0xFFF5E6A8,
  0xFFE8D89C,
  0xFFF0E0A0,
  0xFFD9C98E,
  0xFFE8D89C,
  0xFFF5E6A8,
  0xFFF5E6A8,
  0xFFF0E0A0,
  0xFFE8D89C,
  0xFFD9C98E,
  0xFFE4D396,
  0xFFF5E6A8,
  0xFFD9C98E,
  0xFFE8D89C,
  0xFFE4D396,
  0xFFD9C98E,
  0xFFF5E6A8,
  0xFFE8D89C,
  0xFFF0E0A0,
  0xFFE4D396,
  0xFFF5E6A8,
  0xFFD9C98E,
  0xFFF0E0A0,
  0xFFE8D89C,
  0xFFE4D396,
  0xFFF5E6A8,
  0xFFD9C98E,
  0xFFE8D89C,
  0xFFF0E0A0,
  0xFFE4D396,
  0xFFD9C98E,
  0xFFF5E6A8,
  0xFFE8D89C,
  0xFFE4D396,
  0xFFF0E0A0,
  0xFFD9C98E,
  0xFFF5E6A8,
  0xFFE8D89C,
  0xFFE8D89C,
  0xFFE4D396,
  0xFFF0E0A0,
  0xFFD9C98E,
  0xFFF5E6A8,
  0xFFE8D89C,
  0xFFE4D396,
  0xFFF0E0A0,
];

// Pebble Gravel - natural color variation
const List<int> _pebbleGravel = [
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
  0xFF9D9D9D,
  0xFF8A8A8A,
  0xFF787878,
  0xFF696969,
];

// Terracotta Clay - rich earthy tones
const List<int> _terracottaClay = [
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
  0xFFCD853F,
  0xFFB5651D,
  0xFFA0522D,
  0xFF8B4513,
];

// Red Bricks - classic brick pattern with mortar
const List<int> _redBricks = [
  0xFFB22222,
  0xFFB22222,
  0xFFB22222,
  0xFF8B0000,
  0xFF404040,
  0xFF8B0000,
  0xFF8B0000,
  0xFF8B0000,
  0xFFB22222,
  0xFFA52A2A,
  0xFFB22222,
  0xFF8B0000,
  0xFF404040,
  0xFF8B0000,
  0xFFA52A2A,
  0xFF8B0000,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF8B0000,
  0xFF8B0000,
  0xFF404040,
  0xFFB22222,
  0xFFB22222,
  0xFFB22222,
  0xFF404040,
  0xFF8B0000,
  0xFF8B0000,
  0xFFA52A2A,
  0xFF404040,
  0xFFB22222,
  0xFFA52A2A,
  0xFFB22222,
  0xFF404040,
  0xFF8B0000,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFF404040,
  0xFFB22222,
  0xFFB22222,
  0xFFB22222,
  0xFF404040,
  0xFF8B0000,
  0xFF8B0000,
  0xFF8B0000,
  0xFF404040,
  0xFFB22222,
  0xFFA52A2A,
  0xFFB22222,
  0xFF404040,
  0xFF8B0000,
  0xFFA52A2A,
  0xFF8B0000,
  0xFF404040,
];

// Stone Blocks - structured stone with highlights/shadows
const List<int> _stoneBlocks = [
  0xFFD3D3D3,
  0xFFD3D3D3,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFF808080,
  0xFFC0C0C0,
  0xFFD3D3D3,
  0xFFD3D3D3,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFFC0C0C0,
  0xFFA9A9A9,
  0xFF808080,
  0xFFA9A9A9,
  0xFFC0C0C0,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFFC0C0C0,
  0xFFA9A9A9,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFFA9A9A9,
  0xFFC0C0C0,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFFC0C0C0,
  0xFFA9A9A9,
  0xFF808080,
  0xFF808080,
  0xFFD3D3D3,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFF808080,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFFA9A9A9,
  0xFF808080,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFFA9A9A9,
  0xFF808080,
  0xFFD3D3D3,
  0xFFD3D3D3,
  0xFFC0C0C0,
  0xFF808080,
  0xFFC0C0C0,
  0xFFA9A9A9,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
  0xFF808080,
];

// Cracked Ice - light blue with white cracks
const List<int> _crackedIce = [
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
  0xFFB0E0E6,
  0xFFFFFFFF,
  0xFFB0E0E6,
  0xFFADD8E6,
];

// Dark Cobblestone - irregular dark stones
const List<int> _darkCobblestone = [
  0xFF2F4F4F,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF2F4F4F,
  0xFF36454F,
  0xFF404040,
  0xFF36454F,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF404040,
  0xFF2F4F4F,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF404040,
  0xFF2F4F4F,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF36454F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF404040,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF404040,
  0xFF36454F,
  0xFF2F4F4F,
  0xFF36454F,
  0xFF404040,
  0xFF2F4F4F,
  0xFF404040,
];

// Sandy Gravel - sand mixed with pebbles
const List<int> _sandyGravel = [
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
  0xFFF4A460,
  0xFFD2B48C,
  0xFFBC8F8F,
  0xFFD2B48C,
];

// Volcanic Rock - dark with glowing cracks
const List<int> _volcanicRock = [
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFFFF4500,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF222222,
  0xFFFF4500,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFFFF4500,
  0xFF222222,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFFFF6600,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFFFF4500,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFFFF4500,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF1C1C1C,
  0xFF222222,
  0xFFFF6600,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFF222222,
  0xFF1C1C1C,
  0xFFFF4500,
  0xFF1C1C1C,
];

// --- NEW TEXTURES ---

// Grass - various green shades
const List<int> _grassTexture = [
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF3CB371,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF3CB371,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF2E8B2E,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
  0xFF3CB371,
  0xFF2E8B2E,
  0xFF228B22,
];

// Wood Planks - horizontal wood grain pattern
const List<int> _woodPlanks = [
  0xFF8B4513,
  0xFF8B4513,
  0xFF8B4513,
  0xFF8B4513,
  0xFFA0522D,
  0xFFA0522D,
  0xFFA0522D,
  0xFFA0522D,
  0xFF8B4513,
  0xFF9A6324,
  0xFF8B4513,
  0xFF8B4513,
  0xFFA0522D,
  0xFFB0623D,
  0xFFA0522D,
  0xFFA0522D,
  0xFF8B4513,
  0xFF8B4513,
  0xFF9A6324,
  0xFF8B4513,
  0xFFA0522D,
  0xFFA0522D,
  0xFFB0623D,
  0xFFA0522D,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFFA0522D,
  0xFFA0522D,
  0xFFA0522D,
  0xFFA0522D,
  0xFF8B4513,
  0xFF8B4513,
  0xFF8B4513,
  0xFF8B4513,
  0xFFA0522D,
  0xFFB0623D,
  0xFFA0522D,
  0xFFA0522D,
  0xFF8B4513,
  0xFF9A6324,
  0xFF8B4513,
  0xFF8B4513,
  0xFFA0522D,
  0xFFA0522D,
  0xFFB0623D,
  0xFFA0522D,
  0xFF8B4513,
  0xFF8B4513,
  0xFF9A6324,
  0xFF8B4513,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
  0xFF5C3317,
];

// Water - blue with highlights for waves
const List<int> _waterTexture = [
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
  0xFF87CEEB,
  0xFF1E90FF,
  0xFF4169E1,
  0xFF1E90FF,
];

// Snow - white with subtle blue shadows
const List<int> _snowTexture = [
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
  0xFFF0F8FF,
  0xFFFFFFFF,
  0xFFFAFAFA,
  0xFFFFFFFF,
];

// Marble - white with gray veins
const List<int> _marbleTexture = [
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFD3D3D3,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFE0E0E0,
  0xFFD3D3D3,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFD3D3D3,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFD3D3D3,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFD3D3D3,
  0xFFF5F5F5,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFD3D3D3,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFE0E0E0,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFFAFAFA,
  0xFFD3D3D3,
  0xFFF5F5F5,
];

// Concrete - gray with speckles
const List<int> _concreteTexture = [
  0xFF9E9E9E,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF949494,
  0xFF9E9E9E,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF949494,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF949494,
  0xFF9E9E9E,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF949494,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF949494,
  0xFFB0B0B0,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF949494,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF949494,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF949494,
  0xFFB0B0B0,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF949494,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFF949494,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFF949494,
  0xFFA8A8A8,
  0xFFB0B0B0,
  0xFF949494,
  0xFF9E9E9E,
  0xFFA8A8A8,
  0xFF949494,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFFA8A8A8,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFF949494,
  0xFFB0B0B0,
  0xFF9E9E9E,
  0xFF949494,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFF949494,
  0xFFA8A8A8,
  0xFF9E9E9E,
  0xFF9E9E9E,
  0xFFB0B0B0,
];

// Mud - dark brown with wet spots
const List<int> _mudTexture = [
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF4A3728,
  0xFF3D2D1F,
  0xFF5C4A3A,
  0xFF3D2D1F,
  0xFF4A3728,
  0xFF5C4A3A,
];

// Autumn Leaves - oranges, reds, yellows
const List<int> _autumnLeavesTexture = [
  0xFFFF6347,
  0xFFFF8C00,
  0xFFFFD700,
  0xFF8B4513,
  0xFFFF6347,
  0xFFCD853F,
  0xFFFF8C00,
  0xFFFFD700,
  0xFFFF8C00,
  0xFFFFD700,
  0xFFFF6347,
  0xFFCD853F,
  0xFFFF8C00,
  0xFFFF6347,
  0xFFFFD700,
  0xFF8B4513,
  0xFFFFD700,
  0xFF8B4513,
  0xFFFF8C00,
  0xFFFF6347,
  0xFFFFD700,
  0xFF8B4513,
  0xFFFF6347,
  0xFFCD853F,
  0xFFCD853F,
  0xFFFF6347,
  0xFFFFD700,
  0xFFFF8C00,
  0xFF8B4513,
  0xFFFFD700,
  0xFFCD853F,
  0xFFFF6347,
  0xFFFF6347,
  0xFFFF8C00,
  0xFF8B4513,
  0xFFFFD700,
  0xFFFF6347,
  0xFFFF8C00,
  0xFFFFD700,
  0xFFCD853F,
  0xFFFF8C00,
  0xFFFFD700,
  0xFFCD853F,
  0xFFFF6347,
  0xFFFF8C00,
  0xFFFFD700,
  0xFF8B4513,
  0xFFFF6347,
  0xFFFFD700,
  0xFFCD853F,
  0xFFFF6347,
  0xFFFF8C00,
  0xFFFFD700,
  0xFFFF6347,
  0xFFFF8C00,
  0xFF8B4513,
  0xFF8B4513,
  0xFFFF6347,
  0xFFFF8C00,
  0xFFFFD700,
  0xFFCD853F,
  0xFF8B4513,
  0xFFFF6347,
  0xFFFFD700,
];

// Metal Grate - dark metal with gaps
const List<int> _metalGrateTexture = [
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF505050,
  0xFF606060,
  0xFF505050,
  0xFF202020,
  0xFF505050,
  0xFF606060,
  0xFF505050,
  0xFF202020,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF202020,
  0xFF202020,
  0xFF202020,
  0xFF101010,
  0xFF202020,
  0xFF202020,
  0xFF202020,
  0xFF101010,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF505050,
  0xFF606060,
  0xFF505050,
  0xFF202020,
  0xFF505050,
  0xFF606060,
  0xFF505050,
  0xFF202020,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF404040,
  0xFF505050,
  0xFF404040,
  0xFF202020,
  0xFF202020,
  0xFF202020,
  0xFF202020,
  0xFF101010,
  0xFF202020,
  0xFF202020,
  0xFF202020,
  0xFF101010,
];

// Hex Tiles - honeycomb pattern
const List<int> _hexTilesTexture = [
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFD4AF37,
  0xFFD4AF37,
  0xFFFFD700,
  0xFFFFD700,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
  0xFFB8860B,
];
