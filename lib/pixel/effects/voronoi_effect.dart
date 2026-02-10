part of 'effects.dart';

/// Creates Voronoi diagram patterns with various rendering modes
class VoronoiEffect extends Effect {
  VoronoiEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.voronoi,
          parameters ??
              const {
                'cellCount': 16,
                'mode': 0, // 0=cell, 1=distance, 2=edge, 3=crack
                'metric': 0, // 0=euclidean, 1=manhattan, 2=chebyshev
                'jitter': 1.0,
                'edgeWidth': 2.0,
                'shading': 0.5,
                'color1': 0xFF2d3436,
                'color2': 0xFF636e72,
                'color3': 0xFFb2bec3,
                'color4': 0xFFdfe6e9,
                'color5': 0xFF74b9ff,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'cellCount': 16,
      'mode': 0,
      'metric': 0,
      'jitter': 1.0,
      'edgeWidth': 2.0,
      'shading': 0.5,
      'color1': 0xFF2d3436,
      'color2': 0xFF636e72,
      'color3': 0xFFb2bec3,
      'color4': 0xFFdfe6e9,
      'color5': 0xFF74b9ff,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'cellCount': {
        'label': 'Cell Count',
        'description': 'Number of Voronoi cells/feature points.',
        'type': 'slider',
        'min': 4,
        'max': 256,
        'divisions': 252,
      },
      'mode': {
        'label': 'Mode',
        'description': 'Rendering mode for the Voronoi pattern.',
        'type': 'select',
        'options': {
          0: 'Cell Colors',
          1: 'Distance Field',
          2: 'Edge Highlight',
          3: 'Cracked',
        },
      },
      'metric': {
        'label': 'Distance Metric',
        'description': 'Method to calculate distances.',
        'type': 'select',
        'options': {
          0: 'Euclidean',
          1: 'Manhattan',
          2: 'Chebyshev',
        },
      },
      'jitter': {
        'label': 'Jitter',
        'description': 'Randomness of point placement (0=grid, 1=random).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'edgeWidth': {
        'label': 'Edge Width',
        'description': 'Width of edges/cracks between cells.',
        'type': 'slider',
        'min': 1.0,
        'max': 10.0,
        'divisions': 90,
      },
      'shading': {
        'label': 'Shading',
        'description': 'Amount of distance-based shading.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'color1': {
        'label': 'Color 1',
        'description': 'First palette color.',
        'type': 'color',
      },
      'color2': {
        'label': 'Color 2',
        'description': 'Second palette color.',
        'type': 'color',
      },
      'color3': {
        'label': 'Color 3',
        'description': 'Third palette color.',
        'type': 'color',
      },
      'color4': {
        'label': 'Color 4',
        'description': 'Fourth palette color.',
        'type': 'color',
      },
      'color5': {
        'label': 'Color 5',
        'description': 'Fifth palette color.',
        'type': 'color',
      },
    };
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    // Get parameters
    final cellCount = ((parameters['cellCount'] as int?) ?? 16).clamp(4, 256);
    final mode = ((parameters['mode'] as int?) ?? 0).clamp(0, 3);
    final metric = ((parameters['metric'] as int?) ?? 0).clamp(0, 2);
    final jitter = ((parameters['jitter'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0);
    final edgeWidth = ((parameters['edgeWidth'] as num?)?.toDouble() ?? 2.0).clamp(1.0, 10.0);
    final shading = ((parameters['shading'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);

    // Get palette colors
    final palette = <int>[
      (parameters['color1'] as int?) ?? 0xFF2d3436,
      (parameters['color2'] as int?) ?? 0xFF636e72,
      (parameters['color3'] as int?) ?? 0xFFb2bec3,
      (parameters['color4'] as int?) ?? 0xFFdfe6e9,
      (parameters['color5'] as int?) ?? 0xFF74b9ff,
    ];
    final palLen = palette.length;

    // Generate feature points in a grid with jitter
    final gridSize = (sqrt(cellCount.toDouble())).ceil();
    final points = <_VoronoiPoint>[];
    final cellW = width / gridSize;
    final cellH = height / gridSize;
    final seed = 12345;

    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        final baseX = (gx + 0.5) * cellW;
        final baseY = (gy + 0.5) * cellH;

        final offsetX = (_hash2f(gx, gy, seed) - 0.5) * cellW * jitter;
        final offsetY = (_hash2f(gx, gy, seed + 1000) - 0.5) * cellH * jitter;

        points.add(_VoronoiPoint(
          x: baseX + offsetX,
          y: baseY + offsetY,
          id: gy * gridSize + gx,
        ));
      }
    }

    // For each pixel, find closest and second closest point
    final cellId = Uint16List(width * height);
    final dist1 = Float32List(width * height);
    final dist2 = Float32List(width * height);

    for (int i = 0; i < dist1.length; i++) {
      dist1[i] = double.infinity;
      dist2[i] = double.infinity;
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = y * width + x;
        int closest = 0;
        double d1 = double.infinity;
        double d2 = double.infinity;

        // Check all points (including wrapped versions for tiling)
        for (int pi = 0; pi < points.length; pi++) {
          final pt = points[pi];

          // Check original and wrapped positions
          for (int wy = -1; wy <= 1; wy++) {
            for (int wx = -1; wx <= 1; wx++) {
              final px = pt.x + wx * width;
              final py = pt.y + wy * height;
              final d = _distance(x.toDouble(), y.toDouble(), px, py, width, height, metric);

              if (d < d1) {
                d2 = d1;
                d1 = d;
                closest = pt.id;
              } else if (d < d2) {
                d2 = d;
              }
            }
          }
        }

        cellId[i] = closest;
        dist1[i] = d1;
        dist2[i] = d2;
      }
    }

    // Normalize distances
    double maxDist1 = 0;
    for (int i = 0; i < dist1.length; i++) {
      if (dist1[i] < double.infinity) {
        maxDist1 = max(maxDist1, dist1[i]);
      }
    }
    maxDist1 = maxDist1 > 0 ? maxDist1 : 1.0;

    // Start with existing pixels
    final result = Uint32List.fromList(pixels);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = y * width + x;

        // Get original pixel
        final originalPixel = Color(result[i]);

        // Skip transparent pixels
        if (originalPixel.alpha == 0) continue;

        int colorIdx = 0;

        switch (mode) {
          case 0: // Cell colors
            final baseColor = (cellId[i] % (palLen - 1)) + 1;
            colorIdx = baseColor;

            // Add shading based on distance from center
            if (shading > 0 && palLen > 2) {
              final shade = (dist1[i] / maxDist1) * shading;
              colorIdx = (baseColor - (shade * 2).floor()).clamp(0, palLen - 1);
            }
            break;

          case 1: // Distance field
            final t = dist1[i] / maxDist1;
            colorIdx = (t * (palLen - 1)).floor();
            break;

          case 2: // Edge highlight
            final edgeDist = dist2[i] - dist1[i];
            if (edgeDist < edgeWidth) {
              colorIdx = palLen - 1; // Edge color (last in palette)
            } else {
              final baseColor = (cellId[i] % (palLen - 2)) + 1;
              colorIdx = baseColor;
            }
            break;

          case 3: // Crack effect
            final edgeDist = dist2[i] - dist1[i];
            if (edgeDist < edgeWidth) {
              colorIdx = 0; // Crack color (first/darkest)
            } else {
              // Vary based on cell + distance
              final t = 1 - (dist1[i] / maxDist1) * 0.3;
              colorIdx = (t * (palLen - 1)).floor().clamp(1, palLen - 1);
            }
            break;
        }

        colorIdx = colorIdx.clamp(0, palLen - 1);
        final voronoiColor = Color(palette[colorIdx]);

        // Apply Voronoi pattern while preserving original alpha
        result[i] = (voronoiColor.value & 0x00FFFFFF) | (originalPixel.alpha << 24);
      }
    }

    return result;
  }

  /// Calculate distance based on selected metric
  double _distance(double x1, double y1, double x2, double y2, int width, int height, int metric) {
    // Handle tiling - wrap distances
    double dx = (x2 - x1).abs();
    double dy = (y2 - y1).abs();
    dx = min(dx, width - dx);
    dy = min(dy, height - dy);

    switch (metric) {
      case 1: // Manhattan
        return dx + dy;
      case 2: // Chebyshev
        return max(dx, dy);
      default: // Euclidean
        return sqrt(dx * dx + dy * dy);
    }
  }

  /// Hash to float for point generation
  double _hash2f(int a, int b, int seed) {
    var h = a * 374761393 + b * 668265263 + seed;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0x7FFFFFFF) / 0x7FFFFFFF.toDouble();
  }
}

/// Helper class to store Voronoi point data
class _VoronoiPoint {
  final double x;
  final double y;
  final int id;

  _VoronoiPoint({required this.x, required this.y, required this.id});
}
