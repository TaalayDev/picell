import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/services/effect_icon_export_service.dart';
import 'package:picell/ui/widgets/effects/effect_icon_preview.dart';
import 'package:picell/ui/widgets/effects/pixlel_preview_painter.dart';

void main() {
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

  group('EffectIconPreview widget', () {
    testWidgets('renders static effect without AnimatedBuilder', (tester) async {
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

      final customPaintFinder = find.byKey(const ValueKey('effect-icon-preview-brightness'));
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.painter, isA<PixelPreviewPainter>());
      final animatedBuilderFinder = find.descendant(
        of: find.byType(EffectIconPreview),
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderFinder, findsNothing);
    });

    testWidgets('renders animated effect with AnimatedBuilder and cycles frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectIconPreview(
              effect: FireEffect(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final customPaintFinder = find.byKey(const ValueKey('effect-icon-preview-fire'));
      expect(customPaintFinder, findsOneWidget);

      final animatedBuilderFinder = find.descendant(
        of: find.byType(EffectIconPreview),
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilderFinder, findsOneWidget);

      final customPaint1 = tester.widget<CustomPaint>(customPaintFinder);
      final painter1 = customPaint1.painter as PixelPreviewPainter;
      final initialPixels = painter1.pixels;

      // Advance by half the animation duration (500ms)
      await tester.pump(const Duration(milliseconds: 500));

      final customPaint2 = tester.widget<CustomPaint>(customPaintFinder);
      final painter2 = customPaint2.painter as PixelPreviewPainter;
      final midPixels = painter2.pixels;

      expect(identical(initialPixels, midPixels), isFalse);
    });
  });
}
