import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RadiantRaysEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = RadiantRaysEffect();
      expect(effect.type, equals(EffectType.radiantRays));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['beamCount'], equals(4));
      expect(effect.parameters['rayIntensity'], equals(0.6));
      expect(effect.parameters['dustDensity'], equals(0.5));
      expect(effect.parameters['ascendSpeed'], equals(1.2));
      expect(effect.parameters['auraColor'], equals(0xFFFFD700));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RadiantRaysEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'beamCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rayIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'dustDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'ascendSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'auraColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes RadiantRaysEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.radiantRays,
        {
          'beamCount': 6,
          'auraColor': 0xFF18FFFF,
          'rayIntensity': 0.9,
        },
      );
      expect(effect, isA<RadiantRaysEffect>());
      expect(effect.parameters['beamCount'], equals(6));
      expect(effect.parameters['auraColor'], equals(0xFF18FFFF));
      expect(effect.parameters['rayIntensity'], equals(0.9));
    });

    test('renders volumetric god ray columns and ascending dust motes', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final effect = RadiantRaysEffect({
        'beamCount': 4,
        'rayIntensity': 0.8,
        'dustDensity': 0.6,
        'auraColor': 0xFFFFD700,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Must illuminate ray/mote pixels
      final hasRays = out.any((p) => (p >> 24) & 0xFF > 0);
      expect(hasRays, isTrue);

      // Must contain golden aura tint
      final hasGold = out.any((p) {
        final r = (p >> 16) & 0xFF;
        final g = (p >> 8) & 0xFF;
        return r > 150 && g > 120;
      });
      expect(hasGold, isTrue);
    });

    test('time parameter advances ascension and beam drift', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final t0 = RadiantRaysEffect({
        'dustDensity': 0.8,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final tNext = RadiantRaysEffect({
        'dustDensity': 0.8,
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outNext = tNext.apply(pixels, width, height);

      expect(outNext, isNot(equals(out0)));
    });

    test('preserveAlpha: false fills canvas with dark celestial void', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = RadiantRaysEffect({
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
