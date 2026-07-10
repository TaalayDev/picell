import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../pixel/canvas/pixel_viewport_controller.dart';
import '../../pixel/pixel_canvas_state.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/tools.dart';
import '../../ui/widgets/dialogs/import_dialog.dart';
import 'shortcuts_wrapper.dart';

class PixelCanvasShortcutsWrapper extends HookConsumerWidget {
  const PixelCanvasShortcutsWrapper({
    super.key,
    required this.shortcutsFocusNode,
    required this.currentTool,
    required this.brushSize,
    required this.viewportController,
    required this.state,
    required this.notifier,
    required this.handleExport,
    required this.setZoomFit,
    required this.setZoom100,
    required this.showImportDialog,
    required this.showColorPicker,
    required this.toggleUI,
    required this.onCopySelection,
    required this.onCutSelection,
    required this.onPasteSelection,
    required this.child,
  });

  final FocusNode shortcutsFocusNode;
  final ValueNotifier<PixelTool> currentTool;
  final ValueNotifier<int> brushSize;
  final PixelViewportController viewportController;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final Function(BuildContext context, PixelCanvasNotifier notifier, PixelCanvasState state) handleExport;
  final Function(PixelViewportController controller) setZoomFit;
  final Function(PixelViewportController controller) setZoom100;
  final Future<ImportDialogResult?> Function(BuildContext context) showImportDialog;
  final Function(BuildContext context, PixelCanvasNotifier notifier) showColorPicker;
  final VoidCallback toggleUI;
  final VoidCallback onCopySelection;
  final VoidCallback onCutSelection;
  final VoidCallback onPasteSelection;
  final Widget child;

  static bool _isSelectionTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso ||
        tool == PixelTool.smartSelect;
  }

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
        if (!context.mounted || result == null) return;
        notifier.importImage(
          context,
          isBackground: result.isBackground,
          options: result.conversionOptions,
        );
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
        viewportController.zoomIn();
      },
      onZoomOut: () {
        viewportController.zoomOut();
      },
      onZoomFit: () => setZoomFit(viewportController),
      onZoom100: () => setZoom100(viewportController),
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
        // Alt is the subtract-from-selection modifier for selection tools —
        // don't hijack it into the eyedropper temp-switch.
        if (_isSelectionTool(currentTool.value)) return;
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
      onSelectAll: notifier.selectAll,
      onDeselectAll: () {
        if (state.selectionState != null) {
          notifier.clearSelection();
        }
      },
      onInvertSelection: () {
        if (state.selectionState != null) {
          notifier.invertSelection();
        }
      },
      onGrowSelection: () {
        if (state.selectionState != null) {
          notifier.growSelection();
        }
      },
      onShrinkSelection: () {
        if (state.selectionState != null) {
          notifier.shrinkSelection();
        }
      },
      onCopy: onCopySelection,
      onPaste: onPasteSelection,
      onCut: onCutSelection,
      onDuplicate: () {
        if (state.selectionState != null) {
          // Duplicate the selection into a new layer (matches the
          // "Copy to New Layer" menu action).
          notifier.copyToNewLayer();
        } else {
          notifier.duplicateLayer(state.currentLayerIndex);
        }
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
