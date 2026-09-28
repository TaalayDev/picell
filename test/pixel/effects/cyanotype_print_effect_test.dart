import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CyanotypePrintEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = CyanotypePrintEffect();
      expect(effect.type, equals(EffectType.cyanotypePrint));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['exposureDepth'], equals(1.2));
      expect(effect.parameters['prussianHueShift'], equals(0.0));
      expect(effect.parameters['edgeVignetteBleach'], equals(0.45));
      expect(effect.parameters['paperToothTexture'], equals(0.4));
      expect(effect.parameters['solarizationCurve'], equals(0.3));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CyanotypePrintEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'exposureDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'prussianHueShift' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'edgeVignetteBleach' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'paperToothTexture' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'solarizationCurve' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CyanotypePrintEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.cyanotypePrint,
        {
          'exposureDepth': 1.8,
          'prussianHueShift': -0.1,
        },
      );
      expect(effect, isA<CyanotypePrintEffect>());
      expect(effect.parameters['exposureDepth'], equals(1.8));
      expect(effect.parameters['prussianHueShift'], equals(-0.1));
    });

    test('renders photographic Prussian blue tones and paper highlights', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Create a gradient
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final val = ((x / width) * 255).toInt();
          pixels[y * width + x] = 0xFF000000 | (val << 16) | (val << 8) | val;
        }
      }

      final effect = CyanotypePrintEffect({
        'exposureDepth': 1.2,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, equals(width * height));
    });

    test('solarizationCurve and prussianHueShift affect output colors', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFFE0E0E0; // Near white
      }

      final standard = CyanotypePrintEffect({
        'prussianHueShift': 0.0,
        'solarizationCurve': 0.0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final solarized = CyanotypePrintEffect({
        'prussianHueShift': 0.0,
        'solarizationCurve': 0.8,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final indigo = CyanotypePrintEffect({
        'prussianHueShift': -0.2,
        'solarizationCurve': 0.0,
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffSolarized = false;
      bool diffIndigo = false;
      for (int i = 0; i < pixels.length; i++) {
        if (standard[i] != solarized[i]) diffSolarized = true;
        if (standard[i] != indigo[i]) diffIndigo = true;
      }
      expect(diffSolarized, isTrue);
      expect(diffIndigo, isTrue);
    });

    test('preserveAlpha restricts cyanotype exposure to sprite silhouette', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = CyanotypePrintEffect({
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
