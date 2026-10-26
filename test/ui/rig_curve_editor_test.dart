import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/screens/rig_editor/rig_curve_editor.dart';

void main() {
  testWidgets('dragging a handle and applying returns the edited curve', (tester) async {
    EasingCurve? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        Strings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: Strings.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showEasingCurveDialog(context, EasingCurve.linear),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('cubic-bezier(0.00, 0.00, 1.00, 1.00)'), findsOneWidget);
    final area = tester.getRect(find.byKey(const Key('rigCurveArea')));
    // The first handle sits at x=0, y=0 (the bottom edge of the 0..1 band).
    final start = Offset(area.left + 3, area.top + area.height * 0.75);
    await tester.dragFrom(start, Offset(area.width * 0.4, -area.height * 0.5));
    await tester.pump();
    expect(find.text('cubic-bezier(0.00, 0.00, 1.00, 1.00)'), findsNothing);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.x1, greaterThan(.2));
    expect(result!.y1, greaterThan(.3));
    expect([result!.x2, result!.y2], [1, 1]);
  });

  testWidgets('cancel returns null', (tester) async {
    EasingCurve? result = EasingCurve.linear;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        Strings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: Strings.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showEasingCurveDialog(context, EasingCurve.linear),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
