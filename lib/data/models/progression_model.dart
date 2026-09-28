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
}

enum QuestKind { starter, daily }

class Quest extends Equatable {
  const Quest({
    required this.id,
    required this.kind,
    required this.event,
    required this.target,
    required this.coins,
    this.rewardEffect,
  });

  final String id;
  final QuestKind kind;
  final ProgressionEvent event;
  final int target;
  final int coins;

  /// An effect unlocked for free when the quest is claimed.
  final EffectType? rewardEffect;

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
    Quest(id: 'publish_5', kind: QuestKind.starter, event: ProgressionEvent.projectPublished, target: 5, coins: 300),
  ];

  static const List<Quest> dailyPool = [
    Quest(id: 'daily_strokes', kind: QuestKind.daily, event: ProgressionEvent.strokeCompleted, target: 50, coins: 20),
    Quest(id: 'daily_effects', kind: QuestKind.daily, event: ProgressionEvent.effectAdded, target: 2, coins: 20),
    Quest(id: 'daily_frames', kind: QuestKind.daily, event: ProgressionEvent.frameAdded, target: 4, coins: 25),
    Quest(id: 'daily_export', kind: QuestKind.daily, event: ProgressionEvent.imageExported, target: 1, coins: 20),
    Quest(id: 'daily_layers', kind: QuestKind.daily, event: ProgressionEvent.layerAdded, target: 2, coins: 15),
    Quest(id: 'daily_project', kind: QuestKind.daily, event: ProgressionEvent.projectCreated, target: 1, coins: 20),
    Quest(
      id: 'daily_animation_export',
      kind: QuestKind.daily,
      event: ProgressionEvent.animationExported,
      target: 1,
      coins: 30,
    ),
  ];

  static final Map<String, Quest> byId = {
    for (final quest in [...starter, ...dailyPool]) quest.id: quest,
  };

  /// The same three daily quests for everyone on a given day.
  static List<Quest> dailyFor(String dayKey) {
    // String.hashCode differs between platforms, so hash the key ourselves.
    final seed = dayKey.codeUnits.fold<int>(17, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
    final random = Random(seed);
    final pool = [...dailyPool]..shuffle(random);
    return pool.take(dailyQuestCount).toList();
  }
}

/// Coins granted when a streak reaches the given number of days.
class StreakRewards {
  StreakRewards._();

  static const Map<int, int> coinsByDay = {3: 30, 7: 100, 14: 200, 30: 500};

  static int? nextMilestone(int streakDays) {
    for (final day in coinsByDay.keys) {
      if (day > streakDays) return day;
    }
    return null;
  }
}

class CoinPrices {
  CoinPrices._();

  static const int adReward = 20;
  static const int maxAdsPerDay = 5;
  static const Duration packTrial = Duration(hours: 1);

  /// Pro owners earn quest rewards faster.
  static const double proMultiplier = 1.5;

  static int effect(EffectType type) {
    return switch (EffectPackCatalog.packIdOf(type)) {
      EffectPackId.free => 0,
      EffectPackId.basicFilters => 150,
      EffectPackId.artistic ||
      EffectPackId.materials ||
      EffectPackId.motion ||
      EffectPackId.lightingDistortion =>
        300,
      EffectPackId.worldGenerators || EffectPackId.vfxNature || EffectPackId.vfxMagic || EffectPackId.vfxAction => 400,
    };
  }

  static int pack(EffectPackId pack) {
    return switch (pack) {
      EffectPackId.free => 0,
      EffectPackId.basicFilters => 1500,
      _ => 2500,
    };
  }
}

enum WalletReason { quest, streak, ad, effectPurchase, packPurchase }

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
        reason: WalletReason.values.byName(json['reason'] as String),
        at: DateTime.parse(json['at'] as String),
        detail: json['detail'] as String?,
      );

  @override
  List<Object?> get props => [amount, reason, at, detail];
}

String dayKeyOf(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)}';
}

/// Earned currency, quest progress and content unlocked without purchases.
///
/// All transitions are pure so they can be tested without storage or UI.
class ProgressionState extends Equatable {
  static const int _maxLedgerEntries = 100;

