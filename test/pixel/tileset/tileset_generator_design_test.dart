import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

void main() {
  testWidgets('ready desktop workspace groups variants and renders the design without overflow', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final errorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      errorHandler!(details);
    };
    addTearDown(() => FlutterError.onError = errorHandler);
    await tester.runAsync(() async {
      for (final entry in {
        'Inter': '/System/Library/Fonts/Supplemental/Arial.ttf',
        'monospace': '/System/Library/Fonts/Menlo.ttc',
        'Ahem': '/System/Library/Fonts/Supplemental/Arial.ttf'
      }.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          final loader = FontLoader(entry.key)..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
          await loader.load();
        }
      }
    });
    await tester.runAsync(() async {
      final loader = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await loader.load();
    });
    final s = TilesetSettings();
    final rows = [
      '........................',
      '........................',
      '....#####..........##...',
      '....#####..........##...',
      '........................',
      '..........####..........',
      '........................',
      '..###.............#.....',
      '..###......#......#.....',
      '##.........#......#.....',
      '#######...##############',
      '#######...##############',
      '#######...##############',
      '########################'
    ];
    final doc = TilesetDocument(
        name: 'Meadow Platforms',
        settings: s,
        tiles: generateTileset(s),
        cells:
            rows.expand((r) => r.padRight(24, '.').substring(0, 24).split('').map((c) => c == '#' ? 1 : 0)).toList());
    final boundary = GlobalKey();
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
            key: boundary,
            child: TilesetGeneratorScreen(
                embedded: true, initialDocument: jsonEncode(doc.toJson()), onSaveProject: (_) async {})))));
    for (var i = 0; i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final render = boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${Directory.systemTemp.path}/pv_tileset_ready_ui.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    // Widget presence alone cannot catch a painter erasing earlier siblings.
    // Check pixels outside the map after each background transition.
    for (final background in ['Flat', 'Checker', 'Sky', 'Flat']) {
      await tester.tap(find.byTooltip('$background background'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        try {
          final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          for (final sample in [
            (x: 5, y: 5, color: const Color(0xff1a1b1f)), // Header.
            (x: 5, y: 300, color: const Color(0xff1a1b1f)), // Settings sidebar.
            (x: 300, y: 55, color: const Color(0xff141518)), // Preview toolbar.
          ]) {
            final offset = (sample.y * image.width + sample.x) * 4;
            final actual = Color.fromARGB(
                rgba.getUint8(offset + 3), rgba.getUint8(offset), rgba.getUint8(offset + 1), rgba.getUint8(offset + 2));
            expect(actual, sample.color, reason: '$background must preserve UI at ${sample.x},${sample.y}');
          }
        } finally {
          image.dispose();
        }
      });
    }
    expect(find.byKey(const ValueKey('tileset-variant-110:3')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tileset-variant-110:3')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(320, 740);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiles'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Pixels'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
