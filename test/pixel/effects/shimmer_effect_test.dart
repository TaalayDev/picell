import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  group('ShimmerEffect', () {
    test('instantiates with defaults and factory deserialization works', () {
      final effect = EffectsManager.createEffect(EffectType.shimmer);
      expect(effect, isA<ShimmerEffect>());
      expect(effect.type, EffectType.shimmer);
      expect(effect.isSeamlessLoop, isTrue);
      expect(effect.preferredFrameCount, 16);

      final jsonEffect = EffectsManager.effectFromJson({
        'type': 'shimmer',
        'parameters': effect.parameters,
      });
      expect(jsonEffect, isA<ShimmerEffect>());
    });

    test('getFields returns complete UIField list', () {
      final effect = ShimmerEffect();
      final fields = effect.getFields();
      expect(fields.any((f) => f.key == 'shimmerColor'), isTrue);
      expect(fields.any((f) => f.key == 'intensity'), isTrue);
      expect(fields.any((f) => f.key == 'width'), isTrue);
      expect(fields.any((f) => f.key == 'angle'), isTrue);
      expect(fields.any((f) => f.key == 'mode'), isTrue);
      expect(fields.any((f) => f.key == 'sparkles'), isTrue);
      expect(fields.any((f) => f.key == 'holdDuration'), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha'), isTrue);
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 8;
      const height = 8;
      final empty = Uint32List(width * height);
      final effect = ShimmerEffect({'time': 0.3, 'preserveAlpha': true});
      final output = effect.apply(empty, width, height);
      expect(output.every((pixel) => pixel == 0), isTrue);
    });

    test('sweeps specular highlight across sprite as time advances', () {
      const width = 16;
      const height = 16;
      final sprite = Uint32List(width * height);
      // Fill central 8x8 block with solid blue
      for (int y = 4; y < 12; y++) {
        for (int x = 4; x < 12; x++) {
          sprite[y * width + x] = 0xFF000080;
        }
      }

      final effect1 = ShimmerEffect({
        'time': 0.0,
        'holdDuration': 0.0,
        'width': 4.0,
        'angle': 45.0,
        'mode': 'specular',
        'sparkles': false,
      });
      final output1 = effect1.apply(sprite, width, height);

      final effect2 = ShimmerEffect({
        'time': 0.5,
        'holdDuration': 0.0,
        'width': 4.0,
        'angle': 45.0,
        'mode': 'specular',
        'sparkles': false,
      });
      final output2 = effect2.apply(sprite, width, height);

      // Pixels should differ as wave sweeps from top-left to bottom-right
      expect(output1, isNot(orderedEquals(output2)));

      // Sheen increases brightness of affected pixels
      final centerIdx = 8 * width + 8;
      expect((output2[centerIdx] >> 16) & 0xFF, greaterThan((sprite[centerIdx] >> 16) & 0xFF));
    });

    test('rainbow mode produces prismatic chromatic shifting', () {
      const width = 16;
      const height = 16;
      final sprite = Uint32List(width * height);
      for (int i = 0; i < width * height; i++) {
        sprite[i] = 0xFF808080; // Gray
      }

      final effect = ShimmerEffect({
        'time': 0.5,
        'holdDuration': 0.0,
        'mode': 'rainbow',
        'intensity': 1.0,
        'width': 6.0,
        'sparkles': false,
      });

      final output = effect.apply(sprite, width, height);
      // Verify that color channels diverge (not just pure monochrome)
      bool hasRainbowChromaticity = false;
      for (final p in output) {
        final r = (p >> 16) & 0xFF;
        final g = (p >> 8) & 0xFF;
        final b = p & 0xFF;
        if (r != g || g != b) {
          hasRainbowChromaticity = true;
          break;
        }
      }
      expect(hasRainbowChromaticity, isTrue);
    });
  });
}
