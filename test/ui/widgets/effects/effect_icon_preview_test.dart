import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/services/effect_icon_export_service.dart';
import 'package:picell/pixel/services/effect_preview_cache.dart';
import 'package:picell/ui/widgets/effects/effect_icon_preview.dart';

void main() {
  late Directory tempTestDir;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('effect_cache_test_');
    EffectPreviewCache.instance.setCustomCacheDirectory(tempTestDir);
    await EffectPreviewCache.instance.clear(deleteFiles: true);
  });

  tearDown(() async {
    await EffectPreviewCache.instance.clear(deleteFiles: true);
    if (tempTestDir.existsSync()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  group('EffectIconExportService', () {
    test('renderPreviewFrames returns 1 frame for static effect', () async {
      const service = EffectIconExportService();
      final frames = await service.renderPreviewFrames(BrightnessEffect());
      expect(frames.length, 1);
      expect(frames.first.length, EffectIconExportService.canvasSize * EffectIconExportService.canvasSize);
    });

    test('renderPreviewFrames returns animationFrameCount frames for animated effect', () async {
      const service = EffectIconExportService();
      final frames = await service.renderPreviewFrames(FireEffect());
      expect(frames.length, EffectIconExportService.animationFrameCount);
      for (final frame in frames) {
        expect(frame.length, EffectIconExportService.canvasSize * EffectIconExportService.canvasSize);
      }
    });
  });

  group('EffectPreviewCache', () {
    test('getFirstFrameImage renders, caches in memory, and saves to file for reuse', () async {
      final cache = EffectPreviewCache.instance;
      final effect = BrightnessEffect();

      expect(cache.getCachedFirstFrame(effect), isNull);
      final bytes = await cache.getFirstFrameImage(effect);
      expect(bytes, isNotEmpty);
      expect(cache.getCachedFirstFrame(effect), equals(bytes));

      // Verify file was written to disk
      final file = await cache.getFirstFrameFile(effect);
      expect(file, isNotNull);
      expect(await file!.exists(), isTrue);
      final fileBytes = await file.readAsBytes();
      expect(fileBytes, equals(bytes));

      // Clear memory cache only (simulating app restart)
      await cache.clear(deleteFiles: false);
      expect(cache.getCachedFirstFrame(effect), isNull);
      expect(await file.exists(), isTrue);

      // Next call should load directly from the saved file on disk
      final reusedBytes = await cache.getFirstFrameImage(effect);
      expect(reusedBytes, equals(fileBytes));
      expect(cache.getCachedFirstFrame(effect), equals(reusedBytes));
    });

    test('getAnimatedImage renders, caches in memory, and saves to file for reuse', () async {
      final cache = EffectPreviewCache.instance;
      final effect = FireEffect();

      expect(cache.getCachedAnimated(effect), isNull);
      final bytes = await cache.getAnimatedImage(effect);
      expect(bytes, isNotEmpty);
      expect(cache.getCachedAnimated(effect), equals(bytes));

      // Verify animated GIF file was written to disk
      final file = await cache.getAnimatedFile(effect);
      expect(file, isNotNull);
      expect(await file!.exists(), isTrue);
      final fileBytes = await file.readAsBytes();
      expect(fileBytes, equals(bytes));

      // Clear memory cache only (simulating app restart)
      await cache.clear(deleteFiles: false);
      expect(cache.getCachedAnimated(effect), isNull);
      expect(await file.exists(), isTrue);

      // Next call should load directly from the saved GIF file on disk
      final reusedBytes = await cache.getAnimatedImage(effect);
      expect(reusedBytes, equals(fileBytes));
      expect(cache.getCachedAnimated(effect), equals(reusedBytes));
    });

    test('clear(deleteFiles: true) deletes cached files from disk', () async {
      final cache = EffectPreviewCache.instance;
      final effect = BrightnessEffect();
      await cache.getFirstFrameImage(effect);

      final file = await cache.getFirstFrameFile(effect);
      expect(await file!.exists(), isTrue);

      await cache.clear(deleteFiles: true);
      expect(await file.exists(), isFalse);
    });
  });

  group('EffectIconPreview widget', () {
    testWidgets('renders static effect as image without AnimatedBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectIconPreview(
              effect: BrightnessEffect(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final imageFinder = find.byKey(const ValueKey('effect-icon-preview-brightness'));
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<MemoryImage>());

      final animatedBuilderFinder = find.descendant(
        of: find.byType(EffectIconPreview),
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderFinder, findsNothing);
    });

    testWidgets('renders animated effect with first frame initially then transitions to animated image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectIconPreview(
              effect: FireEffect(),
            ),
          ),
        ),
      );

      // Pump enough time for first frame image to render
      await tester.pump(const Duration(milliseconds: 50));

      final imageFinder = find.byKey(const ValueKey('effect-icon-preview-fire'));
      expect(imageFinder, findsOneWidget);

      final initialImage = tester.widget<Image>(imageFinder);
      final initialMemoryImage = initialImage.image as MemoryImage;
      expect(initialMemoryImage.bytes, isNotEmpty);

      // Verify no AnimatedBuilder is used (eliminating UI thread lag)
      final animatedBuilderFinder = find.descendant(
        of: find.byType(EffectIconPreview),
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderFinder, findsNothing);

      // Pump enough for background animated GIF rendering to finish
      await tester.pump(const Duration(milliseconds: 800));

      final updatedImage = tester.widget<Image>(imageFinder);
      final updatedMemoryImage = updatedImage.image as MemoryImage;
      expect(updatedMemoryImage.bytes, isNotEmpty);

      // Cached animated image is now stored in EffectPreviewCache
      expect(EffectPreviewCache.instance.getCachedAnimated(FireEffect()), isNotNull);
    });

    testWidgets('subsequent render uses synchronous cache immediately', (tester) async {
      // Pre-populate cache
      final effect = BrightnessEffect();
      await EffectPreviewCache.instance.getFirstFrameImage(effect);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectIconPreview(
              effect: effect,
            ),
          ),
        ),
      );

      // Should render image immediately without waiting for pump duration
      await tester.pump();

      final imageFinder = find.byKey(const ValueKey('effect-icon-preview-brightness'));
      expect(imageFinder, findsOneWidget);
    });
  });
}
