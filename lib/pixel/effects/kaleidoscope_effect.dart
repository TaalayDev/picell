part of 'effects.dart';

/// Mirrors the source through radial wedges, with optional animated folding.
class KaleidoscopeEffect extends Effect {
  KaleidoscopeEffect([Map<String, dynamic>? params])
      : super(
            EffectType.kaleidoscope,
            params ??
                const {
                  'segments': 8,
                  'rotation': 0.0,
                  'foldAmount': 1.0,
                  'zoom': 1.0,
                  'centerX': 0.5,
                  'centerY': 0.5,
                  'speed': 0.35,
                  'time': 0.0,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'segments': 8,
        'rotation': 0.0,
        'foldAmount': 1.0,
        'zoom': 1.0,
        'centerX': 0.5,
        'centerY': 0.5,
        'speed': 0.35,
        'time': 0.0
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'segments': {
          'label': 'Mirror Segments',
          'type': 'slider',
          'min': 3,
          'max': 20,
          'divisions': 17
        },
        'rotation': {
          'label': 'Rotation',
          'description': 'Static rotation in degrees.',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'divisions': 72
        },
        'foldAmount': {
          'label': 'Fold Amount',
          'description': 'Blend between rotation and full mirrored folding.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'zoom': {
          'label': 'Zoom',
          'type': 'slider',
          'min': 0.5,
          'max': 2.0,
          'divisions': 75
        },
        'centerX': {
          'label': 'Center X',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'centerY': {
          'label': 'Center Y',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'speed': {
          'label': 'Animation Speed',
          'type': 'slider',
          'min': -2.0,
          'max': 2.0,
          'divisions': 80
        },
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final segments =
        ((parameters['segments'] as num?)?.toInt() ?? 8).clamp(3, 20);
    final fold =
        ((parameters['foldAmount'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0);
    final zoom =
        ((parameters['zoom'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 2.0);
    final cx =
        ((parameters['centerX'] as num?)?.toDouble() ?? 0.5) * (width - 1);
    final cy =
        ((parameters['centerY'] as num?)?.toDouble() ?? 0.5) * (height - 1);
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final speed = (parameters['speed'] as num?)?.toDouble() ?? 0.35;
    final rotation = (((parameters['rotation'] as num?)?.toDouble() ?? 0.0) +
            time * speed * 360.0) *
        math.pi /
        180.0;
    final wedge = 2.0 * math.pi / segments;
    final result = Uint32List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final radius = math.sqrt(dx * dx + dy * dy) / zoom;
        final originalAngle = math.atan2(dy, dx) - rotation;
        var local = ((originalAngle % wedge) + wedge) % wedge;
        if (local > wedge / 2.0) local = wedge - local;
        final foldedAngle = local + rotation;
        final sampleAngle = originalAngle +
            rotation +
            (foldedAngle - (originalAngle + rotation)) * fold;
        final sx = (cx + math.cos(sampleAngle) * radius).round();
        final sy = (cy + math.sin(sampleAngle) * radius).round();
        if (sx >= 0 && sx < width && sy >= 0 && sy < height) {
          result[y * width + x] = pixels[sy * width + sx];
        }
      }
    }
    return result;
  }
}
