import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../pixel/effects/effect_pack_catalog.dart';
import '../../pixel/effects/effects.dart';

/// Things users do in the app that quests count.
enum ProgressionEvent {
  projectCreated,
  strokeCompleted,
  layerAdded,
  frameAdded,
  effectAdded,
  animationGenerated,
  imageExported,
  animationExported,
  projectImported,
  projectPublished,
  templateUsed,
  imageImported,
  animationStateAdded,
  fillUsed,
  shapeDrawn,
  projectLiked,
  challengeEntered,

  /// A stroke in a project created more than a week ago.
  oldProjectStroke,

  /// A daily quest was claimed (counts toward a weekly quest).
  dailyQuestClaimed,
}

/// The daily slot a quest fills. Every day has one easy, one medium and one
/// hard quest, plus an optional bonus; rewards grow with the effort.
enum QuestTier { easy, medium, hard, bonus }

/// What a daily quest needs, so it is never offered to someone who can't do
/// it today.
enum QuestRequirement {
  none,
  signedIn,

  /// Has made an animation (two or more frames) before.
  animator,

  /// Has generated an effect animation before.
  generator,

  /// Has added an animation state before.
  animationStates,

  /// Signed in, with a challenge running.
  challengeRunning,

  /// Has a project created more than a week ago.
  oldProject,
}

/// Things outside the progression state that decide which daily quests can
/// be offered.
class DailyContext extends Equatable {
  const DailyContext({
    this.signedIn = false,
    this.challengeRunning = false,
    this.hasOldProject = false,
    this.seed = '',
  });

  final bool signedIn;
  final bool challengeRunning;
  final bool hasOldProject;

  /// Per-install salt, so not everyone gets the same quests on a given day.
  final String seed;

  @override
  List<Object?> get props => [signedIn, challengeRunning, hasOldProject, seed];
}

/// Starter quests teach the basics once; achievements are tiered goals;
/// dailies reset every day.
enum QuestKind { starter, achievement, daily, weekly }

class Quest extends Equatable {
  const Quest({
    required this.id,
    required this.kind,
    required this.event,
    required this.target,
    required this.coins,
    this.rewardEffect,
    this.requires,
    this.tier,
    this.requirement = QuestRequirement.none,
  });

  final String id;
  final QuestKind kind;
  final ProgressionEvent event;
  final int target;
  final int coins;

  /// An effect unlocked for free when the quest is claimed.
  final EffectType? rewardEffect;

  /// Id of the quest that must be claimed before this one shows up. Progress
  /// counts from the start, so the next tier may already be done.
  final String? requires;

  /// Daily quests only: the slot it fills.
  final QuestTier? tier;

  /// Daily quests only: what the user must be able to do.
  final QuestRequirement requirement;

  @override
  List<Object?> get props => [id];
}

class QuestCatalog {
  QuestCatalog._();

  static const int dailyQuestCount = 3;

  /// One-time quests that also teach the app's main features.
  static const List<Quest> starter = [
    Quest(id: 'first_project', kind: QuestKind.starter, event: ProgressionEvent.projectCreated, target: 1, coins: 50),
    Quest(id: 'strokes_100', kind: QuestKind.starter, event: ProgressionEvent.strokeCompleted, target: 100, coins: 100),
    Quest(id: 'layers_3', kind: QuestKind.starter, event: ProgressionEvent.layerAdded, target: 3, coins: 50),
    Quest(id: 'effects_3', kind: QuestKind.starter, event: ProgressionEvent.effectAdded, target: 3, coins: 75),
    Quest(
      id: 'frames_8',
      kind: QuestKind.starter,
      event: ProgressionEvent.frameAdded,
      target: 8,
      coins: 100,
      rewardEffect: EffectType.float,
    ),
    Quest(
      id: 'first_animation_state',
      kind: QuestKind.starter,
      event: ProgressionEvent.animationStateAdded,
      target: 1,
      coins: 75,
    ),
    Quest(id: 'first_template', kind: QuestKind.starter, event: ProgressionEvent.templateUsed, target: 1, coins: 50),
    Quest(
        id: 'first_image_import', kind: QuestKind.starter, event: ProgressionEvent.imageImported, target: 1, coins: 50),
    Quest(id: 'first_export', kind: QuestKind.starter, event: ProgressionEvent.imageExported, target: 1, coins: 50),
    Quest(
      id: 'first_animation_export',
      kind: QuestKind.starter,
      event: ProgressionEvent.animationExported,
      target: 1,
      coins: 100,
      rewardEffect: EffectType.sparkle,
    ),
    Quest(
      id: 'first_generated_animation',
      kind: QuestKind.starter,
      event: ProgressionEvent.animationGenerated,
      target: 1,
      coins: 100,
    ),
    Quest(id: 'first_import', kind: QuestKind.starter, event: ProgressionEvent.projectImported, target: 1, coins: 50),
    Quest(
      id: 'first_publish',
      kind: QuestKind.starter,
      event: ProgressionEvent.projectPublished,
      target: 1,
      coins: 150,
      rewardEffect: EffectType.fire,
    ),
  ];

