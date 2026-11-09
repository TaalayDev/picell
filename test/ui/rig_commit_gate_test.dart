import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/screens/rig_editor/rig_editor_screen.dart';
import 'package:picell/ui/widgets/notifications/app_notification.dart';

void main() {
  late List<Rig?> results;
  var asked = 0;

  setUp(AppNotification.dismissAll);
  tearDown(AppNotification.dismissAll);

  Future<void> open(WidgetTester tester, {Future<bool> Function()? gate}) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    results = [];
    asked = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => results.add(await RigEditorScreen.show(
            context,
            rig: const Rig(id: 'r', stateId: 1),
            restLayers: [Layer(layerId: 0, id: 'id', name: 'Body', pixels: Uint32List(256), stableKey: 'body')],
            width: 16,
            height: 16,
            commitGate: gate == null
                ? null
                : () {
                    asked++;
                    return gate();
                  },
          )),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('without a gate Done keeps the rig', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('rig-done')));
    await tester.pumpAndSettle();
    expect(results.single, isNotNull);
  });

  testWidgets('a refusing gate keeps the user in the editor and the rig unsaved', (tester) async {
    await open(tester, gate: () async => false);
    await tester.tap(find.byKey(const ValueKey('rig-done')));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(results, isEmpty);
    expect(find.byKey(const ValueKey('rig-done')), findsOneWidget);
  });

  testWidgets('an allowing gate lets Done return the rig', (tester) async {
    await open(tester, gate: () async => true);
    await tester.tap(find.byKey(const ValueKey('rig-done')));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(results.single, isNotNull);
  });
}
