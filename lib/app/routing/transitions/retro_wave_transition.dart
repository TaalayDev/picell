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
      builder: (context, _) {
        final offset = aberrationOffset.value;
        return Stack(
          children: [
            // Red channel — shifted right
            Transform.translate(
              offset: Offset(slide.value.dx * MediaQuery.sizeOf(context).width + offset, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  1, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0.4, 0,
                ]),
                child: child,
              ),
            ),
            // Blue channel — shifted left
            Transform.translate(
              offset: Offset(slide.value.dx * MediaQuery.sizeOf(context).width - offset, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 1, 0, 0,
                  0, 0, 0, 0.4, 0,
                ]),
                child: child,
              ),
            ),
            // Full image on top
            SlideTransition(position: slide, child: child),
          ],
        );
      },
    );
  }
}
