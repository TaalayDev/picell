import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('FrostGlazeEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = FrostGlazeEffect();
      expect(effect.type, equals(EffectType.frostGlaze));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['crystalDensity'], equals(5));
      expect(effect.parameters['iceTint'], equals(0xFF80D8FF));
      expect(effect.parameters['frostBranching'], equals(0.7));
      expect(effect.parameters['specularShimmer'], equals(0.6));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = FrostGlazeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'crystalDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'iceTint' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'frostBranching' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'specularShimmer' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes FrostGlazeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.frostGlaze,
        {
          'crystalDensity': 8,
          'iceTint': 0xFF00E5FF,
          'frostBranching': 0.85,
        },
      );
      expect(effect, isA<FrostGlazeEffect>());
      expect(effect.parameters['crystalDensity'], equals(8));
      expect(effect.parameters['iceTint'], equals(0xFF00E5FF));
      expect(effect.parameters['frostBranching'], equals(0.85));
    });

    test('renders glacial frost glaze and crystals over sprite', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF404040;
      }

      final effect = FrostGlazeEffect({
        'crystalDensity': 6,
        'iceTint': 0xFF80D8FF,
        'time': 0.5,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF404040) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('time animation advances upward freeze front propagation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF404040;
      }

      // Early freeze vs full freeze
      final effect1 = FrostGlazeEffect({'time': 0.1, 'preserveAlpha': false});
      final effect2 = FrostGlazeEffect({'time': 0.8, 'preserveAlpha': false});

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

      final effect = FrostGlazeEffect({
        'time': 0.5,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
