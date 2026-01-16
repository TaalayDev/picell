import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data.dart';
import '../../pixel_point.dart';

const _centerHandleSize = 18.0;
const _handleSize = 12.0;

class SelectionOverlay extends StatefulWidget {
  final List<PixelPoint<int>>? selection;
  final double zoomLevel;
  final Offset canvasOffset;
  final int canvasWidth;
  final int canvasHeight;
  final Size canvasSize;

  final Function(List<PixelPoint<int>>, math.Point delta)? onSelectionMove;
  final Function(List<PixelPoint<int>>, double angle)? onSelectionRotate;

  final Function(List<PixelPoint<int>>, double, double, PixelPoint<int>)? onSelectionResize;
  final Function(List<PixelPoint<int>> original)? onSelectionResizeStart;

  final Function()? onSelectionMoveEnd;

  const SelectionOverlay({
    super.key,
    required this.selection,
    required this.zoomLevel,
    required this.canvasOffset,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.canvasSize,
    this.onSelectionMove,
    this.onSelectionRotate,
    this.onSelectionResize,
    this.onSelectionMoveEnd,
    this.onSelectionResizeStart,
  });

  @override
  State<SelectionOverlay> createState() => _SelectionOverlayState();
}

class _SelectionOverlayState extends State<SelectionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  Offset _lastPanPosition = Offset.zero;
  List<PixelPoint<int>>? _originalSelection;

  double _rotationAngle = 0.0;
  double _initialRotationAngle = 0.0;
  bool _isRotating = false;
  Offset? _centerPoint;

  _Handle? _activeHandle;
  Offset _resizeStartGlobal = Offset.zero;
  _PixelBounds? _origBounds;
  List<PixelPoint<int>>? _resizeOriginalSelection;

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

  SelectionModel? _getSelectionBounds() {
    if (widget.selection == null || widget.selection!.isEmpty) return null;
    return fromPointsToSelection(widget.selection!, widget.canvasSize);
  }

  SelectionModel? fromPointsToSelection(List<PixelPoint<int>> points, Size canvasSize) {
    if (points.isEmpty ||
        widget.canvasWidth <= 0 ||
        widget.canvasHeight <= 0 ||
        canvasSize.width <= 0 ||
        canvasSize.height <= 0) {
      return null;
    }

    // size of one image pixel in canvas logical px
    final pixelWidth = canvasSize.width / widget.canvasWidth;
    final pixelHeight = canvasSize.height / widget.canvasHeight;

    int minPixelX = points.first.x;
    int minPixelY = points.first.y;
    int maxPixelX = points.first.x;
    int maxPixelY = points.first.y;

    for (final p in points) {
      if (p.x < minPixelX) minPixelX = p.x;
      if (p.x > maxPixelX) maxPixelX = p.x;
      if (p.y < minPixelY) minPixelY = p.y;
      if (p.y > maxPixelY) maxPixelY = p.y;
    }

    final canvasX = minPixelX * pixelWidth;
    final canvasY = minPixelY * pixelHeight;
    final canvasW = (maxPixelX - minPixelX + 1) * pixelWidth;
    final canvasH = (maxPixelY - minPixelY + 1) * pixelHeight;

    return SelectionModel(
      x: canvasX.toInt(),
      y: canvasY.toInt(),
      width: canvasW.toInt(),
      height: canvasH.toInt(),
      canvasSize: canvasSize,
    );
  }

  Offset _getSelectionCenter(double screenLeft, double screenTop, double screenWidth, double screenHeight) {
    return Offset(screenLeft + screenWidth / 2, screenTop + screenHeight / 2);
  }

  PixelPoint<int> _rotatePoint(PixelPoint<int> point, PixelPoint<int> center, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    final tx = point.x - center.x;
    final ty = point.y - center.y;
    final rx = tx * c - ty * s;
    final ry = tx * s + ty * c;
    return PixelPoint<int>((rx + center.x).round(), (ry + center.y).round());
  }

  PixelPoint<int>? _getSelectionCenterInPixels() {
    final pts = widget.selection;
    if (pts == null || pts.isEmpty) return null;

    int minX = pts.first.x, maxX = pts.first.x;
    int minY = pts.first.y, maxY = pts.first.y;
    for (final p in pts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return PixelPoint<int>(((minX + maxX) / 2).round(), ((minY + maxY) / 2).round());
  }

  _PixelBounds? _getSelectionPixelBounds() {
    final pts = widget.selection;
    if (pts == null || pts.isEmpty) return null;

    int minX = pts.first.x, maxX = pts.first.x;
    int minY = pts.first.y, maxY = pts.first.y;
    for (final p in pts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return _PixelBounds(minX, minY, maxX, maxY);
  }

  math.Point<double> _screenDeltaToImageDelta(Offset delta) {
    final canvasDx = delta.dx / widget.zoomLevel;
    final canvasDy = delta.dy / widget.zoomLevel;
    final pxDx = canvasDx * (widget.canvasWidth / widget.canvasSize.width);
    final pxDy = canvasDy * (widget.canvasHeight / widget.canvasSize.height);
    return math.Point(pxDx, pxDy);
  }

  @override
  Widget build(BuildContext context) {
    final selectionBounds = _getSelectionBounds();
    if (selectionBounds == null ||
        widget.canvasSize.width == 0 ||
        widget.canvasSize.height == 0 ||
        widget.zoomLevel <= 0) {
      return const SizedBox.shrink();
    }

    final screenLeft = (selectionBounds.x * widget.zoomLevel);
    final screenTop = (selectionBounds.y * widget.zoomLevel);
    final screenWidth = selectionBounds.width * widget.zoomLevel;
    final screenHeight = selectionBounds.height * widget.zoomLevel;

    _centerPoint = _getSelectionCenter(screenLeft, screenTop, screenWidth, screenHeight);

    return Stack(
      children: [
        Positioned(
          left: screenLeft,
          top: screenTop,
          width: screenWidth,
          height: screenHeight,
          // Don't apply visual rotation transform - the selection points are already
          // rotated, so the bounding box reflects the actual rotated selection
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                      ),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: MarchingAntsPainter(progress: _animationController.value),
                      ),
                    );
                  },
                ),
              ),
              ..._buildSelectionHandles(screenWidth, screenHeight),
              _buildRotationHandle(screenWidth, screenHeight),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSelectionHandles(double width, double height) {
    const h = _handleSize;
    const hh = _handleSize / 2;

    return [
      _buildResizeHandle(_Handle.topLeft, Offset(-hh, -hh)),
      _buildResizeHandle(_Handle.top, Offset(width / 2 - hh, -hh)),
      _buildResizeHandle(_Handle.topRight, Offset(width - hh, -hh)),
      _buildResizeHandle(_Handle.right, Offset(width - hh, height / 2 - hh)),
      _buildResizeHandle(_Handle.bottomRight, Offset(width - hh, height - hh)),
      _buildResizeHandle(_Handle.bottom, Offset(width / 2 - hh, height - hh)),
      _buildResizeHandle(_Handle.bottomLeft, Offset(-hh, height - hh)),
      _buildResizeHandle(_Handle.left, Offset(-hh, height / 2 - hh)),
      _buildDraggableCenterHandle(width / 2 - (_centerHandleSize / 2), height / 2 - (_centerHandleSize / 2)),
    ];
  }

  Widget _buildResizeHandle(_Handle handle, Offset pos) {
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: _handleSize,
      height: _handleSize,
      child: GestureDetector(
        onPanStart: (d) => _handleResizeStart(handle, d),
        onPanUpdate: (d) => _handleResizeUpdate(handle, d),
        onPanEnd: _handleResizeEnd,
        child: Container(
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 1.0),
            borderRadius: BorderRadius.circular(1.0),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(1, 1))],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableCenterHandle(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      width: _centerHandleSize,
      height: _centerHandleSize,
      child: GestureDetector(
        // optional: separate gestures; keep move on rect for simplicity
        onPanStart: _handleCenterPanStart,
        onPanUpdate: _handleCenterPanUpdate,
        onPanEnd: _handleCenterPanEnd,
        child: Container(
          width: _centerHandleSize,
          height: _centerHandleSize,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            border: Border.all(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(1, 1))],
          ),
        ),
      ),
    );
  }

  Widget _buildRotationHandle(double width, double height) {
    const handleSize = 14.0;
    const handleDistance = 30.0;

    final rotationHandleX = width / 2 - handleSize / 2;
    final rotationHandleY = height / 2 - handleDistance - handleSize / 2;

    return Positioned(
      left: rotationHandleX,
      top: rotationHandleY,
      width: handleSize,
      height: handleSize,
      child: GestureDetector(
        onPanStart: _handleRotationStart,
        onPanUpdate: _handleRotationUpdate,
        onPanEnd: _handleRotationEnd,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.circular(handleSize / 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(1, 1))],
          ),
          child: const Icon(Icons.rotate_right, size: 6, color: Colors.white),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
    _originalSelection = widget.selection?.map((p) => PixelPoint<int>(p.x, p.y)).toList();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_originalSelection == null || _originalSelection!.isEmpty) return;

    final totalDelta = details.localPosition - _lastPanPosition;
    final pxDelta = _screenDeltaToImageDelta(totalDelta);

    final dx = pxDelta.x.round();
    final dy = pxDelta.y.round();

    final newSelection = _originalSelection!.map((p) {
      return PixelPoint<int>(
        (p.x + dx).clamp(0, widget.canvasWidth - 1),
        (p.y + dy).clamp(0, widget.canvasHeight - 1),
      );
    }).toList();

    widget.onSelectionMove?.call(newSelection, math.Point(dx, dy));
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = Offset.zero;
    _originalSelection = null;
    widget.onSelectionMoveEnd?.call();
  }

  void _handleCenterPanStart(DragStartDetails details) {}
  void _handleCenterPanUpdate(DragUpdateDetails details) {}
  void _handleCenterPanEnd(DragEndDetails details) {}

  void _handleRotationStart(DragStartDetails details) {
    _isRotating = true;
    _originalSelection = widget.selection?.map((p) => PixelPoint<int>(p.x, p.y)).toList();

    if (_centerPoint != null) {
      final angle = math.atan2(
        details.globalPosition.dy - _centerPoint!.dy,
        details.globalPosition.dx - _centerPoint!.dx,
      );
      _initialRotationAngle = angle;
      _rotationAngle = 0.0;
      setState(() {});
    }
  }

  void _handleRotationUpdate(DragUpdateDetails details) {
    if (_originalSelection == null || _originalSelection!.isEmpty || _centerPoint == null || !_isRotating) return;

    final currentAngle = math.atan2(
      details.globalPosition.dy - _centerPoint!.dy,
      details.globalPosition.dx - _centerPoint!.dx,
    );

    _rotationAngle = currentAngle - _initialRotationAngle;
    setState(() {});

    final centerInPixels = _getSelectionCenterInPixels();
    if (centerInPixels == null) return;

    final rotatedSelection = _originalSelection!.map((p) => _rotatePoint(p, centerInPixels, _rotationAngle)).toList();
    widget.onSelectionRotate?.call(rotatedSelection, _rotationAngle);
  }

  void _handleRotationEnd(DragEndDetails details) {
    _isRotating = false;
    _rotationAngle = 0.0;
    _originalSelection = null;
    setState(() {});
    widget.onSelectionMoveEnd?.call();
  }

  void _handleResizeStart(_Handle handle, DragStartDetails details) {
    _activeHandle = handle;
    _resizeStartGlobal = details.globalPosition;
    _resizeOriginalSelection = widget.selection?.map((p) => PixelPoint<int>(p.x, p.y)).toList();
    if (widget.onSelectionResizeStart != null && _resizeOriginalSelection != null) {
      widget.onSelectionResizeStart!(_resizeOriginalSelection!);
    }
    _origBounds = _getSelectionPixelBounds();
  }

  void _handleResizeUpdate(_Handle handle, DragUpdateDetails details) {
    if (_resizeOriginalSelection == null || _resizeOriginalSelection!.isEmpty) return;
    if (_origBounds == null) return;

    final deltaScreen = details.globalPosition - _resizeStartGlobal;

    final pxDelta = _screenDeltaToImageDelta(deltaScreen);
    final dx = pxDelta.x;
    final dy = pxDelta.y;

    int minX = _origBounds!.minX;
    int minY = _origBounds!.minY;
    int maxX = _origBounds!.maxX;
    int maxY = _origBounds!.maxY;

    switch (handle) {
      case _Handle.topLeft:
        minX = (minX + dx.round()).clamp(0, maxX - 1);
        minY = (minY + dy.round()).clamp(0, maxY - 1);
        break;
      case _Handle.top:
        minY = (minY + dy.round()).clamp(0, maxY - 1);
        break;
      case _Handle.topRight:
        maxX = (maxX + dx.round()).clamp(minX + 1, widget.canvasWidth - 1);
        minY = (minY + dy.round()).clamp(0, maxY - 1);
        break;
      case _Handle.right:
        maxX = (maxX + dx.round()).clamp(minX + 1, widget.canvasWidth - 1);
        break;
      case _Handle.bottomRight:
        maxX = (maxX + dx.round()).clamp(minX + 1, widget.canvasWidth - 1);
        maxY = (maxY + dy.round()).clamp(minY + 1, widget.canvasHeight - 1);
        break;
      case _Handle.bottom:
        maxY = (maxY + dy.round()).clamp(minY + 1, widget.canvasHeight - 1);
        break;
      case _Handle.bottomLeft:
        minX = (minX + dx.round()).clamp(0, maxX - 1);
        maxY = (maxY + dy.round()).clamp(minY + 1, widget.canvasHeight - 1);
        break;
      case _Handle.left:
        minX = (minX + dx.round()).clamp(0, maxX - 1);
        break;
      case _Handle.center:
        break;
    }

    final origW = (_origBounds!.maxX - _origBounds!.minX + 1).toDouble();
    final origH = (_origBounds!.maxY - _origBounds!.minY + 1).toDouble();
    final newW = (maxX - minX + 1).toDouble();
    final newH = (maxY - minY + 1).toDouble();

    final pivot = switch (handle) {
      _Handle.topLeft => PixelPoint<int>(_origBounds!.maxX, _origBounds!.maxY),
      _Handle.top => PixelPoint<int>((_origBounds!.minX + _origBounds!.maxX) ~/ 2, _origBounds!.maxY),
      _Handle.topRight => PixelPoint<int>(_origBounds!.minX, _origBounds!.maxY),
      _Handle.right => PixelPoint<int>(_origBounds!.minX, (_origBounds!.minY + _origBounds!.maxY) ~/ 2),
      _Handle.bottomRight => PixelPoint<int>(_origBounds!.minX, _origBounds!.minY),
      _Handle.bottom => PixelPoint<int>((_origBounds!.minX + _origBounds!.maxX) ~/ 2, _origBounds!.minY),
      _Handle.bottomLeft => PixelPoint<int>(_origBounds!.maxX, _origBounds!.minY),
      _Handle.left => PixelPoint<int>(_origBounds!.maxX, (_origBounds!.minY + _origBounds!.maxY) ~/ 2),
      _Handle.center =>
        PixelPoint<int>((_origBounds!.minX + _origBounds!.maxX) ~/ 2, (_origBounds!.minY + _origBounds!.maxY) ~/ 2),
    };

    final affectX = switch (handle) {
      _Handle.top || _Handle.bottom => false,
      _ => true,
    };
    final affectY = switch (handle) {
      _Handle.left || _Handle.right => false,
      _ => true,
    };

    final scaleX = affectX ? (newW / origW).clamp(0.01, 1000.0) : 1.0;
    final scaleY = affectY ? (newH / origH).clamp(0.01, 1000.0) : 1.0;

    final scaled = _resizeOriginalSelection!.map((p) {
      final nx = pivot.x + (p.x - pivot.x) * scaleX;
      final ny = pivot.y + (p.y - pivot.y) * scaleY;
      return PixelPoint<int>(
        nx.round().clamp(0, widget.canvasWidth - 1),
        ny.round().clamp(0, widget.canvasHeight - 1),
      );
    }).toList();

    if (widget.onSelectionResize != null) {
      widget.onSelectionResize!(scaled, scaleX, scaleY, pivot);
    } else if (widget.onSelectionMove != null) {
      widget.onSelectionMove!(scaled, const math.Point(0, 0));
    }
    setState(() {});
  }

  void _handleResizeEnd(DragEndDetails details) {
    _activeHandle = null;
    _resizeOriginalSelection = null;
    _origBounds = null;
    _resizeStartGlobal = Offset.zero;
    widget.onSelectionMoveEnd?.call();
  }
}

