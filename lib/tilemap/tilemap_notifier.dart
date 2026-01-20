import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import 'tilemap_state.dart';

export 'tilemap_state.dart';

/// Provider for tilemap state
final tileMapProvider =
    StateNotifierProvider.autoDispose.family<TileMapNotifier, TileMapState, Project>((ref, project) {
  return TileMapNotifier(project);
});

/// State notifier for tilemap
class TileMapNotifier extends StateNotifier<TileMapState> {
  final Project project;

  TileMapNotifier(this.project) : super(const TileMapState()) {
    _loadFromProject();
  }

  void _loadFromProject() {
    // Get grid size from project, defaulting to 16x16
    final gridColumns = project.gridColumns ?? 16;
    final gridRows = project.gridRows ?? 16;

    if (project.tilemapData != null && project.tilemapData!.isNotEmpty) {
      try {
        final json = jsonDecode(project.tilemapData!) as Map<String, dynamic>;
        // Load from JSON but use project's grid size if available
        var loadedState = TileMapState.fromJson(json);
        // Override grid size with project's values
        state = loadedState.copyWith(
          gridWidth: gridColumns,
          gridHeight: gridRows,
        );
        // Resize layers if needed to match project grid size
        _resizeLayersToGrid(gridColumns, gridRows);
        return;
      } catch (e) {
        debugPrint('Failed to load tilemap data: $e');
        // If loading fails, initialize with default layer
      }
    }
    // Initialize with project's grid size
    state = state.copyWith(gridWidth: gridColumns, gridHeight: gridRows);
    _initializeDefaultLayer();
  }

  void _resizeLayersToGrid(int columns, int rows) {
    if (state.layers.isEmpty) return;

    final resizedLayers = state.layers.map((layer) {
      final newTileIds = List.generate(rows, (y) {
        return List.generate(columns, (x) {
          // Preserve existing tiles if within bounds
          if (y < layer.tileIds.length && x < layer.tileIds[y].length) {
            return layer.tileIds[y][x];
          }
          return null;
        });
      });
      return layer.copyWith(tileIds: newTileIds);
    }).toList();

    state = state.copyWith(layers: resizedLayers);
  }

  void _initializeDefaultLayer() {
    final layer = TilemapLayer(
      id: _generateId(),
      name: 'Layer 1',
      tileIds: List.generate(
        state.gridHeight,
        (_) => List.filled(state.gridWidth, null),
      ),
    );
    state = state.copyWith(layers: [layer]);
  }

  /// Serializes the current state to JSON string
  String toJsonString() {
    return jsonEncode(state.toJson());
  }

  /// Generates thumbnail pixels from the current tilemap state
  Uint32List generateThumbnailPixels() {
    final tileWidth = project.tileWidth ?? 16;
    final tileHeight = project.tileHeight ?? 16;
    final mapWidth = state.gridWidth * tileWidth;
    final mapHeight = state.gridHeight * tileHeight;
    final pixels = Uint32List(mapWidth * mapHeight);

    // Render all visible layers
    for (final layer in state.layers) {
      if (!layer.visible) continue;

      for (int gridY = 0; gridY < layer.tileIds.length; gridY++) {
        for (int gridX = 0; gridX < layer.tileIds[gridY].length; gridX++) {
          final tileId = layer.tileIds[gridY][gridX];
          if (tileId == null) continue;

          final tile = getTileById(tileId);
          if (tile == null) continue;

          // Copy tile pixels to the output
          for (int py = 0; py < tile.height && py < tileHeight; py++) {
            for (int px = 0; px < tile.width && px < tileWidth; px++) {
              final srcIdx = py * tile.width + px;
              if (srcIdx >= tile.pixels.length) continue;

              final color = tile.pixels[srcIdx];
              final alpha = (color >> 24) & 0xFF;
              if (alpha == 0) continue;

              final destX = gridX * tileWidth + px;
              final destY = gridY * tileHeight + py;
              if (destX >= mapWidth || destY >= mapHeight) continue;

              final destIdx = destY * mapWidth + destX;

              // Simple alpha blending
              if (alpha == 255 || layer.opacity >= 1.0) {
                pixels[destIdx] = color;
              } else {
                final existingColor = pixels[destIdx];
                final blendedAlpha = ((alpha * layer.opacity).round()).clamp(0, 255);
                if (blendedAlpha > 0) {
                  pixels[destIdx] = _blendColors(existingColor, color, blendedAlpha / 255.0);
                }
              }
            }
          }
        }
      }
    }

    return pixels;
  }

