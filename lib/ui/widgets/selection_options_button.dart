import 'package:flutter/material.dart';

/// A button that shows selection options when a selection is active
class SelectionOptionsButton extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback? onClearSelection;
  final VoidCallback? onRotate90;
  final VoidCallback? onRotate180;
  final VoidCallback? onFlipHorizontal;
  final VoidCallback? onFlipVertical;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final bool isFloating;

  const SelectionOptionsButton({
    super.key,
    required this.hasSelection,
    this.onClearSelection,
    this.onRotate90,
    this.onRotate180,
    this.onFlipHorizontal,
    this.onFlipVertical,
    this.onCut,
    this.onCopy,
    this.onDelete,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasSelection) {
      return const SizedBox.shrink();
    }

    if (isFloating) {
      return _buildFloatingButton(context);
    } else {
      return _buildToolbarButton(context);
    }
  }

  Widget _buildFloatingButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple deselect button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Deselect',
            onPressed: onClearSelection,
          ),
          // Options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.select_all, color: Colors.blue),
            tooltip: 'Selection Options',
            onSelected: (value) => _handleMenuSelection(value),
            itemBuilder: (BuildContext context) => _buildMenuItems(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Simple deselect button
        IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Deselect',
          onPressed: onClearSelection,
        ),
        // Options menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.select_all,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Selection Options',
          onSelected: (value) => _handleMenuSelection(value),
          itemBuilder: (BuildContext context) => _buildMenuItems(context),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return [
      const PopupMenuItem<String>(
        value: 'clear',
        child: Row(
          children: [
            Icon(Icons.clear, size: 20),
            SizedBox(width: 8),
            Text('Clear Selection'),
          ],
        ),
      ),
      if (onRotate90 != null) ...[
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'rotate90',
          child: Row(
            children: [
              Icon(Icons.rotate_90_degrees_ccw, size: 20),
              SizedBox(width: 8),
              Text('Rotate 90°'),
            ],
          ),
        ),
      ],
      if (onRotate180 != null) ...[
        const PopupMenuItem<String>(
          value: 'rotate180',
          child: Row(
            children: [
              Icon(Icons.rotate_left, size: 20),
              SizedBox(width: 8),
              Text('Rotate 180°'),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
      if (onFlipHorizontal != null)
        const PopupMenuItem<String>(
          value: 'flipH',
          child: Row(
            children: [
              Icon(Icons.flip, size: 20),
              SizedBox(width: 8),
              Text('Flip Horizontal'),
            ],
          ),
        ),
      if (onFlipVertical != null) ...[
        const PopupMenuItem<String>(
          value: 'flipV',
          child: Row(
            children: [
              RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.flip, size: 20),
              ),
              SizedBox(width: 8),
              Text('Flip Vertical'),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
      if (onCut != null)
        const PopupMenuItem<String>(
          value: 'cut',
          child: Row(
            children: [
              Icon(Icons.content_cut, size: 20),
              SizedBox(width: 8),
              Text('Cut'),
            ],
          ),
        ),
      if (onCopy != null)
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 20),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
      if (onDelete != null)
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
    ];
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'clear':
        onClearSelection?.call();
        break;
      case 'rotate90':
        onRotate90?.call();
        break;
      case 'rotate180':
        onRotate180?.call();
        break;
      case 'flipH':
        onFlipHorizontal?.call();
        break;
      case 'flipV':
        onFlipVertical?.call();
        break;
      case 'cut':
        onCut?.call();
        break;
      case 'copy':
        onCopy?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
