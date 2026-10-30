import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source = Uint32List.fromList(
    List.generate(
      48 * 36,
      (i) =>
          0x80000000 |
          ((i % 48 * 5) << 16) |
          ((i ~/ 48 * 6) << 8) |
          ((i * 3) & 0xFF),
    ),
  );

  test('legacy parameters load with new defaults and editable fields', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'stone',
      'parameters': {
        'stoneType': 3,
        'scale': 0.5,
        'roughness': 0.5,
        'cracks': 0.3,
        'variation': 0.4,
        'weathering': 0.2,
        'seed': 42,
      },
    })!;
    expect(effect, isA<StoneEffect>());
    expect(effect.parameters['bevelDepth'], 3.0);
    expect(
      effect.getFields().map((f) => f.key).toSet(),
      effect.parameters.keys.toSet(),
    );
    final restored = EffectsManager.effectFromJson({
      'type': 'stone',
      'parameters': effect.parameters,
    })!;
    expect(restored.apply(source, 48, 36), effect.apply(source, 48, 36));
  });

  test('all seven geological stone types are distinct and deterministic', () {
    final signatures = <String>{};
    for (final type in StoneEffect.stoneTypeOptions.keys) {
      final effect = StoneEffect({'stoneType': type});
      final result = effect.apply(source, 48, 36);
      expect(result, effect.apply(source, 48, 36));
      expect(signatures.add(result.join(',')), isTrue, reason: 'stoneType $type');
      expect(result.toSet().length, greaterThan(15));
    }
  });

  test('all geometry, smart carving, and surface controls affect rendering', () {
    final baseline = StoneEffect().apply(source, 48, 36);
    for (final entry in <String, dynamic>{
      'stoneType': 0,
      'scale': 8,
      'irregularity': 0.0,
      'relief': 0.0,
      'bevelDepth': 0.0,
      'detailCarving': 0.0,
      'sourceBlend': 0.85,
      'cracks': 0.0,
      'roughness': 0.0,
      'variation': 0.0,
      'weathering': 0.0,
      'lightAngle': 45.0,
      'stoneColor': 0xFFB87348,
      'creviceColor': 0xFF050505,
      'mossColor': 0xFF22EE66,
      'seed': 99,
    }.entries) {
      expect(
        StoneEffect({entry.key: entry.value}).apply(source, 48, 36),
        isNot(baseline),
        reason: entry.key,
      );
    }
  });

  test('smart silhouette bevel chisels edges and holes without altering deep interior', () {
    final pixels = Uint32List.fromList(source)..[18 * 48 + 24] = 0;
    final noBevel = StoneEffect({
      'bevelDepth': 0.0,
      'weathering': 0.0,
    }).apply(pixels, 48, 36);
    final beveled = StoneEffect({
      'bevelDepth': 2.0,
      'weathering': 0.0,
    }).apply(pixels, 48, 36);

    expect(beveled[18 * 48 + 24], 0);
    // Edge of canvas and edge of internal hole are beveled:
    expect(beveled[0], isNot(noBevel[0]));
    expect(beveled[18 * 48 + 23], isNot(noBevel[18 * 48 + 23]));
    // Deep interior far from border and hole is unaffected by bevelDepth:
    expect(beveled[8 * 48 + 8], noBevel[8 * 48 + 8]);
  });

  test('smart detail carving never leaks RGB from transparent neighbors', () {
    final a = Uint32List.fromList(source);
    final b = Uint32List.fromList(source);
    for (var y = 0; y < 36; y++) {
      for (var x = 24; x < 48; x++) {
        a[y * 48 + x] = 0x00000000;
        b[y * 48 + x] = 0x00FFFFFF;
      }
    }
    final effect = StoneEffect({'detailCarving': 1.0, 'sourceBlend': 0.5});
    final ra = effect.apply(a, 48, 36);
    final rb = effect.apply(b, 48, 36);
    for (var y = 0; y < 36; y++) {
      for (var x = 0; x < 24; x++) {
        expect(ra[y * 48 + x], rb[y * 48 + x]);
      }
    }
  });

  test('transparency, input immutability, zero opacity, and extreme inputs are safe', () {
    final pixels = Uint32List.fromList(source)..[0] = 0x00123456;
    final copy = Uint32List.fromList(pixels);
    final result = StoneEffect().apply(pixels, 48, 36);
    expect(result[0], pixels[0]);
    expect(pixels, copy);
    for (var i = 1; i < result.length; i++) {
      expect(result[i] >>> 24, pixels[i] >>> 24);
    }
    expect(StoneEffect({'opacity': 0}).apply(pixels, 48, 36), pixels);
    expect(StoneEffect().apply(Uint32List(0), 0, 0), isEmpty);

    for (final (w, h) in [(1, 1), (1, 19), (19, 1), (7, 13)]) {
      final filled = StoneEffect({
        'preserveAlpha': false,
        'stoneType': 99,
        'scale': 0,
        'bevelDepth': 99,
        'cracks': double.nan,
        'roughness': double.infinity,
      }).apply(Uint32List(w * h), w, h);
      expect(filled.length, w * h);
      expect(filled.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
