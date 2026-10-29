import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import 'pv_layout.dart';
import 'pv_pressable.dart';

/// A themed surface card. With [onTap] it lifts on hover, shrinks on press
/// and takes keyboard focus; [selected] outlines it in the accent.
class PvCard extends StatelessWidget {
  const PvCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(PvSpace.lg),
    this.selected = false,
    this.color,
    this.clip = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? color;

  /// Clips the child to the card's corners (for edge-to-edge artwork).
  final bool clip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    Widget card(bool hovered) {
      final decoration = pv.cardDecoration(hovered: hovered || selected, color: color);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: decoration,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        padding: padding,
        child: child,
      );
    }

    if (onTap == null) return card(false);
    return PvPressable(onTap: onTap, semanticLabel: semanticLabel, builder: (context, hovered) => card(hovered));
  }
}
