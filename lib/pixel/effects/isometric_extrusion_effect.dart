part of 'effects.dart';

/// Projects opaque pixels into a blocky directional depth layer.
class IsometricExtrusionEffect extends Effect {
  IsometricExtrusionEffect([Map<String, dynamic>? params])
      : super(
            EffectType.isometricExtrusion,
            params ??
                const {
                  'depth': 6,
                  'direction': 'downRight',
                  'shade': 0.55,
                  'sideColor': 0xFF3949AB,
                  'useSourceColor': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'depth': 6,
        'direction': 'downRight',
        'shade': 0.55,
        'sideColor': 0xFF3949AB,
        'useSourceColor': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'depth': {
          'label': 'Extrusion Depth',
          'type': 'slider',
          'min': 1,
          'max': 24,
          'divisions': 23
        },
        'direction': {
          'label': 'Direction',
          'type': 'select',
          'options': {
            'downRight': 'Down Right',
            'downLeft': 'Down Left',
            'upRight': 'Up Right',
            'upLeft': 'Up Left'
          }
        },
        'shade': {
          'label': 'Side Shading',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'sideColor': {'label': 'Side Color', 'type': 'color'},
        'useSourceColor': {
          'label': 'Tint Source Colors',
          'description': 'Use each source pixel as the base extrusion color.',
          'type': 'bool'
        },
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final depth = ((parameters['depth'] as num?)?.toInt() ?? 6).clamp(1, 24);
    final direction = parameters['direction'] as String? ?? 'downRight';
    final shade =
        ((parameters['shade'] as num?)?.toDouble() ?? 0.55).clamp(0.0, 1.0);
    final side = parameters['sideColor'] as int? ?? 0xFF3949AB;
    final useSource = parameters['useSourceColor'] as bool? ?? true;
    final dx = direction.endsWith('Left') ? -1 : 1;
    final dy = direction.startsWith('up') ? -1 : 1;
    final result = Uint32List(width * height);
    for (var step = depth; step >= 1; step--) {
      final fade = 0.35 + 0.65 * (step / depth);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final source = pixels[y * width + x];
          final alpha = (source >> 24) & 0xff;
          if (alpha == 0) continue;
          final tx = x + dx * step;
          final ty = y + dy * step;
          if (tx < 0 || tx >= width || ty < 0 || ty >= height) continue;
          final base = useSource ? source : side;
          final color =
              _textureBlendColor(base, side, shade, (alpha * fade).round());
          result[ty * width + tx] = color;
        }
      }
    }
    for (var i = 0; i < pixels.length; i++) {
      if (((pixels[i] >> 24) & 0xff) != 0) result[i] = pixels[i];
    }
    return result;
  }
}
