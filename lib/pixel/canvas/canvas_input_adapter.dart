import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/models/selection_region.dart';
import '../../pixel/tools.dart';
import '../pixel_point.dart';
import 'canvas_controller.dart';
import 'canvas_gesture_handler.dart';
import 'canvas_runtime_config.dart';
import 'selection_handle_geometry.dart';
import 'tool_drawing_manager.dart';

class PixelCanvasInputAdapter {
  PixelCanvasInputAdapter({
    required this.controller,
    required this.gestureHandler,
    required this.toolManager,
    required PixelCanvasRuntimeConfig config,
    required Size Function() getCanvasSize,
  })  : _config = config,
        _getCanvasSize = getCanvasSize;

  static const _outsideSelectionDragThreshold = 4.0;

  final PixelCanvasController controller;
  final CanvasGestureHandler gestureHandler;
  final ToolDrawingManager toolManager;

  final Size Function() _getCanvasSize;
  PixelCanvasRuntimeConfig _config;

  SelectionRegion? _rotationOriginalRegion;
  Offset? _rotationCenter;

  SelectionRegion? _pendingInsideSelectionRegion;
  int? _pendingInsideSelectionPointer;
  Offset? _pendingInsideSelectionStart;
  Offset _pendingInsideSelectionAppliedOffset = Offset.zero;
  bool _isDraggingInsideSelection = false;
  PointerDownEvent? _pendingOutsideSelectionDownEvent;
  Offset? _pendingOutsideSelectionStart;
  int? _activeSelectionHandlePointer;
  CanvasSelectionHandle? _activeSelectionHandle;
  Offset _selectionHandleStartScreen = Offset.zero;
  Offset _selectionHandleLastAppliedOffset = Offset.zero;
  Rect? _selectionHandleOriginalBounds;
  SelectionRegion? _selectionHandleOriginalRegion;
  Offset? _rotationCenterScreen;
  double _initialRotationAngle = 0.0;

  void updateConfig(PixelCanvasRuntimeConfig value) {
    _config = value;
  }

  void clearLocalSelection({bool notifyProvider = false}) {
    controller.clearSelection();
    toolManager.setCurrentSelection(null);
    _clearRotationState();
    _clearSelectionHandleInteraction();
    _clearPendingInsideSelection();
    _clearPendingOutsideSelection();

    if (notifyProvider) {
      _config.onSelectionChanged?.call(null);
    }
  }

  void handleSelectionEnd(SelectionRegion? region) {
    if (region == null || region.bounds.width < 2 || region.bounds.height < 2) {
      clearLocalSelection(notifyProvider: true);
      return;
    }

    controller.setSelection(region);
    toolManager.setCurrentSelection(region);
    _config.onSelectionChanged?.call(region);
  }

  void finishPenPath() {
    final details = _createDrawDetails(Offset.zero);
    toolManager.closePenPath(controller, details, close: false);
    gestureHandler.finishDrawing();
  }

  void handlePointerDown(PointerDownEvent event) {
    if (_startSelectionHandleInteraction(event)) {
      return;
    }

    if (_config.currentTool == PixelTool.curve) {
      _handleCurveToolInteraction(event.localPosition);
    } else if (_shouldHandleInsideSelectionPointer(event)) {
      _pendingInsideSelectionRegion = controller.currentSelectionRegion;
      _pendingInsideSelectionPointer = event.pointer;
      _pendingInsideSelectionStart = event.localPosition;
      _pendingInsideSelectionAppliedOffset = Offset.zero;
      _isDraggingInsideSelection = false;
    } else if (_shouldHandleOutsideSelectionPointer(event)) {
      _pendingOutsideSelectionDownEvent = event;
      _pendingOutsideSelectionStart = event.localPosition;
    } else {
      gestureHandler.handlePointerDown(
        event,
        _config.currentTool,
        _createDrawDetails(event.localPosition),
      );
    }
  }

