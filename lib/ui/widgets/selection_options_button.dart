import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core.dart';
import '../../l10n/strings.dart';
import 'theme_selector.dart';

/// A button that shows selection options when a selection is active
class SelectionOptionsButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;

    if (!hasSelection) {
      // No selection, but the clipboard has content — still surface Paste,
      // otherwise there is no way to paste on touch devices (the review
      // "how do I paste after copy with the lasso" bug).
      if (onPaste != null) {
        return isFloating ? _buildFloatingPasteButton(context, theme) : _buildPasteButton(context, theme);
      }
      return const SizedBox.shrink();
    }

    if (isFloating) {
      return _buildFloatingButton(context, theme);
    } else {
      return _buildToolbarButton(context, theme);
    }
  }

  Widget _buildPasteButton(BuildContext context, AppTheme theme) {
    return IconButton(
      icon: Icon(
        Icons.content_paste,
        color: theme.primaryColor,
      ),
      tooltip: Strings.of(context).paste,
      onPressed: onPaste,
    );
  }

  Widget _buildFloatingPasteButton(BuildContext context, AppTheme theme) {
    final g = theme.geometry;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(g.cardRadius),
        border: g.cardBorderWidth > 0 ? Border.all(color: theme.divider, width: g.cardBorderWidth) : null,
        boxShadow: [
          BoxShadow(
            color: g.shadowColor ?? Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.content_paste, color: theme.primaryColor),
        tooltip: Strings.of(context).paste,
        onPressed: onPaste,
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context, AppTheme theme) {
    final g = theme.geometry;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(g.cardRadius),
        border: g.cardBorderWidth > 0 ? Border.all(color: theme.divider, width: g.cardBorderWidth) : null,
        boxShadow: [
          BoxShadow(
            color: g.shadowColor ?? Colors.black.withValues(alpha: 0.1),
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
            icon: Icon(Icons.close, color: theme.error),
            tooltip: Strings.of(context).deselect,
            onPressed: onClearSelection,
          ),
          // Options menu
          PopupMenuButton<String>(
            icon: Icon(Icons.select_all, color: theme.primaryColor),
            tooltip: Strings.of(context).selectionOptions,
            color: theme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(g.dialogRadius)),
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
            onSelected: (value) => _handleMenuSelection(value),
            itemBuilder: (BuildContext context) => _buildMenuItems(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(BuildContext context, AppTheme theme) {
    final g = theme.geometry;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Simple deselect button
        IconButton(
          icon: Icon(Icons.close, color: theme.error),
          tooltip: Strings.of(context).deselect,
          onPressed: onClearSelection,
        ),
        // Options menu
        PopupMenuButton<String>(
          icon: Icon(Icons.select_all, color: theme.primaryColor),
          tooltip: Strings.of(context).selectionOptions,
          color: theme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(g.dialogRadius)),
          constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
          onSelected: (value) => _handleMenuSelection(value),
          itemBuilder: (BuildContext context) => _buildMenuItems(context, theme),
        ),
      ],
    );
  }

  String _cmd(String key) =>
      defaultTargetPlatform == TargetPlatform.macOS ? 'Cmd + $key' : 'Ctrl + $key';

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, AppTheme theme) {
    final s = Strings.of(context);

    Widget item(IconData icon, String label, {Color? color, String? shortcut}) {
      return Row(
        children: [
          Icon(icon, size: 20, color: color ?? theme.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: color ?? theme.textPrimary)),
          ),
          if (shortcut != null) ...[
            const SizedBox(width: 12),
            Text(
              shortcut,
              style: TextStyle(
                color: (color ?? theme.textPrimary).withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    }

    return [
      PopupMenuItem<String>(
        value: 'clear',
        child: item(Icons.clear, s.clearSelection, shortcut: _cmd('D')),
      ),
      if (onInvert != null)
        PopupMenuItem<String>(
          value: 'invert',
          child: item(Icons.flip_to_back, s.invertSelection, shortcut: _cmd('Shift + I')),
        ),
      if (onGrow != null)
        PopupMenuItem<String>(
          value: 'grow',
          child: item(Icons.open_in_full, s.growSelectionOnePixel, shortcut: _cmd('Shift + G')),
        ),
      if (onShrink != null)
        PopupMenuItem<String>(
          value: 'shrink',
          child: item(Icons.close_fullscreen, s.shrinkSelectionOnePixel, shortcut: _cmd('Shift + H')),
        ),
      if (onRotate90 != null) ...[
        PopupMenuDivider(color: theme.divider),
        PopupMenuItem<String>(
          value: 'rotate90',
          child: item(Icons.rotate_90_degrees_ccw, s.rotate90, shortcut: 'Shift + R'),
        ),
      ],
      if (onRotate180 != null) ...[
        PopupMenuItem<String>(
          value: 'rotate180',
          child: item(Icons.rotate_left, s.rotate180, shortcut: 'Shift + X'),
        ),
        PopupMenuDivider(color: theme.divider),
      ],
      if (onFlipHorizontal != null)
        PopupMenuItem<String>(
          value: 'flipH',
          child: item(Icons.flip, s.flipHorizontal, shortcut: 'Shift + H'),
        ),
      if (onFlipVertical != null) ...[
        PopupMenuItem<String>(
          value: 'flipV',
          child: Row(
            children: [
              RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.flip, size: 20, color: theme.textPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.flipVertical, style: TextStyle(color: theme.textPrimary)),
              ),
              const SizedBox(width: 12),
              Text(
                'Shift + V',
                style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ),
        PopupMenuDivider(color: theme.divider),
      ],
      if (onCutToNewLayer != null)
        PopupMenuItem<String>(
          value: 'cutNewLayer',
          child: item(Icons.cut, s.cutToNewLayer),
        ),
      if (onCopyToNewLayer != null) ...[
        PopupMenuItem<String>(
          value: 'copyNewLayer',
          child: item(Icons.copy, s.copyToNewLayer),
        ),
        PopupMenuDivider(color: theme.divider),
      ],
      if (onCut != null)
        PopupMenuItem<String>(
          value: 'cut',
          child: item(Icons.content_cut, s.cut, shortcut: _cmd('X')),
        ),
      if (onCopy != null)
        PopupMenuItem<String>(
          value: 'copy',
          child: item(Icons.content_copy, s.copy, shortcut: _cmd('C')),
        ),
      if (onPaste != null)
        PopupMenuItem<String>(
          value: 'paste',
          child: item(Icons.content_paste, s.paste, shortcut: _cmd('V')),
        ),
      if (onDelete != null)
        PopupMenuItem<String>(
          value: 'delete',
          child: item(Icons.delete, s.clearArea, color: theme.error, shortcut: 'Del'),
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
      case 'paste':
        onPaste?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
