import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('KintsugiLacquerEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = KintsugiLacquerEffect();
      expect(effect.type, equals(EffectType.kintsugiLacquer));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['fractureDensity'], equals(0.5));
      expect(effect.parameters['goldSeamWidth'], equals(2.0));
      expect(effect.parameters['seamImpastoRelief'], equals(0.7));
      expect(effect.parameters['lacquerSheen'], equals(0.6));
      expect(effect.parameters['goldDustSpatter'], equals(0.45));
      expect(effect.parameters['kintsugiStyle'], equals('goldUrushi'));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = KintsugiLacquerEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'fractureDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'goldSeamWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'seamImpastoRelief' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lacquerSheen' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'goldDustSpatter' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'kintsugiStyle' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes KintsugiLacquerEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.kintsugiLacquer,
        {
          'fractureDensity': 0.7,
          'kintsugiStyle': 'celadonCrackle',
          'goldSeamWidth': 2.5,
        },
      );
      expect(effect, isA<KintsugiLacquerEffect>());
      expect(effect.parameters['fractureDensity'], equals(0.7));
      expect(effect.parameters['kintsugiStyle'], equals('celadonCrackle'));
      expect(effect.parameters['goldSeamWidth'], equals(2.5));
    });

    test('renders gold lacquer seams and gold dust spatter', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Dark ceramic base on active layer
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF1B1B1B;
      }

      final effect = KintsugiLacquerEffect({
        'fractureDensity': 0.8,
        'goldSeamWidth': 3.0,
        'seamImpastoRelief': 0.95,
        'goldDustSpatter': 0.5,
        'kintsugiStyle': 'goldUrushi',
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Detect gold pixels (high R, high G, lower B)
      int goldCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        final r = (out[i] >> 16) & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        final b = out[i] & 0xFF;
        if (r > 150 && g > 120 && b < 100) goldCount++;
      }
      expect(goldCount, greaterThan(0));
    });

    test('kintsugiStyle variations produce distinct base glaze and lacquer backgrounds', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF505050;
      }

      final effectUrushi = KintsugiLacquerEffect({
        'kintsugiStyle': 'goldUrushi',
        'fractureDensity': 0.2,
        'preserveAlpha': true,
      });
      final effectCeladon = KintsugiLacquerEffect({
        'kintsugiStyle': 'celadonCrackle',
        'fractureDensity': 0.2,
        'preserveAlpha': true,
      });

      final outUrushi = effectUrushi.apply(pixels, width, height);
      final outCeladon = effectCeladon.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outUrushi[i] != outCeladon[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts kintsugi repair strictly to existing layer pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 vase sprite on layer
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF303030;
        }
      }

      final effect = KintsugiLacquerEffect();

      final out = effect.apply(pixels, width, height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 12 && x < 20 && y >= 12 && y < 20);
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
