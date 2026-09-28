import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CursedChainsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = CursedChainsEffect();
      expect(effect.type, equals(EffectType.cursedChains));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['chainCount'], equals(3));
      expect(effect.parameters['chainTightness'], equals(1.0));
      expect(effect.parameters['runeColor'], equals(0xFFFF1744));
      expect(effect.parameters['strainVibration'], equals(0.5));
      expect(effect.parameters['shatterTrigger'], equals(0.75));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CursedChainsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'chainCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'chainTightness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'runeColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'strainVibration' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shatterTrigger' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CursedChainsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.cursedChains,
        {
          'chainCount': 4,
          'chainTightness': 1.2,
          'runeColor': 0xFF00E5FF,
        },
      );
      expect(effect, isA<CursedChainsEffect>());
      expect(effect.parameters['chainCount'], equals(4));
      expect(effect.parameters['chainTightness'], equals(1.2));
      expect(effect.parameters['runeColor'], equals(0xFF00E5FF));
    });

    test('renders interlocking chains and glowing runes on character silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF303030;
      }

      final effect = CursedChainsEffect({
        'chainCount': 3,
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixelCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF303030) {
          changedPixelCount++;
        }
      }
      expect(changedPixelCount, greaterThan(0));
    });

    test('time animation drives chain strain and shatter break sequence', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF303030;
      }

      // Pre-shatter binding phase vs post-shatter broken shard phase
      final bindingEffect = CursedChainsEffect({'time': 0.3, 'shatterTrigger': 0.75, 'preserveAlpha': false});
      final shatteredEffect = CursedChainsEffect({'time': 0.85, 'shatterTrigger': 0.75, 'preserveAlpha': false});

      final bindingOut = bindingEffect.apply(pixels, width, height);
      final shatteredOut = shatteredEffect.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (bindingOut[i] != shatteredOut[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('respects preserveAlpha and does not alter empty transparent pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height); // All transparent

      final effect = CursedChainsEffect({
        'time': 0.85, // Even during shatter
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
