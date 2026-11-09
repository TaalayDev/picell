import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/models/trial_model.dart';
import 'package:picell/pixel/effects/effect_pack_catalog.dart';

TrialGrantInfo _plan(String tier, DateTime end) => TrialGrantInfo(
      kind: 'plan',
      subject: 'plan',
      tier: tier,
      startedAt: DateTime.utc(2026, 11, 1),
      expiresAt: end,
    );

void main() {
  final now = DateTime.utc(2026, 11, 10);

  group('TrialsState', () {
    test('plan trial is active until its end, then gone', () {
      final state = TrialsState(grants: [_plan('ultimate', DateTime.utc(2026, 11, 12))]);
      expect(state.planTrialAt(now)?.tier, SubscriptionPlan.ultimate);
      expect(state.planTrialAt(DateTime.utc(2026, 11, 12)), isNull);
      expect(state.planTrialUsed, isTrue);
    });

    test('rig and pack trials apply to their own project only', () {
      final state = TrialsState(grants: [
        TrialGrantInfo(kind: 'rig', subject: 'rig', projectKey: 'a', startedAt: now),
        TrialGrantInfo(kind: 'pack', subject: 'artistic', projectKey: 'b', startedAt: now),
      ]);
      expect(state.hasRigTrialFor('a'), isTrue);
      expect(state.hasRigTrialFor('b'), isFalse);
      expect(state.hasRigTrialFor(null), isFalse);
      expect(state.hasPackTrialFor('artistic', 'b'), isTrue);
      expect(state.hasPackTrialFor('artistic', 'a'), isFalse);
      expect(state.hasPackTrialFor('motion', 'b'), isFalse);
    });

    test('grants survive a JSON round trip', () {
      final grant = _plan('pro', DateTime.utc(2026, 11, 12));
      expect(TrialGrantInfo.fromJson(grant.toJson()), grant);
    });
  });

  group('plan trial entitlements', () {
    PlanTrial trial(SubscriptionPlan tier, {bool active = true}) => PlanTrial(
          tier: tier,
          endsAt: DateTime.now().add(Duration(days: active ? 3 : -1)),
        );

    test('Pro trial unlocks pro features and the basic filters only', () {
      final sub = UserSubscription(planTrial: trial(SubscriptionPlan.pro));
      expect(sub.isPro, isTrue);
      expect(sub.hasFeatureAccess(SubscriptionFeature.advancedTools), isTrue);
      expect(sub.ownsEffectPack(EffectPackId.basicFilters), isTrue);
      expect(sub.ownsEffectPack(EffectPackId.artistic), isFalse);
      expect(sub.plan, SubscriptionPlan.free);
    });

    test('Ultimate trial unlocks every pack but never cloud sync', () {
      final sub = UserSubscription(planTrial: trial(SubscriptionPlan.ultimate));
      for (final pack in EffectPackId.values) {
        expect(sub.ownsEffectPack(pack), isTrue, reason: pack.name);
      }
      expect(sub.hasFeatureAccess(SubscriptionFeature.effects), isTrue);
      expect(sub.hasFeatureAccess(SubscriptionFeature.cloudBackup), isFalse);
    });

    test('an expired trial grants nothing', () {
      final sub = UserSubscription(planTrial: trial(SubscriptionPlan.ultimate, active: false));
      expect(sub.isPro, isFalse);
      expect(sub.ownsEffectPack(EffectPackId.artistic), isFalse);
    });
  });

  group('PlanTrial countdown', () {
    PlanTrial endingIn(Duration d) => PlanTrial(tier: SubscriptionPlan.pro, endsAt: DateTime.now().add(d));

    test('partial days round up and the last day reads as ending today', () {
      expect(endingIn(const Duration(days: 3, hours: 2)).daysLeft, 4);
      expect(endingIn(const Duration(days: 2)).daysLeft, 2);
      expect(endingIn(const Duration(days: 2)).endsToday, isFalse);
      expect(endingIn(const Duration(hours: 5)).daysLeft, 1);
      expect(endingIn(const Duration(hours: 5)).endsToday, isTrue);
    });

    test('an ended trial has nothing left', () {
      final ended = endingIn(const Duration(hours: -1));
      expect(ended.isActive, isFalse);
      expect(ended.daysLeft, 0);
    });
  });
}
