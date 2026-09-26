part of 'effects.dart';

/// Applies a painted coat with irregular flakes revealing the source beneath.
class PaintPeelingEffect extends Effect {
  PaintPeelingEffect([Map<String, dynamic>? params])
      : super(
            EffectType.paintPeeling,
            params ??
                const {
                  'paintCoverage': 0.72,
                  'peelScale': 13,
                  'edgeWear': 0.45,
                  'flakeOutline': 0.35,
                  'paintColor': 0xFFB23A48,
                  'outlineColor': 0xFF5C2429,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'paintCoverage': 0.72,
        'peelScale': 13,
        'edgeWear': 0.45,
        'flakeOutline': 0.35,
        'paintColor': 0xFFB23A48,
        'outlineColor': 0xFF5C2429,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'paintCoverage': {
          'label': 'Paint Coverage',
          'description': 'Amount of the underlying material still painted.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'peelScale': {
          'label': 'Flake Scale',
          'type': 'slider',
          'min': 3,
          'max': 32,
          'divisions': 29
        },
        'edgeWear': {
          'label': 'Edge Wear',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'flakeOutline': {
          'label': 'Flake Shadow',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'paintColor': {'label': 'Paint Color', 'type': 'color'},
        'outlineColor': {'label': 'Flake Edge Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final coverage = ((parameters['paintCoverage'] as num?)?.toDouble() ?? 0.72)
        .clamp(0.0, 1.0);
    final scale =
        ((parameters['peelScale'] as num?)?.toInt() ?? 13).clamp(3, 32);
    final edgeWear =
        ((parameters['edgeWear'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final outline = ((parameters['flakeOutline'] as num?)?.toDouble() ?? 0.35)
        .clamp(0.0, 1.0);
    final paint = parameters['paintColor'] as int? ?? 0xFFB23A48;
    final edgeColor = parameters['outlineColor'] as int? ?? 0xFF5C2429;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List.fromList(pixels);
    double field(int x, int y) => _textureFbm(x / scale, y / scale, 503);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final borderDistance =
            math.min(math.min(x, width - 1 - x), math.min(y, height - 1 - y));
        final wornThreshold =
            1.0 - coverage + (borderDistance < 2 ? edgeWear * 0.28 : 0.0);
        final value = field(x, y);
        final painted = value > wornThreshold;
        if (!painted) continue;
        final neighborPeels = field(x - 1, y) <= wornThreshold ||
            field(x + 1, y) <= wornThreshold ||
            field(x, y - 1) <= wornThreshold ||
            field(x, y + 1) <= wornThreshold;
        final base = _textureBlendColor(
            pixels[i], paint, 0.88, preserveAlpha ? alpha : 255);
        result[i] = neighborPeels
            ? _textureBlendColor(
                base, edgeColor, outline, preserveAlpha ? alpha : 255)
            : base;
      }
    }
    return result;
  }
}
