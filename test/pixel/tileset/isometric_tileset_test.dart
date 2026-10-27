import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_geometry.dart';
import 'package:picell/pixel/tileset/tileset_export.dart';
import 'package:picell/pixel/tileset/tileset_project.dart';

void main() {
  for (final type in supportedTilesetTypes(TilesetPerspective.isometric)) {
    test('isometric ${type.name} has deterministic non-square sprites and suppresses internal faces', () {
      for (final size in [16, 32, 48]) {
        final s = TilesetSettings(perspective: TilesetPerspective.isometric, type: type, size: size, variations: 2);
        final first = generateTileset(s), second = generateTileset(s);
        expect(first.length, 94);
        expect(s.spriteWidth, 2 * size);
        expect(s.spriteHeight, size + s.elevation);
        for (var i = 0; i < first.length; i++) {
          expect(first[i].pixels.length, s.spriteWidth * s.spriteHeight);
          expect(first[i].pixels, second[i].pixels);
          expect(first[i].pixels.every((p) => p == 0 || s.palette.contains(p)), isTrue);
        }
        if (s.elevation > 0) {
          final solid = generateTilesetTile(s, 255, 0), isolated = generateTilesetTile(s, 0, 0);
          expect(solid.pixels.skip(size * s.spriteWidth).every((p) => p == 0), isTrue);
          expect(isolated.pixels.skip(size * s.spriteWidth).any((p) => p != 0), isTrue);
        }
      }
    });

    test('isometric ${type.name} projects and picks logical cell centers at every size', () {
      for (final size in [16, 32, 48]) {
        final s = TilesetSettings(perspective: TilesetPerspective.isometric, type: type, size: size);
        final layout = TilesetLayout(s, 7, 5);
        expect(layout.width, 12 * size);
        expect(layout.height, 6 * size + s.elevation);
        for (var row = 0; row < 5; row++) {
          for (var column = 0; column < 7; column++) {
            final center = layout.vertex(column + 0.5, row + 0.5);
            expect(layout.cellAt(center.x, center.y), (column: column, row: row));
          }
        }
        expect(layout.cellAt(-1, -1), isNull);
        expect(layout.drawOrder.map((c) => c.column + c.row),
            orderedEquals(layout.drawOrder.map((c) => c.column + c.row).toList()..sort()));
      }
    });

    test('isometric ${type.name} composes connected surfaces without interior gaps', () {
      for (final size in [16, 32, 48]) {
        final s = TilesetSettings(perspective: TilesetPerspective.isometric, type: type, size: size, variations: 1);
        final doc = TilesetDocument(
            name: 'Solid', settings: s, tiles: generateTileset(s), cells: List.filled(25, 1), columns: 5, rows: 5);
        final layout = TilesetLayout(s, 5, 5), preview = renderTilesetPreview(doc);
        var checked = 0;
        for (var y = 0; y < 5 * size; y++) {
          for (var x = 0; x < 10 * size; x++) {
            final cell = layout.cellAt(x + 0.5, y + 0.5);
            if (cell == null || cell.column == 0 || cell.column == 4 || cell.row == 0 || cell.row == 4) continue;
            if (preview.rgba[(y * preview.width + x) * 4 + 3] == 0) fail('Interior gap: $size/$x/$y');
            checked++;
          }
        }
        expect(checked, greaterThan(0));
      }
    });

    test('isometric ${type.name} preserves rectangular pixels, projection metadata and thumbnail bounds', () {
      final s = TilesetSettings(perspective: TilesetPerspective.isometric, type: type, variations: 1);
      final doc = TilesetDocument(
          name: 'Iso', settings: s, tiles: generateTileset(s), cells: [1, 1, 1, 0], columns: 2, rows: 2);
      final json = doc.toJson();
      expect(json['version'], 3);
      final loaded = TilesetDocument.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(loaded.tiles.first.pixels, doc.tiles.first.pixels);
      expect(() => TilesetDocument.fromJson(json..['version'] = 2), throwsFormatException);
      final manifest = tilesetManifest(doc, 'iso.png');
      expect(manifest['perspective'], 'iso');
      expect(manifest['type'], type.name);
      expect((manifest['projection'] as Map)['anchor'], {'x': 16, 'y': 0});
      expect((manifest['tiles'] as List).first['width'], s.spriteWidth);
      expect((manifest['tiles'] as List).first['height'], s.spriteHeight);
      final layout = TilesetLayout(s, 2, 2);
      final p = projectWithTileset((
        project:
            Project(id: 1, name: 'Iso', width: 16, height: 16, createdAt: DateTime(2026), editedAt: DateTime(2026)),
        document: doc
      ));
      expect(p.width, layout.width);
      expect(p.height, layout.height);
      expect(p.thumbnail!.length, layout.width * layout.height * 4);
      expect(p.tileWidth, s.spriteWidth);
      expect(p.tileHeight, s.spriteHeight);
    });
  }

  test('raised faces pick the visible front sprite outside its top diamond', () {
    for (final type in [TilesetType.raisedBlocks, TilesetType.walls]) {
      final s = TilesetSettings(perspective: TilesetPerspective.isometric, type: type, variations: 1);
      final doc =
          TilesetDocument(name: 'Block', settings: s, tiles: generateTileset(s), cells: [1], columns: 1, rows: 1);
      final layout = TilesetLayout(s, 1, 1), tile = doc.tiles.first;
      var checked = 0;
      for (var y = s.size; y < s.spriteHeight; y++) {
        for (var x = 0; x < s.spriteWidth; x++) {
          if (tile.pixels[y * s.spriteWidth + x] >> 24 == 0) continue;
          if (layout.cellAt(x + 0.5, y + 0.5) != null) continue;
          expect(pickTilesetCell(doc, x + 0.5, y + 0.5), (column: 0, row: 0));
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    }
  });

  test('occlusion-aware picking agrees with the composed pixel color', () {
    final s = TilesetSettings(perspective: TilesetPerspective.isometric, type: TilesetType.walls, variations: 1);
    final doc = TilesetDocument(
        name: 'Walls', settings: s, tiles: generateTileset(s), cells: [1, 1, 1, 0], columns: 2, rows: 2);
    final preview = renderTilesetPreview(doc), layout = TilesetLayout(s, 2, 2);
    final tiles = {for (final placement in tilesetPlacements(doc)) (placement.column, placement.row): placement.tile};
    for (var y = 0; y < preview.height; y++) {
      for (var x = 0; x < preview.width; x++) {
        final i = (y * preview.width + x) * 4;
        if (preview.rgba[i + 3] == 0) continue;
        final picked = pickTilesetCell(doc, x + 0.5, y + 0.5)!;
        final origin = layout.origin(picked.column, picked.row);
        final pixel = tiles[(picked.column, picked.row)]!.pixels[(y - origin.y) * s.spriteWidth + x - origin.x];
        expect(preview.rgba.sublist(i, i + 4), [pixel >> 16 & 255, pixel >> 8 & 255, pixel & 255, pixel >> 24]);
      }
    }
  });
}
