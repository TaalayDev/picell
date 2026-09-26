import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('NanotechCircuitEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = NanotechCircuitEffect();
      expect(effect.type, equals(EffectType.nanotechCircuit));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['traceDensity'], equals(6.0));
      expect(effect.parameters['angleMode'], equals('angled45'));
      expect(effect.parameters['showPads'], isTrue);
      expect(effect.parameters['dataPackets'], isTrue);
      expect(effect.parameters['circuitPalette'], equals('neonCyanPCB'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = NanotechCircuitEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'traceDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'angleMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'showPads' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'dataPackets' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'circuitPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes NanotechCircuitEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.nanotechCircuit,
        {
          'traceDensity': 8.0,
          'angleMode': 'orthogonal90',
          'circuitPalette': 'goldTraces',
        },
      );
      expect(effect, isA<NanotechCircuitEffect>());
      expect(effect.parameters['traceDensity'], equals(8.0));
      expect(effect.parameters['angleMode'], equals('orthogonal90'));
      expect(effect.parameters['circuitPalette'], equals('goldTraces'));
    });

    test('routes circuit traces, via pads, and nanite data packets across sprite', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 12x12 character block in center (12..23, 12..23)
      for (int y = 12; y <= 23; y++) {
        for (int x = 12; x <= 23; x++) {
          pixels[y * width + x] = 0xFF223344;
        }
      }

      final effect = NanotechCircuitEffect({
        'traceDensity': 6.0,
        'angleMode': 'bothMixed',
        'showPads': true,
        'dataPackets': true,
        'circuitPalette': 'neonCyanPCB',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that circuit elements (bright neon cyan or pads) were rendered
      int circuitPixelCount = 0;
      for (int i = 0; i < width * height; i++) {
        if (result[i] != pixels[i] && result[i] != 0) {
          circuitPixelCount++;
        }
      }

      expect(circuitPixelCount, greaterThan(25));
    });

    test('circuitPalette variations produce distinctive metal trace colors', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF111111;
        }
      }

      final goldEffect = NanotechCircuitEffect({
        'traceDensity': 8.0,
        'circuitPalette': 'goldTraces',
      });
      final crimsonEffect = NanotechCircuitEffect({
        'traceDensity': 8.0,
        'circuitPalette': 'crimsonOverclock',
      });

      final goldResult = goldEffect.apply(Uint32List.fromList(pixels), width, height);
      final crimsonResult = crimsonEffect.apply(Uint32List.fromList(pixels), width, height);

      int goldCount = 0;
      int crimsonCount = 0;

      for (int i = 0; i < width * height; i++) {
        final gR = (goldResult[i] >> 16) & 0xFF;
        final gG = (goldResult[i] >> 8) & 0xFF;
        final gB = goldResult[i] & 0xFF;
        if (gR > 200 && gG > 180 && gB < 50) goldCount++;

        final cR = (crimsonResult[i] >> 16) & 0xFF;
        final cG = (crimsonResult[i] >> 8) & 0xFF;
        final cB = crimsonResult[i] & 0xFF;
        if (cR > 200 && cG < 60 && cB < 80) crimsonCount++;
      }

      expect(goldCount, greaterThan(3));
      expect(crimsonCount, greaterThan(3));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      // Foreground character block
      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF334455;
        }
      }

      final effect = NanotechCircuitEffect({
        'traceDensity': 10.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that every single original opaque pixel is preserved 100%
      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF334455));
        }
      }
    });
  });
}
