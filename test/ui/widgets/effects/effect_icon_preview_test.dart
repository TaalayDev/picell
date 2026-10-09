import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/services/effect_icon_export_service.dart';
import 'package:picell/pixel/services/effect_preview_cache.dart';
import 'package:picell/ui/widgets/effects/effect_icon_preview.dart';

void main() {
  setUp(() {
    EffectPreviewCache.instance.clear();
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
    test('getFirstFrameImage renders and caches image bytes', () async {
      final cache = EffectPreviewCache.instance;
      final effect = BrightnessEffect();

      expect(cache.getCachedFirstFrame(effect), isNull);
      final bytes = await cache.getFirstFrameImage(effect);
      expect(bytes, isNotEmpty);
      expect(cache.getCachedFirstFrame(effect), equals(bytes));

      // Subsequent call should return cached bytes directly
      final cachedAgain = await cache.getFirstFrameImage(effect);
      expect(identical(bytes, cachedAgain), isTrue);
    });

    test('getAnimatedImage renders and caches animated GIF bytes', () async {
      final cache = EffectPreviewCache.instance;
      final effect = FireEffect();

      expect(cache.getCachedAnimated(effect), isNull);
      final bytes = await cache.getAnimatedImage(effect);
      expect(bytes, isNotEmpty);
      expect(cache.getCachedAnimated(effect), equals(bytes));

      // Subsequent call should return cached bytes directly
      final cachedAgain = await cache.getAnimatedImage(effect);
      expect(identical(bytes, cachedAgain), isTrue);
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
