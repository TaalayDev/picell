import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/canvas/canvas_controller.dart';
import 'package:picell/pixel/canvas/layer_cache_manager.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/pixel_point.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stroke preview applies layer effects once to the raw pixels', () async {
    final layer = Layer(
      layerId: 1,
      id: 'layer',
      name: 'Layer',
      pixels: Uint32List.fromList([
        0xff202020,
        0,
        0,
        0,
      ]),
      effects: [
        BrightnessEffect({'value': 0.2})
      ],
    );
    final cache = LayerCacheManager(width: 2, height: 2);
    final controller = PixelCanvasController(
      width: 2,
      height: 2,
      layers: [layer],
      currentLayerIndex: 0,
      cacheManager: cache,
    );

    controller.setPreviewPixels([PixelPoint(1, 1, color: 0xff404040)]);
    expect(controller.hasEffectPreview, isTrue);

    for (var attempt = 0;
        attempt < 50 && !controller.hasFreshLivePreviewImage;
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(controller.hasFreshLivePreviewImage, isTrue);

    final imageBytes = await controller.livePreviewImage!
        .toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = imageBytes!.buffer.asUint8List();
    // Both the old pixel and the new stroke should be brightened exactly once.
    expect(bytes.sublist(0, 4), [83, 83, 83, 255]);
    expect(bytes.sublist(12, 16), [115, 115, 115, 255]);

    controller.setPreviewPixels([PixelPoint(1, 0, color: 0xff404040)]);
    expect(controller.hasFreshLivePreviewImage, isFalse);
    expect(controller.hasLivePreviewImage, isTrue);

    controller.clearPreviewPixels();
    controller.dispose();
    cache.dispose();
  });

  test('cache hides an old layer image while its replacement is built',
      () async {
    final cache = LayerCacheManager(width: 1, height: 1);
    cache.updateLayer(1, Uint32List.fromList([0xff202020]), 1, 1);
    for (var attempt = 0;
        attempt < 50 && cache.getLayerImage(1) == null;
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(cache.getLayerImage(1), isNotNull);

    cache.updateLayer(1, Uint32List.fromList([0xff808080]), 1, 1);
    expect(cache.getLayerImage(1), isNull);
    for (var attempt = 0;
        attempt < 50 && cache.getLayerImage(1) == null;
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final bytes = (await cache
            .getLayerImage(1)!
            .toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    expect(bytes.sublist(0, 4), [128, 128, 128, 255]);
    cache.dispose();
  });

  test('noise stays stable when another pixel is drawn', () {
    final effect = NoiseEffect({'amount': 0.5});
    final before = effect.apply(
      Uint32List.fromList([0, 0xff808080]),
      2,
      1,
    );
    final after = effect.apply(
      Uint32List.fromList([0xff808080, 0xff808080]),
      2,
      1,
    );
    expect(after[1], before[1]);
    expect(effect.apply(Uint32List.fromList([0, 0xff808080]), 2, 1), before);
  });
}