  void handlePointerMove(PointerMoveEvent event) {
    if (_isActiveSelectionHandlePointer(event.pointer)) {
      _handleSelectionHandleMove(event);
      return;
    }

    if (_isPendingInsideSelectionPointer(event.pointer)) {
      _handleInsideSelectionMove(event);
      return;
    }

    if (_isPendingOutsideSelectionPointer(event.pointer)) {
      final startPosition = _pendingOutsideSelectionStart;
      if (startPosition == null) return;

      final didStartDrag = (event.localPosition - startPosition).distance >=
          _outsideSelectionDragThreshold;
      if (didStartDrag) {
        _startNewSelectionFromPendingPointer(event);
      }
      return;
    }

    if (_config.currentTool == PixelTool.curve && toolManager.isCurveDefining) {
      final details = _createDrawDetails(event.localPosition);
      toolManager.handleCurveMove(details, controller);
      return;
    }

    gestureHandler.handlePointerMove(
      event,
      _config.currentTool,
      _createDrawDetails(event.localPosition),
    );
  }

  void handlePointerUp(PointerUpEvent event) {
    if (_isActiveSelectionHandlePointer(event.pointer)) {
      _finishSelectionHandleInteraction();
      return;
    }

    if (_config.currentTool == PixelTool.curve) {
      return;
    }

    if (_isPendingInsideSelectionPointer(event.pointer)) {
      if (_isDraggingInsideSelection) {
        _config.onTransformEnd?.call();
        _clearRotationState();
      }
      _clearPendingInsideSelection();
      return;
    }

    if (_isPendingOutsideSelectionPointer(event.pointer)) {
      clearLocalSelection(notifyProvider: true);
      return;
    }

    gestureHandler.handlePointerUp(
      event,
      _config.currentTool,
      _createDrawDetails(event.localPosition),
    );
  }

  void handlePointerCancel(PointerCancelEvent event) {
    if (_isActiveSelectionHandlePointer(event.pointer)) {
      _finishSelectionHandleInteraction();
      return;
    }

    if (_isPendingInsideSelectionPointer(event.pointer)) {
      if (_isDraggingInsideSelection) {
        _config.onTransformEnd?.call();
      }
      _clearPendingInsideSelection();
      return;
    }

    if (_isPendingOutsideSelectionPointer(event.pointer)) {
      _clearPendingOutsideSelection();
      return;
    }

    gestureHandler.handlePointerCancel(
      event,
      _config.currentTool,
      _createDrawDetails(Offset.zero),
    );
  }

  void handlePointerHover(PointerHoverEvent event) {
    if (_config.width > 128 || _config.height > 128) {
      return;
    }

    if (_config.currentTool == PixelTool.curve && toolManager.isCurveDefining) {
      controller.setHoverPosition(event.localPosition);
      final details = _createDrawDetails(event.localPosition);
      toolManager.handleCurveMove(details, controller);
      return;
    }

    _updateHoverPreview(event.localPosition);
  }

  void handlePointerExit(PointerExitEvent event) {
    controller.setHoverPosition(null);
  }

