import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Section title used on the Projects screen: a small gradient square, the
/// title in the pixel label face, and an optional trailing widget.
class PvSectionHeader extends StatelessWidget {
  const PvSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 8, 0),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(gradient: pv.gradient)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: pv.pixelLabel(size: 15).copyWith(letterSpacing: 1),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
