import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WaxSgraffitoEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = WaxSgraffitoEffect();
      expect(effect.type, equals(EffectType.waxSgraffito));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['sgraffitoScratchDensity'], equals(0.45));
      expect(effect.parameters['waxThickImpasto'], equals(0.5));
      expect(effect.parameters['scratchStrokeLength'], equals(5.0));
      expect(effect.parameters['underlayerPalette'], equals('rainbowSpectrum'));
      expect(effect.parameters['waxRoughness'], equals(0.35));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WaxSgraffitoEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'sgraffitoScratchDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waxThickImpasto' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'scratchStrokeLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'underlayerPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'waxRoughness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes WaxSgraffitoEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.waxSgraffito,
        {
          'sgraffitoScratchDensity': 0.7,
          'underlayerPalette': 'neonGlow',
          'waxThickImpasto': 0.8,
        },
      );
      expect(effect, isA<WaxSgraffitoEffect>());
      expect(effect.parameters['sgraffitoScratchDensity'], equals(0.7));
      expect(effect.parameters['underlayerPalette'], equals('neonGlow'));
      expect(effect.parameters['waxThickImpasto'], equals(0.8));
    });

    test('renders dark pastel topcoat with chromatic sgraffito incisions on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Gradient pattern
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = 0xFF000000 | (x * 7 << 16) | (y * 7 << 8);
        }
      }

      final effect = WaxSgraffitoEffect({
        'sgraffitoScratchDensity': 0.5,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, equals(width * height));
    });

    test('higher sgraffitoScratchDensity exposes more chromatic underlayer', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF888888; // Uniform mid-gray
      }

      final lowScratch = WaxSgraffitoEffect({
        'sgraffitoScratchDensity': 0.1,
        'underlayerPalette': 'rainbowSpectrum',
        'preserveAlpha': false,
      });
      final highScratch = WaxSgraffitoEffect({
        'sgraffitoScratchDensity': 0.9,
        'underlayerPalette': 'rainbowSpectrum',
        'preserveAlpha': false,
      });

      final outLow = lowScratch.apply(pixels, width, height);
      final outHigh = highScratch.apply(pixels, width, height);

      int brightChromaticPixels(Uint32List p) {
        int count = 0;
        for (int i = 0; i < p.length; i++) {
          final r = (p[i] >> 16) & 0xFF;
          final g = (p[i] >> 8) & 0xFF;
          final b = p[i] & 0xFF;
          // Uncarved dark topcoat is dark (r,g,b <= 65). Scratched open underlayer is bright (> 70)
          if (r > 70 || g > 70 || b > 70) count++;
        }
        return count;
      }

      expect(brightChromaticPixels(outHigh), greaterThan(brightChromaticPixels(outLow)));
    });

    test('preserveAlpha restricts sgraffito to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Central diagonal cross
      for (int i = 6; i < 18; i++) {
        pixels[i * width + i] = 0xFF44AAFF;
        pixels[i * width + (23 - i)] = 0xFF44AAFF;
      }

      final effect = WaxSgraffitoEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Outside pixel remains transparent
      expect(out[0], equals(0));
      // Inside pixel has color
      expect(out[12 * width + 12], isNot(equals(0)));
    });
  });
}
