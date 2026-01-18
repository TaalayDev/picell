import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../tilemap/tilemap_notifier.dart';
import 'tilemap_painters.dart';

/// The main canvas widget for the tilemap editor
class TilemapCanvasWidget extends HookWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final BoxConstraints constraints;
  final bool isModifierPressed;
  final void Function(int x, int y) onTileTap;
  final void Function(int x, int y) onTileDrag;

  const TilemapCanvasWidget({
    super.key,
    required this.state,
    required this.notifier,
    required this.constraints,
    required this.isModifierPressed,
    required this.onTileTap,
    required this.onTileDrag,
  });

  @override
  Widget build(BuildContext context) {
    final isPainting = useState(false);
    final lastPaintedCell = useState<(int, int)?>(null);
    final hoverCell = useState<(int, int)?>(null);
    final colorScheme = Theme.of(context).colorScheme;

    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    final baseTileSize = min(
      (availableWidth - 40) / state.gridWidth,
      (availableHeight - 40) / state.gridHeight,
    ).clamp(16.0, 64.0);

    final tileSize = baseTileSize * state.zoom;
    final canvasWidth = state.gridWidth * tileSize;
    final canvasHeight = state.gridHeight * tileSize;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BackgroundPatternPainter(colorScheme: colorScheme),
          ),
        ),
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(100),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: MouseRegion(
                  onHover: (event) {
                    final x = (event.localPosition.dx / tileSize).floor();
                    final y = (event.localPosition.dy / tileSize).floor();
                    if (x >= 0 && x < state.gridWidth && y >= 0 && y < state.gridHeight) {
                      hoverCell.value = (x, y);
                    } else {
                      hoverCell.value = null;
                    }
                  },
                  onExit: (_) => hoverCell.value = null,
                  cursor: isModifierPressed ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTapDown: (details) {
                      final x = (details.localPosition.dx / tileSize).floor();
                      final y = (details.localPosition.dy / tileSize).floor();
                      lastPaintedCell.value = (x, y);
                      onTileTap(x, y);
                    },
                    onPanStart: (details) {
                      if (!isModifierPressed) {
                        isPainting.value = true;
                        lastPaintedCell.value = null;
                        _handlePointer(details.localPosition, tileSize, lastPaintedCell);
                      }
                    },
                    onPanUpdate: (details) {
                      if (isPainting.value && !isModifierPressed) {
                        _handlePointer(details.localPosition, tileSize, lastPaintedCell);
                      }
                    },
                    onPanEnd: (_) {
                      isPainting.value = false;
                      lastPaintedCell.value = null;
                    },
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: CustomPaint(
                        painter: TilemapPainter(
                          state: state,
                          notifier: notifier,
                          tileSize: tileSize,
                          hoverCell: hoverCell.value,
                          colorScheme: colorScheme,
                          isModifierPressed: isModifierPressed,
                        ),
                        size: Size(canvasWidth, canvasHeight),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (state.selectedTile != null)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildSelectedTilePreview(context, state.selectedTile!, colorScheme),
          ),
        if (hoverCell.value != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'X: ${hoverCell.value!.$1}, Y: ${hoverCell.value!.$2}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedTilePreview(BuildContext context, SavedTile tile, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Selected', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(
                painter: TilePreviewPainter(
                  pixels: tile.pixels,
                  width: tile.width,
                  height: tile.height,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePointer(Offset position, double tileSize, ValueNotifier<(int, int)?> lastPainted) {
    final x = (position.dx / tileSize).floor();
    final y = (position.dy / tileSize).floor();

    if (lastPainted.value == (x, y)) return;
    lastPainted.value = (x, y);

    if (x >= 0 && x < state.gridWidth && y >= 0 && y < state.gridHeight) {
      onTileDrag(x, y);
    }
  }
}
