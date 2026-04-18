import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core.dart';
import '../../../data.dart';

/// Wraps the pixel canvas with seamless-tile ghost copies on all 8 sides.
///
/// When [enabled] is true the widget renders 8 read-only copies of the
/// composited canvas image (derived from [layers]) at -1/0/+1 offsets on both
/// axes around the real [child] canvas.  This lets the artist see exactly how
/// the artwork will look when tiled — identical to Aseprite's "Show Extras /
/// Tiled Mode" feature.
///
/// The copies are drawn with [clipBehavior] = [Clip.none] so they bleed
/// outside the widget bounds.  The parent [OverflowBox] in the canvas screen
/// already allows this overflow.
class TiledCanvasWrap extends StatefulWidget {
  const TiledCanvasWrap({
    super.key,
    required this.enabled,
    required this.layers,
    required this.width,
    required this.height,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.child,
  });

  final bool enabled;

  /// Layers of the current frame used to composite the ghost image.
  final List<Layer> layers;

  /// Logical pixel dimensions of the canvas (used for compositing).
  final int width;
  final int height;

  /// Rendered size of the canvas widget in logical pixels (for ghost placement).
  final double canvasWidth;
  final double canvasHeight;

  /// The real, interactive canvas widget (placed at the centre of the grid).
  final Widget child;

  @override
  State<TiledCanvasWrap> createState() => _TiledCanvasWrapState();
}

class _TiledCanvasWrapState extends State<TiledCanvasWrap> {
  ui.Image? _ghostImage;
  Timer? _debounce;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _scheduleRebuild();
  }

  @override
  void didUpdateWidget(TiledCanvasWrap old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) return;
    // Rebuild when layers change or tile mode is just toggled on.
    if (!old.enabled || !listEquals(old.layers, widget.layers)) {
      _scheduleRebuild();
    }
  }

  void _scheduleRebuild() {
    if (_dirty) return;
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), _rebuild);
  }

  Future<void> _rebuild() async {
    _dirty = false;
    final pixels = await compute(
      _mergePixels,
      _MergeArgs(
        width: widget.width,
        height: widget.height,
        layers: widget.layers,
      ),
    );

    final image = await ImageHelper.createImageFromPixels(
      pixels,
      widget.width,
      widget.height,
    );

    if (mounted) {
      setState(() {
        _ghostImage?.dispose();
        _ghostImage = image;
      });
    } else {
      image.dispose();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ghostImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _ghostImage == null) return widget.child;

    final w = widget.canvasWidth;
    final h = widget.canvasHeight;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 8 ghost copies at each neighbouring position
          for (final dy in const [-1, 0, 1])
            for (final dx in const [-1, 0, 1])
              if (dx != 0 || dy != 0)
                Positioned(
                  left: dx * w,
                  top: dy * h,
                  width: w,
                  height: h,
                  child: _GhostTile(image: _ghostImage!),
                ),
          // Actual editable canvas (on top, at origin)
          widget.child,
        ],
      ),
    );
  }
}

/// Static, non-interactive rendering of the composited tile image.
class _GhostTile extends StatelessWidget {
  const _GhostTile({required this.image});
  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _GhostPainter(image: image)),
    );
  }
}

class _GhostPainter extends CustomPainter {
  const _GhostPainter({required this.image});
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    // Checkerboard so transparent tiles look nice
    _paintCheckerboard(canvas, size);

    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  void _paintCheckerboard(Canvas canvas, Size size) {
    const cell = 8.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    final light = Paint()..color = const Color(0xFFCCCCCC);
    final dark = Paint()..color = const Color(0xFF999999);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          (r + c) % 2 == 0 ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GhostPainter old) => image != old.image;
}

// ── Isolate helper ─────────────────────────────────────────────────────────────

class _MergeArgs {
  final int width;
  final int height;
  final List<Layer> layers;
  const _MergeArgs({required this.width, required this.height, required this.layers});
}

/// Runs `mergeLayersPixels` in an isolate to avoid jank on large canvases.
Future<dynamic> _mergePixels(_MergeArgs args) async {
  return PixelUtils.mergeLayersPixels(
    width: args.width,
    height: args.height,
    layers: args.layers,
  );
}
