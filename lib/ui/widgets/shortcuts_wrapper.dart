import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pixel/services/pixel_transform_service.dart';
import '../../pixel/tools.dart';

class ShortcutsWrapper extends StatefulWidget {
  const ShortcutsWrapper({
    super.key,
    required this.child,
    required this.onUndo,
    required this.onRedo,
    required this.onSave,
    this.onToolChanged,
    this.onBrushSizeChanged,
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomFit,
    this.onZoom100,
    this.onToggleTileMode,
    this.onToggleGrid,
    this.onToggleOnionSkin,
    this.onSwapColors,
    this.onDefaultColors,
    this.onToggleUI,
    this.onPanStart,
    this.onPanEnd,
    this.onPipetteStart,
    this.onPipetteEnd,
    this.onLayerChanged,
    this.onColorPicker,
    this.onNewLayer,
    this.onDelete,
    this.onSelectAdjacentLayer,
    this.onMoveLayers,
    this.onMergeLayers,
    this.onPreviousFrame,
    this.onNextFrame,
    this.onExtendFrameSelection,
    this.onMoveFrames,
    this.onNewFrame,
    this.onExport,
    this.onImport,
    this.onSelectAll,
    this.onDeselectAll,
    this.onInvertSelection,
    this.onGrowSelection,
    this.onShrinkSelection,
    this.onCopy,
    this.onPaste,
    this.onCut,
    this.onDuplicate,
    this.onCtrlEnter,
    this.onCommit,
    this.onReselect,
    this.onCopyMerged,
    this.onPasteInPlace,
    this.onFillSelection,
    this.onOpenTransform,
    this.onCancel,
    this.onNudge,
    this.onTransform,
    this.currentBrushSize = 1,
    this.maxBrushSize = 10,
    this.maxLayers = 10,
    this.focusNode,
    this.enabled = true,
  });

  final Widget child;

  // Basic actions
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSave;

  // Tool actions
  final Function(PixelTool)? onToolChanged;
  final Function(int)? onBrushSizeChanged;

  // View actions
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomFit;
  final VoidCallback? onZoom100;
  final VoidCallback? onToggleTileMode;
  final VoidCallback? onToggleGrid;
  final VoidCallback? onToggleOnionSkin;

  // Color actions
  final VoidCallback? onSwapColors;
  final VoidCallback? onDefaultColors;
  final VoidCallback? onColorPicker;

  // UI actions
  final VoidCallback? onToggleUI;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;
  final VoidCallback? onPipetteStart;
  final VoidCallback? onPipetteEnd;

  // Layer actions
  final Function(int)? onLayerChanged;
  final VoidCallback? onNewLayer;
  final void Function(int delta)? onSelectAdjacentLayer;
  final void Function(int delta)? onMoveLayers;

  /// Ctrl+Shift+E: merges the selected layers, or the active one down.
  final VoidCallback? onMergeLayers;

  /// Delete / Backspace: deletes whatever the user is working on.
  final VoidCallback? onDelete;

  // Frame actions
  final VoidCallback? onPreviousFrame;
  final VoidCallback? onNextFrame;
  final void Function(int delta)? onExtendFrameSelection;
  final void Function(int delta)? onMoveFrames;
  final VoidCallback? onNewFrame;

  // File actions
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  // Selection actions
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onInvertSelection;
  final VoidCallback? onGrowSelection;
  final VoidCallback? onShrinkSelection;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onCut;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCtrlEnter;

  /// Enter. Falls back to [onDeselectAll].
  final VoidCallback? onCommit;

  /// Esc. Falls back to [onDeselectAll].
  final VoidCallback? onCancel;

  /// Ctrl+Shift+D: brings back the last deselected selection.
  final VoidCallback? onReselect;

  /// Ctrl+Shift+C: copies what every visible layer shows in the selection.
  final VoidCallback? onCopyMerged;

  /// Ctrl+Shift+V: pastes at the copied coordinates.
  final VoidCallback? onPasteInPlace;

  /// Alt+Backspace: fills the selection with the current color.
  final VoidCallback? onFillSelection;

  /// Ctrl+T: opens the typed transform panel.
  final VoidCallback? onOpenTransform;

