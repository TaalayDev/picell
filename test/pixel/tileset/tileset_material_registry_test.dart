import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';

import 'seam_expectations.dart';

/// The shared contract for every registered material and modifier. Adding one to
/// the registry adds it to these tests; nothing here names a specific material.

final _idPattern = RegExp(r'^[a-z][a-z0-9_]{1,23}$');

TilesetRecipe recipeWithAllModifiers(TilesetBase base, TilesetMaterial material, TilesetPerspective p) {
  var recipe = TilesetRecipe(base: base, surface: material);
  for (final modifier in TilesetModifiers.all) {
    if (modifier.applies(base, p)) {
      recipe = recipe.withModifier(modifier.id, modifier.defaultIntensity);
    }
  }
  return recipe;
}

void main() {
  group('registry integrity', () {
    test('materials have unique stable ids, labels, bases and palette presets', () {
      final ids = TilesetMaterials.all.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final m in TilesetMaterials.all) {
        expect(_idPattern.hasMatch(m.id), isTrue, reason: m.id);
        expect(m.label.trim(), isNotEmpty);
        expect(m.bases, isNotEmpty, reason: '${m.id} builds nothing');
        expect(m.primaryFor.difference(m.bases), isEmpty, reason: '${m.id} is primary for a base it cannot build');
        expect(materialPalettes.containsKey(m.palettePreset), isTrue, reason: '${m.id} palette ${m.palettePreset}');
        expect(TilesetMaterials.byId(m.id), same(m));
      }
      expect(() => TilesetMaterials.byId('plasma'), throwsFormatException);
    });

    test('shipped ids stay stable because saved documents refer to them', () {
      expect(TilesetMaterials.all.map((m) => m.id), containsAll(['earth', 'stone', 'sand', 'brick', 'wood']));
      expect(TilesetModifiers.all.map((m) => m.id), containsAll(['platform', 'vegetation']));
    });

    test('every base offers materials and starts with its default', () {
      for (final base in TilesetBase.values) {
        final offered = TilesetRecipe.surfacesFor(base);
        expect(offered, isNotEmpty, reason: base.name);
        expect(offered.every((m) => m.supports(base)), isTrue);
        final primaries = TilesetMaterials.all.where((m) => m.primaryFor.contains(base));
        if (primaries.isNotEmpty) expect(primaries, contains(offered.first), reason: base.name);
      }
    });

    test('modifiers have unique ids, descriptions and a valid default intensity', () {
      final ids = TilesetModifiers.all.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final m in TilesetModifiers.all) {
        expect(_idPattern.hasMatch(m.id), isTrue, reason: m.id);
        expect(m.label.trim(), isNotEmpty);
        expect(m.description.trim(), isNotEmpty);
        expect(m.unavailable.trim(), isNotEmpty);
        expect(m.defaultIntensity, inInclusiveRange(0, 100));
        expect(TilesetModifiers.byId(m.id), same(m));
      }
      expect(() => TilesetModifiers.byId('rust'), throwsFormatException);
    });

    test('recipe validation agrees with each modifier\'s own availability rule', () {
      for (final p in TilesetPerspective.values) {
        for (final base in TilesetBase.values) {
          for (final modifier in TilesetModifiers.all) {
            final recipe = TilesetRecipe(base: base, surface: TilesetRecipe.surfacesFor(base).first)
                .withModifier(modifier.id, modifier.defaultIntensity);
            final shouldWork = TilesetRecipe.basesFor(p).contains(base) && modifier.applies(base, p);
            if (shouldWork) {
              expect(() => recipe.rendererFor(p), returnsNormally, reason: '${modifier.id} ${base.name} ${p.id}');
            } else {
              expect(() => recipe.rendererFor(p), throwsArgumentError, reason: '${modifier.id} ${base.name} ${p.id}');
            }
          }
        }
      }
    });
  });

  group('recipe documents', () {
    test('every material and modifier survives a JSON round trip', () {
      for (final base in TilesetBase.values) {
        for (final material in TilesetRecipe.surfacesFor(base)) {
          final recipe = recipeWithAllModifiers(base, material, TilesetPerspective.side);
          final restored = TilesetRecipe.fromJson(jsonDecode(jsonEncode(recipe.toJson())) as Map<String, dynamic>);
          expect(restored.toJson(), recipe.toJson());
          expect(restored.surface, same(material));
        }
      }
    });

    test('documents saved before the registry still load', () {
      final legacy = {
        'base': 'wall',
        'surface': 'brick',
        'platform': false,
        'vegetation': false,
        'vegetationDensity': 45,
      };
      final recipe = TilesetRecipe.fromJson(legacy);
      expect(recipe.surface, same(TilesetMaterials.brick));
      expect(recipe.toJson(), legacy, reason: 'no new keys unless an extra modifier is used');
    });

    test('unknown materials, modifiers and bad intensities are rejected', () {
      Map<String, dynamic> json([Map<String, dynamic> extra = const {}]) => {
            'base': 'ground',
            'surface': 'earth',
            'platform': false,
            'vegetation': false,
            'vegetationDensity': 45,
            ...extra,
          };
      expect(() => TilesetRecipe.fromJson(json({'surface': 'plasma'})), throwsFormatException);
      expect(
          () => TilesetRecipe.fromJson(json({
                'modifiers': {'rust': 50}
              })),
          throwsFormatException);
      expect(
          () => TilesetRecipe.fromJson(json({
                'modifiers': {'platform': 'high'}
              })),
          throwsFormatException);
      expect(() => const TilesetRecipe(extraModifiers: {'platform': 50}).rendererFor(TilesetPerspective.side),
          throwsArgumentError);
    });

    test('withModifier switches built-in modifiers on and off and keeps vegetation density', () {
      const base = TilesetRecipe();
      final on = base.withModifier('vegetation', 80);
      expect((on.vegetation, on.vegetationDensity, on.modifierIntensity('vegetation')), (true, 80, 80));
      final off = on.withModifier('vegetation', null);
      expect((off.vegetation, off.vegetationDensity, off.modifierIntensity('vegetation')), (false, 80, null));
      expect(base.withModifier('platform', 100).platform, isTrue);
      expect(base.withModifier('platform', 100).withModifier('platform', null).platform, isFalse);
    });
  });

  group('materials draw', () {
    test('every material gives each base artwork that differs from the other materials', () {
      for (final p in [TilesetPerspective.side, TilesetPerspective.topDown]) {
        for (final base in TilesetRecipe.basesFor(p)) {
          final seen = <String, String>{};
          for (final material in TilesetRecipe.surfacesFor(base)) {
            final recipe = TilesetRecipe(base: base, surface: material);
            final s = TilesetSettings(perspective: p, type: recipe.rendererFor(p), recipe: recipe);
            final print = generateTilesetTile(s, 255, 0).pixels.join(',');
            final twin = seen[print];
            expect(twin, isNull, reason: '${material.id} looks like $twin on ${base.name} (${p.id})');
            seen[print] = material.id;
          }
        }
      }
    });

    test('a different seed changes the artwork and the same seed repeats it', () {
      for (final material in TilesetMaterials.all) {
        final base = material.bases.first;
        final recipe = TilesetRecipe(base: base, surface: material);
        final p = TilesetRecipe.basesFor(TilesetPerspective.side).contains(base)
            ? TilesetPerspective.side
            : TilesetPerspective.topDown;
        TilesetSettings at(int seed) => TilesetSettings(
            perspective: p, type: recipe.rendererFor(p), recipe: recipe, seed: seed, parts: [255], variations: 1);
        expect(generateTileset(at(7)).single.pixels, generateTileset(at(7)).single.pixels, reason: material.id);
        expect(generateTileset(at(7)).single.pixels, isNot(generateTileset(at(8)).single.pixels), reason: material.id);
      }
    });

    test('every modifier changes the artwork wherever it applies', () {
      for (final modifier in TilesetModifiers.all) {
        var checked = 0;
        for (final p in TilesetPerspective.values) {
          for (final base in TilesetRecipe.basesFor(p).where((b) => modifier.applies(b, p))) {
            final material = TilesetRecipe.surfacesFor(base).first;
            final plain = TilesetRecipe(base: base, surface: material);
            final modified = plain.withModifier(modifier.id, modifier.hasIntensity ? 100 : modifier.defaultIntensity);
            TilesetSettings of(TilesetRecipe r) =>
                TilesetSettings(perspective: p, type: r.rendererFor(p), recipe: r, parts: [0, 110], variations: 1);
            final a = generateTileset(of(plain)), b = generateTileset(of(modified));
            final changed = [for (var i = 0; i < a.length; i++) a[i].pixels.join() != b[i].pixels.join()].any((c) => c);
            expect(changed, isTrue, reason: '${modifier.id} does nothing on ${base.name} (${p.id})');
            checked++;
          }
        }
        expect(checked, greaterThan(0), reason: '${modifier.id} applies nowhere');
      }
    });
  });

  group('seamless connections', () {
    // One group per material so a failure names the offender.
    for (final material in TilesetMaterials.all) {
      group(material.id, () {
        for (final perspective in [TilesetPerspective.side, TilesetPerspective.topDown]) {
          for (final base in TilesetRecipe.basesFor(perspective).where(material.supports)) {
            for (final size in const [16, 32, 48]) {
              test('${base.name} · ${perspective.id} · ${size}px, plain and with every modifier', () {
                for (final recipe in {
                  TilesetRecipe(base: base, surface: material),
                  recipeWithAllModifiers(base, material, perspective),
                }) {
                  final settings = TilesetSettings(
                      perspective: perspective,
                      size: size,
                      type: recipe.rendererFor(perspective),
                      recipe: recipe,
                      variations: 2);
                  expectSeamless(settings,
                      '${material.id} ${base.name} ${perspective.id} ${size}px ${jsonEncode(recipe.toJson())}');
                }
              });
            }
          }
        }
      });
    }
  });

  group('isometric', () {
    test('every material builds sprites on every isometric base, including modifiers', () {
      for (final base in TilesetRecipe.basesFor(TilesetPerspective.isometric)) {
        for (final material in TilesetRecipe.surfacesFor(base)) {
          for (final recipe in [
            TilesetRecipe(base: base, surface: material),
            recipeWithAllModifiers(base, material, TilesetPerspective.isometric),
          ]) {
            final s = TilesetSettings(
                perspective: TilesetPerspective.isometric,
                type: recipe.rendererFor(TilesetPerspective.isometric),
                recipe: recipe,
                parts: [0, 110, 255],
                variations: 1);
            final tiles = generateTileset(s);
            expect(tiles, hasLength(3), reason: '${material.id} ${base.name}');
            for (final tile in tiles) {
              expect(tile.pixels.length, s.spriteWidth * s.spriteHeight);
              expect(tile.pixels.any((c) => c >> 24 != 0), isTrue, reason: '${material.id} ${base.name} is empty');
            }
          }
        }
      }
    });

    test('mortar lines on isometric walls follow the material flag', () {
      TilesetSettings wall(TilesetMaterial material) {
        final recipe = TilesetRecipe(base: TilesetBase.wall, surface: material);
        return TilesetSettings(
            perspective: TilesetPerspective.isometric,
            type: TilesetType.walls,
            recipe: recipe,
            parts: [0],
            variations: 1);
      }

      final outline = wall(TilesetMaterials.brick).palette[0];
      int outlines(TilesetMaterial m) => generateTileset(wall(m)).single.pixels.where((c) => c == outline).length;
      for (final material in TilesetRecipe.surfacesFor(TilesetBase.wall)) {
        if (!material.faceMortar) {
          expect(outlines(material), lessThan(outlines(TilesetMaterials.brick)),
              reason: '${material.id} has no mortar, so fewer outline-coloured face pixels than brick');
        }
      }
    });
  });
}
