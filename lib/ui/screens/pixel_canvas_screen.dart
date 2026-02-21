import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core.dart';
import '../../l10n/strings.dart';
import '../../pixel/pixel_canvas_state.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../pixel/animation_frame_controller.dart' hide AnimationController;
import '../../pixel/tools.dart';
import '../../data.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/dialogs/import_dialog.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/painter/pixel_painter.dart';
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

  void _setZoomFit(ValueNotifier<double> gridScale, ValueNotifier<Offset> gridOffset) {
    final screenSize = MediaQuery.of(context).size;
    final canvasAspectRatio = project.width / project.height;
    final screenAspectRatio = screenSize.width / screenSize.height;

    double newScale;
    if (canvasAspectRatio > screenAspectRatio) {
      newScale = (screenSize.width * 0.8) / project.width;
    } else {
      newScale = (screenSize.height * 0.8) / project.height;
    }

    gridScale.value = newScale.clamp(0.5, 5.0);
    gridOffset.value = Offset.zero;
  }

  void _setZoom100(ValueNotifier<double> gridScale, ValueNotifier<Offset> gridOffset) {
    gridScale.value = 1.0;
    gridOffset.value = Offset.zero;
  }

  Future<bool?> showImportDialog(BuildContext context) {
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
    }, [currentTool.value]);

    final gridScale = useState(1.0);
    final gridOffset = useState(Offset.zero);
    final brushSize = useState(1);
    final sprayIntensity = useState(5);
    final normalizedOffset = useState(Offset(
      gridOffset.value.dx / gridScale.value,
      gridOffset.value.dy / gridScale.value,
    ));

    final isPlaying = useState(false);
    final showPrevFrames = useState(false);
    final isAnimationTimelineExpanded = useState(false);

    final subscription = ref.watch(subscriptionStateProvider);
    final hasSelection = state.selectionRect != null;

    final size = MediaQuery.sizeOf(context);
    final screenSize = ScreenSize.forWidth(size.width) ?? ScreenSize.xs;

    return PixelCanvasShortcutsWrapper(
      shortcutsFocusNode: _shortcutsFocusNode,
      currentTool: currentTool,
      brushSize: brushSize,
      gridScale: gridScale,
      gridOffset: gridOffset,
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
                    if (result != null) {
                      notifier.importImage(context, background: result);
                    }
                  },
                  currentModifier: currentModifier,
                  onSelectModifier: (modifier) {
                    currentModifier.value = modifier;
                    notifier.setCurrentModifier(modifier);
                  },
                  onZoomIn: () {
                    gridScale.value = (gridScale.value * 1.1).clamp(0.5, 5.0);
                  },
                  onZoomOut: () {
                    gridScale.value = (gridScale.value / 1.1).clamp(0.5, 5.0);
                  },
                  onShare: () => notifier.share(context),
                  showPrevFramesOpacity: () {
                    showPrevFrames.value = !showPrevFrames.value;
                  },
                  onEffects: () => handleEffects(context, notifier),
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
                        child: CanvasDropTarget(
                          onImageDropped: (result) => _handleDroppedImage(result, notifier),
                          onAsepriteDropped: (result) => _handleDroppedAseprite(context, result),
                          child: GestureDetector(
                            onScaleStart: (details) {
                              final pointerCount = details.pointerCount;
                              if (pointerCount == 2) {
                                normalizedOffset.value = (gridOffset.value - details.focalPoint) / gridScale.value;
                              }
                            },
                            onScaleUpdate: (details) {
                              final pointerCount = details.pointerCount;
                              if (pointerCount == 2) {
                                const sensitivity = 0.5;
                                final initialScale = gridScale.value;
                                final newScale = initialScale * (1 + (details.scale - 1) * sensitivity);
                                gridScale.value = newScale.clamp(0.5, 5.0);
                                gridOffset.value = details.focalPoint + normalizedOffset.value * gridScale.value;
                              }
                            },
                            onScaleEnd: (details) {},
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(),
                                  clipBehavior: Clip.hardEdge,
                                  child: AspectRatio(
                                    aspectRatio: width / height,
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..translate(
                                          gridOffset.value.dx,
                                          gridOffset.value.dy,
                                        )
                                        ..scale(gridScale.value),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.grey),
                                          ),
                                          child: PixelPainter(
                                            project: project,
                                            state: state,
                                            notifier: notifier,
                                            gridScale: gridScale,
                                            gridOffset: gridOffset,
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
  ) {
    final currentLayer = notifier.getCurrentLayer();

    context.showEffectsPanel(
      layer: currentLayer,
      width: project.width,
      height: project.height,
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
    super.key,
    required this.currentTool,
    required this.brushSize,
    required this.sprayIntensity,
    this.hasSelection = false,
    this.onClearSelection,
  });

  final ValueNotifier<PixelTool> currentTool;
  final ValueNotifier<int> brushSize;
  final ValueNotifier<int> sprayIntensity;
  final bool hasSelection;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentTool.value == PixelTool.pencil ||
            currentTool.value == PixelTool.brush ||
            currentTool.value == PixelTool.eraser ||
            currentTool.value == PixelTool.sprayPaint) ...[
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.brush),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: brushSize.value.toDouble(),
                    min: 1,
                    max: 10,
                    onChanged: (value) {
                      brushSize.value = value.toInt();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (currentTool.value == PixelTool.sprayPaint) ...[
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(
                  MaterialCommunityIcons.spray,
                ),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: sprayIntensity.value.toDouble(),
                    min: 1,
                    max: 10,
                    onChanged: (value) {
                      sprayIntensity.value = value.toInt();
                    },
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }
}
