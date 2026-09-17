part of 'effects.dart';

/// Simulates video game damage responses including solid color impact flashes,
/// exponential decay flashes, and invulnerability frame (i-frame) blinking.
class HitFlashEffect extends Effect with UIFieldProvider {
  HitFlashEffect([Map<String, dynamic>? params])
      : super(
          EffectType.hitFlash,
          params ??
              const {
                'mode': 'flashDecay',
                'flashColor': 0xFFFFFFFF,
                'intensity': 1.0,
                'blinkCount': 4,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'mode': 'flashDecay',
      'flashColor': 0xFFFFFFFF,
      'intensity': 1.0,
      'blinkCount': 4,
      'time': 0.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'mode': {
        'label': 'Flash Mode',
        'description': 'Damage reaction style (flash decay, invulnerability blink, or combo).',
        'type': 'select',
        'options': {
          'flashDecay': 'Impact Flash Decay (Decays to Normal)',
          'blink': 'Invulnerability Blink (i-Frames)',
          'flashAndBlink': 'Impact Flash + Blinking Recovery',
          'solidFlash': 'Constant Flash (Solid Tint)',
        },
      },
      'flashColor': {
        'label': 'Flash Color',
        'description': 'Color of the hit flash impact tint.',
        'type': 'color',
      },
      'intensity': {
        'label': 'Flash Strength',
        'description': 'Intensity of the color tint overlay.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'blinkCount': {
        'label': 'Blink Cycles',
        'description': 'Frequency of invulnerability blinks across the timeline.',
        'type': 'slider',
        'min': 2,
        'max': 8,
        'divisions': 6,
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Timeline progress parameter updated during frame generation.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Leave background pixels transparent.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'mode',
          label: 'Flash Mode',
          description: 'Damage reaction style (flash decay, invulnerability blink, or combo).',
          options: {
            'flashDecay': 'Impact Flash Decay (Decays to Normal)',
            'blink': 'Invulnerability Blink (i-Frames)',
            'flashAndBlink': 'Impact Flash + Blinking Recovery',
            'solidFlash': 'Constant Flash (Solid Tint)',
          },
        ),
        const ColorField(
          key: 'flashColor',
          label: 'Flash Color',
          description: 'Color of the hit flash impact tint.',
        ),
        SliderField(
          key: 'intensity',
          label: 'Flash Strength',
          description: 'Intensity of the color tint overlay.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'blinkCount',
          label: 'Blink Cycles',
          description: 'Frequency of invulnerability blinks across the timeline.',
          min: 2,
          max: 8,
          divisions: 6,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}x',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Leave background pixels transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final mode = parameters['mode'] as String? ?? 'flashDecay';
    final flashColorInt = (parameters['flashColor'] as int?) ?? 0xFFFFFFFF;
    final intensity = ((parameters['intensity'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0);
    final blinkCount = ((parameters['blinkCount'] as num?)?.toInt() ?? 4).clamp(2, 8);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final flashR = (flashColorInt >> 16) & 0xFF;
    final flashG = (flashColorInt >> 8) & 0xFF;
    final flashB = flashColorInt & 0xFF;

    double flashFactor = 0.0;
    bool isVisible = true;

    switch (mode) {
      case 'solidFlash':
        flashFactor = intensity;
        isVisible = true;
        break;

      case 'flashDecay':
        flashFactor = intensity * math.exp(-time * 4.5);
        isVisible = true;
        break;

      case 'blink':
        final cycle = (time * blinkCount) % 1.0;
        isVisible = cycle < 0.55;
        flashFactor = 0.0;
        break;

      case 'flashAndBlink':
        if (time < 0.25) {
          flashFactor = intensity * (1.0 - time / 0.25);
          isVisible = true;
        } else {
          final blinkProgress = (time - 0.25) / 0.75;
          final cycle = (blinkProgress * blinkCount) % 1.0;
          isVisible = cycle < 0.55;
          flashFactor = 0.0;
        }
        break;
    }

    final result = Uint32List(width * height);
    if (!isVisible) {
      return result; // Fully transparent during off-blink
    }

    final invFactor = 1.0 - flashFactor;

    for (int i = 0; i < width * height; i++) {
      final p = pixels[i];
      final a = (p >> 24) & 0xFF;

      if (a == 0 && preserveAlpha) {
        result[i] = 0;
        continue;
      }

      if (flashFactor <= 0.001) {
        result[i] = p;
        continue;
      }

      final r = (p >> 16) & 0xFF;
      final g = (p >> 8) & 0xFF;
      final b = p & 0xFF;

      final outR = (r * invFactor + flashR * flashFactor).round().clamp(0, 255);
      final outG = (g * invFactor + flashG * flashFactor).round().clamp(0, 255);
      final outB = (b * invFactor + flashB * flashFactor).round().clamp(0, 255);
      final outA = a == 0 ? 255 : a;

      result[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    return result;
  }
}
