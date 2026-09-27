import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/models/layer.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/effects/effects.dart';
import '../../../pixel/pixel_canvas_state.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../app_icon.dart';
import '../dialogs/layer_template_dialog.dart';
import '../effects/effect_animation_generator_dialog.dart';
import '../effects/effects_side_panel.dart';
import '../layers_panel.dart';
import '../notifications/app_notification.dart';

enum _MobilePanelTab {
  layers,
  filters,
  materials,
  generators,
  animation,
  lighting;

  EffectWorkspace? get workspace => switch (this) {
        layers => null,
        filters => EffectWorkspace.filters,
        materials => EffectWorkspace.materials,
        generators => EffectWorkspace.generators,
        animation => EffectWorkspace.animation,
        lighting => EffectWorkspace.lighting,
      };

  IconData get icon => switch (this) {
        layers => Icons.layers_outlined,
        filters => Icons.filter_alt_outlined,
        materials => Icons.texture_outlined,
        generators => Icons.auto_awesome_outlined,
        animation => Icons.animation_outlined,
        lighting => Icons.light_mode_outlined,
      };

  String label(BuildContext context) {
    final strings = Strings.of(context);
    return switch (this) {
      layers => strings.layers,
      filters => strings.effectWorkspaceFilters,
      materials => strings.effectWorkspaceMaterials,
      generators => strings.effectWorkspaceGenerators,
      animation => strings.effectWorkspaceAnimation,
      lighting => strings.effectWorkspaceLighting,
    };
  }
}

class MobileSidePanelBottomSheet extends StatefulWidget {
  final ValueListenable<PixelCanvasState> drawState;
  final PixelCanvasNotifier notifier;
  final int width;
  final int height;
  final EffectWorkspace? initialWorkspace;

  const MobileSidePanelBottomSheet({
    super.key,
    required this.drawState,
    required this.notifier,
    required this.width,
    required this.height,
    this.initialWorkspace,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueListenable<PixelCanvasState> drawState,
    required PixelCanvasNotifier notifier,
    required int width,
    required int height,
    EffectWorkspace? initialWorkspace,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => MobileSidePanelBottomSheet(
          drawState: drawState,
          notifier: notifier,
          width: width,
          height: height,
          initialWorkspace: initialWorkspace,
        ),
      ),
    );
  }

  @override
  State<MobileSidePanelBottomSheet> createState() =>
      _MobileSidePanelBottomSheetState();
}

