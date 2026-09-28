import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DelftwareTileEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = DelftwareTileEffect();
      expect(effect.type, equals(EffectType.delftwareTile));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['cobaltBleed'], equals(0.45));
      expect(effect.parameters['crazingCrackDensity'], equals(0.4));
      expect(effect.parameters['enamelGloss'], equals(0.5));
      expect(effect.parameters['tileBevelDepth'], equals(0.4));
      expect(effect.parameters['porcelainWarmth'], equals(0.3));
      expect(effect.parameters['tilePalette'], equals('delftClassicBlue'));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DelftwareTileEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'cobaltBleed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'crazingCrackDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'enamelGloss' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'tileBevelDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'porcelainWarmth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'tilePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DelftwareTileEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.delftwareTile,
        {
          'tilePalette': 'majolicaPolychrome',
          'crazingCrackDensity': 0.6,
          'enamelGloss': 0.7,
        },
      );
      expect(effect, isA<DelftwareTileEffect>());
      expect(effect.parameters['tilePalette'], equals('majolicaPolychrome'));
      expect(effect.parameters['crazingCrackDensity'], equals(0.6));
      expect(effect.parameters['enamelGloss'], equals(0.7));
    });

    test('renders cobalt blue and glazed porcelain on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Simple figure pattern
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = (x > 10 && x < 22 && y > 10 && y < 22) ? 0xFF000000 : 0xFFFFFFFF;
        }
      }

      final effect = DelftwareTileEffect({
        'cobaltBleed': 0.3,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroCount++;
      }
      expect(nonZeroCount, equals(width * height));
    });

    test('crazingCrackDensity introduces hairline glaze fracture lines', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFFFFFFFF; // Pure white tile
      }

      final noCrackEffect = DelftwareTileEffect({
        'crazingCrackDensity': 0.0,
        'tileBevelDepth': 0.0,
        'preserveAlpha': false,
      });
      final heavyCrackEffect = DelftwareTileEffect({
        'crazingCrackDensity': 0.8,
        'tileBevelDepth': 0.0,
        'preserveAlpha': false,
      });

      final outNoCrack = noCrackEffect.apply(pixels, width, height);
      final outHeavyCrack = heavyCrackEffect.apply(pixels, width, height);

      int darkCracks = 0;
      for (int i = 0; i < pixels.length; i++) {
        final b1 = outNoCrack[i] & 0xFF;
        final b2 = outHeavyCrack[i] & 0xFF;
        if (b2 < b1 - 10) darkCracks++;
      }
      expect(darkCracks, greaterThan(0));
    });

    test('preserveAlpha restricts tile glaze to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      for (int y = 8; y < 16; y++) {
        for (int x = 8; x < 16; x++) {
          pixels[y * width + x] = 0xFF2255AA;
        }
      }

      final effect = DelftwareTileEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[12 * width + 12], isNot(equals(0)));
    });
  });
}
