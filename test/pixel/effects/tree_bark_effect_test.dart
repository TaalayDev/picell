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
      'type': 'treeBark',
      'parameters': {
        'barkType': 2,
        'roughness': 0.7,
        'grooving': 0.6,
        'colorVariation': 0.5,
        'scale': 0.5,
        'weathering': 0.4,
        'mossAmount': 0.1,
        'crackiness': 0.3,
        'lightDirection': 0.5,
        'depth': 0.5,
        'peeling': 0.0,
      },
    })!;
    expect(effect, isA<TreeBarkEffect>());
    expect(effect.parameters['bevelWidth'], 2.5);
    expect(effect.parameters['followShape'], 0.85);
    expect(
      effect.getFields().map((f) => f.key).toSet(),
      effect.parameters.keys.toSet(),
    );
    final restored = EffectsManager.effectFromJson({
      'type': 'treeBark',
      'parameters': effect.parameters,
    })!;
    expect(restored.apply(source, 48, 36), effect.apply(source, 48, 36));
  });

  test('all eight botanical bark types are distinct and deterministic', () {
    final signatures = <String>{};
    for (final type in TreeBarkEffect.barkTypeOptions.keys) {
      final effect = TreeBarkEffect({'barkType': type});
      final result = effect.apply(source, 48, 36);
      expect(result, effect.apply(source, 48, 36));
      expect(
        signatures.add(result.join(',')),
        isTrue,
        reason: 'barkType $type',
      );
      expect(result.toSet().length, greaterThan(15));
    }
  });

  test('all morphological, botanical, and smart controls affect rendering', () {
    final baseline = TreeBarkEffect().apply(source, 48, 36);
    for (final entry in <String, dynamic>{
      'barkType': 1,
      'scale': 24.0,
      'grooving': 0.0,
      'roughness': 0.0,
      'crackiness': 0.9,
      'peeling': 0.9,
      'depth': 0.0,
      'bevelWidth': 0.0,
      'detailCarving': 0.9,
      'mossAmount': 0.9,
      'weathering': 0.9,
      'colorVariation': 0.9,
      'lightDirection': 45.0,
      'barkColor': 0xFF704020,
      'creviceColor': 0xFF050505,
      'mossColor': 0xFF22DD55,
      'seed': 99,
      'keepArtwork': 0.9,
    }.entries) {
      expect(
        TreeBarkEffect({entry.key: entry.value}).apply(source, 48, 36),
        isNot(baseline),
        reason: entry.key,
      );
    }
  });

  test('trunk roundness shades the silhouette rim but not the flat interior', () {
    final pixels = Uint32List.fromList(source)..[18 * 48 + 24] = 0;
    final flat = TreeBarkEffect({'bevelWidth': 0.0, 'mossAmount': 0.0}).apply(pixels, 48, 36);
    final round = TreeBarkEffect({'bevelWidth': 2.5, 'mossAmount': 0.0}).apply(pixels, 48, 36);
    expect(round[18 * 48 + 24], 0);
    expect(round[18 * 48 + 23], isNot(flat[18 * 48 + 23]));
    expect(round[18 * 48 + 12], round[18 * 48 + 12]);
  });

  test('grain follows the silhouette: horizontal limb differs from vertical limb', () {
    Uint32List limb(bool horizontal) {
      final p = Uint32List(40 * 40);
      for (var y = 0; y < 40; y++) {
        for (var x = 0; x < 40; x++) {
          final on = horizontal ? (y - 20).abs() < 6 : (x - 20).abs() < 6;
          if (on) p[y * 40 + x] = 0xFF886644;
        }
      }
      return p;
    }

    final effect = TreeBarkEffect({'barkType': 3, 'mossAmount': 0.0, 'detailCarving': 0.0, 'roughness': 0.0});
    final v = effect.apply(limb(false), 40, 40);
    final h = effect.apply(limb(true), 40, 40);
    // Streaks run along the limb: neighbouring pixels along the axis vary less
    // than neighbouring pixels across it.
    double variation(Uint32List px, bool alongX) {
      var sum = 0.0;
      for (var y = 17; y < 23; y++) {
        for (var x = 17; x < 23; x++) {
          final other = alongX ? px[y * 40 + x + 1] : px[(y + 1) * 40 + x];
          sum += ((px[y * 40 + x] & 0xFF) - (other & 0xFF)).abs();
        }
      }
      return sum;
    }

    expect(variation(h, true), lessThan(variation(h, false)));
    expect(variation(v, false), lessThan(variation(v, true)));
    final locked = TreeBarkEffect({'barkType': 3, 'mossAmount': 0.0, 'detailCarving': 0.0, 'followShape': 0.0});
    expect(locked.apply(limb(true), 40, 40), isNot(h));
  });

  test('artwork tint carries source hue into the bark', () {
    final green = Uint32List.fromList(List.filled(32 * 32, 0xFF30A030));
    final none = TreeBarkEffect({'keepArtwork': 0.0, 'mossAmount': 0.0}).apply(green, 32, 32);
    final tinted = TreeBarkEffect({'keepArtwork': 1.0, 'mossAmount': 0.0}).apply(green, 32, 32);
    int g(Uint32List p) => p.fold(0, (a, c) => a + ((c >> 8) & 0xFF) - ((c >> 16) & 0xFF));
    expect(g(tinted), greaterThan(g(none)));
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
    final effect = TreeBarkEffect({'detailCarving': 0.8});
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
    final result = TreeBarkEffect().apply(pixels, 48, 36);
    expect(result[0], pixels[0]);
    expect(pixels, copy);
    for (var i = 1; i < result.length; i++) {
      expect(result[i] >>> 24, pixels[i] >>> 24);
    }
    expect(TreeBarkEffect({'opacity': 0}).apply(pixels, 48, 36), pixels);
    expect(TreeBarkEffect().apply(Uint32List(0), 0, 0), isEmpty);

    // Empty layer produces all alpha 0 (catalog texture requirement):
    final empty = Uint32List(16 * 16);
    final emptyResult = TreeBarkEffect().apply(empty, 16, 16);
    expect(emptyResult.every((p) => p >>> 24 == 0), isTrue);

    for (final (w, h) in [(1, 1), (1, 19), (19, 1), (7, 13)]) {
      final filled = TreeBarkEffect({
        'preserveAlpha': false,
        'barkType': 99,
        'scale': 0,
        'grooving': double.nan,
        'bevelWidth': 99,
        'roughness': double.infinity,
      }).apply(Uint32List(w * h), w, h);
      expect(filled.length, w * h);
      expect(filled.every((p) => p >>> 24 == 255), isTrue);
    }
  });
}
