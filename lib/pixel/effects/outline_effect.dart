part of 'effects.dart';

/// Outline effect for pixel art
class OutlineEffect extends Effect {
  OutlineEffect([Map<String, dynamic>? params])
      : super(
            EffectType.outline,
            params ??
                {
                  'color': Colors.black.value,
                  'thickness': 1,
                  'threshold': 0.5,
                });

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final outlineColor = parameters['color'] as int;
    final thickness = (parameters['thickness'] as int).clamp(1, 5);
    final threshold = parameters['threshold'] as double;
    final result = Uint32List.fromList(pixels);

    // Temporary buffer for edge detection
    final edges = List.generate(height, (_) => List.filled(width, false));

    // First pass: Detect edges
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = pixels[index];
        final a = (pixel >> 24) & 0xFF;

        // Skip completely transparent pixels
        if (a < threshold * 255) continue;

        // Check if we're at an edge by looking at neighbors
        bool isEdge = false;

        // Check the 8 surrounding pixels
        for (int dy = -1; dy <= 1 && !isEdge; dy++) {
          for (int dx = -1; dx <= 1 && !isEdge; dx++) {
            if (dx == 0 && dy == 0) continue; // Skip self

            final nx = x + dx;
            final ny = y + dy;

            // Check if the neighbor is within bounds
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              final neighborIndex = ny * width + nx;
              final neighborPixel = pixels[neighborIndex];
              final neighborA = (neighborPixel >> 24) & 0xFF;

              // If the neighbor is transparent (or below threshold) and this pixel isn't,
              // it's an edge
              if (neighborA < threshold * 255 && a >= threshold * 255) {
                isEdge = true;
              }
            } else {
              // If neighbor is out of bounds, it's an edge
              isEdge = true;
            }
          }
        }

        edges[y][x] = isEdge;
      }
    }

    // Second pass: Apply the outline effect
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (edges[y][x]) {
          // Apply outline to this pixel and surrounding pixels based on thickness
          for (int dy = -thickness; dy <= thickness; dy++) {
            for (int dx = -thickness; dx <= thickness; dx++) {
              final nx = x + dx;
              final ny = y + dy;

              // Skip pixels outside the bounds
              if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

              // Calculate distance from edge pixel
              final distance = sqrt(dx * dx + dy * dy);
              if (distance <= thickness) {
                final neighborIndex = ny * width + nx;
                final neighborPixel = pixels[neighborIndex];
                final neighborA = (neighborPixel >> 24) & 0xFF;

                // Only apply outline to transparent or nearly transparent pixels
                if (neighborA < threshold * 255) {
                  // Preserve original alpha for smooth outline
                  final outlineA = (outlineColor >> 24) & 0xFF;
                  final alpha = (outlineA * (1.0 - distance / (thickness + 1))).round().clamp(0, 255);
                  final finalColor = (alpha << 24) | (outlineColor & 0x00FFFFFF);

                  result[neighborIndex] = finalColor;
                }
              }
            }
          }
        }
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'color': Colors.black.value, // Outline color
      'thickness': 1, // Range: 1 to 5 pixels
      'threshold': 0.5, // Alpha threshold (0.0 to 1.0)
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'color': {
        'label': 'Outline Color',
        'description': 'Color of the outline effect.',
        'type': 'color',
      },
      'thickness': {
        'label': 'Outline Thickness',
        'description': 'Thickness of the outline in pixels.',
        'type': 'slider',
        'min': 1,
        'max': 5,
        'divisions': 4,
      },
      'threshold': {
        'label': 'Alpha Threshold',
        'description': 'Alpha threshold for edge detection. Pixels below this value are considered transparent.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const ColorField(
          key: 'color',
          label: 'Outline Color',
          description: 'Color of the outline effect.',
        ),
        const SliderField(
          key: 'thickness',
          label: 'Outline Thickness',
          description: 'Thickness of the outline in pixels.',
          min: 1,
          max: 5,
          divisions: 4,
          isInteger: true,
        ),
        const SliderField(
          key: 'threshold',
          label: 'Alpha Threshold',
          description: 'Alpha threshold for edge detection. Pixels below this value are considered transparent.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
      ];
}
