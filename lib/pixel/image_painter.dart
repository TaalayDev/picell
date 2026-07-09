import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final double? opacity;
  final BoxFit fit;

  ImagePainter(this.image, {this.opacity, this.fit = BoxFit.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = fit == BoxFit.contain ? _containedRect(size) : Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint();
    if (opacity != null) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity!);
    }
    canvas.drawImageRect(image, src, dst, paint);
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
