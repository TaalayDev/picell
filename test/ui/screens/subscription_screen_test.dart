import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/subscription_provider.dart';
import 'package:picell/ui/screens/subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedSubscription extends SubscriptionState {
  _FixedSubscription(this.subscription);

  final UserSubscription subscription;

  @override
  UserSubscription build() => subscription;
}

Future<void> _pumpPaywall(
  WidgetTester tester, {
  required UserSubscription subscription,
  required List<PurchaseOffer> offers,
  Size size = const Size(360, 800),
  SubscriptionFeature? featurePrompt,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionStateProvider.overrideWith(() => _FixedSubscription(subscription)),
        purchaseOffersProvider.overrideWith((ref) => offers),
      ],
      child: MaterialApp(
        localizationsDelegates: Strings.localizationsDelegates,
        supportedLocales: Strings.supportedLocales,
        home: SubscriptionOfferScreen(featurePrompt: featurePrompt),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('free users choose between Free, Pro and Ultimate', (tester) async {
    await _pumpPaywall(
      tester,
      subscription: const UserSubscription.free(),
      offers: const [
        PurchaseOffer(plan: SubscriptionPlan.free),
        PurchaseOffer(plan: SubscriptionPlan.pro, productId: SubscriptionProductIds.pro, price: r'$4.99'),
        PurchaseOffer(
          plan: SubscriptionPlan.ultimate,
          productId: SubscriptionProductIds.ultimate,
          price: r'$19.99',
          isMostPopular: true,
        ),
      ],
    );

    expect(find.byKey(const ValueKey('plan-card-free')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-card-pro')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-card-ultimate')), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    // Ultimate is highlighted and preselected.
    expect(find.text('Get Ultimate'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Priority Support'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Compare Plans'), findsOneWidget);
    expect(find.text('All, including future'), findsOneWidget);
    expect(find.text('Add-on'), findsOneWidget);

    final proCard = find.byKey(const ValueKey('plan-card-pro'));
    await tester.scrollUntilVisible(proCard, -300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.descendant(of: proCard, matching: find.text('Pro')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Get Pro'), findsOneWidget);
  });

  testWidgets('desktop offers show rigging and omit ad promotions', (tester) async {
    await _pumpPaywall(
      tester,
      subscription: const UserSubscription.free(),
      offers: const [
        PurchaseOffer(plan: SubscriptionPlan.free),
        PurchaseOffer(plan: SubscriptionPlan.pro, productId: SubscriptionProductIds.pro, price: r'$4.99'),
      ],
    );
    expect(find.text('One-time purchase • No recurring charges • Lifetime access'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pro-rig-feature')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bone rigger'), findsWidgets);
    expect(find.text('Try Pro for Free!'), findsNothing);
    await tester.scrollUntilVisible(find.text('Priority Support'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Watch ads for Pro features'), findsNothing);
    expect(find.text('Watch ads for temporary access'), findsNothing);
    expect(find.text('No ads'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.macOS}));

  testWidgets('Pro owners are offered the Ultimate upgrade', (tester) async {
    await _pumpPaywall(
      tester,
      subscription: const UserSubscription(ownedProductIds: {SubscriptionProductIds.pro}),
      offers: const [
        PurchaseOffer(
          plan: SubscriptionPlan.ultimate,
          productId: SubscriptionProductIds.ultimateUpgrade,
          price: r'$14.99',
          isMostPopular: true,
          isUpgrade: true,
        ),
      ],
    );

    expect(find.byKey(const ValueKey('current-plan-card')), findsOneWidget);
    expect(find.text('Your plan: Pro'), findsOneWidget);
    expect(find.text('Upgrade your Pro and unlock everything forever'), findsOneWidget);
    expect(find.text('Upgrade to Ultimate'), findsOneWidget);
    expect(find.text('Continue with Free'), findsNothing);
  });

  testWidgets('Ultimate owners see their plan and nothing to buy', (tester) async {
    await _pumpPaywall(
      tester,
      subscription: const UserSubscription(ownedProductIds: {SubscriptionProductIds.ultimate}),
      offers: const [],
    );

    expect(find.text('Your plan: Ultimate'), findsOneWidget);
    expect(find.byKey(const ValueKey('own-everything')), findsOneWidget);
    expect(find.text('Everything is unlocked. Thank you for your support!'), findsOneWidget);
    expect(find.byKey(const ValueKey('purchase-button')), findsNothing);
  });

  const allOffers = [
    PurchaseOffer(plan: SubscriptionPlan.free),
    PurchaseOffer(plan: SubscriptionPlan.pro, productId: SubscriptionProductIds.pro, price: r'$9.99'),
    PurchaseOffer(
      plan: SubscriptionPlan.ultimate,
      productId: SubscriptionProductIds.ultimate,
      price: r'$24.99',
      isMostPopular: true,
    ),
  ];

  testWidgets('wide screens lay the three plans out side by side', (tester) async {
    await _pumpPaywall(
      tester,
      subscription: const UserSubscription.free(),
      offers: allOffers,
      size: const Size(1280, 800),
    );

    final free = tester.getTopLeft(find.byKey(const ValueKey('plan-card-free')));
    final pro = tester.getTopLeft(find.byKey(const ValueKey('plan-card-pro')));
    final ultimate = tester.getTopLeft(find.byKey(const ValueKey('plan-card-ultimate')));
    expect(free.dx, lessThan(pro.dx));
    expect(pro.dx, lessThan(ultimate.dx));
    expect(find.text('Get Ultimate'), findsOneWidget);
    // The bar hugs the bottom edge instead of taking the whole screen.
    final bar = tester.getRect(find.byKey(const ValueKey('purchase-button')));
    expect(bar.bottom, greaterThan(700));
    expect(bar.height, 56);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a locked feature is named above the plans', (tester) async {
    await _pumpPaywall(
      tester,
      subscription: const UserSubscription.free(),
      offers: allOffers,
      featurePrompt: SubscriptionFeature.cloudBackup,
    );

    expect(find.byKey(const ValueKey('locked-feature-tile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
