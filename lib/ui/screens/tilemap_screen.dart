import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../widgets/animated_background.dart';
import 'tile_generator_screen.dart';

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
}

/// Tilemap layer data
class TilemapLayer {
  final String id;
  final String name;
  final List<List<String?>> tileIds; // Grid of tile IDs (null = empty)
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
  });

  TilemapLayer? get activeLayer =>
      layers.isNotEmpty && activeLayerIndex < layers.length ? layers[activeLayerIndex] : null;

  SavedTile? get selectedTile => selectedTileId != null ? tiles.where((t) => t.id == selectedTileId).firstOrNull : null;

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

/// Provider for tilemap state
final tileMapProvider =
    StateNotifierProvider.autoDispose.family<TileMapNotifier, TileMapState, Project>((ref, project) {
  return TileMapNotifier(project);
});

/// State notifier for tilemap
class TileMapNotifier extends StateNotifier<TileMapState> {
  final Project project;

  TileMapNotifier(this.project) : super(const TileMapState()) {
    _initializeDefaultLayer();
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
    // Clear tile from all layers
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
}

/// Main TileMap Screen
class TileMapScreen extends StatefulHookConsumerWidget {
  const TileMapScreen({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  ConsumerState<TileMapScreen> createState() => _TileMapScreenState();
}

class _TileMapScreenState extends ConsumerState<TileMapScreen> {
  late final _provider = tileMapProvider(widget.project);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 1000;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildTopBar(context, state, notifier, colorScheme),
            Expanded(
              child: Row(
                children: [
                  // Left panel - Tile collection
                  _buildTileCollectionPanel(context, state, notifier, colorScheme),

                  // Center - Tilemap canvas
                  Expanded(
                    child: _buildTilemapCanvas(context, state, notifier, colorScheme),
                  ),

                  // Right panel - Layers (only on wide screens)
                  if (isWide) _buildLayersPanel(context, state, notifier, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            widget.project.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),

          // Tools
          _buildToolBar(context, state, notifier, colorScheme),

          const Spacer(),

          // Grid toggle
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                state.showGrid ? Icons.grid_on : Icons.grid_off,
                color: state.showGrid ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              onPressed: notifier.toggleGrid,
              tooltip: 'Toggle Grid',
            ),
          ),

          const SizedBox(width: 8),

          // Zoom controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => notifier.setZoom(state.zoom - 0.25),
                  tooltip: 'Zoom Out',
                  visualDensity: VisualDensity.compact,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(state.zoom * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => notifier.setZoom(state.zoom + 0.25),
                  tooltip: 'Zoom In',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Grid size
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<(int, int)>(
              tooltip: 'Grid Size',
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_4x4, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${state.gridWidth}×${state.gridHeight}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
              onSelected: (size) {
                if (size == (-1, -1)) {
                  _showCustomGridSizeDialog(context, notifier, state);
                } else {
                  notifier.setGridSize(size.$1, size.$2);
                }
              },
              itemBuilder: (context) => [
                for (final size in [(8, 8), (16, 16), (24, 24), (32, 32), (48, 48), (64, 64)])
                  PopupMenuItem(
                    value: size,
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view,
                          size: 16,
                          color: (state.gridWidth == size.$1 && state.gridHeight == size.$2)
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text('${size.$1} × ${size.$2}'),
                        if (state.gridWidth == size.$1 && state.gridHeight == size.$2) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 16, color: colorScheme.primary),
                        ],
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: (-1, -1),
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 16),
                      SizedBox(width: 8),
                      Text('Custom...'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Export button
          FilledButton.icon(
            onPressed: state.layers.any((l) => l.tileIds.any((r) => r.any((t) => t != null)))
                ? () => _exportTilemap(context, state, notifier)
                : null,
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('Export'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildToolBar(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TileMapTool.values.asMap().entries.map((entry) {
          final index = entry.key;
          final tool = entry.value;
          final isSelected = state.currentTool == tool;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0 && index == 2) // Add divider before fill
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              Tooltip(
                message: _toolName(tool),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => notifier.setTool(tool),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _toolIcon(tool),
                        size: 20,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _toolIcon(TileMapTool tool) {
    switch (tool) {
      case TileMapTool.paint:
        return Icons.brush;
      case TileMapTool.erase:
        return Icons.auto_fix_high;
      case TileMapTool.fill:
        return Icons.format_color_fill;
      case TileMapTool.eyedropper:
        return Icons.colorize;
      case TileMapTool.select:
        return Icons.select_all;
    }
  }

  String _toolName(TileMapTool tool) {
    switch (tool) {
      case TileMapTool.paint:
        return 'Paint';
      case TileMapTool.erase:
        return 'Erase';
      case TileMapTool.fill:
        return 'Fill';
      case TileMapTool.eyedropper:
        return 'Pick Tile';
      case TileMapTool.select:
        return 'Select';
    }
  }

  Widget _buildTileCollectionPanel(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.grid_view, color: colorScheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiles',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${state.tiles.length} tiles',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _navigateToTileGenerator(context, notifier, state),
                  tooltip: 'Add New Tile',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tiles...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: state.searchQuery != null && state.searchQuery!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => notifier.setSearchQuery(null),
                      )
                    : null,
              ),
              onChanged: notifier.setSearchQuery,
            ),
          ),
          const SizedBox(height: 8),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('Sort:', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<TileSortOption>(
                    value: state.sortOption,
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox(),
                    items: TileSortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(_sortOptionName(option), style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (v) => v != null ? notifier.setSortOption(v) : null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Tile grid
          Expanded(
            child: state.filteredTiles.isEmpty
                ? _buildEmptyTilesPlaceholder(context, notifier, state, colorScheme)
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: state.filteredTiles.length,
                    itemBuilder: (context, index) {
                      final tile = state.filteredTiles[index];
                      final isSelected = tile.id == state.selectedTileId;
                      return _buildTileCard(context, tile, isSelected, notifier, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _sortOptionName(TileSortOption option) {
    switch (option) {
      case TileSortOption.newest:
        return 'Newest';
      case TileSortOption.oldest:
        return 'Oldest';
      case TileSortOption.nameAZ:
        return 'Name (A-Z)';
      case TileSortOption.nameZA:
        return 'Name (Z-A)';
    }
  }

  Widget _buildEmptyTilesPlaceholder(
    BuildContext context,
    TileMapNotifier notifier,
    TileMapState state,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tiles yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tile to start building your tilemap',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _navigateToTileGenerator(context, notifier, state),
              icon: const Icon(Icons.add),
              label: const Text('Create Tile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileCard(
    BuildContext context,
    SavedTile tile,
    bool isSelected,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => notifier.selectTile(tile.id),
      onLongPress: () => _showTileOptionsDialog(context, tile, notifier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Tile preview
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: _TilePreviewPainter(
                  pixels: tile.pixels,
                  width: tile.width,
                  height: tile.height,
                ),
                size: Size.infinite,
              ),
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),

            // Tile name
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                ),
                child: Text(
                  tile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTileOptionsDialog(BuildContext context, SavedTile tile, TileMapNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Tile preview header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CustomPaint(
                        painter: _TilePreviewPainter(
                          pixels: tile.pixels,
                          width: tile.width,
                          height: tile.height,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tile.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${tile.width}×${tile.height} pixels',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Options
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editTile(context, tile, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, tile, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                notifier.duplicateTile(tile.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: colorScheme.error),
              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, tile, notifier);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, SavedTile tile, TileMapNotifier notifier) {
    final controller = TextEditingController(text: tile.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Tile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.renameTile(tile.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SavedTile tile, TileMapNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tile'),
        content: Text('Are you sure you want to delete "${tile.name}"? This will also remove it from the tilemap.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notifier.deleteTile(tile.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editTile(BuildContext context, SavedTile tile, TileMapNotifier notifier) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => TileGeneratorScreen(project: widget.project),
      ),
    )
        .then((result) {
      if (result is Uint32List) {
        notifier.updateTile(
          tile.id,
          tile.copyWith(pixels: result),
        );
      }
    });
  }

  void _navigateToTileGenerator(BuildContext context, TileMapNotifier notifier, TileMapState state) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => _TileGeneratorWrapper(project: widget.project),
      ),
    );

    if (result != null && result['pixels'] is Uint32List) {
      notifier.addTileFromPixels(
        name: result['name'] ?? 'Tile ${state.tiles.length + 1}',
        pixels: result['pixels'],
        width: result['width'] ?? widget.project.tileWidth ?? 16,
        height: result['height'] ?? widget.project.tileHeight ?? 16,
        sourceTemplateId: result['templateId'],
      );
    }
  }

  Widget _buildTilemapCanvas(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _TilemapCanvasWidget(
              state: state,
              notifier: notifier,
              constraints: constraints,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayersPanel(
    BuildContext context,
    TileMapState state,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.layers, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Layers',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => notifier.addLayer(),
                  tooltip: 'Add Layer',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Layer list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.layers.length,
              onReorder: notifier.reorderLayer,
              itemBuilder: (context, index) {
                final layer = state.layers[index];
                final isActive = index == state.activeLayerIndex;
                return _buildLayerTile(context, layer, index, isActive, notifier, colorScheme);
              },
            ),
          ),

          // Layer actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.layers.length > 1 ? () => notifier.removeLayer(state.activeLayerIndex) : null,
                  tooltip: 'Delete Layer',
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => notifier.clearActiveLayer(),
                  tooltip: 'Clear Layer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerTile(
    BuildContext context,
    TilemapLayer layer,
    int index,
    bool isActive,
    TileMapNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return Material(
      key: ValueKey(layer.id),
      color: isActive ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => notifier.setActiveLayer(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  layer.visible ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                ),
                onPressed: () => notifier.toggleLayerVisibility(index),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomGridSizeDialog(BuildContext context, TileMapNotifier notifier, TileMapState state) {
    final colorScheme = Theme.of(context).colorScheme;
    int width = state.gridWidth;
    int height = state.gridHeight;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.grid_4x4, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Custom Grid Size'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Width',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixText: 'tiles',
                      ),
                      controller: TextEditingController(text: width.toString()),
                      onChanged: (v) => width = int.tryParse(v) ?? width,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.close, color: colorScheme.onSurfaceVariant, size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixText: 'tiles',
                      ),
                      controller: TextEditingController(text: height.toString()),
                      onChanged: (v) => height = int.tryParse(v) ?? height,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Supported range: 4-128 tiles',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final clampedWidth = width.clamp(4, 128);
                final clampedHeight = height.clamp(4, 128);
                notifier.setGridSize(clampedWidth, clampedHeight);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportTilemap(BuildContext context, TileMapState state, TileMapNotifier notifier) {
    // Show export options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Tilemap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export your tilemap as:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('PNG Image'),
              subtitle: const Text('Flattened image of all layers'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPng(context, state, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('JSON Data'),
              subtitle: const Text('Tile positions and layer data'),
              onTap: () {
                Navigator.pop(context);
                _exportAsJson(context, state, notifier);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportAsPng(BuildContext context, TileMapState state, TileMapNotifier notifier) {
    // Implementation for PNG export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PNG export coming soon!')),
    );
  }

  void _exportAsJson(BuildContext context, TileMapState state, TileMapNotifier notifier) {
    // Implementation for JSON export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON export coming soon!')),
    );
  }
}

/// Wrapper widget to handle tile creation flow
class _TileGeneratorWrapper extends StatelessWidget {
  final Project project;

  const _TileGeneratorWrapper({required this.project});

  @override
  Widget build(BuildContext context) {
    return TileGeneratorScreen(
      project: project,
      returnResultForTilemap: true,
    );
  }
}

/// Tilemap canvas widget with pan and zoom
class _TilemapCanvasWidget extends HookWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final BoxConstraints constraints;

  const _TilemapCanvasWidget({
    required this.state,
    required this.notifier,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isPainting = useState(false);
    final lastPaintedCell = useState<(int, int)?>(null);
    final transformController = useMemoized(() => TransformationController());
    final hoverCell = useState<(int, int)?>(null);
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate tile size to fit canvas nicely
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // Base tile size that fits the grid
    final baseTileSize = min(
      (availableWidth - 40) / state.gridWidth,
      (availableHeight - 40) / state.gridHeight,
    ).clamp(16.0, 64.0);

    final tileSize = baseTileSize * state.zoom;
    final canvasWidth = state.gridWidth * tileSize;
    final canvasHeight = state.gridHeight * tileSize;

    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(
            painter: _BackgroundPatternPainter(colorScheme: colorScheme),
          ),
        ),

        // Canvas area
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: transformController,
            minScale: 0.5,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(100),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MouseRegion(
                    onHover: (event) {
                      final x = (event.localPosition.dx / tileSize).floor();
                      final y = (event.localPosition.dy / tileSize).floor();
                      if (x >= 0 && x < state.gridWidth && y >= 0 && y < state.gridHeight) {
                        hoverCell.value = (x, y);
                      } else {
                        hoverCell.value = null;
                      }
                    },
                    onExit: (_) => hoverCell.value = null,
                    child: GestureDetector(
                      onTapDown: (details) {
                        _handlePointer(details.localPosition, tileSize, lastPaintedCell);
                      },
                      onPanStart: (details) {
                        isPainting.value = true;
                        lastPaintedCell.value = null;
                        _handlePointer(details.localPosition, tileSize, lastPaintedCell);
                      },
                      onPanUpdate: (details) {
                        if (isPainting.value) {
                          _handlePointer(details.localPosition, tileSize, lastPaintedCell);
                        }
                      },
                      onPanEnd: (_) {
                        isPainting.value = false;
                        lastPaintedCell.value = null;
                      },
                      child: SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: CustomPaint(
                          painter: _TilemapPainter(
                            state: state,
                            notifier: notifier,
                            tileSize: tileSize,
                            hoverCell: hoverCell.value,
                            colorScheme: colorScheme,
                          ),
                          size: Size(canvasWidth, canvasHeight),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Selected tile preview (bottom left)
        if (state.selectedTile != null)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildSelectedTilePreview(context, state.selectedTile!, colorScheme),
          ),

        // Coordinates display (bottom right)
        if (hoverCell.value != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'X: ${hoverCell.value!.$1}, Y: ${hoverCell.value!.$2}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

        // Tool indicator (top left)
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getToolIcon(state.currentTool),
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  _getToolName(state.currentTool),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Grid size indicator (top right)
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              '${state.gridWidth} × ${state.gridHeight}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTilePreview(BuildContext context, SavedTile tile, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selected Tile',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(
                painter: _TilePreviewPainter(
                  pixels: tile.pixels,
                  width: tile.width,
                  height: tile.height,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 48,
            child: Text(
              tile.name,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getToolIcon(TileMapTool tool) {
    switch (tool) {
      case TileMapTool.paint:
        return Icons.brush;
      case TileMapTool.erase:
        return Icons.auto_fix_high;
      case TileMapTool.fill:
        return Icons.format_color_fill;
      case TileMapTool.eyedropper:
        return Icons.colorize;
      case TileMapTool.select:
        return Icons.select_all;
    }
  }

  String _getToolName(TileMapTool tool) {
    switch (tool) {
      case TileMapTool.paint:
        return 'Paint';
      case TileMapTool.erase:
        return 'Erase';
      case TileMapTool.fill:
        return 'Fill';
      case TileMapTool.eyedropper:
        return 'Pick Tile';
      case TileMapTool.select:
        return 'Select';
    }
  }

  void _handlePointer(Offset position, double tileSize, ValueNotifier<(int, int)?> lastPainted) {
    final x = (position.dx / tileSize).floor();
    final y = (position.dy / tileSize).floor();

    // Skip if same cell as last painted (for smoother dragging)
    if (lastPainted.value == (x, y)) return;
    lastPainted.value = (x, y);

    // Bounds check
    if (x < 0 || x >= state.gridWidth || y < 0 || y >= state.gridHeight) return;

    switch (state.currentTool) {
      case TileMapTool.paint:
        notifier.paintTile(x, y);
        break;
      case TileMapTool.erase:
        notifier.eraseTile(x, y);
        break;
      case TileMapTool.fill:
        notifier.fillTiles(x, y);
        break;
      case TileMapTool.eyedropper:
        notifier.pickTile(x, y);
        break;
      case TileMapTool.select:
        // Select functionality
        break;
    }
  }
}

/// Background pattern painter
class _BackgroundPatternPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _BackgroundPatternPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle dot pattern
    final dotPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tilemap painter
class _TilemapPainter extends CustomPainter {
  final TileMapState state;
  final TileMapNotifier notifier;
  final double tileSize;
  final (int, int)? hoverCell;
  final ColorScheme colorScheme;

  _TilemapPainter({
    required this.state,
    required this.notifier,
    required this.tileSize,
    required this.hoverCell,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()..color = const Color(0xFF1E1E2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw checkerboard
    _drawCheckerboard(canvas, size);

    // Draw layers
    for (final layer in state.layers) {
      if (!layer.visible) continue;
      _drawLayer(canvas, layer);
    }

    // Draw grid
    if (state.showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw hover cell
    _drawHoverCell(canvas);
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = const Color(0xFF2A2A3E);
    final darkPaint = Paint()..color = const Color(0xFF252536);
    final checkerSize = tileSize / 2;

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isLight = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  void _drawLayer(Canvas canvas, TilemapLayer layer) {
    for (int y = 0; y < layer.tileIds.length; y++) {
      for (int x = 0; x < layer.tileIds[y].length; x++) {
        final tileId = layer.tileIds[y][x];
        if (tileId == null) continue;

        final tile = notifier.getTileById(tileId);
        if (tile == null) continue;

        _drawTile(canvas, tile, x * tileSize, y * tileSize, layer.opacity);
      }
    }
  }

  void _drawTile(Canvas canvas, SavedTile tile, double x, double y, double opacity) {
    final pixelWidth = tileSize / tile.width;
    final pixelHeight = tileSize / tile.height;

    for (int py = 0; py < tile.height; py++) {
      for (int px = 0; px < tile.width; px++) {
        final index = py * tile.width + px;
        if (index < tile.pixels.length) {
          final color = Color(tile.pixels[index]);
          if (color.alpha > 0) {
            final paint = Paint()..color = color.withValues(alpha: color.a * opacity);
            canvas.drawRect(
              Rect.fromLTWH(
                x + px * pixelWidth,
                y + py * pixelHeight,
                pixelWidth + 0.5,
                pixelHeight + 0.5,
              ),
              paint,
            );
          }
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    for (int x = 0; x <= state.gridWidth; x++) {
      canvas.drawLine(
        Offset(x * tileSize, 0),
        Offset(x * tileSize, size.height),
        gridPaint,
      );
    }

    for (int y = 0; y <= state.gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * tileSize),
        Offset(size.width, y * tileSize),
        gridPaint,
      );
    }
  }

  void _drawHoverCell(Canvas canvas) {
    if (hoverCell == null) return;

    final (x, y) = hoverCell!;
    final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);

    // Draw hover highlight
    final hoverPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, hoverPaint);

    // Draw hover border
    final borderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(1), borderPaint);
  }

  @override
  bool shouldRepaint(_TilemapPainter oldDelegate) => true;
}

/// Tile preview painter
class _TilePreviewPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;

  _TilePreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    // Draw checkerboard background
    final lightPaint = Paint()..color = const Color(0xFFE0E0E0);
    final darkPaint = Paint()..color = const Color(0xFFBDBDBD);
    final checkerSize = min(pixelWidth, pixelHeight);

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isLight = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }

    // Draw pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final color = Color(pixels[index]);
          if (color.alpha > 0) {
            final paint = Paint()..color = color;
            canvas.drawRect(
              Rect.fromLTWH(
                x * pixelWidth,
                y * pixelHeight,
                pixelWidth + 0.5,
                pixelHeight + 0.5,
              ),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TilePreviewPainter oldDelegate) {
    return oldDelegate.pixels != pixels || oldDelegate.width != width || oldDelegate.height != height;
  }
}
