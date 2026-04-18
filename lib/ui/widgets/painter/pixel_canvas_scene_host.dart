import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data.dart';
import '../../../pixel/canvas/canvas_gesture_handler.dart';
import '../../../pixel/canvas/canvas_host_runtime.dart';
import '../../../pixel/canvas/pixel_canvas_callbacks.dart';
import '../../../pixel/canvas/canvas_render_host.dart';
import '../../../pixel/canvas/canvas_surface_models.dart';
import '../../../pixel/canvas/canvas_surface_runtime.dart';
import '../../../pixel/canvas/pixel_viewport_controller.dart';
import '../../../pixel/pixel_canvas_state.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../pixel/tools.dart';
import '../../../providers/background_image_provider.dart';
import '../../../providers/editor_settings_provider.dart';

class PixelCanvasSceneHost extends ConsumerStatefulWidget {
  const PixelCanvasSceneHost({
    super.key,
    required this.project,
    required this.state,
    required this.notifier,
    required this.currentTool,
    required this.currentColor,
    required this.modifier,
    required this.brushSize,
    required this.sprayIntensity,
    required this.mirrorAxis,
    required this.viewportController,
    required this.eventStream,
    required this.editorSettings,
    required this.enableMultiTouchViewportNavigation,
    required this.showPrevFrames,
    this.onionSkinOpacity = 0.5,
    this.onToolAutoSwitch,
  });

  final Project project;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final PixelTool currentTool;
  final Color currentColor;
  final PixelModifier modifier;
  final int brushSize;
  final int sprayIntensity;
  final MirrorAxis mirrorAxis;
  final PixelViewportController viewportController;
  final Stream<PixelDrawEvent>? eventStream;
  final EditorSettings editorSettings;
  final bool enableMultiTouchViewportNavigation;
  final bool showPrevFrames;
  final double onionSkinOpacity;
  final Function(PixelTool)? onToolAutoSwitch;

  @override
  ConsumerState<PixelCanvasSceneHost> createState() => _PixelCanvasSceneHostState();
}

class _PixelCanvasSceneHostState extends ConsumerState<PixelCanvasSceneHost> with SingleTickerProviderStateMixin {
  late final PixelCanvasHostRuntime _canvasRuntime;
  late final PixelCanvasSurfaceRuntime _surfaceRuntime;
  late final AnimationController _selectionAnimationController;

  @override
  void initState() {
    super.initState();
    _selectionAnimationController = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat();
    final sceneConfig = _buildSceneConfig();
    _canvasRuntime = PixelCanvasHostRuntime.create(
      width: widget.project.width,
      height: widget.project.height,
      layers: widget.state.layers,
      currentLayerIndex: widget.state.currentLayerIndex,
      currentTool: widget.currentTool,
      viewportController: widget.viewportController,
      inputMode: sceneConfig.inputMode,
      twoFingerUndoEnabled: sceneConfig.twoFingerUndoEnabled,
      enableMultiTouchViewportNavigation: widget.enableMultiTouchViewportNavigation,
      selectionState: widget.state.selectionState,
      callbacks: _buildHostCallbacks(),
    );
    _surfaceRuntime = PixelCanvasSurfaceRuntime();

    final backgroundImage = ref.read(backgroundImageProvider);
    _surfaceRuntime.update(backgroundImageBytes: backgroundImage.image, onionSkinFrames: sceneConfig.onionSkinFrames);
  }

  @override
  void didUpdateWidget(covariant PixelCanvasSceneHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sceneConfig = _buildSceneConfig();
    _canvasRuntime.update(
      layers: widget.state.layers,
      currentLayerIndex: widget.state.currentLayerIndex,
      currentTool: widget.currentTool,
      viewportController: widget.viewportController,
      inputMode: sceneConfig.inputMode,
      twoFingerUndoEnabled: sceneConfig.twoFingerUndoEnabled,
      enableMultiTouchViewportNavigation: widget.enableMultiTouchViewportNavigation,
      selectionState: widget.state.selectionState,
    );

    final backgroundImage = ref.read(backgroundImageProvider);
    _surfaceRuntime.update(backgroundImageBytes: backgroundImage.image, onionSkinFrames: sceneConfig.onionSkinFrames);
  }

  @override
  void dispose() {
    _selectionAnimationController.dispose();
    _surfaceRuntime.dispose();
    _canvasRuntime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sceneConfig = _buildSceneConfig();
    final backgroundImage = ref.watch(backgroundImageProvider);
    ref.listen(backgroundImageProvider, (_, next) {
      _surfaceRuntime.update(backgroundImageBytes: next.image, onionSkinFrames: sceneConfig.onionSkinFrames);
    });

    return PixelCanvasRenderHost(
      runtime: _canvasRuntime,
      width: widget.project.width,
      height: widget.project.height,
      currentLayer: widget.state.layers[widget.state.currentLayerIndex],
      currentTool: widget.currentTool,
      currentColor: widget.currentColor,
      modifier: widget.modifier,
      brushSize: widget.brushSize,
      sprayIntensity: widget.sprayIntensity,
      mirrorAxis: widget.mirrorAxis,
      selectionState: widget.state.selectionState,
      selectionAnimation: _selectionAnimationController,
      gridWidth: sceneConfig.gridWidth,
      gridHeight: sceneConfig.gridHeight,
      imageResolver: _surfaceRuntime.imageResolver,
      backgroundOpacity: backgroundImage.opacity,
      backgroundScale: backgroundImage.scale,
      backgroundOffset: backgroundImage.offset,
      eventStream: widget.eventStream,
      onSelectionChanged: sceneConfig.callbacks.onSelectionChanged,
      onMoveSelection: sceneConfig.callbacks.onMoveSelection,
      onSelectionResize: sceneConfig.callbacks.onSelectionResize,
      onSelectionRotate: sceneConfig.callbacks.onSelectionRotate,
      onTransformStart: sceneConfig.callbacks.onTransformStart,
      onTransformEnd: sceneConfig.callbacks.onTransformEnd,
      onAnchorChanged: sceneConfig.callbacks.onAnchorChanged,
    );
  }

