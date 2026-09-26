import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WindAshDispersalEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = WindAshDispersalEffect();
      expect(effect.type, equals(EffectType.windAshDispersal));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['disperseProgress'], equals(0.4));
      expect(effect.parameters['windAngle'], equals(20.0));
      expect(effect.parameters['scatterSpread'], equals(0.5));
      expect(effect.parameters['particleDensity'], equals(0.65));
      expect(effect.parameters['driftDistance'], equals(10.0));
      expect(effect.parameters['emberGlow'], equals(0.5));
      expect(effect.parameters['ashPalette'], equals('volcanicAsh'));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WindAshDispersalEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'disperseProgress' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'windAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'scatterSpread' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'particleDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'driftDistance' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'emberGlow' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'ashPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes WindAshDispersalEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.windAshDispersal,
        {
          'disperseProgress': 0.6,
          'ashPalette': 'desertSand',
          'driftDistance': 15.0,
        },
      );
      expect(effect, isA<WindAshDispersalEffect>());
      expect(effect.parameters['disperseProgress'], equals(0.6));
      expect(effect.parameters['ashPalette'], equals('desertSand'));
      expect(effect.parameters['driftDistance'], equals(15.0));
    });

    test('erodes upwind contours and generates downwind drifting motes', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Solid color block
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF445566;
      }

      final effectZero = WindAshDispersalEffect({
        'disperseProgress': 0.0,
        'emberGlow': 0.0,
      });
      final effectEroded = WindAshDispersalEffect({
        'disperseProgress': 0.6,
        'driftDistance': 8.0,
        'particleDensity': 0.8,
      });

      final outZero = effectZero.apply(pixels, width, height);
      final outEroded = effectEroded.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outZero[i] != outEroded[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('ashPalette variations produce distinct ash and ember tones', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF505050;
      }

      final effectVolcano = WindAshDispersalEffect({
        'ashPalette': 'volcanicAsh',
        'disperseProgress': 0.5,
      });
      final effectSpirit = WindAshDispersalEffect({
        'ashPalette': 'spiritEctoplasm',
        'disperseProgress': 0.5,
      });

      final outVolcano = effectVolcano.apply(pixels, width, height);
      final outSpirit = effectSpirit.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outVolcano[i] != outSpirit[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha strictly confines particles to layer pixels and keeps empty space transparent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 10x10 block
      for (int y = 11; y < 21; y++) {
        for (int x = 11; x < 21; x++) {
          pixels[y * width + x] = 0xFF884422;
        }
      }

      final effect = WindAshDispersalEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Corners and exterior must remain completely transparent
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 11 && x < 21 && y >= 11 && y < 21);
          final a = (out[y * width + x] >> 24) & 0xFF;
          if (!isInside) {
            expect(a, equals(0));
          }
        }
      }
    });
  });
}
