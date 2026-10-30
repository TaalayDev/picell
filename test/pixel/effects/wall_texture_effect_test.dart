import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  final source = Uint32List.fromList(
    List.generate(w * h, (i) => 0xFF000000 | ((i % w * 5) << 16) | ((i ~/ w * 6) << 8) | ((i * 7) & 0xFF)),
  );

  Map<String, dynamic> wall(int type, [Map<String, dynamic> extra = const {}]) =>
      {'wallType': type, 'blendAmount': 1.0, ...extra};

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'wallTexture',
      'parameters': {'wallType': 1, 'textureScale': 0.5, 'baseColor': 0xFF888888, 'randomSeed': 42, 'blendAmount': 0.7},
    })!;
    expect(effect, isA<WallTextureEffect>());
    expect(effect.parameters['edgeWear'], 0.5);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('every wall type is deterministic, distinct, and keeps alpha', () {
    final signatures = <String>{};
    for (var type = 0; type <= 8; type++) {
      final effect = WallTextureEffect(wall(type));
      final result = effect.apply(source, w, h);
      expect(signatures.add(result.join(',')), isTrue, reason: 'type $type');
      expect(result.toSet().length, greaterThan(8), reason: 'type $type');
      for (var i = 0; i < result.length; i++) {
        expect(result[i] >>> 24, source[i] >>> 24);
      }
    }
  });

  test('controls change the output', () {
    final base = WallTextureEffect(wall(1)).apply(source, w, h);
    for (final entry in <String, dynamic>{
      'textureScale': 0.9,
      'colorVariation': 0.0,
      'roughness': 0.0,
      'baseColor': 0xFF2244AA,
      'accentColor': 0xFFFFEE00,
      'shadowColor': 0xFF000000,
      'mortarColor': 0xFFFFFFFF,
      'weathering': 0.9,
      'lighting': 0.0,
      'lightAngle': 0.9,
      'randomSeed': 7,
      'blendAmount': 0.3,
      'keepArtwork': 0.0,
    }.entries) {
      expect(WallTextureEffect(wall(1, {entry.key: entry.value})).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('snap to artwork anchors courses at the artwork corner', () {
    Uint32List shifted(int dx, int dy) {
      final p = Uint32List(w * h);
      for (var y = 6; y < 30; y++) {
        for (var x = 6; x < 40; x++) {
          p[(y + dy) * w + x + dx] = 0xFF808080;
        }
      }
      return p;
    }

    final effect = WallTextureEffect(wall(1, {'weathering': 0.0, 'edgeWear': 0.0, 'keepArtwork': 0.0, 'roughness': 0.0}));
    final a = effect.apply(shifted(0, 0), w, h);
    final b = effect.apply(shifted(3, 2), w, h);
    for (var y = 0; y < 24; y++) {
      for (var x = 0; x < 34; x++) {
        expect(b[(y + 8) * w + x + 9], a[(y + 6) * w + x + 6]);
      }
    }
    final loose = WallTextureEffect(wall(1, {'snapToArtwork': false, 'weathering': 0.0, 'edgeWear': 0.0, 'keepArtwork': 0.0}));
    expect(loose.apply(shifted(3, 2), w, h), isNot(WallTextureEffect(wall(1, {'weathering': 0.0, 'edgeWear': 0.0, 'keepArtwork': 0.0})).apply(shifted(3, 2), w, h)));
  });

  test('transparent pixels, zero blend, bad types and tiny canvases are safe', () {
    final pixels = Uint32List.fromList(source)..[0] = 0x00123456;
    final copy = Uint32List.fromList(pixels);
    final result = WallTextureEffect(wall(0)).apply(pixels, w, h);
    expect(result[0], pixels[0]);
    expect(pixels, copy);
    expect(WallTextureEffect({'blendAmount': 0.0}).apply(pixels, w, h), pixels);
    expect(WallTextureEffect({'wallType': 99}).apply(pixels, w, h).length, pixels.length);
    expect(WallTextureEffect().apply(Uint32List(0), 0, 0), isEmpty);
    expect(WallTextureEffect().apply(Uint32List(16), 4, 4), Uint32List(16));
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final out = WallTextureEffect({'textureScale': double.nan, 'roughness': double.infinity})
          .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(out.length, a * b);
    }
  });
}
