part of 'effects.dart';

/// Oxidized metal with layered rust blooms, pits, and rain streaks.
class RustCorrosionEffect extends Effect {
  RustCorrosionEffect([Map<String, dynamic>? params])
      : super(
            EffectType.rustCorrosion,
            params ??
                const {
                  'amount': 0.58,
                  'scale': 12,
                  'pitting': 0.35,
                  'streaks': 0.3,
                  'rustColor': 0xFFB44719,
                  'darkRustColor': 0xFF55230F,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'amount': 0.58,
        'scale': 12,
        'pitting': 0.35,
        'streaks': 0.3,
        'rustColor': 0xFFB44719,
        'darkRustColor': 0xFF55230F,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'amount': {
          'label': 'Corrosion',
          'description': 'Overall oxidized surface coverage.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'scale': {
          'label': 'Rust Scale',
          'description': 'Size of clustered corrosion blooms.',
          'type': 'slider',
          'min': 3,
          'max': 32,
          'divisions': 29
        },
        'pitting': {
          'label': 'Pitting',
          'description': 'Amount of dark porous damage.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'streaks': {
          'label': 'Rain Streaks',
          'description': 'Strength of downward rust trails.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'rustColor': {'label': 'Rust Color', 'type': 'color'},
        'darkRustColor': {'label': 'Deep Rust Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final amount =
        ((parameters['amount'] as num?)?.toDouble() ?? 0.58).clamp(0.0, 1.0);
    final scale = ((parameters['scale'] as num?)?.toInt() ?? 12).clamp(3, 32);
    final pitting =
        ((parameters['pitting'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final streaks =
        ((parameters['streaks'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final rust = parameters['rustColor'] as int? ?? 0xFFB44719;
    final dark = parameters['darkRustColor'] as int? ?? 0xFF55230F;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final bloom = _textureFbm(x / scale, y / scale, 41);
        final drip = _textureFbm(x / (scale * 0.45), y / (scale * 2.8), 73);
        final mask = (bloom * (1.0 - streaks * 0.35) + drip * streaks * 0.55);
        final coverage =
            (((mask - (0.72 - amount * 0.62)) * 3.0).clamp(0.0, 1.0) * amount)
                .clamp(0.0, 1.0);
        final pit = _textureHash(x, y, 107) < pitting * coverage * 0.22;
        final rustTone = _textureBlendColor(
            rust, dark, pit ? 0.9 : (1.0 - bloom) * 0.55, 255);
        result[i] = _textureBlendColor(pixels[i], rustTone,
            pit ? coverage : coverage * 0.88, preserveAlpha ? alpha : 255);
      }
    }
    return result;
  }
}
