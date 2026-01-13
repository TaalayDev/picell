import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'animation_frame_model.dart';

/// The type of project - determines which editor is used
enum ProjectType {
  /// Standard pixel art project (default)
  pixelArt,

  /// Tile generator project - generate a single tile then edit
  tileGenerator,

  /// Legacy tilemap type - maps to tileGenerator
  @Deprecated('Use tileGenerator instead')
  tilemap,
}

class Project with EquatableMixin {
  final int id;
  final String name;
  final int width;
  final int height;
  // final List<Layer> layers;
  final List<AnimationFrame> frames;
  final List<AnimationStateModel> states;
  final Uint8List? thumbnail;
  final bool isCloudSynced;
  final int? remoteId;
  final DateTime createdAt;
  final DateTime editedAt;

  /// The type of project (pixelArt or tilemap)
  final ProjectType type;

  /// For tile generator projects: width of tile in pixels (defaults to width)
  final int? tileWidth;

  /// For tile generator projects: height of tile in pixels (defaults to height)
  final int? tileHeight;

  Project({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.editedAt,
    this.thumbnail,
    this.isCloudSynced = false,
    this.remoteId,
    this.states = const [],
    this.frames = const [],
    this.type = ProjectType.pixelArt,
    this.tileWidth,
    this.tileHeight,
  });

  Project copyWith({
    int? id,
    String? name,
    int? width,
    int? height,
    List<AnimationStateModel>? states,
    List<AnimationFrame>? frames,
    Uint8List? thumbnail,
    bool? isCloudSynced,
    int? remoteId,
    DateTime? createdAt,
    DateTime? editedAt,
    ProjectType? type,
    int? tileWidth,
    int? tileHeight,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      states: states ?? this.states,
      frames: frames ?? this.frames,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
      remoteId: remoteId ?? this.remoteId,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      type: type ?? this.type,
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'type': type.name,
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
      'states': states.map((state) => state.toJson()).toList(),
      'frames': frames.map((frame) => frame.toJson()).toList(),
      'thumbnail': thumbnail?.toList(),
      'isCloudSynced': isCloudSynced,
      'remoteId': remoteId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'editedAt': editedAt.millisecondsSinceEpoch,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      type: json['type'] != null
          ? ProjectType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => ProjectType.pixelArt,
            )
          : ProjectType.pixelArt,
      tileWidth: json['tileWidth'] as int?,
      tileHeight: json['tileHeight'] as int?,
      states: (json['states'] as List)
          .map(
            (state) => AnimationStateModel.fromJson(state as Map<String, dynamic>),
          )
          .toList(),
      frames: (json['frames'] as List)
          .map(
            (layer) => AnimationFrame.fromJson(layer as Map<String, dynamic>),
          )
          .toList(),
      isCloudSynced: json['isCloudSynced'] as bool? ?? false,
      remoteId: json['remoteId'] as int?,
      thumbnail: json['thumbnail'] != null ? Uint8List.fromList(json['thumbnail'].cast<int>()) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      editedAt: DateTime.fromMillisecondsSinceEpoch(json['editedAt'] as int),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        width,
        height,
        type,
        tileWidth,
        tileHeight,
        frames,
        states,
        thumbnail,
        createdAt,
        editedAt,
      ];
}
