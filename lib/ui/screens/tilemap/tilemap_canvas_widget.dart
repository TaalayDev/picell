import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

    final offset = useState(Offset.zero);
    final scale = useState(1.0);
    final pointers = useState<Map<int, Offset>>({});
    final initialPinchDistance = useState<double?>(null);
    final initialPinchScale = useState<double?>(null);
    final initialPinchFocalPoint = useState<Offset?>(null);
    final initialPinchOffset = useState<Offset?>(null);

    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    final baseTileSize = min(
      (availableWidth - 40) / state.gridWidth,
      (availableHeight - 40) / state.gridHeight,
    ).clamp(16.0, 64.0);

    final tileSize = baseTileSize * state.zoom * scale.value;
    final canvasWidth = state.gridWidth * tileSize;
    final canvasHeight = state.gridHeight * tileSize;

    final canvasLeft = (availableWidth - canvasWidth) / 2 + offset.value.dx;
    final canvasTop = (availableHeight - canvasHeight) / 2 + offset.value.dy;

    (int, int)? screenToTile(Offset screenPos) {
      final localX = screenPos.dx - canvasLeft;
      final localY = screenPos.dy - canvasTop;
      final x = (localX / tileSize).floor();
      final y = (localY / tileSize).floor();
      if (x >= 0 && x < state.gridWidth && y >= 0 && y < state.gridHeight) {
        return (x, y);
      }
      return null;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BackgroundPatternPainter(colorScheme: colorScheme),
          ),
        ),
        Positioned.fill(
          child: Listener(
            onPointerDown: (event) {
              pointers.value = {...pointers.value, event.pointer: event.position};

              if (pointers.value.length == 1 && !isModifierPressed) {
                isPainting.value = true;
                final tile = screenToTile(event.localPosition);
                if (tile != null) {
                  lastPaintedCell.value = tile;
                  onTileTap(tile.$1, tile.$2);
                }
              }
              if (pointers.value.length == 1 && isModifierPressed) {
                final tile = screenToTile(event.localPosition);
                if (tile != null) {
                  onTileTap(tile.$1, tile.$2);
                }
              }

              if (pointers.value.length == 2) {
                isPainting.value = false;
                lastPaintedCell.value = null;
                final points = pointers.value.values.toList();
                initialPinchDistance.value = (points[0] - points[1]).distance;
                initialPinchScale.value = scale.value;
                initialPinchFocalPoint.value = (points[0] + points[1]) / 2;
                initialPinchOffset.value = offset.value;
              }
            },
            onPointerMove: (event) {
              if (!pointers.value.containsKey(event.pointer)) return;

              pointers.value = {...pointers.value, event.pointer: event.position};

              if (pointers.value.length == 1) {
                if (isModifierPressed) {
                  // offset.value += event.delta;
                  onTileTap(
                    -event.delta.dx ~/ tileSize,
                    -event.delta.dy ~/ tileSize,
                  );
                } else if (isPainting.value) {
                  final tile = screenToTile(event.localPosition);
                  if (tile != null && lastPaintedCell.value != tile) {
                    lastPaintedCell.value = tile;
                    onTileDrag(tile.$1, tile.$2);
                  }
                }
              } else if (pointers.value.length == 2 &&
                  initialPinchDistance.value != null &&
                  initialPinchScale.value != null &&
                  initialPinchFocalPoint.value != null &&
                  initialPinchOffset.value != null) {
                final points = pointers.value.values.toList();
                final currentDistance = (points[0] - points[1]).distance;
                final currentFocalPoint = (points[0] + points[1]) / 2;

                final newScale =
                    (initialPinchScale.value! * currentDistance / initialPinchDistance.value!).clamp(0.5, 4.0);

                final focalDelta = currentFocalPoint - initialPinchFocalPoint.value!;
                final scaleDelta = newScale / initialPinchScale.value!;

                final centerX = availableWidth / 2;
                final centerY = availableHeight / 2;
                final focalRelativeToCenter = initialPinchFocalPoint.value! - Offset(centerX, centerY);

                final newOffset =
                    initialPinchOffset.value! * scaleDelta + focalRelativeToCenter * (1 - scaleDelta) + focalDelta;

                scale.value = newScale;
                offset.value = newOffset;
              }
            },
            onPointerUp: (event) {
              pointers.value = Map.from(pointers.value)..remove(event.pointer);
              if (pointers.value.isEmpty) {
                isPainting.value = false;
                lastPaintedCell.value = null;
              }
              _resetPinchState(initialPinchDistance, initialPinchScale, initialPinchFocalPoint, initialPinchOffset);
            },
            onPointerCancel: (event) {
              pointers.value = Map.from(pointers.value)..remove(event.pointer);
              if (pointers.value.isEmpty) {
                isPainting.value = false;
                lastPaintedCell.value = null;
              }
              _resetPinchState(initialPinchDistance, initialPinchScale, initialPinchFocalPoint, initialPinchOffset);
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final scaleFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
                final newScale = (scale.value * scaleFactor).clamp(0.5, 4.0);

                final focalPoint = event.localPosition;
                final centerX = availableWidth / 2;
                final centerY = availableHeight / 2;
                final focalRelativeToCenter = focalPoint - Offset(centerX, centerY);

                final scaleDelta = newScale / scale.value;
                offset.value = offset.value * scaleDelta + focalRelativeToCenter * (1 - scaleDelta);

                scale.value = newScale;
              }
            },
            onPointerHover: (event) {
              hoverCell.value = screenToTile(event.localPosition);
            },
            child: MouseRegion(
              cursor: isModifierPressed ? SystemMouseCursors.grab : SystemMouseCursors.basic,
              onExit: (_) => hoverCell.value = null,
              child: ClipRect(
                child: CustomPaint(
                  painter: _TransformedTilemapPainter(
                    state: state,
                    notifier: notifier,
                    tileSize: tileSize,
                    canvasLeft: canvasLeft,
                    canvasTop: canvasTop,
                    hoverCell: hoverCell.value,
                    colorScheme: colorScheme,
                    isModifierPressed: isModifierPressed,
                  ),
                  size: Size(availableWidth, availableHeight),
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

  void _resetPinchState(
    ValueNotifier<double?> initialPinchDistance,
    ValueNotifier<double?> initialPinchScale,
    ValueNotifier<Offset?> initialPinchFocalPoint,
    ValueNotifier<Offset?> initialPinchOffset,
  ) {
    initialPinchDistance.value = null;
    initialPinchScale.value = null;
    initialPinchFocalPoint.value = null;
    initialPinchOffset.value = null;
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
}

class _TransformedTilemapPainter extends CustomPainter {
  final TileMapState state;
  final TileMapNotifier notifier;
  final double tileSize;
  final double canvasLeft;
  final double canvasTop;
  final (int, int)? hoverCell;
  final ColorScheme colorScheme;
  final bool isModifierPressed;

  _TransformedTilemapPainter({
    required this.state,
    required this.notifier,
    required this.tileSize,
    required this.canvasLeft,
    required this.canvasTop,
    required this.hoverCell,
    required this.colorScheme,
    required this.isModifierPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final canvasWidth = state.gridWidth * tileSize;
    final canvasHeight = state.gridHeight * tileSize;

    canvas.save();
    canvas.translate(canvasLeft, canvasTop);

    final tilemapPainter = TilemapPainter(
      state: state,
      notifier: notifier,
      tileSize: tileSize,
      hoverCell: hoverCell,
      colorScheme: colorScheme,
      isModifierPressed: isModifierPressed,
    );
    tilemapPainter.paint(canvas, Size(canvasWidth, canvasHeight));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TransformedTilemapPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.canvasLeft != canvasLeft ||
        oldDelegate.canvasTop != canvasTop ||
        oldDelegate.hoverCell != hoverCell ||
        oldDelegate.isModifierPressed != isModifierPressed;
  }
}
