import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/pixel/effects/effect_pack_catalog.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  group('EffectPackCatalog', () {
    test('puts every effect in exactly one pack', () {
      final counted = <EffectType>[
        for (final pack in EffectPackCatalog.packs.values) ...pack.types,
      ];
      expect(counted.length, EffectType.values.length);
      expect(counted.toSet(), EffectType.values.toSet());
      for (final type in EffectType.values) {
        expect(EffectPackCatalog.packOf(type).types, contains(type));
      }
    });

    test('has contents in every pack', () {
      for (final id in EffectPackId.values) {
        expect(EffectPackCatalog.forId(id).types, isNotEmpty, reason: id.name);
      }
    });
  });

  group('ProductCatalog', () {
    test('sells every paid pack under a unique product id', () {
      final paidPacks = EffectPackId.values.where((id) => id != EffectPackId.free);
      final ids = paidPacks.map(SubscriptionProductIds.pack).toSet();
      expect(ids, isNot(contains(null)));
      expect(ids.length, paidPacks.length);
      expect(SubscriptionProductIds.pack(EffectPackId.free), isNull);
      expect(ProductCatalog.allProductIds, containsAll(ids));
      expect(
        SubscriptionProductIds.pack(EffectPackId.lightingDistortion),
        'com.pixelverse.app.pack.lightigdistortions',
      );
    });

    test('keeps the legacy Pro product as Ultimate', () {
      expect(SubscriptionProductIds.ultimate, 'com.pixelverse.app.pro.purchase');
      expect(
        ProductCatalog.entitlementsFor([SubscriptionProductIds.ultimate]),
        {Entitlement.pro, Entitlement.cloud, Entitlement.allEffects},
      );
    });

    test('pack entitlements are canonical', () {
      expect(
        identical(Entitlement.pack(EffectPackId.motion), Entitlement.pack(EffectPackId.motion)),
        isTrue,
      );
    });
  });

  group('UserSubscription', () {
    const free = UserSubscription.free();
    const pro = UserSubscription(ownedProductIds: {SubscriptionProductIds.pro});
    const ultimate = UserSubscription(ownedProductIds: {SubscriptionProductIds.ultimate});

    test('derives the plan from owned products', () {
      expect(free.plan, SubscriptionPlan.free);
      expect(pro.plan, SubscriptionPlan.pro);
      expect(ultimate.plan, SubscriptionPlan.ultimate);
      expect(
        const UserSubscription(
          ownedProductIds: {SubscriptionProductIds.pro, SubscriptionProductIds.ultimateUpgrade},
        ).plan,
        SubscriptionPlan.ultimate,
      );
    });

    test('a pack purchase alone does not unlock pro features', () {
      final packOnly = UserSubscription(
        ownedProductIds: {SubscriptionProductIds.pack(EffectPackId.artistic)!},
      );
      expect(packOnly.plan, SubscriptionPlan.free);
      expect(packOnly.isPro, isFalse);
      expect(packOnly.canUseEffect(EffectType.watercolor), isTrue);
      expect(packOnly.canUseEffect(EffectType.wood), isFalse);
    });

    test('gates effects by pack', () {
      expect(free.canUseEffect(EffectType.brightness), isTrue);
      expect(free.canUseEffect(EffectType.blur), isFalse);
      expect(pro.canUseEffect(EffectType.blur), isTrue);
      expect(pro.canUseEffect(EffectType.watercolor), isFalse);
      for (final type in EffectType.values) {
        expect(ultimate.canUseEffect(type), isTrue, reason: type.name);
      }
    });

    test('gates features by entitlement', () {
      expect(free.hasFeatureAccess(SubscriptionFeature.advancedTools), isFalse);
      expect(pro.hasFeatureAccess(SubscriptionFeature.advancedTools), isTrue);
      expect(pro.hasFeatureAccess(SubscriptionFeature.templates), isTrue);
      expect(pro.hasFeatureAccess(SubscriptionFeature.cloudBackup), isFalse);
      expect(ultimate.hasFeatureAccess(SubscriptionFeature.cloudBackup), isTrue);
      expect(
        const UserSubscription(
          ownedProductIds: {SubscriptionProductIds.pro, SubscriptionProductIds.cloudAddon},
        ).hasFeatureAccess(SubscriptionFeature.cloudBackup),
        isTrue,
      );
    });

    test('temporary access unlocks pro limits without changing the plan', () {
      final temporary = UserSubscription(
        temporaryProAccess: TemporaryProAccess(
          startTime: DateTime.now(),
          duration: const Duration(hours: 1),
        ),
      );
      expect(temporary.plan, SubscriptionPlan.free);
      expect(temporary.isPro, isTrue);
      expect(temporary.getFeatureLimit<int>(SubscriptionFeature.maxCanvasSize), 1024);
      expect(temporary.hasFeatureAccess(SubscriptionFeature.templates), isFalse);
      expect(free.getFeatureLimit<int>(SubscriptionFeature.maxCanvasSize), 64);
    });

    test('round-trips through json', () {
      final restored = UserSubscription.fromJson(pro.toJson());
      expect(restored, pro);
    });

    group('legacy storage', () {
      test('migrates a real Pro purchase to Ultimate', () {
        final restored = UserSubscription.fromJson({
          'plan': 'proPurchase',
          'status': 'purchased',
          'purchaseId': 'GPA.1234',
          'purchaseDate': '2025-01-01T00:00:00.000',
          'temporaryProAccess': null,
        });
        expect(restored.plan, SubscriptionPlan.ultimate);
      });

      test('does not treat rewarded-ad access as a purchase', () {
        final restored = UserSubscription.fromJson({
          'plan': 'proPurchase',
          'status': 'purchased',
          'purchaseId': null,
          'purchaseDate': null,
          'temporaryProAccess': {
            'startTime': DateTime.now().toIso8601String(),
            'duration': const Duration(hours: 1).inMilliseconds,
          },
        });
        expect(restored.plan, SubscriptionPlan.free);
        expect(restored.hasTemporaryPro, isTrue);
      });

      test('keeps free users free', () {
        final restored = UserSubscription.fromJson({
          'plan': 'free',
          'status': 'notPurchased',
          'purchaseId': null,
          'purchaseDate': null,
          'temporaryProAccess': null,
        });
        expect(restored, const UserSubscription.free());
      });
    });
  });
}
