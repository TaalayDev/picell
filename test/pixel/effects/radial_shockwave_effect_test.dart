import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RadialShockwaveEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = RadialShockwaveEffect();
      expect(effect.type, equals(EffectType.radialShockwave));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['waveThickness'], equals(2));
      expect(effect.parameters['expansionSpeed'], equals(1.5));
      expect(effect.parameters['ringShape'], equals('circular'));
      expect(effect.parameters['shockwaveColor'], equals(0xFFFFFFFF));
      expect(effect.parameters['dustDebris'], isTrue);
      expect(effect.parameters['debrisCount'], equals(30));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RadialShockwaveEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'waveThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'expansionSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'ringShape' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'shockwaveColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'dustDebris' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'debrisCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes RadialShockwaveEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.radialShockwave,
        {
          'waveThickness': 3,
          'ringShape': 'isometricDisc',
          'shockwaveColor': 0xFFFFB300,
        },
      );
      expect(effect, isA<RadialShockwaveEffect>());
      expect(effect.parameters['waveThickness'], equals(3));
      expect(effect.parameters['ringShape'], equals('isometricDisc'));
      expect(effect.parameters['shockwaveColor'], equals(0xFFFFB300));
    });

    test('renders circular blast ring expanding over canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      // Fill canvas
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020;
      }

      final effect = RadialShockwaveEffect({
        'waveThickness': 3,
        'expansionSpeed': 1.0,
        'ringShape': 'circular',
        'shockwaveColor': 0xFFFFFFFF,
        'dustDebris': false,
        'time': 0.4,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Verify that pixels around the current radius are brightened
      int brightenedCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF202020) {
          brightenedCount++;
        }
      }
      expect(brightenedCount, greaterThan(0));
    });

    test('time animation advances shockwave radius outward', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF101010;
      }

      final effectT0 = RadialShockwaveEffect({
        'time': 0.2,
        'expansionSpeed': 1.0,
        'dustDebris': false,
      });

      final effectT1 = RadialShockwaveEffect({
        'time': 0.6,
        'expansionSpeed': 1.0,
        'dustDebris': false,
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
