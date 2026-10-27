import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Placeholder block with a sweeping highlight, for loading skeletons.
/// Renders static when the platform asks to reduce motion.
class PvShimmerBox extends StatefulWidget {
  const PvShimmerBox({super.key, this.width, this.height, this.radius = 12});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<PvShimmerBox> createState() => _PvShimmerBoxState();
}

class _PvShimmerBoxState extends State<PvShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dx = -1.0 + 3 * _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(dx - 1, 0),
              end: Alignment(dx, 0),
              colors: [pv.surface, pv.surfaceHigh, pv.surface],
            ),
          ),
        );
      },
    );
  }
}
