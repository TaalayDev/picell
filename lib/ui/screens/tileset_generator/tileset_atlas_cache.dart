import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../../../pixel/tileset/tileset_canvas.dart';
import '../../../pixel/tileset/tileset_collection.dart';

class _Atlas {
  _Atlas(this.tiles);
  final List<Object?> tiles;
  ui.Image? image;
  bool decoding = false, ready = false;
}

/// One decoded image per set, laid out like the exported atlas. Sets and
/// single tiles on the canvas draw sub-rectangles of it, so panning stays cheap.
class TilesetAtlasCache extends ChangeNotifier {
  final _atlases = <String, _Atlas>{};
  bool _disposed = false;

  static int columnsFor(TilesetEntry entry) {
    final n = entry.document.tiles.length;
    return n < tilesetCanvasColumns ? (n < 1 ? 1 : n) : tilesetCanvasColumns;
  }

  /// Pixel size of the atlas image for [entry].
  static ({int width, int height}) sizeOf(TilesetEntry entry) {
    final s = entry.document.settings, n = entry.document.tiles.length;
    final rows = (n + tilesetCanvasColumns - 1) ~/ tilesetCanvasColumns;
    return (width: columnsFor(entry) * s.spriteWidth, height: (rows < 1 ? 1 : rows) * s.spriteHeight);
  }

  /// Source rectangle of the tile with [tileId], or null when it no longer exists.
  static ui.Rect? tileRect(TilesetEntry entry, String tileId) {
    final tiles = entry.document.tiles;
    final index = tiles.indexWhere((t) => t.id == tileId);
    if (index < 0) return null;
    final s = entry.document.settings, columns = columnsFor(entry);
    return ui.Rect.fromLTWH((index % columns) * s.spriteWidth.toDouble(),
        (index ~/ columns) * s.spriteHeight.toDouble(), s.spriteWidth.toDouble(), s.spriteHeight.toDouble());
  }

  /// The decoded atlas, or the previous one while a newer one decodes.
  /// Decoding starts on first use and listeners are notified when it lands.
  ui.Image? imageFor(TilesetEntry entry) {
    final tiles = entry.document.tiles;
    var atlas = _atlases[entry.id];
    if (atlas == null || !identical(atlas.tiles, tiles)) {
      final old = atlas?.image;
      atlas = _Atlas(tiles)..image = old;
      _atlases[entry.id] = atlas;
    }
    if (!atlas.ready && !atlas.decoding) _decode(entry, atlas);
    return atlas.image;
  }

  void _decode(TilesetEntry entry, _Atlas atlas) {
    atlas.decoding = true;
    final size = sizeOf(entry), s = entry.document.settings, columns = columnsFor(entry);
    final rgba = Uint8List(size.width * size.height * 4);
    final tiles = entry.document.tiles;
    for (var i = 0; i < tiles.length; i++) {
      final ox = (i % columns) * s.spriteWidth, oy = (i ~/ columns) * s.spriteHeight;
      final pixels = tiles[i].pixels;
      for (var y = 0; y < s.spriteHeight; y++) {
        for (var x = 0; x < s.spriteWidth; x++) {
          final c = pixels[y * s.spriteWidth + x], o = ((oy + y) * size.width + ox + x) * 4;
          rgba[o] = (c >> 16) & 255;
          rgba[o + 1] = (c >> 8) & 255;
          rgba[o + 2] = c & 255;
          rgba[o + 3] = c >> 24;
        }
      }
    }
    ui.decodeImageFromPixels(rgba, size.width, size.height, ui.PixelFormat.rgba8888, (image) {
      atlas.decoding = false;
      if (_disposed || !identical(_atlases[entry.id], atlas)) {
        image.dispose();
        return;
      }
      atlas.image?.dispose();
      atlas.image = image;
      atlas.ready = true;
      notifyListeners();
    });
  }

  /// Frees atlases of sets that are gone.
  void retain(Set<String> entryIds) {
    for (final id in _atlases.keys.where((id) => !entryIds.contains(id)).toList()) {
      final atlas = _atlases.remove(id)!;
      atlas.image?.dispose();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final atlas in _atlases.values) {
      atlas.image?.dispose();
    }
    _atlases.clear();
    super.dispose();
  }
}
