import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BlizzardEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = BlizzardEffect();
      expect(effect.type, equals(EffectType.blizzard));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['intensity'], equals(0.6));
      expect(effect.parameters['windAngle'], equals(25.0));
      expect(effect.parameters['swirlTurbulence'], equals(0.5));
      expect(effect.parameters['blizzardHaze'], equals(0.3));
      expect(effect.parameters['frostSurfaces'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BlizzardEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'intensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'windAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'swirlTurbulence' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'blizzardHaze' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'frostSurfaces' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BlizzardEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.blizzard,
        {
          'intensity': 0.9,
          'windAngle': -30.0,
          'frostSurfaces': false,
        },
      );
      expect(effect, isA<BlizzardEffect>());
      expect(effect.parameters['intensity'], equals(0.9));
      expect(effect.parameters['windAngle'], equals(-30.0));
      expect(effect.parameters['frostSurfaces'], isFalse);
    });

    test('renders snow particles onto canvas', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final effect = BlizzardEffect({
        'intensity': 0.8,
        'blizzardHaze': 0.0,
        'frostSurfaces': false,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Should have non-zero snowflake pixels
      final hasSnow = out.any((p) => (p >> 24) & 0xFF > 0);
      expect(hasSnow, isTrue);
    });

    test('time parameter advances snowfall cycle', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final t0 = BlizzardEffect({
        'intensity': 0.8,
        'blizzardHaze': 0.0,
        'frostSurfaces': false,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final tNext = BlizzardEffect({
        'intensity': 0.8,
        'blizzardHaze': 0.0,
        'frostSurfaces': false,
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outNext = tNext.apply(pixels, width, height);

      expect(outNext, isNot(equals(out0)));
    });

    test('frostSurfaces adds frosted snow accumulation to top surface of sprite', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);
      // Sprite block at row 4, column 4
      const spriteColor = 0xFF4A148C; // Deep purple
      pixels[4 * width + 4] = spriteColor;

      final effect = BlizzardEffect({
        'intensity': 0.1,
        'blizzardHaze': 0.0,
        'frostSurfaces': true,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // The top pixel of the sprite (row 4, col 4) should receive a frost tint (brightened)
      final p = out[4 * width + 4];
      expect(p, isNot(equals(spriteColor)));
      // Red and blue channels should be boosted by the icy frost overlay
      final r = (p >> 16) & 0xFF;
      const origR = (spriteColor >> 16) & 0xFF;
      expect(r, greaterThan(origR));
    });

    test('preserveAlpha: false fills background with dark winter night', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = BlizzardEffect({
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
