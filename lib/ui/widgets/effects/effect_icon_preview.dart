import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../pixel/effects/effects.dart';
import '../../../pixel/services/effect_icon_export_service.dart';
import 'pixlel_preview_painter.dart';

/// Renders the same 64×64 smiley/generator frame used by the icon exporter.
///
/// For animated effects, a sequence of raw preview frames is cycled smoothly
/// with an AnimationController without requiring full GIF encoding.
class EffectIconPreview extends StatefulWidget {
  const EffectIconPreview({
    super.key,
    required this.effect,
  });

  final Effect effect;

  @override
  State<EffectIconPreview> createState() => _EffectIconPreviewState();
}

class _EffectIconPreviewState extends State<EffectIconPreview>
    with SingleTickerProviderStateMixin {
  static const _service = EffectIconExportService();
  static final Map<String, Future<List<Uint32List>>> _cache = {};
  static const int _maxCachedAssets = 256;
  late Future<List<Uint32List>> _frames;
  AnimationController? _controller;

  bool get _isAnimated {
    final descriptor = EffectCatalog.forType(widget.effect.type);
    return descriptor.isAnimated ||
        descriptor.workspace == EffectWorkspace.animation;
  }

  @override
  void initState() {
    super.initState();
    _initControllerIfNeeded();
    _frames = _renderFrames();
  }

  void _initControllerIfNeeded() {
    if (_isAnimated) {
      _controller ??= AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: (1000 / EffectIconExportService.animationFps *
                  EffectIconExportService.animationFrameCount)
              .round(),
        ),
      )..repeat();
    } else {
      _controller?.stop();
    }
  }

  @override
  void didUpdateWidget(covariant EffectIconPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initControllerIfNeeded();
    if (oldWidget.effect.type != widget.effect.type ||
        jsonEncode(oldWidget.effect.parameters) !=
            jsonEncode(widget.effect.parameters)) {
      _frames = _renderFrames();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<List<Uint32List>> _renderFrames() {
    final key =
        '${widget.effect.type.name}:${jsonEncode(widget.effect.parameters)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    if (_cache.length >= _maxCachedAssets) {
      _cache.remove(_cache.keys.first);
    }
    final future = _service.renderPreviewFrames(widget.effect).then(
      (frames) => frames,
      onError: (Object error, StackTrace stackTrace) {
        _cache.remove(key);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _cache[key] = future;
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<Uint32List>>(
      future: _frames,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Tooltip(
            message: snapshot.error.toString(),
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
        if (!snapshot.hasData) {
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

        final frames = snapshot.data!;
        if (frames.isEmpty) {
          return const SizedBox.shrink();
        }

        if (!_isAnimated || frames.length <= 1 || _controller == null) {
          return CustomPaint(
            key: ValueKey('effect-icon-preview-${widget.effect.type.name}'),
            painter: PixelPreviewPainter(
              pixels: frames.first,
              width: EffectIconExportService.canvasSize,
              height: EffectIconExportService.canvasSize,
            ),
          );
        }

        return AnimatedBuilder(
          animation: _controller!,
          builder: (context, _) {
            final frameIndex =
                (_controller!.value * frames.length).floor() % frames.length;
            return CustomPaint(
              key: ValueKey('effect-icon-preview-${widget.effect.type.name}'),
              painter: PixelPreviewPainter(
                pixels: frames[frameIndex],
                width: EffectIconExportService.canvasSize,
                height: EffectIconExportService.canvasSize,
              ),
            );
          },
        );
      },
    );
  }
}
