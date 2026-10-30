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
      'type': 'ice',
      'parameters': {
        'iceType': 3,
        'transparency': 0.7,
        'thickness': 0.5,
        'frostiness': 0.3,
        'crackIntensity': 0.2,
        'bubbleAmount': 0.3,
        'refractionStrength': 0.4,
        'crystallization': 0.5,
        'shininess': 0.8,
        'temperature': 0.2,
        'iceAge': 0.3,
        'randomSeed': 42,
      },
    })!;
    expect(effect, isA<IceEffect>());
    expect(effect.parameters['scale'], 14);
    expect(effect.parameters['bevelWidth'], 3.0);
    expect(
      effect.getFields().map((f) => f.key).toSet(),
      effect.parameters.keys.toSet(),
    );
    final restored = EffectsManager.effectFromJson({
      'type': 'ice',
      'parameters': effect.parameters,
    })!;
    expect(restored.apply(source, 48, 36), effect.apply(source, 48, 36));
  });

  test('all six ice types are distinct and deterministic', () {
    final signatures = <String>{};
    for (final type in IceEffect.iceTypeOptions.keys) {
      final effect = IceEffect({'iceType': type});
      final result = effect.apply(source, 48, 36);
      expect(result, effect.apply(source, 48, 36));
      expect(signatures.add(result.join(',')), isTrue, reason: 'iceType $type');
      expect(result.toSet().length, greaterThan(15));
    }
  });

  test('all optical, structural, and smart controls affect rendering', () {
    final baseline = IceEffect().apply(source, 48, 36);
    for (final entry in <String, dynamic>{
      'iceType': 3,
      'scale': 8,
      'transparency': 0.85,
      'thickness': 0.95,
      'frostiness': 0.9,
      'crackIntensity': 0.9,
      'bubbleAmount': 0.9,
      'refractionStrength': 1.0,
      'crystallization': 0.0,
      'shininess': 0.0,
      'temperature': 0.95,
      'iceAge': 0.95,
      'bevelWidth': 0.0,
      'lightAngle': 45.0,
      'iceColor': 0xFF55AAFF,
      'frostColor': 0xFFFFEEDD,
      'deepColor': 0xFF051020,
      'randomSeed': 99,
    }.entries) {
      expect(
        IceEffect({entry.key: entry.value}).apply(source, 48, 36),
        isNot(baseline),
        reason: entry.key,
      );
    }
  });

  test('smart silhouette bevel affects edges and holes without altering deep interior', () {
    final pixels = Uint32List.fromList(source)..[18 * 48 + 24] = 0;
    final noBevel = IceEffect({
      'bevelWidth': 0.0,
      'refractionStrength': 0.0,
    }).apply(pixels, 48, 36);
    final beveled = IceEffect({
      'bevelWidth': 2.0,
      'refractionStrength': 0.0,
    }).apply(pixels, 48, 36);

    expect(beveled[18 * 48 + 24], 0);
    expect(beveled[0], isNot(noBevel[0]));
    expect(beveled[18 * 48 + 23], isNot(noBevel[18 * 48 + 23]));
    expect(beveled[9 * 48 + 9], noBevel[9 * 48 + 9]);
  });

  test('transparent RGB never leaks through ice refraction', () {
    final a = Uint32List.fromList(source);
    final b = Uint32List.fromList(source);
    for (var y = 0; y < 36; y++) {
      for (var x = 24; x < 48; x++) {
        a[y * 48 + x] = 0x00000000;
        b[y * 48 + x] = 0x00FF00FF;
      }
    }
    final effect = IceEffect({
      'refractionStrength': 1.0,
      'transparency': 0.9,
    });
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
    final result = IceEffect().apply(pixels, 48, 36);
    expect(result[0], pixels[0]);
    expect(pixels, copy);
    for (var i = 1; i < result.length; i++) {
      expect(result[i] >>> 24, pixels[i] >>> 24);
    }
    expect(IceEffect({'opacity': 0}).apply(pixels, 48, 36), pixels);
    expect(IceEffect().apply(Uint32List(0), 0, 0), isEmpty);

    for (final (w, h) in [(1, 1), (1, 19), (19, 1), (7, 13)]) {
      final filled = IceEffect({
        'preserveAlpha': false,
        'iceType': 99,
        'scale': 0,
        'bevelWidth': 99,
        'refractionStrength': double.nan,
        'frostiness': double.infinity,
      }).apply(Uint32List(w * h), w, h);
      expect(filled.length, w * h);
      expect(filled.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
