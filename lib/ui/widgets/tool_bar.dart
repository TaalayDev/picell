import 'dart:math' as math;
import 'dart:async';
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
import '../../pixel/effects/effects.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/tools.dart';
import '../../pixel/tools/texture_brush_tool.dart';
import '../../providers/editor_settings_provider.dart';
import 'app_icon.dart';
import 'dialogs/editor_settings_dialog.dart';
import 'dialogs/keyboard_shortcuts_dialog.dart';
import 'effects/effect_animation_generator_dialog.dart';
import 'effects/effects_editor_dialog.dart';
import 'effects/effects_selector_dialog.dart';
import 'menu_value_field.dart';
import 'pen_path_actions.dart';
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
  final VoidCallback? onZoomFit;
  final VoidCallback? onZoom100;
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
  final VoidCallback? onFinishPenPath;
  final VoidCallback? onCancelPenPath;

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
    this.onZoomFit,
    this.onZoom100,
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
    this.onFinishPenPath,
    this.onCancelPenPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(pixelCanvasNotifierProvider(project));
    final notifier = ref.read(pixelCanvasNotifierProvider(project).notifier);
    final hasSelection = canvasState.selectionState != null;

    final size = MediaQuery.sizeOf(context);
    final screenSize = ScreenSize.forWidth(size.width) ?? ScreenSize.xs;

    final editorSettings = ref.watch(editorSettingsNotifierProvider);

    void openEffectSelector(
      EffectWorkspace workspace, {
      FilterKind? filterKind,
      AnimationKind? animationKind,
    }) {
      final parentContext = context;
      EffectSelectorDialog.present(
        context: context,
        builder: (context) => EffectSelectorDialog(
          initialWorkspace: workspace,
          lockWorkspace: true,
          initialFilterKind: filterKind,
          lockFilterKind: filterKind != null,
          initialAnimationKind: animationKind,
          lockAnimationKind: animationKind != null,
          layer: notifier.currentLayer,
          onEffectSelected: (effect) {
            final descriptor = EffectCatalog.forType(effect.type);
            if (descriptor.workspace == EffectWorkspace.animation) {
              final sourceFrame = notifier.currentFrame;
              final sourceLayer = notifier.currentLayer;
              EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
                context,
                effect: effect,
                effects: [...sourceLayer.effects, effect],
                effectIndex: sourceLayer.effects.length,
                layerWidth: project.width,
                layerHeight: project.height,
                layerPixels: sourceLayer.pixels,
                onFramesGenerated: (frames) => notifier.addGeneratedEffectFrames(
                  frames,
                  sourceFrameId: sourceFrame.id,
                  sourceLayerId: sourceLayer.layerId,
                ),
              );
              return;
            }
            if (descriptor.workspace == EffectWorkspace.generators) {
              final sourceLayer = notifier.currentLayer;
              EffectEditorDialog.show(
                context: context,
                effect: effect,
                layerWidth: project.width,
                layerHeight: project.height,
                layerPixels: sourceLayer.pixels,
                applyButtonText: Strings.of(context).apply,
                onApply: (configuredEffect) {
                  notifier.applyEffectToLayer(configuredEffect);
                  AppNotification.success(
                    parentContext,
                    Strings.of(parentContext).effectsPanelAppliedToLayerMessage(
                      configuredEffect.getName(parentContext),
                    ),
                    duration: const Duration(seconds: 2),
                  );
                },
              );
              return;
            }
            notifier.addLayerEffect(effect);
          },
        ),
      );
    }

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
              _TopBarMenuItem(
                value: _FileMenuAction.import,
                icon: const AppIcon(AppIcons.album, size: 18),
                title: Strings.of(context).open,
                shortcut: _cmd('O'),
              ),
              if (kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.windows)
                _TopBarMenuItem(
                  value: _FileMenuAction.export,
                  icon: const AppIcon(AppIcons.archive_down, size: 18),
                  title: Strings.of(context).save,
                  shortcut: _cmd('S'),
                ),
              _TopBarMenuItem(
                value: _FileMenuAction.exportAsImage,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                title: Strings.of(context).saveAs,
                shortcut: _cmd('E'),
              ),
              _TopBarMenuItem(
                value: _FileMenuAction.share,
                icon: const AppIcon(AppIcons.share, size: 18),
                title: Strings.of(context).share,
              ),
              _TopBarMenuItem(
                value: _FileMenuAction.projects,
                icon: const AppIcon(AppIcons.home, size: 18),
                title: Strings.of(context).projects,
              ),
              const PopupMenuDivider(),
              _TopBarMenuItem(
                value: _FileMenuAction.history,
                enabled: onShowHistory != null,
                icon: const Icon(Icons.history_rounded, size: 18),
                title: Strings.of(context).undoHistoryTitle,
                shortcut: _cmd('H'),
              ),
              _TopBarMenuItem(
                value: _FileMenuAction.keyboardShortcuts,
                icon: const Icon(Icons.keyboard_rounded, size: 18),
                title: Strings.of(context).keyboardShortcuts,
                shortcut: '?',
              ),
              _TopBarMenuItem(
                value: _FileMenuAction.settings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                title: Strings.of(context).editorSettings,
                shortcut: _cmd(','),
                hasNotification: editorSettings.isStylusMode,
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
              _TopBarMenuItem(
                value: _ViewMenuAction.tileMode,
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                title: Strings.of(context).tileModeTooltip,
                shortcut: _shift('T'),
                isChecked: tileModeEnabled,
                enabled: onToggleTileMode != null,
              ),
              _TopBarMenuItem(
                value: _ViewMenuAction.pixelGrid,
                icon: const Icon(Icons.grid_on_rounded, size: 18),
                title: Strings.of(context).showGrid,
                shortcut: _cmd("'"),
                isChecked: editorSettings.showPixelGrid,
              ),
              _TopBarMenuItem(
                value: _ViewMenuAction.onionSkin,
                icon: const Icon(Icons.animation_rounded, size: 18),
                title: Strings.of(context).onionSkinTooltip,
                shortcut: _shift('O'),
                isChecked: showPrevFrames,
                enabled: showPrevFramesOpacity != null,
              ),
              _TopBarMenuItem(
                value: _ViewMenuAction.onionSkinOpacity,
                icon: const Icon(Icons.opacity_rounded, size: 18),
                title: 'Onion skin opacity',
                enabled: onionSkinOpacityChanged != null,
              ),
              const PopupMenuDivider(),
              _TopBarMenuItem(
                value: _ViewMenuAction.zoomIn,
                icon: const Icon(Feather.zoom_in, size: 18),
                title: Strings.of(context).zoomIn,
                shortcut: '+',
                enabled: onZoomIn != null,
              ),
              _TopBarMenuItem(
                value: _ViewMenuAction.zoomOut,
                icon: const Icon(Feather.zoom_out, size: 18),
                title: Strings.of(context).zoomOut,
                shortcut: '-',
                enabled: onZoomOut != null,
              ),
              if (onZoomFit != null)
                _TopBarMenuItem(
                  value: _ViewMenuAction.zoomFit,
                  icon: const Icon(Icons.fit_screen_outlined, size: 18),
                  title: Strings.of(context).zoomToFit,
                  shortcut: '0',
                ),
              if (onZoom100 != null)
                _TopBarMenuItem(
                  value: _ViewMenuAction.zoom100,
                  icon: const Icon(Icons.aspect_ratio_outlined, size: 18),
                  title: Strings.of(context).zoomOneToOne,
                  shortcut: '1',
                ),
            ],
            onSelected: (action) {
              switch (action) {
                case _ViewMenuAction.tileMode:
                  onToggleTileMode?.call();
                case _ViewMenuAction.pixelGrid:
                  ref.read(editorSettingsNotifierProvider.notifier).setShowPixelGrid(!editorSettings.showPixelGrid);
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
                case _ViewMenuAction.zoomFit:
                  onZoomFit?.call();
                case _ViewMenuAction.zoom100:
                  onZoom100?.call();
              }
            },
          ),
          _TopBarMenuButton<_AddMenuAction>(
            key: const ValueKey('toolbar-add-menu'),
            label: Strings.of(context).add,
            icon: Icons.add_box_outlined,
            compact: screenSize.isMobile,
            itemBuilder: (context) => [
              _SubmenuTopBarMenuItem(
                key: const ValueKey('toolbar-add-filters'),
                icon: const Icon(Icons.filter_alt_outlined, size: 18),
                title: Strings.of(context).effectWorkspaceFilters,
                items: [
                  _SubmenuItem(
                    key: const ValueKey('toolbar-add-filter-effects'),
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    title: Strings.of(context).effectWorkspaceFilters,
                    shortcut: _alt('1'),
                    onTap: () {
                      openEffectSelector(
                        EffectWorkspace.filters,
                        filterKind: FilterKind.filter,
                      );
                    },
                  ),
                  _SubmenuItem(
                    key: const ValueKey('toolbar-add-distortions'),
                    icon: const Icon(Icons.waves_outlined, size: 18),
                    title: Strings.of(context).effectWorkspaceDistortions,
                    shortcut: _alt('7'),
                    onTap: () {
                      openEffectSelector(
                        EffectWorkspace.filters,
                        filterKind: FilterKind.distortion,
                      );
                    },
                  ),
                ],
              ),
              _TopBarMenuItem(
                key: const ValueKey('toolbar-add-materials'),
                value: _AddMenuAction.materials,
                icon: const Icon(Icons.texture_outlined, size: 18),
                title: Strings.of(context).effectWorkspaceMaterials,
                shortcut: _alt('2'),
              ),
              _TopBarMenuItem(
                key: const ValueKey('toolbar-add-generators'),
                value: _AddMenuAction.generators,
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                title: Strings.of(context).effectWorkspaceGenerators,
                shortcut: _alt('3'),
              ),
              _SubmenuTopBarMenuItem(
                key: const ValueKey('toolbar-add-animation'),
                icon: const Icon(Icons.auto_awesome_motion_outlined, size: 18),
                title: Strings.of(context).effectWorkspaceAnimation,
                items: [
                  _SubmenuItem(
                    key: const ValueKey('toolbar-add-animation-transformers'),
                    icon: const Icon(Icons.transform, size: 18),
                    title: Strings.of(context).animationTransformers,
                    shortcut: _alt('4'),
                    onTap: () {
                      openEffectSelector(
                        EffectWorkspace.animation,
                        animationKind: AnimationKind.transformer,
                      );
                    },
                  ),
                  _SubmenuItem(
                    key: const ValueKey('toolbar-add-animation-special-effects'),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    title: Strings.of(context).animationSpecialEffects,
                    shortcut: _alt('5'),
                    onTap: () {
                      openEffectSelector(
                        EffectWorkspace.animation,
                        animationKind: AnimationKind.specialEffect,
                      );
                    },
                  ),
                ],
              ),
              _TopBarMenuItem(
                key: const ValueKey('toolbar-add-lighting'),
                value: _AddMenuAction.lighting,
                icon: const Icon(Icons.light_mode_outlined, size: 18),
                title: Strings.of(context).effectWorkspaceLighting,
                shortcut: _alt('6'),
              ),
              const PopupMenuDivider(),
              _TopBarMenuItem(
                value: _AddMenuAction.templates,
                icon: const AppIcon(AppIcons.gallery_wide, size: 18),
                title: Strings.of(context).templateGallery,
                enabled: onTemplates != null,
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _AddMenuAction.materials:
                  openEffectSelector(EffectWorkspace.materials);
                case _AddMenuAction.generators:
                  openEffectSelector(EffectWorkspace.generators);
                case _AddMenuAction.lighting:
                  openEffectSelector(EffectWorkspace.lighting);
                case _AddMenuAction.templates:
                  onTemplates?.call();
              }
            },
          ),
          _ActiveViewIndicators(
            tileModeEnabled: tileModeEnabled,
            pixelGridEnabled: false, // editorSettings.showPixelGrid,
            onionSkinEnabled: showPrevFrames,
          ),
          VerticalDivider(
            width: 8,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
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
                                    : IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                              width: 24,
                              height: 24,
                            ),
                            onPressed: () {
                              onSelectModifier(
                                modifier == PixelModifier.mirror ? PixelModifier.none : PixelModifier.mirror,
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
                        if (tool == PixelTool.pen && onFinishPenPath != null && onCancelPenPath != null) ...[
                          PenPathActions(
                            onFinish: onFinishPenPath!,
                            onCancel: onCancelPenPath!,
                          ),
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
  zoomFit,
  zoom100,
}

enum _AddMenuAction {
  materials,
  generators,
  lighting,
  templates,
}

class _SubmenuItem {
  final Key? key;
  final Widget icon;
  final String title;
  final String? shortcut;
  final VoidCallback onTap;

  const _SubmenuItem({
    this.key,
    required this.icon,
    required this.title,
    this.shortcut,
    required this.onTap,
  });
}

class _SubmenuTopBarMenuItem<T> extends PopupMenuEntry<T> {
  const _SubmenuTopBarMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
    this.height = kMinInteractiveDimension,
  });

  final Widget icon;
  final String title;
  final List<_SubmenuItem> items;
  @override
  final double height;

  @override
  bool represents(T? value) => false;

  @override
  State<_SubmenuTopBarMenuItem<T>> createState() => _SubmenuTopBarMenuItemState<T>();
}

