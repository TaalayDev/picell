import 'dart:convert';

import '../../data/models/project_model.dart';
import 'tileset_generator.dart';
import 'tileset_geometry.dart';

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
