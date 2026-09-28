import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ArcLightningEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ArcLightningEffect();
      expect(effect.type, equals(EffectType.arcLightning));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['arcDensity'], equals(0.6));
      expect(effect.parameters['boltThickness'], equals(1.5));
      expect(effect.parameters['branchingProbability'], equals(0.35));
      expect(effect.parameters['electricPalette'], equals('teslaCyan'));
      expect(effect.parameters['crackleJitter'], equals(1.5));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ArcLightningEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'arcDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'boltThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'branchingProbability' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'electricPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'crackleJitter' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ArcLightningEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.arcLightning,
        {
          'arcDensity': 0.8,
          'electricPalette': 'goldenThunder',
          'crackleJitter': 2.0,
        },
      );
      expect(effect, isA<ArcLightningEffect>());
      expect(effect.parameters['arcDensity'], equals(0.8));
      expect(effect.parameters['electricPalette'], equals('goldenThunder'));
      expect(effect.parameters['crackleJitter'], equals(2.0));
    });

    test('projects electric arcs and sparks between sprite extremities', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Draw a cross / star sprite with sharp extremities
      for (int i = 10; i <= 22; i++) {
        pixels[16 * width + i] = 0xFF555555; // Horizontal bar
        pixels[i * width + 16] = 0xFF555555; // Vertical bar
      }

      final effect = ArcLightningEffect({
        'arcDensity': 0.8,
        'boltThickness': 1.5,
        'branchingProbability': 0.5,
        'electricPalette': 'teslaCyan',
        'crackleJitter': 1.5,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that electric arc pixels / sparks are drawn around the contour
      bool foundArcPixel = false;
      for (int y = 8; y <= 24; y++) {
        for (int x = 8; x <= 24; x++) {
          final idx = y * width + x;
          // Check for white core bolt or cyan glow
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 100) {
              foundArcPixel = true;
              break;
            }
          }
        }
        if (foundArcPixel) break;
      }
      expect(foundArcPixel, isTrue, reason: 'Electric arcs should project into contour space');
    });

    test('goldenThunder palette produces yellow and gold voltage glow', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // 4x4 block at (10..13, 10..13)
      for (int y = 10; y <= 13; y++) {
        for (int x = 10; x <= 13; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = ArcLightningEffect({
        'arcDensity': 1.0,
        'boltThickness': 2.0,
        'electricPalette': 'goldenThunder',
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // In goldenThunder, gold/amber outer voltage halo has high Red and Green (yellow/gold)
      bool foundGoldenGlow = false;
      for (int y = 8; y <= 15; y++) {
        for (int x = 8; x <= 15; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final p = result[idx];
            final r = (p >> 16) & 0xFF;
            final g = (p >> 8) & 0xFF;
            final b = p & 0xFF;
            if (r > 200 && g > 150 && b < 100) {
              foundGoldenGlow = true;
              break;
            }
          }
        }
        if (foundGoldenGlow) break;
      }
      expect(foundGoldenGlow, isTrue, reason: 'goldenThunder palette should yield golden/amber halo pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF44AA44;
      for (int y = 8; y <= 14; y++) {
        for (int x = 8; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = ArcLightningEffect({
        'arcDensity': 1.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 8; y <= 14; y++) {
        for (int x = 8; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor),
              reason: 'Foreground sprite pixels should remain untouched when behindOnly is true');
        }
      }
    });
  });
}
