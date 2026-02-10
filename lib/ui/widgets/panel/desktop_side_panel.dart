import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../pixel/pixel_canvas_state.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../pixel/tools.dart';
import 'color_palette_panel.dart';
import '../dialogs/layer_template_dialog.dart';
import '../effects/effects_side_panel.dart';
import '../layers_panel.dart';

class DesktopSidePanel extends StatefulHookConsumerWidget {
  final int width;
  final int height;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final ValueNotifier<PixelTool> currentTool;

  const DesktopSidePanel({
    super.key,
    required this.width,
    required this.height,
    required this.state,
    required this.notifier,
    required this.currentTool,
  });

  @override
  ConsumerState<DesktopSidePanel> createState() => _DesktopSidePanelState();
}

class _DesktopSidePanelState extends ConsumerState<DesktopSidePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: SizedBox(
        width: 250,
        child: Column(
          children: [
            // Layers + Effects with TabBar — flex 3
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Material(
                    color: colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
                      indicatorColor: colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 2,
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.5,
                      ),
                      dividerHeight: 0,
                      tabs: const [
                        Tab(
                          height: 32,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.layers_outlined, size: 14),
                              SizedBox(width: 4),
                              Text('Layers'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_fix_high_outlined, size: 14),
                              SizedBox(width: 4),
                              Text('Effects'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        LayersPanel(
                          width: widget.width,
                          height: widget.height,
                          layers: widget.state.currentFrame.layers,
                          activeLayerIndex: widget.state.currentLayerIndex,
                          onLayerUpdated: (layer) {
                            widget.notifier.updateLayer(layer);
                          },
                          onLayerAdded: (name) {
                            widget.notifier.addLayer(name);
                          },
                          onLayerVisibilityChanged: (index) {
                            widget.notifier.toggleLayerVisibility(index);
                          },
                          onLayerSelected: (index) {
                            widget.notifier.selectLayer(index);
                          },
                          onLayerDeleted: (index) {
                            widget.notifier.removeLayer(index);
                          },
                          onLayerLockedChanged: (index) {},
                          onLayerReordered: (oldIndex, newIndex) {
                            widget.notifier.reorderLayers(
                              newIndex,
                              oldIndex,
                            );
                          },
                          onLayerOpacityChanged: (index, opacity) {},
                          onLayerEffectsChanged: (updatedLayer) {
                            widget.notifier.updateLayer(updatedLayer);
                          },
                          onLayerDuplicated: (index) {
                            widget.notifier.duplicateLayer(index);
                          },
                          onLayerToTemplate: (layer) {
                            LayerToTemplateDialog.show(context,
                                layer: layer, width: widget.width, height: widget.height);
                          },
                        ),
                        EffectsSidePanel(
                          layer: widget.state.layers[widget.state.currentLayerIndex],
                          width: widget.width,
                          height: widget.height,
                          onLayerUpdated: (updatedLayer) {
                            widget.notifier.updateLayer(updatedLayer);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
            // Color palette — flex 2
            Expanded(
              flex: 2,
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
}
