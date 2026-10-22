import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';

/// Stores nothing; assigns ids and records what was written.
class FakeProjectRepo extends Fake implements ProjectRepo {
  /// Makes [createState] fail, to exercise error paths.
  Object? failCreateState;
  final updatedProjects = <Project>[];

  var _nextId = 100;
  final createdStates = <AnimationStateModel>[];
  final updatedStates = <AnimationStateModel>[];
  final createdFrames = <AnimationFrame>[];
  final updatedFrames = <AnimationFrame>[];
  final deletedFrames = <int>[];
  final createdLayers = <Layer>[];

  @override
  Future<AnimationStateModel> createState(int projectId, AnimationStateModel state) async {
    if (failCreateState != null) throw failCreateState!;
    final created = state.copyWith(id: _nextId++);
    createdStates.add(created);
    return created;
  }

  @override
  Future<void> updateProject(Project project) async => updatedProjects.add(project);

  @override
  Future<void> updateProjectSelection(int projectId, {required int frameId, required int layerId}) async {}

  @override
  Future<void> updateState(int projectId, AnimationStateModel state) async => updatedStates.add(state);

  @override
  Future<AnimationFrame> createFrame(int projectId, AnimationFrame frame) async {
    final id = _nextId++;
    final layers = [for (final l in frame.layers) l.copyWith(layerId: _nextId++)];
    final created = frame.copyWith(id: id, layers: layers);
    createdFrames.add(created);
    return created;
  }

  @override
  Future<void> updateFrame(int projectId, AnimationFrame frame) async => updatedFrames.add(frame);

  @override
  Future<void> deleteFrame(int frameId) async => deletedFrames.add(frameId);

  @override
  Future<Layer> createLayer(int projectId, int frameId, Layer layer) async {
    final created = layer.copyWith(layerId: _nextId++);
    createdLayers.add(created);
    return created;
  }
}