  /// Tiered goals. Each tier appears once the previous one is claimed, and
  /// the higher tiers pay out effects from paid packs.
  static const List<Quest> achievements = [
    // Drawing
    Quest(
      id: 'strokes_500',
      kind: QuestKind.achievement,
      event: ProgressionEvent.strokeCompleted,
      target: 500,
      coins: 150,
      requires: 'strokes_100',
    ),
    Quest(
      id: 'strokes_2000',
      kind: QuestKind.achievement,
      event: ProgressionEvent.strokeCompleted,
      target: 2000,
      coins: 300,
      rewardEffect: EffectType.watercolor,
      requires: 'strokes_500',
    ),
    Quest(
      id: 'strokes_10000',
      kind: QuestKind.achievement,
      event: ProgressionEvent.strokeCompleted,
      target: 10000,
      coins: 600,
      rewardEffect: EffectType.rimLight,
      requires: 'strokes_2000',
    ),
    // Projects
    Quest(
      id: 'projects_5',
      kind: QuestKind.achievement,
      event: ProgressionEvent.projectCreated,
      target: 5,
      coins: 100,
      requires: 'first_project',
    ),
    Quest(
      id: 'projects_20',
      kind: QuestKind.achievement,
      event: ProgressionEvent.projectCreated,
      target: 20,
      coins: 250,
      rewardEffect: EffectType.mountainRange,
      requires: 'projects_5',
    ),
    // Layers
    Quest(
      id: 'layers_15',
      kind: QuestKind.achievement,
      event: ProgressionEvent.layerAdded,
      target: 15,
      coins: 100,
      requires: 'layers_3',
    ),
    Quest(
      id: 'layers_50',
      kind: QuestKind.achievement,
      event: ProgressionEvent.layerAdded,
      target: 50,
      coins: 250,
      rewardEffect: EffectType.wood,
      requires: 'layers_15',
    ),
    // Effects
    Quest(
      id: 'effects_15',
      kind: QuestKind.achievement,
      event: ProgressionEvent.effectAdded,
      target: 15,
      coins: 150,
      requires: 'effects_3',
    ),
    Quest(
      id: 'effects_50',
      kind: QuestKind.achievement,
      event: ProgressionEvent.effectAdded,
      target: 50,
      coins: 300,
      rewardEffect: EffectType.auroraCurtains,
      requires: 'effects_15',
    ),
    // Animation
    Quest(
      id: 'frames_30',
      kind: QuestKind.achievement,
      event: ProgressionEvent.frameAdded,
      target: 30,
      coins: 150,
      requires: 'frames_8',
    ),
    Quest(
      id: 'frames_100',
      kind: QuestKind.achievement,
      event: ProgressionEvent.frameAdded,
      target: 100,
      coins: 300,
      rewardEffect: EffectType.explosion,
      requires: 'frames_30',
    ),
    Quest(
      id: 'animation_states_5',
      kind: QuestKind.achievement,
      event: ProgressionEvent.animationStateAdded,
      target: 5,
      coins: 150,
      rewardEffect: EffectType.jello,
      requires: 'first_animation_state',
    ),
    Quest(
      id: 'generated_animations_5',
      kind: QuestKind.achievement,
      event: ProgressionEvent.animationGenerated,
      target: 5,
      coins: 200,
      rewardEffect: EffectType.soulWisps,
      requires: 'first_generated_animation',
    ),
    // Templates
    Quest(
      id: 'templates_5',
      kind: QuestKind.achievement,
      event: ProgressionEvent.templateUsed,
      target: 5,
      coins: 100,
      requires: 'first_template',
    ),
    // Exports
    Quest(
      id: 'exports_10',
      kind: QuestKind.achievement,
      event: ProgressionEvent.imageExported,
      target: 10,
      coins: 150,
      requires: 'first_export',
    ),
    Quest(
      id: 'exports_50',
      kind: QuestKind.achievement,
      event: ProgressionEvent.imageExported,
      target: 50,
      coins: 400,
      rewardEffect: EffectType.halftone,
      requires: 'exports_10',
    ),
    Quest(
      id: 'animation_exports_5',
      kind: QuestKind.achievement,
      event: ProgressionEvent.animationExported,
      target: 5,
      coins: 200,
      requires: 'first_animation_export',
    ),
    Quest(
      id: 'animation_exports_25',
      kind: QuestKind.achievement,
      event: ProgressionEvent.animationExported,
      target: 25,
      coins: 400,
      rewardEffect: EffectType.fireflySwarm,
      requires: 'animation_exports_5',
    ),
    // Community
    Quest(
      id: 'publish_5',
      kind: QuestKind.achievement,
      event: ProgressionEvent.projectPublished,
      target: 5,
      coins: 300,
      requires: 'first_publish',
    ),
    Quest(
      id: 'publish_20',
      kind: QuestKind.achievement,
      event: ProgressionEvent.projectPublished,
      target: 20,
      coins: 600,
      rewardEffect: EffectType.starfield,
      requires: 'publish_5',
    ),
  ];

  /// Every quest that is completed once, in display order.
  static const List<Quest> oneTime = [...starter, ...achievements];

  /// Daily rewards by slot, and the bonus for claiming all three main ones.
  static const Map<QuestTier, int> dailyCoins = {
    QuestTier.easy: 15,
    QuestTier.medium: 25,
    QuestTier.hard: 40,
    QuestTier.bonus: 30,
  };
  static const int allDailyBonus = 30;

  /// Free quest swaps per day.
  static const int maxDailyRerolls = 2;

  /// The slots every day has, in display order; the last one is optional.
  static const List<QuestTier> dailyTiers = [QuestTier.easy, QuestTier.medium, QuestTier.hard, QuestTier.bonus];

