import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:picell/pixel/tileset/tileset_configuration.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('native canvas shares zoom, pans, picks pixels, and respects field focus', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
            embedded: true,
            recipeMode: true,
            configuration: TilesetConfiguration(perspective: TilesetPerspective.topDown))));
    await tester.pumpAndSettle();
    final viewer = find.byKey(const ValueKey('creator-preview-Repeat'));
    TransformationController transform() => tester.widget<InteractiveViewer>(viewer).transformationController!;
    final initial = transform().value.getMaxScaleOnAxis();
    await tester.tap(find.byTooltip('Workbench zoom in'));
    await tester.pumpAndSettle();
    expect(transform().value.getMaxScaleOnAxis(), closeTo(initial * 1.25, 0.001));
    expect(find.text('${(initial * 125).round()}%'), findsOneWidget);
    final beforeWheel = transform().value.getMaxScaleOnAxis();
    await tester
        .sendEventToBinding(PointerScrollEvent(position: tester.getCenter(viewer), scrollDelta: const Offset(0, -100)));
    await tester.pumpAndSettle();
    expect(transform().value.getMaxScaleOnAxis(), greaterThan(beforeWheel));
    final beforePan = transform().value.getTranslation();
    await tester.drag(viewer, const Offset(30, 20));
    await tester.pumpAndSettle();
    expect(transform().value.getTranslation(), isNot(beforePan));
    await tester.tap(find.text('Fit'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(viewer));
    await tester.pump();
    expect(find.byKey(const ValueKey('creator-hover-status')), findsOneWidget);
    await tester.tap(find.byTooltip('Eyedropper (I)'));
    await tester.tapAt(tester.getCenter(viewer));
    await tester.pump();
    expect(find.byKey(const ValueKey('creator-picked-color')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(transform().value.getMaxScaleOnAxis(), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(transform().value.getMaxScaleOnAxis(), 1.25);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    final beforeSpacePan = transform().value.getTranslation();
    expect(tester.widget<InteractiveViewer>(viewer).panEnabled, isTrue);
    await tester.drag(viewer, const Offset(80, 50));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(transform().value.getTranslation(), isNot(beforeSpacePan));
    expect(transform().value.getMaxScaleOnAxis(), closeTo(1.25, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.pumpAndSettle();
    final beforeRepeat = Matrix4.copy(transform().value);
    await tester.tap(find.byKey(const ValueKey('workbench-repeat-2')));
    await tester.pumpAndSettle();
    expect(transform().value, beforeRepeat);
    final paint = tester.widget<InteractiveViewer>(viewer).child as CustomPaint;
    expect(paint.size, const Size(32, 32));
    expect(paint.foregroundPainter, isNotNull);
    await tester.ensureVisible(find.byKey(const ValueKey('creator-pixel-grid')));
    await tester.tap(find.byKey(const ValueKey('creator-pixel-grid')));
    await tester.pumpAndSettle();
    expect((tester.widget<InteractiveViewer>(viewer).child as CustomPaint).foregroundPainter, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('creator-actual-pixels')));
    await tester.tap(find.byKey(const ValueKey('creator-actual-pixels')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('creator-options-seed')));
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(transform().value.getMaxScaleOnAxis(), 1);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });
  testWidgets('prototype Library searches, replaces surfaces, and remembers collapse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget editor() => MaterialApp(
        home: TilesetGeneratorScreen(
            embedded: true,
            recipeMode: true,
            configuration: TilesetConfiguration(perspective: TilesetPerspective.topDown)));
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('creator-properties-dock')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('creator-library-search')), 'lava');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-preset-lava')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-preset-grass')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('library-preset-lava')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace surface'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('creator-tool-surface')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byKey(const ValueKey('surface-name')));
    expect(field.controller!.text, TilesetSurfacePresets.lava.name);
    await tester.tap(find.byTooltip('Collapse library'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand library'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in const [Size(1440, 900), Size(800, 700), Size(390, 844)]) {
    testWidgets('surface workspace remains usable at $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: TilesetGeneratorScreen(
        embedded: true,
        recipeMode: true,
        configuration: TilesetConfiguration(perspective: TilesetPerspective.topDown),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('creator-editor-resize')), findsOneWidget);
      await tester.tap(find.byTooltip('Collapse library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('creator-editor-resize')), findsNothing);
      await tester.tap(find.byTooltip('Palette'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('palette-edit')), findsOneWidget);
      if (size.width < 1000) {
        await tester.tap(find.byTooltip('Close properties'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('workspace-tab-map')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-toggle-tiles')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-toggle-tiles')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-tab-creator')));
      await tester.pumpAndSettle();
      if (size.width >= 1000) expect(find.byKey(const ValueKey('palette-edit')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('creator-view-Connection Shapes')));
      await tester.tap(find.byKey(const ValueKey('creator-view-Connection Shapes')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workbench-shape-strip')), findsOneWidget);
      if (size.width < 1000) {
        await tester.tap(find.byTooltip('Layers and properties'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const ValueKey('creator-tool-output')));
      await tester.tap(find.byKey(const ValueKey('creator-tool-output')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('generation stays in creator and Test on Map opens generated tiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: TilesetGeneratorScreen(
      embedded: true,
      recipeMode: true,
      configuration: TilesetConfiguration(perspective: TilesetPerspective.topDown),
    )));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.byKey(const ValueKey('surface-generate'))));
    await tester.pump();
    for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('LIVE TILE WORKBENCH'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workbench-open-map')));
    await tester.pumpAndSettle();
    expect(find.text('GENERATED TILES'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('generated-tiles-search')), 'no-such-tile');
    await tester.pumpAndSettle();
    expect(find.text('No matching tiles'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear tile search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('generated-tiles-protected')));
    await tester.pumpAndSettle();
    expect(find.text('No matching tiles'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('generated-tiles-protected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-sample-layout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empty'));
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('tileset-map-canvas'));
    final dynamic emptyPainter = tester.widget<CustomPaint>(canvas).painter;
    expect(emptyPainter.cells, everyElement(0));
    await tester.tap(find.byTooltip('Undo stroke'));
    await tester.pumpAndSettle();
    final dynamic restoredPainter = tester.widget<CustomPaint>(canvas).painter;
    expect(restoredPainter.cells, contains(1));
    expect(tester.takeException(), isNull);
  });
}
