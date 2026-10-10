import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final double? opacity;
  final BoxFit fit;

  ImagePainter(this.image, {this.opacity, this.fit = BoxFit.fill});

  @override
  void paint(Canvas canvas, Size size) {
    var src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    var dst = Rect.fromLTWH(0, 0, size.width, size.height);
    switch (fit) {
      case BoxFit.contain:
        dst = _containedRect(size);
      case BoxFit.cover:
        src = _coveredSource(size);
      default:
        break;
    }
    final paint = Paint();
    if (opacity != null) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity!);
    }
    canvas.drawImageRect(image, src, dst, paint);
  }

  /// Centered sub-rect of the image that fills [size] at the box's aspect
  /// ratio — the excess is cropped instead of the image being stretched.
  Rect _coveredSource(Size size) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    if (imageWidth <= 0 || imageHeight <= 0 || size.isEmpty) {
      return Rect.fromLTWH(0, 0, imageWidth, imageHeight);
    }

    final boxRatio = size.width / size.height;
    final imageRatio = imageWidth / imageHeight;
    if (imageRatio > boxRatio) {
      final w = imageHeight * boxRatio;
      return Rect.fromLTWH((imageWidth - w) / 2, 0, w, imageHeight);
    }
    final h = imageWidth / boxRatio;
    return Rect.fromLTWH(0, (imageHeight - h) / 2, imageWidth, h);
  }

  /// Largest centered rect that preserves the image's aspect ratio within
  /// [size] — used so clamped-aspect card slots don't stretch pixel art.
  Rect _containedRect(Size size) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    if (imageWidth <= 0 || imageHeight <= 0) {
      return Rect.fromLTWH(0, 0, size.width, size.height);
    }

    final scale = (size.width / imageWidth < size.height / imageHeight)
        ? size.width / imageWidth
        : size.height / imageHeight;
    final w = imageWidth * scale;
    final h = imageHeight * scale;
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DefaultPixelPainter extends CustomPainter {
  final List<List<Color>> pixels;
  final double pixelSize;

  DefaultPixelPainter(this.pixels, this.pixelSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (var y = 0; y < pixels.length; y++) {
      for (var x = 0; x < pixels[y].length; x++) {
        final pixel = pixels[y][x];
        final paint = Paint()..color = pixel;
        final rect = Rect.fromLTWH(
          x * pixelSize,
          y * pixelSize,
          pixelSize,
          pixelSize,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
