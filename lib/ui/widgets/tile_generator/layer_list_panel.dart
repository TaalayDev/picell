import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data.dart';
import '../../../tilemap/tile_generator_notifier.dart';

class LayerListPanel extends HookConsumerWidget {
  const LayerListPanel({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tileGeneratorProvider(project);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    // Use a reversed list for display because layers are painted 0->N (bottom->top),
    // but in UI typically top layer is at the top of the list
    final layersReversed = state.layers.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Layers',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => notifier.addLayer(),
                tooltip: 'Add Layer',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Layer List
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: layersReversed.length,
            onReorder: (oldIndex, newIndex) {
              // Indices in state list (0 is bottom)
              // Convert UI indices (reversed) back to state indices

              int actualNewIndex = newIndex;
              if (oldIndex < newIndex) {
                actualNewIndex -= 1;
              }

              final fromIndex = state.layers.length - 1 - oldIndex;
              final toIndex = state.layers.length - 1 - actualNewIndex;

              notifier.reorderLayers(fromIndex, toIndex);
            },
            itemBuilder: (context, index) {
              final layer = layersReversed[index];
              return _LayerItem(
                key: ValueKey(layer.id),
                layer: layer,
                isActive: layer.id == state.activeLayerId,
                onTap: () => notifier.setActiveLayer(layer.id),
                onToggleVisibility: () => notifier.toggleLayerVisibility(layer.id),
                onToggleLock: () => notifier.toggleLayerLock(layer.id),
                onDelete: () => notifier.removeLayer(layer.id),
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LayerItem extends StatelessWidget {
  const _LayerItem({
    super.key,
    required this.layer,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onDelete,
    required this.index,
  });

  final Layer layer;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;
  final VoidCallback onDelete;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: isActive ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                // Drag Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: colorScheme.outline,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),

                // Visibility
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    layer.isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: layer.isVisible ? colorScheme.onSurfaceVariant : colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),

                // Thumbnail (Simple preview)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: colorScheme.outlineVariant),
                    // image: const DecorationImage(
                    //   image: AssetImage('assets/images/transparent_bg.png'),
                    //   repeat: ImageRepeat.repeat,
                    // ),
                  ),
                  // We could potentially render a thumbnail here, but it might be expensive
                  // for real-time. For now, just show a placeholder or icon.
                  child: Icon(Icons.image, size: 16, color: colorScheme.outline),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        layer.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? colorScheme.onSurfaceVariant : colorScheme.outline,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (layer.effects.isNotEmpty)
                        Text(
                          '${layer.effects.length} effects',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                        ),
                    ],
                  ),
                ),

                // Lock
                GestureDetector(
                  onTap: onToggleLock,
                  child: Icon(
                    layer.isLocked ? Icons.lock : Icons.lock_open,
                    size: 16,
                    color: layer.isLocked
                        ? colorScheme.primary
                        : Colors.transparent, // Hide if unlocked to reduce clutter? Or show outline?
                  ),
                ),
                // Or always show lock icon if locked, otherwise show nothing or placeholder
                if (!layer.isLocked) const SizedBox(width: 16),

                // Delete
                if (isActive) // Only show delete for active/hovered to reduce clutter? Or always?
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
