import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../pixel/pixel_canvas_state.dart';
import '../../../pixel/effects/effects.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../pixel/tools.dart';
import 'color_palette_panel.dart';
import '../dialogs/layer_template_dialog.dart';
import '../effects/effects_side_panel.dart';
import '../effects/effects_selector_dialog.dart';
import '../effects/effects_editor_dialog.dart';
import '../effects/effect_animation_generator_dialog.dart';
import '../layers_panel.dart';
import '../../../l10n/strings.dart';
import '../notifications/app_notification.dart';

class DesktopSidePanel extends StatefulHookConsumerWidget {
  final int width;
  final int height;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final ValueNotifier<PixelTool> currentTool;
  final ValueChanged<List<int>>? onLayerSelectionChanged;

  const DesktopSidePanel({
    super.key,
    required this.width,
    required this.height,
    required this.state,
    required this.notifier,
    required this.currentTool,
    this.onLayerSelectionChanged,
  });

  @override
  ConsumerState<DesktopSidePanel> createState() => _DesktopSidePanelState();
}

class _DesktopSidePanelState extends ConsumerState<DesktopSidePanel> with TickerProviderStateMixin {
  late List<_SidePanelTab> _tabs;
  late TabController _tabController;
  _SidePanelTab _lastContentTab = _SidePanelTab.layers;
  EffectWorkspace? _pendingWorkspace;

  @override
  void initState() {
    super.initState();
    _tabs = _tabsForState(widget.state);
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didUpdateWidget(DesktopSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _syncTabs() {
    final nextTabs = _tabsForState(widget.state);
    final tabsChanged = !_sameTabs(_tabs, nextTabs);
    final pendingTab = _SidePanelTab.fromWorkspace(_pendingWorkspace);

    if (tabsChanged) {
      final currentTab = pendingTab ?? _tabs[_tabController.index];
      _tabController.dispose();
      _tabs = nextTabs;
      final initialIndex =
          _tabs.contains(currentTab) ? _tabs.indexOf(currentTab) : _tabs.indexOf(_SidePanelTab.filters);
      _tabController = TabController(
        length: _tabs.length,
        initialIndex: initialIndex,
        vsync: this,
      );
      _lastContentTab = _tabs[initialIndex];
      _pendingWorkspace = null;
      return;
    }

    if (pendingTab != null && _tabs.contains(pendingTab)) {
      final index = _tabs.indexOf(pendingTab);
      _lastContentTab = pendingTab;
      _pendingWorkspace = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(index);
      });
    }
  }

  List<_SidePanelTab> _tabsForState(PixelCanvasState state) {
    return [_SidePanelTab.layers, _SidePanelTab.filters, _SidePanelTab.materials, _SidePanelTab.lighting];
  }

  bool _sameTabs(List<_SidePanelTab> left, List<_SidePanelTab> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _onTabTapped(int index) {
    final tab = _tabs[index];
    if (tab != _SidePanelTab.add) {
      _lastContentTab = tab;
      return;
    }

    final returnIndex = _tabs.indexOf(_lastContentTab);
    if (returnIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(returnIndex);
      });
    }

