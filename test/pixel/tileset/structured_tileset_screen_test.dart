import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

Future<void> completeWork(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(find.byType(LinearProgressIndicator), findsNothing);
}

void main() {
  final modes = [
    (TilesetPerspective.side, TilesetType.ground),
    (TilesetPerspective.side, TilesetType.walls),
    (TilesetPerspective.topDown, TilesetType.paths),
    (TilesetPerspective.topDown, TilesetType.walls),
    (TilesetPerspective.topDown, TilesetType.floors),
    (TilesetPerspective.isometric, TilesetType.ground),
    (TilesetPerspective.isometric, TilesetType.raisedBlocks),
    (TilesetPerspective.isometric, TilesetType.walls),
  ];
  for (final (perspective, type) in modes) {
    testWidgets('${perspective.name}/${type.name} generates from its selector and reopens correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var key = GlobalKey<TilesetGeneratorScreenState>();
      TilesetDocument? saved;
      await tester.pumpWidget(MaterialApp(
          home: TilesetGeneratorScreen(
              key: key,
              embedded: true,
              onSaveProject: (doc) async {
                saved = doc;
              })));
      if (perspective != TilesetPerspective.side) {
        await tester.tap(find.ancestor(of: find.text(perspective.label), matching: find.byType(ChoiceChip)));
        await tester.pump();
      }
      await tester.tap(find.text(type.label));
      await tester.pump();
      final chip =
          tester.widget<ChoiceChip>(find.ancestor(of: find.text(type.label), matching: find.byType(ChoiceChip)));
      expect(chip.selected, isTrue);
      await tester.runAsync(() => tester.tap(find.text('Generate Tileset')));
      await tester.pump();
      await completeWork(tester);
      expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
      await tester.pump();
      expect(saved!.settings.type, type);
      expect(saved!.settings.perspective, perspective);
      expect(saved!.tiles.first.pixels, generateTilesetTile(saved!.settings, saved!.tiles.first.mask, 0).pixels);
      expect(saved!.cells.any((v) => v == 1), isTrue);
      final serialized = jsonEncode(saved!.toJson());
      key = GlobalKey<TilesetGeneratorScreenState>();
      await tester.runAsync(() => tester.pumpWidget(MaterialApp(
          home: TilesetGeneratorScreen(
              key: key,
              embedded: true,
              initialDocument: serialized,
              onSaveProject: (doc) async {
                saved = doc;
              }))));
      await completeWork(tester);
      final restoredChip =
          tester.widget<ChoiceChip>(find.ancestor(of: find.text(type.label), matching: find.byType(ChoiceChip)));
      expect(restoredChip.selected, isTrue);
      await tester.runAsync(() => tester.tap(find.text('Regenerate Tile')));
      await tester.pump();
      await completeWork(tester);
      expect(await tester.runAsync(() => key.currentState!.flushPendingSave()), isTrue);
      await tester.pump();
      final changed = saved!.tiles.singleWhere((t) => t.revision == 1);
      expect(changed.revision, 1);
      expect(changed.pixels, generateTilesetTile(saved!.settings, changed.mask, changed.variation, revision: 1).pixels);
      expect(tester.takeException(), isNull);
    });
  }
}
