import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_geometry.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

Future<void> ready(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(find.byType(LinearProgressIndicator), findsNothing);
}

void main() {
  testWidgets('isometric erase and paint use projected grid coordinates and undo preserves cells', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = TilesetSettings(perspective: TilesetPerspective.isometric, variations: 1);
    final source = TilesetDocument(
        name: 'Picking',
        settings: settings,
        tiles: generateTileset(settings),
        cells: List.filled(6, 1),
        columns: 3,
        rows: 2);
    final key = GlobalKey<TilesetGeneratorScreenState>();
    TilesetDocument? saved;
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            key: key,
            embedded: true,
            initialDocument: jsonEncode(source.toJson()),
            onSaveProject: (doc) async {
              saved = doc;
            }))));
    await ready(tester);
    expect(find.text('Raised Blocks'), findsOneWidget);
    final canvas = find.byKey(const ValueKey('tileset-map-canvas'));
    final center = TilesetLayout(settings, 3, 2).vertex(1.5, 0.5);
    final origin = tester.getTopLeft(canvas);
    await tester.tap(find.byTooltip('Erase'));
    await tester.pump();
    await tester.tapAt(origin + Offset(center.x * 2, center.y * 2));
    await tester.pump();
    expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
    await tester.pump();
    expect(saved!.cells, [1, 0, 1, 1, 1, 1]);
    await tester.tap(find.byTooltip('Undo stroke'));
    await tester.pump();
    expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
    await tester.pump();
    expect(saved!.cells, List.filled(6, 1));
    await tester.tap(find.byTooltip('Redo stroke'));
    await tester.pump();
    await tester.tap(find.byTooltip('Paint'));
    await tester.pump();
    await tester.tapAt(origin + Offset(center.x * 2, center.y * 2));
    await tester.pump();
    expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
    await tester.pump();
    expect(saved!.cells, List.filled(6, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rectangular isometric sprites can be edited and protected without truncating pixels', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings =
        TilesetSettings(perspective: TilesetPerspective.isometric, type: TilesetType.raisedBlocks, variations: 1);
    final source = TilesetDocument(
        name: 'Edit', settings: settings, tiles: generateTileset(settings), cells: [1], columns: 1, rows: 1);
    final key = GlobalKey<TilesetGeneratorScreenState>();
    TilesetDocument? saved;
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            key: key,
            embedded: true,
            initialDocument: jsonEncode(source.toJson()),
            onSaveProject: (doc) async {
              saved = doc;
            }))));
    await ready(tester);
    await tester.runAsync(() => tester.tap(find.text('Edit Pixels')));
    await tester.pumpAndSettle();
    final editor = find.byKey(const ValueKey('tileset-pixel-editor'));
    final extent = tester.getSize(editor);
    expect(extent.width / extent.height, closeTo(settings.spriteWidth / settings.spriteHeight, 0.001));
    await tester.tapAt(tester.getTopLeft(editor) + Offset(extent.width * 0.5, extent.height * 0.8));
    await tester.runAsync(() => tester.tap(find.text('Apply & Protect')));
    await tester.pump();
    await ready(tester);
    expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
    await tester.pump();
    final edited = saved!.tiles.singleWhere((t) => t.protected);
    expect(edited.protected, isTrue);
    expect(edited.pixels.length, 32 * 24);
    expect(edited.pixels, isNot(orderedEquals(source.tiles.singleWhere((t) => t.id == edited.id).pixels)));
    expect(tester.takeException(), isNull);
  });
}
