import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BurningEmbersEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = BurningEmbersEffect();
      expect(effect.type, equals(EffectType.burningEmbers));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['emberColor'], equals(0xFFFF6D00));
      expect(effect.parameters['decayDirection'], equals('bottomToTop'));
      expect(effect.parameters['wispSpread'], equals(0.5));
      expect(effect.parameters['sparkCount'], equals(40));
      expect(effect.parameters['burnProgress'], equals(0.5));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BurningEmbersEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'emberColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'decayDirection' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'wispSpread' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sparkCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'burnProgress' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BurningEmbersEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.burningEmbers,
        {
          'emberColor': 0xFF9C27B0,
          'decayDirection': 'radialOutward',
          'burnProgress': 0.8,
        },
      );
      expect(effect, isA<BurningEmbersEffect>());
      expect(effect.parameters['emberColor'], equals(0xFF9C27B0));
      expect(effect.parameters['decayDirection'], equals('radialOutward'));
      expect(effect.parameters['burnProgress'], equals(0.8));
    });

    test('burn progress dissolves lower rows and creates hot scorched edge', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      // Solid sprite column
      for (int y = 0; y < 16; y++) {
        pixels[y * width + 8] = 0xFFFFFFFF;
      }

      final effect = BurningEmbersEffect({
        'decayDirection': 'bottomToTop',
        'burnProgress': 0.5, // Burns from bottom (row 15) up towards row 8
        'sparkCount': 0,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Top rows (unburned) remain white
      expect(out[0 * width + 8], equals(0xFFFFFFFF));
      // Bottom rows are dissolved (transparent)
      expect(out[15 * width + 8], equals(0x00000000));
    });

    test('time parameter advances progressive disintegration wave', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      for (int y = 0; y < 16; y++) {
        pixels[y * width + 8] = 0xFFFFFFFF;
      }

      final t0 = BurningEmbersEffect({
        'decayDirection': 'bottomToTop',
        'time': 0.2,
        'preserveAlpha': true,
      });

      final tNext = BurningEmbersEffect({
        'decayDirection': 'bottomToTop',
        'time': 0.7,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outNext = tNext.apply(pixels, width, height);

      // More pixels dissolved at tNext than at t0
      final nonZero0 = out0.where((p) => p != 0).length;
      final nonZeroNext = outNext.where((p) => p != 0).length;

      expect(nonZeroNext, lessThan(nonZero0));
    });

    test('preserveAlpha: false fills background with ash darkness', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = BurningEmbersEffect({
        'burnProgress': 0.5,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
