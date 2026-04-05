import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paper fold: the new screen "unfolds" like a sheet of paper being opened.
/// Uses a perspective Transform to simulate a 3-D fold along the Y axis.
class OrigamiFoldTransition extends StatelessWidget {
  const OrigamiFoldTransition({
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
    return OrigamiFoldTransition(animation: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        // angle goes from -pi/2 → 0 (fold opens toward viewer)
        final angle = (1 - curved.value) * -math.pi / 2;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateY(angle);

        return Transform(
          alignment: Alignment.centerLeft,
          transform: matrix,
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
