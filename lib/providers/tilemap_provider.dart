import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/project_model.dart';
import '../data/models/tilemap_model.dart';
import 'providers.dart';

final tilemapProvider =
    StateNotifierProvider.family<TilemapNotifier, TilemapData, Project>(
  (ref, project) {
    TilemapData initialData;
    if (project.tilemapData != null && project.tilemapData!.isNotEmpty) {
      try {
        initialData = TilemapData.fromJson(
          jsonDecode(project.tilemapData!) as Map<String, dynamic>,
        );
      } catch (_) {
        initialData = _emptyForProject(project);
      }
    } else {
      initialData = _emptyForProject(project);
    }
    return TilemapNotifier(ref, project, initialData);
  },
);

TilemapData _emptyForProject(Project project) {
  return TilemapData.empty(
    tileWidth: project.tileWidth ?? 16,
    tileHeight: project.tileHeight ?? 16,
    columns: project.gridColumns ?? 16,
    rows: project.gridRows ?? 16,
  );
}

enum TilemapTool { place, erase, fill }

class TilemapNotifier extends StateNotifier<TilemapData> {
  final Ref _ref;
  final Project _project;

  TilemapNotifier(this._ref, this._project, TilemapData initial)
      : super(initial);

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> save() async {
    final json = jsonEncode(state.toJson());
    final updatedProject = _project.copyWith(tilemapData: json);
    await _ref.read(projectRepo).updateProject(updatedProject);
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void selectTile(int index) {
    if (index < 0 || index >= state.tiles.length) return;
    state = state.copyWith(selectedTileIndex: index);
  }

  void selectLayer(int index) {
    if (index < 0 || index >= state.layers.length) return;
    state = state.copyWith(selectedLayerIndex: index);
  }

  // ── Tile placement ─────────────────────────────────────────────────────────

  void placeTile(int col, int row) {
    final layer = state.selectedLayer;
    if (layer == null || layer.isLocked) return;
    if (col < 0 || col >= state.columns || row < 0 || row >= state.rows) return;
    final selectedTile = state.selectedTile;
    if (selectedTile == null) return;

    final idx = row * state.columns + col;
    if (layer.tileIndices[idx] == selectedTile.id) return; // already placed

    final newIndices = List<int>.from(layer.tileIndices);
    newIndices[idx] = selectedTile.id;
    _updateSelectedLayer(layer.copyWith(tileIndices: newIndices));
  }

  void eraseTile(int col, int row) {
    final layer = state.selectedLayer;
    if (layer == null || layer.isLocked) return;
    if (col < 0 || col >= state.columns || row < 0 || row >= state.rows) return;

    final idx = row * state.columns + col;
    if (layer.tileIndices[idx] == -1) return;

    final newIndices = List<int>.from(layer.tileIndices);
    newIndices[idx] = -1;
    _updateSelectedLayer(layer.copyWith(tileIndices: newIndices));
  }

  void fillLayer() {
    final layer = state.selectedLayer;
    if (layer == null || layer.isLocked) return;
    final selectedTile = state.selectedTile;
    if (selectedTile == null) return;

    final newIndices = List<int>.filled(
      state.columns * state.rows,
      selectedTile.id,
    );
    _updateSelectedLayer(layer.copyWith(tileIndices: newIndices));
  }

  void clearLayer() {
    final layer = state.selectedLayer;
    if (layer == null) return;
    final newIndices = List<int>.filled(state.columns * state.rows, -1);
    _updateSelectedLayer(layer.copyWith(tileIndices: newIndices));
  }

  // ── Tile palette management ────────────────────────────────────────────────

  Tile addTile() {
    final newId = state.tiles.isEmpty
        ? 0
        : state.tiles.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    final newTile = Tile.empty(
      id: newId,
      width: state.tileWidth,
      height: state.tileHeight,
      name: 'Tile ${state.tiles.length + 1}',
    );
    final tiles = [...state.tiles, newTile];
    state = state.copyWith(
      tiles: tiles,
      selectedTileIndex: tiles.length - 1,
    );
    return newTile;
  }

  void updateTile(Tile tile) {
    final tiles = state.tiles.map((t) => t.id == tile.id ? tile : t).toList();
    state = state.copyWith(tiles: tiles);
  }

  void deleteTile(int tileId) {
    if (state.tiles.length <= 1) return;
    final tiles = state.tiles.where((t) => t.id != tileId).toList();
    // Clear this tile from all layers
    final layers = state.layers.map((layer) {
      final newIndices =
          layer.tileIndices.map((id) => id == tileId ? -1 : id).toList();
      return layer.copyWith(tileIndices: newIndices);
    }).toList();

    final newSelectedIndex = state.selectedTileIndex >= tiles.length
        ? tiles.length - 1
        : state.selectedTileIndex;
    state = state.copyWith(
      tiles: tiles,
      layers: layers,
      selectedTileIndex: newSelectedIndex,
    );
  }

  // ── Layer management ───────────────────────────────────────────────────────

  void addLayer() {
    final newId = state.layers.isEmpty
        ? 0
        : state.layers.map((l) => l.id).reduce((a, b) => a > b ? a : b) + 1;
    final newLayer = TileLayer.empty(
      id: newId,
      columns: state.columns,
      rows: state.rows,
      name: 'Layer ${state.layers.length + 1}',
      order: state.layers.length,
    );
    state = state.copyWith(
      layers: [...state.layers, newLayer],
      selectedLayerIndex: state.layers.length,
    );
  }

  void removeLayer(int index) {
    if (state.layers.length <= 1) return;
    final layers = List<TileLayer>.from(state.layers)..removeAt(index);
    final newIndex = state.selectedLayerIndex >= layers.length
        ? layers.length - 1
        : state.selectedLayerIndex;
    state = state.copyWith(layers: layers, selectedLayerIndex: newIndex);
  }

  void toggleLayerVisibility(int index) {
    if (index < 0 || index >= state.layers.length) return;
    final layers = List<TileLayer>.from(state.layers);
    layers[index] = layers[index].copyWith(
      isVisible: !layers[index].isVisible,
    );
    state = state.copyWith(layers: layers);
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  void _updateSelectedLayer(TileLayer updated) {
    final layers = List<TileLayer>.from(state.layers);
    layers[state.selectedLayerIndex] = updated;
    state = state.copyWith(layers: layers);
  }
}