  const ProgressionState({
    this.coins = 0,
    this.ledger = const [],
    this.progress = const {},
    this.claimedQuests = const {},
    this.dayKey,
    this.streakDays = 0,
    this.claimedStreakDays = const {},
    this.adsWatchedToday = 0,
    this.earnedEffects = const {},
    this.earnedPacks = const {},
    this.packTrials = const {},
  });

  final int coins;
  final List<WalletEntry> ledger;

  /// Starter quests by id; daily quests by `daily:<id>` for [dayKey].
  final Map<String, int> progress;
  final Set<String> claimedQuests;

  /// Last day with activity, as `yyyy-mm-dd` in local time.
  final String? dayKey;
  final int streakDays;
  final Set<int> claimedStreakDays;
  final int adsWatchedToday;
  final Set<EffectType> earnedEffects;
  final Set<EffectPackId> earnedPacks;
  final Map<EffectPackId, DateTime> packTrials;

  static String dailyProgressKey(Quest quest) => 'daily:${quest.id}';

  List<Quest> get dailyQuests => QuestCatalog.dailyFor(dayKey ?? dayKeyOf(DateTime.now()));

  int progressOf(Quest quest) {
    final key = quest.kind == QuestKind.daily ? dailyProgressKey(quest) : quest.id;
    return min(progress[key] ?? 0, quest.target);
  }

  bool isComplete(Quest quest) => progressOf(quest) >= quest.target;

  bool isClaimed(Quest quest) {
    final key = quest.kind == QuestKind.daily ? dailyProgressKey(quest) : quest.id;
    return claimedQuests.contains(key);
  }

  bool canClaim(Quest quest) => isComplete(quest) && !isClaimed(quest);

