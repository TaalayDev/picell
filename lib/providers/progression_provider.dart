import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/models/progression_model.dart';
import '../data/storage/local_storage.dart';
import '../pixel/effects/effect_pack_catalog.dart';
import '../pixel/effects/effects.dart';
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
    final current = loaded.rollDay(DateTime.now());
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
    final next = before.rollDay(DateTime.now());
    if (identical(next, before)) return;
    _update(next);
    _announceStreak(before, next);
  }

  void record(ProgressionEvent event, {int count = 1}) {
    final before = state;
    final (next, completed) = before.record(event, DateTime.now(), count: count);
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

  bool buyEffect(EffectType type) => _apply(state.buyEffect(type, DateTime.now()));

  bool buyPack(EffectPackId pack) => _apply(state.buyPack(pack, DateTime.now()));

  /// Pays for a watched rewarded ad; false once today's limit is reached.
  bool rewardAd() => _apply(state.rewardAd(DateTime.now()));

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

  void _announceStreak(ProgressionState before, ProgressionState after) {
    for (final days in after.claimedStreakDays.difference(before.claimedStreakDays)) {
      _notices.add(StreakRewardNotice(days, StreakRewards.coinsByDay[days] ?? 0));
    }
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
