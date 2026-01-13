import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../pixel/pixel_canvas_state.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/tools.dart';
import 'shortcuts_wrapper.dart';

class PixelCanvasShortcutsWrapper extends HookConsumerWidget {
  const PixelCanvasShortcutsWrapper({
    super.key,
    required this.shortcutsFocusNode,
    required this.currentTool,
    required this.brushSize,
    required this.gridScale,
    required this.gridOffset,
    required this.state,
    required this.notifier,
    required this.handleExport,
    required this.setZoomFit,
    required this.setZoom100,
    required this.showImportDialog,
    required this.showColorPicker,
    required this.toggleUI,
    required this.child,
  });

  final FocusNode shortcutsFocusNode;
  final ValueNotifier<PixelTool> currentTool;
  final ValueNotifier<int> brushSize;
  final ValueNotifier<double> gridScale;
  final ValueNotifier<Offset> gridOffset;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final Function(BuildContext context, PixelCanvasNotifier notifier, PixelCanvasState state) handleExport;
  final Function(ValueNotifier<double> scale, ValueNotifier<Offset> offset) setZoomFit;
  final Function(ValueNotifier<double> scale, ValueNotifier<Offset> offset) setZoom100;
  final Future<bool?> Function(BuildContext context) showImportDialog;
  final Function(BuildContext context, PixelCanvasNotifier notifier) showColorPicker;
  final VoidCallback toggleUI;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPanMode = useState(false);
    final isPipetteMode = useState(false);
    final previousTool = useState<PixelTool?>(null);

    return ShortcutsWrapper(
      focusNode: shortcutsFocusNode,
      currentBrushSize: brushSize.value,
      maxBrushSize: 10,
      maxLayers: state.layers.length,
      onUndo: state.canUndo ? notifier.undo : () {},
      onRedo: state.canRedo ? notifier.redo : () {},
      onSave: () {
        handleExport(context, notifier, state);
      },
      onExport: () => handleExport(context, notifier, state),
      onImport: () async {
        final result = await showImportDialog(context);
        if (result != null) {
          notifier.importImage(context, background: result);
        }
      },
      onToolChanged: (tool) {
        currentTool.value = tool;
        if (isPanMode.value && tool != PixelTool.drag) {
          isPanMode.value = false;
        } else if (tool == PixelTool.drag) {
          isPanMode.value = true;
        }
      },
      onBrushSizeChanged: (size) {
        brushSize.value = size;
      },
      onZoomIn: () {
        gridScale.value = (gridScale.value * 1.1).clamp(0.5, 5.0);
      },
      onZoomOut: () {
        gridScale.value = (gridScale.value / 1.1).clamp(0.5, 5.0);
      },
      onZoomFit: () => setZoomFit(gridScale, gridOffset),
      onZoom100: () => setZoom100(gridScale, gridOffset),
      onSwapColors: () {},
      onDefaultColors: () {},
      onToggleUI: toggleUI,
      onPanStart: () {
        if (!isPanMode.value) {
          // Store the current tool before switching to pan mode
          previousTool.value = currentTool.value;
          currentTool.value = PixelTool.drag;
          isPanMode.value = true;
        }
      },
      onPanEnd: () {
        if (isPanMode.value) {
          // Restore the previous tool
          currentTool.value = previousTool.value ?? PixelTool.pencil;
          previousTool.value = null;
          isPanMode.value = false;
        }
      },
      onPipetteStart: () {
        if (!isPipetteMode.value && !isPanMode.value) {
          // Store the current tool before switching to pipette mode
          previousTool.value = currentTool.value;
          currentTool.value = PixelTool.eyedropper;
          isPipetteMode.value = true;
        }
      },
      onPipetteEnd: () {
        if (isPipetteMode.value) {
          // Restore the previous tool
          currentTool.value = previousTool.value ?? PixelTool.pencil;
          previousTool.value = null;
          isPipetteMode.value = false;
        }
      },
      onLayerChanged: (layerIndex) {
        if (layerIndex < state.layers.length) {
          notifier.selectLayer(layerIndex);
        }
      },
      onColorPicker: () {
        showColorPicker(context, notifier);
      },
      onNewLayer: () {
        notifier.addLayer('Layer ${state.layers.length + 1}');
      },
      onDeleteLayer: () {
        if (state.layers.length > 1) {
          notifier.removeLayer(state.currentLayerIndex);
        }
      },
      onSelectAll: () {},
      onDeselectAll: () {
        notifier.setSelection(null);
      },
      onCopy: () {
        // TODO: Implement copy functionality
      },
      onPaste: () {
        // TODO: Implement paste functionality
      },
      onCut: () {
        // TODO: Implement cut functionality
      },
      onDuplicate: () {
        // Duplicate current layer
        final currentLayer = state.layers[state.currentLayerIndex];
        notifier.addLayer('${currentLayer.name} Copy');
        // TODO: Copy pixels from current layer to new layer
      },
      onCtrlEnter: () {
        if (currentTool.value == PixelTool.pen) {
          notifier.pushEvent(const ClosePenPathEvent());
        }
      },
      child: child,
    );
  }
}
