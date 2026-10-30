import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source = Uint32List.fromList(List.filled(64 * 64, 0x80909090));
  test('factory, fields and saved settings round trip', () {
    final effect = EffectsManager.createEffect(EffectType.crackedEarth, {'seed': 73, 'rimWidth': 2.0});
    expect(effect, isA<CrackedEarthEffect>());
    expect(effect.getFields().map((f) => f.key).toSet(), effect.parameters.keys.toSet());
    final restored = EffectsManager.effectFromJson({'type': 'crackedEarth', 'parameters': effect.parameters})!;
    expect(restored.apply(source, 64, 64), effect.apply(source, 64, 64));
  });
  test('stable output preserves source pixels and partial alpha', () {
    final pixels = Uint32List.fromList(source)..[0] = 0;
    final before = Uint32List.fromList(pixels);
    final effect = CrackedEarthEffect();
    final result = effect.apply(pixels, 64, 64);
    expect(result, effect.apply(pixels, 64, 64));
    expect(pixels, before);
    expect(result[0], 0);
    expect(result.skip(1).every((p) => p >>> 24 == 128), isTrue);
  });
  test('controls independently affect plate geometry and material', () {
    final baseline = CrackedEarthEffect().apply(source, 64, 64);
    for (final entry in <String, dynamic>{
      'plateSize': 20,
      'pixelSize': 3,
      'irregularity': 0.0,
      'crackWidth': 3.0,
      'rimWidth': 0.0,
      'rimBreakup': 1.0,
      'variation': 0.0,
      'roughness': 1.0,
      'relief': 0.0,
      'lightAngle': 45.0,
      'seed': 87,
      'soilColor': 0xFF884422,
      'rimColor': 0xFFFFFFFF,
      'crackColor': 0xFF000000,
    }.entries) {
      expect(CrackedEarthEffect({entry.key: entry.value}).apply(source, 64, 64), isNot(baseline), reason: entry.key);
    }
  });
  test('regular plates separate dark cracks, pale rims and soil interiors', () {
    final result = CrackedEarthEffect({
      'plateSize': 12,
      'irregularity': 0.0,
      'crackWidth': 2.0,
      'rimWidth': 1.0,
      'rimBreakup': 0.0,
      'relief': 0.0,
      'roughness': 0.0,
      'variation': 0.0,
      'soilColor': 0xFF804020,
      'rimColor': 0xFFFFFFFF,
      'crackColor': 0xFF000000,
    }).apply(source, 64, 64);
    expect(result[6 * 64 + 6], 0x80804020);
    expect(result[6 * 64 + 11], 0x80000000);
    expect(result[6 * 64 + 12], 0x80000000);
    expect(result[6 * 64 + 13], 0x80FFFFFF);
    expect(result[6 * 64 + 14], 0x80804020);
  });
  test('pixel size uses consistent blocks and retains alpha silhouette', () {
    final result = CrackedEarthEffect({'pixelSize': 4}).apply(source, 64, 64);
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        expect(result[y * 64 + x], result[(y ~/ 4 * 4) * 64 + x ~/ 4 * 4]);
      }
    }
  });
  test('zero opacity, empty input, fill mode and extreme settings are safe', () {
    expect(CrackedEarthEffect({'opacity': 0}).apply(source, 64, 64), source);
    expect(CrackedEarthEffect().apply(Uint32List(0), 0, 0), isEmpty);
    for (final size in [1, 3, 17]) {
      final result = CrackedEarthEffect({
        'preserveAlpha': false,
        'plateSize': 0,
        'pixelSize': 8,
        'crackWidth': 99,
        'rimWidth': 99,
        'irregularity': 1.0,
        'roughness': double.nan
      }).apply(Uint32List(size * size), size, size);
      expect(result.length, size * size);
      expect(result.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
