import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_export.dart';

void main() {
  for (final perspective in TilesetPerspective.values) {
    for (final type in supportedTilesetTypes(perspective)) {
      test('PNG pixels and manifest coordinates agree for every ${perspective.name}/${type.name} tile and variation',
          () {
        final settings = TilesetSettings(perspective: perspective, type: type, variations: 2);
        final tiles = generateTileset(settings);
        final doc = TilesetDocument(name: 'Export', settings: settings, tiles: tiles, cells: [1], columns: 1, rows: 1);
        final manifest = tilesetManifest(doc, 'Export.png');
        final atlas = img.decodePng(encodeTilesetAtlas((tiles: tiles, settings: settings)))!;
        expect(atlas.width, manifest['width']);
        expect(atlas.height, manifest['height']);
        final entries = manifest['tiles'] as List;
        expect(entries.length, tiles.length);
        for (var i = 0; i < tiles.length; i++) {
          final entry = entries[i] as Map;
          expect(entry['id'], tiles[i].id);
          for (var y = 0; y < settings.spriteHeight; y++) {
            for (var x = 0; x < settings.spriteWidth; x++) {
              final pixel = atlas.getPixel((entry['x'] as int) + x, (entry['y'] as int) + y);
              final actual = pixel.a.toInt() << 24 | pixel.r.toInt() << 16 | pixel.g.toInt() << 8 | pixel.b.toInt();
              expect(actual, tiles[i].pixels[y * settings.spriteWidth + x]);
            }
          }
        }
      });
    }
  }
}
