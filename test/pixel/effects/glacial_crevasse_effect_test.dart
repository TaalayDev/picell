import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('GlacialCrevasseEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = GlacialCrevasseEffect();
      expect(effect.type, equals(EffectType.glacialCrevasse));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['crevasseDepth'], equals(0.7));
      expect(effect.parameters['iceTurquoiseGlow'], equals(0.75));
      expect(effect.parameters['snowCorniceThickness'], equals(3.5));
      expect(effect.parameters['fractureFacetJitter'], equals(0.45));
      expect(effect.parameters['chasmWidth'], equals(0.4));
      expect(effect.parameters['icePalette'], equals('sapphireGlacier'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = GlacialCrevasseEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'crevasseDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'iceTurquoiseGlow' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'snowCorniceThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'fractureFacetJitter' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'chasmWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'icePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes GlacialCrevasseEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.glacialCrevasse,
        {
          'crevasseDepth': 0.85,
          'icePalette': 'emeraldArctic',
          'iceTurquoiseGlow': 0.9,
        },
      );
      expect(effect, isA<GlacialCrevasseEffect>());
      expect(effect.parameters['crevasseDepth'], equals(0.85));
      expect(effect.parameters['icePalette'], equals('emeraldArctic'));
      expect(effect.parameters['iceTurquoiseGlow'], equals(0.9));
    });

    test('renders glacial chasm with radiant blue interior and snow lips', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Cold alpine rock background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202530;
      }

      final effect = GlacialCrevasseEffect({
        'crevasseDepth': 0.8,
        'iceTurquoiseGlow': 0.85,
        'chasmWidth': 0.45,
        'icePalette': 'sapphireGlacier',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int brightIceCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        final b = out[i] & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        if (b > 120 || g > 120) brightIceCount++;
      }
      expect(brightIceCount, greaterThan(0));
    });

    test('time animation drives drifting snow flurries and facet glints', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF151820;
      }

      final effectT0 = GlacialCrevasseEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = GlacialCrevasseEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts glacial crevasse to sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 block is opaque character sprite
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF354555;
        }
      }

      final effect = GlacialCrevasseEffect({
        'preserveAlpha': true,
        'iceTurquoiseGlow': 0.9,
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
