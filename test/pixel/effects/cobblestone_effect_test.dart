import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source = Uint32List.fromList(List.filled(48 * 48, 0x80909090));
  test('factory, controls and saved settings round trip', () {
    final effect = EffectsManager.createEffect(
        EffectType.cobblestone, {'seed': 73, 'outlineWidth': 1.5, 'outlineOpacity': 0.6, 'outlineColor': 0xFF123456});
    expect(effect, isA<CobblestoneEffect>());
    expect(effect.getFields().map((f) => f.key).toSet(), effect.parameters.keys.toSet());
    final restored = EffectsManager.effectFromJson({'type': 'cobblestone', 'parameters': effect.parameters})!;
    expect(restored.apply(source, 48, 48), effect.apply(source, 48, 48));
  });
  test('rendering is deterministic and preserves source and silhouette', () {
    final pixels = Uint32List.fromList(source)..[0] = 0;
    final before = Uint32List.fromList(pixels);
    final effect = CobblestoneEffect();
    final result = effect.apply(pixels, 48, 48);
    expect(result, effect.apply(pixels, 48, 48));
    expect(pixels, before);
    expect(result[0], 0);
    expect(result.skip(1).every((p) => p >>> 24 == 128), isTrue);
    expect(result.toSet().length, greaterThan(30));
  });
  test('each geometry and surface control affects the result', () {
    final baseline = CobblestoneEffect().apply(source, 48, 48);
    for (final entry in <String, dynamic>{
      'stoneSize': 7,
      'irregularity': 0.0,
      'roundness': 1.0,
      'mortarWidth': 3.0,
      'relief': 0.0,
      'roughness': 0.0,
      'variation': 0.0,
      'moss': 1.0,
      'lightAngle': 45.0,
      'stoneColor': 0xFF884422,
      'mortarColor': 0xFFFFFFFF,
      'seed': 87,
    }.entries) {
      expect(CobblestoneEffect({entry.key: entry.value}).apply(source, 48, 48), isNot(baseline), reason: entry.key);
    }
  });
  test('regular cells have consistent straight joints and intact centers', () {
    final result = CobblestoneEffect({
      'stoneSize': 12,
      'irregularity': 0.0,
      'roundness': 0.0,
      'mortarWidth': 2.0,
      'relief': 0.0,
      'roughness': 0.0,
      'variation': 0.0,
      'moss': 0.0,
      'stoneColor': 0xFFFFFFFF,
      'mortarColor': 0xFF000000,
      'preserveAlpha': false,
    }).apply(source, 48, 48);
    expect(result[6 * 48 + 6], 0xFFFFFFFF);
    expect(result[6 * 48 + 11], 0xFF000000);
    expect(result[6 * 48 + 12], 0xFF000000);
    expect(result[6 * 48 + 13], 0xFFFFFFFF);
  });
  test('outline follows original silhouette, not internal stone joints', () {
    final pixels = Uint32List(48 * 48);
    for (var y = 4; y < 44; y++) {
      for (var x = 4; x < 44; x++) {
        pixels[y * 48 + x] = 0x80909090;
      }
    }
    final params = <String, dynamic>{'outlineColor': 0xFFFF0000};
    Uint32List render(Map<String, dynamic> changes) => CobblestoneEffect({...params, ...changes}).apply(pixels, 48, 48);
    final baseline = render({});
    final outlined = render({'outlineWidth': 1.0});
    expect(outlined[4 * 48 + 20], 0x80FF0000);
    expect(outlined[5 * 48 + 20], baseline[5 * 48 + 20]);
    expect(outlined[20 * 48 + 20], baseline[20 * 48 + 20]);
    expect(outlined[3 * 48 + 20], 0);
    expect(render({'outlineWidth': 2.0})[5 * 48 + 20], 0x80FF0000);
    expect(render({'outlineWidth': 1.0, 'outlineColor': 0xFF00FF00})[4 * 48 + 20], 0x8000FF00);
    expect(render({'outlineWidth': 3.0, 'outlineOpacity': 0.0}), baseline);
    final half = render({'outlineWidth': 1.0, 'outlineOpacity': 0.5});
    final original = baseline[4 * 48 + 20];
    expect((half[4 * 48 + 20] >> 16) & 255, ((((original >> 16) & 255) + 255) / 2).round());
    for (var y = 5; y < 43; y++) {
      for (var x = 5; x < 43; x++) {
        expect(outlined[y * 48 + x], baseline[y * 48 + x]);
      }
    }
  });
  test('silhouette outlines include holes and canvas edges, even in fill mode', () {
    final pixels = Uint32List.fromList(source)..[24 * 48 + 24] = 0;
    for (final preserve in [true, false]) {
      final params = <String, dynamic>{'preserveAlpha': preserve, 'outlineColor': 0xFFFF0000};
      final baseline = CobblestoneEffect(params).apply(pixels, 48, 48);
      final result = CobblestoneEffect({...params, 'outlineWidth': 1.0}).apply(pixels, 48, 48);
      final alpha = preserve ? 0x80000000 : 0xFF000000;
      expect(result[0], alpha | 0xFF0000);
      expect(result[24 * 48 + 23], alpha | 0xFF0000);
      expect(result[23 * 48 + 23], alpha | 0xFF0000);
      expect(result[24 * 48 + 24], baseline[24 * 48 + 24]);
      expect(result[20 * 48 + 20], baseline[20 * 48 + 20]);
    }
    expect(pixels[24 * 48 + 24], 0);
  });
  test('opacity, tiny canvases and clamped parameters are safe', () {
    expect(CobblestoneEffect({'opacity': 0}).apply(source, 48, 48), source);
    expect(CobblestoneEffect().apply(Uint32List(0), 0, 0), isEmpty);
    for (final size in [1, 3, 16]) {
      final result = CobblestoneEffect({
        'preserveAlpha': false,
        'stoneSize': 0,
        'mortarWidth': 99,
        'roundness': 1.0,
        'irregularity': 1.0,
        'relief': double.nan
      }).apply(Uint32List(size * size), size, size);
      expect(result.length, size * size);
      expect(result.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
