part of 'effects.dart';

/// Simulates directional 2D rim lighting and silhouette edge highlights on
/// pixel art sprites and characters based on virtual light sources.
class RimLightEffect extends Effect with UIFieldProvider {
  RimLightEffect([Map<String, dynamic>? params])
      : super(
          EffectType.rimLight,
          params ??
              const {
                'lightColor': 0xFFFFE082,
                'lightAngle': 45.0,
                'brightness': 1.0,
                'thickness': 1,
                'wrap': 0.2,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'lightColor': 0xFFFFE082,
      'lightAngle': 45.0,
      'brightness': 1.0,
      'thickness': 1,
      'wrap': 0.2,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'lightColor': {
        'label': 'Light Color',
        'description': 'Color of the directional rim highlight.',
        'type': 'color',
      },
      'lightAngle': {
        'label': 'Light Direction Angle',
        'description': 'Angle of the virtual light source in degrees (0° = Right, 90° = Top, 180° = Left).',
        'type': 'slider',
        'min': 0.0,
        'max': 360.0,
        'divisions': 72,
      },
      'brightness': {
        'label': 'Rim Intensity',
        'description': 'Brightness and strength of the edge highlight.',
        'type': 'slider',
        'min': 0.0,
        'max': 2.0,
        'divisions': 40,
      },
      'thickness': {
        'label': 'Edge Thickness',
        'description': 'Penetration depth of the rim lighting in pixels.',
        'type': 'slider',
        'min': 1,
        'max': 3,
        'divisions': 2,
      },
      'wrap': {
        'label': 'Light Wrap-around',
        'description': 'How much light wraps around curved sprite silhouettes.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 50,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Keep background transparent.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const ColorField(
          key: 'lightColor',
          label: 'Light Color',
          description: 'Color of the directional rim highlight.',
        ),
        SliderField(
          key: 'lightAngle',
          label: 'Light Direction Angle',
          description: 'Angle of the virtual light source in degrees (0° = Right, 90° = Top, 180° = Left).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'brightness',
          label: 'Rim Intensity',
          description: 'Brightness and strength of the edge highlight.',
          min: 0.0,
          max: 2.0,
          divisions: 40,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'thickness',
          label: 'Edge Thickness',
          description: 'Penetration depth of the rim lighting in pixels.',
          min: 1,
          max: 3,
          divisions: 2,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'wrap',
          label: 'Light Wrap-around',
          description: 'How much light wraps around curved sprite silhouettes.',
          min: 0.0,
          max: 1.0,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep background transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final lightColorInt = (parameters['lightColor'] as int?) ?? 0xFFFFE082;
    final lightAngle = ((parameters['lightAngle'] as num?)?.toDouble() ?? 45.0).clamp(0.0, 360.0);
    final brightness = ((parameters['brightness'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 2.0);
    final thickness = ((parameters['thickness'] as num?)?.toInt() ?? 1).clamp(1, 3);
    final wrap = ((parameters['wrap'] as num?)?.toDouble() ?? 0.2).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final lightR = (lightColorInt >> 16) & 0xFF;
    final lightG = (lightColorInt >> 8) & 0xFF;
    final lightB = lightColorInt & 0xFF;

    final rad = lightAngle * math.pi / 180.0;
    // In image coordinate space (Y down), 90° (top) is -Y.
    final lx = math.cos(rad);
    final ly = -math.sin(rad);

    final result = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final a = (origPixel >> 24) & 0xFF;

        if (a == 0 && preserveAlpha) {
          result[idx] = 0;
          continue;
        }

        // Search nearest transparent background pixel to find silhouette contour & normal
        double normX = 0.0;
        double normY = 0.0;
        int nearestDist = 999;

        for (int dy = -thickness; dy <= thickness; dy++) {
          final ny = y + dy;
          for (int dx = -thickness; dx <= thickness; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;

            final isTransparent = (nx < 0 || nx >= width || ny < 0 || ny >= height)
                ? true
                : (((pixels[ny * width + nx] >> 24) & 0xFF) == 0);

            if (isTransparent) {
              final d = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
              if (d < nearestDist) {
                nearestDist = d;
              }
              // Normal points outward towards the transparent region
              normX += dx.toDouble();
              normY += dy.toDouble();
            }
          }
        }

        if (nearestDist <= thickness && (normX != 0 || normY != 0)) {
          final len = math.sqrt(normX * normX + normY * normY);
          final nxNorm = normX / len;
          final nyNorm = normY / len;

          // Dot product of surface contour outward normal with light direction
          final dot = nxNorm * lx + nyNorm * ly;
          final wrapped = (dot + wrap) / (1.0 + wrap);

          if (wrapped > 0.0) {
            final depthAttenuation = 1.0 - ((nearestDist - 1) / thickness) * 0.4;
            final factor = (wrapped * brightness * depthAttenuation).clamp(0.0, 1.5);

            final r = (origPixel >> 16) & 0xFF;
            final g = (origPixel >> 8) & 0xFF;
            final b = origPixel & 0xFF;

            // Additive/lighten blend with light color
            final outR = math.min(255, r + (lightR * factor).round());
            final outG = math.min(255, g + (lightG * factor).round());
            final outB = math.min(255, b + (lightB * factor).round());
            final outA = a == 0 ? 255 : a;

            result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
            continue;
          }
        }

        result[idx] = origPixel;
      }
    }

    return result;
  }
}
