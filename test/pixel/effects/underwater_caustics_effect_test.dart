import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('UnderwaterCausticsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = UnderwaterCausticsEffect();
      expect(effect.type, equals(EffectType.underwaterCaustics));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['causticScale'], equals(1.5));
      expect(effect.parameters['rippleSpeed'], equals(1.5));
      expect(effect.parameters['waterTint'], equals(0xFF00E5FF));
      expect(effect.parameters['tintStrength'], equals(0.4));
      expect(effect.parameters['buoyancySway'], equals(1.2));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = UnderwaterCausticsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'causticScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rippleSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterTint' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'tintStrength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'buoyancySway' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes UnderwaterCausticsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.underwaterCaustics,
        {
          'causticScale': 1.8,
          'waterTint': 0xFF0D47A1,
          'buoyancySway': 2.5,
        },
      );
      expect(effect, isA<UnderwaterCausticsEffect>());
      expect(effect.parameters['causticScale'], equals(1.8));
      expect(effect.parameters['waterTint'], equals(0xFF0D47A1));
      expect(effect.parameters['buoyancySway'], equals(2.5));
    });

    test('applies water tinting and caustic luminance modulation to sprite pixels', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      // Fill central block with grey
      for (int y = 4; y < 12; y++) {
        for (int x = 4; x < 12; x++) {
          pixels[y * width + x] = 0xFF808080;
        }
      }

      final effect = UnderwaterCausticsEffect({
        'buoyancySway': 0.0, // Disable sway to test in-place shading
        'waterTint': 0xFF00FFFF, // Cyan tint
        'tintStrength': 0.5,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Outside the block should remain transparent (preserveAlpha: true)
      expect(out[0], equals(0x00000000));

      // Inside pixels should be modified with cyan tint
      final centerPixel = out[8 * width + 8];
      expect(centerPixel, isNot(equals(0xFF808080)));
      expect((centerPixel >> 24) & 0xFF, equals(255)); // Fully opaque alpha
      // Green and Blue channels should be boosted by cyan tint
      final g = (centerPixel >> 8) & 0xFF;
      final b = centerPixel & 0xFF;
      expect(g, greaterThan(100));
      expect(b, greaterThan(100));
    });

    test('preserveAlpha false renders caustics across entire canvas', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height); // completely empty canvas

      final effect = UnderwaterCausticsEffect({
        'preserveAlpha': false,
        'waterTint': 0xFF0080FF,
        'tintStrength': 0.3,
      });

      final out = effect.apply(pixels, width, height);

      // Background pixels should now be colored
      expect(out[0], isNot(equals(0x00000000)));
      expect(((out[0] >> 24) & 0xFF), greaterThan(0));
    });

    test('time animation cycles caustics pattern', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      final effectT0 = UnderwaterCausticsEffect({
        'time': 0.0,
        'buoyancySway': 0.0,
      });

      final effectT1 = UnderwaterCausticsEffect({
        'time': 0.5,
        'buoyancySway': 0.0,
      });

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      // Patterns at different times should differ
      bool anyDifferent = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) {
          anyDifferent = true;
          break;
        }
      }
      expect(anyDifferent, isTrue);
    });
  });
}
