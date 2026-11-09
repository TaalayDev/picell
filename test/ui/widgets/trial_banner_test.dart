import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/subscription_provider.dart';
import 'package:picell/ui/widgets/trial_banner.dart';

class _Subscription extends SubscriptionState {
  _Subscription(this.value);
  final UserSubscription value;

  @override
  UserSubscription build() => value;
}

Future<void> _pump(WidgetTester tester, UserSubscription subscription) => tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionStateProvider.overrideWith(() => _Subscription(subscription))],
        child: const MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(body: Column(children: [TrialBanner()])),
        ),
      ),
    );

PlanTrial _ending(Duration d, [SubscriptionPlan tier = SubscriptionPlan.ultimate]) =>
    PlanTrial(tier: tier, endsAt: DateTime.now().add(d));

void main() {
  testWidgets('shows the days left of a running trial', (tester) async {
    await _pump(tester, UserSubscription(planTrial: _ending(const Duration(days: 4, hours: 3))));
    expect(find.byKey(const ValueKey('trial-banner')), findsOneWidget);
    expect(find.textContaining('Ultimate trial'), findsOneWidget);
    expect(find.textContaining('5 days left'), findsOneWidget);
  });

  testWidgets('says it ends today in the last 24 hours', (tester) async {
    await _pump(tester, UserSubscription(planTrial: _ending(const Duration(hours: 6), SubscriptionPlan.pro)));
    expect(find.text('Pro trial ends today'), findsOneWidget);
  });

  testWidgets('hidden without a trial, after it ended, or once a plan is bought', (tester) async {
    await _pump(tester, const UserSubscription.free());
    expect(find.byKey(const ValueKey('trial-banner')), findsNothing);

    await _pump(tester, UserSubscription(planTrial: _ending(const Duration(hours: -1))));
    expect(find.byKey(const ValueKey('trial-banner')), findsNothing);

    await _pump(
      tester,
      UserSubscription(
        ownedProductIds: const {SubscriptionProductIds.ultimate},
        planTrial: _ending(const Duration(days: 3)),
      ),
    );
    expect(find.byKey(const ValueKey('trial-banner')), findsNothing);
  });
}
