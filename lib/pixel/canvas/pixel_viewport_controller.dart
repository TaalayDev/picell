import 'package:flutter/material.dart';

class PixelViewportController extends ChangeNotifier {
  PixelViewportController({
    double initialScale = 1.0,
    Offset initialOffset = Offset.zero,
  })  : _scale = initialScale,
        _offset = initialOffset;

  static const double minScale = 0.5;
  static const double maxScale = 5.0;

  double _scale;
  Offset _offset;

  double get scale => _scale;
  Offset get offset => _offset;

  void setViewport(double scale, Offset offset) {
    final clampedScale = scale.clamp(minScale, maxScale);
    if (_scale == clampedScale && _offset == offset) {
      return;
    }
    _scale = clampedScale;
    _offset = offset;
    notifyListeners();
  }

  void zoomIn() {
    setViewport((_scale * 1.1).clamp(minScale, maxScale), _offset);
  }

  void zoomOut() {
    setViewport((_scale / 1.1).clamp(minScale, maxScale), _offset);
  }

  void reset() {
    setViewport(1.0, Offset.zero);
  }
}
