import 'dart:typed_data';

import '../../data/models/rig/rig.dart';

/// Edits which bone owns which pixels of a layer, so one layer can be split
/// across several bones. Pure: returns new part lists and masks, never
/// modifies its inputs (undo snapshots may alias them).
abstract final class RigInfluencePaint {
  /// Gives the canvas pixels [pixels] (indices into a `width * height` grid)
  /// of [layerKey] to [boneId], taking them from whichever bone owned them.
  /// A null [boneId] erases: the pixels end up owned by nobody and stay still.
  ///
  /// A part without a mask owns the whole layer, so it is turned into an
  /// explicit mask first. Parts left with no pixels are dropped, and a part
  /// that owns everything goes back to having no mask. Part order, ids and
  /// draw order of untouched parts are kept; [drawOrder] and [newId] are used
  /// only when [boneId] gets its first part on this layer.
  static List<RigPart> paint(
    List<RigPart> parts, {
    required String layerKey,
    required String? boneId,
    required Iterable<int> pixels,
    required int width,
    required int height,
    required int drawOrder,
    required String Function() newId,
  }) {
    final size = width * height;
    final targets = [
      for (final p in pixels)
        if (p >= 0 && p < size) p,
    ];
    if (targets.isEmpty) return parts;

    final out = <RigPart>[];
    RigPart? mine;
    for (final part in parts) {
      if (part.layerKey != layerKey || part.attachmentId != null) {
        out.add(part);
        continue;
      }
      final mask = part.mask == null ? (Uint8List(size)..fillRange(0, size, 1)) : Uint8List.fromList(part.mask!);
      if (part.boneId == boneId) {
        for (final p in targets) {
          mask[p] = 1;
        }
        mine = part.copyWith(mask: () => mask);
        out.add(mine);
        continue;
      }
      var changed = false;
      for (final p in targets) {
        if (mask[p] != 0) {
          mask[p] = 0;
          changed = true;
        }
      }
      out.add(changed ? part.copyWith(mask: () => mask) : part);
    }

    if (boneId != null && mine == null) {
      final mask = Uint8List(size);
      for (final p in targets) {
        mask[p] = 1;
      }
      out.add(RigPart(id: newId(), boneId: boneId, layerKey: layerKey, mask: mask, drawOrder: drawOrder));
    }

    return _normalized(out, layerKey, size);
  }

  static List<RigPart> _normalized(List<RigPart> parts, String layerKey, int size) {
    final result = <RigPart>[];
    for (final part in parts) {
      final mask = part.mask;
      if (part.layerKey != layerKey || part.attachmentId != null || mask == null) {
        result.add(part);
        continue;
      }
      var owned = 0;
      for (final v in mask) {
        if (v != 0) owned++;
      }
      if (owned == 0) continue;
      result.add(owned == size ? part.copyWith(mask: () => null) : part);
    }
    return result;
  }

  /// Pixel indices of a round brush of [diameter] pixels centred on the
  /// pixel containing ([x], [y]), clipped to the canvas.
  static List<int> brush(double x, double y, int diameter, int width, int height) {
    final cx = x.floor(), cy = y.floor();
    final r = diameter / 2;
    final lo = -(diameter ~/ 2);
    final centre = lo + r;
    final out = <int>[];
    for (var dy = lo; dy < lo + diameter; dy++) {
      for (var dx = lo; dx < lo + diameter; dx++) {
        final ox = dx + .5 - centre, oy = dy + .5 - centre;
        // Keep 3px and smaller brushes square-ish so they never lose pixels.
        if (diameter > 3 && ox * ox + oy * oy > r * r) continue;
        final px = cx + dx, py = cy + dy;
        if (px < 0 || py < 0 || px >= width || py >= height) continue;
        out.add(py * width + px);
      }
    }
    return out;
  }
}
