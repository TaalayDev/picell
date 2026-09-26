part of 'effects.dart';

/// Rebuilds the image from flat triangular facets.
class LowPolyFacetsEffect extends Effect {
  LowPolyFacetsEffect([Map<String, dynamic>? params])
      : super(
            EffectType.lowPolyFacets,
            params ??
                const {
                  'facetSize': 8,
                  'jitter': 0.35,
                  'lightingAngle': 315.0,
                  'facetContrast': 0.28,
                  'showEdges': false,
                  'edgeColor': 0xFF263238,
                  'preserveAlpha': true,
                });

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'facetSize': 8,
        'jitter': 0.35,
        'lightingAngle': 315.0,
        'facetContrast': 0.28,
        'showEdges': false,
        'edgeColor': 0xFF263238,
        'preserveAlpha': true
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'facetSize': {
          'label': 'Facet Size',
          'type': 'slider',
          'min': 3,
          'max': 32,
          'divisions': 29
        },
        'jitter': {
          'label': 'Facet Irregularity',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'lightingAngle': {
          'label': 'Light Angle',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'divisions': 72
        },
        'facetContrast': {
          'label': 'Facet Contrast',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 80
        },
        'showEdges': {'label': 'Show Triangle Edges', 'type': 'bool'},
        'edgeColor': {'label': 'Edge Color', 'type': 'color'},
        'preserveAlpha': {'label': 'Preserve Transparency', 'type': 'bool'},
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final size = ((parameters['facetSize'] as num?)?.toInt() ?? 8).clamp(3, 32);
    final jitter =
        ((parameters['jitter'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final angle = ((parameters['lightingAngle'] as num?)?.toDouble() ?? 315.0) *
        math.pi /
        180.0;
    final contrast = ((parameters['facetContrast'] as num?)?.toDouble() ?? 0.28)
        .clamp(0.0, 0.8);
    final showEdges = parameters['showEdges'] as bool? ?? false;
    final edgeColor = parameters['edgeColor'] as int? ?? 0xFF263238;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final alpha = (pixels[i] >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;
        final cellX = x ~/ size;
        final cellY = y ~/ size;
        final localX = x % size;
        final localY = y % size;
        final flipped = _textureHash(cellX, cellY, 701) > 0.5;
        final firstTriangle =
            flipped ? localX + localY < size : localX > localY;
        final jitterX =
            ((_textureHash(cellX, cellY, 709) - 0.5) * size * jitter).round();
        final jitterY =
            ((_textureHash(cellX, cellY, 719) - 0.5) * size * jitter).round();
        final sampleX = (cellX * size +
                (firstTriangle ? size * 2 ~/ 3 : size ~/ 3) +
                jitterX)
            .clamp(0, width - 1);
        final sampleY = (cellY * size +
                (firstTriangle ? size ~/ 3 : size * 2 ~/ 3) +
                jitterY)
            .clamp(0, height - 1);
        final sample = pixels[sampleY * width + sampleX];
        final phase = _textureHash(cellX, cellY, firstTriangle ? 727 : 733) *
            math.pi *
            2.0;
        final lighting = math.cos(phase - angle) * contrast;
        final tone = lighting > 0 ? 0xFFFFFFFF : 0xFF000000;
        var color = _textureBlendColor(
            sample, tone, lighting.abs(), preserveAlpha ? alpha : 255);
        final diagonal = flipped
            ? (localX + localY - size).abs() <= 1
            : (localX - localY).abs() <= 1;
        if (showEdges && (localX == 0 || localY == 0 || diagonal)) {
          color = _textureBlendColor(
              color, edgeColor, 0.75, preserveAlpha ? alpha : 255);
        }
        result[i] = color;
      }
    }
    return result;
  }
}
