import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/project_api_models.dart';
import '../data.dart';
import '../providers/providers.dart';
import 'auth_provider.dart';

part 'project_download_provider.freezed.dart';

@freezed
class ProjectDownloadState with _$ProjectDownloadState {
  const factory ProjectDownloadState({
    @Default(false) bool isDownloading,
    @Default(0.0) double downloadProgress,
    String? error,
    @Default(false) bool isSuccess,
    Project? downloadedProject,
  }) = _ProjectDownloadState;
}

class ProjectDownloadNotifier extends StateNotifier<ProjectDownloadState> {
  final Ref _ref;

  ProjectDownloadNotifier(this._ref) : super(const ProjectDownloadState());

  Future<void> downloadProject(ApiProject apiProject) async {
    try {
      state = state.copyWith(
        isDownloading: true,
        downloadProgress: 0.0,
        error: null,
        isSuccess: false,
      );

      _ref.read(analyticsProvider).logEvent(
        name: 'project_download_started',
        parameters: {
          'project_id': apiProject.id,
          'project_name': apiProject.title,
        },
      );

      // Step 1: Check if project already exists locally (10% progress)
      state = state.copyWith(downloadProgress: 0.1);
      final existingProject = await _ref.read(projectRepo).fetchProjectByOrigin(apiProject.id);

      if (existingProject != null) {
        throw Exception('Project "${apiProject.title}" already exists locally');
      }

      // Step 2: Fetch full project data from API (30% progress)
      state = state.copyWith(downloadProgress: 0.3);
      final response = await _ref.read(projectAPIRepoProvider).getProject(
            apiProject.id,
            includeData: true,
          );

      if (!response.success || response.data == null) {
        throw Exception(response.error ?? 'Failed to fetch project data');
      }

      final fullApiProject = response.data!;
      if (fullApiProject.projectData == null || fullApiProject.projectData!.isEmpty) {
        throw Exception('Project data is not available for download');
      }

      // Step 3: Parse project data (50% progress)
      state = state.copyWith(downloadProgress: 0.5);
      late Project projectData;
      try {
        final projectJson = jsonDecode(fullApiProject.projectData!);
        projectData = Project.fromJson(projectJson);
      } catch (e) {
        throw Exception('Invalid project data format: $e');
      }

      // Step 4: Create local project with cloud metadata (70% progress)
      final authState = _ref.read(authProvider);
      final isOwner = authState.isSignedIn && authState.apiUser?.id == fullApiProject.userId;
      state = state.copyWith(downloadProgress: 0.7);
      final localProject = projectData.copyWith(
        id: 0, // Reset ID for local creation
        name: fullApiProject.title,
        isCloudSynced: isOwner,
        // Only an owner's download is "synced" to that server project —
        // otherwise remoteId must be cleared so a later upload creates a new
        // fork instead of attempting to overwrite a project we don't own.
        remoteId: isOwner ? fullApiProject.id : null,
        clearRemoteId: !isOwner,
        // Recorded regardless of ownership so lineage/dedupe survive even
        // after remoteId gets reassigned to a new fork on first upload.
        forkedFromId: fullApiProject.id,
        createdAt: fullApiProject.createdAt ?? DateTime.now(),
        editedAt: fullApiProject.updatedAt ?? DateTime.now(),
      );

      // Step 5: Save to local database (90% progress)
      state = state.copyWith(downloadProgress: 0.9);
      final savedProject = await _ref.read(projectRepo).createProject(localProject);

      // Step 6: Complete (100% progress)
      state = state.copyWith(
        downloadProgress: 1.0,
        isSuccess: true,
        isDownloading: false,
        downloadedProject: savedProject,
      );

      _ref.read(analyticsProvider).logEvent(
        name: 'project_download_success',
        parameters: {
          'project_id': apiProject.id,
          'local_project_id': savedProject.id,
        },
      );
    } catch (e, stackTrace) {
      state = state.copyWith(
        isDownloading: false,
        error: e.toString(),
        downloadProgress: 0.0,
      );

      _ref.read(analyticsProvider).logEvent(
        name: 'project_download_failed',
        parameters: {
          'project_id': apiProject.id,
          'error': e.toString(),
        },
      );

      // Log error for debugging
      debugPrint('Download error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void resetState() {
    state = const ProjectDownloadState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider definition
final projectDownloadProvider = StateNotifierProvider<ProjectDownloadNotifier, ProjectDownloadState>((ref) {
  return ProjectDownloadNotifier(ref);
});
