import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_canvas.dart';
import 'package:picell/pixel/tileset/tileset_collection.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_collection_screen.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_workspace.dart';

TilesetDocument doc(String name, {int size = 16, TilesetPerspective perspective = TilesetPerspective.side}) {
  final settings = TilesetSettings(perspective: perspective, size: size, parts: [0, 255], variations: 2);
  return TilesetDocument(
      name: name, settings: settings, tiles: generateTileset(settings), cells: [1], columns: 1, rows: 1);
}

TilesetEntry entry(String id, {String? name}) => TilesetEntry(id: id, document: doc(name ?? 'Set $id'));

Map<String, dynamic> v1(List<TilesetEntry> entries) =>
    {'kind': 'tilesetCollection', 'version': 1, 'name': 'Old', 'entries': entries.map((e) => e.toJson()).toList()};

void main() {
  group('canvas model', () {
    test('items round trip and reject malformed data', () {
      const canvas = TilesetCanvas([
        TilesetCanvasItem(id: 'a', kind: TilesetCanvasKind.set, entryId: 'one', x: 2, y: -3),
        TilesetCanvasItem(id: 'b', kind: TilesetCanvasKind.tile, entryId: 'one', tileId: '0:0', x: 0, y: 0),
        TilesetCanvasItem(id: 'c', kind: TilesetCanvasKind.note, x: 5, y: 5, text: 'Dungeon', width: 4, height: 3),
      ]);
      final restored = TilesetCanvas.fromJson(jsonDecode(jsonEncode(canvas.toJson())) as Map<String, dynamic>);
      expect(restored.items.map((i) => i.toJson()), canvas.items.map((i) => i.toJson()));
      Map<String, dynamic> one(Map<String, dynamic> item) => {
            'items': [item]
          };
      expect(() => TilesetCanvas.fromJson(one({'id': 'x', 'kind': 'set', 'x': 0, 'y': 0})), throwsFormatException);
      expect(() => TilesetCanvas.fromJson(one({'id': 'x', 'kind': 'tile', 'entry': 'e', 'x': 0, 'y': 0})),
          throwsFormatException);
      expect(
          () => TilesetCanvas.fromJson(one({'id': 'x', 'kind': 'note', 'x': 1 << 30, 'y': 0})), throwsFormatException);
      expect(() => TilesetCanvas.fromJson(one({'id': 'x', 'kind': 'wat', 'x': 0, 'y': 0})), throwsFormatException);
      expect(
          () => TilesetCanvas.fromJson({
                'items': [
                  {'id': 'x', 'kind': 'note', 'x': 0, 'y': 0},
                  {'id': 'x', 'kind': 'note', 'x': 1, 'y': 1}
                ]
              }),
          throwsFormatException);
    });

    test('set sizes follow the exported atlas and tile size', () {
      final cells = tilesetAtlasCells(doc('A'), 16);
      expect((cells.width, cells.height), (4, 1), reason: '4 tiles in one row of 16px sprites');
      final iso = doc('B', perspective: TilesetPerspective.isometric, size: 16);
      final isoCells = tilesetAtlasCells(iso, 16);
      expect(isoCells.width, 8, reason: 'isometric sprites are twice as wide: 4 tiles × 32px / 16px cells');
      expect(isoCells.height, greaterThanOrEqualTo(1));
    });

    test('free spots keep a gap and prefer the anchor when given', () {
      const occupied = [(x: 0, y: 0, width: 4, height: 2)];
      expect(firstFreeCanvasSpot(2, 2, occupied), (x: 5, y: 0));
      expect(firstFreeCanvasSpot(2, 2, const []), (x: 0, y: 0));
      final near = firstFreeCanvasSpot(2, 2, occupied, anchor: (x: 20, y: 20));
      expect((near.x - 20).abs() + (near.y - 20).abs(), 0);
    });

    test('placing never overlaps existing items', () {
      final entries = {'one': entry('one')};
      var canvas = const TilesetCanvas();
      for (var i = 0; i < 6; i++) {
        canvas = placeOnTilesetCanvas(canvas,
            TilesetCanvasItem(id: 'n$i', kind: TilesetCanvasKind.note, x: 0, y: 0, width: 6, height: 2), entries, 16);
      }
      for (final a in canvas.items) {
        for (final b in canvas.items.where((b) => b.id != a.id)) {
          final overlap = a.x < b.x + 6 && b.x < a.x + 6 && a.y < b.y + 2 && b.y < a.y + 2;
          expect(overlap, isFalse, reason: '${a.id} overlaps ${b.id}');
        }
      }
    });

    test('pruning removes items of deleted sets and missing tiles but keeps notes', () {
      final a = entry('a'), b = entry('b');
      final canvas = TilesetCanvas([
        const TilesetCanvasItem(id: '1', kind: TilesetCanvasKind.set, entryId: 'a', x: 0, y: 0),
        const TilesetCanvasItem(id: '2', kind: TilesetCanvasKind.set, entryId: 'b', x: 9, y: 0),
        TilesetCanvasItem(
            id: '3', kind: TilesetCanvasKind.tile, entryId: 'b', tileId: b.document.tiles.first.id, x: 0, y: 9),
        const TilesetCanvasItem(id: '4', kind: TilesetCanvasKind.tile, entryId: 'b', tileId: '99:9', x: 0, y: 12),
        const TilesetCanvasItem(id: '5', kind: TilesetCanvasKind.note, x: 0, y: 20),
      ]);
      expect(canvas.pruned([a, b]).items.map((i) => i.id), ['1', '2', '3', '5']);
      expect(canvas.pruned([a]).items.map((i) => i.id), ['1', '5']);
    });

    test('collections without a canvas get a tidy layout and removing a set drops its items', () {
      final migrated = TilesetCollection.fromJson(v1([entry('a'), entry('b'), entry('c')]));
      expect(migrated.canvas.items.where((i) => i.kind == TilesetCanvasKind.set).length, 3);
      final positions = migrated.canvas.items.map((i) => (i.x, i.y)).toSet();
      expect(positions.length, 3, reason: 'sets do not stack');
      final fewer = migrated.copyWith(entries: migrated.entries.where((e) => e.id != 'b').toList());
      expect(fewer.canvas.items.map((i) => i.entryId), ['a', 'c']);
      final round = TilesetCollection.fromJson(jsonDecode(jsonEncode(migrated.toJson())) as Map<String, dynamic>);
      expect(round.canvas.items.map((i) => (i.id, i.x, i.y)), migrated.canvas.items.map((i) => (i.id, i.x, i.y)));
    });
  });

  group('workspace', () {
    Future<void> pump(WidgetTester tester, TilesetCollection collection,
        {required List<TilesetCanvas> changes, Size size = const Size(1440, 900)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var current = collection;
      await tester.pumpWidget(MaterialApp(
          home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                  body: TilesetWorkspace(
                      collection: current,
                      onCanvasChanged: (canvas) {
                        changes.add(canvas);
                        setState(() => current = current.copyWith(canvas: canvas));
                      },
                      onCreate: () {},
                      onEdit: (_) {},
                      onRename: (_) {},
                      onDuplicate: (_) {},
                      onDelete: (_) {})))));
      await tester.pumpAndSettle();
    }

    TilesetWorkspaceState state(WidgetTester tester) => tester.state(find.byType(TilesetWorkspace));
    Offset canvasTopLeft(WidgetTester tester) => tester.getTopLeft(find.byKey(const ValueKey('tileset-canvas')));

    TilesetCollection two() => TilesetCollection.fromJson(v1([entry('a', name: 'Alpha'), entry('b', name: 'Beta')]));

    testWidgets('dragging an item moves it by whole cells and undo restores it', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, two(), changes: changes);
      final before = changes.isEmpty ? two().canvas : changes.last;
      final item = before.items.first;
      final start = canvasTopLeft(tester) + state(tester).debugItemCenter(item.id)!;
      final cell = 16 * state(tester).debugZoom;
      await tester.dragFrom(start, Offset(3 * cell, 2 * cell));
      await tester.pumpAndSettle();
      expect(changes, hasLength(1));
      final moved = changes.single.byId(item.id)!;
      expect((moved.x, moved.y), (item.x + 3, item.y + 2));
      expect(find.text('Tileset'), findsOneWidget, reason: 'the inspector shows the selected set');
      await tester.tap(find.byKey(const ValueKey('canvas-undo')));
      await tester.pumpAndSettle();
      expect(changes, hasLength(2));
      expect((changes.last.byId(item.id)!.x, changes.last.byId(item.id)!.y), (item.x, item.y));
      await tester.tap(find.byKey(const ValueKey('canvas-redo')));
      await tester.pumpAndSettle();
      expect(changes.last.byId(item.id)!.x, item.x + 3);
    });

    testWidgets('a drag that does not move a whole cell changes nothing', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, two(), changes: changes);
      final start = canvasTopLeft(tester) + state(tester).debugItemCenter(two().canvas.items.first.id)!;
      await tester.dragFrom(start, const Offset(6, 4));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
    });

    testWidgets('marquee selects several items, align and remove from canvas work, sets stay', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, two(), changes: changes);
      final box = tester.getRect(find.byKey(const ValueKey('tileset-canvas')));
      await tester.dragFrom(box.bottomRight - const Offset(6, 6), Offset(-(box.width - 14), -(box.height - 66)));
      await tester.pumpAndSettle();
      expect(find.text('2 items selected'), findsOneWidget);
      await tester.tap(find.text('Align top'));
      await tester.pumpAndSettle();
      expect(changes.last.items.map((i) => i.y).toSet(), hasLength(1));
      await tester.tap(find.text('Remove from canvas'));
      await tester.pumpAndSettle();
      expect(changes.last.items, isEmpty);
      // The sets are still listed and can be put back.
      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.byTooltip('Manage Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to canvas'));
      await tester.pumpAndSettle();
      expect(changes.last.items.map((i) => i.entryId), ['a']);
    });

    testWidgets('tiles are placed from the sets panel and notes can be written', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, two(), changes: changes);
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      final thumbs = find.byTooltip(RegExp(r'· v1$'));
      expect(thumbs, findsWidgets);
      await tester.tap(thumbs.first);
      await tester.pumpAndSettle();
      expect(changes.last.items.where((i) => i.kind == TilesetCanvasKind.tile), hasLength(1));
      expect(find.text('Tile'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('canvas-add-note')));
      await tester.pumpAndSettle();
      expect(find.text('Note'), findsWidgets);
      await tester.enterText(find.byKey(const ValueKey('note-text')), 'Cave');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('note-text')), 'Cave entrance');
      await tester.pumpAndSettle();
      final note = changes.last.items.singleWhere((i) => i.kind == TilesetCanvasKind.note);
      expect(note.text, 'Cave entrance');
      // Typing is one undo step, not one per keystroke.
      final count = changes.length;
      await tester.tap(find.byKey(const ValueKey('canvas-undo')));
      await tester.pumpAndSettle();
      expect(changes.length, count + 1);
      expect(changes.last.items.singleWhere((i) => i.kind == TilesetCanvasKind.note).text, '');
      await tester.tap(find.byKey(const ValueKey('canvas-undo')));
      await tester.pumpAndSettle();
      expect(changes.last.items.where((i) => i.kind == TilesetCanvasKind.note), isEmpty);
    });

    testWidgets('keyboard: delete removes, arrows nudge, undo reverts', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, two(), changes: changes);
      final id = two().canvas.items.first.id;
      await tester.tapAt(canvasTopLeft(tester) + state(tester).debugItemCenter(id)!);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(changes.last.byId(id)!.x, two().canvas.byId(id)!.x + 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(changes.last.byId(id), isNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(changes.last.byId(id), isNotNull);
    });

    testWidgets('narrow screens open the panels over the canvas', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, two(), changes: changes, size: const Size(390, 844));
      expect(find.byKey(const ValueKey('workspace-new-tileset')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('toggle-sets-panel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-tileset')), findsOneWidget);
      await tester.tapAt(const Offset(385, 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-tileset')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('toggle-inspector-panel')));
      await tester.pumpAndSettle();
      expect(find.text('Canvas controls'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty project explains how to start', (tester) async {
      final changes = <TilesetCanvas>[];
      await pump(tester, TilesetCollection(name: 'Empty'), changes: changes);
      expect(find.text('Build your tileset board'), findsOneWidget);
      expect(find.byKey(const ValueKey('canvas-empty-create')), findsOneWidget);
    });
  });

  group('collection screen', () {
    testWidgets('new, duplicated and deleted sets keep the canvas in sync and survive a save', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final start = TilesetCollection.fromJson(v1([entry('a', name: 'Alpha')]));
      TilesetCollection? saved;
      await tester.pumpWidget(MaterialApp(
          home: TilesetCollectionScreen(
              embedded: true,
              initialDocument: jsonEncode(start.toJson()),
              onSaveCollection: (collection) async => saved = collection)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Manage Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.byTooltip('Save collection')));
      await tester.pumpAndSettle();
      expect(saved!.entries, hasLength(2));
      final sets = saved!.canvas.items.where((i) => i.kind == TilesetCanvasKind.set).toList();
      expect(sets.map((i) => i.entryId).toSet(), saved!.entries.map((e) => e.id).toSet());
      expect({for (final i in sets) (i.x, i.y)}, hasLength(2), reason: 'the copy lands on a free spot');
      await tester.tap(find.byTooltip('Manage Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.byTooltip('Save collection')));
      await tester.pumpAndSettle();
      expect(saved!.entries, hasLength(1));
      expect(saved!.canvas.items.every((i) => i.entryId == saved!.entries.single.id), isTrue);
      final reopened = TilesetCollection.fromJson(jsonDecode(jsonEncode(saved!.toJson())) as Map<String, dynamic>);
      expect(reopened.canvas.items, hasLength(1));
    });
  });
}
