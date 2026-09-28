import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('AuroraCurtainsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = AuroraCurtainsEffect();
      expect(effect.type, equals(EffectType.auroraCurtains));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['curtainWaveSpeed'], equals(1.5));
      expect(effect.parameters['auroraBrightness'], equals(0.8));
      expect(effect.parameters['verticalRayDetail'], equals(0.65));
      expect(effect.parameters['curtainCount'], equals(2));
      expect(effect.parameters['auroraPalette'], equals('arcticEmerald'));
      expect(effect.parameters['starsVisibility'], equals(0.65));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = AuroraCurtainsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'curtainWaveSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'auroraBrightness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'verticalRayDetail' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'curtainCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'auroraPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'starsVisibility' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes AuroraCurtainsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.auroraCurtains,
        {
          'curtainCount': 3,
          'auroraPalette': 'solarStormViolet',
          'auroraBrightness': 0.9,
        },
      );
      expect(effect, isA<AuroraCurtainsEffect>());
      expect(effect.parameters['curtainCount'], equals(3));
      expect(effect.parameters['auroraPalette'], equals('solarStormViolet'));
      expect(effect.parameters['auroraBrightness'], equals(0.9));
    });

    test('renders undulating celestial aurora curtains and starry arctic night', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Deep arctic midnight backdrop
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF050812;
      }

      final effect = AuroraCurtainsEffect({
        'curtainWaveSpeed': 1.5,
        'auroraBrightness': 0.9,
        'curtainCount': 2,
        'auroraPalette': 'arcticEmerald',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int brightPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        final r = (out[i] >> 16) & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        final b = out[i] & 0xFF;
        if (g > 60 || b > 60 || r > 60) brightPixels++;
      }
      expect(brightPixels, greaterThan(0));
    });

    test('auroraPalette variations change emission colors', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF080814;
      }

      final effectEmerald = AuroraCurtainsEffect({'auroraPalette': 'arcticEmerald', 'preserveAlpha': false});
      final effectViolet = AuroraCurtainsEffect({'auroraPalette': 'solarStormViolet', 'preserveAlpha': false});

      final outEmerald = effectEmerald.apply(pixels, width, height);
      final outViolet = effectViolet.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outEmerald[i] != outViolet[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('time animation drives harmonic wave undulation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF060914;
      }

      final effectT0 = AuroraCurtainsEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = AuroraCurtainsEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts aurora glow to sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 block is opaque character sprite
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF203045;
        }
      }

      final effect = AuroraCurtainsEffect({
        'preserveAlpha': true,
        'auroraBrightness': 1.0,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside central 8x8 block must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 12 && x < 20 && y >= 12 && y < 20);
          final a = (out[y * width + x] >> 24) & 0xFF;
          if (!isInside) {
            expect(a, equals(0));
          } else {
            expect(a, equals(255));
          }
        }
      }
    });
  });
}
