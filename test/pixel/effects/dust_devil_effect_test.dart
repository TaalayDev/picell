import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DustDevilEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = DustDevilEffect();
      expect(effect.type, equals(EffectType.dustDevil));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['vortexRadius'], equals(0.32));
      expect(effect.parameters['sandstormDensity'], equals(0.7));
      expect(effect.parameters['orbitSpeed'], equals(2.0));
      expect(effect.parameters['funnelWobble'], equals(0.4));
      expect(effect.parameters['dustPalette'], equals('saharaOchre'));
      expect(effect.parameters['heatMirageDistortion'], equals(0.35));
      expect(effect.parameters['groundSkirtScale'], equals(0.5));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DustDevilEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'vortexRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sandstormDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'funnelWobble' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'dustPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'heatMirageDistortion' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'groundSkirtScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DustDevilEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.dustDevil,
        {
          'vortexRadius': 0.45,
          'dustPalette': 'marsCrimson',
          'sandstormDensity': 0.85,
        },
      );
      expect(effect, isA<DustDevilEffect>());
      expect(effect.parameters['vortexRadius'], equals(0.45));
      expect(effect.parameters['dustPalette'], equals('marsCrimson'));
      expect(effect.parameters['sandstormDensity'], equals(0.85));
    });

    test('renders swirling cyclonic dust funnel and orbiting sand grains', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Dark arid bedrock background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF181008;
      }

      final effect = DustDevilEffect({
        'vortexRadius': 0.35,
        'sandstormDensity': 0.8,
        'orbitSpeed': 2.0,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int terracottaDustCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        final r = (out[i] >> 16) & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        final b = out[i] & 0xFF;
        if (r > 120 && g > 60 && r > b) terracottaDustCount++;
      }
      expect(terracottaDustCount, greaterThan(0));
    });

    test('dustPalette variations change color grading', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020;
      }

      final effectMars = DustDevilEffect({'dustPalette': 'marsCrimson', 'preserveAlpha': false});
      final effectWhite = DustDevilEffect({'dustPalette': 'saltFlatsWhite', 'preserveAlpha': false});

      final outMars = effectMars.apply(pixels, width, height);
      final outWhite = effectWhite.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outMars[i] != outWhite[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('time animation drives cyclonic orbital rotation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF140F0A;
      }

      final effectT0 = DustDevilEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = DustDevilEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts dust devil to sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 block is opaque character sprite
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF503520;
        }
      }

      final effect = DustDevilEffect({
        'preserveAlpha': true,
        'sandstormDensity': 0.9,
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
