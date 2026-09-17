part of 'effects.dart';

/// Simulates chromatic aberration and RGB color splitting caused by optical
/// prism refraction, imperfect camera lenses, and retro glitch effects.
class ChromaticAberrationEffect extends Effect with UIFieldProvider {
  ChromaticAberrationEffect([Map<String, dynamic>? params])
      : super(
          EffectType.chromaticAberration,
          params ??
              const {
                'mode': 'linear',
                'distance': 3.0,
                'angle': 0.0,
                'blueFactor': 1.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'mode': 'linear',
      'distance': 3.0,
      'angle': 0.0,
      'blueFactor': 1.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'mode': {
        'label': 'Aberration Mode',
        'description': 'Directional linear split or radial lens edge distortion.',
        'type': 'select',
        'options': {
          'linear': 'Linear (Directional)',
          'radial': 'Radial (Lens Edges)',
        },
      },
      'distance': {
        'label': 'Channel Separation',
        'description': 'Maximum distance in pixels to shift the red and blue channels.',
        'type': 'slider',
        'min': 0.0,
        'max': 15.0,
        'divisions': 75,
      },
      'angle': {
        'label': 'Split Angle',
        'description': 'Angle of channel displacement in degrees (linear mode).',
        'type': 'slider',
        'min': 0.0,
        'max': 360.0,
        'divisions': 72,
      },
      'blueFactor': {
        'label': 'Blue Displacement',
        'description': 'Relative shift distance of the blue channel compared to red.',
        'type': 'slider',
        'min': 0.5,
        'max': 1.5,
        'divisions': 50,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Allow colored fringes to extend into transparent space naturally.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'mode',
          label: 'Aberration Mode',
          description: 'Directional linear split or radial lens edge distortion.',
          options: {
            'linear': 'Linear (Directional)',
            'radial': 'Radial (Lens Edges)',
          },
        ),
        SliderField(
          key: 'distance',
          label: 'Channel Separation',
          description: 'Maximum distance in pixels to shift the red and blue channels.',
          min: 0.0,
          max: 15.0,
          divisions: 75,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'angle',
          label: 'Split Angle',
          description: 'Angle of channel displacement in degrees (linear mode).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'blueFactor',
          label: 'Blue Displacement',
          description: 'Relative shift distance of the blue channel compared to red.',
          min: 0.5,
          max: 1.5,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Allow colored fringes to extend into transparent space naturally.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final mode = parameters['mode'] as String? ?? 'linear';
    final distance = ((parameters['distance'] as num?)?.toDouble() ?? 3.0).clamp(0.0, 15.0);
    final angleDeg = ((parameters['angle'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 360.0);
    final blueFactor = ((parameters['blueFactor'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 1.5);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    if (distance < 0.01) {
      return Uint32List.fromList(pixels);
    }

    final result = Uint32List(width * height);
    final isLinear = mode == 'linear';
    final rad = angleDeg * math.pi / 180.0;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    final centerX = (width - 1) / 2.0;
    final centerY = (height - 1) / 2.0;
    final invMaxRadius = (centerX > 0 && centerY > 0)
        ? 1.0 / math.sqrt(centerX * centerX + centerY * centerY)
        : 1.0;

    // Linear precomputed offsets
    final linearDxR = (distance * cosA).round();
    final linearDyR = (distance * sinA).round();
    final linearDxB = (-distance * blueFactor * cosA).round();
    final linearDyB = (-distance * blueFactor * sinA).round();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final outIndex = y * width + x;

        int dxR = linearDxR;
        int dyR = linearDyR;
        int dxB = linearDxB;
        int dyB = linearDyB;

        if (!isLinear) {
          final nx = x - centerX;
          final ny = y - centerY;
          final r = math.sqrt(nx * nx + ny * ny);
          if (r > 0.001) {
            final normalizedR = (r * invMaxRadius).clamp(0.0, 1.5);
            final radialDist = distance * normalizedR;
            final ux = nx / r;
            final uy = ny / r;

            dxR = (ux * radialDist).round();
            dyR = (uy * radialDist).round();
            dxB = (-ux * radialDist * blueFactor).round();
            dyB = (-uy * radialDist * blueFactor).round();
          } else {
            dxR = 0;
            dyR = 0;
            dxB = 0;
            dyB = 0;
          }
        }

        // 1. Red sample (shifted by dxR, dyR)
        final rx = x + dxR;
        final ry = y + dyR;
        int redVal = 0;
        int redAlpha = 0;
        if (rx >= 0 && rx < width && ry >= 0 && ry < height) {
          final p = pixels[ry * width + rx];
          redAlpha = (p >> 24) & 0xFF;
          redVal = (p >> 16) & 0xFF;
        }

        // 2. Green sample (stays anchored at x, y)
        final origPixel = pixels[outIndex];
        final greenAlpha = (origPixel >> 24) & 0xFF;
        final greenVal = (origPixel >> 8) & 0xFF;

        // 3. Blue sample (shifted by dxB, dyB)
        final bx = x + dxB;
        final by = y + dyB;
        int blueVal = 0;
        int blueAlpha = 0;
        if (bx >= 0 && bx < width && by >= 0 && by < height) {
          final p = pixels[by * width + bx];
          blueAlpha = (p >> 24) & 0xFF;
          blueVal = p & 0xFF;
        }

        // Alpha calculation
        int outA;
        if (preserveAlpha) {
          // If transparent pixel with no channel reaching it
          outA = math.max(greenAlpha, math.max(redAlpha, blueAlpha));
          if (outA == 0) {
            result[outIndex] = 0;
            continue;
          }
        } else {
          outA = 255;
        }

        result[outIndex] = (outA << 24) | (redVal << 16) | (greenVal << 8) | blueVal;
      }
    }

    return result;
  }
}
