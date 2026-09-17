import 'package:flutter/material.dart';

import '../../core/colors.dart';
import 'panel/color_palette_panel.dart';

/// Horizontally scrollable strip of quick-access color swatches shown on the
/// mobile editor layout, so switching colors doesn't require opening the
/// full color palette bottom sheet every time.
class MobileColorSelector extends StatelessWidget {
  const MobileColorSelector({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    required this.isEyedropperSelected,
    required this.onSelectEyedropper,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorSelected;
  final bool isEyedropperSelected;
  final VoidCallback onSelectEyedropper;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 25,
      color: colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kBasicColors.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ColorSwatch(
              color: currentColor,
              isSelected: true,
              showAsCurrent: true,
              onTap: () => _openFullPalette(context),
            );
          }

          final color = kBasicColors[index - 1];
          return _ColorSwatch(
            color: color,
            isSelected: color.toARGB32() == currentColor.toARGB32(),
            onTap: () => onColorSelected(color),
          );
        },
      ),
    );
  }

  void _openFullPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => ColorPalettePanel(
          scrollController: scrollController,
          currentColor: currentColor,
          isEyedropperSelected: isEyedropperSelected,
          onSelectEyedropper: () {
            onSelectEyedropper();
            Navigator.of(context).pop();
          },
          onColorSelected: (color) {
            onColorSelected(color);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.showAsCurrent = false,
  });

  final Color color;
  final bool isSelected;
  final bool showAsCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: showAsCurrent
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: showAsCurrent
            ? Icon(
                Icons.palette,
                size: 14,
                color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70,
              )
            : null,
      ),
    );
  }
}
