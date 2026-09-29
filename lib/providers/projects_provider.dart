import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils.dart';
import '../data.dart';
import '../data/models/progression_model.dart';
import 'progression_provider.dart';
import 'providers.dart';

part 'projects_provider.g.dart';

@riverpod
class Projects extends _$Projects {
  @override
  Stream<List<Project>> build() {
    return ref.read(projectRepo).fetchProjects();
  }

  Future<Project> addProject(Project newProject) async {
    ref.read(analyticsProvider).logEvent(name: 'add_project', parameters: {
      'project_id': newProject.id,
      'project_name': newProject.name,
    });
    ref.read(progressionProvider.notifier).record(ProgressionEvent.projectCreated);

    // Check if the incoming project already has states and frames (e.g., from imported image/aseprite)
    // The insertProject method in the database handles states, frames, and layers automatically
    final hasExistingData = newProject.states.isNotEmpty && newProject.frames.isNotEmpty;

    if (hasExistingData) {
      // Project has existing data (e.g., from dropped image) - insertProject will handle everything
      final project = await ref.read(projectRepo).createProject(newProject);
      ref.read(inAppReviewProvider).incrementProjectCount();
      return project;
    } else {
      // Create empty project first, then add default state and frame
      final project = await ref.read(projectRepo).createProject(newProject);
      final state = await ref.read(projectRepo).createState(
            project.id,
            const AnimationStateModel(
              id: 0,
              name: 'Animation',
              frameRate: 24,
            ),
          );
      final frame = await ref.read(projectRepo).createFrame(
            project.id,
            AnimationFrame(
              id: 0,
              stateId: state.id,
              name: 'Frame 1',
              duration: 100,
              layers: [
                Layer(
                  layerId: 0,
                  id: const Uuid().v4(),
                  name: 'Layer 1',
                  pixels: Uint32List(project.width * project.height),
                  order: 0,
                ),
              ],
            ),
          );

      ref.read(inAppReviewProvider).incrementProjectCount();

      return project.copyWith(
        states: [state],
        frames: [frame],
      );
    }
  }

  /// Loads a full project for the editor, with layer effects already
  /// applied in a background isolate so the editor opens without a freeze.
  Future<Project?> getProject(int projectId) async {
    final project = await ref.read(projectRepo).fetchProject(projectId);
    if (project != null) {
      try {
        await Layer.prepareProcessedPixels(
          project.frames.expand((frame) => frame.layers),
          project.width,
          project.height,
        );
      } catch (e) {
        // The editor still applies effects itself, just on the UI thread.
        debugPrint('Failed to prepare layer effects: $e');
      }
    }
    return project;
  }

  Future<void> renameProject(int projectId, String name) async {
    ref.read(analyticsProvider).logEvent(name: 'rename_project', parameters: {
      'project_id': projectId,
      'project_name': name,
    });

    return ref.read(projectRepo).renameProject(projectId, name);
  }

  Future<void> deleteProject(Project project) async {
    ref.read(analyticsProvider).logEvent(name: 'delete_project', parameters: {
      'project_id': project.id,
      'project_name': project.name,
    });

    return ref.read(projectRepo).deleteProject(project);
  }

  Future<void> markProjectAsSynced(int projectId, int remoteProjectId) async {
    ref.read(analyticsProvider).logEvent(name: 'project_marked_synced', parameters: {
      'project_id': projectId,
      'remote_project_id': remoteProjectId,
    });

    return ref.read(projectRepo).markProjectAsSynced(projectId, remoteProjectId);
  }

  Future<void> markProjectAsUnsynced(int projectId) async {
    ref.read(analyticsProvider).logEvent(name: 'project_marked_unsynced', parameters: {
      'project_id': projectId,
    });

    return ref.read(projectRepo).markProjectAsUnsynced(projectId);
  }

  Future<String?> importProject(BuildContext context) async {
    try {
      final contents = await FileUtils(context).readProjectFileContents();
      if (contents == null) return null;
      final project = Project.fromJson(jsonDecode(contents));

      addProject(project);
      ref.read(progressionProvider.notifier).record(ProgressionEvent.projectImported);
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      return e.toString();
    }
  }
}

final downloadedProjectsProvider = StreamProvider<Set<int>>((ref) {
  return ref.read(projectRepo).fetchProjects().map((projects) {
    // Community project ids that already have a local copy — either an
    // owned sync (remoteId) or a downloaded/forked copy (forkedFromId).
    return projects
        .expand((project) => [
              if (project.isCloudSynced && project.remoteId != null) project.remoteId!,
              if (project.forkedFromId != null) project.forkedFromId!,
            ])
        .toSet();
  });
});

final isProjectDownloadedProvider = Provider.family<bool, int>((ref, remoteId) {
  final downloadedProjects = ref.watch(downloadedProjectsProvider);
  return downloadedProjects.when(
    data: (downloadedIds) => downloadedIds.contains(remoteId),
    loading: () => false,
    error: (_, __) => false,
  );
});

final localProjectByRemoteIdProvider = Provider.family<Project?, int>((ref, remoteId) {
  final projects = ref.read(projectsProvider);
  return projects.when(
    data: (projectsList) => projectsList
        .where((project) => (project.isCloudSynced && project.remoteId == remoteId) || project.forkedFromId == remoteId)
        .firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );
});
