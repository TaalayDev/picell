import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../tools.dart';

enum _GradientDrag { newGradient, startHandle, endHandle }

/// A two-point drag tool for gradients that stay editable until committed.
///
/// **Interaction:**
/// 1. Drag — draws a new gradient from press to release (preview via
///    [onGradientPreview]).
/// 2. Release — the gradient stays *pending*: its start/end handles can be
///    dragged to adjust it.
/// 3. Commit — [commit] (Enter, switching tools) or starting a new gradient
///    elsewhere bakes it in via [onGradientApply]. A plain click outside the
///    handles commits without starting a new one. [cancel] (Esc) drops it.
///
/// The previous pending gradient is only committed when a new drag *ends*, so
/// a drag cancelled midway (e.g. a second finger landing for pinch-zoom)
/// restores it untouched.
///
/// Holding Shift snaps the direction to 15° steps.
///
/// Coordinates passed to the callbacks are in *canvas space* (pixel units),
/// not screen pixels.
class GradientTool extends Tool {
  /// Called whenever the pending/dragged gradient changes.
  final void Function(Offset start, Offset end) onGradientPreview;

  /// Called to bake a gradient into the layer.
  final void Function(Offset startPx, Offset endPx) onGradientApply;

  /// Called after a commit: no gradient is pending any more.
  final VoidCallback onGradientClear;

  /// Called when a gradient is dropped without committing.
  final VoidCallback onGradientCancel;

  /// Current viewport zoom, for screen-sized handle hit areas.
  final double Function() zoomLevel;

  /// Handle grab radius in screen pixels.
  static const double handleHitRadius = 14;

  /// Drags shorter than this (canvas pixels) count as a click.
  static const double minDragLength = 0.5;

  Offset? _start;
  Offset? _end;
  _GradientDrag? _drag;

  // Pending gradient from before the current drag, restored on cancelDrag
  // and committed when a new-gradient drag ends.
  Offset? _prevStart;
  Offset? _prevEnd;

  GradientTool({
    required this.onGradientPreview,
    required this.onGradientApply,
    required this.onGradientClear,
    VoidCallback? onGradientCancel,
    double Function()? zoomLevel,
  })  : onGradientCancel = onGradientCancel ?? onGradientClear,
        zoomLevel = zoomLevel ?? (() => 1.0),
        super(PixelTool.gradient);

  /// Whether a released gradient is waiting for commit or cancel.
  bool get hasPendingGradient => _start != null && _drag == null;

  /// Whether a gradient is visible (pending or being dragged).
  bool get isActive => _start != null;

  Offset? get start => _start;
  Offset? get end => _end;

  @override
  void onStart(PixelDrawDetails details) {
    final p = _toCanvasOffset(details);
    _prevStart = _start;
    _prevEnd = _end;

    if (_start != null) {
      final radius = _hitRadius(details);
      final dStart = (p - _start!).distance;
      final dEnd = (p - _end!).distance;
      if (dEnd <= radius && dEnd <= dStart) {
        _drag = _GradientDrag.endHandle;
        return;
      }
      if (dStart <= radius) {
        _drag = _GradientDrag.startHandle;
        return;
      }
    }

    // Nothing is previewed until the drag has a direction: a zero-length
    // gradient would flood the whole area with the first colour. Any pending
    // gradient stays on screen until then.
    _drag = _GradientDrag.newGradient;
    _start = p;
    _end = p;
  }

  @override
  void onMove(PixelDrawDetails details) {
    final drag = _drag;
    if (drag == null || _start == null) return;
    final p = _toCanvasOffset(details);
    if (drag == _GradientDrag.startHandle) {
      _start = _constrain(_end!, p);
    } else {
      _end = _constrain(_start!, p);
    }
    if (drag == _GradientDrag.newGradient && _isTooShort) return;
    onGradientPreview(_start!, _end!);
  }

  @override
  void onEnd(PixelDrawDetails details) {
    final drag = _drag;
    if (drag == null) return;
    onMove(details);
    _drag = null;

    if (drag != _GradientDrag.newGradient) return;

    final isClick = _isTooShort;
    final newStart = _start!, newEnd = _end!;
    final prevStart = _prevStart, prevEnd = _prevEnd;
    _prevStart = _prevEnd = null;

    if (prevStart != null && prevEnd != null) {
      onGradientApply(prevStart, prevEnd);
    }
    if (isClick) {
      _start = _end = null;
      if (prevStart != null) {
        onGradientClear();
      } else {
        onGradientCancel();
      }
      return;
    }
    // Re-preview against the layer as it is after the previous commit.
    onGradientPreview(newStart, newEnd);
  }

  /// Bakes the pending gradient into the layer. Returns false if none.
  bool commit() {
    if (_start == null || _drag != null) return false;
    final start = _start!, end = _end!;
    _start = _end = null;
    onGradientApply(start, end);
    onGradientClear();
    return true;
  }

  /// Drops the pending (or in-progress) gradient. Returns false if none.
  bool cancel() {
    if (_start == null) return false;
    _start = _end = _drag = _prevStart = _prevEnd = null;
    onGradientCancel();
    return true;
  }

  /// Aborts the current drag only, restoring the gradient that was pending
  /// before it (if any).
  void cancelDrag() {
    if (_drag == null) return;
    _drag = null;
    _start = _prevStart;
    _end = _prevEnd;
    _prevStart = _prevEnd = null;
    if (_start != null) {
      onGradientPreview(_start!, _end!);
    } else {
      onGradientCancel();
    }
  }

  /// Re-renders the pending gradient (e.g. after the layer changed).
  void refresh() {
    if (_start != null) onGradientPreview(_start!, _end!);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isTooShort => (_end! - _start!).distance < minDragLength;

  Offset _constrain(Offset anchor, Offset p) =>
      HardwareKeyboard.instance.isShiftPressed ? snapAngle(anchor, p) : p;

  /// Grab radius in canvas pixels.
  double _hitRadius(PixelDrawDetails details) {
    final screenPerPixel =
        details.size.width / details.width * zoomLevel();
    if (screenPerPixel <= 0) return 1;
    return math.max(handleHitRadius / screenPerPixel, 0.75);
  }

  /// Rotates [end] around [start] to the nearest multiple of [stepDegrees],
  /// keeping the drag length.
  static Offset snapAngle(Offset start, Offset end, {double stepDegrees = 15}) {
    final delta = end - start;
    if (delta.distance == 0) return end;
    final step = stepDegrees * math.pi / 180;
    final angle = (delta.direction / step).round() * step;
    return start + Offset.fromDirection(angle, delta.distance);
  }

  /// Converts the widget-space [PixelDrawDetails.position] to canvas pixel
  /// coordinates (floating-point so the gradient endpoint can land between
  /// pixels for smooth interpolation).
  Offset _toCanvasOffset(PixelDrawDetails details) {
    final scaleX = details.width / details.size.width;
    final scaleY = details.height / details.size.height;
    return Offset(
      details.position.dx * scaleX,
      details.position.dy * scaleY,
    );
  }
}