    EffectSelectorDialog.present(
      context: context,
      builder: (context) => EffectSelectorDialog(
        layer: widget.notifier.currentLayer,
        onEffectSelected: (effect) {
          final descriptor = EffectCatalog.forType(effect.type);
          if (descriptor.workspace == EffectWorkspace.animation && effect.isAnimation) {
            final sourceFrame = widget.notifier.currentFrame;
            final sourceLayer = widget.notifier.currentLayer;
            EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
              context,
              effect: effect,
              effects: [...sourceLayer.effects, effect],
              effectIndex: sourceLayer.effects.length,
              layerWidth: widget.width,
              layerHeight: widget.height,
              layerPixels: sourceLayer.pixels,
              onFramesGenerated: (frames) => widget.notifier.addGeneratedEffectFrames(
                frames,
                sourceFrameId: sourceFrame.id,
                sourceLayerId: sourceLayer.layerId,
              ),
            );
            return;
          }
          if (descriptor.workspace == EffectWorkspace.generators) {
            final sourceLayer = widget.notifier.currentLayer;
            EffectEditorDialog.show(
              context: context,
              effect: effect,
              layerWidth: widget.width,
              layerHeight: widget.height,
              layerPixels: sourceLayer.pixels,
              applyButtonText: Strings.of(context).apply,
              onApply: (configuredEffect) {
                widget.notifier.applyEffectToLayer(configuredEffect);
                AppNotification.success(
                  context,
                  Strings.of(context).effectsPanelAppliedToLayerMessage(
                    configuredEffect.getName(context),
                  ),
                  duration: const Duration(seconds: 2),
                );
              },
            );
            return;
          }
          _pendingWorkspace = descriptor.workspace;
          widget.notifier.addLayerEffect(effect);
        },
      ),
    );
  }

  Future<void> _confirmConvertToPixels() async {
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
    if (confirmed != true || !mounted) return;

    if (widget.notifier.convertCurrentLayerToPixels()) {
      AppNotification.info(
        context,
        strings.proceduralLayerConverted,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: SizedBox(
        width: 250,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Material(
                    color: colorScheme.surface,
                    child: TabBar(
                      key: const ValueKey('desktop-side-panel-tabs'),
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
                      indicatorColor: colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 2,
                      dividerHeight: 0,
                      onTap: _onTabTapped,
                      tabs: [
                        for (final tab in _tabs)
                          Tooltip(
                            message: tab.label(context),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 10,
                                color: _tabController.index == _tabs.indexOf(tab)
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              child: Tab(
                                key: ValueKey('side-panel-tab-${tab.name}'),
                                height: 36,
                                // icon: Icon(tab.icon, size: 18),
                                text: tab.label(context),
                                iconMargin: EdgeInsets.zero,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final tab in _tabs) _buildTabContent(tab),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            Expanded(
              flex: 3,
              child: ColorPalettePanel(
                currentColor: widget.state.currentColor,
                isEyedropperSelected: widget.currentTool.value == PixelTool.eyedropper,
                onSelectEyedropper: () {
                  widget.currentTool.value = PixelTool.eyedropper;
                },
                onColorSelected: (color) {
                  widget.notifier.currentColor = color;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(_SidePanelTab tab) {
    if (tab == _SidePanelTab.layers) {
      return LayersPanel(
        width: widget.width,
        height: widget.height,
        layers: widget.state.currentFrame.layers,
        activeLayerIndex: widget.state.currentLayerIndex,
        onLayerUpdated: widget.notifier.updateLayer,
        onLayerAdded: widget.notifier.addLayer,
        onLayersVisibilityChanged: widget.notifier.setLayersVisibility,
        onLayerSelected: widget.notifier.selectLayer,
        onLayersDeleted: widget.notifier.removeLayers,
        onLayersLockedChanged: widget.notifier.setLayersLocked,
        onLayerReordered: (oldIndex, newIndex) {
          widget.notifier.reorderLayers(newIndex, oldIndex);
        },
        onLayersOpacityChanged: widget.notifier.setLayersOpacity,
        onLayersTransformed: widget.notifier.transformLayers,
        onLayerEffectsChanged: widget.notifier.updateLayer,
        onLayersDuplicated: widget.notifier.duplicateLayers,
        onLayerToTemplate: (layer) {
          LayerToTemplateDialog.show(
            context,
            layer: layer,
            width: widget.width,
            height: widget.height,
          );
        },
        onAutoSelect: widget.notifier.autoSelectLayer,
        onSelectionChanged: widget.onLayerSelectionChanged,
      );
    }

    final workspace = tab.workspace;
    if (workspace == null) return const SizedBox.shrink();

    return _buildEffectsPanel(workspace);
  }

  Widget _buildEffectsPanel(
    EffectWorkspace workspace, {
    AnimationKind? animationKind,
  }) {
    return EffectsSidePanel(
      key: ValueKey(
        'effects-panel-${workspace.name}-${animationKind?.name ?? 'all'}',
      ),
      layer: widget.state.layers[widget.state.currentLayerIndex],
      width: widget.width,
      height: widget.height,
      workspace: workspace,
      animationKind: animationKind,
      onConvertToPixels: workspace == EffectWorkspace.generators && widget.notifier.currentLayerIsProcedural
          ? _confirmConvertToPixels
          : null,
      selectionRegion: widget.state.selectionState?.region,
      onLayerUpdated: widget.notifier.updateLayer,
      onAnimate: (effect, effects, effectIndex) {
        final sourceFrame = widget.notifier.currentFrame;
        final sourceLayer = widget.notifier.currentLayer;
        EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
          context,
          effect: effect,
          effects: effects,
          effectIndex: effectIndex,
          layerWidth: widget.width,
          layerHeight: widget.height,
          layerPixels: sourceLayer.pixels,
          onFramesGenerated: (frames) => widget.notifier.addGeneratedEffectFrames(
            frames,
            sourceFrameId: sourceFrame.id,
            sourceLayerId: sourceLayer.layerId,
          ),
        );
      },
    );
  }
}

enum _SidePanelTab {
  layers,
  filters,
  materials,
  generators,
  animation,
  lighting,
  add;

  EffectWorkspace? get workspace => switch (this) {
        filters => EffectWorkspace.filters,
        materials => EffectWorkspace.materials,
        generators => EffectWorkspace.generators,
        animation => EffectWorkspace.animation,
        lighting => EffectWorkspace.lighting,
        layers || add => null,
      };

  IconData get icon => switch (this) {
        layers => Icons.layers_outlined,
        filters => Icons.filter_alt_outlined,
        materials => Icons.texture_outlined,
        generators => Icons.auto_awesome_outlined,
        animation => Icons.animation_outlined,
        lighting => Icons.light_mode_outlined,
        add => Icons.add,
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
      add => strings.add,
    };
  }

  static _SidePanelTab? fromWorkspace(EffectWorkspace? workspace) {
    return switch (workspace) {
      null => null,
      EffectWorkspace.filters => filters,
      EffectWorkspace.materials => materials,
      EffectWorkspace.generators => generators,
      EffectWorkspace.animation => animation,
      EffectWorkspace.lighting => lighting,
    };
  }
}
