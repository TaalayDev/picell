import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core.dart';
import '../../data/models/selection_region.dart';
import '../../l10n/strings.dart';
import '../../pixel/pixel_canvas_state.dart';
import '../../pixel/services/pixel_transform_service.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/animation_frame_controller.dart' hide AnimationController;
import '../../pixel/canvas/pixel_viewport_controller.dart';
import '../../pixel/tools.dart';
import '../../data.dart';
import '../../providers/editor_settings_provider.dart';
import '../../providers/pixel_clipboard_provider.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/dialogs/import_dialog.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/painter/pixel_canvas_scene_host.dart';
import '../widgets/painter/tiled_canvas_wrap.dart';
import '../widgets/painter/pixel_viewport_gesture_layer.dart';
import '../widgets/painter/pixel_viewport_transform.dart';
import '../widgets/panel/desktop_side_panel.dart';
import '../widgets/pixel_canvas_shortcuts.dart';
import '../widgets/dialogs/animation_preview_dialog.dart';
import '../widgets/animation_timeline.dart';
import '../widgets/effects/effects_panel.dart';
import '../widgets/effects/effect_animation_generator_dialog.dart';
import '../widgets/dialogs/save_image_window.dart';
import '../widgets/dialogs/templates_dialog.dart';
import '../widgets/dialogs/undo_history_dialog.dart';
import '../widgets/mobile_color_selector.dart';
import '../widgets/pen_path_actions.dart';
import '../widgets/selection_mode_toggle.dart';
import '../widgets/selection_options_button.dart';
import '../widgets/tool_bar.dart';
import '../widgets/tool_menu.dart';
import '../widgets/tools_bottom_bar.dart';
import '../widgets/wand_options_bar.dart';

enum _DroppedImageAction { newLayer, thisLayer, newProject }

class PixelCanvasScreen extends StatefulHookConsumerWidget {
  const PixelCanvasScreen({
    super.key,
    required this.project,
    this.tilemapPixels,
    this.isActive = true,
    this.onOpenProject,
  });

  final Project project;

  /// Optional pre-rendered pixels from a tilemap editor
  final Uint32List? tilemapPixels;
  final bool isActive;
  final ValueChanged<Project>? onOpenProject;

  @override
  ConsumerState<PixelCanvasScreen> createState() => _PixelCanvasScreenState();
}

class _PixelCanvasScreenState extends ConsumerState<PixelCanvasScreen> with TickerProviderStateMixin {
  late Project project = widget.project;
  late PixelCanvasNotifierProvider provider = pixelCanvasNotifierProvider(project);
  late PixelCanvasNotifier notifier = ref.read(provider.notifier);

  final _shortcutsFocusNode = FocusNode();
  final _toolbarOnboardingNode = FocusNode(debugLabel: 'editor_toolbar');
  final _toolsOnboardingNode = FocusNode(debugLabel: 'editor_tools');
  final _canvasOnboardingNode = FocusNode(debugLabel: 'editor_canvas');
  final _timelineOnboardingNode = FocusNode(debugLabel: 'editor_timeline');
  bool _showUI = true;
  bool _tilemapPixelsApplied = false;
  List<int> _selectedLayerIndices = const [];

