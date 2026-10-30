import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  // Two colour fields (red | blue) inside a transparent border, with noise.
  final source = Uint32List(w * h);
  for (var y = 4; y < 32; y++) {
    for (var x = 4; x < 44; x++) {
      final n = (x * 7 + y * 13) % 9;
      source[y * w + x] = x < 24 ? (0xFF000000 | ((180 + n) << 16) | (60 << 8) | 50) : (0xFF000000 | (50 << 16) | (90 << 8) | (190 + n));
    }
  }

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'watercolor',
      'parameters': {'intensity': 0.5, 'spread': 0.3, 'texture': 0.2},
    })!;
    expect(effect, isA<WatercolorEffect>());
    expect(effect.parameters['dilution'], 0.15);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('alpha is preserved by default and input is not mutated', () {
    final copy = Uint32List.fromList(source);
    final out = WatercolorEffect().apply(source, w, h);
    expect(source, copy);
    for (var i = 0; i < out.length; i++) {
      expect(out[i] >>> 24, source[i] >>> 24);
    }
    expect(WatercolorEffect({'intensity': 0.0}).apply(source, w, h), source);
  });

  test('controls change the output', () {
    final base = WatercolorEffect().apply(source, w, h);
    for (final entry in <String, dynamic>{
      'intensity': 1.0,
      'spread': 0.9,
      'texture': 0.9,
      'dilution': 0.7,
      'edgeDarkening': 1.0,
      'blooms': 0.9,
      'variation': 0.9,
      'paperColor': 0xFFFFD0D0,
      'seed': 7,
    }.entries) {
      expect(WatercolorEffect({entry.key: entry.value}).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('diffusion smooths noise within a wash but keeps the colour boundary', () {
    final out = WatercolorEffect({
      'intensity': 1.0, 'spread': 0.8, 'texture': 0.0, 'dilution': 0.0, 'edgeDarkening': 0.0, 'blooms': 0.0, 'variation': 0.0,
    }).apply(source, w, h);
    int blueSpread(Uint32List p, int x0, int x1) {
      var lo = 255, hi = 0;
      for (var y = 10; y < 26; y++) {
        for (var x = x0; x < x1; x++) {
          final v = p[y * w + x] & 0xFF;
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
      }
      return hi - lo;
    }

    expect(blueSpread(out, 30, 40), lessThan(blueSpread(source, 30, 40)));
    // Left stays red, right stays blue: no cross-boundary mixing into purple.
    expect((out[18 * w + 10] >> 16) & 0xFF, greaterThan(out[18 * w + 10] & 0xFF));
    expect(out[18 * w + 38] & 0xFF, greaterThan((out[18 * w + 38] >> 16) & 0xFF));
  });

  test('silhouette pooling darkens the rim', () {
    final flat = Uint32List(w * h);
    for (var y = 4; y < 32; y++) {
      for (var x = 4; x < 44; x++) {
        flat[y * w + x] = 0xFF909090;
      }
    }
    final off = WatercolorEffect({'edgeDarkening': 0.0, 'texture': 0.0, 'blooms': 0.0, 'variation': 0.0, 'dilution': 0.0, 'intensity': 1.0}).apply(flat, w, h);
    final on = WatercolorEffect({'edgeDarkening': 1.0, 'texture': 0.0, 'blooms': 0.0, 'variation': 0.0, 'dilution': 0.0, 'intensity': 1.0}).apply(flat, w, h);
    expect(on[4 * w + 20] & 0xFF, lessThan(off[4 * w + 20] & 0xFF));
    expect(on[18 * w + 24], off[18 * w + 24]);
  });

  test('keep lines preserves dark outlines', () {
    final line = Uint32List.fromList(source);
    for (var y = 4; y < 32; y++) {
      line[y * w + 14] = 0xFF101010;
    }
    final kept = WatercolorEffect({'keepLines': 1.0, 'intensity': 1.0}).apply(line, w, h);
    expect(kept[18 * w + 14], 0xFF101010);
    expect(WatercolorEffect({'keepLines': 0.0, 'intensity': 1.0}).apply(line, w, h)[18 * w + 14], isNot(0xFF101010));
  });

  test('edge bleed adds faint pigment just outside the silhouette only', () {
    final out = WatercolorEffect({'edgeBleed': 1.0}).apply(source, w, h);
    var bled = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (source[i] == 0 && out[i] != 0) {
          bled++;
          expect(out[i] >>> 24, lessThan(255));
          expect(x >= 1 && x <= 46 && y >= 1 && y <= 34, isTrue);
        }
      }
    }
    expect(bled, greaterThan(0));
    expect(out[0], 0);
  });

  test('empty and tiny inputs are safe', () {
    expect(WatercolorEffect().apply(Uint32List(0), 0, 0), isEmpty);
    expect(WatercolorEffect().apply(Uint32List(16), 4, 4), Uint32List(16));
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final out = WatercolorEffect({'spread': double.nan, 'texture': double.infinity})
          .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(out.length, a * b);
    }
  });
}
