import 'package:flutter/material.dart';
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
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
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
        home: const SubscriptionOfferScreen(),
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

    expect(find.text('Basic pixel art creation'), findsOneWidget);
    expect(find.text('All tools and features, one-time purchase'), findsOneWidget);
    expect(find.text('Everything forever, including future effect packs'), findsOneWidget);
    // Ultimate is highlighted and preselected.
    expect(find.text('Get Ultimate'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Priority Support'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Compare Plans'), findsOneWidget);
    expect(find.text('All, including future'), findsOneWidget);
    expect(find.text('Add-on'), findsOneWidget);

    final proCard = find.text('All tools and features, one-time purchase');
    await tester.ensureVisible(proCard);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(proCard);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Get Pro'), findsOneWidget);
  });

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
    expect(find.text('Everything is unlocked. Thank you for your support!'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
