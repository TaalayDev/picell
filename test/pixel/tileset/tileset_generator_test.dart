import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';

void main() {
  test('all 256 neighborhoods resolve to exactly 47 canonical shapes', () {
    expect(platformMasks.length, 47);
    for (var mask = 0; mask < 256; mask++) {
      final canonical = normalizeTileMask(mask);
      expect(platformMasks, contains(canonical));
      expect(normalizeTileMask(canonical), canonical);
      expect(canonical & 15, mask & 15);
    }
  });

  test('diagonal cells cannot connect across missing cardinal neighbors', () {
    expect(normalizeTileMask(240), 0);
    expect(normalizeTileMask(255), 255);
    expect(normalizeTileMask(1 | 2 | 16 | 32), 1 | 2 | 16);
  });

  test('map boundaries are empty and concave corners affect the mask', () {
    expect(tileMaskAt([1], 1, 1, 0, 0), 0);
    expect(tileMaskAt(List.filled(9, 1), 3, 3, 1, 1), 255);
    final cells = List.filled(9, 1)..[0] = 0;
    expect(tileMaskAt(cells, 3, 3, 1, 1), 127);
    expect(tileMaskAt(List.filled(9, 1), 3, 3, 0, 0), 2 | 4 | 32);
  });

  test('each native size generates a complete deterministic set', () {
    for (final size in [16, 32, 48]) {
      final settings = TilesetSettings(size: size, variations: 2);
      final first = generatePlatformTileset(settings);
      final second = generatePlatformTileset(settings);
      expect(first.length, 94);
      expect(first.map((t) => t.id).toSet().length, 94);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].pixels.length, size * size);
        expect(first[i].pixels, orderedEquals(second[i].pixels));
        expect(first[i].pixels.every((p) => p == 0 || settings.palette.contains(p)), isTrue);
      }
    }
  });

  test('variant and regeneration changes leave perimeter pixels unchanged', () {
    final settings = TilesetSettings(variations: 2);
    var interiorChanged = false;
    for (final mask in platformMasks) {
      final original = generatePlatformTile(settings, mask, 0);
      for (final alternate in [
        generatePlatformTile(settings, mask, 1),
        generatePlatformTile(settings, mask, 0, revision: 1)
      ]) {
        for (var y = 0; y < settings.size; y++) {
          for (var x = 0; x < settings.size; x++) {
            final i = y * settings.size + x;
            if (x < 2 || y < 2 || x >= 14 || y >= 14) {
              expect(alternate.pixels[i], original.pixels[i]);
            } else if (alternate.pixels[i] != original.pixels[i]) {
              interiorChanged = true;
            }
          }
        }
      }
    }
    expect(interiorChanged, isTrue);
  });

  test('document round trip keeps edited pixels, protection and revisions', () {
    final settings = TilesetSettings(variations: 1);
    final tiles = generatePlatformTileset(settings);
    final edited = generatePlatformTile(settings, 255, 0, revision: 2);
    edited.pixels[100] = 0xffff00ff;
    tiles[tiles.indexWhere((t) => t.id == edited.id)] = edited.copyWith(protected: true);
    final doc =
        TilesetDocument(name: 'Example', settings: settings, tiles: tiles, cells: [1, 0, 1, 1], columns: 2, rows: 2);
    final restored = TilesetDocument.fromJson(jsonDecode(jsonEncode(doc.toJson())) as Map<String, dynamic>);
    final tile = restored.tiles.firstWhere((t) => t.id == '255:0');
    expect(tile.protected, isTrue);
    expect(tile.revision, 2);
    expect(tile.pixels[100], 0xffff00ff);
    expect(restored.cells, [1, 0, 1, 1]);
    expect(restored.settings.toJson(), settings.toJson());
  });

  test('rejects incomplete documents and unsupported settings', () {
    final settings = TilesetSettings(variations: 1);
    final doc = TilesetDocument(
        name: 'Invalid',
        settings: settings,
        tiles: generatePlatformTileset(settings)..removeLast(),
        cells: [1],
        columns: 1,
        rows: 1);
    expect(() => TilesetDocument.fromJson(doc.toJson()), throwsFormatException);
    expect(() => TilesetSettings(size: 0), throwsArgumentError);
    expect(() => TilesetSettings(variations: 7), throwsArgumentError);
    expect(() => TilesetSettings(seed: -1), throwsArgumentError);
  });
}
