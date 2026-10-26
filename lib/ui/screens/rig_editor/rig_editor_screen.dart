import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/image_helper.dart';
import '../../../data/models/layer.dart';
import '../../../data/models/rig/rig.dart';
import '../../../pixel/pixel_utils.dart';
import '../../../pixel/rig/presets/motion_presets.dart';
import '../../../pixel/rig/rig_bake.dart';
import '../../../pixel/rig/rig_baker.dart';
import '../../../pixel/rig/rig_gif.dart';
import '../../../pixel/rig/rig_editor_controller.dart';
import 'rig_canvas.dart';
import 'rig_gif_preview.dart';
import 'rig_presets_dialogs.dart';
import 'rig_panels.dart';
import 'rig_timeline.dart';

/// Full-screen editor for a [Rig]. Opened over the pixel editor and closed
/// with Done (returns the edited rig) or Cancel (returns null).
///
/// Setup mode draws the skeleton and decides which layer each bone moves.
/// Animate mode poses the bones over time, with a live preview of the pixels
/// the rig will produce.
class RigEditorScreen extends StatefulWidget {
  const RigEditorScreen({
    super.key,
    required this.rig,
    required this.restLayers,
    required this.width,
    required this.height,
    this.title = '',
    this.fps = 12,
  });

  /// The rig to edit; pass an empty `Rig` to start a new one.
  final Rig rig;

  /// Rest-pose layers (bottom first), each carrying a `Layer.stableKey`.
  final List<Layer> restLayers;
  final int width;
  final int height;
  final String title;

  /// Frame rate of a new clip (the animation's own frame rate).
  final int fps;

  /// Below this width the side panel moves into a bottom sheet.
  static const double wideBreakpoint = 760;

  static Future<Rig?> show(
    BuildContext context, {
    required Rig rig,
    required List<Layer> restLayers,
    required int width,
    required int height,
    String title = '',
    int fps = 12,
  }) {
    return Navigator.of(context).push<Rig>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RigEditorScreen(
          rig: rig,
          restLayers: restLayers,
          width: width,
          height: height,
          title: title,
          fps: fps,
        ),
      ),
    );
  }

  @override
  State<RigEditorScreen> createState() => _RigEditorScreenState();
}

class _RigEditorScreenState extends State<RigEditorScreen> {
  late final RigEditorController _controller;
  final _canvasKey = GlobalKey<RigCanvasState>();

  /// What the canvas shows: the rest pose in setup, the baked frame in animate.
  ui.Image? _image;

  // The rest composite is baked once; animate frames come from [_baker].
  Uint32List? _restPixels;
  RigBaker? _baker;
  Rig? _bakerRig;

  // What [_image] currently depicts, so unchanged state isn't re-baked.
  Rig? _shownRig;
  int? _shownTime;
  RigMode? _shownMode;
  bool _refreshing = false;
  bool _refreshAgain = false;

  bool _makingGif = false;

  Timer? _playTimer;
  int _playingFps = 0;
  String? _playingClipId;
  bool get _playing => _playTimer != null;

  @override
  void initState() {
    super.initState();
    _controller = RigEditorController(
      rig: widget.rig,
      restLayers: widget.restLayers,
      width: widget.width,
      height: widget.height,
      defaultFps: widget.fps,
      clipName: widget.title.isEmpty ? 'Animation' : widget.title,
    )..addListener(_onControllerChanged);
    _refresh();
  }

