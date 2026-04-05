import 'package:flutter/material.dart';

/// Iris wipe: the new screen is revealed through an expanding circle,
/// like a mechanical aperture opening — fits the Steampunk aesthetic.
class SteampunkIrisTransition extends StatelessWidget {
  const SteampunkIrisTransition({
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
    return SteampunkIrisTransition(animation: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return ClipPath(
          clipper: _IrisClipper(progress: curved.value),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _IrisClipper extends CustomClipper<Path> {
  final double progress;

  _IrisClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide;
    final radius = maxRadius * progress;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_IrisClipper old) => old.progress != progress;
}