  PixelCanvasHostCallbacks _buildHostCallbacks() {
    return PixelCanvasHostCallbacks(
      getCurrentTool: () => widget.currentTool,
      onStartDrawing: () => widget.notifier.startDrawing(),
      onFinishDrawing: () => widget.notifier.endDrawing(),
      onDrawShape: (points) => widget.notifier.fillPixels(points),
      onSelectionChanged: (region) {
        if (region == null) {
          widget.notifier.clearSelection();
        } else {
          widget.notifier.setSelection(region);
        }
      },
      onColorPicked: (color) {
        widget.notifier.currentColor = color == Colors.transparent ? Colors.white : color;
        widget.onToolAutoSwitch?.call(PixelTool.pencil);
      },
      onStartPixelDrag: (_) {
        if (widget.currentTool == PixelTool.drag) {
          widget.notifier.startDrag();
        }
      },
      onPixelDrag: (offset) {
        if (widget.currentTool == PixelTool.drag) {
          widget.notifier.dragPixels(offset);
        }
      },
      onPixelDragEnd: (_) {
        if (widget.currentTool == PixelTool.drag) {
          widget.notifier.endDrag();
        }
      },
      onUndo: widget.notifier.undo,
      onGradientFromPoints: (startPx, endPx) {
        widget.notifier.applyGradientFromPoints(startPx, endPx, Colors.transparent);
      },
    );
  }

  _PixelCanvasSceneConfig _buildSceneConfig() {
    final inputMode = widget.editorSettings.inputMode == InputMode.stylusOnly
        ? GestureInputMode.stylusOnly
        : GestureInputMode.standard;

    return _PixelCanvasSceneConfig(
      callbacks: PixelCanvasCallbacks(
        onStartDrawing: widget.notifier.startDrawing,
        onFinishDrawing: widget.notifier.endDrawing,
        onDrawShape: widget.notifier.fillPixels,
        onSelectionChanged: (region) {
          if (region == null) {
            widget.notifier.clearSelection();
          } else {
            widget.notifier.setSelection(region);
          }
        },
        onMoveSelection: widget.notifier.moveSelection,
        onSelectionResize: (newRegion, oldRegion, newBounds, center) {
          widget.notifier.resizeSelectionNew(newRegion.bounds, region: newRegion);
        },
        onSelectionRotate: (newRegion, oldRegion, angle, center) {
          widget.notifier.rotateSelectionNew(angle, pivot: center, region: newRegion);
        },
        onTransformStart: widget.notifier.startTransformSelection,
        onTransformEnd: widget.notifier.endTransformSelection,
        onAnchorChanged: widget.notifier.setAnchorPoint,
        onColorPicked: (color) {
          widget.notifier.currentColor = color == Colors.transparent ? Colors.white : color;
          widget.onToolAutoSwitch?.call(PixelTool.pencil);
        },
        onGradientApplied: widget.notifier.applyGradient,
        onStartPixelDrag: (_) {
          if (widget.currentTool == PixelTool.drag) {
            widget.notifier.startDrag();
          }
        },
        onPixelDrag: (offset) {
          if (widget.currentTool == PixelTool.drag) {
            widget.notifier.dragPixels(offset);
          }
        },
        onPixelDragEnd: (_) {
          if (widget.currentTool == PixelTool.drag) {
            widget.notifier.endDrag();
          }
        },
        onUndo: widget.notifier.undo,
      ),
      inputMode: inputMode,
      twoFingerUndoEnabled: widget.editorSettings.twoFingerUndoEnabled,
      gridWidth: widget.project.width < 64 ? widget.project.width : 64,
      gridHeight: widget.project.height < 64 ? widget.project.height : 64,
      onionSkinFrames: widget.showPrevFrames
          ? List<PixelCanvasOnionSkinFrame>.generate(
              widget.state.currentFrameIndex,
              (index) => PixelCanvasOnionSkinFrame(
                frameId: widget.state.frames[index].id,
                width: widget.project.width,
                height: widget.project.height,
                layers: widget.state.frames[index].layers,
                opacity: _calculateOnionSkinOpacity(index, widget.state.currentFrameIndex, widget.onionSkinOpacity),
              ),
            )
          : const <PixelCanvasOnionSkinFrame>[],
    );
  }

  double _calculateOnionSkinOpacity(int forIndex, int count, double maxOpacity) {
    if (count <= 0 || forIndex.abs() > count) return 0.0;

    final opacityRange = maxOpacity - 0.01;
    final step = opacityRange / count;
    final opacity = step * (forIndex.abs() - 1);

    return opacity.clamp(0.05, maxOpacity);
  }
}

class _PixelCanvasSceneConfig {
  const _PixelCanvasSceneConfig({
    required this.callbacks,
    required this.inputMode,
    required this.twoFingerUndoEnabled,
    required this.gridWidth,
    required this.gridHeight,
    required this.onionSkinFrames,
  });

  final PixelCanvasCallbacks callbacks;
  final GestureInputMode inputMode;
  final bool twoFingerUndoEnabled;
  final int gridWidth;
  final int gridHeight;
  final List<PixelCanvasOnionSkinFrame> onionSkinFrames;
}
