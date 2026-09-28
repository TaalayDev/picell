import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ChalkPastelEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ChalkPastelEffect();
      expect(effect.type, equals(EffectType.chalkPastel));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['smudgeRadius'], equals(3.0));
      expect(effect.parameters['charcoalSoftness'], equals(0.5));
      expect(effect.parameters['paperToothRoughness'], equals(0.4));
      expect(effect.parameters['chalkPalette'], equals('charcoalMonochrome'));
      expect(effect.parameters['dustGrainDensity'], equals(0.35));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ChalkPastelEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'smudgeRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'charcoalSoftness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'paperToothRoughness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'chalkPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'dustGrainDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ChalkPastelEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.chalkPastel,
        {
          'smudgeRadius': 4.5,
          'chalkPalette': 'sanguineChalk',
          'paperToothRoughness': 0.6,
        },
      );
      expect(effect, isA<ChalkPastelEffect>());
      expect(effect.parameters['smudgeRadius'], equals(4.5));
      expect(effect.parameters['chalkPalette'], equals('sanguineChalk'));
      expect(effect.parameters['paperToothRoughness'], equals(0.6));
    });

    test('renders charcoal and paper texture on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Half-black, half-white pattern
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = x < 16 ? 0xFF000000 : 0xFFFFFFFF;
        }
      }

      final effect = ChalkPastelEffect({
        'smudgeRadius': 3.0,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, equals(width * height));
    });

    test('different chalk palettes produce distinct color profiles', () {
      const width = 20;
      const height = 20;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF505050; // Mid-gray
      }

      final charcoalEffect = ChalkPastelEffect({'chalkPalette': 'charcoalMonochrome'});
      final sanguineEffect = ChalkPastelEffect({'chalkPalette': 'sanguineChalk'});

      final outCharcoal = charcoalEffect.apply(pixels, width, height);
      final outSanguine = sanguineEffect.apply(pixels, width, height);

      // Sanguine should have higher Red vs Blue ratio than Charcoal
      int sanguineRedBias = 0;
      int charcoalRedBias = 0;
      for (int i = 0; i < pixels.length; i++) {
        final cr = (outCharcoal[i] >> 16) & 0xFF;
        final cb = outCharcoal[i] & 0xFF;
        final sr = (outSanguine[i] >> 16) & 0xFF;
        final sb = outSanguine[i] & 0xFF;
        charcoalRedBias += (cr - cb);
        sanguineRedBias += (sr - sb);
      }

      expect(sanguineRedBias, greaterThan(charcoalRedBias));
    });

    test('preserveAlpha restricts chalk marks to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Central block
      for (int y = 6; y < 18; y++) {
        for (int x = 6; x < 18; x++) {
          pixels[y * width + x] = 0xFF112233;
        }
      }

      final effect = ChalkPastelEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Outside pixel remains transparent
      expect(out[0], equals(0));
      // Inside pixel is drawn
      expect(out[10 * width + 10], isNot(equals(0)));
    });
  });
}
