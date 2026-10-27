import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import 'pixel_cut_border.dart';

/// Primary call-to-action with pixel-cut corners and the theme gradient.
/// Reserved for hero actions (new project, create first project).
class PvPixelButton extends StatelessWidget {
  const PvPixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    const shape = PixelCutBorder();
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: pv.ink),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pv.pixelLabel(size: 14, color: pv.ink),
          ),
        ),
      ],
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: pv.gradient,
        shadows: [BoxShadow(color: pv.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          child: SizedBox(
            height: height,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: content),
          ),
        ),
      ),
    );
  }
}
