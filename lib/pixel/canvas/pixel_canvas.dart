import 'dart:math';

import 'package:flutter/material.dart' hide SelectionOverlay;

import '../../core/utils/cursor_manager.dart';
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

  // Callbacks
  final Function(int x, int y) onTapPixel;
  final Function() onStartDrawing;
  final Function() onFinishDrawing;
  final Function(List<PixelPoint<int>>) onDrawShape;
  final Function(List<PixelPoint<int>>?)? onSelectionChanged;
  final Function(List<PixelPoint<int>>, Point)? onMoveSelection;
  final Function(List<PixelPoint<int>>, List<PixelPoint<int>>, Rect, Offset?)? onSelectionResize;
  final Function(List<PixelPoint<int>>, List<PixelPoint<int>>, double, Offset?)? onSelectionRotate;
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
  });

  @override
  State<PixelCanvas> createState() => _PixelCanvasState();
}

class _PixelCanvasState extends State<PixelCanvas> {
  final _boxKey = GlobalKey();

  late final PixelCanvasController _controller;
  late final CanvasGestureHandler _gestureHandler;
  late final LayerCacheManager _cacheManager;
  late final ToolDrawingManager _toolManager;

  List<PixelPoint<int>>? _rotationOriginalSelection;
  Offset? _rotationCenter;

  @override
  void initState() {
    super.initState();
    _initializeComponents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.eventStream?.listen((event) {
        if (event is ClosePenPathEvent) {
          _finishPenPath();
        } else if (event is TextureBrushPatternEvent) {
          _toolManager.setTextureBrush(
            textureId: event.texture.id,
            blendMode: event.blendMode,
            mode: event.isFill ? TextureBrushMode.fill : TextureBrushMode.brush,
            fillMode: event.isFill ? TextureFillMode.stretch : TextureFillMode.center,
          );
        } else if (event is ClearSelectionEvent) {
          _controller.clearSelection();
          widget.onSelectionChanged?.call(null);
          _clearRotationState();
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
      onSelectionEnd: (selection) {
        final length = _controller.selectionPoints.length;
        if (length < 2) {
          _controller.setSelection(null);
          widget.onSelectionChanged?.call(null);
        } else {
          widget.onSelectionChanged?.call(_controller.selectionPoints);
        }
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
        if (widget.currentTool == PixelTool.select) {
          _controller.setSelection(shape);
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
                    if (widget.currentTool == PixelTool.curve && _toolManager.isCurveDefining) {
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
              ),
              LayoutBuilder(builder: (context, constraints) {
                return SelectionOverlay(
                  selection: _controller.selectionPoints,
                  zoomLevel: widget.zoomLevel,
                  canvasOffset: widget.currentOffset,
                  canvasWidth: widget.width,
                  canvasHeight: widget.height,
                  canvasSize: constraints.biggest,
                  onSelectionMove: (selection, delta) {
                    _controller.setSelection(selection);
                    widget.onMoveSelection?.call(selection, delta);
                  },
                  onSelectionMoveEnd: () {
                    widget.onSelectionChanged?.call(_controller.selectionPoints);
                  },
                  onSelectionResizeStart: (original) {},
                  onSelectionResize: (selection, scaleX, scaleY, pivot) {
                    final oldSelection = _controller.selectionPoints;

                    widget.onSelectionResize?.call(
                      selection,
                      oldSelection,
                      Rect.fromLTWH(0, 0, scaleX, scaleY),
                      Offset(pivot.x.toDouble(), pivot.y.toDouble()),
                    );
                    _controller.setSelection(selection);
                  },
                  onSelectionRotate: (rotatedSelection, angle) {
                    _rotationOriginalSelection ??= List<PixelPoint<int>>.from(_controller.selectionPoints);

                    _rotationCenter ??= _centerOf(rotatedSelection);

                    _controller.setSelection(rotatedSelection);

                    // Optional: if you want parents to react during drag (e.g., show angle), you can surface it:
                    widget.onSelectionRotate
                        ?.call(rotatedSelection, _controller.selectionPoints, angle, _rotationCenter);
                  },
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
        if (widget.currentTool == PixelTool.select || widget.currentTool == PixelTool.lasso) {
          _controller.setSelection(pixels);
        } else {
          _controller.setPreviewPixels(pixels);
        }
      },
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.currentTool == PixelTool.curve) {
      _handleCurveToolInteraction(event.localPosition);
    } else {
      _gestureHandler.handlePointerDown(
        event,
        widget.currentTool,
        _createDrawDetails(event.localPosition),
      );
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
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
    return CursorManager.instance.getCursor(widget.currentTool) ?? widget.currentTool.cursor;
  }

  Rect _boundsOf(List<PixelPoint<int>> pts) {
    if (pts.isEmpty) return Rect.zero;
    int minX = pts.first.x, maxX = pts.first.x, minY = pts.first.y, maxY = pts.first.y;
    for (final p in pts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(minX.toDouble(), minY.toDouble(), (maxX + 1).toDouble(), (maxY + 1).toDouble());
  }

  Offset _centerOf(List<PixelPoint<int>> pts) {
    final b = _boundsOf(pts);
    return Offset(b.left + b.width / 2, b.top + b.height / 2);
  }

  void _clearRotationState() {
    _rotationOriginalSelection = null;
    _rotationCenter = null;
  }
}
