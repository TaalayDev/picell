import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SilhouetteDepthBevelEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = SilhouetteDepthBevelEffect();
      expect(effect.type, equals(EffectType.silhouetteDepthBevel));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['bevelDepth'], equals(3.0));
      expect(effect.parameters['lightAngle'], equals(315.0));
      expect(effect.parameters['bevelProfile'], equals('smoothCurved'));
      expect(effect.parameters['specularIntensity'], equals(0.65));
      expect(effect.parameters['ambientOcclusion'], equals(0.5));
      expect(effect.parameters['highlightTint'], equals(0xFFFFFFFF));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SilhouetteDepthBevelEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'bevelDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lightAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bevelProfile' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'specularIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'ambientOcclusion' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'highlightTint' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SilhouetteDepthBevelEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.silhouetteDepthBevel,
        {
          'bevelDepth': 5.0,
          'bevelProfile': 'chiseled',
          'specularIntensity': 0.8,
        },
      );
      expect(effect, isA<SilhouetteDepthBevelEffect>());
      expect(effect.parameters['bevelDepth'], equals(5.0));
      expect(effect.parameters['bevelProfile'], equals('chiseled'));
      expect(effect.parameters['specularIntensity'], equals(0.8));
    });

    test('generates specular highlights on illuminated face and ambient occlusion on shadow face', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Centered 16x16 solid blue block [8, 23] x [8, 23]
      for (int y = 8; y <= 23; y++) {
        for (int x = 8; x <= 23; x++) {
          pixels[y * width + x] = 0xFF4080C0;
        }
      }

      // Light from Top-Left (dx < 0, dy < 0, angle = 225° or 315°).
      // Let's use lightAngle = 135°: cos(135) = -0.707, sin(135) = +0.707 (points towards bottom-left).
      // If light is from top-left, outward normal at top-left edge points toward top-left (-x, -y).
      // In our code:
      // lightDirX = cos(rad), lightDirY = sin(rad).
      // At left edge (x=8): dRight > dLeft, gx > 0, nx = -gx < 0 (points left).
      // At right edge (x=23): dLeft > dRight, gx < 0, nx = -gx > 0 (points right).
      // So if lightAngle = 180°: lightDirX = -1, lightDirY = 0.
      // Left edge has nx < 0, dot = nx * (-1) > 0 -> Illuminated!
      // Right edge has nx > 0, dot = nx * (-1) < 0 -> Shadowed!
      final effect = SilhouetteDepthBevelEffect({
        'bevelDepth': 3.0,
        'lightAngle': 180.0,
        'bevelProfile': 'chiseled',
        'specularIntensity': 0.8,
        'ambientOcclusion': 0.8,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Pixel on left edge (x=8, y=16) should be brightened (specular highlight)
      final leftPixel = result[16 * width + 8];
      final origPixel = pixels[16 * width + 8];
      final leftBrightness = ((leftPixel >> 16) & 0xFF) + ((leftPixel >> 8) & 0xFF) + (leftPixel & 0xFF);
      final origBrightness = ((origPixel >> 16) & 0xFF) + ((origPixel >> 8) & 0xFF) + (origPixel & 0xFF);

      // Pixel on right edge (x=23, y=16) should be darkened (ambient occlusion shadow)
      final rightPixel = result[16 * width + 23];
      final rightBrightness = ((rightPixel >> 16) & 0xFF) + ((rightPixel >> 8) & 0xFF) + (rightPixel & 0xFF);

      expect(leftBrightness, greaterThan(origBrightness), reason: 'Left edge should receive specular highlight');
      expect(rightBrightness, lessThan(origBrightness), reason: 'Right edge should receive AO shadow');
    });

    test('bevelDepth determines inner extent of the bevel rim while leaving flat plateau intact', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Solid 20x20 block from (6, 6) to (25, 25)
      for (int y = 6; y <= 25; y++) {
        for (int x = 6; x <= 25; x++) {
          pixels[y * width + x] = 0xFF5588AA;
        }
      }

      final effect = SilhouetteDepthBevelEffect({
        'bevelDepth': 2.0, // Only 2px from edge
        'lightAngle': 180.0,
        'specularIntensity': 0.8,
        'ambientOcclusion': 0.8,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Deep interior pixel at (16, 16) has distance > 9px, so it must be exactly unchanged!
      expect(result[16 * width + 16], equals(pixels[16 * width + 16]),
          reason: 'Plateau center pixel beyond bevel depth must remain intact');
    });

    test('preserveAlpha strictly confines 3D bevel to layer pixels and keeps empty space transparent', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // 4x4 block in center
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          pixels[y * width + x] = 0xFFE04040;
        }
      }

      final effect = SilhouetteDepthBevelEffect({
        'bevelDepth': 3.0,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final origA = (pixels[y * width + x] >> 24) & 0xFF;
          final resA = (result[y * width + x] >> 24) & 0xFF;

          if (origA == 0) {
            expect(resA, equals(0), reason: 'Transparent canvas background at ($x, $y) must not be filled');
          } else {
            expect(resA, greaterThan(0));
          }
        }
      }
    });
  });
}
