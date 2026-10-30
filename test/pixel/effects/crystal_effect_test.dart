import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source =
      Uint32List.fromList(List.generate(48 * 32, (i) => 0x80000000 | ((i % 48 * 5) << 16) | ((i ~/ 48 * 7) << 8) | 80));
  test('legacy parameters load with new defaults and editable fields', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'crystal',
      'parameters': {
        'facets': 8,
        'color': 0xFFAABBFF,
        'refraction': 0.5,
        'clarity': 0.7,
        'innerGlow': 0.3,
        'surfaceReflection': 0.6,
        'prismEffect': 0.4,
      }
    })!;
    expect(effect, isA<CrystalEffect>());
    expect(effect.parameters['scale'], 16);
    expect(effect.getFields().map((f) => f.key).toSet(), effect.parameters.keys.toSet());
    final restored = EffectsManager.effectFromJson({'type': 'crystal', 'parameters': effect.parameters})!;
    expect(effect.apply(source, 48, 32), restored.apply(source, 48, 32));
  });
  test('full canvas is textured deterministically without modifying source alpha', () {
    final pixels = Uint32List.fromList(source)..[100] = 0x00123456;
    final before = Uint32List.fromList(pixels);
    final effect = CrystalEffect();
    final result = effect.apply(pixels, 48, 32);
    expect(result, effect.apply(pixels, 48, 32));
    expect(pixels, before);
    expect(result[100], pixels[100]);
    for (final i in [0, 47, 48 * 31, 48 * 32 - 1]) {
      expect(result[i], isNot(pixels[i]));
    }
    for (var i = 0; i < result.length; i++) {
      expect(result[i] >>> 24, pixels[i] >>> 24);
    }
  });
  test('growth and optical properties affect rendering', () {
    final baseline = CrystalEffect().apply(source, 48, 32);
    for (final entry in <String, dynamic>{
      'scale': 9,
      'growth': 3.0,
      'direction': 60.0,
      'facets': 4,
      'irregularity': 0.0,
      'facetContrast': 0.0,
      'edgeWidth': 0.0,
      'lightAngle': 45.0,
      'refraction': 1.0,
      'clarity': 0.0,
      'color': 0xFFDD5577,
      'innerGlow': 0.0,
      'surfaceReflection': 0.0,
      'prismEffect': 1.0,
      'seed': 92,
    }.entries) {
      expect(CrystalEffect({entry.key: entry.value}).apply(source, 48, 32), isNot(baseline), reason: entry.key);
    }
  });
  test('transparent RGB cannot leak through refraction', () {
    final a = Uint32List.fromList(source), b = Uint32List.fromList(source);
    for (var y = 0; y < 32; y++) {
      for (var x = 24; x < 48; x++) {
        a[y * 48 + x] = 0;
        b[y * 48 + x] = 0x00FF00FF;
      }
    }
    final effect = CrystalEffect({'refraction': 1.0, 'clarity': 1.0});
    final ar = effect.apply(a, 48, 32), br = effect.apply(b, 48, 32);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 24; x++) {
        expect(ar[y * 48 + x], br[y * 48 + x]);
      }
    }
  });
  test('empty, narrow and extreme inputs are safe; zero opacity is identity', () {
    expect(CrystalEffect({'opacity': 0}).apply(source, 48, 32), source);
    expect(CrystalEffect().apply(Uint32List(0), 0, 0), isEmpty);
    for (final dimensions in [(1, 1), (1, 31), (31, 1), (9, 17)]) {
      final (w, h) = dimensions;
      final result = CrystalEffect({
        'preserveAlpha': false,
        'direction': 359.0,
        'scale': 0,
        'growth': 0,
        'facets': 100,
        'refraction': double.nan
      }).apply(Uint32List(w * h), w, h);
      expect(result.length, w * h);
      expect(result.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
