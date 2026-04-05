import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

import '../../data.dart';
import '../../l10n/strings.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/background_image_provider.dart';
import 'fancy_slider.dart';

class LayersPanel extends HookConsumerWidget {
  final int width;
  final int height;
  final List<Layer> layers;
  final int activeLayerIndex;
  final Function(String name) onLayerAdded;
  final Function(int) onLayerSelected;
  final Function(int) onLayerDeleted;
  final Function(int) onLayerVisibilityChanged;
  final Function(int) onLayerLockedChanged;
  final Function(int) onLayerDuplicated;
  final Function(int oldIndex, int newIndex) onLayerReordered;
  final Function(int, double) onLayerOpacityChanged;
  final Function(Layer)? onLayerEffectsChanged;
  final Function(Layer) onLayerUpdated;
  final Function(Layer) onLayerToTemplate;
  final VoidCallback? onAutoSelect;
  final ScrollController? scrollController;

  const LayersPanel({
    super.key,
    required this.width,
    required this.height,
    required this.layers,
    required this.onLayerAdded,
    required this.activeLayerIndex,
    required this.onLayerSelected,
    required this.onLayerDeleted,
    required this.onLayerVisibilityChanged,
    required this.onLayerLockedChanged,
    required this.onLayerDuplicated,
    required this.onLayerReordered,
    required this.onLayerOpacityChanged,
    required this.onLayerUpdated,
    required this.onLayerToTemplate,
    this.onAutoSelect,
    this.onLayerEffectsChanged,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionStateProvider);
    final backgroundImage = ref.watch(backgroundImageProvider);

    return Column(
      children: [
        const SizedBox(height: 4),
        _ActionButtonsBar(
          layers: layers,
          activeLayerIndex: activeLayerIndex,
          onLayerAdded: onLayerAdded,
          onLayerDeleted: onLayerDeleted,
          onLayerDuplicated: onLayerDuplicated,
          onLayerUpdated: onLayerUpdated,
          onLayerToTemplate: onLayerToTemplate,
          onAutoSelect: onAutoSelect,
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 4),
        Expanded(
          child: AnimatedReorderableListView(
            items: layers,
            controller: scrollController,
            onReorder: (oldIndex, newIndex) {
              final reversedLength = layers.length;
              final actualOldIndex = reversedLength - 1 - oldIndex;
              final actualNewIndex = reversedLength - 1 - newIndex;
              onLayerReordered(actualNewIndex, actualOldIndex);
            },
            itemBuilder: (context, index) {
              final reversedLayers = layers.reversed.toList();
              final layer = reversedLayers[index];
              final actualIndex = layers.length - 1 - index;
              return _LayerTile(
                key: ValueKey(layer.id),
                layer: layer,
                index: actualIndex,
                isSelected: actualIndex == activeLayerIndex,
                onLayerSelected: onLayerSelected,
                onLayerVisibilityChanged: onLayerVisibilityChanged,
              );
            },
            enterTransition: [FlipInX(), ScaleIn()],
            exitTransition: [SlideInLeft()],
            insertDuration: const Duration(milliseconds: 300),
            removeDuration: const Duration(milliseconds: 300),
            isSameItem: (a, b) => a.id == b.id,
          ),
        ),
        if (backgroundImage.image != null)
          _BackgroundImageTile(
            width: width,
            height: height,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ActionButtonsBar extends HookWidget {
  final List<Layer> layers;
  final int activeLayerIndex;
  final Function(String) onLayerAdded;
  final Function(int) onLayerDeleted;
  final Function(int) onLayerDuplicated;
  final Function(Layer) onLayerUpdated;
  final Function(Layer) onLayerToTemplate;
  final VoidCallback? onAutoSelect;

  const _ActionButtonsBar({
    required this.layers,
    required this.activeLayerIndex,
    required this.onLayerAdded,
    required this.onLayerDeleted,
    required this.onLayerDuplicated,
    required this.onLayerUpdated,
    required this.onLayerToTemplate,
    this.onAutoSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedLayer = activeLayerIndex >= 0 && activeLayerIndex < layers.length;
    final selectedLayer = hasSelectedLayer ? layers[activeLayerIndex] : null;

    final menuKey = useState(GlobalKey());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ActionButton(
            icon: Icons.add,
            label: 'Add',
            color: Colors.green,
            onPressed: () => onLayerAdded('Layer ${layers.length + 1}'),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.copy,
            label: 'Copy',
            color: Colors.blue,
            onPressed: hasSelectedLayer ? () => onLayerDuplicated(activeLayerIndex) : null,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.edit,
            label: 'Edit',
            color: Colors.orange,
            onPressed: hasSelectedLayer ? () => _showEditLayerDialog(context, selectedLayer!) : null,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Remove',
            color: Colors.red,
            onPressed:
                hasSelectedLayer && layers.length > 1 ? () => _showDeleteConfirmation(context, activeLayerIndex) : null,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.select_all,
            label: 'Select',
            color: Colors.purple,
            onPressed: hasSelectedLayer ? onAutoSelect : null,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            key: menuKey.value,
            icon: Icons.more_vert,
            label: 'Menu',
            color: Colors.blue,
            onPressed: hasSelectedLayer
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'More Actions',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.opacity, color: Colors.blue, size: 18),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Adjust Opacity', style: TextStyle(fontSize: 14)),
                              onTap: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    double opacity = selectedLayer!.opacity;
                                    return AlertDialog(
                                      title: Text(
                                        'Adjust Layer Opacity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 16,
                                        ),
                                      ),
                                      content: StatefulBuilder(
                                        builder: (context, setState) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CustomSlider(
                                                value: opacity,
                                                min: 0.0,
                                                max: 1.0,
                                                onChanged: (value) {
                                                  setState(() {
                                                    opacity = value;
                                                  });
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            onLayerUpdated(selectedLayer.copyWith(opacity: opacity));
                                          },
                                          child: const Text('Apply'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.checklist_outlined, color: Colors.green, size: 18),
                              title: const Text('Add to Template', style: TextStyle(fontSize: 14)),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.of(context).pop();
                                onLayerToTemplate(selectedLayer!);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Strings.of(context).deleteLayer),
          content: Text(Strings.of(context).areYouSureWantToDeleteLayer),
          actions: <Widget>[
            TextButton(
              child: Text(Strings.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(Strings.of(context).delete),
              onPressed: () {
                Navigator.of(context).pop();
                onLayerDeleted(index);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditLayerDialog(BuildContext context, Layer layer) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _EditLayerDialog(layer: layer),
    );

    if (newName != null && newName.isNotEmpty) {
      onLayerUpdated(layer.copyWith(name: newName));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool badge;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            color: isEnabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isEnabled ? color : Colors.grey.shade400,
                  ),
                  if (badge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final Layer layer;
  final int index;
  final bool isSelected;
  final Function(int) onLayerSelected;
  final Function(int) onLayerVisibilityChanged;

  const _LayerTile({
    super.key,
    required this.layer,
    required this.index,
    required this.isSelected,
    required this.onLayerSelected,
    required this.onLayerVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 40,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        elevation: isSelected ? 3 : 1,
        color: isSelected ? Colors.blue.withValues(alpha: 0.7) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected ? BorderSide(color: Colors.blue.shade300, width: 2) : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onLayerSelected(index),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => onLayerVisibilityChanged(index),
                  icon: Icon(
                    layer.isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: contentColor,
                  ),
                ),
                Text(
                  layer.name,
                  style: TextStyle(
                    color: contentColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditLayerDialog extends StatefulWidget {
  final Layer layer;

  const _EditLayerDialog({required this.layer});

  @override
  State<_EditLayerDialog> createState() => _EditLayerDialogState();
}

class _EditLayerDialogState extends State<_EditLayerDialog> {
  late final TextEditingController _nameController;
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layer.name);
    // Automatically focus the text field when the dialog appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Layer', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Layer Name',
          border: OutlineInputBorder(),
        ),
        focusNode: _nameFocusNode,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_nameController.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _BackgroundImageTile extends ConsumerWidget {
  final int width;
  final int height;

  const _BackgroundImageTile({required this.width, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundImage = ref.watch(backgroundImageProvider);
    if (backgroundImage.image == null) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: Image.memory(
                      backgroundImage.image!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('BG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Reference', style: TextStyle(fontSize: 10, color: Colors.amber.shade800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => ref.read(backgroundImageProvider.notifier).resetTransform(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Reset', style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => ref
                                .read(backgroundImageProvider.notifier)
                                .fitToCanvas(width.toDouble(), height.toDouble()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Fit', style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 15, color: Colors.red.shade400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showBackgroundDeleteConfirmation(context, ref),
                  tooltip: 'Remove background image',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSliderRow(
              context,
              icon: Icons.opacity,
              value: backgroundImage.opacity,
              onChanged: (value) =>
                  ref.read(backgroundImageProvider.notifier).update((state) => state.copyWith(opacity: value)),
              activeColor: Colors.amber,
              label: '${(backgroundImage.opacity * 100).toInt()}%',
            ),
            _buildSliderRow(
              context,
              icon: Icons.zoom_in,
              value: backgroundImage.scale,
              min: 0.1,
              max: 1,
              onChanged: (value) => ref.read(backgroundImageProvider.notifier).setScale(value),
              activeColor: Colors.blue,
              label: '${(backgroundImage.scale * 100).toInt()}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
    required Color activeColor,
    required String label,
    double min = 0.0,
    double max = 1.0,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: activeColor.withValues(alpha: 0.7),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: activeColor.withValues(alpha: 0.9),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  void _showBackgroundDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Background Image'),
          content: const Text('Are you sure you want to remove the background image?'),
          actions: <Widget>[
            TextButton(
              child: Text(Strings.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(backgroundImageProvider.notifier).update((state) => state.copyWith(image: null));
              },
            ),
          ],
        );
      },
    );
  }
}
