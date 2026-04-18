import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/models/tilemap_model.dart';
import '../../../providers/tilemap_provider.dart';

/// Converts an ARGB Uint32List to an RGBA Uint8List for ui.decodeImageFromPixels.
Uint8List _argbToRgba(Uint32List argb) {
  final result = Uint8List(argb.length * 4);
  for (int i = 0; i < argb.length; i++) {
    final p = argb[i];
    result[i * 4] = (p >> 16) & 0xFF; // R
    result[i * 4 + 1] = (p >> 8) & 0xFF; // G
    result[i * 4 + 2] = p & 0xFF; // B
    result[i * 4 + 3] = (p >> 24) & 0xFF; // A
  }
  return result;
}

/// Composites all visible tilemap layers into a single ARGB pixel buffer.
Uint32List _compositeLayers(TilemapData data) {
  final w = data.mapWidth;
  final h = data.mapHeight;
  final out = Uint32List(w * h);

  // Sort layers by order (ascending = bottom first)
  final sorted = [...data.layers]..sort((a, b) => a.order.compareTo(b.order));

  // Build a quick id→tile lookup
  final tileById = {for (final t in data.tiles) t.id: t};

  for (final layer in sorted) {
    if (!layer.isVisible) continue;
    final alpha = (layer.opacity * 255).round().clamp(0, 255);

    for (int row = 0; row < data.rows; row++) {
      for (int col = 0; col < data.columns; col++) {
        final tileId = layer.tileIndices[row * data.columns + col];
        if (tileId == -1) continue;
        final tile = tileById[tileId];
        if (tile == null) continue;

        final destX = col * data.tileWidth;
        final destY = row * data.tileHeight;

        for (int ty = 0; ty < tile.height; ty++) {
          for (int tx = 0; tx < tile.width; tx++) {
            final src = tile.pixels[ty * tile.width + tx];
            if (src == 0) continue; // fully transparent

            final srcA = ((src >> 24) & 0xFF) * alpha ~/ 255;
            if (srcA == 0) continue;

            final dstIdx = (destY + ty) * w + (destX + tx);
            if (dstIdx < 0 || dstIdx >= out.length) continue;

            if (srcA == 255) {
              out[dstIdx] = (src & 0x00FFFFFF) | (0xFF << 24);
            } else {
              // Alpha-composite over existing pixel
              final dst = out[dstIdx];
              final dstA = (dst >> 24) & 0xFF;
              final outA = srcA + dstA * (255 - srcA) ~/ 255;
              if (outA == 0) continue;
              final r = ((src >> 16 & 0xFF) * srcA +
                      (dst >> 16 & 0xFF) * dstA * (255 - srcA) ~/ 255) ~/
                  outA;
              final g = ((src >> 8 & 0xFF) * srcA +
                      (dst >> 8 & 0xFF) * dstA * (255 - srcA) ~/ 255) ~/
                  outA;
              final b = ((src & 0xFF) * srcA +
                      (dst & 0xFF) * dstA * (255 - srcA) ~/ 255) ~/
                  outA;
              out[dstIdx] = (outA << 24) | (r << 16) | (g << 8) | b;
            }
          }
        }
      }
    }
  }
  return out;
}

/// Renders the composed tilemap as a Flutter [Image] widget plus grid lines.
/// Re-renders only when [data] changes identity (via the notifier).
class TilemapCanvas extends StatefulWidget {
  const TilemapCanvas({
    super.key,
    required this.data,
    required this.activeTool,
    required this.onTilePlaced,
    required this.onTileErased,
    required this.onFillRequested,
    this.showGrid = true,
  });

  final TilemapData data;
  final TilemapTool activeTool;
  final void Function(int col, int row) onTilePlaced;
  final void Function(int col, int row) onTileErased;
  final VoidCallback onFillRequested;
  final bool showGrid;

  @override
  State<TilemapCanvas> createState() => _TilemapCanvasState();
}

class _TilemapCanvasState extends State<TilemapCanvas> {
  ui.Image? _cachedImage;
  TilemapData? _lastData;
  bool _building = false;

  // Hover position in tile coords
  int _hoverCol = -1;
  int _hoverRow = -1;

  @override
  void initState() {
    super.initState();
    _rebuild(widget.data);
  }

  @override
  void didUpdateWidget(TilemapCanvas old) {
    super.didUpdateWidget(old);
    if (widget.data != _lastData) {
      _rebuild(widget.data);
    }
  }

  Future<void> _rebuild(TilemapData data) async {
    if (_building) return;
    _building = true;
    _lastData = data;

    final pixels = _compositeLayers(data);
    final rgba = _argbToRgba(pixels);

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      data.mapWidth,
      data.mapHeight,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final img = await completer.future;

    if (mounted) {
      setState(() {
        _cachedImage?.dispose();
        _cachedImage = img;
        _building = false;
      });
    } else {
      _building = false;
    }
  }