class _SubmenuTopBarMenuItemState<T> extends State<_SubmenuTopBarMenuItem<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _closeTimer;
  bool _isHovered = false;

  void _showSubmenu() {
    _closeTimer?.cancel();
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);

    const margin = 8.0;
    const rowHeight = 38.0;
    final submenuWidth = math.min(230.0, screenSize.width - margin * 2);
    final submenuHeight = widget.items.length * rowHeight + 8;

    // Beside the item when there is room (desktop), otherwise below it,
    // overlapping the parent menu: on phones the menu is nearly as wide as
    // the screen and a side submenu ended up off-screen.
    double left;
    double top;
    if (position.dx + size.width + submenuWidth + margin <= screenSize.width) {
      left = position.dx + size.width;
      top = position.dy - 4;
    } else if (position.dx - submenuWidth >= margin) {
      left = position.dx - submenuWidth;
      top = position.dy - 4;
    } else {
      left = position.dx + 24;
      top = position.dy + size.height - 4;
    }
    left = left.clamp(margin, math.max(margin, screenSize.width - submenuWidth - margin));
    final maxTop = screenSize.height - safe.bottom - submenuHeight - margin;
    top = top.clamp(safe.top + margin, math.max(safe.top + margin, maxTop));
    final offset = Offset(left - position.dx, top - position.dy);

    final parentRoute = ModalRoute.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: offset,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: submenuWidth,
              child: MouseRegion(
                onEnter: (_) {
                  _closeTimer?.cancel();
                },
                onExit: (_) {
                  _scheduleClose();
                },
                child: _SubmenuContainer(
                  width: submenuWidth,
                  items: widget.items,
                  onItemSelected: (item) {
                    _closeSubmenu();
                    if (parentRoute != null && parentRoute.isCurrent) {
                      Navigator.of(context, rootNavigator: false).pop();
                    }
                    item.onTap();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() {
        _isHovered = true;
      });
    }
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 200), () {
      _closeSubmenu();
    });
  }

  void _closeSubmenu() {
    _closeTimer?.cancel();
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    if (mounted) {
      setState(() {
        _isHovered = false;
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final popupTextStyle = theme.popupMenuTheme.textStyle ?? theme.textTheme.bodyMedium;
    final defaultTextColor = popupTextStyle?.color ?? colorScheme.onSurface;
    final isHighlighted = _isHovered || _overlayEntry != null;

    return MouseRegion(
      onEnter: (_) => _showSubmenu(),
      onExit: (_) => _scheduleClose(),
      child: InkWell(
        onTap: () {
          if (_overlayEntry != null) {
            _closeSubmenu();
          } else {
            _showSubmenu();
          }
        },
        child: CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(
                        size: 18,
                        color: isHighlighted ? primaryColor : defaultTextColor.withValues(alpha: 0.85),
                      ),
                      child: widget.icon,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: popupTextStyle?.copyWith(
                      color: isHighlighted ? primaryColor : defaultTextColor,
                      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isHighlighted ? primaryColor : defaultTextColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmenuContainer extends StatelessWidget {
  const _SubmenuContainer({
    required this.width,
    required this.items,
    required this.onItemSelected,
  });

  final double width;
  final List<_SubmenuItem> items;
  final ValueChanged<_SubmenuItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final popupTheme = theme.popupMenuTheme;
    final backgroundColor = popupTheme.color ?? colorScheme.surface;
    final shape = popupTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: shape,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              return _SubmenuItemRow(
                item: item,
                onTap: () => onItemSelected(item),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SubmenuItemRow extends StatefulWidget {
  const _SubmenuItemRow({
    required this.item,
    required this.onTap,
  });

  final _SubmenuItem item;
  final VoidCallback onTap;

  @override
  State<_SubmenuItemRow> createState() => _SubmenuItemRowState();
}

class _SubmenuItemRowState extends State<_SubmenuItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final popupTextStyle = theme.popupMenuTheme.textStyle ?? theme.textTheme.bodyMedium;
    final defaultTextColor = popupTextStyle?.color ?? colorScheme.onSurface;

    final textColor = _isHovered ? primaryColor : defaultTextColor;
    final shortcutColor = _isHovered ? primaryColor.withValues(alpha: 0.8) : defaultTextColor.withValues(alpha: 0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        key: widget.item.key,
        onTap: widget.onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(
                      size: 16,
                      color: _isHovered ? primaryColor : defaultTextColor.withValues(alpha: 0.85),
                    ),
                    child: widget.item.icon,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: popupTextStyle?.copyWith(
                    color: textColor,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.item.shortcut != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.item.shortcut!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: shortcutColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _cmd(String key) => defaultTargetPlatform == TargetPlatform.macOS ? 'Cmd + $key' : 'Ctrl + $key';
String _shift(String key) => 'Shift + $key';
String _alt(String key) => defaultTargetPlatform == TargetPlatform.macOS ? 'Opt + $key' : 'Alt + $key';

class _TopBarMenuItem<T> extends PopupMenuItem<T> {
  _TopBarMenuItem({
    super.key,
    required super.value,
    required Widget icon,
    required String title,
    String? shortcut,
    bool? isChecked,
    bool hasNotification = false,
    super.enabled = true,
  }) : super(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _MenuEntryRow(
            icon: icon,
            title: title,
            shortcut: shortcut,
            isChecked: isChecked,
            hasNotification: hasNotification,
            enabled: enabled,
          ),
        );
}

class _MenuEntryRow extends StatelessWidget {
  const _MenuEntryRow({
    required this.icon,
    required this.title,
    this.shortcut,
    this.isChecked,
    this.hasNotification = false,
    this.enabled = true,
  });

  final Widget icon;
  final String title;
  final String? shortcut;
  final bool? isChecked;
  final bool hasNotification;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final checked = isChecked;

    final primaryColor = colorScheme.primary;
    final popupTextStyle = theme.popupMenuTheme.textStyle ?? theme.textTheme.bodyMedium;
    final defaultTextColor = popupTextStyle?.color ?? colorScheme.onSurface;

    final titleColor =
        enabled ? (checked == true ? primaryColor : defaultTextColor) : defaultTextColor.withValues(alpha: 0.38);

    final shortcutColor = enabled ? defaultTextColor.withValues(alpha: 0.5) : defaultTextColor.withValues(alpha: 0.25);

    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                size: 18,
                color: enabled
                    ? (checked == true ? primaryColor : defaultTextColor.withValues(alpha: 0.85))
                    : defaultTextColor.withValues(alpha: 0.38),
              ),
              child: icon,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: popupTextStyle?.copyWith(
              color: titleColor,
              fontWeight: checked == true ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (hasNotification) ...[
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
        if (checked != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 18,
            child: checked
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: primaryColor,
                  )
                : const SizedBox.shrink(),
          ),
        ],
        if (shortcut != null) ...[
          const SizedBox(width: 10),
          Text(
            shortcut!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: shortcutColor,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }
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
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 500),
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
      if (tileModeEnabled) (icon: Icons.grid_view_rounded, label: 'Tile mode is active'),
      if (pixelGridEnabled) (icon: Icons.grid_on_rounded, label: 'Pixel grid is active'),
      if (onionSkinEnabled) (icon: Icons.animation_rounded, label: 'Onion skin is active'),
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
