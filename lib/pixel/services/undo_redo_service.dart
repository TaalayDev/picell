import 'dart:typed_data';

import '../../data/models/animation_frame_model.dart';
import '../../data/models/layer.dart';
import '../../data/models/selection_state.dart';
import '../pixel_canvas_state.dart';

/// The small navigation/selection fields restored alongside a pixel diff.
class UndoMeta {
  final int animationStateIndex;
  final int frameIndex;
  final int layerIndex;
  final SelectionState? selectionState;

  UndoMeta.fromState(PixelCanvasState s)
      : animationStateIndex = s.currentAnimationStateIndex,
        frameIndex = s.currentFrameIndex,
        layerIndex = s.currentLayerIndex,
        selectionState = s.selectionState;
}

sealed class UndoEntry {
  int get sizeInBytes;
}

/// Full shallow snapshot — used for structural operations (layer/frame
/// add/remove/reorder, resize, import, selection transforms) which are rare.
///
/// NOTE: `PixelCanvasState.copyWith()` is a SHALLOW copy. Snapshots alias the
/// live pixel buffers, so undo correctness relies on the copy-on-write
/// discipline of all drawing operations: a `Uint32List` reachable from a
/// state that has been passed to [UndoRedoService.saveState] must never be
/// mutated in place.
class FullStateEntry extends UndoEntry {
  final PixelCanvasState state;
  FullStateEntry(this.state);

  // Approximation: a snapshot uniquely retains about one layer buffer (the
  // one replaced by the operation that follows it); everything else is
  // shared with the live state.
  @override
  int get sizeInBytes => state.width * state.height * 4;
}

/// Compact record of a drawing operation on a single layer. Stores only the
/// changed cells — or the full before/after buffers when most of the layer
/// changed — keeping deep undo histories orders of magnitude cheaper than
/// full snapshots.
class PixelDiffEntry extends UndoEntry {
  final int frameId;
  final int absoluteFrameIndex;
  final String layerUuid;
  final int pixelCount;

  /// Changed cell indices, or null when [oldValues]/[newValues] hold full
  /// buffers (large-change fallback, e.g. flood fill of the whole canvas).
  final Uint32List? indices;
  final Uint32List oldValues;
  final Uint32List newValues;

  /// Restored on undo — captured when the operation ran.
  final UndoMeta preMeta;

  /// Restored on redo — captured at undo time, mirroring the previous
  /// full-snapshot semantics (redo returns to the state as of the undo).
  UndoMeta? redoMeta;

  PixelDiffEntry({
    required this.frameId,
    required this.absoluteFrameIndex,
    required this.layerUuid,
    required this.pixelCount,
    required this.indices,
    required this.oldValues,
    required this.newValues,
    required this.preMeta,
  });

  @override
  int get sizeInBytes => indices != null ? indices!.length * 12 + 64 : oldValues.length * 8 + 64;

  int _resolveFrameIndex(PixelCanvasState s) {
    if (frameId != 0) {
      final byId = s.frames.indexWhere((f) => f.id == frameId);
      if (byId != -1) return byId;
    }
    return absoluteFrameIndex < s.frames.length ? absoluteFrameIndex : -1;
  }

  /// Applies the diff to [s] and returns the resulting state. `forward: true`
  /// re-applies the operation (redo); `forward: false` reverts it (undo).
  /// Returns [s] unchanged if the target frame/layer no longer exists.
  PixelCanvasState apply(PixelCanvasState s, {required bool forward}) {
    final frameIndex = _resolveFrameIndex(s);
    if (frameIndex == -1) return s;
    final frame = s.frames[frameIndex];
    final layerIndex = frame.layers.indexWhere((l) => l.id == layerUuid);
    if (layerIndex == -1) return s;
    final layer = frame.layers[layerIndex];
    if (layer.pixels.length != pixelCount) return s;

    final values = forward ? newValues : oldValues;
    final Uint32List pixels;
    if (indices == null) {
      // Full-buffer variant: the stored buffer is immutable by invariant and
      // can be shared directly.
      pixels = values;
    } else {
      pixels = Uint32List.fromList(layer.pixels);
      final idx = indices!;
      for (var i = 0; i < idx.length; i++) {
        pixels[idx[i]] = values[i];
      }
    }

    final layers = List<Layer>.from(frame.layers);
    layers[layerIndex] = layer.copyWith(pixels: pixels);
    final frames = List<AnimationFrame>.from(s.frames);
    frames[frameIndex] = frame.copyWith(layers: layers);

    final meta = forward ? (redoMeta ?? preMeta) : preMeta;
    return _restoreMeta(s.copyWith(frames: frames), meta);
  }

  PixelCanvasState _restoreMeta(PixelCanvasState s, UndoMeta meta) {
    // Only restore navigation indices when they are still valid; structural
    // changes are guarded by their own full-snapshot entries, so an invalid
    // meta means something drifted — leave the current indices untouched.
    if (meta.animationStateIndex >= s.animationStates.length) return s;
    final stateId = s.animationStates[meta.animationStateIndex].id;
    final filtered = s.frames.where((f) => f.stateId == stateId).toList();
    if (meta.frameIndex >= filtered.length) return s;
    if (meta.layerIndex >= filtered[meta.frameIndex].layers.length) return s;
    return s.copyWith(
      currentAnimationStateIndex: meta.animationStateIndex,
      currentFrameIndex: meta.frameIndex,
      currentLayerIndex: meta.layerIndex,
      selectionState: meta.selectionState,
    );
  }
}

