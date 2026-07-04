import 'package:flutter/material.dart';

import '../../data/models/selection_region.dart';

/// Segmented replace / add / subtract toggle for selection tools. The
/// active-mode highlight doubles as the mode indicator; Shift/Alt override
/// the toggle per gesture on desktop.
class SelectionModeToggle extends StatelessWidget {
  const SelectionModeToggle({super.key, required this.mode});

  final ValueNotifier<SelectionMode> mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return ValueListenableBuilder<SelectionMode>(
      valueListenable: mode,
      builder: (context, current, _) {
        return Container(
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(
                context,
                selected: current == SelectionMode.replace,
                icon: Icons.crop_square,
                tooltip: 'Replace selection',
                onTap: () => mode.value = SelectionMode.replace,
              ),
              _segment(
                context,
                selected: current == SelectionMode.add,
                icon: Icons.add_box_outlined,
                tooltip: 'Add to selection (Shift)',
                onTap: () => mode.value = SelectionMode.add,
              ),
              _segment(
                context,
                selected: current == SelectionMode.subtract,
                icon: Icons.indeterminate_check_box_outlined,
                tooltip: 'Subtract from selection (Alt)',
                onTap: () => mode.value = SelectionMode.subtract,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(
    BuildContext context, {
    required bool selected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? accentColor.withValues(alpha: 0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(icon, size: 16, color: accentColor),
          ),
        ),
      ),
    );
  }
}
