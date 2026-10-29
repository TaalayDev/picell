import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives a panel contextual Ctrl/Cmd+A behavior after the user interacts with
/// it, without stealing Select All from focused text fields inside the panel.
class PanelSelectAllRegion extends StatefulWidget {
  const PanelSelectAllRegion({
    super.key,
    required this.onSelectAll,
    this.onPointerDown,
    required this.child,
  });

  final VoidCallback onSelectAll;

  /// Called on every pointer down inside the panel, e.g. to mark it as the
  /// editor area the user is working in.
  final VoidCallback? onPointerDown;
  final Widget child;

  @override
  State<PanelSelectAllRegion> createState() => _PanelSelectAllRegionState();
}

class _PanelSelectAllRegionState extends State<PanelSelectAllRegion> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'panel-select-all');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            widget.onSelectAll,
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            widget.onSelectAll,
      },
      child: Focus(
        focusNode: _focusNode,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (_focusNode.canRequestFocus) _focusNode.requestFocus();
            widget.onPointerDown?.call();
          },
          child: widget.child,
        ),
      ),
    );
  }
}
