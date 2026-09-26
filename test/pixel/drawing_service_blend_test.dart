import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/canvas/canvas_controller.dart';
import 'package:picell/pixel/canvas/layer_cache_manager.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/pixel_point.dart';
import 'package:picell/pixel/services/drawing_service.dart';
import 'package:picell/pixel/tools.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingService compositing', () {
    final service = DrawingService();

    test('50% opacity red over opaque white produces blended pink', () {
      final pixels = Uint32List.fromList([0xFFFFFFFF]);
      final result = service.setPixel(
        pixels: pixels,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        color: const Color(0x80FF0000),
      );
      expect(result[0], 0xFFFF7F7F);
    });

    test('0% opacity color over opaque pixel leaves existing pixel intact (does not erase)', () {
      final pixels = Uint32List.fromList([0xFF00FF00]);
      final result = service.setPixel(
        pixels: pixels,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        color: const Color(0x00FF0000),
      );
      expect(result[0], 0xFF00FF00);
    });

    test('50% opacity red over transparent empty pixel results in 50% red', () {
      final pixels = Uint32List.fromList([0x00000000]);
      final result = service.setPixel(
        pixels: pixels,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        color: const Color(0x80FF0000),
      );
      expect(result[0], 0x80FF0000);
    });

    test('50% opacity red over 50% opacity green blends colors and increases alpha', () {
      final pixels = Uint32List.fromList([0x8000FF00]);
      final result = service.setPixel(
        pixels: pixels,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        color: const Color(0x80FF0000),
      );
      final alpha = (result[0] >>> 24) & 0xFF;
      expect(alpha > 0x80, isTrue);
      expect(result[0], 0xC0AA5500);
    });

    test('eraser tool correctly clears pixel to 0', () {
      final pixels = Uint32List.fromList([0xFF00FF00]);
      final result = service.setPixel(
        pixels: pixels,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        color: const Color(0xFF000000),
        erase: true,
      );
      expect(result[0], 0);
    });

    test('fillPixelsMutable with point.color == 0 falls back to tool color if non-zero', () {
      final pixels = Uint32List.fromList([0x00000000]);
      service.fillPixelsMutable(
        pixels: pixels,
        points: [PixelPoint(0, 0, color: 0)],
        width: 1,
        color: const Color(0xFFFF0000),
      );
      expect(pixels[0], 0xFFFF0000);
    });
  });

  group('CanvasController preview and compositing', () {
    test('translucent preview stroke does not replace/erase base pixel', () async {
      final layer = Layer(
        layerId: 1,
        id: 'layer1',
        name: 'Layer 1',
        pixels: Uint32List.fromList([0xFFFFFFFF]), // opaque white
        effects: [BrightnessEffect({'value': 0.0})], // enable effect preview path
      );
      final cache = LayerCacheManager(width: 1, height: 1);
      final controller = PixelCanvasController(
        width: 1,
        height: 1,
        layers: [layer],
        currentLayerIndex: 0,
        cacheManager: cache,
      );

      // User draws with 50% opacity red
      controller.setPreviewPixels([
        PixelPoint(0, 0, color: 0x80FF0000),
      ]);

      for (var attempt = 0;
          attempt < 50 && !controller.hasFreshLivePreviewImage;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(controller.hasFreshLivePreviewImage, isTrue);

      final imageBytes = await controller.livePreviewImage!
          .toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = imageBytes!.buffer.asUint8List();
      // Opaque white was 255,255,255,255. 50% red is 255,0,0,128.
      // Blended RGBA: Red = 255, Green = 127, Blue = 127, Alpha = 255.
      expect(bytes[0], 255); // R
      expect(bytes[1], 127); // G
      expect(bytes[2], 127); // B
      expect(bytes[3], 255); // A (fully opaque, NOT translucent/erased!)

      controller.clearPreviewPixels();
      controller.dispose();
      cache.dispose();
    });

    test('0% opacity preview stroke does not erase base pixel in effect preview', () async {
      final layer = Layer(
        layerId: 1,
        id: 'layer1',
        name: 'Layer 1',
        pixels: Uint32List.fromList([0xFF00FF00]), // opaque green
        effects: [BrightnessEffect({'value': 0.0})],
      );
      final cache = LayerCacheManager(width: 1, height: 1);
      final controller = PixelCanvasController(
        width: 1,
        height: 1,
        layers: [layer],
        currentLayerIndex: 0,
        cacheManager: cache,
      );

      // User draws with 0% opacity (transparent)
      controller.setPreviewPixels([
        PixelPoint(0, 0, color: 0x00FF0000),
      ]);

      for (var attempt = 0;
          attempt < 50 && !controller.hasFreshLivePreviewImage;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(controller.hasFreshLivePreviewImage, isTrue);

      final imageBytes = await controller.livePreviewImage!
          .toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = imageBytes!.buffer.asUint8List();
      // Base green pixel should remain intact
      expect(bytes[0], 0);
      expect(bytes[1], 255);
      expect(bytes[2], 0);
      expect(bytes[3], 255);

      controller.clearPreviewPixels();
      controller.dispose();
      cache.dispose();
    });

    test('eraser tool correctly clears base pixel in effect preview', () async {
      final layer = Layer(
        layerId: 1,
        id: 'layer1',
        name: 'Layer 1',
        pixels: Uint32List.fromList([0xFF00FF00]), // opaque green
        effects: [BrightnessEffect({'value': 0.0})],
      );
      final cache = LayerCacheManager(width: 1, height: 1);
      final controller = PixelCanvasController(
        width: 1,
        height: 1,
        layers: [layer],
        currentLayerIndex: 0,
        cacheManager: cache,
      );
      controller.setCurrentTool(PixelTool.eraser);

      controller.setPreviewPixels([
        PixelPoint(0, 0, color: 0x00000000),
      ]);

      for (var attempt = 0;
          attempt < 50 && !controller.hasFreshLivePreviewImage;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(controller.hasFreshLivePreviewImage, isTrue);

      final imageBytes = await controller.livePreviewImage!
          .toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = imageBytes!.buffer.asUint8List();
      // Cleared pixel has alpha 0
      expect(bytes[3], 0);

      controller.clearPreviewPixels();
      controller.dispose();
      cache.dispose();
    });

    test('multi-layer updateCachedPixels composites translucent layer over base layer', () {
      final layerBottom = Layer(
        layerId: 1,
        id: 'l1',
        name: 'Layer 1',
        pixels: Uint32List.fromList([0xFFFFFFFF]), // opaque white
      );
      final layerTop = Layer(
        layerId: 2,
        id: 'l2',
        name: 'Layer 2',
        pixels: Uint32List.fromList([0x80FF0000]), // 50% red
      );
      final cache = LayerCacheManager(width: 1, height: 1);
      final controller = PixelCanvasController(
        width: 1,
        height: 1,
        layers: [layerBottom, layerTop],
        currentLayerIndex: 1,
        cacheManager: cache,
      );
      controller.initialize([layerBottom, layerTop]);

      // cachedPixels should blend 50% red over opaque white = 0xFFFF7F7F
      expect(controller.cachedPixels[0], 0xFFFF7F7F);

      controller.dispose();
      cache.dispose();
    });
  });
}
