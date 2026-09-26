import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/models/selection_region.dart';
import '../../../l10n/strings.dart';
import '../../../providers/subscription_provider.dart';
import '../../../pixel/effects/effects.dart';
import '../../../pixel/services/effect_stack_service.dart';
import '../../utils/multi_selection.dart';
import '../panel_select_all_region.dart';
import 'effect_list_item.dart';
import 'effects_editor_dialog.dart';
import 'effects_empty_widget.dart';
import 'effects_selector_dialog.dart';

class EffectsSidePanel extends StatefulHookConsumerWidget {
  final Layer layer;
  final int width;
  final int height;
  final SelectionRegion? selectionRegion;
  final Function(Layer)? onLayerUpdated;
  final void Function(Effect, List<Effect>, int)? onAnimate;
  final EffectWorkspace? workspace;
  final AnimationKind? animationKind;
  final VoidCallback? onConvertToPixels;

  const EffectsSidePanel({
    super.key,
    required this.layer,
    required this.width,
    required this.height,
    this.selectionRegion,
    this.onLayerUpdated,
    this.onAnimate,
    this.workspace,
    this.animationKind,
    this.onConvertToPixels,
  });

  @override
  ConsumerState<EffectsSidePanel> createState() => _EffectsSidePanelState();
}

class _EffectsSidePanelState extends ConsumerState<EffectsSidePanel> {
  late List<Effect> _effects;
  int? _selectedEffectIndex;
  Set<int> _selectedEffectIndices = {};
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _effects = List<Effect>.from(widget.layer.effects);
  }

  @override
  void didUpdateWidget(EffectsSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layer != widget.layer ||
        oldWidget.workspace != widget.workspace ||
        oldWidget.animationKind != widget.animationKind) {
      setState(() {
        _effects = List<Effect>.from(widget.layer.effects);
        _selectedEffectIndex = null;
        _selectedEffectIndices = {};
      });
    }
  }

  bool _isVisibleEffect(Effect effect) {
    final descriptor = EffectCatalog.forType(effect.type);
    if (widget.workspace != null && descriptor.workspace != widget.workspace) {
      return false;
    }
    if (widget.animationKind != null &&
        descriptor.animationKind != widget.animationKind) {
      return false;
    }
    return true;
  }

  List<int> get _visibleEffectIndices => [
        for (final (index, effect) in _effects.indexed)
          if (_isVisibleEffect(effect)) index,
      ];

  String? _workspaceLabel(BuildContext context) {
    final workspace = widget.workspace;
    if (workspace == null) return null;

    final strings = Strings.of(context);
    final workspaceLabel = switch (workspace) {
      EffectWorkspace.filters => strings.effectWorkspaceFilters,
      EffectWorkspace.materials => strings.effectWorkspaceMaterials,
      EffectWorkspace.generators => strings.effectWorkspaceGenerators,
      EffectWorkspace.animation => strings.effectWorkspaceAnimation,
      EffectWorkspace.lighting => strings.effectWorkspaceLighting,
      EffectWorkspace.distortions => strings.effectWorkspaceDistortions,
    };
    final animationLabel = switch (widget.animationKind) {
      AnimationKind.transformer => strings.animationTransformers,
      AnimationKind.specialEffect => strings.animationSpecialEffects,
      null => null,
    };
    return animationLabel == null
        ? workspaceLabel
        : '$workspaceLabel · $animationLabel';
  }

  IconData get _workspaceIcon => switch (widget.workspace) {
        EffectWorkspace.filters => Icons.filter_alt_outlined,
        EffectWorkspace.materials => Icons.texture_outlined,
        EffectWorkspace.generators => Icons.auto_awesome_outlined,
        EffectWorkspace.animation =>
          widget.animationKind == AnimationKind.transformer
              ? Icons.transform
              : Icons.auto_awesome,
        EffectWorkspace.lighting => Icons.light_mode_outlined,
        EffectWorkspace.distortions => Icons.waves_outlined,
        null => Icons.auto_fix_high,
      };

  void _updateLayer() {
    if (widget.selectionRegion != null) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (widget.onLayerUpdated != null) {
        final updatedLayer = widget.layer.copyWith(effects: _effects);
        widget.onLayerUpdated!(updatedLayer);
      }
    });
  }

  void _addEffect() {
    showDialog(
      context: context,
      builder: (context) => EffectSelectorDialog(
        initialWorkspace: widget.workspace,
        lockWorkspace: widget.workspace != null,
        initialAnimationKind: widget.animationKind,
        lockAnimationKind: widget.animationKind != null,
        layer: widget.layer.copyWith(effects: _effects),
        onEffectSelected: (effect) {
          final result = EffectStackService.addEffect(
            widget.layer.copyWith(effects: _effects),
            effect,
          );
          if (!result.didAdd) return;
          setState(() {
            _effects = List<Effect>.from(result.layer.effects);
          });
          _updateLayer();
        },
      ),
    );
  }

  void _editEffect(int index) {
    if (index >= 0 && index < _effects.length) {
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
            });
            _updateLayer();
          },
        ),
      );
    }
  }

  void _removeEffect(int index) {
    if (index >= 0 && index < _effects.length) {
      final s = Strings.of(context);
      final effectName = _effects[index].getName(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.effectsPanelRemoveEffectTitle),
          content: Text(s.effectsPanelRemoveEffectMessage(effectName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _effects.removeAt(index);
                  _adjustSelectionAfterRemoval(index);
                });
                _updateLayer();
              },
              child: Text(s.effectsPanelActionRemove),
            ),
          ],
        ),
      );
    }
  }

  void _removeSelectedEffect() {
    if (_selectedEffectIndices.isEmpty) return;
    if (_selectedEffectIndices.length == 1) {
      _removeEffect(_selectedEffectIndices.single);
      return;
    }

    final s = Strings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.effectsPanelRemoveEffectTitle),
        content: Text(
            '${s.effectsPanelActionRemove}: ${_selectedEffectIndices.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final selected = _selectedEffectIndices;
                _effects = [
                  for (final (index, effect) in _effects.indexed)
                    if (!selected.contains(index)) effect,
                ];
                _selectedEffectIndices = {};
                _selectedEffectIndex = null;
              });
              _updateLayer();
            },
            child: Text(s.effectsPanelActionRemove),
          ),
        ],
      ),
    );
  }

  void _adjustSelectionAfterRemoval(int removedIndex) {
    _selectedEffectIndices = {
      for (final index in _selectedEffectIndices)
        if (index != removedIndex) index > removedIndex ? index - 1 : index,
    };
    if (_selectedEffectIndex == removedIndex) {
      _selectedEffectIndex =
          _selectedEffectIndices.isEmpty ? null : _selectedEffectIndices.first;
    } else if (_selectedEffectIndex != null &&
        _selectedEffectIndex! > removedIndex) {
      _selectedEffectIndex = _selectedEffectIndex! - 1;
    }
  }

  void _clearAllEffects() {
    if (_visibleEffectIndices.isEmpty) return;

    final s = Strings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.effectsPanelClearAllEffectsTitle),
        content: Text(s.effectsPanelClearAllEffectsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _effects.removeWhere(_isVisibleEffect);
                _selectedEffectIndex = null;
                _selectedEffectIndices = {};
              });
              _updateLayer();
            },
            child: Text(s.effectsPanelClearAll),
          ),
        ],
      ),
    );
  }

  void _performApplyEffect(Effect effect) {
    final s = Strings.of(context);
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
      _adjustSelectionAfterRemoval(index);
    });

    final updatedLayer = widget.layer.copyWith(
      pixels: processedPixels,
      effects: widget.selectionRegion == null ? _effects : const [],
    );

    widget.onLayerUpdated!(updatedLayer);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.effectsPanelAppliedToLayerMessage(effect.getName(context)),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionStateProvider);
    final visibleEffectIndices = _visibleEffectIndices;
    final workspaceLabel = _workspaceLabel(context);

    return PanelSelectAllRegion(
      onSelectAll: () {
        if (visibleEffectIndices.isEmpty) return;
        setState(() {
          _selectedEffectIndices = visibleEffectIndices.toSet();
          _selectedEffectIndex ??= visibleEffectIndices.first;
        });
      },
      child: Column(
        children: [
          if (workspaceLabel != null)
            _buildWorkspaceHeader(
              context,
              label: workspaceLabel,
              count: visibleEffectIndices.length,
            ),
          if (visibleEffectIndices.isNotEmpty || widget.workspace == null)
            _buildActionButtonsBar(context, subscription),
          if (visibleEffectIndices.isEmpty)
            Expanded(
              child: EffectsEmptyWidget(
                addEffect: _addEffect,
                title: workspaceLabel,
                icon: _workspaceIcon,
              ),
            )
          else
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: visibleEffectIndices.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final reordered = [
                      for (final index in visibleEffectIndices) _effects[index],
                    ];
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    for (var index = 0;
                        index < visibleEffectIndices.length;
                        index++) {
                      _effects[visibleEffectIndices[index]] = reordered[index];
                    }
                    _selectedEffectIndices = {};
                    _selectedEffectIndex = null;
                  });
                  _updateLayer();
                },
                itemBuilder: (context, index) {
                  final effectIndex = visibleEffectIndices[index];
                  final isSelected =
                      _selectedEffectIndices.contains(effectIndex);
                  return EffectListItem(
                    key: ValueKey(_effects[effectIndex].type.toString() +
                        effectIndex.toString()),
                    effect: _effects[effectIndex],
                    isSelected: isSelected,
                    onSelect: () {
                      setState(() {
                        final result = updateMultiSelection(
                          orderedItems: visibleEffectIndices,
                          selected: _selectedEffectIndices,
                          active: _selectedEffectIndex ?? effectIndex,
                          clicked: effectIndex,
                          anchor: _selectedEffectIndex,
                          toggle: isMultiSelectTogglePressed,
                          extendRange: isRangeSelectPressed,
                        );
                        _selectedEffectIndices = result.selected;
                        _selectedEffectIndex = result.active;
                      });
                    },
                    onEdit: () => _editEffect(effectIndex),
                    onAnimate: widget.onAnimate == null
                        ? null
                        : () => widget.onAnimate!(_effects[effectIndex],
                            List<Effect>.from(_effects), effectIndex),
                    onRemove: () => _removeEffect(effectIndex),
                    showDragHandle: true,
                    showRemoveButton: false,
                    onParametersChanged: (updatedEffect) {
                      setState(() {
                        _effects[effectIndex] = updatedEffect;
                      });
                      _updateLayer();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader(
    BuildContext context, {
    required String label,
    required int count,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('effects-workspace-header'),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.16),
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(_workspaceIcon, size: 17, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              key: const ValueKey('effects-workspace-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Container(
            key: const ValueKey('effects-workspace-count'),
            constraints: const BoxConstraints(minWidth: 24),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          IconButton(
            key: const ValueKey('effects-workspace-add'),
            tooltip: Strings.of(context).effectsPanelAddEffect,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: _addEffect,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsBar(
      BuildContext context, UserSubscription subscription) {
    final s = Strings.of(context);
    final selectedEffect =
        _selectedEffectIndex == null ? null : _effects[_selectedEffectIndex!];
    final selectedIsGenerator = selectedEffect != null &&
        EffectCatalog.forType(selectedEffect.type).role == EffectRole.generator;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.workspace == null) ...[
            _buildActionButton(
              context: context,
              icon: Icons.add,
              label: s.add,
              color: Colors.green,
              onPressed: _addEffect,
            ),
            const SizedBox(width: 8),
          ],
          _buildActionButton(
            context: context,
            icon: Icons.check,
            label: s.effectsPanelActionApply,
            color: Colors.blue,
            onPressed: selectedEffect == null
                ? null
                : selectedIsGenerator
                    ? widget.onConvertToPixels
                    : () => _performApplyEffect(selectedEffect),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context: context,
            icon: Icons.delete_outline,
            label: s.effectsPanelActionRemove,
            color: Colors.red,
            onPressed: _selectedEffectIndices.isNotEmpty
                ? _removeSelectedEffect
                : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context: context,
            icon: Icons.more_vert,
            label: s.effectsPanelActionMore,
            color: Colors.grey,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    s.effectsPanelMoreActionsTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onConvertToPixels != null)
                        ListTile(
                          key: const ValueKey('convert-procedural-to-pixels'),
                          leading: const Icon(Icons.grid_on),
                          title: Text(s.convertToPixels),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onConvertToPixels!();
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.checklist_outlined,
                            color: Colors.green),
                        title: Text(s.effectsPanelApplyAll),
                        onTap: () {},
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.delete_sweep, color: Colors.red),
                        title: Text(s.effectsPanelClearAllEffectsTitle),
                        onTap: () {
                          Navigator.of(context).pop();
                          _clearAllEffects();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool badge = false,
  }) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEnabled
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            color: isEnabled
                ? color.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
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
