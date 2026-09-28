import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/progression_model.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/progression_provider.dart';
import 'package:picell/providers/subscription_provider.dart';
import 'package:picell/ui/screens/effect_store_screen.dart';
import 'package:picell/ui/widgets/progression/progression_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FreeSubscription extends SubscriptionState {
  @override
  UserSubscription build() => const UserSubscription.free();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('a completed quest is announced over other routes and opens quests', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionStateProvider.overrideWith(_FreeSubscription.new)],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: const ProgressionNotifications(child: Scaffold(body: Text('home'))),
        ),
      ),
    );
    await tester.pump();

    // The editor or any other screen is on top of home.
    navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('editor'))));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.text('editor')));
    container.read(progressionProvider.notifier).record(ProgressionEvent.projectCreated);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Quest complete: Create a project'), findsOneWidget);

    await tester.tap(find.text('Claim'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final store = tester.widget<EffectStoreScreen>(find.byType(EffectStoreScreen));
    expect(store.initialTab, EffectStoreTab.quests);

    // Let the notification's timers finish.
    await tester.pump(const Duration(seconds: 10));
  });
}
