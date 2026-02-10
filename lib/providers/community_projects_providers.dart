import 'dart:async';

import 'package:picell/providers/projects_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/project_api_models.dart';
import '../providers/providers.dart';

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

  Future<void> toggleLike(ApiProject project) async {
    try {
      ref.read(analyticsProvider).logEvent(name: 'community_project_like');

      final response = await ref.read(projectAPIRepoProvider).toggleLike(project.id);

      if (response.success && response.data != null) {
        final isLiked = response.data!.liked;
        final newLikeCount = isLiked ? project.likeCount + 1 : project.likeCount - 1;

        // Update the project in our local state
        final updatedProjects = state.projects.map((p) {
          if (p.id == project.id) {
            return p.copyWith(
              isLiked: isLiked,
              likeCount: newLikeCount,
            );
          }
          return p;
        }).toList();

        state = state.copyWith(projects: updatedProjects);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
    }
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
