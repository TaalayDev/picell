import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../../pixel/pixel_point.dart';
import '../../pixel/tools.dart';
import '../../pixel/pixel_canvas_state.dart';

// Platform detection
bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool get isTouch => isMobile || kIsWeb;

// Main Animation Screen with responsive design
class AnimationScreen extends StatefulHookConsumerWidget {
  final Project project;

  const AnimationScreen({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends ConsumerState<AnimationScreen> with TickerProviderStateMixin {
  late final AnimationCanvasController _canvasController;
  late final AnimationController _previewController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _canvasController = AnimationCanvasController(
      project: widget.project,
    );
    _previewController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _canvasController.dispose();
    _previewController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFrame = useState(0);
    final isPlaying = useState(false);
    final selectedCurve = useState(Curves.easeInOut);
    final transformMode = useState(TransformMode.move);
    final frameCount = useState(10);
    final isControlPanelOpen = useState(!isDesktop); // Open by default on mobile

    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: isDesktop ? (event) => _handleKeyboardShortcuts(event, transformMode, isPlaying) : null,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(context, isPlaying, isControlPanelOpen),
        body: isWideScreen
            ? _buildDesktopLayout(
                context,
                currentFrame,
                isPlaying,
                selectedCurve,
                transformMode,
                frameCount,
              )
            : _buildMobileLayout(
                context,
                currentFrame,
                isPlaying,
                selectedCurve,
                transformMode,
                frameCount,
                isControlPanelOpen,
                isMediumScreen,
              ),
        floatingActionButton: isMobile ? _buildMobileFAB(transformMode, isControlPanelOpen) : null,
        bottomNavigationBar: isMobile ? _buildMobileBottomBar(transformMode) : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ValueNotifier<bool> isPlaying,
    ValueNotifier<bool> isControlPanelOpen,
  ) {
    return AppBar(
      title: Text('Animate: ${widget.project.name}'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        // Play/Pause button
        IconButton(
          icon: Icon(isPlaying.value ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            isPlaying.value = !isPlaying.value;
            if (isPlaying.value) {
              _previewController.repeat();
            } else {
              _previewController.stop();
            }
          },
          tooltip: isPlaying.value ? 'Pause' : 'Play',
        ),

        // Desktop-specific actions
        if (isDesktop) ...[
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _canvasController.undo(),
            tooltip: 'Undo (Ctrl+Z)',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => _canvasController.redo(),
            tooltip: 'Redo (Ctrl+Y)',
          ),
        ],

        // Mobile panel toggle
        if (isMobile)
          IconButton(
            icon: Icon(isControlPanelOpen.value ? Icons.close : Icons.settings),
            onPressed: () => isControlPanelOpen.value = !isControlPanelOpen.value,
          ),

        // Save button
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () => _saveAnimation(),
          tooltip: 'Save Animation',
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ValueNotifier<int> currentFrame,
    ValueNotifier<bool> isPlaying,
    ValueNotifier<Curve> selectedCurve,
    ValueNotifier<TransformMode> transformMode,
    ValueNotifier<int> frameCount,
  ) {
    return Row(
      children: [
        // Main Canvas Area
        Expanded(
          flex: 3,
          child: ResponsiveAnimationCanvas(
            controller: _canvasController,
            project: widget.project,
            currentFrame: currentFrame.value,
            transformMode: transformMode.value,
            onFrameChanged: (frame) => currentFrame.value = frame,
            isDesktop: true,
          ),
        ),

        // Right Control Panel
        Container(
          width: 320,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: _buildControlPanels(
            context,
            transformMode,
            selectedCurve,
            frameCount,
            currentFrame,
            isVertical: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ValueNotifier<int> currentFrame,
    ValueNotifier<bool> isPlaying,
    ValueNotifier<Curve> selectedCurve,
    ValueNotifier<TransformMode> transformMode,
    ValueNotifier<int> frameCount,
    ValueNotifier<bool> isControlPanelOpen,
    bool isMediumScreen,
  ) {
    return Stack(
      children: [
        // Main Canvas (full screen)
        ResponsiveAnimationCanvas(
          controller: _canvasController,
          project: widget.project,
          currentFrame: currentFrame.value,
          transformMode: transformMode.value,
          onFrameChanged: (frame) => currentFrame.value = frame,
          isDesktop: false,
        ),

        // Overlay controls
        if (isControlPanelOpen.value)
          _buildMobileControlOverlay(
            context,
            transformMode,
            selectedCurve,
            frameCount,
            currentFrame,
            isMediumScreen,
          ),
      ],
    );
  }

  Widget _buildMobileControlOverlay(
    BuildContext context,
    ValueNotifier<TransformMode> transformMode,
    ValueNotifier<Curve> selectedCurve,
    ValueNotifier<int> frameCount,
    ValueNotifier<int> currentFrame,
    bool isMediumScreen,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Controls
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildControlPanels(
                    context,
                    transformMode,
                    selectedCurve,
                    frameCount,
                    currentFrame,
                    isVertical: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlPanels(BuildContext context, ValueNotifier<TransformMode> transformMode,
      ValueNotifier<Curve> selectedCurve, ValueNotifier<int> frameCount, ValueNotifier<int> currentFrame,
      {required bool isVertical}) {
    final children = [
      // Transform Controls
      ResponsiveTransformControlsPanel(
        transformMode: transformMode.value,
        onTransformModeChanged: (mode) => transformMode.value = mode,
        controller: _canvasController,
        isDesktop: isDesktop,
      ),

      if (isVertical) const Divider(),

      // Animation Curve Selector
      ResponsiveCurveSelectorPanel(
        selectedCurve: selectedCurve.value,
        onCurveChanged: (curve) => selectedCurve.value = curve,
        isCompact: !isDesktop,
      ),

      if (isVertical) const Divider(),

      // Frame Generation
      ResponsiveFrameGenerationPanel(
        frameCount: frameCount.value,
        onFrameCountChanged: (count) => frameCount.value = count,
        onGenerateFrames: () => _generateFrames(selectedCurve.value, frameCount.value),
        isCompact: !isDesktop,
      ),

      if (isVertical) const Divider(),

      // Timeline
      if (isVertical)
        Expanded(
          child: ResponsiveAnimationTimelinePanel(
            frames: _canvasController.animationFrames,
            currentFrame: currentFrame.value,
            onFrameSelected: (frame) => currentFrame.value = frame,
            onFrameDeleted: (frame) => _canvasController.deleteFrame(frame),
            isDesktop: isDesktop,
          ),
        )
      else
        SizedBox(
          height: 200,
          child: ResponsiveAnimationTimelinePanel(
            frames: _canvasController.animationFrames,
            currentFrame: currentFrame.value,
            onFrameSelected: (frame) => currentFrame.value = frame,
            onFrameDeleted: (frame) => _canvasController.deleteFrame(frame),
            isDesktop: isDesktop,
          ),
        ),
    ];

    return isVertical
        ? Column(children: children)
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          );
  }

  Widget? _buildMobileFAB(ValueNotifier<TransformMode> transformMode, ValueNotifier<bool> isControlPanelOpen) {
    return SpeedDial(
      icon: Icons.transform,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.open_with),
          label: 'Move',
          onTap: () => transformMode.value = TransformMode.move,
        ),
        SpeedDialChild(
          child: const Icon(Icons.zoom_out_map),
          label: 'Scale',
          onTap: () => transformMode.value = TransformMode.scale,
        ),
        SpeedDialChild(
          child: const Icon(Icons.rotate_right),
          label: 'Rotate',
          onTap: () => transformMode.value = TransformMode.rotate,
        ),
      ],
    );
  }

  Widget? _buildMobileBottomBar(ValueNotifier<TransformMode> transformMode) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: transformMode.value.index,
      onTap: (index) => transformMode.value = TransformMode.values[index],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.open_with),
          label: 'Move',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.zoom_out_map),
          label: 'Scale',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rotate_right),
          label: 'Rotate',
        ),
      ],
    );
  }

  void _handleKeyboardShortcuts(
    KeyEvent event,
    ValueNotifier<TransformMode> transformMode,
    ValueNotifier<bool> isPlaying,
  ) {
    if (event is KeyDownEvent) {
      final isCtrl =
          event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight;
      final isShift =
          event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight;

      if (HardwareKeyboard.instance.isControlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyZ:
            _canvasController.undo();
            break;
          case LogicalKeyboardKey.keyY:
            _canvasController.redo();
            break;
          case LogicalKeyboardKey.keyS:
            _saveAnimation();
            break;
        }
      }

      // Tool shortcuts
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyM:
          transformMode.value = TransformMode.move;
          break;
        case LogicalKeyboardKey.keyS:
          if (!HardwareKeyboard.instance.isControlPressed) {
            transformMode.value = TransformMode.scale;
          }
          break;
        case LogicalKeyboardKey.keyR:
          transformMode.value = TransformMode.rotate;
          break;
        case LogicalKeyboardKey.space:
          isPlaying.value = !isPlaying.value;
          break;
      }
    }
  }

  void _generateFrames(Curve curve, int frameCount) {
    _canvasController.generateAnimationFrames(curve, frameCount);
  }

  void _saveAnimation() {
    Navigator.of(context).pop(_canvasController.getAnimatedProject());
  }
}

