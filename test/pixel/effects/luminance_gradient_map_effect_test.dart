import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('LuminanceGradientMapEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = LuminanceGradientMapEffect();
      expect(effect.type, equals(EffectType.luminanceGradientMap));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['palette'], equals('cyberpunkNeon'));
      expect(effect.parameters['contrastBoost'], equals(1.0));
      expect(effect.parameters['ditherBands'], isTrue);
      expect(effect.parameters['blendMode'], equals('replace'));
      expect(effect.parameters['blendStrength'], equals(1.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = LuminanceGradientMapEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'palette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'shadowColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'midColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'highlightColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'contrastBoost' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'ditherBands' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'blendMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'blendStrength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes LuminanceGradientMapEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.luminanceGradientMap,
        {
          'palette': 'heatVision',
          'contrastBoost': 1.5,
          'blendMode': 'overlay',
        },
      );
      expect(effect, isA<LuminanceGradientMapEffect>());
      expect(effect.parameters['palette'], equals('heatVision'));
      expect(effect.parameters['contrastBoost'], equals(1.5));
      expect(effect.parameters['blendMode'], equals('overlay'));
    });

    test('remaps shadows to shadow stop and highlights to highlight stop', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Pixel 0 is pure black (luminance 0), Pixel 1 is pure white (luminance 255)
      pixels[0] = 0xFF000000;
      pixels[1] = 0xFFFFFFFF;

      final effect = LuminanceGradientMapEffect({
        'palette': 'custom',
        'shadowColor': 0xFF0000FF, // Pure Blue in shadows
        'midColor': 0xFF00FF00,
        'highlightColor': 0xFFFF0000, // Pure Red in highlights
        'contrastBoost': 1.0,
        'ditherBands': false,
        'blendMode': 'replace',
        'blendStrength': 1.0,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      final p0 = result[0];
      final r0 = (p0 >> 16) & 0xFF;
      final b0 = p0 & 0xFF;

      final p1 = result[1];
      final r1 = (p1 >> 16) & 0xFF;
      final b1 = p1 & 0xFF;

      // Shadow pixel should map to blue
      expect(b0, greaterThan(200));
      expect(r0, lessThan(50));

      // Highlight pixel should map to red
      expect(r1, greaterThan(200));
      expect(b1, lessThan(50));
    });

    test('different palettes produce distinct color mapping', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Mid-grey pixels
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      final effectCyber = LuminanceGradientMapEffect({
        'palette': 'cyberpunkNeon',
        'ditherBands': false,
      });
      final effectGb = LuminanceGradientMapEffect({
        'palette': 'gameboyClassic',
        'ditherBands': false,
      });

      final outCyber = effectCyber.apply(Uint32List.fromList(pixels), width, height);
      final outGb = effectGb.apply(Uint32List.fromList(pixels), width, height);

      expect(outCyber[0], isNot(equals(outGb[0])));
    });

    test('preserveAlpha strictly confines color mapping to layer pixels and keeps empty space transparent', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Small 4x4 block in center
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          pixels[y * width + x] = 0xFFAAAAAA;
        }
      }

      final effect = LuminanceGradientMapEffect({
        'palette': 'cyberpunkNeon',
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final origA = (pixels[y * width + x] >> 24) & 0xFF;
          final resA = (result[y * width + x] >> 24) & 0xFF;

          if (origA == 0) {
            expect(resA, equals(0), reason: 'Transparent canvas background at ($x, $y) must not be filled');
          } else {
            expect(resA, greaterThan(0));
          }
        }
      }
    });
  });
}
