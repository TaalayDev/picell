import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SunbeamGodRaysEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SunbeamGodRaysEffect();
      expect(effect.type, equals(EffectType.sunbeamGodRays));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['rayAngle'], equals(30.0));
      expect(effect.parameters['rayIntensity'], equals(0.65));
      expect(effect.parameters['dustMoteCount'], equals(45));
      expect(effect.parameters['atmosphereTint'], equals('goldenDawn'));
      expect(effect.parameters['canopyShadowScale'], equals(3.5));
      expect(effect.parameters['decayRate'], equals(1.1));
      expect(effect.parameters['moteSpeed'], equals(1.0));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SunbeamGodRaysEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'rayAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rayIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'dustMoteCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'atmosphereTint' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'canopyShadowScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'decayRate' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'moteSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SunbeamGodRaysEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.sunbeamGodRays,
        {
          'rayAngle': 45.0,
          'atmosphereTint': 'mistyJungleCyan',
          'rayIntensity': 0.8,
        },
      );
      expect(effect, isA<SunbeamGodRaysEffect>());
      expect(effect.parameters['rayAngle'], equals(45.0));
      expect(effect.parameters['atmosphereTint'], equals('mistyJungleCyan'));
      expect(effect.parameters['rayIntensity'], equals(0.8));
    });

    test('renders volumetric Tyndall god rays and specular dust motes on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Dark temple vault background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF101216;
      }

      final effect = SunbeamGodRaysEffect({
        'rayAngle': 25.0,
        'rayIntensity': 0.8,
        'dustMoteCount': 50,
        'atmosphereTint': 'goldenDawn',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int brightPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        final r = (out[i] >> 16) & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        final b = out[i] & 0xFF;
        if (r > 60 || g > 60 || b > 60) brightPixels++;
      }
      expect(brightPixels, greaterThan(0));
    });

    test('time animation advances dust mote drift positions and ray shimmer', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF0A0D10;
      }

      final effectT0 = SunbeamGodRaysEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = SunbeamGodRaysEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts illumination and motes to sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 block is opaque character sprite
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF4A3525;
        }
      }

      final effect = SunbeamGodRaysEffect({
        'preserveAlpha': true,
        'rayIntensity': 0.9,
        'dustMoteCount': 40,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside the central 8x8 block must remain 0
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
