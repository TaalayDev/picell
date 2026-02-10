import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picell/config/constants.dart';

part 'project_api_models.freezed.dart';
part 'project_api_models.g.dart';

@freezed
abstract class ApiProject with _$ApiProject {
  const ApiProject._();
  const factory ApiProject({
    @JsonKey(fromJson: ProjectConverters.intFromJson) required int id,
    @JsonKey(name: 'user_id', fromJson: ProjectConverters.intFromJson) required int userId,
    required String title,
    String? description,
    @JsonKey(fromJson: ProjectConverters.intFromJson) required int width,
    @JsonKey(fromJson: ProjectConverters.intFromJson) required int height,
    @JsonKey(name: 'project_data') String? projectData,
    @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson) @Default(true) bool isPublic,
    @JsonKey(name: 'is_featured', fromJson: ProjectConverters.boolFromJson) @Default(false) bool isFeatured,
    @JsonKey(name: 'view_count', fromJson: ProjectConverters.intFromJson) @Default(0) int viewCount,
    @JsonKey(name: 'like_count', fromJson: ProjectConverters.intFromJson) @Default(0) int likeCount,
    @JsonKey(name: 'download_count', fromJson: ProjectConverters.intFromJson) @Default(0) int downloadCount,
    @JsonKey(name: 'comment_count', fromJson: ProjectConverters.intFromJson) @Default(0) int commentCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'published_at') DateTime? publishedAt,

    // User info
    String? username,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,

    // Social info
    @JsonKey(name: 'is_liked', fromJson: ProjectConverters.boolFromJson) bool? isLiked,
    @Default([]) List<String> tags,
  }) = _ApiProject;

  factory ApiProject.fromJson(Map<String, dynamic> json) => _$ApiProjectFromJson(json);

  String get thumbnailUrl {
    return '${Constants.apiUrl}/projects/$id/thumbnail';
  }
}

@freezed
abstract class ProjectsResponse with _$ProjectsResponse {
  const factory ProjectsResponse({
    required List<ApiProject> projects,
    required PaginationInfo pagination,
  }) = _ProjectsResponse;

  factory ProjectsResponse.fromJson(Map<String, dynamic> json) => _$ProjectsResponseFromJson(json);
}

@freezed
abstract class PaginationInfo with _$PaginationInfo {
  const factory PaginationInfo({
    required int page,
    required int limit,
    required int total,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _PaginationInfo;

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => _$PaginationInfoFromJson(json);
}

@freezed
abstract class CreateProjectRequest with _$CreateProjectRequest {
  const factory CreateProjectRequest({
    required String title,
    String? description,
    required int width,
    required int height,
    @JsonKey(name: 'project_data') required String projectData,
    @JsonKey(name: 'is_public', fromJson: ProjectConverters.boolFromJson) @Default(true) bool isPublic,
    @Default([]) List<String> tags,
  }) = _CreateProjectRequest;

  factory CreateProjectRequest.fromJson(Map<String, dynamic> json) => _$CreateProjectRequestFromJson(json);
}

@freezed
abstract class UpdateProjectRequest with _$UpdateProjectRequest {
  const factory UpdateProjectRequest({
    String? title,
    String? description,
    @JsonKey(name: 'project_data') String? projectData,
    @JsonKey(name: 'is_public') bool? isPublic,
    List<String>? tags,
  }) = _UpdateProjectRequest;

  factory UpdateProjectRequest.fromJson(Map<String, dynamic> json) => _$UpdateProjectRequestFromJson(json);
}

@freezed
abstract class ProjectFilters with _$ProjectFilters {
  const ProjectFilters._();
  const factory ProjectFilters({
    @Default(1) int page,
    @Default(20) int limit,
    @Default('recent') String sort, // recent, popular, views, likes, title, oldest
    String? search,
    @JsonKey(name: 'user_id') int? userId,
    String? username,
    @Default([]) List<String> tags,
    @JsonKey(name: 'min_width') int? minWidth,
    @JsonKey(name: 'max_width') int? maxWidth,
    @JsonKey(name: 'min_height') int? minHeight,
    @JsonKey(name: 'max_height') int? maxHeight,
    @JsonKey(name: 'created_after') DateTime? createdAfter,
    @JsonKey(name: 'created_before') DateTime? createdBefore,
  }) = _ProjectFilters;

  factory ProjectFilters.fromJson(Map<String, dynamic> json) => _$ProjectFiltersFromJson(json);

  Map<String, dynamic> toQueryParams() {
    final map = toJson();

    // Convert DateTime to ISO strings
    if (createdAfter != null) {
      map['created_after'] = createdAfter!.toIso8601String();
    }
    if (createdBefore != null) {
      map['created_before'] = createdBefore!.toIso8601String();
    }

    // Convert tags list to comma-separated string
    if (tags.isNotEmpty) {
      map['tags'] = tags.join(',');
    }

    // Remove null values
    map.removeWhere((key, value) => value == null);

    return map;
  }
}

@freezed
abstract class ApiTag with _$ApiTag {
  const factory ApiTag({
    required String name,
    required String slug,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    String? color,
    String? description,
  }) = _ApiTag;

  factory ApiTag.fromJson(Map<String, dynamic> json) => _$ApiTagFromJson(json);
}

@freezed
abstract class ApiComment with _$ApiComment {
  const factory ApiComment({
    required int id,
    required String content,
    @JsonKey(name: 'is_edited', fromJson: ProjectConverters.boolFromJson) @Default(false) bool isEdited,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'replies_count') @Default(0) int repliesCount,

    // User info
    required String username,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_verified', fromJson: ProjectConverters.boolFromJson) @Default(false) bool isVerified,
  }) = _ApiComment;

  factory ApiComment.fromJson(Map<String, dynamic> json) => _$ApiCommentFromJson(json);
}

@freezed
abstract class LikeResponse with _$LikeResponse {
  const factory LikeResponse({
    required String message,
    @JsonKey(fromJson: ProjectConverters.boolFromJson) required bool liked,
  }) = _LikeResponse;

  factory LikeResponse.fromJson(Map<String, dynamic> json) => _$LikeResponseFromJson(json);
}

// Custom converters for the repository
class ProjectConverters {
  static ApiProject project(dynamic data) => ApiProject.fromJson(data as Map<String, dynamic>);

  static ProjectsResponse projectsList(dynamic data) => ProjectsResponse.fromJson(data as Map<String, dynamic>);

  static List<ApiProject> projects(dynamic data) {
    return (data['projects'] as List).map((item) => ApiProject.fromJson(item)).toList();
  }

  static List<ApiTag> tags(dynamic data) {
    return (data['tags'] as List).map((item) => ApiTag.fromJson(item)).toList();
  }

  static List<ApiComment> comments(dynamic data) {
    return (data['comments'] as List).map((item) => ApiComment.fromJson(item)).toList();
  }

  static LikeResponse likeResponse(dynamic data) => LikeResponse.fromJson(data as Map<String, dynamic>);

  static Map<String, dynamic> simpleMap(dynamic data) => data as Map<String, dynamic>;

  static bool boolFromJson(dynamic data) {
    if (data is bool) {
      return data;
    } else if (data is String) {
      return data.toLowerCase() == 'true';
    } else if (data is int) {
      return data != 0;
    }
    return false;
  }

  static int intFromJson(dynamic data) {
    if (data is int) {
      return data;
    } else if (data is String) {
      return int.tryParse(data) ?? 0;
    }
    return 0;
  }
}
