import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../pixel/effects/effects.dart';
import '../../../pixel/services/effect_icon_export_service.dart';
import 'pixlel_preview_painter.dart';

/// Renders the same 64×64 smiley/generator frame used by the icon exporter.
///
/// Cards intentionally render one representative frame instead of encoding a
/// complete GIF. Full JPG/GIF encoding remains an export operation and would
/// make grids with many animated effects unnecessarily expensive.
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
  static const _service = EffectIconExportService();
  static final Map<String, Future<Uint32List>> _cache = {};
  static const int _maxCachedAssets = 256;
  late Future<Uint32List> _pixels;

  @override
  void initState() {
    super.initState();
    _pixels = _renderPreview();
  }

  @override
  void didUpdateWidget(covariant EffectIconPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect.type != widget.effect.type ||
        jsonEncode(oldWidget.effect.parameters) !=
            jsonEncode(widget.effect.parameters)) {
      _pixels = _renderPreview();
    }
  }

  Future<Uint32List> _renderPreview() {
    final key =
        '${widget.effect.type.name}:${jsonEncode(widget.effect.parameters)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    if (_cache.length >= _maxCachedAssets) {
      _cache.remove(_cache.keys.first);
    }
    final future = _service.renderPreview(widget.effect).then(
      (pixels) => pixels,
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
    return FutureBuilder<Uint32List>(
      future: _pixels,
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

        return CustomPaint(
          key: ValueKey('effect-icon-preview-${widget.effect.type.name}'),
          painter: PixelPreviewPainter(
            pixels: snapshot.data!,
            width: EffectIconExportService.canvasSize,
            height: EffectIconExportService.canvasSize,
          ),
        );
      },
    );
  }
}
