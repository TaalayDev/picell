import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('FireflySwarmEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = FireflySwarmEffect();
      expect(effect.type, equals(EffectType.fireflySwarm));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['fireflyCount'], equals(25));
      expect(effect.parameters['blinkFrequency'], equals(1.5));
      expect(effect.parameters['glowRadius'], equals(2.5));
      expect(effect.parameters['swarmWanderRadius'], equals(0.6));
      expect(effect.parameters['synchronousBlink'], isFalse);
      expect(effect.parameters['lightColor'], equals('phosphorGreen'));
      expect(effect.parameters['twilightTint'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = FireflySwarmEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'fireflyCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'blinkFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glowRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'swarmWanderRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'synchronousBlink' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'lightColor' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'twilightTint' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes FireflySwarmEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.fireflySwarm,
        {
          'fireflyCount': 35,
          'lightColor': 'goldenAmber',
          'synchronousBlink': true,
        },
      );
      expect(effect, isA<FireflySwarmEffect>());
      expect(effect.parameters['fireflyCount'], equals(35));
      expect(effect.parameters['lightColor'], equals('goldenAmber'));
      expect(effect.parameters['synchronousBlink'], isTrue);
    });

    test('renders glowing firefly swarm and twilight meadow on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = FireflySwarmEffect({
        'fireflyCount': 20,
        'twilightTint': true,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('different lightColor themes produce distinctive lantern glows', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final green = FireflySwarmEffect({
        'lightColor': 'phosphorGreen',
        'twilightTint': false,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final amber = FireflySwarmEffect({
        'lightColor': 'goldenAmber',
        'twilightTint': false,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final blue = FireflySwarmEffect({
        'lightColor': 'fairyBlue',
        'twilightTint': false,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffGreenAmber = false;
      bool diffGreenBlue = false;
      for (int i = 0; i < pixels.length; i++) {
        if (green[i] != amber[i]) diffGreenAmber = true;
        if (green[i] != blue[i]) diffGreenBlue = true;
      }
      expect(diffGreenAmber, isTrue);
      expect(diffGreenBlue, isTrue);
    });

    test('time animation drives 3D Brownian flight paths and bio-pulses', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final t0 = FireflySwarmEffect({
        'time': 0.0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final t5 = FireflySwarmEffect({
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

    test('preserveAlpha restricts firefly lanterns within sprite bounds', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF101010;
        }
      }

      final effect = FireflySwarmEffect({
        'fireflyCount': 40,
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
