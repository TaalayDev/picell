import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RomanTravertineEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = RomanTravertineEffect();
      expect(effect.type, equals(EffectType.romanTravertine));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['blockScale'], equals(6.0));
      expect(effect.parameters['poreDensity'], equals(0.45));
      expect(effect.parameters['beddingBands'], equals(0.6));
      expect(effect.parameters['mortarWidth'], equals(1.8));
      expect(effect.parameters['stoneErosion'], equals(0.5));
      expect(effect.parameters['travertinePalette'], equals('classicIvory'));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RomanTravertineEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'blockScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'poreDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'beddingBands' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mortarWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'stoneErosion' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'travertinePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes RomanTravertineEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.romanTravertine,
        {
          'blockScale': 8.0,
          'travertinePalette': 'silverVein',
          'poreDensity': 0.7,
        },
      );
      expect(effect, isA<RomanTravertineEffect>());
      expect(effect.parameters['blockScale'], equals(8.0));
      expect(effect.parameters['travertinePalette'], equals('silverVein'));
      expect(effect.parameters['poreDensity'], equals(0.7));
    });

    test('renders ashlar stone blocks, karst pores, and mortar joints', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Fill with solid neutral color
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF888888;
      }

      final effect = RomanTravertineEffect({
        'blockScale': 6.0,
        'travertinePalette': 'classicIvory',
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroCount++;
      }
      expect(nonZeroCount, equals(width * height));
    });

    test('travertinePalette variations produce distinct limestone hues', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFFAAAAAA;
      }

      final effectIvory = RomanTravertineEffect({
        'travertinePalette': 'classicIvory',
        'preserveAlpha': true,
      });
      final effectPompeii = RomanTravertineEffect({
        'travertinePalette': 'pompeiiOchre',
        'preserveAlpha': true,
      });

      final outIvory = effectIvory.apply(pixels, width, height);
      final outPompeii = effectPompeii.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outIvory[i] != outPompeii[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts travertine texture strictly to existing layer pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 10x10 square is drawn on layer
      for (int y = 11; y < 21; y++) {
        for (int x = 11; x < 21; x++) {
          pixels[y * width + x] = 0xFFCCCCCC;
        }
      }

      final effect = RomanTravertineEffect();

      final out = effect.apply(pixels, width, height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 11 && x < 21 && y >= 11 && y < 21);
          final a = (out[y * width + x] >> 24) & 0xFF;
          if (!isInside) {
            expect(a, equals(0), reason: 'Transparent pixels must remain transparent');
          } else {
            expect(a, equals(255), reason: 'Existing pixels must be textured');
          }
        }
      }
    });
  });
}
