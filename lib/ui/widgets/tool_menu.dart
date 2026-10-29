import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/editor_tool_memory_provider.dart';
import 'grouped_tool_button.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
import '../../pixel/tools.dart';
import '../../pixel/tools/texture_brush_tool.dart';
import 'app_icon.dart';
import 'subscription/feature_gate.dart';
import 'panel/texture_brush_panel.dart';

class ToolMenu extends StatelessWidget {
  final ValueNotifier<PixelTool> currentTool;
  final Function(PixelTool) onSelectTool;
  final Function() onColorPicker;
  final Function(TexturePattern, BlendMode, bool isFill)? onTextureSelected;
  final Color currentColor;
  final UserSubscription subscription;

  const ToolMenu({
    super.key,
    required this.currentTool,
    required this.onSelectTool,
    required this.onColorPicker,
    required this.onTextureSelected,
    required this.currentColor,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PixelTool>(
      valueListenable: currentTool,
      builder: (context, tool, child) {
        return IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              iconSize: 18,
            ),
          ),
          child: Column(
            spacing: 15,
            children: [
              IconButton(
                icon: AppIcon(
                  AppIcons.pencil,
                  color: tool == PixelTool.pencil ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.pencil),
              ),
              // IconButton(
              //   icon: AppIcon(
              //     AppIcons.brush,
              //     color: tool == PixelTool.brush ? Colors.blue : null,
              //   ),
              //   onPressed: () => onSelectTool(PixelTool.brush),
              // ),
              IconButton(
                icon: AppIcon(
                  AppIcons.fill,
                  color: tool == PixelTool.fill ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.fill),
              ),
              IconButton(
                key: const ValueKey('tool-menu-gradient'),
                tooltip: Strings.of(context).gradient,
                icon: Icon(
                  Icons.gradient,
                  color: tool == PixelTool.gradient ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.gradient),
              ),
              IconButton(
                icon: AppIcon(
                  AppIcons.eraser,
                  color: tool == PixelTool.eraser ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.eraser),
              ),
              ShapesMenuButton(
                currentTool: currentTool,
                onSelectTool: onSelectTool,
              ),
              ProBadge(
                show: false,
                child: SelectionToolsMenuButton(
                  currentTool: currentTool,
                  onSelectTool: onSelectTool,
                ),
              ),
              ProBadge(
                show: !subscription.isPro,
                child: IconButton(
                  icon: AppIcon(
                    AppIcons.pen,
                    color: tool == PixelTool.pen ? Colors.blue : null,
                  ),
                  onPressed: !subscription.isPro ? null : () => onSelectTool(PixelTool.pen),
                ),
              ),
              ProBadge(
                show: !subscription.isPro,
                child: IconButton(
                  icon: AppIcon(
                    AppIcons.curved_connector,
                    color: tool == PixelTool.curve ? Colors.blue : null,
                  ),
                  onPressed: !subscription.isPro ? null : () => onSelectTool(PixelTool.curve),
                ),
              ),
              ProBadge(
                show: !subscription.isPro,
                child: IconButton(
                  icon: Icon(
                    Feather.move,
                    color: tool == PixelTool.drag ? Colors.blue : null,
                  ),
                  onPressed: !subscription.isPro ? null : () => onSelectTool(PixelTool.drag),
                ),
              ),
              IconButton(
                icon: Icon(
                  MaterialCommunityIcons.spray,
                  color: tool == PixelTool.sprayPaint ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.sprayPaint),
              ),
              TextureToolsMenuButton(
                currentTool: currentTool,
                onTextureSelected: onTextureSelected,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShapesMenuButton extends ConsumerWidget {
  final ValueNotifier<PixelTool> currentTool;
  final Function(PixelTool) onSelectTool;

  const ShapesMenuButton({
    super.key,
    required this.currentTool,
    required this.onSelectTool,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remembered = ref.watch(editorToolMemoryProvider).shape;
    final selected = shapeTools.contains(currentTool.value) ? currentTool.value : remembered;
    final active = shapeTools.contains(currentTool.value);
    final menuKey = GlobalKey<PopupMenuButtonState<PixelTool>>();
    return PopupMenuButton<PixelTool>(
      key: menuKey,
      initialValue: selected,
      child: GroupedToolButton(
        group: 'shape-tool',
        icon: Icon(_shapeIcon(selected), color: active ? Theme.of(context).colorScheme.primary : null),
        onActivate: () => onSelectTool(selected),
        onOpenMenu: () => menuKey.currentState?.showButtonMenu(),
      ),
      onSelected: (result) {
        ref.read(editorToolMemoryProvider.notifier).rememberTool(result);
        onSelectTool(result);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<PixelTool>>[
        PopupMenuItem<PixelTool>(
          value: PixelTool.line,
          child: ListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(Strings.of(context).lineTool),
            trailing: Text(
              'L',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.rectangle,
          child: ListTile(
            leading: const Icon(Icons.crop_square),
            title: Text(Strings.of(context).rectangleTool),
            trailing: Text(
              'U',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.circle,
          child: ListTile(
            leading: const Icon(Icons.radio_button_unchecked),
            title: Text(Strings.of(context).circleTool),
            trailing: Text(
              'O',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<PixelTool>(
          value: PixelTool.triangle,
          child: ListTile(
            leading: const Icon(Icons.change_history),
            title: Text(Strings.of(context).triangle),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.diamond,
          child: ListTile(
            leading: const Icon(Icons.diamond_outlined),
            title: Text(Strings.of(context).diamond),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.hexagon,
          child: ListTile(
            leading: const Icon(Icons.hexagon_outlined),
            title: Text(Strings.of(context).hexagon),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<PixelTool>(
          value: PixelTool.heart,
          child: ListTile(
            leading: const Icon(Icons.favorite_border),
            title: Text(Strings.of(context).heart),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.arrow,
          child: ListTile(
            leading: const Icon(Icons.arrow_forward),
            title: Text(Strings.of(context).arrow),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.lightning,
          child: ListTile(
            leading: const Icon(Icons.flash_on),
            title: Text(Strings.of(context).lightning),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.cross,
          child: ListTile(
            leading: const Icon(Icons.add),
            title: Text(Strings.of(context).cross),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<PixelTool>(
          value: PixelTool.spiral,
          child: ListTile(
            leading: const Icon(Icons.sync),
            title: Text(Strings.of(context).spiral),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.cloud,
          child: ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(Strings.of(context).cloudShape),
          ),
        ),
      ],
    );
  }

  IconData _shapeIcon(PixelTool tool) => switch (tool) {
        PixelTool.line => Icons.show_chart,
        PixelTool.rectangle => Icons.crop_square,
        PixelTool.triangle => Icons.change_history,
        PixelTool.diamond => Icons.diamond_outlined,
        PixelTool.hexagon => Icons.hexagon_outlined,
        PixelTool.heart => Icons.favorite_border,
        PixelTool.arrow => Icons.arrow_forward,
        PixelTool.lightning => Icons.flash_on,
        PixelTool.cross => Icons.add,
        PixelTool.spiral => Icons.sync,
        PixelTool.cloud => Icons.cloud_outlined,
        _ => Icons.radio_button_unchecked,
      };
}

class SelectionToolsMenuButton extends ConsumerWidget {
  final ValueNotifier<PixelTool> currentTool;
  final Function(PixelTool) onSelectTool;

  const SelectionToolsMenuButton({
    super.key,
    required this.currentTool,
    required this.onSelectTool,
  });

  bool _isSelectionTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso ||
        tool == PixelTool.smartSelect;
  }

  Widget _buildCurrentIcon(PixelTool tool, Color? color) {
    switch (tool) {
      case PixelTool.ellipseSelect:
        return Icon(Icons.circle_outlined, color: color);
      case PixelTool.lasso:
        return AppIcon(AppIcons.lasso, color: color);
      case PixelTool.smartSelect:
        return AppIcon(AppIcons.magic_stick, color: color);
      case PixelTool.select:
      default:
        return AppIcon(AppIcons.select, color: color);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remembered = ref.watch(editorToolMemoryProvider).selection;
    final selected = selectionTools.contains(currentTool.value) ? currentTool.value : remembered;
    final activeColor = _isSelectionTool(currentTool.value) ? Theme.of(context).colorScheme.primary : null;
    final menuKey = GlobalKey<PopupMenuButtonState<PixelTool>>();
    return PopupMenuButton<PixelTool>(
      key: menuKey,
      initialValue: selected,
      child: GroupedToolButton(
        group: 'selection-tool',
        icon: _buildCurrentIcon(selected, activeColor),
        onActivate: () => onSelectTool(selected),
        onOpenMenu: () => menuKey.currentState?.showButtonMenu(),
      ),
      onSelected: (result) {
        ref.read(editorToolMemoryProvider.notifier).rememberTool(result);
        onSelectTool(result);
      },
      itemBuilder: (context) => [
        PopupMenuItem<PixelTool>(
          value: PixelTool.select,
          child: ListTile(
            leading: const AppIcon(AppIcons.select),
            title: Text(Strings.of(context).rectangleSelect),
            trailing: Text(
              'M',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.ellipseSelect,
          child: ListTile(
            leading: const Icon(Icons.circle_outlined),
            title: Text(Strings.of(context).ellipseSelection),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.lasso,
          child: ListTile(
            leading: const AppIcon(AppIcons.lasso),
            title: Text(Strings.of(context).lasso),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.smartSelect,
          child: ListTile(
            leading: const AppIcon(AppIcons.magic_stick),
            title: Text(Strings.of(context).magicWand),
          ),
        ),
      ],
    );
  }
}

class TextureToolsMenuButton extends ConsumerWidget {
  const TextureToolsMenuButton({super.key, required this.currentTool, required this.onTextureSelected});

  final ValueNotifier<PixelTool> currentTool;
  final Function(TexturePattern, BlendMode, bool isFill)? onTextureSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memory = ref.watch(editorToolMemoryProvider);
    final active = currentTool.value == PixelTool.textureBrush || currentTool.value == PixelTool.textureFill;
    void apply(TexturePattern texture, BlendMode blendMode, bool isFill) {
      ref.read(editorToolMemoryProvider.notifier).rememberTexture(texture, blendMode, isFill);
      onTextureSelected?.call(texture, blendMode, isFill);
    }

    void openOptions() {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: TextureBrushPanel(
              selectedTextureId: memory.texture?.id,
              blendMode: memory.blendMode,
              isFill: memory.isTextureFill,
              onBlendModeChanged: (_) {},
              onTextureSelected: (texture, blendMode, isFill) {
                if (texture == null) return;
                Navigator.of(dialogContext).pop();
                apply(texture, blendMode, isFill);
              },
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: Strings.of(context).textureBrush,
      child: GroupedToolButton(
        group: 'texture-tool',
        icon: Icon(memory.isTextureFill ? Icons.format_color_fill : Icons.texture,
            color: active ? Theme.of(context).colorScheme.primary : null),
        onActivate:
            memory.texture == null ? openOptions : () => apply(memory.texture!, memory.blendMode, memory.isTextureFill),
        onOpenMenu: openOptions,
      ),
    );
  }
}
