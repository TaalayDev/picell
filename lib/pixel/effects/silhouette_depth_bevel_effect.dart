part of 'effects.dart';

/// Applies 3D silhouette depth beveling, surface normal lighting, specular facet
/// highlights, and ambient occlusion crevices using an interior distance transform,
/// strictly confining the 3D volume to layer pixels when [preserveAlpha] is enabled.
class SilhouetteDepthBevelEffect extends Effect {
  SilhouetteDepthBevelEffect([Map<String, dynamic>? params])
      : super(
          EffectType.silhouetteDepthBevel,
          params ??
              {
                'bevelDepth': 3.0,
                'lightAngle': 315.0,
                'bevelProfile': 'smoothCurved',
                'specularIntensity': 0.65,
                'ambientOcclusion': 0.5,
                'highlightTint': 0xFFFFFFFF,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'bevelDepth': 3.0,
        'lightAngle': 315.0,
        'bevelProfile': 'smoothCurved',
        'specularIntensity': 0.65,
        'ambientOcclusion': 0.5,
        'highlightTint': 0xFFFFFFFF,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'bevelDepth': {
          'label': 'Bevel Depth',
          'description': 'Thickness of the 3D inner bevel rim in pixels.',
          'type': 'slider',
          'min': 1.0,
          'max': 12.0,
          'step': 0.5,
        },
        'lightAngle': {
          'label': 'Light Source Angle',
          'description': 'Direction of the virtual 3D light (315° = Top-Left, 45° = Top-Right).',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'step': 5.0,
        },
        'bevelProfile': {
          'label': 'Bevel Profile',
          'description': '3D curvature profile of the beveled edge.',
          'type': 'dropdown',
          'options': [
            {'value': 'smoothCurved', 'label': 'Smooth Pillowed (Spherical Cushion)'},
            {'value': 'chiseled', 'label': 'Chiseled Facet (Linear Angular)'},
            {'value': 'embossed', 'label': 'Raised Plateau (Rounded Ridge)'},
          ],
        },
        'specularIntensity': {
          'label': 'Specular Highlight',
          'description': 'Brightness of the illuminated 3D bevel edges.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'ambientOcclusion': {
          'label': 'Ambient Occlusion Shadow',
          'description': 'Crease depth and inner shadow darkness on opposite edges.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'highlightTint': {
          'label': 'Highlight Color',
          'description': 'Color tint of the illuminated specular edge reflections.',
          'type': 'color',
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine 3D bevel strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'bevelDepth',
          label: 'Bevel Depth',
          description: 'Thickness of the 3D inner bevel rim in pixels.',
          min: 1.0,
          max: 12.0,
          divisions: 22,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'lightAngle',
          label: 'Light Source Angle',
          description: 'Direction of the virtual 3D light (315° = Top-Left, 45° = Top-Right).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        const SelectField(
          key: 'bevelProfile',
          label: 'Bevel Profile',
          description: '3D curvature profile of the beveled edge.',
          options: {
            'smoothCurved': 'Smooth Pillowed (Spherical Cushion)',
            'chiseled': 'Chiseled Facet (Linear Angular)',
            'embossed': 'Raised Plateau (Rounded Ridge)',
          },
        ),
        SliderField(
          key: 'specularIntensity',
          label: 'Specular Highlight',
          description: 'Brightness of the illuminated 3D bevel edges.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'ambientOcclusion',
          label: 'Ambient Occlusion Shadow',
          description: 'Crease depth and inner shadow darkness on opposite edges.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const ColorField(
          key: 'highlightTint',
          label: 'Highlight Color',
          description: 'Color tint of the illuminated specular edge reflections.',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine 3D bevel strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double depth = ((parameters['bevelDepth'] as num?)?.toDouble() ?? 3.0).clamp(1.0, 12.0);
    final double angleDeg = ((parameters['lightAngle'] as num?)?.toDouble() ?? 315.0) % 360.0;
    final String profile = parameters['bevelProfile'] as String? ?? 'smoothCurved';
    final double specular = ((parameters['specularIntensity'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0);
    final double ao = ((parameters['ambientOcclusion'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final int tintColor = (parameters['highlightTint'] as num?)?.toInt() ?? 0xFFFFFFFF;
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final int tintR = (tintColor >> 16) & 0xFF;
    final int tintG = (tintColor >> 8) & 0xFF;
    final int tintB = tintColor & 0xFF;

    final double rad = angleDeg * (math.pi / 180.0);
    final double lightDirX = math.cos(rad);
    final double lightDirY = math.sin(rad);

    // Step 1: Initialize Distance Field
    final distMap = Float64List(width * height);
    const double infinity = 1e6;

    for (int i = 0; i < pixels.length; i++) {
      final int a = (pixels[i] >> 24) & 0xFF;
      distMap[i] = (a == 0) ? 0.0 : infinity;
    }

    // Step 2: 2-Pass Distance Transform (Chamfer metric: orthogonal = 1.0, diagonal = 1.414)
    // Pass 1: Top-Left to Bottom-Right
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final double d = distMap[idx];
        if (d == 0.0) continue;

        double minD = d;
        if (x > 0) {
          final double left = distMap[idx - 1] + 1.0;
          if (left < minD) minD = left;
        }
        if (y > 0) {
          final double top = distMap[idx - width] + 1.0;
          if (top < minD) minD = top;

          if (x > 0) {
            final double topLeft = distMap[idx - width - 1] + 1.414;
            if (topLeft < minD) minD = topLeft;
          }
          if (x < width - 1) {
            final double topRight = distMap[idx - width + 1] + 1.414;
            if (topRight < minD) minD = topRight;
          }
        }
        distMap[idx] = minD;
      }
    }

    // Pass 2: Bottom-Right to Top-Left
    for (int y = height - 1; y >= 0; y--) {
      for (int x = width - 1; x >= 0; x--) {
        final int idx = y * width + x;
        final double d = distMap[idx];
        if (d == 0.0) continue;

        double minD = d;
        if (x < width - 1) {
          final double right = distMap[idx + 1] + 1.0;
          if (right < minD) minD = right;
        }
        if (y < height - 1) {
          final double bottom = distMap[idx + width] + 1.0;
          if (bottom < minD) minD = bottom;

          if (x < width - 1) {
            final double bottomRight = distMap[idx + width + 1] + 1.414;
            if (bottomRight < minD) minD = bottomRight;
          }
          if (x > 0) {
            final double bottomLeft = distMap[idx + width - 1] + 1.414;
            if (bottomLeft < minD) minD = bottomLeft;
          }
        }
        distMap[idx] = minD;
      }
    }

    // Step 3: Compute Surface Normals and 3D Bevel Shading
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;

        if (origA == 0) {
          output[idx] = 0;
          continue;
        }

        final double d = distMap[idx];

        // Central flat interior plateau
        if (d >= depth) {
          output[idx] = origPixel;
          continue;
        }

        // Gradient of distance field (points inward toward interior)
        final double dLeft = (x > 0) ? distMap[idx - 1] : 0.0;
        final double dRight = (x < width - 1) ? distMap[idx + 1] : 0.0;
        final double dTop = (y > 0) ? distMap[idx - width] : 0.0;
        final double dBottom = (y < height - 1) ? distMap[idx + width] : 0.0;

        // Inward surface gradient vector
        final double gx = (dRight - dLeft) * 0.5;
        final double gy = (dBottom - dTop) * 0.5;
        final double gradLen = math.sqrt(gx * gx + gy * gy) + 0.001;

        // Outward surface slope normal facing towards the perimeter edge
        final double nx = -gx / gradLen;
        final double ny = -gy / gradLen;

        // Normalized distance within bevel rim [0, 1]
        final double u = (d / depth).clamp(0.0, 1.0);

        // Curvature weight depending on profile
        double slopeWeight;
        if (profile == 'chiseled') {
          slopeWeight = 1.0 - u * 0.5;
        } else if (profile == 'embossed') {
          slopeWeight = (1.0 - u * u);
        } else {
          // 'smoothCurved': spherical pillow arc
          slopeWeight = math.sqrt((1.0 - u * u).clamp(0.0, 1.0));
        }

        // Dot product with directional light vector
        // Light vector points towards light source, outward normal points toward silhouette edge
        final double dot = (nx * lightDirX + ny * lightDirY);

        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        int finalR = origR;
        int finalG = origG;
        int finalB = origB;

        if (dot > 0.0 && specular > 0.01) {
          // Illuminated bevel edge face
          final double specFactor = dot * specular * slopeWeight;
          finalR = (origR + (tintR - origR) * specFactor + 255 * specFactor * 0.35).clamp(0, 255).round();
          finalG = (origG + (tintG - origG) * specFactor + 255 * specFactor * 0.35).clamp(0, 255).round();
          finalB = (origB + (tintB - origB) * specFactor + 255 * specFactor * 0.35).clamp(0, 255).round();
        } else if (dot < 0.0 && ao > 0.01) {
          // Shadow-facing bevel face (Ambient Occlusion Crevice)
          final double shadowFactor = (-dot) * ao * slopeWeight;
          final double darken = (1.0 - shadowFactor * 0.75).clamp(0.15, 1.0);
          finalR = (origR * darken).clamp(0, 255).round();
          finalG = (origG * darken).clamp(0, 255).round();
          finalB = (origB * darken).clamp(0, 255).round();
        }

        final int finalA = preserveAlpha ? origA : 255;
        output[idx] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return output;
  }
}
