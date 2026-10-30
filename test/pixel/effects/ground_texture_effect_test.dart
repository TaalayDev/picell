import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  const w = 48, h = 36;
  final source = Uint32List.fromList(
    List.generate(w * h, (i) => 0xFF000000 | ((i % w * 5) << 16) | ((i ~/ w * 6) << 8) | ((i * 7) & 0xFF)),
  );

  Map<String, dynamic> tiled(int type, [Map<String, dynamic> extra = const {}]) =>
      {'textureType': type, 'blend': 1.0, ...extra};

  test('legacy parameters load and defaults fill the new controls', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'groundTexture',
      'parameters': {'textureType': 5, 'scale': 24.0, 'blend': 0.75, 'seamlessBlend': true},
    })!;
    expect(effect, isA<GroundTextureEffect>());
    expect(effect.parameters['edgeWear'], 0.5);
    expect(effect.apply(source, w, h), effect.apply(source, w, h));
  });

  test('every surface is deterministic, distinct, and keeps alpha', () {
    final signatures = <String>{};
    for (var type = 0; type <= 20; type++) {
      final effect = GroundTextureEffect(tiled(type));
      final result = effect.apply(source, w, h);
      expect(result, effect.apply(source, w, h));
      expect(signatures.add(result.join(',')), isTrue, reason: 'type $type');
      expect(result.toSet().length, greaterThan(8), reason: 'type $type');
      for (var i = 0; i < result.length; i++) {
        expect(result[i] >>> 24, source[i] >>> 24);
      }
    }
  });

  // edgeWear needs a silhouette, so it has its own test below.
  test('controls change the output', () {
    final base = GroundTextureEffect(tiled(5)).apply(source, w, h);
    for (final entry in <String, dynamic>{
      'scale': 32.0,
      'blendMode': 1,
      'offsetX': 0.4,
      'offsetY': 0.4,
      'noiseAmount': 0.4,
      'rotation': 2,
      'depthIntensity': 0.0,
      'colorTint': 3,
      'keepArtwork': 0.0,
      'lightDirection': 90.0,
      'seed': 7,
      'blend': 0.3,
    }.entries) {
      expect(GroundTextureEffect(tiled(5, {entry.key: entry.value})).apply(source, w, h), isNot(base), reason: entry.key);
    }
  });

  test('edge wear only changes pixels near the silhouette', () {
    final slab = Uint32List(w * h);
    for (var y = 4; y < 32; y++) {
      for (var x = 4; x < 44; x++) {
        slab[y * w + x] = 0xFF808080;
      }
    }
    final off = GroundTextureEffect(tiled(16, {'edgeWear': 0.0, 'keepArtwork': 0.0})).apply(slab, w, h);
    final on = GroundTextureEffect(tiled(16, {'edgeWear': 1.0, 'keepArtwork': 0.0})).apply(slab, w, h);
    expect(on[4 * w + 10], isNot(off[4 * w + 10]));
    expect(on[18 * w + 24], off[18 * w + 24]);
    expect(on[0], 0);
  });

  test('transparent pixels, zero blend, bad types and tiny canvases are safe', () {
    final pixels = Uint32List.fromList(source)..[0] = 0x00123456;
    final copy = Uint32List.fromList(pixels);
    final result = GroundTextureEffect(tiled(3)).apply(pixels, w, h);
    expect(result[0], pixels[0]);
    expect(pixels, copy);
    expect(GroundTextureEffect({'blend': 0.0}).apply(pixels, w, h), pixels);
    expect(GroundTextureEffect({'textureType': 999}).apply(pixels, w, h), pixels);
    expect(GroundTextureEffect().apply(Uint32List(0), 0, 0), isEmpty);
    for (final (a, b) in [(1, 1), (1, 19), (19, 1)]) {
      final out = GroundTextureEffect({'scale': double.nan, 'noiseAmount': double.infinity})
          .apply(Uint32List.fromList(List.filled(a * b, 0xFF446688)), a, b);
      expect(out.length, a * b);
    }
  });
}
