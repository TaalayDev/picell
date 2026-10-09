import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../effects/effect_animation_renderer.dart';
import '../effects/effects.dart';
import '../pixel_utils.dart';
import 'effect_icon_export_service.dart';

/// Cache for rendered effect preview images supporting both in-memory
/// and persistent disk file storage for future app launches.
///
/// Previews are stored on disk as:
/// - Static first frame images: `{effect_type}_{params_hash}_frame.png`
/// - Animated preview images: `{effect_type}_{params_hash}_anim.gif`
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

  Directory? _customDirectory;
  Directory? _cachedBaseDir;

  /// Overrides the persistent disk cache directory (useful for testing).
  void setCustomCacheDirectory(Directory? directory) {
    _customDirectory = directory;
    _cachedBaseDir = directory;
  }

  /// Generates a cache key based on effect type and parameters.
  static String cacheKey(Effect effect) {
    return '${effect.type.name}:${jsonEncode(effect.parameters)}';
  }

  /// Generates a filesystem-safe base name for the effect file.
  static String getFileNameBase(Effect effect) {
    final paramsJson = jsonEncode(effect.parameters);
    if (paramsJson == '{}') {
      return '${effect.type.name}_default';
    }
    final hash = _hashString(paramsJson);
    return '${effect.type.name}_$hash';
  }

  static String _hashString(String input) {
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  Directory? _getCacheDirectorySync() {
    if (kIsWeb) return null;
    if (_customDirectory != null) {
      if (!_customDirectory!.existsSync()) {
        _customDirectory!.createSync(recursive: true);
      }
      return _customDirectory;
    }
    return _cachedBaseDir;
  }

  Future<Directory?> _ensureCacheDirectory() async {
    if (kIsWeb) return null;
    if (_customDirectory != null) {
      if (!_customDirectory!.existsSync()) {
        _customDirectory!.createSync(recursive: true);
      }
      return _customDirectory;
    }
    if (_cachedBaseDir != null && _cachedBaseDir!.existsSync()) {
      return _cachedBaseDir;
    }

    try {
      final baseDir = await getApplicationSupportDirectory();
      final previewDir = Directory('${baseDir.path}/effect_previews');
      if (!previewDir.existsSync()) {
        previewDir.createSync(recursive: true);
      }
      _cachedBaseDir = previewDir;
      return previewDir;
    } catch (_) {
      try {
        final tempDir = await getTemporaryDirectory();
        final previewDir = Directory('${tempDir.path}/effect_previews');
        if (!previewDir.existsSync()) {
          previewDir.createSync(recursive: true);
        }
        _cachedBaseDir = previewDir;
        return previewDir;
      } catch (_) {
        try {
          final sysTemp =
              Directory('${Directory.systemTemp.path}/effect_previews');
          if (!sysTemp.existsSync()) {
            sysTemp.createSync(recursive: true);
          }
          _cachedBaseDir = sysTemp;
          return sysTemp;
        } catch (_) {
          return null;
        }
      }
    }
  }

  /// Returns the file for the static first-frame image.
  Future<File?> getFirstFrameFile(Effect effect) async {
    final dir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
    if (dir == null) return null;
    final name = getFileNameBase(effect);
    return File('${dir.path}/${name}_frame.png');
  }

  /// Returns the file for the animated preview image.
  Future<File?> getAnimatedFile(Effect effect) async {
    final dir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
    if (dir == null) return null;
    final name = getFileNameBase(effect);
    return File('${dir.path}/${name}_anim.gif');
  }

  /// Returns cached static first-frame image bytes synchronously, or null if not in memory.
  Uint8List? getCachedFirstFrame(Effect effect) {
    return _firstFrameCache[cacheKey(effect)];
  }

  /// Returns cached animated image bytes synchronously, or null if not in memory.
  Uint8List? getCachedAnimated(Effect effect) {
    return _animatedCache[cacheKey(effect)];
  }

  /// Checks if either first frame or animated image is already cached in memory.
  bool hasCachedPreview(Effect effect, {bool isAnimated = false}) {
    final key = cacheKey(effect);
    if (isAnimated) {
      return _animatedCache.containsKey(key) ||
          _firstFrameCache.containsKey(key);
    }
    return _firstFrameCache.containsKey(key);
  }

  /// Retrieves or renders the static first frame of [effect] as an image (PNG).
  ///
  /// Checks in-memory cache, then disk file cache. If absent, renders the frame,
  /// saves to file cache for future use, and stores in memory cache.
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

    final future = _loadOrRenderFirstFrame(effect).then((bytes) {
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

  Future<Uint8List> _loadOrRenderFirstFrame(Effect effect) async {
    // 1. Try reading from persistent file cache
    try {
      final syncDir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
      if (syncDir != null) {
        final name = getFileNameBase(effect);
        final file = File('${syncDir.path}/${name}_frame.png');
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          if (bytes.isNotEmpty) {
            return bytes;
          }
        }
      }
    } catch (_) {}

    // 2. Render frame
    final bytes = await _renderFirstFrame(effect);

    // 3. Save to file cache synchronously so it's guaranteed saved
    try {
      final syncDir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
      if (syncDir != null) {
        final name = getFileNameBase(effect);
        final file = File('${syncDir.path}/${name}_frame.png');
        file.writeAsBytesSync(bytes, flush: true);
      }
    } catch (_) {}

    return bytes;
  }

  /// Retrieves or renders the animated preview of [effect] as an animated GIF image.
  ///
  /// Checks in-memory cache, then disk file cache. If absent, renders all frames,
  /// saves the GIF to file cache for future use, and stores in memory cache.
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

    final future = _loadOrRenderAnimated(effect).then((bytes) {
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

  Future<Uint8List> _loadOrRenderAnimated(Effect effect) async {
    // 1. Try reading from persistent file cache
    try {
      final syncDir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
      if (syncDir != null) {
        final name = getFileNameBase(effect);
        final file = File('${syncDir.path}/${name}_anim.gif');
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          if (bytes.isNotEmpty) {
            return bytes;
          }
        }
      }
    } catch (_) {}

    // 2. Render animation frames and encode to GIF
    final bytes = await _renderAnimated(effect);

    // 3. Save to file cache synchronously so it's guaranteed saved
    try {
      final syncDir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
      if (syncDir != null) {
        final name = getFileNameBase(effect);
        final file = File('${syncDir.path}/${name}_anim.gif');
        file.writeAsBytesSync(bytes, flush: true);
      }
    } catch (_) {}

    return bytes;
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

  /// Clears in-memory caches. Optionally deletes persistent cache files from disk.
  Future<void> clear({bool deleteFiles = false}) async {
    _firstFrameCache.clear();
    _animatedCache.clear();
    _pendingFirstFrames.clear();
    _pendingAnimated.clear();

    if (deleteFiles) {
      try {
        final dir = _getCacheDirectorySync() ?? await _ensureCacheDirectory();
        if (dir != null && dir.existsSync()) {
          for (final entity in dir.listSync()) {
            if (entity is File) {
              entity.deleteSync();
            }
          }
        }
      } catch (_) {}
    }
  }
}
