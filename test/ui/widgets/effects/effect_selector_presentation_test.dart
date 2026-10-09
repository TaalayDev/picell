import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/challenges_provider.dart';
import 'package:picell/data/models/challenge_models.dart';
import 'package:picell/ui/widgets/effects/effects_selector_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentChallengesProvider.overrideWith(_NoChallenges.new)],
      key: UniqueKey(),
      child: MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => EffectSelectorDialog.present(
                context: context,
                builder: (context) =>
                    EffectSelectorDialog(onEffectSelected: (_) {}),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('opens as a bottom sheet on small screens', (tester) async {
    await _open(tester, const Size(390, 844));

    expect(find.byType(EffectSelectorDialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(EffectSelectorDialog), findsNothing);
  });

  testWidgets('opens as a dialog on wide screens', (tester) async {
    await _open(tester, const Size(1200, 900));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });
}

class _NoChallenges extends CurrentChallengesNotifier {
  @override
  Future<CurrentChallenges?> build() async => null;
}