class _MobileSidePanelBottomSheetState extends State<MobileSidePanelBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<_MobilePanelTab> _tabs;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabs = _tabsForState(widget.drawState.value);

    int initialIndex = 0;
    if (widget.initialWorkspace != null) {
      final index =
          _tabs.indexWhere((t) => t.workspace == widget.initialWorkspace);
      if (index >= 0) initialIndex = index;
    }

    _tabController = TabController(
      length: _tabs.length,
      initialIndex: initialIndex,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_MobilePanelTab> _tabsForState(PixelCanvasState state) {
    final usedWorkspaces = <EffectWorkspace>{
      for (final layer in state.currentFrame.layers)
        for (final effect in layer.effects)
          EffectCatalog.forType(effect.type).workspace,
    };

    return [
      _MobilePanelTab.layers,
      _MobilePanelTab.filters,
      _MobilePanelTab.materials,
      if (usedWorkspaces.contains(EffectWorkspace.generators))
        _MobilePanelTab.generators,
      if (usedWorkspaces.contains(EffectWorkspace.animation))
        _MobilePanelTab.animation,
      _MobilePanelTab.lighting,
    ];
  }

  bool _sameTabs(List<_MobilePanelTab> left, List<_MobilePanelTab> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  void _syncTabs(PixelCanvasState state) {
    final nextTabs = _tabsForState(state);
    if (!_sameTabs(_tabs, nextTabs)) {
      final currentTab = _tabs[_tabController.index.clamp(0, _tabs.length - 1)];
      _tabController.dispose();
      _tabs = nextTabs;
      final initialIndex =
          _tabs.contains(currentTab) ? _tabs.indexOf(currentTab) : 0;
      _tabController = TabController(
        length: _tabs.length,
        initialIndex: initialIndex,
        vsync: this,
      );
    }
  }

  int _countBadge(Layer? layer, _MobilePanelTab tab, int totalLayers) {
    if (tab == _MobilePanelTab.layers) {
      return totalLayers > 1 ? totalLayers : 0;
    }
    if (layer == null) return 0;
    final workspace = tab.workspace;
    if (workspace == null) return 0;
    return layer.effects
        .where((e) => EffectCatalog.forType(e.type).workspace == workspace)
        .length;
  }

  Future<void> _confirmConvertToPixels(BuildContext context) async {
    final strings = Strings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.convertProceduralLayerTitle),
        content: Text(strings.convertProceduralLayerMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.convertToPixels),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (widget.notifier.convertCurrentLayerToPixels()) {
      AppNotification.info(
        context,
        strings.proceduralLayerConverted,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = Strings.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ValueListenableBuilder<PixelCanvasState>(
        valueListenable: widget.drawState,
        builder: (context, state, _) {
          _syncTabs(state);

          final layerIndex = state.currentLayerIndex.clamp(
            0,
            state.layers.isEmpty ? 0 : state.layers.length - 1,
          );
          final currentLayer =
              state.layers.isEmpty ? null : state.layers[layerIndex];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const AppIcon(AppIcons.layers, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      strings.layers,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (currentLayer != null) ...[
                      if (state.layers.length > 1)
                        PopupMenuButton<int>(
                          tooltip: strings.layers,
                          initialValue: layerIndex,
                          onSelected: (index) {
                            widget.notifier.selectLayer(index);
                          },
                          itemBuilder: (context) => [
                            for (int i = 0; i < state.layers.length; i++)
                              PopupMenuItem(
                                value: i,
                                child: Row(
                                  children: [
                                    if (i == layerIndex)
                                      Icon(Icons.check,
                                          size: 16,
                                          color: colorScheme.primary)
                                    else
                                      const SizedBox(width: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        state.layers[i].name,
                                        style: TextStyle(
                                          fontWeight: i == layerIndex
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    currentLayer.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentLayer.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: strings.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // TabBar with first tab = Layers and then effect workspaces
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                labelColor: colorScheme.primary,
                unselectedLabelColor:
                    colorScheme.onSurface.withValues(alpha: 0.55),
                indicatorColor: colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 2,
                dividerHeight: 1,
                tabs: [
                  for (final tab in _tabs)
                    Tab(
                      key: ValueKey('mobile-side-panel-tab-${tab.name}'),
                      height: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(tab.label(context)),
                          Builder(
                            builder: (context) {
                              final count = _countBadge(
                                currentLayer,
                                tab,
                                state.layers.length,
                              );
                              if (count == 0) return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final tab in _tabs)
                      if (tab == _MobilePanelTab.layers)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LayersPanel(
                            width: widget.width,
                            height: widget.height,
                            layers: state.layers,
                            activeLayerIndex: layerIndex,
                            onLayerAdded: widget.notifier.addLayer,
                            onLayerUpdated: widget.notifier.updateLayer,
                            onLayersVisibilityChanged:
                                widget.notifier.setLayersVisibility,
                            onLayerSelected: widget.notifier.selectLayer,
                            onLayersDeleted: widget.notifier.removeLayers,
                            onLayersLockedChanged:
                                widget.notifier.setLayersLocked,
                            onLayersDuplicated:
                                widget.notifier.duplicateLayers,
                            onLayerReordered: (oldIndex, newIndex) {
                              widget.notifier.reorderLayers(newIndex, oldIndex);
                            },
                            onLayersOpacityChanged:
                                widget.notifier.setLayersOpacity,
                            onLayerEffectsChanged: widget.notifier.updateLayer,
                            onLayerToTemplate: (layer) {
                              Navigator.of(context).pop();
                              LayerToTemplateDialog.show(
                                context,
                                layer: layer,
                                width: state.width,
                                height: state.height,
                              );
                            },
                            onAutoSelect: widget.notifier.autoSelectLayer,
                          ),
                        )
                      else if (currentLayer != null)
                        EffectsSidePanel(
                          key: ValueKey(
                            'mobile-side-panel-${tab.workspace!.name}-${currentLayer.id}-${currentLayer.effects.length}',
                          ),
                          layer: currentLayer,
                          width: widget.width,
                          height: widget.height,
                          workspace: tab.workspace,
                          selectionRegion: state.selectionState?.region,
                          onLayerUpdated: (updatedLayer) {
                            widget.notifier.updateLayer(updatedLayer);
                          },
                          onConvertToPixels: tab.workspace ==
                                      EffectWorkspace.generators &&
                                  widget.notifier.currentLayerIsProcedural
                              ? () => _confirmConvertToPixels(context)
                              : null,
                          onAnimate: (effect, effects, effectIndex) {
                            final sourceFrame = widget.notifier.currentFrame;
                            final sourceLayer = widget.notifier.currentLayer;
                            EffectAnimationGeneratorDialog
                                .showEffectAnimationGenerator(
                              context,
                              effect: effect,
                              layerWidth: widget.width,
                              layerHeight: widget.height,
                              layerPixels: sourceLayer.pixels,
                              onFramesGenerated: (frames) =>
                                  widget.notifier.addGeneratedEffectFrames(
                                frames,
                                sourceFrameId: sourceFrame.id,
                                sourceLayerId: sourceLayer.layerId,
                              ),
                              effects: effects,
                              effectIndex: effectIndex,
                            );
                          },
                        )
                      else
                        const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
