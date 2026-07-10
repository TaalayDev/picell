import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

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
  final VoidCallback? onPaste;
  final VoidCallback? onDelete; // Usually "Clear Area"
  final VoidCallback? onCutToNewLayer;
  final VoidCallback? onCopyToNewLayer;
  final VoidCallback? onInvert;
  final VoidCallback? onGrow;
  final VoidCallback? onShrink;
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
    this.onPaste,
    this.onDelete,
    this.onCutToNewLayer,
    this.onCopyToNewLayer,
    this.onInvert,
    this.onGrow,
    this.onShrink,
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
            color: Colors.black.withValues(alpha: 0.1),
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
            tooltip: Strings.of(context).deselect,
            onPressed: onClearSelection,
          ),
          // Options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.select_all, color: Colors.blue),
            tooltip: Strings.of(context).selectionOptions,
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
          tooltip: Strings.of(context).deselect,
          onPressed: onClearSelection,
        ),
        // Options menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.select_all,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: Strings.of(context).selectionOptions,
          onSelected: (value) => _handleMenuSelection(value),
          itemBuilder: (BuildContext context) => _buildMenuItems(context),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final s = Strings.of(context);

    return [
      PopupMenuItem<String>(
        value: 'clear',
        child: Row(
          children: [
            const Icon(Icons.clear, size: 20),
            const SizedBox(width: 8),
            Text(s.clearSelection),
          ],
        ),
      ),
      if (onInvert != null)
        PopupMenuItem<String>(
          value: 'invert',
          child: Row(
            children: [
              const Icon(Icons.flip_to_back, size: 20),
              const SizedBox(width: 8),
              Text(s.invertSelection),
            ],
          ),
        ),
      if (onGrow != null)
        PopupMenuItem<String>(
          value: 'grow',
          child: Row(
            children: [
              const Icon(Icons.open_in_full, size: 20),
              const SizedBox(width: 8),
              Text(s.growSelectionOnePixel),
            ],
          ),
        ),
      if (onShrink != null)
        PopupMenuItem<String>(
          value: 'shrink',
          child: Row(
            children: [
              const Icon(Icons.close_fullscreen, size: 20),
              const SizedBox(width: 8),
              Text(s.shrinkSelectionOnePixel),
            ],
          ),
        ),
      if (onRotate90 != null) ...[
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'rotate90',
          child: Row(
            children: [
              const Icon(Icons.rotate_90_degrees_ccw, size: 20),
              const SizedBox(width: 8),
              Text(s.rotate90),
            ],
          ),
        ),
      ],
      if (onRotate180 != null) ...[
        PopupMenuItem<String>(
          value: 'rotate180',
          child: Row(
            children: [
              const Icon(Icons.rotate_left, size: 20),
              const SizedBox(width: 8),
              Text(s.rotate180),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
      if (onFlipHorizontal != null)
        PopupMenuItem<String>(
          value: 'flipH',
          child: Row(
            children: [
              const Icon(Icons.flip, size: 20),
              const SizedBox(width: 8),
              Text(s.flipHorizontal),
            ],
          ),
        ),
      if (onFlipVertical != null) ...[
        PopupMenuItem<String>(
          value: 'flipV',
          child: Row(
            children: [
              const RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.flip, size: 20),
              ),
              const SizedBox(width: 8),
              Text(s.flipVertical),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
      if (onCutToNewLayer != null)
        PopupMenuItem<String>(
          value: 'cutNewLayer',
          child: Row(
            children: [
              const Icon(Icons.cut, size: 20),
              const SizedBox(width: 8),
              Text(s.cutToNewLayer),
            ],
          ),
        ),
      if (onCopyToNewLayer != null) ...[
        PopupMenuItem<String>(
          value: 'copyNewLayer',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 8),
              Text(s.copyToNewLayer),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
      if (onCut != null)
        PopupMenuItem<String>(
          value: 'cut',
          child: Row(
            children: [
              const Icon(Icons.content_cut, size: 20),
              const SizedBox(width: 8),
              Text(s.cut),
            ],
          ),
        ),
      if (onCopy != null)
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              const Icon(Icons.content_copy, size: 20),
              const SizedBox(width: 8),
              Text(s.copy),
            ],
          ),
        ),
      if (onDelete != null)
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              Text(s.clearArea, style: const TextStyle(color: Colors.red)),
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
      case 'invert':
        onInvert?.call();
        break;
      case 'grow':
        onGrow?.call();
        break;
      case 'shrink':
        onShrink?.call();
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
      case 'cutNewLayer':
        onCutToNewLayer?.call();
        break;
      case 'copyNewLayer':
        onCopyToNewLayer?.call();
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
