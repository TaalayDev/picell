import 'package:flutter/material.dart' hide SelectionOverlay;

import '../../core/utils/cursor_manager.dart';
import '../../data/models/selection_region.dart';
import '../../data/models/selection_state.dart';
import '../../pixel/tools/mirror_modifier.dart';
import '../../pixel/tools.dart';
import '../../data.dart';
import '../pixel_canvas_state.dart';
import '../pixel_point.dart';

import '../tools/texture_brush_tool.dart';
import 'canvas_controller.dart';
import 'canvas_gesture_handler.dart';
import 'canvas_painter.dart';
import 'layer_cache_manager.dart';
import 'tool_drawing_manager.dart';
import 'widgets/selection_overlay.dart';

class PixelCanvas extends StatefulWidget {
  final int width;
  final int height;
  final List<Layer> layers;
  final int currentLayerIndex;
  final PixelTool currentTool;
  final Color currentColor;
  final PixelModifier modifier;
  final int brushSize;
  final int sprayIntensity;
  final MirrorAxis mirrorAxis;
  final double zoomLevel;
  final Offset currentOffset;

  final Stream<PixelDrawEvent>? eventStream;

  final GestureInputMode inputMode;
  final bool twoFingerUndoEnabled;

  // Callbacks
  final Function(int x, int y) onTapPixel;
  final Function() onStartDrawing;
  final Function() onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(SelectionRegion?)? onSelectionChanged;
  final Function(Offset)? onMoveSelection;
  final Function(SelectionRegion, SelectionRegion, Rect, Offset?)?
      onSelectionResize;
  final Function(SelectionRegion, SelectionRegion, double, Offset?)?
      onSelectionRotate;
  final Function(SelectionRegion)? onTransformStart;
  final Function()? onTransformEnd;
  final Function(Offset)? onAnchorChanged;
  final SelectionState? selectionState;
  final Function(Color)? onColorPicked;
  final Function(List<Color>)? onGradientApplied;
  final Function(double, Offset)? onStartDrag;
  final Function(double, Offset)? onDrag;
  final Function(double, Offset)? onDragEnd;
  final Function()? onUndo;

  const PixelCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.layers,
    required this.currentLayerIndex,
    required this.onTapPixel,
    required this.currentTool,
    required this.currentColor,
    this.modifier = PixelModifier.none,
    required this.onDrawShape,
    required this.onStartDrawing,
    required this.onFinishDrawing,
    this.onColorPicked,
    this.brushSize = 1,
    this.onSelectionChanged,
    this.onMoveSelection,
    this.onSelectionResize,
    this.onSelectionRotate,
    this.onTransformStart,
    this.onTransformEnd,
    this.onAnchorChanged,
    this.selectionState,
    this.onGradientApplied,
    this.sprayIntensity = 5,
    this.zoomLevel = 1.0,
    this.currentOffset = Offset.zero,
    this.mirrorAxis = MirrorAxis.vertical,
    this.eventStream,
    this.onStartDrag,
    this.onDrag,
    this.onDragEnd,
    this.onUndo,
    this.inputMode = GestureInputMode.standard,
    this.twoFingerUndoEnabled = true,
  });

  @override
  State<PixelCanvas> createState() => _PixelCanvasState();
}

class _PixelCanvasState extends State<PixelCanvas> {
  final _boxKey = GlobalKey();
  static const _outsideSelectionDragThreshold = 4.0;

  late final PixelCanvasController _controller;
  late final CanvasGestureHandler _gestureHandler;
  late final LayerCacheManager _cacheManager;
  late final ToolDrawingManager _toolManager;

  SelectionRegion? _rotationOriginalRegion;
  Offset? _rotationCenter;

  SelectionRegion? _resizeOriginalRegion;
  SelectionRegion? _pendingInsideSelectionRegion;
  int? _pendingInsideSelectionPointer;
  Offset? _pendingInsideSelectionStart;
  Offset _pendingInsideSelectionAppliedOffset = Offset.zero;
  bool _isDraggingInsideSelection = false;
  PointerDownEvent? _pendingOutsideSelectionDownEvent;
  Offset? _pendingOutsideSelectionStart;

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

