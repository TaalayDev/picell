import 'package:flutter/material.dart';

/// Horizontal slide with chromatic aberration effect on the incoming screen.
/// R/G/B layers start slightly offset and converge by end of animation.
class RetroWaveTransition extends StatelessWidget {
  const RetroWaveTransition({
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
    return RetroWaveTransition(animation: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    // Slide from right
    final slide = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(curved);

    // Chromatic aberration: offset shrinks from 8px → 0 as animation completes
    final aberrationOffset = Tween<double>(begin: 10, end: 0).animate(curved);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final chromaStrength = (aberrationOffset.value / 10).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            SlideTransition(position: slide, child: child),
            if (chromaStrength > 0)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFFF4D6D)
                            .withValues(alpha: 0.08 * chromaStrength),
                        Colors.transparent,
                        const Color(0xFF4DD2FF)
                            .withValues(alpha: 0.08 * chromaStrength),
                      ],
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