  void _onControllerChanged() {
    // Playback is for animate mode, at the clip's current speed.
    if (_playing &&
        (_controller.mode != RigMode.animate ||
            _controller.activeClip.fps != _playingFps ||
            _controller.activeClip.id != _playingClipId)) {
      _stopPlayback();
    }
    _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        await _refreshImage();
      } while (_refreshAgain && mounted);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refreshImage() async {
    final c = _controller;
    final animate = c.mode == RigMode.animate;
    final time = animate ? c.time : -1;
    if (identical(_shownRig, c.rig) && _shownTime == time && _shownMode == c.mode) return;

    final Uint32List pixels;
    if (animate) {
      if (!identical(_bakerRig, c.rig)) {
        _baker = RigBaker(rig: c.rig, width: widget.width, height: widget.height, layers: widget.restLayers);
        _bakerRig = c.rig;
      }
      pixels = _baker!.bakeFrame(c.activeClip, time.toDouble());
    } else {
      _restPixels ??= PixelUtils.mergeLayersPixels(
        width: widget.width,
        height: widget.height,
        layers: widget.restLayers,
      );
      // ImageHelper swaps colour channels in place, so hand it a copy.
      pixels = Uint32List.fromList(_restPixels!);
    }

    final rig = c.rig, mode = c.mode;
    final image = await ImageHelper.createImageFromPixels(pixels, widget.width, widget.height);
    if (!mounted) {
      image.dispose();
      return;
    }
    final old = _image;
    setState(() {
      _image = image;
      _shownRig = rig;
      _shownTime = time;
      _shownMode = mode;
    });
    // The painter may still be using the old image this frame.
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// Bakes the animation as it is now and shows it as a looping GIF.
  Future<void> _previewGif(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!RigBakeService.canBake(_controller.rig)) {
      messenger?.showSnackBar(
          const SnackBar(content: Text('Pose a bone or move an IK target first: nothing is keyed yet.')));
      return;
    }
    _stopPlayback();
    setState(() => _makingGif = true);
    try {
      final bytes = await RigGif.render(
        rig: _controller.rig,
        restLayers: widget.restLayers,
        width: widget.width,
        height: widget.height,
      );
      if (!mounted || !context.mounted) return;
      await RigGifPreviewDialog.show(context, bytes: bytes, fileName: _gifFileName);
    } catch (_) {
      messenger?.showSnackBar(const SnackBar(content: Text('Couldn\'t make the preview.')));
    } finally {
      if (mounted) setState(() => _makingGif = false);
    }
  }

  /// "Walk" for a title of "Walk · Frame 2"; anything unsafe in a file name is dropped.
  String get _gifFileName {
    final name = _controller.activeClip.name.split(' · ').first.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    return '${name.isEmpty ? 'rig-animation' : name}.gif';
  }

  void _togglePlayback() {
    if (_playing) {
      _stopPlayback();
      return;
    }
    final clip = _controller.activeClip;
    if (!clip.loop && _controller.time >= clip.length - 1) _controller.setTime(0);
    _playingFps = clip.fps;
    _playingClipId = clip.id;
    setState(() {
      _playTimer = Timer.periodic(Duration(milliseconds: (1000 / clip.fps).round()), (_) => _tick());
    });
    _controller.setGhostPlayback(true);
  }

  void _stopPlayback() {
    _playTimer?.cancel();
    if (mounted) {
      setState(() => _playTimer = null);
    } else {
      _playTimer = null;
    }
    if (mounted) _controller.setGhostPlayback(false);
  }

