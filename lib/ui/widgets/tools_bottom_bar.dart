import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../data/models/subscription_model.dart';
import '../../pixel/pixel_canvas_state.dart';
import '../../pixel/tools.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../l10n/strings.dart';
import 'app_icon.dart';
import 'panel/mobile_side_panel_bottom_sheet.dart';
import 'styled_tool_bottom_sheet.dart';

class ToolsBottomBar extends HookWidget {
  const ToolsBottomBar({
    super.key,
    required this.currentTool,
    required this.state,
    required this.notifier,
    required this.width,
    required this.height,
    required this.subscription,
    this.onLayerSelectionChanged,
  });

  final ValueNotifier<PixelTool> currentTool;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final UserSubscription subscription;
  final int width;
  final int height;
  final ValueChanged<List<int>>? onLayerSelectionChanged;

  @override
  Widget build(BuildContext context) {
    // Workaround for the issue with the bottom sheet not updating
    // when the state changes. This is a temporary solution
    final drawState = useState(state);

    final showExtraTools = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        drawState.value = state;
      });
      return null;
    }, [state]);

    const extraTools = {
      PixelTool.sprayPaint: (AppIcons.spray, 'Spray'),
      PixelTool.line: (AppIcons.line, 'Line'),
      PixelTool.circle: (AppIcons.circle, 'Circle'),
      PixelTool.rectangle: (AppIcons.rectangle, 'Rectangle'),
      PixelTool.pen: (AppIcons.pen, 'Pen'),
      PixelTool.select: (AppIcons.select, 'Select'),
      PixelTool.curve: (AppIcons.curved_connector, 'Curve'),
    };

    return BottomAppBar(
      height: showExtraTools.value ? 90 : 45,
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(0),
            iconSize: 18,
          ),
        ),
        child: Column(
          children: [
            if (showExtraTools.value)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: extraTools.entries.map((entry) {
                    final tool = entry.key;
                    final iconData = entry.value.$1;
                    final label = entry.value.$2;

                    return IconButton(
                      icon: AppIcon(iconData),
                      color: currentTool.value == tool ? Colors.blue : null,
                      onPressed: () {
                        currentTool.value = tool;
                        showExtraTools.value = false; // Close the extra tools
                      },
                      tooltip: label,
                    );
                  }).toList(),
                ).animate().fadeIn(duration: const Duration(milliseconds: 200)),
              ),
            if (showExtraTools.value)
              Divider(
                  color: Colors.grey.withValues(alpha: 0.5), thickness: 0.1),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const AppIcon(AppIcons.pencil),
                    color: currentTool.value == PixelTool.pencil
                        ? Colors.blue
                        : null,
                    onPressed: () async {
                      currentTool.value = PixelTool.pencil;
                    },
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.eraser),
                    color: currentTool.value == PixelTool.eraser
                        ? Colors.blue
                        : null,
                    onPressed: () {
                      currentTool.value = PixelTool.eraser;
                    },
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.fill),
                    color: currentTool.value == PixelTool.fill
                        ? Colors.blue
                        : null,
                    onPressed: () {
                      currentTool.value = PixelTool.fill;
                    },
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.lasso),
                    color: currentTool.value == PixelTool.lasso
                        ? Colors.blue
                        : null,
                    onPressed: () {
                      currentTool.value = PixelTool.lasso;
                    },
                  ),
                  IconButton(
                    key: const ValueKey('tools-bottom-bar-layers'),
                    icon: const AppIcon(AppIcons.layers),
                    tooltip: Strings.of(context).layers,
                    onPressed: () {
                      MobileSidePanelBottomSheet.show(
                        context,
                        drawState: drawState,
                        notifier: notifier,
                        width: width,
                        height: height,
                        onLayerSelectionChanged: onLayerSelectionChanged,
                      );
                    },
                  ),
                  IconButton(
                    color: extraTools.containsKey(currentTool.value)
                        ? Colors.blue
                        : null,
                    onPressed: () async {
                      showStyledToolBottomSheet(context, currentTool);
                    },
                    icon: const AppIcon(AppIcons.unfold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<PixelTool?> showStyledToolBottomSheet(
    BuildContext context,
    ValueNotifier<PixelTool> currentTool,
  ) {
    return showModalBottomSheet<PixelTool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StyledToolBottomSheet(currentTool: currentTool),
    );
  }
}
