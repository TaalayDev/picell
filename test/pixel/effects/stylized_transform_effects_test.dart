import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source = Uint32List.fromList([
    for (var y = 0; y < 8; y++)
      for (var x = 0; x < 8; x++)
        x == 0 && y == 0
            ? 0
            : 0xff000000 | (x * 31 << 16) | (y * 31 << 8) | ((x + y) * 15),
  ]);

  group('stylized transform effects', () {
    final cases = <EffectType, Effect>{
      EffectType.kaleidoscope: KaleidoscopeEffect(),
      EffectType.topographicContours: TopographicContoursEffect(),
      EffectType.isometricExtrusion: IsometricExtrusionEffect(),
      EffectType.paperCutout: PaperCutoutEffect(),
      EffectType.celShading: CelShadingEffect(),
      EffectType.lowPolyFacets: LowPolyFacetsEffect(),
      EffectType.asciiMosaic: AsciiMosaicEffect(),
    };

    for (final entry in cases.entries) {
      test('${entry.key.name} renders deterministically and round-trips', () {
        final first = entry.value.apply(source, 8, 8);
        final second = entry.value.apply(source, 8, 8);
        expect(first, orderedEquals(second));
        expect(first, hasLength(source.length));

        final restored = EffectsManager.effectFromJson({
          'type': entry.key.name,
          'parameters': entry.value.getDefaultParameters(),
        });
        expect(restored?.runtimeType, entry.value.runtimeType);
      });
    }

    test('kaleidoscope animation changes with time', () {
      final first = KaleidoscopeEffect({
        ...KaleidoscopeEffect().getDefaultParameters(),
        'time': 0.0,
      }).apply(source, 8, 8);
      final later = KaleidoscopeEffect({
        ...KaleidoscopeEffect().getDefaultParameters(),
        'time': 0.4,
      }).apply(source, 8, 8);

      expect(first, isNot(orderedEquals(later)));
      expect(KaleidoscopeEffect().isAnimation, isTrue);
    });

    test('isometric extrusion creates depth outside the source silhouette', () {
      final sprite = Uint32List(25)..[6] = 0xffffffff;
      final output = IsometricExtrusionEffect({
        ...IsometricExtrusionEffect().getDefaultParameters(),
        'depth': 2,
      }).apply(sprite, 5, 5);

      expect(output[6], 0xffffffff);
      expect((output[12] >> 24) & 0xff, greaterThan(0));
    });

    test('ASCII monochrome mode uses only configured colors', () {
      final effect = AsciiMosaicEffect({
        ...AsciiMosaicEffect().getDefaultParameters(),
        'cellSize': 5,
        'colorize': false,
        'foregroundColor': 0xffffffff,
        'backgroundColor': 0xff000000,
        'preserveAlpha': false,
      });
      final output = effect.apply(source, 8, 8);

      expect(output.toSet().difference({0xffffffff, 0xff000000}), isEmpty);
    });

    test('static styles preserve transparent sprite pixels', () {
      for (final effect
          in cases.values.where((effect) => !effect.isAnimation)) {
        expect(effect.apply(source, 8, 8).first, 0);
      }
    });
  });
}
