part of 'effects.dart';

/// Remaps perceptual pixel luminance (shadows to highlights) through
/// multi-stop color gradients with optional Bayer dithering and blend modes,
/// strictly confining the color mapping to layer pixels when [preserveAlpha] is enabled.
class LuminanceGradientMapEffect extends Effect {
  LuminanceGradientMapEffect([Map<String, dynamic>? params])
      : super(
          EffectType.luminanceGradientMap,
          params ??
              {
                'palette': 'cyberpunkNeon',
                'shadowColor': 0xFF1A0033,
                'midColor': 0xFFE0115F,
                'highlightColor': 0xFF00F5D4,
                'contrastBoost': 1.0,
                'ditherBands': true,
                'blendMode': 'replace',
                'blendStrength': 1.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'palette': 'cyberpunkNeon',
        'shadowColor': 0xFF1A0033,
        'midColor': 0xFFE0115F,
        'highlightColor': 0xFF00F5D4,
        'contrastBoost': 1.0,
        'ditherBands': true,
        'blendMode': 'replace',
        'blendStrength': 1.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'palette': {
          'label': 'Gradient Palette',
          'description': 'Curated multi-stop gradient color ramp from shadows to highlights.',
          'type': 'dropdown',
          'options': [
            {'value': 'cyberpunkNeon', 'label': 'Cyberpunk Neon (Violet / Magenta / Cyan)'},
            {'value': 'gameboyClassic', 'label': 'Game Boy Classic (4-Shade Olive)'},
            {'value': 'heatVision', 'label': 'Thermal Heat Vision (Crimson / Amber)'},
            {'value': 'vaporwaveSunset', 'label': 'Vaporwave Sunset (Navy / Coral / Gold)'},
            {'value': 'monochromeNoir', 'label': 'Film Noir (Charcoal / Slate / White)'},
            {'value': 'emeraldForest', 'label': 'Emerald Forest (Pine / Jade / Lime)'},
            {'value': 'custom', 'label': 'Custom 3-Stop Ramp'},
          ],
        },
        'shadowColor': {
          'label': 'Shadow Color (Custom)',
          'description': 'Base color mapped to deepest shadow tones.',
          'type': 'color',
        },
        'midColor': {
          'label': 'Midtone Color (Custom)',
          'description': 'Color mapped to medium luminance midtones.',
          'type': 'color',
        },
        'highlightColor': {
          'label': 'Highlight Color (Custom)',
          'description': 'Color mapped to specular highlights.',
          'type': 'color',
        },
        'contrastBoost': {
          'label': 'Contrast Boost',
          'description': 'Adjusts dynamic range curve before color remapping.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.5,
          'step': 0.1,
        },
        'ditherBands': {
          'label': 'Bayer Dithering',
          'description': 'Ordered matrix dithering to eliminate harsh banding between gradient steps.',
          'type': 'bool',
        },
        'blendMode': {
          'label': 'Blend Mode',
          'description': 'How the gradient map is composited over the original image.',
          'type': 'dropdown',
          'options': [
            {'value': 'replace', 'label': 'Replace (Full Remap)'},
            {'value': 'overlay', 'label': 'Overlay (Retain Texture)'},
            {'value': 'softLight', 'label': 'Soft Light (Subtle Wash)'},
            {'value': 'multiply', 'label': 'Multiply (Moody Tint)'},
          ],
        },
        'blendStrength': {
          'label': 'Blend Strength',
          'description': 'Intensity of the gradient map application.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine gradient remapping strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'palette',
          label: 'Gradient Palette',
          description: 'Curated multi-stop gradient color ramp from shadows to highlights.',
          options: {
            'cyberpunkNeon': 'Cyberpunk Neon (Violet / Magenta / Cyan)',
            'gameboyClassic': 'Game Boy Classic (4-Shade Olive)',
            'heatVision': 'Thermal Heat Vision (Crimson / Amber)',
            'vaporwaveSunset': 'Vaporwave Sunset (Navy / Coral / Gold)',
            'monochromeNoir': 'Film Noir (Charcoal / Slate / White)',
            'emeraldForest': 'Emerald Forest (Pine / Jade / Lime)',
            'custom': 'Custom 3-Stop Ramp',
          },
        ),
        const ColorField(
          key: 'shadowColor',
          label: 'Shadow Color (Custom)',
          description: 'Base color mapped to deepest shadow tones.',
        ),
        const ColorField(
          key: 'midColor',
          label: 'Midtone Color (Custom)',
          description: 'Color mapped to medium luminance midtones.',
        ),
        const ColorField(
          key: 'highlightColor',
          label: 'Highlight Color (Custom)',
          description: 'Color mapped to specular highlights.',
        ),
        SliderField(
          key: 'contrastBoost',
          label: 'Contrast Boost',
          description: 'Adjusts dynamic range curve before color remapping.',
          min: 0.5,
          max: 2.5,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const BoolField(
          key: 'ditherBands',
          label: 'Bayer Dithering',
          description: 'Ordered matrix dithering to eliminate harsh banding between gradient steps.',
        ),
        const SelectField(
          key: 'blendMode',
          label: 'Blend Mode',
          description: 'How the gradient map is composited over the original image.',
          options: {
            'replace': 'Replace (Full Remap)',
            'overlay': 'Overlay (Retain Texture)',
            'softLight': 'Soft Light (Subtle Wash)',
            'multiply': 'Multiply (Moody Tint)',
          },
        ),
        SliderField(
          key: 'blendStrength',
          label: 'Blend Strength',
          description: 'Intensity of the gradient map application.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine gradient remapping strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  static const List<int> _bayer4x4 = [
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5,
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final String paletteName = parameters['palette'] as String? ?? 'cyberpunkNeon';
    final double contrast = ((parameters['contrastBoost'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 2.5);
    final bool dither = parameters['ditherBands'] as bool? ?? true;
    final String blendMode = parameters['blendMode'] as String? ?? 'replace';
    final double strength = ((parameters['blendStrength'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    // Resolve gradient color stops
    final List<_GradientStop> stops = _resolveStops(paletteName);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        // Rec. 709 / sRGB perceptual luminance
        double luma = (0.299 * origR + 0.587 * origG + 0.114 * origB) / 255.0;

        // Contrast adjustment centered at 0.5
        if ((contrast - 1.0).abs() > 0.01) {
          luma = ((luma - 0.5) * contrast + 0.5).clamp(0.0, 1.0);
        }

        // Bayer dither jitter across gradient stop boundaries
        if (dither) {
          final int bx = x & 3;
          final int by = y & 3;
          final double bNorm = (_bayer4x4[by * 4 + bx] / 15.0) - 0.5; // -0.5 to +0.5
          luma = (luma + bNorm * 0.08).clamp(0.0, 1.0);
        }

        // Interpolate along gradient stops
        int mapR = stops.first.r;
        int mapG = stops.first.g;
        int mapB = stops.first.b;

        for (int s = 0; s < stops.length - 1; s++) {
          final _GradientStop s0 = stops[s];
          final _GradientStop s1 = stops[s + 1];

          if (luma >= s0.pos && luma <= s1.pos) {
            final double range = s1.pos - s0.pos;
            final double t = range > 0.0001 ? ((luma - s0.pos) / range).clamp(0.0, 1.0) : 0.0;
            mapR = (s0.r + (s1.r - s0.r) * t).round().clamp(0, 255);
            mapG = (s0.g + (s1.g - s0.g) * t).round().clamp(0, 255);
            mapB = (s0.b + (s1.b - s0.b) * t).round().clamp(0, 255);
            break;
          } else if (luma > stops.last.pos) {
            mapR = stops.last.r;
            mapG = stops.last.g;
            mapB = stops.last.b;
          }
        }

        // Apply blending
        int finalR;
        int finalG;
        int finalB;

        switch (blendMode) {
          case 'overlay':
            finalR = _blendOverlay(origR, mapR);
            finalG = _blendOverlay(origG, mapG);
            finalB = _blendOverlay(origB, mapB);
            break;
          case 'softLight':
            finalR = _blendSoftLight(origR, mapR);
            finalG = _blendSoftLight(origG, mapG);
            finalB = _blendSoftLight(origB, mapB);
            break;
          case 'multiply':
            finalR = ((origR * mapR) / 255.0).round().clamp(0, 255);
            finalG = ((origG * mapG) / 255.0).round().clamp(0, 255);
            finalB = ((origB * mapB) / 255.0).round().clamp(0, 255);
            break;
          case 'replace':
          default:
            finalR = mapR;
            finalG = mapG;
            finalB = mapB;
            break;
        }

        if (strength < 0.999) {
          finalR = (origR * (1.0 - strength) + finalR * strength).round().clamp(0, 255);
          finalG = (origG * (1.0 - strength) + finalG * strength).round().clamp(0, 255);
          finalB = (origB * (1.0 - strength) + finalB * strength).round().clamp(0, 255);
        }

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

  List<_GradientStop> _resolveStops(String paletteName) {
    switch (paletteName) {
      case 'gameboyClassic':
        return const [
          _GradientStop(0.0, 15, 56, 15),     // #0F380F Deepest Olive
          _GradientStop(0.33, 48, 98, 48),    // #306230 Dark Olive
          _GradientStop(0.66, 139, 172, 15),  // #8BAC0F Light Green
          _GradientStop(1.0, 155, 188, 15),   // #9BBC0F Pale Bright Olive
        ];
      case 'heatVision':
        return const [
          _GradientStop(0.0, 0, 0, 0),         // Pure Black
          _GradientStop(0.28, 183, 28, 28),    // Deep Crimson
          _GradientStop(0.62, 255, 152, 0),    // Vibrant Amber
          _GradientStop(0.88, 255, 238, 88),   // Hot Pale Yellow
          _GradientStop(1.0, 255, 255, 255),   // Specular White
        ];
      case 'vaporwaveSunset':
        return const [
          _GradientStop(0.0, 27, 20, 100),     // Midnight Navy
          _GradientStop(0.35, 131, 58, 180),   // Violet Purple
          _GradientStop(0.70, 253, 29, 29),    // Radiant Coral Red
          _GradientStop(1.0, 252, 176, 69),    // Sunset Golden Yellow
        ];
      case 'monochromeNoir':
        return const [
          _GradientStop(0.0, 18, 18, 18),      // Charcoal Black
          _GradientStop(0.33, 74, 74, 74),     // Dark Slate
          _GradientStop(0.66, 189, 189, 189),  // Silver Grey
          _GradientStop(1.0, 255, 255, 255),   // Crisp White
        ];
      case 'emeraldForest':
        return const [
          _GradientStop(0.0, 5, 26, 16),       // Pine Shadow
          _GradientStop(0.30, 27, 77, 62),     // Forest Moss
          _GradientStop(0.65, 46, 139, 87),    // Jade Sea Green
          _GradientStop(0.88, 167, 244, 50),   // Radiant Chartreuse
          _GradientStop(1.0, 240, 255, 240),   // Mint Highlight
        ];
      case 'custom':
        final int sc = (parameters['shadowColor'] as num?)?.toInt() ?? 0xFF1A0033;
        final int mc = (parameters['midColor'] as num?)?.toInt() ?? 0xFFE0115F;
        final int hc = (parameters['highlightColor'] as num?)?.toInt() ?? 0xFF00F5D4;
        return [
          _GradientStop(0.0, (sc >> 16) & 0xFF, (sc >> 8) & 0xFF, sc & 0xFF),
          _GradientStop(0.5, (mc >> 16) & 0xFF, (mc >> 8) & 0xFF, mc & 0xFF),
          _GradientStop(1.0, (hc >> 16) & 0xFF, (hc >> 8) & 0xFF, hc & 0xFF),
        ];
      case 'cyberpunkNeon':
      default:
        return const [
          _GradientStop(0.0, 26, 0, 51),       // Deep Dark Purple
          _GradientStop(0.35, 224, 17, 95),    // Hot Neon Magenta
          _GradientStop(0.70, 0, 245, 212),    // Bright Electric Cyan
          _GradientStop(1.0, 255, 255, 255),   // Specular White
        ];
    }
  }
}

class _GradientStop {
  final double pos;
  final int r;
  final int g;
  final int b;
  const _GradientStop(this.pos, this.r, this.g, this.b);
}
