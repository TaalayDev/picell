import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source = Uint32List.fromList(List.filled(64 * 64, 0x80909090));
  test('all 20 patterns are distinct, nonempty and deterministic', () {
    final signatures = <String>{};
    expect(PatternsEffect.patternOptions.length, 20);
    for (final pattern in PatternsEffect.patternOptions.keys) {
      final effect = PatternsEffect({'pattern': pattern});
      final result = effect.apply(source, 64, 64);
      expect(result.toSet().length, 2, reason: pattern);
      expect(result, effect.apply(source, 64, 64), reason: pattern);
      expect(signatures.add(result.join(',')), isTrue, reason: pattern);
    }
  });
  test('factory, fields and saved parameters round trip', () {
    final effect =
        EffectsManager.createEffect(EffectType.patterns, {'pattern': 'truchet', 'seed': 71, 'rotation': 35.0});
    expect(effect, isA<PatternsEffect>());
    expect(effect.getFields().map((f) => f.key).toSet(), effect.parameters.keys.toSet());
    final restored = EffectsManager.effectFromJson({'type': 'patterns', 'parameters': effect.parameters})!;
    expect(restored.apply(source, 64, 64), effect.apply(source, 64, 64));
  });
  test('shared controls affect rendering', () {
    final params = {'pattern': 'confetti', 'variation': 0.4};
    final baseline = PatternsEffect(params).apply(source, 64, 64);
    for (final entry in <String, dynamic>{
      'scale': 20,
      'spacing': 5.0,
      'thickness': 0.7,
      'rotation': 38.0,
      'stretch': 2.0,
      'offsetX': 4.0,
      'offsetY': -5.0,
      'pixelSize': 3,
      'variation': 0.0,
      'seed': 92,
      'invert': true,
      'sourceBlend': 0.5,
      'foregroundColor': 0xFFFF0000,
      'backgroundColor': 0xFF000000,
    }.entries) {
      expect(PatternsEffect({...params, entry.key: entry.value}).apply(source, 64, 64), isNot(baseline),
          reason: entry.key);
    }
  });
  test('alpha, identity and inverse masks behave correctly', () {
    final pixels = Uint32List.fromList(source)..[0] = 0;
    final before = Uint32List.fromList(pixels);
    final normal = PatternsEffect().apply(pixels, 64, 64);
    final inverse = PatternsEffect({'invert': true}).apply(pixels, 64, 64);
    expect(pixels, before);
    expect(normal[0], 0);
    for (var i = 1; i < pixels.length; i++) {
      expect(normal[i] >>> 24, 128);
      expect(inverse[i], isNot(normal[i]));
    }
    expect(PatternsEffect({'opacity': 0}).apply(pixels, 64, 64), pixels);
    final filled = PatternsEffect({'preserveAlpha': false}).apply(Uint32List(4096), 64, 64);
    expect(filled.every((p) => p >>> 24 == 255), isTrue);
  });
  test('pixel blocks, negative coordinates and extreme settings stay valid', () {
    for (final pattern in PatternsEffect.patternOptions.keys) {
      final effect = PatternsEffect(
          {'pattern': pattern, 'pixelSize': 4, 'rotation': 45.0, 'offsetX': 64.0, 'scale': double.nan, 'stretch': 0.0});
      final result = effect.apply(source, 64, 64);
      for (var y = 0; y < 64; y++) {
        for (var x = 0; x < 64; x++) {
          expect(result[y * 64 + x], result[(y ~/ 4 * 4) * 64 + x ~/ 4 * 4]);
        }
      }
      expect(effect.apply(Uint32List(0), 0, 0), isEmpty);
      expect(effect.apply(Uint32List.fromList([0xFFFFFFFF]), 1, 1).length, 1);
    }
    expect(PatternsEffect({'pattern': 'unknown'}).apply(source, 64, 64), PatternsEffect().apply(source, 64, 64));
  });
}
