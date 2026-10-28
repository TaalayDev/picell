import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_collection.dart';
import 'package:picell/pixel/tileset/tileset_export.dart';
import 'package:picell/pixel/tileset/tileset_geometry.dart';

TilesetDocument document(TilesetSettings s) =>
    TilesetDocument(name: 'Recipe', settings: s, tiles: generateTileset(s), cells: [1], columns: 1, rows: 1);

void main() {
  test('partial recipe documents preserve exact pixels, revisions, protection and export identities', () {
    const recipe = TilesetRecipe(platform: true, vegetation: true);
    final s = TilesetSettings(
        type: recipe.rendererFor(TilesetPerspective.side), recipe: recipe, parts: [255, 55, 110], variations: 2);
    final d = document(s);
    d.tiles[0] = d.tiles[0].copyWith(protected: true);
    d.tiles[0].pixels[20] = 0xffff00ff;
    final restored = TilesetDocument.fromJson(jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>);
    expect(d.toJson()['version'], 4);
    expect(restored.settings.parts, [55, 110, 255]);
    expect(restored.settings.recipe!.toJson(), recipe.toJson());
    expect(restored.tiles.first.pixels[20], 0xffff00ff);
    expect(restored.tiles.first.protected, isTrue);
    expect(restored.tiles.length, 6);
    expect(missingTilesetParts(restored), {0});
    expect(tilesetPlacements(restored), isEmpty);
    expect(renderTilesetPreview(restored).rgba.every((v) => v == 0), isTrue);
    final manifest = tilesetManifest(restored, 'partial.png');
    expect(manifest['version'], 3);
    expect(manifest['partCount'], 3);
    expect(manifest['complete'], isFalse);
    expect((manifest['tiles'] as List).map((t) => t['id']), restored.tiles.map((t) => t.id));
    final png = img.decodePng(encodeTilesetAtlas((tiles: restored.tiles, settings: s)))!;
    expect(png.width, s.spriteWidth * 8);
    expect(png.height, s.spriteHeight);
    expect(() => TilesetDocument.fromJson(d.toJson()..['version'] = 2), throwsFormatException);
    expect(() => TilesetSettings(parts: []), throwsArgumentError);
    expect(() => TilesetSettings(parts: [0, 0]), throwsArgumentError);
    expect(() => TilesetSettings(parts: [256]), throwsArgumentError);
  });

  test('every compatible recipe generates deterministic sprites in all projections', () {
    for (final p in TilesetPerspective.values) {
      for (final base in TilesetRecipe.basesFor(p)) {
        for (final surface in TilesetRecipe.surfacesFor(base)) {
          var recipe = TilesetRecipe(base: base, surface: surface);
          if (recipe.canVegetate) recipe = recipe.copyWith(vegetation: true);
          if (recipe.canPlatform(p)) recipe = recipe.copyWith(platform: true);
          final s = TilesetSettings(
              perspective: p, type: recipe.rendererFor(p), recipe: recipe, parts: [0, 110, 255], variations: 1);
          final a = generateTileset(s), b = generateTileset(s);
          expect(a.length, 3);
          for (var i = 0; i < a.length; i++) {
            expect(a[i].pixels, b[i].pixels);
            expect(a[i].pixels.length, s.spriteWidth * s.spriteHeight);
          }
          expect(TilesetDocument.fromJson(document(s).toJson()).settings.toJson(), s.toJson());
        }
      }
    }
    expect(
        () => const TilesetRecipe(base: TilesetBase.wall, surface: TilesetMaterials.wood, platform: true)
            .rendererFor(TilesetPerspective.side),
        throwsArgumentError);
    expect(() => const TilesetRecipe(platform: true).rendererFor(TilesetPerspective.topDown), throwsArgumentError);
  });

  test('wall subtypes and vegetation produce different artwork; regeneration preserves recipe borders', () {
    final fingerprints = <String>{};
    for (final surface in TilesetRecipe.surfacesFor(TilesetBase.wall)) {
      final recipe = TilesetRecipe(base: TilesetBase.wall, surface: surface);
      final s = TilesetSettings(type: recipe.rendererFor(TilesetPerspective.side), recipe: recipe);
      fingerprints.add(generateTilesetTile(s, 255, 0).pixels.join(','));
    }
    expect(fingerprints.length, TilesetRecipe.surfacesFor(TilesetBase.wall).length);
    const plain = TilesetRecipe(platform: true),
        grass = TilesetRecipe(platform: true, vegetation: true, vegetationDensity: 100);
    final a = TilesetSettings(type: TilesetType.platforms, recipe: plain),
        b = TilesetSettings(type: TilesetType.platforms, recipe: grass);
    expect(generateTilesetTile(a, 110, 0).pixels, isNot(generateTilesetTile(b, 110, 0).pixels));
    for (final mask in platformMasks) {
      final first = generateTilesetTile(b, mask, 0), changed = generateTilesetTile(b, mask, 1, revision: 2);
      for (var y = 0; y < b.size; y++) {
        for (var x = 0; x < b.size; x++) {
          if (x < 2 || y < 2 || x >= b.size - 2 || y >= b.size - 2) {
            expect(first.pixels[y * b.size + x], changed.pixels[y * b.size + x]);
          }
        }
      }
    }
  });

  test('recipe surfaces keep shared edges across all local neighborhoods', () {
    for (final recipe in [
      const TilesetRecipe(platform: true, vegetation: true),
      const TilesetRecipe(base: TilesetBase.wall, surface: TilesetMaterials.wood),
      const TilesetRecipe(base: TilesetBase.wall, surface: TilesetMaterials.stone)
    ]) {
      final s = TilesetSettings(type: recipe.rendererFor(TilesetPerspective.side), recipe: recipe, variations: 2);
      final tiles = {for (final t in generateTileset(s)) t.id: t};
      for (var bits = 0; bits < 4096; bits++) {
        final h = List.generate(12, (i) => (bits >> i) & 1)
          ..[5] = 1
          ..[6] = 1;
        final v = List.generate(12, (i) => (bits >> i) & 1)
          ..[4] = 1
          ..[7] = 1;
        final left = tileMaskAt(h, 4, 3, 1, 1), right = tileMaskAt(h, 4, 3, 2, 1);
        final top = tileMaskAt(v, 3, 4, 1, 1), bottom = tileMaskAt(v, 3, 4, 1, 2);
        final a = tiles['$left:0']!.pixels,
            b = tiles['$right:1']!.pixels,
            c = tiles['$top:1']!.pixels,
            d = tiles['$bottom:0']!.pixels;
        for (var i = 0; i < s.size; i++) {
          if (a[i * s.size + s.size - 1] != b[i * s.size]) fail('Horizontal recipe seam $left/$right/$i');
          if (c[(s.size - 1) * s.size + i] != d[i]) fail('Vertical recipe seam $top/$bottom/$i');
        }
      }
    }
  });

  test('collections migrate old documents and round trip multiple sets without pixel regeneration', () {
    final old = document(TilesetSettings(variations: 1));
    old.tiles.first.pixels[4] = 0xffff00ff;
    old.tiles[0] = old.tiles.first.copyWith(protected: true);
    final migrated = TilesetCollection.fromJson(old.toJson());
    expect(migrated.entries.single.document.tiles.first.pixels[4], 0xffff00ff);
    expect(migrated.entries.single.document.tiles.first.protected, isTrue);
    final next = TilesetCollection(name: 'World', entries: [
      ...migrated.entries,
      TilesetEntry(id: 'second', document: document(TilesetSettings(parts: [0], variations: 1)))
    ]);
    final restored = TilesetCollection.fromJson(jsonDecode(jsonEncode(next.toJson())) as Map<String, dynamic>);
    expect(restored.entries.length, 2);
    expect(restored.entries.first.document.tiles.first.pixels[4], 0xffff00ff);
    expect(restored.entries.last.document.settings.parts, [0]);
    expect(
        () => TilesetCollection.fromJson(
            TilesetCollection(name: 'bad', entries: [migrated.entries.first, migrated.entries.first]).toJson()),
        throwsFormatException);
  });
}
