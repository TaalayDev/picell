import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SolarEclipseEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SolarEclipseEffect();
      expect(effect.type, equals(EffectType.solarEclipse));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['coronaRadius'], equals(0.25));
      expect(effect.parameters['flareTurbulence'], equals(0.5));
      expect(effect.parameters['eclipsePhase'], equals(0.0));
      expect(effect.parameters['glowColor'], equals(0xFFFFB300));
      expect(effect.parameters['diamondRing'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SolarEclipseEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'coronaRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flareTurbulence' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'eclipsePhase' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glowColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'diamondRing' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SolarEclipseEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.solarEclipse,
        {
          'coronaRadius': 0.3,
          'glowColor': 0xFFFF1744,
          'flareTurbulence': 0.8,
        },
      );
      expect(effect, isA<SolarEclipseEffect>());
      expect(effect.parameters['coronaRadius'], equals(0.3));
      expect(effect.parameters['glowColor'], equals(0xFFFF1744));
      expect(effect.parameters['flareTurbulence'], equals(0.8));
    });

    test('renders coronal illumination and dark occulting moon disc', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      // Grey sprite block
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      final effect = SolarEclipseEffect({
        'coronaRadius': 0.3,
        'eclipsePhase': 0.0, // Centered total eclipse
        'glowColor': 0xFFFFB300,
        'preserveAlpha': true,
        'time': 0.0,
      });

      final out = effect.apply(pixels, width, height);

      // Center (under moon umbra) should be shaded darker than original grey
      final centerPixel = out[16 * width + 16];
      final cR = (centerPixel >> 16) & 0xFF;
      expect(cR, lessThan(128));

      // Coronal ring area outside the moon disc should be illuminated by golden corona
      final rimPixel = out[6 * width + 16];
      expect(rimPixel, isNot(equals(0xFF808080)));
    });

    test('time animation advances lunar transit across solar disc', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      final effectT0 = SolarEclipseEffect({
        'time': 0.1,
      });

      final effectT1 = SolarEclipseEffect({
        'time': 0.7,
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
