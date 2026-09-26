import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CoralReefEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = CoralReefEffect();
      expect(effect.type, equals(EffectType.coralReef));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['coralPattern'], equals('turingBrain'));
      expect(effect.parameters['bioluminescenceGlow'], equals(0.6));
      expect(effect.parameters['polypDensity'], equals(25));
      expect(effect.parameters['waterDepthTint'], equals('tropicalLagoon'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CoralReefEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'coralPattern' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'bioluminescenceGlow' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'polypDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterDepthTint' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CoralReefEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.coralReef,
        {
          'coralPattern': 'branchingFan',
          'bioluminescenceGlow': 0.8,
          'waterDepthTint': 'abyssalDeep',
        },
      );
      expect(effect, isA<CoralReefEffect>());
      expect(effect.parameters['coralPattern'], equals('branchingFan'));
      expect(effect.parameters['bioluminescenceGlow'], equals(0.8));
      expect(effect.parameters['waterDepthTint'], equals('abyssalDeep'));
    });

    test('renders Turing reaction-diffusion brain coral labyrinth on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = CoralReefEffect({
        'coralPattern': 'turingBrain',
        'bioluminescenceGlow': 0.6,
        'polypDensity': 20,
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

    test('generates branchingFan and tubeSponge morphologies', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectFan = CoralReefEffect({
        'coralPattern': 'branchingFan',
        'preserveAlpha': false,
      });
      final effectTube = CoralReefEffect({
        'coralPattern': 'tubeSponge',
        'preserveAlpha': false,
      });

      final outFan = effectFan.apply(pixels, width, height);
      final outTube = effectTube.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outFan[i] != outTube[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation drives living polyp respiration glow pulse', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = CoralReefEffect({
        'bioluminescenceGlow': 0.8,
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = CoralReefEffect({
        'bioluminescenceGlow': 0.8,
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