  int _blendColors(int bg, int fg, double alpha) {
    final bgA = (bg >> 24) & 0xFF;
    final bgR = (bg >> 16) & 0xFF;
    final bgG = (bg >> 8) & 0xFF;
    final bgB = bg & 0xFF;

    final fgR = (fg >> 16) & 0xFF;
    final fgG = (fg >> 8) & 0xFF;
    final fgB = fg & 0xFF;

    final outR = ((fgR * alpha) + (bgR * (1 - alpha))).round().clamp(0, 255);
    final outG = ((fgG * alpha) + (bgG * (1 - alpha))).round().clamp(0, 255);
    final outB = ((fgB * alpha) + (bgB * (1 - alpha))).round().clamp(0, 255);
    final outA = ((255 * alpha) + (bgA * (1 - alpha))).round().clamp(0, 255);

    return (outA << 24) | (outR << 16) | (outG << 8) | outB;
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString();

  // Tile Collection Management
  void addTile(SavedTile tile) {
    state = state.copyWith(tiles: [...state.tiles, tile]);
  }

  void addTileFromPixels({
    required String name,
    required Uint32List pixels,
    required int width,
    required int height,
    String? sourceTemplateId,
    List<String> tags = const [],
  }) {
    final tile = SavedTile(
      id: _generateId(),
      name: name,
      width: width,
      height: height,
      pixels: Uint32List.fromList(pixels),
      createdAt: DateTime.now(),
      sourceTemplateId: sourceTemplateId,
      tags: tags,
    );
    addTile(tile);
  }

  void updateTile(String tileId, SavedTile updatedTile) {
    final index = state.tiles.indexWhere((t) => t.id == tileId);
    if (index != -1) {
      final newTiles = List<SavedTile>.from(state.tiles);
      newTiles[index] = updatedTile;
      state = state.copyWith(tiles: newTiles);
    }
  }

  void deleteTile(String tileId) {
    state = state.copyWith(
      tiles: state.tiles.where((t) => t.id != tileId).toList(),
      selectedTileId: state.selectedTileId == tileId ? null : state.selectedTileId,
      clearSelectedTile: state.selectedTileId == tileId,
    );
    _clearTileFromLayers(tileId);
  }

  void _clearTileFromLayers(String tileId) {
    final newLayers = state.layers.map((layer) {
      final newTileIds = layer.tileIds.map((row) {
        return row.map((id) => id == tileId ? null : id).toList();
      }).toList();
      return layer.copyWith(tileIds: newTileIds);
    }).toList();
    state = state.copyWith(layers: newLayers);
  }

  void selectTile(String? tileId) {
    state = state.copyWith(
      selectedTileId: tileId,
      clearSelectedTile: tileId == null,
    );
  }

  void renameTile(String tileId, String newName) {
    final tile = state.tiles.firstWhere((t) => t.id == tileId);
    updateTile(tileId, tile.copyWith(name: newName));
  }

  void duplicateTile(String tileId) {
    final tile = state.tiles.firstWhere((t) => t.id == tileId);
    final newTile = SavedTile(
      id: _generateId(),
      name: '${tile.name} (Copy)',
      width: tile.width,
      height: tile.height,
      pixels: Uint32List.fromList(tile.pixels),
      createdAt: DateTime.now(),
      sourceTemplateId: tile.sourceTemplateId,
      tags: List.from(tile.tags),
    );
    addTile(newTile);
  }

  // Search and Filter
  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
  }

