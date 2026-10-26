import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import '../../data/models/layer.dart';
import '../../data/models/rig/rig.dart';
import '../../gifencoder/gifencoder.dart' as gifencoder;
import '../pixel_utils.dart';
import 'rig_baker.dart';

/// What [encodeRigGif] needs, in a form an isolate can receive.
typedef RigGifJob = ({List<Uint32List> frames, int width, int height, int scale, int fps});

/// Encodes already-composited frames as an animated GIF, each pixel enlarged
/// [scale] times (nearest neighbour, so pixel art stays crisp).
///
/// Top-level so it can run on an isolate. Transparent pixels stay
/// transparent; partly transparent ones are snapped to opaque or clear,
/// since GIF only has 1-bit transparency.
Uint8List encodeRigGif(RigGifJob job) {
  final outWidth = job.width * job.scale, outHeight = job.height * job.scale;
  final gif = gifencoder.GifBuffer(outWidth, outHeight);

  for (final frame in job.frames) {
    // Layer opacity leaves colours scaled by their alpha; undo that for the
    // pixels that survive the 1-bit cut, so they keep their real colour.
    final straight = Uint32List.fromList(frame);
    for (var i = 0; i < straight.length; i++) {
      final pixel = straight[i];
      final a = (pixel >> 24) & 0xFF;
      if (a == 0 || a == 255) continue;
      if (a < 128) {
        straight[i] = 0;
        continue;
      }
      final k = 255.0 / a;
      final r = (((pixel >> 16) & 0xFF) * k).round().clamp(0, 255);
      final g = (((pixel >> 8) & 0xFF) * k).round().clamp(0, 255);
      final b = ((pixel & 0xFF) * k).round().clamp(0, 255);
      straight[i] = (255 << 24) | (r << 16) | (g << 8) | b;
    }

    final sized = job.scale == 1
        ? straight
        : PixelUtils.resizeWithImagePackage(
            straight,
            job.width,
            job.height,
            outWidth,
            outHeight,
            interpolation: img.Interpolation.nearest,
          );
    gif.add(PixelUtils.aarrggbbToRgbaForGif(sized));
  }
  return Uint8List.fromList(gif.build(job.fps));
}

/// Renders a rig's clip as a GIF, to look at what baking will produce.
abstract final class RigGif {
  /// The enlargement that brings a [width] x [height] sprite to about
  /// [target] pixels on its longer side (never below 1, never past 1024).
  static int scaleFor(int width, int height, {int target = 256}) {
    final longest = math.max(width, height);
    return (target ~/ longest).clamp(1, math.max(1, 1024 ~/ longest));
  }

  /// Bakes [rig]'s selected clip against [restLayers] and encodes it. Uses the
  /// rig as it is now, unsaved edits included. The encoding runs on an
  /// isolate. Throws a [StateError] if the rig has nothing to animate.
  static Future<Uint8List> render({
    required Rig rig,
    required List<Layer> restLayers,
    required int width,
    required int height,
    int target = 256,
  }) async {
    if (rig.clips.isEmpty ||
        (rig.activeClip!.keyframes.isEmpty &&
            rig.activeClip!.ikKeyframes.isEmpty &&
            rig.activeClip!.orderKeyframes.isEmpty &&
            rig.activeClip!.freezes.isEmpty)) {
      throw StateError('The rig has no keyframes to preview.');
    }
    final clip = rig.activeClip!;
    final frames = RigBaker(rig: rig, width: width, height: height, layers: restLayers).bakeClip(clip);
    return compute(encodeRigGif, (
      frames: frames,
      width: width,
      height: height,
      scale: scaleFor(width, height, target: target),
      fps: clip.fps,
    ));
  }
}
