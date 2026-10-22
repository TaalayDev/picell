import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/animation_frame_model.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effect_target.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effect_animation_generator_dialog.dart';
import 'package:picell/ui/widgets/effects/pixlel_preview_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The big preview, not the thumbnails on the layer chips.
Rect largestPreview(WidgetTester tester) {
  final rects = find
      .byWidgetPredicate((w) => w is CustomPaint && w.painter is PixelPreviewPainter)
      .evaluate()
      .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)));
  return rects.reduce((a, b) => a.width * a.height >= b.width * b.height ? a : b);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  Layer layer(int id, String name) => Layer(
        layerId: id,
        id: 'l$id',
        name: name,
        pixels: Uint32List.fromList([0xff808080, 0, 0, 0xff202020]),
      );

  Future<({List<AnimationFrame>? frames, EffectGenerationResult? result})> run(
    WidgetTester tester, {
    Effect? animated,
    Future<void> Function()? interact,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    List<AnimationFrame>? frames;
    EffectGenerationResult? result;
    final effect = animated ?? WipeEffect();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
                context,
                effect: effect,
                effects: [effect],
                effectIndex: 0,
                layerWidth: 2,
                layerHeight: 2,
                frameLayers: [layer(1, 'Sky'), layer(2, 'Hero'), layer(3, 'Fog')],
                activeLayerIndex: 1,
                initialLayerIndices: const [0, 1],
                onGenerated: (f, r) async {
                  frames = f;
                  result = r;
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await interact?.call();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump();
    return (frames: frames, result: result);
  }

  testWidgets('lists the selected layers and offers the rest', (tester) async {
    await run(tester, interact: () async {
      expect(tester.takeException(), isNull);
      expect(find.text('Applying to layers'), findsOneWidget);
      expect(find.text('Sky'), findsOneWidget);
      expect(find.text('Hero'), findsOneWidget);
      expect(find.text('Fog'), findsNothing);
      expect(find.text('Add layer'), findsOneWidget);
      // The layer being edited can't be removed, the other can.
      final chips = tester.widgetList<InputChip>(find.byType(InputChip)).toList();
      expect(chips, hasLength(2));
      expect(chips.where((c) => c.onDeleted != null), hasLength(1));
    });
  });

  testWidgets('combined mode keeps layers for position-only effects', (tester) async {
    final out = await run(tester);
    expect(out.result!.flattened, isFalse);
    expect(out.result!.layerIds, [1, 2]);
    expect(find.text('The layers move together as one image and stay on their own layers.'), findsOneWidget);
  });

  testWidgets('combined mode flattens onto one layer for content-aware effects', (tester) async {
    final out = await run(tester, animated: SquashStretchEffect());
    expect(out.result!.flattened, isTrue);
    expect(out.result!.layerIds, [1, 2]);
    expect(out.result!.activeLayerId, 2);
    expect(out.frames!.first.layers, hasLength(2));
  });

  testWidgets('separate mode keeps the layers apart', (tester) async {
    final out = await run(tester, interact: () async {
      await tester.tap(find.text('Separate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    });
    expect(out.result!.flattened, isFalse);
    expect(out.frames!.first.layers, hasLength(2));
  });

  testWidgets('adding a layer includes it in the result', (tester) async {
    final out = await run(tester, interact: () async {
      await tester.tap(find.text('Add layer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fog').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    });
    expect(out.result!.layerIds, [1, 2, 3]);
    expect(find.text('Add layer'), findsNothing);
  });

  group('layout', () {
    testWidgets('is full screen with the preview filling the left side', (tester) async {
      await run(tester, interact: () async {
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(tester.getSize(find.byType(Dialog)), screen);

        final preview = largestPreview(tester);
        final params = tester.getRect(find.text('Applying to layers'));
        expect(preview.right, lessThan(params.left)); // preview left, properties right
        expect(preview.height, greaterThan(screen.height * 0.6)); // fits the height
        expect(preview.width, closeTo(preview.height, 1)); // keeps the image's shape
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('stacks the preview over the settings on a phone', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final effect = WipeEffect();
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
                  context,
                  effect: effect,
                  effects: [effect],
                  effectIndex: 0,
                  layerWidth: 2,
                  layerHeight: 2,
                  layerPixels: Uint32List.fromList(List.filled(4, 0xff808080)),
                  onFramesGenerated: (_) async {},
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      final preview = largestPreview(tester);
      expect(preview.bottom, lessThan(tester.getRect(find.text('Animation Settings')).top));
      expect(tester.takeException(), isNull);
    });
  });
}
