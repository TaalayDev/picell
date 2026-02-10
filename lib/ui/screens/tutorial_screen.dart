import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/pixel/tools/pencil_tool.dart';

import '../../pixel/canvas/pixel_canvas.dart';
import '../../pixel/pixel_point.dart';
import '../../pixel/tools.dart';
import '../../data.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../widgets/painter/grid_painter.dart';

class DrawingStep {
  final String title;
  final String description;
  final String imageAsset; // Reference image to show
  final List<PixelPoint<int>> expectedPixels; // Expected pixel positions
  final PixelTool requiredTool; // Tool that should be used
  final Color? requiredColor; // Color that should be used
  final double similarity; // How close the drawing needs to be (0-1)

  DrawingStep({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.expectedPixels,
    required this.requiredTool,
    this.requiredColor,
    this.similarity = 0.8,
  });
}

class DrawingTutorial {
  final String title;
  final String description;
  final List<DrawingStep> steps;

  DrawingTutorial({
    required this.title,
    required this.description,
    required this.steps,
  });
}

final tutorialProvider = Provider<DrawingTutorial>((ref) {
  // Example tutorial data
  return DrawingTutorial(
    title: 'Drawing a Simple Tree',
    description: 'Learn to draw a pixel art tree step by step',
    steps: [
      DrawingStep(
        title: 'Draw the Trunk',
        description: 'Start by drawing a simple brown trunk using the pencil tool.',
        imageAsset: 'assets/tutorials/tree/trunk.png',
        expectedPixels: [
          PixelPoint(10, 15, color: Colors.brown.value),
          PixelPoint(10, 16, color: Colors.brown.value),
          // Add more expected pixel positions...
        ],
        requiredTool: PixelTool.pencil,
        requiredColor: Colors.brown,
      ),
      DrawingStep(
        title: 'Add Leaves',
        description: 'Use the brush tool to add green leaves on top.',
        imageAsset: 'assets/tutorials/tree/leaves.png',
        expectedPixels: [
          PixelPoint(9, 12, color: Colors.green.value),
          PixelPoint(10, 12, color: Colors.green.value),
          // Add more expected pixel positions...
        ],
        requiredTool: PixelTool.brush,
        requiredColor: Colors.green,
      ),
      // Add more steps...
    ],
  );
});

