import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SlimeDripEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SlimeDripEffect();
      expect(effect.type, equals(EffectType.slimeDrip));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['dripFrequency'], equals(2));
      expect(effect.parameters['viscosity'], equals(0.6));
      expect(effect.parameters['liquidColor'], equals(0xFF76FF03));
      expect(effect.parameters['splashSize'], equals(2));
      expect(effect.parameters['gravity'], equals(1.5));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SlimeDripEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'dripFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'viscosity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'liquidColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'splashSize' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'gravity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SlimeDripEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.slimeDrip,
        {
          'viscosity': 0.8,
          'liquidColor': 0xFFD50000,
          'splashSize': 3,
        },
      );
      expect(effect, isA<SlimeDripEffect>());
      expect(effect.parameters['viscosity'], equals(0.8));
      expect(effect.parameters['liquidColor'], equals(0xFFD50000));
      expect(effect.parameters['splashSize'], equals(3));
    });

    test('generates drips hanging or falling from bottom edge of sprite', () {
      const width = 20;
      const height = 30;
      final pixels = Uint32List(width * height);
      // Create a solid block in the top half (rows 4..10)
      for (int y = 4; y <= 10; y++) {
        for (int x = 4; x <= 16; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = SlimeDripEffect({
        'viscosity': 0.7,
        'gravity': 1.5,
        'liquidColor': 0xFF76FF03,
        'preserveAlpha': true,
        'time': 0.5,
      });

      final out = effect.apply(pixels, width, height);

      // Verify that below row 10 (which was empty originally), drip or splatter pixels are drawn
      int belowPixels = 0;
      for (int y = 11; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (out[y * width + x] != 0x00000000) {
            belowPixels++;
          }
        }
      }
      expect(belowPixels, greaterThan(0));
    });

    test('time animation drives droplet progression downwards', () {
      const width = 20;
      const height = 30;
      final pixels = Uint32List(width * height);
      for (int y = 2; y <= 6; y++) {
        for (int x = 2; x <= 18; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effectT0 = SlimeDripEffect({
        'time': 0.1,
        'liquidColor': 0xFF76FF03,
      });

      final effectT1 = SlimeDripEffect({
        'time': 0.7,
        'liquidColor': 0xFF76FF03,
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
