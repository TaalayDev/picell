import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ByzantineMosaicEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ByzantineMosaicEffect();
      expect(effect.type, equals(EffectType.byzantineMosaic));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['tesseraeSize'], equals(6.0));
      expect(effect.parameters['groutThickness'], equals(1.0));
      expect(effect.parameters['groutColor'], equals('darkMortar'));
      expect(effect.parameters['goldLeafRatio'], equals(0.25));
      expect(effect.parameters['tileAngleJitter'], equals(0.45));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ByzantineMosaicEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'tesseraeSize' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'groutThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'groutColor' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'goldLeafRatio' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'tileAngleJitter' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ByzantineMosaicEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.byzantineMosaic,
        {
          'tesseraeSize': 8.0,
          'groutColor': 'antiqueSand',
          'goldLeafRatio': 0.5,
        },
      );
      expect(effect, isA<ByzantineMosaicEffect>());
      expect(effect.parameters['tesseraeSize'], equals(8.0));
      expect(effect.parameters['groutColor'], equals('antiqueSand'));
      expect(effect.parameters['goldLeafRatio'], equals(0.5));
    });

    test('renders Voronoi tesserae and mortar channels on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Create test pattern
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = 0xFF2196F3; // Deep blue
        }
      }

      final effect = ByzantineMosaicEffect({
        'tesseraeSize': 6.0,
        'groutThickness': 1.0,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, equals(width * height));
    });

    test('goldLeafRatio increases golden tesserae pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF102040; // Dark navy background
      }

      final noGoldEffect = ByzantineMosaicEffect({
        'tesseraeSize': 6.0,
        'goldLeafRatio': 0.0,
        'preserveAlpha': false,
      });
      final highGoldEffect = ByzantineMosaicEffect({
        'tesseraeSize': 6.0,
        'goldLeafRatio': 0.8,
        'preserveAlpha': false,
      });

      final outNoGold = noGoldEffect.apply(pixels, width, height);
      final outHighGold = highGoldEffect.apply(pixels, width, height);

      int goldToneCount(Uint32List p) {
        int count = 0;
        for (int i = 0; i < p.length; i++) {
          final r = (p[i] >> 16) & 0xFF;
          final g = (p[i] >> 8) & 0xFF;
          final b = p[i] & 0xFF;
          // Gold smalti has high red and green with lower blue (yellow-amber spectrum)
          if (r > 160 && g > 130 && b < 100) count++;
        }
        return count;
      }

      expect(goldToneCount(outHighGold), greaterThan(goldToneCount(outNoGold)));
    });

    test('preserveAlpha restricts mosaic to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Central circular icon
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final dx = x - 12;
          final dy = y - 12;
          if (dx * dx + dy * dy <= 36) {
            pixels[y * width + x] = 0xFFFF0055;
          }
        }
      }

      final effect = ByzantineMosaicEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Corner pixel must remain transparent
      expect(out[0], equals(0));
      // Center pixel must be non-zero
      expect(out[12 * width + 12], isNot(equals(0)));
    });
  });
}
