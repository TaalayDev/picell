part of 'effects.dart';

/// Spawns high-octane anime and manga speed lines streaming from the trailing
/// silhouette edge of a sprite along a configurable motion vector.
class ActionSpeedLinesEffect extends Effect {
  ActionSpeedLinesEffect([Map<String, dynamic>? params])
      : super(
          EffectType.actionSpeedLines,
          params ??
              {
                'motionAngle': 0.0,
                'lineLength': 24.0,
                'lineDensity': 0.6,
                'strokeWidth': 1.5,
                'taperFalloff': 1.0,
                'strokeColor': 0xFFFFFFFF,
                'speedDust': true,
                'behindOnly': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'motionAngle': 0.0,
        'lineLength': 24.0,
        'lineDensity': 0.6,
        'strokeWidth': 1.5,
        'taperFalloff': 1.0,
        'strokeColor': 0xFFFFFFFF,
        'speedDust': true,
        'behindOnly': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'motionAngle': {
          'label': 'Motion Direction',
          'description': 'Direction of character movement (0° = Dash Right, 180° = Dash Left). Lines trail backward.',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'step': 5.0,
        },
        'lineLength': {
          'label': 'Speed Line Length',
          'description': 'Maximum distance of speed strokes streaming behind the sprite.',
          'type': 'slider',
          'min': 8.0,
          'max': 48.0,
          'step': 2.0,
        },
        'lineDensity': {
          'label': 'Line Density',
          'description': 'Frequency of speed lines emitting from trailing edges.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'strokeWidth': {
          'label': 'Stroke Thickness',
          'description': 'Width of individual speed lines in pixels.',
          'type': 'slider',
          'min': 1.0,
          'max': 3.0,
          'step': 0.5,
        },
        'taperFalloff': {
          'label': 'Taper Falloff',
          'description': 'Steepness of stroke fading towards line tails.',
          'type': 'slider',
          'min': 0.2,
          'max': 2.0,
          'step': 0.1,
        },
        'strokeColor': {
          'label': 'Speed Line Color',
          'description': 'Color of speed strokes (Manga White, Ink Black, or Energy Glow).',
          'type': 'color',
        },
        'speedDust': {
          'label': 'Speed Dust Motes',
          'description': 'Spawn fine particulate dust specks near launch edges.',
          'type': 'bool',
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'Keep sprite in the foreground; lines only trail behind in empty space.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'motionAngle',
          label: 'Motion Direction',
          description: 'Direction of character movement (0° = Dash Right, 180° = Dash Left). Lines trail backward.',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'lineLength',
          label: 'Speed Line Length',
          description: 'Maximum distance of speed strokes streaming behind the sprite.',
          min: 8.0,
          max: 48.0,
          divisions: 20,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'lineDensity',
          label: 'Line Density',
          description: 'Frequency of speed lines emitting from trailing edges.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'strokeWidth',
          label: 'Stroke Thickness',
          description: 'Width of individual speed lines in pixels.',
          min: 1.0,
          max: 3.0,
          divisions: 4,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'taperFalloff',
          label: 'Taper Falloff',
          description: 'Steepness of stroke fading towards line tails.',
          min: 0.2,
          max: 2.0,
          divisions: 18,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'strokeColor',
          label: 'Speed Line Color',
          description: 'Color of speed strokes (Manga White, Ink Black, or Energy Glow).',
        ),
        const BoolField(
          key: 'speedDust',
          label: 'Speed Dust Motes',
          description: 'Spawn fine particulate dust specks near launch edges.',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'Keep sprite in the foreground; lines only trail behind in empty space.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double motionAngleDeg = ((parameters['motionAngle'] as num?)?.toDouble() ?? 0.0) % 360.0;
    final double maxLen = ((parameters['lineLength'] as num?)?.toDouble() ?? 24.0).clamp(8.0, 48.0);
    final double density = ((parameters['lineDensity'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    final double strokeWidth = ((parameters['strokeWidth'] as num?)?.toDouble() ?? 1.5).clamp(1.0, 3.0);
    final double falloff = ((parameters['taperFalloff'] as num?)?.toDouble() ?? 1.0).clamp(0.2, 2.0);
    final int colorVal = (parameters['strokeColor'] as num?)?.toInt() ?? 0xFFFFFFFF;
    final bool dust = parameters['speedDust'] as bool? ?? true;
    final bool behindOnly = parameters['behindOnly'] as bool? ?? true;

    final int strokeR = (colorVal >> 16) & 0xFF;
    final int strokeG = (colorVal >> 8) & 0xFF;
    final int strokeB = colorVal & 0xFF;

    // Movement vector
    final double rad = motionAngleDeg * (math.pi / 180.0);
    final double moveX = math.cos(rad);
    final double moveY = math.sin(rad);

    // Speed lines trail in the opposite direction of motion
    final double trailX = -moveX;
    final double trailY = -moveY;

    // Perpendicular vector for line width and speed dust scatter
    final double perpX = -trailY;
    final double perpY = trailX;

    // First pass: identify trailing boundary pixels and project speed lines
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int p = pixels[idx];
        final int a = (p >> 24) & 0xFF;
        if (a == 0) continue;

        // Check if neighbor in the trailing direction is transparent
        final int neighborX = (x + trailX).round();
        final int neighborY = (y + trailY).round();

        bool isTrailingEdge = false;
        if (neighborX < 0 || neighborX >= width || neighborY < 0 || neighborY >= height) {
          isTrailingEdge = true;
        } else {
          final int nIdx = neighborY * width + neighborX;
          if (((pixels[nIdx] >> 24) & 0xFF) == 0) {
            isTrailingEdge = true;
          }
        }

        if (!isTrailingEdge) continue;

        // Deterministic hash to decide if this edge pixel fires a speed line
        final double h1 = _hash(x * 67 + y * 131 + 47);
        if (h1 > density) continue;

        final double hLen = _hash(x * 97 + y * 43 + 89);
        final double curLen = maxLen * (0.45 + hLen * 0.55);

        // Ray-cast speed stroke along trail vector
        final int steps = curLen.round();
        for (int s = 1; s <= steps; s++) {
          final double t = s / curLen; // 0.0 to 1.0
          final double alphaT = math.pow(1.0 - t, falloff).toDouble();
          final int lineA = (alphaT * 255.0).round().clamp(0, 255);
          if (lineA <= 0) break;

          final double targetX = x + trailX * s;
          final double targetY = y + trailY * s;
          final int tx = targetX.round();
          final int ty = targetY.round();

          if (tx < 0 || tx >= width || ty < 0 || ty >= height) break;

          final int tIdx = ty * width + tx;

          // If behindOnly is true, do not overwrite opaque sprite pixels
          if (behindOnly && ((pixels[tIdx] >> 24) & 0xFF) > 0) {
            continue;
          }

          _blendPixel(output, tIdx, strokeR, strokeG, strokeB, lineA);

          // Apply extra width if strokeWidth > 1.2
          if (strokeWidth >= 1.5) {
            final int wA = (lineA * 0.5).round();
            if (wA > 10) {
              final int px1 = (targetX + perpX).round();
              final int py1 = (targetY + perpY).round();
              if (px1 >= 0 && px1 < width && py1 >= 0 && py1 < height) {
                final int idx1 = py1 * width + px1;
                if (!behindOnly || ((pixels[idx1] >> 24) & 0xFF) == 0) {
                  _blendPixel(output, idx1, strokeR, strokeG, strokeB, wA);
                }
              }

              final int px2 = (targetX - perpX).round();
              final int py2 = (targetY - perpY).round();
              if (px2 >= 0 && px2 < width && py2 >= 0 && py2 < height) {
                final int idx2 = py2 * width + px2;
                if (!behindOnly || ((pixels[idx2] >> 24) & 0xFF) == 0) {
                  _blendPixel(output, idx2, strokeR, strokeG, strokeB, wA);
                }
              }
            }
          }
        }

        // Speed dust particle scatter
        if (dust) {
          final double hDust = _hash(x * 137 + y * 73 + 19);
          if (hDust < 0.45) {
            final double dustDist = 2.0 + hDust * 10.0;
            final double dustScatter = (_hash(x * 53 + y * 179 + 31) - 0.5) * 4.0;
            final int dx = (x + trailX * dustDist + perpX * dustScatter).round();
            final int dy = (y + trailY * dustDist + perpY * dustScatter).round();

            if (dx >= 0 && dx < width && dy >= 0 && dy < height) {
              final int dIdx = dy * width + dx;
              if (!behindOnly || ((pixels[dIdx] >> 24) & 0xFF) == 0) {
                _blendPixel(output, dIdx, strokeR, strokeG, strokeB, 190);
              }
            }
          }
        }
      }
    }

    // Second pass: blit original sprite on top
    for (int i = 0; i < pixels.length; i++) {
      final int p = pixels[i];
      final int a = (p >> 24) & 0xFF;
      if (a > 0) {
        if (behindOnly || a == 255) {
          output[i] = p;
        } else {
          // Alpha composite
          final double srcA = a / 255.0;
          final int bgP = output[i];
          final int bgR = (bgP >> 16) & 0xFF;
          final int bgG = (bgP >> 8) & 0xFF;
          final int bgB = bgP & 0xFF;
          final int bgA = (bgP >> 24) & 0xFF;

          final int r = (((p >> 16) & 0xFF) * srcA + bgR * (1.0 - srcA)).round();
          final int g = (((p >> 8) & 0xFF) * srcA + bgG * (1.0 - srcA)).round();
          final int b = ((p & 0xFF) * srcA + bgB * (1.0 - srcA)).round();
          final int outA = math.max(a, bgA);
          output[i] = (outA << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static void _blendPixel(Uint32List buffer, int idx, int r, int g, int b, int a) {
    final int curP = buffer[idx];
    final int curA = (curP >> 24) & 0xFF;
    if (curA == 0) {
      buffer[idx] = (a << 24) | (r << 16) | (g << 8) | b;
    } else {
      final int curR = (curP >> 16) & 0xFF;
      final int curG = (curP >> 8) & 0xFF;
      final int curB = curP & 0xFF;

      final double na = a / 255.0;
      final int outR = math.max(curR, (r * na).round());
      final int outG = math.max(curG, (g * na).round());
      final int outB = math.max(curB, (b * na).round());
      final int outA = math.max(curA, a);

      buffer[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }
  }

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}
