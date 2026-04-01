import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../pixel/tools.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import 'subscription/feature_gate.dart';
import 'app_icon.dart';
import 'theme_selector.dart';

class StyledToolBottomSheet extends HookConsumerWidget {
  final ValueNotifier<PixelTool> currentTool;

  const StyledToolBottomSheet({
    super.key,
    required this.currentTool,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;
    final subscription = ref.watch(subscriptionStateProvider);
    final hasProFeature = subscription.hasFeatureAccess(
      SubscriptionFeature.advancedTools,
    );

    final extraTools = [
      const ToolItem(
        tool: PixelTool.sprayPaint,
        icon: AppIcons.spray,
        label: 'Spray Paint',
        tooltip: 'Creates a spray effect with particles',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.line,
        icon: AppIcons.line,
        label: 'Line',
        tooltip: 'Draw straight lines between two points',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.circle,
        icon: AppIcons.circle,
        label: 'Circle',
        tooltip: 'Draw perfect circles and ellipses',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.rectangle,
        icon: AppIcons.rectangle,
        label: 'Rectangle',
        tooltip: 'Draw rectangles and squares',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.triangle,
        icon: Icons.change_history,
        label: 'Triangle',
        tooltip: 'Draw triangular shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.diamond,
        icon: Icons.diamond_outlined,
        label: 'Diamond',
        tooltip: 'Draw diamond shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.hexagon,
        icon: Icons.hexagon_outlined,
        label: 'Hexagon',
        tooltip: 'Draw hexagonal shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.heart,
        icon: Icons.favorite_border,
        label: 'Heart',
        tooltip: 'Draw heart shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.arrow,
        icon: Icons.arrow_forward,
        label: 'Arrow',
        tooltip: 'Draw arrow shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.lightning,
        icon: Icons.flash_on,
        label: 'Lightning',
        tooltip: 'Draw lightning bolt shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.cross,
        icon: Icons.add,
        label: 'Cross',
        tooltip: 'Draw cross or plus shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.spiral,
        icon: Icons.sync,
        label: 'Spiral',
        tooltip: 'Draw spiral shapes',
        isPro: false,
      ),
      const ToolItem(
        tool: PixelTool.cloud,
        icon: Icons.cloud_outlined,
        label: 'Cloud',
        tooltip: 'Draw cloud shapes',
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.pen,
        icon: AppIcons.pen,
        label: 'Pen',
        tooltip: 'Advanced freehand drawing tool',
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.select,
        icon: AppIcons.select,
        label: 'Rect Select',
        tooltip: 'Select a rectangular area',
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.ellipseSelect,
        icon: AppIcons.circle,
        label: 'Ellipse',
        tooltip: 'Select an elliptical area',
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.lasso,
        icon: AppIcons.lasso,
        label: 'Lasso',
        tooltip: 'Freehand selection tool',
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.smartSelect,
        icon: AppIcons.magic_stick,
        label: 'Magic Wand',
        tooltip: 'Select contiguous pixels by color',
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.curve,
        icon: AppIcons.curved_connector,
        label: 'Curve',
        tooltip: 'Draw smooth curved lines',
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.drag,
        icon: Feather.move,
        label: 'Move',
        tooltip: 'Move and drag elements',
        isPro: !hasProFeature,
      ),
    ];

    return ToolBottomSheetContainer(
      theme: theme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          ToolGrid(
            tools: extraTools,
            currentTool: currentTool,
            theme: theme,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ToolItem {
  final PixelTool tool;
  final dynamic icon; // Can be IconData or AppIcons
  final String label;
  final String tooltip;
  final bool isPro;

  const ToolItem({
    required this.tool,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.isPro = false,
  });
}

class ToolBottomSheetContainer extends StatelessWidget {
  final AppTheme theme;
  final Widget child;

  const ToolBottomSheetContainer({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class BottomSheetTitle extends StatelessWidget {
  final String title;
  final AppTheme theme;

  const BottomSheetTitle({
    super.key,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(
          color: theme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class ToolGrid extends StatelessWidget {
  final List<ToolItem> tools;
  final ValueNotifier<PixelTool> currentTool;
  final AppTheme theme;

  const ToolGrid({
    super.key,
    required this.tools,
    required this.currentTool,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return ToolGridItem(
            toolItem: tool,
            currentTool: currentTool,
            theme: theme,
          );
        },
      ),
    );
  }
}

class ToolGridItem extends StatelessWidget {
  final ToolItem toolItem;
  final ValueNotifier<PixelTool> currentTool;
  final AppTheme theme;

  const ToolGridItem({
    super.key,
    required this.toolItem,
    required this.currentTool,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentTool.value == toolItem.tool;

    return Tooltip(
      message: toolItem.tooltip,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: toolItem.isPro
              ? null
              : () {
                  currentTool.value = toolItem.tool;
                  Navigator.of(context).pop(toolItem.tool);
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primaryColor.withValues(alpha: 0.2)
                  : theme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.primaryColor, width: 2)
                  : Border.all(color: theme.divider, width: 1),
            ),
            child: ProBadge(
              show: toolItem.isPro,
              child: ToolItemContent(
                toolItem: toolItem,
                isSelected: isSelected,
                theme: theme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ToolItemContent extends StatelessWidget {
  final ToolItem toolItem;
  final bool isSelected;
  final AppTheme theme;

  const ToolItemContent({
    super.key,
    required this.toolItem,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ToolIcon(
            icon: toolItem.icon,
            isSelected: isSelected,
            theme: theme,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              toolItem.label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? theme.primaryColor : theme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ToolIcon extends StatelessWidget {
  final dynamic icon;
  final bool isSelected;
  final AppTheme theme;

  const ToolIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? theme.primaryColor : theme.inactiveIcon;

    // Check if it's an AppIcon or regular IconData
    if (icon.runtimeType.toString().contains('AppIcons')) {
      return AppIcon(
        icon,
        color: color,
        size: 24,
      );
    } else {
      return Icon(
        icon,
        color: color,
        size: 24,
      );
    }
  }
}
