import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('EnergyShieldEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = EnergyShieldEffect();
      expect(effect.type, equals(EffectType.energyShield));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['shieldShape'], equals('hexMatrix'));
      expect(effect.parameters['barrierColor'], equals(0xFF00B0FF));
      expect(effect.parameters['pulseRate'], equals(1.5));
      expect(effect.parameters['impactRipple'], equals(0.6));
      expect(effect.parameters['shieldThickness'], equals(2));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = EnergyShieldEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'shieldShape' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'barrierColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'pulseRate' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'impactRipple' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shieldThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes EnergyShieldEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.energyShield,
        {
          'shieldShape': 'spherical',
          'barrierColor': 0xFFFFD700,
          'pulseRate': 2.0,
        },
      );
      expect(effect, isA<EnergyShieldEffect>());
      expect(effect.parameters['shieldShape'], equals('spherical'));
      expect(effect.parameters['barrierColor'], equals(0xFFFFD700));
      expect(effect.parameters['pulseRate'], equals(2.0));
    });

    test('renders hex matrix forcefield over sprite', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      // Center character block
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          pixels[y * width + x] = 0xFF4CAF50;
        }
      }

      final effect = EnergyShieldEffect({
        'shieldShape': 'hexMatrix',
        'barrierColor': 0xFF00B0FF,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Forcefield barrier must cast luminous blue barrier pixels
      final hasBarrier = out.any((p) {
        final b = p & 0xFF;
        return b > 150;
      });
      expect(hasBarrier, isTrue);
    });

    test('time parameter advances ripple wavefront', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      pixels[8 * width + 8] = 0xFFFFFFFF;

      final t0 = EnergyShieldEffect({
        'shieldShape': 'spherical',
        'time': 0.0,
        'preserveAlpha': true,
      });

      final tNext = EnergyShieldEffect({
        'shieldShape': 'spherical',
        'time': 0.3,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outNext = tNext.apply(pixels, width, height);

      expect(outNext, isNot(equals(out0)));
    });

    test('contourAura wraps sprite silhouette boundary', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      pixels[8 * width + 8] = 0xFFFFFFFF;

      final effect = EnergyShieldEffect({
        'shieldShape': 'contourAura',
        'barrierColor': 0xFF00E676,
        'shieldThickness': 2,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Immediate neighbors around (8, 8) must have contour aura
      final neighbor = out[8 * width + 9];
      expect((neighbor >> 24) & 0xFF, greaterThan(0));
    });

    test('preserveAlpha: false fills background with dark chamber', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = EnergyShieldEffect({
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
