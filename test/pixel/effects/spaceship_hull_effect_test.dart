import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SpaceshipHullEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SpaceshipHullEffect();
      expect(effect.type, equals(EffectType.spaceshipHull));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['panelGridSize'], equals(8));
      expect(effect.parameters['greebleDensity'], equals(0.5));
      expect(effect.parameters['rivetSpacing'], equals(3));
      expect(effect.parameters['hullWeathering'], equals(0.3));
      expect(effect.parameters['hazardStripes'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SpaceshipHullEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'panelGridSize' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'greebleDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rivetSpacing' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'hullWeathering' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'hazardStripes' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SpaceshipHullEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.spaceshipHull,
        {
          'panelGridSize': 12,
          'greebleDensity': 0.7,
          'rivetSpacing': 2,
        },
      );
      expect(effect, isA<SpaceshipHullEffect>());
      expect(effect.parameters['panelGridSize'], equals(12));
      expect(effect.parameters['greebleDensity'], equals(0.7));
      expect(effect.parameters['rivetSpacing'], equals(2));
    });

    test('renders modular armor hull plating with seam joints on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = SpaceshipHullEffect({
        'panelGridSize': 8,
        'greebleDensity': 0.5,
        'rivetSpacing': 3,
        'hazardStripes': true,
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

    test('renders hazard chevrons and ventilation greebles', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectWithStripes = SpaceshipHullEffect({
        'hazardStripes': true,
        'greebleDensity': 0.8,
        'preserveAlpha': false,
      });
      final effectWithoutStripes = SpaceshipHullEffect({
        'hazardStripes': false,
        'greebleDensity': 0.0,
        'preserveAlpha': false,
      });

      final outWith = effectWithStripes.apply(pixels, width, height);
      final outWithout = effectWithoutStripes.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outWith[i] != outWithout[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation cycles beacon flasher LEDs', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = SpaceshipHullEffect({
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = SpaceshipHullEffect({
        'time': 0.35,
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
