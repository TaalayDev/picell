import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Binds pixels of a layer to a [Bone]. The part moves rigidly with its bone.
///
/// Pixels come from the rest-pose layer whose `Layer.stableKey` equals
/// [layerKey]; they are never copied into the rig. When [mask] is null the
/// whole layer belongs to the bone, otherwise only the masked pixels do (so
/// one layer can be split across several bones).
class RigPart with EquatableMixin {
  final String id;
  final String boneId;
  final String layerKey;
  final String? attachmentId;

  /// One byte per canvas pixel, non-zero = owned by this part.
  final Uint8List? mask;
  final int drawOrder;

  /// Rotation pivot in rest-pose pixels; null means the bone head.
  final Offset? pivotOverride;

  const RigPart({
    required this.id,
    required this.boneId,
    required this.layerKey,
    this.attachmentId,
    this.mask,
    this.drawOrder = 0,
    this.pivotOverride,
  });

  RigPart copyWith({
    String? id,
    String? boneId,
    String? layerKey,
    String? Function()? attachmentId,
    Uint8List? Function()? mask,
    int? drawOrder,
    Offset? Function()? pivotOverride,
  }) {
    return RigPart(
      id: id ?? this.id,
      boneId: boneId ?? this.boneId,
      layerKey: layerKey ?? this.layerKey,
      attachmentId: attachmentId != null ? attachmentId() : this.attachmentId,
      mask: mask != null ? mask() : this.mask,
      drawOrder: drawOrder ?? this.drawOrder,
      pivotOverride: pivotOverride != null ? pivotOverride() : this.pivotOverride,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'boneId': boneId,
        'layerKey': layerKey,
        if (attachmentId != null) 'attachmentId': attachmentId,
        if (mask != null) 'mask': encodeMask(mask!),
        'drawOrder': drawOrder,
        if (pivotOverride != null) 'pivotOverride': {'dx': pivotOverride!.dx, 'dy': pivotOverride!.dy},
      };

  factory RigPart.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivotOverride'] as Map<String, dynamic>?;
    return RigPart(
      id: json['id'] as String,
      boneId: json['boneId'] as String,
      layerKey: json['layerKey'] as String,
      attachmentId: json['attachmentId'] as String?,
      mask: json['mask'] == null ? null : decodeMask((json['mask'] as List).cast<int>()),
      drawOrder: json['drawOrder'] as int? ?? 0,
      pivotOverride: pivot == null ? null : Offset((pivot['dx'] as num).toDouble(), (pivot['dy'] as num).toDouble()),
    );
  }

  /// Run-length encodes a mask as `[value, runLength, value, runLength, ...]`
  /// with value 0 or 1. Masks are mostly long runs, so this stays small where
  /// a plain int list (as `Layer.pixels` uses) would not.
  static List<int> encodeMask(Uint8List mask) {
    final out = <int>[];
    var i = 0;
    while (i < mask.length) {
      final value = mask[i] == 0 ? 0 : 1;
      var j = i + 1;
      while (j < mask.length && (mask[j] == 0 ? 0 : 1) == value) {
        j++;
      }
      out
        ..add(value)
        ..add(j - i);
      i = j;
    }
    return out;
  }

  static Uint8List decodeMask(List<int> runs) {
    var total = 0;
    for (var i = 1; i < runs.length; i += 2) {
      total += runs[i];
    }
    final mask = Uint8List(total);
    var pos = 0;
    for (var i = 0; i + 1 < runs.length; i += 2) {
      if (runs[i] != 0) mask.fillRange(pos, pos + runs[i + 1], 1);
      pos += runs[i + 1];
    }
    return mask;
  }

  @override
  List<Object?> get props => [id, boneId, layerKey, attachmentId, mask, drawOrder, pivotOverride];
}
