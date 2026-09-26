import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DitheredFrostedBlurEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = DitheredFrostedBlurEffect();
      expect(effect.type, equals(EffectType.ditheredFrostedBlur));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['diffusionRadius'], equals(3.0));
      expect(effect.parameters['ditherPattern'], equals('bayer4x4'));
      expect(effect.parameters['colorQuantization'], equals(8.0));
      expect(effect.parameters['intensity'], equals(0.8));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DitheredFrostedBlurEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'diffusionRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'ditherPattern' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'colorQuantization' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'intensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DitheredFrostedBlurEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.ditheredFrostedBlur,
        {
          'diffusionRadius': 5.0,
          'ditherPattern': 'stochasticNoise',
          'colorQuantization': 16.0,
        },
      );
      expect(effect, isA<DitheredFrostedBlurEffect>());
      expect(effect.parameters['diffusionRadius'], equals(5.0));
      expect(effect.parameters['ditherPattern'], equals('stochasticNoise'));
      expect(effect.parameters['colorQuantization'], equals(16.0));
    });

    test('dither dispersion scatters pixels according to pattern', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Split canvas horizontally: top half black, bottom half white
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = (y < 16) ? 0xFF000000 : 0xFFFFFFFF;
        }
      }

      final effect = DitheredFrostedBlurEffect({
        'diffusionRadius': 4.0,
        'ditherPattern': 'bayer4x4',
        'colorQuantization': 8.0,
        'intensity': 1.0,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Near border (y = 14 to 17), pixels should diffuse across boundary
      bool foundWhiteInTop = false;
      for (int x = 0; x < width; x++) {
        final c = result[14 * width + x];
        final r = (c >> 16) & 0xFF;
        if (r > 0) {
          foundWhiteInTop = true;
          break;
        }
      }
      expect(foundWhiteInTop, isTrue, reason: 'Pixels should diffuse across the border line');
    });

    test('colorQuantization restricts colors to discrete steps', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Smooth horizontal gradient
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int v = ((x / (width - 1.0)) * 255.0).round();
          pixels[y * width + x] = 0xFF000000 | (v << 16) | (v << 8) | v;
        }
      }

      const int steps = 4;
      final effect = DitheredFrostedBlurEffect({
        'diffusionRadius': 2.0,
        'ditherPattern': 'crosshatch',
        'colorQuantization': steps.toDouble(),
        'intensity': 0.8,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Collect all distinct channel values in result
      final distinctValues = <int>{};
      for (int i = 0; i < result.length; i++) {
        final r = (result[i] >> 16) & 0xFF;
        distinctValues.add(r);
      }

      // With 4 steps, there should be at most 4 distinct tonal levels across the entire canvas
      expect(distinctValues.length, lessThanOrEqualTo(steps),
          reason: 'Color quantization must constrain distinct channel levels to specified steps');
    });

    test('preserveAlpha strictly confines diffusion to layer pixels and keeps empty space transparent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 4x4 block in center
      for (int y = 14; y < 18; y++) {
        for (int x = 14; x < 18; x++) {
          pixels[y * width + x] = 0xFF33CC88;
        }
      }

      final effect = DitheredFrostedBlurEffect({
        'diffusionRadius': 6.0,
        'ditherPattern': 'bayer4x4',
        'colorQuantization': 8.0,
        'intensity': 0.9,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Every transparent pixel in original must remain transparent
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final orig = pixels[y * width + x];
          final origA = (orig >> 24) & 0xFF;
          final resA = (result[y * width + x] >> 24) & 0xFF;

          if (origA == 0) {
            expect(resA, equals(0), reason: 'Transparent canvas background at ($x, $y) must not be filled');
          }
        }
      }
    });
  });
}