// Responsive Animation Canvas
class ResponsiveAnimationCanvas extends StatefulWidget {
  final AnimationCanvasController controller;
  final Project project;
  final int currentFrame;
  final TransformMode transformMode;
  final Function(int) onFrameChanged;
  final bool isDesktop;

  const ResponsiveAnimationCanvas({
    super.key,
    required this.controller,
    required this.project,
    required this.currentFrame,
    required this.transformMode,
    required this.onFrameChanged,
    required this.isDesktop,
  });

  @override
  State<ResponsiveAnimationCanvas> createState() => _ResponsiveAnimationCanvasState();
}

class _ResponsiveAnimationCanvasState extends State<ResponsiveAnimationCanvas> {
  Offset? _lastFocalPoint;
  TransformData _initialTransform = TransformData.identity();
  bool _isTransforming = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: AspectRatio(
          aspectRatio: widget.project.width / widget.project.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: widget.isDesktop ? _buildDesktopCanvas() : _buildMobileCanvas(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCanvas() {
    return MouseRegion(
      cursor: _getMouseCursor(),
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerSignal: _handlePointerSignal,
        child: _buildCanvas(),
      ),
    );
  }

  Widget _buildMobileCanvas() {
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: _buildCanvas(),
    );
  }

  Widget _buildCanvas() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          painter: AnimationCanvasPainter(
            project: widget.project,
            controller: widget.controller,
            currentFrame: widget.currentFrame,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // Desktop mouse handling
  MouseCursor _getMouseCursor() {
    switch (widget.transformMode) {
      case TransformMode.move:
        return _isTransforming ? SystemMouseCursors.grabbing : SystemMouseCursors.grab;
      case TransformMode.scale:
        return SystemMouseCursors.resizeDownRight;
      case TransformMode.rotate:
        return SystemMouseCursors.click;
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _lastFocalPoint = event.localPosition;
    _initialTransform = widget.controller.currentTransform;
    _isTransforming = true;
    setState(() {});
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isTransforming || _lastFocalPoint == null) return;

    final delta = event.localPosition - _lastFocalPoint!;
    _updateTransform(delta, 1.0, 0.0);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _isTransforming = false;
    _lastFocalPoint = null;
    setState(() {});
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Handle zoom with mouse wheel
      if (widget.transformMode == TransformMode.scale) {
        final scale = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
        final newTransform = widget.controller.currentTransform.copyWith(
          scaleX: widget.controller.currentTransform.scaleX * scale,
          scaleY: widget.controller.currentTransform.scaleY * scale,
        );
        widget.controller.setCurrentTransform(newTransform);
      }
    }
  }

