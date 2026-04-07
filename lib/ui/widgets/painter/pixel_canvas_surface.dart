import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide Layer;

import '../../../core/utils/image_helper.dart';
import '../../../data/models/layer.dart';
import '../../../pixel/pixel_utils.dart';

class PixelCanvasOnionSkinFrame {
  const PixelCanvasOnionSkinFrame({
    required this.frameId,
    required this.width,
    required this.height,
    required this.layers,
    required this.opacity,
  });

  final int frameId;
  final int width;
  final int height;
  final List<Layer> layers;
  final double opacity;

  bool hasSameRasterData(PixelCanvasOnionSkinFrame other) {
    if (frameId != other.frameId ||
        width != other.width ||
        height != other.height) {
      return false;
    }
    if (layers.length != other.layers.length) {
      return false;
    }
    for (var i = 0; i < layers.length; i++) {
      if (layers[i] != other.layers[i]) {
        return false;
      }
    }
    return true;
  }
}

class _ResolvedOnionSkinFrame {
  const _ResolvedOnionSkinFrame({
    required this.frameId,
    required this.image,
    required this.opacity,
  });

  final int frameId;
  final ui.Image image;
  final double opacity;
}

class PixelCanvasSurface extends StatefulWidget {
  const PixelCanvasSurface({
    super.key,
    required this.gridWidth,
    required this.gridHeight,
    this.backgroundImageBytes,
    this.backgroundOpacity = 0.3,
    this.backgroundScale = 1.0,
    this.backgroundOffset = Offset.zero,
    this.onionSkinFrames = const <PixelCanvasOnionSkinFrame>[],
    required this.child,
  });

  final int gridWidth;
  final int gridHeight;
  final Uint8List? backgroundImageBytes;
  final double backgroundOpacity;
  final double backgroundScale;
  final Offset backgroundOffset;
  final List<PixelCanvasOnionSkinFrame> onionSkinFrames;
  final Widget child;

  @override
  State<PixelCanvasSurface> createState() => _PixelCanvasSurfaceState();
}

class _PixelCanvasSurfaceState extends State<PixelCanvasSurface> {
  ui.Image? _backgroundImage;
  List<PixelCanvasOnionSkinFrame> _lastOnionSkinFrames =
      const <PixelCanvasOnionSkinFrame>[];
  List<_ResolvedOnionSkinFrame> _onionSkinImages =
      const <_ResolvedOnionSkinFrame>[];
  int _decodeGeneration = 0;
  int _onionSkinGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_syncBackgroundImage());
    unawaited(_syncOnionSkinImages());
  }

  @override
  void didUpdateWidget(covariant PixelCanvasSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backgroundImageBytes != widget.backgroundImageBytes) {
      unawaited(_syncBackgroundImage());
    }
    if (!_sameOnionSkinFrames(
        oldWidget.onionSkinFrames, widget.onionSkinFrames)) {
      unawaited(_syncOnionSkinImages());
    }
  }

  Future<void> _syncBackgroundImage() async {
    final bytes = widget.backgroundImageBytes;
    final generation = ++_decodeGeneration;

    if (bytes == null) {
      _disposeBackgroundImage();
      return;
    }

    final decodedImage = await _decodeImageFromBytes(bytes);
    if (!mounted || generation != _decodeGeneration) {
      decodedImage.dispose();
      return;
    }

    final previousImage = _backgroundImage;
    setState(() {
      _backgroundImage = decodedImage;
    });
    _disposeImageAfterFrame(previousImage);
  }

  Future<ui.Image> _decodeImageFromBytes(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<void> _syncOnionSkinImages() async {
    final generation = ++_onionSkinGeneration;
    final nextFrames = widget.onionSkinFrames;
    final previousFramesById = <int, PixelCanvasOnionSkinFrame>{
      for (final frame in _lastOnionSkinFrames) frame.frameId: frame,
    };
    final previousImagesById = <int, _ResolvedOnionSkinFrame>{
      for (final frame in _onionSkinImages) frame.frameId: frame,
    };
    final createdImages = <ui.Image>[];
    final reusedImages = <ui.Image>{};
    final nextImages = <_ResolvedOnionSkinFrame>[];

    if (nextFrames.isEmpty) {
      final oldImages = _onionSkinImages;
      if (!mounted || generation != _onionSkinGeneration) {
        return;
      }
      setState(() {
        _lastOnionSkinFrames = const <PixelCanvasOnionSkinFrame>[];
        _onionSkinImages = const <_ResolvedOnionSkinFrame>[];
      });
      for (final frame in oldImages) {
        _disposeImageAfterFrame(frame.image);
      }
      return;
    }

    for (final frame in nextFrames) {
      final previousFrame = previousFramesById[frame.frameId];
      final previousImage = previousImagesById[frame.frameId];
      if (previousFrame != null &&
          previousImage != null &&
          frame.hasSameRasterData(previousFrame)) {
        nextImages.add(
          _ResolvedOnionSkinFrame(
            frameId: frame.frameId,
            image: previousImage.image,
            opacity: frame.opacity,
          ),
        );
        reusedImages.add(previousImage.image);
        continue;
      }

      final mergedPixels = PixelUtils.mergeLayersPixels(
        width: frame.width,
        height: frame.height,
        layers: frame.layers,
      );
      final image = await ImageHelper.createImageFromPixels(
        mergedPixels,
        frame.width,
        frame.height,
      );
      createdImages.add(image);

      if (!mounted || generation != _onionSkinGeneration) {
        for (final createdImage in createdImages) {
          createdImage.dispose();
        }
        return;
      }

      nextImages.add(
        _ResolvedOnionSkinFrame(
          frameId: frame.frameId,
          image: image,
          opacity: frame.opacity,
        ),
      );
    }

    if (!mounted || generation != _onionSkinGeneration) {
      for (final createdImage in createdImages) {
        createdImage.dispose();
      }
      return;
    }

    final oldImages = _onionSkinImages;
    setState(() {
      _lastOnionSkinFrames = List<PixelCanvasOnionSkinFrame>.from(nextFrames);
      _onionSkinImages = nextImages;
    });

    for (final oldFrame in oldImages) {
      if (!reusedImages.contains(oldFrame.image)) {
        _disposeImageAfterFrame(oldFrame.image);
      }
    }
  }

  bool _sameOnionSkinFrames(
    List<PixelCanvasOnionSkinFrame> a,
    List<PixelCanvasOnionSkinFrame> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      final current = a[i];
      final next = b[i];
      if (current.opacity != next.opacity || !current.hasSameRasterData(next)) {
        return false;
      }
    }
    return true;
  }

  void _disposeBackgroundImage() {
    final previousImage = _backgroundImage;
    if (previousImage == null) {
      return;
    }

    _backgroundImage = null;
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
    _backgroundImage?.dispose();
    _backgroundImage = null;
    for (final frame in _onionSkinImages) {
      frame.image.dispose();
    }
    _onionSkinImages = const <_ResolvedOnionSkinFrame>[];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PixelCanvasSurfaceRenderWidget(
      gridWidth: widget.gridWidth,
      gridHeight: widget.gridHeight,
      backgroundImage: _backgroundImage,
      backgroundOpacity: widget.backgroundOpacity,
      backgroundScale: widget.backgroundScale,
      backgroundOffset: widget.backgroundOffset,
      onionSkinFrames: _onionSkinImages,
      child: widget.child,
    );
  }
}

