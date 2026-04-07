import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../pixel_canvas_state.dart' as canvas_events;
import 'canvas_controller.dart';
import 'canvas_event_dispatcher.dart';
import 'canvas_gesture_handler.dart';
import 'canvas_input_adapter.dart';
import 'canvas_render_pipeline.dart';
import 'canvas_repaint_binding.dart';
import 'canvas_runtime_config.dart';
import 'layer_cache_manager.dart';
import 'tool_drawing_manager.dart';

class PixelCanvasRenderLayer extends LeafRenderObjectWidget {
  const PixelCanvasRenderLayer({
    super.key,
    required this.controller,
    required this.cacheManager,
    required this.gestureHandler,
    required this.toolManager,
    required this.config,
    this.eventStream,
  });

  final PixelCanvasController controller;
  final LayerCacheManager cacheManager;
  final CanvasGestureHandler gestureHandler;
  final ToolDrawingManager toolManager;
  final PixelCanvasRuntimeConfig config;
  final Stream<canvas_events.PixelDrawEvent>? eventStream;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPixelCanvasLayer(
      controller: controller,
      cacheManager: cacheManager,
      gestureHandler: gestureHandler,
      toolManager: toolManager,
      config: config,
      eventStream: eventStream,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderPixelCanvasLayer renderObject,
  ) {
    renderObject
      ..controller = controller
      ..cacheManager = cacheManager
      ..gestureHandler = gestureHandler
      ..toolManager = toolManager
      ..config = config
      ..eventStream = eventStream;
  }
}

class RenderPixelCanvasLayer extends RenderBox
    implements MouseTrackerAnnotation {
  RenderPixelCanvasLayer({
    required PixelCanvasController controller,
    required LayerCacheManager cacheManager,
    required CanvasGestureHandler gestureHandler,
    required ToolDrawingManager toolManager,
    required PixelCanvasRuntimeConfig config,
    Stream<canvas_events.PixelDrawEvent>? eventStream,
  })  : _controller = controller,
        _cacheManager = cacheManager,
        _gestureHandler = gestureHandler,
        _toolManager = toolManager,
        _config = config {
    _inputAdapter = _createInputAdapter();
    _eventDispatcher = PixelCanvasEventDispatcher(
      inputAdapter: _inputAdapter,
      toolManager: _toolManager,
      eventStream: eventStream,
    );
    _renderPipeline = PixelCanvasRenderPipeline(
      controller: _controller,
      cacheManager: _cacheManager,
      config: _config,
    );
    _repaintBinding = PixelCanvasRepaintBinding(
      controller: _controller,
      cacheManager: _cacheManager,
      selectionAnimation: _config.selectionAnimation,
      onRepaint: _handleRepaint,
    );
  }

  PixelCanvasController _controller;
  PixelCanvasController get controller => _controller;
  set controller(PixelCanvasController value) {
    if (identical(_controller, value)) return;
    _controller = value;
    _recreateInputAdapter();
    _renderPipeline.update(controller: value);
    _repaintBinding.update(controller: value);
    markNeedsPaint();
  }

  LayerCacheManager _cacheManager;
  LayerCacheManager get cacheManager => _cacheManager;
  set cacheManager(LayerCacheManager value) {
    if (identical(_cacheManager, value)) return;
    _cacheManager = value;
    _renderPipeline.update(cacheManager: value);
    _repaintBinding.update(cacheManager: value);
    markNeedsPaint();
  }

  CanvasGestureHandler _gestureHandler;
  CanvasGestureHandler get gestureHandler => _gestureHandler;
  set gestureHandler(CanvasGestureHandler value) {
    if (identical(_gestureHandler, value)) return;
    _gestureHandler = value;
    _recreateInputAdapter();
  }

  ToolDrawingManager _toolManager;
  ToolDrawingManager get toolManager => _toolManager;
  set toolManager(ToolDrawingManager value) {
    if (identical(_toolManager, value)) return;
    _toolManager = value;
    _recreateInputAdapter();
    _eventDispatcher.update(toolManager: value, inputAdapter: _inputAdapter);
  }

  PixelCanvasRuntimeConfig _config;
  PixelCanvasRuntimeConfig get config => _config;
  set config(PixelCanvasRuntimeConfig value) {
    if (identical(_config, value)) return;

    final oldConfig = _config;
    final layoutChanged =
        oldConfig.width != value.width || oldConfig.height != value.height;

    _config = value;
    _inputAdapter.updateConfig(value);
    _renderPipeline.update(config: value);
    _repaintBinding.update(selectionAnimation: value.selectionAnimation);

    if (layoutChanged) {
      markNeedsLayout();
    }
    markNeedsPaint();
  }

  Stream<canvas_events.PixelDrawEvent>? get eventStream =>
      _eventDispatcher.eventStream;
  set eventStream(Stream<canvas_events.PixelDrawEvent>? value) {
    _eventDispatcher.eventStream = value;
  }

  late PixelCanvasInputAdapter _inputAdapter;
  late final PixelCanvasEventDispatcher _eventDispatcher;
  late final PixelCanvasRenderPipeline _renderPipeline;
  late final PixelCanvasRepaintBinding _repaintBinding;
  bool _validForMouseTracker = true;

  @override
  bool get validForMouseTracker => _validForMouseTracker;

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => _inputAdapter.handlePointerExit;

  @override
  MouseCursor get cursor => config.cursor;

  PixelCanvasInputAdapter _createInputAdapter() {
    return PixelCanvasInputAdapter(
      controller: controller,
      gestureHandler: gestureHandler,
      toolManager: toolManager,
      config: config,
      getCanvasSize: () => size,
    );
  }

  void _recreateInputAdapter() {
    _inputAdapter = _createInputAdapter();
    _eventDispatcher.update(
      inputAdapter: _inputAdapter,
      toolManager: _toolManager,
    );
  }

  void _handleRepaint() {
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _validForMouseTracker = true;
    _repaintBinding.attach();
    _eventDispatcher.attach();
  }

  @override
  void detach() {
    _validForMouseTracker = false;
    _eventDispatcher.detach();
    _repaintBinding.detach();
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerHoverEvent) {
      _inputAdapter.handlePointerHover(event);
      return;
    }
    if (event is PointerDownEvent) {
      _inputAdapter.handlePointerDown(event);
      return;
    }
    if (event is PointerMoveEvent) {
      _inputAdapter.handlePointerMove(event);
      return;
    }
    if (event is PointerUpEvent) {
      _inputAdapter.handlePointerUp(event);
      return;
    }
    if (event is PointerCancelEvent) {
      _inputAdapter.handlePointerCancel(event);
    }
  }

  @override
  void performLayout() {
    final desiredSize = Size(
      constraints.hasBoundedWidth
          ? constraints.maxWidth
          : config.width.toDouble(),
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : config.height.toDouble(),
    );
    size = constraints.constrain(desiredSize);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final desiredSize = Size(
      constraints.hasBoundedWidth
          ? constraints.maxWidth
          : config.width.toDouble(),
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : config.height.toDouble(),
    );
    return constraints.constrain(desiredSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _renderPipeline.paint(context, offset, size);
  }
}
