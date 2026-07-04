import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils.dart';
import '../../data.dart';

abstract class ProjectRepo {
  Stream<List<Project>> fetchProjects();
  Future<Project?> fetchProject(int projectId);
  Future<Project?> fetchProjectByRemoteId(int remoteId);
  Future<Project> createProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> renameProject(int projectId, String name);
  Future<void> deleteProject(Project project);
  Future<void> markProjectAsSynced(int projectId, int? remoteProjectId);
  Future<void> markProjectAsUnsynced(int projectId);
  Future<AnimationStateModel> createState(
    int projectId,
    AnimationStateModel state,
  );
  Future<void> updateState(int projectId, AnimationStateModel state);
  Future<void> deleteState(int stateId);
  Future<AnimationFrame> createFrame(int projectId, AnimationFrame frame);
  Future<void> updateFrame(int projectId, AnimationFrame frame);
  Future<void> deleteFrame(int frameId);
  Future<Layer> createLayer(int projectId, int frameId, Layer layer);
  Future<void> updateLayer(int projectId, int frameId, Layer layer);
  Future<void> deleteLayer(int layerId);
}

/// Merges the first frame's layers and converts them to raw RGBA bytes.
/// Top-level so it can run in a background isolate via [compute].
Uint8List _generateProjectThumbnail(
  ({int width, int height, List<Layer> layers}) args,
) {
  final pixels = PixelUtils.mergeLayersPixels(
    width: args.width,
    height: args.height,
    layers: args.layers,
  );
  return ImageHelper.convertToBytes(pixels);
}

class ProjectLocalRepo extends ProjectRepo {
  final AppDatabase db;
  final QueueManager queueManager;

  ProjectLocalRepo(this.db, this.queueManager);

  @override
  Stream<List<Project>> fetchProjects() => db.getAllProjects();
  @override
  Future<Project?> fetchProject(int projectId) => db.getProject(projectId);
  @override
  Future<Project> createProject(Project project) => db.insertProject(project);
  @override
  Future<void> updateProject(Project project) {
    // Latest-wins: a burst of saves for the same project collapses into one
    // pending queue entry instead of stacking thumbnail + DB work.
    return queueManager.addCoalesced('updateProject:${project.id}', () async {
      Project projectToSave = project;

      // For tile generator projects, the thumbnail is provided by the caller
      // For pixel art projects, regenerate thumbnail from layers
      if (project.type == ProjectType.pixelArt && project.frames.isNotEmpty && project.frames.first.layers.isNotEmpty) {
        final thumbnail = await compute(_generateProjectThumbnail, (
          width: project.width,
          height: project.height,
          layers: project.frames.first.layers,
        ));
        projectToSave = project.copyWith(thumbnail: thumbnail);
      }

      await db.updateProject(projectToSave);
    });
  }

  @override
  Future<void> renameProject(int projectId, String name) {
    return queueManager.add(() => db.renameProject(projectId, name));
  }

  @override
  Future<void> markProjectAsSynced(int projectId, int? remoteProjectId) {
    return queueManager.add(() => db.markProjectAsSynced(projectId, remoteProjectId));
  }

  @override
  Future<void> markProjectAsUnsynced(int projectId) {
    return queueManager.add(() => db.markProjectAsUnsynced(projectId));
  }

  @override
  Future<void> deleteProject(Project project) {
    return queueManager.add(() => db.deleteProject(project.id));
  }

  @override
  Future<Layer> createLayer(int projectId, int frameId, Layer layer) {
    final completer = Completer<Layer>();
    queueManager.add(() async {
      final newLayer = await db.insertLayer(projectId, frameId, layer);
      completer.complete(newLayer);
    });
    return completer.future;
  }

  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) {
    // Latest-wins per layer: consecutive stroke saves overwrite the same row.
    return queueManager.addCoalesced(
      'updateLayer:$projectId:$frameId:${layer.layerId}',
      () => db.updateLayer(projectId, frameId, layer),
    );
  }

  @override
  Future<void> deleteLayer(int layerId) {
    return queueManager.add(() => db.deleteLayer(layerId));
  }

  @override
  Future<AnimationFrame> createFrame(int projectId, AnimationFrame frame) {
    final completer = Completer<AnimationFrame>();
    queueManager.add(() async {
      final newFrame = await db.insertFrame(projectId, frame);
      completer.complete(newFrame);
    });
    return completer.future;
  }

  @override
  Future<void> deleteFrame(int frameId) {
    return queueManager.add(() => db.deleteFrame(frameId));
  }

  @override
  Future<void> updateFrame(int projectId, AnimationFrame frame) {
    return queueManager.add(() => db.updateFrame(projectId, frame));
  }

  @override
  Future<AnimationStateModel> createState(
    int projectId,
    AnimationStateModel state,
  ) {
    final completer = Completer<AnimationStateModel>();
    queueManager.add(() async {
      final newState = await db.insertState(projectId, state);
      completer.complete(newState);
    });
    return completer.future;
  }

  @override
  Future<void> deleteState(int stateId) {
    return queueManager.add(() => db.deleteState(stateId));
  }

  @override
  Future<void> updateState(int projectId, AnimationStateModel state) {
    return queueManager.add(() => db.updateState(projectId, state));
  }

  @override
  Future<Project?> fetchProjectByRemoteId(int remoteId) {
    final completer = Completer<Project?>();
    queueManager.add(() async {
      try {
        final project = await db.getProjectByRemoteId(remoteId);
        completer.complete(project);
      } catch (e) {
        completer.complete(null);
      }
    });
    return completer.future;
  }
}
