import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('MeteorShowerEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = MeteorShowerEffect();
      expect(effect.type, equals(EffectType.meteorShower));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['meteorAngle'], equals(-45.0));
      expect(effect.parameters['showerDensity'], equals(12));
      expect(effect.parameters['trailLength'], equals(12));
      expect(effect.parameters['meteorSpeed'], equals(1.5));
      expect(effect.parameters['burnColor'], equals(0xFFFFF59D));
      expect(effect.parameters['burstFlashes'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = MeteorShowerEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'meteorAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'showerDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'trailLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'meteorSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'burnColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'burstFlashes' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes MeteorShowerEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.meteorShower,
        {
          'meteorAngle': -60.0,
          'showerDensity': 18,
          'burnColor': 0xFF00E5FF,
        },
      );
      expect(effect, isA<MeteorShowerEffect>());
      expect(effect.parameters['meteorAngle'], equals(-60.0));
      expect(effect.parameters['showerDensity'], equals(18));
      expect(effect.parameters['burnColor'], equals(0xFF00E5FF));
    });

    test('renders incandescent meteors and trails over sprite canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF101020;
      }

      final effect = MeteorShowerEffect({
        'showerDensity': 15,
        'trailLength': 10,
        'meteorSpeed': 1.5,
        'burnColor': 0xFFFFF59D,
        'time': 0.35,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int brightenedCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF101020) {
          brightenedCount++;
        }
      }
      expect(brightenedCount, greaterThan(0));
    });

    test('time animation advances shooting star positions', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectT0 = MeteorShowerEffect({
        'time': 0.1,
        'preserveAlpha': false,
      });

      final effectT1 = MeteorShowerEffect({
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
