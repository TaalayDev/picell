import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BeamTeleportEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = BeamTeleportEffect();
      expect(effect.type, equals(EffectType.beamTeleport));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['teleportMode'], equals('beamDown'));
      expect(effect.parameters['beamWidth'], equals(6));
      expect(effect.parameters['laserColor'], equals(0xFF00E5FF));
      expect(effect.parameters['impactDust'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BeamTeleportEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'teleportMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'beamWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'laserColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'impactDust' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BeamTeleportEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.beamTeleport,
        {
          'teleportMode': 'digitizeBlocks',
          'beamWidth': 8,
          'laserColor': 0xFF00E676,
        },
      );
      expect(effect, isA<BeamTeleportEffect>());
      expect(effect.parameters['teleportMode'], equals('digitizeBlocks'));
      expect(effect.parameters['beamWidth'], equals(8));
      expect(effect.parameters['laserColor'], equals(0xFF00E676));
    });

    test('renders vertical laser beam column and ground dust in beamDown mode', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF252525;
      }

      final effect = BeamTeleportEffect({
        'teleportMode': 'beamDown',
        'beamWidth': 8,
        'time': 0.45,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF252525) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('renders streaming digital blocks in digitizeBlocks mode', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF252525;
      }

      final effect = BeamTeleportEffect({
        'teleportMode': 'digitizeBlocks',
        'beamWidth': 6,
        'time': 0.35,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF252525) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('time animation advances beam landing and dissipation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF252525;
      }

      final effect1 = BeamTeleportEffect({'time': 0.15, 'preserveAlpha': false});
      final effect2 = BeamTeleportEffect({'time': 0.55, 'preserveAlpha': false});

      final out1 = effect1.apply(pixels, width, height);
      final out2 = effect2.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out1[i] != out2[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('respects preserveAlpha and does not draw onto transparent empty background', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height); // All transparent

      final effect = BeamTeleportEffect({
        'time': 0.45,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
