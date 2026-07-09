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

  /// The community project id this project was downloaded/forked from, if
  /// any. Unlike [remoteId] (which means "the server project I own and sync
  /// to"), this survives regardless of ownership so lineage isn't lost when
  /// a downloaded-but-not-owned project is later uploaded as a new fork.
  final int? forkedFromId;
  final DateTime createdAt;
  final DateTime editedAt;

  /// The type of project (pixelArt or tilemap)
  final ProjectType type;

  /// For tile generator projects: width of tile in pixels (defaults to width)
  final int? tileWidth;

  /// For tile generator projects: height of tile in pixels (defaults to height)
  final int? tileHeight;

  /// For tilemap projects: number of columns in the tilemap grid
  final int? gridColumns;

  /// For tilemap projects: number of rows in the tilemap grid
  final int? gridRows;

  /// JSON string containing tilemap state data (tiles, layers, grid)
  final String? tilemapData;

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
    this.forkedFromId,
    this.states = const [],
    this.frames = const [],
    this.type = ProjectType.pixelArt,
    this.tileWidth,
    this.tileHeight,
    this.gridColumns,
    this.gridRows,
    this.tilemapData,
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
    bool clearRemoteId = false,
    int? forkedFromId,
    bool clearForkedFromId = false,
    DateTime? createdAt,
    DateTime? editedAt,
    ProjectType? type,
    int? tileWidth,
    int? tileHeight,
    int? gridColumns,
    int? gridRows,
    String? tilemapData,
    bool clearTilemapData = false,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      states: states ?? this.states,
      frames: frames ?? this.frames,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
      remoteId: clearRemoteId ? null : (remoteId ?? this.remoteId),
      forkedFromId: clearForkedFromId ? null : (forkedFromId ?? this.forkedFromId),
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      type: type ?? this.type,
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      tilemapData: clearTilemapData ? null : (tilemapData ?? this.tilemapData),
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
      'gridColumns': gridColumns,
      'gridRows': gridRows,
      'tilemapData': tilemapData,
      'states': states.map((state) => state.toJson()).toList(),
      'frames': frames.map((frame) => frame.toJson()).toList(),
      'thumbnail': thumbnail?.toList(),
      'isCloudSynced': isCloudSynced,
      'remoteId': remoteId,
      'forkedFromId': forkedFromId,
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
      gridColumns: json['gridColumns'] as int?,
      gridRows: json['gridRows'] as int?,
      tilemapData: json['tilemapData'] as String?,
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
      forkedFromId: json['forkedFromId'] as int?,
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
        gridColumns,
        gridRows,
        tilemapData,
        frames,
        states,
        thumbnail,
        createdAt,
        editedAt,
      ];
}
