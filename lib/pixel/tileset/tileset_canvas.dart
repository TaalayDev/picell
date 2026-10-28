import 'tileset_collection.dart';
import 'tileset_generator.dart';

/// What a canvas item shows. Sets and tiles reference collection entries;
/// notes are free text.
enum TilesetCanvasKind { set, tile, note }

/// Atlas width used by the canvas, matching the export ordering.
const tilesetCanvasColumns = 8;
const _maxCoordinate = 100000;

/// One element on the infinite canvas. Positions and sizes are in cells; one
/// cell is the project's tile size, so layouts do not depend on zoom.
class TilesetCanvasItem {
  const TilesetCanvasItem(
      {required this.id,
      required this.kind,
      required this.x,
      required this.y,
      this.entryId,
      this.tileId,
      this.text = '',
      this.width = 6,
      this.height = 2});
  final String id;
  final TilesetCanvasKind kind;
  final int x, y;
  final String? entryId, tileId;
  final String text;

  /// Only notes store their own size; sets and tiles derive it from their pixels.
  final int width, height;

  TilesetCanvasItem copyWith({int? x, int? y, String? text, int? width, int? height}) => TilesetCanvasItem(
      id: id,
      kind: kind,
      x: x ?? this.x,
      y: y ?? this.y,
      entryId: entryId,
      tileId: tileId,
      text: text ?? this.text,
      width: width ?? this.width,
      height: height ?? this.height);

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'x': x,
        'y': y,
        if (entryId != null) 'entry': entryId,
        if (tileId != null) 'tile': tileId,
        if (kind == TilesetCanvasKind.note) ...{'text': text, 'width': width, 'height': height},
      };

  factory TilesetCanvasItem.fromJson(Map<String, dynamic> json) {
    final kind = TilesetCanvasKind.values.firstWhere((k) => k.name == json['kind'],
        orElse: () => throw const FormatException('Unsupported canvas item'));
    final x = json['x'], y = json['y'];
    if (json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        x is! int ||
        y is! int ||
        x.abs() > _maxCoordinate ||
        y.abs() > _maxCoordinate) {
      throw const FormatException('Invalid canvas item');
    }
    final entry = json['entry'], tile = json['tile'];
    if (kind != TilesetCanvasKind.note && entry is! String) throw const FormatException('Canvas item needs a set');
    if (kind == TilesetCanvasKind.tile && tile is! String) throw const FormatException('Canvas tile needs a tile');
    final text = json['text'] as String? ?? '';
    final width = json['width'] as int? ?? 6, height = json['height'] as int? ?? 2;
    if (width < 1 || width > 64 || height < 1 || height > 64) throw const FormatException('Invalid note size');
    return TilesetCanvasItem(
        id: json['id'] as String,
        kind: kind,
        x: x,
        y: y,
        entryId: entry as String?,
        tileId: tile as String?,
        text: text.length > 500 ? text.substring(0, 500) : text,
        width: width,
        height: height);
  }
}

/// Immutable canvas layout stored in the collection.
class TilesetCanvas {
  const TilesetCanvas([this.items = const []]);
  final List<TilesetCanvasItem> items;

  Map<String, dynamic> toJson() => {'items': items.map((i) => i.toJson()).toList()};

  factory TilesetCanvas.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List).map((i) => TilesetCanvasItem.fromJson(i as Map<String, dynamic>)).toList();
    if (items.map((i) => i.id).toSet().length != items.length) throw const FormatException('Duplicate canvas items');
    return TilesetCanvas(List.unmodifiable(items));
  }

  TilesetCanvasItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  TilesetCanvas replacing(Iterable<TilesetCanvasItem> updated) {
    final byId = {for (final item in updated) item.id: item};
    return TilesetCanvas(List.unmodifiable([for (final item in items) byId[item.id] ?? item]));
  }

  TilesetCanvas adding(TilesetCanvasItem item) => TilesetCanvas(List.unmodifiable([...items, item]));
  TilesetCanvas removing(Set<String> ids) => TilesetCanvas(List.unmodifiable(items.where((i) => !ids.contains(i.id))));

  /// Drops items whose set or tile no longer exists.
  TilesetCanvas pruned(List<TilesetEntry> entries) {
    final tiles = {
      for (final entry in entries) entry.id: {for (final tile in entry.document.tiles) tile.id}
    };
    final kept = items.where((item) {
      if (item.kind == TilesetCanvasKind.note) return true;
      final known = tiles[item.entryId];
      if (known == null) return false;
      return item.kind == TilesetCanvasKind.set || known.contains(item.tileId);
    }).toList();
    return kept.length == items.length ? this : TilesetCanvas(List.unmodifiable(kept));
  }
}

