import 'dart:typed_data';
import 'dart:ui';

class ClipboardPixelPlacement {
  const ClipboardPixelPlacement({
    required this.pixels,
    required this.offset,
  });

  final Uint32List pixels;
  final Offset offset;
}

/// Places source-canvas pixels on a target canvas without resampling.
///
/// Equal-sized canvases preserve coordinates. Different sizes are centered,
/// and pixels outside the target bounds are clipped.
ClipboardPixelPlacement placeClipboardPixels({
  required Uint32List source,
  required int sourceWidth,
  required int sourceHeight,
  required int targetWidth,
  required int targetHeight,
}) {
  final target = Uint32List(targetWidth * targetHeight);
  final offsetX = ((targetWidth - sourceWidth) / 2).floor();
  final offsetY = ((targetHeight - sourceHeight) / 2).floor();

  for (var sourceY = 0; sourceY < sourceHeight; sourceY++) {
    final targetY = sourceY + offsetY;
    if (targetY < 0 || targetY >= targetHeight) continue;

    for (var sourceX = 0; sourceX < sourceWidth; sourceX++) {
      final targetX = sourceX + offsetX;
      if (targetX < 0 || targetX >= targetWidth) continue;

      final sourceIndex = sourceY * sourceWidth + sourceX;
      if (sourceIndex >= source.length) continue;
      target[targetY * targetWidth + targetX] = source[sourceIndex];
    }
  }

  return ClipboardPixelPlacement(
    pixels: target,
    offset: Offset(offsetX.toDouble(), offsetY.toDouble()),
  );
}