enum _Handle { topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left, center }

class _PixelBounds {
  final int minX, minY, maxX, maxY;
  _PixelBounds(this.minX, this.minY, this.maxX, this.maxY);
  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}

class MarchingAntsPainter extends CustomPainter {
  final double progress;
  MarchingAntsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    const totalDashLength = dashWidth + dashSpace;
    final offset = progress * totalDashLength;

    _drawDashedRect(canvas, Rect.fromLTWH(0, 0, size.width, size.height), paint, dashWidth, dashSpace, offset);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, double dashWidth, double dashSpace, double offset) {
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashWidth, dashSpace, offset);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashWidth, dashSpace, offset);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashWidth, dashSpace, offset);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashWidth, dashSpace, offset);
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace, double offset) {
    final distance = (end - start).distance;
    if (distance == 0) return;

    final unitVector = (end - start) / distance;

    double currentDistance = -offset;
    bool isDash = true;

    while (currentDistance < distance) {
      final segmentLength = isDash ? dashWidth : dashSpace;
      final segmentStart = currentDistance.clamp(0.0, distance);
      final segmentEnd = (currentDistance + segmentLength).clamp(0.0, distance);

      if (isDash && segmentStart < distance && segmentEnd > 0) {
        final startPoint = start + unitVector * segmentStart;
        final endPoint = start + unitVector * segmentEnd;
        canvas.drawLine(startPoint, endPoint, paint);
      }

      currentDistance += segmentLength;
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(covariant MarchingAntsPainter oldDelegate) => progress != oldDelegate.progress;
}
