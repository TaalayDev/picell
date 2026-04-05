import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.theme.accentColor,
                  Color.lerp(widget.theme.accentColor, Colors.purple, 0.5)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.accentColor.withValues(alpha: _glowAnimation.value),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        MaterialCommunityIcons.star,
                        color: Colors.white,
                        size: 18,
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .rotate(
                            duration: 3.seconds,
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(width: 4),
                      const Text(
                        'Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
