import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.onDeleteLayer,
    this.onExport,
    this.onImport,
    this.onSelectAll,
    this.onDeselectAll,
    this.onCopy,
    this.onPaste,
    this.onCut,
    this.onDuplicate,
    this.onCtrlEnter,
    this.currentBrushSize = 1,
    this.maxBrushSize = 10,
    this.maxLayers = 10,
    this.focusNode,
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
  final VoidCallback? onDeleteLayer;

  // File actions
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  // Selection actions
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onCut;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCtrlEnter;

  // State
  final int currentBrushSize;
  final int maxBrushSize;
  final int maxLayers;
  final FocusNode? focusNode;

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
    return defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
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
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Shortcuts(
          shortcuts: _buildShortcuts(),
          child: Actions(
            actions: _buildActions(),
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
      LogicalKeySet(controlKey, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): const RedoIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyS): const SaveIntent(),

      // File operations
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyE): const ExportIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyO): const ImportIntent(),

      // Tools (Aseprite-like)
      LogicalKeySet(LogicalKeyboardKey.keyB): const ToolIntent(PixelTool.pencil),
      LogicalKeySet(LogicalKeyboardKey.keyE): const ToolIntent(PixelTool.eraser),
      LogicalKeySet(LogicalKeyboardKey.keyI): const ToolIntent(PixelTool.eyedropper),
      LogicalKeySet(LogicalKeyboardKey.keyG): const ToolIntent(PixelTool.fill),
      LogicalKeySet(LogicalKeyboardKey.keyM): const ToolIntent(PixelTool.select),
      LogicalKeySet(LogicalKeyboardKey.keyL): const ToolIntent(PixelTool.line),
      LogicalKeySet(LogicalKeyboardKey.keyU): const ToolIntent(PixelTool.rectangle),
      LogicalKeySet(LogicalKeyboardKey.keyO): const ToolIntent(PixelTool.circle),
      LogicalKeySet(LogicalKeyboardKey.keyH): const ToolIntent(PixelTool.drag),
      LogicalKeySet(LogicalKeyboardKey.keyP): const ToolIntent(PixelTool.pen),
      LogicalKeySet(LogicalKeyboardKey.keyS): const ToolIntent(PixelTool.sprayPaint),

      // Brush size
      LogicalKeySet(LogicalKeyboardKey.bracketLeft): const BrushSizeIntent(-1),
      LogicalKeySet(LogicalKeyboardKey.bracketRight): const BrushSizeIntent(1),

      // Zoom
      LogicalKeySet(LogicalKeyboardKey.equal): const ZoomInIntent(),
      LogicalKeySet(LogicalKeyboardKey.minus): const ZoomOutIntent(),
      LogicalKeySet(LogicalKeyboardKey.digit0): const ZoomFitIntent(),
      LogicalKeySet(LogicalKeyboardKey.digit1): const Zoom100Intent(),

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
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyN): const NewLayerIntent(),
      LogicalKeySet(LogicalKeyboardKey.delete): const DeleteLayerIntent(),

      // Selection
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyA): const SelectAllIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyD): const DeselectAllIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyC): const CopyIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyV): const PasteIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyX): const CutIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.keyJ): const DuplicateIntent(),
      LogicalKeySet(controlKey, LogicalKeyboardKey.enter): CallbackIntent(widget.onCtrlEnter ?? () {}),
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
      ToolIntent: CallbackAction<ToolIntent>(
        onInvoke: (intent) => widget.onToolChanged?.call(intent.tool),
      ),
      BrushSizeIntent: CallbackAction<BrushSizeIntent>(
        onInvoke: (intent) {
          final newSize = (widget.currentBrushSize + intent.delta).clamp(1, widget.maxBrushSize);
          widget.onBrushSizeChanged?.call(newSize);
        },
      ),
      ZoomInIntent: CallbackAction<ZoomInIntent>(
        onInvoke: (intent) => widget.onZoomIn?.call(),
      ),
      ZoomOutIntent: CallbackAction<ZoomOutIntent>(
        onInvoke: (intent) => widget.onZoomOut?.call(),
      ),
      ZoomFitIntent: CallbackAction<ZoomFitIntent>(
        onInvoke: (intent) => widget.onZoomFit?.call(),
      ),
      Zoom100Intent: CallbackAction<Zoom100Intent>(
        onInvoke: (intent) => widget.onZoom100?.call(),
      ),
      SwapColorsIntent: CallbackAction<SwapColorsIntent>(
        onInvoke: (intent) => widget.onSwapColors?.call(),
      ),
      DefaultColorsIntent: CallbackAction<DefaultColorsIntent>(
        onInvoke: (intent) => widget.onDefaultColors?.call(),
      ),
      ColorPickerIntent: CallbackAction<ColorPickerIntent>(
        onInvoke: (intent) => widget.onColorPicker?.call(),
      ),
      ToggleUIIntent: CallbackAction<ToggleUIIntent>(
        onInvoke: (intent) => widget.onToggleUI?.call(),
      ),
      PanStartIntent: CallbackAction<PanStartIntent>(
        onInvoke: (intent) {
          if (!_isSpacePressed) {
            _isSpacePressed = true;
            widget.onPanStart?.call();
          }
        },
      ),
      LayerIntent: CallbackAction<LayerIntent>(
        onInvoke: (intent) {
          if (intent.layerIndex < widget.maxLayers) {
            widget.onLayerChanged?.call(intent.layerIndex);
          }
        },
      ),
      NewLayerIntent: CallbackAction<NewLayerIntent>(
        onInvoke: (intent) => widget.onNewLayer?.call(),
      ),
      DeleteLayerIntent: CallbackAction<DeleteLayerIntent>(
        onInvoke: (intent) => widget.onDeleteLayer?.call(),
      ),
      SelectAllIntent: CallbackAction<SelectAllIntent>(
        onInvoke: (intent) => widget.onSelectAll?.call(),
      ),
      DeselectAllIntent: CallbackAction<DeselectAllIntent>(
        onInvoke: (intent) => widget.onDeselectAll?.call(),
      ),
      CopyIntent: CallbackAction<CopyIntent>(
        onInvoke: (intent) => widget.onCopy?.call(),
      ),
      PasteIntent: CallbackAction<PasteIntent>(
        onInvoke: (intent) => widget.onPaste?.call(),
      ),
      CutIntent: CallbackAction<CutIntent>(
        onInvoke: (intent) => widget.onCut?.call(),
      ),
      DuplicateIntent: CallbackAction<DuplicateIntent>(
        onInvoke: (intent) => widget.onDuplicate?.call(),
      ),
      CallbackIntent: CallbackAction<CallbackIntent>(onInvoke: (intent) => intent.callback()),
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

class DeleteLayerIntent extends Intent {
  const DeleteLayerIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class DeselectAllIntent extends Intent {
  const DeselectAllIntent();
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

class CallbackIntent extends Intent {
  final VoidCallback callback;

  const CallbackIntent(this.callback);
}
