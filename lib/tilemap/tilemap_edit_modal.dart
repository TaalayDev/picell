import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../ui/screens/tilemap/tilemap_painters.dart';
import 'tilemap_notifier.dart';

class TileEditModal extends HookWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final int tileWidth;
  final int tileHeight;

  const TileEditModal({
    super.key,
    required this.state,
    required this.notifier,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDrawing = useState(false);
    final lastPixel = useState<(int, int)?>(null);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, colorScheme),
            Expanded(
              child: Row(
                children: [
                  _buildToolsPanel(context, colorScheme),
                  Expanded(
                    child: _buildCanvasArea(
                      context,
                      colorScheme,
                      isDrawing,
                      lastPixel,
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Edit Tile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.canEditUndo ? notifier.editUndo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: state.canEditRedo ? notifier.editRedo : null,
            tooltip: 'Redo',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: notifier.cancelTileEdit,
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildToolButton(
            context,
            TileEditTool.pencil,
            Icons.edit,
            'Pencil',
            colorScheme,
          ),
          const SizedBox(height: 4),
          _buildToolButton(
            context,
            TileEditTool.eraser,
            Icons.auto_fix_high,
            'Eraser',
            colorScheme,
          ),
          const SizedBox(height: 4),
          _buildToolButton(
            context,
            TileEditTool.fill,
            Icons.format_color_fill,
            'Fill',
            colorScheme,
          ),
          const SizedBox(height: 4),
          _buildToolButton(
            context,
            TileEditTool.eyedropper,
            Icons.colorize,
            'Pick Color',
            colorScheme,
          ),
          const Divider(height: 16),
          _buildColorPreview(colorScheme),
          const SizedBox(height: 8),
          _buildQuickColors(colorScheme),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    TileEditTool tool,
    IconData icon,
    String tooltip,
    ColorScheme colorScheme,
  ) {
    final isSelected = state.editTool == tool;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => notifier.setEditTool(tool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview(ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(state.editColor),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
    );
  }

  Widget _buildQuickColors(ColorScheme colorScheme) {
    final colors = [
      0xFF000000,
      0xFFFFFFFF,
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFFFF00,
      0xFFFF00FF,
      0xFF00FFFF,
    ];

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: colors.map((color) {
        final isSelected = state.editColor == color;
        return GestureDetector(
          onTap: () => notifier.setEditColor(color),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Color(color),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCanvasArea(
    BuildContext context,
    ColorScheme colorScheme,
    ValueNotifier<bool> isDrawing,
    ValueNotifier<(int, int)?> lastPixel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Edge size shows 2 pixels worth of neighbor
        const edgePixels = 2;
        final totalPixels = max(tileWidth, tileHeight) + (edgePixels * 2);

        final availableSize = min(constraints.maxWidth, constraints.maxHeight) - 32;
        final pixelSize = availableSize / totalPixels;
        final edgeSize = pixelSize * edgePixels;
        final mainSize = availableSize - (edgeSize * 2);

        final topNeighbor = notifier.getNeighborPixels(0, -1);
        final bottomNeighbor = notifier.getNeighborPixels(0, 1);
        final leftNeighbor = notifier.getNeighborPixels(-1, 0);
        final rightNeighbor = notifier.getNeighborPixels(1, 0);

        return Center(
          child: Container(
            width: availableSize,
            height: availableSize,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Stack(
              children: [
                // Top edge neighbor (show bottom row of top neighbor)
                if (topNeighbor != null)
                  Positioned(
                    left: edgeSize,
                    top: 0,
                    width: mainSize,
                    height: edgeSize,
                    child: _buildEdgeNeighborPreview(
                      topNeighbor,
                      _Edge.top,
                      edgePixels,
                    ),
                  ),
                // Bottom edge neighbor (show top row of bottom neighbor)
                if (bottomNeighbor != null)
                  Positioned(
                    left: edgeSize,
                    bottom: 0,
                    width: mainSize,
                    height: edgeSize,
                    child: _buildEdgeNeighborPreview(
                      bottomNeighbor,
                      _Edge.bottom,
                      edgePixels,
                    ),
                  ),
                // Left edge neighbor (show right column of left neighbor)
                if (leftNeighbor != null)
                  Positioned(
                    left: 0,
                    top: edgeSize,
                    width: edgeSize,
                    height: mainSize,
                    child: _buildEdgeNeighborPreview(
                      leftNeighbor,
                      _Edge.left,
                      edgePixels,
                    ),
                  ),
                // Right edge neighbor (show left column of right neighbor)
                if (rightNeighbor != null)
                  Positioned(
                    right: 0,
                    top: edgeSize,
                    width: edgeSize,
                    height: mainSize,
                    child: _buildEdgeNeighborPreview(
                      rightNeighbor,
                      _Edge.right,
                      edgePixels,
                    ),
                  ),
                // Main editing area
                Positioned(
                  left: edgeSize,
                  top: edgeSize,
                  width: mainSize,
                  height: mainSize,
                  child: _buildEditableCanvas(
                    colorScheme,
                    isDrawing,
                    lastPixel,
                    mainSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEdgeNeighborPreview(
    Uint32List pixels,
    _Edge edge,
    int edgePixels,
  ) {
    return Opacity(
      opacity: 0.6,
      child: CustomPaint(
        painter: _EdgeNeighborPainter(
          pixels: pixels,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          edge: edge,
          edgePixels: edgePixels,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildEditableCanvas(
    ColorScheme colorScheme,
    ValueNotifier<bool> isDrawing,
    ValueNotifier<(int, int)?> lastPixel,
    double canvasSize,
  ) {
    if (state.editingPixels == null) return const SizedBox();

    final pixelSize = canvasSize / max(tileWidth, tileHeight);

    return GestureDetector(
      onTapDown: (details) {
        notifier.editStartDrawing();
        final pos = _getPixelPos(details.localPosition, pixelSize);
        if (pos != null) {
          lastPixel.value = pos;
          notifier.editDrawPixel(pos.$1, pos.$2, tileWidth, tileHeight);
        }
      },
      onPanStart: (details) {
        isDrawing.value = true;
        notifier.editStartDrawing();
        lastPixel.value = null;
        final pos = _getPixelPos(details.localPosition, pixelSize);
        if (pos != null) {
          lastPixel.value = pos;
          notifier.editDrawPixel(pos.$1, pos.$2, tileWidth, tileHeight);
        }
      },
      onPanUpdate: (details) {
        if (isDrawing.value) {
          final pos = _getPixelPos(details.localPosition, pixelSize);
          if (pos != null && pos != lastPixel.value) {
            if (lastPixel.value != null) {
              _drawLine(lastPixel.value!, pos);
            } else {
              notifier.editDrawPixel(pos.$1, pos.$2, tileWidth, tileHeight);
            }
            lastPixel.value = pos;
          }
        }
      },
      onPanEnd: (_) {
        isDrawing.value = false;
        lastPixel.value = null;
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CustomPaint(
          painter: TilePixelsPainter(
            pixels: state.editingPixels!,
            width: tileWidth,
            height: tileHeight,
            showGrid: true,
          ),
          size: Size(canvasSize, canvasSize),
        ),
      ),
    );
  }

  (int, int)? _getPixelPos(Offset offset, double pixelSize) {
    final x = (offset.dx / pixelSize).floor();
    final y = (offset.dy / pixelSize).floor();
    if (x >= 0 && x < tileWidth && y >= 0 && y < tileHeight) {
      return (x, y);
    }
    return null;
  }

  void _drawLine((int, int) from, (int, int) to) {
    int x0 = from.$1, y0 = from.$2;
    int x1 = to.$1, y1 = to.$2;

    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    while (true) {
      notifier.editDrawPixel(x0, y0, tileWidth, tileHeight);

      if (x0 == x1 && y0 == y1) break;

      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: notifier.cancelTileEdit,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: notifier.saveTileEdit,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

enum _Edge { top, bottom, left, right }

/// Paints edge neighbor preview showing the adjacent pixels of neighboring tiles
class _EdgeNeighborPainter extends CustomPainter {
  final Uint32List pixels;
  final int tileWidth;
  final int tileHeight;
  final _Edge edge;
  final int edgePixels;

  _EdgeNeighborPainter({
    required this.pixels,
    required this.tileWidth,
    required this.tileHeight,
    required this.edge,
    required this.edgePixels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw checkerboard background
    final lightPaint = Paint()..color = const Color(0xFFD0D0D0);
    final darkPaint = Paint()..color = const Color(0xFFB0B0B0);

    switch (edge) {
      case _Edge.top:
        // Show bottom rows of top neighbor
        final pixelW = size.width / tileWidth;
        final pixelH = size.height / edgePixels;
        _drawCheckerboard(canvas, size, pixelW, pixelH, lightPaint, darkPaint);
        for (int py = 0; py < edgePixels; py++) {
          final srcY = tileHeight - edgePixels + py;
          for (int px = 0; px < tileWidth; px++) {
            _drawPixel(canvas, px, py, srcY * tileWidth + px, pixelW, pixelH);
          }
        }
        break;
      case _Edge.bottom:
        // Show top rows of bottom neighbor
        final pixelW = size.width / tileWidth;
        final pixelH = size.height / edgePixels;
        _drawCheckerboard(canvas, size, pixelW, pixelH, lightPaint, darkPaint);
        for (int py = 0; py < edgePixels; py++) {
          for (int px = 0; px < tileWidth; px++) {
            _drawPixel(canvas, px, py, py * tileWidth + px, pixelW, pixelH);
          }
        }
        break;
      case _Edge.left:
        // Show right columns of left neighbor
        final pixelW = size.width / edgePixels;
        final pixelH = size.height / tileHeight;
        _drawCheckerboard(canvas, size, pixelW, pixelH, lightPaint, darkPaint);
        for (int py = 0; py < tileHeight; py++) {
          for (int px = 0; px < edgePixels; px++) {
            final srcX = tileWidth - edgePixels + px;
            _drawPixel(canvas, px, py, py * tileWidth + srcX, pixelW, pixelH);
          }
        }
        break;
      case _Edge.right:
        // Show left columns of right neighbor
        final pixelW = size.width / edgePixels;
        final pixelH = size.height / tileHeight;
        _drawCheckerboard(canvas, size, pixelW, pixelH, lightPaint, darkPaint);
        for (int py = 0; py < tileHeight; py++) {
          for (int px = 0; px < edgePixels; px++) {
            _drawPixel(canvas, px, py, py * tileWidth + px, pixelW, pixelH);
          }
        }
        break;
    }
  }

  void _drawCheckerboard(Canvas canvas, Size size, double pixelW, double pixelH, Paint lightPaint, Paint darkPaint) {
    final rows = (size.height / pixelH).ceil();
    final cols = (size.width / pixelW).ceil();
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final isLight = (x + y) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x * pixelW, y * pixelH, pixelW, pixelH),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  void _drawPixel(Canvas canvas, int destX, int destY, int srcIndex, double pixelW, double pixelH) {
    if (srcIndex < 0 || srcIndex >= pixels.length) return;
    final color = Color(pixels[srcIndex]);
    if (color.alpha > 0) {
      final paint = Paint()..color = color;
      canvas.drawRect(
        Rect.fromLTWH(
          destX * pixelW,
          destY * pixelH,
          pixelW + 0.5,
          pixelH + 0.5,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EdgeNeighborPainter oldDelegate) => true;
}
