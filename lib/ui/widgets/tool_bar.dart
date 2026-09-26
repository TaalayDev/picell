import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core.dart';
import '../../data.dart';
import '../../l10n/strings.dart';
import '../../config/assets.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/selection_region.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/tools.dart';
import '../../pixel/tools/texture_brush_tool.dart';
import '../../providers/editor_settings_provider.dart';
import 'app_icon.dart';
import 'dialogs/editor_settings_dialog.dart';
import 'dialogs/keyboard_shortcuts_dialog.dart';
import 'menu_value_field.dart';
import 'selection_mode_toggle.dart';
import 'selection_options_button.dart';
import 'wand_options_bar.dart';

class ToolBar extends ConsumerWidget {
  final ValueNotifier<PixelTool> currentTool;
  final ValueNotifier<PixelModifier> currentModifier;
  final ValueNotifier<int> brushSize;
  final ValueNotifier<int> sprayIntensity;
  final bool showPrevFrames;
  final Function(PixelTool) onSelectTool;
  final Function(PixelModifier) onSelectModifier;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? import;
  final VoidCallback? export;
  final VoidCallback? exportAsImage;
  final VoidCallback? onShare;
  final VoidCallback? onEffects;
  final VoidCallback? onTemplates;
  final Function(TexturePattern, BlendMode)? onTextureSelected;
  final Color currentColor;
  final Function() onColorPicker;
  final Function()? showPrevFramesOpacity;
  final double onionSkinOpacity;
  final ValueChanged<double>? onionSkinOpacityChanged;
  final bool currentLayerHasEffects; // Added flag to show if layer has effects
  final UserSubscription subscription;
  final Project project;
  final bool tileModeEnabled;
  final VoidCallback? onToggleTileMode;
  final VoidCallback? onCopySelection;
  final VoidCallback? onCutSelection;
  final VoidCallback? onPasteSelection;
  final bool canPaste;
  final VoidCallback? onShowHistory;
  final ValueNotifier<SelectionMode>? selectionMode;

