import '../../data.dart';

typedef EditorSelectionIndices = ({
  int stateIndex,
  int frameIndex,
  int layerIndex,
});

/// Resolves persisted database IDs into the indices used by the editor.
/// Missing or deleted entities safely fall back to the first available item.
EditorSelectionIndices restoreEditorSelection(
  Project project,
  List<AnimationStateModel> animationStates,
  List<AnimationFrame> frames,
) {
  final selectedFrameIndex = project.selectedFrameId == null
      ? -1
      : frames.indexWhere((frame) => frame.id == project.selectedFrameId);
  if (selectedFrameIndex < 0) {
    return (stateIndex: 0, frameIndex: 0, layerIndex: 0);
  }

  final selectedFrame = frames[selectedFrameIndex];
  final stateIndex = animationStates.indexWhere(
    (animationState) => animationState.id == selectedFrame.stateId,
  );
  if (stateIndex < 0) {
    return (stateIndex: 0, frameIndex: 0, layerIndex: 0);
  }

  final stateFrames =
      frames.where((frame) => frame.stateId == selectedFrame.stateId).toList();
  final frameIndex = stateFrames.indexWhere(
    (frame) => frame.id == selectedFrame.id,
  );
  var layerIndex = 0;
  if (selectedFrame.layers.isNotEmpty && project.selectedLayerId != null) {
    final storedLayerIndex = selectedFrame.layers.indexWhere(
      (layer) => layer.layerId == project.selectedLayerId,
    );
    if (storedLayerIndex >= 0) layerIndex = storedLayerIndex;
  }

  return (
    stateIndex: stateIndex,
    frameIndex: frameIndex < 0 ? 0 : frameIndex,
    layerIndex: layerIndex,
  );
}
