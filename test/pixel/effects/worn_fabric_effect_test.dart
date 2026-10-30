import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  Uint32List cloth() {
    final p = Uint32List(w * h);
    for (var y = 4; y < 32; y++) {
      for (var x = 4; x < 44; x++) {
        p[y * w + x] = 0xFF5070A0;
      }
    }
    return p;
  }

  final source = cloth();

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'wornFabric',
      'parameters': {'pattern': 1, 'threadSpacing': 3, 'weaveStrength': 0.42, 'wear': 0.3, 'fray': 0.18},
    })!;
    expect(effect, isA<WornFabricEffect>());
    expect(effect.parameters['dirt'], 0.25);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('weaves are distinct and over/under threads create relief', () {
    final signatures = <String>{};
    for (var pattern = 0; pattern < 3; pattern++) {
      final out = WornFabricEffect({'pattern': pattern, 'wear': 0.0, 'dirt': 0.0, 'fray': 0.0}).apply(source, w, h);
      expect(signatures.add(out.join(',')), isTrue, reason: 'pattern $pattern');
      expect(out.toSet().length, greaterThan(3));
    }
  });

  test('controls change the output', () {
    final base = WornFabricEffect().apply(source, w, h);
    for (final entry in <String, dynamic>{
      'pattern': 2,
      'threadSpacing': 5,
      'weaveStrength': 0.9,
      'wear': 0.9,
      'edgeWear': 0.0,
      'dirt': 0.9,
      'holes': 0.9,
      'fray': 0.9,
      'lightDirection': 45.0,
      'seed': 9,
      'threadColor': 0xFFFF0000,
    }.entries) {
      expect(WornFabricEffect({entry.key: entry.value}).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('fraying unravels whole threads at the silhouette, not the interior', () {
    final out = WornFabricEffect({'fray': 1.0, 'holes': 0.0}).apply(source, w, h);
    var removed = 0;
    for (var x = 4; x < 44; x++) {
      if (out[4 * w + x] == 0) removed++;
    }
    expect(removed, greaterThan(0));
    for (var y = 12; y < 24; y++) {
      for (var x = 12; x < 36; x++) {
        expect(out[y * w + x] >>> 24, 255);
      }
    }
    expect(WornFabricEffect({'fray': 0.0, 'holes': 0.0}).apply(source, w, h).where((p) => p == 0).length, w * h - 40 * 28);
  });

  test('holes open the weave only where cloth is worn through', () {
    final out = WornFabricEffect({'holes': 1.0, 'fray': 0.0}).apply(source, w, h);
    expect(out.where((p) => p == 0).length, greaterThan(w * h - 40 * 28));
  });

  test('transparency, zero effects, preserveAlpha off, and tiny canvases are safe', () {
    final copy = Uint32List.fromList(source);
    final out = WornFabricEffect().apply(source, w, h);
    expect(source, copy);
    expect(out[0], 0);
    expect(WornFabricEffect().apply(Uint32List(0), 0, 0), isEmpty);
    final filled = WornFabricEffect({'preserveAlpha': false}).apply(Uint32List(w * h), w, h);
    expect(filled.every((p) => p >>> 24 == 255), isTrue);
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final o = WornFabricEffect({'wear': double.nan, 'threadSpacing': 99}).apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(o.length, a * b);
    }
  });
}
