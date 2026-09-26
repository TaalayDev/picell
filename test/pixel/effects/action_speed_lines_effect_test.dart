import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ActionSpeedLinesEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ActionSpeedLinesEffect();
      expect(effect.type, equals(EffectType.actionSpeedLines));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['motionAngle'], equals(0.0));
      expect(effect.parameters['lineLength'], equals(24.0));
      expect(effect.parameters['lineDensity'], equals(0.6));
      expect(effect.parameters['strokeWidth'], equals(1.5));
      expect(effect.parameters['taperFalloff'], equals(1.0));
      expect(effect.parameters['strokeColor'], equals(0xFFFFFFFF));
      expect(effect.parameters['speedDust'], isTrue);
      expect(effect.parameters['behindOnly'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ActionSpeedLinesEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'motionAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lineLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lineDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'strokeWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'taperFalloff' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'strokeColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'speedDust' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ActionSpeedLinesEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.actionSpeedLines,
        {
          'motionAngle': 180.0,
          'lineLength': 32.0,
          'strokeColor': 0xFF00E5FF,
        },
      );
      expect(effect, isA<ActionSpeedLinesEffect>());
      expect(effect.parameters['motionAngle'], equals(180.0));
      expect(effect.parameters['lineLength'], equals(32.0));
      expect(effect.parameters['strokeColor'], equals(0xFF00E5FF));
    });

    test('projects speed lines trailing behind the sprite motion direction', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Draw a 6x6 square in the center (x: 13..18, y: 13..18)
      for (int y = 13; y <= 18; y++) {
        for (int x = 13; x <= 18; x++) {
          pixels[y * width + x] = 0xFF0000FF; // solid blue sprite
        }
      }

      // Moving right (motionAngle = 0), lines shoot leftward (trail direction: -x)
      final effect = ActionSpeedLinesEffect({
        'motionAngle': 0.0,
        'lineLength': 12.0,
        'lineDensity': 1.0, // force lines to emit from all trailing edge pixels
        'strokeWidth': 1.0,
        'taperFalloff': 1.0,
        'strokeColor': 0xFFFFFFFF,
        'speedDust': false,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Trailing side is x < 13. Check that at least some pixels in x in [5..12], y in [13..18] are drawn
      bool foundSpeedLinesBehind = false;
      for (int y = 13; y <= 18; y++) {
        for (int x = 5; x < 13; x++) {
          final p = result[y * width + x];
          if (((p >> 24) & 0xFF) > 0) {
            foundSpeedLinesBehind = true;
            break;
          }
        }
        if (foundSpeedLinesBehind) break;
      }
      expect(foundSpeedLinesBehind, isTrue, reason: 'Speed lines should stream behind trailing edge of sprite');

      // The front side (x > 18) should NOT have trailing speed lines
      bool foundSpeedLinesInFront = false;
      for (int y = 13; y <= 18; y++) {
        for (int x = 19; x < width; x++) {
          final p = result[y * width + x];
          if (((p >> 24) & 0xFF) > 0) {
            foundSpeedLinesInFront = true;
            break;
          }
        }
      }
      expect(foundSpeedLinesInFront, isFalse, reason: 'Speed lines should not emit in front of moving sprite');
    });

    test('behindOnly preserves foreground sprite pixels without modification', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFFFF0000; // Red
      for (int y = 10; y <= 14; y++) {
        for (int x = 10; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = ActionSpeedLinesEffect({
        'motionAngle': 90.0,
        'lineLength': 10.0,
        'lineDensity': 1.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 14; y++) {
        for (int x = 10; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor),
              reason: 'Foreground sprite pixel should remain identical when behindOnly is true');
        }
      }
    });

    test('custom strokeColor tints emitted speed strokes', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // 4x4 square at (10, 10)
      for (int y = 10; y <= 13; y++) {
        for (int x = 10; x <= 13; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      const cyanColor = 0xFF00E5FF;
      final effect = ActionSpeedLinesEffect({
        'motionAngle': 0.0,
        'lineLength': 8.0,
        'lineDensity': 1.0,
        'strokeColor': cyanColor,
        'speedDust': false,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that trailing line pixel has cyan color components (R=0, G=0xE5, B=0xFF)
      bool verifiedTint = false;
      for (int x = 2; x < 10; x++) {
        final p = result[11 * width + x];
        final a = (p >> 24) & 0xFF;
        if (a > 50) {
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          expect(g, inInclusiveRange(0xD0, 0xFF));
          expect(b, equals(0xFF));
          verifiedTint = true;
          break;
        }
      }
      expect(verifiedTint, isTrue);
    });
  });
}
