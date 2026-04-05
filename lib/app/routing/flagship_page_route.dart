import 'package:flutter/material.dart';

import '../theme/flagship/flagship_extensions.dart';

/// A [PageRoute] that uses the active theme's [FlagshipConfig.transitionBuilder]
/// when available, otherwise falls back to a standard fade transition.
class FlagshipPageRoute<T> extends PageRouteBuilder<T> {
  FlagshipPageRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: context.flagship?.transitionDuration ??
              const Duration(milliseconds: 300),
          reverseTransitionDuration: context.flagship?.transitionDuration ??
              const Duration(milliseconds: 300),
          pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            final flagship = ctx.flagship;
            if (flagship?.isFlagship == true &&
                flagship?.transitionBuilder != null) {
              return flagship!.transitionBuilder!(
                  ctx, animation, secondaryAnimation, child);
            }
            // Default fallback: fade
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
              ),
              child: child,
            );
          },
        );
}