  void _tick() {
    final clip = _controller.activeClip;
    final next = _controller.time + 1;
    if (next < clip.length) {
      _controller.setTime(next);
    } else if (clip.loop) {
      _controller.setTime(0);
    } else {
      _stopPlayback();
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard rig changes?'),
        content: const Text('The changes you made to this rig won\'t be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted && context.mounted) Navigator.of(context).pop();
  }

  void _done() => Navigator.of(context).pop(_controller.rig);

  void _showPanelSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: RigSidePanel(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final readableTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
      iconTheme: theme.iconTheme.copyWith(color: colors.onSurfaceVariant),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        helperStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
    return Theme(
      data: readableTheme,
      child: DefaultTextStyle(
        style: readableTheme.textTheme.bodyMedium!,
        child: Builder(builder: _buildEditor),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= RigEditorScreen.wideBreakpoint;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.hasChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard(context);
          },
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _controller.undo,
              const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _controller.undo,
              const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): _controller.redo,
              const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _controller.redo,
              const SingleActivator(LogicalKeyboardKey.keyV): () => _controller.tool = RigTool.select,
              const SingleActivator(LogicalKeyboardKey.keyB): () => _controller.tool = RigTool.createBone,
              const SingleActivator(LogicalKeyboardKey.keyR): () => _controller.tool = RigTool.rotate,
              const SingleActivator(LogicalKeyboardKey.keyM): () => _controller.tool = RigTool.move,
              const SingleActivator(LogicalKeyboardKey.space): _playPauseIfAnimating,
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _stepFrame(-1),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () => _stepFrame(1),
              const SingleActivator(LogicalKeyboardKey.escape): _controller.cancelPlacement,
              const SingleActivator(LogicalKeyboardKey.enter): _placeIfPlacing,
              const SingleActivator(LogicalKeyboardKey.delete): _deleteSelected,
              const SingleActivator(LogicalKeyboardKey.backspace): _deleteSelected,
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                body: SafeArea(
                  child: Column(
                    children: [
                      _TopBar(
                        title: widget.title,
                        controller: _controller,
                        onCancel: () => Navigator.of(context).maybePop(),
                        onDone: _done,
                        onPanels: wide ? null : () => _showPanelSheet(context),
                      ),
                      if (_makingGif) const LinearProgressIndicator(minHeight: 2),
                      // Its own strip, not a float over the canvas: the box's handles
                      // run to the canvas edges and must stay reachable.
                      if (_controller.placement != null) _PlacementBar(controller: _controller, onPlace: _placePreset),
                      Expanded(
                        child: Row(
                          children: [
                            if (wide) _ToolRail(controller: _controller, onFit: () => _canvasKey.currentState?.fit()),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: RigCanvas(key: _canvasKey, controller: _controller, image: _image),
                                  ),
                                  if (_controller.mode == RigMode.setup && _controller.activeLayerKey != null)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      right: 8,
                                      child: Center(child: _ArmedLayerBanner(controller: _controller)),
                                    ),
                                ],
                              ),
                            ),
                            if (wide)
                              Container(
                                width: 248,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  border: Border(left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
                                ),
                                child: RigSidePanel(controller: _controller),
                              ),
                          ],
                        ),
                      ),
                      if (_controller.mode == RigMode.animate)
                        RigTimeline(
                          controller: _controller,
                          isPlaying: _playing,
                          onPlayPause: _togglePlayback,
                          onBeforeEdit: _stopPlayback,
                          onPreviewGif: () => _previewGif(context),
                          onPresets: () => _chooseAnimation(context),
                          onClearAnimations: () {
                            _stopPlayback();
                            _controller.clearAnimations();
                          },
                        ),
                      if (!wide)
                        _ToolRail(
                          controller: _controller,
                          horizontal: true,
                          onFit: () => _canvasKey.currentState?.fit(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _playPauseIfAnimating() {
    if (_controller.mode == RigMode.animate) _togglePlayback();
  }

  void _stepFrame(int delta) {
    if (_controller.mode != RigMode.animate) return;
    _stopPlayback();
    _controller.setTime(_controller.time + delta);
  }

  void _placeIfPlacing() {
    if (_controller.placement != null) _placePreset();
  }

  /// Adds the skeleton being placed and says what happened.
  void _placePreset() {
    final name = _controller.placement?.preset.name;
    final placed = _controller.commitPlacement();
    if (placed == null) return;
    final bound = placed.boundLayers;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(
        '$name added: ${placed.boneIds.length} bone${placed.boneIds.length == 1 ? '' : 's'}'
        '${bound == 0 ? '' : ', $bound layer${bound == 1 ? '' : 's'} bound by name'}.',
      ),
    ));
  }

  /// Picks a ready-made animation and puts it on the clip.
  Future<void> _chooseAnimation(BuildContext context) async {
    _stopPlayback();
    final choice = await pickMotionPreset(context, _controller);
    if (choice == null || !mounted || !context.mounted) return;

    final result = _controller.applyMotion(choice.preset, intensity: choice.intensity, mirror: choice.mirror);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (result.isEmpty) {
      messenger?.showSnackBar(SnackBar(
        content: Text(
          choice.preset.target == MotionTarget.roles
              ? 'No bones for "${choice.preset.name}". Name them like ${choice.preset.roles.take(3).join(', ')}, or add a ready-made skeleton in Setup.'
              : 'Select a bone first.',
        ),
      ));
      return;
    }
    final missing = result.missing.length;
    messenger?.showSnackBar(SnackBar(
      content: Text(
        '"${choice.preset.name}" applied to ${result.matched.length} bone${result.matched.length == 1 ? '' : 's'}'
        '${missing == 0 ? '' : ' ($missing not found)'}. Undo brings the old animation back.',
      ),
    ));
  }

  void _deleteSelected() {
    final id = _controller.selectedBoneId;
    if (id != null) _controller.deleteBone(id);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.controller,
    required this.onCancel,
    required this.onDone,
    required this.onPanels,
  });

