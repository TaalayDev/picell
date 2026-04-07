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
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/animation_frame_controller.dart' hide AnimationController;
import '../../pixel/canvas/pixel_viewport_controller.dart';
import '../../pixel/tools.dart';
import '../../data.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/dialogs/import_dialog.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/painter/pixel_painter.dart';
import '../widgets/painter/pixel_viewport_gesture_layer.dart';
import '../widgets/painter/pixel_viewport_transform.dart';
import '../widgets/panel/desktop_side_panel.dart';
import '../widgets/pixel_canvas_shortcuts.dart';
import '../widgets/dialogs/animation_preview_dialog.dart';
import '../widgets/animation_timeline.dart';
import '../widgets/effects/effects_panel.dart';
import '../widgets/dialogs/save_image_window.dart';
import '../widgets/dialogs/templates_dialog.dart';
import '../widgets/selection_options_button.dart';
import '../widgets/tool_bar.dart';
import '../widgets/tool_menu.dart';
import '../widgets/tools_bottom_bar.dart';

class PixelCanvasScreen extends StatefulHookConsumerWidget {
  const PixelCanvasScreen({
    super.key,
    required this.project,
    this.tilemapPixels,
  });

  final Project project;

  /// Optional pre-rendered pixels from a tilemap editor
  final Uint32List? tilemapPixels;

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