class DrawingTutorialScreen extends HookConsumerWidget {
  const DrawingTutorialScreen({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorial = ref.watch(tutorialProvider);
    final currentStep = useState(0);
    final provider = pixelCanvasNotifierProvider(project);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final isCompactWidth = MediaQuery.sizeOf(context).width < 600;
    final isMediumWidth = MediaQuery.sizeOf(context).width < 900;
    final isExpandedWidth = MediaQuery.sizeOf(context).width >= 900;

    final showBrushPicker = useState(false);
    final showShapePicker = useState(false);
    final showStartDrawing = useState(false);

    final canUndo = state.canUndo;
    final canRedo = state.canRedo;
    final currentTool = PencilTool();

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Left sidebar for expanded width (desktop)
            if (isExpandedWidth)
              LessonSidebar(
                lesson: tutorial,
                currentPage: currentStep.value,
                canMoveNext: canUndo,
                onPageSelected: (page) {
                  currentStep.value = page;
                },
                onStartDrawing: () => showStartDrawing.value = true,
              ),

            // Main content
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(
                    context,
                    tutorial,
                    currentStep.value,
                    tutorial.steps.length,
                    currentTool,
                    () => showBrushPicker.value = true,
                    () => showShapePicker.value = true,
                  ),

                  // Drawing area
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: project.width / project.height,
                            child: CustomPaint(
                              painter: GridPainter(
                                width: min(project.width, 64),
                                height: min(project.height, 64),
                                // scale: gridScale.value,
                                // offset: gridOffset.value,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: AspectRatio(
                            aspectRatio: project.width / project.height,
                            child: PixelCanvas(
                              width: project.width,
                              height: project.height,
                              layers: state.layers,
                              currentLayerIndex: state.currentLayerIndex,
                              onTapPixel: (x, y) => notifier.setPixel(x, y),
                              onStartDrawing: () {},
                              onFinishDrawing: () {},
                              currentTool: state.currentTool,
                              currentColor: state.currentColor,
                              onDrawShape: (points) => notifier.fillPixels(
                                points,
                              ),
                            ),
                          ),
                        ),

                        // Undo/Redo buttons
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildUndoRedoButtons(
                            context,
                            canUndo,
                            canRedo,
                          ),
                        ),

                        // Step description overlay
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Card(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                tutorial.steps[currentStep.value].description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom navigation for compact/medium width
                  if (!isExpandedWidth)
                    _buildBottomNavigation(
                      context,
                      currentStep.value,
                      tutorial.steps.length,
                      canUndo,
                      () {
                        if (currentStep.value > 0) {
                          currentStep.value--;
                        }
                      },
                      () {
                        if (currentStep.value < tutorial.steps.length - 1) {
                          currentStep.value++;
                        } else {
                          showStartDrawing.value = true;
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    DrawingTutorial lesson,
    int currentPage,
    int totalPages,
    Tool currentTool,
    VoidCallback onBrushTap,
    VoidCallback onShapeTap,
  ) {
    return AppBar(
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentPage + 1} of $totalPages',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
      leading: const BackButton(),
      actions: [
        IconButton(
          icon: const Icon(Entypo.brush),
          onPressed: onBrushTap,
          color: currentTool.isPencil || currentTool.isBrush ? Theme.of(context).colorScheme.primary : null,
        ),
        IconButton(
          icon: const Icon(Feather.square),
          onPressed: onShapeTap,
          color: currentTool.isCircle || currentTool.isRectangle || currentTool.isLine
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        IconButton(
          icon: const Icon(Fontisto.eraser),
          onPressed: () {},
          color: currentTool.isEraser ? Theme.of(context).colorScheme.primary : null,
        ),
      ],
    );
  }

  Widget _buildUndoRedoButtons(
    BuildContext context,
    bool canUndo,
    bool canRedo,
  ) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(EvilIcons.undo),
          onPressed: canUndo ? () {} : null,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(EvilIcons.redo),
          onPressed: canRedo ? () {} : null,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    int currentPage,
    int totalPages,
    bool canMoveNext,
    VoidCallback onPrevious,
    VoidCallback onNext,
  ) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: currentPage > 0 ? onPrevious : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
            Column(
              children: [
                Text(
                  'Step ${currentPage + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentPage + 1) / totalPages,
                  minHeight: 4,
                ),
              ],
            ),
            TextButton.icon(
              onPressed: canMoveNext ? onNext : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                currentPage == totalPages - 1 ? 'Start Drawing' : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonSidebar extends StatelessWidget {
  final DrawingTutorial lesson;
  final int currentPage;
  final bool canMoveNext;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onStartDrawing;

  const LessonSidebar({
    super.key,
    required this.lesson,
    required this.currentPage,
    required this.canMoveNext,
    required this.onPageSelected,
    required this.onStartDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: (currentPage + 1) / lesson.steps.length,
            minHeight: 4,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: lesson.steps.length,
              itemBuilder: (context, index) {
                return LessonStepCard(
                  step: lesson.steps[index],
                  stepNumber: index + 1,
                  isCompleted: index < currentPage,
                  isActive: index == currentPage,
                  onTap: () => onPageSelected(index),
                );
              },
            ),
          ),
          if (currentPage == lesson.steps.length - 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: onStartDrawing,
                icon: const Icon(Icons.draw),
                label: const Text('Start Drawing'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LessonStepCard extends StatelessWidget {
  final DrawingStep step;
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;

  const LessonStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive
        ? Theme.of(context).colorScheme.primaryContainer
        : isCompleted
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.surface;

    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : Text(stepNumber.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step $stepNumber',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
