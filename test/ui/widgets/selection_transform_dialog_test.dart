import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/dialogs/selection_transform_dialog.dart';

void main() {
  Future<SelectionTransformRequest?> run(WidgetTester tester, Future<void> Function() edit) async {
    SelectionTransformRequest? result;
    var closed = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showSelectionTransformDialog(context, bounds: const Rect.fromLTWH(2, 3, 10, 5));
            closed = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await edit();
    await tester.tap(find.byKey(const ValueKey('selection-transform-apply')));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    return result;
  }

  Finder field(String key) => find.byKey(ValueKey('selection-transform-$key'));

  testWidgets('applying without edits asks for nothing', (tester) async {
    final request = await run(tester, () async {});
    expect(request!.bounds, isNull);
    expect(request.angleDegrees, 0);
    expect(request.flipHorizontal, isFalse);
  });

  testWidgets('position, size, angle and flips come back typed', (tester) async {
    final request = await run(tester, () async {
      await tester.tap(find.byKey(const ValueKey('selection-transform-keep-aspect')));
      await tester.pump();
      await tester.enterText(field('x'), '-1');
      await tester.enterText(field('w'), '20');
      await tester.enterText(field('angle'), '-22.5');
      await tester.tap(find.byKey(const ValueKey('selection-transform-flip-v')));
      await tester.pump();
    });
    expect(request!.bounds, const Rect.fromLTWH(-1, 3, 20, 5));
    expect(request.angleDegrees, -22.5);
    expect(request.flipVertical, isTrue);
    expect(request.flipHorizontal, isFalse);
  });

  testWidgets('with the aspect locked, width drives height', (tester) async {
    final request = await run(tester, () async {
      await tester.enterText(field('w'), '20');
      await tester.pump();
    });
    expect(request!.bounds, const Rect.fromLTWH(2, 3, 20, 10));
  });
}
