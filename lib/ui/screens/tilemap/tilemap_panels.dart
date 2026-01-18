import 'package:flutter/material.dart';

import '../../../data.dart';
import '../../../tilemap/tilemap_notifier.dart';
import 'tilemap_painters.dart';

/// Panel showing the tile collection on the left side
class TileCollectionPanel extends StatelessWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final Project project;
  final VoidCallback onAddTile;
  final void Function(SavedTile tile)? onEditTile;

  const TileCollectionPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.project,
    required this.onAddTile,
    this.onEditTile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, colorScheme),
          _buildSearchField(context, colorScheme),
          const Divider(height: 16),
          Expanded(
            child: state.filteredTiles.isEmpty
                ? _buildEmptyPlaceholder(context, colorScheme)
                : _buildTileGrid(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
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
            onPressed: onAddTile,
            tooltip: 'Add New Tile',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tiles...',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: notifier.setSearchQuery,
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('No tiles yet', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddTile,
              icon: const Icon(Icons.add),
              label: const Text('Create Tile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileGrid(BuildContext context, ColorScheme colorScheme) {
    return GridView.builder(
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
        return TileCard(
          tile: tile,
          isSelected: isSelected,
          onTap: () => notifier.selectTile(tile.id),
          onLongPress: () => _showTileOptionsDialog(context, tile),
          onEdit: () => onEditTile?.call(tile),
          onDelete: () => notifier.deleteTile(tile.id),
        );
      },
    );
  }

  void _showTileOptionsDialog(BuildContext context, SavedTile tile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, tile);
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
            leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              notifier.deleteTile(tile.id);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, SavedTile tile) {
    final controller = TextEditingController(text: tile.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Tile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
}

/// A single tile card in the collection
class TileCard extends StatelessWidget {
  final SavedTile tile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TileCard({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: TilePreviewPainter(
                  pixels: tile.pixels,
                  width: tile.width,
                  height: tile.height,
                ),
                size: Size.infinite,
              ),
            ),
            if (isSelected)
              Positioned(
                top: -8,
                right: -8,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  splashRadius: 16,
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.more_vert, size: 14, color: colorScheme.onPrimary),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: colorScheme.onSurface),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                ),
                child: Text(
                  tile.name,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
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
}

/// Panel showing layers on the right side
class LayersPanel extends StatelessWidget {
  final TileMapState state;
  final TileMapNotifier notifier;

  const LayersPanel({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, colorScheme),
          const Divider(height: 1),
          Expanded(child: _buildLayerList(context, colorScheme)),
          _buildFooter(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
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
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerList(BuildContext context, ColorScheme colorScheme) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.layers.length,
      onReorder: notifier.reorderLayer,
      itemBuilder: (context, index) {
        final layer = state.layers[index];
        final isActive = index == state.activeLayerIndex;
        return LayerListItem(
          key: ValueKey(layer.id),
          layer: layer,
          index: index,
          isActive: isActive,
          onTap: () => notifier.setActiveLayer(index),
          onToggleVisibility: () => notifier.toggleLayerVisibility(index),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: state.layers.length > 1 ? () => notifier.removeLayer(state.activeLayerIndex) : null,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => notifier.clearActiveLayer(),
          ),
        ],
      ),
    );
  }
}

/// A single layer item in the layers panel
class LayerListItem extends StatelessWidget {
  final TilemapLayer layer;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;

  const LayerListItem({
    super.key,
    required this.layer,
    required this.index,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isActive ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle, size: 18, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  layer.visible ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                ),
                onPressed: onToggleVisibility,
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
}

/// Top toolbar for the tilemap screen
class TilemapToolbar extends StatelessWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final bool isModifierPressed;

  const TilemapToolbar({
    super.key,
    required this.state,
    required this.notifier,
    required this.isModifierPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TileMapTool.values.map((tool) {
          final isSelected = state.currentTool == tool;
          return Tooltip(
            message: _toolName(tool),
            child: InkWell(
              onTap: () => notifier.setTool(tool),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _toolIcon(tool),
                  size: 20,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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
}

/// Edit hint widget showing modifier key status
class EditHintWidget extends StatelessWidget {
  final bool isModifierPressed;

  const EditHintWidget({super.key, required this.isModifierPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard,
            size: 14,
            color: isModifierPressed ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Cmd/Ctrl + Click to edit tile',
            style: TextStyle(
              fontSize: 11,
              color: isModifierPressed ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// View controls (grid toggle, zoom)
class ViewControlsWidget extends StatelessWidget {
  final TileMapState state;
  final TileMapNotifier notifier;

  const ViewControlsWidget({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          icon: Icon(state.showGrid ? Icons.grid_on : Icons.grid_off),
          onPressed: notifier.toggleGrid,
          tooltip: 'Toggle Grid',
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: () => notifier.setZoom(state.zoom - 0.25),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(state.zoom * 100).toInt()}%',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => notifier.setZoom(state.zoom + 0.25),
        ),
      ],
    );
  }
}
