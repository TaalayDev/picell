import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WhisperingReedsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = WhisperingReedsEffect();
      expect(effect.type, equals(EffectType.whisperingReeds));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['reedDensity'], equals(14));
      expect(effect.parameters['windGustSpeed'], equals(1.8));
      expect(effect.parameters['rippleFrequency'], equals(5));
      expect(effect.parameters['reflectionShimmer'], equals(0.5));
      expect(effect.parameters['waterClarity'], equals(0.6));
      expect(effect.parameters['reedStyle'], equals('cattails'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WhisperingReedsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'reedDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'windGustSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rippleFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'reflectionShimmer' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterClarity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'reedStyle' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes WhisperingReedsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.whisperingReeds,
        {
          'reedDensity': 20,
          'reedStyle': 'bambooReeds',
          'waterClarity': 0.8,
        },
      );
      expect(effect, isA<WhisperingReedsEffect>());
      expect(effect.parameters['reedDensity'], equals(20));
      expect(effect.parameters['reedStyle'], equals('bambooReeds'));
      expect(effect.parameters['waterClarity'], equals(0.8));
    });

    test('renders pond water surface and whispering reeds on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = WhisperingReedsEffect({
        'reedDensity': 10,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('different reedStyle configurations render distinct vegetation morphology', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final cattails = WhisperingReedsEffect({
        'reedStyle': 'cattails',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final bamboo = WhisperingReedsEffect({
        'reedStyle': 'bambooReeds',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final grass = WhisperingReedsEffect({
        'reedStyle': 'marshGrass',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffCattailsBamboo = false;
      bool diffCattailsGrass = false;
      for (int i = 0; i < pixels.length; i++) {
        if (cattails[i] != bamboo[i]) diffCattailsBamboo = true;
        if (cattails[i] != grass[i]) diffCattailsGrass = true;
      }
      expect(diffCattailsBamboo, isTrue);
      expect(diffCattailsGrass, isTrue);
    });

    test('time animation advances wind sway and expanding concentric water ripples', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final t0 = WhisperingReedsEffect({
        'time': 0.0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final t5 = WhisperingReedsEffect({
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

    test('preserveAlpha restricts pond ripples and reeds to sprite boundary', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF101010;
        }
      }

      final effect = WhisperingReedsEffect({
        'reedDensity': 20,
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
