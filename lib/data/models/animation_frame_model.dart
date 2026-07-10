import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../pixel/pixel_utils.dart';
import 'layer.dart';

class AnimationFrame extends Equatable {
  final int id;
  final String name;
  final int stateId;
  final int duration; // Duration in milliseconds
  final List<Layer> layers;
  final int order;
  final DateTime createdAt;
  final DateTime editedAt;

  /// Composite of all visible layers, using the same convention as
  /// [PixelUtils.mergeLayersPixels]: the last layer in the list is on top
  /// and per-layer opacity is applied.
  Uint32List get pixels {
    final visible = layers.where((l) => l.isVisible && l.opacity > 0).toList();
    if (visible.isEmpty) {
      return Uint32List(layers.isEmpty ? 0 : layers.first.pixels.length);
    }

    final merged = Uint32List(visible.first.processedPixels.length);
    for (final layer in visible.reversed) {
      final src = layer.processedPixels;
      for (int i = 0; i < merged.length; i++) {
        if (merged[i] == 0) {
          merged[i] = PixelUtils.applyAlpha(src[i], layer.opacity);
        }
      }
    }
    return merged;
  }

  AnimationFrame({
    required this.id,
    required this.name,
    required this.stateId,
    required this.duration,
    required this.layers,
    this.order = 0,
    DateTime? createdAt,
    DateTime? editedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        editedAt = editedAt ?? DateTime.now();

  AnimationFrame copyWith({
    int? id,
    String? name,
    int? stateId,
    int? duration,
    List<Layer>? layers,
    DateTime? editedAt,
    int? order,
  }) {
    return AnimationFrame(
      id: id ?? this.id,
      name: name ?? this.name,
      stateId: stateId ?? this.stateId,
      duration: duration ?? this.duration,
      layers: layers ?? this.layers,
      order: order ?? this.order,
      createdAt: createdAt,
      editedAt: editedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stateId': stateId,
      'layers': layers.map((layer) => layer.toJson()).toList(),
      'duration': duration,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'editedAt': editedAt.millisecondsSinceEpoch,
      'order': order,
    };
  }

  factory AnimationFrame.fromJson(Map<String, dynamic> json) {
    return AnimationFrame(
      id: json['id'] as int,
      name: json['name'] as String,
      stateId: json['stateId'] as int,
      layers: (json['layers'] as List)
          .map((layer) => Layer.fromJson(layer as Map<String, dynamic>))
          .toList(),
      duration: json['duration'] as int,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      editedAt: DateTime.fromMillisecondsSinceEpoch(json['editedAt'] as int),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, stateId, duration, createdAt, editedAt, order];
}

class AnimationStateModel extends Equatable {
  final int id;
  final String name;
  final int frameRate;

  const AnimationStateModel({
    required this.id,
    required this.name,
    required this.frameRate,
  });

  AnimationStateModel copyWith({
    int? id,
    List<AnimationFrame>? frames,
    int? currentFrameIndex,
    bool? isPlaying,
    bool? isLooping,
    int? frameRate,
  }) {
    return AnimationStateModel(
      id: id ?? this.id,
      name: name,
      frameRate: frameRate ?? this.frameRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frameRate': frameRate,
    };
  }

  factory AnimationStateModel.fromJson(Map<String, dynamic> json) {
    return AnimationStateModel(
      id: json['id'] as int,
      name: json['name'] as String,
      frameRate: json['frameRate'] as int,
    );
  }

  @override
  List<Object?> get props => [id, frameRate, name];
}
