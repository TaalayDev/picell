import 'package:flutter/material.dart';

import '../../data.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../pixel_point.dart';
import '../tools.dart';
import 'canvas_controller.dart';
import 'canvas_gesture_handler.dart';
import 'layer_cache_manager.dart';
import 'pixel_viewport_controller.dart';
import 'tool_drawing_manager.dart';

class PixelCanvasHostCallbacks {
  const PixelCanvasHostCallbacks({
    required this.getCurrentTool,
    required this.onStartDrawing,
    required this.onFinishDrawing,
    required this.onDrawShape,
    this.onSelectionChanged,
    this.onColorPicked,
    this.onStartPixelDrag,
    this.onPixelDrag,
    this.onPixelDragEnd,
    this.onUndo,
  });

  final PixelTool Function() getCurrentTool;
  final VoidCallback onStartDrawing;
  final VoidCallback onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(SelectionRegion?)? onSelectionChanged;
  final Function(Color)? onColorPicked;
  final Function(Offset)? onStartPixelDrag;
  final Function(Offset)? onPixelDrag;
  final Function(Offset)? onPixelDragEnd;
  final Function()? onUndo;
}

class PixelCanvasHostRuntime {
  PixelCanvasHostRuntime._({
    required this.controller,
    required this.cacheManager,
    required this.toolManager,
    required this.gestureHandler,
    required List<Layer> layers,
    required int currentLayerIndex,
    required PixelTool currentTool,
    required PixelViewportController viewportController,
    required GestureInputMode inputMode,
    required bool twoFingerUndoEnabled,
    required bool enableMultiTouchViewportNavigation,
    required SelectionState? selectionState,
  }) : _lastLayers = layers,
       _lastCurrentLayerIndex = currentLayerIndex,
       _lastCurrentTool = currentTool,
       _lastInputMode = inputMode,
       _lastTwoFingerUndoEnabled = twoFingerUndoEnabled,
       _lastEnableMultiTouchViewportNavigation = enableMultiTouchViewportNavigation,
       _lastSelectionState = selectionState,
       _viewportController = viewportController;

  factory PixelCanvasHostRuntime.create({
    required int width,
    required int height,
    required List<Layer> layers,
    required int currentLayerIndex,
    required PixelTool currentTool,
    required PixelViewportController viewportController,
    required GestureInputMode inputMode,
    required bool twoFingerUndoEnabled,
    required bool enableMultiTouchViewportNavigation,
    required SelectionState? selectionState,
    required PixelCanvasHostCallbacks callbacks,
  }) {
    final cacheManager = LayerCacheManager(width: width, height: height);

    final controller = PixelCanvasController(
      width: width,
      height: height,
      layers: layers,
      currentLayerIndex: currentLayerIndex,
      cacheManager: cacheManager,
    );

    late final ToolDrawingManager toolManager;
    toolManager = ToolDrawingManager(
      width: width,
      height: height,
      onColorPicked: callbacks.onColorPicked,
      onSelectionChanged: (region) {
        controller.setSelection(region);
      },
      onSelectionEnd: (region) {
        if (region == null || region.bounds.width < 2 || region.bounds.height < 2) {
          controller.clearSelection();
          toolManager.setCurrentSelection(null);
          callbacks.onSelectionChanged?.call(null);
        } else {
          controller.setSelection(region);
          toolManager.setCurrentSelection(region);
          callbacks.onSelectionChanged?.call(region);
        }
      },
      onLassoUpdate: (points, isDrawing) {
        controller.updateLassoPreview(points, isDrawing);
      },
    );

    final gestureHandler = CanvasGestureHandler(
      controller: controller,
      toolManager: toolManager,
      viewportController: viewportController,
      onStartDrawing: callbacks.onStartDrawing,
      onFinishDrawing: () {
        callbacks.onFinishDrawing();
        controller.applyLayerCache();
      },
      onDrawShape: (shape) {
        final currentToolValue = callbacks.getCurrentTool();
        if (currentToolValue == PixelTool.select || currentToolValue == PixelTool.ellipseSelect) {
          return;
        }
        callbacks.onDrawShape(shape);
      },
      onStartPixelDrag: callbacks.onStartPixelDrag,
      onPixelDrag: callbacks.onPixelDrag,
      onPixelDragEnd: callbacks.onPixelDragEnd,
      onUndo: callbacks.onUndo,
    );

    controller.initialize(layers);
    controller.setCurrentTool(currentTool);
    controller.setZoomAndOffset(viewportController.scale, viewportController.offset);
    gestureHandler.inputMode = inputMode;
    gestureHandler.twoFingerUndoEnabled = twoFingerUndoEnabled;
    gestureHandler.enableMultiTouchViewportNavigation = enableMultiTouchViewportNavigation;

    final runtime = PixelCanvasHostRuntime._(
      controller: controller,
      cacheManager: cacheManager,
      toolManager: toolManager,
      gestureHandler: gestureHandler,
      layers: layers,
      currentLayerIndex: currentLayerIndex,
      currentTool: currentTool,
      viewportController: viewportController,
      inputMode: inputMode,
      twoFingerUndoEnabled: twoFingerUndoEnabled,
      enableMultiTouchViewportNavigation: enableMultiTouchViewportNavigation,
      selectionState: selectionState,
    );

    runtime._bindViewportController();
    runtime.syncExternalSelectionState(selectionState);
    return runtime;
  }

