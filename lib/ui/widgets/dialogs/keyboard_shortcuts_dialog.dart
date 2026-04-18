import 'package:flutter/material.dart';

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Keyboard Shortcuts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(context, 'File', [
                      _ShortcutRow('Save', 'Ctrl + S'),
                      _ShortcutRow('Export', 'Ctrl + E'),
                      _ShortcutRow('Import', 'Ctrl + O'),
                    ]),
                    _section(context, 'Edit', [
                      _ShortcutRow('Undo', 'Ctrl + Z'),
                      _ShortcutRow('Redo', 'Ctrl + Y  /  Ctrl + Shift + Z'),
                      _ShortcutRow('Copy selection', 'Ctrl + C'),
                      _ShortcutRow('Cut selection', 'Ctrl + X'),
                      _ShortcutRow('Paste', 'Ctrl + V'),
                      _ShortcutRow('Duplicate layer', 'Ctrl + J'),
                    ]),
                    _section(context, 'Selection', [
                      _ShortcutRow('Select all', 'Ctrl + A'),
                      _ShortcutRow('Deselect', 'Ctrl + D  /  Escape'),
                      _ShortcutRow('Close pen path', 'Ctrl + Enter'),
                    ]),
                    _section(context, 'Tools', [
                      _ShortcutRow('Pencil', 'B'),
                      _ShortcutRow('Eraser', 'E'),
                      _ShortcutRow('Eyedropper', 'I'),
                      _ShortcutRow('Fill', 'G'),
                      _ShortcutRow('Select / Marquee', 'M'),
                      _ShortcutRow('Line', 'L'),
                      _ShortcutRow('Rectangle', 'U'),
                      _ShortcutRow('Circle', 'O'),
                      _ShortcutRow('Move / Drag', 'H'),
                      _ShortcutRow('Pen', 'P'),
                      _ShortcutRow('Spray paint', 'S'),
                      _ShortcutRow('Pan (hold)', 'Space'),
                      _ShortcutRow('Eyedropper (hold)', 'Alt'),
                      _ShortcutRow('Color picker', 'C'),
                    ]),
                    _section(context, 'Brush', [
                      _ShortcutRow('Increase size', ']'),
                      _ShortcutRow('Decrease size', '['),
                    ]),
                    _section(context, 'Colors', [
                      _ShortcutRow('Swap colors', 'X'),
                      _ShortcutRow('Default colors', 'D'),
                    ]),
                    _section(context, 'View', [
                      _ShortcutRow('Zoom in', '='),
                      _ShortcutRow('Zoom out', '-'),
                      _ShortcutRow('Zoom to fit', '0'),
                      _ShortcutRow('Zoom 1:1', '1'),
                      _ShortcutRow('Toggle UI', 'Tab'),
                    ]),
                    _section(context, 'Layers', [
                      _ShortcutRow('Select layer 1–9', '1 – 9'),
                      _ShortcutRow('New layer', 'Ctrl + N'),
                      _ShortcutRow('Delete layer', 'Delete'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String action;
  final String keys;

  const _ShortcutRow(this.action, this.keys);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(action, style: Theme.of(context).textTheme.bodySmall),
          ),
          _KeyBadge(keys),
        ],
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String label;

  const _KeyBadge(this.label);

  @override
  Widget build(BuildContext context) {
    final parts = label.split('  /  ');
    if (parts.length > 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: parts
            .expand<Widget>((p) => [
                  _single(context, p),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('/',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            )),
                  ),
                ])
            .toList()
          ..removeLast(),
      );
    }
    return _single(context, label);
  }

  Widget _single(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