  final String title;
  final RigEditorController controller;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final VoidCallback? onPanels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Phones have no room for the title or a labelled Done button.
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
              constraints: compact ? const BoxConstraints.tightFor(width: 32, height: 32) : null,
              padding: compact ? const EdgeInsets.all(4) : null,
              style: compact ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
              visualDensity: compact ? VisualDensity.compact : null,
              tooltip: 'Cancel',
              icon: const Icon(Icons.close, size: 18),
              onPressed: onCancel),
          if (!compact)
            Flexible(
              child: Text(
                title.isEmpty ? 'Rig' : title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          const Spacer(),
          _RigModeTabs(controller: controller, compact: compact),
          const Spacer(),
          if (onPanels != null)
            IconButton(
                constraints: compact ? const BoxConstraints.tightFor(width: 32, height: 32) : null,
                padding: compact ? const EdgeInsets.all(4) : null,
                style: compact ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
                visualDensity: compact ? VisualDensity.compact : null,
                tooltip: 'Bones and layers',
                icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                onPressed: onPanels),
          IconButton(
            constraints: compact ? const BoxConstraints.tightFor(width: 32, height: 32) : null,
            padding: compact ? const EdgeInsets.all(4) : null,
            style: compact ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
            visualDensity: compact ? VisualDensity.compact : null,
            tooltip: 'Undo',
            icon: const Icon(Icons.undo, size: 18),
            onPressed: controller.canUndo ? controller.undo : null,
          ),
          IconButton(
            constraints: compact ? const BoxConstraints.tightFor(width: 32, height: 32) : null,
            padding: compact ? const EdgeInsets.all(4) : null,
            style: compact ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
            visualDensity: compact ? VisualDensity.compact : null,
            tooltip: 'Redo',
            icon: const Icon(Icons.redo, size: 18),
            onPressed: controller.canRedo ? controller.redo : null,
          ),
          const SizedBox(width: 6),
          if (compact)
            IconButton.filled(
                constraints: compact ? const BoxConstraints.tightFor(width: 32, height: 32) : null,
                padding: compact ? const EdgeInsets.all(4) : null,
                style: compact ? IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap) : null,
                visualDensity: VisualDensity.compact,
                tooltip: 'Done',
                icon: const Icon(Icons.check, size: 18),
                onPressed: onDone)
          else
            FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Done'),
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Compact tabs share the editor's surface, outline and accent palette.
class _RigModeTabs extends StatelessWidget {
  const _RigModeTabs({required this.controller, required this.compact});
  final RigEditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const ValueKey('rig-mode-tabs'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in RigMode.values)
            Semantics(
              selected: controller.mode == mode,
              button: true,
              child: Material(
                color: controller.mode == mode ? colors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                child: InkWell(
                  key: ValueKey('rig-mode-${mode.name}'),
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => controller.mode = mode,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!compact) ...[
                        Icon(mode == RigMode.setup ? Icons.account_tree_outlined : Icons.animation,
                            size: 15, color: controller.mode == mode ? colors.onPrimaryContainer : colors.onSurface),
                        const SizedBox(width: 6),
                      ],
                      Text(mode == RigMode.setup ? 'Setup' : 'Animate',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: controller.mode == mode ? colors.onPrimaryContainer : colors.onSurface,
                            fontWeight: controller.mode == mode ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({required this.controller, required this.onFit, this.horizontal = false});

  final RigEditorController controller;
  final VoidCallback onFit;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tool(RigTool t, IconData icon, String label) {
      final on = controller.tool == t;
      return IconButton(
        tooltip: label,
        isSelected: on,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: on ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
          backgroundColor: on ? theme.colorScheme.primaryContainer : null,
        ),
        onPressed: () => controller.tool = t,
      );
    }

    final animating = controller.mode == RigMode.animate;
    final selectedId = controller.selectedBoneId;
    final children = [
      tool(RigTool.select, Icons.near_me_outlined, animating ? 'Select a bone (V)' : 'Select and move bones (V)'),
      if (!animating) tool(RigTool.createBone, Icons.show_chart, 'Draw a bone (B)'),
      if (!animating)
        IconButton(
          key: const ValueKey('add-skeleton-preset'),
          tooltip: 'Add a ready-made skeleton',
          icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
          onPressed: () => addSkeletonPreset(context, controller),
        ),
      if (animating) ...[
        tool(RigTool.rotate, Icons.rotate_right, 'Rotate a bone (R)'),
        tool(RigTool.move, Icons.open_with, 'Move a bone (M)'),
        IconButton(
          tooltip: 'Flip the selected bone',
          icon: const Icon(Icons.flip, size: 18),
          onPressed: selectedId == null
              ? null
              : () => controller.setPose(selectedId, flipX: !controller.poseOf(selectedId).flipX),
        ),
      ],
      IconButton(
          key: const ValueKey('rig-multi-select'),
          tooltip: 'Select multiple bones',
          isSelected: controller.multiSelectEnabled,
          icon: const Icon(Icons.select_all, size: 18),
          onPressed: controller.toggleMultiSelect),
      if (!animating)
        IconButton(
            key: const ValueKey('rig-snapping'),
            tooltip: 'Joint snapping (Alt bypasses)',
            isSelected: controller.snappingEnabled,
            icon: const Icon(Icons.align_horizontal_center, size: 18),
            onPressed: () => controller.setSnapping(!controller.snappingEnabled)),
      IconButton(
          tooltip: 'Fit to screen', icon: const Icon(Icons.center_focus_strong_outlined, size: 18), onPressed: onFit),
    ];

    return Container(
      width: horizontal ? null : 44,
      height: horizontal ? 44 : null,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: horizontal
            ? Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)))
            : Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: horizontal
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: children))
          : Column(children: children),
    );
  }
}

