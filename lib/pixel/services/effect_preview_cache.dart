import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../effects/effect_animation_renderer.dart';
import '../effects/effects.dart';
import '../pixel_utils.dart';
import 'effect_icon_export_service.dart';

/// In-memory cache for rendered effect preview images.
///
/// Converts raw pixel arrays into raster images (PNG for static frames,
/// animated GIF for animations) so that UI widgets can display them via
/// native image renderers instead of repainting thousands of custom paint rects.
class EffectPreviewCache {
  EffectPreviewCache._();

  static final EffectPreviewCache instance = EffectPreviewCache._();

  static const EffectIconExportService _service = EffectIconExportService();

  static const int maxCacheEntries = 256;

  // In-memory cache for static first-frame image bytes (PNG)
  final Map<String, Uint8List> _firstFrameCache = {};

  // In-memory cache for animated image bytes (GIF)
  final Map<String, Uint8List> _animatedCache = {};

  // Pending futures to avoid duplicate concurrent render passes
  final Map<String, Future<Uint8List>> _pendingFirstFrames = {};
  final Map<String, Future<Uint8List>> _pendingAnimated = {};

  /// Generates a cache key based on effect type and parameters.
  static String cacheKey(Effect effect) {
    return '${effect.type.name}:${jsonEncode(effect.parameters)}';
  }

  /// Returns cached static first-frame image bytes synchronously, or null if not yet cached.
  Uint8List? getCachedFirstFrame(Effect effect) {
    return _firstFrameCache[cacheKey(effect)];
  }

  /// Returns cached animated image bytes synchronously, or null if not yet cached.
  Uint8List? getCachedAnimated(Effect effect) {
    return _animatedCache[cacheKey(effect)];
  }

  /// Checks if either first frame or animated image is already cached.
  bool hasCachedPreview(Effect effect, {bool isAnimated = false}) {
    final key = cacheKey(effect);
    if (isAnimated) {
      return _animatedCache.containsKey(key) || _firstFrameCache.containsKey(key);
    }
    return _firstFrameCache.containsKey(key);
  }

  /// Retrieves or renders the static first frame of [effect] as an image (PNG).
  Future<Uint8List> getFirstFrameImage(Effect effect) {
    final key = cacheKey(effect);
    final cached = _firstFrameCache[key];
    if (cached != null) {
      return Future.value(cached);
    }

    final pending = _pendingFirstFrames[key];
    if (pending != null) {
      return pending;
    }

    final future = _renderFirstFrame(effect).then((bytes) {
      _putFirstFrame(key, bytes);
      _pendingFirstFrames.remove(key);
      return bytes;
    }, onError: (Object error, StackTrace stackTrace) {
      _pendingFirstFrames.remove(key);
      Error.throwWithStackTrace(error, stackTrace);
    });

    _pendingFirstFrames[key] = future;
    return future;
  }

  /// Retrieves or renders the animated preview of [effect] as an animated GIF image.
  Future<Uint8List> getAnimatedImage(Effect effect) {
    final key = cacheKey(effect);
    final cached = _animatedCache[key];
    if (cached != null) {
      return Future.value(cached);
    }

    final pending = _pendingAnimated[key];
    if (pending != null) {
      return pending;
    }

    final future = _renderAnimated(effect).then((bytes) {
      _putAnimated(key, bytes);
      _pendingAnimated.remove(key);
      return bytes;
    }, onError: (Object error, StackTrace stackTrace) {
      _pendingAnimated.remove(key);
      Error.throwWithStackTrace(error, stackTrace);
    });

    _pendingAnimated[key] = future;
    return future;
  }

  Future<Uint8List> _renderFirstFrame(Effect effect) async {
    final descriptor = EffectCatalog.forType(effect.type);
    final isAnimated = descriptor.isAnimated ||
        descriptor.workspace == EffectWorkspace.animation;
    final source = _service.sourcePixelsFor(effect);

    Uint32List pixels;
    if (!isAnimated) {
      pixels = await effect.apply(
        source,
        EffectIconExportService.canvasSize,
        EffectIconExportService.canvasSize,
      );
    } else {
      pixels = await EffectAnimationRenderer.renderFrame(
        pixels: Uint32List.fromList(source),
        width: EffectIconExportService.canvasSize,
        height: EffectIconExportService.canvasSize,
        effects: [effect],
        animatedEffectIndex: 0,
        progress: 0.0,
      );
    }

    final image = PixelUtils.imageFromAarrggbb(
      pixels,
      EffectIconExportService.canvasSize,
      EffectIconExportService.canvasSize,
      hardAlphaForGif: isAnimated,
    );

    return Uint8List.fromList(img.encodePng(image));
  }

  Future<Uint8List> _renderAnimated(Effect effect) async {
    final source = _service.sourcePixelsFor(effect);
    final encoder = img.GifEncoder(
      delay: (100 / EffectIconExportService.animationFps).round(),
      repeat: 0,
    );

    const frameCount = EffectIconExportService.animationFrameCount;
    for (var frame = 0; frame < frameCount; frame++) {
      final progress = frame / frameCount;
      final pixels = await EffectAnimationRenderer.renderFrame(
        pixels: Uint32List.fromList(source),
        width: EffectIconExportService.canvasSize,
        height: EffectIconExportService.canvasSize,
        effects: [effect],
        animatedEffectIndex: 0,
        progress: progress,
      );
      final image = PixelUtils.imageFromAarrggbb(
        pixels,
        EffectIconExportService.canvasSize,
        EffectIconExportService.canvasSize,
        hardAlphaForGif: true,
      );
      encoder.addFrame(image);

      // Yield briefly between frames so the UI thread stays responsive
      await Future<void>.delayed(Duration.zero);
    }

    final bytes = encoder.finish();
    if (bytes == null) {
      throw StateError('Failed to encode animated GIF for ${effect.type.name}');
    }
    return Uint8List.fromList(bytes);
  }

  void _putFirstFrame(String key, Uint8List bytes) {
    if (_firstFrameCache.length >= maxCacheEntries) {
      _firstFrameCache.remove(_firstFrameCache.keys.first);
    }
    _firstFrameCache[key] = bytes;
  }

  void _putAnimated(String key, Uint8List bytes) {
    if (_animatedCache.length >= maxCacheEntries) {
      _animatedCache.remove(_animatedCache.keys.first);
    }
    _animatedCache[key] = bytes;
  }

  /// Clears in-memory caches.
  void clear() {
    _firstFrameCache.clear();
    _animatedCache.clear();
    _pendingFirstFrames.clear();
    _pendingAnimated.clear();
  }
}
