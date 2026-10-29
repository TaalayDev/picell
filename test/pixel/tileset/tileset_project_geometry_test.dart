import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/pixel/tileset/tileset_collection.dart';
import 'package:picell/pixel/tileset/tileset_configuration.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_project.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_collection_screen.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_geometry_picker.dart';

TilesetDocument doc(String name, TilesetPerspective perspective, int size) {
  final settings = TilesetSettings(perspective: perspective, size: size, parts: [0], variations: 1);
  return TilesetDocument(
      name: name, settings: settings, tiles: generateTileset(settings), cells: [1], columns: 1, rows: 1);
}

Map<String, dynamic> v1(List<TilesetEntry> entries) => {
      'kind': 'tilesetCollection',
      'version': 1,
      'name': 'Old world',
      'entries': entries.map((e) => e.toJson()).toList(),
    };

void main() {
  group('collection geometry', () {
    test('version 2 round trips the project geometry', () {
      final collection = TilesetCollection(
          name: 'World',
          perspective: TilesetPerspective.isometric,
          tileSize: 32,
          entries: [TilesetEntry(id: 'a', document: doc('A', TilesetPerspective.isometric, 32))]);
      final json = jsonDecode(jsonEncode(collection.toJson())) as Map<String, dynamic>;
      expect(json['version'], 2);
      final restored = TilesetCollection.fromJson(json);
      expect(restored.perspective, TilesetPerspective.isometric);
      expect(restored.tileSize, 32);
      expect(restored.matchesGeometry(restored.entries.single), isTrue);
    });

    test('version 1 derives the most common geometry and keeps pixels untouched', () {
      final top = doc('Top', TilesetPerspective.topDown, 16)..tiles.first.pixels[3] = 0xff123456;
      final entries = [
        TilesetEntry(id: 'a', document: doc('Side', TilesetPerspective.side, 16)),
        TilesetEntry(id: 'b', document: top),
        TilesetEntry(id: 'c', document: doc('Top 2', TilesetPerspective.topDown, 16)),
      ];
      final migrated = TilesetCollection.fromJson(v1(entries));
      expect(migrated.perspective, TilesetPerspective.topDown);
      expect(migrated.tileSize, 16);
      expect(migrated.matchesGeometry(migrated.entries[0]), isFalse);
      expect(migrated.matchesGeometry(migrated.entries[1]), isTrue);
      expect(migrated.entries[1].document.tiles.first.pixels[3], 0xff123456);
      expect(migrated.toJson()['version'], 2);
    });

    test('a tie goes to the earliest set and an empty v1 collection uses defaults', () {
      final tie = TilesetCollection.fromJson(v1([
        TilesetEntry(id: 'a', document: doc('Iso', TilesetPerspective.isometric, 32)),
        TilesetEntry(id: 'b', document: doc('Side', TilesetPerspective.side, 16)),
      ]));
      expect((tie.perspective, tie.tileSize), (TilesetPerspective.isometric, 32));
      final empty = TilesetCollection.fromJson(v1(const []));
      expect((empty.perspective, empty.tileSize), (TilesetPerspective.side, 16));
    });

    test('desired configuration, not only generated pixels, decides the migrated geometry', () {
      final entry = TilesetEntry(
          id: 'a',
          document: doc('Side', TilesetPerspective.side, 16),
          configuration: TilesetConfiguration(perspective: TilesetPerspective.topDown, size: 32));
      final migrated = TilesetCollection.fromJson(v1([entry]));
      expect((migrated.perspective, migrated.tileSize), (TilesetPerspective.topDown, 32));
      expect(migrated.matchesGeometry(migrated.entries.single), isFalse);
    });

    test('legacy single documents adopt their own geometry', () {
      final legacy = TilesetCollection.fromJson(doc('Solo', TilesetPerspective.topDown, 48).toJson());
      expect((legacy.perspective, legacy.tileSize), (TilesetPerspective.topDown, 48));
    });

    test('rejects invalid sizes, unknown perspectives and future versions', () {
      final good = TilesetCollection(name: 'W').toJson();
      expect(() => TilesetCollection(name: 'W', tileSize: 24), throwsArgumentError);
      expect(() => TilesetCollection.fromJson({...good, 'tileSize': 24}), throwsFormatException);
      expect(() => TilesetCollection.fromJson({...good, 'perspective': 'nope'}), throwsFormatException);
      expect(() => TilesetCollection.fromJson({...good, 'version': 3}), throwsFormatException);
    });

    test('new tileset projects store the chosen geometry before any set exists', () {
      final project = newTilesetProject(
          name: 'Dungeon', geometry: (perspective: TilesetPerspective.topDown, size: 32), now: DateTime(2026));
      expect(project.type, ProjectType.proceduralTileset);
      final collection = TilesetCollection.fromJson(jsonDecode(project.tilesetData!) as Map<String, dynamic>);
      expect((collection.perspective, collection.tileSize), (TilesetPerspective.topDown, 32));
      expect(collection.entries, isEmpty);
    });
  });

  group('geometry screens', () {
    Future<void> sizeView(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('a project without saved data asks for perspective and size first', (tester) async {
      await sizeView(tester);
      TilesetCollection? saved;
      await tester.pumpWidget(MaterialApp(
          home: TilesetCollectionScreen(
              projectName: 'World', embedded: true, onSaveCollection: (collection) async => saved = collection)));
      expect(find.text('Set up your tileset project'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace-new-tileset')), findsNothing);
      FilledButton cont() => tester.widget(find.byKey(const ValueKey('tileset-geometry-continue')));
      expect(cont().onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('tileset-perspective-iso')));
      await tester.pump();
      expect(cont().onPressed, isNull, reason: 'tile size is still missing');
      await tester.tap(find.byKey(const ValueKey('tileset-size-32')));
      await tester.pump();
      expect(cont().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('tileset-geometry-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-tileset')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('tileset-geometry-chip')), matching: find.text('Isometric · 32px')),
          findsOneWidget);
      await tester.runAsync(() => tester.tap(find.byTooltip('Save collection')));
      await tester.pumpAndSettle();
      expect((saved!.perspective, saved!.tileSize), (TilesetPerspective.isometric, 32));
    });

    testWidgets('geometry can change only while the project has no tilesets', (tester) async {
      await sizeView(tester);
      final empty = TilesetCollection(name: 'World', perspective: TilesetPerspective.topDown, tileSize: 16);
      await tester.pumpWidget(MaterialApp(
          home: TilesetCollectionScreen(
              embedded: true, initialDocument: jsonEncode(empty.toJson()), onSaveCollection: (_) async {})));
      IconButton change() => tester.widget(find.byKey(const ValueKey('tileset-geometry-change')));
      expect(change().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('tileset-geometry-change')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tileset-size-48')));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('tileset-geometry-chip')), matching: find.text('Top-Down · 48px')),
          findsOneWidget);

      final locked = TilesetCollection(
          name: 'World', entries: [TilesetEntry(id: 'a', document: doc('Side', TilesetPerspective.side, 16))]);
      await tester.pumpWidget(MaterialApp(
          key: UniqueKey(),
          home: TilesetCollectionScreen(
              embedded: true, initialDocument: jsonEncode(locked.toJson()), onSaveCollection: (_) async {})));
      expect(change().onPressed, isNull);
    });

    testWidgets('a set generated with another geometry is flagged and adopts the project geometry when edited',
        (tester) async {
      await sizeView(tester);
      final migrated = TilesetCollection.fromJson(v1([
        TilesetEntry(id: 'a', document: doc('Top A', TilesetPerspective.topDown, 16)),
        TilesetEntry(id: 'b', document: doc('Top B', TilesetPerspective.topDown, 16)),
        TilesetEntry(id: 'c', document: doc('Odd one', TilesetPerspective.side, 32)),
      ]));
      await tester.pumpWidget(MaterialApp(
          home: TilesetCollectionScreen(
              embedded: true, initialDocument: jsonEncode(migrated.toJson()), onSaveCollection: (_) async {})));
      expect(find.byKey(const ValueKey('geometry-mismatch-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('geometry-mismatch-a')), findsNothing);
      await tester.tap(find.byTooltip('Manage Odd one'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit tileset'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('section-output')));
      await tester.pump();
      final summary = find.byKey(const ValueKey('set-geometry-summary'));
      expect(find.descendant(of: summary, matching: find.text('Top-Down')), findsOneWidget);
      expect(find.descendant(of: summary, matching: find.text('16 × 16 px')), findsOneWidget);
    });

    testWidgets('the creation dialog needs both choices and returns them', (tester) async {
      TilesetGeometry? result;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => TextButton(
                  onPressed: () async => result = await showTilesetGeometryDialog(context),
                  child: const Text('open')))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      FilledButton create() => tester.widget(find.widgetWithText(FilledButton, 'Create'));
      expect(create().onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('tileset-perspective-side')));
      await tester.pump();
      expect(create().onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('tileset-size-48')));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(result, (perspective: TilesetPerspective.side, size: 48));
    });
  });
}
