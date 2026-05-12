import 'dart:convert';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;

import '../data/models/api_models.dart';
import '../data/models/project_api_models.dart';
import '../data.dart';
import '../core/utils.dart';
import '../providers/providers.dart';

part 'project_upload_provider.freezed.dart';
part 'project_upload_provider.g.dart';

@freezed
class ProjectUploadState with _$ProjectUploadState {
  const factory ProjectUploadState({
    @Default(false) bool isUploading,
    @Default(0.0) double uploadProgress,
    String? error,
    ApiProject? uploadedProject,
    @Default(false) bool isSuccess,
    @Default(false) bool isUpdating,
    // Background silent sync (no UI modal)
    @Default(false) bool isSilentSyncing,
    int? lastSyncedRemoteId,
  }) = _ProjectUploadState;
}

@riverpod
class ProjectUpload extends _$ProjectUpload {
  @override
  ProjectUploadState build() {
    return const ProjectUploadState();
  }

  Future<void> uploadProject({
    required Project localProject,
    required String title,
    String? description,
    required bool isPublic,
    required List<String> tags,
  }) async {
    try {
      final isUpdate = localProject.isCloudSynced && localProject.remoteId != null;

      state = state.copyWith(
        isUploading: true,
        uploadProgress: 0.0,
        isUpdating: isUpdate,
        error: null,
        isSuccess: false,
      );

      ref.read(analyticsProvider).logEvent(
        name: 'project_upload_started',
        parameters: {
          'project_name': title,
          'is_public': isPublic.toString(),
          'tags_count': tags.length,
        },
      );

      // Step 1: Generate project data JSON (10% progress)
      state = state.copyWith(uploadProgress: 0.1);
      final projectData = jsonEncode(localProject.toJson());

      // Step 2: Generate thumbnail (30% progress)
      state = state.copyWith(uploadProgress: 0.3);
      final thumbnailBytes = await _generateThumbnail(localProject);

      // Step 3: Upload to API (70% progress)
      state = state.copyWith(uploadProgress: 0.7);
      ApiResponse<ApiProject> response;
      if (isUpdate) {
        response = await ref.read(projectAPIRepoProvider).updateProject(
              projectId: localProject.remoteId!,
              title: title,
              description: description,
              projectData: projectData,
              isPublic: isPublic,
              tags: tags,
              thumbnailBytes: thumbnailBytes,
            );
      } else {
        response = await ref.read(projectAPIRepoProvider).createProject(
              title: title,
              description: description ?? '',
              width: localProject.width,
              height: localProject.height,
              projectData: projectData,
              isPublic: isPublic,
              tags: tags,
              thumbnailBytes: thumbnailBytes,
            );
      }

      if (response.success && response.data != null) {
        state = state.copyWith(uploadProgress: 0.9);
        if (!isUpdate) {
          await ref.read(projectRepo).markProjectAsSynced(localProject.id, response.data!.id);
        }

        state = state.copyWith(
          uploadProgress: 1.0,
          isSuccess: true,
          isUploading: false,
          uploadedProject: response.data,
        );

        ref.read(analyticsProvider).logEvent(
          name: isUpdate ? 'project_update_success' : 'project_upload_success',
          parameters: {
            'project_id': response.data?.id.toString() ?? '',
            'project_name': title,
            'is_update': isUpdate.toString(),
          },
        );
      } else {
        throw Exception(response.error ?? 'Upload failed');
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
        uploadProgress: 0.0,
      );

      ref.read(analyticsProvider).logEvent(
        name: 'project_upload_failed',
        parameters: {
          'error': e.toString(),
          'project_name': title,
        },
      );
    }
  }

  Future<void> updateProject({
    required Project localProject,
    String? title,
    String? description,
    bool? isPublic,
    List<String>? tags,
  }) async {
    if (!localProject.isCloudSynced || localProject.remoteId == null) {
      throw Exception('Project is not synced to cloud');
    }

    state = state.copyWith(
      isUpdating: true,
      error: null,
      isSuccess: false,
    );

    final response = await ref.read(projectAPIRepoProvider).updateProject(
          projectId: localProject.remoteId!,
          title: title,
          description: description,
          projectData: jsonEncode(localProject.toJson()),
          isPublic: isPublic,
          tags: tags,
          thumbnailBytes: localProject.thumbnail,
        );

    if (response.success && response.data != null) {
      state = state.copyWith(
        isUpdating: false,
        isSuccess: true,
        uploadedProject: response.data,
      );

      ref.read(analyticsProvider).logEvent(
        name: 'project_update_success',
        parameters: {
          'project_id': response.data!.id.toString(),
          'project_name': title ?? localProject.name,
        },
      );
    } else {
      throw Exception(response.error ?? 'Failed to update project');
    }
  }

