// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApiProject _$ApiProjectFromJson(Map<String, dynamic> json) {
  return _ApiProject.fromJson(json);
}

/// @nodoc
mixin _$ApiProject {
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
  int get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  int get width => throw _privateConstructorUsedError;
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  int get height => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_data')
  String? get projectData => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
  bool get isPublic => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
  bool get isFeatured => throw _privateConstructorUsedError;
  @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
  int get viewCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
  int get likeCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
  int get downloadCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
  int get commentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
  int get forkCount => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'parent_project_id',
      fromJson: ProjectConverters.nullableIntFromJson)
  int? get parentProjectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'published_at')
  DateTime? get publishedAt => throw _privateConstructorUsedError; // User info
  String? get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError; // Social info
  @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
  bool? get isLiked => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiProjectCopyWith<ApiProject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiProjectCopyWith<$Res> {
  factory $ApiProjectCopyWith(
          ApiProject value, $Res Function(ApiProject) then) =
      _$ApiProjectCopyWithImpl<$Res, ApiProject>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: ProjectConverters.intFromJson) int id,
      @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
      int userId,
      String title,
      String? description,
      @JsonKey(fromJson: ProjectConverters.intFromJson) int width,
      @JsonKey(fromJson: ProjectConverters.intFromJson) int height,
      @JsonKey(name: 'project_data') String? projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      bool isPublic,
      @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
      bool isFeatured,
      @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
      int viewCount,
      @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
      int likeCount,
      @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
      int downloadCount,
      @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
      int commentCount,
      @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
      int forkCount,
      @JsonKey(
          name: 'parent_project_id',
          fromJson: ProjectConverters.nullableIntFromJson)
      int? parentProjectId,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'published_at') DateTime? publishedAt,
      String? username,
      @JsonKey(name: 'display_name') String? displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
      bool? isLiked,
      List<String> tags});
}

/// @nodoc
class _$ApiProjectCopyWithImpl<$Res, $Val extends ApiProject>
    implements $ApiProjectCopyWith<$Res> {
  _$ApiProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = freezed,
    Object? width = null,
    Object? height = null,
    Object? projectData = freezed,
    Object? isPublic = null,
    Object? isFeatured = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? downloadCount = null,
    Object? commentCount = null,
    Object? forkCount = null,
    Object? parentProjectId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? publishedAt = freezed,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? isLiked = freezed,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      projectData: freezed == projectData
          ? _value.projectData
          : projectData // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      isFeatured: null == isFeatured
          ? _value.isFeatured
          : isFeatured // ignore: cast_nullable_to_non_nullable
              as bool,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      downloadCount: null == downloadCount
          ? _value.downloadCount
          : downloadCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      forkCount: null == forkCount
          ? _value.forkCount
          : forkCount // ignore: cast_nullable_to_non_nullable
              as int,
      parentProjectId: freezed == parentProjectId
          ? _value.parentProjectId
          : parentProjectId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      publishedAt: freezed == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isLiked: freezed == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiProjectImplCopyWith<$Res>
    implements $ApiProjectCopyWith<$Res> {
  factory _$$ApiProjectImplCopyWith(
          _$ApiProjectImpl value, $Res Function(_$ApiProjectImpl) then) =
      __$$ApiProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: ProjectConverters.intFromJson) int id,
      @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
      int userId,
      String title,
      String? description,
      @JsonKey(fromJson: ProjectConverters.intFromJson) int width,
      @JsonKey(fromJson: ProjectConverters.intFromJson) int height,
      @JsonKey(name: 'project_data') String? projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      bool isPublic,
      @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
      bool isFeatured,
      @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
      int viewCount,
      @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
      int likeCount,
      @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
      int downloadCount,
      @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
      int commentCount,
      @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
      int forkCount,
      @JsonKey(
          name: 'parent_project_id',
          fromJson: ProjectConverters.nullableIntFromJson)
      int? parentProjectId,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'published_at') DateTime? publishedAt,
      String? username,
      @JsonKey(name: 'display_name') String? displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
      bool? isLiked,
      List<String> tags});
}

