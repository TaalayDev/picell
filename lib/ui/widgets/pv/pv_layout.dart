import 'package:flutter/material.dart';

/// Spacing scale on a 4 px grid. Use these instead of ad-hoc paddings so
/// screens line up with each other.
abstract final class PvSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// How much room a window has, from phone to wide desktop.
enum PvWindowSize {
  /// Phones in portrait (< 600).
  compact,

  /// Large phones in landscape and small tablets (600–904).
  medium,

  /// Tablets in landscape and laptop windows (905–1239).
  expanded,

  /// Desktop (1240+).
  large;

  bool get isCompact => this == compact;
  bool get isWide => index >= expanded.index;
}

abstract final class PvBreakpoints {
  static const double medium = 600;
  static const double expanded = 905;
  static const double large = 1240;

  /// Widest readable column for text-heavy pages.
  static const double readableWidth = 720;

  /// Widest content column for grids and dashboards.
  static const double contentWidth = 1200;

  static PvWindowSize sizeFor(double width) {
    if (width >= large) return PvWindowSize.large;
    if (width >= expanded) return PvWindowSize.expanded;
    if (width >= medium) return PvWindowSize.medium;
    return PvWindowSize.compact;
  }

  /// Side margin for a window [width] wide.
  static double gutterFor(double width) => switch (sizeFor(width)) {
        PvWindowSize.compact => PvSpace.lg,
        PvWindowSize.medium => PvSpace.xl,
        PvWindowSize.expanded || PvWindowSize.large => PvSpace.xxl,
      };
}

extension PvLayoutContext on BuildContext {
  PvWindowSize get pvWindowSize => PvBreakpoints.sizeFor(MediaQuery.sizeOf(this).width);
  double get pvGutter => PvBreakpoints.gutterFor(MediaQuery.sizeOf(this).width);
}

/// Centres [child] in a column no wider than [maxWidth], with the window's
/// gutter either side. Wrap scrolling page bodies in it so content does not
/// stretch edge to edge on desktop.
class PvContentWidth extends StatelessWidget {
  const PvContentWidth({
    super.key,
    required this.child,
    this.maxWidth = PvBreakpoints.contentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;

  /// Overrides the default gutter-on-both-sides padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: context.pvGutter),
          child: child,
        ),
      ),
    );
  }
}
