import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WaterRippleWakeEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = WaterRippleWakeEffect();
      expect(effect.type, equals(EffectType.waterRippleWake));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['rippleRadius'], equals(12.0));
      expect(effect.parameters['waveCount'], equals(3));
      expect(effect.parameters['reflectionDepth'], equals(4.0));
      expect(effect.parameters['waterPalette'], equals('springWater'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WaterRippleWakeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'rippleRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waveCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'reflectionDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes WaterRippleWakeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.waterRippleWake,
        {
          'rippleRadius': 16.0,
          'waterPalette': 'toxicSwamp',
          'waveCount': 4,
        },
      );
      expect(effect, isA<WaterRippleWakeEffect>());
      expect(effect.parameters['rippleRadius'], equals(16.0));
      expect(effect.parameters['waterPalette'], equals('toxicSwamp'));
      expect(effect.parameters['waveCount'], equals(4));
    });

    test('renders concentric ground ripples and reflection beneath feet', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // Centered sprite block at (14..21, 10..18)
      for (int y = 10; y <= 18; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF336699;
        }
      }

      final effect = WaterRippleWakeEffect({
        'rippleRadius': 12.0,
        'waveCount': 3,
        'reflectionDepth': 5.0,
        'waterPalette': 'springWater',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that water ripples expand into the empty space beneath/around the feet (y > 18)
      bool foundWaterPixelBelow = false;
      for (int y = 19; y <= 24; y++) {
        for (int x = 8; x <= 28; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 30) {
              foundWaterPixelBelow = true;
              break;
            }
          }
        }
        if (foundWaterPixelBelow) break;
      }
      expect(foundWaterPixelBelow, isTrue, reason: 'Water ripples should project below baseline');
    });

    test('bloodPool palette produces crimson and wine red ripple colors', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 8; y <= 14; y++) {
        for (int x = 11; x <= 16; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = WaterRippleWakeEffect({
        'rippleRadius': 10.0,
        'waterPalette': 'bloodPool',
        'reflectionDepth': 3.0,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify red / crimson hue in water ripples (R high, G and B lower)
      bool foundBloodRed = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (r > 150 && g < 80 && b < 100) {
            foundBloodRed = true;
            break;
          }
        }
      }
      expect(foundBloodRed, isTrue, reason: 'bloodPool palette should generate red water pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF448833;
      for (int y = 8; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = WaterRippleWakeEffect({
        'rippleRadius': 8.0,
        'reflectionDepth': 3.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must remain untouched
      for (int y = 8; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
