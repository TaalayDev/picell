import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/models/selection_region.dart';
import '../../../data/models/selection_state.dart';

const _centerHandleSize = 18.0;
const _handleSize = 12.0;

class SelectionOverlay extends StatefulWidget {
  final SelectionRegion selectionRegion;
  final SelectionState? selectionState;
  final double zoomLevel;
  final Offset canvasOffset;
  final int canvasWidth;
  final int canvasHeight;
  final Size canvasSize;

  final Function(Offset delta)? onSelectionMove;
  final Function(SelectionRegion original)? onSelectionMoveStart;
  final Function(SelectionRegion newRegion, double angle)? onSelectionRotate;
  final Function(SelectionRegion newRegion, double scaleX, double scaleY,
      math.Point<int> pivot)? onSelectionResize;
  final Function(SelectionRegion original)? onSelectionResizeStart;
  final Function()? onSelectionMoveEnd;
  final Function(Offset)? onAnchorChanged;

  const SelectionOverlay({
    super.key,
    required this.selectionRegion,
    this.selectionState,
    required this.zoomLevel,
    required this.canvasOffset,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.canvasSize,
    this.onSelectionMove,
    this.onSelectionMoveStart,
    this.onSelectionRotate,
    this.onSelectionResize,
    this.onSelectionMoveEnd,
    this.onSelectionResizeStart,
    this.onAnchorChanged,
  });

  @override
  State<SelectionOverlay> createState() => _SelectionOverlayState();
}

