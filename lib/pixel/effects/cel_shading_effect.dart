part of 'effects.dart';

/// Applies stepped lighting and dark ink contours.
class CelShadingEffect extends Effect {
  CelShadingEffect([Map<String, dynamic>? params])
      : super(
            EffectType.celShading,
            params ??
                const {
                  'bands': 4,
                  'shadowStrength': 0.55,
                  'highlightStrength': 0.22,
                  'outlineThreshold': 0.2,
                  'outlineStrength': 0.95,
                  'outlineColor': 0xFF17151A,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'bands': 4,
        'shadowStrength': 0.55,
        'highlightStrength': 0.22,
        'outlineThreshold': 0.2,
        'outlineStrength': 0.95,
        'outlineColor': 0xFF17151A,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'bands': {
          'label': 'Lighting Bands',
          'type': 'slider',
          'min': 2,
          'max': 8,
          'divisions': 6
        },
        'shadowStrength': {
          'label': 'Shadow Strength',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'highlightStrength': {
          'label': 'Highlight Strength',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 80
        },
        'outlineThreshold': {
          'label': 'Outline Sensitivity',
          'type': 'slider',
          'min': 0.02,
          'max': 0.8,
          'divisions': 78
        },
        'outlineStrength': {
          'label': 'Outline Strength',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'outlineColor': {'label': 'Outline Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final bands = ((parameters['bands'] as num?)?.toInt() ?? 4).clamp(2, 8);
    final shadowStrength =
        ((parameters['shadowStrength'] as num?)?.toDouble() ?? 0.55)
            .clamp(0.0, 1.0);
    final highlight =
        ((parameters['highlightStrength'] as num?)?.toDouble() ?? 0.22)
            .clamp(0.0, 0.8);
    final threshold =
        ((parameters['outlineThreshold'] as num?)?.toDouble() ?? 0.2)
            .clamp(0.02, 0.8);
    final outlineStrength =
        ((parameters['outlineStrength'] as num?)?.toDouble() ?? 0.95)
            .clamp(0.0, 1.0);
    final outline = parameters['outlineColor'] as int? ?? 0xFF17151A;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    double lum(int x, int y) {
      x = x.clamp(0, width - 1);
      y = y.clamp(0, height - 1);
      final p = pixels[y * width + x];
      return ((p >> 24) & 0xff) == 0 ? 1.0 : _textureLuminance(p);
    }

    final result = Uint32List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final l = lum(x, y);
        final band = (l * (bands - 1)).round() / (bands - 1);
        final factor = _textureMix(1.0 - shadowStrength, 1.0 + highlight, band);
        final r =
            (_textureChannel(pixels[i], 16) * factor).round().clamp(0, 255);
        final g =
            (_textureChannel(pixels[i], 8) * factor).round().clamp(0, 255);
        final b =
            (_textureChannel(pixels[i], 0) * factor).round().clamp(0, 255);
        var color =
            ((preserveAlpha ? alpha : 255) << 24) | (r << 16) | (g << 8) | b;
        final gx = lum(x + 1, y) - lum(x - 1, y);
        final gy = lum(x, y + 1) - lum(x, y - 1);
        final edge = math.sqrt(gx * gx + gy * gy);
        if (edge > threshold) {
          color = _textureBlendColor(
              color, outline, outlineStrength, preserveAlpha ? alpha : 255);
        }
        result[i] = color;
      }
    }
    return result;
  }
}
