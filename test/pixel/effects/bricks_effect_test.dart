import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final pixels = Uint32List.fromList(List.filled(32 * 24, 0x8090A0B0));
  test('factory and serialization preserve controllable parameters', () {
    final effect = EffectsManager.createEffect(EffectType.bricks, {'seed': 91});
    expect(effect, isA<BricksEffect>());
    expect(effect.parameters['brickWidth'], 16);
    expect(effect.getFields().map((f) => f.key).toSet(), effect.parameters.keys.toSet());
    final restored = EffectsManager.effectFromJson({'type': 'bricks', 'parameters': effect.parameters})!;
    expect(restored.apply(pixels, 32, 24), effect.apply(pixels, 32, 24));
  });
  test('deterministic seed, silhouette and source pixels are preserved', () {
    final source = Uint32List.fromList(pixels)..[0] = 0;
    final before = Uint32List.fromList(source);
    final effect = BricksEffect();
    final result = effect.apply(source, 32, 24);
    expect(result, effect.apply(source, 32, 24));
    expect(source, before);
    expect(result[0], 0);
    expect(result.skip(1).every((p) => p >>> 24 == 128), isTrue);
    expect(result, isNot(BricksEffect({'seed': 99}).apply(source, 32, 24)));
  });
  test('zero opacity is identity and canvas mode fills transparent pixels', () {
    expect(BricksEffect({'opacity': 0}).apply(pixels, 32, 24), pixels);
    final result = BricksEffect({'preserveAlpha': false}).apply(Uint32List(768), 32, 24);
    expect(result.every((p) => p >>> 24 == 255), isTrue);
  });
  test('bonds and surface controls independently change the texture', () {
    final baseline = BricksEffect().apply(pixels, 32, 24);
    for (final entry in {
      'bond': 'english',
      'brickWidth': 10,
      'brickHeight': 5,
      'mortarWidth': 3.0,
      'stagger': 0.2,
      'bevel': 0.0,
      'variation': 0.0,
      'roughness': 0.0,
      'weathering': 0.8,
      'lightAngle': 45.0,
      'brickColor': 0xFF223344,
      'mortarColor': 0xFFFFFFFF,
    }.entries) {
      expect(BricksEffect({entry.key: entry.value}).apply(pixels, 32, 24), isNot(baseline), reason: entry.key);
    }
  });
  test('rounded corners cut into mortar and borders follow the inner contour', () {
    final params = <String, dynamic>{
      'bond': 'stack',
      'brickWidth': 16,
      'brickHeight': 8,
      'mortarWidth': 2.0,
      'bevel': 0.0,
      'roughness': 0.0,
      'variation': 0.0,
      'weathering': 0.0,
      'brickColor': 0xFFFF0000,
      'borderColor': 0xFF00FF00,
      'mortarColor': 0xFF000000,
      'preserveAlpha': false,
    };
    final source = Uint32List(128);
    final square = BricksEffect(params).apply(source, 16, 8);
    final rounded = BricksEffect({...params, 'cornerRadius': 3.0}).apply(source, 16, 8);
    final bordered = BricksEffect({...params, 'cornerRadius': 3.0, 'borderWidth': 1.0}).apply(source, 16, 8);
    expect(square[17], 0xFFFF0000);
    expect(rounded[17], 0xFF000000);
    expect(bordered[17], 0xFF000000);
    expect(bordered[1 * 16 + 8], 0xFF00FF00);
    expect(bordered[4 * 16 + 8], 0xFFFF0000);
    expect(BricksEffect({...params, 'borderWidth': 0.0, 'cornerRadius': 0.0}).apply(source, 16, 8), square);
  });
  test('tiny canvases and oversized joints remain valid', () {
    for (final size in [1, 2, 3, 8]) {
      final result = BricksEffect({
        'brickWidth': 4,
        'brickHeight': 3,
        'mortarWidth': 8,
        'bevel': 4,
        'cornerRadius': 16,
        'borderWidth': 8,
        'preserveAlpha': false
      }).apply(Uint32List(size * size), size, size);
      expect(result.length, size * size);
      expect(result.every((p) => p >>> 24 == 255), isTrue);
    }
    expect(BricksEffect().apply(Uint32List(0), 0, 0), isEmpty);
  });
}