  // Mobile touch handling
  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _initialTransform = widget.controller.currentTransform;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_lastFocalPoint == null) return;

    final delta = details.focalPoint - _lastFocalPoint!;
    _updateTransform(delta, details.scale, details.rotation);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
  }

  void _updateTransform(Offset delta, double scale, double rotation) {
    switch (widget.transformMode) {
      case TransformMode.move:
        final newTransform = _initialTransform.copyWith(
          translateX: _initialTransform.translateX + delta.dx * 0.5,
          translateY: _initialTransform.translateY + delta.dy * 0.5,
        );
        widget.controller.setCurrentTransform(newTransform);
        break;

      case TransformMode.scale:
        if (scale != 1.0) {
          final newTransform = _initialTransform.copyWith(
            scaleX: _initialTransform.scaleX * scale,
            scaleY: _initialTransform.scaleY * scale,
          );
          widget.controller.setCurrentTransform(newTransform);
        }
        break;

      case TransformMode.rotate:
        if (rotation != 0.0) {
          final newTransform = _initialTransform.copyWith(
            rotation: _initialTransform.rotation + rotation,
          );
          widget.controller.setCurrentTransform(newTransform);
        }
        break;
    }
  }
}

// Responsive Transform Controls Panel
class ResponsiveTransformControlsPanel extends StatelessWidget {
  final TransformMode transformMode;
  final Function(TransformMode) onTransformModeChanged;
  final AnimationCanvasController controller;
  final bool isDesktop;

