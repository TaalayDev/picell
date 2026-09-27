import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/screens/effect_icon_generator_screen.dart';

void main() {
  testWidgets('filters exportable effect icons by functional workspace',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: EffectIconGeneratorScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Effect Icon Generator'), findsOneWidget);
    expect(
      find.text('Export visible (${EffectType.values.length})'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Generators'));
    await tester.pump();

    final generatorCount = EffectCatalog.inWorkspace(
      EffectWorkspace.generators,
    ).length;
    expect(find.text('Export visible ($generatorCount)'), findsOneWidget);
    expect(find.text('Empty source'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('effect-icon-search')),
      'mountainRange',
    );
    await tester.pump();

    expect(find.text('Export visible (1)'), findsOneWidget);
    expect(find.text('Mountain Range'), findsOneWidget);
    expect(find.text('GIF'), findsOneWidget);
  });
}