  /// Arrow keys: 1 pixel, 10 with Shift.
  final void Function(Offset delta)? onNudge;

  // Flip / rotate the selection, or the current layer when nothing is selected
  final void Function(PixelTransform transform)? onTransform;

  // State
  final int currentBrushSize;
  final int maxBrushSize;
  final int maxLayers;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  State<ShortcutsWrapper> createState() => _ShortcutsWrapperState();
}

class _ShortcutsWrapperState extends State<ShortcutsWrapper> {
  late FocusNode _focusNode;
  bool _isSpacePressed = false;
  bool _isAltPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    // Auto-focus when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShortcutsWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    _focusNode.canRequestFocus = widget.enabled;
    if (!widget.enabled) _focusNode.unfocus();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  bool get isDesktopOrWeb {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  LogicalKeyboardKey get controlKey {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopOrWeb) {
      return widget.child;
    }

    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      },
      child: Shortcuts(
        shortcuts: _buildShortcuts(),
        child: Actions(
          actions: _buildActions(),
          child: Focus(
            focusNode: _focusNode,
            autofocus: widget.enabled,
            canRequestFocus: widget.enabled,
            skipTraversal: false,
            onKeyEvent: (_, event) {
              _handleKeyEvent(event);
              return KeyEventResult.ignored;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    // Handle spacebar for temporary pan mode
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent && !_isSpacePressed) {
        _isSpacePressed = true;
        widget.onPanStart?.call();
      } else if (event is KeyUpEvent && _isSpacePressed) {
        _isSpacePressed = false;
        widget.onPanEnd?.call();
      }
    }

    // Handle Alt key for temporary pipette/eyedropper mode
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      if (event is KeyDownEvent && !_isAltPressed) {
        _isAltPressed = true;
        widget.onPipetteStart?.call();
      } else if (event is KeyUpEvent && _isAltPressed) {
        _isAltPressed = false;
        widget.onPipetteEnd?.call();
      }
    }
  }

