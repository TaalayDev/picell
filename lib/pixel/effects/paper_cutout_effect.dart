part of 'effects.dart';

/// Quantizes artwork into layered paper shapes with stepped shadows.
class PaperCutoutEffect extends Effect {
  PaperCutoutEffect([Map<String, dynamic>? params])
      : super(
            EffectType.paperCutout,
            params ??
                const {
                  'layers': 5,
                  'shadowOffset': 2,
                  'shadowStrength': 0.45,
                  'paperGrain': 0.12,
                  'colorBoost': 0.15,
                  'shadowColor': 0xFF382B26,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'layers': 5,
        'shadowOffset': 2,
        'shadowStrength': 0.45,
        'paperGrain': 0.12,
        'colorBoost': 0.15,
        'shadowColor': 0xFF382B26,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'layers': {
          'label': 'Paper Layers',
          'type': 'slider',
          'min': 2,
          'max': 12,
          'divisions': 10
        },
        'shadowOffset': {
          'label': 'Shadow Offset',
          'type': 'slider',
          'min': 0,
          'max': 6,
          'divisions': 6
        },
        'shadowStrength': {
          'label': 'Shadow Strength',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'paperGrain': {
          'label': 'Paper Grain',
          'type': 'slider',
          'min': 0.0,
          'max': 0.5,
          'divisions': 50
        },
        'colorBoost': {
          'label': 'Color Boost',
          'type': 'slider',
          'min': 0.0,
          'max': 0.6,
          'divisions': 60
        },
        'shadowColor': {'label': 'Shadow Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final layers = ((parameters['layers'] as num?)?.toInt() ?? 5).clamp(2, 12);
    final offset =
        ((parameters['shadowOffset'] as num?)?.toInt() ?? 2).clamp(0, 6);
    final shadowStrength =
        ((parameters['shadowStrength'] as num?)?.toDouble() ?? 0.45)
            .clamp(0.0, 1.0);
    final grain = ((parameters['paperGrain'] as num?)?.toDouble() ?? 0.12)
        .clamp(0.0, 0.5);
    final boost = ((parameters['colorBoost'] as num?)?.toDouble() ?? 0.15)
        .clamp(0.0, 0.6);
    final shadow = parameters['shadowColor'] as int? ?? 0xFF382B26;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final levels = List<int>.generate(pixels.length,
        (i) => (_textureLuminance(pixels[i]) * (layers - 1)).round());
    final result = Uint32List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final quantized = levels[i] / (layers - 1);
        var color = _textureBlendColor(
            pixels[i],
            quantized > 0.5 ? 0xFFFFFFFF : 0xFF000000,
            boost * (quantized - 0.5).abs(),
            preserveAlpha ? alpha : 255);
        final sx = x - offset;
        final sy = y - offset;
        if (offset > 0 && sx >= 0 && sy >= 0) {
          final sourceIndex = sy * width + sx;
          if (((pixels[sourceIndex] >> 24) & 0xff) != 0 &&
              levels[sourceIndex] != levels[i]) {
            color = _textureBlendColor(
                color, shadow, shadowStrength, preserveAlpha ? alpha : 255);
          }
        }
        final fiber = (_textureHash(x, y, 601) - 0.5) * grain;
        color = _textureBlendColor(color, fiber > 0 ? 0xFFFFFFFF : 0xFF000000,
            fiber.abs(), preserveAlpha ? alpha : 255);
        result[i] = color;
      }
    }
    return result;
  }
}
