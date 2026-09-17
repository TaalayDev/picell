part of 'effects.dart';

/// Generates tangent-space 2D normal maps from pixel art sprites and textures
/// using Sobel surface gradients and alpha-edge beveling for dynamic 2D lighting.
class NormalMapEffect extends Effect with UIFieldProvider {
  NormalMapEffect([Map<String, dynamic>? params])
      : super(
          EffectType.normalMap,
          params ??
              const {
                'strength': 2.5,
                'bevelEdges': true,
                'bevelRadius': 2,
                'invertY': false,
                'smoothness': 0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'strength': 2.5,
      'bevelEdges': true,
      'bevelRadius': 2,
      'invertY': false,
      'smoothness': 0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'strength': {
        'label': 'Bump Depth',
        'description': 'Normal vector extrusion intensity.',
        'type': 'slider',
        'min': 0.2,
        'max': 8.0,
        'divisions': 78,
      },
      'bevelEdges': {
        'label': 'Bevel Contour Edges',
        'description': 'Adds rounded 3D volume along transparent sprite boundaries.',
        'type': 'bool',
      },
      'bevelRadius': {
        'label': 'Bevel Radius',
        'description': 'Width in pixels of the rounded edge bevel.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3,
      },
      'invertY': {
        'label': 'Invert Y (DirectX)',
        'description': 'Invert green channel for DirectX normal format instead of OpenGL.',
        'type': 'bool',
      },
      'smoothness': {
        'label': 'Pre-filter Smoothness',
        'description': 'Subtle pre-smoothing of pixel height transitions.',
        'type': 'slider',
        'min': 0,
        'max': 2,
        'divisions': 2,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Keep sprite background transparent instead of flat tangent normal (128, 128, 255).',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'strength',
          label: 'Bump Depth',
          description: 'Normal vector extrusion intensity.',
          min: 0.2,
          max: 8.0,
          divisions: 78,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const BoolField(
          key: 'bevelEdges',
          label: 'Bevel Contour Edges',
          description: 'Adds rounded 3D volume along transparent sprite boundaries.',
        ),
        SliderField(
          key: 'bevelRadius',
          label: 'Bevel Radius',
          description: 'Width in pixels of the rounded edge bevel.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const BoolField(
          key: 'invertY',
          label: 'Invert Y (DirectX)',
          description: 'Invert green channel for DirectX normal format instead of OpenGL.',
        ),
        SliderField(
          key: 'smoothness',
          label: 'Pre-filter Smoothness',
          description: 'Subtle pre-smoothing of pixel height transitions.',
          min: 0,
          max: 2,
          divisions: 2,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep sprite background transparent instead of flat tangent normal (128, 128, 255).',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final strength = ((parameters['strength'] as num?)?.toDouble() ?? 2.5).clamp(0.2, 8.0);
    final bevelEdges = parameters['bevelEdges'] as bool? ?? true;
    final bevelRadius = ((parameters['bevelRadius'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final invertY = parameters['invertY'] as bool? ?? false;
    final smoothness = ((parameters['smoothness'] as num?)?.toInt() ?? 0).clamp(0, 2);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final heightMap = Float32List(width * height);

    // 1. Build initial height map
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final p = pixels[idx];
        final a = (p >> 24) & 0xFF;

        if (a == 0) {
          heightMap[idx] = 0.0;
          continue;
        }

        final r = (p >> 16) & 0xFF;
        final g = (p >> 8) & 0xFF;
        final b = p & 0xFF;
        final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        if (bevelEdges) {
          // Compute distance to nearest edge
          double minDist = bevelRadius.toDouble();
          for (int dy = -bevelRadius; dy <= bevelRadius; dy++) {
            final ny = y + dy;
            if (ny < 0 || ny >= height) {
              minDist = math.min(minDist, dy.abs().toDouble());
              continue;
            }
            for (int dx = -bevelRadius; dx <= bevelRadius; dx++) {
              final nx = x + dx;
              if (nx < 0 || nx >= width) {
                minDist = math.min(minDist, math.sqrt(dx * dx + dy * dy));
                continue;
              }
              if (((pixels[ny * width + nx] >> 24) & 0xFF) == 0) {
                final d = math.sqrt(dx * dx + dy * dy);
                if (d < minDist) minDist = d;
              }
            }
          }
          final bevelFactor = (minDist / bevelRadius).clamp(0.0, 1.0);
          heightMap[idx] = (lum * 0.4 + bevelFactor * 0.6);
        } else {
          heightMap[idx] = lum;
        }
      }
    }

    // Optional pre-filter smoothing
    var smoothedMap = heightMap;
    if (smoothness > 0) {
      smoothedMap = _smoothHeightMap(heightMap, width, height, smoothness);
    }

    final result = Uint32List(width * height);

    // 2. Sobel filter for normal vectors
    for (int y = 0; y < height; y++) {
      final yPrev = y > 0 ? y - 1 : 0;
      final yNext = y < height - 1 ? y + 1 : height - 1;

      for (int x = 0; x < width; x++) {
        final outIndex = y * width + x;
        final origPixel = pixels[outIndex];
        final origA = (origPixel >> 24) & 0xFF;

        if (origA == 0 && preserveAlpha) {
          result[outIndex] = 0;
          continue;
        }

        final xPrev = x > 0 ? x - 1 : 0;
        final xNext = x < width - 1 ? x + 1 : width - 1;

        final tl = smoothedMap[yPrev * width + xPrev];
        final t = smoothedMap[yPrev * width + x];
        final tr = smoothedMap[yPrev * width + xNext];

        final l = smoothedMap[y * width + xPrev];
        final r = smoothedMap[y * width + xNext];

        final bl = smoothedMap[yNext * width + xPrev];
        final b = smoothedMap[yNext * width + x];
        final br = smoothedMap[yNext * width + xNext];

        // Horizontal and vertical Sobel gradients
        final dx = (tr + 2.0 * r + br) - (tl + 2.0 * l + bl);
        final dy = (bl + 2.0 * b + br) - (tl + 2.0 * t + tr);

        var nx = -dx * strength;
        var ny = (invertY ? dy : -dy) * strength;
        var nz = 1.0;

        final len = math.sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0.0001) {
          nx /= len;
          ny /= len;
          nz /= len;
        }

        final outR = ((nx * 0.5 + 0.5) * 255.0).round().clamp(0, 255);
        final outG = ((ny * 0.5 + 0.5) * 255.0).round().clamp(0, 255);
        final outB = ((nz * 0.5 + 0.5) * 255.0).round().clamp(0, 255);
        final outA = preserveAlpha ? origA : 255;

        result[outIndex] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return result;
  }

  Float32List _smoothHeightMap(Float32List src, int width, int height, int radius) {
    final dst = Float32List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double sum = 0.0;
        int count = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) continue;
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= width) continue;
            sum += src[ny * width + nx];
            count++;
          }
        }
        dst[y * width + x] = count > 0 ? sum / count : src[y * width + x];
      }
    }
    return dst;
  }
}
