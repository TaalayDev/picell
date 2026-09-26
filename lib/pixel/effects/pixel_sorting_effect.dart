part of 'effects.dart';

/// Sorts selected tonal bands into graphic glitch trails.
class PixelSortingEffect extends Effect with UIFieldProvider {
  PixelSortingEffect([Map<String, dynamic>? params])
      : super(
          EffectType.pixelSorting,
          params ??
              const {
                'direction': 'horizontal',
                'metric': 'brightness',
                'lowerThreshold': 0.2,
                'upperThreshold': 0.85,
                'maxSpan': 48,
                'descending': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => const {
        'direction': 'horizontal',
        'metric': 'brightness',
        'lowerThreshold': 0.2,
        'upperThreshold': 0.85,
        'maxSpan': 48,
        'descending': false,
      };

  @override
  Map<String, dynamic> getMetadata() => const {
        'direction': {
          'label': 'Direction',
          'description': 'Direction in which qualifying pixels are sorted.',
          'type': 'select',
          'options': {'horizontal': 'Horizontal', 'vertical': 'Vertical'},
        },
        'metric': {
          'label': 'Sort Metric',
          'description': 'Pixel property used for selection and ordering.',
          'type': 'select',
          'options': {
            'brightness': 'Brightness',
            'hue': 'Hue',
            'saturation': 'Saturation',
          },
        },
        'lowerThreshold': {
          'label': 'Lower Threshold',
          'description': 'Lowest metric value included in a sorted band.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'upperThreshold': {
          'label': 'Upper Threshold',
          'description': 'Highest metric value included in a sorted band.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'maxSpan': {
          'label': 'Maximum Trail',
          'description': 'Longest continuous segment sorted at once.',
          'type': 'slider',
          'min': 2,
          'max': 256,
          'divisions': 127,
        },
        'descending': {
          'label': 'Reverse Sort',
          'description': 'Reverse the direction of each color trail.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SelectField<String>(
          key: 'direction',
          label: 'Direction',
          description: 'Direction in which qualifying pixels are sorted.',
          options: {'horizontal': 'Horizontal', 'vertical': 'Vertical'},
        ),
        SelectField<String>(
          key: 'metric',
          label: 'Sort Metric',
          description: 'Pixel property used for selection and ordering.',
          options: {
            'brightness': 'Brightness',
            'hue': 'Hue',
            'saturation': 'Saturation',
          },
        ),
        SliderField(
          key: 'lowerThreshold',
          label: 'Lower Threshold',
          description: 'Lowest metric value included in a sorted band.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        SliderField(
          key: 'upperThreshold',
          label: 'Upper Threshold',
          description: 'Highest metric value included in a sorted band.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        SliderField(
          key: 'maxSpan',
          label: 'Maximum Trail',
          description: 'Longest continuous segment sorted at once.',
          min: 2,
          max: 256,
          divisions: 127,
          isInteger: true,
        ),
        BoolField(
          key: 'descending',
          label: 'Reverse Sort',
          description: 'Reverse the direction of each color trail.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) {
      return Uint32List.fromList(pixels);
    }
    final direction = parameters['direction'] as String? ?? 'horizontal';
    final metric = parameters['metric'] as String? ?? 'brightness';
    var low = ((parameters['lowerThreshold'] as num?)?.toDouble() ?? 0.2)
        .clamp(0.0, 1.0);
    var high = ((parameters['upperThreshold'] as num?)?.toDouble() ?? 0.85)
        .clamp(0.0, 1.0);
    if (low > high) {
      final swap = low;
      low = high;
      high = swap;
    }
    final maxSpan =
        ((parameters['maxSpan'] as num?)?.toInt() ?? 48).clamp(2, 256);
    final descending = parameters['descending'] as bool? ?? false;
    final result = Uint32List.fromList(pixels);

    if (direction == 'vertical') {
      for (var x = 0; x < width; x++) {
        _sortLine(result, height, maxSpan, low, high, descending, metric,
            (position) => position * width + x);
      }
    } else {
      for (var y = 0; y < height; y++) {
        _sortLine(result, width, maxSpan, low, high, descending, metric,
            (position) => y * width + position);
      }
    }
    return result;
  }

  void _sortLine(
    Uint32List pixels,
    int length,
    int maxSpan,
    double low,
    double high,
    bool descending,
    String metric,
    int Function(int) indexAt,
  ) {
    var cursor = 0;
    while (cursor < length) {
      final value = _metric(pixels[indexAt(cursor)], metric);
      if (value == null || value < low || value > high) {
        cursor++;
        continue;
      }

      final start = cursor;
      while (cursor < length && cursor - start < maxSpan) {
        final next = _metric(pixels[indexAt(cursor)], metric);
        if (next == null || next < low || next > high) break;
        cursor++;
      }
      final end = cursor;
      if (end - start > 1) {
        final segment = <int>[
          for (var position = start; position < end; position++)
            pixels[indexAt(position)],
        ]..sort((a, b) {
            final order = _metric(a, metric)!.compareTo(_metric(b, metric)!);
            return descending ? -order : order;
          });
        for (var i = 0; i < segment.length; i++) {
          pixels[indexAt(start + i)] = segment[i];
        }
      }
      if (cursor == start) cursor++;
    }
  }

  double? _metric(int pixel, String metric) {
    if (((pixel >> 24) & 0xff) == 0) return null;
    final r = ((pixel >> 16) & 0xff) / 255.0;
    final g = ((pixel >> 8) & 0xff) / 255.0;
    final b = (pixel & 0xff) / 255.0;
    final maxChannel = math.max(r, math.max(g, b));
    final minChannel = math.min(r, math.min(g, b));
    if (metric == 'saturation') {
      return maxChannel == 0 ? 0.0 : (maxChannel - minChannel) / maxChannel;
    }
    if (metric == 'hue') {
      final delta = maxChannel - minChannel;
      if (delta == 0) return 0.0;
      double hue;
      if (maxChannel == r) {
        hue = ((g - b) / delta) % 6.0;
      } else if (maxChannel == g) {
        hue = (b - r) / delta + 2.0;
      } else {
        hue = (r - g) / delta + 4.0;
      }
      return ((hue * 60.0 + 360.0) % 360.0) / 360.0;
    }
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }
}
