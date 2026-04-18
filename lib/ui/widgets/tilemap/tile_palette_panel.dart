import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/models/tilemap_model.dart';

/// Sidebar panel showing the tile palette. Lets the user select, add, or
/// delete tiles. Tapping a tile selects it; long-pressing opens a context menu.
class TilePalettePanel extends StatelessWidget {
  const TilePalettePanel({
    super.key,
    required this.tiles,
    required this.selectedIndex,
    required this.onTileSelected,
    required this.onAddTile,
    required this.onDeleteTile,
    required this.onEditTile,
  });

  final List<Tile> tiles;
  final int selectedIndex;
  final void Function(int index) onTileSelected;
  final VoidCallback onAddTile;
  final void Function(int tileId) onDeleteTile;
  final void Function(Tile tile) onEditTile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Tiles',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  tooltip: 'Add tile',
                  onPressed: onAddTile,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          // Tile grid
          Expanded(
            child: tiles.isEmpty
                ? Center(
                    child: Text(
                      'No tiles yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: tiles.length,
                    itemBuilder: (context, index) {
                      final tile = tiles[index];
                      final isSelected = index == selectedIndex;
                      return _TileThumbnail(
                        tile: tile,
                        isSelected: isSelected,
                        onTap: () => onTileSelected(index),
                        onEdit: () => onEditTile(tile),
                        onDelete: tiles.length > 1 ? () => onDeleteTile(tile.id) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TileThumbnail extends StatelessWidget {
  const _TileThumbnail({
    required this.tile,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  final Tile tile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Checkerboard background
              CustomPaint(painter: _CheckerPainter()),
              // Tile pixels
              _TilePixelPainter(tile: tile),
              // Name label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                  child: Text(
                    tile.name,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromDirectional(
        textDirection: Directionality.of(context),
        start: 0,
        top: 0,
        end: 0,
        bottom: 0,
      ),
      items: [
        PopupMenuItem(onTap: onEdit, child: const Text('Edit tile')),
        if (onDelete != null)
          PopupMenuItem(
            onTap: onDelete,
            child: const Text('Delete tile', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 4.0;
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
  bool shouldRepaint(_CheckerPainter _) => false;
}

/// Paints a [Tile]'s pixels asynchronously, similar to the tilemap canvas.
class _TilePixelPainter extends StatefulWidget {
  const _TilePixelPainter({required this.tile});
  final Tile tile;

  @override
  State<_TilePixelPainter> createState() => _TilePixelPainterState();
}

class _TilePixelPainterState extends State<_TilePixelPainter> {
  ui.Image? _image;
  Tile? _lastTile;

  @override
  void initState() {
    super.initState();
    _buildImage(widget.tile);
  }

  @override
  void didUpdateWidget(_TilePixelPainter old) {
    super.didUpdateWidget(old);
    if (widget.tile != _lastTile) _buildImage(widget.tile);
  }

  Future<void> _buildImage(Tile tile) async {
    _lastTile = tile;
    final rgba = Uint8List(tile.pixels.length * 4);
    for (int i = 0; i < tile.pixels.length; i++) {
      final p = tile.pixels[i];
      rgba[i * 4] = (p >> 16) & 0xFF;
      rgba[i * 4 + 1] = (p >> 8) & 0xFF;
      rgba[i * 4 + 2] = p & 0xFF;
      rgba[i * 4 + 3] = (p >> 24) & 0xFF;
    }

    ui.decodeImageFromPixels(rgba, tile.width, tile.height, ui.PixelFormat.rgba8888, (img) {
      if (mounted) {
        setState(() {
          _image?.dispose();
          _image = img;
        });
      }
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return const SizedBox.shrink();
    return CustomPaint(
      painter: _ImagePainter(image: _image!),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  const _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter old) => image != old.image;
}
