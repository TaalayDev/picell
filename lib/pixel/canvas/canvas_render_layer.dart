import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../pixel_canvas_state.dart' as canvas_events;
import '../tools.dart';
import 'canvas_controller.dart';
import 'canvas_event_dispatcher.dart';
import 'canvas_gesture_handler.dart';
import 'canvas_input_adapter.dart';
import 'canvas_render_pipeline.dart';
import 'canvas_repaint_binding.dart';
import 'canvas_runtime_config.dart';
import 'canvas_surface_image_resolver.dart';
import 'canvas_surface_paint_delegate.dart';
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
    required this.gridWidth,
    required this.gridHeight,
    required this.imageResolver,
    this.backgroundOpacity = 0.3,
    this.backgroundScale = 1.0,
    this.backgroundOffset = Offset.zero,
    this.eventStream,
  });

  final PixelCanvasController controller;
  final LayerCacheManager cacheManager;
  final CanvasGestureHandler gestureHandler;
  final ToolDrawingManager toolManager;
  final PixelCanvasRuntimeConfig config;
  final int gridWidth;
  final int gridHeight;
  final PixelCanvasSurfaceImageResolver imageResolver;
  final double backgroundOpacity;
  final double backgroundScale;
  final Offset backgroundOffset;
  final Stream<canvas_events.PixelDrawEvent>? eventStream;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPixelCanvasLayer(
      controller: controller,
      cacheManager: cacheManager,
      gestureHandler: gestureHandler,
      toolManager: toolManager,
      config: config,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      imageResolver: imageResolver,
      backgroundOpacity: backgroundOpacity,
      backgroundScale: backgroundScale,
      backgroundOffset: backgroundOffset,
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
      ..gridWidth = gridWidth
      ..gridHeight = gridHeight
      ..imageResolver = imageResolver
      ..backgroundOpacity = backgroundOpacity
      ..backgroundScale = backgroundScale
      ..backgroundOffset = backgroundOffset
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
    required int gridWidth,
    required int gridHeight,
    required PixelCanvasSurfaceImageResolver imageResolver,
    required double backgroundOpacity,
    required double backgroundScale,
    required Offset backgroundOffset,
    Stream<canvas_events.PixelDrawEvent>? eventStream,
  })  : _controller = controller,
        _cacheManager = cacheManager,
        _gestureHandler = gestureHandler,
        _toolManager = toolManager,
        _config = config,
        _gridWidth = gridWidth,
        _gridHeight = gridHeight,
        _imageResolver = imageResolver,
        _backgroundOpacity = backgroundOpacity,
        _backgroundScale = backgroundScale,
        _backgroundOffset = backgroundOffset {
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
    _surfaceDelegate = PixelCanvasSurfacePaintDelegate(
      gridWidth: _gridWidth,
      gridHeight: _gridHeight,
      imageResolver: _imageResolver,
      backgroundOpacity: _backgroundOpacity,
      backgroundScale: _backgroundScale,
      backgroundOffset: _backgroundOffset,
    );
    _repaintBinding = PixelCanvasRepaintBinding(
      controller: _controller,
      cacheManager: _cacheManager,
      selectionAnimation: _config.selectionAnimation,
      onRepaint: _handleRepaint,
    );
    _semanticsSignature = _buildSemanticsSignature();
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
    _markNeedsSemanticsIfChanged();
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
    _markNeedsSemanticsIfChanged();
  }

  int _gridWidth;
  int get gridWidth => _gridWidth;
  set gridWidth(int value) {
    if (_gridWidth == value) return;
    _gridWidth = value;
    _surfaceDelegate.update(gridWidth: value);
    markNeedsPaint();
  }

  int _gridHeight;
  int get gridHeight => _gridHeight;
  set gridHeight(int value) {
    if (_gridHeight == value) return;
    _gridHeight = value;
    _surfaceDelegate.update(gridHeight: value);
    markNeedsPaint();
  }

  PixelCanvasSurfaceImageResolver _imageResolver;
  PixelCanvasSurfaceImageResolver get imageResolver => _imageResolver;
  set imageResolver(PixelCanvasSurfaceImageResolver value) {
    if (identical(_imageResolver, value)) return;
    if (attached) {
      _imageResolver.removeListener(_handleSurfaceImagesChanged);
    }
    _imageResolver = value;
    _surfaceDelegate.update(imageResolver: value);
    if (attached) {
      _imageResolver.addListener(_handleSurfaceImagesChanged);
    }
    markNeedsPaint();
  }

  double _backgroundOpacity;
  double get backgroundOpacity => _backgroundOpacity;
  set backgroundOpacity(double value) {
    if (_backgroundOpacity == value) return;
    _backgroundOpacity = value;
    _surfaceDelegate.update(backgroundOpacity: value);
    markNeedsPaint();
  }

  double _backgroundScale;
  double get backgroundScale => _backgroundScale;
  set backgroundScale(double value) {
    if (_backgroundScale == value) return;
    _backgroundScale = value;
    _surfaceDelegate.update(backgroundScale: value);
    markNeedsPaint();
  }

  Offset _backgroundOffset;
  Offset get backgroundOffset => _backgroundOffset;
  set backgroundOffset(Offset value) {
    if (_backgroundOffset == value) return;
    _backgroundOffset = value;
    _surfaceDelegate.update(backgroundOffset: value);
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
  late final PixelCanvasSurfacePaintDelegate _surfaceDelegate;
  late final PixelCanvasRepaintBinding _repaintBinding;
  String? _semanticsSignature;
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
    _markNeedsSemanticsIfChanged();
  }

  void _handleSurfaceImagesChanged() {
    markNeedsPaint();
  }

  void _markNeedsSemanticsIfChanged() {
    final nextSignature = _buildSemanticsSignature();
    if (nextSignature == _semanticsSignature) {
      return;
    }
    _semanticsSignature = nextSignature;
    markNeedsSemanticsUpdate();
  }

  String _buildSemanticsSignature() {
    final selection = controller.currentSelectionRegion?.bounds;
    return [
      config.width,
      config.height,
      controller.currentLayerIndex,
      controller.layers.length,
      config.currentTool.name,
      controller.zoomLevel.toStringAsFixed(2),
      selection?.left.toStringAsFixed(1),
      selection?.top.toStringAsFixed(1),
      selection?.width.toStringAsFixed(1),
      selection?.height.toStringAsFixed(1),
      config.selectionState?.isTransforming,
    ].join('|');
  }

  String _buildSemanticsValue() {
    final parts = <String>[
      '${config.width} by ${config.height} pixels',
      'tool ${config.currentTool.name}',
      'layer ${controller.currentLayerIndex + 1} of ${controller.layers.length}',
      'zoom ${controller.zoomLevel.toStringAsFixed(2)}x',
    ];

    final selection = controller.currentSelectionRegion?.bounds;
    if (selection != null) {
      final selectionPart =
          'selection ${selection.width.round()} by ${selection.height.round()} pixels';
      if (config.selectionState?.isTransforming ?? false) {
        parts.add('$selectionPart, transforming');
      } else {
        parts.add(selectionPart);
      }
    } else {
      parts.add('no selection');
    }

    return parts.join(', ');
  }

  String _buildSemanticsHint() {
    switch (config.currentTool) {
      case PixelTool.drag:
        return 'Drag to move selected pixels or navigate the canvas.';
      case PixelTool.eyedropper:
        return 'Tap to pick a color from the canvas.';
      case PixelTool.select:
      case PixelTool.smartSelect:
      case PixelTool.ellipseSelect:
      case PixelTool.lasso:
        return 'Use the current tool to create or transform a selection.';
      default:
        return 'Use the current tool to draw on the canvas.';
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _validForMouseTracker = true;
    _imageResolver.addListener(_handleSurfaceImagesChanged);
    _repaintBinding.attach();
    _eventDispatcher.attach();
  }

  @override
  void detach() {
    _validForMouseTracker = false;
    _imageResolver.removeListener(_handleSurfaceImagesChanged);
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
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = 'Pixel canvas'
      ..value = _buildSemanticsValue()
      ..hint = _buildSemanticsHint()
      ..textDirection = TextDirection.ltr;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _surfaceDelegate.paint(context.canvas, offset & size);
    _renderPipeline.paint(context, offset, size);
  }
}
