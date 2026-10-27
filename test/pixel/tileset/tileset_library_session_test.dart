import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

void main() {
  testWidgets('library session restores output and retains dirty state after failed save', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = TilesetSettings(variations: 1);
    final document = TilesetDocument(
        name: 'Saved Platforms',
        settings: settings,
        tiles: generatePlatformTileset(settings),
        cells: [1],
        columns: 1,
        rows: 1);
    final key = GlobalKey<TilesetGeneratorScreenState>();
    final dirty = <bool>[];
    var fail = true;
    TilesetDocument? saved;
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
            home: TilesetGeneratorScreen(
          key: key,
          embedded: true,
          projectName: 'Renamed in library',
          initialDocument: jsonEncode(document.toJson()),
          onDirtyChanged: dirty.add,
          onSaveProject: (doc) async {
            if (fail) throw StateError('Storage unavailable');
            saved = doc;
          },
        ))));
    for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Renamed in library'), findsOneWidget);
    expect(find.textContaining('47 tiles · 47 connection shapes'), findsOneWidget);
    final name = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Tileset name');
    await tester.enterText(name, 'Renamed Platforms');
    expect(dirty.last, isTrue);
    final failed = await tester.runAsync(() => key.currentState!.flushPendingSave());
    await tester.pump();
    expect(failed, isFalse);
    expect(dirty.last, isTrue);
    expect(saved, isNull);
    fail = false;
    final success = await tester.runAsync(() => key.currentState!.flushPendingSave());
    await tester.pump();
    expect(success, isTrue);
    expect(dirty.last, isFalse);
    expect(saved!.name, 'Renamed Platforms');
    expect(saved!.tiles.length, 47);
    expect(saved!.cells, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unreadable project shows an error and cannot overwrite its document', (tester) async {
    final key = GlobalKey<TilesetGeneratorScreenState>();
    var writes = 0;
    await tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            key: key,
            embedded: true,
            initialDocument: '{broken',
            onSaveProject: (_) async {
              writes++;
            })));
    await tester.pump();
    expect(find.textContaining('Could not load this tileset'), findsOneWidget);
    expect(await key.currentState!.flushPendingSave(), isTrue); // safe to close unchanged
    expect(writes, 0);
    expect(tester.takeException(), isNull);
  });
}
