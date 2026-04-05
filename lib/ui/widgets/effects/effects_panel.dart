import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../pixel/effects/effects.dart';
import '../../../data/models/layer.dart';
import '../../../data/models/selection_region.dart';
import '../animated_background.dart';
import 'effect_list_item.dart';
import 'effects_editor_dialog.dart';
import 'effects_selector_dialog.dart';
import 'pixlel_preview_painter.dart';

class EffectsPanel extends StatefulWidget {
  final Layer layer;
  final Function(Layer) onLayerUpdated;
  final int width;
  final int height;
  final SelectionRegion? selectionRegion;
  final bool isDialog;
  final VoidCallback? onClose;

  const EffectsPanel({
    super.key,
    required this.layer,
    required this.onLayerUpdated,
    required this.width,
    required this.height,
    this.selectionRegion,
    this.isDialog = false,
    this.onClose,
  });

  @override
  State<EffectsPanel> createState() => _EffectsPanelState();
}

class _EffectsPanelState extends State<EffectsPanel> {
  late List<Effect> _effects;
  Uint32List? _previewPixels;
  int? _selectedEffectIndex;

  @override
  void initState() {
    super.initState();
    _effects = List<Effect>.from(widget.layer.effects);
    _updatePreview();
  }

  void _updatePreview() {
    if (_effects.isEmpty) {
      _previewPixels = widget.layer.pixels;
    } else if (widget.selectionRegion != null) {
      _previewPixels = EffectsManager.applyMultipleEffectsToSelection(
        widget.layer.pixels,
        widget.width,
        widget.height,
        _effects,
        widget.selectionRegion!,
      );
    } else {
      _previewPixels = EffectsManager.applyMultipleEffects(
        widget.layer.pixels,
        widget.width,
        widget.height,
        _effects,
      );
    }
    // Ensure the UI rebuilds after the preview is updated.
    if (mounted) {
      setState(() {});
    }
  }

  void _addEffect() {
    showDialog(
      context: context,
      builder: (context) => EffectSelectorDialog(
        onEffectSelected: (effect) {
          setState(() {
            _effects.add(effect);
            _updatePreview();
          });
        },
      ),
    );
  }

  void _editEffect(int index) {
    showDialog(
      context: context,
      builder: (context) => EffectEditorDialog(
        effect: _effects[index],
        layerWidth: widget.width,
        layerHeight: widget.height,
        layerPixels: widget.layer.pixels,
        onEffectUpdated: (updatedEffect) {
          setState(() {
            _effects[index] = updatedEffect;
            _updatePreview();
          });
        },
      ),
    );
  }

  void _removeEffect(int index) {
    setState(() {
      _effects.removeAt(index);
      if (_selectedEffectIndex == index) {
        _selectedEffectIndex = null;
      } else if (_selectedEffectIndex != null && _selectedEffectIndex! > index) {
        _selectedEffectIndex = _selectedEffectIndex! - 1;
      }
      _updatePreview();
    });
  }

