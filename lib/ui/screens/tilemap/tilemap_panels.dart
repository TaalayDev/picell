import 'package:flutter/material.dart';

import '../../../data.dart';
import '../../../tilemap/tilemap_notifier.dart';
import 'tilemap_painters.dart';

/// Panel showing the tile collection
class TileCollectionPanel extends StatelessWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final Project project;
  final VoidCallback onAddTile;
  final void Function(SavedTile tile)? onEditTile;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final bool isBottomSheet;

  const TileCollectionPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.project,
    required this.onAddTile,
    this.onEditTile,
    this.onClose,
    this.scrollController,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

    if (isBottomSheet) {
      return _buildBottomSheetContent(context, colorScheme);
    }

    return Container(
      width: isCompact ? size.width * 0.85 : 280,
      constraints: BoxConstraints(maxWidth: isCompact ? 300 : 280),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, colorScheme, showClose: onClose != null),
          _buildSearchField(context, colorScheme),
          const Divider(height: 16),
          Expanded(
            child: state.filteredTiles.isEmpty
                ? _buildEmptyPlaceholder(context, colorScheme)
                : _buildTileGrid(context, colorScheme, isCompact: isCompact),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildDragHandle(colorScheme),
          _buildHeader(context, colorScheme, showClose: false),
          _buildSearchField(context, colorScheme),
          const Divider(height: 16),
          Expanded(
            child: state.filteredTiles.isEmpty
                ? _buildEmptyPlaceholder(context, colorScheme)
                : _buildTileGrid(context, colorScheme, isCompact: true, useScrollController: true),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, {bool showClose = false}) {
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
          if (showClose) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
              tooltip: 'Close',
            ),
          ],
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

  Widget _buildTileGrid(BuildContext context, ColorScheme colorScheme,
      {bool isCompact = false, bool useScrollController = false}) {
    final crossAxisCount = isCompact ? 4 : 3;

    return GridView.builder(
      controller: useScrollController ? scrollController : null,
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
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
          onTap: () {
            notifier.selectTile(tile.id);
            if (isBottomSheet) Navigator.pop(context);
          },
          onLongPress: () => _showTileOptionsDialog(context, tile),
          onEdit: () => onEditTile?.call(tile),
          onDelete: () => notifier.deleteTile(tile.id),
          compact: isCompact,
        );
      },
    );
  }

  void _showTileOptionsDialog(BuildContext context, SavedTile tile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
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
  final bool compact;

  const TileCard({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.compact = false,
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
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 5 : 7),
              child: CustomPaint(
                painter: TilePreviewPainter(
                  pixels: tile.pixels,
                  width: tile.width,
                  height: tile.height,
                ),
                size: Size.infinite,
              ),
            ),
            if (!compact)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                  ),
                  child: Text(
                    tile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: compact ? 10 : 12,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Panel showing the layers
class LayersPanel extends StatelessWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final bool isBottomSheet;

  const LayersPanel({
    super.key,
    required this.state,
    required this.notifier,
    this.onClose,
    this.scrollController,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

    if (isBottomSheet) {
      return _buildBottomSheetContent(context, colorScheme);
    }

    return Container(
      width: isCompact ? size.width * 0.7 : 220,
      constraints: BoxConstraints(maxWidth: isCompact ? 260 : 220),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, colorScheme, showClose: onClose != null),
          Expanded(child: _buildLayerList(context, colorScheme)),
          _buildFooter(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildBottomSheetContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildDragHandle(colorScheme),
          _buildHeader(context, colorScheme, showClose: false),
          Expanded(child: _buildLayerList(context, colorScheme, useScrollController: true)),
          _buildFooter(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, {bool showClose = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.layers, color: colorScheme.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Layers',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${state.layers.length} layers',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => notifier.addLayer(),
            tooltip: 'Add Layer',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
          ),
          if (showClose) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
              tooltip: 'Close',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayerList(BuildContext context, ColorScheme colorScheme, {bool useScrollController = false}) {
    return ReorderableListView.builder(
      scrollController: useScrollController ? scrollController : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: state.layers.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        notifier.reorderLayer(oldIndex, newIndex);
      },
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
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
  final bool compact;

  const TilemapToolbar({
    super.key,
    required this.state,
    required this.notifier,
    required this.isModifierPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 2 : 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TileMapTool.values.map((tool) {
          final isSelected = state.currentTool == tool;
          return Tooltip(
            message: _toolName(tool),
            child: InkWell(
              onTap: () => notifier.setTool(tool),
              borderRadius: BorderRadius.circular(compact ? 6 : 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.all(compact ? 6 : 10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(compact ? 6 : 8),
                ),
                child: Icon(
                  _toolIcon(tool),
                  size: compact ? 16 : 20,
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
  final bool compact;

  const ViewControlsWidget({
    super.key,
    required this.state,
    required this.notifier,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return Row(
        //  mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(state.showGrid ? Icons.grid_on : Icons.grid_off, size: 20),
            onPressed: notifier.toggleGrid,
            tooltip: 'Toggle Grid',
            visualDensity: VisualDensity.compact,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(state.zoom * 100).toInt()}%',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
          ),
        ],
      );
    }

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