class _SelectionOverlayState extends State<SelectionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  Offset _lastPanPosition = Offset.zero;

  double _rotationAngle = 0.0;
  double _initialRotationAngle = 0.0;
  bool _isRotating = false;
  Offset? _rotationCenterScreen;

  Offset _resizeStartScreen = Offset.zero;
  Rect? _origBounds;
  SelectionRegion? _resizeOriginalRegion;

  bool _isDraggingAnchor = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _pixelWidth => widget.canvasSize.width / widget.canvasWidth;
  double get _pixelHeight => widget.canvasSize.height / widget.canvasHeight;

  Rect get _selectionScreenRect {
    final bounds = widget.selectionRegion.bounds;
    return Rect.fromLTWH(
      bounds.left * _pixelWidth,
      bounds.top * _pixelHeight,
      bounds.width * _pixelWidth,
      bounds.height * _pixelHeight,
    );
  }

  Offset _pixelToScreen(Offset pixelPos) {
    return Offset(pixelPos.dx * _pixelWidth, pixelPos.dy * _pixelHeight);
  }

  Offset _screenToPixel(Offset screenPos) {
    return Offset(screenPos.dx / _pixelWidth, screenPos.dy / _pixelHeight);
  }

  Offset _globalToOverlay(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return globalPosition;
    }
    return renderObject.globalToLocal(globalPosition);
  }

  Offset _clampPixelOffset(Offset pixelPos) {
    return Offset(
      pixelPos.dx.clamp(0.0, widget.canvasWidth.toDouble()),
      pixelPos.dy.clamp(0.0, widget.canvasHeight.toDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selRect = _selectionScreenRect;
    if (selRect.width <= 0 || selRect.height <= 0) {
      return const SizedBox.shrink();
    }

    final anchorPixel = widget.selectionState?.anchorPoint ??
        widget.selectionRegion.bounds.center;
    final anchorScreen = _pixelToScreen(anchorPixel);

    return Stack(
      children: [
        // Marching ants border
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              size: widget.canvasSize,
              painter: _SelectionPathPainter(
                selectionRegion: widget.selectionRegion,
                pixelWidth: _pixelWidth,
                pixelHeight: _pixelHeight,
                animationValue: _animationController.value,
              ),
            );
          },
        ),

        // Move area (entire selection)
        Positioned(
          left: selRect.left,
          top: selRect.top,
          width: selRect.width,
          height: selRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: _onMoveStart,
            onPanUpdate: _onMoveUpdate,
            onPanEnd: _onMoveEnd,
            child: const SizedBox.expand(),
          ),
        ),

        // Resize handles
        ..._buildResizeHandles(selRect),

        // Rotation handle
        _buildRotationHandle(selRect),

        // Anchor point handle
        _buildAnchorHandle(anchorScreen),
      ],
    );
  }

  // ── Move ──

  void _onMoveStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
    widget.onSelectionMoveStart?.call(widget.selectionRegion);
  }

  void _onMoveUpdate(DragUpdateDetails details) {
    final delta = details.localPosition - _lastPanPosition;
    _lastPanPosition = details.localPosition;

    // Convert screen delta to pixel delta
    final pixelDelta = Offset(
      (delta.dx / _pixelWidth).roundToDouble(),
      (delta.dy / _pixelHeight).roundToDouble(),
    );

    if (pixelDelta != Offset.zero) {
      widget.onSelectionMove?.call(pixelDelta);
    }
  }

  void _onMoveEnd(DragEndDetails details) {
    widget.onSelectionMoveEnd?.call();
  }

  // ── Resize Handles ──

  List<Widget> _buildResizeHandles(Rect selRect) {
    final handles = <Widget>[];
    final handlePositions = {
      _Handle.topLeft: selRect.topLeft,
      _Handle.topRight: selRect.topRight,
      _Handle.bottomLeft: selRect.bottomLeft,
      _Handle.bottomRight: selRect.bottomRight,
      _Handle.topCenter: Offset(selRect.center.dx, selRect.top),
      _Handle.bottomCenter: Offset(selRect.center.dx, selRect.bottom),
      _Handle.leftCenter: Offset(selRect.left, selRect.center.dy),
      _Handle.rightCenter: Offset(selRect.right, selRect.center.dy),
    };

    for (final entry in handlePositions.entries) {
      handles.add(_buildHandle(entry.key, entry.value));
    }

    return handles;
  }

  Widget _buildHandle(_Handle handle, Offset position) {
    return Positioned(
      left: position.dx - _handleSize / 2,
      top: position.dy - _handleSize / 2,
      width: _handleSize,
      height: _handleSize,
      child: GestureDetector(
        onPanStart: (details) => _onResizeStart(handle, details),
        onPanUpdate: (details) => _onResizeUpdate(handle, details),
        onPanEnd: _onResizeEnd,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  void _onResizeStart(_Handle handle, DragStartDetails details) {
    _resizeStartScreen = _globalToOverlay(details.globalPosition);
    _origBounds = widget.selectionRegion.bounds;
    _resizeOriginalRegion = widget.selectionRegion;
    widget.onSelectionResizeStart?.call(widget.selectionRegion);
  }

  void _onResizeUpdate(_Handle handle, DragUpdateDetails details) {
    if (_origBounds == null || _resizeOriginalRegion == null) return;

    final currentScreen = _globalToOverlay(details.globalPosition);
    final screenDelta = currentScreen - _resizeStartScreen;
    final pixelDeltaX = screenDelta.dx / _pixelWidth;
    final pixelDeltaY = screenDelta.dy / _pixelHeight;

    final ob = _origBounds!;
    double newLeft = ob.left;
    double newTop = ob.top;
    double newRight = ob.right;
    double newBottom = ob.bottom;

    switch (handle) {
      case _Handle.topLeft:
        newLeft += pixelDeltaX;
        newTop += pixelDeltaY;
        break;
      case _Handle.topRight:
        newRight += pixelDeltaX;
        newTop += pixelDeltaY;
        break;
      case _Handle.bottomLeft:
        newLeft += pixelDeltaX;
        newBottom += pixelDeltaY;
        break;
      case _Handle.bottomRight:
        newRight += pixelDeltaX;
        newBottom += pixelDeltaY;
        break;
      case _Handle.topCenter:
        newTop += pixelDeltaY;
        break;
      case _Handle.bottomCenter:
        newBottom += pixelDeltaY;
        break;
      case _Handle.leftCenter:
        newLeft += pixelDeltaX;
        break;
      case _Handle.rightCenter:
        newRight += pixelDeltaX;
        break;
    }

    // Ensure minimum size
    if (newRight - newLeft < 1) newRight = newLeft + 1;
    if (newBottom - newTop < 1) newBottom = newTop + 1;

    final newRect = Rect.fromLTRB(
      newLeft.roundToDouble(),
      newTop.roundToDouble(),
      newRight.roundToDouble(),
      newBottom.roundToDouble(),
    );
    final newPath = Path()..addRect(newRect);
    final newRegion = SelectionRegion(
      path: newPath,
      bounds: newRect,
      shape: SelectionShape.rectangle,
    );

    final scaleX = newRect.width / ob.width;
    final scaleY = newRect.height / ob.height;
    final pivot = math.Point<int>(ob.center.dx.round(), ob.center.dy.round());

    widget.onSelectionResize?.call(newRegion, scaleX, scaleY, pivot);
  }

  void _onResizeEnd(DragEndDetails details) {
    _origBounds = null;
    _resizeOriginalRegion = null;
    widget.onSelectionMoveEnd?.call();
  }

  // ── Rotation Handle ──

  Widget _buildRotationHandle(Rect selRect) {
    const rotHandleDistance = 30.0;
    final handlePos =
        Offset(selRect.center.dx, selRect.top - rotHandleDistance);

    return Positioned(
      left: handlePos.dx - _centerHandleSize / 2,
      top: handlePos.dy - _centerHandleSize / 2,
      width: _centerHandleSize,
      height: _centerHandleSize,
      child: GestureDetector(
        onPanStart: _onRotateStart,
        onPanUpdate: _onRotateUpdate,
        onPanEnd: _onRotateEnd,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade300,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.rotate_right, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  void _onRotateStart(DragStartDetails details) {
    _isRotating = true;
    final anchorPixel = widget.selectionState?.effectiveAnchor ??
        widget.selectionRegion.bounds.center;
    _rotationCenterScreen = _pixelToScreen(anchorPixel);
    final pointerScreen = _globalToOverlay(details.globalPosition);
    final dx = pointerScreen.dx - _rotationCenterScreen!.dx;
    final dy = pointerScreen.dy - _rotationCenterScreen!.dy;
    _initialRotationAngle = math.atan2(dy, dx);
    _rotationAngle = 0.0;
  }

  void _onRotateUpdate(DragUpdateDetails details) {
    if (!_isRotating || _rotationCenterScreen == null) return;

    final pointerScreen = _globalToOverlay(details.globalPosition);
    final dx = pointerScreen.dx - _rotationCenterScreen!.dx;
    final dy = pointerScreen.dy - _rotationCenterScreen!.dy;
    final currentAngle = math.atan2(dy, dx);
    _rotationAngle = currentAngle - _initialRotationAngle;

    // Create a rotated selection region
    final anchorPixel = widget.selectionState?.effectiveAnchor ??
        widget.selectionRegion.bounds.center;
    final matrix = Matrix4.translationValues(
      anchorPixel.dx,
      anchorPixel.dy,
      0.0,
    )
      ..rotateZ(_rotationAngle)
      ..multiply(
        Matrix4.translationValues(
          -anchorPixel.dx,
          -anchorPixel.dy,
          0.0,
        ),
      );

    final rotatedRegion = widget.selectionRegion.transformed(matrix);
    widget.onSelectionRotate?.call(rotatedRegion, _rotationAngle);
  }

  void _onRotateEnd(DragEndDetails details) {
    _isRotating = false;
    _rotationCenterScreen = null;
    widget.onSelectionMoveEnd?.call();
  }

  // ── Anchor Handle ──

  Widget _buildAnchorHandle(Offset anchorScreen) {
    return Positioned(
      left: anchorScreen.dx - _centerHandleSize / 2,
      top: anchorScreen.dy - _centerHandleSize / 2,
      width: _centerHandleSize,
      height: _centerHandleSize,
      child: GestureDetector(
        onPanStart: (d) => _isDraggingAnchor = true,
        onPanUpdate: (details) {
          if (!_isDraggingAnchor) return;
          final currentScreen = _globalToOverlay(details.globalPosition);
          final newPixelPos = _clampPixelOffset(_screenToPixel(currentScreen));
          widget.onAnchorChanged?.call(newPixelPos);
        },
        onPanEnd: (d) => _isDraggingAnchor = false,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withValues(alpha: 0.8),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.adjust, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Marching Ants Painter ──

class _SelectionPathPainter extends CustomPainter {
  final SelectionRegion selectionRegion;
  final double pixelWidth;
  final double pixelHeight;
  final double animationValue;

  _SelectionPathPainter({
    required this.selectionRegion,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = selectionRegion.bounds;
    if (bounds.width <= 0 || bounds.height <= 0) return;

    // Scale the selection path to screen coordinates
    final matrix = Matrix4.diagonal3Values(pixelWidth, pixelHeight, 1.0);
    final scaledPath = selectionRegion.path.transform(matrix.storage);

    // Draw black background line
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black;
    canvas.drawPath(scaledPath, bgPaint);

    // Draw white dashed line on top (marching ants effect)
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white;

    const dashLength = 6.0;
    const gapLength = 4.0;
    const totalDash = dashLength + gapLength;
    final offset = animationValue * totalDash;

    for (final metric in scaledPath.computeMetrics()) {
      double distance = -offset;
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + dashLength).clamp(0.0, metric.length);
        if (end > start) {
          final extractedPath = metric.extractPath(start, end);
          canvas.drawPath(extractedPath, dashPaint);
        }
        distance += totalDash;
      }
    }
  }

  @override
  bool shouldRepaint(_SelectionPathPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        selectionRegion != oldDelegate.selectionRegion;
  }
}

enum _Handle {
  topLeft,
  topCenter,
  topRight,
  rightCenter,
  bottomRight,
  bottomCenter,
  bottomLeft,
  leftCenter,
}
