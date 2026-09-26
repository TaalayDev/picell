part of 'effects.dart';

/// Fired ceramic glaze with cellular crazing, chips, and specular highlights.
class CrackedCeramicEffect extends Effect {
  CrackedCeramicEffect([Map<String, dynamic>? params])
      : super(
            EffectType.crackedCeramic,
            params ??
                const {
                  'cellSize': 14,
                  'crackAmount': 0.58,
                  'crackWidth': 0.16,
                  'chips': 0.12,
                  'gloss': 0.45,
                  'glazeColor': 0xFFB2DFDB,
                  'crackColor': 0xFF37474F,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'cellSize': 14,
        'crackAmount': 0.58,
        'crackWidth': 0.16,
        'chips': 0.12,
        'gloss': 0.45,
        'glazeColor': 0xFFB2DFDB,
        'crackColor': 0xFF37474F,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'cellSize': {
          'label': 'Crazing Scale',
          'type': 'slider',
          'min': 5,
          'max': 32,
          'divisions': 27
        },
        'crackAmount': {
          'label': 'Crack Density',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'crackWidth': {
          'label': 'Crack Width',
          'type': 'slider',
          'min': 0.03,
          'max': 0.45,
          'divisions': 42
        },
        'chips': {
          'label': 'Chipped Glaze',
          'type': 'slider',
          'min': 0.0,
          'max': 0.6,
          'divisions': 60
        },
        'gloss': {
          'label': 'Glaze Gloss',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'glazeColor': {'label': 'Glaze Color', 'type': 'color'},
        'crackColor': {'label': 'Crack Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final cell = ((parameters['cellSize'] as num?)?.toInt() ?? 14).clamp(5, 32);
    final amount = ((parameters['crackAmount'] as num?)?.toDouble() ?? 0.58)
        .clamp(0.0, 1.0);
    final crackWidth = ((parameters['crackWidth'] as num?)?.toDouble() ?? 0.16)
        .clamp(0.03, 0.45);
    final chips =
        ((parameters['chips'] as num?)?.toDouble() ?? 0.12).clamp(0.0, 0.6);
    final gloss =
        ((parameters['gloss'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final glaze = parameters['glazeColor'] as int? ?? 0xFFB2DFDB;
    final crackColor = parameters['crackColor'] as int? ?? 0xFF37474F;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final gx = x ~/ cell;
        final gy = y ~/ cell;
        var nearest = double.infinity;
        var second = double.infinity;
        for (var oy = -1; oy <= 1; oy++) {
          for (var ox = -1; ox <= 1; ox++) {
            final cx = (gx + ox + _textureHash(gx + ox, gy + oy, 307)) * cell;
            final cy = (gy + oy + _textureHash(gx + ox, gy + oy, 311)) * cell;
            final distance =
                math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
            if (distance < nearest) {
              second = nearest;
              nearest = distance;
            } else if (distance < second) {
              second = distance;
            }
          }
        }
        final boundary = ((second - nearest) / cell).abs();
        final isCrack = boundary < crackWidth * amount;
        final chipNoise = _textureFbm(x / 4.0, y / 4.0, 331);
        final isChip = chips > 0 && chipNoise > 0.96 - chips * 0.28;
        var base = _textureBlendColor(
            pixels[i], glaze, 0.72, preserveAlpha ? alpha : 255);
        if (isCrack || isChip) {
          base = _textureBlendColor(base, crackColor, isChip ? 0.82 : 0.7,
              preserveAlpha ? alpha : 255);
        } else {
          final shine =
              math.max(0.0, 1.0 - ((x + y) % math.max(3, cell ~/ 2)) / 2.0);
          base = _textureBlendColor(base, 0xFFFFFFFF, shine * gloss * 0.14,
              preserveAlpha ? alpha : 255);
        }
        result[i] = base;
      }
    }
    return result;
  }
}
