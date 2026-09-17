import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/pixel/effects/effect_animation_renderer.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effect_list_item.dart';
import 'package:picell/ui/widgets/effects/effect_animation_generator_dialog.dart';
import 'package:picell/data/models/animation_frame_model.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test('animation renders different frames using the ordered effect stack',
      () async {
    final pixels = Uint32List.fromList(List.filled(4, 0xff202020));
    final effects = <Effect>[
      BrightnessEffect({'value': 0.2}),
      WipeEffect(),
    ];

    final first = await EffectAnimationRenderer.renderFrame(
      pixels: pixels,
      width: 2,
      height: 2,
      effects: effects,
      animatedEffectIndex: 1,
      progress: 0,
    );
    final last = await EffectAnimationRenderer.renderFrame(
      pixels: pixels,
      width: 2,
      height: 2,
      effects: effects,
      animatedEffectIndex: 1,
      progress: 1,
    );

    expect(first, isNot(last));
    expect(last, Uint32List.fromList(List.filled(4, 0xff535353)));
    expect(effects.last.parameters['progress'], 0.0);
  });

  test('every animated effect produces changing frames', () async {
    final unchanged = <String>[];
    final pixels = Uint32List.fromList([
      for (var y = 0; y < 32; y++)
        for (var x = 0; x < 32; x++)
          y < 16 ? 0 : 0xff000000 | (x * 8 << 16) | (y * 8 << 8) | 0x40,
    ]);
    for (final type in EffectType.values) {
      final effect = EffectsManager.createEffect(type);
      if (!effect.isAnimation) continue;
      Uint32List? first;
      var changed = false;
      for (final progress in [0.0, 0.12, 0.25, 0.37, 0.5, 0.62, 0.75, 0.87]) {
        final frame = await EffectAnimationRenderer.renderFrame(
          pixels: pixels,
          width: 32,
          height: 32,
          effects: [effect],
          animatedEffectIndex: 0,
          progress: progress,
        );
        first ??= frame;
        if (!listEquals(first, frame)) {
          changed = true;
          break;
        }
      }
      if (!changed) {
        unchanged.add(type.name);
      }
    }
    expect(unchanged, isEmpty);
  });

  testWidgets('animated effect exposes a generate action', (tester) async {
    var animateCalls = 0;
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
        body: EffectListItem(
          effect: WipeEffect(),
          isSelected: false,
          onSelect: () {},
          onEdit: () {},
          onRemove: () {},
          onAnimate: () => animateCalls++,
        ),
      ),
    )));

    await tester.tap(find.byIcon(Icons.movie_creation_outlined));
    expect(animateCalls, 1);
  });

  testWidgets('generator sends playable frames to its save callback',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    List<AnimationFrame>? saved;
    final effect = WipeEffect();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () =>
                EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
              context,
              effect: effect,
              effects: [effect],
              effectIndex: 0,
              layerWidth: 2,
              layerHeight: 2,
              layerPixels: Uint32List.fromList(List.filled(4, 0xff808080)),
              onFramesGenerated: (frames) async {
                saved = frames;
              },
            ),
            child: const Text('Open generator'),
          );
        }),
      ),
    )));

    await tester.tap(find.text('Open generator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.length, greaterThan(1));
    expect(saved!.every((frame) => frame.duration > 0), isTrue);
    expect(
        listEquals(saved!.first.layers.single.pixels,
            saved!.last.layers.single.pixels),
        isFalse);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('generator fits a $width px mobile viewport', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final effect = WipeEffect();
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.defaultTheme.themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: Builder(builder: (context) {
              return TextButton(
                onPressed: () =>
                    EffectAnimationGeneratorDialog.showEffectAnimationGenerator(
                  context,
                  effect: effect,
                  effects: [effect],
                  effectIndex: 0,
                  layerWidth: 2,
                  layerHeight: 2,
                  layerPixels: Uint32List.fromList(List.filled(4, 0xff808080)),
                  onFramesGenerated: (_) async {},
                ),
                child: const Text('Open generator'),
              );
            }),
          ),
        ),
      ));
      await tester.tap(find.text('Open generator'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.byType(EffectAnimationGeneratorDialog), findsOneWidget);
      final dialogRect = tester.getRect(find.byType(Dialog));
      final buttonRect = tester.getRect(find.widgetWithText(
        ElevatedButton,
        'Generate Frames',
      ));
      expect(dialogRect.width, greaterThan(width - 24));
      expect(buttonRect.left, greaterThanOrEqualTo(dialogRect.left));
      expect(buttonRect.right, lessThanOrEqualTo(dialogRect.right));
      expect(tester.getSize(find.textContaining('frames generated')).width,
          greaterThan(100));
      final title = tester.widget<Text>(find.text('Generate Animation Frames'));
      expect(title.style?.color,
          AppTheme.defaultTheme.themeData.colorScheme.onSurface);
    });
  }
}