  final PixelCanvasController controller;
  final LayerCacheManager cacheManager;
  final ToolDrawingManager toolManager;
  final CanvasGestureHandler gestureHandler;
  PixelViewportController _viewportController;

  List<Layer> _lastLayers;
  int _lastCurrentLayerIndex;
  PixelTool _lastCurrentTool;
  GestureInputMode _lastInputMode;
  bool _lastTwoFingerUndoEnabled;
  bool _lastEnableMultiTouchViewportNavigation;
  SelectionState? _lastSelectionState;

  void update({
    required List<Layer> layers,
    required int currentLayerIndex,
    required PixelTool currentTool,
    required PixelViewportController viewportController,
    required GestureInputMode inputMode,
    required bool twoFingerUndoEnabled,
    required bool enableMultiTouchViewportNavigation,
    required SelectionState? selectionState,
  }) {
    if (layers != _lastLayers) {
      controller.updateLayers(layers);
      _lastLayers = layers;
    }

    if (currentLayerIndex != _lastCurrentLayerIndex) {
      controller.setCurrentLayerIndex(currentLayerIndex);
      _lastCurrentLayerIndex = currentLayerIndex;
    }

    if (currentTool != _lastCurrentTool) {
      controller.setCurrentTool(currentTool);
      _lastCurrentTool = currentTool;
    }

    if (!identical(viewportController, _viewportController)) {
      _unbindViewportController();
      _viewportController = viewportController;
      gestureHandler.viewportController = viewportController;
      _bindViewportController();
      _syncViewportFromController();
    }

    if (selectionState != _lastSelectionState) {
      syncExternalSelectionState(selectionState);
      _lastSelectionState = selectionState;
    }

    if (inputMode != _lastInputMode) {
      gestureHandler.inputMode = inputMode;
      _lastInputMode = inputMode;
    }

    if (twoFingerUndoEnabled != _lastTwoFingerUndoEnabled) {
      gestureHandler.twoFingerUndoEnabled = twoFingerUndoEnabled;
      _lastTwoFingerUndoEnabled = twoFingerUndoEnabled;
    }

    if (enableMultiTouchViewportNavigation != _lastEnableMultiTouchViewportNavigation) {
      gestureHandler.enableMultiTouchViewportNavigation = enableMultiTouchViewportNavigation;
      _lastEnableMultiTouchViewportNavigation = enableMultiTouchViewportNavigation;
    }
  }

  void syncExternalSelectionState(SelectionState? selectionState) {
    final region = selectionState?.region;
    controller.syncSelectionWithoutNotify(region);
    toolManager.setCurrentSelection(region);
  }

  void _syncViewportFromController() {
    controller.setZoomAndOffset(_viewportController.scale, _viewportController.offset);
  }

  void _handleViewportChanged() {
    _syncViewportFromController();
  }

  void _bindViewportController() {
    _viewportController.addListener(_handleViewportChanged);
  }

  void _unbindViewportController() {
    _viewportController.removeListener(_handleViewportChanged);
  }

  void dispose() {
    _unbindViewportController();
    controller.dispose();
    cacheManager.dispose();
  }
}
