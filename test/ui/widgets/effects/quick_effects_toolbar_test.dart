import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/quick_effects_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('quick toolbar is generated from functional workspaces',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Effect? selectedEffect;
    final layer = Layer(
      layerId: 1,
      id: 'layer',
      name: 'Layer',
      pixels: Uint32List.fromList([0xFFFFFFFF]),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: QuickEffectsToolbar(
              layer: layer,
              onApplyEffect: (effect) => selectedEffect = effect,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final workspace in EffectWorkspace.values) {
      expect(
        find.byKey(ValueKey('quick-effects-workspace-${workspace.name}')),
        findsOneWidget,
      );
    }
    expect(find.text('Invert'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('quick-effects-workspace-materials')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Wood');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Wood'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(selectedEffect, isA<WoodEffect>());

    await tester.tap(
      find.byKey(const ValueKey('quick-effects-workspace-animation')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('animation-kind-transformer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('animation-kind-specialEffect')),
      findsOneWidget,
    );
  });
}
