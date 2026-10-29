import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picell/pixel/tileset/tileset_collection.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_collection_screen.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_geometry_picker.dart';

Future<void> waitForWork(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 150 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

/// Centres [finder] in the settings list so the pinned footer cannot cover it.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, 120));
    await tester.pump();
  }
  final box = tester.getRect(finder), view = tester.getRect(list);
  await tester.drag(list, Offset(0, view.center.dy - box.center.dy));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('set settings persist separately from pixels and are consumed by generation', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = TilesetSettings(variations: 1);
    final tiles = generateTileset(settings);
    tiles.first.pixels[100] = 0xffff00ff;
    final d = TilesetDocument(name: 'Ground', settings: settings, tiles: tiles, cells: [1], columns: 1, rows: 1);
    TilesetCollection? saved;
    await tester.pumpWidget(MaterialApp(
        home: TilesetCollectionScreen(
            initialDocument: jsonEncode(d.toJson()), onSaveCollection: (collection) async => saved = collection)));
    await tester.tap(find.byTooltip('Manage Ground'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit tileset'));
    await waitForWork(tester);
    // Settings live inside the generator now; there is no separate settings page.
    expect(find.text('Tileset settings'), findsNothing);
    expect(find.byType(TilesetGeneratorScreen), findsOneWidget);
    // Geometry is chosen once for the project and cannot be edited per set.
    expect(find.text('1 · PERSPECTIVE'), findsNothing);
    expect(find.byType(TilesetGeometryPicker), findsNothing);
    await tester.tap(find.byKey(const ValueKey('section-output')));
    await tester.pumpAndSettle();
    final summary = find.byKey(const ValueKey('set-geometry-summary'));
    expect(find.descendant(of: summary, matching: find.text('Side View')), findsOneWidget);
    expect(find.descendant(of: summary, matching: find.text('16 × 16 px')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-look')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('surface-open-presets')));
    await tester.tap(find.byKey(const ValueKey('surface-open-presets')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('gallery-search')), 'ice');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('preset-ice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-output')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('global-seed')));
    await tester.enterText(find.byKey(const ValueKey('global-seed')), '314');
    await tester.pump();
    await tester.runAsync(() => tester.tap(find.text('REGENERATE TILESET')));
    await waitForWork(tester);
    await tester.runAsync(() => tester.tap(find.text('Save to collection')));
    await waitForWork(tester);
    final entry = saved!.entries.single;
    expect(entry.resolvedConfiguration.perspective, TilesetPerspective.side);
    expect(entry.resolvedConfiguration.size, 16);
    expect(entry.resolvedConfiguration.seed, 314);
    expect(entry.document.settings.perspective, TilesetPerspective.side);
    expect(entry.document.settings.size, 16);
    expect(entry.document.settings.seed, 314);
    expect(entry.document.settings.palette, TilesetSurfacePresets.ice.palette);
    expect(entry.document.tiles.first.pixels.length, 16 * 16);
    final restored = TilesetCollection.fromJson(jsonDecode(jsonEncode(saved!.toJson())) as Map<String, dynamic>);
    expect(restored.entries.single.resolvedConfiguration.seed, 314);
    expect(tester.takeException(), isNull);
  });
}
