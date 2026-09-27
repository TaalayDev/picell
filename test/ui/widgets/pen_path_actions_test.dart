import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/pen_path_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  Widget buildSubject({
    required bool isFloating,
    required VoidCallback onFinish,
    required VoidCallback onCancel,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: Scaffold(
          body: Center(
            child: PenPathActions(
              isFloating: isFloating,
              onFinish: onFinish,
              onCancel: onCancel,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('top bar variant exposes finish and cancel icon buttons',
      (tester) async {
    var finishes = 0;
    var cancellations = 0;

    await tester.pumpWidget(buildSubject(
      isFloating: false,
      onFinish: () => finishes++,
      onCancel: () => cancellations++,
    ));

    await tester.tap(find.byKey(const ValueKey('finish-pen-path')));
    await tester.tap(find.byKey(const ValueKey('cancel-pen-path')));

    expect(finishes, 1);
    expect(cancellations, 1);
    expect(find.text('Done'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('mobile variant groups the icon buttons in a floating surface',
      (tester) async {
    await tester.pumpWidget(buildSubject(
      isFloating: true,
      onFinish: () {},
      onCancel: () {},
    ));

    final finish = find.byKey(const ValueKey('finish-pen-path'));
    final cancel = find.byKey(const ValueKey('cancel-pen-path'));

    expect(finish, findsOneWidget);
    expect(cancel, findsOneWidget);
    expect(
      find.ancestor(of: finish, matching: find.byType(DecoratedBox)),
      findsWidgets,
    );
  });
}