  /// Each slot has at least one quest without requirements, so every day is
  /// completable by anyone.
  static const List<Quest> dailyPool = [
    // Easy
    Quest(
        id: 'daily_strokes',
        kind: QuestKind.daily,
        tier: QuestTier.easy,
        event: ProgressionEvent.strokeCompleted,
        target: 50,
        coins: 15),
    Quest(
        id: 'daily_layers',
        kind: QuestKind.daily,
        tier: QuestTier.easy,
        event: ProgressionEvent.layerAdded,
        target: 2,
        coins: 15),
    Quest(
        id: 'daily_project',
        kind: QuestKind.daily,
        tier: QuestTier.easy,
        event: ProgressionEvent.projectCreated,
        target: 1,
        coins: 15),
    Quest(
        id: 'daily_fill',
        kind: QuestKind.daily,
        tier: QuestTier.easy,
        event: ProgressionEvent.fillUsed,
        target: 3,
        coins: 15),
    Quest(
        id: 'daily_shapes',
        kind: QuestKind.daily,
        tier: QuestTier.easy,
        event: ProgressionEvent.shapeDrawn,
        target: 3,
        coins: 15),
    Quest(
      id: 'daily_like',
      kind: QuestKind.daily,
      tier: QuestTier.easy,
      event: ProgressionEvent.projectLiked,
      target: 1,
      coins: 15,
      requirement: QuestRequirement.signedIn,
    ),
    // Medium
    Quest(
        id: 'daily_effects',
        kind: QuestKind.daily,
        tier: QuestTier.medium,
        event: ProgressionEvent.effectAdded,
        target: 2,
        coins: 25),
    Quest(
        id: 'daily_frames',
        kind: QuestKind.daily,
        tier: QuestTier.medium,
        event: ProgressionEvent.frameAdded,
        target: 4,
        coins: 25),
    Quest(
        id: 'daily_export',
        kind: QuestKind.daily,
        tier: QuestTier.medium,
        event: ProgressionEvent.imageExported,
        target: 1,
        coins: 25),
    Quest(
        id: 'daily_template',
        kind: QuestKind.daily,
        tier: QuestTier.medium,
        event: ProgressionEvent.templateUsed,
        target: 1,
        coins: 25),
    Quest(
      id: 'daily_image_import',
      kind: QuestKind.daily,
      tier: QuestTier.medium,
      event: ProgressionEvent.imageImported,
      target: 1,
      coins: 25,
    ),
    Quest(
      id: 'daily_strokes_200',
      kind: QuestKind.daily,
      tier: QuestTier.medium,
      event: ProgressionEvent.strokeCompleted,
      target: 200,
      coins: 25,
    ),
    // Hard
    Quest(
      id: 'daily_strokes_500',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.strokeCompleted,
      target: 500,
      coins: 40,
    ),
    Quest(
        id: 'daily_effects_5',
        kind: QuestKind.daily,
        tier: QuestTier.hard,
        event: ProgressionEvent.effectAdded,
        target: 5,
        coins: 40),
    Quest(
      id: 'daily_animation_export',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.animationExported,
      target: 1,
      coins: 40,
      requirement: QuestRequirement.animator,
    ),
    Quest(
      id: 'daily_frames_12',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.frameAdded,
      target: 12,
      coins: 40,
      requirement: QuestRequirement.animator,
    ),
    Quest(
      id: 'daily_generated_animation',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.animationGenerated,
      target: 1,
      coins: 40,
      requirement: QuestRequirement.generator,
    ),
    Quest(
      id: 'daily_animation_state',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.animationStateAdded,
      target: 1,
      coins: 40,
      requirement: QuestRequirement.animationStates,
    ),
    Quest(
      id: 'daily_publish',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.projectPublished,
      target: 1,
      coins: 40,
      requirement: QuestRequirement.signedIn,
    ),
    Quest(
      id: 'daily_challenge',
      kind: QuestKind.daily,
      tier: QuestTier.hard,
      event: ProgressionEvent.challengeEntered,
      target: 1,
      coins: 40,
      requirement: QuestRequirement.challengeRunning,
    ),
    // Bonus (optional)
    Quest(
      id: 'bonus_strokes_300',
      kind: QuestKind.daily,
      tier: QuestTier.bonus,
      event: ProgressionEvent.strokeCompleted,
      target: 300,
      coins: 30,
    ),
    Quest(
        id: 'bonus_layers_4',
        kind: QuestKind.daily,
        tier: QuestTier.bonus,
        event: ProgressionEvent.layerAdded,
        target: 4,
        coins: 30),
    Quest(
        id: 'bonus_shapes_6',
        kind: QuestKind.daily,
        tier: QuestTier.bonus,
        event: ProgressionEvent.shapeDrawn,
        target: 6,
        coins: 30),
    Quest(
        id: 'bonus_fill_6',
        kind: QuestKind.daily,
        tier: QuestTier.bonus,
        event: ProgressionEvent.fillUsed,
        target: 6,
        coins: 30),
    Quest(
        id: 'bonus_export_2',
        kind: QuestKind.daily,
        tier: QuestTier.bonus,
        event: ProgressionEvent.imageExported,
        target: 2,
        coins: 30),
    Quest(
      id: 'bonus_old_project',
      kind: QuestKind.daily,
      tier: QuestTier.bonus,
      event: ProgressionEvent.oldProjectStroke,
      target: 20,
      coins: 30,
      requirement: QuestRequirement.oldProject,
    ),
  ];

  static final Map<String, Quest> byId = {
    for (final quest in [...oneTime, ...dailyPool, ...weeklyPool]) quest.id: quest,
  };

  /// The quest unlocked by claiming the given one, if any.
  static final Map<String, Quest> nextTier = {
    for (final quest in oneTime)
      if (quest.requires != null) quest.requires!: quest,
  };

