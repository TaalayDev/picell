import 'package:flutter/material.dart';

/// Hover-lift and press-shrink wrapper for tappable cards.
///
/// Also focusable: Tab reaches it, Enter or Space activates it, and the
/// builder sees keyboard focus as "hovered" so the card shows where focus is.
class PvPressable extends StatefulWidget {
  const PvPressable({super.key, required this.onTap, required this.builder, this.semanticLabel});

  final VoidCallback? onTap;

  /// Called with the current hover state so the child can restyle its border.
  final Widget Function(BuildContext context, bool hovered) builder;
  final String? semanticLabel;

  @override
  State<PvPressable> createState() => _PvPressableState();
}

class _PvPressableState extends State<PvPressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final highlighted = _hovered || _focused;
    final lifted = _enabled && highlighted && !_pressed;
    return Semantics(
      button: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onTap?.call();
            return null;
          }),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..translateByDouble(0.0, lifted ? -2.0 : 0.0, 0.0, 1.0)
              ..scaleByDouble(_pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0, 1.0, 1.0),
            transformAlignment: Alignment.center,
            child: widget.builder(context, highlighted),
          ),
        ),
      ),
    );
  }
}
