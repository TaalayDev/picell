import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/models/challenge_models.dart';
import '../data/models/progression_model.dart';
import '../data/storage/local_storage.dart';
import '../pixel/effects/effect_pack_catalog.dart';
import '../pixel/effects/effects.dart';
import 'auth_provider.dart';
import 'challenges_provider.dart';
import 'projects_provider.dart';
import 'subscription_provider.dart';

/// Something the user should be told about right away.
sealed class ProgressionNotice {
  const ProgressionNotice();
}

class QuestCompletedNotice extends ProgressionNotice {
  const QuestCompletedNotice(this.quest);

  final Quest quest;
}

class StreakRewardNotice extends ProgressionNotice {
  const StreakRewardNotice(this.days, this.coins);

  final int days;
  final int coins;
}

/// A reward from the server (a challenge or support) reached the wallet.
class ServerRewardNotice extends ProgressionNotice {
  const ServerRewardNotice(this.grant, this.pack);

  final RewardGrant grant;
  final EffectPackId? pack;
}

final progressionProvider = NotifierProvider<ProgressionNotifier, ProgressionState>(ProgressionNotifier.new);

/// Quests, earned currency and content unlocked by playing rather than paying.
///
/// Recording is cheap (in-memory counters); storage writes are debounced so
/// hot paths such as strokes never wait on disk.
class ProgressionNotifier extends Notifier<ProgressionState> {
  static const _storageKey = 'progression_v1';
  static const _saveDelay = Duration(seconds: 1);

  final _notices = StreamController<ProgressionNotice>.broadcast();
  Timer? _saveTimer;
  Timer? _trialTimer;

  Stream<ProgressionNotice> get notices => _notices.stream;

  @override
  ProgressionState build() {
    ref.onDispose(() {
      if (_saveTimer?.isActive ?? false) _save();
      _saveTimer?.cancel();
      _trialTimer?.cancel();
      _notices.close();
    });

    final loaded = _load();
    final current = loaded.rollDay(DateTime.now(), context: _dailyContext());
    if (current != loaded) {
      // Listeners subscribe right after the first read, so announce later.
      scheduleMicrotask(() => _announceStreak(loaded, current));
      _scheduleSave();
    }
    _scheduleTrialExpiry(current);
    return current;
  }

  /// Moves to today when the app comes back: resets dailies, extends streaks.
  void checkIn() {
    final before = state;
    final next = before.rollDay(DateTime.now(), context: _dailyContext());
    if (identical(next, before)) return;
    _update(next);
    _announceStreak(before, next);
  }

  void record(ProgressionEvent event, {int count = 1}) {
    final before = state;
    final (next, completed) = before.record(event, DateTime.now(), count: count, context: _dailyContext());
    if (identical(next, before)) return;
    _update(next);
    _announceStreak(before, next);
    // One event can finish a starter and a daily quest with the same title;
    // a single notification is enough to send the user to claim both.
    if (completed.isNotEmpty) _notices.add(QuestCompletedNotice(completed.first));
  }

  bool claim(Quest quest) {
    final multiplier = ref.read(subscriptionStateProvider).isPermanentPro ? CoinPrices.proMultiplier : 1.0;
    return _apply(state.claim(quest, DateTime.now(), multiplier: multiplier));
  }

  /// Pays the bonus for claiming all three main daily quests.
  bool claimDailyBonus() {
    final multiplier = ref.read(subscriptionStateProvider).isPermanentPro ? CoinPrices.proMultiplier : 1.0;
    return _apply(state.claimDailyBonus(DateTime.now(), multiplier: multiplier));
  }

  /// Pays the bonus for claiming all three weekly quests.
  bool claimWeeklyBonus() {
    final multiplier = ref.read(subscriptionStateProvider).isPermanentPro ? CoinPrices.proMultiplier : 1.0;
    return _apply(state.claimWeeklyBonus(DateTime.now(), multiplier: multiplier));
  }

  /// Picks the pack to save for; null stops saving.
  void setGoal(EffectPackId? pack) => _update(state.setGoal(pack));

  /// Swaps a daily quest for another one of its slot.
  bool rerollDaily(Quest quest) => _apply(state.rerollDaily(quest, context: _dailyContext()));

  bool buyEffect(EffectType type) => _apply(state.buyEffect(type, DateTime.now()));

