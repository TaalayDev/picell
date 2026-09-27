import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/providers/pixel_canvas_provider.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/ui/widgets/effects/effect_list_item.dart';
import 'package:picell/ui/widgets/panel/desktop_side_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('side panel uses icon-only tabs and reveals used workspaces',
      (tester) async {
    final currentTool = ValueNotifier(PixelTool.pencil);
    addTearDown(currentTool.dispose);

    final project = Project(
      id: 51,
      name: 'Side panel test',
      width: 32,
      height: 32,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
      frames: [
        AnimationFrame(
          id: 1,
          stateId: 0,
          name: 'Frame',
          duration: 100,
          layers: [
            Layer(
              layerId: 1,
              id: 'layer',
              name: 'Layer',
              order: 0,
              pixels: Uint32List(32 * 32),
              effects: [
                BrightnessEffect(),
                GlitchEffect(),
                WoodEffect(),
                PulseEffect(),
                FireEffect(),
              ],
            ),
          ],
        ),
      ],
    );

    PixelCanvasNotifier? notifier;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(pixelCanvasNotifierProvider(project));
                notifier =
                    ref.read(pixelCanvasNotifierProvider(project).notifier);
                return SizedBox(
                  height: 800,
                  child: DesktopSidePanel(
                    width: project.width,
                    height: project.height,
                    state: state,
                    notifier: notifier!,
                    currentTool: currentTool,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('side-panel-tab-layers')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('side-panel-tab-filters')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('side-panel-tab-materials')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('side-panel-tab-animation')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('side-panel-tab-generators')), findsNothing);
    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('side-panel-tab-filters')),
    );
    await tester.pumpAndSettle();
    final filterItems =
        tester.widgetList<EffectListItem>(find.byType(EffectListItem)).toList();
    expect(
        filterItems.map((item) => item.effect.type), [EffectType.brightness, EffectType.glitch]);

    final animationTab =
        find.byKey(const ValueKey('side-panel-tab-animation'));
    await tester.ensureVisible(animationTab);
    await tester.tap(animationTab);
    await tester.pumpAndSettle();

    var animationItems =
        tester.widgetList<EffectListItem>(find.byType(EffectListItem)).toList();
    expect(animationItems.map((item) => item.effect.type), [EffectType.pulse, EffectType.fire]);

    notifier!.addLayerEffect(MountainRangeEffect());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('side-panel-tab-generators')),
      findsOneWidget,
    );

    final generatorTab =
        find.byKey(const ValueKey('side-panel-tab-generators'));
    await tester.ensureVisible(generatorTab);
    await tester.tap(generatorTab);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('convert-procedural-to-pixels')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Convert procedural layer?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Convert to pixels'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('side-panel-tab-generators')),
      findsNothing,
    );
    expect(notifier!.currentLayer.effects, isEmpty);
    expect(
      notifier!.currentLayer.pixels.any((pixel) => pixel >>> 24 != 0),
      isTrue,
    );
    expect(notifier!.startDrawing(), isTrue);
    notifier!.cancelDrawing();

    notifier!.undo();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('side-panel-tab-generators')),
      findsOneWidget,
    );
    expect(notifier!.currentLayer.effects.first, isA<MountainRangeEffect>());
    expect(notifier!.startDrawing(), isFalse);
  });
}
