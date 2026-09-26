import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('LateralSliceGlitchEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = LateralSliceGlitchEffect();
      expect(effect.type, equals(EffectType.lateralSliceGlitch));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['sliceCount'], equals(12.0));
      expect(effect.parameters['maxShift'], equals(5.0));
      expect(effect.parameters['shiftProbability'], equals(0.65));
      expect(effect.parameters['sliceAngle'], equals(0.0));
      expect(effect.parameters['chromaticSplit'], equals(1.8));
      expect(effect.parameters['faultNoise'], equals(0.35));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = LateralSliceGlitchEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'sliceCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'maxShift' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shiftProbability' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sliceAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'chromaticSplit' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'faultNoise' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes LateralSliceGlitchEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.lateralSliceGlitch,
        {
          'sliceCount': 16.0,
          'maxShift': 8.0,
          'chromaticSplit': 3.0,
        },
      );
      expect(effect, isA<LateralSliceGlitchEffect>());
      expect(effect.parameters['sliceCount'], equals(16.0));
      expect(effect.parameters['maxShift'], equals(8.0));
      expect(effect.parameters['chromaticSplit'], equals(3.0));
    });

    test('shears pixels with stepped lateral displacement', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Create a vertical stripe in the middle (x from 14 to 18)
      for (int y = 0; y < height; y++) {
        for (int x = 14; x <= 18; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = LateralSliceGlitchEffect({
        'sliceCount': 8.0,
        'maxShift': 6.0,
        'shiftProbability': 1.0, // Force every slice to shift
        'sliceAngle': 0.0,
        'chromaticSplit': 0.0,
        'faultNoise': 0.0,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that some pixels outside original x range [14, 18] now have color
      bool shiftedOutside = false;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final color = result[y * width + x];
          if ((color & 0xFF000000) != 0) {
            if (x < 14 || x > 18) {
              shiftedOutside = true;
              break;
            }
          }
        }
        if (shiftedOutside) break;
      }

      expect(shiftedOutside, isTrue, reason: 'Pixels should be laterally displaced into adjacent columns');
    });

    test('chromaticSplit separates RGB color channels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Create a white block in center
      for (int y = 10; y < 22; y++) {
        for (int x = 10; x < 22; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = LateralSliceGlitchEffect({
        'sliceCount': 8.0,
        'maxShift': 0.0, // No displacement, only chromatic split
        'shiftProbability': 1.0,
        'sliceAngle': 0.0,
        'chromaticSplit': 4.0, // Pronounced split
        'faultNoise': 0.0,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Check if edges of the white block exhibit chromatic aberration (R != B or G != R)
      bool channelSeparationFound = false;
      for (int y = 10; y < 22; y++) {
        for (int x = 6; x < 26; x++) {
          final color = result[y * width + x];
          final a = (color >> 24) & 0xFF;
          final r = (color >> 16) & 0xFF;
          final g = (color >> 8) & 0xFF;
          final b = color & 0xFF;

          if (a > 0 && (r != g || g != b || r != b)) {
            channelSeparationFound = true;
            break;
          }
        }
        if (channelSeparationFound) break;
      }

      expect(channelSeparationFound, isTrue, reason: 'Chromatic split should separate color channels at slice edges');
    });

    test('preserveAlpha strictly confines glitch to layer pixels and keeps empty space transparent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Small 4x4 sprite in center
      for (int y = 14; y < 18; y++) {
        for (int x = 14; x < 18; x++) {
          pixels[y * width + x] = 0xFFE04040;
        }
      }

      final effect = LateralSliceGlitchEffect({
        'sliceCount': 6.0,
        'maxShift': 8.0,
        'shiftProbability': 1.0,
        'sliceAngle': 0.0,
        'chromaticSplit': 3.0,
        'faultNoise': 0.5,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // With preserveAlpha: true, every transparent pixel in original MUST remain completely transparent
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
