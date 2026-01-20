import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../tilemap/tilemap_notifier.dart';
import 'tilemap_painters.dart';
import 'tilemap_screen.dart';

/// The main canvas widget for the tilemap editor
class TilemapCanvasWidget extends HookWidget {
  final TileMapState state;
  final TileMapNotifier notifier;
  final BoxConstraints constraints;
  final bool isModifierPressed;
  final ScreenSize screenSize;
  final void Function(int x, int y) onTileTap;
  final void Function(int x, int y) onTileDrag;
  final void Function(int x, int y)? onTileLongPress;

  const TilemapCanvasWidget({
    super.key,
    required this.state,
    required this.notifier,
    required this.constraints,
    required this.isModifierPressed,
    required this.screenSize,
    required this.onTileTap,
    required this.onTileDrag,
    this.onTileLongPress,
  });

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;

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

    // Long press tracking for mobile
    final longPressTimer = useState<int?>(null);
    final longPressPosition = useState<Offset?>(null);

    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // Adjust base tile size based on screen size
    final minTileSize = isMobile ? 24.0 : 16.0;
    final maxTileSize = isMobile ? 48.0 : 64.0;
    final padding = isMobile ? 20.0 : 40.0;

    final baseTileSize = min(
      (availableWidth - padding) / state.gridWidth,
      (availableHeight - padding) / state.gridHeight,
    ).clamp(minTileSize, maxTileSize);

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

    void cancelLongPress() {
      if (longPressTimer.value != null) {
        longPressTimer.value = null;
        longPressPosition.value = null;
      }
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

              if (pointers.value.length == 1) {
                if (isMobile && onTileLongPress != null) {
                  // Start long press timer for mobile
                  longPressPosition.value = event.localPosition;
                  longPressTimer.value = DateTime.now().millisecondsSinceEpoch;
                }

                if (!isModifierPressed) {
                  isPainting.value = true;
                  final tile = screenToTile(event.localPosition);
                  if (tile != null) {
                    lastPaintedCell.value = tile;
                    onTileTap(tile.$1, tile.$2);
                  }
                } else {
                  final tile = screenToTile(event.localPosition);
                  if (tile != null) {
                    onTileTap(tile.$1, tile.$2);
                  }
                }
              }

              if (pointers.value.length == 2) {
                cancelLongPress();
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

              // Cancel long press if moved too far
              if (longPressPosition.value != null) {
                final distance = (event.localPosition - longPressPosition.value!).distance;
                if (distance > 10) {
                  cancelLongPress();
                }
              }

              if (pointers.value.length == 1) {
                if (isModifierPressed) {
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

                // Wider zoom range for touch
                final minScale = isMobile ? 0.3 : 0.5;
                final maxScale = isMobile ? 5.0 : 4.0;

                final newScale = (initialPinchScale.value! * currentDistance / initialPinchDistance.value!)
                    .clamp(minScale, maxScale);

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
              // Check for long press on mobile
              if (isMobile &&
                  longPressTimer.value != null &&
                  longPressPosition.value != null &&
                  onTileLongPress != null) {
                final pressDuration = DateTime.now().millisecondsSinceEpoch - longPressTimer.value!;
                if (pressDuration >= 500) {
                  final tile = screenToTile(longPressPosition.value!);
                  if (tile != null) {
                    onTileLongPress!(tile.$1, tile.$2);
                  }
                }
              }
              cancelLongPress();

              pointers.value = Map.from(pointers.value)..remove(event.pointer);
              if (pointers.value.isEmpty) {
                isPainting.value = false;
                lastPaintedCell.value = null;
              }
              _resetPinchState(initialPinchDistance, initialPinchScale, initialPinchFocalPoint, initialPinchOffset);
            },
            onPointerCancel: (event) {
              cancelLongPress();
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
                final minScale = isMobile ? 0.3 : 0.5;
                final maxScale = isMobile ? 5.0 : 4.0;
                final newScale = (scale.value * scaleFactor).clamp(minScale, maxScale);

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
        // Selected tile preview - adjusted for mobile
        if (state.selectedTile != null && !isMobile)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildSelectedTilePreview(context, state.selectedTile!, colorScheme),
          ),
        // Hover coordinates - hide on mobile
        if (hoverCell.value != null && !isMobile)
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
        // Mobile: Touch hint on first use
        if (isMobile && state.tiles.isNotEmpty && state.selectedTile != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Long press tile to edit • Pinch to zoom',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
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
    final previewSize = isTablet ? 40.0 : 48.0;

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
            width: previewSize,
            height: previewSize,
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
