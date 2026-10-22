import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_gif.dart';

import 'rig_test_support.dart';

void main() {
  const w = 8, h = 8;

  Uint32List frameWith(int x, int y, int color) => Uint32List(w * h)..[y * w + x] = color;

  test('scaleFor brings small sprites to about the target size and never goes below 1', () {
    expect(RigGif.scaleFor(16, 16), 16);
    expect(RigGif.scaleFor(64, 32), 4);
    expect(RigGif.scaleFor(300, 300), 1, reason: 'already bigger than the target');
    expect(RigGif.scaleFor(8, 8, target: 4096), 128, reason: 'capped at 1024 pixels');
  });

  test('frames become an animated GIF with the sprite enlarged', () {
    final bytes = encodeRigGif((
      frames: [frameWith(1, 1, 0xFFFF0000), frameWith(5, 2, 0xFF00FF00), frameWith(3, 6, 0xFF0000FF)],
      width: w,
      height: h,
      scale: 4,
      fps: 10,
    ));

    expect(String.fromCharCodes(bytes.sublist(0, 6)), 'GIF89a');
    final gif = img.decodeGif(bytes)!;
    expect(gif.numFrames, 3);
    expect((gif.width, gif.height), (32, 32));

    // The first frame's red pixel is a 4x4 block at (4,4); the rest is clear.
    final first = gif.frames[0];
    for (final (x, y) in [(4, 4), (7, 7), (5, 6)]) {
      final p = first.getPixel(x, y);
      expect((p.r, p.g, p.b), (255, 0, 0), reason: 'inside the block at $x,$y');
    }
    expect(first.getPixel(0, 0).a, 0, reason: 'transparent stays transparent');
    expect(first.getPixel(8, 4).a, 0);
  });

  test('without scaling the size is unchanged', () {
    final bytes = encodeRigGif((frames: [frameWith(0, 0, 0xFFFFFFFF), frameWith(1, 1, 0xFFFFFFFF)], width: w, height: h, scale: 1, fps: 12));
    final gif = img.decodeGif(bytes)!;
    expect((gif.width, gif.height), (w, h));
    expect(gif.numFrames, 2);
  });

  test('half-transparent pixels are cut to opaque or clear, keeping their colour', () {
    final faint = frameWith(0, 0, 0x40FF0000); // alpha 64: below the cut
    final solidish = frameWith(1, 0, 0x80804020); // alpha 128, colours scaled by it
    final gif = img.decodeGif(encodeRigGif((frames: [faint, solidish], width: w, height: h, scale: 1, fps: 10)))!;
    expect(gif.frames[0].getPixel(0, 0).a, 0);
    final p = gif.frames[1].getPixel(1, 0);
    expect(p.a, 255);
    // 0x80 / 0x80 -> ~0xFF red, 0x40 -> ~0x80 green (scaled back up by 255/128).
    expect(p.r, greaterThan(200));
  });

  group('render', () {
    Layer body() => Layer(
          layerId: 0,
          id: 'b',
          name: 'Body',
          pixels: parseGrid(['W.......', ...List.filled(7, '........')]),
          stableKey: 'body',
        );

    Rig rig({bool keys = true}) => Rig(
          id: 'r',
          stateId: 1,
          bones: const [Bone(id: 'root', name: 'root', head: Offset(0.5, 0.5), length: 2)],
          parts: const [RigPart(id: 'p', boneId: 'root', layerKey: 'body')],
          clips: [
            RigClip(id: 'main', name: 'x', length: 3, fps: 8, keyframes: [
              if (keys) const RigKeyframe(time: 0, boneId: 'root'),
              if (keys) const RigKeyframe(time: 2, boneId: 'root', translation: Offset(2, 0)),
            ]),
          ],
        );

    test('bakes the clip and returns one GIF frame per clip frame', () async {
      final bytes = await RigGif.render(rig: rig(), restLayers: [body()], width: w, height: h, target: 32);
      final gif = img.decodeGif(bytes)!;
      expect(gif.numFrames, 3);
      expect((gif.width, gif.height), (32, 32));
      // The body slides right: frame 3's white block starts at x = 2 * 4.
      expect(gif.frames[0].getPixel(0, 0).a, 255);
      expect(gif.frames[2].getPixel(0, 0).a, 0);
      expect(gif.frames[2].getPixel(8, 0).a, 255);
    });

    test('a rig with nothing keyed has nothing to preview', () async {
      await expectLater(
        RigGif.render(rig: rig(keys: false), restLayers: [body()], width: w, height: h),
        throwsStateError,
      );
      await expectLater(
        RigGif.render(rig: const Rig(id: 'r', stateId: 1), restLayers: [body()], width: w, height: h),
        throwsStateError,
      );
    });
  });
}