  bool _isSelectionInteractionTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso ||
        tool == PixelTool.smartSelect;
  }

  bool _isSelectionDragCreateTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso;
  }

  void _clearPendingInsideSelection() {
    _pendingInsideSelectionRegion = null;
    _pendingInsideSelectionPointer = null;
    _pendingInsideSelectionStart = null;
    _pendingInsideSelectionAppliedOffset = Offset.zero;
    _isDraggingInsideSelection = false;
  }

  void _clearPendingOutsideSelection() {
    _pendingOutsideSelectionDownEvent = null;
    _pendingOutsideSelectionStart = null;
  }

  void _clearSelectionHandleInteraction() {
    _activeSelectionHandlePointer = null;
    _activeSelectionHandle = null;
    _selectionHandleStartScreen = Offset.zero;
    _selectionHandleLastAppliedOffset = Offset.zero;
    _selectionHandleOriginalBounds = null;
    _selectionHandleOriginalRegion = null;
    _rotationCenterScreen = null;
    _initialRotationAngle = 0.0;
  }

  void _clearRotationState() {
    _rotationOriginalRegion = null;
    _rotationCenter = null;
  }

  bool _isPendingInsideSelectionPointer(int pointer) {
    return _pendingInsideSelectionPointer == pointer;
  }

  bool _isPendingOutsideSelectionPointer(int pointer) {
    return _pendingOutsideSelectionDownEvent?.pointer == pointer;
  }

  bool _isActiveSelectionHandlePointer(int pointer) {
    return _activeSelectionHandlePointer == pointer;
  }

  Offset _screenToPixel(Offset screenPos, Size canvasSize) {
    return CanvasSelectionHandleGeometry.screenToPixel(
      screenPosition: screenPos,
      canvasSize: canvasSize,
      canvasWidth: _config.width,
      canvasHeight: _config.height,
    );
  }

  Offset _clampPixelOffset(Offset pixelPos) {
    return Offset(
      pixelPos.dx.clamp(0.0, _config.width.toDouble()),
      pixelPos.dy.clamp(0.0, _config.height.toDouble()),
    );
  }

  CanvasSelectionHandle? _hitTestSelectionHandle(Offset localPosition) {
    final canvasSize = _getCanvasSize();
    final selectionRegion = controller.currentSelectionRegion;
    if (canvasSize == Size.zero ||
        selectionRegion == null ||
        selectionRegion.bounds == Rect.zero) {
      return null;
    }

    final isSelectionTool = _isSelectionInteractionTool(_config.currentTool);
    final geometry = CanvasSelectionHandleGeometry.compute(
      selectionRegion: selectionRegion,
      canvasSize: canvasSize,
      canvasWidth: _config.width,
      canvasHeight: _config.height,
      showSelectionMoveHandle: !isSelectionTool,
      showSelectionTransformHandles: isSelectionTool,
      showSelectionAnchorHandle: isSelectionTool,
      selectionAnchorPoint: _config.selectionState?.anchorPoint,
    );
    if (geometry == null) {
      return null;
    }
    return geometry.hitTest(localPosition);
  }

  bool _startSelectionHandleInteraction(PointerDownEvent event) {
    final selectionRegion = controller.currentSelectionRegion;
    final canvasSize = _getCanvasSize();
    final handle = _hitTestSelectionHandle(event.localPosition);
    if (selectionRegion == null || canvasSize == Size.zero || handle == null) {
      return false;
    }

    _activeSelectionHandlePointer = event.pointer;
    _activeSelectionHandle = handle;
    _selectionHandleStartScreen = event.localPosition;
    _selectionHandleLastAppliedOffset = Offset.zero;

    switch (handle) {
      case CanvasSelectionHandle.move:
        _config.onTransformStart?.call(selectionRegion);
        break;
      case CanvasSelectionHandle.rotate:
        _rotationOriginalRegion = selectionRegion;
        _selectionHandleOriginalRegion = selectionRegion;
        _rotationCenter = _config.selectionState?.effectiveAnchor ??
            selectionRegion.bounds.center;
        _rotationCenterScreen = CanvasSelectionHandleGeometry.pixelToScreen(
          pixelPosition: _rotationCenter!,
          canvasSize: canvasSize,
          canvasWidth: _config.width,
          canvasHeight: _config.height,
        );
        final pointerScreen = event.localPosition;
        final dx = pointerScreen.dx - _rotationCenterScreen!.dx;
        final dy = pointerScreen.dy - _rotationCenterScreen!.dy;
        _initialRotationAngle = math.atan2(dy, dx);
        _config.onTransformStart?.call(selectionRegion);
        break;
      case CanvasSelectionHandle.anchor:
        break;
      case CanvasSelectionHandle.topLeft:
      case CanvasSelectionHandle.topCenter:
      case CanvasSelectionHandle.topRight:
      case CanvasSelectionHandle.rightCenter:
      case CanvasSelectionHandle.bottomRight:
      case CanvasSelectionHandle.bottomCenter:
      case CanvasSelectionHandle.bottomLeft:
      case CanvasSelectionHandle.leftCenter:
        _selectionHandleOriginalBounds = selectionRegion.bounds;
        _selectionHandleOriginalRegion = selectionRegion;
        _config.onTransformStart?.call(selectionRegion);
        break;
    }

    return true;
  }

  bool _shouldHandleInsideSelectionPointer(PointerDownEvent event) {
    final selectionRegion = controller.currentSelectionRegion;
    if (selectionRegion == null ||
        !_isSelectionInteractionTool(_config.currentTool)) {
      return false;
    }

    final pixelPosition = _createDrawDetails(event.localPosition).pixelPosition;
    return selectionRegion.contains(pixelPosition.x, pixelPosition.y);
  }

  bool _shouldHandleOutsideSelectionPointer(PointerDownEvent event) {
    final selectionRegion = controller.currentSelectionRegion;
    if (selectionRegion == null ||
        !_isSelectionDragCreateTool(_config.currentTool)) {
      return false;
    }

    final pixelPosition = _createDrawDetails(event.localPosition).pixelPosition;
    return !selectionRegion.contains(pixelPosition.x, pixelPosition.y);
  }

  void _startNewSelectionFromPendingPointer(PointerMoveEvent event) {
    final downEvent = _pendingOutsideSelectionDownEvent;
    final startPosition = _pendingOutsideSelectionStart;
    if (downEvent == null || startPosition == null) return;

    clearLocalSelection();
    gestureHandler.handlePointerDown(
      downEvent,
      _config.currentTool,
      _createDrawDetails(startPosition),
    );
    _clearPendingOutsideSelection();
    gestureHandler.handlePointerMove(
      event,
      _config.currentTool,
      _createDrawDetails(event.localPosition),
    );
  }

  void _handleInsideSelectionMove(PointerMoveEvent event) {
    final startPosition = _pendingInsideSelectionStart;
    final baseRegion = _pendingInsideSelectionRegion;
    final canvasSize = _getCanvasSize();
    if (startPosition == null ||
        baseRegion == null ||
        canvasSize == Size.zero) {
      return;
    }

    final totalScreenDelta = event.localPosition - startPosition;
    if (!_isDraggingInsideSelection &&
        totalScreenDelta.distance < _outsideSelectionDragThreshold) {
      return;
    }

    if (!_isDraggingInsideSelection) {
      _isDraggingInsideSelection = true;
      _config.onTransformStart?.call(baseRegion);
    }

    final pixelWidth = canvasSize.width / _config.width;
    final pixelHeight = canvasSize.height / _config.height;
    if (pixelWidth <= 0 || pixelHeight <= 0) return;

    final totalPixelOffset = Offset(
      totalScreenDelta.dx / pixelWidth,
      totalScreenDelta.dy / pixelHeight,
    );
    final roundedPixelOffset = Offset(
      totalPixelOffset.dx.roundToDouble(),
      totalPixelOffset.dy.roundToDouble(),
    );
    final pixelDelta =
        roundedPixelOffset - _pendingInsideSelectionAppliedOffset;

    if (pixelDelta != Offset.zero) {
      _pendingInsideSelectionAppliedOffset = roundedPixelOffset;
      _config.onMoveSelection?.call(pixelDelta);
    }
  }

  void _handleSelectionHandleMove(PointerMoveEvent event) {
    final handle = _activeSelectionHandle;
    final canvasSize = _getCanvasSize();
    final selectionRegion = controller.currentSelectionRegion;
    if (handle == null || canvasSize == Size.zero || selectionRegion == null) {
      return;
    }

    final pixelWidth = canvasSize.width / _config.width;
    final pixelHeight = canvasSize.height / _config.height;
    if (pixelWidth <= 0 || pixelHeight <= 0) {
      return;
    }

    switch (handle) {
      case CanvasSelectionHandle.move:
        final totalScreenDelta =
            event.localPosition - _selectionHandleStartScreen;
        final totalPixelOffset = Offset(
          totalScreenDelta.dx / pixelWidth,
          totalScreenDelta.dy / pixelHeight,
        );
        final roundedPixelOffset = Offset(
          totalPixelOffset.dx.roundToDouble(),
          totalPixelOffset.dy.roundToDouble(),
        );
        final pixelDelta =
            roundedPixelOffset - _selectionHandleLastAppliedOffset;

        if (pixelDelta != Offset.zero) {
          _selectionHandleLastAppliedOffset = roundedPixelOffset;
          _config.onMoveSelection?.call(pixelDelta);
        }
        break;
      case CanvasSelectionHandle.rotate:
        final rotationCenterScreen = _rotationCenterScreen;
        final baseRegion = _selectionHandleOriginalRegion;
        if (rotationCenterScreen == null ||
            baseRegion == null ||
            _rotationOriginalRegion == null) {
          return;
        }

        final scenePosition = event.localPosition;
        final dx = scenePosition.dx - rotationCenterScreen.dx;
        final dy = scenePosition.dy - rotationCenterScreen.dy;
        final currentAngle = math.atan2(dy, dx);
        final rotationAngle = currentAngle - _initialRotationAngle;

        final anchorPixel = _config.selectionState?.effectiveAnchor ??
            selectionRegion.bounds.center;
        final matrix = Matrix4.translationValues(
          anchorPixel.dx,
          anchorPixel.dy,
          0.0,
        )
          ..rotateZ(rotationAngle)
          ..multiply(
            Matrix4.translationValues(
              -anchorPixel.dx,
              -anchorPixel.dy,
              0.0,
            ),
          );

        final rotatedRegion = baseRegion.transformed(matrix);
        controller.setSelection(rotatedRegion);
        _config.onSelectionRotate?.call(
          rotatedRegion,
          _rotationOriginalRegion!,
          rotationAngle,
          _rotationCenter,
        );
        break;
      case CanvasSelectionHandle.anchor:
        final newPixelPos = _clampPixelOffset(
          _screenToPixel(event.localPosition, canvasSize),
        );
        _config.onAnchorChanged?.call(newPixelPos);
        break;
      case CanvasSelectionHandle.topLeft:
      case CanvasSelectionHandle.topCenter:
      case CanvasSelectionHandle.topRight:
      case CanvasSelectionHandle.rightCenter:
      case CanvasSelectionHandle.bottomRight:
      case CanvasSelectionHandle.bottomCenter:
      case CanvasSelectionHandle.bottomLeft:
      case CanvasSelectionHandle.leftCenter:
        final originalBounds = _selectionHandleOriginalBounds;
        final originalRegion = _selectionHandleOriginalRegion;
        if (originalBounds == null || originalRegion == null) {
          return;
        }

        final screenDelta = event.localPosition - _selectionHandleStartScreen;
        final pixelDeltaX = screenDelta.dx / pixelWidth;
        final pixelDeltaY = screenDelta.dy / pixelHeight;

        double newLeft = originalBounds.left;
        double newTop = originalBounds.top;
        double newRight = originalBounds.right;
        double newBottom = originalBounds.bottom;

        switch (handle) {
          case CanvasSelectionHandle.topLeft:
            newLeft += pixelDeltaX;
            newTop += pixelDeltaY;
            break;
          case CanvasSelectionHandle.topRight:
            newRight += pixelDeltaX;
            newTop += pixelDeltaY;
            break;
          case CanvasSelectionHandle.bottomLeft:
            newLeft += pixelDeltaX;
            newBottom += pixelDeltaY;
            break;
          case CanvasSelectionHandle.bottomRight:
            newRight += pixelDeltaX;
            newBottom += pixelDeltaY;
            break;
          case CanvasSelectionHandle.topCenter:
            newTop += pixelDeltaY;
            break;
          case CanvasSelectionHandle.bottomCenter:
            newBottom += pixelDeltaY;
            break;
          case CanvasSelectionHandle.leftCenter:
            newLeft += pixelDeltaX;
            break;
          case CanvasSelectionHandle.rightCenter:
            newRight += pixelDeltaX;
            break;
          case CanvasSelectionHandle.move:
          case CanvasSelectionHandle.rotate:
          case CanvasSelectionHandle.anchor:
            break;
        }

        if (newRight - newLeft < 1) newRight = newLeft + 1;
        if (newBottom - newTop < 1) newBottom = newTop + 1;

        final newRect = Rect.fromLTRB(
          newLeft.roundToDouble(),
          newTop.roundToDouble(),
          newRight.roundToDouble(),
          newBottom.roundToDouble(),
        );
        final newRegion = SelectionRegion(
          path: Path()..addRect(newRect),
          bounds: newRect,
          shape: SelectionShape.rectangle,
        );
        final scaleX = newRect.width / originalBounds.width;
        final scaleY = newRect.height / originalBounds.height;
        final pivot = originalBounds.center;

        _config.onSelectionResize?.call(
          newRegion,
          originalRegion,
          Rect.fromLTWH(0, 0, scaleX, scaleY),
          Offset(pivot.dx, pivot.dy),
        );
        controller.setSelection(newRegion);
        break;
    }
  }

  void _finishSelectionHandleInteraction() {
    final handle = _activeSelectionHandle;
    if (handle == null) {
      return;
    }

    switch (handle) {
      case CanvasSelectionHandle.move:
      case CanvasSelectionHandle.rotate:
      case CanvasSelectionHandle.topLeft:
      case CanvasSelectionHandle.topCenter:
      case CanvasSelectionHandle.topRight:
      case CanvasSelectionHandle.rightCenter:
      case CanvasSelectionHandle.bottomRight:
      case CanvasSelectionHandle.bottomCenter:
      case CanvasSelectionHandle.bottomLeft:
      case CanvasSelectionHandle.leftCenter:
        _config.onTransformEnd?.call();
        _clearRotationState();
        break;
      case CanvasSelectionHandle.anchor:
        break;
    }

    _clearSelectionHandleInteraction();
  }

  void _handleCurveToolInteraction(Offset position) {
    if (_config.currentTool != PixelTool.curve) return;

    final details = _createDrawDetails(position);

    toolManager.handleCurveTap(details, controller);

    if (!toolManager.isCurveActive) {
      gestureHandler.finishDrawing();
      controller.clearCurvePoints();
    }
  }

  PixelDrawDetails _createDrawDetails(Offset position) {
    return PixelDrawDetails(
      position: position,
      size: _getCanvasSize(),
      width: _config.width,
      height: _config.height,
      currentLayer: _config.currentLayer,
      color: _config.currentColor,
      strokeWidth: _config.brushSize,
      modifier: _config.modifier,
      onPixelsUpdated: (pixels) {
        if (_config.currentTool != PixelTool.select &&
            _config.currentTool != PixelTool.ellipseSelect &&
            _config.currentTool != PixelTool.lasso &&
            _config.currentTool != PixelTool.smartSelect) {
          controller.setPreviewPixels(pixels);
        }
      },
    );
  }

  bool _shouldShowHoverPreview(PixelTool tool) {
    return [
      PixelTool.pencil,
      PixelTool.eraser,
      PixelTool.line,
      PixelTool.rectangle,
      PixelTool.circle,
      PixelTool.sprayPaint,
      PixelTool.curve,
    ].contains(tool);
  }

  void _updateHoverPreview(Offset? position) {
    if (position == null || !_shouldShowHoverPreview(_config.currentTool)) {
      controller.setHoverPosition(null);
      return;
    }

    final canvasSize = _getCanvasSize();
    List<PixelPoint<int>> previewPixels;

    if (_config.currentTool == PixelTool.sprayPaint) {
      previewPixels = toolManager.generateSprayPixels(
        position,
        _config.brushSize,
        _config.sprayIntensity,
        _config.currentColor.withValues(alpha: 0.5),
        canvasSize,
      );
    } else {
      previewPixels = toolManager.generateBrushStroke(
        position,
        position,
        _config.brushSize,
        _config.currentColor,
        canvasSize,
      );
    }

    controller.setHoverPosition(position, previewPixels: previewPixels);
  }
}
