import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/project_model.dart';
import 'tileset_generator.dart';
import 'tileset_collection.dart';
import 'tileset_geometry.dart';

/// A tileset project whose geometry was chosen before it was created.
Project newTilesetProject({required String name, required TilesetGeometry geometry, required DateTime now}) => Project(
      id: 0,
      name: name,
      width: 16,
      height: 16,
      type: ProjectType.proceduralTileset,
      createdAt: now,
      editedAt: now,
      tilesetData: jsonEncode(
          TilesetCollection(name: name, perspective: geometry.perspective, tileSize: geometry.size).toJson()),
    );

/// Produces the library's raw RGBA thumbnail from the actual sample geometry.
Project projectWithTileset(({Project project, TilesetDocument document}) args) {
  final doc = args.document;
  final preview = renderTilesetPreview(doc);
  return args.project.copyWith(
    name: doc.name.trim(),
    type: ProjectType.proceduralTileset,
    width: preview.width,
    height: preview.height,
    tileWidth: doc.settings.spriteWidth,
    tileHeight: doc.settings.spriteHeight,
    gridColumns: doc.columns,
    gridRows: doc.rows,
    thumbnail: preview.rgba,
    tilesetData: jsonEncode(doc.toJson()),
    editedAt: DateTime.now(),
  );
}

/// Persist the collection atomically; the first set supplies the library cover.
Project projectWithTilesetCollection(({Project project, TilesetCollection collection}) args) {
  final collection = args.collection;
  var cover = collection.entries.isEmpty
      ? args.project.copyWith(width: 32, height: 32, thumbnail: Uint8List(32 * 32 * 4))
      : projectWithTileset((project: args.project, document: collection.entries.first.document));
  if (collection.entries.isNotEmpty && (cover.thumbnail?.every((v) => v == 0) ?? true)) {
    final doc = collection.entries.first.document, tile = collection.entries.first.document.tiles.first;
    final rgba = Uint8List(tile.pixels.length * 4);
    for (var i = 0; i < tile.pixels.length; i++) {
      final color = tile.pixels[i];
      rgba[i * 4] = color >> 16 & 255;
      rgba[i * 4 + 1] = color >> 8 & 255;
      rgba[i * 4 + 2] = color & 255;
      rgba[i * 4 + 3] = color >> 24;
    }
    cover = cover.copyWith(width: doc.settings.spriteWidth, height: doc.settings.spriteHeight, thumbnail: rgba);
  }
  return cover.copyWith(
      name: collection.name.trim(),
      type: ProjectType.proceduralTileset,
      tilesetData: jsonEncode(collection.toJson()),
      editedAt: DateTime.now());
}
