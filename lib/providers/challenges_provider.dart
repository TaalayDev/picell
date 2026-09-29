import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/models/challenge_models.dart';
import '../data/models/progression_model.dart';
import '../data/models/project_api_models.dart';
import '../data/storage/local_storage.dart';
import 'progression_provider.dart';
import 'providers.dart';

/// The app's language, sent as `Accept-Language` so texts come localized.
String _requestLanguage() {
  try {
    return (LocalStorage.instance.locale ?? PlatformDispatcher.instance.locale).languageCode;
  } catch (_) {
    return PlatformDispatcher.instance.locale.languageCode;
  }
}

final currentChallengesProvider =
    AsyncNotifierProvider<CurrentChallengesNotifier, CurrentChallenges?>(CurrentChallengesNotifier.new);

/// Challenges for the home banner. Falls back to the last response when the
/// network fails, and refreshes itself when the next challenge ends.
///
/// Resolves to null (never an error) when there is nothing to show, so the
/// banner simply stays hidden.
class CurrentChallengesNotifier extends AsyncNotifier<CurrentChallenges?> {
  static const _cacheKey = 'challenges_current_v1';
  static const _maxRefreshInterval = Duration(hours: 1);

  Timer? _refreshTimer;

  @override
  Future<CurrentChallenges?> build() async {
    ref.onDispose(() => _refreshTimer?.cancel());

    final result = await _fetch() ?? _readCache();
    _scheduleRefresh(result);
    return result;
  }

  /// Reloads after something that changes the user's entries, such as
  /// publishing a project with a challenge tag.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<CurrentChallenges?> _fetch() async {
    try {
      final response = await ref.read(challengeAPIRepoProvider).getCurrent(languageCode: _requestLanguage());
      final data = response.data;
      if (!response.success || data == null) return null;
      _writeCache(data);
      return data;
    } catch (e) {
      debugPrint('Failed to load challenges: $e');
      return null;
    }
  }

  /// Wakes up when the soonest running challenge ends, at most an hour away.
  void _scheduleRefresh(CurrentChallenges? current) {
    _refreshTimer?.cancel();
    var wait = _maxRefreshInterval;
    if (current != null) {
      final now = current.serverNow();
      for (final challenge in current.challenges) {
        final untilEnd = challenge.endsAt.difference(now);
        if (untilEnd > Duration.zero && untilEnd < wait) wait = untilEnd;
      }
    }
    _refreshTimer = Timer(wait + const Duration(seconds: 5), ref.invalidateSelf);
  }

  CurrentChallenges? _readCache() {
    try {
      final json = LocalStorage.instance.getString(_cacheKey);
      if (json == null) return null;
      return CurrentChallenges.fromCache(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to read cached challenges: $e');
      return null;
    }
  }

  void _writeCache(CurrentChallenges data) {
    try {
      LocalStorage.instance.setString(_cacheKey, jsonEncode(data.toJson()));
    } catch (e) {
      debugPrint('Failed to cache challenges: $e');
    }
  }
}

/// One challenge for the challenge screen.
final challengeDetailsProvider = FutureProvider.autoDispose.family<ChallengeDetails, int>((ref, id) async {
  final response = await ref.read(challengeAPIRepoProvider).getChallenge(id, languageCode: _requestLanguage());
  final data = response.data;
  if (!response.success || data == null) throw Exception(response.error ?? 'Failed to load challenge $id');
  return data;
});

enum ChallengeEntrySort { recent, winners }

typedef ChallengeEntriesKey = ({int challengeId, ChallengeEntrySort sort});