  void _syncSelectionStateToController() {
    final region = widget.selectionState?.region;
    _controller.setSelection(region);
    _toolManager.setCurrentSelection(region);
  }

  void _clearLocalSelection({bool notifyProvider = false}) {
    _controller.clearSelection();
    _toolManager.setCurrentSelection(null);
    _clearRotationState();
    _resizeOriginalRegion = null;
    _clearPendingInsideSelection();
    _clearPendingOutsideSelection();

    if (notifyProvider) {
      widget.onSelectionChanged?.call(null);
    }
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

  bool _isPendingInsideSelectionPointer(int pointer) {
    return _pendingInsideSelectionPointer == pointer;
  }

  bool _isPendingOutsideSelectionPointer(int pointer) {
    return _pendingOutsideSelectionDownEvent?.pointer == pointer;
  }

  bool _shouldHandleInsideSelectionPointer(PointerDownEvent event) {
    final selectionRegion = _controller.currentSelectionRegion;
    if (selectionRegion == null ||
        !_isSelectionInteractionTool(widget.currentTool)) {
      return false;
    }

    final pixelPosition = _createDrawDetails(event.localPosition).pixelPosition;
    return selectionRegion.contains(pixelPosition.x, pixelPosition.y);
  }

  bool _shouldHandleOutsideSelectionPointer(PointerDownEvent event) {
    final selectionRegion = _controller.currentSelectionRegion;
    if (selectionRegion == null ||
        !_isSelectionDragCreateTool(widget.currentTool)) {
      return false;
    }

    final pixelPosition = _createDrawDetails(event.localPosition).pixelPosition;
    return !selectionRegion.contains(pixelPosition.x, pixelPosition.y);
  }

  void _startNewSelectionFromPendingPointer(PointerMoveEvent event) {
    final downEvent = _pendingOutsideSelectionDownEvent;
    final startPosition = _pendingOutsideSelectionStart;
    if (downEvent == null || startPosition == null) return;

    _clearLocalSelection();
    _gestureHandler.handlePointerDown(
      downEvent,
      widget.currentTool,
      _createDrawDetails(startPosition),
    );
    _clearPendingOutsideSelection();
    _gestureHandler.handlePointerMove(
      event,
      widget.currentTool,
      _createDrawDetails(event.localPosition),
    );
  }

  void _handleInsideSelectionMove(PointerMoveEvent event) {
    final startPosition = _pendingInsideSelectionStart;
    final baseRegion = _pendingInsideSelectionRegion;
    final canvasSize = context.size;
    if (startPosition == null || baseRegion == null || canvasSize == null) {
      return;
    }

    final totalScreenDelta = event.localPosition - startPosition;
    if (!_isDraggingInsideSelection &&
        totalScreenDelta.distance < _outsideSelectionDragThreshold) {
      return;
    }

    if (!_isDraggingInsideSelection) {
      _isDraggingInsideSelection = true;
      widget.onTransformStart?.call(baseRegion);
    }

    final pixelWidth = canvasSize.width / widget.width;
    final pixelHeight = canvasSize.height / widget.height;
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
      widget.onMoveSelection?.call(pixelDelta);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _syncSelectionStateToController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.eventStream?.listen((event) {
        if (event is ClosePenPathEvent) {
          _finishPenPath();
        } else if (event is TextureBrushPatternEvent) {
          _toolManager.setTextureBrush(
            textureId: event.texture.id,
            blendMode: event.blendMode,
            mode: event.isFill ? TextureBrushMode.fill : TextureBrushMode.brush,
            fillMode:
                event.isFill ? TextureFillMode.stretch : TextureFillMode.center,
          );
        } else if (event is ClearSelectionEvent) {
          _clearLocalSelection();
        }
      });
    });
  }

  void _finishPenPath() {
    final details = _createDrawDetails(Offset.zero);

    _toolManager.closePenPath(_controller, details, close: false);
    _gestureHandler.finishDrawing();
  }

  void _initializeComponents() {
    _cacheManager = LayerCacheManager(
      width: widget.width,
      height: widget.height,
    );

    _controller = PixelCanvasController(
      width: widget.width,
      height: widget.height,
      layers: widget.layers,
      currentLayerIndex: widget.currentLayerIndex,
      cacheManager: _cacheManager,
    );

    _toolManager = ToolDrawingManager(
      width: widget.width,
      height: widget.height,
      onColorPicked: widget.onColorPicked,
      // During drag: update controller only (fast local preview, no provider rebuild)
      onSelectionChanged: (region) {
        _controller.setSelection(region);
      },
      // On release: validate and propagate to provider
      onSelectionEnd: (region) {
        if (region == null ||
            region.bounds.width < 2 ||
            region.bounds.height < 2) {
          _clearLocalSelection(notifyProvider: true);
        } else {
          _controller.setSelection(region);
          _toolManager.setCurrentSelection(region);
          widget.onSelectionChanged?.call(region);
        }
      },
      // Lasso free-draw preview: store screen-space points in controller
      onLassoUpdate: (points, isDrawing) {
        _controller.updateLassoPreview(points, isDrawing);
      },
    );

    _gestureHandler = CanvasGestureHandler(
      controller: _controller,
      toolManager: _toolManager,
      onStartDrawing: widget.onStartDrawing,
      onFinishDrawing: () {
        widget.onFinishDrawing();
        _controller.applyLayerCache();
      },
      onDrawShape: (shape) {
        if (widget.currentTool == PixelTool.select ||
            widget.currentTool == PixelTool.ellipseSelect) {
          // Selection tools handle their own callbacks
        } else {
          widget.onDrawShape(shape);
        }
      },
      onStartDrag: widget.onStartDrag,
      onDrag: widget.onDrag,
      onDragEnd: widget.onDragEnd,
      onUndo: widget.onUndo,
    );

    _controller.initialize(widget.layers);

    // Apply initial settings
    _gestureHandler.inputMode = widget.inputMode;
    _gestureHandler.twoFingerUndoEnabled = widget.twoFingerUndoEnabled;
  }

  @override
  void didUpdateWidget(covariant PixelCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.layers != oldWidget.layers) {
      _controller.updateLayers(widget.layers);
    }

    if (widget.currentLayerIndex != oldWidget.currentLayerIndex) {
      _controller.setCurrentLayerIndex(widget.currentLayerIndex);
    }

    if (widget.currentTool != oldWidget.currentTool) {
      _controller.setCurrentTool(widget.currentTool);
    }

    if (widget.zoomLevel != oldWidget.zoomLevel) {
      _controller.setZoomLevel(widget.zoomLevel);
    }

    if (widget.currentOffset != oldWidget.currentOffset) {
      _controller.setOffset(widget.currentOffset);
    }

    // Sync provider's confirmed selection → controller (e.g. select-all, invert, clear)
    if (widget.selectionState != oldWidget.selectionState) {
      _syncSelectionStateToController();
    }

    // Update gesture handler settings
    if (widget.inputMode != oldWidget.inputMode) {
      _gestureHandler.inputMode = widget.inputMode;
    }

    if (widget.twoFingerUndoEnabled != oldWidget.twoFingerUndoEnabled) {
      _gestureHandler.twoFingerUndoEnabled = widget.twoFingerUndoEnabled;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cacheManager.dispose();
    super.dispose();
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
    if (position == null || !_shouldShowHoverPreview(widget.currentTool)) {
      return _controller.setHoverPosition(null);
    }

    List<PixelPoint<int>> previewPixels;

    if (widget.currentTool == PixelTool.sprayPaint) {
      previewPixels = _toolManager.generateSprayPixels(
        position,
        widget.brushSize,
        widget.sprayIntensity,
        widget.currentColor.withOpacity(0.5),
        context.size ?? Size.zero,
      );
    } else {
      previewPixels = _toolManager.generateBrushStroke(
        position,
        position,
        widget.brushSize,
        widget.currentColor,
        context.size ?? Size.zero,
      );
    }
    _controller.setHoverPosition(position, previewPixels: previewPixels);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boxKey,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: (event) {
                  if (widget.currentTool == PixelTool.curve) {
                    return;
                  }

                  if (_isPendingInsideSelectionPointer(event.pointer)) {
                    if (_isDraggingInsideSelection) {
                      widget.onTransformEnd?.call();
                      _resizeOriginalRegion = null;
                      _clearRotationState();
                    }
                    _clearPendingInsideSelection();
                    return;
                  }

                  if (_isPendingOutsideSelectionPointer(event.pointer)) {
                    _clearLocalSelection(notifyProvider: true);
                    return;
                  }

                  _gestureHandler.handlePointerUp(
                    event,
                    widget.currentTool,
                    _createDrawDetails(event.localPosition),
                  );
                },
                child: MouseRegion(
                  cursor: _getCursor(),
                  onHover: (event) {
                    if (widget.width > 128 || widget.height > 128) {
                      return;
                    }

                    _controller.setHoverPosition(event.localPosition);
                    if (widget.currentTool == PixelTool.curve &&
                        _toolManager.isCurveDefining) {
                      final details = _createDrawDetails(event.localPosition);
                      _toolManager.handleCurveMove(details, _controller);
                    } else {
                      _updateHoverPreview(event.localPosition);
                    }
                  },
                  onExit: (event) {
                    _controller.setHoverPosition(null);
                  },
                  child: CustomPaint(
                    painter: PixelCanvasPainter(
                      width: widget.width,
                      height: widget.height,
                      controller: _controller,
                      cacheManager: _cacheManager,
                      currentTool: widget.currentTool,
                      currentColor: widget.currentColor,
                    ),
                    size: Size.infinite,
                  ),
                ),
                onPointerCancel: (event) {
                  if (_isPendingInsideSelectionPointer(event.pointer)) {
                    if (_isDraggingInsideSelection) {
                      widget.onTransformEnd?.call();
                    }
                    _clearPendingInsideSelection();
                    return;
                  }

                  if (_isPendingOutsideSelectionPointer(event.pointer)) {
                    _clearPendingOutsideSelection();
                    return;
                  }

                  _gestureHandler.handlePointerCancel(
                    event,
                    widget.currentTool,
                    _createDrawDetails(Offset.zero),
                  );
                },
              ),
              LayoutBuilder(builder: (context, constraints) {
                // Use controller's region — it reflects both live preview and confirmed state
                final selRegion = _controller.currentSelectionRegion;
                if (selRegion == null || selRegion.bounds == Rect.zero) {
                  return const SizedBox.shrink();
                }
                final isSelectionTool =
                    _isSelectionInteractionTool(widget.currentTool);
                return SelectionOverlay(
                  selectionRegion: selRegion,
                  selectionState: widget.selectionState,
                  allowDirectMove: false,
                  showMoveHandle: !isSelectionTool,
                  showTransformHandles: isSelectionTool,
                  showAnchorHandle: isSelectionTool,
                  anchorHandleInteractive: false,
                  zoomLevel: widget.zoomLevel,
                  canvasOffset: widget.currentOffset,
                  canvasWidth: widget.width,
                  canvasHeight: widget.height,
                  canvasSize: constraints.biggest,
                  onSelectionMoveStart: (region) {
                    widget.onTransformStart?.call(region);
                  },
                  onSelectionMove: (delta) {
                    widget.onMoveSelection?.call(delta);
                  },
                  onSelectionTap: null,
                  onSelectionMoveEnd: () {
                    widget.onTransformEnd?.call();
                    _resizeOriginalRegion = null;
                    _clearRotationState();
                  },
                  onSelectionResizeStart: (region) {
                    _resizeOriginalRegion = region;
                    widget.onTransformStart?.call(region);
                  },
                  onSelectionResize: (newRegion, scaleX, scaleY, pivot) {
                    final oldRegion = _resizeOriginalRegion ?? selRegion;
                    widget.onSelectionResize?.call(
                      newRegion,
                      oldRegion,
                      Rect.fromLTWH(0, 0, scaleX, scaleY),
                      Offset(pivot.x.toDouble(), pivot.y.toDouble()),
                    );
                    _controller.setSelection(newRegion);
                  },
                  onSelectionRotate: (newRegion, angle) {
                    if (_rotationOriginalRegion == null) {
                      _rotationOriginalRegion = selRegion;
                      _rotationCenter =
                          widget.selectionState?.effectiveAnchor ??
                              selRegion.bounds.center;
                      widget.onTransformStart?.call(selRegion);
                    }
                    _controller.setSelection(newRegion);
                    widget.onSelectionRotate?.call(newRegion,
                        _rotationOriginalRegion!, angle, _rotationCenter);
                  },
                  onAnchorChanged: widget.onAnchorChanged,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  PixelDrawDetails _createDrawDetails(Offset position) {
    return PixelDrawDetails(
      position: position,
      size: context.size ?? Size.zero,
      width: widget.width,
      height: widget.height,
      currentLayer: widget.layers[widget.currentLayerIndex],
      color: widget.currentColor,
      strokeWidth: widget.brushSize,
      modifier: _getModifier(),
      onPixelsUpdated: (pixels) {
        // Selection tools handle their own callbacks (onSelectionEnd / onPreview).
        // Drawing tools write to the preview pixel buffer.
        if (widget.currentTool != PixelTool.select &&
            widget.currentTool != PixelTool.ellipseSelect &&
            widget.currentTool != PixelTool.lasso &&
            widget.currentTool != PixelTool.smartSelect) {
          _controller.setPreviewPixels(pixels);
        }
      },
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.currentTool == PixelTool.curve) {
      _handleCurveToolInteraction(event.localPosition);
    } else if (_shouldHandleInsideSelectionPointer(event)) {
      _pendingInsideSelectionRegion = _controller.currentSelectionRegion;
      _pendingInsideSelectionPointer = event.pointer;
      _pendingInsideSelectionStart = event.localPosition;
      _pendingInsideSelectionAppliedOffset = Offset.zero;
      _isDraggingInsideSelection = false;
    } else if (_shouldHandleOutsideSelectionPointer(event)) {
      _pendingOutsideSelectionDownEvent = event;
      _pendingOutsideSelectionStart = event.localPosition;
    } else {
      _gestureHandler.handlePointerDown(
        event,
        widget.currentTool,
        _createDrawDetails(event.localPosition),
      );
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
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

    if (widget.currentTool == PixelTool.curve && _toolManager.isCurveDefining) {
      final details = _createDrawDetails(event.localPosition);
      _toolManager.handleCurveMove(details, _controller);
    } else {
      _gestureHandler.handlePointerMove(
        event,
        widget.currentTool,
        _createDrawDetails(event.localPosition),
      );
    }
  }

  void _handleCurveToolInteraction(Offset position) {
    if (widget.currentTool != PixelTool.curve) return;

    final details = _createDrawDetails(position);

    _toolManager.handleCurveTap(details, _controller);

    if (!_toolManager.isCurveActive) {
      _gestureHandler.finishDrawing();
      _controller.clearCurvePoints();
    }
  }

  Modifier? _getModifier() {
    if (widget.modifier == PixelModifier.mirror) {
      return MirrorModifier(widget.mirrorAxis);
    }
    return null;
  }

  MouseCursor _getCursor() {
    return CursorManager.instance.getCursor(widget.currentTool) ??
        widget.currentTool.cursor;
  }

  void _clearRotationState() {
    _rotationOriginalRegion = null;
    _rotationCenter = null;
  }
}
