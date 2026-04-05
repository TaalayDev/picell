import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/extensions/primitive_extensions.dart';
import '../../../pixel/effects/effects.dart';
import '../../../data.dart';
import '../animated_background.dart';
import 'pixlel_preview_painter.dart';

class EffectAnimationGeneratorDialog extends StatefulWidget {
  final Effect effect;
  final int layerWidth;
  final int layerHeight;
  final Uint32List layerPixels;
  final Function(List<AnimationFrame>) onFramesGenerated;

  static Future<void> showEffectAnimationGenerator(
    BuildContext context, {
    required Effect effect,
    required int layerWidth,
    required int layerHeight,
    required Uint32List layerPixels,
    required Function(List<AnimationFrame>) onFramesGenerated,
  }) async {
    if (!effect.isAnimation) {
      // Show error dialog for non-animation effects
      return showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Static Effect'),
            ],
          ),
          content: Text(
            'The ${effect.getName(context)} effect is not an animated effect. '
            'Animation frame generation is only available for effects that support animation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
            const Text('Generate Animation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate animation frames for ${effect.getName(context)} effect?',
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
                        'Animation Details',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('• Effect: ${effect.getName(context)}'),
                  Text('• Estimated frames: ~$estimatedFrames'),
                  Text('• Processing time: ~${(estimatedFrames * 0.1).round()} seconds'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will create multiple animation frames that you can add to your timeline.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Generate Animation'),
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
    required this.onFramesGenerated,
  });

  @override
  State<EffectAnimationGeneratorDialog> createState() => _EffectAnimationGeneratorDialogState();
}

class _EffectAnimationGeneratorDialogState extends State<EffectAnimationGeneratorDialog> with TickerProviderStateMixin {
  late Map<String, dynamic> _parameters;
  late AnimationController _previewController;
  Timer? _previewTimer;

  // Animation settings
  int _frameCount = 30;
  int _fps = 12;
  double _duration = 2.5; // seconds
  int _loops = 1;
  bool _pingPong = false;
  bool _generateNewFrames = true;
  int _insertPosition = 0;

  // Preview state
  List<Uint32List> _generatedFrames = [];
  int _currentPreviewFrame = 0;
  bool _isGenerating = false;
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
    if (_frameCount < 1) _frameCount = 1;
    if (_frameCount > 120) _frameCount = 120; // Reasonable limit
  }

