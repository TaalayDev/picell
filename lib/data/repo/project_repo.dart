import 'dart:async';

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
  Future<void> updateProject(Project project) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      Project projectToSave = project;

      // For tile generator projects, the thumbnail is provided by the caller
      // For pixel art projects, regenerate thumbnail from layers
      if (project.type == ProjectType.pixelArt && project.frames.isNotEmpty && project.frames.first.layers.isNotEmpty) {
        final pixels = PixelUtils.mergeLayersPixels(
          width: project.width,
          height: project.height,
          layers: project.frames.first.layers,
        );
        projectToSave = project.copyWith(thumbnail: ImageHelper.convertToBytes(pixels));
      }

      await db.updateProject(projectToSave);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> renameProject(int projectId, String name) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.renameProject(projectId, name);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> markProjectAsSynced(int projectId, int? remoteProjectId) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.markProjectAsSynced(projectId, remoteProjectId);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> markProjectAsUnsynced(int projectId) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.markProjectAsUnsynced(projectId);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> deleteProject(Project project) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.deleteProject(project.id);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<Layer> createLayer(int projectId, int frameId, Layer layer) async {
    final completer = Completer<Layer>();
    queueManager.add(() async {
      final newLayer = await db.insertLayer(projectId, frameId, layer);
      completer.complete(newLayer);
    });
    return completer.future;
  }

  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.updateLayer(projectId, frameId, layer);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> deleteLayer(int layerId) async {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.deleteLayer(layerId);
      completer.complete();
    });
    return completer.future;
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
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.deleteFrame(frameId);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> updateFrame(int projectId, AnimationFrame frame) {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.updateFrame(projectId, frame);
      completer.complete();
    });
    return completer.future;
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
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.deleteState(stateId);
      completer.complete();
    });
    return completer.future;
  }

  @override
  Future<void> updateState(int projectId, AnimationStateModel state) {
    final completer = Completer<void>();
    queueManager.add(() async {
      await db.updateState(projectId, state);
      completer.complete();
    });
    return completer.future;
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
