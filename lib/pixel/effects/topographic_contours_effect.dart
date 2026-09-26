part of 'effects.dart';

/// Maps luminance to stepped elevation bands and contour lines.
class TopographicContoursEffect extends Effect {
  TopographicContoursEffect([Map<String, dynamic>? params])
      : super(
            EffectType.topographicContours,
            params ??
                const {
                  'levels': 10,
                  'lineWidth': 0.12,
                  'lineStrength': 0.9,
                  'tintStrength': 0.2,
                  'lineColor': 0xFF2D241E,
                  'tintColor': 0xFFC8B88A,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'levels': 10,
        'lineWidth': 0.12,
        'lineStrength': 0.9,
        'tintStrength': 0.2,
        'lineColor': 0xFF2D241E,
        'tintColor': 0xFFC8B88A,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'levels': {
          'label': 'Elevation Levels',
          'type': 'slider',
          'min': 3,
          'max': 32,
          'divisions': 29
        },
        'lineWidth': {
          'label': 'Contour Width',
          'type': 'slider',
          'min': 0.02,
          'max': 0.45,
          'divisions': 43
        },
        'lineStrength': {
          'label': 'Line Strength',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'tintStrength': {
          'label': 'Map Tint',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'lineColor': {'label': 'Contour Color', 'type': 'color'},
        'tintColor': {'label': 'Map Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final levels = ((parameters['levels'] as num?)?.toInt() ?? 10).clamp(3, 32);
    final lineWidth = ((parameters['lineWidth'] as num?)?.toDouble() ?? 0.12)
        .clamp(0.02, 0.45);
    final strength = ((parameters['lineStrength'] as num?)?.toDouble() ?? 0.9)
        .clamp(0.0, 1.0);
    final tintStrength =
        ((parameters['tintStrength'] as num?)?.toDouble() ?? 0.2)
            .clamp(0.0, 1.0);
    final lineColor = parameters['lineColor'] as int? ?? 0xFF2D241E;
    final tint = parameters['tintColor'] as int? ?? 0xFFC8B88A;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List(width * height);
    for (var i = 0; i < pixels.length; i++) {
      final alpha = (pixels[i] >> 24) & 0xff;
      if (preserveAlpha && alpha == 0) continue;
      final heightValue = _textureLuminance(pixels[i]) * levels;
      final fraction = heightValue - heightValue.floor();
      final distance = math.min(fraction, 1.0 - fraction);
      final contour = (1.0 - distance / lineWidth).clamp(0.0, 1.0) * strength;
      final tinted = _textureBlendColor(
          pixels[i], tint, tintStrength, preserveAlpha ? alpha : 255);
      result[i] = _textureBlendColor(
          tinted, lineColor, contour, preserveAlpha ? alpha : 255);
    }
    return result;
  }
}
