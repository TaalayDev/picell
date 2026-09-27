import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/pixel/services/editor_selection_service.dart';

void main() {
  Layer layer(int id) => Layer(
        layerId: id,
        id: 'layer-$id',
        name: 'Layer $id',
        pixels: Uint32List(4),
      );

  AnimationFrame frame(int id, int stateId, List<Layer> layers) =>
      AnimationFrame(
        id: id,
        stateId: stateId,
        name: 'Frame $id',
        duration: 100,
        layers: layers,
      );

  Project project({int? frameId, int? layerId}) => Project(
        id: 1,
        name: 'Project',
        width: 2,
        height: 2,
        createdAt: DateTime(2026),
        editedAt: DateTime(2026),
        selectedFrameId: frameId,
        selectedLayerId: layerId,
      );

  const states = [
    AnimationStateModel(id: 10, name: 'Idle', frameRate: 12),
    AnimationStateModel(id: 20, name: 'Run', frameRate: 12),
  ];

  final frames = [
    frame(101, 10, [layer(1001)]),
    frame(102, 10, [layer(1002)]),
    frame(201, 20, [layer(2001), layer(2002)]),
    frame(202, 20, [layer(2003), layer(2004)]),
  ];

  test('restores frame and layer by database IDs across animation states', () {
    final result = restoreEditorSelection(
      project(frameId: 202, layerId: 2004),
      states,
      frames,
    );

    expect(result.stateIndex, 1);
    expect(result.frameIndex, 1);
    expect(result.layerIndex, 1);
  });

  test('falls back safely when persisted IDs were deleted', () {
    final result = restoreEditorSelection(
      project(frameId: 999, layerId: 9999),
      states,
      frames,
    );

    expect(result, (stateIndex: 0, frameIndex: 0, layerIndex: 0));
  });

  test('keeps the frame and falls back to its first layer', () {
    final result = restoreEditorSelection(
      project(frameId: 201, layerId: 9999),
      states,
      frames,
    );

    expect(result.stateIndex, 1);
    expect(result.frameIndex, 0);
    expect(result.layerIndex, 0);
  });

  test('project JSON preserves the selected database IDs', () {
    final source = Project(
      id: 1,
      name: 'Project',
      width: 2,
      height: 2,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
      states: states,
      frames: frames,
      selectedFrameId: 202,
      selectedLayerId: 2004,
    );

    final restored = Project.fromJson(source.toJson());

    expect(restored.selectedFrameId, 202);
    expect(restored.selectedLayerId, 2004);
  });
}
