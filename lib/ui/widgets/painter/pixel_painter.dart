import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data.dart';
import '../../../pixel/canvas/pixel_canvas.dart';
import '../../../pixel/image_painter.dart';
import '../../../pixel/pixel_canvas_state.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../pixel/tools.dart';
import '../../../providers/background_image_provider.dart';
import '../layers_preview.dart';
import 'grid_painter.dart';

class PixelPainter extends HookConsumerWidget {
  const PixelPainter({
    super.key,
    required this.project,
    required this.state,
    required this.notifier,
    required this.gridScale,
    required this.gridOffset,
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
  final ValueNotifier<double> gridScale;
  final ValueNotifier<Offset> gridOffset;
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

    return CustomPaint(
      painter: GridPainter(
        width: min(project.width, 64),
        height: min(project.height, 64),
        // scale: gridScale.value,
        // offset: gridOffset.value,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (backgroundImage.image != null)
            Positioned.fill(
              child: LayoutBuilder(builder: (context, constraints) {
                final maXWidth = constraints.maxWidth;
                final maXHeight = constraints.maxHeight;

                return Opacity(
                  opacity: backgroundImage.opacity,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(backgroundImage.scale)
                      ..translate(
                        backgroundImage.offset.dx * maXWidth,
                        backgroundImage.offset.dy * maXHeight,
                      ),
                    child: Image.memory(
                      backgroundImage.image!,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),
            ),
          // Positioned.fill(
          //   child: LayoutBuilder(builder: (context, constraints) {
          //     final maXWidth = constraints.maxWidth;
          //     final maXHeight = constraints.maxHeight;

          //     return Opacity(
          //       opacity: backgroundImage.opacity,
          //       child: Transform(
          //         transform: Matrix4.identity()
          //           ..scale(backgroundImage.scale)
          //           ..translate(
          //             backgroundImage.offset.dx * maXWidth,
          //             backgroundImage.offset.dy * maXHeight,
          //           ),
          //         child: SvgPicture.asset(
          //           'assets/vectors/black_hole.svg',
          //           fit: BoxFit.cover,
          //         ),
          //       ),
          //     );
          //   }),
          // ),
          if (showPrevFrames)
            for (var i = 0; i < state.currentFrameIndex; i++)
              Positioned.fill(
                child: Opacity(
                  opacity: calculateOnionSkinOpacity(
                    i,
                    state.currentFrameIndex,
                  ),
                  child: LayersPreview(
                    width: project.width,
                    height: project.height,
                    layers: state.frames[i].layers,
                    builder: (context, image) {
                      return image != null
                          ? CustomPaint(painter: ImagePainter(image))
                          : const ColoredBox(color: Colors.transparent);
                    },
                  ),
                ),
              ),
          Positioned.fill(
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
              zoomLevel: gridScale.value,
              currentOffset: gridOffset.value,
              eventStream: notifier.eventStream,
              onDrawShape: (points) {
                ref.read(pixelCanvasNotifierProvider(project).notifier).fillPixels(points);
              },
              onStartDrawing: () {
                ref.read(pixelCanvasNotifierProvider(project).notifier).startDrawing();
              },
              onFinishDrawing: () {
                ref.read(pixelCanvasNotifierProvider(project).notifier).endDrawing();
              },
              onSelectionChanged: (selectionPoints) {
                ref.read(pixelCanvasNotifierProvider(project).notifier).setSelection(selectionPoints);
              },
              onMoveSelection: (selectionPoints, delta) {
                ref.read(pixelCanvasNotifierProvider(project).notifier).moveSelection(selectionPoints, delta);
              },
              onSelectionResize: (selection, oldSelection, newBounds, center) {
                ref
                    .read(pixelCanvasNotifierProvider(project).notifier)
                    .resizeSelection(selection, oldSelection, newBounds, center);
              },
              onSelectionRotate: (selection, oldSelection, angle, center) {
                ref
                    .read(pixelCanvasNotifierProvider(project).notifier)
                    .rotateSelection(selection, oldSelection, angle, center);
              },
              onTransformStart: (selection) {
                ref.read(pixelCanvasNotifierProvider(project).notifier).startTransformSelection(selection);
              },
              onTransformEnd: () {
                ref.read(pixelCanvasNotifierProvider(project).notifier).endTransformSelection();
              },
              onColorPicked: (color) {
                ref.read(pixelCanvasNotifierProvider(project).notifier).currentColor =
                    color == Colors.transparent ? Colors.white : color;
                // Auto-switch back to pencil after picking a color
                onToolAutoSwitch?.call(PixelTool.pencil);
              },
              onGradientApplied: (gradientColors) {
                ref.read(pixelCanvasNotifierProvider(project).notifier).applyGradient(gradientColors);
              },
              onStartDrag: (scale, offset) {
                if (currentTool == PixelTool.drag) {
                  return ref.read(pixelCanvasNotifierProvider(project).notifier).startDrag();
                }
              },
              onDrag: (scale, offset) {
                if (currentTool == PixelTool.drag) {
                  return ref.read(pixelCanvasNotifierProvider(project).notifier).dragPixels(scale, offset);
                }

                gridScale.value = scale;
                gridOffset.value = offset;
              },
              onDragEnd: (s, o) {
                if (currentTool == PixelTool.drag) {
                  return ref.read(pixelCanvasNotifierProvider(project).notifier).endDrag();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
