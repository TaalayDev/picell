import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/progression_model.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effect_pack_catalog.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/providers/progression_provider.dart';
import 'package:picell/providers/subscription_provider.dart';
import 'package:picell/ui/screens/effect_store_screen.dart';
import 'package:picell/ui/widgets/progression/quests_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FreeSubscription extends SubscriptionState {
  @override
  UserSubscription build() => const UserSubscription.free();
}

class _SeededProgression extends ProgressionNotifier {
  _SeededProgression(this.seed);

  final ProgressionState seed;

  @override
  ProgressionState build() {
    super.build();
    return seed;
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, ProgressionState seed, Widget home) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        subscriptionStateProvider.overrideWith(_FreeSubscription.new),
        progressionProvider.overrideWith(() => _SeededProgression(seed)),
      ],
      child: MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  final today = DateTime.now();

  testWidgets('completed quests can be claimed once for gems', (tester) async {
    final seed = const ProgressionState().rollDay(today).record(ProgressionEvent.projectCreated, today).$1;
    final container = await _pump(
      tester,
      seed,
      const EffectStoreScreen(initialTab: EffectStoreTab.quests),
    );

    expect(find.text('Getting started'), findsOneWidget);
    final claim = find.byKey(const ValueKey('claim-first_project'));
    await tester.ensureVisible(claim);
    await tester.tap(claim);
    await tester.pump(const Duration(milliseconds: 300));

    final quest = QuestCatalog.byId['first_project']!;
    expect(container.read(progressionProvider).coins, seed.coins + quest.coins);
    expect(find.byKey(const ValueKey('claim-first_project')), findsNothing);
    expect(
      find.descendant(of: find.byKey(const ValueKey('wallet-chip')), matching: find.text('${seed.coins + quest.coins}')),
      findsOneWidget,
    );
  });

  testWidgets('effects can be unlocked one by one with gems', (tester) async {
    final container = await _pump(
      tester,
      const ProgressionState(coins: 1000),
      const EffectPackScreen(packId: EffectPackId.artistic),
    );

    final price = CoinPrices.effect(EffectType.watercolor);
    final watercolorTile = find.byKey(const ValueKey('pack-effect-tile-watercolor'));
    expect(find.descendant(of: watercolorTile, matching: find.text('$price')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pack-effect-tile-watercolor')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('confirm-unlock-effect')));
    await tester.pump(const Duration(milliseconds: 300));

    final state = container.read(progressionProvider);
    expect(state.coins, 1000 - price);
    expect(state.earnedEffects, contains(EffectType.watercolor));
    expect(container.read(effectAccessProvider(EffectType.watercolor)), isTrue);
    expect(container.read(effectAccessProvider(EffectType.oilPaint)), isFalse);
  });

  testWidgets('unlocking without enough gems changes nothing', (tester) async {
    final container = await _pump(
      tester,
      const ProgressionState(coins: 10),
      const EffectPackScreen(packId: EffectPackId.artistic),
    );

    await tester.tap(find.byKey(const ValueKey('pack-effect-tile-watercolor')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('confirm-unlock-effect')), findsNothing);

    final unlockPack = find.byKey(const ValueKey('unlock-pack-with-coins'));
    await tester.ensureVisible(unlockPack);
    await tester.tap(unlockPack);
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(progressionProvider).coins, 10);
    expect(container.read(effectPackAccessProvider(EffectPackId.artistic)), isFalse);
  });

  testWidgets('a pack bought with gems shows as owned without a buy bar', (tester) async {
    await _pump(
      tester,
      const ProgressionState(earnedPacks: {EffectPackId.materials}),
      const EffectPackScreen(packId: EffectPackId.materials),
    );
    expect(find.byKey(const ValueKey('buy-effect-pack')), findsNothing);
    expect(find.byKey(const ValueKey('pack-effect-tile-wood')), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('pack-effect-tile-wood')), matching: find.byType(GemAmount)),
      findsNothing,
    );
  });
}
