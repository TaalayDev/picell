import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RisingBubblesEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = RisingBubblesEffect();
      expect(effect.type, equals(EffectType.risingBubbles));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['bubbleCount'], equals(20));
      expect(effect.parameters['bubbleSize'], equals('mixed'));
      expect(effect.parameters['wobbleSpeed'], equals(1.5));
      expect(effect.parameters['riseSpeed'], equals(1.2));
      expect(effect.parameters['popSplashes'], isTrue);
      expect(effect.parameters['bubbleColor'], equals(0xFFE0F7FA));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RisingBubblesEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'bubbleCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bubbleSize' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'wobbleSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'riseSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bubbleColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'popSplashes' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes RisingBubblesEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.risingBubbles,
        {
          'bubbleCount': 45,
          'bubbleColor': 0xFF76FF03,
          'popSplashes': false,
        },
      );
      expect(effect, isA<RisingBubblesEffect>());
      expect(effect.parameters['bubbleCount'], equals(45));
      expect(effect.parameters['bubbleColor'], equals(0xFF76FF03));
      expect(effect.parameters['popSplashes'], isFalse);
    });

    test('renders bubbles over sprite pixels when preserveAlpha is true', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      // Fill solid canvas
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF102030;
      }

      final effect = RisingBubblesEffect({
        'bubbleCount': 30,
        'bubbleColor': 0xFF00E5FF,
        'preserveAlpha': true,
        'time': 0.3,
      });

      final out = effect.apply(pixels, width, height);

      // Verify that bubble highlight pixels were stamped into the canvas
      int alteredCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF102030) {
          alteredCount++;
        }
      }
      expect(alteredCount, greaterThan(0));
    });

    test('time animation advances bubble positions upwards', () {
      const width = 20;
      const height = 30;
      final pixels = Uint32List(width * height);

      final effectT0 = RisingBubblesEffect({
        'bubbleCount': 10,
        'preserveAlpha': false,
        'time': 0.1,
      });

      final effectT1 = RisingBubblesEffect({
        'bubbleCount': 10,
        'preserveAlpha': false,
        'time': 0.6,
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