  @override
  void initState() {
    super.initState();
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

  void handleExport(
    BuildContext context,
    PixelCanvasNotifier notifier,
    PixelCanvasState state,
  ) async {
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
              notifier.exportImage(
                context,
                background: !transparent,
                exportWidth: width,
                exportHeight: height,
              );
              break;

            case 'gif':
              notifier.exportAnimation(
                context,
                background: !transparent,
                exportWidth: width,
                exportHeight: height,
              );
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

  void _handleDroppedImage(DroppedFileResult result, PixelCanvasNotifier notifier) {
    if (result.image == null) return;

    final dropHandler = DropHandlerService();
    final layer = dropHandler.imageToLayer(
      result.image!,
      project.width,
      project.height,
      layerName: result.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
    );

    notifier.addLayerWithPixels(layer);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported "${result.fileName}" as new layer'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDroppedAseprite(BuildContext context, DroppedFileResult result) {
    if (result.project == null) return;

    // Show dialog asking what to do with the Aseprite file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Aseprite File'),
        content: Text(
          'How would you like to import "${result.fileName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Import first frame as layer
              if (result.project!.frames.isNotEmpty && result.project!.frames.first.layers.isNotEmpty) {
                final importedLayer = result.project!.frames.first.layers.first;
                notifier.addLayerWithPixels(importedLayer);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Imported first layer from "${result.fileName}"'),
                  ),
                );
              }
            },
            child: const Text('Import as Layer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open as new project
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PixelCanvasScreen(project: result.project!),
                ),
              );
            },
            child: const Text('Open as Project'),
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

    final isPlaying = useState(false);
    final showPrevFrames = useState(false);
    final isAnimationTimelineExpanded = useState(false);

    final subscription = ref.watch(subscriptionStateProvider);
    final hasSelection = state.selectionState != null;

    final size = MediaQuery.sizeOf(context);
    final screenSize = ScreenSize.forWidth(size.width) ?? ScreenSize.xs;

    return PixelCanvasShortcutsWrapper(
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
                  subscription: subscription,
                  onSelectTool: (tool) => currentTool.value = tool,
                  onUndo: state.canUndo ? notifier.undo : null,
                  onRedo: state.canRedo ? notifier.redo : null,
                  exportAsImage: () => handleExport(
                    context,
                    notifier,
                    state,
                  ),
                  export: () => notifier.exportJson(context),
                  currentColor: state.currentColor,
                  showPrevFrames: showPrevFrames.value,
                  onColorPicker: () {
                    showColorPicker(context, notifier);
                  },
                  import: () async {
                    final result = await showImportDialog(context);
                    if (!context.mounted || result == null) return;

                    notifier.importImage(
                      context,
                      isBackground: result.isBackground,
                      options: result.conversionOptions,
                    );
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
                  onShare: () => notifier.share(context),
                  showPrevFramesOpacity: () {
                    showPrevFrames.value = !showPrevFrames.value;
                  },
                  onEffects: () => handleEffects(
                    context,
                    notifier,
                    state.selectionState?.region,
                  ),
                  onTemplates: () {
                    TemplatesDialog.show(context, (template) {
                      notifier.addTemplate(template);
                    });
                  },
                  currentLayerHasEffects: notifier.getCurrentLayer().effects.isNotEmpty,
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
                              notifier.pushEvent(TextureBrushPatternEvent(
                                texture,
                                blendMode: blendMode,
                                isFill: isFill,
                              ));
                            },
                            // onColorSelected: (color) {},
                          ),
                        ),
                      Expanded(
                        child: ClipRect(
                          child: CanvasDropTarget(
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

                                        return Center(
                                          child: OverflowBox(
                                            minWidth: 0,
                                            minHeight: 0,
                                            maxWidth: double.infinity,
                                            maxHeight: double.infinity,
                                            alignment: Alignment.center,
                                            child: PixelViewportTransform(
                                              controller: viewportController,
                                              child: SizedBox(
                                                width: canvasWidth,
                                                height: canvasHeight,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: PixelPainter(
                                                    project: project,
                                                    state: state,
                                                    notifier: notifier,
                                                    viewportController: viewportController,
                                                    currentTool: currentTool.value,
                                                    currentModifier: currentModifier.value,
                                                    currentColor: state.currentColor,
                                                    brushSize: brushSize,
                                                    sprayIntensity: sprayIntensity,
                                                    showPrevFrames: showPrevFrames.value,
                                                    onToolAutoSwitch: (tool) {
                                                      currentTool.value = tool;
                                                    },
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
                                      ),
                                    ),
                                    if (screenSize.isMobile)
                                      Positioned(
                                        right: 26,
                                        bottom: 26,
                                        child: SelectionOptionsButton(
                                          hasSelection: hasSelection,
                                          isFloating: true,
                                          onClearSelection: () => notifier.clearSelection(),
                                          onDelete: () => notifier.clearSelectionArea(),
                                          onCutToNewLayer: () => notifier.cutToNewLayer(),
                                          onCopyToNewLayer: () => notifier.copyToNewLayer(),
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
                    notifier.addFrame(
                      'Frame ${state.currentFrames.length + 1}',
                    );
                  },
                  copyFrame: (id) {
                    notifier.addFrame(
                      'Frame ${state.currentFrames.length + 1}',
                      copyFrame: id,
                    );
                  },
                  onDeleteFrame: notifier.removeFrame,
                  onDurationChanged: (index, duration) {
                    notifier.updateFrame(
                      index,
                      state.frames[index].copyWith(duration: duration),
                    );
                  },
                  onFrameReordered: (oldIndex, newIndex) {},
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
                  ToolsBottomBar(
                    currentTool: currentTool,
                    state: state,
                    notifier: notifier,
                    subscription: subscription,
                    width: width,
                    height: height,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void handleEffects(
    BuildContext context,
    PixelCanvasNotifier notifier,
    SelectionRegion? selectionRegion,
  ) {
    final currentLayer = notifier.getCurrentLayer();

    context.showEffectsPanel(
      layer: currentLayer,
      width: project.width,
      height: project.height,
      selectionRegion: selectionRegion,
      onLayerUpdated: (updatedLayer) {
        notifier.updateLayer(updatedLayer);
      },
    );
  }

  void showColorPicker(
    BuildContext context,
    PixelCanvasNotifier controller,
  ) {
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
  });

  final ValueNotifier<PixelTool> currentTool;
  final ValueNotifier<int> brushSize;
  final ValueNotifier<int> sprayIntensity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBrushTool = currentTool.value == PixelTool.pencil ||
        currentTool.value == PixelTool.brush ||
        currentTool.value == PixelTool.eraser ||
        currentTool.value == PixelTool.sprayPaint;
    final isSpray = currentTool.value == PixelTool.sprayPaint;

    if (!isBrushTool) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SliderPill(
          icon: Icons.brush_rounded,
          value: brushSize,
          min: 1,
          max: 10,
          accentColor: colorScheme.primary,
        ),
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
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