  /// Quests of [tier] the user can do, in this day's (and this install's)
  /// order. The first one is offered; swaps move down the list.
  static List<Quest> candidates(QuestTier tier, String dayKey, DailyEligibility eligibility) {
    // String.hashCode differs between platforms, so hash the key ourselves.
    final key = '$dayKey|${eligibility.seed}|${tier.name}';
    final seed = key.codeUnits.fold<int>(17, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
    return [
      for (final quest in dailyPool)
        if (quest.tier == tier && eligibility.allows(quest.requirement)) quest,
    ]..shuffle(Random(seed));
  }

  /// Weekly quests: three a week, bigger goals than dailies. The first is
  /// always "finish some daily quests", which even an occasional player can
  /// make progress on.
  static const int allWeeklyBonus = 100;
  static const Quest weeklyDailies = Quest(
    id: 'weekly_dailies_5',
    kind: QuestKind.weekly,
    event: ProgressionEvent.dailyQuestClaimed,
    target: 5,
    coins: 150,
  );
  static const List<Quest> weeklyPool = [
    weeklyDailies,
    Quest(id: 'weekly_strokes_1000', kind: QuestKind.weekly, event: ProgressionEvent.strokeCompleted, target: 1000, coins: 150),
    Quest(id: 'weekly_effects_10', kind: QuestKind.weekly, event: ProgressionEvent.effectAdded, target: 10, coins: 150),
    Quest(id: 'weekly_exports_5', kind: QuestKind.weekly, event: ProgressionEvent.imageExported, target: 5, coins: 150),
    Quest(id: 'weekly_projects_3', kind: QuestKind.weekly, event: ProgressionEvent.projectCreated, target: 3, coins: 150),
    Quest(id: 'weekly_shapes_20', kind: QuestKind.weekly, event: ProgressionEvent.shapeDrawn, target: 20, coins: 150),
    Quest(id: 'weekly_layers_10', kind: QuestKind.weekly, event: ProgressionEvent.layerAdded, target: 10, coins: 150),
    Quest(
      id: 'weekly_frames_20',
      kind: QuestKind.weekly,
      event: ProgressionEvent.frameAdded,
      target: 20,
      coins: 200,
      requirement: QuestRequirement.animator,
    ),
    Quest(
      id: 'weekly_publish_2',
      kind: QuestKind.weekly,
      event: ProgressionEvent.projectPublished,
      target: 2,
      coins: 200,
      requirement: QuestRequirement.signedIn,
    ),
    Quest(
      id: 'weekly_challenge',
      kind: QuestKind.weekly,
      event: ProgressionEvent.challengeEntered,
      target: 1,
      coins: 200,
      requirement: QuestRequirement.challengeRunning,
    ),
  ];

  /// "Finish daily quests" plus two others for [weekKey], distinct actions.
  static List<Quest> pickWeekly(String weekKey, DailyEligibility eligibility) {
    final key = '$weekKey|${eligibility.seed}|weekly';
    final seed = key.codeUnits.fold<int>(17, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
    final others = [
      for (final quest in weeklyPool)
        if (quest != weeklyDailies && eligibility.allows(quest.requirement)) quest,
    ]..shuffle(Random(seed));
    final picked = [weeklyDailies];
    for (final quest in others) {
      if (picked.length == 3) break;
      if (picked.every((other) => other.event != quest.event)) picked.add(quest);
    }
    return picked;
  }

  /// One quest per slot for [dayKey], never two with the same action.
  static List<Quest> pickDaily(String dayKey, DailyEligibility eligibility) {
    final picked = <Quest>[];
    for (final tier in dailyTiers) {
      final quest = candidates(tier, dayKey, eligibility)
          .where((candidate) => picked.every((other) => other.event != candidate.event))
          .firstOrNull;
      if (quest != null) picked.add(quest);
    }
    return picked;
  }
}

/// Which requirements hold for a user today.
class DailyEligibility {
  const DailyEligibility({
    required this.context,
    this.animator = false,
    this.generator = false,
    this.animationStates = false,
  });

  final DailyContext context;
  final bool animator;
  final bool generator;
  final bool animationStates;

  String get seed => context.seed;

  bool allows(QuestRequirement requirement) {
    return switch (requirement) {
      QuestRequirement.none => true,
      QuestRequirement.signedIn => context.signedIn,
      QuestRequirement.animator => animator,
      QuestRequirement.generator => generator,
      QuestRequirement.animationStates => animationStates,
      QuestRequirement.challengeRunning => context.signedIn && context.challengeRunning,
      QuestRequirement.oldProject => context.hasOldProject,
    };
  }
}

/// Daily login rewards in a repeating seven-day cycle, growing towards a
/// big seventh day. One missed day per cycle doesn't break it.
class LoginRewards {
  LoginRewards._();

  static const List<int> coinsByCycleDay = [10, 15, 20, 25, 30, 40, 100];

  static int get cycleLength => coinsByCycleDay.length;

  /// Reward for day [cycleDay] (1-based) of the cycle.
  static int coinsFor(int cycleDay) => coinsByCycleDay[(cycleDay - 1).clamp(0, cycleLength - 1)];
}

class CoinPrices {
  CoinPrices._();

  // Ads only exist on phones, so they stay a small speed-up (at most ~20% of a
  // regular player's income) rather than the main source of gems.
  static const int adReward = 15;
  static const int maxAdsPerDay = 3;
  static const Duration packTrial = Duration(hours: 1);

  /// Pro owners earn quest rewards faster.
  static const double proMultiplier = 1.5;

  static int effect(EffectType type) {
    return switch (EffectPackCatalog.packIdOf(type)) {
      EffectPackId.free => 0,
      EffectPackId.basicFilters => 150,
      EffectPackId.artistic || EffectPackId.materials || EffectPackId.motion || EffectPackId.lightingDistortion => 300,
      EffectPackId.worldGenerators || EffectPackId.vfxNature || EffectPackId.vfxMagic || EffectPackId.vfxAction => 400,
    };
  }

  /// Off the first pack bought with gems.
  static const double firstPackDiscount = 0.4;

  /// A pack never costs less than this share of its price, however many of
  /// its effects are owned.
  static const double packPriceFloor = 0.3;

  /// Days of absence after which daily quests pay double for a day.
  static const int welcomeBackAfterDays = 5;

  static int pack(EffectPackId pack) {
    return switch (pack) {
      EffectPackId.free => 0,
      EffectPackId.basicFilters => 1500,
      _ => 2500,
    };
  }
}

enum WalletReason { quest, streak, ad, effectPurchase, packPurchase, serverReward }

class WalletEntry extends Equatable {
  const WalletEntry({required this.amount, required this.reason, required this.at, this.detail});

  final int amount;
  final WalletReason reason;
  final DateTime at;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'reason': reason.name,
        'at': at.toIso8601String(),
        if (detail != null) 'detail': detail,
      };

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
        amount: json['amount'] as int,
        // Unknown reasons come from a newer app version; keep the amount.
        reason: WalletReason.values.asNameMap()[json['reason']] ?? WalletReason.serverReward,
        at: DateTime.parse(json['at'] as String),
        detail: json['detail'] as String?,
      );

  @override
  List<Object?> get props => [amount, reason, at, detail];
}

/// The Monday that starts [time]'s week, as a day key.
String weekKeyOf(DateTime time) => dayKeyOf(DateTime(time.year, time.month, time.day - (time.weekday - 1)));

String dayKeyOf(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)}';
}

/// Earned currency, quest progress and content unlocked without purchases.
///
/// All transitions are pure so they can be tested without storage or UI.
class ProgressionState extends Equatable {
  static const int _maxLedgerEntries = 100;
  static const int _maxClaimedGrants = 300;

  const ProgressionState({
    this.coins = 0,
    this.ledger = const [],
    this.progress = const {},
    this.claimedQuests = const {},
    this.dayKey,
    this.streakDays = 0,
    this.loginCycleDay = 0,
    this.graceUsed = false,
    this.loginRewardToday = 0,
    this.dailyQuestIds = const [],
    this.dailyRerolls = 0,
    this.dailyBonusClaimed = false,
    this.weekKey,
    this.weeklyQuestIds = const [],
    this.weeklyBonusClaimed = false,
    this.welcomeBackToday = false,
    this.firstPackDiscountUsed = false,
    this.goalPack,
    this.adsWatchedToday = 0,
    this.earnedEffects = const {},
    this.earnedPacks = const {},
    this.packTrials = const {},
    this.claimedGrants = const [],
  });

