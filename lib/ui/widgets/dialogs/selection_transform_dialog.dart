import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/strings.dart';

/// What the transform dialog asks for. Applied in this order: flips, then
/// position and size, then rotation.
class SelectionTransformRequest {
  const SelectionTransformRequest({
    this.bounds,
    this.angleDegrees = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  /// The new bounds in canvas pixels, or null when X/Y/W/H were left as
  /// they were.
  final Rect? bounds;
  final double angleDegrees;
  final bool flipHorizontal;
  final bool flipVertical;
}

/// Typed X / Y / W / H / angle and flips for the selected pixels. Returns
/// null when cancelled.
Future<SelectionTransformRequest?> showSelectionTransformDialog(
  BuildContext context, {
  required Rect bounds,
}) {
  return showDialog<SelectionTransformRequest>(
    context: context,
    builder: (context) => SelectionTransformDialog(bounds: bounds),
  );
}

class SelectionTransformDialog extends StatefulWidget {
  const SelectionTransformDialog({super.key, required this.bounds});

  /// The selection's current bounds.
  final Rect bounds;

  @override
  State<SelectionTransformDialog> createState() => _SelectionTransformDialogState();
}

class _SelectionTransformDialogState extends State<SelectionTransformDialog> {
  late final _x = TextEditingController(text: '${widget.bounds.left.round()}');
  late final _y = TextEditingController(text: '${widget.bounds.top.round()}');
  late final _w = TextEditingController(text: '${widget.bounds.width.round()}');
  late final _h = TextEditingController(text: '${widget.bounds.height.round()}');
  final _angle = TextEditingController(text: '0');
  bool _keepAspect = true;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  @override
  void dispose() {
    for (final c in [_x, _y, _w, _h, _angle]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _aspect => widget.bounds.height > 0 ? widget.bounds.width / widget.bounds.height : 1;

  // With the aspect locked, editing one side updates the other.
  void _sizeChanged({required bool width}) {
    if (!_keepAspect) return;
    final value = int.tryParse((width ? _w : _h).text);
    if (value == null || value <= 0) return;
    final other = width ? (value / _aspect).round() : (value * _aspect).round();
    (width ? _h : _w).text = '${other < 1 ? 1 : other}';
  }

  void _apply() {
    final x = int.tryParse(_x.text) ?? widget.bounds.left.round();
    final y = int.tryParse(_y.text) ?? widget.bounds.top.round();
    final w = (int.tryParse(_w.text) ?? widget.bounds.width.round()).clamp(1, 1 << 16);
    final h = (int.tryParse(_h.text) ?? widget.bounds.height.round()).clamp(1, 1 << 16);
    final original = widget.bounds;
    final unchanged = x == original.left.round() &&
        y == original.top.round() &&
        w == original.width.round() &&
        h == original.height.round();
    Navigator.of(context).pop(SelectionTransformRequest(
      bounds: unchanged ? null : Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
      angleDegrees: double.tryParse(_angle.text) ?? 0,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
    ));
  }

  Widget _field(String key, String label, TextEditingController controller,
      {bool signed = false, bool decimal = false, ValueChanged<String>? onChanged}) {
    return Expanded(
      child: TextField(
        key: ValueKey('selection-transform-$key'),
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true),
        keyboardType: TextInputType.numberWithOptions(signed: signed, decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(decimal ? r'^-?\d*\.?\d*' : (signed ? r'^-?\d*' : r'^\d*'))),
        ],
        onChanged: onChanged,
        onSubmitted: (_) => _apply(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transform selection'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              _field('x', 'X', _x, signed: true),
              const SizedBox(width: 12),
              _field('y', 'Y', _y, signed: true),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _field('w', 'W', _w, onChanged: (_) => _sizeChanged(width: true)),
              const SizedBox(width: 12),
              _field('h', 'H', _h, onChanged: (_) => _sizeChanged(width: false)),
              IconButton(
                key: const ValueKey('selection-transform-keep-aspect'),
                tooltip: 'Keep aspect ratio',
                isSelected: _keepAspect,
                icon: const Icon(Icons.link_off),
                selectedIcon: const Icon(Icons.link),
                onPressed: () => setState(() => _keepAspect = !_keepAspect),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _field('angle', 'Rotate (°)', _angle, signed: true, decimal: true),
              const SizedBox(width: 12),
              IconButton(
                key: const ValueKey('selection-transform-flip-h'),
                tooltip: 'Flip horizontally',
                isSelected: _flipHorizontal,
                icon: const Icon(Icons.flip),
                onPressed: () => setState(() => _flipHorizontal = !_flipHorizontal),
              ),
              IconButton(
                key: const ValueKey('selection-transform-flip-v'),
                tooltip: 'Flip vertically',
                isSelected: _flipVertical,
                icon: const RotatedBox(quarterTurns: 1, child: Icon(Icons.flip)),
                onPressed: () => setState(() => _flipVertical = !_flipVertical),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Strings.of(context).cancel),
        ),
        FilledButton(
          key: const ValueKey('selection-transform-apply'),
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
