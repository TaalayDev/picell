import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ThermalReceiptEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ThermalReceiptEffect();
      expect(effect.type, equals(EffectType.thermalReceipt));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['pinDensity'], equals(2.0));
      expect(effect.parameters['thermalBurnStrength'], equals(0.6));
      expect(effect.parameters['paperFadeAge'], equals(0.35));
      expect(effect.parameters['feedLineJitter'], equals(0.3));
      expect(effect.parameters['creaseDistortion'], equals(0.25));
      expect(effect.parameters['receiptTheme'], equals('posThermalBlack'));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ThermalReceiptEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'pinDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'thermalBurnStrength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'paperFadeAge' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'feedLineJitter' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'creaseDistortion' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'receiptTheme' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ThermalReceiptEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.thermalReceipt,
        {
          'receiptTheme': 'retroDotMatrix',
          'thermalBurnStrength': 0.8,
          'pinDensity': 3.0,
        },
      );
      expect(effect, isA<ThermalReceiptEffect>());
      expect(effect.parameters['receiptTheme'], equals('retroDotMatrix'));
      expect(effect.parameters['thermalBurnStrength'], equals(0.8));
      expect(effect.parameters['pinDensity'], equals(3.0));
    });

    test('renders dithered needle impact marks and receipt paper on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Gradient pattern
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final v = (x * 255 ~/ 31);
          pixels[y * width + x] = 0xFF000000 | (v << 16) | (v << 8) | v;
        }
      }

      final effect = ThermalReceiptEffect({
        'pinDensity': 2.0,
        'thermalBurnStrength': 0.7,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroCount++;
      }
      expect(nonZeroCount, equals(width * height));
    });

    test('different receipt themes produce distinctive paper and dye tones', () {
      const width = 20;
      const height = 20;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020; // Dark image => heavy burn
      }

      final posEffect = ThermalReceiptEffect({
        'receiptTheme': 'posThermalBlack',
        'paperFadeAge': 0.0,
        'preserveAlpha': false,
      });
      final dotMatrixEffect = ThermalReceiptEffect({
        'receiptTheme': 'retroDotMatrix',
        'paperFadeAge': 0.0,
        'preserveAlpha': false,
      });

      final outPos = posEffect.apply(pixels, width, height);
      final outMatrix = dotMatrixEffect.apply(pixels, width, height);

      // Dot matrix purple ribbon has higher Blue component than POS thermal charcoal
      int matrixBlueBias = 0;
      for (int i = 0; i < pixels.length; i++) {
        final pb = outPos[i] & 0xFF;
        final mb = outMatrix[i] & 0xFF;
        if (mb > pb) matrixBlueBias++;
      }
      expect(matrixBlueBias, greaterThan(0));
    });

    test('preserveAlpha restricts thermal burn to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      for (int y = 5; y < 19; y++) {
        for (int x = 5; x < 19; x++) {
          pixels[y * width + x] = 0xFF000000;
        }
      }

      final effect = ThermalReceiptEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[10 * width + 10], isNot(equals(0)));
    });
  });
}