  final int coins;
  final List<WalletEntry> ledger;

  /// Starter quests by id; daily quests by `daily:<id>` for [dayKey].
  final Map<String, int> progress;
  final Set<String> claimedQuests;

  /// Last day with activity, as `yyyy-mm-dd` in local time.
  final String? dayKey;

  /// Days in a row the app was opened (one missed day per cycle forgiven).
  final int streakDays;

  /// Position (1-7) in the repeating login reward cycle; 0 before the first day.
  final int loginCycleDay;

  /// Whether this cycle's forgiven missed day is used up.
  final bool graceUsed;

  /// Gems paid for today's login, for the notification.
  final int loginRewardToday;

  /// Today's daily quests, one per slot. Chosen once per day and kept, so
  /// they don't change when the user signs in or a challenge starts.
  final List<String> dailyQuestIds;
  final int dailyRerolls;

  /// Whether the bonus for claiming all three main daily quests was paid.
  final bool dailyBonusClaimed;

  /// Monday of the current quest week, and its three weekly quests.
  final String? weekKey;
  final List<String> weeklyQuestIds;
  final bool weeklyBonusClaimed;

  /// Back after [CoinPrices.welcomeBackAfterDays] or more days away: daily
  /// quests pay double today.
  final bool welcomeBackToday;

  /// The one-time discount on the first pack bought with gems is used.
  final bool firstPackDiscountUsed;

  /// The pack the user is saving for, if any.
  final EffectPackId? goalPack;

  final int adsWatchedToday;
  final Set<EffectType> earnedEffects;
  final Set<EffectPackId> earnedPacks;
  final Map<EffectPackId, DateTime> packTrials;

  /// Ids of server reward grants already added to the wallet, newest first,
  /// so a grant is never paid twice.
  final List<String> claimedGrants;

  static String dailyProgressKey(Quest quest) => 'daily:${quest.id}';

  /// Where a quest's progress and claim are stored: daily and weekly quests
  /// are prefixed so they can be reset.
  static String progressKey(Quest quest) => switch (quest.kind) {
        QuestKind.daily => dailyProgressKey(quest),
        QuestKind.weekly => 'weekly:${quest.id}',
        _ => quest.id,
      };

  /// Which requirements hold, combining [context] with what the user has
  /// done so far.
  DailyEligibility eligibility([DailyContext context = const DailyContext()]) {
    int done(String questId) => progress[questId] ?? (claimedQuests.contains(questId) ? 1 << 20 : 0);
    return DailyEligibility(
      context: context,
      animator: done('frames_8') >= 2,
      generator: done('first_generated_animation') > 0,
      animationStates: done('first_animation_state') > 0,
    );
  }

  /// Today's quests: easy, medium, hard and the optional bonus.
  List<Quest> get dailyQuests {
    final chosen = [
      for (final id in dailyQuestIds)
        if (QuestCatalog.byId[id] case final quest?) quest,
    ];
    if (chosen.isNotEmpty) return chosen;
    // Saved before daily quests were stored: pick without outside context.
    return QuestCatalog.pickDaily(dayKey ?? dayKeyOf(DateTime.now()), eligibility());
  }

  /// The three quests that count toward the all-three bonus.
  List<Quest> get mainDailyQuests => dailyQuests.where((quest) => quest.tier != QuestTier.bonus).toList();

  Quest? get bonusDailyQuest => dailyQuests.where((quest) => quest.tier == QuestTier.bonus).firstOrNull;

  bool get canClaimDailyBonus {
    final main = mainDailyQuests;
    return !dailyBonusClaimed && main.isNotEmpty && main.every(isClaimed);
  }

  int get rerollsLeft => max(0, QuestCatalog.maxDailyRerolls - dailyRerolls);

  /// This week's quests; "finish daily quests" first.
  List<Quest> get weeklyQuests {
    final chosen = [
      for (final id in weeklyQuestIds)
        if (QuestCatalog.byId[id] case final quest?) quest,
    ];
    if (chosen.isNotEmpty) return chosen;
    return QuestCatalog.pickWeekly(weekKey ?? weekKeyOf(DateTime.now()), eligibility());
  }

  bool get canClaimWeeklyBonus {
    final quests = weeklyQuests;
    return !weeklyBonusClaimed && quests.isNotEmpty && quests.every(isClaimed);
  }

  // ── Pack prices and savings ───────────────────────────────────────────

  bool get firstPackDiscountAvailable => !firstPackDiscountUsed;

  /// Gems already spent (or earned) on single effects of [pack]; they count
  /// toward the pack so saving for it never wastes earlier purchases.
  int packCredit(EffectPackId pack) {
    return EffectPackCatalog.forId(pack)
        .types
        .where(earnedEffects.contains)
        .fold(0, (sum, type) => sum + CoinPrices.effect(type));
  }

  /// What [pack] costs this user in gems: the first pack is discounted and
  /// owned effects count toward it, down to [CoinPrices.packPriceFloor].
  int packPrice(EffectPackId pack) {
    final base = CoinPrices.pack(pack);
    if (base <= 0) return 0;
    final discounted = firstPackDiscountAvailable ? (base * (1 - CoinPrices.firstPackDiscount)).round() : base;
    final floor = (base * CoinPrices.packPriceFloor).round();
    return max(floor, discounted - packCredit(pack));
  }

  /// Gems earned (not spent) in the last [days] days, for the savings pace.
  int earnedInLast(int days, DateTime now) {
    final since = now.subtract(Duration(days: days));
    return ledger
        .where((entry) => entry.amount > 0 && entry.at.isAfter(since))
        .fold(0, (sum, entry) => sum + entry.amount);
  }

  /// Days until the goal pack is affordable at the last week's pace; 0 when
  /// it already is, null without a goal or any recent income.
  int? goalEtaDays(DateTime now) {
    final pack = goalPack;
    if (pack == null) return null;
    final missing = packPrice(pack) - coins;
    if (missing <= 0) return 0;
    final perDay = earnedInLast(7, now) / 7;
    if (perDay <= 0) return null;
    return (missing / perDay).ceil();
  }

