import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SoulWispsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SoulWispsEffect();
      expect(effect.type, equals(EffectType.soulWisps));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['soulCount'], equals(3));
      expect(effect.parameters['orbitRadius'], equals(0.38));
      expect(effect.parameters['orbitSpeed'], equals(1.2));
      expect(effect.parameters['wispColor'], equals(0xFF00E676));
      expect(effect.parameters['trailLength'], equals(8));
      expect(effect.parameters['whisperJitter'], equals(0.4));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SoulWispsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'soulCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'wispColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'trailLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'whisperJitter' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SoulWispsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.soulWisps,
        {
          'soulCount': 5,
          'orbitRadius': 0.45,
          'wispColor': 0xFF00E5FF,
        },
      );
      expect(effect, isA<SoulWispsEffect>());
      expect(effect.parameters['soulCount'], equals(5));
      expect(effect.parameters['orbitRadius'], equals(0.45));
      expect(effect.parameters['wispColor'], equals(0xFF00E5FF));
    });

    test('renders spirit skulls and vapor trails over sprite', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020;
      }

      final effect = SoulWispsEffect({
        'soulCount': 4,
        'orbitRadius': 0.35,
        'wispColor': 0xFF00E676,
        'time': 0.3,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixelCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF202020) {
          changedPixelCount++;
        }
      }
      expect(changedPixelCount, greaterThan(0));
    });

    test('time animation changes spirit positions in 3D orbit', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020;
      }

      final effect1 = SoulWispsEffect({'time': 0.1, 'preserveAlpha': false});
      final effect2 = SoulWispsEffect({'time': 0.6, 'preserveAlpha': false});

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

    test('respects preserveAlpha and does not write to transparent background', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height); // All transparent

      final effect = SoulWispsEffect({
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
