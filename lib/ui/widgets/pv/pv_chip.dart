import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Small status chip: tinted fill, matching border, optional leading icon.
///
/// The icon keeps status readable without relying on color alone.
class PvChip extends StatelessWidget {
  const PvChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
    this.solid = false,
  });

  final String label;
  final IconData? icon;

  /// Defaults to the theme's secondary text color.
  final Color? color;
  final bool dense;

  /// Opaque surface fill, for chips laid over artwork.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final c = color ?? pv.textSecondary;
    return Container(
      height: dense ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8),
      decoration: BoxDecoration(
        color: solid ? pv.surface : c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(pv.chipRadius.clamp(4, 12)),
        border: Border.all(color: solid ? pv.divider : c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: c),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: pv.body(size: dense ? 10 : 11, color: solid ? pv.textPrimary : c, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