  const ResponsiveTransformControlsPanel({
    super.key,
    required this.transformMode,
    required this.onTransformModeChanged,
    required this.controller,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transform Controls',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Transform mode buttons
          if (isDesktop)
            Row(
              children: TransformMode.values.map((mode) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _TransformButton(
                      icon: _getTransformIcon(mode),
                      isSelected: transformMode == mode,
                      onPressed: () => onTransformModeChanged(mode),
                      tooltip: '${mode.name} (${_getShortcut(mode)})',
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Wrap(
              spacing: 8,
              children: TransformMode.values.map((mode) {
                return _TransformButton(
                  icon: _getTransformIcon(mode),
                  isSelected: transformMode == mode,
                  onPressed: () => onTransformModeChanged(mode),
                  tooltip: mode.name,
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          // Start/End transform buttons
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.setStartTransform(controller.currentTransform),
                    child: const Text('Set Start'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.setEndTransform(controller.currentTransform),
                    child: const Text('Set End'),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.setStartTransform(controller.currentTransform),
                    child: const Text('Set Start Position'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.setEndTransform(controller.currentTransform),
                    child: const Text('Set End Position'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.setCurrentTransform(TransformData.identity()),
              child: const Text('Reset Transform'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransformIcon(TransformMode mode) {
    switch (mode) {
      case TransformMode.move:
        return Icons.open_with;
      case TransformMode.scale:
        return Icons.zoom_out_map;
      case TransformMode.rotate:
        return Icons.rotate_right;
    }
  }

  String _getShortcut(TransformMode mode) {
    switch (mode) {
      case TransformMode.move:
        return 'M';
      case TransformMode.scale:
        return 'S';
      case TransformMode.rotate:
        return 'R';
    }
  }
}

class _TransformButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final String tooltip;

  const _TransformButton({
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
      ),
    );
  }
}

// Responsive Curve Selector Panel
class ResponsiveCurveSelectorPanel extends StatelessWidget {
  final Curve selectedCurve;
  final Function(Curve) onCurveChanged;
  final bool isCompact;

  const ResponsiveCurveSelectorPanel({
    super.key,
    required this.selectedCurve,
    required this.onCurveChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final curves = [
      ('Linear', Curves.linear),
      ('Ease In', Curves.easeIn),
      ('Ease Out', Curves.easeOut),
      ('Ease In Out', Curves.easeInOut),
      ('Bounce', Curves.bounceOut),
      ('Elastic', Curves.elasticOut),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Animation Curve',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (isCompact)
            DropdownButtonFormField<Curve>(
              value: selectedCurve,
              decoration: const InputDecoration(
                labelText: 'Curve Type',
                border: OutlineInputBorder(),
              ),
              items: curves.map((curveData) {
                return DropdownMenuItem(
                  value: curveData.$2,
                  child: Text(curveData.$1),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onCurveChanged(value);
                }
              },
            )
          else
            ...curves.map((curveData) {
              final name = curveData.$1;
              final curve = curveData.$2;

              return RadioListTile<Curve>(
                title: Text(name),
                value: curve,
                groupValue: selectedCurve,
                onChanged: (value) {
                  if (value != null) {
                    onCurveChanged(value);
                  }
                },
                dense: true,
              );
            }).toList(),
        ],
      ),
    );
  }
}

// Responsive Frame Generation Panel
class ResponsiveFrameGenerationPanel extends StatelessWidget {
  final int frameCount;
  final Function(int) onFrameCountChanged;
  final VoidCallback onGenerateFrames;
  final bool isCompact;

  const ResponsiveFrameGenerationPanel({
    super.key,
    required this.frameCount,
    required this.onFrameCountChanged,
    required this.onGenerateFrames,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frame Generation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Frames: '),
              Expanded(
                child: Slider(
                  value: frameCount.toDouble(),
                  min: 2,
                  max: 30,
                  divisions: 28,
                  label: frameCount.toString(),
                  onChanged: (value) => onFrameCountChanged(value.toInt()),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  frameCount.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerateFrames,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Animation'),
            ),
          ),
        ],
      ),
    );
  }
}

// Responsive Animation Timeline Panel
class ResponsiveAnimationTimelinePanel extends StatelessWidget {
  final List<AnimationFrameData> frames;
  final int currentFrame;
  final Function(int) onFrameSelected;
  final Function(int) onFrameDeleted;
  final bool isDesktop;

  const ResponsiveAnimationTimelinePanel({
    super.key,
    required this.frames,
    required this.currentFrame,
    required this.onFrameSelected,
    required this.onFrameDeleted,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline (${frames.length} frames)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: frames.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No frames generated yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set start & end positions, then generate frames',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: frames.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == currentFrame;

                      return Card(
                        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
                            foregroundColor: isSelected ? Colors.white : null,
                            child: Text('${index + 1}'),
                          ),
                          title: Text('Frame ${index + 1}'),
                          subtitle: isDesktop ? Text('Transform: ${frames[index].transform.toString()}') : null,
                          trailing: isDesktop
                              ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => onFrameDeleted(index),
                                )
                              : PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      onFrameDeleted(index);
                                    }
                                  },
                                ),
                          onTap: () => onFrameSelected(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Speed Dial for mobile FAB
class SpeedDial extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final List<SpeedDialChild> children;

  const SpeedDial({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.children,
  });

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial> with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.children.reversed.map((child) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.scale(
                scale: _controller.value,
                child: Opacity(
                  opacity: _controller.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: FloatingActionButton.small(
                      onPressed: () {
                        child.onTap();
                        _toggle();
                      },
                      tooltip: child.label,
                      child: child.child,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
        FloatingActionButton(
          onPressed: _toggle,
          child: Icon(_isOpen ? widget.activeIcon : widget.icon),
        ),
      ],
    );
  }
}

class SpeedDialChild {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const SpeedDialChild({
    required this.child,
    required this.label,
    required this.onTap,
  });
}

// Animation Canvas Controller (unchanged from previous implementation)
class AnimationCanvasController extends ChangeNotifier {
  final Project project;
  List<AnimationFrameData> _animationFrames = [];
  TransformData _currentTransform = TransformData.identity();
  TransformData _startTransform = TransformData.identity();
  TransformData _endTransform = TransformData.identity();
  final List<TransformData> _undoStack = [];
  final List<TransformData> _redoStack = [];

  AnimationCanvasController({required this.project}) {
    _initializeFrames();
  }

  List<AnimationFrameData> get animationFrames => _animationFrames;
  TransformData get currentTransform => _currentTransform;
  TransformData get startTransform => _startTransform;
  TransformData get endTransform => _endTransform;

  void _initializeFrames() {
    if (project.frames.isNotEmpty) {
      _animationFrames = [
        AnimationFrameData(
          frame: project.frames.first,
          transform: TransformData.identity(),
        )
      ];
    }
  }

  void setCurrentTransform(TransformData transform) {
    _undoStack.add(_currentTransform);
    _redoStack.clear();
    _currentTransform = transform;
    notifyListeners();
  }

  void setStartTransform(TransformData transform) {
    _startTransform = transform;
    notifyListeners();
  }

  void setEndTransform(TransformData transform) {
    _endTransform = transform;
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_currentTransform);
      _currentTransform = _undoStack.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_currentTransform);
      _currentTransform = _redoStack.removeLast();
      notifyListeners();
    }
  }

  void generateAnimationFrames(Curve curve, int frameCount) {
    _animationFrames.clear();

    for (int i = 0; i < frameCount; i++) {
      final t = i / (frameCount - 1);
      final curveValue = curve.transform(t);

      final interpolatedTransform = TransformData.lerp(
        _startTransform,
        _endTransform,
        curveValue,
      );

      _animationFrames.add(AnimationFrameData(
        frame: _createTransformedFrame(project.frames.first, interpolatedTransform),
        transform: interpolatedTransform,
      ));
    }

    notifyListeners();
  }

  AnimationFrame _createTransformedFrame(AnimationFrame originalFrame, TransformData transform) {
    final transformedLayers = originalFrame.layers.map((layer) {
      return _transformLayer(layer, transform);
    }).toList();

    return originalFrame.copyWith(
      layers: transformedLayers,
      name: '${originalFrame.name}_transformed',
    );
  }

  Layer _transformLayer(Layer layer, TransformData transform) {
    final transformedPixels = _transformPixels(
      layer.pixels,
      project.width,
      project.height,
      transform,
    );

    return layer.copyWith(pixels: transformedPixels);
  }

  Uint32List _transformPixels(
    Uint32List pixels,
    int width,
    int height,
    TransformData transform,
  ) {
    final transformedPixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final pixel = pixels[index];

        if (pixel != 0) {
          final transformedPoint = _transformPoint(
            x.toDouble(),
            y.toDouble(),
            width,
            height,
            transform,
          );

          final newX = transformedPoint.dx.round();
          final newY = transformedPoint.dy.round();

          if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
            final newIndex = newY * width + newX;
            transformedPixels[newIndex] = pixel;
          }
        }
      }
    }

    return transformedPixels;
  }

  Offset _transformPoint(
    double x,
    double y,
    int width,
    int height,
    TransformData transform,
  ) {
    final centerX = width / 2;
    final centerY = height / 2;

    x -= centerX;
    y -= centerY;

    final cos = math.cos(transform.rotation);
    final sin = math.sin(transform.rotation);
    final rotatedX = x * cos - y * sin;
    final rotatedY = x * sin + y * cos;

    final scaledX = rotatedX * transform.scaleX;
    final scaledY = rotatedY * transform.scaleY;

    final finalX = scaledX + centerX + transform.translateX;
    final finalY = scaledY + centerY + transform.translateY;

    return Offset(finalX, finalY);
  }

  void deleteFrame(int index) {
    if (index >= 0 && index < _animationFrames.length) {
      _animationFrames.removeAt(index);
      notifyListeners();
    }
  }

  Project getAnimatedProject() {
    final animatedFrames = _animationFrames.map((frameData) => frameData.frame).toList();

    return project.copyWith(
      frames: animatedFrames,
      editedAt: DateTime.now(),
    );
  }
}

// Animation Canvas Painter (unchanged from previous implementation)
class AnimationCanvasPainter extends CustomPainter {
  final Project project;
  final AnimationCanvasController controller;
  final int currentFrame;

  AnimationCanvasPainter({
    required this.project,
    required this.controller,
    required this.currentFrame,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / project.width;
    final pixelHeight = size.height / project.height;

    _drawGrid(canvas, size, pixelWidth, pixelHeight);

    if (controller.animationFrames.isNotEmpty && currentFrame < controller.animationFrames.length) {
      _drawFrame(canvas, size, controller.animationFrames[currentFrame].frame);
    } else if (project.frames.isNotEmpty) {
      _drawFrame(canvas, size, project.frames.first);
    }

    _drawTransformHandles(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size, double pixelWidth, double pixelHeight) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int x = 0; x <= project.width; x++) {
      canvas.drawLine(
        Offset(x * pixelWidth, 0),
        Offset(x * pixelWidth, size.height),
        paint,
      );
    }

    for (int y = 0; y <= project.height; y++) {
      canvas.drawLine(
        Offset(0, y * pixelHeight),
        Offset(size.width, y * pixelHeight),
        paint,
      );
    }
  }

  void _drawFrame(Canvas canvas, Size size, AnimationFrame frame) {
    final pixelWidth = size.width / project.width;
    final pixelHeight = size.height / project.height;

    for (final layer in frame.layers) {
      if (!layer.isVisible) continue;
      _drawLayer(canvas, layer, pixelWidth, pixelHeight);
    }
  }

  void _drawLayer(Canvas canvas, Layer layer, double pixelWidth, double pixelHeight) {
    final paint = Paint();

    for (int y = 0; y < project.height; y++) {
      for (int x = 0; x < project.width; x++) {
        final index = y * project.width + x;
        if (index < layer.pixels.length) {
          final pixel = layer.pixels[index];
          if (pixel != 0) {
            paint.color = Color(pixel);
            canvas.drawRect(
              Rect.fromLTWH(
                x * pixelWidth,
                y * pixelHeight,
                pixelWidth,
                pixelHeight,
              ),
              paint,
            );
          }
        }
      }
    }
  }

  void _drawTransformHandles(Canvas canvas, Size size) {
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      6,
      handlePaint,
    );

    const handleSize = 8.0;
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    for (final corner in corners) {
      canvas.drawRect(
        Rect.fromCenter(
          center: corner,
          width: handleSize,
          height: handleSize,
        ),
        handlePaint,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AnimationCanvasPainter oldDelegate) {
    return oldDelegate.currentFrame != currentFrame || oldDelegate.controller != controller;
  }
}

// Data Models (unchanged from previous implementation)
class AnimationFrameData {
  final AnimationFrame frame;
  final TransformData transform;

  AnimationFrameData({
    required this.frame,
    required this.transform,
  });
}

class TransformData {
  final double translateX;
  final double translateY;
  final double scaleX;
  final double scaleY;
  final double rotation;

  const TransformData({
    required this.translateX,
    required this.translateY,
    required this.scaleX,
    required this.scaleY,
    required this.rotation,
  });

  static TransformData identity() => const TransformData(
        translateX: 0,
        translateY: 0,
        scaleX: 1,
        scaleY: 1,
        rotation: 0,
      );

  static TransformData lerp(TransformData a, TransformData b, double t) {
    return TransformData(
      translateX: a.translateX + (b.translateX - a.translateX) * t,
      translateY: a.translateY + (b.translateY - a.translateY) * t,
      scaleX: a.scaleX + (b.scaleX - a.scaleX) * t,
      scaleY: a.scaleY + (b.scaleY - a.scaleY) * t,
      rotation: a.rotation + (b.rotation - a.rotation) * t,
    );
  }

  TransformData copyWith({
    double? translateX,
    double? translateY,
    double? scaleX,
    double? scaleY,
    double? rotation,
  }) {
    return TransformData(
      translateX: translateX ?? this.translateX,
      translateY: translateY ?? this.translateY,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  String toString() {
    return 'T(${translateX.toStringAsFixed(1)}, ${translateY.toStringAsFixed(1)}) '
        'S(${scaleX.toStringAsFixed(2)}, ${scaleY.toStringAsFixed(2)}) '
        'R(${(rotation * 180 / math.pi).toStringAsFixed(1)}°)';
  }
}

enum TransformMode {
  move,
  scale,
  rotate,
}