  /// A daily quest can be swapped until it is done.
  bool canReroll(Quest quest) =>
      quest.kind == QuestKind.daily && rerollsLeft > 0 && !isComplete(quest) && !isClaimed(quest);

  int progressOf(Quest quest) {
    return min(progress[progressKey(quest)] ?? 0, quest.target);
  }

  bool isComplete(Quest quest) => progressOf(quest) >= quest.target;

  bool isClaimed(Quest quest) => claimedQuests.contains(progressKey(quest));

  /// Whether the quest is shown: its prerequisite, if any, was claimed.
  bool isUnlocked(Quest quest) => quest.requires == null || claimedQuests.contains(quest.requires);

  bool canClaim(Quest quest) => isUnlocked(quest) && isComplete(quest) && !isClaimed(quest);

  int get claimableCount =>
      [...QuestCatalog.oneTime, ...dailyQuests, ...weeklyQuests].where(canClaim).length +
      (canClaimDailyBonus ? 1 : 0) +
      (canClaimWeeklyBonus ? 1 : 0);

  bool hasPackTrial(EffectPackId pack, DateTime now) => packTrials[pack]?.isAfter(now) ?? false;

  bool ownsPack(EffectPackId pack, DateTime now) => earnedPacks.contains(pack) || hasPackTrial(pack, now);

  bool canUseEffect(EffectType type, DateTime now) =>
      earnedEffects.contains(type) || ownsPack(EffectPackCatalog.packIdOf(type), now);

  bool canWatchAdForCoins() => adsWatchedToday < CoinPrices.maxAdsPerDay;

  ProgressionState copyWith({
    int? coins,
    List<WalletEntry>? ledger,
    Map<String, int>? progress,
    Set<String>? claimedQuests,
    String? dayKey,
    int? streakDays,
    int? loginCycleDay,
    bool? graceUsed,
    int? loginRewardToday,
    List<String>? dailyQuestIds,
    int? dailyRerolls,
    bool? dailyBonusClaimed,
    String? weekKey,
    List<String>? weeklyQuestIds,
    bool? weeklyBonusClaimed,
    bool? welcomeBackToday,
    bool? firstPackDiscountUsed,
    EffectPackId? Function()? goalPack,
    int? adsWatchedToday,
    Set<EffectType>? earnedEffects,
    Set<EffectPackId>? earnedPacks,
    Map<EffectPackId, DateTime>? packTrials,
    List<String>? claimedGrants,
  }) {
    return ProgressionState(
      coins: coins ?? this.coins,
      ledger: ledger ?? this.ledger,
      progress: progress ?? this.progress,
      claimedQuests: claimedQuests ?? this.claimedQuests,
      dayKey: dayKey ?? this.dayKey,
      streakDays: streakDays ?? this.streakDays,
      loginCycleDay: loginCycleDay ?? this.loginCycleDay,
      graceUsed: graceUsed ?? this.graceUsed,
      loginRewardToday: loginRewardToday ?? this.loginRewardToday,
      dailyQuestIds: dailyQuestIds ?? this.dailyQuestIds,
      dailyRerolls: dailyRerolls ?? this.dailyRerolls,
      dailyBonusClaimed: dailyBonusClaimed ?? this.dailyBonusClaimed,
      weekKey: weekKey ?? this.weekKey,
      weeklyQuestIds: weeklyQuestIds ?? this.weeklyQuestIds,
      weeklyBonusClaimed: weeklyBonusClaimed ?? this.weeklyBonusClaimed,
      welcomeBackToday: welcomeBackToday ?? this.welcomeBackToday,
      firstPackDiscountUsed: firstPackDiscountUsed ?? this.firstPackDiscountUsed,
      goalPack: goalPack != null ? goalPack() : this.goalPack,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      earnedEffects: earnedEffects ?? this.earnedEffects,
      earnedPacks: earnedPacks ?? this.earnedPacks,
      packTrials: packTrials ?? this.packTrials,
      claimedGrants: claimedGrants ?? this.claimedGrants,
    );
  }

  ProgressionState _withCoins(int amount, WalletReason reason, DateTime now, {String? detail}) {
    final entries = [WalletEntry(amount: amount, reason: reason, at: now, detail: detail), ...ledger];
    return copyWith(
      coins: coins + amount,
      ledger: entries.length > _maxLedgerEntries ? entries.sublist(0, _maxLedgerEntries) : entries,
    );
  }

  /// Moves to [now]'s day: resets daily quests and pays the login reward.
  /// The login cycle goes on after yesterday, or after the day before once
  /// per cycle; otherwise it starts over.
  ProgressionState rollDay(DateTime now, {DailyContext context = const DailyContext()}) {
    final today = dayKeyOf(now);
    if (dayKey == today) {
      // Saved before daily/weekly quests were stored: pick them once.
      if (dailyQuestIds.isNotEmpty && weeklyQuestIds.isNotEmpty) return this;
      return copyWith(
        dailyQuestIds: [for (final quest in dailyQuests) quest.id],
        weekKey: weekKey ?? weekKeyOf(now),
        weeklyQuestIds: [for (final quest in weeklyQuests) quest.id],
      );
    }

    final yesterday = dayKeyOf(DateTime(now.year, now.month, now.day - 1));
    final dayBefore = dayKeyOf(DateTime(now.year, now.month, now.day - 2));
    final continues = dayKey == yesterday;
    final forgiven = !continues && dayKey == dayBefore && !graceUsed && loginCycleDay > 0;

    final int cycleDay;
    final bool grace;
    if (continues || forgiven) {
      cycleDay = loginCycleDay % LoginRewards.cycleLength + 1;
      // A new cycle brings a new forgiven day.
      grace = cycleDay == 1 ? forgiven : (graceUsed || forgiven);
    } else {
      cycleDay = 1;
      grace = false;
    }
    final reward = LoginRewards.coinsFor(cycleDay);
    final lastDay = dayKey == null ? null : DateTime.tryParse(dayKey!);
    final daysAway = lastDay == null ? 0 : DateTime(now.year, now.month, now.day).difference(lastDay).inDays;
    final thisWeek = weekKeyOf(now);
    final newWeek = weekKey != thisWeek;

    final reset = copyWith(
      dayKey: today,
      streakDays: continues || forgiven ? streakDays + 1 : 1,
      loginCycleDay: cycleDay,
      graceUsed: grace,
      loginRewardToday: reward,
      dailyRerolls: 0,
      dailyBonusClaimed: false,
      welcomeBackToday: daysAway >= CoinPrices.welcomeBackAfterDays,
      adsWatchedToday: 0,
      weekKey: thisWeek,
      weeklyBonusClaimed: newWeek ? false : weeklyBonusClaimed,
      progress: {
        for (final entry in progress.entries)
          if (!entry.key.startsWith('daily:') && !(newWeek && entry.key.startsWith('weekly:'))) entry.key: entry.value,
      },
      claimedQuests: {
        for (final key in claimedQuests)
          if (!key.startsWith('daily:') && !(newWeek && key.startsWith('weekly:'))) key,
      },
    );
    final eligibility = reset.eligibility(context);
    return reset.copyWith(
      dailyQuestIds: [for (final quest in QuestCatalog.pickDaily(today, eligibility)) quest.id],
      weeklyQuestIds: newWeek || weeklyQuestIds.isEmpty
          ? [for (final quest in QuestCatalog.pickWeekly(thisWeek, eligibility)) quest.id]
          : null,
    )._withCoins(reward, WalletReason.streak, now, detail: 'day $cycleDay');
  }