  bool buyPack(EffectPackId pack) => _apply(state.buyPack(pack, DateTime.now()));

  /// Pays for a watched rewarded ad; false once today's limit is reached.
  bool rewardAd() => _apply(state.rewardAd(DateTime.now()));

  bool hasClaimedGrant(String grantId) => state.hasClaimedGrant(grantId);

  /// Adds a claimed server grant to the wallet once and announces it.
  /// Saves right away: the server already counts the grant as claimed.
  bool applyServerGrant(RewardGrant grant) {
    final pack = EffectPackId.values.asNameMap()[grant.effectPack];
    final next = state.applyServerGrant(
      grant.id,
      gems: grant.gems,
      pack: pack,
      now: DateTime.now(),
      detail: grant.challengeTag ?? grant.reason.name,
    );
    if (next == null) return false;
    state = next;
    _saveTimer?.cancel();
    _save();
    _notices.add(ServerRewardNotice(grant, pack));
    return true;
  }

  void startPackTrial(EffectPackId pack) {
    final next = state.startPackTrial(pack, DateTime.now());
    _update(next);
    _scheduleTrialExpiry(next);
  }

  bool _apply(ProgressionState? next) {
    if (next == null) return false;
    _update(next);
    return true;
  }

  void _update(ProgressionState next) {
    state = next;
    _scheduleSave();
  }

  /// Announces the login reward paid when a new day starts.
  void _announceStreak(ProgressionState before, ProgressionState after) {
    if (before.dayKey == after.dayKey || after.loginRewardToday <= 0) return;
    _notices.add(StreakRewardNotice(after.streakDays, after.loginRewardToday));
  }

  /// What decides which daily quests can be offered today. Reads other
  /// providers without watching them: quests are chosen once per day.
  DailyContext _dailyContext() {
    var signedIn = false;
    var challengeRunning = false;
    var hasOldProject = false;
    var seed = '';
    try {
      signedIn = ref.read(authProvider).isSignedIn;
    } catch (_) {}
    try {
      challengeRunning = ref.read(currentChallengesProvider).valueOrNull?.running().isNotEmpty ?? false;
    } catch (_) {}
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      hasOldProject =
          ref.read(projectsProvider).valueOrNull?.any((project) => project.createdAt.isBefore(weekAgo)) ?? false;
    } catch (_) {}
    try {
      seed = LocalStorage.instance.installationId;
    } catch (_) {}
    return DailyContext(
      signedIn: signedIn,
      challengeRunning: challengeRunning,
      hasOldProject: hasOldProject,
      seed: seed,
    );
  }

  /// Rebuilds dependents when the earliest trial ends, so access is revoked.
  void _scheduleTrialExpiry(ProgressionState current) {
    _trialTimer?.cancel();
    final now = DateTime.now();
    final active = current.packTrials.values.where((end) => end.isAfter(now)).toList()..sort();
    if (active.isEmpty) return;
    _trialTimer = Timer(active.first.difference(now), () {
      final pruned = state.copyWith(
        packTrials: {
          for (final entry in state.packTrials.entries)
            if (entry.value.isAfter(DateTime.now())) entry.key: entry.value,
        },
      );
      _update(pruned);
      _scheduleTrialExpiry(pruned);
    });
  }

  ProgressionState _load() {
    try {
      final json = LocalStorage.instance.getString(_storageKey);
      if (json == null) return const ProgressionState();
      return ProgressionState.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load progression: $e');
      return const ProgressionState();
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
  }

  void _save() {
    try {
      LocalStorage.instance.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Failed to save progression: $e');
    }
  }
}

/// Whether [EffectType] can be used through a purchase, an earned unlock or a trial.
final effectAccessProvider = Provider.autoDispose.family<bool, EffectType>((ref, type) {
  if (ref.watch(subscriptionStateProvider).canUseEffect(type)) return true;
  return ref.watch(progressionProvider).canUseEffect(type, DateTime.now());
});

final effectPackAccessProvider = Provider.autoDispose.family<bool, EffectPackId>((ref, pack) {
  if (ref.watch(subscriptionStateProvider).ownsEffectPack(pack)) return true;
  return ref.watch(progressionProvider).ownsPack(pack, DateTime.now());
});
