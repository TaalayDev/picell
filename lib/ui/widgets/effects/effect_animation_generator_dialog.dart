import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/extensions/primitive_extensions.dart';
import '../../../data.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/effects/effects.dart';
import '../../../pixel/effects/effect_animation_renderer.dart';
import '../animated_background.dart';
import 'pixlel_preview_painter.dart';

class EffectAnimationGeneratorDialog extends StatefulWidget {
  final Effect effect;
  final int layerWidth;
  final int layerHeight;
  final Uint32List layerPixels;
  final List<Effect> effects;
  final int effectIndex;
  final Future<void> Function(List<AnimationFrame>) onFramesGenerated;

  static Future<void> showEffectAnimationGenerator(
    BuildContext context, {
    required Effect effect,
    required int layerWidth,
    required int layerHeight,
    required Uint32List layerPixels,
    required List<Effect> effects,
    required int effectIndex,
    required Future<void> Function(List<AnimationFrame>) onFramesGenerated,
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
        effects: effects,
        effectIndex: effectIndex,
        onFramesGenerated: onFramesGenerated,
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
                  Text(Strings.of(context)
                      .animationDetailEffect(effect.getName(context))),
                  Text(Strings.of(context)
                      .animationDetailEstimatedFrames(estimatedFrames)),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
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

  const EffectAnimationGeneratorDialog({
    super.key,
    required this.effect,
    required this.layerWidth,
    required this.layerHeight,
    required this.layerPixels,
    required this.effects,
    required this.effectIndex,
    required this.onFramesGenerated,
  });

  @override
  State<EffectAnimationGeneratorDialog> createState() =>
      _EffectAnimationGeneratorDialogState();
}

class _EffectAnimationGeneratorDialogState
    extends State<EffectAnimationGeneratorDialog>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _parameters;
  late AnimationController _previewController;
  Timer? _previewTimer;

  // Animation settings
  int _frameCount = 30;
  int _fps = 12;
  double _duration = 2.5; // seconds
  bool _pingPong = false;

  // Preview state
  List<Uint32List> _generatedFrames = [];
  int _currentPreviewFrame = 0;
  bool _isGenerating = false;
  int _generationRevision = 0;
  bool _isApplying = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _parameters = Map<String, dynamic>.from(widget.effect.parameters);
    _previewController = AnimationController(vsync: this);
    _updateFrameCount();
    _generateFrames();
  }

  @override
  void dispose() {
    _previewController.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  void _updateFrameCount() {
    _frameCount = (_duration * _fps).round();
    if (_frameCount < 2) _frameCount = 2;
    if (_frameCount > 120) _frameCount = 120; // Reasonable limit
  }

  Future<void> _generateFrames() async {
    final revision = ++_generationRevision;
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _generatedFrames.clear();
    });

    try {
      await Future.delayed(
          const Duration(milliseconds: 50)); // Allow UI to update

      final frames = <Uint32List>[];
      final effects = List<Effect>.from(widget.effects);
      effects[widget.effectIndex] =
          EffectsManager.createEffect(widget.effect.type, _parameters);

      for (int i = 0; i < _frameCount; i++) {
        final t = i / (_frameCount - 1);
        frames.add(await EffectAnimationRenderer.renderFrame(
          pixels: widget.layerPixels,
          width: widget.layerWidth,
          height: widget.layerHeight,
          effects: effects,
          animatedEffectIndex: widget.effectIndex,
          progress: t,
        ));
        if (revision != _generationRevision || !mounted) break;
      }

      if (mounted && revision == _generationRevision) {
        setState(() => _generatedFrames = frames);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
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
        _currentPreviewFrame =
            (_currentPreviewFrame + 1) % _generatedFrames.length;
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
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                  child:
                      isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
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
    final onPressed =
        _generatedFrames.isEmpty || _isApplying ? null : _applyFrames;
    if (compact) {
      return ElevatedButton(
        onPressed: onPressed,
        child: _isApplying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(s.generateFrames,
                maxLines: 1, overflow: TextOverflow.ellipsis),
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
                _buildAnimationSettings(),
                const SizedBox(height: 20),
                _buildFrameGenerationSettings(),
                const SizedBox(height: 20),
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
        // Preview title and controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                s.preview,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _generatedFrames.isEmpty ? null : _togglePreview,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  tooltip: _isPlaying ? s.pause : s.play,
                ),
                IconButton(
                  onPressed: _generatedFrames.isEmpty ? null : _stopPreview,
                  icon: const Icon(Icons.stop),
                  tooltip: s.stop,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Preview canvas
        LayoutBuilder(
          builder: (context, constraints) {
            final size =
                constraints.maxWidth < 300 ? constraints.maxWidth : 300.0;
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
              Text(s.frameLabel),
              const SizedBox(width: 8),
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

  Widget _buildAnimationSettings() {
    final s = Strings.of(context);

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.effectParameters,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _editParameters(),
                    child: Text(s.editParameters),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              s.effectParametersBaseNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),

            const SizedBox(height: 12),

            // Show some key parameters
            ..._parameters.entries.take(3).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.capitalize(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _editParameters() {
    // Show a simplified parameter editor
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).editBaseParameters),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _parameters.entries.map((entry) {
              if (entry.value is double) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key.capitalize()),
                    Slider(
                      value: entry.value,
                      min: 0.0,
                      max: 2.0,
                      onChanged: (value) {
                        setState(() {
                          _parameters[entry.key] = value;
                        });
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Strings.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateFrames();
            },
            child: Text(Strings.of(context).applyAndRegenerate),
          ),
        ],
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

    final frames = <AnimationFrame>[];
    final frameDuration = (1000 / _fps).round();

    for (int i = 0; i < _generatedFrames.length; i++) {
      // Create a new layer with the effect-processed pixels
      final layer = Layer(
        layerId: i,
        id: 'animated_effect_$i',
        name: Strings.of(context).effectFrameName(i + 1),
        pixels: _generatedFrames[i],
        order: 0,
      );

      final frame = AnimationFrame(
        id: i,
        stateId: 0,
        name: Strings.of(context).effectAnimationName(i + 1),
        duration: frameDuration,
        layers: [layer],
        order: i,
      );

      frames.add(frame);
    }

    // If ping-pong, add reversed frames
    if (_pingPong && frames.length > 1) {
      final reversedFrames =
          frames.reversed.skip(1).take(frames.length - 1).toList();
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
      await widget.onFramesGenerated(frames);
    } catch (error) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(Strings.of(context).generatedAnimationFrames(frames.length)),
      ),
    );
  }
}
