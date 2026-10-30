import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  // Red | blue fields inside a transparent border, with per-pixel noise.
  final source = Uint32List(w * h);
  for (var y = 4; y < 32; y++) {
    for (var x = 4; x < 44; x++) {
      final n = (x * 7 + y * 13) % 17;
      source[y * w + x] = x < 24 ? (0xFF000000 | ((170 + n) << 16) | (50 << 8) | 50) : (0xFF000000 | (50 << 16) | (80 << 8) | (170 + n));
    }
  }

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'oilPaint',
      'parameters': {'brushSize': 0.5, 'detail': 0.6, 'textureAmount': 0.7, 'colorBlending': 0.5, 'strokeDirection': 0.5},
    })!;
    expect(effect, isA<OilPaintEffect>());
    expect(effect.parameters['followForm'], 0.7);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('alpha is preserved, transparent pixels stay empty, input is not mutated', () {
    final copy = Uint32List.fromList(source);
    final out = OilPaintEffect().apply(source, w, h);
    expect(source, copy);
    for (var i = 0; i < out.length; i++) {
      expect(out[i] >>> 24, source[i] >>> 24);
      if (source[i] == 0) expect(out[i], 0);
    }
  });

  test('controls change the output', () {
    final base = OilPaintEffect().apply(source, w, h);
    for (final entry in <String, dynamic>{
      'brushSize': 0.9,
      'detail': 0.1,
      'textureAmount': 0.1,
      'colorBlending': 0.0,
      'strokeDirection': 0.25,
      'gloss': 1.0,
      'lightDirection': 45.0,
      'seed': 9,
    }.entries) {
      expect(OilPaintEffect({entry.key: entry.value}).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('strokes flatten pixel noise into dabs of colour', () {
    final out = OilPaintEffect({'detail': 0.0, 'textureAmount': 0.0, 'colorBlending': 0.0, 'brushSize': 0.7}).apply(source, w, h);
    expect(out.toSet().length, lessThan(source.toSet().length ~/ 2 + 40));
  });

  test('strokes respect colour edges', () {
    final out = OilPaintEffect({'brushSize': 0.8, 'detail': 0.8, 'colorBlending': 0.0, 'textureAmount': 0.0}).apply(source, w, h);
    for (var y = 6; y < 30; y++) {
      for (var x = 6; x < 22; x++) {
        final p = out[y * w + x];
        expect((p >> 16) & 0xFF, greaterThan(p & 0xFF), reason: 'red side $x,$y');
      }
      for (var x = 26; x < 42; x++) {
        final p = out[y * w + x];
        expect(p & 0xFF, greaterThan((p >> 16) & 0xFF), reason: 'blue side $x,$y');
      }
    }
  });

  test('strokes follow the form: bristles run along a vertical bar', () {
    final bar = Uint32List(w * h);
    for (var y = 2; y < 34; y++) {
      for (var x = 17; x < 31; x++) {
        bar[y * w + x] = 0xFF808080;
      }
    }
    final out = OilPaintEffect({'followForm': 1.0, 'textureAmount': 1.0, 'detail': 0.2, 'colorBlending': 0.0, 'strokeDirection': 0.0}).apply(bar, w, h);
    var vertical = 0, horizontal = 0;
    for (var y = 10; y < 26; y++) {
      for (var x = 20; x < 28; x++) {
        vertical += ((out[y * w + x] & 0xFF) - (out[(y + 1) * w + x] & 0xFF)).abs();
        horizontal += ((out[y * w + x] & 0xFF) - (out[y * w + x + 1] & 0xFF)).abs();
      }
    }
    expect(vertical, lessThan(horizontal));
    final locked = OilPaintEffect({'followForm': 0.0, 'textureAmount': 1.0, 'detail': 0.2, 'colorBlending': 0.0, 'strokeDirection': 0.0}).apply(bar, w, h);
    expect(locked, isNot(out));
  });

  test('empty and tiny inputs are safe', () {
    expect(OilPaintEffect().apply(Uint32List(0), 0, 0), isEmpty);
    expect(OilPaintEffect().apply(Uint32List(16), 4, 4), Uint32List(16));
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final out = OilPaintEffect({'brushSize': double.nan, 'detail': double.infinity})
          .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(out.length, a * b);
    }
  });
}
