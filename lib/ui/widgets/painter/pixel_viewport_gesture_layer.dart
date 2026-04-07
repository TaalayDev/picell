import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../pixel/canvas/pixel_viewport_controller.dart';

class PixelViewportGestureLayer extends SingleChildRenderObjectWidget {
  const PixelViewportGestureLayer({
    super.key,
    required this.controller,
    required super.child,
  });

  final PixelViewportController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPixelViewportGestureLayer(
      controller: controller,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderPixelViewportGestureLayer renderObject,
  ) {
    renderObject.controller = controller;
  }
}

class RenderPixelViewportGestureLayer extends RenderProxyBox {
  RenderPixelViewportGestureLayer({
    required PixelViewportController controller,
  }) : _controller = controller;

  static const double _minScale = 0.5;
  static const double _maxScale = 5.0;
  static const double _touchScaleSensitivity = 0.5;

  final Map<int, PointerEvent> _activeTouchPointers = <int, PointerEvent>{};
  double? _gestureStartScale;
  double _initialPointerDistance = 0.0;
  Offset _normalizedOffset = Offset.zero;
  Offset? _trackpadStartFocalPoint;
  double? _trackpadStartScale;

  PixelViewportController _controller;
  PixelViewportController get controller => _controller;
  set controller(PixelViewportController value) {
    if (identical(_controller, value)) {
      return;
    }
    _controller = value;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerPanZoomStartEvent) {
      _handlePanZoomStart(event);
      return;
    }
    if (event is PointerPanZoomUpdateEvent) {
      _handlePanZoomUpdate(event);
      return;
    }
    if (event is PointerPanZoomEndEvent) {
      _resetTrackpadGesture();
      return;
    }

    if (event.kind != PointerDeviceKind.touch) {
      return;
    }

    if (event is PointerDownEvent) {
      _activeTouchPointers[event.pointer] = event;
      if (_activeTouchPointers.length == 2) {
        final pointers = _activeTouchPointers.values.toList(growable: false);
        final focalPoint = Offset(
          (pointers[0].localPosition.dx + pointers[1].localPosition.dx) / 2,
          (pointers[0].localPosition.dy + pointers[1].localPosition.dy) / 2,
        );
        _gestureStartScale = controller.scale;
        _normalizedOffset = (controller.offset - focalPoint) /
            math.max(controller.scale, 0.0001);
        _initialPointerDistance =
            (pointers[0].localPosition - pointers[1].localPosition).distance;
      }
      return;
    }

    if (event is PointerMoveEvent) {
      if (!_activeTouchPointers.containsKey(event.pointer)) {
        return;
      }
      _activeTouchPointers[event.pointer] = event;
      if (_activeTouchPointers.length != 2 || _gestureStartScale == null) {
        return;
      }

      final pointers = _activeTouchPointers.values.toList(growable: false);
      final focalPoint = Offset(
        (pointers[0].localPosition.dx + pointers[1].localPosition.dx) / 2,
        (pointers[0].localPosition.dy + pointers[1].localPosition.dy) / 2,
      );
      final currentDistance =
          (pointers[0].localPosition - pointers[1].localPosition).distance;
      if (_initialPointerDistance <= 0) {
        return;
      }

      final scaleRatio = currentDistance / _initialPointerDistance;
      final adjustedScaleRatio =
          1 + ((scaleRatio - 1) * _touchScaleSensitivity);
      final nextScale = (_gestureStartScale! * adjustedScaleRatio)
          .clamp(_minScale, _maxScale);
      final nextOffset = focalPoint + _normalizedOffset * nextScale;
      controller.setViewport(nextScale, nextOffset);
      return;
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _activeTouchPointers.remove(event.pointer);
      if (_activeTouchPointers.length < 2) {
        _resetTouchGesture();
      }
    }
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _trackpadStartFocalPoint = event.localPosition;
    _trackpadStartScale = controller.scale;
    _normalizedOffset = (controller.offset - event.localPosition) /
        math.max(controller.scale, 0.0001);
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final startFocalPoint = _trackpadStartFocalPoint;
    final startScale = _trackpadStartScale;
    if (startFocalPoint == null || startScale == null) {
      return;
    }

    final nextScale = (startScale * event.scale).clamp(_minScale, _maxScale);
    final focalPoint = startFocalPoint + event.localPan;
    final nextOffset = focalPoint + _normalizedOffset * nextScale;
    controller.setViewport(nextScale, nextOffset);
  }

  void _resetTouchGesture() {
    _gestureStartScale = null;
    _initialPointerDistance = 0.0;
  }

  void _resetTrackpadGesture() {
    _trackpadStartFocalPoint = null;
    _trackpadStartScale = null;
  }
}
