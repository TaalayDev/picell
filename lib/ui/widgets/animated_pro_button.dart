import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

class AnimatedProButton extends StatefulWidget {
  final VoidCallback onTap;
  final AppTheme theme;

  const AnimatedProButton({
    super.key,
    required this.onTap,
    required this.theme,
  });

  @override
  State<AnimatedProButton> createState() => _AnimatedProButtonState();
}

class _AnimatedProButtonState extends State<AnimatedProButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: reduceMotion ? 1.0 : _scaleAnimation.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: pv.gradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: pv.primary.withValues(alpha: _glowAnimation.value * 0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 30,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, color: pv.ink, size: 16),
                        const SizedBox(width: 4),
                        Text('PRO', style: pv.pixelLabel(size: 12, color: pv.ink)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
