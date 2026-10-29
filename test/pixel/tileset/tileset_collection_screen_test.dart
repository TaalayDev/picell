import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_collection.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_collection_screen.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';
import 'package:picell/ui/widgets/pv/pv_compact_controls.dart';

Future<void> waitForWork(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 150 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('collection creates partial recipes, retains failed saves, duplicates and deletes sets', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var failWrites = true;
    TilesetCollection? saved;
    await tester.pumpWidget(MaterialApp(
        home: TilesetCollectionScreen(
            projectName: 'World',
            embedded: true,
            initialGeometry: (perspective: TilesetPerspective.side, size: 16),
            onSaveCollection: (collection) async {
              if (failWrites) throw StateError('write failed');
              saved = collection;
            })));
    expect(find.byType(TilesetGeneratorScreen), findsNothing);
    expect(find.text('Tileset collection'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workspace-new-tileset')));
    await tester.pumpAndSettle();
    expect(find.byType(TilesetGeneratorScreen), findsOneWidget);
    expect(find.text('SURFACE EDITOR'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-output')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('set-geometry-summary')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-shape')));
    await tester.pumpAndSettle();
    final settingsList = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    await tester.scrollUntilVisible(find.text('Vegetation'), 200, scrollable: settingsList);
    final platform = find.ancestor(of: find.text('Platform'), matching: find.byType(PvSwitchTile));
    await tester.ensureVisible(platform);
    await tester.tap(platform);
    await tester.pump();
    final vegetation = find.ancestor(of: find.text('Vegetation'), matching: find.byType(PvSwitchTile));
    await tester.ensureVisible(vegetation);
    await tester.tap(vegetation);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Select parts · 47 / 47'), 200, scrollable: settingsList);
    await tester.tap(find.text('Select parts · 47 / 47'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('part-55')));
    await tester.tap(find.byKey(const ValueKey('part-55')));
    await tester.ensureVisible(find.byKey(const ValueKey('part-38')));
    await tester.tap(find.byKey(const ValueKey('part-38')));
    await tester.pump();
    await tester.tap(find.text('Use 2 parts'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('GENERATE TILESET')));
    await waitForWork(tester);
    expect(find.textContaining('8 tiles · 2 connection shapes'), findsOneWidget);
    expect(find.text('Generate missing parts'), findsOneWidget);
    await tester.tap(find.text('Edit Pixels'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Apply & Protect')));
    await waitForWork(tester);
    await tester.runAsync(() => tester.tap(find.text('Add to collection')));
    await waitForWork(tester);
    expect(find.byType(TilesetGeneratorScreen), findsOneWidget);
    expect(find.textContaining('Could not save project:'), findsOneWidget);
    expect(saved, isNull);
    failWrites = false;
    await tester.runAsync(() => tester.tap(find.text('Add to collection')));
    await waitForWork(tester);
    expect(find.byType(TilesetGeneratorScreen), findsNothing);
    expect(saved!.name, 'World');
    final doc = saved!.entries.single.document;
    expect(doc.settings.parts, [38, 55]);
    expect(doc.settings.recipe!.platform, isTrue);
    expect(doc.settings.recipe!.vegetation, isTrue);
    expect(doc.tiles.where((t) => t.protected).length, 1);
    await tester.tap(find.byTooltip('Manage Ground tileset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.byTooltip('Save collection')));
    await waitForWork(tester);
    expect(saved!.entries.length, 2);
    expect(saved!.entries.last.document.tiles.first.pixels, doc.tiles.first.pixels);
    await tester.tap(find.byTooltip('Manage Ground tileset copy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'Renamed set');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();
    expect(find.text('Renamed set'), findsOneWidget);
    await tester.tap(find.byTooltip('Manage Renamed set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.byTooltip('Save collection')));
    await waitForWork(tester);
    expect(saved!.entries.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding missing parts preserves existing revisions and protected pixels', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const recipe = TilesetRecipe();
    final settings = TilesetSettings(type: TilesetType.ground, recipe: recipe, parts: [255], variations: 1);
    final tiles = generateTileset(settings);
    tiles[0] = generateTilesetTile(settings, 255, 0, revision: 7).copyWith(protected: true);
    tiles.first.pixels[100] = 0xffff00ff;
    final document =
        TilesetDocument(name: 'Partial', settings: settings, tiles: tiles, cells: [1], columns: 1, rows: 1);
    TilesetDocument? saved;
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            recipeMode: true,
            initialDocument: jsonEncode(document.toJson()),
            onSaveProject: (doc) async => saved = doc))));
    await waitForWork(tester);
    await tester.runAsync(() => tester.tap(find.text('Generate missing parts')));
    await waitForWork(tester);
    expect(find.text('Generate missing parts'), findsNothing);
    await tester.runAsync(() => tester.tap(find.text('Save to collection')));
    await waitForWork(tester);
    expect(saved!.settings.parts, [0, 255]);
    final kept = saved!.tiles.singleWhere((tile) => tile.mask == 255);
    expect(kept.revision, 7);
    expect(kept.protected, isTrue);
    expect(kept.pixels[100], 0xffff00ff);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy projects open in collection; cancelled drafts keep existing protected pixels', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = TilesetSettings(variations: 1);
    final tiles = generateTileset(s);
    tiles[0] = tiles.first.copyWith(protected: true);
    tiles.first.pixels[4] = 0xffff00ff;
    final d = TilesetDocument(name: 'Old set', settings: s, tiles: tiles, cells: [1], columns: 1, rows: 1);
    TilesetCollection? saved;
    await tester.pumpWidget(MaterialApp(
        home: TilesetCollectionScreen(
            projectName: 'World',
            initialDocument: jsonEncode(d.toJson()),
            onSaveCollection: (collection) async => saved = collection)));
    // On a phone the tilesets panel opens over the canvas.
    expect(find.text('Old set'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('toggle-sets-panel')));
    await tester.pumpAndSettle();
    expect(find.text('Old set'), findsOneWidget);
    expect(find.byType(TilesetGeneratorScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('workspace-new-tileset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-sets-panel')));
    await tester.pumpAndSettle();
    expect(find.text('Old set'), findsOneWidget);
    final name = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Collection name');
    await tester.enterText(name, 'New collection name');
    await tester.runAsync(() => tester.tap(find.byTooltip('Save collection')));
    await waitForWork(tester);
    expect(saved!.entries.single.document.tiles.first.pixels[4], 0xffff00ff);
    expect(saved!.entries.single.document.tiles.first.protected, isTrue);
    expect(tester.takeException(), isNull);
  });
}
