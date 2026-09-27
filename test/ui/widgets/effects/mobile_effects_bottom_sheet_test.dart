import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/providers/pixel_canvas_provider.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/ui/widgets/effects/effect_list_item.dart';
import 'package:picell/ui/widgets/layers_panel.dart';
import 'package:picell/ui/widgets/panel/mobile_side_panel_bottom_sheet.dart';
import 'package:picell/ui/widgets/tools_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets(
      'ToolsBottomBar has unified layers button that opens MobileSidePanelBottomSheet with Layers first, then effects tabs',
      (tester) async {
    final currentTool = ValueNotifier(PixelTool.pencil);
    addTearDown(currentTool.dispose);

    final project = Project(
      id: 88,
      name: 'Mobile unified sheet test',
      width: 16,
      height: 16,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
      frames: [
        AnimationFrame(
          id: 1,
          stateId: 0,
          name: 'Frame 1',
          duration: 100,
          order: 0,
          layers: [
            Layer(
              layerId: 1,
              id: 'layer-1',
              name: 'Layer 1',
              pixels: Uint32List(16 * 16),
              effects: [
                GlitchEffect(),
                PulseEffect(),
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
          locale: const Locale('en'),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final canvasState =
                    ref.watch(pixelCanvasNotifierProvider(project));
                notifier =
                    ref.read(pixelCanvasNotifierProvider(project).notifier);

                return Stack(
                  children: [
                    const Positioned.fill(child: SizedBox()),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ToolsBottomBar(
                        currentTool: currentTool,
                        state: canvasState,
                        notifier: notifier!,
                        width: 16,
                        height: 16,
                        subscription: UserSubscription.free(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify single unified button exists in bottom bar
    final layersButton = find.byKey(const ValueKey('tools-bottom-bar-layers'));
    expect(layersButton, findsOneWidget);

    // Tap layers button to open unified bottom sheet
    await tester.tap(layersButton);
    await tester.pumpAndSettle();

    // Verify MobileSidePanelBottomSheet is open
    expect(find.byType(MobileSidePanelBottomSheet), findsOneWidget);

    // Verify tabs order: Layers first, then effects tabs like wide version
    expect(
        find.byKey(const ValueKey('mobile-side-panel-tab-layers')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-side-panel-tab-filters')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-side-panel-tab-materials')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-side-panel-tab-animation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-side-panel-tab-lighting')),
        findsOneWidget);

    // First tab is Layers by default, displaying LayersPanel
    expect(find.byType(LayersPanel), findsOneWidget);

    // Switch to Filters tab
    final filtersTab =
        find.byKey(const ValueKey('mobile-side-panel-tab-filters'));
    await tester.tap(filtersTab);
    await tester.pumpAndSettle();

    // Verify GlitchEffect is shown in Filters tab
    final filterItems =
        tester.widgetList<EffectListItem>(find.byType(EffectListItem)).toList();
    expect(filterItems.any((item) => item.effect.type == EffectType.glitch),
        isTrue);

    // Switch to Animation tab
    final animTab =
        find.byKey(const ValueKey('mobile-side-panel-tab-animation'));
    await tester.ensureVisible(animTab);
    await tester.tap(animTab);
    await tester.pumpAndSettle();

    // Verify PulseEffect is shown in Animation tab
    final animItems =
        tester.widgetList<EffectListItem>(find.byType(EffectListItem)).toList();
    expect(
        animItems.any((item) => item.effect.type == EffectType.pulse), isTrue);

    // Close bottom sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(MobileSidePanelBottomSheet), findsNothing);
  });
}
