import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/progression_model.dart';
import 'package:picell/pixel/effects/effect_pack_catalog.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final day1 = DateTime(2026, 9, 28, 10);
  final day2 = DateTime(2026, 9, 29, 10);

  Quest starter(String id) => QuestCatalog.byId[id]!;

  group('quests', () {
    test('counts events and completes a starter quest once', () {
      var state = const ProgressionState();
      final (afterFirst, completed) = state.record(ProgressionEvent.projectCreated, day1);
      expect(completed, contains(starter('first_project')));

      final (afterSecond, completedAgain) = afterFirst.record(ProgressionEvent.projectCreated, day1);
      expect(completedAgain.where((quest) => quest.id == 'first_project'), isEmpty);
      state = afterSecond;
      expect(state.progressOf(starter('first_project')), 1);
    });

    test('pays a claim once and grants reward effects', () {
      var state = const ProgressionState();
      for (var i = 0; i < 8; i++) {
        state = state.record(ProgressionEvent.frameAdded, day1).$1;
      }
      final quest = starter('frames_8');
      expect(state.canClaim(quest), isTrue);

      final claimed = state.claim(quest, day1)!;
      // The day's login reward was paid on the first event.
      expect(claimed.coins - state.coins, quest.coins);
      expect(claimed.canUseEffect(EffectType.float, day1), isTrue);
      expect(claimed.claim(quest, day1), isNull);
    });

    test('Pro multiplier increases quest rewards', () {
      final state = const ProgressionState().record(ProgressionEvent.projectCreated, day1).$1;
      final claimed = state.claim(starter('first_project'), day1, multiplier: 1.5)!;
      expect(claimed.coins - state.coins, 75);
    });

    test('daily quests are stable for a day and reset the next day', () {
      final eligibility = const ProgressionState().eligibility();
      expect(QuestCatalog.pickDaily('2026-09-28', eligibility), QuestCatalog.pickDaily('2026-09-28', eligibility));

      var state = const ProgressionState().rollDay(day1);
      expect(state.dailyQuests.map((quest) => quest.tier), QuestCatalog.dailyTiers);
      final daily = state.dailyQuests.first;
      for (var i = 0; i < daily.target; i++) {
        state = state.record(daily.event, day1).$1;
      }
      expect(state.isComplete(daily), isTrue);
      state = state.claim(daily, day1)!;
      expect(state.isClaimed(daily), isTrue);

      final nextDay = state.rollDay(day2);
      expect(nextDay.progress.keys.where((key) => key.startsWith('daily:')), isEmpty);
      expect(nextDay.claimedQuests.where((key) => key.startsWith('daily:')), isEmpty);
    });
  });

  group('catalog', () {
    test('quest ids are unique', () {
      final ids = [...QuestCatalog.oneTime, ...QuestCatalog.dailyPool].map((quest) => quest.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('each tier requires an easier one-time quest for the same action', () {
      for (final quest in QuestCatalog.oneTime.where((quest) => quest.requires != null)) {
        final previous = QuestCatalog.byId[quest.requires];
        expect(previous, isNotNull, reason: quest.id);
        expect(previous!.kind, isNot(QuestKind.daily), reason: quest.id);
        expect(previous.event, quest.event, reason: quest.id);
        expect(previous.target, lessThan(quest.target), reason: quest.id);
      }
    });

    test('reward effects come from paid packs', () {
      for (final quest in QuestCatalog.oneTime.where((quest) => quest.rewardEffect != null)) {
        expect(EffectPackCatalog.isFree(quest.rewardEffect!), isFalse, reason: quest.id);
      }
    });

    test('every daily slot has a quest anyone can do', () {
      for (final tier in QuestCatalog.dailyTiers) {
        expect(
          QuestCatalog.dailyPool.any((quest) => quest.tier == tier && quest.requirement == QuestRequirement.none),
          isTrue,
          reason: tier.name,
        );
      }
      for (final quest in QuestCatalog.dailyPool) {
        expect(quest.coins, QuestCatalog.dailyCoins[quest.tier], reason: quest.id);
      }
    });

    test('a day never repeats an action and has one quest per slot', () {
      for (var day = 1; day <= 60; day++) {
        final key = dayKeyOf(DateTime(2026, 9, day));
        final quests = QuestCatalog.pickDaily(key, const ProgressionState().eligibility());
        expect(quests.map((quest) => quest.tier), QuestCatalog.dailyTiers, reason: key);
        expect(quests.map((quest) => quest.event).toSet(), hasLength(quests.length), reason: key);
      }
    });
  });

  group('achievement tiers', () {
    test('stay hidden and unannounced until the previous tier is claimed', () {
      final tier = QuestCatalog.byId['projects_5']!;
      var state = const ProgressionState().rollDay(day1);
      final completed = <Quest>[];
      for (var i = 0; i < tier.target; i++) {
        final (next, done) = state.record(ProgressionEvent.projectCreated, day1);
        state = next;
        completed.addAll(done);
      }

      expect(state.isComplete(tier), isTrue);
      expect(state.isUnlocked(tier), isFalse);
      expect(state.canClaim(tier), isFalse);
      expect(completed, isNot(contains(tier)));

      state = state.claim(starter('first_project'), day1)!;
      expect(state.isUnlocked(tier), isTrue);
      expect(state.canClaim(tier), isTrue);
    });
  });

  group('daily quests', () {
    const signedOut = DailyContext();
    const signedIn = DailyContext(signedIn: true, challengeRunning: true, hasOldProject: true);

    test('never offer what the user cannot do', () {
      for (var day = 1; day <= 60; day++) {
        final quests = QuestCatalog.pickDaily(dayKeyOf(DateTime(2026, 9, day)), const ProgressionState().eligibility());
        expect(quests.where((quest) => quest.requirement != QuestRequirement.none), isEmpty);
      }
      final eligibility = const ProgressionState().eligibility(signedIn);
      expect(eligibility.allows(QuestRequirement.signedIn), isTrue);
      expect(eligibility.allows(QuestRequirement.challengeRunning), isTrue);
      expect(eligibility.allows(QuestRequirement.animator), isFalse);
      expect(const ProgressionState().eligibility(signedOut).allows(QuestRequirement.signedIn), isFalse);
    });

    test('keep the day\'s choice when the context changes later', () {
      final state = const ProgressionState().rollDay(day1, context: signedOut);
      final again = state.rollDay(day1.add(const Duration(hours: 2)), context: signedIn);
      expect(again.dailyQuestIds, state.dailyQuestIds);
    });

    test('can be swapped twice a day, not after they are done', () {
      var state = const ProgressionState().rollDay(day1);
      final first = state.mainDailyQuests.first;

      final swapped = state.rerollDaily(first)!;
      expect(swapped.mainDailyQuests.first.id, isNot(first.id));
      expect(swapped.mainDailyQuests.first.tier, first.tier);
      expect(swapped.rerollsLeft, QuestCatalog.maxDailyRerolls - 1);

      state = swapped.rerollDaily(swapped.mainDailyQuests.first)!;
      expect(state.rerollsLeft, 0);
      expect(state.rerollDaily(state.mainDailyQuests[1]), isNull);

      final fresh = const ProgressionState().rollDay(day1);
      final done = fresh.mainDailyQuests.first;
      var completed = fresh;
      for (var i = 0; i < done.target; i++) {
        completed = completed.record(done.event, day1).$1;
      }
      expect(completed.canReroll(done), isFalse);
    });

    test('pay a bonus once all three main quests are claimed', () {
      var state = const ProgressionState().rollDay(day1);
      expect(state.canClaimDailyBonus, isFalse);
      for (final quest in state.mainDailyQuests) {
        for (var i = 0; i < quest.target; i++) {
          state = state.record(quest.event, day1).$1;
        }
        state = state.claim(quest, day1)!;
      }
      expect(state.canClaimDailyBonus, isTrue);
      final before = state.coins;
      state = state.claimDailyBonus(day1)!;
      expect(state.coins, before + QuestCatalog.allDailyBonus);
      expect(state.claimDailyBonus(day1), isNull);
      expect(state.rollDay(day2).dailyBonusClaimed, isFalse);
    });
  });

  group('weekly quests', () {
    test('always include finishing daily quests, which claimed dailies count toward', () {
      var state = const ProgressionState().rollDay(day1);
      expect(state.weeklyQuests.first, QuestCatalog.weeklyDailies);
      expect(state.weeklyQuests, hasLength(3));
      expect(state.weeklyQuests.map((quest) => quest.event).toSet(), hasLength(3));

      final daily = state.mainDailyQuests.first;
      for (var i = 0; i < daily.target; i++) {
        state = state.record(daily.event, day1).$1;
      }
      state = state.claim(daily, day1)!;
      expect(state.progressOf(QuestCatalog.weeklyDailies), 1);
    });

    test('keep progress through the week and reset on Monday', () {
      // 2026-09-28 is a Monday.
      var state = const ProgressionState().rollDay(DateTime(2026, 9, 28));
      final weekly = state.weeklyQuests[1];
      state = state.record(weekly.event, DateTime(2026, 9, 28)).$1;
      final midWeek = state.rollDay(DateTime(2026, 9, 30));
      expect(midWeek.weeklyQuestIds, state.weeklyQuestIds);
      expect(midWeek.progressOf(weekly), 1);

      final nextWeek = midWeek.rollDay(DateTime(2026, 10, 5));
      expect(nextWeek.weekKey, '2026-10-05');
      expect(nextWeek.progress.keys.where((key) => key.startsWith('weekly:')), isEmpty);
    });
  });

  group('welcome back', () {
    test('daily quests pay double after a long break', () {
      var state = const ProgressionState().rollDay(DateTime(2026, 9, 1));
      state = state.rollDay(DateTime(2026, 9, 10));
      expect(state.welcomeBackToday, isTrue);

      final daily = state.mainDailyQuests.first;
      for (var i = 0; i < daily.target; i++) {
        state = state.record(daily.event, DateTime(2026, 9, 10)).$1;
      }
      final claimed = state.claim(daily, DateTime(2026, 9, 10))!;
      expect(claimed.coins - state.coins, daily.coins * 2);
      expect(claimed.rollDay(DateTime(2026, 9, 11)).welcomeBackToday, isFalse);
    });
  });

  group('login cycle', () {
    test('pays each day of the cycle and starts over after a week', () {
      var state = const ProgressionState();
      var paid = 0;
      for (var day = 0; day < 8; day++) {
        state = state.rollDay(DateTime(2026, 9, 1 + day));
        paid += LoginRewards.coinsFor(day % LoginRewards.cycleLength + 1);
        expect(state.loginRewardToday, LoginRewards.coinsFor(day % LoginRewards.cycleLength + 1));
      }
      expect(state.coins, paid);
      expect(state.loginCycleDay, 1);
      expect(state.streakDays, 8);

      // Rolling the same day again does not pay twice.
      expect(state.rollDay(DateTime(2026, 9, 8, 23)), same(state));
    });

    test('forgives one missed day per cycle, then breaks', () {
      var state = const ProgressionState().rollDay(DateTime(2026, 9, 1)).rollDay(DateTime(2026, 9, 2));
      state = state.rollDay(DateTime(2026, 9, 4)); // missed the 3rd
      expect(state.loginCycleDay, 3);
      expect(state.graceUsed, isTrue);

      final broken = state.rollDay(DateTime(2026, 9, 6)); // missed again
      expect(broken.loginCycleDay, 1);
      expect(broken.streakDays, 1);
    });

    test('continues across month boundaries', () {
      final state = const ProgressionState().rollDay(DateTime(2026, 9, 30)).rollDay(DateTime(2026, 10, 1));
      expect(state.streakDays, 2);
    });
  });

  group('wallet', () {
    test('buys an effect with coins and refuses without enough coins', () {
      const poor = ProgressionState(coins: 10);
      expect(poor.buyEffect(EffectType.watercolor, day1), isNull);

      final rich = const ProgressionState(coins: 1000).buyEffect(EffectType.watercolor, day1)!;
      expect(rich.coins, 1000 - CoinPrices.effect(EffectType.watercolor));
      expect(rich.canUseEffect(EffectType.watercolor, day1), isTrue);
      expect(rich.canUseEffect(EffectType.oilPaint, day1), isFalse);
      expect(rich.ledger.first.reason, WalletReason.effectPurchase);
      // Already owned: no second charge.
      expect(rich.buyEffect(EffectType.watercolor, day1), isNull);
    });

    test('free effects are not sold', () {
      expect(const ProgressionState(coins: 1000).buyEffect(EffectType.brightness, day1), isNull);
    });

    test('buys a whole pack with coins, the first one discounted', () {
      const start = ProgressionState(coins: 5000);
      final firstPrice = start.packPrice(EffectPackId.materials);
      expect(firstPrice, (CoinPrices.pack(EffectPackId.materials) * (1 - CoinPrices.firstPackDiscount)).round());

      final state = start.buyPack(EffectPackId.materials, day1)!;
      expect(state.coins, 5000 - firstPrice);
      expect(state.canUseEffect(EffectType.wood, day1), isTrue);
      expect(state.firstPackDiscountAvailable, isFalse);
      // The discount is spent: the next pack costs full price.
      expect(state.packPrice(EffectPackId.artistic), CoinPrices.pack(EffectPackId.artistic));
    });

    test('owned effects count toward their pack, down to a floor', () {
      const noDiscount = ProgressionState(firstPackDiscountUsed: true);
      final base = CoinPrices.pack(EffectPackId.artistic);
      expect(noDiscount.packPrice(EffectPackId.artistic), base);

      final withOne = noDiscount.copyWith(earnedEffects: {EffectType.watercolor});
      expect(withOne.packCredit(EffectPackId.artistic), CoinPrices.effect(EffectType.watercolor));
      expect(withOne.packPrice(EffectPackId.artistic), base - CoinPrices.effect(EffectType.watercolor));

      final withAll = noDiscount.copyWith(earnedEffects: EffectPackCatalog.forId(EffectPackId.artistic).types.toSet());
      expect(withAll.packPrice(EffectPackId.artistic), (base * CoinPrices.packPriceFloor).round());
    });

    test('a savings goal shows how long it takes and clears when bought', () {
      final now = DateTime(2026, 9, 28, 12);
      var state = ProgressionState(
        coins: 100,
        firstPackDiscountUsed: true,
        ledger: [WalletEntry(amount: 700, reason: WalletReason.quest, at: now.subtract(const Duration(days: 2)))],
      ).setGoal(EffectPackId.materials);
      // 700 gems a week = 100 a day; 2400 missing.
      expect(state.goalEtaDays(now), 24);

      state = state.copyWith(coins: 3000);
      expect(state.goalEtaDays(now), 0);
      expect(state.buyPack(EffectPackId.materials, now)!.goalPack, isNull);
      expect(const ProgressionState().goalEtaDays(now), isNull);
    });

    test('limits ad rewards per day', () {
      var state = const ProgressionState().rollDay(day1);
      final before = state.coins;
      for (var i = 0; i < CoinPrices.maxAdsPerDay; i++) {
        state = state.rewardAd(day1)!;
      }
      expect(state.coins - before, CoinPrices.adReward * CoinPrices.maxAdsPerDay);
      expect(state.rewardAd(day1), isNull);
      expect(state.rewardAd(day2), isNotNull);
    });
  });

  test('pack trials expire', () {
    final state = const ProgressionState().startPackTrial(EffectPackId.vfxMagic, day1);
    expect(state.canUseEffect(EffectType.sparkle, day1), isTrue);
    expect(state.canUseEffect(EffectType.sparkle, day1.add(const Duration(hours: 2))), isFalse);
  });

  test('round-trips through json and ignores removed content', () {
    var state = const ProgressionState(coins: 500).rollDay(day1);
    state = state.record(ProgressionEvent.projectCreated, day1).$1;
    state = state.buyEffect(EffectType.watercolor, day1)!;
    state = state.buyPack(EffectPackId.basicFilters, day1) ?? state;
    state = state.startPackTrial(EffectPackId.motion, day1);

    final restored = ProgressionState.fromJson(state.toJson());
    expect(restored, state);

    final json = state.toJson()..['earnedEffects'] = ['watercolor', 'removedEffect'];
    expect(ProgressionState.fromJson(json).earnedEffects, {EffectType.watercolor});
  });

  test('server grants are added once and survive a restart', () {
    const state = ProgressionState(coins: 10);
    final paid = state.applyServerGrant('grant-1', gems: 500, pack: EffectPackId.vfxMagic, now: day1, detail: 'dragons')!;

    expect(paid.coins, 510);
    expect(paid.earnedPacks, {EffectPackId.vfxMagic});
    expect(paid.ledger.first.reason, WalletReason.serverReward);
    expect(paid.applyServerGrant('grant-1', gems: 500, now: day1), isNull);

    final restored = ProgressionState.fromJson(paid.toJson());
    expect(restored.hasClaimedGrant('grant-1'), isTrue);
    expect(restored.applyServerGrant('grant-1', gems: 500, now: day2), isNull);
  });
}
