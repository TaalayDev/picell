import 'package:flutter/material.dart';

/// Hover-lift and press-shrink wrapper for tappable cards.
class PvPressable extends StatefulWidget {
  const PvPressable({super.key, required this.onTap, required this.builder});

  final VoidCallback? onTap;

  /// Called with the current hover state so the child can restyle its border.
  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<PvPressable> createState() => _PvPressableState();
}

class _PvPressableState extends State<PvPressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translateByDouble(0.0, _hovered && !_pressed ? -2.0 : 0.0, 0.0, 1.0)
            ..scaleByDouble(_pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0, 1.0, 1.0),
          transformAlignment: Alignment.center,
          child: widget.builder(context, _hovered),
        ),
      ),
    );
  }
}
