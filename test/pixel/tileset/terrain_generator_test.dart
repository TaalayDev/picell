import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_export.dart';
import 'package:picell/pixel/tileset/tileset_project.dart';
import 'package:picell/data/models/project_model.dart';

void main() {
  test('terrain generates native, deterministic surfaces rather than platform sides', () {
    for (final size in [16, 32, 48]) {
      final settings = TilesetSettings(perspective: TilesetPerspective.topDown, size: size, variations: 2);
      final first = generateTileset(settings), second = generateTileset(settings);
      expect(first.length, 94);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].pixels.length, size * size);
        expect(first[i].pixels, orderedEquals(second[i].pixels));
        expect(first[i].pixels.every((p) => p == 0 || settings.palette.contains(p)), isTrue);
      }
      final flat = TilesetSettings(perspective: TilesetPerspective.topDown, size: size, density: 0);
      final fill = generateTilesetTile(flat, 255, 0);
      expect(fill.pixels.every((c) => c == flat.palette[2]), isTrue);
      final side = generateTilesetTile(TilesetSettings(size: size, density: 0), 255, 0);
      expect(side.pixels, isNot(orderedEquals(fill.pixels)));
    }
  });

  test('terrain variants and regeneration keep every mask perimeter unchanged', () {
    for (final size in [16, 32, 48]) {
      final settings = TilesetSettings(perspective: TilesetPerspective.topDown, size: size, variations: 2);
      final band = size ~/ 8;
      var interiorChanged = false;
      for (final mask in platformMasks) {
        final first = generateTilesetTile(settings, mask, 0);
        for (final alternate in [
          generateTilesetTile(settings, mask, 1),
          generateTilesetTile(settings, mask, 0, revision: 1)
        ]) {
          for (var y = 0; y < size; y++) {
            for (var x = 0; x < size; x++) {
              final i = y * size + x;
              if (x < band || y < band || x >= size - band || y >= size - band) {
                if (first.pixels[i] != alternate.pixels[i]) fail('Changed perimeter: $size/$mask/$x/$y');
              } else if (first.pixels[i] != alternate.pixels[i]) {
                interiorChanged = true;
              }
            }
          }
        }
      }
      expect(interiorChanged, isTrue);
    }
  });

  test('every shared terrain edge matches for all 4096 local neighborhoods', () {
    for (final size in [16, 32, 48]) {
      final settings = TilesetSettings(perspective: TilesetPerspective.topDown, size: size, variations: 2);
      final tiles = {for (final t in generateTileset(settings)) t.id: t};
      for (var bits = 0; bits < 4096; bits++) {
        final horizontal = List.generate(12, (i) => (bits >> i) & 1)
          ..[5] = 1
          ..[6] = 1;
        final left = tileMaskAt(horizontal, 4, 3, 1, 1), right = tileMaskAt(horizontal, 4, 3, 2, 1);
        final a = tiles['$left:0']!.pixels, b = tiles['$right:1']!.pixels;
        final vertical = List.generate(12, (i) => (bits >> i) & 1)
          ..[4] = 1
          ..[7] = 1;
        final top = tileMaskAt(vertical, 3, 4, 1, 1), bottom = tileMaskAt(vertical, 3, 4, 1, 2);
        final c = tiles['$top:1']!.pixels, d = tiles['$bottom:0']!.pixels;
        for (var offset = 0; offset < size; offset++) {
          if (a[offset * size + size - 1] != b[offset * size]) {
            fail('Horizontal seam: size=$size masks=$left/$right offset=$offset');
          }
          if (c[(size - 1) * size + offset] != d[offset]) {
            fail('Vertical seam: size=$size masks=$top/$bottom offset=$offset');
          }
        }
      }
    }
  });

  test('legacy v1 platform documents remain readable and keep their pixels', () {
    final settings = TilesetSettings(variations: 1);
    final original = TilesetDocument(
        name: 'Legacy', settings: settings, tiles: generatePlatformTileset(settings), cells: [1], columns: 1, rows: 1);
    final legacy = original.toJson()..['version'] = 1;
    (legacy['settings'] as Map)
      ..remove('perspective')
      ..remove('type');
    final restored = TilesetDocument.fromJson(jsonDecode(jsonEncode(legacy)) as Map<String, dynamic>);
    expect(restored.settings.perspective, TilesetPerspective.side);
    expect(restored.settings.type, TilesetType.platforms);
    expect(restored.tiles.last.pixels, original.tiles.last.pixels);
    expect(generateTileset(restored.settings).last.pixels, original.tiles.last.pixels);
  });

  test('terrain metadata survives document, project and manifest serialization', () {
    final settings = TilesetSettings(perspective: TilesetPerspective.topDown, variations: 1);
    final original = TilesetDocument(
        name: 'Terrain', settings: settings, tiles: generateTileset(settings), cells: [1, 0], columns: 2, rows: 1);
    final restored = TilesetDocument.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
    expect(restored.settings.perspective, TilesetPerspective.topDown);
    expect(restored.settings.type, TilesetType.terrain);
    final manifest = tilesetManifest(restored, 'terrain.png');
    expect(manifest['perspective'], 'top');
    expect(manifest['type'], 'terrain');
    expect((manifest['tiles'] as List).first['role'], 'Single terrain patch');
    expect((manifest['tiles'] as List).first['group'], 'Isolated Terrain');
    final project = projectWithTileset((
      project:
          Project(id: 1, name: 'Terrain', width: 16, height: 16, createdAt: DateTime(2026), editedAt: DateTime(2026)),
      document: restored
    ));
    final fromProject = TilesetDocument.fromJson(jsonDecode(project.tilesetData!) as Map<String, dynamic>);
    expect(fromProject.settings.perspective, TilesetPerspective.topDown);
    expect(project.thumbnail!.length, 32 * 16 * 4);
  });

  test('rejects unsupported perspective/type combinations and conflicting metadata', () {
    expect(() => TilesetSettings(perspective: TilesetPerspective.topDown, type: TilesetType.platforms),
        throwsArgumentError);
    final settings = TilesetSettings(perspective: TilesetPerspective.topDown, variations: 1);
    final doc = TilesetDocument(
        name: 'Terrain', settings: settings, tiles: generateTileset(settings), cells: [1], columns: 1, rows: 1);
    expect(() => TilesetDocument.fromJson(doc.toJson()..['perspective'] = 'side'), throwsFormatException);
    expect(() => TilesetDocument.fromJson(doc.toJson()..['version'] = 1), throwsFormatException);
    expect(() => TilesetPerspective.parse('unknown'), throwsFormatException);
  });
}
