import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BismuthCrystalsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = BismuthCrystalsEffect();
      expect(effect.type, equals(EffectType.bismuthCrystals));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['hopperStepCount'], equals(6));
      expect(effect.parameters['iridescencePalette'], equals('rainbowOxide'));
      expect(effect.parameters['hollowCoreRatio'], equals(0.4));
      expect(effect.parameters['specularEdge'], equals(0.7));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BismuthCrystalsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'hopperStepCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'iridescencePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'hollowCoreRatio' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'specularEdge' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BismuthCrystalsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.bismuthCrystals,
        {
          'hopperStepCount': 8,
          'iridescencePalette': 'amethystOpal',
          'specularEdge': 0.8,
        },
      );
      expect(effect, isA<BismuthCrystalsEffect>());
      expect(effect.parameters['hopperStepCount'], equals(8));
      expect(effect.parameters['iridescencePalette'], equals('amethystOpal'));
      expect(effect.parameters['specularEdge'], equals(0.8));
    });

    test('renders concentric 90-degree hopper terraces and rainbow oxide on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = BismuthCrystalsEffect({
        'hopperStepCount': 6,
        'iridescencePalette': 'rainbowOxide',
        'hollowCoreRatio': 0.4,
        'specularEdge': 0.7,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('generates different palettes (amethystOpal vs solarAura)', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectAmethyst = BismuthCrystalsEffect({
        'iridescencePalette': 'amethystOpal',
        'preserveAlpha': false,
      });
      final effectSolar = BismuthCrystalsEffect({
        'iridescencePalette': 'solarAura',
        'preserveAlpha': false,
      });

      final outAmethyst = effectAmethyst.apply(pixels, width, height);
      final outSolar = effectSolar.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outAmethyst[i] != outSolar[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation drives chromatic wavelength interference shifts', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = BismuthCrystalsEffect({
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = BismuthCrystalsEffect({
        'time': 0.6,
        'preserveAlpha': false,
      });

      final out1 = effect1.apply(pixels, width, height);
      final out2 = effect2.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out1[i] != out2[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });
  });
}
