import 'dart:typed_data';
import 'dart:ui' show Offset;

/// A saved tile with metadata
class SavedTile {
  final String id;
  final String name;
  final int width;
  final int height;
  final Uint32List pixels;
  final DateTime createdAt;
  final String? sourceTemplateId;
  final List<String> tags;

  SavedTile({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.pixels,
    required this.createdAt,
    this.sourceTemplateId,
    this.tags = const [],
  });

  SavedTile copyWith({
    String? id,
    String? name,
    int? width,
    int? height,
    Uint32List? pixels,
    DateTime? createdAt,
    String? sourceTemplateId,
    List<String>? tags,
  }) {
    return SavedTile(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      pixels: pixels ?? this.pixels,
      createdAt: createdAt ?? this.createdAt,
      sourceTemplateId: sourceTemplateId ?? this.sourceTemplateId,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'pixels': pixels.toList(),
      'createdAt': createdAt.toIso8601String(),
      'sourceTemplateId': sourceTemplateId,
      'tags': tags,
    };
  }

  factory SavedTile.fromJson(Map<String, dynamic> json) {
    return SavedTile(
      id: json['id'] as String,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      pixels: Uint32List.fromList((json['pixels'] as List).cast<int>()),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sourceTemplateId: json['sourceTemplateId'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    );
  }
}

/// Tilemap layer data
class TilemapLayer {
  final String id;
  final String name;
  final List<List<String?>> tileIds;
  final bool visible;
  final double opacity;

  TilemapLayer({
    required this.id,
    required this.name,
    required this.tileIds,
    this.visible = true,
    this.opacity = 1.0,
  });

  TilemapLayer copyWith({
    String? id,
    String? name,
    List<List<String?>>? tileIds,
    bool? visible,
    double? opacity,
  }) {
    return TilemapLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      tileIds: tileIds ?? this.tileIds,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tileIds': tileIds,
      'visible': visible,
      'opacity': opacity,
    };
  }

  factory TilemapLayer.fromJson(Map<String, dynamic> json) {
    return TilemapLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      tileIds: (json['tileIds'] as List).map((row) => (row as List).map((e) => e as String?).toList()).toList(),
      visible: json['visible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

enum TileMapTool {
  paint,
  erase,
  fill,
  eyedropper,
  select,
}

enum TileSortOption {
  newest,
  oldest,
  nameAZ,
  nameZA,
}

enum TileEditTool {
  pencil,
  eraser,
  fill,
  eyedropper,
}

/// State for the tilemap screen
class TileMapState {
  final List<SavedTile> tiles;
  final String? selectedTileId;
  final int gridWidth;
  final int gridHeight;
  final List<TilemapLayer> layers;
  final int activeLayerIndex;
  final TileMapTool currentTool;
  final double zoom;
  final Offset panOffset;
  final bool showGrid;
  final String? searchQuery;
  final TileSortOption sortOption;

  // Tile editing state
  final bool isEditingTile;
  final String? editingTileId;
  final int? editingTileX;
  final int? editingTileY;
  final Uint32List? editingPixels;
  final TileEditTool editTool;
  final int editColor;
  final List<Uint32List> editUndoHistory;
  final int editUndoIndex;

  const TileMapState({
    this.tiles = const [],
    this.selectedTileId,
    this.gridWidth = 16,
    this.gridHeight = 16,
    this.layers = const [],
    this.activeLayerIndex = 0,
    this.currentTool = TileMapTool.paint,
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.showGrid = true,
    this.searchQuery,
    this.sortOption = TileSortOption.newest,
    this.isEditingTile = false,
    this.editingTileId,
    this.editingTileX,
    this.editingTileY,
    this.editingPixels,
    this.editTool = TileEditTool.pencil,
    this.editColor = 0xFF000000,
    this.editUndoHistory = const [],
    this.editUndoIndex = -1,
  });

  TilemapLayer? get activeLayer =>
      layers.isNotEmpty && activeLayerIndex < layers.length ? layers[activeLayerIndex] : null;

  SavedTile? get selectedTile => selectedTileId != null ? tiles.where((t) => t.id == selectedTileId).firstOrNull : null;

  bool get canEditUndo => editUndoIndex > 0;
  bool get canEditRedo => editUndoIndex < editUndoHistory.length - 1;

  List<SavedTile> get filteredTiles {
    var result = List<SavedTile>.from(tiles);

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result
          .where((t) => t.name.toLowerCase().contains(query) || t.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();
    }

    switch (sortOption) {
      case TileSortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TileSortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TileSortOption.nameAZ:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TileSortOption.nameZA:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    return result;
  }

  TileMapState copyWith({
    List<SavedTile>? tiles,
    String? selectedTileId,
    bool clearSelectedTile = false,
    int? gridWidth,
    int? gridHeight,
    List<TilemapLayer>? layers,
    int? activeLayerIndex,
    TileMapTool? currentTool,
    double? zoom,
    Offset? panOffset,
    bool? showGrid,
    String? searchQuery,
    bool clearSearch = false,
    TileSortOption? sortOption,
    bool? isEditingTile,
    String? editingTileId,
    bool clearEditingTileId = false,
    int? editingTileX,
    int? editingTileY,
    Uint32List? editingPixels,
    bool clearEditingPixels = false,
    TileEditTool? editTool,
    int? editColor,
    List<Uint32List>? editUndoHistory,
    int? editUndoIndex,
  }) {
    return TileMapState(
      tiles: tiles ?? this.tiles,
      selectedTileId: clearSelectedTile ? null : (selectedTileId ?? this.selectedTileId),
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
      layers: layers ?? this.layers,
      activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
      currentTool: currentTool ?? this.currentTool,
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      showGrid: showGrid ?? this.showGrid,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      sortOption: sortOption ?? this.sortOption,
      isEditingTile: isEditingTile ?? this.isEditingTile,
      editingTileId: clearEditingTileId ? null : (editingTileId ?? this.editingTileId),
      editingTileX: editingTileX ?? this.editingTileX,
      editingTileY: editingTileY ?? this.editingTileY,
      editingPixels: clearEditingPixels ? null : (editingPixels ?? this.editingPixels),
      editTool: editTool ?? this.editTool,
      editColor: editColor ?? this.editColor,
      editUndoHistory: editUndoHistory ?? this.editUndoHistory,
      editUndoIndex: editUndoIndex ?? this.editUndoIndex,
    );
  }

  /// Serializes the persistable state to JSON (tiles, layers, grid size)
  Map<String, dynamic> toJson() {
    return {
      'tiles': tiles.map((t) => t.toJson()).toList(),
      'layers': layers.map((l) => l.toJson()).toList(),
      'gridWidth': gridWidth,
      'gridHeight': gridHeight,
      'selectedTileId': selectedTileId,
      'activeLayerIndex': activeLayerIndex,
    };
  }

  /// Creates a TileMapState from JSON data
  factory TileMapState.fromJson(Map<String, dynamic> json) {
    return TileMapState(
      tiles: (json['tiles'] as List?)?.map((t) => SavedTile.fromJson(t as Map<String, dynamic>)).toList() ?? const [],
      layers:
          (json['layers'] as List?)?.map((l) => TilemapLayer.fromJson(l as Map<String, dynamic>)).toList() ?? const [],
      gridWidth: json['gridWidth'] as int? ?? 16,
      gridHeight: json['gridHeight'] as int? ?? 16,
      selectedTileId: json['selectedTileId'] as String?,
      activeLayerIndex: json['activeLayerIndex'] as int? ?? 0,
    );
  }
}
