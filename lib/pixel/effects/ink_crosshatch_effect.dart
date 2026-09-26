part of 'effects.dart';

/// Converts artwork into inked contours with tonal hatch lines.
class InkCrosshatchEffect extends Effect with UIFieldProvider {
  InkCrosshatchEffect([Map<String, dynamic>? params])
      : super(
          EffectType.inkCrosshatch,
          params ??
              const {
                'edgeThreshold': 0.18,
                'hatchSpacing': 4,
                'hatchStrength': 0.75,
                'angle': 45.0,
                'crosshatch': true,
                'colorWash': 0.12,
                'inkColor': 0xFF201A17,
                'paperColor': 0xFFFFF8E8,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'edgeThreshold': 0.18,
        'hatchSpacing': 4,
        'hatchStrength': 0.75,
        'angle': 45.0,
        'crosshatch': true,
        'colorWash': 0.12,
        'inkColor': 0xFF201A17,
        'paperColor': 0xFFFFF8E8,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'edgeThreshold': {
          'label': 'Edge Sensitivity',
          'description': 'Lower values detect finer contour details.',
          'type': 'slider',
          'min': 0.02,
          'max': 0.8,
          'divisions': 78,
        },
        'hatchSpacing': {
          'label': 'Hatch Spacing',
          'description': 'Distance between hand-drawn shading lines.',
          'type': 'slider',
          'min': 2,
          'max': 12,
          'divisions': 10,
        },
        'hatchStrength': {
          'label': 'Hatch Strength',
          'description': 'Amount of tonal shading converted to ink.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'angle': {
          'label': 'Hatch Angle',
          'description': 'Direction of the primary hatch strokes.',
          'type': 'slider',
          'min': 0.0,
          'max': 180.0,
          'divisions': 36,
        },
        'crosshatch': {
          'label': 'Crosshatch Shadows',
          'description': 'Add a second stroke direction in darker regions.',
          'type': 'bool',
        },
        'colorWash': {
          'label': 'Original Color Wash',
          'description': 'Retain a subtle wash of the source colors.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'inkColor': {
          'label': 'Ink Color',
          'description': 'Color used for contours and hatch lines.',
          'type': 'color',
        },
        'paperColor': {
          'label': 'Paper Color',
          'description': 'Color beneath the ink drawing.',
          'type': 'color',
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Keep transparent sprite pixels transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'edgeThreshold',
          label: 'Edge Sensitivity',
          description: 'Lower values detect finer contour details.',
          min: 0.02,
          max: 0.8,
          divisions: 78,
        ),
        SliderField(
          key: 'hatchSpacing',
          label: 'Hatch Spacing',
          description: 'Distance between hand-drawn shading lines.',
          min: 2,
          max: 12,
          divisions: 10,
          isInteger: true,
        ),
        SliderField(
          key: 'hatchStrength',
          label: 'Hatch Strength',
          description: 'Amount of tonal shading converted to ink.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        SliderField(
          key: 'angle',
          label: 'Hatch Angle',
          description: 'Direction of the primary hatch strokes.',
          min: 0.0,
          max: 180.0,
          divisions: 36,
        ),
        BoolField(
          key: 'crosshatch',
          label: 'Crosshatch Shadows',
          description: 'Add a second stroke direction in darker regions.',
        ),
        SliderField(
          key: 'colorWash',
          label: 'Original Color Wash',
          description: 'Retain a subtle wash of the source colors.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        ColorField(
          key: 'inkColor',
          label: 'Ink Color',
          description: 'Color used for contours and hatch lines.',
        ),
        ColorField(
          key: 'paperColor',
          label: 'Paper Color',
          description: 'Color beneath the ink drawing.',
        ),
        BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep transparent sprite pixels transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final edgeThreshold =
        ((parameters['edgeThreshold'] as num?)?.toDouble() ?? 0.18)
            .clamp(0.02, 0.8);
    final spacing =
        ((parameters['hatchSpacing'] as num?)?.toInt() ?? 4).clamp(2, 12);
    final hatchStrength =
        ((parameters['hatchStrength'] as num?)?.toDouble() ?? 0.75)
            .clamp(0.0, 1.0);
    final angle =
        ((parameters['angle'] as num?)?.toDouble() ?? 45.0) * math.pi / 180.0;
    final crosshatch = parameters['crosshatch'] as bool? ?? true;
    final colorWash =
        ((parameters['colorWash'] as num?)?.toDouble() ?? 0.12).clamp(0.0, 1.0);
    final ink = (parameters['inkColor'] as int?) ?? 0xFF201A17;
    final paper = (parameters['paperColor'] as int?) ?? 0xFFFFF8E8;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;
    final result = Uint32List(width * height);

    final inkR = (ink >> 16) & 0xff;
    final inkG = (ink >> 8) & 0xff;
    final inkB = ink & 0xff;
    final paperR = (paper >> 16) & 0xff;
    final paperG = (paper >> 8) & 0xff;
    final paperB = paper & 0xff;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    double luminanceAt(int x, int y) {
      final sx = x.clamp(0, width - 1);
      final sy = y.clamp(0, height - 1);
      final pixel = pixels[sy * width + sx];
      if (((pixel >> 24) & 0xff) == 0) return 1.0;
      return (0.299 * ((pixel >> 16) & 0xff) +
              0.587 * ((pixel >> 8) & 0xff) +
              0.114 * (pixel & 0xff)) /
          255.0;
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * width + x;
        final source = pixels[index];
        final alpha = (source >> 24) & 0xff;
        if (preserveAlpha && alpha == 0) continue;

        final sourceR = (source >> 16) & 0xff;
        final sourceG = (source >> 8) & 0xff;
        final sourceB = source & 0xff;
        final luminance = luminanceAt(x, y);
        final darkness = 1.0 - luminance;

        final gx = -luminanceAt(x - 1, y - 1) +
            luminanceAt(x + 1, y - 1) -
            2.0 * luminanceAt(x - 1, y) +
            2.0 * luminanceAt(x + 1, y) -
            luminanceAt(x - 1, y + 1) +
            luminanceAt(x + 1, y + 1);
        final gy = -luminanceAt(x - 1, y - 1) -
            2.0 * luminanceAt(x, y - 1) -
            luminanceAt(x + 1, y - 1) +
            luminanceAt(x - 1, y + 1) +
            2.0 * luminanceAt(x, y + 1) +
            luminanceAt(x + 1, y + 1);
        final edge = math.sqrt(gx * gx + gy * gy) / 4.0;

        final primaryLine = _onLine(x * cosA + y * sinA, spacing);
        final secondaryLine = _onLine(-x * sinA + y * cosA, spacing + 1);
        var coverage = 0.0;
        if (primaryLine && darkness > 0.24) {
          coverage = darkness * hatchStrength;
        }
        if (crosshatch && secondaryLine && darkness > 0.52) {
          coverage = math.max(coverage, darkness * hatchStrength * 0.9);
        }
        if (edge >= edgeThreshold) {
          coverage = math.max(
              coverage,
              ((edge - edgeThreshold) / (1.0 - edgeThreshold) + 0.55)
                  .clamp(0.0, 1.0));
        }

        final baseR = paperR * (1.0 - colorWash) + sourceR * colorWash;
        final baseG = paperG * (1.0 - colorWash) + sourceG * colorWash;
        final baseB = paperB * (1.0 - colorWash) + sourceB * colorWash;
        final outR =
            (baseR * (1.0 - coverage) + inkR * coverage).round().clamp(0, 255);
        final outG =
            (baseG * (1.0 - coverage) + inkG * coverage).round().clamp(0, 255);
        final outB =
            (baseB * (1.0 - coverage) + inkB * coverage).round().clamp(0, 255);
        result[index] = ((preserveAlpha ? alpha : 255) << 24) |
            (outR << 16) |
            (outG << 8) |
            outB;
      }
    }
    return result;
  }

  bool _onLine(double coordinate, int spacing) {
    final wrapped = ((coordinate.round() % spacing) + spacing) % spacing;
    return wrapped == 0;
  }
}
