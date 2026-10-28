import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_configuration.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> open(WidgetTester tester, TilesetPerspective perspective) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            embedded: true, recipeMode: true, configuration: TilesetConfiguration(perspective: perspective))));
    await tester.pumpAndSettle();
  }

  bool selected(WidgetTester tester, String key) => tester.widget<ChoiceChip>(find.byKey(ValueKey(key))).selected;

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, 120));
      await tester.pump();
    }
    if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 120, scrollable: list);
    final box = tester.getRect(finder), view = tester.getRect(list);
    await tester.drag(list, Offset(0, view.center.dy - box.center.dy));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('a new set starts from the grass preset as editable layers', (tester) async {
    await open(tester, TilesetPerspective.topDown);
    expect(find.byKey(const ValueKey('layer-row-0')), findsOneWidget);
    expect(find.byKey(Key('layer-row-${TilesetSurfacePresets.grass.spec.layers.length - 1}')), findsOneWidget);
    expect(find.byKey(const ValueKey('seam-pill')), findsOneWidget);
    expect(find.text('Seamless'), findsOneWidget);
    expect(find.text('BASE TYPE'), findsNothing);
  });

  testWidgets('layers can be added, edited, hidden, duplicated and removed, with undo', (tester) async {
    await open(tester, TilesetPerspective.topDown);
    final count = TilesetSurfacePresets.grass.spec.layers.length;
    await tap(tester, find.byKey(const ValueKey('layer-add')));
    expect(find.byKey(Key('layer-row-$count')), findsOneWidget);
    expect(find.text('LAYER ${count + 1} · DOTS'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('pattern-bricks')));
    expect(find.text('LAYER ${count + 1} · BRICKS'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('layer-tab-rules')));
    await tap(tester, find.byKey(const ValueKey('area-top')));
    expect(selected(tester, 'area-top'), isTrue);
    await tap(tester, find.byKey(const ValueKey('blend-dark')));
    expect(selected(tester, 'blend-dark'), isTrue);

    await tap(tester, find.byKey(const ValueKey('layer-tab-noise')));
    await tap(tester, find.byKey(const ValueKey('noise-streak')));
    expect(selected(tester, 'noise-streak'), isTrue);

    await tap(tester, find.byTooltip('Duplicate layer ${count + 1}'));
    expect(find.byKey(Key('layer-row-${count + 1}')), findsOneWidget);
    await tap(tester, find.byTooltip('Delete layer ${count + 2}'));
    expect(find.byKey(Key('layer-row-${count + 1}')), findsNothing);

    await tap(tester, find.byTooltip('Hide layer ${count + 1}'));
    expect(find.byTooltip('Show layer ${count + 1}'), findsOneWidget);

    await tap(tester, find.byTooltip('Undo surface edit'));
    expect(find.byTooltip('Hide layer ${count + 1}'), findsOneWidget);
    await tap(tester, find.byTooltip('Redo surface edit'));
    expect(find.byTooltip('Show layer ${count + 1}'), findsOneWidget);
    expect(find.text('Seamless'), findsOneWidget);
  });

  testWidgets('the base layer cannot be hidden or blended and the stack is capped', (tester) async {
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, find.byKey(const ValueKey('layer-row-0')));
    expect(find.byTooltip('The base layer is always visible'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('layer-tab-rules')));
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('blend-dark'))).onSelected, isNull);

    for (var i = TilesetSurfacePresets.grass.spec.layers.length; i < tilesetMaxLayers; i++) {
      await tap(tester, find.byKey(const ValueKey('layer-add')));
    }
    await reveal(tester, find.byKey(const ValueKey('layer-add')));
    expect(find.text('Layer limit reached'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('layer-add'))).onPressed, isNull);
  });

  testWidgets('the preset gallery filters by tag and replaces or appends layers', (tester) async {
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, find.byKey(const ValueKey('surface-open-presets')));
    expect(find.byKey(const ValueKey('preset-brick')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gallery-tag-Liquid')));
    await tester.pump();
    expect(find.byKey(const ValueKey('preset-brick')), findsNothing);
    expect(find.byKey(const ValueKey('preset-lava')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gallery-tag-Liquid')));
    await tester.enterText(find.byKey(const ValueKey('gallery-search')), 'ice');
    await tester.pump();
    expect(find.byKey(const ValueKey('preset-ice')), findsOneWidget);
    expect(find.byKey(const ValueKey('preset-lava')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('preset-ice')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('layer-row-${TilesetSurfacePresets.ice.spec.layers.length}')), findsNothing);
    await reveal(tester, find.byKey(const ValueKey('surface-name')));
    expect(
        tester
            .widget<EditableText>(
                find.descendant(of: find.byKey(const ValueKey('surface-name')), matching: find.byType(EditableText)))
            .controller
            .text,
        TilesetSurfacePresets.ice.name);

    await tap(tester, find.byKey(const ValueKey('surface-open-presets')));
    await tester.tap(find.byKey(const ValueKey('preset-add-brick')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('layer-row-${TilesetSurfacePresets.ice.spec.layers.length}')), findsOneWidget);
  });
}
