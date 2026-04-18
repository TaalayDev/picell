import 'package:flutter/material.dart';

import '../pixel_point.dart';
import '../tools.dart';

/// A two-point drag tool that applies a linear gradient between the start and
/// end positions.
///
/// **Interaction:**
/// 1. Press — anchors the gradient start.
/// 2. Drag — updates the gradient end preview (via [onGradientPreview]).
/// 3. Release — commits the gradient (via [onGradientApply]).
///
/// Coordinates passed to the callbacks are in *canvas space* (pixel units),
/// not screen pixels.  The host is responsible for the coordinate conversion.
class GradientTool extends Tool {
  /// Called continuously during drag with the current start/end canvas
  /// positions so the painter can draw a live preview line.
  final void Function(Offset start, Offset end) onGradientPreview;

  /// Called once on pointer-up to actually bake the gradient into the layer.
  final void Function(Offset startPx, Offset endPx) onGradientApply;

  /// Called when the gesture is cancelled or starts, to clear the preview.
  final VoidCallback onGradientClear;

  Offset? _startCanvas;

  GradientTool({
    required this.onGradientPreview,
    required this.onGradientApply,
    required this.onGradientClear,
  }) : super(PixelTool.gradient);

  @override
  void onStart(PixelDrawDetails details) {
    _startCanvas = _toCanvasOffset(details);
    onGradientPreview(_startCanvas!, _startCanvas!);
  }

  @override
  void onMove(PixelDrawDetails details) {
    if (_startCanvas == null) return;
    final end = _toCanvasOffset(details);
    onGradientPreview(_startCanvas!, end);
  }

  @override
  void onEnd(PixelDrawDetails details) {
    if (_startCanvas == null) return;
    final end = _toCanvasOffset(details);
    onGradientApply(_startCanvas!, end);
    _startCanvas = null;
    onGradientClear();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
