import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/utils/image_helper.dart';
import '../pixel_utils.dart';
import 'canvas_surface_models.dart';

class PixelCanvasSurfaceImageResolver extends ChangeNotifier {
  ui.Image? _backgroundImage;
  ui.Image? get backgroundImage => _backgroundImage;

  Uint8List? _requestedBackgroundImageBytes;
  List<PixelCanvasOnionSkinFrame> _requestedOnionSkinFrames = const <PixelCanvasOnionSkinFrame>[];
  List<PixelCanvasOnionSkinFrame> _lastOnionSkinFrames = const <PixelCanvasOnionSkinFrame>[];
  List<PixelCanvasResolvedOnionSkinFrame> _onionSkinImages = const <PixelCanvasResolvedOnionSkinFrame>[];
  List<PixelCanvasResolvedOnionSkinFrame> get onionSkinFrames => _onionSkinImages;

  int _decodeGeneration = 0;
  int _onionSkinGeneration = 0;
  bool _isDisposed = false;

  void update({required Uint8List? backgroundImageBytes, required List<PixelCanvasOnionSkinFrame> onionSkinFrames}) {
    if (!identical(backgroundImageBytes, _requestedBackgroundImageBytes)) {
      _requestedBackgroundImageBytes = backgroundImageBytes;
      unawaited(_syncBackgroundImage(backgroundImageBytes));
    }

    if (!samePixelCanvasOnionSkinFrames(_requestedOnionSkinFrames, onionSkinFrames)) {
      _requestedOnionSkinFrames = List<PixelCanvasOnionSkinFrame>.from(onionSkinFrames);
      unawaited(_syncOnionSkinImages(_requestedOnionSkinFrames));
    }
  }

  Future<void> _syncBackgroundImage(Uint8List? bytes) async {
    final generation = ++_decodeGeneration;

    if (bytes == null) {
      _clearBackgroundImage();
      return;
    }

    final decodedImage = await _decodeImageFromBytes(bytes);
    if (_isDisposed || generation != _decodeGeneration) {
      decodedImage.dispose();
      return;
    }

    final previousImage = _backgroundImage;
    _backgroundImage = decodedImage;
    notifyListeners();
    _disposeImageAfterFrame(previousImage);
  }

  Future<ui.Image> _decodeImageFromBytes(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<void> _syncOnionSkinImages(List<PixelCanvasOnionSkinFrame> nextFrames) async {
    final generation = ++_onionSkinGeneration;
    final previousFramesById = <int, PixelCanvasOnionSkinFrame>{
      for (final frame in _lastOnionSkinFrames) frame.frameId: frame,
    };
    final previousImagesById = <int, PixelCanvasResolvedOnionSkinFrame>{
      for (final frame in _onionSkinImages) frame.frameId: frame,
    };
    final createdImages = <ui.Image>[];
    final reusedImages = <ui.Image>{};
    final nextImages = <PixelCanvasResolvedOnionSkinFrame>[];

    if (nextFrames.isEmpty) {
      final oldImages = _onionSkinImages;
      if (_isDisposed || generation != _onionSkinGeneration) {
        return;
      }

      _lastOnionSkinFrames = const <PixelCanvasOnionSkinFrame>[];
      _onionSkinImages = const <PixelCanvasResolvedOnionSkinFrame>[];
      notifyListeners();

      for (final frame in oldImages) {
        _disposeImageAfterFrame(frame.image);
      }
      return;
    }

    for (final frame in nextFrames) {
      final previousFrame = previousFramesById[frame.frameId];
      final previousImage = previousImagesById[frame.frameId];
      if (previousFrame != null && previousImage != null && frame.hasSameRasterData(previousFrame)) {
        nextImages.add(
          PixelCanvasResolvedOnionSkinFrame(frameId: frame.frameId, image: previousImage.image, opacity: frame.opacity),
        );
        reusedImages.add(previousImage.image);
        continue;
      }

      final mergedPixels = PixelUtils.mergeLayersPixels(width: frame.width, height: frame.height, layers: frame.layers);
      final image = await ImageHelper.createImageFromPixels(mergedPixels, frame.width, frame.height);
      createdImages.add(image);

      if (_isDisposed || generation != _onionSkinGeneration) {
        for (final createdImage in createdImages) {
          createdImage.dispose();
        }
        return;
      }

      nextImages.add(PixelCanvasResolvedOnionSkinFrame(frameId: frame.frameId, image: image, opacity: frame.opacity));
    }

    if (_isDisposed || generation != _onionSkinGeneration) {
      for (final createdImage in createdImages) {
        createdImage.dispose();
      }
      return;
    }

    final oldImages = _onionSkinImages;
    _lastOnionSkinFrames = List<PixelCanvasOnionSkinFrame>.from(nextFrames);
    _onionSkinImages = nextImages;
    notifyListeners();

    for (final oldFrame in oldImages) {
      if (!reusedImages.contains(oldFrame.image)) {
        _disposeImageAfterFrame(oldFrame.image);
      }
    }
  }

  void _clearBackgroundImage() {
    final previousImage = _backgroundImage;
    if (previousImage == null) {
      return;
    }

    _backgroundImage = null;
    notifyListeners();
    _disposeImageAfterFrame(previousImage);
  }

  void _disposeImageAfterFrame(ui.Image? image) {
    if (image == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      image.dispose();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _backgroundImage?.dispose();
    _backgroundImage = null;

    for (final frame in _onionSkinImages) {
      frame.image.dispose();
    }
    _onionSkinImages = const <PixelCanvasResolvedOnionSkinFrame>[];
    super.dispose();
  }
}