  Future<void> deleteCloudProject({
    required Project localProject,
  }) async {
    if (!localProject.isCloudSynced || localProject.remoteId == null) {
      throw Exception('Project is not synced to cloud');
    }

    try {
      state = state.copyWith(
        isUploading: true,
        error: null,
      );

      ref.read(analyticsProvider).logEvent(
        name: 'project_cloud_delete_started',
        parameters: {
          'project_id': localProject.remoteId.toString(),
          'project_name': localProject.name,
        },
      );

      // Delete from cloud
      final response = await ref.read(projectAPIRepoProvider).deleteProject(
            localProject.remoteId!,
          );

      if (response.success) {
        // Mark local project as unsynced
        await ref.read(projectRepo).markProjectAsUnsynced(localProject.id);

        state = state.copyWith(
          isUploading: false,
          isSuccess: true,
        );

        ref.read(analyticsProvider).logEvent(
          name: 'project_cloud_delete_success',
          parameters: {
            'project_id': localProject.remoteId.toString(),
          },
        );
      } else {
        throw Exception(response.error ?? 'Failed to delete cloud project');
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );

      ref.read(analyticsProvider).logEvent(
        name: 'project_cloud_delete_failed',
        parameters: {
          'error': e.toString(),
          'project_id': localProject.remoteId?.toString() ?? 'unknown',
        },
      );
      rethrow;
    }
  }

  Future<Uint8List> _generateThumbnail(Project project) async {
    // Get the merged pixels from all visible layers
    final pixels = ImageHelper.fixColorChannels(PixelUtils.mergeLayersPixels(
      width: project.width,
      height: project.height,
      layers: project.frames.first.layers,
    ));

    // Convert to PNG bytes
    final img.Image image = img.Image.fromBytes(
      width: project.width,
      height: project.height,
      bytes: pixels.buffer,
      numChannels: 4,
    );

    // Resize to thumbnail size (max 256x256) while maintaining aspect ratio
    const maxSize = 256;
    final aspectRatio = project.width / project.height;
    int thumbnailWidth, thumbnailHeight;

    if (aspectRatio > 1) {
      thumbnailWidth = maxSize;
      thumbnailHeight = (maxSize / aspectRatio).round();
    } else {
      thumbnailHeight = maxSize;
      thumbnailWidth = (maxSize * aspectRatio).round();
    }

    final thumbnail = img.copyResize(
      image,
      width: thumbnailWidth,
      height: thumbnailHeight,
      interpolation: img.Interpolation.nearest, // Maintain pixel art look
    );

    return Uint8List.fromList(img.encodePng(thumbnail));
  }

  /// Silent background resync — called automatically when a cloud-synced project
  /// is saved locally. Does not show any upload UI; just pushes the latest data.
  Future<void> silentSyncProject({required Project localProject}) async {
    if (!localProject.isCloudSynced || localProject.remoteId == null) return;
    if (state.isUploading || state.isSilentSyncing) return;

    try {
      state = state.copyWith(isSilentSyncing: true, error: null);

      final projectData = jsonEncode(localProject.toJson());
      final thumbnailBytes = await _generateThumbnail(localProject);

      final response = await ref.read(projectAPIRepoProvider).updateProject(
        projectId: localProject.remoteId!,
        projectData: projectData,
        thumbnailBytes: thumbnailBytes,
      );

      if (response.success) {
        state = state.copyWith(
          isSilentSyncing: false,
          lastSyncedRemoteId: localProject.remoteId,
        );

        ref.read(analyticsProvider).logEvent(
          name: 'project_silent_sync_success',
          parameters: {'project_id': localProject.remoteId.toString()},
        );
      } else {
        state = state.copyWith(isSilentSyncing: false);
      }
    } catch (_) {
      state = state.copyWith(isSilentSyncing: false);
    }
  }

  /// Toggle cloud visibility for an already-uploaded project without re-uploading data.
  Future<void> toggleCloudVisibility({
    required Project localProject,
    required bool isPublic,
  }) async {
    if (!localProject.isCloudSynced || localProject.remoteId == null) return;

    try {
      state = state.copyWith(isUpdating: true, error: null);

      final response = await ref.read(projectAPIRepoProvider).updateProject(
        projectId: localProject.remoteId!,
        isPublic: isPublic,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          isUpdating: false,
          isSuccess: true,
          uploadedProject: response.data,
        );
        ref.read(analyticsProvider).logEvent(
          name: 'project_visibility_changed',
          parameters: {
            'project_id': localProject.remoteId.toString(),
            'is_public': isPublic.toString(),
          },
        );
      } else {
        throw Exception(response.error ?? 'Failed to update visibility');
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  void resetState() {
    state = const ProjectUploadState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

@riverpod
class PopularProjectTags extends _$PopularProjectTags {
  @override
  Future<List<ApiTag>> build() async {
    final response = await ref.read(projectAPIRepoProvider).getPopularTags(limit: 50);
    if (response.success && response.data != null) {
      return response.data!;
    }
    return [];
  }

  Future<List<ApiTag>> searchTags(String query) async {
    if (query.isEmpty) {
      return state.valueOrNull ?? [];
    }

    final response = await ref.read(projectAPIRepoProvider).searchTags(query);
    if (response.success && response.data != null) {
      return response.data!;
    }
    return [];
  }
}
