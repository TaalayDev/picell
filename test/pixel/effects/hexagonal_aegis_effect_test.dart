import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('HexagonalAegisEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = HexagonalAegisEffect();
      expect(effect.type, equals(EffectType.hexagonalAegis));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['barrierOffset'], equals(3.0));
      expect(effect.parameters['hexRadius'], equals(4.0));
      expect(effect.parameters['shieldCoverage'], equals('fullBubble'));
      expect(effect.parameters['barrierPalette'], equals('holoCyan'));
      expect(effect.parameters['innerDither'], isTrue);
      expect(effect.parameters['edgeGlow'], equals(0.75));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = HexagonalAegisEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'barrierOffset' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'hexRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shieldCoverage' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'barrierPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'innerDither' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'edgeGlow' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes HexagonalAegisEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.hexagonalAegis,
        {
          'barrierOffset': 4.0,
          'barrierPalette': 'neonOrange',
          'shieldCoverage': 'forwardRight',
        },
      );
      expect(effect, isA<HexagonalAegisEffect>());
      expect(effect.parameters['barrierOffset'], equals(4.0));
      expect(effect.parameters['barrierPalette'], equals('neonOrange'));
      expect(effect.parameters['shieldCoverage'], equals('forwardRight'));
    });

    test('renders hexagonal wireframe barrier shell outside sprite contour', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 8x8 solid sprite centered at (12..19, 12..19)
      for (int y = 12; y <= 19; y++) {
        for (int x = 12; x <= 19; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = HexagonalAegisEffect({
        'barrierOffset': 2.0,
        'hexRadius': 3.5,
        'shieldCoverage': 'fullBubble',
        'barrierPalette': 'holoCyan',
        'innerDither': true,
        'edgeGlow': 0.8,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that barrier pixels are drawn in the offset shell (e.g. at distance 2-6px from sprite)
      bool foundBarrierPixel = false;
      for (int y = 4; y <= 27; y++) {
        for (int x = 4; x <= 27; x++) {
          final idx = y * width + x;
          // Look outside original sprite
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 50) {
              foundBarrierPixel = true;
              break;
            }
          }
        }
        if (foundBarrierPixel) break;
      }
      expect(foundBarrierPixel, isTrue, reason: 'Hexagonal barrier shell should be drawn outside sprite');
    });

    test('neonOrange palette produces warm orange and amber barrier hues', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      // 6x6 square at center (11..16, 11..16)
      for (int y = 11; y <= 16; y++) {
        for (int x = 11; x <= 16; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = HexagonalAegisEffect({
        'barrierOffset': 2.0,
        'hexRadius': 3.0,
        'shieldCoverage': 'fullBubble',
        'barrierPalette': 'neonOrange',
        'innerDither': true,
        'edgeGlow': 1.0,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of orange wireframe/dither pixels (R high, B low)
      bool foundOrange = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (r > 200 && g > 100 && b < 80) {
            foundOrange = true;
            break;
          }
        }
      }
      expect(foundOrange, isTrue, reason: 'neonOrange palette should produce orange pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF228844;
      for (int y = 10; y <= 14; y++) {
        for (int x = 10; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = HexagonalAegisEffect({
        'barrierOffset': 1.0,
        'hexRadius': 3.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must be perfectly untouched
      for (int y = 10; y <= 14; y++) {
        for (int x = 10; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