  Map<LogicalKeySet, Intent> _buildShortcuts() {
    return {
      // Basic editing
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyZ): const UndoIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyY): const RedoIntent(),
      LogicalKeySet(
              controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ):
          const RedoIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyS): const SaveIntent(),

      // File operations
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyE): const ExportIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyO): const ImportIntent(),

      // Tools (Aseprite-like)
      LogicalKeySet(LogicalKeyboardKey.keyB):
          const ToolIntent(PixelTool.pencil),
      LogicalKeySet(LogicalKeyboardKey.keyE):
          const ToolIntent(PixelTool.eraser),
      LogicalKeySet(LogicalKeyboardKey.keyI):
          const ToolIntent(PixelTool.eyedropper),
      LogicalKeySet(LogicalKeyboardKey.keyG): const ToolIntent(PixelTool.fill),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyG):
          const ToolIntent(PixelTool.gradient),
      LogicalKeySet(LogicalKeyboardKey.keyM):
          const ToolIntent(PixelTool.select),
      LogicalKeySet(LogicalKeyboardKey.keyL): const ToolIntent(PixelTool.line),
      LogicalKeySet(LogicalKeyboardKey.keyU):
          const ToolIntent(PixelTool.rectangle),
      LogicalKeySet(LogicalKeyboardKey.keyO):
          const ToolIntent(PixelTool.circle),
      LogicalKeySet(LogicalKeyboardKey.keyH): const ToolIntent(PixelTool.drag),
      LogicalKeySet(LogicalKeyboardKey.keyP): const ToolIntent(PixelTool.pen),
      LogicalKeySet(LogicalKeyboardKey.keyS):
          const ToolIntent(PixelTool.sprayPaint),

      // Brush size
      LogicalKeySet(LogicalKeyboardKey.bracketLeft): const BrushSizeIntent(-1),
      LogicalKeySet(LogicalKeyboardKey.bracketRight): const BrushSizeIntent(1),

      // Zoom
      LogicalKeySet(LogicalKeyboardKey.equal): const ZoomInIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.equal): const ZoomInIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.add): const ZoomInIntent(),
      LogicalKeySet(LogicalKeyboardKey.minus): const ZoomOutIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.minus): const ZoomOutIntent(),
      LogicalKeySet(LogicalKeyboardKey.digit0): const ZoomFitIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.digit0):
          const ZoomFitIntent(),
      // Plain 1-9 pick layers.
      LogicalKeySet(controlKey, LogicalKeyboardKey.digit1):
          const Zoom100Intent(),

      // View toggles
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyT):
          const ToggleTileModeIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.quote):
          const ToggleGridIntent(),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyO):
          const ToggleOnionSkinIntent(),

      // Colors
      LogicalKeySet(LogicalKeyboardKey.keyX): const SwapColorsIntent(),
      LogicalKeySet(LogicalKeyboardKey.keyD): const DefaultColorsIntent(),
      LogicalKeySet(LogicalKeyboardKey.keyC): const ColorPickerIntent(),

      // UI
      LogicalKeySet(LogicalKeyboardKey.tab): const ToggleUIIntent(),
      // Note: Space is handled directly in _handleKeyEvent for key up support

      // Layers (1-9)
      LogicalKeySet(LogicalKeyboardKey.digit1): const LayerIntent(0),
      LogicalKeySet(LogicalKeyboardKey.digit2): const LayerIntent(1),
      LogicalKeySet(LogicalKeyboardKey.digit3): const LayerIntent(2),
      LogicalKeySet(LogicalKeyboardKey.digit4): const LayerIntent(3),
      LogicalKeySet(LogicalKeyboardKey.digit5): const LayerIntent(4),
      LogicalKeySet(LogicalKeyboardKey.digit6): const LayerIntent(5),
      LogicalKeySet(LogicalKeyboardKey.digit7): const LayerIntent(6),
      LogicalKeySet(LogicalKeyboardKey.digit8): const LayerIntent(7),
      LogicalKeySet(LogicalKeyboardKey.digit9): const LayerIntent(8),

      // Layer management
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyN):
          const NewLayerIntent(),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.bracketLeft):
          const LayerStepIntent(-1),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.bracketRight):
          const LayerStepIntent(1),
      LogicalKeySet(controlKey, LogicalKeyboardKey.bracketLeft):
          const MoveLayersIntent(-1),
      LogicalKeySet(controlKey, LogicalKeyboardKey.bracketRight):
          const MoveLayersIntent(1),
      LogicalKeySet(
              controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyE):
          const MergeLayersIntent(),

      // Frames
      LogicalKeySet(LogicalKeyboardKey.comma): const FrameStepIntent(-1),
      LogicalKeySet(LogicalKeyboardKey.period): const FrameStepIntent(1),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.comma):
          const ExtendFrameSelectionIntent(-1),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.period):
          const ExtendFrameSelectionIntent(1),
      LogicalKeySet(controlKey, LogicalKeyboardKey.arrowLeft):
          const MoveFramesIntent(-1),
      LogicalKeySet(controlKey, LogicalKeyboardKey.arrowRight):
          const MoveFramesIntent(1),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN):
          const NewFrameIntent(),

      // Deletes the selected pixels, layers or frames
      LogicalKeySet(LogicalKeyboardKey.delete): const DeleteIntent(),
      LogicalKeySet(LogicalKeyboardKey.backspace): const DeleteIntent(),

      // Selection
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyA):
          const SelectAllIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyD):
          const DeselectAllIntent(),
      LogicalKeySet(
              controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD):
          const ReselectIntent(),
      LogicalKeySet(
              controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyC):
          const CopyMergedIntent(),
      LogicalKeySet(
              controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyV):
          const PasteInPlaceIntent(),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.backspace):
          const FillSelectionIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyT):
          const OpenTransformIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter): const CommitIntent(),
      LogicalKeySet(LogicalKeyboardKey.numpadEnter): const CommitIntent(),
      for (final (key, delta) in [
        (LogicalKeyboardKey.arrowLeft, const Offset(-1, 0)),
        (LogicalKeyboardKey.arrowRight, const Offset(1, 0)),
        (LogicalKeyboardKey.arrowUp, const Offset(0, -1)),
        (LogicalKeyboardKey.arrowDown, const Offset(0, 1)),
      ]) ...{
        LogicalKeySet(key): NudgeIntent(delta),
        LogicalKeySet(LogicalKeyboardKey.shift, key): NudgeIntent(delta * 10),
      },
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyC): const CopyIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyV): const PasteIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyX): const CutIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyJ):
          const DuplicateIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI):
          const InvertSelectionIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyG):
          const GrowSelectionIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyH):
          const ShrinkSelectionIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.enter):
          CallbackIntent(widget.onCtrlEnter ?? () {}),

      // Transforms
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyH):
          const TransformIntent(PixelTransform.flipHorizontal),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyV):
          const TransformIntent(PixelTransform.flipVertical),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR):
          const TransformIntent(PixelTransform.rotate90Clockwise),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyL):
          const TransformIntent(PixelTransform.rotate90CounterClockwise),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyX):
          const TransformIntent(PixelTransform.rotate180),
    };
  }

  Map<Type, Action<Intent>> _buildActions() {
    return {
      UndoIntent: CallbackAction<UndoIntent>(
        onInvoke: (intent) => widget.onUndo(),
      ),
      RedoIntent: CallbackAction<RedoIntent>(
        onInvoke: (intent) => widget.onRedo(),
      ),
      SaveIntent: CallbackAction<SaveIntent>(
        onInvoke: (intent) => widget.onSave(),
      ),
      ExportIntent: CallbackAction<ExportIntent>(
        onInvoke: (intent) => widget.onExport?.call(),
      ),
      ImportIntent: CallbackAction<ImportIntent>(
        onInvoke: (intent) => widget.onImport?.call(),
      ),
      ToolIntent: _OutsideTextAction<ToolIntent>(
        onInvoke: (intent) => widget.onToolChanged?.call(intent.tool),
      ),
      BrushSizeIntent: _OutsideTextAction<BrushSizeIntent>(
        onInvoke: (intent) {
          final newSize = (widget.currentBrushSize + intent.delta)
              .clamp(1, widget.maxBrushSize);
          widget.onBrushSizeChanged?.call(newSize);
          return null;
        },
      ),
      ZoomInIntent: _OutsideTextAction<ZoomInIntent>(
        onInvoke: (intent) => widget.onZoomIn?.call(),
      ),
      ZoomOutIntent: _OutsideTextAction<ZoomOutIntent>(
        onInvoke: (intent) => widget.onZoomOut?.call(),
      ),
      ZoomFitIntent: _OutsideTextAction<ZoomFitIntent>(
        onInvoke: (intent) => widget.onZoomFit?.call(),
      ),
      Zoom100Intent: CallbackAction<Zoom100Intent>(
        onInvoke: (intent) => widget.onZoom100?.call(),
      ),
      ToggleTileModeIntent: _OutsideTextAction<ToggleTileModeIntent>(
        onInvoke: (intent) => widget.onToggleTileMode?.call(),
      ),
      ToggleGridIntent: CallbackAction<ToggleGridIntent>(
        onInvoke: (intent) => widget.onToggleGrid?.call(),
      ),
      ToggleOnionSkinIntent: _OutsideTextAction<ToggleOnionSkinIntent>(
        onInvoke: (intent) => widget.onToggleOnionSkin?.call(),
      ),
      SwapColorsIntent: _OutsideTextAction<SwapColorsIntent>(
        onInvoke: (intent) => widget.onSwapColors?.call(),
      ),
      DefaultColorsIntent: _OutsideTextAction<DefaultColorsIntent>(
        onInvoke: (intent) => widget.onDefaultColors?.call(),
      ),
      ColorPickerIntent: _OutsideTextAction<ColorPickerIntent>(
        onInvoke: (intent) => widget.onColorPicker?.call(),
      ),
      ToggleUIIntent: _OutsideTextAction<ToggleUIIntent>(
        onInvoke: (intent) => widget.onToggleUI?.call(),
      ),
      PanStartIntent: CallbackAction<PanStartIntent>(
        onInvoke: (intent) {
          if (!_isSpacePressed) {
            _isSpacePressed = true;
            widget.onPanStart?.call();
          }
          return null;
        },
      ),
      LayerIntent: _OutsideTextAction<LayerIntent>(
        onInvoke: (intent) {
          if (intent.layerIndex < widget.maxLayers) {
            widget.onLayerChanged?.call(intent.layerIndex);
          }
          return null;
        },
      ),
      NewLayerIntent: CallbackAction<NewLayerIntent>(
        onInvoke: (intent) => widget.onNewLayer?.call(),
      ),
      DeleteIntent: _OutsideTextAction<DeleteIntent>(
        onInvoke: (intent) => widget.onDelete?.call(),
      ),
      LayerStepIntent: _OutsideTextAction<LayerStepIntent>(
        onInvoke: (intent) => widget.onSelectAdjacentLayer?.call(intent.delta),
      ),
      MoveLayersIntent: CallbackAction<MoveLayersIntent>(
        onInvoke: (intent) => widget.onMoveLayers?.call(intent.delta),
      ),
      MergeLayersIntent: CallbackAction<MergeLayersIntent>(
        onInvoke: (intent) => widget.onMergeLayers?.call(),
      ),
      FrameStepIntent: _OutsideTextAction<FrameStepIntent>(
        onInvoke: (intent) => intent.delta < 0
            ? widget.onPreviousFrame?.call()
            : widget.onNextFrame?.call(),
      ),
      ExtendFrameSelectionIntent:
          _OutsideTextAction<ExtendFrameSelectionIntent>(
        onInvoke: (intent) => widget.onExtendFrameSelection?.call(intent.delta),
      ),
      MoveFramesIntent: _OutsideTextAction<MoveFramesIntent>(
        onInvoke: (intent) => widget.onMoveFrames?.call(intent.delta),
      ),
      NewFrameIntent: _OutsideTextAction<NewFrameIntent>(
        onInvoke: (intent) => widget.onNewFrame?.call(),
      ),
      SelectAllIntent: _OutsideTextAction<SelectAllIntent>(
        onInvoke: (intent) => widget.onSelectAll?.call(),
      ),
      DeselectAllIntent: _OutsideTextAction<DeselectAllIntent>(
        onInvoke: (intent) => widget.onDeselectAll?.call(),
      ),
      ReselectIntent: _OutsideTextAction<ReselectIntent>(
        onInvoke: (intent) => widget.onReselect?.call(),
      ),
      CopyMergedIntent: _OutsideTextAction<CopyMergedIntent>(
        onInvoke: (intent) => widget.onCopyMerged?.call(),
      ),
      PasteInPlaceIntent: _OutsideTextAction<PasteInPlaceIntent>(
        onInvoke: (intent) => widget.onPasteInPlace?.call(),
      ),
      FillSelectionIntent: _OutsideTextAction<FillSelectionIntent>(
        onInvoke: (intent) => widget.onFillSelection?.call(),
      ),
      OpenTransformIntent: _OutsideTextAction<OpenTransformIntent>(
        onInvoke: (intent) => widget.onOpenTransform?.call(),
      ),
      CommitIntent: _OutsideTextAction<CommitIntent>(
        onInvoke: (intent) => (widget.onCommit ?? widget.onDeselectAll)?.call(),
      ),
      CancelIntent: _OutsideTextAction<CancelIntent>(
        onInvoke: (intent) => (widget.onCancel ?? widget.onDeselectAll)?.call(),
      ),
      NudgeIntent: _OutsideTextAction<NudgeIntent>(
        onInvoke: (intent) => widget.onNudge?.call(intent.delta),
      ),
      CopyIntent: _OutsideTextAction<CopyIntent>(
        onInvoke: (intent) => widget.onCopy?.call(),
      ),
      PasteIntent: _OutsideTextAction<PasteIntent>(
        onInvoke: (intent) => widget.onPaste?.call(),
      ),
      CutIntent: _OutsideTextAction<CutIntent>(
        onInvoke: (intent) => widget.onCut?.call(),
      ),
      DuplicateIntent: CallbackAction<DuplicateIntent>(
        onInvoke: (intent) => widget.onDuplicate?.call(),
      ),
      InvertSelectionIntent: CallbackAction<InvertSelectionIntent>(
        onInvoke: (intent) => widget.onInvertSelection?.call(),
      ),
      GrowSelectionIntent: CallbackAction<GrowSelectionIntent>(
        onInvoke: (intent) => widget.onGrowSelection?.call(),
      ),
      ShrinkSelectionIntent: CallbackAction<ShrinkSelectionIntent>(
        onInvoke: (intent) => widget.onShrinkSelection?.call(),
      ),
      TransformIntent: _OutsideTextAction<TransformIntent>(
        onInvoke: (intent) => widget.onTransform?.call(intent.transform),
      ),
      CallbackIntent: CallbackAction<CallbackIntent>(
          onInvoke: (intent) => intent.callback()),
    };
  }
}