/// @nodoc
class __$$ApiProjectImplCopyWithImpl<$Res>
    extends _$ApiProjectCopyWithImpl<$Res, _$ApiProjectImpl>
    implements _$$ApiProjectImplCopyWith<$Res> {
  __$$ApiProjectImplCopyWithImpl(
      _$ApiProjectImpl _value, $Res Function(_$ApiProjectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = freezed,
    Object? width = null,
    Object? height = null,
    Object? projectData = freezed,
    Object? isPublic = null,
    Object? isFeatured = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? downloadCount = null,
    Object? commentCount = null,
    Object? forkCount = null,
    Object? parentProjectId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? publishedAt = freezed,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? isLiked = freezed,
    Object? tags = null,
  }) {
    return _then(_$ApiProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      projectData: freezed == projectData
          ? _value.projectData
          : projectData // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      isFeatured: null == isFeatured
          ? _value.isFeatured
          : isFeatured // ignore: cast_nullable_to_non_nullable
              as bool,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      downloadCount: null == downloadCount
          ? _value.downloadCount
          : downloadCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      forkCount: null == forkCount
          ? _value.forkCount
          : forkCount // ignore: cast_nullable_to_non_nullable
              as int,
      parentProjectId: freezed == parentProjectId
          ? _value.parentProjectId
          : parentProjectId // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      publishedAt: freezed == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isLiked: freezed == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiProjectImpl extends _ApiProject {
  const _$ApiProjectImpl(
      {@JsonKey(fromJson: ProjectConverters.intFromJson) required this.id,
      @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
      required this.userId,
      required this.title,
      this.description,
      @JsonKey(fromJson: ProjectConverters.intFromJson) required this.width,
      @JsonKey(fromJson: ProjectConverters.intFromJson) required this.height,
      @JsonKey(name: 'project_data') this.projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      this.isPublic = true,
      @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
      this.isFeatured = false,
      @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
      this.viewCount = 0,
      @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
      this.likeCount = 0,
      @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
      this.downloadCount = 0,
      @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
      this.commentCount = 0,
      @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
      this.forkCount = 0,
      @JsonKey(
          name: 'parent_project_id',
          fromJson: ProjectConverters.nullableIntFromJson)
      this.parentProjectId,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'published_at') this.publishedAt,
      this.username,
      @JsonKey(name: 'display_name') this.displayName,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
      this.isLiked,
      final List<String> tags = const []})
      : _tags = tags,
        super._();

  factory _$ApiProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiProjectImplFromJson(json);

  @override
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  final int id;
  @override
  @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
  final int userId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  final int width;
  @override
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  final int height;
  @override
  @JsonKey(name: 'project_data')
  final String? projectData;
  @override
  @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
  final bool isPublic;
  @override
  @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
  final bool isFeatured;
  @override
  @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
  final int viewCount;
  @override
  @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
  final int likeCount;
  @override
  @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
  final int downloadCount;
  @override
  @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
  final int commentCount;
  @override
  @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
  final int forkCount;
  @override
  @JsonKey(
      name: 'parent_project_id',
      fromJson: ProjectConverters.nullableIntFromJson)
  final int? parentProjectId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
// User info
  @override
  final String? username;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
// Social info
  @override
  @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
  final bool? isLiked;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'ApiProject(id: $id, userId: $userId, title: $title, description: $description, width: $width, height: $height, projectData: $projectData, isPublic: $isPublic, isFeatured: $isFeatured, viewCount: $viewCount, likeCount: $likeCount, downloadCount: $downloadCount, commentCount: $commentCount, forkCount: $forkCount, parentProjectId: $parentProjectId, createdAt: $createdAt, updatedAt: $updatedAt, publishedAt: $publishedAt, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isLiked: $isLiked, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.projectData, projectData) ||
                other.projectData == projectData) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.downloadCount, downloadCount) ||
                other.downloadCount == downloadCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.forkCount, forkCount) ||
                other.forkCount == forkCount) &&
            (identical(other.parentProjectId, parentProjectId) ||
                other.parentProjectId == parentProjectId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        userId,
        title,
        description,
        width,
        height,
        projectData,
        isPublic,
        isFeatured,
        viewCount,
        likeCount,
        downloadCount,
        commentCount,
        forkCount,
        parentProjectId,
        createdAt,
        updatedAt,
        publishedAt,
        username,
        displayName,
        avatarUrl,
        isLiked,
        const DeepCollectionEquality().hash(_tags)
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiProjectImplCopyWith<_$ApiProjectImpl> get copyWith =>
      __$$ApiProjectImplCopyWithImpl<_$ApiProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiProjectImplToJson(
      this,
    );
  }
}

abstract class _ApiProject extends ApiProject {
  const factory _ApiProject(
      {@JsonKey(fromJson: ProjectConverters.intFromJson) required final int id,
      @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
      required final int userId,
      required final String title,
      final String? description,
      @JsonKey(fromJson: ProjectConverters.intFromJson)
      required final int width,
      @JsonKey(fromJson: ProjectConverters.intFromJson)
      required final int height,
      @JsonKey(name: 'project_data') final String? projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      final bool isPublic,
      @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
      final bool isFeatured,
      @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
      final int viewCount,
      @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
      final int likeCount,
      @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
      final int downloadCount,
      @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
      final int commentCount,
      @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
      final int forkCount,
      @JsonKey(
          name: 'parent_project_id',
          fromJson: ProjectConverters.nullableIntFromJson)
      final int? parentProjectId,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      @JsonKey(name: 'published_at') final DateTime? publishedAt,
      final String? username,
      @JsonKey(name: 'display_name') final String? displayName,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
      final bool? isLiked,
      final List<String> tags}) = _$ApiProjectImpl;
  const _ApiProject._() : super._();

  factory _ApiProject.fromJson(Map<String, dynamic> json) =
      _$ApiProjectImpl.fromJson;

  @override
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  int get id;
  @override
  @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson)
  int get userId;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  int get width;
  @override
  @JsonKey(fromJson: ProjectConverters.intFromJson)
  int get height;
  @override
  @JsonKey(name: 'project_data')
  String? get projectData;
  @override
  @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
  bool get isPublic;
  @override
  @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson)
  bool get isFeatured;
  @override
  @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson)
  int get viewCount;
  @override
  @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson)
  int get likeCount;
  @override
  @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson)
  int get downloadCount;
  @override
  @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson)
  int get commentCount;
  @override
  @JsonKey(name: 'fork_count', fromJson: ProjectConverters.intFromJson)
  int get forkCount;
  @override
  @JsonKey(
      name: 'parent_project_id',
      fromJson: ProjectConverters.nullableIntFromJson)
  int? get parentProjectId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'published_at')
  DateTime? get publishedAt;
  @override // User info
  String? get username;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override // Social info
  @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson)
  bool? get isLiked;
  @override
  List<String> get tags;
  @override
  @JsonKey(ignore: true)
  _$$ApiProjectImplCopyWith<_$ApiProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectsResponse _$ProjectsResponseFromJson(Map<String, dynamic> json) {
  return _ProjectsResponse.fromJson(json);
}

