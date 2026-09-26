import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DirectionalLightRampEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = DirectionalLightRampEffect();
      expect(effect.type, equals(EffectType.directionalLightRamp));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['lightAngle'], equals(270.0));
      expect(effect.parameters['primaryLightColor'], equals(0xFFFFE082));
      expect(effect.parameters['secondaryLightColor'], equals(0xFFFF3D00));
      expect(effect.parameters['rampSpread'], equals(1.0));
      expect(effect.parameters['rampOffset'], equals(0.0));
      expect(effect.parameters['lightingBlend'], equals('overlay'));
      expect(effect.parameters['intensity'], equals(0.75));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DirectionalLightRampEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'lightAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'primaryLightColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'secondaryLightColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'rampSpread' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'rampOffset' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lightingBlend' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'intensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DirectionalLightRampEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.directionalLightRamp,
        {
          'lightAngle': 90.0,
          'primaryLightColor': 0xFF00FF00,
          'intensity': 0.9,
        },
      );
      expect(effect, isA<DirectionalLightRampEffect>());
      expect(effect.parameters['lightAngle'], equals(90.0));
      expect(effect.parameters['primaryLightColor'], equals(0xFF00FF00));
      expect(effect.parameters['intensity'], equals(0.9));
    });

    test('applies directional lighting gradient from primary light side to secondary light side', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Solid neutral grey canvas
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF808080;
      }

      // Vertical ramp: lightAngle = 90° (dirY = 1, dirX = 0).
      // Max projection at bottom (y = 31), min at top (y = 0).
      // Primary light color (Pure Green) at max projection (bottom),
      // Secondary light color (Pure Red) at min projection (top).
      final effect = DirectionalLightRampEffect({
        'lightAngle': 90.0,
        'primaryLightColor': 0xFF00FF00, // Green at bottom
        'secondaryLightColor': 0xFFFF0000, // Red at top
        'rampSpread': 1.0,
        'rampOffset': 0.0,
        'lightingBlend': 'overlay',
        'intensity': 1.0,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      final topPixel = result[0 * width + 16];
      final bottomPixel = result[(height - 1) * width + 16];

      final topR = (topPixel >> 16) & 0xFF;
      final topG = (topPixel >> 8) & 0xFF;

      final bottomR = (bottomPixel >> 16) & 0xFF;
      final bottomG = (bottomPixel >> 8) & 0xFF;

      // Top should have more red than green
      expect(topR, greaterThan(topG));
      // Bottom should have more green than red
      expect(bottomG, greaterThan(bottomR));
    });

    test('preserveAlpha strictly confines lighting to layer pixels and keeps empty space transparent', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // 4x4 block in center
      for (int y = 6; y < 10; y++) {
        for (int x = 6; x < 10; x++) {
          pixels[y * width + x] = 0xFF808080;
        }
      }

      final effect = DirectionalLightRampEffect({
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