  const ToolBar({
    super.key,
    required this.currentTool,
    required this.currentModifier,
    required this.brushSize,
    required this.sprayIntensity,
    required this.onSelectTool,
    required this.onSelectModifier,
    required this.onUndo,
    required this.onRedo,
    this.showPrevFrames = false,
    this.onZoomIn,
    this.onZoomOut,
    this.import,
    this.export,
    this.exportAsImage,
    this.onShare,
    this.onEffects,
    this.onTextureSelected,
    this.onTemplates,
    required this.currentColor,
    required this.onColorPicker,
    this.showPrevFramesOpacity,
    this.onionSkinOpacity = 0.5,
    this.onionSkinOpacityChanged,
    this.currentLayerHasEffects = false,
    required this.subscription,
    required this.project,
    this.tileModeEnabled = false,
    this.onToggleTileMode,
    this.onCopySelection,
    this.onCutSelection,
    this.onPasteSelection,
    this.canPaste = false,
    this.onShowHistory,
    this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(pixelCanvasNotifierProvider(project));
    final notifier = ref.read(pixelCanvasNotifierProvider(project).notifier);
    final hasSelection = canvasState.selectionState != null;

    final size = MediaQuery.sizeOf(context);
    final screenSize = ScreenSize.forWidth(size.width) ?? ScreenSize.xs;

    final editorSettings = ref.watch(editorSettingsNotifierProvider);

    return Container(
      height: 45,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          const SizedBox(width: 4),
          _TopBarMenuButton<_FileMenuAction>(
            key: const ValueKey('toolbar-file-menu'),
            label: Strings.of(context).fileMenu,
            icon: Feather.save,
            compact: screenSize.isMobile,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _FileMenuAction.import,
                child: ListTile(
                  leading: const AppIcon(AppIcons.album),
                  title: Text(Strings.of(context).open),
                ),
              ),
              if (kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.windows)
                PopupMenuItem(
                  value: _FileMenuAction.export,
                  child: ListTile(
                    leading: const AppIcon(AppIcons.archive_down),
                    title: Text(Strings.of(context).save),
                  ),
                ),
              PopupMenuItem(
                value: _FileMenuAction.exportAsImage,
                child: ListTile(
                  leading: const AppIcon(AppIcons.archive_down),
                  title: Text(Strings.of(context).saveAs),
                ),
              ),
              PopupMenuItem(
                value: _FileMenuAction.share,
                child: ListTile(
                  leading: const AppIcon(AppIcons.share),
                  title: Text(Strings.of(context).share),
                ),
              ),
              PopupMenuItem(
                value: _FileMenuAction.projects,
                child: ListTile(
                  leading: const AppIcon(AppIcons.home),
                  title: Text(Strings.of(context).projects),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _FileMenuAction.history,
                enabled: onShowHistory != null,
                child: ListTile(
                  leading: const Icon(Icons.history_rounded, size: 20),
                  title: Text(Strings.of(context).undoHistoryTitle),
                ),
              ),
              PopupMenuItem(
                value: _FileMenuAction.keyboardShortcuts,
                child: ListTile(
                  leading: const Icon(Icons.keyboard_rounded, size: 20),
                  title: Text(Strings.of(context).keyboardShortcuts),
                ),
              ),
              PopupMenuItem(
                value: _FileMenuAction.settings,
                child: ListTile(
                  leading: const Icon(Icons.settings, size: 20),
                  title: Text(Strings.of(context).editorSettings),
                  trailing: editorSettings.isStylusMode
                      ? Icon(
                          Icons.circle,
                          size: 8,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _FileMenuAction.import:
                  import?.call();
                case _FileMenuAction.export:
                  export?.call();
                case _FileMenuAction.exportAsImage:
                  exportAsImage?.call();
                case _FileMenuAction.share:
                  onShare?.call();
                case _FileMenuAction.projects:
                  Navigator.of(context).pop();
                case _FileMenuAction.history:
                  onShowHistory?.call();
                case _FileMenuAction.keyboardShortcuts:
                  KeyboardShortcutsDialog.show(context);
                case _FileMenuAction.settings:
                  EditorSettingsDialog.show(context);
              }
            },
          ),
          _TopBarMenuButton<_ViewMenuAction>(
            key: const ValueKey('toolbar-view-menu'),
            label: Strings.of(context).view,
            icon: Icons.visibility_outlined,
            compact: screenSize.isMobile,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: _ViewMenuAction.tileMode,
                checked: tileModeEnabled,
                enabled: onToggleTileMode != null,
                child: Text(Strings.of(context).tileModeTooltip),
              ),
              CheckedPopupMenuItem(
                value: _ViewMenuAction.pixelGrid,
                checked: editorSettings.showPixelGrid,
                child: Text(Strings.of(context).showGrid),
              ),
              CheckedPopupMenuItem(
                value: _ViewMenuAction.onionSkin,
                checked: showPrevFrames,
                enabled: showPrevFramesOpacity != null,
                child: Text(Strings.of(context).onionSkinTooltip),
              ),
              PopupMenuItem(
                value: _ViewMenuAction.onionSkinOpacity,
                enabled: onionSkinOpacityChanged != null,
                child: const ListTile(
                  leading: Icon(Icons.opacity_rounded, size: 20),
                  title: Text('Onion skin opacity'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ViewMenuAction.zoomIn,
                enabled: onZoomIn != null,
                child: ListTile(
                  leading: const Icon(Feather.zoom_in, size: 20),
                  title: Text(Strings.of(context).zoomIn),
                ),
              ),
              PopupMenuItem(
                value: _ViewMenuAction.zoomOut,
                enabled: onZoomOut != null,
                child: ListTile(
                  leading: const Icon(Feather.zoom_out, size: 20),
                  title: Text(Strings.of(context).zoomOut),
                ),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _ViewMenuAction.tileMode:
                  onToggleTileMode?.call();
                case _ViewMenuAction.pixelGrid:
                  ref
                      .read(editorSettingsNotifierProvider.notifier)
                      .setShowPixelGrid(!editorSettings.showPixelGrid);
                case _ViewMenuAction.onionSkin:
                  showPrevFramesOpacity?.call();
                case _ViewMenuAction.onionSkinOpacity:
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Onion skin opacity'),
                      content: _OpacitySlider(
                        opacity: onionSkinOpacity,
                        onChanged: onionSkinOpacityChanged,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(Strings.of(context).done),
                        ),
                      ],
                    ),
                  );
                case _ViewMenuAction.zoomIn:
                  onZoomIn?.call();
                case _ViewMenuAction.zoomOut:
                  onZoomOut?.call();
              }
            },
          ),
          _TopBarMenuButton<_AddMenuAction>(
            key: const ValueKey('toolbar-add-menu'),
            label: Strings.of(context).add,
            icon: Icons.add_box_outlined,
            compact: screenSize.isMobile,
            hasNotification: currentLayerHasEffects,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _AddMenuAction.effects,
                enabled: onEffects != null,
                child: ListTile(
                  leading: const Icon(Icons.auto_fix_high, size: 20),
                  title: Text(Strings.of(context).effects),
                  trailing: currentLayerHasEffects
                      ? Icon(
                          Icons.circle,
                          size: 8,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),
              PopupMenuItem(
                value: _AddMenuAction.templates,
                enabled: onTemplates != null,
                child: ListTile(
                  leading: const AppIcon(AppIcons.gallery_wide, size: 20),
                  title: Text(Strings.of(context).templateGallery),
                ),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _AddMenuAction.effects:
                  onEffects?.call();
                case _AddMenuAction.templates:
                  onTemplates?.call();
              }
            },
          ),
          _ActiveViewIndicators(
            tileModeEnabled: tileModeEnabled,
            pixelGridEnabled: editorSettings.showPixelGrid,
            onionSkinEnabled: showPrevFrames,
          ),
          VerticalDivider(
            width: 8,
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ValueListenableBuilder<PixelTool>(
                valueListenable: currentTool,
                builder: (context, tool, child) {
                  return Row(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: currentModifier,
                        builder: (context, modifier, child) {
                          return IconButton(
                            icon: SvgPicture.asset(
                              Assets.vectors.reflectSymmetry,
                              colorFilter: ColorFilter.mode(
                                modifier == PixelModifier.mirror
                                    ? Colors.blue
                                    : IconTheme.of(context).color ??
                                        Theme.of(context).colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                              width: 24,
                              height: 24,
                            ),
                            onPressed: () {
                              onSelectModifier(
                                modifier == PixelModifier.mirror
                                    ? PixelModifier.none
                                    : PixelModifier.mirror,
                              );
                            },
                          );
                        },
                      ),
                      if (!screenSize.isMobile) ...[
                        if (tool == PixelTool.brush ||
                            tool == PixelTool.eraser ||
                            tool == PixelTool.sprayPaint ||
                            tool == PixelTool.pencil) ...[
                          MenuToolValueField(
                            value: brushSize.value,
                            min: 1,
                            max: 10,
                            icon: const Icon(Icons.brush, size: 18),
                            child: Text('${brushSize.value}px'),
                            onChanged: (value) {
                              brushSize.value = value;
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (tool == PixelTool.sprayPaint) ...[
                          MenuToolValueField(
                            value: sprayIntensity.value,
                            min: 1,
                            max: 10,
                            icon: const Icon(MaterialCommunityIcons.spray),
                            child: Text(sprayIntensity.value.toString()),
                            onChanged: (value) {
                              sprayIntensity.value = value;
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (selectionMode != null &&
                            (tool == PixelTool.select ||
                                tool == PixelTool.ellipseSelect ||
                                tool == PixelTool.lasso ||
                                tool == PixelTool.smartSelect)) ...[
                          SelectionModeToggle(mode: selectionMode!),
                          const SizedBox(width: 8),
                        ],
                        if (tool == PixelTool.smartSelect) ...[
                          const WandOptionsBar(),
                          const SizedBox(width: 8),
                        ],
                      ],
                      if (!screenSize.isMobile)
                        SelectionOptionsButton(
                          hasSelection: hasSelection,
                          onClearSelection: () => notifier.clearSelection(),
                          onDelete: () => notifier.clearSelectionArea(),
                          onCutToNewLayer: () => notifier.cutToNewLayer(),
                          onCopyToNewLayer: () => notifier.copyToNewLayer(),
                          onCopy: onCopySelection,
                          onCut: onCutSelection,
                          onPaste: canPaste ? onPasteSelection : null,
                          onInvert: () => notifier.invertSelection(),
                          onGrow: () => notifier.growSelection(),
                          onShrink: () => notifier.shrinkSelection(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.undo,
              color: onUndo != null ? null : Colors.grey,
            ),
            onPressed: onUndo,
            tooltip: Strings.of(context).undo,
          ),
          IconButton(
            icon: Icon(
              Icons.redo,
              color: onRedo != null ? null : Colors.grey,
            ),
            onPressed: onRedo,
            tooltip: Strings.of(context).redo,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

enum _FileMenuAction {
  import,
  export,
  exportAsImage,
  share,
  projects,
  history,
  keyboardShortcuts,
  settings,
}

enum _ViewMenuAction {
  tileMode,
  pixelGrid,
  onionSkin,
  onionSkinOpacity,
  zoomIn,
  zoomOut,
}

enum _AddMenuAction {
  effects,
  templates,
}

class _TopBarMenuButton<T> extends StatelessWidget {
  const _TopBarMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.compact,
    required this.itemBuilder,
    required this.onSelected,
    this.hasNotification = false,
  });

  final String label;
  final IconData icon;
  final bool compact;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: label,
      offset: const Offset(0, 40),
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: compact ? 40 : 64),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 18),
                  if (hasNotification)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(width: 5),
                Text(label),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveViewIndicators extends StatelessWidget {
  const _ActiveViewIndicators({
    required this.tileModeEnabled,
    required this.pixelGridEnabled,
    required this.onionSkinEnabled,
  });

  final bool tileModeEnabled;
  final bool pixelGridEnabled;
  final bool onionSkinEnabled;

  @override
  Widget build(BuildContext context) {
    final active = <({IconData icon, String label})>[
      if (tileModeEnabled)
        (icon: Icons.grid_view_rounded, label: 'Tile mode is active'),
      if (pixelGridEnabled)
        (icon: Icons.grid_on_rounded, label: 'Pixel grid is active'),
      if (onionSkinEnabled)
        (icon: Icons.animation_rounded, label: 'Onion skin is active'),
    ];

    if (active.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('toolbar-active-view-indicators'),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in active)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: item.label,
                child: Icon(
                  item.icon,
                  size: 14,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpacitySlider extends StatefulWidget {
  const _OpacitySlider({required this.opacity, this.onChanged});
  final double opacity;
  final ValueChanged<double>? onChanged;

  @override
  State<_OpacitySlider> createState() => _OpacitySliderState();
}

class _OpacitySliderState extends State<_OpacitySlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.opacity;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onion skin opacity',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _value,
                  min: 0.05,
                  max: 1.0,
                  divisions: 19,
                  onChanged: (v) {
                    setState(() => _value = v);
                    widget.onChanged?.call(v);
                  },
                ),
              ),
              Text(
                '${(_value * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick toggle for pixel grid overlay, with a dot indicator when active.
