import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';

import 'seam_expectations.dart';

TilesetSettings settingsFor(TilesetSurfaceSpec spec, TilesetBase base, TilesetPerspective p, int size,
    {List<int>? palette, int seed = 48213, bool single = false}) {
  final recipe = TilesetRecipe(base: base, surface: TilesetMaterial.custom(spec));
  return TilesetSettings(
      perspective: p,
      size: size,
      type: recipe.rendererFor(p),
      recipe: recipe,
      palette: palette,
      seed: seed,
      parts: single ? const [255] : null,
      variations: single ? 1 : 2);
}

TilesetSurfaceSpec randomSpec(Random r) {
  T pick<T>(List<T> values) => values[r.nextInt(values.length)];
  final count = 1 + r.nextInt(tilesetMaxLayers);
  return TilesetSurfaceSpec(name: 'Random', layers: [
    for (var i = 0; i < count; i++)
      TilesetLayer(
          pattern: pick(TilesetPattern.values),
          colors:
              TilesetLayerColors(mid: r.nextInt(8), dark: r.nextInt(8), light: r.nextInt(8), highlight: r.nextInt(8)),
          noise: r.nextBool()
              ? TilesetNoise(
                  type: pick(TilesetNoiseType.values),
                  scale: 1 + r.nextInt(16),
                  strength: r.nextDouble(),
                  threshold: r.nextDouble(),
                  seed: r.nextInt(5000))
              : null,
          area: pick(TilesetLayerArea.values),
          density: pick([1.0, 0.7, 0.3]),
          blend: pick(TilesetLayerBlend.values),
          invert: r.nextInt(4) == 0)
  ]);
}

void main() {
  group('layer documents', () {
    test('every preset round-trips through JSON', () {
      for (final preset in TilesetSurfacePresets.all) {
        final restored =
            TilesetSurfaceSpec.fromJson(jsonDecode(jsonEncode(preset.spec.toJson())) as Map<String, dynamic>);
        expect(restored, preset.spec, reason: preset.id);
        expect(preset.palette.length, 8);
      }
    });

    test('a recipe with a custom surface keeps its layers through JSON', () {
      final recipe =
          TilesetRecipe(base: TilesetBase.floor, surface: TilesetMaterial.custom(TilesetSurfacePresets.brick.spec));
      final restored = TilesetRecipe.fromJson(jsonDecode(jsonEncode(recipe.toJson())) as Map<String, dynamic>);
      expect(restored.surface.spec, TilesetSurfacePresets.brick.spec);
      expect(restored.surface, recipe.surface);
      expect(() => restored.rendererFor(TilesetPerspective.topDown), returnsNormally);
    });

    test('invalid surfaces are rejected', () {
      Map<String, dynamic> layer(Map<String, dynamic> patch) => {
            'pattern': 'solid',
            'colors': {'m': 5},
            ...patch
          };
      Map<String, dynamic> doc(List<Map<String, dynamic>> layers) => {'name': 'x', 'layers': layers};
      expect(() => TilesetSurfaceSpec.fromJson(doc([])), throwsFormatException);
      expect(
          () => TilesetSurfaceSpec.fromJson(doc([
                layer({'pattern': 'lava'})
              ])),
          throwsFormatException);
      expect(
          () => TilesetSurfaceSpec.fromJson(doc([
                layer({
                  'colors': {'m': 9}
                })
              ])),
          throwsFormatException);
      expect(
          () => TilesetSurfaceSpec.fromJson(doc([
                layer({'density': 2})
              ])),
          throwsFormatException);
      expect(
          () => TilesetSurfaceSpec.fromJson(doc([
                layer({'blend': 'xor'})
              ])),
          throwsFormatException);
      expect(() => TilesetSurfaceSpec.fromJson(doc([for (var i = 0; i < 7; i++) layer({})])), throwsFormatException);
      expect(() => TilesetSurfaceSpec(layers: const []), throwsArgumentError);
    });
  });

  group('rendering', () {
    test('patterns and layer settings change the artwork; the same seed repeats it', () {
      final seen = <String>{};
      for (final pattern in TilesetPattern.values) {
        final s = settingsFor(TilesetSurfaceSpec(layers: [TilesetLayer(pattern: pattern)]), TilesetBase.floor,
            TilesetPerspective.topDown, 32,
            single: true);
        final a = generateTileset(s).single.pixels;
        expect(generateTileset(s).single.pixels, a, reason: pattern.name);
        if (pattern != TilesetPattern.solid) seen.add(a.join(','));
      }
      expect(seen.length, TilesetPattern.values.length - 1, reason: 'patterns must look different');
    });

    test('hiding a layer changes the pixels, and hiding every upper layer leaves the base', () {
      final full = TilesetSurfacePresets.grass.spec;
      final hidden = full.copyWith(layers: [full.layers[0], full.layers[1].copyWith(visible: false), full.layers[2]]);
      final onlyBase = full.copyWith(layers: [full.layers[0]]);
      final allHidden =
          full.copyWith(layers: [full.layers[0], for (final l in full.layers.skip(1)) l.copyWith(visible: false)]);
      List<int> pixels(TilesetSurfaceSpec spec) =>
          generateTileset(settingsFor(spec, TilesetBase.floor, TilesetPerspective.topDown, 16,
                  palette: TilesetSurfacePresets.grass.palette, single: true))
              .single
              .pixels
              .toList();
      expect(pixels(hidden), isNot(pixels(full)));
      expect(pixels(allHidden), pixels(onlyBase));
    });
  });

  group('seamless connections', () {
    for (final preset in TilesetSurfacePresets.all) {
      for (final (base, perspective) in [
        (TilesetBase.ground, TilesetPerspective.side),
        (TilesetBase.wall, TilesetPerspective.side),
        (TilesetBase.floor, TilesetPerspective.topDown),
      ]) {
        for (final size in const [16, 32, 48]) {
          test('${preset.id} · ${base.name} · ${perspective.id} · ${size}px', () {
            expectSeamless(settingsFor(preset.spec, base, perspective, size, palette: preset.palette),
                '${preset.id} ${base.name} ${perspective.id} ${size}px');
          });
        }
      }
    }

    test('random surfaces never break a seam, whatever area, blend, noise or inversion they use', () {
      final random = Random(20260101);
      for (var i = 0; i < 24; i++) {
        final spec = randomSpec(random);
        final size = const [16, 32, 48][i % 3];
        final (base, perspective) = [
          (TilesetBase.ground, TilesetPerspective.side),
          (TilesetBase.wall, TilesetPerspective.side),
          (TilesetBase.floor, TilesetPerspective.topDown),
        ][i % 3];
        expectSeamless(settingsFor(spec, base, perspective, size, seed: i * 977),
            'random #$i ${size}px ${base.name} ${jsonEncode(spec.toJson())}');
      }
    });
  });
}