// Intents
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

class ImportIntent extends Intent {
  const ImportIntent();
}

class ToolIntent extends Intent {
  const ToolIntent(this.tool);
  final PixelTool tool;
}

class BrushSizeIntent extends Intent {
  const BrushSizeIntent(this.delta);
  final int delta;
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ZoomFitIntent extends Intent {
  const ZoomFitIntent();
}

class Zoom100Intent extends Intent {
  const Zoom100Intent();
}

class ToggleTileModeIntent extends Intent {
  const ToggleTileModeIntent();
}

class ToggleGridIntent extends Intent {
  const ToggleGridIntent();
}

class ToggleOnionSkinIntent extends Intent {
  const ToggleOnionSkinIntent();
}

class SwapColorsIntent extends Intent {
  const SwapColorsIntent();
}

class DefaultColorsIntent extends Intent {
  const DefaultColorsIntent();
}

class ColorPickerIntent extends Intent {
  const ColorPickerIntent();
}

class ToggleUIIntent extends Intent {
  const ToggleUIIntent();
}

class PanStartIntent extends Intent {
  const PanStartIntent();
}

class LayerIntent extends Intent {
  const LayerIntent(this.layerIndex);
  final int layerIndex;
}

class NewLayerIntent extends Intent {
  const NewLayerIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class LayerStepIntent extends Intent {
  const LayerStepIntent(this.delta);
  final int delta;
}

class MoveLayersIntent extends Intent {
  const MoveLayersIntent(this.delta);
  final int delta;
}

class MergeLayersIntent extends Intent {
  const MergeLayersIntent();
}

class FrameStepIntent extends Intent {
  const FrameStepIntent(this.delta);
  final int delta;
}

class ExtendFrameSelectionIntent extends Intent {
  const ExtendFrameSelectionIntent(this.delta);
  final int delta;
}

class MoveFramesIntent extends Intent {
  const MoveFramesIntent(this.delta);
  final int delta;
}

class NewFrameIntent extends Intent {
  const NewFrameIntent();
}

/// A [CallbackAction] that stands down while a text field has focus, so keys
/// like digits, letters, Backspace and Ctrl+C keep editing the text.
class _OutsideTextAction<T extends Intent> extends CallbackAction<T> {
  _OutsideTextAction({required super.onInvoke});

