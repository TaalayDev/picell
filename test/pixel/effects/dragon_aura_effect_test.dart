import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DragonAuraEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = DragonAuraEffect();
      expect(effect.type, equals(EffectType.dragonAura));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['auraColor'], equals(0xFFFFD600));
      expect(effect.parameters['spikiness'], equals(0.7));
      expect(effect.parameters['riseSpeed'], equals(1.5));
      expect(effect.parameters['coreLuminance'], equals(0.6));
      expect(effect.parameters['miniArcs'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DragonAuraEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'auraColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'spikiness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'riseSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'coreLuminance' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'miniArcs' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DragonAuraEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.dragonAura,
        {
          'auraColor': 0xFFFF1744,
          'spikiness': 0.85,
          'riseSpeed': 2.0,
        },
      );
      expect(effect, isA<DragonAuraEffect>());
      expect(effect.parameters['auraColor'], equals(0xFFFF1744));
      expect(effect.parameters['spikiness'], equals(0.85));
      expect(effect.parameters['riseSpeed'], equals(2.0));
    });

    test('renders rising plasma flames and core illumination over sprite', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF353535;
      }

      final effect = DragonAuraEffect({
        'auraColor': 0xFFFFD600,
        'spikiness': 0.8,
        'coreLuminance': 0.7,
        'time': 0.35,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF353535) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('time animation drives upward plasma flame oscillation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF353535;
      }

      final effect1 = DragonAuraEffect({'time': 0.1, 'preserveAlpha': false});
      final effect2 = DragonAuraEffect({'time': 0.6, 'preserveAlpha': false});

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

      final effect = DragonAuraEffect({
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
