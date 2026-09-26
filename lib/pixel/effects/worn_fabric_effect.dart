part of 'effects.dart';

/// Textile weave with faded fibers, abrasion, and optional edge fraying.
class WornFabricEffect extends Effect {
  WornFabricEffect([Map<String, dynamic>? params])
      : super(
            EffectType.wornFabric,
            params ??
                const {
                  'pattern': 0,
                  'threadSpacing': 3,
                  'weaveStrength': 0.42,
                  'wear': 0.3,
                  'fray': 0.18,
                  'threadColor': 0xFFD7D2C8,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'pattern': 0,
        'threadSpacing': 3,
        'weaveStrength': 0.42,
        'wear': 0.3,
        'fray': 0.18,
        'threadColor': 0xFFD7D2C8,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'pattern': {
          'label': 'Weave',
          'description': 'Choose plain, twill, or basket weaving.',
          'type': 'select',
          'options': {0: 'Plain', 1: 'Twill', 2: 'Basket'}
        },
        'threadSpacing': {
          'label': 'Thread Spacing',
          'type': 'slider',
          'min': 2,
          'max': 8,
          'divisions': 6
        },
        'weaveStrength': {
          'label': 'Weave Relief',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'wear': {
          'label': 'Wear & Fading',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'fray': {
          'label': 'Edge Fraying',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'threadColor': {'label': 'Exposed Fiber', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final pattern = ((parameters['pattern'] as num?)?.toInt() ?? 0).clamp(0, 2);
    final spacing =
        ((parameters['threadSpacing'] as num?)?.toInt() ?? 3).clamp(2, 8);
    final strength = ((parameters['weaveStrength'] as num?)?.toDouble() ?? 0.42)
        .clamp(0.0, 1.0);
    final wear =
        ((parameters['wear'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final fray =
        ((parameters['fray'] as num?)?.toDouble() ?? 0.18).clamp(0.0, 1.0);
    final fiber = parameters['threadColor'] as int? ?? 0xFFD7D2C8;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List.fromList(pixels);
    bool transparentAt(int x, int y) =>
        x < 0 ||
        y < 0 ||
        x >= width ||
        y >= height ||
        ((pixels[y * width + x] >> 24) & 0xff) == 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final edge = transparentAt(x - 1, y) ||
            transparentAt(x + 1, y) ||
            transparentAt(x, y - 1) ||
            transparentAt(x, y + 1);
        if (edge && preserveAlpha && _textureHash(x, y, 211) < fray * 0.3) {
          result[i] = 0;
          continue;
        }
        final warp = x % spacing == 0;
        final weft = y % spacing == 0;
        final twill = (x + y * 2) % (spacing * 2) < 2;
        final basket = (x ~/ spacing + y ~/ spacing).isEven && (warp || weft);
        final thread =
            switch (pattern) { 1 => twill, 2 => basket, _ => warp || weft };
        final abrasion = _textureFbm(x / 9.0, y / 7.0, 223);
        var blend = thread ? strength * 0.28 : 0.0;
        if (abrasion > 0.76 - wear * 0.38) blend += wear * 0.48;
        result[i] = _textureBlendColor(pixels[i], fiber, blend.clamp(0.0, 0.82),
            preserveAlpha ? alpha : 255);
      }
    }
    return result;
  }
}