  int get claimableCount => [...QuestCatalog.starter, ...dailyQuests].where(canClaim).length;

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
    Set<int>? claimedStreakDays,
    int? adsWatchedToday,
    Set<EffectType>? earnedEffects,
    Set<EffectPackId>? earnedPacks,
    Map<EffectPackId, DateTime>? packTrials,
  }) {
    return ProgressionState(
      coins: coins ?? this.coins,
      ledger: ledger ?? this.ledger,
      progress: progress ?? this.progress,
      claimedQuests: claimedQuests ?? this.claimedQuests,
      dayKey: dayKey ?? this.dayKey,
      streakDays: streakDays ?? this.streakDays,
      claimedStreakDays: claimedStreakDays ?? this.claimedStreakDays,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      earnedEffects: earnedEffects ?? this.earnedEffects,
      earnedPacks: earnedPacks ?? this.earnedPacks,
      packTrials: packTrials ?? this.packTrials,
    );
  }

  ProgressionState _withCoins(int amount, WalletReason reason, DateTime now, {String? detail}) {
    final entries = [WalletEntry(amount: amount, reason: reason, at: now, detail: detail), ...ledger];
    return copyWith(
      coins: coins + amount,
      ledger: entries.length > _maxLedgerEntries ? entries.sublist(0, _maxLedgerEntries) : entries,
    );
  }

  /// Moves to [now]'s day: resets daily progress and advances or breaks the
  /// streak. Streak milestones pay out automatically.
  ProgressionState rollDay(DateTime now) {
    final today = dayKeyOf(now);
    if (dayKey == today) return this;

    final yesterday = dayKeyOf(DateTime(now.year, now.month, now.day - 1));
    final continues = dayKey == yesterday;
    final newStreak = continues ? streakDays + 1 : 1;

    var next = copyWith(
      dayKey: today,
      streakDays: newStreak,
      claimedStreakDays: continues ? claimedStreakDays : const {},
      adsWatchedToday: 0,
      progress: {
        for (final entry in progress.entries)
          if (!entry.key.startsWith('daily:')) entry.key: entry.value,
      },
      claimedQuests: {
        for (final key in claimedQuests)
          if (!key.startsWith('daily:')) key,
      },
    );

    final reward = StreakRewards.coinsByDay[newStreak];
    if (reward != null && !next.claimedStreakDays.contains(newStreak)) {
      next = next
          ._withCoins(reward, WalletReason.streak, now, detail: '$newStreak')
          .copyWith(claimedStreakDays: {...next.claimedStreakDays, newStreak});
    }
    return next;
  }

  /// Counts [event]; returns the new state and the quests it just completed.
  (ProgressionState, List<Quest>) record(ProgressionEvent event, DateTime now, {int count = 1}) {
    final current = rollDay(now);
    final quests = [
      ...QuestCatalog.starter.where((quest) => quest.event == event),
      ...current.dailyQuests.where((quest) => quest.event == event),
    ];
    if (quests.isEmpty) return (current, const []);

    final progress = Map<String, int>.from(current.progress);
    final completed = <Quest>[];
    for (final quest in quests) {
      final key = quest.kind == QuestKind.daily ? dailyProgressKey(quest) : quest.id;
      final before = progress[key] ?? 0;
      if (before >= quest.target) continue;
      final after = before + count;
      // Stop counting past the target so progress maps stay small.
      progress[key] = min(after, quest.target);
      if (after >= quest.target) completed.add(quest);
    }
    return (current.copyWith(progress: progress), completed);
  }

  /// Pays out a completed quest once. Returns null if it cannot be claimed.
  ProgressionState? claim(Quest quest, DateTime now, {double multiplier = 1}) {
    if (!canClaim(quest)) return null;
    final key = quest.kind == QuestKind.daily ? dailyProgressKey(quest) : quest.id;
    final reward = (quest.coins * multiplier).round();
    return _withCoins(reward, WalletReason.quest, now, detail: quest.id).copyWith(
      claimedQuests: {...claimedQuests, key},
      earnedEffects: quest.rewardEffect == null ? null : {...earnedEffects, quest.rewardEffect!},
    );
  }

  ProgressionState? buyEffect(EffectType type, DateTime now) {
    final price = CoinPrices.effect(type);
    if (price <= 0 || coins < price || canUseEffect(type, now)) return null;
    return _withCoins(-price, WalletReason.effectPurchase, now, detail: type.name)
        .copyWith(earnedEffects: {...earnedEffects, type});
  }

  ProgressionState? buyPack(EffectPackId pack, DateTime now) {
    final price = CoinPrices.pack(pack);
    if (price <= 0 || coins < price || earnedPacks.contains(pack)) return null;
    return _withCoins(-price, WalletReason.packPurchase, now, detail: pack.name)
        .copyWith(earnedPacks: {...earnedPacks, pack});
  }

  ProgressionState? rewardAd(DateTime now) {
    final current = rollDay(now);
    if (!current.canWatchAdForCoins()) return null;
    return current
        ._withCoins(CoinPrices.adReward, WalletReason.ad, now)
        .copyWith(adsWatchedToday: current.adsWatchedToday + 1);
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
        'claimedStreakDays': claimedStreakDays.toList(),
        'adsWatchedToday': adsWatchedToday,
        'earnedEffects': [for (final type in earnedEffects) type.name],
        'earnedPacks': [for (final pack in earnedPacks) pack.name],
        'packTrials': {for (final entry in packTrials.entries) entry.key.name: entry.value.toIso8601String()},
      };

  factory ProgressionState.fromJson(Map<String, dynamic> json) {
    T? byName<T extends Enum>(List<T> values, String name) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return null; // Content removed in a later version.
    }

    return ProgressionState(
      coins: json['coins'] as int? ?? 0,
      ledger: [
        for (final entry in json['ledger'] as List? ?? const []) WalletEntry.fromJson(entry as Map<String, dynamic>),
      ],
      progress: (json['progress'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as int)),
      claimedQuests: {...(json['claimedQuests'] as List? ?? const []).cast<String>()},
      dayKey: json['dayKey'] as String?,
      streakDays: json['streakDays'] as int? ?? 0,
      claimedStreakDays: {...(json['claimedStreakDays'] as List? ?? const []).cast<int>()},
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
        claimedStreakDays,
        adsWatchedToday,
        earnedEffects,
        earnedPacks,
        packTrials,
      ];
}
