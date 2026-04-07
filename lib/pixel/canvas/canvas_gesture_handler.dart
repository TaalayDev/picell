import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../pixel/tools.dart';
import '../pixel_point.dart';
import 'canvas_controller.dart';
import 'pixel_viewport_controller.dart';
import 'tool_drawing_manager.dart';

/// Input mode for touch/stylus handling
enum GestureInputMode {
  /// Both touch and stylus can draw
  standard,

  /// Only stylus can draw, touch is for navigation only
  stylusOnly,
}

class CanvasGestureHandler {
  final PixelCanvasController controller;
  final ToolDrawingManager toolManager;
  PixelViewportController viewportController;

  final VoidCallback onStartDrawing;
  final VoidCallback onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(Offset)? onStartPixelDrag;
  final Function(Offset)? onPixelDrag;
  final Function(Offset)? onPixelDragEnd;
  final VoidCallback? onUndo;

  /// Current input mode - determines how touch vs stylus is handled
  GestureInputMode inputMode = GestureInputMode.standard;

  /// Whether two-finger tap undo is enabled
  bool twoFingerUndoEnabled = true;

  /// Whether raw two-pointer navigation should be handled inside the canvas.
  /// When false, parent viewport runtime owns pinch/pan.
  bool enableMultiTouchViewportNavigation = true;

  int _pointerCount = 0;
  Offset? _panStartPosition;
  Offset? _twoFingerStartFocalPoint;
  int? _twoFingerStartTimeMs;
  double? _initialTwoFingerScale;
  bool _isTwoFingerPotentiallyUndo = false;
  Offset _normalizedOffset = Offset.zero;
  // Stored once when two fingers land; used for scale ratio in the raw-pointer path.
  double _initialTwoPointerDistance = 0.0;

  bool _isDrawingActive = false;

  final Map<int, PointerEvent> _activePointers = {};
  bool _isRawPointerDrawing = false;

  /// Separate flag for selection tools — they don't trigger onStartDrawing/onFinishDrawing.
  bool _isSelectionDrawingActive = false;

  bool get hasActivePointers => _activePointers.isNotEmpty;
  int get activePointerCount => _activePointers.length;

  bool _canDrawWithPointer(PointerDeviceKind kind) {
    if (inputMode == GestureInputMode.standard) return true;
    return kind == PointerDeviceKind.stylus || kind == PointerDeviceKind.invertedStylus;
  }

  bool _shouldUseForNavigation(PointerDeviceKind kind) {
    if (inputMode == GestureInputMode.standard) return false;
    return kind == PointerDeviceKind.touch;
  }

