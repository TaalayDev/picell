import 'dart:async';

import 'package:picell/providers/projects_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/project_api_models.dart';
import '../providers/providers.dart';
import '../data/models/progression_model.dart';
import 'progression_provider.dart';

part 'community_projects_providers.freezed.dart';
part 'community_projects_providers.g.dart';

@freezed
class CommunityProjectsState with _$CommunityProjectsState {
  const factory CommunityProjectsState({
    @Default([]) List<ApiProject> projects,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,
    @Default(1) int currentPage,
    String? error,
    @Default(ProjectFilters()) ProjectFilters filters,
    @Default([]) List<ApiTag> popularTags,
  }) = _CommunityProjectsState;
}

@riverpod
class CommunityProjects extends _$CommunityProjects {
  @override
  CommunityProjectsState build() {
    // Auto-load initial data
    scheduleMicrotask(() {
      loadProjects();
      loadPopularTags();
    });

    return const CommunityProjectsState();
  }

  Future<void> loadProjects({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      projects: refresh ? [] : state.projects,
      currentPage: refresh ? 1 : state.currentPage,
    );

    try {
      final response = await ref.read(projectAPIRepoProvider).getProjects(
            state.filters.copyWith(page: state.currentPage),
          );

      if (response.success && response.data != null) {
        final newProjects = response.data!.projects;
        final hasMore = state.currentPage < response.data!.pagination.totalPages;

        state = state.copyWith(
          projects: refresh ? newProjects : [...state.projects, ...newProjects],
          isLoading: false,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load projects',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(
      isLoadingMore: true,
      currentPage: state.currentPage + 1,
    );

    try {
      final response = await ref.read(projectAPIRepoProvider).getProjects(
            state.filters.copyWith(page: state.currentPage),
          );

      if (response.success && response.data != null) {
        final newProjects = response.data!.projects;
        final hasMore = state.currentPage < response.data!.pagination.totalPages;

        state = state.copyWith(
          projects: [...state.projects, ...newProjects],
          isLoadingMore: false,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          currentPage: state.currentPage - 1, // Revert page increment
          error: response.error ?? 'Failed to load more projects',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        currentPage: state.currentPage - 1, // Revert page increment
        error: e.toString(),
      );
    }
  }

  Future<void> searchProjects(String query) async {
    final newFilters = state.filters.copyWith(search: query.isEmpty ? null : query);
    await updateFilters(newFilters);
  }

  Future<void> updateFilters(ProjectFilters newFilters) async {
    state = state.copyWith(
      filters: newFilters,
      currentPage: 1,
    );
    await loadProjects(refresh: true);
  }

  Future<void> setSortOrder(String sort) async {
    final newFilters = state.filters.copyWith(sort: sort);
    await updateFilters(newFilters);
  }

  Future<void> filterByTags(List<String> tags) async {
    final newFilters = state.filters.copyWith(tags: tags);
    await updateFilters(newFilters);
  }

  Future<void> filterByUser(String username) async {
    final newFilters = state.filters.copyWith(username: username);
    await updateFilters(newFilters);
  }

  Future<void> clearFilters() async {
    await updateFilters(const ProjectFilters());
  }

  Future<void> loadPopularTags() async {
    try {
      final response = await ref.read(projectAPIRepoProvider).getPopularTags();
      if (response.success && response.data != null) {
        state = state.copyWith(popularTags: response.data!);
      }
    } catch (e) {
      // Silent fail for tags - not critical
    }
  }

  final Set<int> _likeInFlight = {};

  void _applyLike(int projectId, {required bool isLiked, required int likeCount}) {
    state = state.copyWith(
      projects: [
        for (final p in state.projects)
          if (p.id == projectId) p.copyWith(isLiked: isLiked, likeCount: likeCount) else p,
      ],
    );

    // The detail screen reads its own provider, so mirror the like there too
    // (only if it is alive — don't trigger a fetch).
    for (final includeData in const [true, false]) {
      final detail = communityProjectProvider(projectId, includeData: includeData);
      if (ref.exists(detail)) {
        ref.read(detail.notifier).applyLike(isLiked: isLiked, likeCount: likeCount);
      }
    }
  }

  /// Toggles the like optimistically: the UI flips immediately, the server
  /// result reconciles it, and a failure rolls it back. Returns false when
  /// the like could not be saved.
  Future<bool> toggleLike(ApiProject project) async {
    if (!_likeInFlight.add(project.id)) return true;

    final wasLiked = project.isLiked == true;
    final baseCount = project.likeCount;
    final optimisticLiked = !wasLiked;
    final optimisticCount = (baseCount + (optimisticLiked ? 1 : -1)).clamp(0, 1 << 31);
    _applyLike(project.id, isLiked: optimisticLiked, likeCount: optimisticCount);

    try {
      ref.read(analyticsProvider).logEvent(name: 'community_project_like');
      final response = await ref.read(projectAPIRepoProvider).toggleLike(project.id);

      if (response.success && response.data != null) {
        final liked = response.data!.liked;
        if (liked) ref.read(progressionProvider.notifier).record(ProgressionEvent.projectLiked);
        if (liked != optimisticLiked) {
          // Server disagreed with our guess (e.g. liked from another device).
          final count = (baseCount + (liked == wasLiked ? 0 : (liked ? 1 : -1))).clamp(0, 1 << 31);
          _applyLike(project.id, isLiked: liked, likeCount: count);
        }
        return true;
      }
    } catch (_) {
      // fall through to rollback
    } finally {
      _likeInFlight.remove(project.id);
    }

    _applyLike(project.id, isLiked: wasLiked, likeCount: baseCount);
    return false;
  }

  /// Saves edits to a project the user owns and mirrors them into the cached
  /// list and the detail provider. Returns false when the server rejected the
  /// update; network/parse errors propagate so callers can show them.
  Future<bool> updateProjectInfo(
    ApiProject project, {
    String? title,
    String? description,
    List<String>? tags,
    bool? isPublic,
  }) async {
    final response = await ref.read(projectAPIRepoProvider).updateProject(
          projectId: project.id,
          title: title,
          description: description,
          tags: tags,
          isPublic: isPublic,
        );
    if (!response.success) return false;

    final updated = response.data;
    state = state.copyWith(
      projects: state.projects.map((p) {
        if (p.id != project.id) return p;
        return p.copyWith(
          title: updated?.title ?? title ?? p.title,
          description: updated?.description ?? description ?? p.description,
          tags: updated?.tags ?? tags ?? p.tags,
          isPublic: updated?.isPublic ?? isPublic ?? p.isPublic,
        );
      }).toList(),
    );

    ref.invalidate(communityProjectProvider(project.id, includeData: true));
    ref.invalidate(communityProjectProvider(project.id));
    return true;
  }

  void refresh() {
    loadProjects(refresh: true);
  }

  Future<bool> deleteProject(ApiProject project) async {
    final response = await ref.read(projectAPIRepoProvider).deleteProject(project.id);
    if (response.success) {
      final proj = await ref.read(projectRepo).fetchProjectByRemoteId(project.id);
      if (proj != null) {
        ref.read(projectsProvider.notifier).markProjectAsUnsynced(proj.id);
      }

      final updatedProjects = state.projects.where((p) => p.id != project.id).toList();
      state = state.copyWith(projects: updatedProjects);
      return true;
    } else {
      return false;
    }
  }
}

@riverpod
class FeaturedProjects extends _$FeaturedProjects {
  @override
  Future<List<ApiProject>> build() async {
    final response = await ref.read(projectAPIRepoProvider).getFeaturedProjects();
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load featured projects');
  }
}

@riverpod
class TrendingProjects extends _$TrendingProjects {
  @override
  Future<List<ApiProject>> build() async {
    final response = await ref.read(projectAPIRepoProvider).getTrendingProjects();
    if (response.success && response.data != null) {
      return response.data!.projects;
    }
    throw Exception(response.error ?? 'Failed to load trending projects');
  }
}

// For accessing individual projects
@riverpod
class CommunityProject extends _$CommunityProject {
  @override
  Future<ApiProject> build(int projectId, {bool includeData = false}) async {
    final response = await ref.read(projectAPIRepoProvider).getProject(projectId, includeData: includeData);

    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load project');
  }

  /// Applies a like toggle performed elsewhere without refetching.
  void applyLike({required bool isLiked, required int likeCount}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(isLiked: isLiked, likeCount: likeCount));
  }
}

// Direct forks (remixes) of a project — other users' uploads created by
// downloading and re-editing this one.
@riverpod
class ProjectForks extends _$ProjectForks {
  @override
  Future<List<ApiProject>> build(int projectId) async {
    final response = await ref.read(projectAPIRepoProvider).getProjectForks(projectId);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load forks');
  }
}

// Other public projects by the same author — used for the "More by this
// user" section on the project detail screen.
@riverpod
class UserProjects extends _$UserProjects {
  @override
  Future<List<ApiProject>> build(String username) async {
    final response = await ref.read(projectAPIRepoProvider).getUserProjects(username);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load user projects');
  }
}

// Comments provider
@riverpod
class ProjectComments extends _$ProjectComments {
  @override
  Future<List<ApiComment>> build(int projectId) async {
    final response = await ref.read(projectAPIRepoProvider).getComments(projectId);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load comments');
  }

  Future<void> addComment(String content, {int? parentId}) async {
    ref.read(analyticsProvider).logEvent(name: 'community_project_comment');

    final response = await ref.read(projectAPIRepoProvider).addComment(
          projectId,
          content,
          parentId: parentId,
        );

    if (response.success) {
      // Refresh comments after adding
      ref.invalidateSelf();
    } else {
      throw Exception(response.error ?? 'Failed to add comment');
    }
  }
}