  Future<void> _generateFrames() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _generatedFrames.clear();
    });

    await Future.delayed(const Duration(milliseconds: 50)); // Allow UI to update

    final frames = <Uint32List>[];

    for (int i = 0; i < _frameCount; i++) {
      // Calculate time parameter (0.0 to 1.0 over the animation duration)
      final t = i / (_frameCount - 1);

      // Create effect with time parameter
      final timeParameters = Map<String, dynamic>.from(_parameters);
      timeParameters['time'] = t;
      timeParameters['frame'] = i;
      timeParameters['totalFrames'] = _frameCount;

      // Apply specific time-based modifications for different effects
      _applyTimeBasedParameters(timeParameters, t, i);

      final effect = EffectsManager.createEffect(widget.effect.type, timeParameters);
      final framePixels = effect.apply(
        widget.layerPixels,
        widget.layerWidth,
        widget.layerHeight,
      );

      frames.add(framePixels);
    }

    if (mounted) {
      setState(() {
        _generatedFrames = frames;
        _isGenerating = false;
      });
    }
  }

  void _applyTimeBasedParameters(Map<String, dynamic> params, double t, int frame) {
    switch (widget.effect.type) {
      case EffectType.pulse:
        params['phase'] = t * 2 * pi;
        break;
      case EffectType.wave:
        params['wavePhase'] = t * 4 * pi;
        break;
      case EffectType.rotate:
        params['angle'] = t * 360;
        break;
      case EffectType.float:
      case EffectType.simpleFloat:
        params['offset'] = sin(t * 2 * pi) * 10;
        break;
      case EffectType.physicsFloat:
        params['bouncePhase'] = t;
        break;
      case EffectType.shake:
      case EffectType.quickShake:
      case EffectType.cameraShake:
        params['shakeIntensity'] = sin(t * 8 * pi) * (params['intensity'] ?? 5);
        break;
      case EffectType.dissolve:
      case EffectType.fadeDissolve:
        params['dissolveAmount'] = t;
        break;
      case EffectType.melt:
        params['meltProgress'] = t;
        break;
      case EffectType.explosion:
        params['explosionRadius'] = t * (params['maxRadius'] ?? 50);
        break;
      case EffectType.jello:
        params['elasticPhase'] = t * 2 * pi;
        break;
      case EffectType.wipe:
        params['wipeProgress'] = t;
        break;
      case EffectType.sparkle:
        params['sparklePhase'] = t;
        params['randomSeed'] = frame;
        break;
      case EffectType.particle:
        params['particleTime'] = t;
        params['randomSeed'] = frame;
        break;
      case EffectType.rain:
        params['rainOffset'] = t * (params['speed'] ?? 10);
        break;
      case EffectType.fire:
        params['fireFlicker'] = t;
        params['randomSeed'] = frame;
        break;
      case EffectType.oceanWaves:
        params['waveTime'] = t;
        break;
      case EffectType.clouds:
        params['cloudMovement'] = t;
        break;
      default:
        // Generic time parameter
        params['animationTime'] = t;
        break;
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    final effectName = widget.effect.getName(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? double.infinity : 900,
        height: isMobile ? double.infinity : 700,
        child: AnimatedBackground(
          child: Container(
            padding: const EdgeInsets.all(20),
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
                            'Generate Animation Frames',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '$effectName Effect',
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
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      // Frame info
                      Expanded(
                        child: Text(
                          '${_generatedFrames.length} frames generated',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _generatedFrames.isEmpty ? null : _applyFrames,
                        icon: const Icon(Icons.check),
                        label: const Text('Generate Frames'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return Column(
      children: [
        // Preview title and controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _generatedFrames.isEmpty ? null : _togglePreview,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                ),
                IconButton(
                  onPressed: _generatedFrames.isEmpty ? null : _stopPreview,
                  icon: const Icon(Icons.stop),
                  tooltip: 'Stop',
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Preview canvas
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _buildPreview(),
        ),

        const SizedBox(height: 16),

        // Frame scrubber
        if (_generatedFrames.isNotEmpty) ...[
          Row(
            children: [
              Text('Frame:'),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating frames...'),
          ],
        ),
      );
    }

    if (_generatedFrames.isEmpty) {
      return const Center(
        child: Text('No frames generated'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animation Settings',
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
                      Text('Duration (seconds)'),
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
                      Text('FPS'),
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
                  Text(
                    'Total Frames:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
              title: const Text('Ping-Pong Animation'),
              subtitle: const Text('Play forward then backward'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frame Generation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text('Generate New Frames'),
              subtitle: const Text('Create new frames for this animation'),
              value: true,
              groupValue: _generateNewFrames,
              onChanged: (value) {
                setState(() {
                  _generateNewFrames = value!;
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('Insert Into Timeline'),
              subtitle: const Text('Add frames to existing timeline'),
              value: false,
              groupValue: _generateNewFrames,
              onChanged: (value) {
                setState(() {
                  _generateNewFrames = value!;
                });
              },
            ),
            if (!_generateNewFrames) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Insert Position:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _insertPosition,
                      isExpanded: true,
                      items: List.generate(10, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text('After frame ${index + 1}'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _insertPosition = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEffectParameters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Effect Parameters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => _editParameters(),
                  child: const Text('Edit Parameters'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Current effect settings will be used as the base for animation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
        title: const Text('Edit Base Parameters'),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateFrames();
            },
            child: const Text('Apply & Regenerate'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Animation Frame Generator'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This tool generates multiple animation frames by applying the selected effect with different time parameters.\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Duration: Total length of the animation in seconds'),
              Text('• FPS: Frames per second (higher = smoother but more frames)'),
              Text('• Ping-Pong: Makes animation play forward then backward'),
              Text('• The effect parameters are interpolated over time to create smooth animations'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Start with lower FPS for testing'),
              Text('• Use Preview to see the animation before generating'),
              Text('• Longer durations work better for slower effects'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _applyFrames() {
    if (_generatedFrames.isEmpty) return;

    final frames = <AnimationFrame>[];
    final frameDuration = (1000 / _fps).round();

    for (int i = 0; i < _generatedFrames.length; i++) {
      // Create a new layer with the effect-processed pixels
      final layer = Layer(
        layerId: i,
        id: 'animated_effect_$i',
        name: 'Effect Frame ${i + 1}',
        pixels: _generatedFrames[i],
        order: 0,
      );

      final frame = AnimationFrame(
        id: i,
        stateId: 0,
        name: 'Effect Animation ${i + 1}',
        duration: frameDuration,
        layers: [layer],
        order: i,
      );

      frames.add(frame);
    }

    // If ping-pong, add reversed frames
    if (_pingPong && frames.length > 1) {
      final reversedFrames = frames.reversed.skip(1).take(frames.length - 1).toList();
      for (int i = 0; i < reversedFrames.length; i++) {
        final frame = reversedFrames[i];
        final newFrame = frame.copyWith(
          id: frames.length + i,
          name: 'Effect Animation ${frames.length + i + 1} (Return)',
          order: frames.length + i,
        );
        frames.add(newFrame);
      }
    }

    widget.onFramesGenerated(frames);
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated ${frames.length} animation frames!'),
        action: SnackBarAction(
          label: 'View Timeline',
          onPressed: () {
            // Could trigger timeline expansion or navigation
          },
        ),
      ),
    );
  }
}
