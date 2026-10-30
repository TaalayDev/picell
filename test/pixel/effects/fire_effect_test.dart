import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 48;
  // A stone block in the lower middle of an otherwise empty canvas.
  final source = Uint32List(w * h);
  for (var y = 30; y < 44; y++) {
    for (var x = 14; x < 34; x++) {
      source[y * w + x] = 0xFF707070;
    }
  }

  int visible(Uint32List p, bool Function(int x, int y) where) {
    var n = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (where(x, y) && (p[y * w + x] >>> 24) != 0) n++;
      }
    }
    return n;
  }

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'fire',
      'parameters': {'intensity': 0.8, 'flare': 0.6, 'ash': 0.4, 'smoke': 0.5, 'flameHeight': 0.7, 'time': 0.0, 'animated': true},
    })!;
    expect(effect, isA<FireEffect>());
    expect(effect.parameters['embers'], 0.4);
    expect(effect.isSeamlessLoop, isTrue);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('flames rise from the artwork into the empty space above it', () {
    final out = FireEffect({'source': 0}).apply(source, w, h);
    expect(visible(out, (x, y) => y < 30 && x >= 12 && x < 36), greaterThan(40));
    // Nothing burns far from the fuel (the empty bottom-left corner is only haloed, not flamed).
    expect(visible(out, (x, y) => y < 10 && x < 4), 0);
  });

  test('the artwork keeps its alpha and is lit by the fire', () {
    final out = FireEffect({'glow': 1.0}).apply(source, w, h);
    for (var i = 0; i < out.length; i++) {
      if (source[i] != 0) expect(out[i] >>> 24, 255);
    }
    expect(out[30 * w + 24], isNot(source[30 * w + 24]));
    final dark = FireEffect({'glow': 0.0, 'embers': 0.0}).apply(source, w, h);
    expect(dark[40 * w + 24], source[40 * w + 24]);
  });

  test('ground fire burns from the bottom of the canvas, not from the sprite', () {
    final empty = Uint32List(w * h);
    expect(visible(FireEffect({'source': 0}).apply(empty, w, h), (x, y) => true), 0);
    expect(visible(FireEffect({'source': 1}).apply(empty, w, h), (x, y) => y > 30), greaterThan(60));
  });

  test('animation is a seamless loop and actually moves', () {
    final a = FireEffect({'time': 0.0}).apply(source, w, h);
    expect(FireEffect({'time': 1.0}).apply(source, w, h), a);
    expect(FireEffect({'time': 0.25}).apply(source, w, h), isNot(a));
    expect(FireEffect({'time': 0.7, 'animated': false}).apply(source, w, h), a);
    for (final speed in [2, 3]) {
      final s = FireEffect({'speed': speed, 'time': 0.0}).apply(source, w, h);
      expect(FireEffect({'speed': speed, 'time': 1.0}).apply(source, w, h), s);
    }
  });

  test('controls change the output', () {
    final base = FireEffect().apply(source, w, h);
    for (final entry in <String, dynamic>{
      'intensity': 0.4,
      'flameHeight': 1.0,
      'flameWidth': 1.0,
      'flare': 0.0,
      'ash': 1.0,
      'smoke': 0.0,
      'embers': 1.0,
      'glow': 0.0,
      'wind': 0.8,
      'palette': 1,
      'bands': 3,
      'seed': 7,
    }.entries) {
      expect(FireEffect({entry.key: entry.value}).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('wind leans the flames', () {
    double centroid(Uint32List p) {
      var sum = 0.0, n = 0;
      for (var y = 0; y < 26; y++) {
        for (var x = 0; x < w; x++) {
          if ((p[y * w + x] >>> 24) != 0) {
            sum += x;
            n++;
          }
        }
      }
      return sum / n;
    }

    final right = FireEffect({'wind': 1.0, 'smoke': 0.0, 'embers': 0.0, 'glow': 0.0}).apply(source, w, h);
    final left = FireEffect({'wind': -1.0, 'smoke': 0.0, 'embers': 0.0, 'glow': 0.0}).apply(source, w, h);
    expect(centroid(right), greaterThan(centroid(left)));
  });

  test('zero intensity, empty, and tiny inputs are safe', () {
    expect(FireEffect({'intensity': 0.0}).apply(source, w, h), source);
    expect(FireEffect().apply(Uint32List(0), 0, 0), isEmpty);
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      for (final src in [0, 1]) {
        final out = FireEffect({'source': src, 'flameHeight': double.nan, 'time': double.infinity})
            .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
        expect(out.length, a * b);
      }
    }
  });
}
