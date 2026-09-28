import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('StarfieldEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = StarfieldEffect();
      expect(effect.type, equals(EffectType.starfield));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['starDensity'], equals(0.5));
      expect(effect.parameters['twinkleSpeed'], equals(1.5));
      expect(effect.parameters['nebulaIntensity'], equals(0.4));
      expect(effect.parameters['nebulaTheme'], equals('violet'));
      expect(effect.parameters['shootingStars'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = StarfieldEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'starDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'twinkleSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'nebulaIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'nebulaTheme' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'shootingStars' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes StarfieldEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.starfield,
        {
          'starDensity': 0.8,
          'nebulaTheme': 'synthwave',
          'time': 0.5,
        },
      );
      expect(effect, isA<StarfieldEffect>());
      expect(effect.parameters['starDensity'], equals(0.8));
      expect(effect.parameters['nebulaTheme'], equals('synthwave'));
      expect(effect.parameters['time'], equals(0.5));
    });

    test('time parameter advances star twinkle luminosity', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final t0 = StarfieldEffect({
        'starDensity': 0.8,
        'twinkleSpeed': 2.0,
        'nebulaIntensity': 0.0,
        'shootingStars': false,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final tQuarter = StarfieldEffect({
        'starDensity': 0.8,
        'twinkleSpeed': 2.0,
        'nebulaIntensity': 0.0,
        'shootingStars': false,
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outQuarter = tQuarter.apply(pixels, width, height);

      // Starfield should contain stars (non-zero pixels)
      expect(out0.any((p) => (p >> 24) & 0xFF > 0), isTrue);
      // Brightness shifts across the animation cycle
      expect(outQuarter, isNot(equals(out0)));
    });

    test('preserveAlpha: true keeps foreground sprite intact', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);
      // Center solid foreground pixel
      const fgColor = 0xFFFF0000;
      pixels[4 * width + 4] = fgColor;

      final effect = StarfieldEffect({
        'starDensity': 0.5,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      expect(out[4 * width + 4], equals(fgColor));
    });

    test('preserveAlpha: false fills canvas with cosmic backdrop', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = StarfieldEffect({
        'nebulaIntensity': 0.5,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      // Background pixels should be opaque space void
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
