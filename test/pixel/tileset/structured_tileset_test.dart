import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_export.dart';

void main() {
  final newModes = [
    (TilesetPerspective.side, TilesetType.ground),
    (TilesetPerspective.side, TilesetType.walls),
    (TilesetPerspective.topDown, TilesetType.paths),
    (TilesetPerspective.topDown, TilesetType.walls),
    (TilesetPerspective.topDown, TilesetType.floors),
  ];
  for (final (perspective, type) in newModes) {
    test('${perspective.name}/${type.name} is deterministic, complete and preserves variation boundaries', () {
      for (final size in [16, 32, 48]) {
        final s = TilesetSettings(perspective: perspective, type: type, size: size, variations: 2);
        final first = generateTileset(s), second = generateTileset(s);
        expect(first.length, 94);
        final band = size ~/ 8;
        var interiorChanges = false;
        for (var i = 0; i < first.length; i++) {
          expect(first[i].pixels, orderedEquals(second[i].pixels));
          expect(first[i].pixels.every((p) => p == 0 || s.palette.contains(p)), isTrue);
          final other = generateTilesetTile(s, first[i].mask, 1 - first[i].variation, revision: 1);
          for (var y = 0; y < size; y++) {
            for (var x = 0; x < size; x++) {
              final p = y * size + x;
              if (x < band || y < band || x >= size - band || y >= size - band) {
                if (first[i].pixels[p] != other.pixels[p]) fail('Boundary changed $size/${first[i].mask}/$x/$y');
              } else if (first[i].pixels[p] != other.pixels[p]) {
                interiorChanges = true;
              }
            }
          }
        }
        expect(interiorChanges, isTrue);
      }
    });

    test('${perspective.name}/${type.name} matches every shared edge in all local neighborhoods', () {
      for (final size in [16, 32, 48]) {
        final s = TilesetSettings(perspective: perspective, type: type, size: size, variations: 2);
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
          final a = tiles['$left:0']!.pixels, b = tiles['$right:1']!.pixels;
          final c = tiles['$top:1']!.pixels, d = tiles['$bottom:0']!.pixels;
          for (var i = 0; i < size; i++) {
            if (a[i * size + size - 1] != b[i * size]) fail('Horizontal seam $size/$left/$right/$i');
            if (c[(size - 1) * size + i] != d[i]) fail('Vertical seam $size/$top/$bottom/$i');
          }
        }
      }
    });

    test('${perspective.name}/${type.name} survives document and export serialization', () {
      final s = TilesetSettings(perspective: perspective, type: type, variations: 1);
      final doc =
          TilesetDocument(name: type.label, settings: s, tiles: generateTileset(s), cells: [1], columns: 1, rows: 1);
      final restored = TilesetDocument.fromJson(jsonDecode(jsonEncode(doc.toJson())) as Map<String, dynamic>);
      expect(restored.settings.type, type);
      expect(restored.settings.perspective, perspective);
      final manifest = tilesetManifest(restored, 'tiles.png');
      expect(manifest['type'], type.name);
      expect(manifest['perspective'], perspective.id);
      expect((manifest['tiles'] as List).first['group'], isolatedTileGroup(perspective, type));
      expect(() => TilesetDocument.fromJson(doc.toJson()..['version'] = 1), throwsFormatException);
    });
  }

  test('supported combinations have distinct rendering and reject incompatible types', () {
    final fingerprints = <String>{};
    var modes = 0;
    for (final p in TilesetPerspective.values) {
      for (final t in supportedTilesetTypes(p)) {
        final s = TilesetSettings(perspective: p, type: t);
        fingerprints.add(generateTilesetTile(s, 255, 0).pixels.join(','));
        modes++;
      }
    }
    expect(modes, 10);
    expect(fingerprints.length, 10);
    expect(() => TilesetSettings(type: TilesetType.paths), throwsArgumentError);
    expect(() => TilesetSettings(type: TilesetType.floors), throwsArgumentError);
    expect(
        () => TilesetSettings(perspective: TilesetPerspective.topDown, type: TilesetType.ground), throwsArgumentError);
  });
}
