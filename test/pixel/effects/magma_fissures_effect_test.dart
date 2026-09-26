import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('MagmaFissuresEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = MagmaFissuresEffect();
      expect(effect.type, equals(EffectType.magmaFissures));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['fissureDensity'], equals(4));
      expect(effect.parameters['magmaColor'], equals(0xFFFF3D00));
      expect(effect.parameters['heatHazeDistortion'], equals(0.6));
      expect(effect.parameters['pulseSpeed'], equals(1.2));
      expect(effect.parameters['crustDarkening'], equals(0.45));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = MagmaFissuresEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'fissureDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'magmaColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'heatHazeDistortion' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'pulseSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'crustDarkening' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes MagmaFissuresEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.magmaFissures,
        {
          'fissureDensity': 6,
          'magmaColor': 0xFFFFD600,
          'heatHazeDistortion': 0.8,
        },
      );
      expect(effect, isA<MagmaFissuresEffect>());
      expect(effect.parameters['fissureDensity'], equals(6));
      expect(effect.parameters['magmaColor'], equals(0xFFFFD600));
      expect(effect.parameters['heatHazeDistortion'], equals(0.8));
    });

    test('renders glowing molten fissures and charred margins on sprite', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF505050;
      }

      final effect = MagmaFissuresEffect({
        'fissureDensity': 5,
        'magmaColor': 0xFFFF3D00,
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF505050) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('time animation modulates thermal pulsing and heat haze', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF505050;
      }

      final effect1 = MagmaFissuresEffect({'time': 0.1, 'preserveAlpha': false});
      final effect2 = MagmaFissuresEffect({'time': 0.6, 'preserveAlpha': false});

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

      final effect = MagmaFissuresEffect({
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
