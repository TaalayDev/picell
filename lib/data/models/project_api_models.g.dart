// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiProjectImpl _$$ApiProjectImplFromJson(Map<String, dynamic> json) =>
    _$ApiProjectImpl(
      id: ProjectConverters.intFromJson(json['id']),
      userId: ProjectConverters.intFromJson(json['user_id']),
      title: json['title'] as String,
      description: json['description'] as String?,
      width: ProjectConverters.intFromJson(json['width']),
      height: ProjectConverters.intFromJson(json['height']),
      projectData: json['project_data'] as String?,
      isPublic: json['is_public'] == null
          ? true
          : ProjectConverters.boolFromJson(json['is_public']),
      isFeatured: json['is_featured'] == null
          ? false
          : ProjectConverters.boolFromJson(json['is_featured']),
      viewCount: json['view_count'] == null
          ? 0
          : ProjectConverters.intFromJson(json['view_count']),
      likeCount: json['like_count'] == null
          ? 0
          : ProjectConverters.intFromJson(json['like_count']),
      downloadCount: json['download_count'] == null
          ? 0
          : ProjectConverters.intFromJson(json['download_count']),
      commentCount: json['comment_count'] == null
          ? 0
          : ProjectConverters.intFromJson(json['comment_count']),
      forkCount: json['fork_count'] == null
          ? 0
          : ProjectConverters.intFromJson(json['fork_count']),
      parentProjectId:
          ProjectConverters.nullableIntFromJson(json['parent_project_id']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isLiked: ProjectConverters.boolFromJson(json['is_liked']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$ApiProjectImplToJson(_$ApiProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'width': instance.width,
      'height': instance.height,
      'project_data': instance.projectData,
      'is_public': instance.isPublic,
      'is_featured': instance.isFeatured,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'download_count': instance.downloadCount,
      'comment_count': instance.commentCount,
      'fork_count': instance.forkCount,
      'parent_project_id': instance.parentProjectId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'published_at': instance.publishedAt?.toIso8601String(),
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'is_liked': instance.isLiked,
      'tags': instance.tags,
    };

_$ProjectsResponseImpl _$$ProjectsResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectsResponseImpl(
      projects: (json['projects'] as List<dynamic>)
          .map((e) => ApiProject.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectsResponseImplToJson(
        _$ProjectsResponseImpl instance) =>
    <String, dynamic>{
      'projects': instance.projects,
      'pagination': instance.pagination,
    };

_$PaginationInfoImpl _$$PaginationInfoImplFromJson(Map<String, dynamic> json) =>
    _$PaginationInfoImpl(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
    );

Map<String, dynamic> _$$PaginationInfoImplToJson(
        _$PaginationInfoImpl instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'total_pages': instance.totalPages,
    };

_$CreateProjectRequestImpl _$$CreateProjectRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CreateProjectRequestImpl(
      title: json['title'] as String,
      description: json['description'] as String?,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      projectData: json['project_data'] as String,
      isPublic: json['is_public'] == null
          ? true
          : ProjectConverters.boolFromJson(json['is_public']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$CreateProjectRequestImplToJson(
        _$CreateProjectRequestImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'width': instance.width,
      'height': instance.height,
      'project_data': instance.projectData,
      'is_public': instance.isPublic,
      'tags': instance.tags,
    };

_$UpdateProjectRequestImpl _$$UpdateProjectRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$UpdateProjectRequestImpl(
      title: json['title'] as String?,
      description: json['description'] as String?,
      projectData: json['project_data'] as String?,
      isPublic: json['is_public'] as bool?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$UpdateProjectRequestImplToJson(
        _$UpdateProjectRequestImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'project_data': instance.projectData,
      'is_public': instance.isPublic,
      'tags': instance.tags,
    };

_$ProjectFiltersImpl _$$ProjectFiltersImplFromJson(Map<String, dynamic> json) =>
    _$ProjectFiltersImpl(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      sort: json['sort'] as String? ?? 'recent',
      search: json['search'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      username: json['username'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      minWidth: (json['min_width'] as num?)?.toInt(),
      maxWidth: (json['max_width'] as num?)?.toInt(),
      minHeight: (json['min_height'] as num?)?.toInt(),
      maxHeight: (json['max_height'] as num?)?.toInt(),
      createdAfter: json['created_after'] == null
          ? null
          : DateTime.parse(json['created_after'] as String),
      createdBefore: json['created_before'] == null
          ? null
          : DateTime.parse(json['created_before'] as String),
    );

Map<String, dynamic> _$$ProjectFiltersImplToJson(
        _$ProjectFiltersImpl instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'sort': instance.sort,
      'search': instance.search,
      'user_id': instance.userId,
      'username': instance.username,
      'tags': instance.tags,
      'min_width': instance.minWidth,
      'max_width': instance.maxWidth,
      'min_height': instance.minHeight,
      'max_height': instance.maxHeight,
      'created_after': instance.createdAfter?.toIso8601String(),
      'created_before': instance.createdBefore?.toIso8601String(),
    };

_$ApiTagImpl _$$ApiTagImplFromJson(Map<String, dynamic> json) => _$ApiTagImpl(
      name: json['name'] as String,
      slug: json['slug'] as String,
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      color: json['color'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$ApiTagImplToJson(_$ApiTagImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'slug': instance.slug,
      'usage_count': instance.usageCount,
      'color': instance.color,
      'description': instance.description,
    };

_$ApiCommentImpl _$$ApiCommentImplFromJson(Map<String, dynamic> json) =>
    _$ApiCommentImpl(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String,
      isEdited: json['is_edited'] == null
          ? false
          : ProjectConverters.boolFromJson(json['is_edited']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] == null
          ? false
          : ProjectConverters.boolFromJson(json['is_verified']),
    );

Map<String, dynamic> _$$ApiCommentImplToJson(_$ApiCommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'is_edited': instance.isEdited,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'replies_count': instance.repliesCount,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'is_verified': instance.isVerified,
    };

_$LikeResponseImpl _$$LikeResponseImplFromJson(Map<String, dynamic> json) =>
    _$LikeResponseImpl(
      message: json['message'] as String,
      liked: ProjectConverters.boolFromJson(json['liked']),
    );

Map<String, dynamic> _$$LikeResponseImplToJson(_$LikeResponseImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'liked': instance.liked,
    };
