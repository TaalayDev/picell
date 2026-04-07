import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'layer_cache_manager.dart';

class PixelCanvasRepaintBinding {
  PixelCanvasRepaintBinding({
    required PixelCanvasController controller,
    required LayerCacheManager cacheManager,
    required Animation<double>? selectionAnimation,
    required VoidCallback onRepaint,
  })  : _controller = controller,
        _cacheManager = cacheManager,
        _selectionAnimation = selectionAnimation,
        _onRepaint = onRepaint;

  PixelCanvasController _controller;
  LayerCacheManager _cacheManager;
  Animation<double>? _selectionAnimation;
  final VoidCallback _onRepaint;
  bool _attached = false;

  void update({
    PixelCanvasController? controller,
    LayerCacheManager? cacheManager,
    Animation<double>? selectionAnimation,
  }) {
    final oldController = _controller;
    final oldCacheManager = _cacheManager;
    final oldSelectionAnimation = _selectionAnimation;

    final nextController = controller ?? _controller;
    final nextCacheManager = cacheManager ?? _cacheManager;
    final nextSelectionAnimation = selectionAnimation ?? _selectionAnimation;

    if (_attached) {
      if (!identical(oldController, nextController)) {
        oldController.removeListener(_onRepaint);
      }
      if (!identical(oldCacheManager, nextCacheManager)) {
        oldCacheManager.removeListener(_onRepaint);
      }
      if (!identical(oldSelectionAnimation, nextSelectionAnimation)) {
        oldSelectionAnimation?.removeListener(_onRepaint);
      }
    }

    _controller = nextController;
    _cacheManager = nextCacheManager;
    _selectionAnimation = nextSelectionAnimation;

    if (_attached) {
      if (!identical(oldController, nextController)) {
        nextController.addListener(_onRepaint);
      }
      if (!identical(oldCacheManager, nextCacheManager)) {
        nextCacheManager.addListener(_onRepaint);
      }
      if (!identical(oldSelectionAnimation, nextSelectionAnimation)) {
        nextSelectionAnimation?.addListener(_onRepaint);
      }
    }
  }

  void attach() {
    if (_attached) return;
    _attached = true;
    _controller.addListener(_onRepaint);
    _cacheManager.addListener(_onRepaint);
    _selectionAnimation?.addListener(_onRepaint);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _controller.removeListener(_onRepaint);
    _cacheManager.removeListener(_onRepaint);
    _selectionAnimation?.removeListener(_onRepaint);
  }
}
