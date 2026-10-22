import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data.dart';
import '../../../pixel/effects/effect_target.dart';
import '../../../pixel/pixel_utils.dart';
import '../../../pixel/providers/pixel_canvas_provider.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/effects/effects.dart';
import '../animated_background.dart';
import '../fields/ui_field_builder.dart';
import '../notifications/app_notification.dart';
import 'pixlel_preview_painter.dart';

typedef EffectFramesCallback = Future<void> Function(
  List<AnimationFrame> frames,
  EffectGenerationResult result,
);

class EffectAnimationGeneratorDialog extends StatefulWidget {
  final Effect effect;
  final int layerWidth;
  final int layerHeight;

  /// Layers of the frame being animated. Left empty for the single-layer form
  /// (see [layerPixels]).
  final List<Layer> frameLayers;
  final int activeLayerIndex;
  final List<int> initialLayerIndices;
  final Uint32List? layerPixels;
  final List<Effect> effects;
  final int effectIndex;
  final Future<void> Function(List<AnimationFrame>)? onFramesGenerated;
  final EffectFramesCallback? onGenerated;

  /// Animates [effect] across the layers selected on [notifier]'s canvas.
  static Future<void> showForCanvas(
    BuildContext context, {
    required PixelCanvasNotifier notifier,
    required Effect effect,
    required List<Effect> effects,
    required int effectIndex,
    required int layerWidth,
    required int layerHeight,
  }) {
    final snapshot = notifier.effectLayerContext;
    final frame = snapshot.frame;
    return showEffectAnimationGenerator(
      context,
      effect: effect,
      effects: effects,
      effectIndex: effectIndex,
      layerWidth: layerWidth,
      layerHeight: layerHeight,
      frameLayers: frame.layers,
      activeLayerIndex: snapshot.activeIndex,
      initialLayerIndices: snapshot.selectedIndices,
      onGenerated: (frames, result) => notifier.addGeneratedEffectFrames(
        frames,
        sourceFrameId: frame.id,
        sourceLayerIds: result.layerIds,
        activeLayerId: result.activeLayerId,
        flattened: result.flattened,
      ),
    );
  }

