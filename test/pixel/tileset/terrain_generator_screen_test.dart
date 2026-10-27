import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

Future<void> finishWork(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(find.byType(LinearProgressIndicator), findsNothing);
}

void main() {
  testWidgets('perspective selection generates and saves actual top-down terrain', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<TilesetGeneratorScreenState>();
    TilesetDocument? saved;
    await tester.pumpWidget(
        MaterialApp(home: TilesetGeneratorScreen(key: key, embedded: true, onSaveProject: (doc) async => saved = doc)));
    await tester.tap(find.ancestor(of: find.text('Top-Down'), matching: find.byType(ChoiceChip)));
    await tester.pump();
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Platforms'), findsNothing);
    expect(find.text('Sample Map'), findsOneWidget);
    final perspective =
        tester.widget<ChoiceChip>(find.ancestor(of: find.text('Top-Down'), matching: find.byType(ChoiceChip)));
    expect(perspective.selected, isTrue);
    await tester.runAsync(() => tester.tap(find.text('Generate Tileset')));
    await tester.pump();
    await finishWork(tester);
    await tester.scrollUntilVisible(find.text('Isolated Terrain'), 500,
        scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
        maxScrolls: 30);
    expect(find.text('Isolated Terrain'), findsOneWidget);
    expect(find.text('Isolated Platforms'), findsNothing);
    expect(find.textContaining('188 tiles · 47 connection shapes'), findsOneWidget);
    expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
    await tester.pump();
    expect(saved!.settings.perspective, TilesetPerspective.topDown);
    expect(saved!.settings.type, TilesetType.terrain);
    expect(saved!.cells[6 * 24 + 6], 0); // the sample island contains an interior pond
    expect(saved!.cells[3 * 24 + 3], 1);
    final fill = saved!.tiles.firstWhere((t) => t.mask == 255 && t.variation == 0);
    expect(fill.pixels.every((p) => saved!.settings.palette.take(4).contains(p)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopened terrain restores selection and uses terrain for individual regeneration', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = TilesetSettings(perspective: TilesetPerspective.topDown, variations: 1);
    final source = TilesetDocument(
        name: 'Saved Terrain', settings: settings, tiles: generateTileset(settings), cells: [1], columns: 1, rows: 1);
    final key = GlobalKey<TilesetGeneratorScreenState>();
    TilesetDocument? saved;
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            key: key,
            embedded: true,
            initialDocument: jsonEncode(source.toJson()),
            onSaveProject: (doc) async => saved = doc))));
    await finishWork(tester);
    expect(find.text('Sample Map'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.text('Regenerate Tile')));
    await tester.pump();
    await finishWork(tester);
    expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
    await tester.pump();
    final tile = saved!.tiles.singleWhere((t) => t.revision == 1);
    expect(tile.revision, 1);
    expect(tile.pixels, generateTerrainTile(settings, tile.mask, 0, revision: 1).pixels);
    expect(saved!.settings.perspective, TilesetPerspective.topDown);
    expect(tester.takeException(), isNull);
  });
}
