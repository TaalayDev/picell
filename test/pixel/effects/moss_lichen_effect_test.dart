import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  Uint32List slab() {
    final p = Uint32List(w * h);
    for (var y = 4; y < 32; y++) {
      for (var x = 4; x < 44; x++) {
        p[y * w + x] = 0xFF8A8A8A;
      }
    }
    return p;
  }

  final source = slab();

  int changed(Uint32List out, [Uint32List? base, bool Function(int x, int y)? where]) {
    final b = base ?? source;
    var n = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if ((where?.call(x, y) ?? true) && out[y * w + x] != b[y * w + x]) n++;
      }
    }
    return n;
  }

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'mossLichen',
      'parameters': {'coverage': 0.42, 'scale': 10, 'edgeGrowth': 0.6, 'lichenMix': 0.38},
    })!;
    expect(effect, isA<MossLichenEffect>());
    expect(effect.parameters['gravity'], 0.5);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('coverage grows monotonically and zero coverage changes nothing', () {
    expect(MossLichenEffect({'coverage': 0.0}).apply(source, w, h), source);
    var previous = -1;
    for (final coverage in [0.15, 0.4, 0.7, 1.0]) {
      final n = changed(MossLichenEffect({'coverage': coverage}).apply(source, w, h));
      expect(n, greaterThan(previous), reason: 'coverage $coverage');
      previous = n;
    }
  });

  test('moss keeps alpha and stays inside the silhouette', () {
    final out = MossLichenEffect({'coverage': 1.0}).apply(source, w, h);
    for (var i = 0; i < out.length; i++) {
      expect(out[i] >>> 24, source[i] >>> 24);
    }
  });

  test('controls change the output', () {
    final base = MossLichenEffect({'coverage': 0.7}).apply(source, w, h);
    for (final entry in <String, dynamic>{
      'scale': 20,
      'edgeGrowth': 0.0,
      'lichenMix': 1.0,
      'gravity': 1.0,
      'fuzz': 0.0,
      'lightDirection': 45.0,
      'seed': 9,
      'mossColor': 0xFF225500,
      'lichenColor': 0xFFFFEE88,
    }.entries) {
      expect(MossLichenEffect({'coverage': 0.7, entry.key: entry.value}).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('gravity pulls moss onto up-facing edges', () {
    var withGravity = 0, without = 0;
    for (var seed = 1; seed <= 8; seed++) {
      bool top(int x, int y) => y >= 4 && y < 7 && x >= 8 && x < 40;
      withGravity += changed(MossLichenEffect({'coverage': 0.45, 'gravity': 1.0, 'seed': seed}).apply(source, w, h), null, top);
      without += changed(MossLichenEffect({'coverage': 0.45, 'gravity': 0.0, 'seed': seed}).apply(source, w, h), null, top);
    }
    expect(withGravity, greaterThan(without));
  });

  test('crevices attract moss', () {
    final grooved = slab();
    for (var y = 6; y < 30; y++) {
      grooved[y * w + 20] = 0xFF101010;
    }
    bool groove(int x, int y) => x >= 19 && x <= 21 && y >= 8 && y < 28;
    var withCrevice = 0, without = 0;
    for (var seed = 1; seed <= 8; seed++) {
      withCrevice += changed(MossLichenEffect({'coverage': 0.4, 'crevice': 1.0, 'seed': seed}).apply(grooved, w, h), grooved, groove);
      without += changed(MossLichenEffect({'coverage': 0.4, 'crevice': 0.0, 'seed': seed}).apply(grooved, w, h), grooved, groove);
    }
    expect(withCrevice, greaterThan(without));
  });

  test('preserveAlpha off lets moss overhang by one pixel only', () {
    final out = MossLichenEffect({'coverage': 1.0, 'preserveAlpha': false}).apply(source, w, h);
    var overhang = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (source[i] == 0 && out[i] != 0) {
          overhang++;
          expect(out[i] >>> 24, 255);
          expect(x >= 3 && x <= 44 && y >= 3 && y <= 32, isTrue);
        }
      }
    }
    expect(overhang, greaterThan(0));
    expect(out[0], 0);
  });

  test('transparent, empty, and tiny inputs are safe', () {
    expect(MossLichenEffect().apply(Uint32List(0), 0, 0), isEmpty);
    expect(MossLichenEffect().apply(Uint32List(16), 4, 4), Uint32List(16));
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final out = MossLichenEffect({'scale': double.nan, 'coverage': double.infinity})
          .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(out.length, a * b);
    }
  });
}
