part of 'effects.dart';

/// Simulates high-speed dash, teleport, and speed-phantom trail after-images
/// with fading silhouettes and custom color tints (Mega Man / Castlevania / Celeste style).
class GhostTrailEffect extends Effect with UIFieldProvider {
  GhostTrailEffect([Map<String, dynamic>? params])
      : super(
          EffectType.ghostTrail,
          params ??
              const {
                'ghostCount': 3,
                'spacing': 6,
                'direction': 0.0,
                'tintColor': 0xFF00E5FF,
                'tintStrength': 0.7,
                'fade': 0.6,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'ghostCount': 3,
      'spacing': 6,
      'direction': 0.0,
      'tintColor': 0xFF00E5FF,
      'tintStrength': 0.7,
      'fade': 0.6,
      'time': 0.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'ghostCount': {
        'label': 'After-image Count',
        'description': 'Number of trailing ghost silhouettes.',
        'type': 'slider',
        'min': 1,
        'max': 5,
        'divisions': 4,
      },
      'spacing': {
        'label': 'Trail Distance',
        'description': 'Pixel separation distance between consecutive ghosts.',
        'type': 'slider',
        'min': 2,
        'max': 20,
        'divisions': 18,
      },
      'direction': {
        'label': 'Dash Direction Angle',
        'description': 'Motion vector angle (0° = Dash Right, 180° = Dash Left, 90° = Up).',
        'type': 'slider',
        'min': 0.0,
        'max': 360.0,
        'divisions': 72,
      },
      'tintColor': {
        'label': 'Ghost Tint Color',
        'description': 'Color tint of the trailing silhouettes.',
        'type': 'color',
      },
      'tintStrength': {
        'label': 'Tint Intensity',
        'description': 'Strength of the color tint overlay (0 = natural sprite colors, 1 = solid phantom).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'fade': {
        'label': 'Opacity Falloff',
        'description': 'Decay rate of older ghosts in the trail.',
        'type': 'slider',
        'min': 0.2,
        'max': 1.2,
        'divisions': 50,
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Timeline progress parameter updated during frame generation.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Allow ghost trails to float cleanly over transparent backgrounds.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'ghostCount',
          label: 'After-image Count',
          description: 'Number of trailing ghost silhouettes.',
          min: 1,
          max: 5,
          divisions: 4,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}x',
        ),
        SliderField(
          key: 'spacing',
          label: 'Trail Distance',
          description: 'Pixel separation distance between consecutive ghosts.',
          min: 2,
          max: 20,
          divisions: 18,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'direction',
          label: 'Dash Direction Angle',
          description: 'Motion vector angle (0° = Dash Right, 180° = Dash Left, 90° = Up).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        const ColorField(
          key: 'tintColor',
          label: 'Ghost Tint Color',
          description: 'Color tint of the trailing silhouettes.',
        ),
        SliderField(
          key: 'tintStrength',
          label: 'Tint Intensity',
          description: 'Strength of the color tint overlay (0 = natural sprite colors, 1 = solid phantom).',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'fade',
          label: 'Opacity Falloff',
          description: 'Decay rate of older ghosts in the trail.',
          min: 0.2,
          max: 1.2,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Allow ghost trails to float cleanly over transparent backgrounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final ghostCount = ((parameters['ghostCount'] as num?)?.toInt() ?? 3).clamp(1, 5);
    final spacing = ((parameters['spacing'] as num?)?.toDouble() ?? 6.0).clamp(2.0, 20.0);
    final direction = ((parameters['direction'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 360.0);
    final tintColorInt = (parameters['tintColor'] as int?) ?? 0xFF00E5FF;
    final tintStrength = ((parameters['tintStrength'] as num?)?.toDouble() ?? 0.7).clamp(0.0, 1.0);
    final fade = ((parameters['fade'] as num?)?.toDouble() ?? 0.6).clamp(0.2, 1.2);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final tintR = (tintColorInt >> 16) & 0xFF;
    final tintG = (tintColorInt >> 8) & 0xFF;
    final tintB = tintColorInt & 0xFF;

    final rad = direction * math.pi / 180.0;
    // Dash vector: (cos, -sin). Ghost trail is behind: (-cos, sin)
    final trailDx = -math.cos(rad) * spacing;
    final trailDy = math.sin(rad) * spacing;

    // Time pulsation factor
    final dynamicSpacing = 0.8 + 0.4 * math.sin(time * 2.0 * math.pi);

    final result = Uint32List.fromList(pixels);

    // Render ghosts from furthest (ghostCount) down to closest (1)
    for (int k = ghostCount; k >= 1; k--) {
      final offsetX = (k * trailDx * dynamicSpacing).round();
      final offsetY = (k * trailDy * dynamicSpacing).round();
      final ghostOpacity = math.pow((ghostCount + 1 - k) / (ghostCount + 1), fade).clamp(0.1, 0.9);

      for (int sy = 0; sy < height; sy++) {
        final ty = sy + offsetY;
        if (ty < 0 || ty >= height) continue;

        for (int sx = 0; sx < width; sx++) {
          final tx = sx + offsetX;
          if (tx < 0 || tx >= width) continue;

          final srcPixel = pixels[sy * width + sx];
          final srcA = (srcPixel >> 24) & 0xFF;
          if (srcA == 0) continue;

          final targetIndex = ty * width + tx;
          final existingPixel = result[targetIndex];
          final existingA = (existingPixel >> 24) & 0xFF;

          // Compute tinted ghost color
          final sr = (srcPixel >> 16) & 0xFF;
          final sg = (srcPixel >> 8) & 0xFF;
          final sb = srcPixel & 0xFF;

          final gr = (sr * (1.0 - tintStrength) + tintR * tintStrength).round().clamp(0, 255);
          final gg = (sg * (1.0 - tintStrength) + tintG * tintStrength).round().clamp(0, 255);
          final gb = (sb * (1.0 - tintStrength) + tintB * tintStrength).round().clamp(0, 255);
          final ga = (srcA * ghostOpacity).round().clamp(0, 255);

          if (existingA == 0) {
            result[targetIndex] = (ga << 24) | (gr << 16) | (gg << 8) | gb;
          } else {
            // Under blend (ghost sits behind existing foreground pixel)
            final fgNorm = existingA / 255.0;
            final bgNorm = (ga / 255.0) * (1.0 - fgNorm);
            final totalA = fgNorm + bgNorm;

            if (totalA > 0) {
              final er = (existingPixel >> 16) & 0xFF;
              final eg = (existingPixel >> 8) & 0xFF;
              final eb = existingPixel & 0xFF;

              final outR = ((er * fgNorm + gr * bgNorm) / totalA).round().clamp(0, 255);
              final outG = ((eg * fgNorm + gg * bgNorm) / totalA).round().clamp(0, 255);
              final outB = ((eb * fgNorm + gb * bgNorm) / totalA).round().clamp(0, 255);
              final outA = (totalA * 255).round().clamp(0, 255);

              result[targetIndex] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
            }
          }
        }
      }
    }

    if (!preserveAlpha) {
      for (int i = 0; i < result.length; i++) {
        if (((result[i] >> 24) & 0xFF) == 0) {
          result[i] = 0xFF000000;
        }
      }
    }

    return result;
  }
}
