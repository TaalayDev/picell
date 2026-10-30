import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source =
      Uint32List.fromList(List.generate(64 * 48, (i) => 0x80000000 | ((i % 64 * 4) << 16) | ((i ~/ 64 * 5) << 8) | 90));
  test('legacy finish IDs load with new defaults and editable fields', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'metal',
      'parameters': {
        'metalType': 3,
        'reflectivity': 0.6,
        'scratchIntensity': 0.3,
        'color': 0xFFC0C0C0,
        'roughness': 0.4,
        'oxidation': 0.2,
        'anisotropy': 0.5,
        'lightDirection': 0.25,
      }
    })!;
    expect(effect, isA<MetalEffect>());
    expect(effect.parameters['scale'], 16);
    expect(effect.getFields().map((f) => f.key).toSet(), effect.parameters.keys.toSet());
    final restored = EffectsManager.effectFromJson({'type': 'metal', 'parameters': effect.parameters})!;
    expect(restored.apply(source, 64, 48), effect.apply(source, 64, 48));
  });
  test('six finishes are distinct and deterministic', () {
    final signatures = <String>{};
    for (final finish in MetalEffect.finishOptions.keys) {
      final effect = MetalEffect({'metalType': finish});
      final result = effect.apply(source, 64, 48);
      expect(result, effect.apply(source, 64, 48));
      expect(signatures.add(result.join(',')), isTrue, reason: '$finish');
      expect(result.toSet().length, greaterThan(3));
    }
  });
  test('controls affect the material', () {
    final baseline = MetalEffect().apply(source, 64, 48);
    for (final entry in <String, dynamic>{
      'reflectivity': 0.0,
      'scratchIntensity': 1.0,
      'color': 0xFFCC8844,
      'roughness': 1.0,
      'oxidation': 0.9,
      'anisotropy': 0.0,
      'lightDirection': 0.125,
      'grainDirection': 65.0,
      'scale': 8,
      'bevelWidth': 0.0,
      'bevelStrength': 0.0,
      'sourceDetail': 0.0,
      'shadeSteps': 3,
      'seed': 71,
    }.entries) {
      expect(MetalEffect({entry.key: entry.value}).apply(source, 64, 48), isNot(baseline), reason: entry.key);
    }
  });
  test('silhouette bevel affects edges and holes, not material interiors', () {
    final pixels = Uint32List.fromList(source)..[24 * 64 + 32] = 0;
    final params = <String, dynamic>{'bevelWidth': 1.0, 'shadeSteps': 24, 'bevelStrength': 1.0};
    final baseline = MetalEffect({...params, 'bevelStrength': 0.0}).apply(pixels, 64, 48);
    final result = MetalEffect(params).apply(pixels, 64, 48);
    expect(result[24 * 64 + 32], 0);
    expect(result[24 * 64 + 31], isNot(baseline[24 * 64 + 31]));
    expect(result[0], isNot(baseline[0]));
    expect(result[12 * 64 + 12], baseline[12 * 64 + 12]);
    for (var i = 0; i < pixels.length; i++) {
      expect(result[i] >>> 24, pixels[i] >>> 24);
    }
  });
  test('transparency, input immutability, empty and narrow inputs', () {
    final pixels = Uint32List.fromList(source)..[0] = 0x00123456;
    final copy = Uint32List.fromList(pixels);
    expect(MetalEffect().apply(pixels, 64, 48)[0], pixels[0]);
    expect(pixels, copy);
    expect(MetalEffect({'opacity': 0}).apply(pixels, 64, 48), pixels);
    expect(MetalEffect().apply(Uint32List(0), 0, 0), isEmpty);
    for (final dimensions in [(1, 1), (1, 19), (19, 1), (7, 13)]) {
      final (w, h) = dimensions;
      final result =
          MetalEffect({'preserveAlpha': false, 'roughness': double.nan, 'scale': 0, 'metalType': 99, 'shadeSteps': 0})
              .apply(Uint32List(w * h), w, h);
      expect(result.length, w * h);
      expect(result.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
