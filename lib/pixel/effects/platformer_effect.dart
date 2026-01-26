part of 'effects.dart';

enum MergeType {
  solid,
  gradient,
  dither,
  wave,
  zigzag,
  noise,
  step,
  shadow,
}

class PlatformerEffect extends Effect {
  PlatformerEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.platformer,
          parameters ??
              {
                'keepTop': true,
                'keepBottom': false,
                'keepLeft': false,
                'keepRight': false,
                'edgeWidth': 4,
                'cornerRadius': 2,
                'mergeType': 'solid',
                'transitionSize': 3,
                'waveFrequency': 4.0,
                'waveAmplitude': 2.0,
                'noiseIntensity': 0.5,
                'shadowDepth': 3,
                'shadowOpacity': 0.5,
              },
        );

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final keepTop = parameters['keepTop'] as bool? ?? true;
    final keepBottom = parameters['keepBottom'] as bool? ?? false;
    final keepLeft = parameters['keepLeft'] as bool? ?? false;
    final keepRight = parameters['keepRight'] as bool? ?? false;
    final edgeWidth = ((parameters['edgeWidth'] as num?)?.toInt() ?? 4).clamp(1, 20);
    final cornerRadius = ((parameters['cornerRadius'] as num?)?.toInt() ?? 2).clamp(0, 10);
    final mergeTypeStr = parameters['mergeType'] as String? ?? 'solid';
    final waveFrequency = (parameters['waveFrequency'] as num?)?.toDouble() ?? 4.0;
    final waveAmplitude = (parameters['waveAmplitude'] as num?)?.toDouble() ?? 2.0;
    final noiseIntensity = (parameters['noiseIntensity'] as num?)?.toDouble() ?? 0.5;
    final shadowDepth = ((parameters['shadowDepth'] as num?)?.toInt() ?? 3).clamp(1, 10);
    final shadowOpacity = (parameters['shadowOpacity'] as num?)?.toDouble() ?? 0.5;

    final mergeType = MergeType.values.firstWhere(
      (e) => e.name == mergeTypeStr,
      orElse: () => MergeType.solid,
    );

    final result = Uint32List.fromList(pixels);
    final random = Random(42); // Fixed seed for consistency

    // Helper to check if pixel should be kept based on edge settings
    bool shouldKeepPixel(int x, int y) {
      // Check each edge
      bool inTopEdge = keepTop && y < edgeWidth;
      bool inBottomEdge = keepBottom && y >= height - edgeWidth;
      bool inLeftEdge = keepLeft && x < edgeWidth;
      bool inRightEdge = keepRight && x >= width - edgeWidth;

      // Check if in any enabled edge
      if (!inTopEdge && !inBottomEdge && !inLeftEdge && !inRightEdge) {
        return false; // Not in any kept edge, remove this pixel
      }

      // Get distance from nearest enabled edge
      int distance = edgeWidth + 1;
      if (keepTop) distance = min(distance, y);
      if (keepBottom) distance = min(distance, height - 1 - y);
      if (keepLeft) distance = min(distance, x);
      if (keepRight) distance = min(distance, width - 1 - x);

      // Check corner cutouts
      if (cornerRadius > 0) {
        // Top-left corner
        if (keepTop && keepLeft && x < cornerRadius && y < cornerRadius) {
          final dx = cornerRadius - x - 0.5;
          final dy = cornerRadius - y - 0.5;
          if (dx * dx + dy * dy > cornerRadius * cornerRadius) {
            return false;
          }
        }

        // Top-right corner
        if (keepTop && keepRight && x >= width - cornerRadius && y < cornerRadius) {
          final dx = x - (width - cornerRadius - 1) + 0.5;
          final dy = cornerRadius - y - 0.5;
          if (dx * dx + dy * dy > cornerRadius * cornerRadius) {
            return false;
          }
        }

        // Bottom-left corner
        if (keepBottom && keepLeft && x < cornerRadius && y >= height - cornerRadius) {
          final dx = cornerRadius - x - 0.5;
          final dy = y - (height - cornerRadius - 1) + 0.5;
          if (dx * dx + dy * dy > cornerRadius * cornerRadius) {
            return false;
          }
        }

        // Bottom-right corner
        if (keepBottom && keepRight && x >= width - cornerRadius && y >= height - cornerRadius) {
          final dx = x - (width - cornerRadius - 1) + 0.5;
          final dy = y - (height - cornerRadius - 1) + 0.5;
          if (dx * dx + dy * dy > cornerRadius * cornerRadius) {
            return false;
          }
        }
      }

      // Apply merge type to determine if pixel should be kept
      final t = distance / edgeWidth;

      switch (mergeType) {
        case MergeType.solid:
          return true;

        case MergeType.gradient:
          // Gradually fade out
          final alpha = (1.0 - t).clamp(0.0, 1.0);
          return random.nextDouble() < alpha;

        case MergeType.dither:
          // Bayer matrix dithering
          final bayerMatrix = [
            [0, 8, 2, 10],
            [12, 4, 14, 6],
            [3, 11, 1, 9],
            [15, 7, 13, 5],
          ];
          final threshold = bayerMatrix[y % 4][x % 4] / 16.0;
          return (1.0 - t) > threshold;

        case MergeType.wave:
          final offset = sin(x * waveFrequency * pi / width) * waveAmplitude;
          final adjustedDist = distance + offset;
          return adjustedDist < edgeWidth;

        case MergeType.zigzag:
          final zigzag = ((x + y) % 4) < 2 ? 1.0 : -1.0;
          final adjustedDist = distance + zigzag;
          return adjustedDist < edgeWidth;

        case MergeType.noise:
          final noiseValue = (random.nextDouble() - 0.5) * noiseIntensity * edgeWidth;
          final adjustedDist = distance + noiseValue;
          return adjustedDist < edgeWidth;

        case MergeType.step:
          // Pixel-art stair-step pattern
          final step = (distance / (edgeWidth / 3)).floor();
          return step % 2 == 0;

        case MergeType.shadow:
          return true; // Keep all pixels in shadow mode, darken later
      }
    }

    // Apply the effect
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final originalPixel = pixels[index];

        if (shouldKeepPixel(x, y)) {
          // Keep this pixel, possibly with shadow effect
          if (mergeType == MergeType.shadow) {
            // Get distance for shadow calculation
            int distance = edgeWidth + 1;
            if (keepTop) distance = min(distance, y);
            if (keepBottom) distance = min(distance, height - 1 - y);
            if (keepLeft) distance = min(distance, x);
            if (keepRight) distance = min(distance, width - 1 - x);

            if (distance < shadowDepth) {
              // Apply shadow darkening
              final shadowFactor = -(1.0 - distance / shadowDepth) * shadowOpacity;

              final a = (originalPixel >> 24) & 0xFF;
              final r = (originalPixel >> 16) & 0xFF;
              final g = (originalPixel >> 8) & 0xFF;
              final b = originalPixel & 0xFF;

              final shadowR = (r * (1.0 - shadowFactor)).round();
              final shadowG = (g * (1.0 - shadowFactor)).round();
              final shadowB = (b * (1.0 - shadowFactor)).round();

              result[index] = (a << 24) | (shadowR << 16) | (shadowG << 8) | shadowB;
            } else {
              result[index] = originalPixel;
            }
          } else {
            result[index] = originalPixel;
          }
        } else {
          // Remove this pixel (make transparent)
          result[index] = 0x00000000;
        }
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'keepTop': true,
      'keepBottom': false,
      'keepLeft': false,
      'keepRight': false,
      'edgeWidth': 4,
      'cornerRadius': 2,
      'mergeType': 'solid',
      'waveFrequency': 4.0,
      'waveAmplitude': 2.0,
      'noiseIntensity': 0.5,
      'shadowDepth': 3,
      'shadowOpacity': 0.5,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'keepTop': {'type': 'bool', 'label': 'Keep Top'},
      'keepBottom': {'type': 'bool', 'label': 'Keep Bottom'},
      'keepLeft': {'type': 'bool', 'label': 'Keep Left'},
      'keepRight': {'type': 'bool', 'label': 'Keep Right'},
      'edgeWidth': {'min': 1, 'max': 20, 'label': 'Edge Width'},
      'cornerRadius': {'min': 0, 'max': 10, 'label': 'Corner Radius'},
      'mergeType': {
        'type': 'select',
        'options': ['solid', 'gradient', 'dither', 'wave', 'zigzag', 'noise', 'step', 'shadow'],
        'label': 'Merge Type'
      },
      'waveFrequency': {'min': 1.0, 'max': 10.0, 'label': 'Wave Frequency'},
      'waveAmplitude': {'min': 0.5, 'max': 5.0, 'label': 'Wave Amplitude'},
      'noiseIntensity': {'min': 0.0, 'max': 1.0, 'label': 'Noise Intensity'},
      'shadowDepth': {'min': 1, 'max': 10, 'label': 'Shadow Depth'},
      'shadowOpacity': {'min': 0.0, 'max': 1.0, 'label': 'Shadow Opacity'},
    };
  }
}
