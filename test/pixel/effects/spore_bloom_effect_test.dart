import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SporeBloomEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SporeBloomEffect();
      expect(effect.type, equals(EffectType.sporeBloom));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['mushroomCount'], equals(6));
      expect(effect.parameters['bioluminescenceGlow'], equals(0.7));
      expect(effect.parameters['sporeCloudDensity'], equals(0.5));
      expect(effect.parameters['capPalette'], equals('mycenaCyan'));
      expect(effect.parameters['airDriftSpeed'], equals(1.0));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SporeBloomEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'mushroomCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bioluminescenceGlow' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sporeCloudDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'capPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'airDriftSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SporeBloomEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.sporeBloom,
        {
          'mushroomCount': 8,
          'capPalette': 'ghostFungusEmerald',
          'bioluminescenceGlow': 0.9,
        },
      );
      expect(effect, isA<SporeBloomEffect>());
      expect(effect.parameters['mushroomCount'], equals(8));
      expect(effect.parameters['capPalette'], equals('ghostFungusEmerald'));
      expect(effect.parameters['bioluminescenceGlow'], equals(0.9));
    });

    test('renders glowing mushroom caps and upward-venting spores on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Dark forest loam background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF080C0E;
      }

      final effect = SporeBloomEffect({
        'mushroomCount': 5,
        'bioluminescenceGlow': 0.8,
        'sporeCloudDensity': 0.6,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int brightPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        final r = (out[i] >> 16) & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        final b = out[i] & 0xFF;
        if (r > 30 || g > 30 || b > 30) brightPixels++;
      }
      expect(brightPixels, greaterThan(0));
    });

    test('time animation advances spore particle ascent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF050505;
      }

      final effectT0 = SporeBloomEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = SporeBloomEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts mushroom caps and spores to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Central pillar
      for (int y = 0; y < height; y++) {
        for (int x = 8; x < 16; x++) {
          pixels[y * width + x] = 0xFF1A1A1A;
        }
      }

      final effect = SporeBloomEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[20 * width + 12], isNot(equals(0)));
    });
  });
}
