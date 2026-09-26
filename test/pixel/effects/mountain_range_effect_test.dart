import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('MountainRangeEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = MountainRangeEffect();
      expect(effect.type, equals(EffectType.mountainRange));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isTrue);
      expect(effect.parameters['layers'], equals(3));
      expect(effect.parameters['style'], equals(0));
      expect(effect.parameters['heightVariation'], equals(0.55));
      expect(effect.parameters['baseHeight'], equals(0.0));
      expect(effect.parameters['colorScheme'], equals(0));
      expect(effect.parameters['atmosphericHaze'], equals(0.5));
      expect(effect.parameters['snowCaps'], equals(0.2));
      expect(effect.parameters['mistIntensity'], equals(0.3));
      expect(effect.parameters['skyGradient'], isTrue);
      expect(effect.parameters['sunPosition'], equals(0.7));
      expect(effect.parameters['parallaxScroll'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = MountainRangeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'layers' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'style' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'heightVariation' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'baseHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'colorScheme' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'atmosphericHaze' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'snowCaps' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mistIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'skyGradient' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'sunPosition' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'parallaxScroll' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes MountainRangeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.mountainRange,
        {
          'style': 3,
          'colorScheme': 1,
          'layers': 4,
          'snowCaps': 0.5,
        },
      );
      expect(effect, isA<MountainRangeEffect>());
      expect(effect.parameters['style'], equals(3));
      expect(effect.parameters['colorScheme'], equals(1));
      expect(effect.parameters['layers'], equals(4));
      expect(effect.parameters['snowCaps'], equals(0.5));
    });

    test('renders multi-layered mountain panorama on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = MountainRangeEffect({
        'style': 0,
        'colorScheme': 0,
        'layers': 3,
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

    test('renders different styles (Jagged vs Rolling Ridge vs Volcanic)', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final jagged = MountainRangeEffect({
        'style': 1,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final rolling = MountainRangeEffect({
        'style': 2,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final volcanic = MountainRangeEffect({
        'style': 4,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffJaggedRolling = false;
      bool diffJaggedVolcanic = false;
      for (int i = 0; i < pixels.length; i++) {
        if (jagged[i] != rolling[i]) diffJaggedRolling = true;
        if (jagged[i] != volcanic[i]) diffJaggedVolcanic = true;
      }
      expect(diffJaggedRolling, isTrue);
      expect(diffJaggedVolcanic, isTrue);
    });

    test('colorScheme variations produce distinct color output', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final blue = MountainRangeEffect({
        'colorScheme': 0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final sunset = MountainRangeEffect({
        'colorScheme': 1,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final green = MountainRangeEffect({
        'colorScheme': 3,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffBlueSunset = false;
      bool diffBlueGreen = false;
      for (int i = 0; i < pixels.length; i++) {
        if (blue[i] != sunset[i]) diffBlueSunset = true;
        if (blue[i] != green[i]) diffBlueGreen = true;
      }
      expect(diffBlueSunset, isTrue);
      expect(diffBlueGreen, isTrue);
    });

    test('time animation drives parallax scrolling and diurnal sun transit', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final t0 = MountainRangeEffect({
        'time': 0.0,
        'parallaxScroll': true,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final t5 = MountainRangeEffect({
        'time': 0.5,
        'parallaxScroll': true,
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

      // Create a small 4x4 square in the center
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          pixels[y * width + x] = 0xFF00FF00;
        }
      }

      final effect = MountainRangeEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Outside the 4x4 square must stay 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 6 || x >= 10 || y < 6 || y >= 10) {
            expect(out[y * width + x], equals(0));
          }
        }
      }

      // Inside the 4x4 square should be drawn
      int nonZeroInside = 0;
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          if (out[y * width + x] != 0) nonZeroInside++;
        }
      }
      expect(nonZeroInside, greaterThan(0));
    });
  });
}
