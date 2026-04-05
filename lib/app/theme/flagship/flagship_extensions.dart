import 'package:flutter/material.dart';

import 'flagship_config.dart';

extension FlagshipBuildContext on BuildContext {
  /// Returns the [FlagshipConfig] attached to the current theme, or null.
  FlagshipConfig? get flagship => Theme.of(this).extension<FlagshipConfig>();

  /// True when the active theme is one of the 6 flagship themes.
  bool get isFlagship => flagship?.isFlagship ?? false;
}

/// Wraps an icon with a glow effect when the theme requests it.
class FlagshipIconGlow extends StatelessWidget {
  const FlagshipIconGlow({
    super.key,
    required this.child,
    required this.active,
  });

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cfg = context.flagship;
    if (cfg == null || !cfg.enableIconGlow || !active) return child;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (cfg.iconGlowColor ?? Theme.of(context).colorScheme.primary)
                .withValues(alpha: 0.7),
            blurRadius: cfg.iconGlowRadius,
            spreadRadius: cfg.iconGlowRadius * 0.25,
          ),
        ],
      ),
      child: child,
    );
  }
}
