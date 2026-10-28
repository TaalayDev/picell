import 'tileset_canvas.dart';
import 'tileset_generator.dart';
import 'tileset_configuration.dart';

class TilesetEntry {
  const TilesetEntry({required this.id, required this.document, this.configuration});
  final String id;
  final TilesetDocument document;
  final TilesetConfiguration? configuration;
  TilesetConfiguration get resolvedConfiguration => configuration ?? TilesetConfiguration.fromDocument(document);
  Map<String, dynamic> toJson() =>
      {'id': id, 'document': document.toJson(), if (configuration != null) 'configuration': configuration!.toJson()};
}

/// Project-wide geometry. Every set in a collection shares it.
typedef TilesetGeometry = ({TilesetPerspective perspective, int size});

const tilesetTileSizes = [16, 32, 48];

/// Collection envelope. Legacy single documents are read without regenerating pixels.
///
/// Version 2 stores the project geometry. Version 1 collections derive it from
/// their sets: the most common geometry wins and ties go to the earliest set.
/// Sets that differ keep their pixels and are reported by [matchesGeometry].
class TilesetCollection {
  TilesetCollection(
      {required this.name,
      List<TilesetEntry> entries = const [],
      this.perspective = TilesetPerspective.side,
      this.tileSize = 16,
      this.canvas = const TilesetCanvas()})
      : entries = List.unmodifiable(entries) {
    if (!tilesetTileSizes.contains(tileSize)) throw ArgumentError('Invalid tileset tile size');
  }
  static const version = 2;
  final String name;
  final List<TilesetEntry> entries;
  final TilesetPerspective perspective;
  final int tileSize;

  /// Free-form layout of sets, tiles and notes on the workspace canvas.
  final TilesetCanvas canvas;
  Map<String, TilesetEntry> get entriesById => {for (final entry in entries) entry.id: entry};

  /// Entries and canvas always change together: items of removed sets are dropped.
  TilesetCollection copyWith(
      {String? name,
      List<TilesetEntry>? entries,
      TilesetPerspective? perspective,
      int? tileSize,
      TilesetCanvas? canvas}) {
    final nextEntries = entries ?? this.entries;
    return TilesetCollection(
        name: name ?? this.name,
        entries: nextEntries,
        perspective: perspective ?? this.perspective,
        tileSize: tileSize ?? this.tileSize,
        canvas: (canvas ?? this.canvas).pruned(nextEntries));
  }

  TilesetGeometry get geometry => (perspective: perspective, size: tileSize);

  /// Whether the generated pixels of [entry] already use the project geometry.
  bool matchesGeometry(TilesetEntry entry) =>
      entry.document.settings.perspective == perspective && entry.document.settings.size == tileSize;

  static TilesetGeometry deriveGeometry(List<TilesetEntry> entries) {
    final counts = <TilesetGeometry, int>{};
    for (final entry in entries) {
      final config = entry.resolvedConfiguration;
      counts.update((perspective: config.perspective, size: config.size), (n) => n + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return (perspective: TilesetPerspective.side, size: 16);
    // Map iteration follows insertion order, so the first maximum is the earliest set.
    return counts.entries.reduce((best, next) => next.value > best.value ? next : best).key;
  }

  Map<String, dynamic> toJson() => {
        'kind': 'tilesetCollection',
        'version': version,
        'name': name,
        'perspective': perspective.id,
        'tileSize': tileSize,
        'canvas': canvas.toJson(),
        'entries': entries.map((e) => e.toJson()).toList()
      };
  factory TilesetCollection.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'tilesetCollection') {
      final document = TilesetDocument.fromJson(json);
      return TilesetCollection(
          name: document.name,
          perspective: document.settings.perspective,
          tileSize: document.settings.size,
          canvas: autoLayoutTilesetCanvas([TilesetEntry(id: 'legacy', document: document)], document.settings.size),
          entries: [TilesetEntry(id: 'legacy', document: document)]);
    }
    final fileVersion = json['version'];
    if (fileVersion != 1 && fileVersion != version) throw const FormatException('Unsupported tileset collection');
    final entries = (json['entries'] as List).map((raw) {
      final entry = raw as Map<String, dynamic>;
      return TilesetEntry(
          id: entry['id'] as String,
          configuration: entry['configuration'] == null
              ? null
              : TilesetConfiguration.fromJson(entry['configuration'] as Map<String, dynamic>),
          document: TilesetDocument.fromJson(entry['document'] as Map<String, dynamic>));
    }).toList();
    if (entries.any((e) => e.id.isEmpty) || entries.map((e) => e.id).toSet().length != entries.length) {
      throw const FormatException('Duplicate or empty tileset identifiers');
    }
    late final TilesetGeometry geometry;
    if (fileVersion == 1) {
      geometry = deriveGeometry(entries);
    } else {
      final size = json['tileSize'];
      if (size is! int || !tilesetTileSizes.contains(size)) throw const FormatException('Unsupported tile size');
      geometry = (perspective: TilesetPerspective.parse(json['perspective'] as String), size: size);
    }
    // Collections saved before the canvas existed get a tidy default layout.
    final canvas = json['canvas'] == null
        ? autoLayoutTilesetCanvas(entries, geometry.size)
        : TilesetCanvas.fromJson(json['canvas'] as Map<String, dynamic>).pruned(entries);
    return TilesetCollection(
        name: json['name'] as String,
        entries: entries,
        perspective: geometry.perspective,
        tileSize: geometry.size,
        canvas: canvas);
  }
}
