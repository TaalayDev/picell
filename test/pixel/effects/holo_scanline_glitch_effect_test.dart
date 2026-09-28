import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('HoloScanlineGlitchEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = HoloScanlineGlitchEffect();
      expect(effect.type, equals(EffectType.holoScanlineGlitch));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['scanlineGap'], equals(2.0));
      expect(effect.parameters['scanlineOpacity'], equals(0.35));
      expect(effect.parameters['glitchIntensity'], equals(3.0));
      expect(effect.parameters['chromaticSplit'], isTrue);
      expect(effect.parameters['holoPalette'], equals('holoCyan'));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = HoloScanlineGlitchEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'scanlineGap' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'scanlineOpacity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glitchIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'chromaticSplit' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'holoPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes HoloScanlineGlitchEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.holoScanlineGlitch,
        {
          'scanlineGap': 3.0,
          'scanlineOpacity': 0.5,
          'holoPalette': 'vividMagenta',
        },
      );
      expect(effect, isA<HoloScanlineGlitchEffect>());
      expect(effect.parameters['scanlineGap'], equals(3.0));
      expect(effect.parameters['scanlineOpacity'], equals(0.5));
      expect(effect.parameters['holoPalette'], equals('vividMagenta'));
    });

    test('applies horizontal scanlines and slice displacement jitter to sprite', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 16x16 white sprite block in center (8..23, 8..23)
      for (int y = 8; y <= 23; y++) {
        for (int x = 8; x <= 23; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = HoloScanlineGlitchEffect({
        'scanlineGap': 2.0,
        'scanlineOpacity': 0.5,
        'glitchIntensity': 3.0,
        'chromaticSplit': true,
        'holoPalette': 'holoCyan',
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that scanline rows are darker than non-scanline rows
      int scanlineTotalLuma = 0;
      int scanlineCount = 0;
      int normalTotalLuma = 0;
      int normalCount = 0;

      for (int y = 8; y <= 23; y++) {
        final isScanline = (y % 2 == 0);
        for (int x = 10; x <= 20; x++) {
          final px = result[y * width + x];
          final r = (px >> 16) & 0xFF;
          final g = (px >> 8) & 0xFF;
          final b = px & 0xFF;
          final luma = (r + g + b) ~/ 3;
          if (isScanline) {
            scanlineTotalLuma += luma;
            scanlineCount++;
          } else {
            normalTotalLuma += luma;
            normalCount++;
          }
        }
      }

      final avgScanlineLuma = scanlineTotalLuma / scanlineCount;
      final avgNormalLuma = normalTotalLuma / normalCount;

      expect(avgScanlineLuma, lessThan(avgNormalLuma));
    });

    test('different holoPalette themes apply distinctive phosphor tints', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      for (int y = 6; y <= 17; y++) {
        for (int x = 6; x <= 17; x++) {
          pixels[y * width + x] = 0xFF888888;
        }
      }

      final magentaEffect = HoloScanlineGlitchEffect({
        'holoPalette': 'vividMagenta',
        'glitchIntensity': 0.0,
      });
      final amberEffect = HoloScanlineGlitchEffect({
        'holoPalette': 'terminalAmber',
        'glitchIntensity': 0.0,
      });

      final magentaResult = magentaEffect.apply(Uint32List.fromList(pixels), width, height);
      final amberResult = amberEffect.apply(Uint32List.fromList(pixels), width, height);

      final magPx = magentaResult[11 * width + 11];
      final ambPx = amberResult[11 * width + 11];

      final magR = (magPx >> 16) & 0xFF;
      final magB = magPx & 0xFF;

      final ambR = (ambPx >> 16) & 0xFF;
      final ambG = (ambPx >> 8) & 0xFF;
      final ambB = ambPx & 0xFF;

      // Magenta should have high Red and Blue
      expect(magR, greaterThan(130));
      expect(magB, greaterThan(130));

      // Amber should have high Red and Green, low Blue
      expect(ambR, greaterThan(130));
      expect(ambG, greaterThan(100));
      expect(ambB, lessThan(ambR));
    });

    test('preserveAlpha restricts holographic glitch strictly to active pixels', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      // Small 6x6 square in center (12..17, 12..17)
      for (int y = 12; y <= 17; y++) {
        for (int x = 12; x <= 17; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = HoloScanlineGlitchEffect({
        'glitchIntensity': 4.0,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that all outer pixels remain strictly transparent
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 12 && x <= 17 && y >= 12 && y <= 17);
          if (!isInside) {
            expect(result[y * width + x], equals(0));
          }
        }
      }
    });
  });
}
