import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data.dart';
import '../../../pixel/image_painter.dart';
import '../layers_preview.dart';
import '../../../l10n/strings.dart';

Future<void> showAnimationPreviewDialog(
  BuildContext context, {
  required List<AnimationFrame> frames,
  required int width,
  required int height,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AnimationPreviewDialog(
        frames: frames,
        width: width,
        height: height,
      );
    },
  );
}

class AnimationPreviewDialog extends StatefulWidget {
  final List<AnimationFrame> frames;
  final int width;
  final int height;

  const AnimationPreviewDialog({
    super.key,
    required this.frames,
    required this.width,
    required this.height,
  });

  @override
  State<AnimationPreviewDialog> createState() => _AnimationPreviewDialogState();
}

class _AnimationPreviewDialogState extends State<AnimationPreviewDialog> with SingleTickerProviderStateMixin {
  int _currentFrameIndex = 0;
  Timer? _timer;
  late AnimationController _scaleController;
  bool _isPlaying = true;
  double _frameRate = 12; // Default FPS
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for subtle scale effect
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleController.forward();

    // Start animation playback
    _startPlayback();
  }

  void _startPlayback() {
    _timer?.cancel();
    if (!_isPlaying) return;

    final frame = widget.frames[_currentFrameIndex];

    // Calculate frame duration based on original duration and playback speed
    final duration = Duration(
      milliseconds: (frame.duration / _playbackSpeed).round(),
    );

    _timer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % widget.frames.length;
          _startPlayback();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate a good preview size based on screen size and aspect ratio
    final screenSize = MediaQuery.of(context).size;
    final previewWidth = min(screenSize.width * 0.8, 600.0);
    final aspectRatio = widget.width / widget.height;
    final previewHeight = previewWidth / aspectRatio;

    // Animation for subtle effects
    final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: previewWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top handle for dialog
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  Strings.of(context).animationPreview,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

              // Frame display
              Container(
                width: previewWidth,
                height: previewHeight,
                decoration: BoxDecoration(
                  // Checkerboard pattern for transparency
                  color: Colors.white.withValues(alpha: 0.8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  children: [
                    // Checkerboard background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CheckerboardPainter(
                          cellSize: 10,
                          color1: Colors.grey.shade200,
                          color2: Colors.grey.shade100,
                        ),
                      ),
                    ),

                    // Animation frames
                    IndexedStack(
                      index: _currentFrameIndex,
                      sizing: StackFit.expand,
                      children: [
                        for (var frame in widget.frames)
                          LayersPreview(
                            width: widget.width,
                            height: widget.height,
                            layers: frame.layers,
                            builder: (context, image) {
                              return image != null
                                  ? CustomPaint(painter: ImagePainter(image))
                                  : const ColoredBox(color: Colors.transparent);
                            },
                          ),
                      ],
                    ),

                    // Frame counter overlay
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          Strings.of(context).frameCount(_currentFrameIndex + 1, widget.frames.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _currentFrameIndex > 0 ? Icons.skip_previous : Icons.skip_previous_outlined,
                          ),
                          onPressed: _currentFrameIndex > 0
                              ? () {
                                  setState(() {
                                    _currentFrameIndex = 0;
                                    _startPlayback();
                                  });
                                }
                              : null,
                          tooltip: Strings.of(context).firstFrame,
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_before),
                          onPressed: () {
                            setState(() {
                              _currentFrameIndex =
                                  (_currentFrameIndex - 1 + widget.frames.length) % widget.frames.length;
                              _startPlayback();
                            });
                          },
                          tooltip: Strings.of(context).previousFrame,
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                          onPressed: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                              if (_isPlaying) {
                                _startPlayback();
                              } else {
                                _timer?.cancel();
                              }
                            });
                          },
                          tooltip: _isPlaying ? Strings.of(context).pause : Strings.of(context).play,
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_next),
                          onPressed: () {
                            setState(() {
                              _currentFrameIndex = (_currentFrameIndex + 1) % widget.frames.length;
                              _startPlayback();
                            });
                          },
                          tooltip: Strings.of(context).nextFrame,
                        ),
                        IconButton(
                          icon: Icon(
                            _currentFrameIndex < widget.frames.length - 1 ? Icons.skip_next : Icons.skip_next_outlined,
                          ),
                          onPressed: _currentFrameIndex < widget.frames.length - 1
                              ? () {
                                  setState(() {
                                    _currentFrameIndex = widget.frames.length - 1;
                                    _startPlayback();
                                  });
                                }
                              : null,
                          tooltip: Strings.of(context).lastFrame,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Speed controls
                    Row(
                      children: [
                        Text(Strings.of(context).playbackSpeed),
                        Expanded(
                          child: Slider(
                            value: _playbackSpeed,
                            min: 0.25,
                            max: 2.0,
                            divisions: 7,
                            label: '${_playbackSpeed}x',
                            onChanged: (value) {
                              setState(() {
                                _playbackSpeed = value;
                                _startPlayback();
                              });
                            },
                          ),
                        ),
                        Text('${_playbackSpeed}x'),
                      ],
                    ),

                    // Frame information
                    if (widget.frames.isNotEmpty)
                      Text(
                        Strings.of(context).duration(widget.frames[_currentFrameIndex].duration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                  ],
                ),
              ),

              // Bottom buttons
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       TextButton(
              //         onPressed: () => Navigator.of(context).pop(),
              //         child: const Text('Close'),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  final double cellSize;
  final Color color1;
  final Color color2;

  CheckerboardPainter({
    required this.cellSize,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rows = (size.height / cellSize).ceil();
    final cols = (size.width / cellSize).ceil();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final color = (row + col) % 2 == 0 ? color1 : color2;
        paint.color = color;

        canvas.drawRect(
          Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
