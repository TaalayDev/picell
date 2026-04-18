import 'package:flutter/material.dart';

import '../../../pixel/providers/pixel_canvas_provider.dart';

/// Shows a bottom sheet with the undo/redo history for [notifier].
///
/// Entries are displayed newest-first (top = most recent past state).
/// Tapping an undo step calls [onUndo] the required number of times;
/// tapping a redo step calls [onRedo] the required number of times.
class UndoHistorySheet extends StatefulWidget {
  final PixelCanvasNotifier notifier;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const UndoHistorySheet({
    super.key,
    required this.notifier,
    this.onUndo,
    this.onRedo,
  });

  static Future<void> show(
    BuildContext context, {
    required PixelCanvasNotifier notifier,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UndoHistorySheet(
        notifier: notifier,
        onUndo: onUndo,
        onRedo: onRedo,
      ),
    );
  }

  @override
  State<UndoHistorySheet> createState() => _UndoHistorySheetState();
}

class _UndoHistorySheetState extends State<UndoHistorySheet> {
  late List<String> _undoSummary;
  late List<String> _redoSummary;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _undoSummary = widget.notifier.undoStackSummary;
    _redoSummary = widget.notifier.redoStackSummary;
  }

  void _applyUndo(int steps) {
    for (int i = 0; i < steps; i++) {
      widget.onUndo?.call();
    }
    setState(_refresh);
  }

  void _applyRedo(int steps) {
    for (int i = 0; i < steps; i++) {
      widget.onRedo?.call();
    }
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    final undoCount = _undoSummary.length;
    final redoCount = _redoSummary.length;
    final total = undoCount + redoCount + 1; // +1 for current state

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                'History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 6),
              Text(
                '($total steps)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: undoCount > 0 ? () => _applyUndo(undoCount) : null,
                icon: const Icon(Icons.skip_previous_rounded, size: 16),
                label: const Text('Revert all'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            // Display order: redo stack (future), current, undo stack (past)
            itemCount: total,
            itemBuilder: (context, index) {
              // index 0 = oldest undo; index undoCount = current; index > undoCount = redo
              if (index < undoCount) {
                // undo entries — shown newest first so reverse
                final undoIndex = undoCount - 1 - index;
                final stepsToUndo = undoIndex + 1;
                final label = _parseLabel(_undoSummary[undoIndex]);
                return _HistoryTile(
                  label: label,
                  stepNumber: index + 1,
                  type: _TileType.past,
                  onTap: () => _applyUndo(stepsToUndo),
                );
              } else if (index == undoCount) {
                return _HistoryTile(
                  label: 'Current state',
                  stepNumber: undoCount + 1,
                  type: _TileType.current,
                  onTap: null,
                );
              } else {
                // redo entries
                final redoIndex = index - undoCount - 1;
                final stepsToRedo = redoIndex + 1;
                final label = _parseLabel(_redoSummary[redoIndex]);
                return _HistoryTile(
                  label: label,
                  stepNumber: undoCount + 2 + redoIndex,
                  type: _TileType.future,
                  onTap: () => _applyRedo(stepsToRedo),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Converts "Frame: 0, Layer: 1" → "Frame 1, Layer 2" (1-indexed, readable).
  String _parseLabel(String raw) {
    try {
      final frameMatch = RegExp(r'Frame: (\d+)').firstMatch(raw);
      final layerMatch = RegExp(r'Layer: (\d+)').firstMatch(raw);
      final frame = int.tryParse(frameMatch?.group(1) ?? '') ?? 0;
      final layer = int.tryParse(layerMatch?.group(1) ?? '') ?? 0;
      return 'Frame ${frame + 1}, Layer ${layer + 1}';
    } catch (_) {
      return raw;
    }
  }
}

enum _TileType { past, current, future }

class _HistoryTile extends StatelessWidget {
  final String label;
  final int stepNumber;
  final _TileType type;
  final VoidCallback? onTap;

  const _HistoryTile({
    required this.label,
    required this.stepNumber,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = type == _TileType.current;
    final isFuture = type == _TileType.future;

    Color? tileColor;
    if (isCurrent) {
      tileColor =
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4);
    }

    return ListTile(
      dense: true,
      tileColor: tileColor,
      leading: SizedBox(
        width: 28,
        child: Text(
          '$stepNumber',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: isCurrent ? 0.8 : 0.45),
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isFuture
                  ? Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)
                  : null,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      trailing: isCurrent
          ? Icon(Icons.arrow_right_rounded,
              color: Theme.of(context).colorScheme.primary)
          : Icon(
              isFuture ? Icons.redo_rounded : Icons.undo_rounded,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
      onTap: onTap,
    );
  }
}
