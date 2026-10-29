import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import 'pixel_cut_border.dart';
import 'pv_layout.dart';

/// What a screen shows when it has nothing to list yet, or failed to load:
/// a pixel-cut icon tile, a short title, one line of help and an optional
/// action.
class PvEmptyState extends StatelessWidget {
  const PvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Usually a button that gets the user out of the empty state.
  final Widget? action;

  /// Accent for the icon tile; the theme accent by default. Pass the error
  /// color for failures.
  final Color? color;

  /// Smaller version for panels and dialogs.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final c = color ?? pv.accent;
    final tile = compact ? 56.0 : 80.0;
    final content = Padding(
      padding: EdgeInsets.all(compact ? PvSpace.lg : PvSpace.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tile,
              height: tile,
              decoration: ShapeDecoration(
                shape: PixelCutBorder(side: BorderSide(color: c.withValues(alpha: 0.45), width: 2)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.06)],
                ),
              ),
              child: Icon(icon, size: tile * 0.45, color: c),
            ),
            SizedBox(height: compact ? PvSpace.md : PvSpace.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: pv.body(size: compact ? 15 : 18, weight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: PvSpace.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: pv
                    .body(size: compact ? 12 : 14, color: pv.textSecondary, weight: FontWeight.w400)
                    .copyWith(height: 1.45),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? PvSpace.lg : PvSpace.xl),
              action!,
            ],
          ],
        ),
      ),
    );
    // Inside a list it sizes to its content; given a fixed height it centres
    // and scrolls rather than overflowing on short windows. (No LayoutBuilder:
    // slivers such as SliverFillRemaining measure their child's intrinsics.)
    return Center(child: SingleChildScrollView(child: content));
  }
}
