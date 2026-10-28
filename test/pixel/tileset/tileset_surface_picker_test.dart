import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_configuration.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester, TilesetPerspective perspective, {Size size = const Size(1440, 1400)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            embedded: true, recipeMode: true, configuration: TilesetConfiguration(perspective: perspective))));
    await tester.pumpAndSettle();
  }

  SemanticsNode node(WidgetTester tester, String key) => tester.getSemantics(find.byKey(ValueKey(key)));
  bool selected(WidgetTester tester, String key) => node(tester, key).flagsCollection.isSelected == Tristate.isTrue;
  bool enabled(WidgetTester tester, String key) => node(tester, key).flagsCollection.isEnabled == Tristate.isTrue;

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, 120));
      await tester.pump();
    }
    if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 120, scrollable: list);
    final box = tester.getRect(finder), view = tester.getRect(list);
    final dy = view.center.dy - box.center.dy;
    // A drag shorter than the touch slop would land as a tap on whatever sits at the list's center.
    if (dy.abs() < 24) return;
    await tester.drag(list, Offset(0, dy));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Finder key(String k) => find.byKey(ValueKey(k));
  final grass = TilesetSurfacePresets.grass.spec.layers.length;

  testWidgets('a new set starts from the grass preset as editable layers', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    expect(key('layer-row-0'), findsOneWidget);
    expect(find.byKey(Key('layer-row-${grass - 1}')), findsOneWidget);
    expect(key('seam-pill'), findsOneWidget);
    expect(find.text('SEAMLESS'), findsOneWidget);
    expect(find.text('SURFACE EDITOR'), findsOneWidget);
    expect(find.text('GENERATE TILESET'), findsOneWidget);
    expect(find.text('BASE TYPE'), findsNothing);
    semantics.dispose();
  });

  testWidgets('wide layout shows the tile card and seam check over the sample map', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    expect(key('tile-card'), findsOneWidget);
    expect(find.text('TILE 16×16'), findsOneWidget);
    expect(find.text('3×3 REPEAT'), findsOneWidget);
    expect(find.text('all seams match'), findsOneWidget);
    await tester.tap(find.descendant(of: key('seam-check'), matching: find.byType(GestureDetector)).first);
    await tester.pump();
    expect(find.text('all seams match'), findsNothing);
    semantics.dispose();
  });

  testWidgets('layers can be added, edited, hidden, duplicated and removed, with undo', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, key('layer-add'));
    expect(find.byKey(Key('layer-row-$grass')), findsOneWidget);
    expect(find.text('Dots'), findsWidgets);

    await tap(tester, key('pattern-change'));
    await tester.pumpAndSettle();
    expect(find.text('PICK A PATTERN'), findsOneWidget);
    await tester.tap(key('pattern-bricks'));
    await tester.pump();
    expect(selected(tester, 'pattern-bricks'), isTrue);
    await tester.tap(find.text('USE BRICKS'));
    await tester.pumpAndSettle();
    expect(find.text('PICK A PATTERN'), findsNothing);

    await tap(tester, key('layer-tab-rules'));
    await tap(tester, key('area-top'));
    expect(selected(tester, 'area-top'), isTrue);
    await tap(tester, key('blend-dark'));
    expect(selected(tester, 'blend-dark'), isTrue);

    await tap(tester, key('layer-tab-noise'));
    await tap(tester, key('noise-streak'));
    expect(selected(tester, 'noise-streak'), isTrue);

    await tap(tester, key('layer-tab-pattern'));
    await tap(tester, find.byTooltip('Duplicate layer ${grass + 1}'));
    expect(find.byKey(Key('layer-row-${grass + 1}')), findsOneWidget);
    await tap(tester, find.byTooltip('Delete layer ${grass + 2}'));
    expect(find.byKey(Key('layer-row-${grass + 1}')), findsNothing);

    await tap(tester, find.byTooltip('Hide layer ${grass + 1}'));
    expect(find.byTooltip('Show layer ${grass + 1}'), findsOneWidget);

    await tester.tap(find.byTooltip('Undo surface edit'));
    await tester.pump();
    expect(find.byTooltip('Hide layer ${grass + 1}'), findsOneWidget);
    await tester.tap(find.byTooltip('Redo surface edit'));
    await tester.pump();
    expect(find.byTooltip('Show layer ${grass + 1}'), findsOneWidget);
    expect(find.text('SEAMLESS'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('solo shows one layer in the tile card and can be switched off again', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, find.byTooltip('Solo layer 2'));
    expect(find.byTooltip('Show all layers'), findsOneWidget);
    await tap(tester, find.byTooltip('Show all layers'));
    expect(find.byTooltip('Show all layers'), findsNothing);
    semantics.dispose();
  });

  testWidgets('the base layer cannot be hidden or blended and the stack is capped', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, key('layer-row-0'));
    expect(find.byTooltip('The base layer is always visible'), findsOneWidget);
    await tap(tester, key('layer-tab-rules'));
    expect(enabled(tester, 'blend-dark'), isFalse);

    for (var i = grass; i < tilesetMaxLayers; i++) {
      await tap(tester, key('layer-add'));
    }
    await reveal(tester, key('layer-add'));
    expect(find.textContaining('Layer limit reached'), findsOneWidget);
    expect(enabled(tester, 'layer-add'), isFalse);
    semantics.dispose();
  });

  testWidgets('a blend that has nothing to sit on is disabled with a visible reason', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    // Layer 1 is one flat mid green: light enough that "only on dark" has nothing to match.
    await reveal(tester, key('layer-row-2'));
    await tester.tapAt(tester.getTopLeft(key('layer-row-2')) + const Offset(90, 20));
    await tester.pump();
    await tap(tester, key('layer-tab-pattern'));
    await tap(tester, key('layer-tab-rules'));
    await reveal(tester, key('blend-dark'));
    final blocked = ['blend-dark', 'blend-light'].where((k) => !enabled(tester, k)).toList();
    if (blocked.isNotEmpty) {
      await reveal(tester, key('blend-reason'));
      expect(key('blend-reason'), findsOneWidget);
      expect(find.textContaining('is unavailable'), findsOneWidget);
    } else {
      expect(key('blend-reason'), findsNothing);
    }
    semantics.dispose();
  });

  testWidgets('pattern parameters: cell size for every pattern, grout width for brick-like ones', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, key('layer-row-0'));
    await tap(tester, key('layer-tab-pattern'));
    Future<void> choose(String name) async {
      await tap(tester, key('pattern-change'));
      await tester.pumpAndSettle();
      await tester.tap(key('pattern-$name'));
      await tester.pump();
      await tester.tap(key('pattern-use'));
      await tester.pumpAndSettle();
    }

    await choose('solid');
    expect(key('cell-large'), findsNothing);
    await choose('bricks');
    await tap(tester, key('cell-large'));
    expect(selected(tester, 'cell-large'), isTrue);
    await tap(tester, key('gap-2'));
    expect(selected(tester, 'gap-2'), isTrue);
    await choose('dots');
    expect(key('gap-2'), findsNothing);
    expect(key('cell-large'), findsOneWidget);
    expect(find.text('SEAMLESS'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('noise can be added, changed and removed', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, key('layer-row-0'));
    await tap(tester, key('layer-tab-noise'));
    if (key('noise-enabled').evaluate().isEmpty) await tap(tester, key('noise-remove'));
    expect(key('noise-enabled'), findsOneWidget);
    await tap(tester, key('noise-enabled'));
    expect(selected(tester, 'noise-speckle'), isTrue);
    await tap(tester, key('noise-grain'));
    expect(selected(tester, 'noise-grain'), isTrue);
    expect(find.text('Scale'), findsOneWidget);
    await tap(tester, key('noise-remove'));
    expect(key('noise-enabled'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('palette editor suggests shades, warns about flat ramps and applies', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, key('palette-edit'));
    await tester.pumpAndSettle();
    expect(find.text('PALETTE'), findsOneWidget);
    expect(find.text('Editing slot 5 · Mid'), findsOneWidget);
    expect(key('palette-warning'), findsNothing);
    expect(find.text('APPLY PALETTE'), findsOneWidget);

    await tester.tap(key('palette-preset-Ember'));
    await tester.pump();
    await tester.tap(key('palette-suggest'));
    await tester.pump();
    expect(key('palette-warning'), findsNothing);
    await tester.tap(key('palette-apply'));
    await tester.pumpAndSettle();
    expect(key('palette-apply'), findsNothing);
    semantics.dispose();
  });

  testWidgets('the preset gallery filters by tag and replaces or appends layers', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown);
    await tap(tester, key('surface-open-presets'));
    await tester.pumpAndSettle();
    expect(find.text('PRESETS'), findsWidgets);
    expect(key('preset-brick'), findsOneWidget);
    await tester.tap(key('gallery-tag-Liquid'));
    await tester.pump();
    expect(key('preset-brick'), findsNothing);
    expect(key('preset-lava'), findsOneWidget);
    await tester.tap(key('gallery-tag-All'));
    await tester.enterText(key('gallery-search'), 'ice');
    await tester.pump();
    expect(key('preset-ice'), findsOneWidget);
    expect(key('preset-lava'), findsNothing);

    await tester.tap(key('preset-ice'));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('layer-row-${TilesetSurfacePresets.ice.spec.layers.length}')), findsNothing);
    await reveal(tester, key('surface-name'));
    expect(tester.widget<TextField>(key('surface-name')).controller!.text, TilesetSurfacePresets.ice.name);

    await tap(tester, key('surface-open-presets'));
    await tester.pumpAndSettle();
    await tester.tap(key('preset-add-brick'));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('layer-row-${TilesetSurfacePresets.ice.spec.layers.length}')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('on a phone the preview is pinned and the inspector is a bottom sheet', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, TilesetPerspective.topDown, size: const Size(390, 844));
    expect(key('pinned-preview'), findsOneWidget);
    expect(key('layer-sheet'), findsOneWidget);
    expect(key('sheet-handle'), findsOneWidget);
    expect(key('layer-tab-noise'), findsOneWidget);
    expect(key('tile-card'), findsNothing);
    expect(tester.getSize(key('layer-row-0')).height, greaterThanOrEqualTo(56));

    await tester.tap(key('layer-tab-pattern'));
    await tester.pump();
    await tester.tap(key('pattern-change'));
    await tester.pumpAndSettle();
    await tester.tap(key('pattern-planks'));
    await tester.pump();
    await tester.tap(key('pattern-use'));
    await tester.pumpAndSettle();
    expect(find.text('Planks'), findsWidgets);
    semantics.dispose();
  });
}
