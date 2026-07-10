import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../l10n/strings.dart';
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
    final s = Strings.of(context);

    final extraTools = [
      ToolItem(
        tool: PixelTool.sprayPaint,
        icon: AppIcons.spray,
        label: s.sprayPaint,
        tooltip: s.sprayPaintToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.line,
        icon: AppIcons.line,
        label: s.lineTool,
        tooltip: s.lineToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.circle,
        icon: AppIcons.circle,
        label: s.circleTool,
        tooltip: s.circleToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.rectangle,
        icon: AppIcons.rectangle,
        label: s.rectangleTool,
        tooltip: s.rectangleToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.triangle,
        icon: Icons.change_history,
        label: s.triangle,
        tooltip: s.triangleToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.diamond,
        icon: Icons.diamond_outlined,
        label: s.diamond,
        tooltip: s.diamondToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.hexagon,
        icon: Icons.hexagon_outlined,
        label: s.hexagon,
        tooltip: s.hexagonToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.heart,
        icon: Icons.favorite_border,
        label: s.heart,
        tooltip: s.heartToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.arrow,
        icon: Icons.arrow_forward,
        label: s.arrow,
        tooltip: s.arrowToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.lightning,
        icon: Icons.flash_on,
        label: s.lightning,
        tooltip: s.lightningToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.cross,
        icon: Icons.add,
        label: s.cross,
        tooltip: s.crossToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.spiral,
        icon: Icons.sync,
        label: s.spiral,
        tooltip: s.spiralToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.cloud,
        icon: Icons.cloud_outlined,
        label: s.cloudShape,
        tooltip: s.cloudToolDescription,
        isPro: false,
      ),
      ToolItem(
        tool: PixelTool.pen,
        icon: AppIcons.pen,
        label: s.pen,
        tooltip: s.penToolDescription,
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.select,
        icon: AppIcons.select,
        label: s.rectangleSelect,
        tooltip: s.rectangleSelectToolDescription,
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.ellipseSelect,
        icon: AppIcons.circle,
        label: s.ellipseSelection,
        tooltip: s.ellipseSelectToolDescription,
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.lasso,
        icon: AppIcons.lasso,
        label: s.lasso,
        tooltip: s.lassoToolDescription,
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.smartSelect,
        icon: AppIcons.magic_stick,
        label: s.magicWand,
        tooltip: s.magicWandToolDescription,
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.curve,
        icon: AppIcons.curved_connector,
        label: s.curve,
        tooltip: s.curveToolDescription,
        isPro: !hasProFeature,
      ),
      ToolItem(
        tool: PixelTool.drag,
        icon: Feather.move,
        label: s.move,
        tooltip: s.moveToolDescription,
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
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
              maxLines: 1,
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
