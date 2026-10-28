import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents a single tile in the tile palette
class Tile with EquatableMixin {
  /// Unique identifier for this tile
  final int id;

  /// Display name for the tile
  final String name;

  /// Width of the tile in pixels
  final int width;

  /// Height of the tile in pixels
  final int height;

  /// Pixel data for the tile (ARGB format)
  final Uint32List pixels;

  const Tile({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.pixels,
  });

  /// Creates an empty tile with transparent pixels
  factory Tile.empty({
    required int id,
    required int width,
    required int height,
    String? name,
  }) {
    return Tile(
      id: id,
      name: name ?? 'Tile $id',
      width: width,
      height: height,
      pixels: Uint32List(width * height),
    );
  }

  Tile copyWith({
    int? id,
    String? name,
    int? width,
    int? height,
    Uint32List? pixels,
  }) {
    return Tile(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      pixels: pixels ?? this.pixels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'pixels': pixels.toList(),
    };
  }

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      id: json['id'] as int,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      pixels: Uint32List.fromList((json['pixels'] as List).cast<int>()),
    );
  }

  @override
  List<Object?> get props => [id, name, width, height, pixels];
}

/// Represents a layer in the tilemap containing tile placements
class TileLayer with EquatableMixin {
  /// Unique identifier for this layer
  final int id;

  /// Display name for the layer
  final String name;

  /// Grid of tile IDs (-1 means empty/no tile)
  /// Stored as a flat list, indexed by (row * columns + column)
  final List<int> tileIndices;

  /// Whether this layer is visible
  final bool isVisible;

  /// Whether this layer is locked for editing
  final bool isLocked;

  /// Layer opacity (0.0 to 1.0)
  final double opacity;

  /// Layer order (for z-ordering)
  final int order;

  const TileLayer({
    required this.id,
    required this.name,
    required this.tileIndices,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    this.order = 0,
  });

  /// Creates an empty layer with no tiles placed
  factory TileLayer.empty({
    required int id,
    required int columns,
    required int rows,
    String? name,
    int order = 0,
  }) {
    return TileLayer(
      id: id,
      name: name ?? 'Layer $id',
      tileIndices: List.filled(columns * rows, -1),
      order: order,
    );
  }

  TileLayer copyWith({
    int? id,
    String? name,
    List<int>? tileIndices,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    int? order,
  }) {
    return TileLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      tileIndices: tileIndices ?? this.tileIndices,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tileIndices': tileIndices,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'opacity': opacity,
      'order': order,
    };
  }

  factory TileLayer.fromJson(Map<String, dynamic> json) {
    return TileLayer(
      id: json['id'] as int,
      name: json['name'] as String,
      tileIndices: (json['tileIndices'] as List).cast<int>(),
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, tileIndices, isVisible, isLocked, opacity, order];
}

/// Complete tilemap data including tiles palette and layers
class TilemapData with EquatableMixin {
  /// Width of each tile in pixels
  final int tileWidth;

  /// Height of each tile in pixels
  final int tileHeight;

  /// Number of columns in the map grid
  final int columns;

  /// Number of rows in the map grid
  final int rows;

  /// List of available tiles (the palette)
  final List<Tile> tiles;

  /// List of tile layers
  final List<TileLayer> layers;

  /// Currently selected tile index in the palette
  final int selectedTileIndex;

  /// Currently selected layer index
  final int selectedLayerIndex;

  const TilemapData({
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.tiles,
    required this.layers,
    this.selectedTileIndex = 0,
    this.selectedLayerIndex = 0,
  });

  /// Creates a new empty tilemap with default settings
  factory TilemapData.empty({
    required int tileWidth,
    required int tileHeight,
    required int columns,
    required int rows,
  }) {
    return TilemapData(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columns: columns,
      rows: rows,
      tiles: [
        Tile.empty(id: 0, width: tileWidth, height: tileHeight, name: 'Empty'),
      ],
      layers: [
        TileLayer.empty(id: 0, columns: columns, rows: rows, name: 'Layer 1'),
      ],
    );
  }

  /// Total width of the map in pixels
  int get mapWidth => columns * tileWidth;

  /// Total height of the map in pixels
  int get mapHeight => rows * tileHeight;

  /// Get the currently selected tile
  Tile? get selectedTile =>
      selectedTileIndex >= 0 && selectedTileIndex < tiles.length ? tiles[selectedTileIndex] : null;

  /// Get the currently selected layer
  TileLayer? get selectedLayer =>
      selectedLayerIndex >= 0 && selectedLayerIndex < layers.length ? layers[selectedLayerIndex] : null;

  TilemapData copyWith({
    int? tileWidth,
    int? tileHeight,
    int? columns,
    int? rows,
    List<Tile>? tiles,
    List<TileLayer>? layers,
    int? selectedTileIndex,
    int? selectedLayerIndex,
  }) {
    return TilemapData(
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      tiles: tiles ?? this.tiles,
      layers: layers ?? this.layers,
      selectedTileIndex: selectedTileIndex ?? this.selectedTileIndex,
      selectedLayerIndex: selectedLayerIndex ?? this.selectedLayerIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
      'columns': columns,
      'rows': rows,
      'tiles': tiles.map((t) => t.toJson()).toList(),
      'layers': layers.map((l) => l.toJson()).toList(),
      'selectedTileIndex': selectedTileIndex,
      'selectedLayerIndex': selectedLayerIndex,
    };
  }

  factory TilemapData.fromJson(Map<String, dynamic> json) {
    return TilemapData(
      tileWidth: json['tileWidth'] as int,
      tileHeight: json['tileHeight'] as int,
      columns: json['columns'] as int,
      rows: json['rows'] as int,
      tiles: (json['tiles'] as List).map((t) => Tile.fromJson(t as Map<String, dynamic>)).toList(),
      layers: (json['layers'] as List).map((l) => TileLayer.fromJson(l as Map<String, dynamic>)).toList(),
      selectedTileIndex: json['selectedTileIndex'] as int? ?? 0,
      selectedLayerIndex: json['selectedLayerIndex'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        tileWidth,
        tileHeight,
        columns,
        rows,
        tiles,
        layers,
        selectedTileIndex,
        selectedLayerIndex,
      ];
}
