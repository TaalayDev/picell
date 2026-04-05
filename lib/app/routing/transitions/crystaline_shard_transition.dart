import 'package:flutter/material.dart';

/// Crystal reveal: scale from 0.9 + fade, with a brief shimmer flash
/// at the very start — as if a gem facet is catching light.
class CrystalineShardTransition extends StatelessWidget {
  const CrystalineShardTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  static Widget builder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CrystalineShardTransition(animation: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuint,
    );

    // Shimmer flash only in first 20% of animation
    final shimmerOpacity = Tween<double>(begin: 0.25, end: 0.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    final scale = Tween<double>(begin: 0.9, end: 1.0).animate(curved);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: curved,
              child: ScaleTransition(scale: scale, child: child),
            ),
            // Shimmer overlay
            if (shimmerOpacity.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE8D5FF).withValues(alpha: shimmerOpacity.value),
                          Colors.white.withValues(alpha: shimmerOpacity.value * 0.5),
                          const Color(0xFF9B59B6).withValues(alpha: shimmerOpacity.value),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
