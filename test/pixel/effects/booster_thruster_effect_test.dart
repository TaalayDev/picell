import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BoosterThrusterEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = BoosterThrusterEffect();
      expect(effect.type, equals(EffectType.boosterThruster));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['thrustAngle'], equals(90.0));
      expect(effect.parameters['flameLength'], equals(24.0));
      expect(effect.parameters['plumeWidth'], equals(0.8));
      expect(effect.parameters['shockDiamonds'], isTrue);
      expect(effect.parameters['exhaustPalette'], equals('rocketOrange'));
      expect(effect.parameters['smokeBillow'], equals(0.5));
      expect(effect.parameters['behindOnly'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BoosterThrusterEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'thrustAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flameLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'plumeWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shockDiamonds' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'exhaustPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'smokeBillow' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BoosterThrusterEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.boosterThruster,
        {
          'thrustAngle': 180.0,
          'flameLength': 36.0,
          'exhaustPalette': 'plasmaBlue',
        },
      );
      expect(effect, isA<BoosterThrusterEffect>());
      expect(effect.parameters['thrustAngle'], equals(180.0));
      expect(effect.parameters['flameLength'], equals(36.0));
      expect(effect.parameters['exhaustPalette'], equals('plasmaBlue'));
    });

    test('projects rocket exhaust flame along thrustAngle direction from sprite edge', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Rocket sprite centered near top: x in [14..18], y in [4..10]
      for (int y = 4; y <= 10; y++) {
        for (int x = 14; x <= 18; x++) {
          pixels[y * width + x] = 0xFFCCCCCC; // rocket hull
        }
      }

      // Downward thrust: angle 90° -> exhaust shoots downward (y > 10)
      final effect = BoosterThrusterEffect({
        'thrustAngle': 90.0,
        'flameLength': 16.0,
        'plumeWidth': 0.8,
        'shockDiamonds': true,
        'exhaustPalette': 'rocketOrange',
        'smokeBillow': 0.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that flame exhaust appears beneath the rocket nozzle (y in [11..22], x in [14..18])
      bool foundFlameBelow = false;
      for (int y = 11; y <= 22; y++) {
        final p = result[y * width + 16];
        if (((p >> 24) & 0xFF) > 0) {
          foundFlameBelow = true;
          break;
        }
      }
      expect(foundFlameBelow, isTrue, reason: 'Flame exhaust should project downward from the nozzle');

      // Verify that above the rocket (y < 4) there is NO flame
      bool foundFlameAbove = false;
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < width; x++) {
          if (((result[y * width + x] >> 24) & 0xFF) > 0) {
            foundFlameAbove = true;
            break;
          }
        }
      }
      expect(foundFlameAbove, isFalse, reason: 'Flame exhaust should not project backward/above the rocket');
    });

    test('plasmaBlue palette applies blue/cyan plasma coloration', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Small ship at (14..17, 8..12)
      for (int y = 8; y <= 12; y++) {
        for (int x = 14; x <= 17; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = BoosterThrusterEffect({
        'thrustAngle': 90.0,
        'flameLength': 14.0,
        'plumeWidth': 0.8,
        'shockDiamonds': false,
        'exhaustPalette': 'plasmaBlue',
        'smokeBillow': 0.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Check pixel in flame zone (e.g. y = 16, x = 15 or 16)
      bool foundPlasmaBlue = false;
      for (int y = 14; y <= 20; y++) {
        final p = result[y * width + 15];
        final a = (p >> 24) & 0xFF;
        if (a > 50) {
          final r = (p >> 16) & 0xFF;
          final b = p & 0xFF;
          // In plasma blue mode, mid-to-outer heat has high Blue and lower Red
          if (b > r) {
            foundPlasmaBlue = true;
            break;
          }
        }
      }
      expect(foundPlasmaBlue, isTrue, reason: 'plasmaBlue palette should yield blue/cyan plume colors');
    });

    test('behindOnly preserves foreground rocket sprite hull pixels', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const rocketHullColor = 0xFF555555;
      for (int y = 4; y <= 8; y++) {
        for (int x = 10; x <= 14; x++) {
          pixels[y * width + x] = rocketHullColor;
        }
      }

      final effect = BoosterThrusterEffect({
        'thrustAngle': 90.0,
        'flameLength': 12.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 4; y <= 8; y++) {
        for (int x = 10; x <= 14; x++) {
          expect(result[y * width + x], equals(rocketHullColor));
        }
      }
    });
  });
}
