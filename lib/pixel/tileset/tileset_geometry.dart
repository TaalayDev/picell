import 'dart:typed_data';
import 'tileset_generator.dart';

/// Shared layout for the preview, pointer picking, and library thumbnail.
class TilesetLayout {
  TilesetLayout(this.settings, this.columns, this.rows);
  final TilesetSettings settings;
  final int columns, rows;
  bool get isometric => settings.perspective == TilesetPerspective.isometric;
  int get width => isometric ? (columns + rows) * settings.size : columns * settings.size;
  int get height => isometric ? (columns + rows) * settings.size ~/ 2 + settings.elevation : rows * settings.size;
  ({int x, int y}) origin(int column, int row) => isometric
      ? (x: (column - row + rows - 1) * settings.size, y: (column + row) * settings.size ~/ 2)
      : (x: column * settings.size, y: row * settings.size);
  ({double x, double y}) vertex(double column, double row) => isometric
      ? (x: (column - row + rows) * settings.size, y: (column + row) * settings.size / 2)
      : (x: column * settings.size, y: row * settings.size);
  ({int column, int row})? cellAt(double x, double y) {
    final int column, row;
    if (isometric) {
      final dx = (x - rows * settings.size) / settings.size, dy = y / (settings.size / 2);
      column = ((dy + dx) / 2).floor();
      row = ((dy - dx) / 2).floor();
    } else {
      column = (x / settings.size).floor();
      row = (y / settings.size).floor();
    }
    return column >= 0 && row >= 0 && column < columns && row < rows ? (column: column, row: row) : null;
  }

  Iterable<({int column, int row})> get drawOrder sync* {
    if (!isometric) {
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < columns; col++) {
          yield (column: col, row: row);
        }
      }
    } else {
      for (var diagonal = 0; diagonal < columns + rows - 1; diagonal++) {
        for (var row = 0; row < rows; row++) {
          final col = diagonal - row;
          if (col >= 0 && col < columns) yield (column: col, row: row);
        }
      }
    }
  }
}

typedef TilesetPlacement = ({int column, int row, int x, int y, GeneratedTile tile});
Iterable<TilesetPlacement> tilesetPlacements(TilesetDocument doc) sync* {
  final layout = TilesetLayout(doc.settings, doc.columns, doc.rows);
  final byId = {for (final tile in doc.tiles) tile.id: tile};
  for (final cell in layout.drawOrder) {
    if (doc.cells[cell.row * doc.columns + cell.column] == 0) continue;
    final mask = tileMaskAt(doc.cells, doc.columns, doc.rows, cell.column, cell.row);
    final variant = tileHash(cell.column, cell.row, doc.settings.seed) % doc.settings.variations;
    final origin = layout.origin(cell.column, cell.row);
    yield (column: cell.column, row: cell.row, x: origin.x, y: origin.y, tile: byId['$mask:$variant']!);
  }
}

/// Raised faces may cover another cell. Pick the last painted nontransparent
/// sprite pixel first, then fall back to the empty grid's inverse projection.
({int column, int row})? pickTilesetCell(TilesetDocument doc, double x, double y) {
  final layout = TilesetLayout(doc.settings, doc.columns, doc.rows);
  if (layout.isometric && doc.settings.elevation > 0) {
    for (final placement in tilesetPlacements(doc).toList().reversed) {
      final px = (x - placement.x).floor(), py = (y - placement.y).floor();
      if (px < 0 || py < 0 || px >= doc.settings.spriteWidth || py >= doc.settings.spriteHeight) continue;
      if (placement.tile.pixels[py * doc.settings.spriteWidth + px] >> 24 != 0) {
        return (column: placement.column, row: placement.row);
      }
    }
  }
  return layout.cellAt(x, y);
}

({int width, int height, Uint8List rgba}) renderTilesetPreview(TilesetDocument doc) {
  final layout = TilesetLayout(doc.settings, doc.columns, doc.rows);
  final rgba = Uint8List(layout.width * layout.height * 4);
  for (final placement in tilesetPlacements(doc)) {
    for (var y = 0; y < doc.settings.spriteHeight; y++) {
      for (var x = 0; x < doc.settings.spriteWidth; x++) {
        final c = placement.tile.pixels[y * doc.settings.spriteWidth + x];
        final alpha = c >> 24;
        if (alpha == 0) continue; // Keep the sprite behind transparent top/face pixels.
        final offset = ((placement.y + y) * layout.width + placement.x + x) * 4;
        for (var channel = 0; channel < 3; channel++) {
          final value = c >> (16 - channel * 8) & 255;
          final oldAlpha = rgba[offset + 3];
          final outAlpha = alpha + oldAlpha * (255 - alpha) ~/ 255;
          rgba[offset + channel] = outAlpha == 0
              ? 0
              : (value * alpha + rgba[offset + channel] * oldAlpha * (255 - alpha) ~/ 255) ~/ outAlpha;
        }
        rgba[offset + 3] = alpha + rgba[offset + 3] * (255 - alpha) ~/ 255;
      }
    }
  }
  return (width: layout.width, height: layout.height, rgba: rgba);
}