  /// Counts [event]; returns the new state and the quests it just completed.
  (ProgressionState, List<Quest>) record(
    ProgressionEvent event,
    DateTime now, {
    int count = 1,
    DailyContext context = const DailyContext(),
  }) {
    final current = rollDay(now, context: context);
    return current._count(event, count);
  }

  (ProgressionState, List<Quest>) _count(ProgressionEvent event, int count) {
    final current = this;
    final quests = [
      ...QuestCatalog.oneTime.where((quest) => quest.event == event),
      ...current.dailyQuests.where((quest) => quest.event == event),
      ...current.weeklyQuests.where((quest) => quest.event == event),
    ];
    if (quests.isEmpty) return (current, const []);

    final progress = Map<String, int>.from(current.progress);
    final completed = <Quest>[];
    for (final quest in quests) {
      final key = progressKey(quest);
      final before = progress[key] ?? 0;
      if (before >= quest.target) continue;
      final after = before + count;
      // Stop counting past the target so progress maps stay small.
      progress[key] = min(after, quest.target);
      // Hidden tiers keep counting but are announced once they appear.
      if (after >= quest.target && current.isUnlocked(quest)) completed.add(quest);
    }
    return (current.copyWith(progress: progress), completed);
  }

  /// Pays out a completed quest once. Returns null if it cannot be claimed.
  ProgressionState? claim(Quest quest, DateTime now, {double multiplier = 1}) {
    if (!canClaim(quest)) return null;
    final isDaily = quest.kind == QuestKind.daily;
    final welcomeBack = isDaily && welcomeBackToday ? 2 : 1;
    final reward = (quest.coins * multiplier * welcomeBack).round();
    final claimed = _withCoins(reward, WalletReason.quest, now, detail: quest.id).copyWith(
      claimedQuests: {...claimedQuests, progressKey(quest)},
      earnedEffects: quest.rewardEffect == null ? null : {...earnedEffects, quest.rewardEffect!},
    );
    // Claimed dailies count toward "finish daily quests" this week.
    return isDaily ? claimed._count(ProgressionEvent.dailyQuestClaimed, 1).$1 : claimed;
  }

  /// Pays the bonus for claiming all three weekly quests, once a week.
  ProgressionState? claimWeeklyBonus(DateTime now, {double multiplier = 1}) {
    if (!canClaimWeeklyBonus) return null;
    final reward = (QuestCatalog.allWeeklyBonus * multiplier).round();
    return _withCoins(reward, WalletReason.quest, now, detail: 'weekly_bonus').copyWith(weeklyBonusClaimed: true);
  }

  ProgressionState setGoal(EffectPackId? pack) => copyWith(goalPack: () => pack);

  /// Pays the bonus for claiming all three main daily quests, once a day.
  ProgressionState? claimDailyBonus(DateTime now, {double multiplier = 1}) {
    if (!canClaimDailyBonus) return null;
    final reward = (QuestCatalog.allDailyBonus * multiplier).round();
    return _withCoins(reward, WalletReason.quest, now, detail: 'daily_bonus').copyWith(dailyBonusClaimed: true);
  }

  /// Swaps a daily quest for the next one of its slot the user can do.
  /// Returns null when it can't be swapped or nothing else fits.
  ProgressionState? rerollDaily(Quest quest, {DailyContext context = const DailyContext()}) {
    final tier = quest.tier;
    if (tier == null || !canReroll(quest)) return null;
    final today = dailyQuests;
    final index = today.indexWhere((other) => other.id == quest.id);
    if (index < 0) return null;

    final candidates = QuestCatalog.candidates(tier, dayKey ?? dayKeyOf(DateTime.now()), eligibility(context));
    final start = candidates.indexWhere((candidate) => candidate.id == quest.id);
    for (var step = 1; step <= candidates.length; step++) {
      final candidate = candidates[(start + step) % candidates.length];
      final clashes = today.any((other) => other.id != quest.id && other.event == candidate.event);
      if (candidate.id == quest.id || clashes || isClaimed(candidate)) continue;
      final ids = [for (final other in today) other.id]..[index] = candidate.id;
      return copyWith(dailyQuestIds: ids, dailyRerolls: dailyRerolls + 1);
    }
    return null;
  }

  ProgressionState? buyEffect(EffectType type, DateTime now) {
    final price = CoinPrices.effect(type);
    if (price <= 0 || coins < price || canUseEffect(type, now)) return null;
    return _withCoins(-price, WalletReason.effectPurchase, now, detail: type.name)
        .copyWith(earnedEffects: {...earnedEffects, type});
  }

  ProgressionState? buyPack(EffectPackId pack, DateTime now) {
    final price = packPrice(pack);
    if (price <= 0 || coins < price || earnedPacks.contains(pack)) return null;
    return _withCoins(-price, WalletReason.packPurchase, now, detail: pack.name).copyWith(
      earnedPacks: {...earnedPacks, pack},
      firstPackDiscountUsed: true,
      // Reached the goal: clear it so the next one can be picked.
      goalPack: goalPack == pack ? () => null : null,
    );
  }


