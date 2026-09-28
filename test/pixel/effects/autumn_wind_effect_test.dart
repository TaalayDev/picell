import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('AutumnWindEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = AutumnWindEffect();
      expect(effect.type, equals(EffectType.autumnWind));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['foliageType'], equals('maple'));
      expect(effect.parameters['leafCount'], equals(25));
      expect(effect.parameters['windStrength'], equals(1.2));
      expect(effect.parameters['gustFrequency'], equals(1.5));
      expect(effect.parameters['swirlVortex'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = AutumnWindEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'foliageType' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'leafCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'windStrength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'gustFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'swirlVortex' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes AutumnWindEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.autumnWind,
        {
          'foliageType': 'sakura',
          'leafCount': 35,
          'windStrength': 1.8,
        },
      );
      expect(effect, isA<AutumnWindEffect>());
      expect(effect.parameters['foliageType'], equals('sakura'));
      expect(effect.parameters['leafCount'], equals(35));
      expect(effect.parameters['windStrength'], equals(1.8));
    });

    test('renders tumbling foliage particles across canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020;
      }

      final effect = AutumnWindEffect({
        'foliageType': 'maple',
        'leafCount': 30,
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int leafPixelCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF202020) {
          leafPixelCount++;
        }
      }
      expect(leafPixelCount, greaterThan(0));
    });

    test('time animation drives leaf movement and 3D tumbling', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectT0 = AutumnWindEffect({
        'time': 0.1,
        'preserveAlpha': false,
      });

      final effectT1 = AutumnWindEffect({
        'time': 0.6,
        'preserveAlpha': false,
      });

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      bool differ = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) {
          differ = true;
          break;
        }
      }
      expect(differ, isTrue);
    });
  });
}