/// Reminds that the next bone drawn will move a layer, and lets go of it.
class _ArmedLayerBanner extends StatelessWidget {
  const _ArmedLayerBanner({required this.controller});

  final RigEditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = controller.activeLayerKey;
    final layer = controller.restLayers.where((l) => l.stableKey == key).firstOrNull;
    if (layer == null) return const SizedBox.shrink();

    return Material(
      key: const ValueKey('armed-layer-banner'),
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Next bone moves "${layer.name}"',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            IconButton(
              tooltip: 'Don\'t bind a layer',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16, color: theme.colorScheme.onPrimaryContainer),
              onPressed: () => controller.selectLayer(null),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirms or drops a skeleton being placed, with the choices that change
/// how it lands.
class _PlacementBar extends StatelessWidget {
  const _PlacementBar({required this.controller, required this.onPlace});

  final RigEditorController controller;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final placement = controller.placement;
    if (placement == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final preset = placement.preset;
    final parent = controller.selectedBone;

    return Material(
      key: const ValueKey('placement-bar'),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Place "${preset.name}": drag the box to move it, its edges to stretch it.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  key: const ValueKey('placement-flip'),
                  label: const Text('Mirror'),
                  selected: placement.flip,
                  onSelected: controller.setPlacementFlip,
                ),
                if (preset.ik.isNotEmpty)
                  FilterChip(
                    key: const ValueKey('placement-ik'),
                    label: const Text('With IK'),
                    selected: placement.withIk,
                    onSelected: controller.setPlacementIk,
                  ),
                if (parent != null)
                  FilterChip(
                    key: const ValueKey('placement-attach'),
                    label: Text('Attach to ${parent.name}'),
                    selected: placement.attach,
                    onSelected: controller.setPlacementAttach,
                  ),
                TextButton(
                  key: const ValueKey('placement-cancel'),
                  onPressed: controller.cancelPlacement,
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('placement-place'),
                  onPressed: onPlace,
                  child: const Text('Add skeleton'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