  @override
  void dispose() {
    _cachedImage?.dispose();
    super.dispose();
  }

  // ── Gesture helpers ────────────────────────────────────────────────────────

  void _handleTap(Offset local, Size size) {
    final (col, row) = _toTileCoords(local, size);
    _dispatch(col, row);
  }

  void _handleDrag(Offset local, Size size) {
    final (col, row) = _toTileCoords(local, size);
    if (widget.activeTool == TilemapTool.fill) return; // fill is tap-only
    _dispatch(col, row);
  }

  void _dispatch(int col, int row) {
    switch (widget.activeTool) {
      case TilemapTool.place:
        widget.onTilePlaced(col, row);
      case TilemapTool.erase:
        widget.onTileErased(col, row);
      case TilemapTool.fill:
        widget.onFillRequested();
    }
  }

  (int, int) _toTileCoords(Offset local, Size size) {
    final cellW = size.width / widget.data.columns;
    final cellH = size.height / widget.data.rows;
    final col = (local.dx / cellW).floor().clamp(0, widget.data.columns - 1);
    final row = (local.dy / cellH).floor().clamp(0, widget.data.rows - 1);
    return (col, row);
  }

  void _updateHover(Offset local, Size size) {
    final (col, row) = _toTileCoords(local, size);
    if (col != _hoverCol || row != _hoverRow) {
      setState(() {
        _hoverCol = col;
        _hoverRow = row;
      });
    }
  }

  void _clearHover() {
    if (_hoverCol != -1 || _hoverRow != -1) {
      setState(() {
        _hoverCol = -1;
        _hoverRow = -1;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return MouseRegion(
        cursor: _cursorForTool(),
        onHover: (e) => _updateHover(e.localPosition, size),
        onExit: (_) => _clearHover(),
        child: GestureDetector(
          onTapDown: (d) => _handleTap(d.localPosition, size),
          onPanUpdate: (d) => _handleDrag(d.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _TilemapPainter(
              image: _cachedImage,
              data: widget.data,
              showGrid: widget.showGrid,
              hoverCol: _hoverCol,
              hoverRow: _hoverRow,
              activeTool: widget.activeTool,
            ),
          ),
        ),
      );
    });
  }

  MouseCursor _cursorForTool() {
    switch (widget.activeTool) {
      case TilemapTool.place:
        return SystemMouseCursors.precise;
      case TilemapTool.erase:
        return SystemMouseCursors.precise;
      case TilemapTool.fill:
        return SystemMouseCursors.click;
    }
  }
}

class _TilemapPainter extends CustomPainter {
  final ui.Image? image;
  final TilemapData data;
  final bool showGrid;
  final int hoverCol;
  final int hoverRow;
  final TilemapTool activeTool;

  const _TilemapPainter({
    required this.image,
    required this.data,
    required this.showGrid,
    required this.hoverCol,
    required this.hoverRow,
    required this.activeTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Checkerboard background
    _drawCheckerboard(canvas, size);

    // Tilemap image
    if (image != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        image!.width.toDouble(),
        image!.height.toDouble(),
      );
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(image!, src, dst, Paint()..filterQuality = FilterQuality.none);
    }

    // Grid lines
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Hover highlight
    if (hoverCol >= 0 && hoverRow >= 0) {
      _drawHoverHighlight(canvas, size);
    }
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    const cellSize = 8.0;
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    final light = Paint()..color = const Color(0xFFCCCCCC);
    final dark = Paint()..color = const Color(0xFF999999);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final paint = (r + c) % 2 == 0 ? light : dark;
        canvas.drawRect(
          Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    final cellW = size.width / data.columns;
    final cellH = size.height / data.rows;

    for (int c = 0; c <= data.columns; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int r = 0; r <= data.rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawHoverHighlight(Canvas canvas, Size size) {
    final cellW = size.width / data.columns;
    final cellH = size.height / data.rows;
    final rect = Rect.fromLTWH(
      hoverCol * cellW,
      hoverRow * cellH,
      cellW,
      cellH,
    );

    final fillColor = activeTool == TilemapTool.erase
        ? Colors.red.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.2);

    canvas.drawRect(rect, Paint()..color = fillColor);
    canvas.drawRect(
      rect,
      Paint()
        ..color = activeTool == TilemapTool.erase
            ? Colors.red.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_TilemapPainter old) =>
      image != old.image ||
      data != old.data ||
      showGrid != old.showGrid ||
      hoverCol != old.hoverCol ||
      hoverRow != old.hoverRow ||
      activeTool != old.activeTool;
}