({int width, int height}) tilesetAtlasCells(TilesetDocument document, int tileSize) {
  final count = document.tiles.length.clamp(1, 1 << 20);
  final columns = count < tilesetCanvasColumns ? count : tilesetCanvasColumns;
  final rows = (count + tilesetCanvasColumns - 1) ~/ tilesetCanvasColumns;
  return (
    width: (columns * document.settings.spriteWidth + tileSize - 1) ~/ tileSize,
    height: (rows * document.settings.spriteHeight + tileSize - 1) ~/ tileSize,
  );
}

/// Size of [item] in cells; null when the item's set no longer exists.
({int width, int height})? tilesetCanvasItemCells(
    TilesetCanvasItem item, Map<String, TilesetEntry> entries, int tileSize) {
  if (item.kind == TilesetCanvasKind.note) return (width: item.width, height: item.height);
  final entry = entries[item.entryId];
  if (entry == null) return null;
  final settings = entry.document.settings;
  return item.kind == TilesetCanvasKind.set
      ? tilesetAtlasCells(entry.document, tileSize)
      : (
          width: (settings.spriteWidth + tileSize - 1) ~/ tileSize,
          height: (settings.spriteHeight + tileSize - 1) ~/ tileSize,
        );
}

const _gap = 1;

/// First position where a [width]×[height] block keeps a one-cell gap to every
/// [occupied] rectangle (x, y, width, height). Without [anchor] the result is the
/// first free spot in reading order; with it, the free spot nearest to the anchor.
({int x, int y}) firstFreeCanvasSpot(int width, int height, List<({int x, int y, int width, int height})> occupied,
    {({int x, int y})? anchor}) {
  final xs = <int>{0, if (anchor != null) anchor.x, for (final r in occupied) r.x + r.width + _gap}.toList()..sort();
  final ys = <int>{0, if (anchor != null) anchor.y, for (final r in occupied) r.y + r.height + _gap}.toList()..sort();
  bool free(int x, int y) => occupied.every((r) =>
      x + width + _gap <= r.x || r.x + r.width + _gap <= x || y + height + _gap <= r.y || r.y + r.height + _gap <= y);
  ({int x, int y})? best;
  var bestDistance = 1 << 62;
  for (final y in ys) {
    for (final x in xs) {
      if (!free(x, y)) continue;
      if (anchor == null) return (x: x, y: y);
      final dx = x - anchor.x, dy = y - anchor.y, distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        best = (x: x, y: y);
        bestDistance = distance;
      }
    }
  }
  return best ?? (x: 0, y: ys.last);
}

/// Adds [item] at a free spot (nearest to [anchor] when given) and returns the new canvas.
TilesetCanvas placeOnTilesetCanvas(
    TilesetCanvas canvas, TilesetCanvasItem item, Map<String, TilesetEntry> entries, int tileSize,
    {({int x, int y})? anchor}) {
  final size = tilesetCanvasItemCells(item, entries, tileSize);
  if (size == null) return canvas;
  final occupied = <({int x, int y, int width, int height})>[];
  for (final other in canvas.items) {
    final cells = tilesetCanvasItemCells(other, entries, tileSize);
    if (cells != null) occupied.add((x: other.x, y: other.y, width: cells.width, height: cells.height));
  }
  final spot = firstFreeCanvasSpot(size.width, size.height, occupied, anchor: anchor);
  return canvas.adding(TilesetCanvasItem(
      id: item.id,
      kind: item.kind,
      entryId: item.entryId,
      tileId: item.tileId,
      text: item.text,
      width: item.width,
      height: item.height,
      x: spot.x,
      y: spot.y));
}

/// Places every set in a flowing grid; used for collections saved before the canvas existed.
TilesetCanvas autoLayoutTilesetCanvas(List<TilesetEntry> entries, int tileSize, {int rowWidth = 48}) {
  final items = <TilesetCanvasItem>[];
  var x = 0, y = 0, rowHeight = 0;
  for (final entry in entries) {
    final size = tilesetAtlasCells(entry.document, tileSize);
    if (x > 0 && x + size.width > rowWidth) {
      x = 0;
      y += rowHeight + _gap + 1;
      rowHeight = 0;
    }
    items.add(TilesetCanvasItem(id: 'set-${entry.id}', kind: TilesetCanvasKind.set, entryId: entry.id, x: x, y: y));
    x += size.width + _gap + 1;
    if (size.height > rowHeight) rowHeight = size.height;
  }
  return TilesetCanvas(List.unmodifiable(items));
}