  /// Returns true for all selection tools (rect, ellipse, lasso, magic wand).
  bool _isSelectionTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso ||
        tool == PixelTool.smartSelect;
  }

  CanvasGestureHandler({
    required this.controller,
    required this.toolManager,
    required this.viewportController,
    required this.onStartDrawing,
    required this.onFinishDrawing,
    required this.onDrawShape,
    this.onStartPixelDrag,
    this.onPixelDrag,
    this.onPixelDragEnd,
    this.onUndo,
  });

  void handleScaleStart(ScaleStartDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    _pointerCount = details.pointerCount;

    if (_pointerCount == 1) {
      _handleSingleFingerStart(details, currentTool, drawDetails);
    } else if (_pointerCount == 2) {
      _handleTwoFingerStart(details);
    }
  }

  void handleScaleUpdate(ScaleUpdateDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    _pointerCount = details.pointerCount;

    if (_pointerCount == 1) {
      _handleSingleFingerUpdate(details, currentTool, drawDetails);
    } else if (_pointerCount == 2) {
      _handleTwoFingerUpdate(details);
    }
  }

  void handleScaleEnd(ScaleEndDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    final wasUndoAttempt = _isTwoFingerPotentiallyUndo;
    final startTimeForUndo = _twoFingerStartTimeMs;
    final currentPointerCountAtEnd = _pointerCount;

    _resetTwoFingerState();

    if (wasUndoAttempt && startTimeForUndo != null && currentPointerCountAtEnd == 2) {
      if (_handleUndoGesture(startTimeForUndo)) {
        _pointerCount = 0;
        _isDrawingActive = false;
        return;
      }
    }

    if (_pointerCount == 1) {
      _handleSingleFingerEnd(currentTool, drawDetails);
    }

    _pointerCount = 0;
  }

  void handleTapDown(TapDownDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (_shouldHandleDirectTap(currentTool)) {
      onStartDrawing();
      toolManager.handleTap(currentTool, drawDetails);
      if (_shouldFinishImmediately(currentTool)) {
        _finishDrawing();
      }
    } else if (currentTool == PixelTool.pen) {
      toolManager.handlePenTap(drawDetails, controller);
    } else if (currentTool == PixelTool.curve) {
      toolManager.handleCurveTap(drawDetails, controller);
      if (!toolManager.isCurveActive) {
        _finishDrawing();
      }
    } else if (_isSelectionTool(currentTool)) {
      toolManager.startDrawing(currentTool, drawDetails);
      _isDrawingActive = true;
    } else if (currentTool != PixelTool.drag) {
      _startDrawing(currentTool, drawDetails);
    }
  }

  void handleTapUp(TapUpDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (!_shouldHandleDirectTap(currentTool) && !_isSelectionTool(currentTool)) {
      _finishDrawing();
    } else if (_isSelectionTool(currentTool) && _isDrawingActive) {
      toolManager.endDrawing(currentTool, drawDetails);
      _isDrawingActive = false;
    }
  }

  void handleCurveTap(TapDownDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (currentTool == PixelTool.curve) {
      toolManager.handleCurveTap(drawDetails, controller);
    }
  }

  void handleCurveMove(Offset position, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (currentTool == PixelTool.curve) {
      toolManager.handleCurveMove(drawDetails, controller);
    }
  }

  void _handleSingleFingerStart(ScaleStartDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (currentTool == PixelTool.drag) {
      _panStartPosition = details.localFocalPoint - controller.offset;
      onStartPixelDrag?.call(controller.offset);
    } else if (_isSelectionTool(currentTool) && !_isDrawingActive) {
      toolManager.startDrawing(currentTool, drawDetails);
      _isDrawingActive = true;
    } else if (!_isDrawingActive) {
      onStartDrawing();
      toolManager.startDrawing(currentTool, drawDetails);
      _isDrawingActive = true;
    }
  }

  void _handleSingleFingerUpdate(ScaleUpdateDetails details, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (currentTool == PixelTool.drag) {
      final newOffset = details.localFocalPoint - _panStartPosition!;
      controller.setOffset(newOffset);
      onPixelDrag?.call(newOffset);
    } else if (currentTool == PixelTool.curve) {
      if (toolManager.isCurveDefining) {
        toolManager.handleCurveMove(drawDetails, controller);
      }
    } else if (_isDrawingActive) {
      toolManager.continueDrawing(currentTool, drawDetails);
    }
  }

  void _handleSingleFingerEnd(PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (currentTool == PixelTool.drag) {
      onPixelDragEnd?.call(controller.offset);
    } else if (_isSelectionTool(currentTool) && _isDrawingActive) {
      toolManager.endDrawing(currentTool, drawDetails);
    } else if (_isDrawingActive) {
      toolManager.endDrawing(currentTool, drawDetails);
      _finishDrawing();
    }
    _isDrawingActive = false;
  }

  void _handleTwoFingerStart(ScaleStartDetails details) {
    _twoFingerStartFocalPoint = details.localFocalPoint;
    _twoFingerStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    _initialTwoFingerScale = controller.zoomLevel;
    _isTwoFingerPotentiallyUndo = true;
    _normalizedOffset = (controller.offset - details.localFocalPoint) / controller.zoomLevel;
  }

  void _handleTwoFingerUpdate(ScaleUpdateDetails details) {
    if (_isTwoFingerPotentiallyUndo) {
      final distanceMoved = (details.localFocalPoint - _twoFingerStartFocalPoint!).distance;
      if (distanceMoved > 12.0 || (details.scale - 1.0).abs() > 0.05) {
        _isTwoFingerPotentiallyUndo = false;
      }
    }

    // Don't commit zoom/pan while we're still deciding if this is a tap-to-undo.
    // This prevents a visual canvas jump if undo fires.
    if (_isTwoFingerPotentiallyUndo) return;

    final newScale = (_initialTwoFingerScale! * details.scale).clamp(0.5, 10.0);
    final newOffset = details.localFocalPoint + _normalizedOffset * newScale;

    viewportController.setViewport(newScale, newOffset);
  }

  bool _handleUndoGesture(int startTimeForUndo) {
    if (!twoFingerUndoEnabled) return false;

    final endTimeMs = DateTime.now().millisecondsSinceEpoch;
    final durationMs = endTimeMs - startTimeForUndo;

    if (durationMs < 350) {
      debugPrint("Two-finger tap for UNDO detected. Duration: $durationMs ms");
      onUndo?.call();
      return true;
    }
    return false;
  }

  void _startDrawing(PixelTool currentTool, PixelDrawDetails drawDetails) {
    onStartDrawing();
    toolManager.startDrawing(currentTool, drawDetails);
    _isDrawingActive = true;
  }

  void _finishDrawing() {
    final previewPixels = List<PixelPoint<int>>.from(controller.previewPixels);
    if (previewPixels.isNotEmpty) {
      onDrawShape(previewPixels);
    }
    onFinishDrawing();
    _isDrawingActive = false;
  }

  void finishDrawing() {
    if (_isRawPointerDrawing) {
      _finishRawPointerDrawing();
    } else {
      _finishDrawing();
    }
  }

  void _resetTwoFingerState() {
    _isTwoFingerPotentiallyUndo = false;
    _twoFingerStartFocalPoint = null;
    _twoFingerStartTimeMs = null;
    _initialTwoFingerScale = null;
    _initialTwoPointerDistance = 0.0;
  }

  bool _shouldHandleDirectTap(PixelTool tool) {
    return tool == PixelTool.fill || tool == PixelTool.eyedropper;
  }

  bool _shouldFinishImmediately(PixelTool tool) {
    return tool == PixelTool.fill || tool == PixelTool.eyedropper;
  }

  // ── Raw pointer handling (used by Listener, not GestureDetector) ──

  void handlePointerDown(PointerDownEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    _activePointers[event.pointer] = event;
    final pointerCount = _activePointers.length;

    if (pointerCount == 1) {
      _handleSinglePointerDown(event, currentTool, drawDetails);
    } else if (pointerCount == 2) {
      _handleTwoPointerDown(event, currentTool);
    }
  }

  void handlePointerMove(PointerMoveEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (!_activePointers.containsKey(event.pointer)) return;

    _activePointers[event.pointer] = event;
    final pointerCount = _activePointers.length;

    if (pointerCount == 1) {
      _handleSinglePointerMove(event, currentTool, drawDetails);
    } else if (pointerCount == 2) {
      _handleTwoPointerMove(event, currentTool);
    }
  }

  void handlePointerUp(PointerUpEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    _activePointers.remove(event.pointer);
    final pointerCount = _activePointers.length;

    if (pointerCount == 0) {
      _handleAllPointersUp(event, currentTool, drawDetails);
    } else if (pointerCount == 1) {
      _handleMultiToSinglePointer(currentTool);
    }
  }

  void _handleSinglePointerDown(PointerDownEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    final pointerKind = event.kind;
    final canDraw = _canDrawWithPointer(pointerKind);
    final shouldNavigate = _shouldUseForNavigation(pointerKind);

    if (shouldNavigate || currentTool == PixelTool.drag) {
      _panStartPosition = event.position;
      if (currentTool == PixelTool.drag) {
        onStartPixelDrag?.call(controller.offset);
      }
      return;
    }

    if (!canDraw) return;

    if (_shouldHandleDirectTap(currentTool)) {
      onStartDrawing();
      toolManager.handleTap(currentTool, drawDetails);
      if (_shouldFinishImmediately(currentTool)) {
        _finishDrawing();
      }
    } else if (currentTool == PixelTool.pen) {
      toolManager.handlePenTap(drawDetails, controller, onPathClosed: () => _finishDrawing());
    } else if (_isSelectionTool(currentTool)) {
      // Selection tools: don't save undo state, just start the selection gesture
      toolManager.startDrawing(currentTool, drawDetails);
      _isSelectionDrawingActive = true;
    } else {
      onStartDrawing();
      toolManager.startDrawing(currentTool, drawDetails);
      _isRawPointerDrawing = true;
    }
  }

  void _handleSinglePointerMove(PointerMoveEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    final pointerKind = event.kind;
    final shouldNavigate = _shouldUseForNavigation(pointerKind);

    if (shouldNavigate && _panStartPosition != null) {
      final newOffset = controller.offset + event.delta;
      viewportController.setViewport(controller.zoomLevel, newOffset);
      return;
    }

    if (currentTool == PixelTool.drag && _panStartPosition != null) {
      final newOffset = controller.offset + event.delta;
      controller.setOffset(newOffset);
      onPixelDrag?.call(newOffset);
    } else if (currentTool == PixelTool.curve) {
      if (toolManager.isCurveDefining) {
        toolManager.handleCurveMove(drawDetails, controller);
      }
    } else if (_isSelectionDrawingActive) {
      toolManager.continueDrawing(currentTool, drawDetails);
    } else if (_isRawPointerDrawing) {
      toolManager.continueDrawing(currentTool, drawDetails);
    }
  }

  void _handleTwoPointerDown(PointerDownEvent event, PixelTool currentTool) {
    if (_isRawPointerDrawing) {
      _finishRawPointerDrawing();
    }
    if (_isSelectionDrawingActive) {
      // Cancel ongoing selection if user adds a second finger
      _isSelectionDrawingActive = false;
    }

    if (!enableMultiTouchViewportNavigation) {
      _resetTwoFingerState();
      return;
    }

    final pointers = _activePointers.values.toList();
    if (pointers.length >= 2) {
      final pointer1 = pointers[0];
      final pointer2 = pointers[1];
      final focalPoint = Offset(
        (pointer1.localPosition.dx + pointer2.localPosition.dx) / 2,
        (pointer1.localPosition.dy + pointer2.localPosition.dy) / 2,
      );

      _twoFingerStartFocalPoint = focalPoint;
      _twoFingerStartTimeMs = DateTime.now().millisecondsSinceEpoch;
      _initialTwoFingerScale = controller.zoomLevel;
      _isTwoFingerPotentiallyUndo = true;
      _normalizedOffset = (controller.offset - focalPoint) / controller.zoomLevel;
      // Capture distance once here — _activePointers already has both pointers.
      _initialTwoPointerDistance = _getCurrentTwoPointerDistance();
    }
  }

  void _handleTwoPointerMove(PointerMoveEvent event, PixelTool currentTool) {
    if (!enableMultiTouchViewportNavigation) {
      return;
    }

    final pointers = _activePointers.values.toList();
    if (pointers.length < 2) return;

    final pointer1 = pointers[0];
    final pointer2 = pointers[1];

    final currentFocalPoint = Offset(
      (pointer1.localPosition.dx + pointer2.localPosition.dx) / 2,
      (pointer1.localPosition.dy + pointer2.localPosition.dy) / 2,
    );

    final currentDistance = (pointer1.localPosition - pointer2.localPosition).distance;
    // Use the distance captured when both fingers first touched (not current).
    final initialDistance = _initialTwoPointerDistance;

    if (_isTwoFingerPotentiallyUndo && _twoFingerStartFocalPoint != null) {
      final distanceMoved = (currentFocalPoint - _twoFingerStartFocalPoint!).distance;
      final scaleChange = initialDistance > 0 ? (currentDistance / initialDistance - 1.0).abs() : 0.0;

      if (distanceMoved > 12.0 || scaleChange > 0.05) {
        _isTwoFingerPotentiallyUndo = false;
      }
    }

    // Don't commit zoom/pan while we're still deciding if this is a tap-to-undo.
    if (_isTwoFingerPotentiallyUndo) return;

    if (initialDistance > 0 && _initialTwoFingerScale != null) {
      final scale = currentDistance / initialDistance;
      final newScale = (_initialTwoFingerScale! * scale).clamp(0.5, 10.0);
      final newOffset = currentFocalPoint + _normalizedOffset * newScale;

      viewportController.setViewport(newScale, newOffset);
    }
  }

  void _handleAllPointersUp(PointerUpEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    if (_isTwoFingerPotentiallyUndo && _twoFingerStartTimeMs != null) {
      if (_handleUndoGesture(_twoFingerStartTimeMs!)) {
        _resetPointerState();
        return;
      }
    }

    if (currentTool == PixelTool.drag) {
      onPixelDragEnd?.call(controller.offset);
    } else if (_isSelectionDrawingActive) {
      toolManager.endDrawing(currentTool, drawDetails);
      _isSelectionDrawingActive = false;
    } else if (_isRawPointerDrawing) {
      toolManager.endDrawing(currentTool, drawDetails);
      _finishRawPointerDrawing();
    }

    _resetPointerState();
  }

  void _handleMultiToSinglePointer(PixelTool currentTool) {
    if (!_isTwoFingerPotentiallyUndo) {
      // Gesture was confirmed as zoom/pan — safe to clear two-finger state.
      _resetTwoFingerState();
    }
    // If still potentially undo, preserve state so _handleAllPointersUp can
    // fire the undo when the last finger lifts.
  }

  void _finishRawPointerDrawing() {
    if (_isRawPointerDrawing) {
      final previewPixels = List<PixelPoint<int>>.from(controller.previewPixels);
      if (previewPixels.isNotEmpty) {
        onDrawShape(previewPixels);
      }
      onFinishDrawing();
      _isRawPointerDrawing = false;
    }
  }

  void _resetPointerState() {
    _isRawPointerDrawing = false;
    _isSelectionDrawingActive = false;
    _panStartPosition = null;
    _resetTwoFingerState();
  }

  /// Returns the current distance between the two active pointers (local coords).
  /// Call this once when two fingers first land to capture the initial distance.
  double _getCurrentTwoPointerDistance() {
    if (_activePointers.length < 2) return 0.0;
    final pointers = _activePointers.values.toList();
    return (pointers[0].localPosition - pointers[1].localPosition).distance;
  }

  void handlePointerCancel(PointerCancelEvent event, PixelTool currentTool, PixelDrawDetails drawDetails) {
    _activePointers.remove(event.pointer);

    if (_activePointers.isEmpty) {
      if (_isRawPointerDrawing) {
        controller.clearPreviewPixels();
        onFinishDrawing();
        _isRawPointerDrawing = false;
      }
      _isSelectionDrawingActive = false;
      _resetPointerState();
    }
  }

  void resetCurveTool() {
    toolManager.resetCurveTool();
    controller.clearCurvePoints();
  }
}