  static Future<void> showEffectAnimationGenerator(
    BuildContext context, {
    required Effect effect,
    required int layerWidth,
    required int layerHeight,
    Uint32List? layerPixels,
    List<Layer> frameLayers = const [],
    int activeLayerIndex = 0,
    List<int> initialLayerIndices = const [],
    required List<Effect> effects,
    required int effectIndex,
    Future<void> Function(List<AnimationFrame>)? onFramesGenerated,
    EffectFramesCallback? onGenerated,
  }) async {
    if (!effect.isAnimation) {
      // Show error dialog for non-animation effects
      return showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(Strings.of(context).staticEffect),
            ],
          ),
          content: Text(
            Strings.of(context).effectNotAnimatedMessage(
              effect.getName(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Strings.of(context).ok),
            ),
          ],
        ),
      );
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EffectAnimationGeneratorDialog(
        effect: effect,
        layerWidth: layerWidth,
        layerHeight: layerHeight,
        layerPixels: layerPixels,
        frameLayers: frameLayers,
        activeLayerIndex: activeLayerIndex,
        initialLayerIndices: initialLayerIndices,
        effects: effects,
        effectIndex: effectIndex,
        onFramesGenerated: onFramesGenerated,
        onGenerated: onGenerated,
      ),
    );
  }

  Future<bool> confirmAnimationGeneration(
    BuildContext context, {
    required Effect effect,
    required int estimatedFrames,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.movie_creation,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(Strings.of(context).generateAnimation),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.of(context).generateAnimationForEffect(
                effect.getName(context),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        Strings.of(context).animationDetails,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(Strings.of(context).animationDetailEffect(effect.getName(context))),
                  Text(Strings.of(context).animationDetailEstimatedFrames(estimatedFrames)),
                  Text(
                    Strings.of(context).animationDetailProcessingTime(
                      (estimatedFrames * 0.1).round(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              Strings.of(context).generateAnimationTimelineNote,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Strings.of(context).cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.play_arrow),
            label: Text(Strings.of(context).generateAnimation),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  EffectAnimationGeneratorDialog({
    super.key,
    required this.effect,
    required this.layerWidth,
    required this.layerHeight,
    this.layerPixels,
    this.frameLayers = const [],
    this.activeLayerIndex = 0,
    this.initialLayerIndices = const [],
    required this.effects,
    required this.effectIndex,
    this.onFramesGenerated,
    this.onGenerated,
  }) : assert(
          frameLayers.isNotEmpty != (layerPixels != null),
          'Pass either frameLayers or layerPixels',
        );

  @override
  State<EffectAnimationGeneratorDialog> createState() => _EffectAnimationGeneratorDialogState();
}

class _EffectAnimationGeneratorDialogState extends State<EffectAnimationGeneratorDialog> with TickerProviderStateMixin {
  late Map<String, dynamic> _parameters;
  late AnimationController _previewController;
  Timer? _previewTimer;
  Timer? _parameterDebounceTimer;

  // Animation settings
  int _frameCount = 30;
  int _fps = 12;
  double _duration = 2.5; // seconds
  bool _pingPong = false;

  // Layers the effect is applied to
  late final List<Layer> _frameLayers;
  late final int _activeLayerIndex;
  late Set<int> _layerIndices;
  EffectMultiLayerMode _layerMode = EffectMultiLayerMode.merged;
  EffectTarget? _lastTarget;

  // Preview state
  List<Uint32List> _generatedFrames = [];
  List<EffectTargetFrame> _targetFrames = [];
  int _currentPreviewFrame = 0;
  bool _isGenerating = false;
  int _generationRevision = 0;
  bool _isApplying = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _parameters = Map<String, dynamic>.from(widget.effect.parameters);
    if (widget.frameLayers.isNotEmpty) {
      _frameLayers = widget.frameLayers;
      _activeLayerIndex = widget.activeLayerIndex.clamp(0, _frameLayers.length - 1);
    } else {
      _frameLayers = [
        Layer(layerId: 0, id: 'source', name: '', pixels: widget.layerPixels!),
      ];
      _activeLayerIndex = 0;
    }
    _layerIndices = {
      ...widget.initialLayerIndices.where((i) => i >= 0 && i < _frameLayers.length),
      _activeLayerIndex,
    };
    _previewController = AnimationController(vsync: this);
    _updateFrameCount();
    _generateFrames();
  }

  @override
  void dispose() {
    _previewController.dispose();
    _previewTimer?.cancel();
    _parameterDebounceTimer?.cancel();
    super.dispose();
  }

  void _onParameterChanged(String key, dynamic value) {
    setState(() {
      _parameters[key] = value;
      _updateFrameCount();
    });
    _parameterDebounceTimer?.cancel();
    _parameterDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        _generateFrames();
      }
    });
  }

  /// Effect instance reflecting the current (edited) parameters.
  Effect get _currentEffect => EffectsManager.createEffect(widget.effect.type, _parameters);

  /// Frame count dictated by the effect itself (e.g. Breathing), if any.
  int? get _effectFrameCount => _currentEffect.preferredFrameCount;

  void _updateFrameCount() {
    final preferred = _effectFrameCount;
    _frameCount = preferred ?? (_duration * _fps).round();
    if (_frameCount < 2) _frameCount = 2;
    if (_frameCount > 120) _frameCount = 120; // Reasonable limit
  }

  EffectTarget _buildTarget() {
    final effects = List<Effect>.from(widget.effects);
    effects[widget.effectIndex] = _currentEffect;
    return EffectTarget.fromFrame(
      frameLayers: _frameLayers,
      indices: _layerIndices,
      primaryIndex: _activeLayerIndex,
      primaryEffects: effects,
      primaryAnimatedIndex: widget.effectIndex,
      mode: _layerMode,
    );
  }

  /// What the user would see for [frame]: the target layers stacked with
  /// their visibility and opacity (or the raw pixels for a single layer).
  Uint32List _previewOf(EffectTarget target, EffectTargetFrame frame) {
    if (target.layers.length == 1) return frame.pixels.single;
    return PixelUtils.mergeLayersPixels(
      width: widget.layerWidth,
      height: widget.layerHeight,
      layers: [
        for (final (i, item) in target.layers.indexed)
          item.layer.copyWith(
            pixels: frame.pixels[i],
            effects: const [],
            opacity: frame.flattened && frame.pixels[i].any((p) => p != 0) ? 1.0 : item.layer.opacity,
          ),
      ],
    );
  }

  void _onLayersChanged(void Function() change) {
    setState(change);
    _generateFrames();
  }

  Future<void> _generateFrames() async {
    final revision = ++_generationRevision;
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _generatedFrames = [];
      _targetFrames = [];
    });

    try {
      await Future.delayed(const Duration(milliseconds: 50)); // Allow UI to update

      final previews = <Uint32List>[];
      final targetFrames = <EffectTargetFrame>[];
      final target = _buildTarget();
      final seamless = _currentEffect.isSeamlessLoop;
      final frameCount = _frameCount;

      for (int i = 0; i < frameCount; i++) {
        // Seamless loops sample [0, 1) so frame N doesn't repeat frame 0.
        final t = seamless ? i / frameCount : i / (frameCount - 1);
        final frame = await EffectTargetRenderer.renderFrame(
          target: target,
          width: widget.layerWidth,
          height: widget.layerHeight,
          progress: t,
        );
        targetFrames.add(frame);
        previews.add(_previewOf(target, frame));
        if (revision != _generationRevision || !mounted) break;
      }

      if (mounted && revision == _generationRevision) {
        setState(() {
          _generatedFrames = previews;
          _targetFrames = targetFrames;
          _lastTarget = target;
          if (_currentPreviewFrame >= previews.length) _currentPreviewFrame = 0;
        });
      }
    } catch (error) {
      if (mounted) {
        AppNotification.error(
          context,
          error.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
        if (revision != _generationRevision) _generateFrames();
      }
    }
  }

  void _startPreview() {
    if (_generatedFrames.isEmpty) return;

    setState(() {
      _isPlaying = true;
    });

    final frameDuration = Duration(milliseconds: (1000 / _fps).round());

    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(frameDuration, (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentPreviewFrame = (_currentPreviewFrame + 1) % _generatedFrames.length;
      });
    });
  }

  void _stopPreview() {
    setState(() {
      _isPlaying = false;
    });
    _previewTimer?.cancel();
  }

  void _togglePreview() {
    if (_isPlaying) {
      _stopPreview();
    } else {
      _startPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final effectName = widget.effect.getName(context);

    return Dialog(
      insetPadding: isMobile ? const EdgeInsets.all(8) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? double.infinity : 900,
        height: isMobile ? double.infinity : 700,
        child: AnimatedBackground(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            s.generateAnimationFrames,
                            style: (isMobile
                                    ? Theme.of(context).textTheme.titleLarge
                                    : Theme.of(context).textTheme.headlineSmall)
                                ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            s.effectNameLabel(effectName),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () => _showHelpDialog(),
                    ),
                  ],
                ),

                const Divider(),

                // Content
                Expanded(
                  child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                ),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          s.framesGeneratedCount(_generatedFrames.length),
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (isMobile) ...[
                          _buildGenerateButton(s, compact: true),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(s.cancel),
                          ),
                        ] else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(s.cancel),
                              ),
                              const SizedBox(width: 8),
                              _buildGenerateButton(s),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(Strings s, {bool compact = false}) {
    final onPressed = _generatedFrames.isEmpty || _isApplying ? null : _applyFrames;
    if (compact) {
      return ElevatedButton(
        onPressed: onPressed,
        child: _isApplying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(s.generateFrames, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: _isApplying
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(
        s.generateFrames,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewSection(),
          const SizedBox(height: 20),
          _buildLayersSection(),
          _buildAnimationSettings(),
          const SizedBox(height: 20),
          _buildFrameGenerationSettings(),
          const SizedBox(height: 20),
          _buildEffectParameters(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Preview and playback controls
        Expanded(
          flex: 2,
          child: _buildPreviewSection(),
        ),

        const SizedBox(width: 20),

        // Right side - Settings
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLayersSection(),
                _buildAnimationSettings(),
                const SizedBox(height: 10),
                _buildEffectParameters(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final s = Strings.of(context);

    return Column(
      children: [
        // Preview canvas
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth < 300 ? constraints.maxWidth : 300.0;
            return Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildPreview(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Frame scrubber
        if (_generatedFrames.isNotEmpty) ...[
          Row(
            children: [
              IconButton(
                onPressed: _generatedFrames.isEmpty ? null : _togglePreview,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                tooltip: _isPlaying ? s.pause : s.play,
              ),
              Expanded(
                child: Slider(
                  value: _currentPreviewFrame.toDouble(),
                  min: 0,
                  max: (_generatedFrames.length - 1).toDouble(),
                  divisions: _generatedFrames.length - 1,
                  label: '${_currentPreviewFrame + 1}',
                  onChanged: (value) {
                    setState(() {
                      _currentPreviewFrame = value.toInt();
                    });
                  },
                ),
              ),
              Text('${_currentPreviewFrame + 1}/${_generatedFrames.length}'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(Strings.of(context).generatingFrames),
          ],
        ),
      );
    }

    if (_generatedFrames.isEmpty) {
      return Center(
        child: Text(Strings.of(context).noFramesGenerated),
      );
    }

    final currentFrame = _generatedFrames[_currentPreviewFrame];

    return CustomPaint(
      painter: PixelPreviewPainter(
        pixels: currentFrame,
        width: widget.layerWidth,
        height: widget.layerHeight,
      ),
    );
  }

  Widget _buildLayersSection() {
    if (_frameLayers.length < 2) return const SizedBox.shrink();
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final selected = _layerIndices.toList()..sort();
    final available = [
      for (var i = 0; i < _frameLayers.length; i++)
        if (!_layerIndices.contains(i)) i,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.effectApplyingToLayers, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final index in selected)
                    InputChip(
                      avatar: SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: PixelPreviewPainter(
                            pixels: _frameLayers[index].pixels,
                            width: widget.layerWidth,
                            height: widget.layerHeight,
                          ),
                        ),
                      ),
                      label: Text(
                        _frameLayers[index].name.isEmpty ? '${index + 1}' : _frameLayers[index].name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // The layer being edited owns the effect stack.
                      tooltip: index == _activeLayerIndex ? s.effectPrimaryLayerLocked : null,
                      onDeleted: index == _activeLayerIndex || selected.length < 2
                          ? null
                          : () => _onLayersChanged(() => _layerIndices.remove(index)),
                    ),
                  if (available.isNotEmpty)
                    PopupMenuButton<int>(
                      tooltip: s.effectAddLayer,
                      onSelected: (index) => _onLayersChanged(() => _layerIndices.add(index)),
                      itemBuilder: (context) => [
                        // Top layer first, like the layers panel.
                        for (final index in available.reversed)
                          PopupMenuItem(
                            value: index,
                            child: Text(
                              _frameLayers[index].name.isEmpty ? '${index + 1}' : _frameLayers[index].name,
                            ),
                          ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(s.effectAddLayer),
                      ),
                    ),
                ],
              ),
              if (selected.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<EffectMultiLayerMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: EffectMultiLayerMode.merged,
                        icon: const Icon(Icons.layers_outlined),
                        label: Text(s.effectLayersCombined),
                      ),
                      ButtonSegment(
                        value: EffectMultiLayerMode.perLayer,
                        icon: const Icon(Icons.view_agenda_outlined),
                        label: Text(s.effectLayersSeparate),
                      ),
                    ],
                    selected: {_layerMode},
                    onSelectionChanged: (value) => _onLayersChanged(() => _layerMode = value.single),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _layerMode == EffectMultiLayerMode.perLayer
                      ? s.effectLayersSeparateHint
                      : EffectCatalog.isCanvasSpaceTransform(widget.effect.type)
                          ? s.effectLayersCombinedKeepHint
                          : s.effectLayersCombinedHint,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationSettings() {
    final s = Strings.of(context);
    final effectDrivesFrames = _effectFrameCount != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.animationSettings,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Duration
            Row(
              children: [
                if (effectDrivesFrames)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.durationSeconds),
                        const SizedBox(height: 12),
                        Text(
                          '${(_frameCount / _fps).toStringAsFixed(2)}s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Set by the effect\'s Frame Count',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.durationSeconds),
                      Slider(
                        value: _duration,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label: _duration.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _duration = value;
                            _updateFrameCount();
                          });
                          _generateFrames();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fps),
                      Slider(
                        value: _fps.toDouble(),
                        min: 6,
                        max: 30,
                        divisions: 24,
                        label: _fps.toString(),
                        onChanged: (value) {
                          setState(() {
                            _fps = value.toInt();
                            _updateFrameCount();
                          });
                          _generateFrames();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Frame count display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.totalFrames,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    _frameCount.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional options
            SwitchListTile(
              title: Text(s.pingPongAnimation),
              subtitle: Text(s.playForwardThenBackward),
              value: _pingPong,
              onChanged: (value) {
                setState(() {
                  _pingPong = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameGenerationSettings() {
    final s = Strings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.frameGeneration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(s.addFramesToExistingTimeline),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectParameters() {
    final s = Strings.of(context);
    final fields = widget.effect.getFields();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.parameters,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              s.effectParametersBaseNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            if (fields.isNotEmpty)
              ...UIFieldBuilder.buildAll(
                context: context,
                fields: fields,
                values: _parameters,
                onChanged: _onParameterChanged,
              )
            else if (_parameters.isNotEmpty)
              ..._parameters.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  )),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).animationFrameGenerator),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Strings.of(context).animationGeneratorHelpIntro,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(Strings.of(context).animationHelpDuration),
              Text(Strings.of(context).animationHelpFps),
              Text(Strings.of(context).animationHelpPingPong),
              Text(Strings.of(context).animationHelpInterpolation),
              const SizedBox(height: 16),
              Text(
                Strings.of(context).tips,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(Strings.of(context).animationTipLowerFps),
              Text(Strings.of(context).animationTipUsePreview),
              Text(Strings.of(context).animationTipLongerDurations),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Strings.of(context).gotIt),
          ),
        ],
      ),
    );
  }

  Future<void> _applyFrames() async {
    if (_generatedFrames.isEmpty || _isApplying) return;
    setState(() => _isApplying = true);

    final target = _lastTarget;
    if (target == null || _targetFrames.length != _generatedFrames.length) {
      setState(() => _isApplying = false);
      return;
    }
    final frames = <AnimationFrame>[];
    final frameDuration = (1000 / _fps).round();

    for (int i = 0; i < _targetFrames.length; i++) {
      // One layer per target layer, holding the effect-processed pixels.
      final layers = [
        for (final (k, pixels) in _targetFrames[i].pixels.indexed)
          Layer(
            layerId: k,
            id: 'animated_effect_${i}_$k',
            name: Strings.of(context).effectFrameName(i + 1),
            pixels: pixels,
            order: 0,
          ),
      ];

      frames.add(AnimationFrame(
        id: i,
        stateId: 0,
        name: Strings.of(context).effectAnimationName(i + 1),
        duration: frameDuration,
        layers: layers,
        order: i,
      ));
    }

    // If ping-pong, add reversed frames
    if (_pingPong && frames.length > 1) {
      final reversedFrames = frames.reversed.skip(1).take(frames.length - 1).toList();
      for (int i = 0; i < reversedFrames.length; i++) {
        final frame = reversedFrames[i];
        final newFrame = frame.copyWith(
          id: frames.length + i,
          name: Strings.of(context).effectAnimationReturnName(
            frames.length + i + 1,
          ),
          order: frames.length + i,
        );
        frames.add(newFrame);
      }
    }

    try {
      final onGenerated = widget.onGenerated;
      if (onGenerated != null) {
        await onGenerated(
          frames,
          EffectGenerationResult(
            layerIds: target.layerIds,
            activeLayerId: _frameLayers[_activeLayerIndex].layerId,
            flattened: _targetFrames.first.flattened,
          ),
        );
      } else {
        await widget.onFramesGenerated!(frames);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isApplying = false);
        AppNotification.error(
          context,
          error.toString(),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();

    // Show success message
    AppNotification.success(
      context,
      Strings.of(context).generatedAnimationFrames(frames.length),
    );
  }
}
