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
        onTapPixel: (x, y) {
          switch (currentTool) {
            case PixelTool.pencil:
            case PixelTool.brush:
            case PixelTool.pixelPerfectLine:
            case PixelTool.sprayPaint:
              notifier.setPixel(x, y);
              break;
            case PixelTool.fill:
              notifier.fill(x, y);
              break;
            case PixelTool.eraser:
              final originalColor = notifier.currentColor;
              notifier.currentColor = Colors.transparent;
              notifier.setPixel(x, y);
              notifier.currentColor = originalColor;
              break;
            default:
              break;
          }
        },
        currentTool: currentTool,
        currentColor: currentColor,
        modifier: currentModifier,
        brushSize: brushSize.value,
        sprayIntensity: sprayIntensity.value,
        viewportController: viewportController,
        eventStream: notifier.eventStream,
        inputMode: inputMode,
        twoFingerUndoEnabled: editorSettings.twoFingerUndoEnabled,
        enableMultiTouchViewportNavigation: false,
        onDrawShape: (points) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .fillPixels(points);
        },
        onStartDrawing: () {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .startDrawing();
        },
        onFinishDrawing: () {
          ref.read(pixelCanvasNotifierProvider(project).notifier).endDrawing();
        },
        selectionState: state.selectionState,
        onSelectionChanged: (region) {
          final notifier =
              ref.read(pixelCanvasNotifierProvider(project).notifier);
          if (region == null) {
            notifier.clearSelection();
          } else {
            notifier.setSelection(region);
          }
        },
        onMoveSelection: (delta) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .moveSelection(delta);
        },
        onSelectionResize: (newRegion, oldRegion, newBounds, center) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .resizeSelectionNew(
                newRegion.bounds,
                region: newRegion,
              );
        },
        onSelectionRotate: (newRegion, oldRegion, angle, center) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .rotateSelectionNew(
                angle,
                pivot: center,
                region: newRegion,
              );
        },
        onTransformStart: (region) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .startTransformSelection(region);
        },
        onTransformEnd: () {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .endTransformSelection();
        },
        onAnchorChanged: (anchor) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .setAnchorPoint(anchor);
        },
        onColorPicked: (color) {
          ref.read(pixelCanvasNotifierProvider(project).notifier).currentColor =
              color == Colors.transparent ? Colors.white : color;
          onToolAutoSwitch?.call(PixelTool.pencil);
        },
        onGradientApplied: (gradientColors) {
          ref
              .read(pixelCanvasNotifierProvider(project).notifier)
              .applyGradient(gradientColors);
        },
        onStartDrag: (scale, offset) {
          if (currentTool == PixelTool.drag) {
            return ref
                .read(pixelCanvasNotifierProvider(project).notifier)
                .startDrag();
          }
        },
        onDrag: (scale, offset) {
          if (currentTool == PixelTool.drag) {
            return ref
                .read(pixelCanvasNotifierProvider(project).notifier)
                .dragPixels(scale, offset);
          }

          viewportController.setViewport(scale, offset);
        },
        onDragEnd: (s, o) {
          if (currentTool == PixelTool.drag) {
            return ref
                .read(pixelCanvasNotifierProvider(project).notifier)
                .endDrag();
          }
        },
      ),
    );
  }
}
