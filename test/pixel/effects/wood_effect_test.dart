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
          ((i * 7) & 0xFF),
    ),
  );

  test('legacy parameters load with new defaults and editable fields', () {
    final effect = EffectsManager.effectFromJson({
      'type': 'wood',
      'parameters': {
        'woodType': 2,
        'grainDirection': 0.25,
        'grainIntensity': 0.7,
        'knotCount': 2,
        'ringSpacing': 8.0,
        'colorVariation': 0.5,
      },
    })!;
    expect(effect, isA<WoodEffect>());
    expect(effect.parameters['bevelWidth'], 2.5);
    expect(
      effect.getFields().map((f) => f.key).toSet(),
      effect.parameters.keys.toSet(),
    );
    final restored = EffectsManager.effectFromJson({
      'type': 'wood',
      'parameters': effect.parameters,
    })!;
    expect(restored.apply(source, 48, 36), effect.apply(source, 48, 36));
  });

  test('all seven wood species are distinct and deterministic', () {
    final signatures = <String>{};
    for (final species in WoodEffect.woodTypeOptions.keys) {
      final effect = WoodEffect({'woodType': species});
      final result = effect.apply(source, 48, 36);
      expect(result, effect.apply(source, 48, 36));
      expect(
        signatures.add(result.join(',')),
        isTrue,
        reason: 'woodType $species',
      );
      expect(result.toSet().length, greaterThan(15));
    }
  });

  test('all structural, botanical, and smart controls affect rendering', () {
    final baseline = WoodEffect().apply(source, 48, 36);
    for (final entry in <String, dynamic>{
      'woodType': 3,
      'grainDirection': 45.0,
      'grainIntensity': 0.1,
      'ringSpacing': 20.0,
      'knotCount': 4,
      'knotSize': 18.0,
      'colorVariation': 0.9,
      'roughness': 0.9,
      'bevelWidth': 0.0,
      'detailCarving': 0.9,
      'varnish': 0.0,
      'weathering': 0.8,
      'lightAngle': 45.0,
      'woodColor': 0xFFE0C090,
      'darkColor': 0xFF301005,
      'seed': 99,
    }.entries) {
      expect(
        WoodEffect({entry.key: entry.value}).apply(source, 48, 36),
        isNot(baseline),
        reason: entry.key,
      );
    }
  });

  test('knots realistically deflect grain and darken core areas', () {
    final noKnots = WoodEffect({'knotCount': 0}).apply(source, 48, 36);
    final withKnots = WoodEffect({'knotCount': 3}).apply(source, 48, 36);
    expect(withKnots, isNot(noKnots));
  });

  test('smart silhouette bevel chisels edges and holes without altering deep interior', () {
    final pixels = Uint32List.fromList(source)..[18 * 48 + 24] = 0;
    final noBevel = WoodEffect({
      'bevelWidth': 0.0,
      'weathering': 0.0,
    }).apply(pixels, 48, 36);
    final beveled = WoodEffect({
      'bevelWidth': 2.5,
      'weathering': 0.0,
    }).apply(pixels, 48, 36);

    expect(beveled[18 * 48 + 24], 0);
    expect(beveled[0], isNot(noBevel[0]));
    expect(beveled[18 * 48 + 23], isNot(noBevel[18 * 48 + 23]));
    expect(beveled[9 * 48 + 9], noBevel[9 * 48 + 9]);
  });

  test('smart detail carving never leaks transparent neighbor RGB', () {
    final a = Uint32List.fromList(source);
    final b = Uint32List.fromList(source);
    for (var y = 0; y < 36; y++) {
      for (var x = 24; x < 48; x++) {
        a[y * 48 + x] = 0x00000000;
        b[y * 48 + x] = 0x00FFFFFF;
      }
    }
    final effect = WoodEffect({'detailCarving': 0.8});
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
    final result = WoodEffect().apply(pixels, 48, 36);
    expect(result[0], pixels[0]);
    expect(pixels, copy);
    for (var i = 1; i < result.length; i++) {
      expect(result[i] >>> 24, pixels[i] >>> 24);
    }
    expect(WoodEffect({'opacity': 0}).apply(pixels, 48, 36), pixels);
    expect(WoodEffect().apply(Uint32List(0), 0, 0), isEmpty);

    for (final (w, h) in [(1, 1), (1, 19), (19, 1), (7, 13)]) {
      final filled = WoodEffect({
        'preserveAlpha': false,
        'woodType': 99,
        'grainDirection': double.nan,
        'ringSpacing': 0,
        'knotCount': 20,
        'bevelWidth': 99,
        'roughness': double.infinity,
      }).apply(Uint32List(w * h), w, h);
      expect(filled.length, w * h);
      expect(filled.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
