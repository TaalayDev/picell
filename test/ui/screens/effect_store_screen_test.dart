import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effect_pack_catalog.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/providers/subscription_provider.dart';
import 'package:picell/ui/screens/effect_store_screen.dart';
import 'package:picell/ui/widgets/effects/effect_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedSubscription extends SubscriptionState {
  _FixedSubscription(this.subscription);

  final UserSubscription subscription;

  @override
  UserSubscription build() => subscription;
}

Future<void> _pump(
  WidgetTester tester,
  UserSubscription subscription,
  Widget home, {
  Size size = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      // A fresh scope, so re-pumping applies the new subscription override.
      key: UniqueKey(),
      overrides: [
        subscriptionStateProvider.overrideWith(() => _FixedSubscription(subscription)),
      ],
      child: MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  final artisticOwner = UserSubscription(
    ownedProductIds: {SubscriptionProductIds.pack(EffectPackId.artistic)},
  );

  testWidgets('store lists every pack and offers Ultimate', (tester) async {
    // Tall enough for every pack card to be built.
    await _pump(tester, artisticOwner, const EffectStoreScreen(), size: const Size(1080, 9000));

    expect(find.text('Get every pack with Ultimate'), findsOneWidget);
    final cardTops = {
      for (final id in EffectPackId.values) id: tester.getTopLeft(find.byKey(ValueKey('effect-pack-${id.name}'))).dy,
    };
    // Packs still for sale come first, then owned ones, then the free pack.
    expect(cardTops[EffectPackId.materials]!, lessThan(cardTops[EffectPackId.artistic]!));
    expect(cardTops[EffectPackId.artistic]!, lessThan(cardTops[EffectPackId.free]!));
    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('In Pro'), findsOneWidget);
  });

  testWidgets('Ultimate owners see every pack unlocked', (tester) async {
    await _pump(
      tester,
      const UserSubscription(ownedProductIds: {SubscriptionProductIds.ultimate}),
      const EffectStoreScreen(),
    );

    expect(find.text('All effect packs are unlocked'), findsOneWidget);
    expect(find.text('Get every pack with Ultimate'), findsNothing);
  });

  testWidgets('pack page shows its effects and a buy bar until owned', (tester) async {
    await _pump(tester, const UserSubscription.free(), const EffectPackScreen(packId: EffectPackId.materials));

    expect(find.text('Materials & Textures'), findsOneWidget);
    expect(find.text('15 effects'), findsOneWidget);
    // No store products in tests, so the pack cannot be bought yet.
    final buyButton = tester.widget<FilledButton>(find.byKey(const ValueKey('buy-effect-pack')));
    expect(buyButton.onPressed, isNull);
    expect(find.text('Not available yet'), findsOneWidget);

    await _pump(tester, artisticOwner, const EffectPackScreen(packId: EffectPackId.artistic));
    expect(find.byKey(const ValueKey('buy-effect-pack')), findsNothing);
  });

  testWidgets('effects from unowned packs are locked in the layer stack', (tester) async {
    var editCalls = 0;
    await _pump(
      tester,
      const UserSubscription.free(),
      Scaffold(
        body: EffectListItem(
          effect: WatercolorEffect(),
          isSelected: false,
          onSelect: () {},
          onEdit: () => editCalls++,
          onRemove: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('locked-effect-badge')), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);

    await tester.tap(find.byKey(const ValueKey('locked-effect-badge')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(editCalls, 0);
    expect(find.byType(EffectPackScreen), findsOneWidget);
    expect(find.text('Artistic Styles'), findsOneWidget);
  });

  testWidgets('owned effects stay editable', (tester) async {
    await _pump(
      tester,
      artisticOwner,
      Scaffold(
        body: EffectListItem(
          effect: WatercolorEffect(),
          isSelected: false,
          onSelect: () {},
          onEdit: () {},
          onRemove: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('locked-effect-badge')), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