  @override
  bool isEnabled(T intent) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return true;
    return context.widget is! EditableText &&
        context.findAncestorWidgetOfExactType<EditableText>() == null;
  }
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class DeselectAllIntent extends Intent {
  const DeselectAllIntent();
}

class CopyMergedIntent extends Intent {
  const CopyMergedIntent();
}

class PasteInPlaceIntent extends Intent {
  const PasteInPlaceIntent();
}

class FillSelectionIntent extends Intent {
  const FillSelectionIntent();
}

class OpenTransformIntent extends Intent {
  const OpenTransformIntent();
}

class ReselectIntent extends Intent {
  const ReselectIntent();
}

class CommitIntent extends Intent {
  const CommitIntent();
}

class CancelIntent extends Intent {
  const CancelIntent();
}

class NudgeIntent extends Intent {
  const NudgeIntent(this.delta);
  final Offset delta;
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class CutIntent extends Intent {
  const CutIntent();
}

class DuplicateIntent extends Intent {
  const DuplicateIntent();
}

class InvertSelectionIntent extends Intent {
  const InvertSelectionIntent();
}

class GrowSelectionIntent extends Intent {
  const GrowSelectionIntent();
}

class ShrinkSelectionIntent extends Intent {
  const ShrinkSelectionIntent();
}

class TransformIntent extends Intent {
  const TransformIntent(this.transform);
  final PixelTransform transform;
}

class CallbackIntent extends Intent {
  final VoidCallback callback;

  const CallbackIntent(this.callback);
}
