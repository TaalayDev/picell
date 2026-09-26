import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('GothicRosetteEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = GothicRosetteEffect();
      expect(effect.type, equals(EffectType.gothicRosette));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['symmetryOrder'], equals(8));
      expect(effect.parameters['leadThickness'], equals(1));
      expect(effect.parameters['glassPalette'], equals('roseCathedral'));
      expect(effect.parameters['innerRings'], equals(3));
      expect(effect.parameters['sunlightShaft'], equals(0.5));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = GothicRosetteEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'symmetryOrder' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'leadThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glassPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'innerRings' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sunlightShaft' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes GothicRosetteEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.gothicRosette,
        {
          'symmetryOrder': 12,
          'glassPalette': 'jewel',
          'innerRings': 4,
          'sunlightShaft': 0.8,
        },
      );
      expect(effect, isA<GothicRosetteEffect>());
      expect(effect.parameters['symmetryOrder'], equals(12));
      expect(effect.parameters['glassPalette'], equals('jewel'));
      expect(effect.parameters['innerRings'], equals(4));
      expect(effect.parameters['sunlightShaft'], equals(0.8));
    });

    test('renders radial symmetry gothic rosette with jewel tones', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = GothicRosetteEffect({
        'symmetryOrder': 8,
        'glassPalette': 'jewel',
        'innerRings': 3,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int coloredPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          coloredPixels++;
        }
      }
      expect(coloredPixels, greaterThan(0));
    });

    test('renders with 6-fold and 12-fold symmetry', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect6 = GothicRosetteEffect({
        'symmetryOrder': 6,
        'glassPalette': 'celestial',
        'preserveAlpha': false,
      });
      final effect12 = GothicRosetteEffect({
        'symmetryOrder': 12,
        'glassPalette': 'monochrome',
        'preserveAlpha': false,
      });

      final out6 = effect6.apply(pixels, width, height);
      final out12 = effect12.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out6[i] != out12[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation shifts volumetric sunlight rays', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = GothicRosetteEffect({
        'sunlightShaft': 0.8,
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = GothicRosetteEffect({
        'sunlightShaft': 0.8,
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
