part of 'effects.dart';

/// Simulates 2D drop shadows and isometric ground-plane projected shadows
/// for pixel art characters and objects.
class DropShadowEffect extends Effect with UIFieldProvider {
  DropShadowEffect([Map<String, dynamic>? params])
      : super(
          EffectType.dropShadow,
          params ??
              const {
                'mode': 'drop',
                'shadowColor': 0x99000000,
                'offsetX': 2,
                'offsetY': 3,
                'isometricAngle': 30.0,
                'isometricScale': 0.5,
                'softness': 0,
                'shadowOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'mode': 'drop',
      'shadowColor': 0x99000000,
      'offsetX': 2,
      'offsetY': 3,
      'isometricAngle': 30.0,
      'isometricScale': 0.5,
      'softness': 0,
      'shadowOnly': false,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'mode': {
        'label': 'Shadow Mode',
        'description': 'Direct 2D drop shadow or isometric ground-plane projection.',
        'type': 'select',
        'options': {
          'drop': '2D Drop Shadow',
          'isometric': 'Isometric Ground Shadow',
        },
      },
      'shadowColor': {
        'label': 'Shadow Color',
        'description': 'Color and opacity of the shadow silhouette.',
        'type': 'color',
      },
      'offsetX': {
        'label': 'Offset X',
        'description': 'Horizontal shadow shift distance in pixels.',
        'type': 'slider',
        'min': -20,
        'max': 20,
        'divisions': 40,
      },
      'offsetY': {
        'label': 'Offset Y',
        'description': 'Vertical shadow shift distance in pixels.',
        'type': 'slider',
        'min': -20,
        'max': 20,
        'divisions': 40,
      },
      'isometricAngle': {
        'label': 'Isometric Skew Angle',
        'description': 'Ground projection shear angle in degrees (isometric mode).',
        'type': 'slider',
        'min': -60.0,
        'max': 60.0,
        'divisions': 60,
      },
      'isometricScale': {
        'label': 'Isometric Depth Scale',
        'description': 'Vertical foreshortening scale along the ground plane.',
        'type': 'slider',
        'min': 0.2,
        'max': 1.2,
        'divisions': 50,
      },
      'softness': {
        'label': 'Shadow Softness',
        'description': 'Blur radius of the shadow silhouette (0 = crisp pixel art).',
        'type': 'slider',
        'min': 0,
        'max': 3,
        'divisions': 3,
      },
      'shadowOnly': {
        'label': 'Shadow Only',
        'description': 'Render only the generated shadow without the original sprite.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'mode',
          label: 'Shadow Mode',
          description: 'Direct 2D drop shadow or isometric ground-plane projection.',
          options: {
            'drop': '2D Drop Shadow',
            'isometric': 'Isometric Ground Shadow',
          },
        ),
        const ColorField(
          key: 'shadowColor',
          label: 'Shadow Color',
          description: 'Color and opacity of the shadow silhouette.',
        ),
        SliderField(
          key: 'offsetX',
          label: 'Offset X',
          description: 'Horizontal shadow shift distance in pixels.',
          min: -20,
          max: 20,
          divisions: 40,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'offsetY',
          label: 'Offset Y',
          description: 'Vertical shadow shift distance in pixels.',
          min: -20,
          max: 20,
          divisions: 40,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'isometricAngle',
          label: 'Isometric Skew Angle',
          description: 'Ground projection shear angle in degrees (isometric mode).',
          min: -60.0,
          max: 60.0,
          divisions: 60,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'isometricScale',
          label: 'Isometric Depth Scale',
          description: 'Vertical foreshortening scale along the ground plane.',
          min: 0.2,
          max: 1.2,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'softness',
          label: 'Shadow Softness',
          description: 'Blur radius of the shadow silhouette (0 = crisp pixel art).',
          min: 0,
          max: 3,
          divisions: 3,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const BoolField(
          key: 'shadowOnly',
          label: 'Shadow Only',
          description: 'Render only the generated shadow without the original sprite.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final mode = parameters['mode'] as String? ?? 'drop';
    final shadowColorInt = (parameters['shadowColor'] as int?) ?? 0x99000000;
    final offsetX = ((parameters['offsetX'] as num?)?.toInt() ?? 2).clamp(-20, 20);
    final offsetY = ((parameters['offsetY'] as num?)?.toInt() ?? 3).clamp(-20, 20);
    final isoAngle = ((parameters['isometricAngle'] as num?)?.toDouble() ?? 30.0).clamp(-60.0, 60.0);
    final isoScale = ((parameters['isometricScale'] as num?)?.toDouble() ?? 0.5).clamp(0.2, 1.2);
    final softness = ((parameters['softness'] as num?)?.toInt() ?? 0).clamp(0, 3);
    final shadowOnly = parameters['shadowOnly'] as bool? ?? false;

    final shadowAlphaChannel = (shadowColorInt >> 24) & 0xFF;
    if (shadowAlphaChannel == 0 && shadowOnly) {
      return Uint32List(width * height);
    }

    final shadowR = (shadowColorInt >> 16) & 0xFF;
    final shadowG = (shadowColorInt >> 8) & 0xFF;
    final shadowB = shadowColorInt & 0xFF;

    final shadowMask = Uint8List(width * height);

    if (mode == 'drop') {
      for (int sy = 0; sy < height; sy++) {
        final ty = sy + offsetY;
        if (ty < 0 || ty >= height) continue;

        for (int sx = 0; sx < width; sx++) {
          final a = (pixels[sy * width + sx] >> 24) & 0xFF;
          if (a == 0) continue;

          final tx = sx + offsetX;
          if (tx >= 0 && tx < width) {
            final targetIdx = ty * width + tx;
            if (a > shadowMask[targetIdx]) {
              shadowMask[targetIdx] = a;
            }
          }
        }
      }
    } else {
      // Isometric ground projection
      int lowestOpaqueY = 0;
      for (int y = height - 1; y >= 0; y--) {
        bool hasPixel = false;
        for (int x = 0; x < width; x++) {
          if (((pixels[y * width + x] >> 24) & 0xFF) > 0) {
            hasPixel = true;
            break;
          }
        }
        if (hasPixel) {
          lowestOpaqueY = y;
          break;
        }
      }

      final tanAngle = math.tan(isoAngle * math.pi / 180.0);

      for (int sy = 0; sy <= lowestOpaqueY; sy++) {
        final deltaY = lowestOpaqueY - sy;
        final ty = lowestOpaqueY + (deltaY * isoScale * 0.4).round() + offsetY;
        if (ty < 0 || ty >= height) continue;

        final shearX = (deltaY * tanAngle).round() + offsetX;

        for (int sx = 0; sx < width; sx++) {
          final a = (pixels[sy * width + sx] >> 24) & 0xFF;
          if (a == 0) continue;

          final tx = sx + shearX;
          if (tx >= 0 && tx < width) {
            final targetIdx = ty * width + tx;
            if (a > shadowMask[targetIdx]) {
              shadowMask[targetIdx] = a;
            }
          }
        }
      }
    }

    // Optional softness (blur)
    var finalMask = shadowMask;
    if (softness > 0) {
      finalMask = _blurMask(shadowMask, width, height, softness);
    }

    final result = Uint32List(width * height);
    final maxShadowOpacity = shadowAlphaChannel / 255.0;

    for (int i = 0; i < width * height; i++) {
      final origPixel = pixels[i];
      final origA = (origPixel >> 24) & 0xFF;
      final maskVal = finalMask[i];

      final shadowA = (maskVal * maxShadowOpacity).round().clamp(0, 255);

      if (shadowOnly) {
        if (shadowA > 0) {
          result[i] = (shadowA << 24) | (shadowR << 16) | (shadowG << 8) | shadowB;
        }
        continue;
      }

      if (origA == 255) {
        // Full opacity foreground pixel covers shadow completely
        result[i] = origPixel;
      } else if (origA > 0) {
        // Semi-transparent foreground over shadow
        final fgNorm = origA / 255.0;
        final fgR = (origPixel >> 16) & 0xFF;
        final fgG = (origPixel >> 8) & 0xFF;
        final fgB = origPixel & 0xFF;

        final bgNorm = (shadowA / 255.0) * (1.0 - fgNorm);
        final outNorm = fgNorm + bgNorm;

        if (outNorm > 0) {
          final outR = ((fgR * fgNorm + shadowR * bgNorm) / outNorm).round().clamp(0, 255);
          final outG = ((fgG * fgNorm + shadowG * bgNorm) / outNorm).round().clamp(0, 255);
          final outB = ((fgB * fgNorm + shadowB * bgNorm) / outNorm).round().clamp(0, 255);
          final outA = (outNorm * 255).round().clamp(0, 255);
          result[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
      } else if (shadowA > 0) {
        // Background has only shadow
        result[i] = (shadowA << 24) | (shadowR << 16) | (shadowG << 8) | shadowB;
      }
    }

    return result;
  }

  Uint8List _blurMask(Uint8List src, int width, int height, int radius) {
    final temp = Uint8List(width * height);
    final dst = Uint8List(width * height);

    // Horizontal box pass
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int sum = 0;
        int count = 0;
        for (int dx = -radius; dx <= radius; dx++) {
          final nx = x + dx;
          if (nx >= 0 && nx < width) {
            sum += src[y * width + nx];
            count++;
          }
        }
        temp[y * width + x] = (sum / count).round();
      }
    }

    // Vertical box pass
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int sum = 0;
        int count = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          final ny = y + dy;
          if (ny >= 0 && ny < height) {
            sum += temp[ny * width + x];
            count++;
          }
        }
        dst[y * width + x] = (sum / count).round();
      }
    }

    return dst;
  }
}
