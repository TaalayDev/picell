import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

void main() {
  testWidgets('desktop setup shows perspective-first controls and no mock output', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(const MaterialApp(home: TilesetGeneratorScreen()));
    expect(find.text('1 · PERSPECTIVE'), findsOneWidget);
    expect(find.text('2 · TILESET TYPE'), findsOneWidget);
    expect(find.text('Generate Tileset'), findsOneWidget);
    expect(find.text('GENERATED TILES'), findsOneWidget);
    expect(find.text('One click, one matching tileset'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => tester.tap(find.text('Generate Tileset')));
    await tester.pump();
    for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('188 tiles · 47 connection shapes'), findsOneWidget);
    expect(find.text('Edit Pixels'), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.text('Edit Pixels')));
    await tester.pumpAndSettle();
    expect(find.text('Apply & Protect'), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.text('Apply & Protect')));
    await tester.pump();
    for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.textContaining('1 protected'), findsOneWidget);
    await tester.tap(find.text('Ground'));
    await tester.pump();
    expect(find.textContaining('Generate to apply Side View · Ground'), findsOneWidget);
    await tester.tap(find.text('Regenerate Tileset'));
    await tester.pump();
    expect(find.textContaining('unlock protected tiles before changing tileset type'), findsOneWidget);
    expect(find.textContaining('1 protected'), findsOneWidget);
    await tester.tap(find.ancestor(of: find.text('Top-Down'), matching: find.byType(ChoiceChip)));
    await tester.pump();
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.textContaining('Showing Side View'), findsOneWidget);
    await tester.tap(find.text('Regenerate Tileset'));
    await tester.pump();
    expect(find.textContaining('unlock protected tiles before changing perspective'), findsOneWidget);
    expect(find.text('Sample Level'), findsOneWidget);
    expect(find.textContaining('1 protected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screen exposes settings, preview and tile tabs', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: TilesetGeneratorScreen()));
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Sample Level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