  void _clearAllEffects() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Effects'),
        content: const Text('Are you sure you want to remove all effects from this layer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _effects.clear();
                _selectedEffectIndex = null;
                _updatePreview();
              });
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _applyChanges() {
    final updatedLayer = widget.selectionRegion == null
        ? widget.layer.copyWith(effects: _effects)
        : widget.layer.copyWith(
            pixels: EffectsManager.applyMultipleEffectsToSelection(
              widget.layer.pixels,
              widget.width,
              widget.height,
              _effects,
              widget.selectionRegion!,
            ),
            effects: const [],
          );
    widget.onLayerUpdated(updatedLayer);
    if (widget.isDialog) {
      Navigator.of(context).pop();
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _effects.removeAt(oldIndex);
      _effects.insert(newIndex, item);
      _updatePreview();
    });
  }

  void _handleSelect(int index) {
    setState(() {
      _selectedEffectIndex = _selectedEffectIndex == index ? null : index;
    });
  }

  void _performApplyEffect(Effect effect) {
    final effectsToApply = [effect];
    final index = _effects.indexOf(effect);

    final processedPixels = widget.selectionRegion == null
        ? EffectsManager.applyMultipleEffects(
            widget.layer.pixels,
            widget.width,
            widget.height,
            effectsToApply,
          )
        : EffectsManager.applyMultipleEffectsToSelection(
            widget.layer.pixels,
            widget.width,
            widget.height,
            effectsToApply,
            widget.selectionRegion!,
          );

    setState(() {
      _effects.removeAt(index);
      if (_selectedEffectIndex == index) {
        _selectedEffectIndex = null;
      } else if (_selectedEffectIndex != null && _selectedEffectIndex! > index) {
        _selectedEffectIndex = _selectedEffectIndex! - 1;
      }
    });

    final updatedLayer = widget.layer.copyWith(
      pixels: processedPixels,
      effects: widget.selectionRegion == null ? _effects : const [],
    );

    _updatePreview();

    widget.onLayerUpdated(updatedLayer);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Effect "${effectsToApply[index].getName(context)}" applied to layer'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _performApplyAllEffects() {
    // Apply all effects to get processed pixels
    final processedPixels = widget.selectionRegion == null
        ? EffectsManager.applyMultipleEffects(
            widget.layer.pixels,
            widget.width,
            widget.height,
            _effects,
          )
        : EffectsManager.applyMultipleEffectsToSelection(
            widget.layer.pixels,
            widget.width,
            widget.height,
            _effects,
            widget.selectionRegion!,
          );

    // Clear all effects
    setState(() {
      _effects.clear();
      _selectedEffectIndex = null;
    });

    // Create updated layer with processed pixels as base pixels and no effects
    final updatedLayer = widget.layer.copyWith(
      pixels: processedPixels,
      effects: [],
    );

    // Update preview
    _updatePreview();

    // Call the callback to update the layer
    widget.onLayerUpdated(updatedLayer);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All effects applied to layer and removed from effects list'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;

    return LayoutBuilder(builder: (context, constraints) {
      if (isMobile) {
        return _MobileLayout(
          layer: widget.layer,
          effects: _effects,
          previewPixels: _previewPixels,
          selectedEffectIndex: _selectedEffectIndex,
          width: widget.width,
          height: widget.height,
          isDialog: widget.isDialog,
          onClose: widget.onClose,
          onAddEffect: _addEffect,
          onApplyChanges: _applyChanges,
          onEditEffect: _editEffect,
          onRemoveEffect: _removeEffect,
          onSelectEffect: _handleSelect,
          onApplyEffect: _performApplyEffect,
        );
      } else if (isTablet) {
        return _TabletLayout(
          layer: widget.layer,
          effects: _effects,
          previewPixels: _previewPixels,
          selectedEffectIndex: _selectedEffectIndex,
          width: widget.width,
          height: widget.height,
          isDialog: widget.isDialog,
          onClose: widget.onClose,
          onAddEffect: _addEffect,
          onApplyChanges: _applyChanges,
          onEditEffect: _editEffect,
          onRemoveEffect: _removeEffect,
          onSelectEffect: _handleSelect,
          onApplyEffect: _performApplyEffect,
        );
      } else {
        return _DesktopLayout(
          layer: widget.layer,
          effects: _effects,
          previewPixels: _previewPixels,
          selectedEffectIndex: _selectedEffectIndex,
          width: widget.width,
          height: widget.height,
          isDialog: widget.isDialog,
          onClose: widget.onClose,
          onAddEffect: _addEffect,
          onApplyChanges: _applyChanges,
          onEditEffect: _editEffect,
          onRemoveEffect: _removeEffect,
          onSelectEffect: _handleSelect,
          onClearAllEffects: _clearAllEffects,
          onReorder: _handleReorder,
          onApplyEffect: _performApplyEffect,
          onApplyAllEffects: _performApplyAllEffects,
        );
      }
    });
  }
}

