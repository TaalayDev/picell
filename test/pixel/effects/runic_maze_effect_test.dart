import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RunicMazeEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = RunicMazeEffect();
      expect(effect.type, equals(EffectType.runicMaze));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['mazeStyle'], equals('celticKnot'));
      expect(effect.parameters['grooveDepth'], equals(0.7));
      expect(effect.parameters['runePulse'], isTrue);
      expect(effect.parameters['runeColor'], equals(0xFF00E5FF));
      expect(effect.parameters['weatheringNoise'], equals(0.4));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RunicMazeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'mazeStyle' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'grooveDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'runePulse' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'runeColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'weatheringNoise' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes RunicMazeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.runicMaze,
        {
          'mazeStyle': 'greekMeander',
          'grooveDepth': 0.6,
          'runeColor': 0xFFFFD600,
          'weatheringNoise': 0.3,
        },
      );
      expect(effect, isA<RunicMazeEffect>());
      expect(effect.parameters['mazeStyle'], equals('greekMeander'));
      expect(effect.parameters['grooveDepth'], equals(0.6));
      expect(effect.parameters['runeColor'], equals(0xFFFFD600));
      expect(effect.parameters['weatheringNoise'], equals(0.3));
    });

    test('renders carved Celtic knot stele pattern with stone relief', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = RunicMazeEffect({
        'mazeStyle': 'celticKnot',
        'grooveDepth': 0.8,
        'weatheringNoise': 0.4,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('renders Greek meander and Aztec stepped maze styles', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectMeander = RunicMazeEffect({
        'mazeStyle': 'greekMeander',
        'preserveAlpha': false,
      });
      final effectAztec = RunicMazeEffect({
        'mazeStyle': 'aztecStepped',
        'preserveAlpha': false,
      });

      final outMeander = effectMeander.apply(pixels, width, height);
      final outAztec = effectAztec.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outMeander[i] != outAztec[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation animates traveling runic pulse', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = RunicMazeEffect({
        'runePulse': true,
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = RunicMazeEffect({
        'runePulse': true,
        'time': 0.6,
        'preserveAlpha': false,
      });

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
  });
}
