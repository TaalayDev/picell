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
      expect(claimed.coins, quest.coins);
      expect(claimed.canUseEffect(EffectType.float, day1), isTrue);
      expect(claimed.claim(quest, day1), isNull);
    });

    test('Pro multiplier increases quest rewards', () {
      final state = const ProgressionState().record(ProgressionEvent.projectCreated, day1).$1;
      final claimed = state.claim(starter('first_project'), day1, multiplier: 1.5)!;
      expect(claimed.coins, 75);
    });

    test('daily quests are stable for a day and reset the next day', () {
      expect(QuestCatalog.dailyFor('2026-09-28'), QuestCatalog.dailyFor('2026-09-28'));
      expect(QuestCatalog.dailyFor('2026-09-28'), hasLength(QuestCatalog.dailyQuestCount));

      var state = const ProgressionState().rollDay(day1);
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

    test('daily quests never repeat an action on the same day', () {
      final events = QuestCatalog.dailyPool.map((quest) => quest.event).toList();
      expect(events.toSet().length, events.length);
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

  group('streaks', () {
    test('grows on consecutive days, pays milestones and breaks after a gap', () {
      var state = const ProgressionState();
      for (var day = 0; day < 3; day++) {
        state = state.rollDay(DateTime(2026, 9, 28 + day));
      }
      expect(state.streakDays, 3);
      expect(state.coins, StreakRewards.coinsByDay[3]);
      expect(state.claimedStreakDays, {3});

      // Rolling the same day again does not pay twice.
      expect(state.rollDay(DateTime(2026, 9, 30, 23)), same(state));

      final broken = state.rollDay(DateTime(2026, 10, 5));
      expect(broken.streakDays, 1);
      expect(broken.claimedStreakDays, isEmpty);
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

    test('buys a whole pack with coins', () {
      final state = const ProgressionState(coins: 3000).buyPack(EffectPackId.materials, day1)!;
      expect(state.coins, 3000 - CoinPrices.pack(EffectPackId.materials));
      expect(state.canUseEffect(EffectType.wood, day1), isTrue);
    });

    test('limits ad rewards per day', () {
      var state = const ProgressionState().rollDay(day1);
      for (var i = 0; i < CoinPrices.maxAdsPerDay; i++) {
        state = state.rewardAd(day1)!;
      }
      expect(state.coins, CoinPrices.adReward * CoinPrices.maxAdsPerDay);
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
