import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('AbyssalTentaclesEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = AbyssalTentaclesEffect();
      expect(effect.type, equals(EffectType.abyssalTentacles));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['tentacleCount'], equals(5));
      expect(effect.parameters['tentacleLength'], equals(18));
      expect(effect.parameters['wriggleSpeed'], equals(1.5));
      expect(effect.parameters['eyeBlinkRate'], equals(1.2));
      expect(effect.parameters['eyeColor'], equals(0xFFFF1744));
      expect(effect.parameters['tentacleColor'], equals(0xFF1B002B));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = AbyssalTentaclesEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'tentacleCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'tentacleLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'wriggleSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'eyeBlinkRate' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'eyeColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'tentacleColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes AbyssalTentaclesEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.abyssalTentacles,
        {
          'tentacleCount': 7,
          'tentacleLength': 18,
          'eyeColor': 0xFFFF1744,
        },
      );
      expect(effect, isA<AbyssalTentaclesEffect>());
      expect(effect.parameters['tentacleCount'], equals(7));
      expect(effect.parameters['tentacleLength'], equals(18));
      expect(effect.parameters['eyeColor'], equals(0xFFFF1744));
    });

    test('renders writhing tentacles and eyes over sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF404040;
      }

      final effect = AbyssalTentaclesEffect({
        'tentacleCount': 5,
        'tentacleLength': 14,
        'eyeColor': 0xFFFFD600,
        'time': 0.2,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixelCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF404040) {
          changedPixelCount++;
        }
      }
      expect(changedPixelCount, greaterThan(0));
    });

    test('time animation undulates tentacles and updates eye glancing', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF404040;
      }

      final effect1 = AbyssalTentaclesEffect({'time': 0.1, 'preserveAlpha': false});
      final effect2 = AbyssalTentaclesEffect({'time': 0.6, 'preserveAlpha': false});

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

    test('respects preserveAlpha and does not draw onto transparent empty background', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height); // All transparent

      final effect = AbyssalTentaclesEffect({
        'time': 0.3,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