  void setSortOption(TileSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  // Tilemap Grid Management
  void setGridSize(int width, int height) {
    final newLayers = state.layers.map((layer) {
      final newTileIds = List.generate(height, (y) {
        return List.generate(width, (x) {
          if (y < layer.tileIds.length && x < layer.tileIds[y].length) {
            return layer.tileIds[y][x];
          }
          return null;
        });
      });
      return layer.copyWith(tileIds: newTileIds);
    }).toList();

    state = state.copyWith(
      gridWidth: width,
      gridHeight: height,
      layers: newLayers,
    );
  }

  // Layer Management
  void addLayer({String? name}) {
    final layer = TilemapLayer(
      id: _generateId(),
      name: name ?? 'Layer ${state.layers.length + 1}',
      tileIds: List.generate(
        state.gridHeight,
        (_) => List.filled(state.gridWidth, null),
      ),
    );
    state = state.copyWith(
      layers: [...state.layers, layer],
      activeLayerIndex: state.layers.length,
    );
  }

  void removeLayer(int index) {
    if (state.layers.length <= 1) return;
    final newLayers = List<TilemapLayer>.from(state.layers)..removeAt(index);
    state = state.copyWith(
      layers: newLayers,
      activeLayerIndex: state.activeLayerIndex >= newLayers.length ? newLayers.length - 1 : state.activeLayerIndex,
    );
  }

  void setActiveLayer(int index) {
    if (index >= 0 && index < state.layers.length) {
      state = state.copyWith(activeLayerIndex: index);
    }
  }

  void toggleLayerVisibility(int index) {
    if (index >= 0 && index < state.layers.length) {
      final newLayers = List<TilemapLayer>.from(state.layers);
      newLayers[index] = newLayers[index].copyWith(visible: !newLayers[index].visible);
      state = state.copyWith(layers: newLayers);
    }
  }

  void renameLayer(int index, String name) {
    if (index >= 0 && index < state.layers.length) {
      final newLayers = List<TilemapLayer>.from(state.layers);
      newLayers[index] = newLayers[index].copyWith(name: name);
      state = state.copyWith(layers: newLayers);
    }
  }

  void reorderLayer(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.layers.length) return;
    if (newIndex < 0 || newIndex >= state.layers.length) return;

    final newLayers = List<TilemapLayer>.from(state.layers);
    final layer = newLayers.removeAt(oldIndex);
    newLayers.insert(newIndex, layer);

    int newActiveIndex = state.activeLayerIndex;
    if (state.activeLayerIndex == oldIndex) {
      newActiveIndex = newIndex;
    } else if (oldIndex < state.activeLayerIndex && newIndex >= state.activeLayerIndex) {
      newActiveIndex--;
    } else if (oldIndex > state.activeLayerIndex && newIndex <= state.activeLayerIndex) {
      newActiveIndex++;
    }

    state = state.copyWith(layers: newLayers, activeLayerIndex: newActiveIndex);
  }

  // Tilemap Painting
  void paintTile(int x, int y) {
    if (state.selectedTileId == null) return;
    if (state.activeLayer == null) return;
    if (x < 0 || x >= state.gridWidth || y < 0 || y >= state.gridHeight) return;

    final newLayers = List<TilemapLayer>.from(state.layers);
    final layer = newLayers[state.activeLayerIndex];
    final newTileIds = layer.tileIds.map((row) => List<String?>.from(row)).toList();
    newTileIds[y][x] = state.selectedTileId;
    newLayers[state.activeLayerIndex] = layer.copyWith(tileIds: newTileIds);
    state = state.copyWith(layers: newLayers);
  }

  void eraseTile(int x, int y) {
    if (state.activeLayer == null) return;
    if (x < 0 || x >= state.gridWidth || y < 0 || y >= state.gridHeight) return;

    final newLayers = List<TilemapLayer>.from(state.layers);
    final layer = newLayers[state.activeLayerIndex];
    final newTileIds = layer.tileIds.map((row) => List<String?>.from(row)).toList();
    newTileIds[y][x] = null;
    newLayers[state.activeLayerIndex] = layer.copyWith(tileIds: newTileIds);
    state = state.copyWith(layers: newLayers);
  }

