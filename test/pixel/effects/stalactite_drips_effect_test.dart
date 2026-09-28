import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('StalactiteDripsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = StalactiteDripsEffect();
      expect(effect.type, equals(EffectType.stalactiteDrips));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['dripRate'], equals(1.5));
      expect(effect.parameters['stalactiteDensity'], equals(6));
      expect(effect.parameters['splashImpactParticles'], equals(8));
      expect(effect.parameters['acousticRippleDecay'], equals(0.5));
      expect(effect.parameters['caveAmbiance'], equals('limestoneEcho'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = StalactiteDripsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'dripRate' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'stalactiteDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'splashImpactParticles' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'acousticRippleDecay' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'caveAmbiance' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes StalactiteDripsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.stalactiteDrips,
        {
          'dripRate': 2.0,
          'stalactiteDensity': 8,
          'caveAmbiance': 'bioluminescentCyan',
        },
      );
      expect(effect, isA<StalactiteDripsEffect>());
      expect(effect.parameters['dripRate'], equals(2.0));
      expect(effect.parameters['stalactiteDensity'], equals(8));
      expect(effect.parameters['caveAmbiance'], equals('bioluminescentCyan'));
    });

    test('renders speleothems, droplets, and puddle floor on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = StalactiteDripsEffect({
        'stalactiteDensity': 5,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('different caveAmbiance configurations render distinctive subterranean lighting', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final limestone = StalactiteDripsEffect({
        'caveAmbiance': 'limestoneEcho',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final cyan = StalactiteDripsEffect({
        'caveAmbiance': 'bioluminescentCyan',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final crystal = StalactiteDripsEffect({
        'caveAmbiance': 'crystalGrotto',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffLimestoneCyan = false;
      bool diffLimestoneCrystal = false;
      for (int i = 0; i < pixels.length; i++) {
        if (limestone[i] != cyan[i]) diffLimestoneCyan = true;
        if (limestone[i] != crystal[i]) diffLimestoneCrystal = true;
      }
      expect(diffLimestoneCyan, isTrue);
      expect(diffLimestoneCrystal, isTrue);
    });

    test('time animation advances droplet detachment, free-fall, and puddle ripples', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final t0 = StalactiteDripsEffect({
        'time': 0.1,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final t5 = StalactiteDripsEffect({
        'time': 0.5,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (t0[i] != t5[i]) {
          diffDetected = true;
          break;
        }
      }
      expect(diffDetected, isTrue);
    });

    test('preserveAlpha restricts stalactites, drips, and ripples within sprite boundary', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF101010;
        }
      }

      final effect = StalactiteDripsEffect({
        'time': 0.5,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside 6x6 must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 5 || x >= 11 || y < 5 || y >= 11) {
            expect(out[y * width + x], equals(0));
          }
        }
      }
    });
  });
}
