import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RisographPrintEffect', () {
    test('exposes editable print controls and factory serialization', () {
      final effect = RisographPrintEffect();

      expect(effect.type, EffectType.risographPrint);
      expect(effect.parameters['inkCount'], 2);
      expect(effect.getFields(), hasLength(7));
      expect(effect.getFields().whereType<ColorField>(), hasLength(1));

      final restored = EffectsManager.effectFromJson({
        'type': 'risographPrint',
        'parameters': {'palette': 2, 'grain': 0.4},
      });
      expect(restored, isA<RisographPrintEffect>());
      expect(restored?.parameters['palette'], 2);
    });

    test('is deterministic and preserves transparent sprite pixels', () {
      final pixels = Uint32List.fromList([
        0x00000000,
        0xffff0000,
        0xff00ff00,
        0xff0000ff,
      ]);
      final effect = RisographPrintEffect();

      final first = effect.apply(pixels, 2, 2);
      final second = effect.apply(pixels, 2, 2);

      expect(first, orderedEquals(second));
      expect(first.first, 0);
      expect(first.skip(1), isNot(orderedEquals(pixels.skip(1))));
    });
  });

  group('PixelSortingEffect', () {
    test('sorts selected brightness bands horizontally', () {
      final pixels = Uint32List.fromList([
        0xffcccccc,
        0xff222222,
        0xff888888,
        0xffffffff,
      ]);
      final effect = PixelSortingEffect({
        'direction': 'horizontal',
        'metric': 'brightness',
        'lowerThreshold': 0.0,
        'upperThreshold': 1.0,
        'maxSpan': 16,
        'descending': false,
      });

      final output = effect.apply(pixels, 4, 1);

      expect(output, orderedEquals([
        0xff222222,
        0xff888888,
        0xffcccccc,
        0xffffffff,
      ]));
    });

    test('sorts vertically and leaves transparent breaks in place', () {
      final pixels = Uint32List.fromList([
        0xffeeeeee,
        0xffaaaaaa,
        0x00000000,
        0xff111111,
        0xffdddddd,
        0xff333333,
      ]);
      final effect = PixelSortingEffect({
        'direction': 'vertical',
        'metric': 'brightness',
        'lowerThreshold': 0.0,
        'upperThreshold': 1.0,
        'maxSpan': 16,
        'descending': false,
      });

      final output = effect.apply(pixels, 2, 3);

      expect(output[2], 0);
      expect(output[0], 0xffeeeeee);
      expect(output[4], 0xffdddddd);
      expect(output[1], 0xff111111);
      expect(output[3], 0xff333333);
      expect(output[5], 0xffaaaaaa);
    });
  });

  group('InkCrosshatchEffect', () {
    test('draws dark ink around a hard tonal edge', () {
      final pixels = Uint32List.fromList([
        0xffffffff,
        0xffffffff,
        0xff000000,
        0xff000000,
        0xffffffff,
        0xffffffff,
        0xff000000,
        0xff000000,
        0xffffffff,
        0xffffffff,
        0xff000000,
        0xff000000,
      ]);
      final effect = InkCrosshatchEffect({
        'edgeThreshold': 0.05,
        'hatchSpacing': 12,
        'hatchStrength': 0.0,
        'angle': 45.0,
        'crosshatch': false,
        'colorWash': 0.0,
        'inkColor': 0xff000000,
        'paperColor': 0xffffffff,
        'preserveAlpha': true,
      });

      final output = effect.apply(pixels, 4, 3);

      final edgePixel = output[1];
      final edgeRed = (edgePixel >> 16) & 0xff;
      expect(edgeRed, lessThan(128));
      expect(output[0], 0xffffffff);
    });

    test('preserves transparency', () {
      final pixels = Uint32List.fromList([0, 0xff404040]);
      final output = InkCrosshatchEffect().apply(pixels, 2, 1);

      expect(output.first, 0);
      expect((output.last >> 24) & 0xff, 255);
    });
  });
}