  void fillTiles(int startX, int startY) {
    if (state.selectedTileId == null) return;
    if (state.activeLayer == null) return;
    if (startX < 0 || startX >= state.gridWidth || startY < 0 || startY >= state.gridHeight) return;

    final layer = state.activeLayer!;
    final targetTileId = layer.tileIds[startY][startX];
    if (targetTileId == state.selectedTileId) return;

    final newTileIds = layer.tileIds.map((row) => List<String?>.from(row)).toList();
    final stack = <(int, int)>[(startX, startY)];
    final visited = <String>{};

    while (stack.isNotEmpty) {
      final (x, y) = stack.removeLast();
      final key = '$x,$y';
      if (visited.contains(key)) continue;
      if (x < 0 || x >= state.gridWidth || y < 0 || y >= state.gridHeight) continue;
      if (newTileIds[y][x] != targetTileId) continue;

      visited.add(key);
      newTileIds[y][x] = state.selectedTileId;

      stack.add((x + 1, y));
      stack.add((x - 1, y));
      stack.add((x, y + 1));
      stack.add((x, y - 1));
    }

    final newLayers = List<TilemapLayer>.from(state.layers);
    newLayers[state.activeLayerIndex] = layer.copyWith(tileIds: newTileIds);
    state = state.copyWith(layers: newLayers);
  }

  void pickTile(int x, int y) {
    if (state.activeLayer == null) return;
    if (x < 0 || x >= state.gridWidth || y < 0 || y >= state.gridHeight) return;

    final tileId = state.activeLayer!.tileIds[y][x];
    if (tileId != null) {
      state = state.copyWith(selectedTileId: tileId, currentTool: TileMapTool.paint);
    }
  }

  void clearActiveLayer() {
    if (state.activeLayer == null) return;

    final newLayers = List<TilemapLayer>.from(state.layers);
    newLayers[state.activeLayerIndex] = state.activeLayer!.copyWith(
      tileIds: List.generate(
        state.gridHeight,
        (_) => List.filled(state.gridWidth, null),
      ),
    );
    state = state.copyWith(layers: newLayers);
  }

