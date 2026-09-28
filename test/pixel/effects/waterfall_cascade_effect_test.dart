import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WaterfallCascadeEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = WaterfallCascadeEffect();
      expect(effect.type, equals(EffectType.waterfallCascade));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['flowSpeed'], equals(2.0));
      expect(effect.parameters['cascadeWidth'], equals(0.6));
      expect(effect.parameters['foamTurbulence'], equals(0.5));
      expect(effect.parameters['sprayDroplets'], equals(30));
      expect(effect.parameters['mistRisingDensity'], equals(0.4));
      expect(effect.parameters['rockTiers'], equals(2));
      expect(effect.parameters['waterPalette'], equals('mountainGlacier'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WaterfallCascadeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'flowSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'cascadeWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'foamTurbulence' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sprayDroplets' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mistRisingDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rockTiers' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes WaterfallCascadeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.waterfallCascade,
        {
          'flowSpeed': 3.0,
          'cascadeWidth': 0.8,
          'waterPalette': 'tropicalLagoon',
        },
      );
      expect(effect, isA<WaterfallCascadeEffect>());
      expect(effect.parameters['flowSpeed'], equals(3.0));
      expect(effect.parameters['cascadeWidth'], equals(0.8));
      expect(effect.parameters['waterPalette'], equals('tropicalLagoon'));
    });

    test('renders waterfall fluid streams and plunge pool on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = WaterfallCascadeEffect({
        'cascadeWidth': 0.6,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('different waterPalette configurations produce distinct color output', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final glacier = WaterfallCascadeEffect({
        'waterPalette': 'mountainGlacier',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final tropical = WaterfallCascadeEffect({
        'waterPalette': 'tropicalLagoon',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final canyon = WaterfallCascadeEffect({
        'waterPalette': 'muddyCanyon',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffGlacierTropical = false;
      bool diffGlacierCanyon = false;
      for (int i = 0; i < pixels.length; i++) {
        if (glacier[i] != tropical[i]) diffGlacierTropical = true;
        if (glacier[i] != canyon[i]) diffGlacierCanyon = true;
      }
      expect(diffGlacierTropical, isTrue);
      expect(diffGlacierCanyon, isTrue);
    });

    test('time animation advances water fluid flow and ballistic spray droplets', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final t0 = WaterfallCascadeEffect({
        'time': 0.0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final t5 = WaterfallCascadeEffect({
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

    test('preserveAlpha respects input sprite silhouette mask', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF00FF00;
        }
      }

      final effect = WaterfallCascadeEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside 6x6 box must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 5 || x >= 11 || y < 5 || y >= 11) {
            expect(out[y * width + x], equals(0));
          }
        }
      }

      // Pixels inside must be modified
      int nonZeroInside = 0;
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          if (out[y * width + x] != 0) nonZeroInside++;
        }
      }
      expect(nonZeroInside, greaterThan(0));
    });
  });
}
