import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('HologramGlitchEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = HologramGlitchEffect();
      expect(effect.type, equals(EffectType.hologramGlitch));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['holoColor'], equals(0xFF00E5FF));
      expect(effect.parameters['colorIntensity'], equals(0.75));
      expect(effect.parameters['scanlineDensity'], equals(2));
      expect(effect.parameters['flickerInterval'], equals(1.5));
      expect(effect.parameters['glitchDropout'], equals(0.3));
      expect(effect.parameters['jitterSpread'], equals(2));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = HologramGlitchEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'holoColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'colorIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'scanlineDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flickerInterval' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glitchDropout' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'jitterSpread' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes HologramGlitchEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.hologramGlitch,
        {
          'holoColor': 0xFFFFB300,
          'colorIntensity': 0.8,
          'jitterSpread': 4,
        },
      );
      expect(effect, isA<HologramGlitchEffect>());
      expect(effect.parameters['holoColor'], equals(0xFFFFB300));
      expect(effect.parameters['colorIntensity'], equals(0.8));
      expect(effect.parameters['jitterSpread'], equals(4));
    });

    test('applies holographic tint and raster scanlines to sprite pixels', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      // Fill canvas with grey
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      final effect = HologramGlitchEffect({
        'holoColor': 0xFF00E5FF, // Cyan
        'colorIntensity': 1.0,
        'scanlineDensity': 2,
        'glitchDropout': 0.0,
        'jitterSpread': 0,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Cyan tinted: Blue and Green components should be high
      final p = out[1 * width + 1];
      final r = (p >> 16) & 0xFF;
      final g = (p >> 8) & 0xFF;
      final b = p & 0xFF;
      expect(g, greaterThan(r));
      expect(b, greaterThan(r));

      // Scanline row (row 0) should be dimmer than non-scanline row (row 1)
      final scanlineP = out[0 * width + 1];
      final nonScanlineP = out[1 * width + 1];
      final scanlineB = scanlineP & 0xFF;
      final nonScanlineB = nonScanlineP & 0xFF;
      expect(scanlineB, lessThan(nonScanlineB));
    });

    test('time animation cycles flicker and jitter across frames', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      final effectT0 = HologramGlitchEffect({
        'time': 0.1,
        'glitchDropout': 0.5,
        'jitterSpread': 3,
      });

      final effectT1 = HologramGlitchEffect({
        'time': 0.6,
        'glitchDropout': 0.5,
        'jitterSpread': 3,
      });

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      bool differ = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) {
          differ = true;
          break;
        }
      }
      expect(differ, isTrue);
    });
  });
}