  // View Controls
  void setTool(TileMapTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.25, 4.0));
  }

  void setPanOffset(Offset offset) {
    state = state.copyWith(panOffset: offset);
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  // Utility
  SavedTile? getTileById(String id) {
    return state.tiles.where((t) => t.id == id).firstOrNull;
  }

  // =========================================================================
  // TILE EDITING
  // =========================================================================

  void startEditingTile(int gridX, int gridY) {
    if (state.activeLayer == null) return;
    if (gridX < 0 || gridX >= state.gridWidth || gridY < 0 || gridY >= state.gridHeight) return;

    final tileId = state.activeLayer!.tileIds[gridY][gridX];
    if (tileId == null) return;

    final tile = getTileById(tileId);
    if (tile == null) return;

    final pixels = Uint32List.fromList(tile.pixels);
    state = state.copyWith(
      isEditingTile: true,
      editingTileId: tileId,
      editingTileX: gridX,
      editingTileY: gridY,
      editingPixels: pixels,
      editUndoHistory: [Uint32List.fromList(pixels)],
      editUndoIndex: 0,
    );
  }

  /// Start editing a tile directly by its ID (from tile collection)
  void startEditingTileById(String tileId) {
    final tile = getTileById(tileId);
    if (tile == null) return;

    final pixels = Uint32List.fromList(tile.pixels);
    state = state.copyWith(
      isEditingTile: true,
      editingTileId: tileId,
      editingTileX: null,
      editingTileY: null,
      editingPixels: pixels,
      editUndoHistory: [Uint32List.fromList(pixels)],
      editUndoIndex: 0,
    );
  }

  void cancelTileEdit() {
    state = state.copyWith(
      isEditingTile: false,
      clearEditingTileId: true,
      editingTileX: null,
      editingTileY: null,
      clearEditingPixels: true,
      editUndoHistory: const [],
      editUndoIndex: -1,
    );
  }

  void saveTileEdit() {
    if (!state.isEditingTile || state.editingPixels == null) return;
    if (state.editingTileId == null) return;

    final tile = getTileById(state.editingTileId!);
    if (tile == null) return;

    updateTile(state.editingTileId!, tile.copyWith(pixels: Uint32List.fromList(state.editingPixels!)));
    cancelTileEdit();
  }

  void setEditTool(TileEditTool tool) {
    state = state.copyWith(editTool: tool);
  }

  void setEditColor(int color) {
    state = state.copyWith(editColor: color);
  }

  void editDrawPixel(int x, int y, int tileWidth, int tileHeight) {
    if (state.editingPixels == null) return;
    if (x < 0 || x >= tileWidth || y < 0 || y >= tileHeight) return;

    final pixels = Uint32List.fromList(state.editingPixels!);
    final index = y * tileWidth + x;

    switch (state.editTool) {
      case TileEditTool.pencil:
        pixels[index] = state.editColor;
        break;
      case TileEditTool.eraser:
        pixels[index] = 0x00000000;
        break;
      case TileEditTool.fill:
        _editFloodFill(pixels, x, y, tileWidth, tileHeight, state.editColor);
        break;
      case TileEditTool.eyedropper:
        state = state.copyWith(
          editColor: pixels[index],
          editTool: TileEditTool.pencil,
        );
        return;
    }

    state = state.copyWith(editingPixels: pixels);
  }

  void _editFloodFill(Uint32List pixels, int startX, int startY, int width, int height, int newColor) {
    final targetColor = pixels[startY * width + startX];
    if (targetColor == newColor) return;

    final stack = <(int, int)>[];
    stack.add((startX, startY));

    while (stack.isNotEmpty) {
      final (x, y) = stack.removeLast();
      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      final index = y * width + x;
      if (pixels[index] != targetColor) continue;

      pixels[index] = newColor;

      stack.add((x + 1, y));
      stack.add((x - 1, y));
      stack.add((x, y + 1));
      stack.add((x, y - 1));
    }
  }

  void editStartDrawing() {
    if (state.editingPixels == null) return;
    _pushEditUndoState(Uint32List.fromList(state.editingPixels!));
  }

  void _pushEditUndoState(Uint32List pixels) {
    final newHistory = state.editUndoHistory.sublist(0, state.editUndoIndex + 1);
    newHistory.add(Uint32List.fromList(pixels));
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }
    state = state.copyWith(
      editUndoHistory: newHistory,
      editUndoIndex: newHistory.length - 1,
    );
  }

  void editUndo() {
    if (!state.canEditUndo) return;
    final newIndex = state.editUndoIndex - 1;
    state = state.copyWith(
      editUndoIndex: newIndex,
      editingPixels: Uint32List.fromList(state.editUndoHistory[newIndex]),
    );
  }

  void editRedo() {
    if (!state.canEditRedo) return;
    final newIndex = state.editUndoIndex + 1;
    state = state.copyWith(
      editUndoIndex: newIndex,
      editingPixels: Uint32List.fromList(state.editUndoHistory[newIndex]),
    );
  }

  Uint32List? getNeighborPixels(int dx, int dy) {
    if (state.activeLayer == null) return null;
    if (state.editingTileX == null || state.editingTileY == null) return null;

    final nx = state.editingTileX! + dx;
    final ny = state.editingTileY! + dy;

    if (nx < 0 || nx >= state.gridWidth || ny < 0 || ny >= state.gridHeight) return null;

    final tileId = state.activeLayer!.tileIds[ny][nx];
    if (tileId == null) return null;

    return getTileById(tileId)?.pixels;
  }
}
