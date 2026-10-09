import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  group('ColorShiftEffect', () {
    test('instantiates with defaults and factory deserialization works', () {
      final effect = EffectsManager.createEffect(EffectType.colorShift);
      expect(effect, isA<ColorShiftEffect>());
      expect(effect.type, EffectType.colorShift);
      expect(effect.isSeamlessLoop, isTrue);
      expect(effect.preferredFrameCount, 16);

      final jsonEffect = EffectsManager.effectFromJson({
        'type': 'colorShift',
        'parameters': effect.parameters,
      });
      expect(jsonEffect, isA<ColorShiftEffect>());
    });

    test('getFields returns complete UIField list', () {
      final effect = ColorShiftEffect();
      final fields = effect.getFields();
      expect(fields.any((f) => f.key == 'shiftMode'), isTrue);
      expect(fields.any((f) => f.key == 'hueShift'), isTrue);
      expect(fields.any((f) => f.key == 'saturation'), isTrue);
      expect(fields.any((f) => f.key == 'brightness'), isTrue);
      expect(fields.any((f) => f.key == 'channelSplit'), isTrue);
      expect(fields.any((f) => f.key == 'tintColor'), isTrue);
      expect(fields.any((f) => f.key == 'tintAmount'), isTrue);
      expect(fields.any((f) => f.key == 'waveDirection'), isTrue);
      expect(fields.any((f) => f.key == 'waveFrequency'), isTrue);
      expect(fields.any((f) => f.key == 'paletteSteps'), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha'), isTrue);
    });

    test('preserves transparent pixels when preserveAlpha is true', () {
      const width = 4;
      const height = 4;
      final empty = Uint32List(width * height);
      final effect = ColorShiftEffect({'preserveAlpha': true});
      final output = effect.apply(empty, width, height);
      expect(output.every((pixel) => pixel == 0), isTrue);
    });

    test('rotates red hue towards green with 120° shift and blue with 240° shift', () {
      const width = 1;
      const height = 1;
      final redPixel = Uint32List.fromList([0xFFFF0000]); // Pure Red

      // 120 degrees shift: Red (0°) -> Green (120°)
      final greenShift = ColorShiftEffect({'shiftMode': 'full', 'hueShift': 120.0});
      final greenOutput = greenShift.apply(redPixel, width, height);
      final greenG = (greenOutput[0] >> 8) & 0xFF;
      final greenR = (greenOutput[0] >> 16) & 0xFF;
      expect(greenG, greaterThan(200));
      expect(greenR, lessThan(50));

      // 240 degrees shift: Red (0°) -> Blue (240°)
      final blueShift = ColorShiftEffect({'shiftMode': 'full', 'hueShift': 240.0});
      final blueOutput = blueShift.apply(redPixel, width, height);
      final blueB = blueOutput[0] & 0xFF;
      final blueR = (blueOutput[0] >> 16) & 0xFF;
      expect(blueB, greaterThan(200));
      expect(blueR, lessThan(50));
    });

    test('cycle mode rotates hues as time advances', () {
      const width = 2;
      const height = 2;
      final pixels = Uint32List(4)..fillRange(0, 4, 0xFFFF0000);

      final t0 = ColorShiftEffect({'shiftMode': 'cycle', 'time': 0.0}).apply(pixels, width, height);
      final tHalf = ColorShiftEffect({'shiftMode': 'cycle', 'time': 0.5}).apply(pixels, width, height);

      expect(t0, isNot(orderedEquals(tHalf)));
    });

    test('wave mode creates position-dependent color gradient', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height)..fillRange(0, width * height, 0xFFFF0000);

      final effect = ColorShiftEffect({
        'shiftMode': 'wave',
        'waveDirection': 'vertical',
        'waveFrequency': 0.5,
      });
      final output = effect.apply(pixels, width, height);

      // Top row vs bottom row should have distinct hues (half-cycle difference)
      final topPixel = output[0];
      final bottomPixel = output[(height - 1) * width];
      expect(topPixel, isNot(equals(bottomPixel)));
    });

    test('channelSplit displaces color channels laterally', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);
      // Single white pixel at center
      pixels[4 * width + 4] = 0xFFFFFFFF;

      final effect = ColorShiftEffect({
        'shiftMode': 'channelSplit',
        'channelSplit': 2.0,
        'preserveAlpha': false,
      });
      final output = effect.apply(pixels, width, height);

      // One offset pixel gets blue channel, the other gets red channel
      final leftIdx = 4 * width + 2;
      final rightIdx = 4 * width + 6;
      final leftB = output[leftIdx] & 0xFF;
      final rightR = (output[rightIdx] >> 16) & 0xFF;
      expect(leftB, greaterThan(0));
      expect(rightR, greaterThan(0));
    });

    test('tint mode harmonizes colors towards tint target', () {
      const width = 2;
      const height = 2;
      final pixels = Uint32List(4)..fillRange(0, 4, 0xFF00FF00); // Green

      final effect = ColorShiftEffect({
        'shiftMode': 'tint',
        'tintColor': 0xFFFF4081, // Pink / Magenta
        'tintAmount': 0.8,
      });
      final output = effect.apply(pixels, width, height);

      // Output should have significant red component from the magenta tint
      final outR = (output[0] >> 16) & 0xFF;
      expect(outR, greaterThan(150));
    });
  });
}
