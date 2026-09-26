part of 'effects.dart';

/// Applies directional lighting blends across sprites (such as overhead sunlight
/// vs ground lava/bounce reflection) along a configurable angle vector,
/// strictly confining the lighting to layer pixels when [preserveAlpha] is enabled.
class DirectionalLightRampEffect extends Effect {
  DirectionalLightRampEffect([Map<String, dynamic>? params])
      : super(
          EffectType.directionalLightRamp,
          params ??
              {
                'lightAngle': 270.0,
                'primaryLightColor': 0xFFFFE082,
                'secondaryLightColor': 0xFFFF3D00,
                'rampSpread': 1.0,
                'rampOffset': 0.0,
                'lightingBlend': 'overlay',
                'intensity': 0.75,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'lightAngle': 270.0,
        'primaryLightColor': 0xFFFFE082,
        'secondaryLightColor': 0xFFFF3D00,
        'rampSpread': 1.0,
        'rampOffset': 0.0,
        'lightingBlend': 'overlay',
        'intensity': 0.75,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'lightAngle': {
          'label': 'Light Angle',
          'description': 'Direction of the primary light source (270° = Top Sun, 90° = Bottom Lava).',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'step': 5.0,
        },
        'primaryLightColor': {
          'label': 'Primary Light Color',
          'description': 'Color of the dominant directional light source (top-side illumination).',
          'type': 'color',
        },
        'secondaryLightColor': {
          'label': 'Counter / Bounce Light Color',
          'description': 'Color of the opposing environmental light (bottom-side reflection/lava).',
          'type': 'color',
        },
        'rampSpread': {
          'label': 'Ramp Transition Spread',
          'description': 'Falloff steepness and blend gradient between primary and secondary lights.',
          'type': 'slider',
          'min': 0.2,
          'max': 2.5,
          'step': 0.1,
        },
        'rampOffset': {
          'label': 'Ramp Balance Offset',
          'description': 'Shifts light/shadow balance along the lighting vector.',
          'type': 'slider',
          'min': -1.0,
          'max': 1.0,
          'step': 0.05,
        },
        'lightingBlend': {
          'label': 'Lighting Blend Mode',
          'description': 'How the light ramp composites over the original sprite colors.',
          'type': 'dropdown',
          'options': [
            {'value': 'overlay', 'label': 'Overlay (Vibrant Dynamic Range)'},
            {'value': 'softLight', 'label': 'Soft Light (Subtle Atmospheric Wash)'},
            {'value': 'screen', 'label': 'Screen (Luminous Radiance)'},
            {'value': 'multiply', 'label': 'Multiply (Moody Shadow Shading)'},
          ],
        },
        'intensity': {
          'label': 'Light Intensity',
          'description': 'Overall blend strength of the directional light ramp.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine directional lighting strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'lightAngle',
          label: 'Light Angle',
          description: 'Direction of the primary light source (270° = Top Sun, 90° = Bottom Lava).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        const ColorField(
          key: 'primaryLightColor',
          label: 'Primary Light Color',
          description: 'Color of the dominant directional light source (top-side illumination).',
        ),
        const ColorField(
          key: 'secondaryLightColor',
          label: 'Counter / Bounce Light Color',
          description: 'Color of the opposing environmental light (bottom-side reflection/lava).',
        ),
        SliderField(
          key: 'rampSpread',
          label: 'Ramp Transition Spread',
          description: 'Falloff steepness and blend gradient between primary and secondary lights.',
          min: 0.2,
          max: 2.5,
          divisions: 23,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'rampOffset',
          label: 'Ramp Balance Offset',
          description: 'Shifts light/shadow balance along the lighting vector.',
          min: -1.0,
          max: 1.0,
          divisions: 40,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'lightingBlend',
          label: 'Lighting Blend Mode',
          description: 'How the light ramp composites over the original sprite colors.',
          options: {
            'overlay': 'Overlay (Vibrant Dynamic Range)',
            'softLight': 'Soft Light (Subtle Atmospheric Wash)',
            'screen': 'Screen (Luminous Radiance)',
            'multiply': 'Multiply (Moody Shadow Shading)',
          },
        ),
        SliderField(
          key: 'intensity',
          label: 'Light Intensity',
          description: 'Overall blend strength of the directional light ramp.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine directional lighting strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double angleDeg = ((parameters['lightAngle'] as num?)?.toDouble() ?? 270.0) % 360.0;
    final int priColor = (parameters['primaryLightColor'] as num?)?.toInt() ?? 0xFFFFE082;
    final int secColor = (parameters['secondaryLightColor'] as num?)?.toInt() ?? 0xFFFF3D00;
    final double spread = ((parameters['rampSpread'] as num?)?.toDouble() ?? 1.0).clamp(0.2, 2.5);
    final double offset = ((parameters['rampOffset'] as num?)?.toDouble() ?? 0.0).clamp(-1.0, 1.0);
    final String blendMode = parameters['lightingBlend'] as String? ?? 'overlay';
    final double intensity = ((parameters['intensity'] as num?)?.toDouble() ?? 0.75).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final double rad = angleDeg * (math.pi / 180.0);
    final double dirX = math.cos(rad);
    final double dirY = math.sin(rad);

    // Primary (top/head) light RGB
    final int priR = (priColor >> 16) & 0xFF;
    final int priG = (priColor >> 8) & 0xFF;
    final int priB = priColor & 0xFF;

    // Secondary (bottom/counter) light RGB
    final int secR = (secColor >> 16) & 0xFF;
    final int secG = (secColor >> 8) & 0xFF;
    final int secB = secColor & 0xFF;

    // Calculate projection range across canvas corners
    const double p0 = 0.0;
    final double p1 = (width - 1) * dirX;
    final double p2 = (height - 1) * dirY;
    final double p3 = (width - 1) * dirX + (height - 1) * dirY;

    final double minProj = math.min(math.min(p0, p1), math.min(p2, p3));
    final double maxProj = math.max(math.max(p0, p1), math.max(p2, p3));
    final double projRange = math.max(1.0, maxProj - minProj);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        final double p = x * dirX + y * dirY;
        final double rawT = (p - minProj) / projRange;

        // Apply spread and offset
        final double t = ((rawT - 0.5 - offset * 0.5) * spread + 0.5).clamp(0.0, 1.0);

        // Interpolated light color along the ramp
        final int lightR = (secR + (priR - secR) * t).round().clamp(0, 255);
        final int lightG = (secG + (priG - secG) * t).round().clamp(0, 255);
        final int lightB = (secB + (priB - secB) * t).round().clamp(0, 255);

        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        int blendedR;
        int blendedG;
        int blendedB;

        switch (blendMode) {
          case 'softLight':
            blendedR = _blendSoftLight(origR, lightR);
            blendedG = _blendSoftLight(origG, lightG);
            blendedB = _blendSoftLight(origB, lightB);
            break;
          case 'screen':
            blendedR = (255 - ((255 - origR) * (255 - lightR)) / 255.0).round().clamp(0, 255);
            blendedG = (255 - ((255 - origG) * (255 - lightG)) / 255.0).round().clamp(0, 255);
            blendedB = (255 - ((255 - origB) * (255 - lightB)) / 255.0).round().clamp(0, 255);
            break;
          case 'multiply':
            blendedR = ((origR * lightR) / 255.0).round().clamp(0, 255);
            blendedG = ((origG * lightG) / 255.0).round().clamp(0, 255);
            blendedB = ((origB * lightB) / 255.0).round().clamp(0, 255);
            break;
          case 'overlay':
          default:
            blendedR = _blendOverlay(origR, lightR);
            blendedG = _blendOverlay(origG, lightG);
            blendedB = _blendOverlay(origB, lightB);
            break;
        }

        final int finalR = (origR * (1.0 - intensity) + blendedR * intensity).round().clamp(0, 255);
        final int finalG = (origG * (1.0 - intensity) + blendedG * intensity).round().clamp(0, 255);
        final int finalB = (origB * (1.0 - intensity) + blendedB * intensity).round().clamp(0, 255);
        final int finalA = preserveAlpha ? origA : 255;

        output[idx] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return output;
  }

  static int _blendOverlay(int base, int blend) {
    if (base < 128) {
      return ((2 * base * blend) / 255.0).round().clamp(0, 255);
    } else {
      return (255 - (2 * (255 - base) * (255 - blend)) / 255.0).round().clamp(0, 255);
    }
  }

  static int _blendSoftLight(int base, int blend) {
    final double b = base / 255.0;
    final double s = blend / 255.0;
    double r;
    if (s <= 0.5) {
      r = b - (1.0 - 2.0 * s) * b * (1.0 - b);
    } else {
      final double d = (b <= 0.25) ? ((16.0 * b - 12.0) * b + 4.0) * b : math.sqrt(b);
      r = b + (2.0 * s - 1.0) * (d - b);
    }
    return (r * 255.0).round().clamp(0, 255);
  }
}
