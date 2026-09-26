import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('GeyserVentEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = GeyserVentEffect();
      expect(effect.type, equals(EffectType.geyserVent));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['eruptionInterval'], equals(5.0));
      expect(effect.parameters['plumeHeight'], equals(0.75));
      expect(effect.parameters['bubbleBoilRate'], equals(2.0));
      expect(effect.parameters['steamDispersion'], equals(0.6));
      expect(effect.parameters['mineralPalette'], equals('sulfurYellow'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = GeyserVentEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'eruptionInterval' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'plumeHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bubbleBoilRate' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'steamDispersion' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mineralPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes GeyserVentEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.geyserVent,
        {
          'eruptionInterval': 6.0,
          'plumeHeight': 0.9,
          'mineralPalette': 'ironRed',
        },
      );
      expect(effect, isA<GeyserVentEffect>());
      expect(effect.parameters['eruptionInterval'], equals(6.0));
      expect(effect.parameters['plumeHeight'], equals(0.9));
      expect(effect.parameters['mineralPalette'], equals('ironRed'));
    });

    test('renders geothermal mineral terraces and boiling mud basin on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = GeyserVentEffect({
        'mineralPalette': 'sulfurYellow',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('different mineralPalette configurations produce distinct terrace colors', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final sulfur = GeyserVentEffect({
        'mineralPalette': 'sulfurYellow',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final iron = GeyserVentEffect({
        'mineralPalette': 'ironRed',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final silica = GeyserVentEffect({
        'mineralPalette': 'silicaWhite',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffSulfurIron = false;
      bool diffSulfurSilica = false;
      for (int i = 0; i < pixels.length; i++) {
        if (sulfur[i] != iron[i]) diffSulfurIron = true;
        if (sulfur[i] != silica[i]) diffSulfurSilica = true;
      }
      expect(diffSulfurIron, isTrue);
      expect(diffSulfurSilica, isTrue);
    });

    test('time animation drives eruption phases from dormant to explosive blast', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Dormant phase
      final tDormant = GeyserVentEffect({
        'time': 0.1,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      // Peak eruption surge phase
      final tErupt = GeyserVentEffect({
        'time': 0.55,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (tDormant[i] != tErupt[i]) {
          diffDetected = true;
          break;
        }
      }
      expect(diffDetected, isTrue);
    });

    test('preserveAlpha restricts geyser eruption and mud within sprite boundary', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF101010;
        }
      }

      final effect = GeyserVentEffect({
        'time': 0.55,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside 6x6 must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 5 || x >= 11 || y < 5 || y >= 11) {
            expect(out[y * width + x], equals(0));
          }
        }
      }

      int nonZeroInside = 0;
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          if (out[y * width + x] != 0) nonZeroInside++;
        }
      }
      expect(nonZeroInside, greaterThan(0));
    });
  });
}
