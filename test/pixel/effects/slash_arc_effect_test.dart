import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SlashArcEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SlashArcEffect();
      expect(effect.type, equals(EffectType.slashArc));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['slashAngle'], equals(-35.0));
      expect(effect.parameters['arcCurvature'], equals(0.4));
      expect(effect.parameters['slashWidth'], equals(3));
      expect(effect.parameters['bladeColor'], equals(0xFF00E5FF));
      expect(effect.parameters['sparkSpray'], isTrue);
      expect(effect.parameters['sparkCount'], equals(25));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SlashArcEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'slashAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'arcCurvature' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'slashWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bladeColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'sparkSpray' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'sparkCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SlashArcEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.slashArc,
        {
          'slashAngle': 45.0,
          'bladeColor': 0xFFFF1744,
          'slashWidth': 5,
        },
      );
      expect(effect, isA<SlashArcEffect>());
      expect(effect.parameters['slashAngle'], equals(45.0));
      expect(effect.parameters['bladeColor'], equals(0xFFFF1744));
      expect(effect.parameters['slashWidth'], equals(5));
    });

    test('renders curved blade streak across sprite pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      // Fill canvas
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF102030;
      }

      final effect = SlashArcEffect({
        'slashAngle': -35.0,
        'arcCurvature': 0.4,
        'slashWidth': 4,
        'bladeColor': 0xFF00E5FF,
        'sparkSpray': false,
        'time': 0.5,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int alteredCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF102030) {
          alteredCount++;
        }
      }
      expect(alteredCount, greaterThan(0));
    });

    test('time animation advances blade sweep position', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF000000;
      }

      final effectT0 = SlashArcEffect({
        'time': 0.2,
        'sparkSpray': false,
        'preserveAlpha': false,
      });

      final effectT1 = SlashArcEffect({
        'time': 0.7,
        'sparkSpray': false,
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
