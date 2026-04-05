import 'package:flutter/material.dart';

import 'project_card_data.dart';

/// ThemeExtension that carries flagship-specific UI customisation.
/// Attached to ThemeData.extensions for the 6 flagship themes.
/// All builders are nullable — null means "use the default widget".
class FlagshipConfig extends ThemeExtension<FlagshipConfig> {
  final bool isFlagship;

  // ── Project card ───────────────────────────────────────────────────────────
  /// Build a theme-specific project card.
  /// Receives full [ProjectCardData] (project + callbacks).
  final Widget Function(BuildContext ctx, ProjectCardData data)? cardBuilder;

  // ── Page transitions ───────────────────────────────────────────────────────
  final RouteTransitionsBuilder? transitionBuilder;
  final Duration transitionDuration;

  // ── AppBar ─────────────────────────────────────────────────────────────────
  final Gradient? appBarGradient;

  /// Decoration painted below the AppBar (e.g. neon line, chain, wave).
  final PreferredSizeWidget Function(BuildContext, PreferredSizeWidget original)?
      appBarWrapper;

  // ── Icons ──────────────────────────────────────────────────────────────────
  final bool enableIconGlow;
  final Color? iconGlowColor;
  final double iconGlowRadius;

  // ── Empty state ────────────────────────────────────────────────────────────
  final Widget Function(BuildContext)? emptyStateBuilder;

  // ── ThemeSelector badge ────────────────────────────────────────────────────
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeTextColor;

  const FlagshipConfig({
    required this.isFlagship,
    this.cardBuilder, // Widget Function(BuildContext, ProjectCardData)?
    this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 350),
    this.appBarGradient,
    this.appBarWrapper,
    this.enableIconGlow = false,
    this.iconGlowColor,
    this.iconGlowRadius = 10,
    this.emptyStateBuilder,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  static const none = FlagshipConfig(
    isFlagship: false,
    badgeLabel: '',
    badgeColor: Colors.transparent,
    badgeTextColor: Colors.transparent,
  );

  @override
  FlagshipConfig copyWith({
    bool? isFlagship,
    Widget Function(BuildContext, ProjectCardData)? cardBuilder,
    RouteTransitionsBuilder? transitionBuilder,
    Duration? transitionDuration,
    Gradient? appBarGradient,
    PreferredSizeWidget Function(BuildContext, PreferredSizeWidget)? appBarWrapper,
    bool? enableIconGlow,
    Color? iconGlowColor,
    double? iconGlowRadius,
    Widget Function(BuildContext)? emptyStateBuilder,
    String? badgeLabel,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return FlagshipConfig(
      isFlagship: isFlagship ?? this.isFlagship,
      cardBuilder: cardBuilder ?? this.cardBuilder,
      transitionBuilder: transitionBuilder ?? this.transitionBuilder,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      appBarGradient: appBarGradient ?? this.appBarGradient,
      appBarWrapper: appBarWrapper ?? this.appBarWrapper,
      enableIconGlow: enableIconGlow ?? this.enableIconGlow,
      iconGlowColor: iconGlowColor ?? this.iconGlowColor,
      iconGlowRadius: iconGlowRadius ?? this.iconGlowRadius,
      emptyStateBuilder: emptyStateBuilder ?? this.emptyStateBuilder,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      badgeColor: badgeColor ?? this.badgeColor,
      badgeTextColor: badgeTextColor ?? this.badgeTextColor,
    );
  }

  @override
  FlagshipConfig lerp(ThemeExtension<FlagshipConfig>? other, double t) {
    if (other is! FlagshipConfig) return this;
    return FlagshipConfig(
      isFlagship: t < 0.5 ? isFlagship : other.isFlagship,
      cardBuilder: t < 0.5 ? cardBuilder : other.cardBuilder,
      transitionBuilder: t < 0.5 ? transitionBuilder : other.transitionBuilder,
      transitionDuration: t < 0.5 ? transitionDuration : other.transitionDuration,
      appBarGradient: t < 0.5 ? appBarGradient : other.appBarGradient,
      appBarWrapper: t < 0.5 ? appBarWrapper : other.appBarWrapper,
      enableIconGlow: t < 0.5 ? enableIconGlow : other.enableIconGlow,
      iconGlowColor: Color.lerp(iconGlowColor, other.iconGlowColor, t),
      iconGlowRadius: lerpDouble(iconGlowRadius, other.iconGlowRadius, t),
      emptyStateBuilder: t < 0.5 ? emptyStateBuilder : other.emptyStateBuilder,
      badgeLabel: t < 0.5 ? badgeLabel : other.badgeLabel,
      badgeColor: Color.lerp(badgeColor, other.badgeColor, t) ?? badgeColor,
      badgeTextColor:
          Color.lerp(badgeTextColor, other.badgeTextColor, t) ?? badgeTextColor,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
