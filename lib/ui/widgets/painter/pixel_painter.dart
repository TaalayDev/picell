import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data.dart';
import '../../../pixel/canvas/canvas_gesture_handler.dart';
import '../../../pixel/canvas/pixel_canvas.dart';
import '../../../pixel/canvas/pixel_viewport_controller.dart';
import '../../../pixel/pixel_canvas_state.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../pixel/tools.dart';
import '../../../providers/background_image_provider.dart';
import '../../../providers/editor_settings_provider.dart';
import 'pixel_canvas_surface.dart';
import 'pixel_painter_bindings.dart';

class PixelPainter extends HookConsumerWidget {
  const PixelPainter({
    super.key,
    required this.project,
    required this.state,
    required this.notifier,
    required this.viewportController,
    required this.currentTool,
    required this.currentModifier,
    required this.currentColor,
    required this.brushSize,
    required this.sprayIntensity,
    this.showPrevFrames = false,
    this.onToolAutoSwitch,
  });

  final Project project;
  final PixelCanvasState state;
  final PixelCanvasNotifier notifier;
  final PixelViewportController viewportController;
  final PixelTool currentTool;
  final PixelModifier currentModifier;
  final Color currentColor;
  final ValueNotifier<int> brushSize;
  final ValueNotifier<int> sprayIntensity;
  final bool showPrevFrames;
  final Function(PixelTool)? onToolAutoSwitch;

  double calculateOnionSkinOpacity(int forIndex, int count) {
    if (count <= 0 || forIndex.abs() > count) {
      return 0.0;
    }

    const opacityRange = 0.5 - 0.01;
    final step = opacityRange / count;

    final opacity = (step * (forIndex.abs() - 1));

    return opacity.clamp(0.1, 0.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundImage = ref.watch(backgroundImageProvider);
    final editorSettings = ref.watch(editorSettingsNotifierProvider);
    final canvasCallbacks = PixelPainterBindings.buildCanvasCallbacks(
      notifier: notifier,
      currentTool: currentTool,
      onToolAutoSwitch: onToolAutoSwitch,
    );

    // Map editor settings to gesture handler input mode
    final inputMode = editorSettings.inputMode == InputMode.stylusOnly
        ? GestureInputMode.stylusOnly
        : GestureInputMode.standard;
    final onionSkinFrames = showPrevFrames
        ? List<PixelCanvasOnionSkinFrame>.generate(
            state.currentFrameIndex,
            (index) => PixelCanvasOnionSkinFrame(
              frameId: state.frames[index].id,
              width: project.width,
              height: project.height,
              layers: state.frames[index].layers,
              opacity: calculateOnionSkinOpacity(
                index,
                state.currentFrameIndex,
              ),
            ),
          )
        : const <PixelCanvasOnionSkinFrame>[];

    return PixelCanvasSurface(
      gridWidth: min(project.width, 64),
      gridHeight: min(project.height, 64),
      backgroundImageBytes: backgroundImage.image,
      backgroundOpacity: backgroundImage.opacity,
      backgroundScale: backgroundImage.scale,
      backgroundOffset: backgroundImage.offset,
      onionSkinFrames: onionSkinFrames,
      child: PixelCanvas(
        width: project.width,
        height: project.height,
        layers: state.layers,
        currentLayerIndex: state.currentLayerIndex,
        currentTool: currentTool,
        currentColor: currentColor,
        modifier: currentModifier,
        brushSize: brushSize.value,
        sprayIntensity: sprayIntensity.value,
        callbacks: canvasCallbacks,
        viewportController: viewportController,
        eventStream: notifier.eventStream,
        inputMode: inputMode,
        twoFingerUndoEnabled: editorSettings.twoFingerUndoEnabled,
        enableMultiTouchViewportNavigation: false,
        selectionState: state.selectionState,
      ),
    );
  }
}
