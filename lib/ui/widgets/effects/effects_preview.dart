import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../data/models/layer.dart';
import '../../../pixel/effects/effects.dart';

class EffectPreviewWidget extends StatefulWidget {
  final Layer layer;
  final Effect? effect;
  final int width;
  final int height;
  final double previewSize;

  const EffectPreviewWidget({
    super.key,
    required this.layer,
    this.effect,
    required this.width,
    required this.height,
    this.previewSize = 100,
  });

  @override
  State<EffectPreviewWidget> createState() => _EffectPreviewWidgetState();
}

class _EffectPreviewWidgetState extends State<EffectPreviewWidget> {
  Uint32List? _previewPixels;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _processPreview();
  }

  @override
  void didUpdateWidget(EffectPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect != widget.effect || oldWidget.layer != widget.layer) {
      _processPreview();
    }
  }

  Future<void> _processPreview() async {
    setState(() {
      _loading = true;
    });

    // Use a compute function to avoid blocking the UI
    await Future.microtask(() {
      Uint32List pixels;

      if (widget.effect != null) {
        // Apply just this effect to the original pixels
        pixels = widget.effect!.apply(
          widget.layer.pixels,
          widget.width,
          widget.height,
        );
      } else if (widget.layer.effects.isNotEmpty) {
        // Apply all layer effects
        pixels = EffectsManager.applyMultipleEffects(
          widget.layer.pixels,
          widget.width,
          widget.height,
          widget.layer.effects,
        );
      } else {
        // Just use the original pixels
        pixels = widget.layer.pixels;
      }

      _previewPixels = pixels;
    });

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.previewSize,
        height: widget.previewSize,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      width: widget.previewSize,
      height: widget.previewSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          painter: _EffectPreviewPainter(
            pixels: _previewPixels!,
            width: widget.width,
            height: widget.height,
          ),
        ),
      ),
    );
  }
}

class _EffectPreviewPainter extends CustomPainter {
  final Uint32List pixels;
  final int width;
  final int height;

  _EffectPreviewPainter({
    required this.pixels,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a checkerboard background for transparent areas
    final checkerPaint = Paint()..color = Colors.grey.shade300;

    final checkerSize = size.width / 10;
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 10; x++) {
        if ((x + y) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * checkerSize,
              y * checkerSize,
              checkerSize,
              checkerSize,
            ),
            checkerPaint,
          );
        }
      }
    }

    // Draw the pixels
    final paint = Paint()..style = PaintingStyle.fill;
    final pixelWidth = size.width / width;
    final pixelHeight = size.height / height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < pixels.length) {
          final pixelValue = pixels[index];
          final color = Color(pixelValue);

          if (color.alpha > 0) {
            paint.color = color;
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _EffectPreviewPainter) {
      return oldDelegate.pixels != pixels;
    }
    return true;
  }
}

// Effect comparison widget that shows before and after
class BeforeAfterEffectPreview extends StatelessWidget {
  final Layer layer;
  final Effect? effect;
  final List<Effect>? effects;
  final int width;
  final int height;

  const BeforeAfterEffectPreview({
    super.key,
    required this.layer,
    this.effect,
    this.effects,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Effect Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  EffectPreviewWidget(
                    layer: layer,
                    width: width,
                    height: height,
                    previewSize: 120,
                  ),
                  const SizedBox(height: 8),
                  const Text('Original'),
                ],
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward),
              const SizedBox(width: 16),
              Column(
                children: [
                  EffectPreviewWidget(
                    layer: layer,
                    effect: effect,
                    width: width,
                    height: height,
                    previewSize: 120,
                  ),
                  const SizedBox(height: 8),
                  const Text('With Effect'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