class _MobileLayout extends StatelessWidget {
  final Layer layer;
  final List<Effect> effects;
  final Uint32List? previewPixels;
  final int? selectedEffectIndex;
  final int width;
  final int height;
  final bool isDialog;
  final VoidCallback? onClose;
  final VoidCallback onAddEffect;
  final VoidCallback onApplyChanges;
  final ValueChanged<int> onEditEffect;
  final ValueChanged<int> onRemoveEffect;
  final ValueChanged<int> onSelectEffect;
  final ValueChanged<Effect> onApplyEffect;

  const _MobileLayout({
    required this.layer,
    required this.effects,
    required this.previewPixels,
    required this.selectedEffectIndex,
    required this.width,
    required this.height,
    required this.isDialog,
    this.onClose,
    required this.onAddEffect,
    required this.onApplyChanges,
    required this.onEditEffect,
    required this.onRemoveEffect,
    required this.onSelectEffect,
    required this.onApplyEffect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBar(
          title: Text(
            'Effects for ${layer.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: isDialog
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAddEffect,
              tooltip: 'Add effect',
            ),
          ],
        ),
        if (previewPixels != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Theme.of(context).canvasColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _PreviewWidget(
                  pixels: previewPixels,
                  width: width,
                  height: height,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applied Effects',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Text(
                '${effects.length} effect${effects.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: effects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Feather.droplet,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No effects applied',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Effect'),
                        onPressed: onAddEffect,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: effects.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedEffectIndex == index;
                    final effect = effects[index];
                    return EffectListItem(
                      effect: effect,
                      isSelected: isSelected,
                      onSelect: () => onSelectEffect(index),
                      onEdit: () => onEditEffect(index),
                      onRemove: () => onRemoveEffect(index),
                      onApply: () => onApplyEffect(effect),
                      showApplyButton: true,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onApplyChanges,
              child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final Layer layer;
  final List<Effect> effects;
  final Uint32List? previewPixels;
  final int? selectedEffectIndex;
  final int width;
  final int height;
  final bool isDialog;
  final VoidCallback? onClose;
  final VoidCallback onAddEffect;
  final VoidCallback onApplyChanges;
  final ValueChanged<int> onEditEffect;
  final ValueChanged<int> onRemoveEffect;
  final ValueChanged<int> onSelectEffect;
  final ValueChanged<Effect> onApplyEffect;

  const _TabletLayout({
    required this.layer,
    required this.effects,
    required this.previewPixels,
    required this.selectedEffectIndex,
    required this.width,
    required this.height,
    required this.isDialog,
    this.onClose,
    required this.onAddEffect,
    required this.onApplyChanges,
    required this.onEditEffect,
    required this.onRemoveEffect,
    required this.onSelectEffect,
    required this.onApplyEffect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: Text(
                  'Effects Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                leading: isDialog
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: onClose ?? () => Navigator.of(context).pop(),
                      )
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.white,
                    ),
                    child: _PreviewWidget(
                      pixels: previewPixels,
                      width: width,
                      height: height,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Effect'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onAddEffect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: onApplyChanges,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: Text(
                  'Effects for ${layer.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                automaticallyImplyLeading: false,
                actions: [
                  Text(
                    '${effects.length} effect${effects.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              Expanded(
                child: effects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Feather.droplet,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No effects applied',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: effects.length,
                        itemBuilder: (context, index) {
                          final isSelected = selectedEffectIndex == index;
                          final effect = effects[index];
                          return EffectListItem(
                            effect: effect,
                            isSelected: isSelected,
                            onSelect: () => onSelectEffect(index),
                            onEdit: () => onEditEffect(index),
                            onRemove: () => onRemoveEffect(index),
                            onApply: () => onApplyEffect(effect),
                            showApplyButton: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Layer layer;
  final List<Effect> effects;
  final Uint32List? previewPixels;
  final int? selectedEffectIndex;
  final int width;
  final int height;
  final bool isDialog;
  final VoidCallback? onClose;
  final VoidCallback onAddEffect;
  final VoidCallback onApplyChanges;
  final ValueChanged<int> onEditEffect;
  final ValueChanged<int> onRemoveEffect;
  final ValueChanged<int> onSelectEffect;
  final VoidCallback onClearAllEffects;
  final ValueChanged<Effect> onApplyEffect;
  final VoidCallback onApplyAllEffects;
  final ReorderCallback onReorder;

  const _DesktopLayout({
    required this.layer,
    required this.effects,
    required this.previewPixels,
    required this.selectedEffectIndex,
    required this.width,
    required this.height,
    required this.isDialog,
    this.onClose,
    required this.onAddEffect,
    required this.onApplyChanges,
    required this.onEditEffect,
    required this.onRemoveEffect,
    required this.onSelectEffect,
    required this.onClearAllEffects,
    required this.onReorder,
    required this.onApplyEffect,
    required this.onApplyAllEffects,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: Text(
                  'Effect Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                leading: isDialog
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: onClose ?? () => Navigator.of(context).pop(),
                      )
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Final Result',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.white,
                                ),
                                child: _PreviewWidget(
                                  pixels: previewPixels,
                                  width: width,
                                  height: height,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (effects.isNotEmpty)
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Before & After',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            color: Theme.of(context).canvasColor,
                                          ),
                                          child: CustomPaint(
                                            painter: PixelPreviewPainter(
                                              pixels: layer.pixels,
                                              width: width,
                                              height: height,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Original'),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            color: Theme.of(context).canvasColor,
                                          ),
                                          child: _PreviewWidget(
                                            pixels: previewPixels,
                                            width: width,
                                            height: height,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('With Effects'),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Effect'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onAddEffect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: onApplyChanges,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: Text(
                  layer.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                centerTitle: false,
                automaticallyImplyLeading: false,
                actions: [
                  if (effects.isNotEmpty) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                      onPressed: onClearAllEffects,
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      icon: const Icon(Feather.check_circle),
                      label: const Text('Apply All'),
                      onPressed: onApplyAllEffects,
                    ),
                  ] else ...[
                    const SizedBox(),
                  ],
                  const SizedBox(width: 16),
                ],
              ),
              if (effects.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${effects.length} effect${effects.length != 1 ? 's' : ''} applied',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('Effects are applied in order'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Effects are applied from top to bottom. Drag to reorder.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: effects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Feather.droplet,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No effects applied',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add your first effect'),
                              onPressed: onAddEffect,
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: effects.length,
                        onReorder: onReorder,
                        itemBuilder: (context, index) {
                          final isSelected = selectedEffectIndex == index;
                          final effect = effects[index];
                          return EffectListItem(
                            key: ValueKey(effect.type.toString() + index.toString()),
                            effect: effect,
                            isSelected: isSelected,
                            onSelect: () => onSelectEffect(index),
                            onEdit: () => onEditEffect(index),
                            onRemove: () => onRemoveEffect(index),
                            onApply: () => onApplyEffect(effect),
                            showDragHandle: true,
                            showApplyButton: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewWidget extends StatelessWidget {
  final Uint32List? pixels;
  final int width;
  final int height;

  const _PreviewWidget({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (pixels == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomPaint(
      painter: PixelPreviewPainter(
        pixels: pixels!,
        width: width,
        height: height,
      ),
    );
  }
}

extension EffectPanelDialogExtension on BuildContext {
  Future<void> showEffectsPanel({
    required Layer layer,
    required int width,
    required int height,
    required Function(Layer) onLayerUpdated,
    SelectionRegion? selectionRegion,
  }) {
    final size = MediaQuery.sizeOf(this);
    final isSmallScreen = size.width < 600;
    if (isSmallScreen) {
      return showModalBottomSheet(
        context: this,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SizedBox(
          height: size.height * 0.95,
          child: EffectsPanel(
            layer: layer,
            width: width,
            height: height,
            onLayerUpdated: onLayerUpdated,
            selectionRegion: selectionRegion,
            isDialog: true,
          ),
        ),
      );
    }

    return showDialog(
      context: this,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: size.width < 600 ? double.infinity : 900,
            maxHeight: size.width < 600 ? double.infinity : 900,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBackground(
              child: EffectsPanel(
                layer: layer,
                width: width,
                height: height,
                onLayerUpdated: onLayerUpdated,
                selectionRegion: selectionRegion,
                isDialog: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