  @override
  void initState() {
    super.initState();
    _shortcutsFocusNode.canRequestFocus = widget.isActive;
    // Apply tilemap pixels after the first frame if provided
    if (widget.tilemapPixels != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_tilemapPixelsApplied && widget.tilemapPixels != null) {
          notifier.setLayerPixels(widget.tilemapPixels!);
          _tilemapPixelsApplied = true;
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PixelCanvasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;

    _shortcutsFocusNode.canRequestFocus = widget.isActive;
    if (!widget.isActive) {
      _shortcutsFocusNode.unfocus();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _shortcutsFocusNode.canRequestFocus) {
        _shortcutsFocusNode.requestFocus();
      }
    });
  }

  void handleExport(BuildContext context, PixelCanvasNotifier notifier, PixelCanvasState state) async {
    _shortcutsFocusNode.canRequestFocus = false;
    _shortcutsFocusNode.unfocus();

    try {
      await showSaveImageWindow(
        context,
        state: state,
        subscription: ref.read(subscriptionStateProvider),
        onSave: (options) async {
          final format = options['format'] as String;
          final transparent = options['transparent'] as bool;
          final width = options['exportWidth'] as double;
          final height = options['exportHeight'] as double;

          switch (format) {
            case 'png':
              notifier.exportImage(context, background: !transparent, exportWidth: width, exportHeight: height);
              break;

            case 'gif':
              notifier.exportAnimation(context, background: !transparent, exportWidth: width, exportHeight: height);
              break;

            case 'sprite-sheet':
              final spriteOptions = options['spriteSheetOptions'] as Map<String, dynamic>;
              await notifier.exportSpriteSheet(
                context,
                columns: spriteOptions['columns'] as int,
                spacing: spriteOptions['spacing'] as int,
                includeAllFrames: spriteOptions['includeAllFrames'] as bool,
                withBackground: !transparent,
                exportWidth: width,
                exportHeight: height,
              );
              break;
          }
        },
      );
    } finally {
      if (mounted) {
        _shortcutsFocusNode.canRequestFocus = true;
        _shortcutsFocusNode.requestFocus();
      }
    }
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  void _setZoomFit(PixelViewportController viewportController) {
    final screenSize = MediaQuery.of(context).size;
    final canvasAspectRatio = project.width / project.height;
    final screenAspectRatio = screenSize.width / screenSize.height;

    double newScale;
    if (canvasAspectRatio > screenAspectRatio) {
      newScale = (screenSize.width * 0.8) / project.width;
    } else {
      newScale = (screenSize.height * 0.8) / project.height;
    }

    viewportController.setViewport(newScale.clamp(0.5, 5.0), Offset.zero);
  }

  void _setZoom100(PixelViewportController viewportController) {
    viewportController.reset();
  }

  Future<ImportDialogResult?> showImportDialog(BuildContext context) {
    return ImportDialog.show(context);
  }

  Future<void> _handleDroppedImage(DroppedFileResult result, PixelCanvasNotifier notifier) async {
    final image = result.image;
    if (image == null) return;

    final strings = Strings.of(context);
    final action = await showDialog<_DroppedImageAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.dropImageTitle),
        content: Text(strings.dropImageMessage(result.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DroppedImageAction.thisLayer),
            child: Text(strings.dropImageThisLayer),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DroppedImageAction.newLayer),
            child: Text(strings.dropImageNewLayer),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _DroppedImageAction.newProject),
            child: Text(strings.dropImageNewProject),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    final dropHandler = DropHandlerService();
    final layerName = result.fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

    switch (action) {
      case _DroppedImageAction.newProject:
        widget.onOpenProject?.call(dropHandler.imageToProject(image, result.fileName));
        return;
      case _DroppedImageAction.newLayer:
        final layer = dropHandler.imageToLayer(image, project.width, project.height, layerName: layerName);
        notifier.addLayerWithPixels(layer);
      case _DroppedImageAction.thisLayer:
        final layer = dropHandler.imageToLayer(image, project.width, project.height, layerName: layerName);
        notifier.importPixelsToCurrentLayer(layer.pixels);
    }

    AppNotification.info(
      context,
      strings.importedFileAsNewLayer(result.fileName),
      duration: const Duration(seconds: 2),
    );
  }

  void _handleDroppedAseprite(BuildContext context, DroppedFileResult result) {
    if (result.project == null) return;

    // Show dialog asking what to do with the Aseprite file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).importAsepriteFile),
        content: Text(Strings.of(context).howImportAsepriteFile(result.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Strings.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Import first frame as layer
              if (result.project!.frames.isNotEmpty && result.project!.frames.first.layers.isNotEmpty) {
                final importedLayer = result.project!.frames.first.layers.first;
                notifier.addLayerWithPixels(importedLayer);
                AppNotification.info(
                  context,
                  Strings.of(context).importedFirstLayerFromFile(result.fileName),
                );
              }
            },
            child: Text(Strings.of(context).importAsLayer),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onOpenProject?.call(result.project!);
            },
            child: Text(Strings.of(context).openAsProject),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shortcutsFocusNode.dispose();
    _toolbarOnboardingNode.dispose();
    _toolsOnboardingNode.dispose();
    _canvasOnboardingNode.dispose();
    _timelineOnboardingNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTool = useState(PixelTool.pencil);
    final currentModifier = useState(PixelModifier.none);
    final width = project.width;
    final height = project.height;

    final state = ref.watch(provider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.currentTool = currentTool.value;
      });
      return null;
    }, [currentTool.value]);

    final viewportController = useMemoized(PixelViewportController.new);
    useListenable(viewportController);
    useEffect(() {
      return viewportController.dispose;
    }, [viewportController]);
    final brushSize = useState(1);
    final sprayIntensity = useState(5);
    final selectionMode = useState(SelectionMode.replace);

    final isPlaying = useState(false);
    final showPrevFrames = useState(false);
    final isAnimationTimelineExpanded = useState(false);
    final tileModeEnabled = useState(false);
    final onionSkinOpacity = useState(0.5);

    final subscription = ref.watch(subscriptionStateProvider);
    final editorSettings = ref.watch(editorSettingsNotifierProvider);
    final hasSelection = state.selectionState != null;
    final clipboard = ref.watch(pixelClipboardProvider);
    final clipboardNotifier = ref.read(pixelClipboardProvider.notifier);

    final size = MediaQuery.sizeOf(context);
    final screenSize = ScreenSize.forWidth(size.width) ?? ScreenSize.xs;

    // Shared clipboard handlers — used by both the toolbar buttons and the
    // keyboard shortcuts (Ctrl+C/X/V).
    void copySelectionToClipboard() {
      final region = state.selectionState?.region;
      final pixels = notifier.copySelectionPixels();
      if (region != null && pixels != null) {
        clipboardNotifier.store(PixelClipboardData(
          pixels: pixels,
          width: width,
          height: height,
          region: region,
        ));
        return;
      }

      final indices = _selectedLayerIndices.isEmpty ? [state.currentLayerIndex] : _selectedLayerIndices;
      final layers = notifier.copyLayers(indices);
      if (layers.isEmpty) return;
      clipboardNotifier.store(LayerClipboardData(
        layers: layers,
        width: width,
        height: height,
      ));
    }

    void cutSelectionToClipboard() {
      final region = state.selectionState?.region;
      final pixels = notifier.cutSelectionPixels();
      if (region != null && pixels != null) {
        clipboardNotifier.store(PixelClipboardData(
          pixels: pixels,
          width: width,
          height: height,
          region: region,
        ));
        return;
      }

      final indices = _selectedLayerIndices.isEmpty ? [state.currentLayerIndex] : _selectedLayerIndices;
      final layers = notifier.copyLayers(indices);
      if (layers.isEmpty) return;
      clipboardNotifier.store(LayerClipboardData(
        layers: layers,
        width: width,
        height: height,
      ));
      notifier.removeLayers(indices);
    }

    Future<void> pasteFromClipboard() async {
      final clip = clipboardNotifier.take();
      if (clip == null) return;
      final pasteErrorMessage = Strings.of(context).anErrorOccurred;

      try {
        switch (clip) {
          case PixelClipboardData():
            await notifier.pastePixels(
              clip.pixels,
              clip.region,
              sourceWidth: clip.width,
              sourceHeight: clip.height,
            );
          case LayerClipboardData():
            await notifier.pasteLayers(
              clip.layers,
              sourceWidth: clip.width,
              sourceHeight: clip.height,
            );
        }
      } catch (_) {
        clipboardNotifier.restoreIfEmpty(clip);
        if (mounted) {
          AppNotification.error(
            this.context,
            pasteErrorMessage,
          );
        }
      }
    }

    return PixelCanvasShortcutsWrapper(
      enabled: widget.isActive,
      shortcutsFocusNode: _shortcutsFocusNode,
      currentTool: currentTool,
      brushSize: brushSize,
      viewportController: viewportController,
      state: state,
      notifier: notifier,
      handleExport: handleExport,
      setZoomFit: _setZoomFit,
      setZoom100: _setZoom100,
      showImportDialog: showImportDialog,
      showColorPicker: showColorPicker,
      toggleUI: _toggleUI,
      onCopySelection: copySelectionToClipboard,
      onCutSelection: cutSelectionToClipboard,
      onPasteSelection: pasteFromClipboard,
      onToggleTileMode: () => tileModeEnabled.value = !tileModeEnabled.value,
      onToggleGrid: () {
        ref.read(editorSettingsNotifierProvider.notifier).setShowPixelGrid(!editorSettings.showPixelGrid);
      },
      onToggleOnionSkin: () => showPrevFrames.value = !showPrevFrames.value,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: AnimatedBackground(
            enableAnimation: false,
            child: Column(
              children: [
                ToolBar(
                  project: project,
                  currentTool: currentTool,
                  brushSize: brushSize,
                  sprayIntensity: sprayIntensity,
                  selectionMode: selectionMode,
                  subscription: subscription,
                  onSelectTool: (tool) => currentTool.value = tool,
                  onUndo: state.canUndo ? notifier.undo : null,
                  onRedo: state.canRedo ? notifier.redo : null,
                  exportAsImage: () => handleExport(context, notifier, state),
                  export: () => notifier.exportJson(context),
                  currentColor: state.currentColor,
                  showPrevFrames: showPrevFrames.value,
                  onColorPicker: () {
                    showColorPicker(context, notifier);
                  },
                  import: () async {
                    final result = await showImportDialog(context);
                    if (!context.mounted || result == null) return;

                    notifier.importImage(context, isBackground: result.isBackground, options: result.conversionOptions);
                  },
                  currentModifier: currentModifier,
                  onSelectModifier: (modifier) {
                    currentModifier.value = modifier;
                    notifier.setCurrentModifier(modifier);
                  },
                  onZoomIn: () {
                    viewportController.zoomIn();
                  },
                  onZoomOut: () {
                    viewportController.zoomOut();
                  },
                  onZoomFit: () => _setZoomFit(viewportController),
                  onZoom100: () => _setZoom100(viewportController),
                  onShare: () => notifier.share(context),
                  showPrevFramesOpacity: () {
                    showPrevFrames.value = !showPrevFrames.value;
                  },
                  onionSkinOpacity: onionSkinOpacity.value,
                  onionSkinOpacityChanged: (v) => onionSkinOpacity.value = v,
                  onEffects: () => handleEffects(context, notifier, state.selectionState?.region),
                  tileModeEnabled: tileModeEnabled.value,
                  onToggleTileMode: () => tileModeEnabled.value = !tileModeEnabled.value,
                  canPaste: clipboard != null,
                  onCopySelection: copySelectionToClipboard,
                  onCutSelection: cutSelectionToClipboard,
                  onPasteSelection: pasteFromClipboard,
                  onTemplates: () {
                    TemplatesDialog.show(context, (template) {
                      notifier.addTemplate(template);
                    });
                  },
                  onShowHistory: () {
                    UndoHistorySheet.show(
                      context,
                      notifier: notifier,
                      onUndo: notifier.undo,
                      onRedo: notifier.redo,
                    );
                  },
                  currentLayerHasEffects: notifier.getCurrentLayer().effects.isNotEmpty,
                  onFinishPenPath: () => notifier.pushEvent(const ClosePenPathEvent()),
                  onCancelPenPath: () => notifier.pushEvent(const CancelPenPathEvent()),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (MediaQuery.sizeOf(context).width > 1050)
                        Container(
                          width: 45,
                          color: Theme.of(context).colorScheme.surface,
                          child: ToolMenu(
                            currentTool: currentTool,
                            onSelectTool: (tool) => currentTool.value = tool,
                            onColorPicker: () {
                              showColorPicker(context, notifier);
                            },
                            currentColor: state.currentColor,
                            subscription: subscription,
                            onTextureSelected: (texture, blendMode, isFill) {
                              currentTool.value = isFill ? PixelTool.textureFill : PixelTool.textureBrush;
                              notifier.pushEvent(
                                TextureBrushPatternEvent(texture, blendMode: blendMode, isFill: isFill),
                              );
                            },
                            // onColorSelected: (color) {},
                          ),
                        ),
                      Expanded(
                        child: ClipRect(
                          child: CanvasDropTarget(
                            enabled: widget.isActive,
                            onImageDropped: (result) => _handleDroppedImage(result, notifier),
                            onAsepriteDropped: (result) => _handleDroppedAseprite(context, result),
                            child: PixelViewportGestureLayer(
                              controller: viewportController,
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final viewportWidth = constraints.maxWidth;
                                        final viewportHeight = constraints.maxHeight;

                                        double canvasWidth = viewportWidth;
                                        double canvasHeight = canvasWidth * height / width;

                                        if (canvasHeight > viewportHeight) {
                                          canvasHeight = viewportHeight;
                                          canvasWidth = canvasHeight * width / height;
                                        }

                                        // The canvas is centred and scaled about its own
                                        // top-left corner; tell the gesture layer where
                                        // that corner is so pinch zoom anchors correctly.
                                        viewportController.origin = Offset(
                                          (viewportWidth - canvasWidth) / 2,
                                          (viewportHeight - canvasHeight) / 2,
                                        );

                                        return Center(
                                          child: OverflowBox(
                                            minWidth: 0,
                                            minHeight: 0,
                                            maxWidth: double.infinity,
                                            maxHeight: double.infinity,
                                            alignment: Alignment.center,
                                            child: PixelViewportTransform(
                                              controller: viewportController,
                                              child: TiledCanvasWrap(
                                                enabled: tileModeEnabled.value,
                                                layers: state.currentFrame.layers,
                                                width: width,
                                                height: height,
                                                canvasWidth: canvasWidth,
                                                canvasHeight: canvasHeight,
                                                child: SizedBox(
                                                  width: canvasWidth,
                                                  height: canvasHeight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: PixelCanvasSceneHost(
                                                      project: project,
                                                      state: state,
                                                      notifier: notifier,
                                                      viewportController: viewportController,
                                                      currentTool: currentTool.value,
                                                      modifier: currentModifier.value,
                                                      currentColor: state.currentColor,
                                                      brushSize: brushSize.value,
                                                      sprayIntensity: sprayIntensity.value,
                                                      mirrorAxis: MirrorAxis.vertical,
                                                      eventStream: notifier.eventStream,
                                                      editorSettings: editorSettings,
                                                      enableMultiTouchViewportNavigation: false,
                                                      showPrevFrames: showPrevFrames.value,
                                                      selectionMode: selectionMode.value,
                                                      onionSkinOpacity: onionSkinOpacity.value,
                                                      onToolAutoSwitch: (tool) {
                                                        currentTool.value = tool;
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (MediaQuery.sizeOf(context).width < 1000) ...[
                                    Positioned(
                                      left: 16,
                                      right: 16,
                                      top: 16,
                                      child: _ToolElements(
                                        currentTool: currentTool,
                                        brushSize: brushSize,
                                        sprayIntensity: sprayIntensity,
                                        selectionMode: selectionMode,
                                      ),
                                    ),
                                    if (screenSize.isMobile)
                                      Positioned(
                                        right: 26,
                                        bottom: 26,
                                        child: currentTool.value == PixelTool.pen
                                            ? PenPathActions(
                                                isFloating: true,
                                                onFinish: () => notifier.pushEvent(const ClosePenPathEvent()),
                                                onCancel: () => notifier.pushEvent(const CancelPenPathEvent()),
                                              )
                                            : SelectionOptionsButton(
                                                hasSelection: hasSelection,
                                                isFloating: true,
                                                onClearSelection: () => notifier.clearSelection(),
                                                onDelete: () => notifier.clearSelectionArea(),
                                                onCutToNewLayer: () => notifier.cutToNewLayer(),
                                                onCopyToNewLayer: () => notifier.copyToNewLayer(),
                                                onCopy: copySelectionToClipboard,
                                                onCut: cutSelectionToClipboard,
                                                onPaste: clipboard != null ? pasteFromClipboard : null,
                                                onInvert: () => notifier.invertSelection(),
                                                onGrow: () => notifier.growSelection(),
                                                onShrink: () => notifier.shrinkSelection(),
                                                onRotate90: () =>
                                                    notifier.transformSelection(PixelTransform.rotate90Clockwise),
                                                onRotate180: () =>
                                                    notifier.transformSelection(PixelTransform.rotate180),
                                                onFlipHorizontal: () => notifier.flipSelection(horizontal: true),
                                                onFlipVertical: () => notifier.flipSelection(horizontal: false),
                                              ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width > 1050)
                        DesktopSidePanel(
                          width: width,
                          height: height,
                          state: state,
                          notifier: notifier,
                          currentTool: currentTool,
                          onLayerSelectionChanged: (indices) {
                            _selectedLayerIndices = indices;
                          },
                        ),
                    ],
                  ),
                ),
                AnimationTimeline(
                  width: width,
                  height: height,
                  // itemsHeight: 80,
                  onSelectFrame: notifier.selectFrame,
                  onAddFrame: () {
                    notifier.addFrame('Frame ${state.currentFrames.length + 1}');
                  },
                  copyFrame: notifier.duplicateFramesByIds,
                  onDeleteFrame: notifier.removeFramesByIds,
                  onDurationChanged: notifier.updateFramesDurationByIds,
                  onFrameReordered: notifier.reorderFramesByIds,
                  onPlayPause: () {
                    isPlaying.value = !isPlaying.value;
                    if (isPlaying.value) {
                      showAnimationPreviewDialog(
                        context,
                        frames: state.currentFrames,
                        width: width,
                        height: height,
                      ).then((_) {
                        isPlaying.value = false;
                      });
                    }
                  },
                  onStop: () {
                    isPlaying.value = false;
                    notifier.selectFrame(0);
                  },
                  onNextFrame: () {
                    notifier.nextFrame();
                  },
                  onPreviousFrame: () {
                    notifier.prevFrame();
                  },
                  frames: state.frames,
                  states: state.animationStates,
                  selectedStateId: state.currentAnimationState.id,
                  selectedFrameId: state.currentFrame.id,
                  isPlaying: isPlaying.value,
                  settings: const AnimationSettings(),
                  onSettingsChanged: (settings) {},
                  isExpanded: isAnimationTimelineExpanded.value,
                  onExpandChanged: () {
                    isAnimationTimelineExpanded.value = !isAnimationTimelineExpanded.value;
                  },
                  onAddState: (name) {
                    notifier.addAnimationState(name, 24);
                  },
                  onDeleteState: notifier.removeAnimationState,
                  onRenameState: (id, name) {},
                  onSelectedStateChanged: notifier.selectAnimationState,
                  onDuplicateState: (id) {},
                  onCopyState: (id) {
                    notifier.copyAnimationState(id);
                  },
                ),
                if (MediaQuery.sizeOf(context).width <= 1050)
                  MobileColorSelector(
                    currentColor: state.currentColor,
                    isEyedropperSelected: currentTool.value == PixelTool.eyedropper,
                    onSelectEyedropper: () {
                      currentTool.value = PixelTool.eyedropper;
                    },
                    onColorSelected: (color) {
                      notifier.currentColor = color;
                    },
                  ),
                if (MediaQuery.sizeOf(context).width <= 1050)
                  ToolsBottomBar(
                    currentTool: currentTool,
                    state: state,
                    notifier: notifier,
                    subscription: subscription,
                    width: width,
                    height: height,
                    onLayerSelectionChanged: (indices) {
                      _selectedLayerIndices = indices;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void handleEffects(BuildContext context, PixelCanvasNotifier notifier, SelectionRegion? selectionRegion) {
    final currentLayer = notifier.getCurrentLayer();

    context.showEffectsPanel(
      layer: currentLayer,
      width: project.width,
      height: project.height,
      selectionRegion: selectionRegion,
      onLayerUpdated: (updatedLayer) {
        notifier.updateLayer(updatedLayer);
      },
      onConvertToPixels: (effects) => notifier.convertCurrentLayerToPixels(effects: effects),
      onAnimate: (effect, effects, effectIndex) {
        final sourceFrame = notifier.currentFrame;
        final sourceLayer = notifier.currentLayer;
        EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
          context,
          effect: effect,
          effects: effects,
          effectIndex: effectIndex,
          layerWidth: project.width,
          layerHeight: project.height,
          layerPixels: sourceLayer.pixels,
          onFramesGenerated: (frames) => notifier.addGeneratedEffectFrames(
            frames,
            sourceFrameId: sourceFrame.id,
            sourceLayerId: sourceLayer.layerId,
          ),
        );
      },
    );
  }

  void showColorPicker(BuildContext context, PixelCanvasNotifier controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).pickAColor),
        content: SingleChildScrollView(
          child: MaterialPicker(
            pickerColor: controller.currentColor,
            onColorChanged: (color) {
              controller.currentColor = color;
            },
            enableLabel: true,
            portraitOnly: true,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: Text(Strings.of(context).gotIt),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _ToolElements extends StatelessWidget {
  const _ToolElements({
    required this.currentTool,
    required this.brushSize,
    required this.sprayIntensity,
    required this.selectionMode,
  });

  final ValueNotifier<PixelTool> currentTool;
  final ValueNotifier<int> brushSize;
  final ValueNotifier<int> sprayIntensity;
  final ValueNotifier<SelectionMode> selectionMode;

  static bool _isSelectionTool(PixelTool tool) {
    return tool == PixelTool.select ||
        tool == PixelTool.ellipseSelect ||
        tool == PixelTool.lasso ||
        tool == PixelTool.smartSelect;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBrushTool = currentTool.value == PixelTool.pencil ||
        currentTool.value == PixelTool.brush ||
        currentTool.value == PixelTool.eraser ||
        currentTool.value == PixelTool.sprayPaint;
    final isSpray = currentTool.value == PixelTool.sprayPaint;
    final isWand = currentTool.value == PixelTool.smartSelect;

    if (_isSelectionTool(currentTool.value)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionModeToggle(mode: selectionMode),
          if (isWand) ...[
            const SizedBox(width: 6),
            const WandOptionsBar(),
          ],
        ],
      );
    }

    if (!isBrushTool) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SliderPill(icon: Icons.brush_rounded, value: brushSize, min: 1, max: 10, accentColor: colorScheme.primary),
        if (isSpray) ...[
          const SizedBox(height: 6),
          _SliderPill(
            icon: MaterialCommunityIcons.spray,
            value: sprayIntensity,
            min: 1,
            max: 10,
            accentColor: colorScheme.tertiary,
          ),
        ],
      ],
    );
  }
}

class _SliderPill extends StatelessWidget {
  const _SliderPill({
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
  });

  final IconData icon;
  final ValueNotifier<int> value;
  final int min;
  final int max;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, current, _) {
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accentColor),
              SizedBox(
                width: 120,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: accentColor.withValues(alpha: 0.2),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: current.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    onChanged: (v) => value.value = v.toInt(),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: Text(
                  '$current',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}