class UndoRedoService {
  /// Byte budget for retained undo history. Diff entries make typical
  /// strokes a few KB, so this allows hundreds of steps even on large
  /// canvases while bounding worst-case memory.
  static const int _maxUndoBytes = 64 * 1024 * 1024;
  static const int _maxUndoEntries = 200;

  final List<UndoEntry> _undoStack = [];
  final List<UndoEntry> _redoStack = [];
  int _undoBytes = 0;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _push(UndoEntry entry) {
    _undoStack.add(entry);
    _undoBytes += entry.sizeInBytes;

    while (_undoStack.length > 1 && (_undoBytes > _maxUndoBytes || _undoStack.length > _maxUndoEntries)) {
      _undoBytes -= _undoStack.removeAt(0).sizeInBytes;
    }

    // Clear redo stack when new state is saved
    _redoStack.clear();
  }

  void saveState(PixelCanvasState state) {
    _push(FullStateEntry(state.copyWith()));
  }

  /// Records a drawing operation as a compact pixel diff between
  /// [prePixels] and [postPixels] on the layer that was current in
  /// [preState]. No-op strokes (no changed pixels) record nothing.
  void savePixelDiff({
    required PixelCanvasState preState,
    required Uint32List prePixels,
    required Uint32List postPixels,
  }) {
    if (prePixels.length != postPixels.length) {
      // Unexpected shape change — fall back to a full snapshot.
      saveState(preState);
      return;
    }

    var changed = 0;
    for (var i = 0; i < prePixels.length; i++) {
      if (prePixels[i] != postPixels[i]) changed++;
    }
    if (changed == 0) return;

    final frame = preState.currentFrame;
    final layer = preState.currentLayer;
    final meta = UndoMeta.fromState(preState);
    final absoluteFrameIndex = preState.frames.indexOf(frame);

    final PixelDiffEntry entry;
    if (changed * 3 >= prePixels.length) {
      // Most of the layer changed — index arrays would cost more than the
      // buffers themselves. Keep the before/after buffer references (both
      // immutable by invariant).
      entry = PixelDiffEntry(
        frameId: frame.id,
        absoluteFrameIndex: absoluteFrameIndex,
        layerUuid: layer.id,
        pixelCount: prePixels.length,
        indices: null,
        oldValues: prePixels,
        newValues: postPixels,
        preMeta: meta,
      );
    } else {
      final indices = Uint32List(changed);
      final oldValues = Uint32List(changed);
      final newValues = Uint32List(changed);
      var n = 0;
      for (var i = 0; i < prePixels.length; i++) {
        if (prePixels[i] != postPixels[i]) {
          indices[n] = i;
          oldValues[n] = prePixels[i];
          newValues[n] = postPixels[i];
          n++;
        }
      }
      entry = PixelDiffEntry(
        frameId: frame.id,
        absoluteFrameIndex: absoluteFrameIndex,
        layerUuid: layer.id,
        pixelCount: prePixels.length,
        indices: indices,
        oldValues: oldValues,
        newValues: newValues,
        preMeta: meta,
      );
    }
    _push(entry);
  }

  PixelCanvasState? undo(PixelCanvasState currentState) {
    if (!canUndo) return null;

    final entry = _undoStack.removeLast();
    _undoBytes -= entry.sizeInBytes;

    switch (entry) {
      case FullStateEntry(:final state):
        _redoStack.add(FullStateEntry(currentState.copyWith()));
        return state.copyWith(canUndo: canUndo, canRedo: canRedo);
      case PixelDiffEntry():
        entry.redoMeta = UndoMeta.fromState(currentState);
        _redoStack.add(entry);
        return entry.apply(currentState, forward: false).copyWith(canUndo: canUndo, canRedo: canRedo);
    }
  }

  PixelCanvasState? redo(PixelCanvasState currentState) {
    if (!canRedo) return null;

    final entry = _redoStack.removeLast();

    switch (entry) {
      case FullStateEntry(:final state):
        final snapshot = FullStateEntry(currentState.copyWith());
        _undoStack.add(snapshot);
        _undoBytes += snapshot.sizeInBytes;
        return state.copyWith(canUndo: canUndo, canRedo: canRedo);
      case PixelDiffEntry():
        _undoStack.add(entry);
        _undoBytes += entry.sizeInBytes;
        return entry.apply(currentState, forward: true).copyWith(canUndo: canUndo, canRedo: canRedo);
    }
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _undoBytes = 0;
  }

  /// Discards the most recently saved undo entry without restoring it.
  /// Used to cancel a drawing that was started but never produced changes.
  void discardLastSavedState() {
    if (_undoStack.isNotEmpty) {
      _undoBytes -= _undoStack.removeLast().sizeInBytes;
    }
  }

  int get undoStackSize => _undoStack.length;
  int get redoStackSize => _redoStack.length;

  // For debugging purposes
  List<String> getUndoStackSummary() => _undoStack.map(_describeEntry).toList();

  List<String> getRedoStackSummary() => _redoStack.map(_describeEntry).toList();

  String _describeEntry(UndoEntry entry) {
    return switch (entry) {
      FullStateEntry(:final state) => 'Full — Frame: ${state.currentFrameIndex}, Layer: ${state.currentLayerIndex}',
      PixelDiffEntry() =>
        'Diff — Frame id: ${entry.frameId}, Layer: ${entry.layerUuid}, changed: ${entry.oldValues.length}',
    };
  }
}
