part of 'effects.dart';

/// Overlays clustered moss and pale lichen while retaining the base material.
class MossLichenEffect extends Effect {
  MossLichenEffect([Map<String, dynamic>? params])
      : super(
            EffectType.mossLichen,
            params ??
                const {
                  'coverage': 0.42,
                  'scale': 10,
                  'edgeGrowth': 0.6,
                  'lichenMix': 0.38,
                  'mossColor': 0xFF4F772D,
                  'lichenColor': 0xFFA7C957,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'coverage': 0.42,
        'scale': 10,
        'edgeGrowth': 0.6,
        'lichenMix': 0.38,
        'mossColor': 0xFF4F772D,
        'lichenColor': 0xFFA7C957,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'coverage': {
          'label': 'Growth Coverage',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'scale': {
          'label': 'Cluster Scale',
          'type': 'slider',
          'min': 3,
          'max': 28,
          'divisions': 25
        },
        'edgeGrowth': {
          'label': 'Edge Preference',
          'description': 'Encourage growth beside silhouettes and crevices.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'lichenMix': {
          'label': 'Lichen Amount',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'mossColor': {'label': 'Moss Color', 'type': 'color'},
        'lichenColor': {'label': 'Lichen Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final coverage =
        ((parameters['coverage'] as num?)?.toDouble() ?? 0.42).clamp(0.0, 1.0);
    final scale = ((parameters['scale'] as num?)?.toInt() ?? 10).clamp(3, 28);
    final edgeGrowth =
        ((parameters['edgeGrowth'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final lichenMix =
        ((parameters['lichenMix'] as num?)?.toDouble() ?? 0.38).clamp(0.0, 1.0);
    final moss = parameters['mossColor'] as int? ?? 0xFF4F772D;
    final lichen = parameters['lichenColor'] as int? ?? 0xFFA7C957;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List.fromList(pixels);
    bool isOpen(int x, int y) =>
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
        final nearEdge = isOpen(x - 1, y) ||
            isOpen(x + 1, y) ||
            isOpen(x, y - 1) ||
            isOpen(x, y + 1);
        final cluster = _textureFbm(x / scale, y / scale, 401);
        final shade = 1.0 - _textureLuminance(pixels[i]);
        final growth =
            cluster + shade * 0.18 + (nearEdge ? edgeGrowth * 0.24 : 0.0);
        final mask =
            ((growth - (0.92 - coverage * 0.58)) * 3.2).clamp(0.0, 1.0) *
                coverage;
        if (mask <= 0) continue;
        final lichenPatch =
            _textureFbm(x / (scale * 0.42), y / (scale * 0.42), 419) >
                0.68 - lichenMix * 0.25;
        final color = lichenPatch ? lichen : moss;
        final speckle = 0.7 + _textureHash(x, y, 431) * 0.3;
        result[i] = _textureBlendColor(pixels[i], color, mask * speckle * 0.88,
            preserveAlpha ? alpha : 255);
      }
    }
    return result;
  }
}
