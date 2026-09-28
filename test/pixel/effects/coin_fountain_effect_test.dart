import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CoinFountainEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = CoinFountainEffect();
      expect(effect.type, equals(EffectType.coinFountain));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['itemType'], equals('coins'));
      expect(effect.parameters['particleCount'], equals(24));
      expect(effect.parameters['fountainForce'], equals(1.2));
      expect(effect.parameters['gravity'], equals(1.0));
      expect(effect.parameters['bounceFloor'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CoinFountainEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'itemType' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'particleCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'fountainForce' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'gravity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bounceFloor' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CoinFountainEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.coinFountain,
        {
          'itemType': 'gems',
          'particleCount': 30,
          'fountainForce': 1.5,
        },
      );
      expect(effect, isA<CoinFountainEffect>());
      expect(effect.parameters['itemType'], equals('gems'));
      expect(effect.parameters['particleCount'], equals(30));
      expect(effect.parameters['fountainForce'], equals(1.5));
    });

    test('renders celebratory items bursting over canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF222222;
      }

      final effect = CoinFountainEffect({
        'itemType': 'coins',
        'particleCount': 24,
        'time': 0.35,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF222222) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('supports all four item profiles: coins, gems, confetti, stars', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF222222;
      }

      for (final type in ['coins', 'gems', 'confetti', 'stars']) {
        final effect = CoinFountainEffect({
          'itemType': type,
          'particleCount': 16,
          'time': 0.3,
          'preserveAlpha': false,
        });
        final out = effect.apply(pixels, width, height);
        expect(out.any((p) => p != 0xFF222222), isTrue);
      }
    });

    test('time animation advances particle ballistic trajectories', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF222222;
      }

      final effect1 = CoinFountainEffect({'time': 0.1, 'preserveAlpha': false});
      final effect2 = CoinFountainEffect({'time': 0.6, 'preserveAlpha': false});

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

      final effect = CoinFountainEffect({
        'time': 0.35,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