class _PixelCanvasSurfaceRenderWidget extends SingleChildRenderObjectWidget {
  const _PixelCanvasSurfaceRenderWidget({
    required this.gridWidth,
    required this.gridHeight,
    required this.backgroundImage,
    required this.backgroundOpacity,
    required this.backgroundScale,
    required this.backgroundOffset,
    required this.onionSkinFrames,
    required super.child,
  });

  final int gridWidth;
  final int gridHeight;
  final ui.Image? backgroundImage;
  final double backgroundOpacity;
  final double backgroundScale;
  final Offset backgroundOffset;
  final List<_ResolvedOnionSkinFrame> onionSkinFrames;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPixelCanvasSurface(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      backgroundImage: backgroundImage,
      backgroundOpacity: backgroundOpacity,
      backgroundScale: backgroundScale,
      backgroundOffset: backgroundOffset,
      onionSkinFrames: onionSkinFrames,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderPixelCanvasSurface renderObject,
  ) {
    renderObject
      ..gridWidth = gridWidth
      ..gridHeight = gridHeight
      ..backgroundImage = backgroundImage
      ..backgroundOpacity = backgroundOpacity
      ..backgroundScale = backgroundScale
      ..backgroundOffset = backgroundOffset
      ..onionSkinFrames = onionSkinFrames;
  }
}

class _RenderPixelCanvasSurface extends RenderProxyBox {
  _RenderPixelCanvasSurface({
    required int gridWidth,
    required int gridHeight,
    ui.Image? backgroundImage,
    required double backgroundOpacity,
    required double backgroundScale,
    required Offset backgroundOffset,
    required List<_ResolvedOnionSkinFrame> onionSkinFrames,
  })  : _gridWidth = gridWidth,
        _gridHeight = gridHeight,
        _backgroundImage = backgroundImage,
        _backgroundOpacity = backgroundOpacity,
        _backgroundScale = backgroundScale,
        _backgroundOffset = backgroundOffset,
        _onionSkinFrames = onionSkinFrames;

