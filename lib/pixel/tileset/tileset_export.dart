import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'tileset_generator.dart';

/// The atlas and manifest share the same row-major tile ordering.
Uint8List encodeTilesetAtlas(({List<GeneratedTile> tiles, TilesetSettings settings}) args) {
  const columns = 8;
  final width = args.settings.spriteWidth, height = args.settings.spriteHeight;
  final image = img.Image(
      width: columns * width, height: ((args.tiles.length + columns - 1) ~/ columns) * height, numChannels: 4);
  for (var i = 0; i < args.tiles.length; i++) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final c = args.tiles[i].pixels[y * width + x];
        image.setPixelRgba(
            (i % columns) * width + x, (i ~/ columns) * height + y, (c >> 16) & 255, (c >> 8) & 255, c & 255, c >> 24);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Map<String, dynamic> tilesetManifest(TilesetDocument document, String imageName) {
  final size = document.settings.size;
  final spriteWidth = document.settings.spriteWidth, spriteHeight = document.settings.spriteHeight;
  return {
    'version': document.settings.perspective == TilesetPerspective.isometric ? 2 : 1,
    'image': imageName,
    'perspective': document.settings.perspective.id,
    'type': document.settings.type.name,
    'tileSize': size,
    'columns': 8,
    'width': 8 * spriteWidth,
    'height': ((document.tiles.length + 7) ~/ 8) * spriteHeight,
    'generatorVersion': 1,
    'spriteWidth': spriteWidth,
    'spriteHeight': spriteHeight,
    if (document.settings.perspective == TilesetPerspective.isometric)
      'projection': {
        'kind': 'isometric',
        'ratio': '2:1',
        'cellWidth': size * 2,
        'cellHeight': size,
        'elevation': document.settings.elevation,
        'anchor': {'x': size, 'y': 0},
        'columnStep': {'x': size, 'y': size ~/ 2},
        'rowStep': {'x': -size, 'y': size ~/ 2},
        'drawOrder': 'column+row ascending, row ascending',
        'maskSpace': 'logical grid axes, before projection',
      },
    'settings': document.settings.toJson(),
    'maskBits': ['N', 'E', 'S', 'W', 'NE', 'SE', 'SW', 'NW'],
    'diagonalRule': 'A diagonal bit is ignored unless both adjacent cardinal bits are set.',
    'outsideGrid': 'empty',
    'tiles': [
      for (var i = 0; i < document.tiles.length; i++)
        {
          'id': document.tiles[i].id,
          'mask': document.tiles[i].mask,
          'role': document.tiles[i].nameFor(document.settings.perspective, type: document.settings.type),
          'group': document.tiles[i].groupFor(document.settings.perspective, type: document.settings.type),
          'variation': document.tiles[i].variation,
          'x': i % 8 * spriteWidth,
          'y': i ~/ 8 * spriteHeight,
          'width': spriteWidth,
          'height': spriteHeight,
        }
    ],
  };
}
