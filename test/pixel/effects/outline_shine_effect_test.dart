import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 7;
  const h = 7;
  const red = 0xFFC83232;

  // 3x3 red square centered in a 7x7 transparent canvas.
  Uint32List square() {
    final px = Uint32List(w * h);
    for (var y = 2; y <= 4; y++) {
      for (var x = 2; x <= 4; x++) {
        px[y * w + x] = red;
      }
    }
    return px;
  }

  Uint32List run(Map<String, dynamic> params, [Uint32List? src]) =>
      OutlineShineEffect({...OutlineShineEffect().getDefaultParameters(), ...params})
          .apply(src ?? square(), w, h);

  group('OutlineShineEffect', () {
    test('is created by the manager', () {
      expect(EffectsManager.createEffect(EffectType.outlineShine), isA<OutlineShineEffect>());
    });

    test('outline only fills transparent pixels next to the sprite', () {
      final src = square();
      final out = run({'shineEnabled': false});

      expect(out[1 * w + 3], 0xFF000000); // above the square
      expect(out[3 * w + 5], 0xFF000000); // right of the square
      expect(out[0], 0); // far corner untouched
      expect(out[1 * w + 1], 0); // diagonal corner skipped (rounded)
      for (var i = 0; i < src.length; i++) {
        if (src[i] != 0) expect(out[i], src[i], reason: 'sprite pixel $i must not change');
      }
    });

    test('square corners include diagonals', () {
      final out = run({'shineEnabled': false, 'outlineCorners': 'square'});
      expect(out[1 * w + 1], 0xFF000000);
    });

    test('uses the configured outline color and thickness', () {
      final out = run({'shineEnabled': false, 'outlineColor': 0xFF00FF00, 'outlineThickness': 2});
      expect(out[0 * w + 3], 0xFF00FF00);
    });

    test('does not outline between touching opaque pixels', () {
      final px = Uint32List(w * h)..fillRange(0, w * h, red);
      expect(run({'shineEnabled': false}, px), px);
    });

    test('auto shine lightens light-facing edges only', () {
      final out = run({'outlineEnabled': false});
      final topLeft = out[2 * w + 2];
      final center = out[3 * w + 3];
      final bottomRight = out[4 * w + 4];

      expect((topLeft >> 16) & 0xFF, greaterThan((red >> 16) & 0xFF));
      expect(bottomRight, red); // faces away from the top-left light
      // Falloff: deeper pixels get less shine than the edge pixel.
      expect((center >> 16) & 0xFF, lessThan((topLeft >> 16) & 0xFF));
      expect(topLeft >> 24, 0xFF);
    });

    test('fixed shine color is used when auto is off', () {
      final out = run({
        'outlineEnabled': false,
        'autoShineColor': false,
        'shineColor': 0xFF0000FF,
        'shineIntensity': 1.0,
      });
      expect(out[2 * w + 2] & 0xFF, greaterThan(0x32));
    });

    int red8(int px) => (px >> 16) & 0xFF;

    test('flat style gives every shined pixel the same strength', () {
      final out = run({'outlineEnabled': false, 'shineStyle': 'flat', 'shineDepth': 3});
      final edge = out[2 * w + 3];
      final deeper = out[3 * w + 3];
      expect(red8(deeper), red8(edge));
      expect(red8(edge), greaterThan(red8(red)));
    });

    test('bold style has a brighter rim than inner band', () {
      final out = run({'outlineEnabled': false, 'shineStyle': 'bold', 'shineDepth': 3});
      expect(red8(out[2 * w + 3]), greaterThan(red8(out[3 * w + 3])));
      expect(red8(out[3 * w + 3]), greaterThan(red8(red)));
    });

    test('gloss style lights a streak, not the edge ring', () {
      final big = Uint32List(w * h)..fillRange(0, w * h, red);
      final out = run({
        'outlineEnabled': false,
        'shineStyle': 'gloss',
        'glossPosition': 0.5,
        'glossWidth': 1,
      }, big);
      final lit = [for (var i = 0; i < out.length; i++) if (out[i] != red) i];
      expect(lit, isNotEmpty);
      expect(lit.length, lessThan(out.length ~/ 2));
    });

    test('empty layer stays empty', () {
      expect(run({}, Uint32List(w * h)).every((p) => p == 0), isTrue);
    });

    test('does not mutate the input', () {
      final src = square();
      final copy = Uint32List.fromList(src);
      run({});
      expect(src, copy);
    });

    test('survives JSON round trip', () {
      final effect = EffectsManager.effectFromJson({
        'type': 'outlineShine',
        'parameters': OutlineShineEffect().parameters,
      });
      expect(effect, isA<OutlineShineEffect>());
    });
  });
}
