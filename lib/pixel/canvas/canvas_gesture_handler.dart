import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../pixel/tools.dart';
import '../pixel_point.dart';
import 'canvas_controller.dart';
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

  final VoidCallback onStartDrawing;
  final VoidCallback onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(double, Offset)? onStartDrag;
  final Function(double, Offset)? onDrag;
  final Function(double, Offset)? onDragEnd;
  final VoidCallback? onUndo;

  /// Current input mode - determines how touch vs stylus is handled
  GestureInputMode inputMode = GestureInputMode.standard;

  /// Whether two-finger tap undo is enabled
  bool twoFingerUndoEnabled = true;

  int _pointerCount = 0;
  Offset? _panStartPosition;
  Offset? _twoFingerStartFocalPoint;
  int? _twoFingerStartTimeMs;
  double? _initialTwoFingerScale;
  bool _isTwoFingerPotentiallyUndo = false;
  Offset _normalizedOffset = Offset.zero;

  bool _isDrawingActive = false;

  final Map<int, PointerEvent> _activePointers = {};
  bool _isRawPointerDrawing = false;

  bool get hasActivePointers => _activePointers.isNotEmpty;
  int get activePointerCount => _activePointers.length;

  /// Check if drawing is allowed based on input mode and pointer type
  bool _canDrawWithPointer(PointerDeviceKind kind) {
    if (inputMode == GestureInputMode.standard) {
      return true;
    }
    // In stylus mode, only stylus and inverted stylus can draw
    return kind == PointerDeviceKind.stylus || kind == PointerDeviceKind.invertedStylus;
  }

  /// Check if pointer should be used for navigation (pan/zoom)
  bool _shouldUseForNavigation(PointerDeviceKind kind) {
    if (inputMode == GestureInputMode.standard) {
      return false; // In standard mode, single touch draws
    }
    // In stylus mode, touch is for navigation
    return kind == PointerDeviceKind.touch;
  }

  CanvasGestureHandler({
    required this.controller,
    required this.toolManager,
    required this.onStartDrawing,
    required this.onFinishDrawing,
    required this.onDrawShape,
    this.onStartDrag,
    this.onDrag,
    this.onDragEnd,
    this.onUndo,
  });

  void handleScaleStart(
    ScaleStartDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    _pointerCount = details.pointerCount;

    if (_pointerCount == 1) {
      _handleSingleFingerStart(details, currentTool, drawDetails);
    } else if (_pointerCount == 2) {
      _handleTwoFingerStart(details);
    }
  }

  void handleScaleUpdate(
    ScaleUpdateDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    _pointerCount = details.pointerCount;

    if (_pointerCount == 1) {
      _handleSingleFingerUpdate(details, currentTool, drawDetails);
    } else if (_pointerCount == 2) {
      _handleTwoFingerUpdate(details);
    }
  }

  void handleScaleEnd(
    ScaleEndDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
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

  void handleTapDown(
    TapDownDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
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

      // Check if curve is complete (3 clicks)
      if (!toolManager.isCurveActive) {
        _finishDrawing();
      }
    } else if (currentTool == PixelTool.select) {
      toolManager.handleSelectionStart(drawDetails);
    } else if (currentTool == PixelTool.lasso) {
      // Handle lasso tool - start lasso selection
      toolManager.handleLassoStart(drawDetails);
      _isDrawingActive = true;
      onStartDrawing();
    } else if (currentTool != PixelTool.drag) {
      _startDrawing(currentTool, drawDetails);
    }
  }

  void handleTapUp(
    TapUpDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (!_shouldHandleDirectTap(currentTool) && currentTool != PixelTool.select) {
      _finishDrawing();
    } else if (currentTool == PixelTool.select) {
      toolManager.handleSelectionEnd(drawDetails);
    } else if (currentTool == PixelTool.lasso) {
      // For lasso, we handle ending differently because it might be closed via proximity
      if (!toolManager.isDrawingLasso) {
        _finishDrawing();
        _isDrawingActive = false;
      }
    }
  }

  void handleCurveTap(
    TapDownDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (currentTool == PixelTool.curve) {
      toolManager.handleCurveTap(drawDetails, controller);
    }
  }

  void handleCurveMove(
    Offset position,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (currentTool == PixelTool.curve) {
      toolManager.handleCurveMove(drawDetails, controller);
    }
  }

  void _handleSingleFingerStart(
    ScaleStartDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (currentTool == PixelTool.drag) {
      _panStartPosition = details.focalPoint - controller.offset;
      onStartDrag?.call(controller.zoomLevel, controller.offset);
    } else if (!_isDrawingActive) {
      onStartDrawing();

      toolManager.startDrawing(currentTool, drawDetails);
      _isDrawingActive = true;
    }
  }

  void _handleSingleFingerUpdate(
    ScaleUpdateDetails details,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (currentTool == PixelTool.drag) {
      final newOffset = details.focalPoint - _panStartPosition!;
      controller.setOffset(newOffset);
      onDrag?.call(controller.zoomLevel, newOffset);
    } else if (currentTool == PixelTool.curve) {
      // Handle curve control point movement
      if (toolManager.isCurveDefining) {
        toolManager.handleCurveMove(drawDetails, controller);
      }
    } else if (currentTool == PixelTool.lasso && _isDrawingActive) {
      // Handle lasso drawing
      toolManager.handleLassoMove(drawDetails);
    } else if (_isDrawingActive) {
      toolManager.continueDrawing(currentTool, drawDetails);
    }
  }

  void _handleSingleFingerEnd(
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (currentTool == PixelTool.drag) {
      onDragEnd?.call(controller.zoomLevel, controller.offset);
    } else if (currentTool == PixelTool.lasso && _isDrawingActive) {
      // Handle lasso end
      toolManager.handleLassoEnd(drawDetails);
      _finishDrawing();
    } else if (_isDrawingActive) {
      toolManager.endDrawing(currentTool, drawDetails);
      _finishDrawing();
    }
    _isDrawingActive = false;
  }

  void _handleTwoFingerStart(ScaleStartDetails details) {
    _twoFingerStartFocalPoint = details.focalPoint;
    _twoFingerStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    _initialTwoFingerScale = controller.zoomLevel;
    _isTwoFingerPotentiallyUndo = true;
    _normalizedOffset = (controller.offset - details.focalPoint) / controller.zoomLevel;
  }

  void _handleTwoFingerUpdate(ScaleUpdateDetails details) {
    if (_isTwoFingerPotentiallyUndo) {
      final distanceMoved = (details.focalPoint - _twoFingerStartFocalPoint!).distance;
      if (distanceMoved > 20.0 || (details.scale - 1.0).abs() > 0.05) {
        _isTwoFingerPotentiallyUndo = false;
      }
    }

    final newScale = (_initialTwoFingerScale! * details.scale).clamp(0.5, 10.0);
    final newOffset = details.focalPoint + _normalizedOffset * newScale;

    controller.setZoomLevel(newScale);
    controller.setOffset(newOffset);
    onDrag?.call(newScale, newOffset);
  }

  bool _handleUndoGesture(int startTimeForUndo) {
    // Check if two-finger undo is enabled
    if (!twoFingerUndoEnabled) {
      return false;
    }

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
  }

  bool _shouldHandleDirectTap(PixelTool tool) {
    return tool == PixelTool.fill || tool == PixelTool.eyedropper;
  }

  bool _shouldFinishImmediately(PixelTool tool) {
    return tool == PixelTool.fill || tool == PixelTool.eyedropper;
  }

  void handlePointerDown(
    PointerDownEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    _activePointers[event.pointer] = event;
    final pointerCount = _activePointers.length;

    if (pointerCount == 1) {
      _handleSinglePointerDown(event, currentTool, drawDetails);
    } else if (pointerCount == 2) {
      _handleTwoPointerDown(event, currentTool);
    }
  }

  void handlePointerMove(
    PointerMoveEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (!_activePointers.containsKey(event.pointer)) return;

    _activePointers[event.pointer] = event;
    final pointerCount = _activePointers.length;

    if (pointerCount == 1) {
      _handleSinglePointerMove(event, currentTool, drawDetails);
    } else if (pointerCount == 2) {
      _handleTwoPointerMove(event, currentTool);
    }
  }

  void handlePointerUp(
    PointerUpEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    _activePointers.remove(event.pointer);
    final pointerCount = _activePointers.length;

    if (pointerCount == 0) {
      _handleAllPointersUp(event, currentTool, drawDetails);
    } else if (pointerCount == 1) {
      _handleMultiToSinglePointer(currentTool);
    }
  }

  void _handleSinglePointerDown(
    PointerDownEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    final pointerKind = event.kind;
    final canDraw = _canDrawWithPointer(pointerKind);
    final shouldNavigate = _shouldUseForNavigation(pointerKind);

    // In stylus mode, touch initiates pan/drag instead of drawing
    if (shouldNavigate || currentTool == PixelTool.drag) {
      _panStartPosition = event.position - controller.offset;
      onStartDrag?.call(controller.zoomLevel, controller.offset);
      return;
    }

    // If we can't draw with this pointer type, ignore
    if (!canDraw) {
      return;
    }

    if (_shouldHandleDirectTap(currentTool)) {
      onStartDrawing();
      toolManager.handleSelectionEnd(drawDetails);
      toolManager.handleTap(currentTool, drawDetails);

      if (_shouldFinishImmediately(currentTool)) {
        _finishDrawing();
      }
    } else if (currentTool == PixelTool.pen) {
      toolManager.handlePenTap(
        drawDetails,
        controller,
        onPathClosed: () {
          _finishDrawing();
        },
      );
    } else if (currentTool == PixelTool.select) {
      toolManager.handleSelectionStart(drawDetails);
    } else if (currentTool == PixelTool.lasso) {
      // Handle lasso tool
      onStartDrawing();
      toolManager.handleSelectionEnd(drawDetails);
      toolManager.handleLassoStart(drawDetails);
      _isRawPointerDrawing = true;
    } else {
      onStartDrawing();
      toolManager.handleSelectionEnd(drawDetails);
      toolManager.startDrawing(currentTool, drawDetails);
      _isRawPointerDrawing = true;
    }
  }

  void _handleSinglePointerMove(
    PointerMoveEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    final pointerKind = event.kind;
    final shouldNavigate = _shouldUseForNavigation(pointerKind);

    // Handle navigation (pan) in stylus mode when using touch
    if (shouldNavigate && _panStartPosition != null) {
      final newOffset = event.position - _panStartPosition!;
      controller.setOffset(newOffset);
      onDrag?.call(controller.zoomLevel, newOffset);
      return;
    }

    if (currentTool == PixelTool.drag && _panStartPosition != null) {
      final newOffset = event.position - _panStartPosition!;
      controller.setOffset(newOffset);
      onDrag?.call(controller.zoomLevel, newOffset);
    } else if (currentTool == PixelTool.curve) {
      if (toolManager.isCurveDefining) {
        toolManager.handleCurveMove(drawDetails, controller);
      }
    } else if (currentTool == PixelTool.lasso && _isRawPointerDrawing) {
      // Handle lasso drawing
      toolManager.handleLassoMove(drawDetails);
    } else if (_isRawPointerDrawing) {
      toolManager.continueDrawing(currentTool, drawDetails);
    } else if (currentTool == PixelTool.select) {
      toolManager.handleSelectionUpdate(drawDetails);
    }
  }

  void _handleTwoPointerDown(
    PointerDownEvent event,
    PixelTool currentTool,
  ) {
    if (_isRawPointerDrawing) {
      _finishRawPointerDrawing();
    }

    // Initialize two-finger gesture (zoom/pan or undo)
    final pointers = _activePointers.values.toList();
    if (pointers.length >= 2) {
      final pointer1 = pointers[0];
      final pointer2 = pointers[1];
      final focalPoint = Offset(
        (pointer1.position.dx + pointer2.position.dx) / 2,
        (pointer1.position.dy + pointer2.position.dy) / 2,
      );

      _twoFingerStartFocalPoint = focalPoint;
      _twoFingerStartTimeMs = DateTime.now().millisecondsSinceEpoch;
      _initialTwoFingerScale = controller.zoomLevel;
      _isTwoFingerPotentiallyUndo = true;
      _normalizedOffset = (controller.offset - focalPoint) / controller.zoomLevel;
    }
  }

  void _handleTwoPointerMove(
    PointerMoveEvent event,
    PixelTool currentTool,
  ) {
    final pointers = _activePointers.values.toList();
    if (pointers.length < 2) return;

    final pointer1 = pointers[0];
    final pointer2 = pointers[1];

    final currentFocalPoint = Offset(
      (pointer1.position.dx + pointer2.position.dx) / 2,
      (pointer1.position.dy + pointer2.position.dy) / 2,
    );

    final currentDistance = (pointer1.position - pointer2.position).distance;
    final initialDistance = _getInitialTwoPointerDistance();

    if (_isTwoFingerPotentiallyUndo && _twoFingerStartFocalPoint != null) {
      final distanceMoved = (currentFocalPoint - _twoFingerStartFocalPoint!).distance;
      final scaleChange = initialDistance > 0 ? (currentDistance / initialDistance - 1.0).abs() : 0.0;

      if (distanceMoved > 20.0 || scaleChange > 0.05) {
        _isTwoFingerPotentiallyUndo = false;
      }
    }

    // Apply zoom and pan
    if (initialDistance > 0 && _initialTwoFingerScale != null) {
      final scale = currentDistance / initialDistance;
      final newScale = (_initialTwoFingerScale! * scale).clamp(0.5, 10.0);
      final newOffset = currentFocalPoint + _normalizedOffset * newScale;

      controller.setZoomLevel(newScale);
      controller.setOffset(newOffset);
      onDrag?.call(newScale, newOffset);
    }
  }

  void _handleAllPointersUp(
    PointerUpEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    if (_isTwoFingerPotentiallyUndo && _twoFingerStartTimeMs != null) {
      if (_handleUndoGesture(_twoFingerStartTimeMs!)) {
        _resetPointerState();
        return;
      }
    }

    if (currentTool == PixelTool.drag) {
      onDragEnd?.call(controller.zoomLevel, controller.offset);
    } else if (currentTool == PixelTool.lasso && _isRawPointerDrawing) {
      // Handle lasso completion
      toolManager.handleLassoEnd(drawDetails);
      _finishRawPointerDrawing();
    } else if (_isRawPointerDrawing) {
      toolManager.endDrawing(currentTool, drawDetails);
      _finishRawPointerDrawing();
    } else if (currentTool == PixelTool.select) {
      toolManager.handleSelectionEnd(drawDetails);
    }

    _resetPointerState();
  }

  void _handleMultiToSinglePointer(PixelTool currentTool) {
    _resetTwoFingerState();
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
    _panStartPosition = null;
    _resetTwoFingerState();
  }

  double _getInitialTwoPointerDistance() {
    if (_activePointers.length < 2) return 0.0;

    final pointers = _activePointers.values.toList();
    return (pointers[0].position - pointers[1].position).distance;
  }

  void handlePointerCancel(
    PointerCancelEvent event,
    PixelTool currentTool,
    PixelDrawDetails drawDetails,
  ) {
    _activePointers.remove(event.pointer);

    if (_activePointers.isEmpty) {
      if (_isRawPointerDrawing) {
        controller.clearPreviewPixels();
        onFinishDrawing();
        _isRawPointerDrawing = false;
      }
      _resetPointerState();
    }
  }

  void resetCurveTool() {
    toolManager.resetCurveTool();
    controller.clearCurvePoints();
  }
}
