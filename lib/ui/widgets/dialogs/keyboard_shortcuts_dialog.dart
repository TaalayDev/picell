import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';

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
    final s = Strings.of(context);

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
                    s.keyboardShortcuts,
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
                    _section(context, s.fileMenu, [
                      _ShortcutRow(s.save, 'Ctrl + S'),
                      _ShortcutRow(s.export, 'Ctrl + E'),
                      _ShortcutRow(s.import, 'Ctrl + O'),
                    ]),
                    _section(context, s.edit, [
                      _ShortcutRow(s.undo, 'Ctrl + Z'),
                      _ShortcutRow(s.redo, 'Ctrl + Y  /  Ctrl + Shift + Z'),
                      _ShortcutRow(s.copySelection, 'Ctrl + C'),
                      _ShortcutRow(s.cutSelection, 'Ctrl + X'),
                      _ShortcutRow(s.paste, 'Ctrl + V'),
                      _ShortcutRow(s.duplicateLayer, 'Ctrl + J'),
                    ]),
                    _section(context, s.selection, [
                      _ShortcutRow(s.selectAll, 'Ctrl + A'),
                      _ShortcutRow(s.deselect, 'Ctrl + D  /  Escape'),
                      _ShortcutRow(s.closePenPath, 'Ctrl + Enter'),
                    ]),
                    _section(context, s.tools, [
                      _ShortcutRow(s.pencil, 'B'),
                      _ShortcutRow(s.eraser, 'E'),
                      _ShortcutRow(s.eyedropper, 'I'),
                      _ShortcutRow(s.fill, 'G'),
                      _ShortcutRow(s.selectMarquee, 'M'),
                      _ShortcutRow(s.lineTool, 'L'),
                      _ShortcutRow(s.rectangleTool, 'U'),
                      _ShortcutRow(s.circleTool, 'O'),
                      _ShortcutRow(s.moveDrag, 'H'),
                      _ShortcutRow(s.pen, 'P'),
                      _ShortcutRow(s.sprayPaint, 'S'),
                      _ShortcutRow(s.panHold, 'Space'),
                      _ShortcutRow(s.eyedropperHold, 'Alt'),
                      _ShortcutRow(s.colorPicker, 'C'),
                    ]),
                    _section(context, s.brush, [
                      _ShortcutRow(s.increaseSize, ']'),
                      _ShortcutRow(s.decreaseSize, '['),
                    ]),
                    _section(context, s.colors, [
                      _ShortcutRow(s.swapColors, 'X'),
                      _ShortcutRow(s.defaultColors, 'D'),
                    ]),
                    _section(context, s.view, [
                      _ShortcutRow(s.zoomIn, '='),
                      _ShortcutRow(s.zoomOut, '-'),
                      _ShortcutRow(s.zoomToFit, '0'),
                      _ShortcutRow(s.zoomOneToOne, '1'),
                      _ShortcutRow(s.toggleUi, 'Tab'),
                    ]),
                    _section(context, s.layers, [
                      _ShortcutRow(s.selectLayerOneToNine, '1 – 9'),
                      _ShortcutRow(s.newLayer, 'Ctrl + N'),
                      _ShortcutRow(s.deleteLayer, 'Delete'),
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
