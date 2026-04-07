import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../core.dart';

/// Manages caching of layer images for efficient rendering
class LayerCacheManager extends ChangeNotifier {
  final int width;
  final int height;
  final Map<int, LayerCacheEntry> _cachedLayers = {};
  bool _isBatchUpdate = false;

  LayerCacheManager({required this.width, required this.height});

  /// Get cached image for a layer
  ui.Image? getLayerImage(int layerId) {
    return _cachedLayers[layerId]?.image;
  }

  /// Check if a layer needs updating
  bool isLayerDirty(int layerId) {
    return _cachedLayers[layerId]?.isDirty ?? true;
  }

  /// Update a layer's cached image
  void updateLayer(int layerId, Uint32List pixels, int width, int height) {
    _createImageAsync(layerId, pixels, width, height);
  }

  /// Mark a layer as dirty (needs re-caching)
  void markLayerDirty(int layerId) {
    final entry = _cachedLayers[layerId];
    if (entry != null && !entry.isDirty) {
      entry.isDirty = true;
      if (!_isBatchUpdate) {
        notifyListeners();
      }
    }
  }

  /// Remove a layer from cache
  void removeLayer(int layerId) {
    final entry = _cachedLayers.remove(layerId);
    entry?.dispose();
    if (!_isBatchUpdate) {
      notifyListeners();
    }
  }

  /// Perform multiple operations without triggering multiple notifications
  void batchUpdate(VoidCallback operations) {
    _isBatchUpdate = true;
    operations();
    _isBatchUpdate = false;
    notifyListeners();
  }

  /// Clear all cached layers
  void clearAll() {
    for (final entry in _cachedLayers.values) {
      entry.dispose();
    }
    _cachedLayers.clear();
    // notifyListeners();
  }

  /// Get memory usage information
  CacheMemoryInfo getMemoryInfo() {
    int totalImages = _cachedLayers.length;
    int dirtyImages = _cachedLayers.values.where((e) => e.isDirty).length;
    int estimatedMemoryBytes = totalImages * width * height * 4; // RGBA

    return CacheMemoryInfo(
      totalImages: totalImages,
      dirtyImages: dirtyImages,
      estimatedMemoryBytes: estimatedMemoryBytes,
    );
  }

  Future<void> _createImageAsync(int layerId, Uint32List pixels, int width, int height) async {
    try {
      final image = await ImageHelper.createImageFromPixels(Uint32List.fromList(pixels), width, height);

      _updateLayerImage(layerId, image);
    } catch (e) {
      debugPrint('Error creating image for layer $layerId: $e');
    }
  }

  void _updateLayerImage(int layerId, ui.Image image) {
    // Dispose old image if it exists
    _cachedLayers[layerId]?.dispose();

    _cachedLayers[layerId] = LayerCacheEntry(image: image, isDirty: false, lastUpdated: DateTime.now());

    if (!_isBatchUpdate) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}

/// Represents a cached layer entry
class LayerCacheEntry {
  ui.Image image;
  bool isDirty;
  DateTime lastUpdated;

  LayerCacheEntry({required this.image, required this.isDirty, required this.lastUpdated});

  void dispose() {
    image.dispose();
  }
}

/// Information about cache memory usage
class CacheMemoryInfo {
  final int totalImages;
  final int dirtyImages;
  final int estimatedMemoryBytes;

  const CacheMemoryInfo({required this.totalImages, required this.dirtyImages, required this.estimatedMemoryBytes});

  String get estimatedMemoryMB => '${(estimatedMemoryBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  String toString() {
    return 'CacheMemoryInfo(total: $totalImages, dirty: $dirtyImages, memory: $estimatedMemoryMB)';
  }
}
