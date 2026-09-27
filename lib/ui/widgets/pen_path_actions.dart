import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/strings.dart';
import 'theme_selector.dart';

/// Finish/cancel controls for an in-progress Pen path. Mirrors the selection
/// controls: plain icon buttons in the top bar and a raised group on mobile.
class PenPathActions extends ConsumerWidget {
  const PenPathActions({
    super.key,
    required this.onFinish,
    required this.onCancel,
    this.isFloating = false,
  });

  final VoidCallback onFinish;
  final VoidCallback onCancel;
  final bool isFloating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('finish-pen-path'),
          onPressed: onFinish,
          icon: Icon(Icons.check, color: theme.primaryColor),
          tooltip: Strings.of(context).done,
        ),
        IconButton(
          key: const ValueKey('cancel-pen-path'),
          onPressed: onCancel,
          icon: Icon(Icons.close, color: theme.error),
          tooltip: Strings.of(context).cancel,
        ),
      ],
    );

    if (!isFloating) return actions;

    final geometry = theme.geometry;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(geometry.cardRadius),
        border: geometry.cardBorderWidth > 0
            ? Border.all(
                color: theme.divider,
                width: geometry.cardBorderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: geometry.shadowColor ?? Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: actions,
    );
  }
}