@immutable
class ChallengeEntriesState {
  const ChallengeEntriesState({
    this.projects = const [],
    this.page = 0,
    this.totalPages = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<ApiProject> projects;

  /// The last page loaded; 0 before the first one.
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < totalPages;

  ChallengeEntriesState copyWith({
    List<ApiProject>? projects,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ChallengeEntriesState(
      projects: projects ?? this.projects,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// The entries gallery of a challenge, loaded page by page.
final challengeEntriesProvider =
    NotifierProvider.autoDispose.family<ChallengeEntriesNotifier, ChallengeEntriesState, ChallengeEntriesKey>(
        ChallengeEntriesNotifier.new);

class ChallengeEntriesNotifier extends AutoDisposeFamilyNotifier<ChallengeEntriesState, ChallengeEntriesKey> {
  static const _pageSize = 20;

  /// Set when the screen closes; late responses are then dropped.
  bool _disposed = false;

  @override
  ChallengeEntriesState build(ChallengeEntriesKey arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(_loadNextPage);
    return const ChallengeEntriesState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _loadNextPage();
  }

  Future<void> refresh() async {
    state = const ChallengeEntriesState();
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final nextPage = state.page + 1;
    try {
      final response = await ref.read(challengeAPIRepoProvider).getEntries(
            arg.challengeId,
            sort: arg.sort.name,
            page: nextPage,
            limit: _pageSize,
          );
      final data = response.data;
      if (!response.success || data == null) throw Exception(response.error ?? 'Failed to load entries');
      if (_disposed) return;
      state = state.copyWith(
        projects: [...state.projects, ...data.projects],
        page: data.pagination.page,
        totalPages: data.pagination.totalPages,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e.toString());
    }
  }

  /// Likes or unlikes an entry and updates it in place.
  Future<void> toggleLike(ApiProject project) async {
    try {
      final response = await ref.read(projectAPIRepoProvider).toggleLike(project.id);
      final result = response.data;
      if (!response.success || result == null || _disposed) return;
      if (result.liked) ref.read(progressionProvider.notifier).record(ProgressionEvent.projectLiked);
      state = state.copyWith(
        projects: [
          for (final p in state.projects)
            p.id == project.id
                ? p.copyWith(isLiked: result.liked, likeCount: p.likeCount + (result.liked ? 1 : -1))
                : p,
        ],
      );
    } catch (e) {
      debugPrint('Failed to toggle like: $e');
    }
  }
}

/// The signed-in user's entries in every challenge, for "My entries".
final myChallengeEntriesProvider = FutureProvider.autoDispose<List<MyChallengeEntry>>((ref) async {
  final response = await ref.read(challengeAPIRepoProvider).getMyEntries(languageCode: _requestLanguage());
  final data = response.data;
  if (!response.success || data == null) throw Exception(response.error ?? 'Failed to load your entries');
  return data;
});

/// What the last publish or edit did to the project's challenge entries,
/// for the upload dialog to announce. Null until the server answers.
final challengeSubmissionProvider = StateProvider<ChallengeSubmission?>((ref) => null);

final serverRewardsProvider = Provider<ServerRewardsSync>(ServerRewardsSync.new);

/// Brings rewards the server paid (challenge participation, wins, support
/// grants) into the local wallet.
///
/// A grant is added to the wallet first and claimed on the server second, so
/// a crash or a lost connection in between never loses it: the next sync
/// sees it still unclaimed, skips the wallet (the id is remembered) and only
/// repeats the claim.
class ServerRewardsSync {
  ServerRewardsSync(this._ref);

  static const _minInterval = Duration(minutes: 2);

  final Ref _ref;
  Future<void>? _running;
  DateTime? _lastRun;

  /// Checks for new grants; does nothing when signed out or checked recently
  /// (unless [force]).
  Future<void> sync({bool force = false}) {
    final running = _running;
    if (running != null) return running;
    final token = LocalStorage.instance.token;
    if (token == null || token.isEmpty) return Future.value();
    final last = _lastRun;
    if (!force && last != null && DateTime.now().difference(last) < _minInterval) return Future.value();

    final future = _sync().whenComplete(() {
      _running = null;
      _lastRun = DateTime.now();
    });
    _running = future;
    return future;
  }

  Future<void> _sync() async {
    try {
      final repo = _ref.read(challengeAPIRepoProvider);
      final response = await repo.getMyGrants(languageCode: _requestLanguage());
      final grants = response.data;
      if (!response.success || grants == null) return;

      // Oldest first, so notifications arrive in the order rewards were paid.
      for (final grant in grants.reversed.where((grant) => grant.isUnclaimed)) {
        await _claim(grant);
      }
    } catch (e) {
      debugPrint('Failed to sync server rewards: $e');
    }
  }

  /// Claims one reward now, from the claim button on a challenge. Returns
  /// whether the server confirmed it; the wallet is credited either way (at
  /// most once), and a failed claim is repeated by the next sync.
  Future<bool> claim(RewardGrant grant) async {
    try {
      final confirmed = await _claim(grant);
      _ref.invalidate(currentChallengesProvider);
      return confirmed;
    } catch (e) {
      debugPrint('Failed to claim reward ${grant.id}: $e');
      return false;
    }
  }

  Future<bool> _claim(RewardGrant grant) async {
    _ref.read(progressionProvider.notifier).applyServerGrant(grant);
    final claim = await _ref.read(challengeAPIRepoProvider).claimGrant(grant.id);
    if (!claim.success) debugPrint('Reward ${grant.id} not claimed yet: ${claim.error}');
    return claim.success;
  }
}
