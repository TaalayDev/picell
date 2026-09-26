import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SandDunesEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SandDunesEffect();
      expect(effect.type, equals(EffectType.sandDunes));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['duneScale'], equals(2.5));
      expect(effect.parameters['windAngle'], equals(20.0));
      expect(effect.parameters['rippleFrequency'], equals(5.0));
      expect(effect.parameters['crestPlumeDensity'], equals(0.6));
      expect(effect.parameters['sandPalette'], equals('namibRed'));
      expect(effect.parameters['duneShadowContrast'], equals(0.65));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SandDunesEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'duneScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'windAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rippleFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'crestPlumeDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'sandPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'duneShadowContrast' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SandDunesEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.sandDunes,
        {
          'duneScale': 3.5,
          'sandPalette': 'saharaGold',
          'crestPlumeDensity': 0.8,
        },
      );
      expect(effect, isA<SandDunesEffect>());
      expect(effect.parameters['duneScale'], equals(3.5));
      expect(effect.parameters['sandPalette'], equals('saharaGold'));
      expect(effect.parameters['crestPlumeDensity'], equals(0.8));
    });

    test('renders sweeping dunes with razor crests and wind ripples', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Dark background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF101010;
      }

      final effect = SandDunesEffect({
        'duneScale': 2.5,
        'sandPalette': 'namibRed',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int redSandCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        final r = (out[i] >> 16) & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        final b = out[i] & 0xFF;
        if (r > 100 && r > g && r > b) redSandCount++;
      }
      expect(redSandCount, greaterThan(0));
    });

    test('sandPalette variations produce distinct desert coloration', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF181818;
      }

      final effectRed = SandDunesEffect({'sandPalette': 'namibRed', 'preserveAlpha': false});
      final effectWhite = SandDunesEffect({'sandPalette': 'gypsumWhite', 'preserveAlpha': false});

      final outRed = effectRed.apply(pixels, width, height);
      final outWhite = effectWhite.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outRed[i] != outWhite[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('time animation advances blowing crest sand plumes', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF151515;
      }

      final effectT0 = SandDunesEffect({'time': 0.0, 'crestPlumeDensity': 0.8, 'preserveAlpha': false});
      final effectT1 = SandDunesEffect({'time': 0.5, 'crestPlumeDensity': 0.8, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts sand dunes to sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 block is opaque character sprite
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF4A3020;
        }
      }

      final effect = SandDunesEffect({
        'preserveAlpha': true,
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
