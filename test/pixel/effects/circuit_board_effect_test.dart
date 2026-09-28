import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CircuitBoardEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = CircuitBoardEffect();
      expect(effect.type, equals(EffectType.circuitBoard));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['traceDensity'], equals(6));
      expect(effect.parameters['substrateColor'], equals('cyberEmerald'));
      expect(effect.parameters['solderPadRatio'], equals(0.5));
      expect(effect.parameters['activeGlowTraces'], isTrue);
      expect(effect.parameters['glowColor'], equals(0xFF00E5FF));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CircuitBoardEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'traceDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'substrateColor' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'solderPadRatio' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'activeGlowTraces' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'glowColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CircuitBoardEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.circuitBoard,
        {
          'traceDensity': 8,
          'substrateColor': 'matteBlack',
          'glowColor': 0xFF76FF03,
        },
      );
      expect(effect, isA<CircuitBoardEffect>());
      expect(effect.parameters['traceDensity'], equals(8));
      expect(effect.parameters['substrateColor'], equals('matteBlack'));
      expect(effect.parameters['glowColor'], equals(0xFF76FF03));
    });

    test('renders copper traces, solder vias, and fiberglass weave on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = CircuitBoardEffect({
        'traceDensity': 6,
        'substrateColor': 'cyberEmerald',
        'solderPadRatio': 0.5,
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

    test('generates different substrates (matteBlack and industrialNavy)', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectBlack = CircuitBoardEffect({
        'substrateColor': 'matteBlack',
        'preserveAlpha': false,
      });
      final effectNavy = CircuitBoardEffect({
        'substrateColor': 'industrialNavy',
        'preserveAlpha': false,
      });

      final outBlack = effectBlack.apply(pixels, width, height);
      final outNavy = effectNavy.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outBlack[i] != outNavy[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation drives electronic signal pulse wave', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = CircuitBoardEffect({
        'activeGlowTraces': true,
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = CircuitBoardEffect({
        'activeGlowTraces': true,
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
