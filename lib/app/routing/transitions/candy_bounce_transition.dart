import 'package:flutter/material.dart';

/// Scale from 0.8 → 1.0 with elastic bounce + fade.
class CandyBounceTransition extends StatelessWidget {
  const CandyBounceTransition({
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
    return CandyBounceTransition(animation: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    );
    final fadeCurved = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    final scale = Tween<double>(begin: 0.8, end: 1.0).animate(curved);

    return FadeTransition(
      opacity: fadeCurved,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}
