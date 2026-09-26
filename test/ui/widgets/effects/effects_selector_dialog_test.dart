import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/effects/effects_selector_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('texture category exposes the new material effects',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(onEffectSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(ListView), const Offset(-1000, 0));
    await tester.pump();
    await tester.ensureVisible(find.text('Textures'));
    await tester.tap(find.text('Textures'));
    await tester.pump();

    final search = find.byType(TextField);
    for (final name in [
      'Rust & Corrosion',
      'Worn Fabric',
      'Cracked Ceramic',
      'Moss & Lichen',
      'Paint Peeling',
    ]) {
      await tester.enterText(search, name);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text(name),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('artistic category exposes the stylized transform effects',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(onEffectSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView), const Offset(-250, 0));
    await tester.pump();
    await tester.tap(find.text('Artistic'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('Artistic'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );

    final search = find.byType(TextField);
    for (final name in [
      'Kaleidoscope',
      'Topographic Contours',
      'Isometric Extrusion',
      'Paper Cutout',
      'Cel Shading',
      'Low-Poly Facets',
      'ASCII Mosaic',
    ]) {
      await tester.enterText(search, name);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text(name),
        ),
        findsOneWidget,
      );
    }
  });
}
