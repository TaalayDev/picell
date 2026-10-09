import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

Uint32List _canvas(int w, int h, Map<(int, int), int> px) {
  final out = Uint32List(w * h);
  px.forEach((p, c) => out[p.$2 * w + p.$1] = c);
  return out;
}

Uint32List _block(int w, int h, int x0, int y0, int x1, int y1, int color) {
  final out = Uint32List(w * h);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      out[y * w + x] = color;
    }
  }
  return out;
}

int _lum(int c) => ((c >> 16) & 0xFF) + ((c >> 8) & 0xFF) + (c & 0xFF);

void main() {
  const w = 12;
  const h = 12;
  const base = 0xFF808080;

  group('SmartShadingEffect', () {
    final src = _block(w, h, 2, 2, 10, 10, base);
    Uint32List run(Map<String, dynamic> params) =>
        SmartShadingEffect({...SmartShadingEffect().getDefaultParameters(), ...params}).apply(src, w, h);

    test('is created by the manager', () {
      expect(EffectsManager.createEffect(EffectType.smartShading), isA<SmartShadingEffect>());
    });

    test('lights the edge facing the light and darkens the far edge', () {
      final out = run({'hueShift': 0.0});
      expect(_lum(out[2 * w + 3]), greaterThan(_lum(base)), reason: 'top edge lit');
      expect(_lum(out[9 * w + 8]), lessThan(_lum(base)), reason: 'bottom edge shaded');
      expect(out[5 * w + 5], base, reason: 'interior untouched');
    });

    test('never touches transparent pixels or alpha', () {
      final out = run({});
      for (var i = 0; i < src.length; i++) {
        expect(out[i] >> 24, src[i] >> 24);
      }
    });

    test('hue shift tints highlights warm and shadows cool', () {
      const green = 0xFF50A050;
      final colored = _block(w, h, 2, 2, 10, 10, green);
      final shifted = SmartShadingEffect({...SmartShadingEffect().getDefaultParameters(), 'hueShift': 40.0})
          .apply(colored, w, h);
      final lit = shifted[2 * w + 3];
      final shade = shifted[9 * w + 8];
      // The base has equal red and blue. Highlights drift toward yellow (red
      // over blue), shadows toward blue (blue over red).
      expect((lit >> 16) & 0xFF, greaterThan(lit & 0xFF));
      expect(shade & 0xFF, greaterThan((shade >> 16) & 0xFF));
    });

    test('bands=1 gives a single tone per side', () {
      final out = run({'bands': 1, 'depth': 3, 'hueShift': 0.0});
      expect(out[2 * w + 4], out[3 * w + 4]);
    });

    test('empty layer stays empty and input is untouched', () {
      expect(SmartShadingEffect().apply(Uint32List(w * h), w, h).every((p) => p == 0), isTrue);
      final copy = Uint32List.fromList(src);
      run({});
      expect(src, copy);
    });
  });

  group('SelectiveOutlineEffect', () {
    const red = 0xFFC83232;
    final src = _block(w, h, 4, 4, 8, 8, red);
    Uint32List run(Map<String, dynamic> params, [Uint32List? input]) =>
        SelectiveOutlineEffect({...SelectiveOutlineEffect().getDefaultParameters(), ...params})
            .apply(input ?? src, w, h);

    test('is created by the manager', () {
      expect(EffectsManager.createEffect(EffectType.selectiveOutline), isA<SelectiveOutlineEffect>());
    });

    test('outlines only transparent pixels and keeps the sprite intact', () {
      final out = run({});
      for (var i = 0; i < src.length; i++) {
        if (src[i] != 0) expect(out[i], src[i]);
      }
      expect(out[3 * w + 5], isNot(0));
      expect(out[0], 0);
      expect(out[3 * w + 3], 0, reason: 'diagonal corner skipped when rounded');
    });

    test('outline is a darker shade of the sprite color, not a flat color', () {
      final out = run({'lightBias': 0.0, 'saturation': 1.0});
      final o = out[3 * w + 5];
      expect(_lum(o), lessThan(_lum(red)));
      expect((o >> 16) & 0xFF, greaterThan(o & 0xFF), reason: 'still reddish');

      final twoColors = _block(w, h, 2, 4, 5, 8, 0xFFC83232);
      for (var y = 4; y < 8; y++) {
        for (var x = 6; x < 9; x++) {
          twoColors[y * w + x] = 0xFF3232C8;
        }
      }
      final out2 = run({'lightBias': 0.0, 'saturation': 1.0}, twoColors);
      final left = out2[3 * w + 3];
      final right = out2[3 * w + 7];
      expect((left >> 16) & 0xFF, greaterThan(left & 0xFF));
      expect(right & 0xFF, greaterThan((right >> 16) & 0xFF));
    });

    test('light bias makes the lit side lighter than the shaded side', () {
      final out = run({'lightBias': 0.8});
      final lit = out[3 * w + 5]; // above the block (light from top-left)
      final shaded = out[8 * w + 5]; // below it
      expect(_lum(lit), greaterThan(_lum(shaded)));
    });

    test('thickness grows the outline and square corners fill diagonals', () {
      final thin = run({'thickness': 1}).where((p) => p != 0).length;
      final thick = run({'thickness': 2}).where((p) => p != 0).length;
      expect(thick, greaterThan(thin));
      expect(run({'corners': 'square'})[3 * w + 3], isNot(0));
    });

    test('empty layer stays empty', () {
      expect(SelectiveOutlineEffect().apply(Uint32List(w * h), w, h).every((p) => p == 0), isTrue);
    });
  });

  group('AntiJaggiesEffect', () {
    const c = 0xFFFFFFFF;
    Uint32List run(Map<String, dynamic> params, Uint32List input) =>
        AntiJaggiesEffect({...AntiJaggiesEffect().getDefaultParameters(), ...params}).apply(input, w, h);

    test('is created by the manager', () {
      expect(EffectsManager.createEffect(EffectType.antiJaggies), isA<AntiJaggiesEffect>());
    });

    test('removes stray single pixels but keeps solid shapes', () {
      final input = _block(w, h, 3, 3, 7, 7, c);
      input[10 * w + 10] = c;
      final out = run({}, input);
      expect(out[10 * w + 10], 0);
      expect(out[4 * w + 4], c);
      expect(out[3 * w + 3], c);
    });

    test('fills pinholes with the surrounding colour', () {
      final input = _block(w, h, 3, 3, 8, 8, c);
      input[5 * w + 5] = 0;
      expect(run({}, input)[5 * w + 5], c);
      expect(run({'fillPinholes': false}, input)[5 * w + 5], 0);
    });

    test('pixel-perfect removes the redundant corner of a staircase line', () {
      // (1,1) (2,1) (2,2) (3,2) -- the L corners at (2,1) and (2,2) double up.
      final input = _canvas(w, h, {(1, 1): c, (2, 1): c, (2, 2): c, (3, 2): c});
      final out = run({'removeOrphans': false}, input);
      final remaining = out.where((p) => p != 0).length;
      expect(remaining, 3);
      expect(out[1 * w + 2], 0);
      // The line must stay connected end to end (8-connectivity).
      expect(out[1 * w + 1], c);
      expect(out[2 * w + 3], c);
      expect(run({'removeOrphans': false, 'pixelPerfect': false}, input), input);
    });

    test('a straight one-pixel line is unchanged', () {
      final line = _canvas(w, h, {for (var x = 2; x < 9; x++) (x, 5): c});
      expect(run({}, line), line);
    });

    test('empty layer stays empty', () {
      expect(run({}, Uint32List(w * h)).every((p) => p == 0), isTrue);
    });
  });
}
