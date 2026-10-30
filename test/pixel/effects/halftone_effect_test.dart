import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  // Horizontal gray ramp inside a rounded blob with a transparent corner.
  final source = Uint32List(w * h);
  for (var y = 2; y < 34; y++) {
    for (var x = 2; x < 46; x++) {
      final g = ((x - 2) * 255 ~/ 43).clamp(0, 255);
      source[y * w + x] = 0xFF000000 | (g << 16) | (g << 8) | g;
    }
  }

  int inkCount(Uint32List p, int x0, int x1) {
    var n = 0;
    for (var y = 2; y < 34; y++) {
      for (var x = x0; x < x1; x++) {
        if (p[y * w + x] != 0) n++;
      }
    }
    return n;
  }

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'halftone',
      'parameters': {'dotSize': 0.5, 'spacing': 0.5, 'angle': 0.0, 'style': 0},
    })!;
    expect(effect, isA<HalftoneEffect>());
    expect(effect.parameters['paperMode'], 0);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('dot coverage follows tone: dark side has more ink than light side', () {
    for (var style = 0; style <= 4; style++) {
      final out = HalftoneEffect({'style': style, 'keepOutlines': 0.0, 'dotSize': 0.8}).apply(source, w, h);
      expect(inkCount(out, 2, 14), greaterThan(inkCount(out, 34, 46)), reason: 'style $style');
    }
    final inverted = HalftoneEffect({'invert': true, 'keepOutlines': 0.0, 'dotSize': 0.8}).apply(source, w, h);
    expect(inkCount(inverted, 2, 14), lessThan(inkCount(inverted, 34, 46)));
  });

  test('dots are clipped to the silhouette and never fill the background', () {
    final out = HalftoneEffect({'paperMode': 1}).apply(source, w, h);
    for (var i = 0; i < out.length; i++) {
      expect(out[i] >>> 24, source[i] >>> 24);
    }
  });

  test('controls change the output', () {
    final base = HalftoneEffect().apply(source, w, h);
    for (final entry in <String, dynamic>{
      'dotSize': 0.9,
      'spacing': 0.0,
      'angle': 0.125,
      'style': 4,
      'inkMode': 1,
      'paperMode': 1,
      'invert': true,
    }.entries) {
      expect(HalftoneEffect({entry.key: entry.value}).apply(source, w, h), isNot(base), reason: entry.key);
    }
    final single = HalftoneEffect({'inkMode': 1, 'inkColor': 0xFFFF0000, 'keepOutlines': 0.0}).apply(source, w, h);
    expect(single.where((p) => p != 0).every((p) => (p & 0xFFFFFF) == 0xFF0000), isTrue);
  });

  test('keep outlines preserves dark lines; auto levels rescues flat art', () {
    final line = Uint32List.fromList(List.filled(w * h, 0xFFE0E0E0));
    for (var y = 0; y < h; y++) {
      line[y * w + 20] = 0xFF101010;
    }
    final kept = HalftoneEffect({'keepOutlines': 1.0, 'paperMode': 1}).apply(line, w, h);
    expect(kept[10 * w + 20], 0xFF101010);
    final flat = Uint32List.fromList(List.filled(w * h, 0xFF777777));
    expect(HalftoneEffect().apply(flat, w, h).toSet().length, greaterThan(1));
  });

  test('transparent, empty, and tiny inputs are safe', () {
    expect(HalftoneEffect().apply(Uint32List(0), 0, 0), isEmpty);
    expect(HalftoneEffect().apply(Uint32List(16), 4, 4), Uint32List(16));
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final out = HalftoneEffect({'spacing': double.nan, 'angle': double.infinity})
          .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(out.length, a * b);
    }
  });
}
