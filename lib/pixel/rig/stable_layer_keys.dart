import '../../data.dart';

/// Gives layers a `Layer.stableKey` so a rig can follow "the same layer"
/// across the frames of an animation state.
///
/// Frame duplication regenerates `Layer.id`, so before a rig exists nothing
/// links a layer to its copies. Duplicates made *after* keys are assigned
/// keep them (`Layer.copyWith` preserves the key).
///
/// Keys are derived, not random: by default a layer's key is the id of the
/// layer at the same position in the first frame that needs keys. Undoing in
/// the editor can restore frames from before keys were stamped; stamping
/// again then reproduces the same keys, so rig parts keep pointing at the
/// right layers.
class StableLayerKeys {
  const StableLayerKeys._();

  /// Returns [frames] with every layer keyed. Layers that already have a key
  /// are left alone; the rest are keyed by position, i.e. the layer at index
  /// `n` of each frame shares one key, taken from [keyFor] applied to the
  /// first such layer (default: its `id`). Only the frames in [stateId]
  /// change.
  ///
  /// Frames not in [stateId] and frames needing no change are returned as the
  /// same instances, so callers can use [identical] to skip writes.
  static List<AnimationFrame> ensure(List<AnimationFrame> frames, int stateId, {String Function(Layer firstSeen)? keyFor}) {
    final makeKey = keyFor ?? (Layer layer) => layer.id;
    final byPosition = <int, String>{};

    return [
      for (final frame in frames)
        if (frame.stateId != stateId || frame.layers.every((l) => l.stableKey != null))
          frame
        else
          frame.copyWith(layers: [
            for (final (index, layer) in frame.layers.indexed)
              layer.stableKey != null ? layer : layer.copyWith(stableKey: byPosition.putIfAbsent(index, () => makeKey(layer))),
          ]),
    ];
  }

  /// The layer of [frame] bound to [key], or null if that frame lacks it.
  static Layer? find(AnimationFrame frame, String key) {
    for (final layer in frame.layers) {
      if (layer.stableKey == key) return layer;
    }
    return null;
  }
}
