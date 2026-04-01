import 'package:flutter/material.dart';
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
              IconButton(
                icon: AppIcon(
                  AppIcons.brush,
                  color: tool == PixelTool.brush ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.brush),
              ),
              IconButton(
                icon: AppIcon(
                  AppIcons.fill,
                  color: tool == PixelTool.fill ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.fill),
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
                  onPressed: !subscription.isPro
                      ? null
                      : () => onSelectTool(PixelTool.pen),
                ),
              ),
              ProBadge(
                show: !subscription.isPro,
                child: IconButton(
                  icon: AppIcon(
                    AppIcons.curved_connector,
                    color: tool == PixelTool.curve ? Colors.blue : null,
                  ),
                  onPressed: !subscription.isPro
                      ? null
                      : () => onSelectTool(PixelTool.curve),
                ),
              ),
              ProBadge(
                show: !subscription.isPro,
                child: IconButton(
                  icon: Icon(
                    Feather.move,
                    color: tool == PixelTool.drag ? Colors.blue : null,
                  ),
                  onPressed: !subscription.isPro
                      ? null
                      : () => onSelectTool(PixelTool.drag),
                ),
              ),
              IconButton(
                icon: Icon(
                  MaterialCommunityIcons.spray,
                  color: tool == PixelTool.sprayPaint ? Colors.blue : null,
                ),
                onPressed: () => onSelectTool(PixelTool.sprayPaint),
              ),
              Stack(
                fit: StackFit.passthrough,
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.texture,
                      color: tool == PixelTool.textureBrush ||
                              tool == PixelTool.textureFill
                          ? Colors.blue
                          : null,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 400,
                              maxHeight: 500,
                            ),
                            child: TextureBrushPanel(
                              isFill: tool == PixelTool.textureFill,
                              onTextureSelected: (texture, blendMode, isFill) {
                                Navigator.of(context).pop();
                                if (texture != null) {
                                  onTextureSelected?.call(
                                      texture, blendMode, isFill);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Texture Brush',
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Transform.rotate(
                      angle: -0.785398,
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShapesMenuButton extends StatelessWidget {
  final ValueNotifier<PixelTool> currentTool;
  final Function(PixelTool) onSelectTool;

  const ShapesMenuButton({
    super.key,
    required this.currentTool,
    required this.onSelectTool,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PixelTool>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            currentTool.value == PixelTool.line
                ? Icons.show_chart
                : currentTool.value == PixelTool.rectangle
                    ? Icons.crop_square
                    : Icons.radio_button_unchecked,
            color: _isShapeTool(currentTool.value) ? Colors.blue : null,
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Transform.rotate(
              angle: -0.785398,
              child: const Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
                size: 16,
              ),
            ),
          ),
        ],
      ),
      onSelected: (PixelTool result) {
        onSelectTool(result);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<PixelTool>>[
        PopupMenuItem<PixelTool>(
          value: PixelTool.line,
          child: ListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(Strings.of(context).lineTool),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.rectangle,
          child: ListTile(
            leading: const Icon(Icons.crop_square),
            title: Text(Strings.of(context).rectangleTool),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.circle,
          child: ListTile(
            leading: const Icon(Icons.radio_button_unchecked),
            title: Text(Strings.of(context).circleTool),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.triangle,
          child: ListTile(
            leading: Icon(Icons.change_history),
            title: Text('Triangle'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.diamond,
          child: ListTile(
            leading: Icon(Icons.diamond_outlined),
            title: Text('Diamond'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.hexagon,
          child: ListTile(
            leading: Icon(Icons.hexagon_outlined),
            title: Text('Hexagon'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.heart,
          child: ListTile(
            leading: Icon(Icons.favorite_border),
            title: Text('Heart'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.arrow,
          child: ListTile(
            leading: Icon(Icons.arrow_forward),
            title: Text('Arrow'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.lightning,
          child: ListTile(
            leading: Icon(Icons.flash_on),
            title: Text('Lightning'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.cross,
          child: ListTile(
            leading: Icon(Icons.add),
            title: Text('Cross'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.spiral,
          child: ListTile(
            leading: Icon(Icons.sync),
            title: Text('Spiral'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.cloud,
          child: ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Cloud'),
          ),
        ),
      ],
    );
  }

  bool _isShapeTool(PixelTool tool) {
    return tool == PixelTool.line ||
        tool == PixelTool.rectangle ||
        tool == PixelTool.circle;
  }
}

class SelectionToolsMenuButton extends StatelessWidget {
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

  Widget _buildCurrentIcon(Color? color) {
    switch (currentTool.value) {
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
  Widget build(BuildContext context) {
    final activeColor =
        _isSelectionTool(currentTool.value) ? Colors.blue : null;

    return PopupMenuButton<PixelTool>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCurrentIcon(activeColor),
          Positioned(
            right: -5,
            bottom: -5,
            child: Transform.rotate(
              angle: -0.785398,
              child: const Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
                size: 16,
              ),
            ),
          ),
        ],
      ),
      onSelected: onSelectTool,
      itemBuilder: (context) => [
        const PopupMenuItem<PixelTool>(
          value: PixelTool.select,
          child: ListTile(
            leading: AppIcon(AppIcons.select),
            title: Text('Rectangle Select'),
          ),
        ),
        PopupMenuItem<PixelTool>(
          value: PixelTool.ellipseSelect,
          child: ListTile(
            leading: const Icon(Icons.circle_outlined),
            title: Text(Strings.of(context).ellipseSelection),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.lasso,
          child: ListTile(
            leading: AppIcon(AppIcons.lasso),
            title: Text('Lasso'),
          ),
        ),
        const PopupMenuItem<PixelTool>(
          value: PixelTool.smartSelect,
          child: ListTile(
            leading: AppIcon(AppIcons.magic_stick),
            title: Text('Magic Wand'),
          ),
        ),
      ],
    );
  }
}
