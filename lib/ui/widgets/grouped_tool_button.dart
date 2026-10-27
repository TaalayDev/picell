import 'package:flutter/material.dart';

/// Click to reactivate a group; the arrow or a long press opens its choices.
class GroupedToolButton extends StatelessWidget {
  const GroupedToolButton({
    super.key,
    required this.group,
    required this.icon,
    required this.onActivate,
    required this.onOpenMenu,
  });

  final String group;
  final Widget icon;
  final VoidCallback onActivate;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onLongPress: onOpenMenu,
              child: IconButton(
                key: ValueKey('$group-activate'),
                icon: icon,
                onPressed: onActivate,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: SizedBox.square(
              dimension: 20,
              child: IconButton(
                key: ValueKey('$group-options'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_drop_down, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: onOpenMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