  ProgressionState? rewardAd(DateTime now) {
    final current = rollDay(now);
    if (!current.canWatchAdForCoins()) return null;
    return current
        ._withCoins(CoinPrices.adReward, WalletReason.ad, now)
        .copyWith(adsWatchedToday: current.adsWatchedToday + 1);
  }

  bool hasClaimedGrant(String grantId) => claimedGrants.contains(grantId);

  /// Adds a server reward (gems and optionally a pack) once per [grantId].
  /// Returns null when it was already added.
  ProgressionState? applyServerGrant(String grantId,
      {required int gems, EffectPackId? pack, required DateTime now, String? detail}) {
    if (hasClaimedGrant(grantId)) return null;
    final ids = [grantId, ...claimedGrants];
    var next = copyWith(
      claimedGrants: ids.length > _maxClaimedGrants ? ids.sublist(0, _maxClaimedGrants) : ids,
      earnedPacks: pack == null || pack == EffectPackId.free ? null : {...earnedPacks, pack},
    );
    if (gems > 0) next = next._withCoins(gems, WalletReason.serverReward, now, detail: detail);
    return next;
  }

  ProgressionState startPackTrial(EffectPackId pack, DateTime now) {
    return copyWith(
      packTrials: {
        for (final entry in packTrials.entries)
          if (entry.value.isAfter(now)) entry.key: entry.value,
        pack: now.add(CoinPrices.packTrial),
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'ledger': [for (final entry in ledger) entry.toJson()],
        'progress': progress,
        'claimedQuests': claimedQuests.toList(),
        'dayKey': dayKey,
        'streakDays': streakDays,
        'loginCycleDay': loginCycleDay,
        'graceUsed': graceUsed,
        'loginRewardToday': loginRewardToday,
        'dailyQuestIds': dailyQuestIds,
        'dailyRerolls': dailyRerolls,
        'dailyBonusClaimed': dailyBonusClaimed,
        'weekKey': weekKey,
        'weeklyQuestIds': weeklyQuestIds,
        'weeklyBonusClaimed': weeklyBonusClaimed,
        'welcomeBackToday': welcomeBackToday,
        'firstPackDiscountUsed': firstPackDiscountUsed,
        'goalPack': goalPack?.name,
        'adsWatchedToday': adsWatchedToday,
        'earnedEffects': [for (final type in earnedEffects) type.name],
        'earnedPacks': [for (final pack in earnedPacks) pack.name],
        'packTrials': {for (final entry in packTrials.entries) entry.key.name: entry.value.toIso8601String()},
        'claimedGrants': claimedGrants,
      };

  factory ProgressionState.fromJson(Map<String, dynamic> json) {
    T? byName<T extends Enum>(List<T> values, String name) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return null; // Content removed in a later version.
    }

    final streakDays = json['streakDays'] as int? ?? 0;
    return ProgressionState(
      coins: json['coins'] as int? ?? 0,
      ledger: [
        for (final entry in json['ledger'] as List? ?? const []) WalletEntry.fromJson(entry as Map<String, dynamic>),
      ],
      progress: (json['progress'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as int)),
      claimedQuests: {...(json['claimedQuests'] as List? ?? const []).cast<String>()},
      dayKey: json['dayKey'] as String?,
      streakDays: streakDays,
      // Saved before the login cycle: carry the streak into it.
      loginCycleDay:
          json['loginCycleDay'] as int? ?? (streakDays > 0 ? (streakDays - 1) % LoginRewards.cycleLength + 1 : 0),
      graceUsed: json['graceUsed'] as bool? ?? false,
      loginRewardToday: json['loginRewardToday'] as int? ?? 0,
      dailyQuestIds: [
        for (final id in (json['dailyQuestIds'] as List? ?? const []).cast<String>())
          if (QuestCatalog.byId.containsKey(id)) id,
      ],
      dailyRerolls: json['dailyRerolls'] as int? ?? 0,
      dailyBonusClaimed: json['dailyBonusClaimed'] as bool? ?? false,
      weekKey: json['weekKey'] as String?,
      weeklyQuestIds: [
        for (final id in (json['weeklyQuestIds'] as List? ?? const []).cast<String>())
          if (QuestCatalog.byId.containsKey(id)) id,
      ],
      weeklyBonusClaimed: json['weeklyBonusClaimed'] as bool? ?? false,
      welcomeBackToday: json['welcomeBackToday'] as bool? ?? false,
      // Saved before the discount existed: anyone who already bought a pack
      // with gems has had their first one.
      firstPackDiscountUsed: json['firstPackDiscountUsed'] as bool? ??
          (json['ledger'] as List? ?? const []).any((entry) => entry is Map && entry['reason'] == 'packPurchase'),
      goalPack: byName(EffectPackId.values, json['goalPack'] as String? ?? ''),
      adsWatchedToday: json['adsWatchedToday'] as int? ?? 0,
      earnedEffects: {
        for (final name in (json['earnedEffects'] as List? ?? const []).cast<String>())
          if (byName(EffectType.values, name) case final type?) type,
      },
      earnedPacks: {
        for (final name in (json['earnedPacks'] as List? ?? const []).cast<String>())
          if (byName(EffectPackId.values, name) case final pack?) pack,
      },
      packTrials: {
        for (final entry in (json['packTrials'] as Map<String, dynamic>? ?? const {}).entries)
          if (byName(EffectPackId.values, entry.key) case final pack?) pack: DateTime.parse(entry.value as String),
      },
      claimedGrants: (json['claimedGrants'] as List? ?? const []).cast<String>(),
    );
  }

  @override
  List<Object?> get props => [
        coins,
        ledger,
        progress,
        claimedQuests,
        dayKey,
        streakDays,
        loginCycleDay,
        graceUsed,
        loginRewardToday,
        dailyQuestIds,
        dailyRerolls,
        dailyBonusClaimed,
        weekKey,
        weeklyQuestIds,
        weeklyBonusClaimed,
        welcomeBackToday,
        firstPackDiscountUsed,
        goalPack,
        adsWatchedToday,
        earnedEffects,
        earnedPacks,
        packTrials,
        claimedGrants,
      ];
}
