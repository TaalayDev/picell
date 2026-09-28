import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DeepSpaceNebulaEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = DeepSpaceNebulaEffect();
      expect(effect.type, equals(EffectType.deepSpaceNebula));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['nebulaPalette'], equals('orionViolet'));
      expect(effect.parameters['fractalTurbulence'], equals(0.6));
      expect(effect.parameters['starClusterDensity'], equals(35));
      expect(effect.parameters['showGasGiant'], isTrue);
      expect(effect.parameters['ringInclination'], equals(20.0));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DeepSpaceNebulaEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'nebulaPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'fractalTurbulence' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'starClusterDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'showGasGiant' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'ringInclination' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DeepSpaceNebulaEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.deepSpaceNebula,
        {
          'nebulaPalette': 'solarGold',
          'fractalTurbulence': 0.8,
          'starClusterDensity': 50,
          'showGasGiant': false,
        },
      );
      expect(effect, isA<DeepSpaceNebulaEffect>());
      expect(effect.parameters['nebulaPalette'], equals('solarGold'));
      expect(effect.parameters['fractalTurbulence'], equals(0.8));
      expect(effect.parameters['starClusterDensity'], equals(50));
      expect(effect.parameters['showGasGiant'], isFalse);
    });

    test('renders cosmic nebula gas, stars, and ringed gas giant', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = DeepSpaceNebulaEffect({
        'nebulaPalette': 'orionViolet',
        'fractalTurbulence': 0.6,
        'starClusterDensity': 35,
        'showGasGiant': true,
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

    test('renders different nebula palettes (solarGold vs emeraldPillars)', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectGold = DeepSpaceNebulaEffect({
        'nebulaPalette': 'solarGold',
        'showGasGiant': false,
        'preserveAlpha': false,
      });
      final effectEmerald = DeepSpaceNebulaEffect({
        'nebulaPalette': 'emeraldPillars',
        'showGasGiant': false,
        'preserveAlpha': false,
      });

      final outGold = effectGold.apply(pixels, width, height);
      final outEmerald = effectEmerald.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outGold[i] != outEmerald[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation drives cloud drift and star twinkling', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = DeepSpaceNebulaEffect({
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = DeepSpaceNebulaEffect({
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
