import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../pixel/effects/effects.dart';
import '../../../pixel/services/effect_preview_cache.dart';
import 'pixlel_preview_painter.dart';

/// Renders a rasterized preview image of the effect.
///
/// Previews are rendered and cached as images:
/// - Static effects render a single frame image (PNG) and save to cache.
/// - Animated effects render and display their first frame immediately
///   while the animated GIF is generated in the background, then save
///   and display the animated image.
///
/// Rendering as raster images avoids expensive per-frame custom paint
/// iterations and AnimationControllers, ensuring smooth scrolling and dialog loading.
class EffectIconPreview extends StatefulWidget {
  const EffectIconPreview({
    super.key,
    required this.effect,
  });

  final Effect effect;

  @override
  State<EffectIconPreview> createState() => _EffectIconPreviewState();
}

class _EffectIconPreviewState extends State<EffectIconPreview> {
  Uint8List? _firstFrameBytes;
  Uint8List? _animatedBytes;
  Object? _error;
  bool _isLoading = true;

  bool get _isAnimated {
    final descriptor = EffectCatalog.forType(widget.effect.type);
    return descriptor.isAnimated ||
        descriptor.workspace == EffectWorkspace.animation;
  }

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant EffectIconPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect.type != widget.effect.type ||
        jsonEncode(oldWidget.effect.parameters) !=
            jsonEncode(widget.effect.parameters)) {
      _loadPreview();
    }
  }

  void _loadPreview() {
    final cache = EffectPreviewCache.instance;
    final effect = widget.effect;
    final isAnim = _isAnimated;

    // Check synchronous cache first for instant presentation
    if (isAnim) {
      final cachedAnim = cache.getCachedAnimated(effect);
      if (cachedAnim != null) {
        setState(() {
          _animatedBytes = cachedAnim;
          _firstFrameBytes = null;
          _isLoading = false;
          _error = null;
        });
        return;
      }
    }

    final cachedFirst = cache.getCachedFirstFrame(effect);
    if (cachedFirst != null) {
      _firstFrameBytes = cachedFirst;
      _isLoading = false;
    } else {
      _firstFrameBytes = null;
      _isLoading = true;
    }
    _animatedBytes = null;
    _error = null;

    if (cachedFirst == null) {
      cache.getFirstFrameImage(effect).then((bytes) {
        if (!mounted || widget.effect != effect) return;
        setState(() {
          _firstFrameBytes = bytes;
          _isLoading = false;
        });
      }, onError: (Object err) {
        if (!mounted || widget.effect != effect) return;
        setState(() {
          _error = err;
          _isLoading = false;
        });
      });
    }

    if (isAnim) {
      cache.getAnimatedImage(effect).then((bytes) {
        if (!mounted || widget.effect != effect) return;
        setState(() {
          _animatedBytes = bytes;
        });
      }, onError: (Object err) {
        if (!mounted || widget.effect != effect) return;
        if (_firstFrameBytes == null) {
          setState(() {
            _error = err;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_error != null && _firstFrameBytes == null && _animatedBytes == null) {
      return Tooltip(
        message: _error.toString(),
        child: ColoredBox(
          color: colors.errorContainer,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.onErrorContainer,
            ),
          ),
        ),
      );
    }

    final displayBytes = _animatedBytes ?? _firstFrameBytes;

    if (displayBytes == null || (_isLoading && _firstFrameBytes == null)) {
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: const Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: CheckerboardPainter(),
          ),
          Image.memory(
            displayBytes,
            key: ValueKey('effect-icon-preview-${widget.effect.type.name}'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ],
      ),
    );
  }
}
