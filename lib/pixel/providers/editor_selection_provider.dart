import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../pixel_canvas_state.dart';

/// The editor area the user worked in last. Context-aware actions (delete,
/// duplicate) act on that area's selection.
enum EditorSelectionTarget { canvas, layers, frames }

/// Timeline multi-selection plus the last-used editor area.
///
/// [frameIds] is stored raw and may hold stale ids (deleted frames, frames of
/// another animation); read it through [resolveFrames], which always yields a
/// valid selection containing the active frame.
@immutable
class EditorSelection {
  const EditorSelection({
    this.frameIds = const {},
    this.frameAnchorId,
    this.target = EditorSelectionTarget.canvas,
  });

  final Set<int> frameIds;

  /// Where a Shift-click range starts.
  final int? frameAnchorId;
  final EditorSelectionTarget target;

  /// The selected frames of the current animation. Falls back to only the
  /// active frame when the stored selection doesn't contain it.
  Set<int> resolveFrames(PixelCanvasState state) {
    final active = state.currentFrame.id;
    if (!frameIds.contains(active)) return {active};
    final stateId = state.currentAnimationState.id;
    return {
      for (final frame in state.frames)
        if (frame.stateId == stateId && frameIds.contains(frame.id)) frame.id,
    };
  }

  EditorSelection copyWith({
    Set<int>? frameIds,
    int? Function()? frameAnchorId,
    EditorSelectionTarget? target,
  }) {
    return EditorSelection(
      frameIds: frameIds ?? this.frameIds,
      frameAnchorId: frameAnchorId != null ? frameAnchorId() : this.frameAnchorId,
      target: target ?? this.target,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EditorSelection &&
      setEquals(other.frameIds, frameIds) &&
      other.frameAnchorId == frameAnchorId &&
      other.target == target;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(frameIds), frameAnchorId, target);
}

/// Per-project [EditorSelection]. Written only by the pixel draw controller,
/// which keeps it alive while the project is open.
final editorSelectionProvider =
    NotifierProvider.autoDispose.family<EditorSelectionNotifier, EditorSelection, int>(EditorSelectionNotifier.new);

class EditorSelectionNotifier extends AutoDisposeFamilyNotifier<EditorSelection, int> {
  @override
  EditorSelection build(int projectId) => const EditorSelection();

  void modify(EditorSelection Function(EditorSelection current) change) {
    final next = change(state);
    if (next != state) state = next;
  }
}