/// @nodoc
mixin _$ProjectsResponse {
  List<ApiProject> get projects => throw _privateConstructorUsedError;
  PaginationInfo get pagination => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProjectsResponseCopyWith<ProjectsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectsResponseCopyWith<$Res> {
  factory $ProjectsResponseCopyWith(
          ProjectsResponse value, $Res Function(ProjectsResponse) then) =
      _$ProjectsResponseCopyWithImpl<$Res, ProjectsResponse>;
  @useResult
  $Res call({List<ApiProject> projects, PaginationInfo pagination});

  $PaginationInfoCopyWith<$Res> get pagination;
}

/// @nodoc
class _$ProjectsResponseCopyWithImpl<$Res, $Val extends ProjectsResponse>
    implements $ProjectsResponseCopyWith<$Res> {
  _$ProjectsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projects = null,
    Object? pagination = null,
  }) {
    return _then(_value.copyWith(
      projects: null == projects
          ? _value.projects
          : projects // ignore: cast_nullable_to_non_nullable
              as List<ApiProject>,
      pagination: null == pagination
          ? _value.pagination
          : pagination // ignore: cast_nullable_to_non_nullable
              as PaginationInfo,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PaginationInfoCopyWith<$Res> get pagination {
    return $PaginationInfoCopyWith<$Res>(_value.pagination, (value) {
      return _then(_value.copyWith(pagination: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectsResponseImplCopyWith<$Res>
    implements $ProjectsResponseCopyWith<$Res> {
  factory _$$ProjectsResponseImplCopyWith(_$ProjectsResponseImpl value,
          $Res Function(_$ProjectsResponseImpl) then) =
      __$$ProjectsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ApiProject> projects, PaginationInfo pagination});

  @override
  $PaginationInfoCopyWith<$Res> get pagination;
}

/// @nodoc
class __$$ProjectsResponseImplCopyWithImpl<$Res>
    extends _$ProjectsResponseCopyWithImpl<$Res, _$ProjectsResponseImpl>
    implements _$$ProjectsResponseImplCopyWith<$Res> {
  __$$ProjectsResponseImplCopyWithImpl(_$ProjectsResponseImpl _value,
      $Res Function(_$ProjectsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projects = null,
    Object? pagination = null,
  }) {
    return _then(_$ProjectsResponseImpl(
      projects: null == projects
          ? _value._projects
          : projects // ignore: cast_nullable_to_non_nullable
              as List<ApiProject>,
      pagination: null == pagination
          ? _value.pagination
          : pagination // ignore: cast_nullable_to_non_nullable
              as PaginationInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectsResponseImpl implements _ProjectsResponse {
  const _$ProjectsResponseImpl(
      {required final List<ApiProject> projects, required this.pagination})
      : _projects = projects;

  factory _$ProjectsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectsResponseImplFromJson(json);

  final List<ApiProject> _projects;
  @override
  List<ApiProject> get projects {
    if (_projects is EqualUnmodifiableListView) return _projects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_projects);
  }

  @override
  final PaginationInfo pagination;

  @override
  String toString() {
    return 'ProjectsResponse(projects: $projects, pagination: $pagination)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectsResponseImpl &&
            const DeepCollectionEquality().equals(other._projects, _projects) &&
            (identical(other.pagination, pagination) ||
                other.pagination == pagination));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_projects), pagination);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectsResponseImplCopyWith<_$ProjectsResponseImpl> get copyWith =>
      __$$ProjectsResponseImplCopyWithImpl<_$ProjectsResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectsResponseImplToJson(
      this,
    );
  }
}

abstract class _ProjectsResponse implements ProjectsResponse {
  const factory _ProjectsResponse(
      {required final List<ApiProject> projects,
      required final PaginationInfo pagination}) = _$ProjectsResponseImpl;

  factory _ProjectsResponse.fromJson(Map<String, dynamic> json) =
      _$ProjectsResponseImpl.fromJson;

  @override
  List<ApiProject> get projects;
  @override
  PaginationInfo get pagination;
  @override
  @JsonKey(ignore: true)
  _$$ProjectsResponseImplCopyWith<_$ProjectsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PaginationInfo _$PaginationInfoFromJson(Map<String, dynamic> json) {
  return _PaginationInfo.fromJson(json);
}

/// @nodoc
mixin _$PaginationInfo {
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_pages')
  int get totalPages => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaginationInfoCopyWith<PaginationInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationInfoCopyWith<$Res> {
  factory $PaginationInfoCopyWith(
          PaginationInfo value, $Res Function(PaginationInfo) then) =
      _$PaginationInfoCopyWithImpl<$Res, PaginationInfo>;
  @useResult
  $Res call(
      {int page,
      int limit,
      int total,
      @JsonKey(name: 'total_pages') int totalPages});
}

/// @nodoc
class _$PaginationInfoCopyWithImpl<$Res, $Val extends PaginationInfo>
    implements $PaginationInfoCopyWith<$Res> {
  _$PaginationInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
    Object? total = null,
    Object? totalPages = null,
  }) {
    return _then(_value.copyWith(
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaginationInfoImplCopyWith<$Res>
    implements $PaginationInfoCopyWith<$Res> {
  factory _$$PaginationInfoImplCopyWith(_$PaginationInfoImpl value,
          $Res Function(_$PaginationInfoImpl) then) =
      __$$PaginationInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int page,
      int limit,
      int total,
      @JsonKey(name: 'total_pages') int totalPages});
}

/// @nodoc
class __$$PaginationInfoImplCopyWithImpl<$Res>
    extends _$PaginationInfoCopyWithImpl<$Res, _$PaginationInfoImpl>
    implements _$$PaginationInfoImplCopyWith<$Res> {
  __$$PaginationInfoImplCopyWithImpl(
      _$PaginationInfoImpl _value, $Res Function(_$PaginationInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
    Object? total = null,
    Object? totalPages = null,
  }) {
    return _then(_$PaginationInfoImpl(
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginationInfoImpl implements _PaginationInfo {
  const _$PaginationInfoImpl(
      {required this.page,
      required this.limit,
      required this.total,
      @JsonKey(name: 'total_pages') required this.totalPages});

  factory _$PaginationInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginationInfoImplFromJson(json);

  @override
  final int page;
  @override
  final int limit;
  @override
  final int total;
  @override
  @JsonKey(name: 'total_pages')
  final int totalPages;

  @override
  String toString() {
    return 'PaginationInfo(page: $page, limit: $limit, total: $total, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationInfoImpl &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, page, limit, total, totalPages);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationInfoImplCopyWith<_$PaginationInfoImpl> get copyWith =>
      __$$PaginationInfoImplCopyWithImpl<_$PaginationInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginationInfoImplToJson(
      this,
    );
  }
}

abstract class _PaginationInfo implements PaginationInfo {
  const factory _PaginationInfo(
          {required final int page,
          required final int limit,
          required final int total,
          @JsonKey(name: 'total_pages') required final int totalPages}) =
      _$PaginationInfoImpl;

  factory _PaginationInfo.fromJson(Map<String, dynamic> json) =
      _$PaginationInfoImpl.fromJson;

  @override
  int get page;
  @override
  int get limit;
  @override
  int get total;
  @override
  @JsonKey(name: 'total_pages')
  int get totalPages;
  @override
  @JsonKey(ignore: true)
  _$$PaginationInfoImplCopyWith<_$PaginationInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateProjectRequest _$CreateProjectRequestFromJson(Map<String, dynamic> json) {
  return _CreateProjectRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateProjectRequest {
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_data')
  String get projectData => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
  bool get isPublic => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreateProjectRequestCopyWith<CreateProjectRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateProjectRequestCopyWith<$Res> {
  factory $CreateProjectRequestCopyWith(CreateProjectRequest value,
          $Res Function(CreateProjectRequest) then) =
      _$CreateProjectRequestCopyWithImpl<$Res, CreateProjectRequest>;
  @useResult
  $Res call(
      {String title,
      String? description,
      int width,
      int height,
      @JsonKey(name: 'project_data') String projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      bool isPublic,
      List<String> tags});
}

/// @nodoc
class _$CreateProjectRequestCopyWithImpl<$Res,
        $Val extends CreateProjectRequest>
    implements $CreateProjectRequestCopyWith<$Res> {
  _$CreateProjectRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = freezed,
    Object? width = null,
    Object? height = null,
    Object? projectData = null,
    Object? isPublic = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      projectData: null == projectData
          ? _value.projectData
          : projectData // ignore: cast_nullable_to_non_nullable
              as String,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateProjectRequestImplCopyWith<$Res>
    implements $CreateProjectRequestCopyWith<$Res> {
  factory _$$CreateProjectRequestImplCopyWith(_$CreateProjectRequestImpl value,
          $Res Function(_$CreateProjectRequestImpl) then) =
      __$$CreateProjectRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      String? description,
      int width,
      int height,
      @JsonKey(name: 'project_data') String projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      bool isPublic,
      List<String> tags});
}

/// @nodoc
class __$$CreateProjectRequestImplCopyWithImpl<$Res>
    extends _$CreateProjectRequestCopyWithImpl<$Res, _$CreateProjectRequestImpl>
    implements _$$CreateProjectRequestImplCopyWith<$Res> {
  __$$CreateProjectRequestImplCopyWithImpl(_$CreateProjectRequestImpl _value,
      $Res Function(_$CreateProjectRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = freezed,
    Object? width = null,
    Object? height = null,
    Object? projectData = null,
    Object? isPublic = null,
    Object? tags = null,
  }) {
    return _then(_$CreateProjectRequestImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      projectData: null == projectData
          ? _value.projectData
          : projectData // ignore: cast_nullable_to_non_nullable
              as String,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateProjectRequestImpl implements _CreateProjectRequest {
  const _$CreateProjectRequestImpl(
      {required this.title,
      this.description,
      required this.width,
      required this.height,
      @JsonKey(name: 'project_data') required this.projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      this.isPublic = true,
      final List<String> tags = const []})
      : _tags = tags;

  factory _$CreateProjectRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateProjectRequestImplFromJson(json);

  @override
  final String title;
  @override
  final String? description;
  @override
  final int width;
  @override
  final int height;
  @override
  @JsonKey(name: 'project_data')
  final String projectData;
  @override
  @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
  final bool isPublic;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'CreateProjectRequest(title: $title, description: $description, width: $width, height: $height, projectData: $projectData, isPublic: $isPublic, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateProjectRequestImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.projectData, projectData) ||
                other.projectData == projectData) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      width,
      height,
      projectData,
      isPublic,
      const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateProjectRequestImplCopyWith<_$CreateProjectRequestImpl>
      get copyWith =>
          __$$CreateProjectRequestImplCopyWithImpl<_$CreateProjectRequestImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateProjectRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateProjectRequest implements CreateProjectRequest {
  const factory _CreateProjectRequest(
      {required final String title,
      final String? description,
      required final int width,
      required final int height,
      @JsonKey(name: 'project_data') required final String projectData,
      @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
      final bool isPublic,
      final List<String> tags}) = _$CreateProjectRequestImpl;

  factory _CreateProjectRequest.fromJson(Map<String, dynamic> json) =
      _$CreateProjectRequestImpl.fromJson;

  @override
  String get title;
  @override
  String? get description;
  @override
  int get width;
  @override
  int get height;
  @override
  @JsonKey(name: 'project_data')
  String get projectData;
  @override
  @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson)
  bool get isPublic;
  @override
  List<String> get tags;
  @override
  @JsonKey(ignore: true)
  _$$CreateProjectRequestImplCopyWith<_$CreateProjectRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UpdateProjectRequest _$UpdateProjectRequestFromJson(Map<String, dynamic> json) {
  return _UpdateProjectRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateProjectRequest {
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_data')
  String? get projectData => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_public')
  bool? get isPublic => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UpdateProjectRequestCopyWith<UpdateProjectRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateProjectRequestCopyWith<$Res> {
  factory $UpdateProjectRequestCopyWith(UpdateProjectRequest value,
          $Res Function(UpdateProjectRequest) then) =
      _$UpdateProjectRequestCopyWithImpl<$Res, UpdateProjectRequest>;
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'project_data') String? projectData,
      @JsonKey(name: 'is_public') bool? isPublic,
      List<String>? tags});
}

/// @nodoc
class _$UpdateProjectRequestCopyWithImpl<$Res,
        $Val extends UpdateProjectRequest>
    implements $UpdateProjectRequestCopyWith<$Res> {
  _$UpdateProjectRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? projectData = freezed,
    Object? isPublic = freezed,
    Object? tags = freezed,
  }) {
    return _then(_value.copyWith(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      projectData: freezed == projectData
          ? _value.projectData
          : projectData // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublic: freezed == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateProjectRequestImplCopyWith<$Res>
    implements $UpdateProjectRequestCopyWith<$Res> {
  factory _$$UpdateProjectRequestImplCopyWith(_$UpdateProjectRequestImpl value,
          $Res Function(_$UpdateProjectRequestImpl) then) =
      __$$UpdateProjectRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? title,
      String? description,
      @JsonKey(name: 'project_data') String? projectData,
      @JsonKey(name: 'is_public') bool? isPublic,
      List<String>? tags});
}

/// @nodoc
class __$$UpdateProjectRequestImplCopyWithImpl<$Res>
    extends _$UpdateProjectRequestCopyWithImpl<$Res, _$UpdateProjectRequestImpl>
    implements _$$UpdateProjectRequestImplCopyWith<$Res> {
  __$$UpdateProjectRequestImplCopyWithImpl(_$UpdateProjectRequestImpl _value,
      $Res Function(_$UpdateProjectRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? projectData = freezed,
    Object? isPublic = freezed,
    Object? tags = freezed,
  }) {
    return _then(_$UpdateProjectRequestImpl(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      projectData: freezed == projectData
          ? _value.projectData
          : projectData // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublic: freezed == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateProjectRequestImpl implements _UpdateProjectRequest {
  const _$UpdateProjectRequestImpl(
      {this.title,
      this.description,
      @JsonKey(name: 'project_data') this.projectData,
      @JsonKey(name: 'is_public') this.isPublic,
      final List<String>? tags})
      : _tags = tags;

  factory _$UpdateProjectRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateProjectRequestImplFromJson(json);

  @override
  final String? title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'project_data')
  final String? projectData;
  @override
  @JsonKey(name: 'is_public')
  final bool? isPublic;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'UpdateProjectRequest(title: $title, description: $description, projectData: $projectData, isPublic: $isPublic, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateProjectRequestImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.projectData, projectData) ||
                other.projectData == projectData) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, title, description, projectData,
      isPublic, const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateProjectRequestImplCopyWith<_$UpdateProjectRequestImpl>
      get copyWith =>
          __$$UpdateProjectRequestImplCopyWithImpl<_$UpdateProjectRequestImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateProjectRequestImplToJson(
      this,
    );
  }
}

abstract class _UpdateProjectRequest implements UpdateProjectRequest {
  const factory _UpdateProjectRequest(
      {final String? title,
      final String? description,
      @JsonKey(name: 'project_data') final String? projectData,
      @JsonKey(name: 'is_public') final bool? isPublic,
      final List<String>? tags}) = _$UpdateProjectRequestImpl;

  factory _UpdateProjectRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateProjectRequestImpl.fromJson;

  @override
  String? get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'project_data')
  String? get projectData;
  @override
  @JsonKey(name: 'is_public')
  bool? get isPublic;
  @override
  List<String>? get tags;
  @override
  @JsonKey(ignore: true)
  _$$UpdateProjectRequestImplCopyWith<_$UpdateProjectRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectFilters _$ProjectFiltersFromJson(Map<String, dynamic> json) {
  return _ProjectFilters.fromJson(json);
}

/// @nodoc
mixin _$ProjectFilters {
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  String get sort =>
      throw _privateConstructorUsedError; // recent, popular, views, likes, title, oldest
  String? get search => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  int? get userId => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_width')
  int? get minWidth => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_width')
  int? get maxWidth => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_height')
  int? get minHeight => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_height')
  int? get maxHeight => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_after')
  DateTime? get createdAfter => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_before')
  DateTime? get createdBefore => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProjectFiltersCopyWith<ProjectFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectFiltersCopyWith<$Res> {
  factory $ProjectFiltersCopyWith(
          ProjectFilters value, $Res Function(ProjectFilters) then) =
      _$ProjectFiltersCopyWithImpl<$Res, ProjectFilters>;
  @useResult
  $Res call(
      {int page,
      int limit,
      String sort,
      String? search,
      @JsonKey(name: 'user_id') int? userId,
      String? username,
      List<String> tags,
      @JsonKey(name: 'min_width') int? minWidth,
      @JsonKey(name: 'max_width') int? maxWidth,
      @JsonKey(name: 'min_height') int? minHeight,
      @JsonKey(name: 'max_height') int? maxHeight,
      @JsonKey(name: 'created_after') DateTime? createdAfter,
      @JsonKey(name: 'created_before') DateTime? createdBefore});
}

/// @nodoc
class _$ProjectFiltersCopyWithImpl<$Res, $Val extends ProjectFilters>
    implements $ProjectFiltersCopyWith<$Res> {
  _$ProjectFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
    Object? sort = null,
    Object? search = freezed,
    Object? userId = freezed,
    Object? username = freezed,
    Object? tags = null,
    Object? minWidth = freezed,
    Object? maxWidth = freezed,
    Object? minHeight = freezed,
    Object? maxHeight = freezed,
    Object? createdAfter = freezed,
    Object? createdBefore = freezed,
  }) {
    return _then(_value.copyWith(
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      sort: null == sort
          ? _value.sort
          : sort // ignore: cast_nullable_to_non_nullable
              as String,
      search: freezed == search
          ? _value.search
          : search // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      minWidth: freezed == minWidth
          ? _value.minWidth
          : minWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      maxWidth: freezed == maxWidth
          ? _value.maxWidth
          : maxWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      minHeight: freezed == minHeight
          ? _value.minHeight
          : minHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      maxHeight: freezed == maxHeight
          ? _value.maxHeight
          : maxHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAfter: freezed == createdAfter
          ? _value.createdAfter
          : createdAfter // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBefore: freezed == createdBefore
          ? _value.createdBefore
          : createdBefore // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectFiltersImplCopyWith<$Res>
    implements $ProjectFiltersCopyWith<$Res> {
  factory _$$ProjectFiltersImplCopyWith(_$ProjectFiltersImpl value,
          $Res Function(_$ProjectFiltersImpl) then) =
      __$$ProjectFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int page,
      int limit,
      String sort,
      String? search,
      @JsonKey(name: 'user_id') int? userId,
      String? username,
      List<String> tags,
      @JsonKey(name: 'min_width') int? minWidth,
      @JsonKey(name: 'max_width') int? maxWidth,
      @JsonKey(name: 'min_height') int? minHeight,
      @JsonKey(name: 'max_height') int? maxHeight,
      @JsonKey(name: 'created_after') DateTime? createdAfter,
      @JsonKey(name: 'created_before') DateTime? createdBefore});
}

/// @nodoc
class __$$ProjectFiltersImplCopyWithImpl<$Res>
    extends _$ProjectFiltersCopyWithImpl<$Res, _$ProjectFiltersImpl>
    implements _$$ProjectFiltersImplCopyWith<$Res> {
  __$$ProjectFiltersImplCopyWithImpl(
      _$ProjectFiltersImpl _value, $Res Function(_$ProjectFiltersImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
    Object? sort = null,
    Object? search = freezed,
    Object? userId = freezed,
    Object? username = freezed,
    Object? tags = null,
    Object? minWidth = freezed,
    Object? maxWidth = freezed,
    Object? minHeight = freezed,
    Object? maxHeight = freezed,
    Object? createdAfter = freezed,
    Object? createdBefore = freezed,
  }) {
    return _then(_$ProjectFiltersImpl(
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      sort: null == sort
          ? _value.sort
          : sort // ignore: cast_nullable_to_non_nullable
              as String,
      search: freezed == search
          ? _value.search
          : search // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      minWidth: freezed == minWidth
          ? _value.minWidth
          : minWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      maxWidth: freezed == maxWidth
          ? _value.maxWidth
          : maxWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      minHeight: freezed == minHeight
          ? _value.minHeight
          : minHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      maxHeight: freezed == maxHeight
          ? _value.maxHeight
          : maxHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAfter: freezed == createdAfter
          ? _value.createdAfter
          : createdAfter // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBefore: freezed == createdBefore
          ? _value.createdBefore
          : createdBefore // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectFiltersImpl extends _ProjectFilters {
  const _$ProjectFiltersImpl(
      {this.page = 1,
      this.limit = 20,
      this.sort = 'recent',
      this.search,
      @JsonKey(name: 'user_id') this.userId,
      this.username,
      final List<String> tags = const [],
      @JsonKey(name: 'min_width') this.minWidth,
      @JsonKey(name: 'max_width') this.maxWidth,
      @JsonKey(name: 'min_height') this.minHeight,
      @JsonKey(name: 'max_height') this.maxHeight,
      @JsonKey(name: 'created_after') this.createdAfter,
      @JsonKey(name: 'created_before') this.createdBefore})
      : _tags = tags,
        super._();

  factory _$ProjectFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectFiltersImplFromJson(json);

  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final int limit;
  @override
  @JsonKey()
  final String sort;
// recent, popular, views, likes, title, oldest
  @override
  final String? search;
  @override
  @JsonKey(name: 'user_id')
  final int? userId;
  @override
  final String? username;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'min_width')
  final int? minWidth;
  @override
  @JsonKey(name: 'max_width')
  final int? maxWidth;
  @override
  @JsonKey(name: 'min_height')
  final int? minHeight;
  @override
  @JsonKey(name: 'max_height')
  final int? maxHeight;
  @override
  @JsonKey(name: 'created_after')
  final DateTime? createdAfter;
  @override
  @JsonKey(name: 'created_before')
  final DateTime? createdBefore;

  @override
  String toString() {
    return 'ProjectFilters(page: $page, limit: $limit, sort: $sort, search: $search, userId: $userId, username: $username, tags: $tags, minWidth: $minWidth, maxWidth: $maxWidth, minHeight: $minHeight, maxHeight: $maxHeight, createdAfter: $createdAfter, createdBefore: $createdBefore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectFiltersImpl &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.sort, sort) || other.sort == sort) &&
            (identical(other.search, search) || other.search == search) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.minWidth, minWidth) ||
                other.minWidth == minWidth) &&
            (identical(other.maxWidth, maxWidth) ||
                other.maxWidth == maxWidth) &&
            (identical(other.minHeight, minHeight) ||
                other.minHeight == minHeight) &&
            (identical(other.maxHeight, maxHeight) ||
                other.maxHeight == maxHeight) &&
            (identical(other.createdAfter, createdAfter) ||
                other.createdAfter == createdAfter) &&
            (identical(other.createdBefore, createdBefore) ||
                other.createdBefore == createdBefore));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      page,
      limit,
      sort,
      search,
      userId,
      username,
      const DeepCollectionEquality().hash(_tags),
      minWidth,
      maxWidth,
      minHeight,
      maxHeight,
      createdAfter,
      createdBefore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectFiltersImplCopyWith<_$ProjectFiltersImpl> get copyWith =>
      __$$ProjectFiltersImplCopyWithImpl<_$ProjectFiltersImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectFiltersImplToJson(
      this,
    );
  }
}

abstract class _ProjectFilters extends ProjectFilters {
  const factory _ProjectFilters(
          {final int page,
          final int limit,
          final String sort,
          final String? search,
          @JsonKey(name: 'user_id') final int? userId,
          final String? username,
          final List<String> tags,
          @JsonKey(name: 'min_width') final int? minWidth,
          @JsonKey(name: 'max_width') final int? maxWidth,
          @JsonKey(name: 'min_height') final int? minHeight,
          @JsonKey(name: 'max_height') final int? maxHeight,
          @JsonKey(name: 'created_after') final DateTime? createdAfter,
          @JsonKey(name: 'created_before') final DateTime? createdBefore}) =
      _$ProjectFiltersImpl;
  const _ProjectFilters._() : super._();

  factory _ProjectFilters.fromJson(Map<String, dynamic> json) =
      _$ProjectFiltersImpl.fromJson;

  @override
  int get page;
  @override
  int get limit;
  @override
  String get sort;
  @override // recent, popular, views, likes, title, oldest
  String? get search;
  @override
  @JsonKey(name: 'user_id')
  int? get userId;
  @override
  String? get username;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'min_width')
  int? get minWidth;
  @override
  @JsonKey(name: 'max_width')
  int? get maxWidth;
  @override
  @JsonKey(name: 'min_height')
  int? get minHeight;
  @override
  @JsonKey(name: 'max_height')
  int? get maxHeight;
  @override
  @JsonKey(name: 'created_after')
  DateTime? get createdAfter;
  @override
  @JsonKey(name: 'created_before')
  DateTime? get createdBefore;
  @override
  @JsonKey(ignore: true)
  _$$ProjectFiltersImplCopyWith<_$ProjectFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApiTag _$ApiTagFromJson(Map<String, dynamic> json) {
  return _ApiTag.fromJson(json);
}

/// @nodoc
mixin _$ApiTag {
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  @JsonKey(name: 'usage_count')
  int get usageCount => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiTagCopyWith<ApiTag> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiTagCopyWith<$Res> {
  factory $ApiTagCopyWith(ApiTag value, $Res Function(ApiTag) then) =
      _$ApiTagCopyWithImpl<$Res, ApiTag>;
  @useResult
  $Res call(
      {String name,
      String slug,
      @JsonKey(name: 'usage_count') int usageCount,
      String? color,
      String? description});
}

/// @nodoc
class _$ApiTagCopyWithImpl<$Res, $Val extends ApiTag>
    implements $ApiTagCopyWith<$Res> {
  _$ApiTagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? slug = null,
    Object? usageCount = null,
    Object? color = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      usageCount: null == usageCount
          ? _value.usageCount
          : usageCount // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiTagImplCopyWith<$Res> implements $ApiTagCopyWith<$Res> {
  factory _$$ApiTagImplCopyWith(
          _$ApiTagImpl value, $Res Function(_$ApiTagImpl) then) =
      __$$ApiTagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String slug,
      @JsonKey(name: 'usage_count') int usageCount,
      String? color,
      String? description});
}

/// @nodoc
class __$$ApiTagImplCopyWithImpl<$Res>
    extends _$ApiTagCopyWithImpl<$Res, _$ApiTagImpl>
    implements _$$ApiTagImplCopyWith<$Res> {
  __$$ApiTagImplCopyWithImpl(
      _$ApiTagImpl _value, $Res Function(_$ApiTagImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? slug = null,
    Object? usageCount = null,
    Object? color = freezed,
    Object? description = freezed,
  }) {
    return _then(_$ApiTagImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      usageCount: null == usageCount
          ? _value.usageCount
          : usageCount // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiTagImpl implements _ApiTag {
  const _$ApiTagImpl(
      {required this.name,
      required this.slug,
      @JsonKey(name: 'usage_count') this.usageCount = 0,
      this.color,
      this.description});

  factory _$ApiTagImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiTagImplFromJson(json);

  @override
  final String name;
  @override
  final String slug;
  @override
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @override
  final String? color;
  @override
  final String? description;

  @override
  String toString() {
    return 'ApiTag(name: $name, slug: $slug, usageCount: $usageCount, color: $color, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiTagImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.usageCount, usageCount) ||
                other.usageCount == usageCount) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, slug, usageCount, color, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiTagImplCopyWith<_$ApiTagImpl> get copyWith =>
      __$$ApiTagImplCopyWithImpl<_$ApiTagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiTagImplToJson(
      this,
    );
  }
}

abstract class _ApiTag implements ApiTag {
  const factory _ApiTag(
      {required final String name,
      required final String slug,
      @JsonKey(name: 'usage_count') final int usageCount,
      final String? color,
      final String? description}) = _$ApiTagImpl;

  factory _ApiTag.fromJson(Map<String, dynamic> json) = _$ApiTagImpl.fromJson;

  @override
  String get name;
  @override
  String get slug;
  @override
  @JsonKey(name: 'usage_count')
  int get usageCount;
  @override
  String? get color;
  @override
  String? get description;
  @override
  @JsonKey(ignore: true)
  _$$ApiTagImplCopyWith<_$ApiTagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApiComment _$ApiCommentFromJson(Map<String, dynamic> json) {
  return _ApiComment.fromJson(json);
}

/// @nodoc
mixin _$ApiComment {
  int get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
  bool get isEdited => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'replies_count')
  int get repliesCount => throw _privateConstructorUsedError; // User info
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
  bool get isVerified => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiCommentCopyWith<ApiComment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiCommentCopyWith<$Res> {
  factory $ApiCommentCopyWith(
          ApiComment value, $Res Function(ApiComment) then) =
      _$ApiCommentCopyWithImpl<$Res, ApiComment>;
  @useResult
  $Res call(
      {int id,
      String content,
      @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
      bool isEdited,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'replies_count') int repliesCount,
      String username,
      @JsonKey(name: 'display_name') String? displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
      bool isVerified});
}

/// @nodoc
class _$ApiCommentCopyWithImpl<$Res, $Val extends ApiComment>
    implements $ApiCommentCopyWith<$Res> {
  _$ApiCommentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? isEdited = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? repliesCount = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? isVerified = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      repliesCount: null == repliesCount
          ? _value.repliesCount
          : repliesCount // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiCommentImplCopyWith<$Res>
    implements $ApiCommentCopyWith<$Res> {
  factory _$$ApiCommentImplCopyWith(
          _$ApiCommentImpl value, $Res Function(_$ApiCommentImpl) then) =
      __$$ApiCommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String content,
      @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
      bool isEdited,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'replies_count') int repliesCount,
      String username,
      @JsonKey(name: 'display_name') String? displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
      bool isVerified});
}

/// @nodoc
class __$$ApiCommentImplCopyWithImpl<$Res>
    extends _$ApiCommentCopyWithImpl<$Res, _$ApiCommentImpl>
    implements _$$ApiCommentImplCopyWith<$Res> {
  __$$ApiCommentImplCopyWithImpl(
      _$ApiCommentImpl _value, $Res Function(_$ApiCommentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? isEdited = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? repliesCount = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? isVerified = null,
  }) {
    return _then(_$ApiCommentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      repliesCount: null == repliesCount
          ? _value.repliesCount
          : repliesCount // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiCommentImpl implements _ApiComment {
  const _$ApiCommentImpl(
      {required this.id,
      required this.content,
      @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
      this.isEdited = false,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'replies_count') this.repliesCount = 0,
      required this.username,
      @JsonKey(name: 'display_name') this.displayName,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
      this.isVerified = false});

  factory _$ApiCommentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiCommentImplFromJson(json);

  @override
  final int id;
  @override
  final String content;
  @override
  @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
  final bool isEdited;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'replies_count')
  final int repliesCount;
// User info
  @override
  final String username;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
  final bool isVerified;

  @override
  String toString() {
    return 'ApiComment(id: $id, content: $content, isEdited: $isEdited, createdAt: $createdAt, updatedAt: $updatedAt, repliesCount: $repliesCount, username: $username, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiCommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.repliesCount, repliesCount) ||
                other.repliesCount == repliesCount) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, isEdited, createdAt,
      updatedAt, repliesCount, username, displayName, avatarUrl, isVerified);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiCommentImplCopyWith<_$ApiCommentImpl> get copyWith =>
      __$$ApiCommentImplCopyWithImpl<_$ApiCommentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiCommentImplToJson(
      this,
    );
  }
}

abstract class _ApiComment implements ApiComment {
  const factory _ApiComment(
      {required final int id,
      required final String content,
      @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
      final bool isEdited,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      @JsonKey(name: 'replies_count') final int repliesCount,
      required final String username,
      @JsonKey(name: 'display_name') final String? displayName,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
      final bool isVerified}) = _$ApiCommentImpl;

  factory _ApiComment.fromJson(Map<String, dynamic> json) =
      _$ApiCommentImpl.fromJson;

  @override
  int get id;
  @override
  String get content;
  @override
  @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson)
  bool get isEdited;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'replies_count')
  int get repliesCount;
  @override // User info
  String get username;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson)
  bool get isVerified;
  @override
  @JsonKey(ignore: true)
  _$$ApiCommentImplCopyWith<_$ApiCommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LikeResponse _$LikeResponseFromJson(Map<String, dynamic> json) {
  return _LikeResponse.fromJson(json);
}

/// @nodoc
mixin _$LikeResponse {
  String get message => throw _privateConstructorUsedError;
  @JsonKey(fromJson: ProjectConverters.boolFromJson)
  bool get liked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LikeResponseCopyWith<LikeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LikeResponseCopyWith<$Res> {
  factory $LikeResponseCopyWith(
          LikeResponse value, $Res Function(LikeResponse) then) =
      _$LikeResponseCopyWithImpl<$Res, LikeResponse>;
  @useResult
  $Res call(
      {String message,
      @JsonKey(fromJson: ProjectConverters.boolFromJson) bool liked});
}

/// @nodoc
class _$LikeResponseCopyWithImpl<$Res, $Val extends LikeResponse>
    implements $LikeResponseCopyWith<$Res> {
  _$LikeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? liked = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      liked: null == liked
          ? _value.liked
          : liked // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LikeResponseImplCopyWith<$Res>
    implements $LikeResponseCopyWith<$Res> {
  factory _$$LikeResponseImplCopyWith(
          _$LikeResponseImpl value, $Res Function(_$LikeResponseImpl) then) =
      __$$LikeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      @JsonKey(fromJson: ProjectConverters.boolFromJson) bool liked});
}

/// @nodoc
class __$$LikeResponseImplCopyWithImpl<$Res>
    extends _$LikeResponseCopyWithImpl<$Res, _$LikeResponseImpl>
    implements _$$LikeResponseImplCopyWith<$Res> {
  __$$LikeResponseImplCopyWithImpl(
      _$LikeResponseImpl _value, $Res Function(_$LikeResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? liked = null,
  }) {
    return _then(_$LikeResponseImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      liked: null == liked
          ? _value.liked
          : liked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LikeResponseImpl implements _LikeResponse {
  const _$LikeResponseImpl(
      {required this.message,
      @JsonKey(fromJson: ProjectConverters.boolFromJson) required this.liked});

  factory _$LikeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LikeResponseImplFromJson(json);

  @override
  final String message;
  @override
  @JsonKey(fromJson: ProjectConverters.boolFromJson)
  final bool liked;

  @override
  String toString() {
    return 'LikeResponse(message: $message, liked: $liked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LikeResponseImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.liked, liked) || other.liked == liked));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, message, liked);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LikeResponseImplCopyWith<_$LikeResponseImpl> get copyWith =>
      __$$LikeResponseImplCopyWithImpl<_$LikeResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LikeResponseImplToJson(
      this,
    );
  }
}

abstract class _LikeResponse implements LikeResponse {
  const factory _LikeResponse(
      {required final String message,
      @JsonKey(fromJson: ProjectConverters.boolFromJson)
      required final bool liked}) = _$LikeResponseImpl;

  factory _LikeResponse.fromJson(Map<String, dynamic> json) =
      _$LikeResponseImpl.fromJson;

  @override
  String get message;
  @override
  @JsonKey(fromJson: ProjectConverters.boolFromJson)
  bool get liked;
  @override
  @JsonKey(ignore: true)
  _$$LikeResponseImplCopyWith<_$LikeResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
