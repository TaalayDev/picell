import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BenDayComicEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = BenDayComicEffect();
      expect(effect.type, equals(EffectType.benDayComic));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['dotPitch'], equals(4.0));
      expect(effect.parameters['misregistrationShift'], equals(1.2));
      expect(effect.parameters['newsprintYellowing'], equals(0.4));
      expect(effect.parameters['cmykDotGain'], equals(0.3));
      expect(effect.parameters['paperInkBleed'], equals(0.25));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BenDayComicEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'dotPitch' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'misregistrationShift' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'newsprintYellowing' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'cmykDotGain' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'paperInkBleed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BenDayComicEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.benDayComic,
        {
          'dotPitch': 6.0,
          'misregistrationShift': 2.0,
          'newsprintYellowing': 0.6,
        },
      );
      expect(effect, isA<BenDayComicEffect>());
      expect(effect.parameters['dotPitch'], equals(6.0));
      expect(effect.parameters['misregistrationShift'], equals(2.0));
      expect(effect.parameters['newsprintYellowing'], equals(0.6));
    });

    test('renders CMYK Ben-Day halftone screen dots on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Saturated test colors
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = (x < 16) ? 0xFFFF0055 : 0xFF00AAFF;
        }
      }

      final effect = BenDayComicEffect({
        'dotPitch': 4.0,
        'misregistrationShift': 1.0,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroCount++;
      }
      expect(nonZeroCount, equals(width * height));
    });

    test('misregistrationShift produces ink color fringing along edges', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Sharp central boundary
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = (x < 16) ? 0xFF00FFFF : 0xFFFF00FF;
        }
      }

      final noShiftEffect = BenDayComicEffect({
        'dotPitch': 3.0,
        'misregistrationShift': 0.0,
        'preserveAlpha': false,
      });
      final heavyShiftEffect = BenDayComicEffect({
        'dotPitch': 3.0,
        'misregistrationShift': 3.0,
        'preserveAlpha': false,
      });

      final outNoShift = noShiftEffect.apply(pixels, width, height);
      final outHeavyShift = heavyShiftEffect.apply(pixels, width, height);

      // Check pixel difference around edge (x = 15, 16, 17)
      int edgeDiffCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 14; x <= 18; x++) {
          if (outNoShift[y * width + x] != outHeavyShift[y * width + x]) {
            edgeDiffCount++;
          }
        }
      }
      expect(edgeDiffCount, greaterThan(0));
    });

    test('preserveAlpha restricts comic dots to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      for (int y = 6; y < 18; y++) {
        for (int x = 6; x < 18; x++) {
          pixels[y * width + x] = 0xFFEE2211;
        }
      }

      final effect = BenDayComicEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[10 * width + 10], isNot(equals(0)));
    });
  });
}