  int _gridWidth;
  int get gridWidth => _gridWidth;
  set gridWidth(int value) {
    if (_gridWidth == value) return;
    _gridWidth = value;
    markNeedsPaint();
  }

  int _gridHeight;
  int get gridHeight => _gridHeight;
  set gridHeight(int value) {
    if (_gridHeight == value) return;
    _gridHeight = value;
    markNeedsPaint();
  }

  ui.Image? _backgroundImage;
  ui.Image? get backgroundImage => _backgroundImage;
  set backgroundImage(ui.Image? value) {
    if (_backgroundImage == value) return;
    _backgroundImage = value;
    markNeedsPaint();
  }

  double _backgroundOpacity;
  double get backgroundOpacity => _backgroundOpacity;
  set backgroundOpacity(double value) {
    if (_backgroundOpacity == value) return;
    _backgroundOpacity = value;
    markNeedsPaint();
  }

  double _backgroundScale;
  double get backgroundScale => _backgroundScale;
  set backgroundScale(double value) {
    if (_backgroundScale == value) return;
    _backgroundScale = value;
    markNeedsPaint();
  }

  Offset _backgroundOffset;
  Offset get backgroundOffset => _backgroundOffset;
  set backgroundOffset(Offset value) {
    if (_backgroundOffset == value) return;
    _backgroundOffset = value;
    markNeedsPaint();
  }

  List<_ResolvedOnionSkinFrame> _onionSkinFrames;
  List<_ResolvedOnionSkinFrame> get onionSkinFrames => _onionSkinFrames;
  set onionSkinFrames(List<_ResolvedOnionSkinFrame> value) {
    if (_sameResolvedOnionSkinFrames(_onionSkinFrames, value)) {
      return;
    }
    _onionSkinFrames = value;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (size.isEmpty) {
      return;
    }

    final rect = offset & size;
    _paintCanvasSurface(context.canvas, rect);
    if (child != null) {
      context.paintChild(child, offset);
    }
  }

  void _paintCanvasSurface(Canvas canvas, Rect rect) {
    _paintBaseFill(canvas, rect);
    _paintGrid(canvas, rect);
    _paintBackgroundImage(canvas, rect);
    _paintOnionSkinFrames(canvas, rect);
    _paintBorder(canvas, rect);
  }

  void _paintBaseFill(Canvas canvas, Rect rect) {
    if (rect.isEmpty) {
      return;
    }

    canvas.drawRect(rect, Paint()..color = Colors.white);
  }

  void _paintBorder(Canvas canvas, Rect rect) {
    if (rect.isEmpty) {
      return;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintGrid(Canvas canvas, Rect rect) {
    if (gridWidth <= 0 || gridHeight <= 0 || rect.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cellWidth = rect.width / gridWidth;
    final cellHeight = rect.height / gridHeight;

    for (var column = 0; column <= gridWidth; column++) {
      final x = rect.left + column * cellWidth;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    }

    for (var row = 0; row <= gridHeight; row++) {
      final y = rect.top + row * cellHeight;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _paintBackgroundImage(Canvas canvas, Rect rect) {
    final image = backgroundImage;
    if (image == null || backgroundOpacity <= 0 || rect.isEmpty) {
      return;
    }

    final outputSize = rect.size;
    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final fitted = applyBoxFit(BoxFit.cover, imageSize, outputSize);
    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );

    final offsetDelta = Offset(
      backgroundOffset.dx * rect.width,
      backgroundOffset.dy * rect.height,
    );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: backgroundOpacity)
      ..filterQuality = FilterQuality.none;

    canvas.save();
    canvas.clipRect(rect);
    canvas.translate(
      rect.center.dx + offsetDelta.dx,
      rect.center.dy + offsetDelta.dy,
    );
    canvas.scale(backgroundScale);
    canvas.drawImageRect(
      image,
      sourceRect,
      Rect.fromCenter(
        center: Offset.zero,
        width: fitted.destination.width,
        height: fitted.destination.height,
      ),
      paint,
    );
    canvas.restore();
  }

  void _paintOnionSkinFrames(Canvas canvas, Rect rect) {
    if (_onionSkinFrames.isEmpty || rect.isEmpty) {
      return;
    }

    for (final frame in _onionSkinFrames) {
      final sourceRect = Rect.fromLTWH(
        0,
        0,
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: frame.opacity)
        ..filterQuality = FilterQuality.none;
      canvas.drawImageRect(frame.image, sourceRect, rect, paint);
    }
  }

  bool _sameResolvedOnionSkinFrames(
    List<_ResolvedOnionSkinFrame> a,
    List<_ResolvedOnionSkinFrame> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      final current = a[i];
      final next = b[i];
      if (current.frameId != next.frameId ||
          current.image != next.image ||
          current.opacity != next.opacity) {
        return false;
      }
    }
    return true;
  }
}
