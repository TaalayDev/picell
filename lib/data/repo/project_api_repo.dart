import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/utils/api_client.dart';
import '../models/api_models.dart';
import '../models/project_api_models.dart';

class ProjectAPIRepo {
  final ApiClient _apiClient;
  final Logger _logger = Logger('ProjectRepository');

  ProjectAPIRepo(this._apiClient);

  /// Create a new project
  Future<ApiResponse<ApiProject>> createProject({
    required String title,
    required String description,
    required int width,
    required int height,
    required String projectData,
    bool isPublic = true,
    List<String> tags = const [],
    Uint8List? thumbnailBytes,
  }) async {
    try {
      final formData = FormData();

      // Add basic project data
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('width', width.toString()),
        MapEntry('height', height.toString()),
        MapEntry('project_data', projectData),
        MapEntry('is_public', isPublic.toString()),
      ]);

      if (tags.isNotEmpty) {
        formData.fields.add(MapEntry('tags', tags.join(',')));
      }

      // Add thumbnail if provided
      if (thumbnailBytes != null) {
        formData.files.add(MapEntry(
          'thumbnail',
          MultipartFile.fromBytes(
            thumbnailBytes,
            filename: 'thumbnail.png',
            contentType: DioMediaType('image', 'png'),
          ),
        ));
      }

      return _apiClient.post<ApiProject>(
        '/api/v1/projects',
        data: formData,
        converter: (data) {
          print('Project created: ${data} ${data['project']}');
          return ProjectConverters.project(data['project']);
        },
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } catch (e) {
      _logger.severe('Error creating project: $e');
      rethrow;
    }
  }

  Future<ApiResponse<ApiProject>> updateProject({
    required int projectId,
    String? title,
    String? description,
    String? projectData,
    bool? isPublic,
    List<String>? tags,
    Uint8List? thumbnailBytes,
  }) async {
    try {
      final formData = FormData();

      // Add updated fields only
      if (title != null) formData.fields.add(MapEntry('title', title));
      if (description != null) formData.fields.add(MapEntry('description', description));
      if (projectData != null) formData.fields.add(MapEntry('project_data', projectData));
      if (isPublic != null) formData.fields.add(MapEntry('is_public', isPublic.toString()));

      if (tags != null) {
        formData.fields.add(MapEntry('tags', tags.join(',')));
      }

      // Add thumbnail if provided
      if (thumbnailBytes != null) {
        formData.files.add(MapEntry(
          'thumbnail',
          MultipartFile.fromBytes(
            thumbnailBytes,
            filename: 'thumbnail.png',
            contentType: DioMediaType('image', 'png'),
          ),
        ));
      }

      return _apiClient.post<ApiProject>(
        '/api/v1/projects/$projectId',
        data: formData,
        converter: (data) => ProjectConverters.project(data['project']),
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } catch (e) {
      _logger.severe('Error updating project $projectId: $e');
      rethrow;
    }
  }

  /// Delete a project
  Future<ApiResponse<Map<String, dynamic>>> deleteProject(int projectId) async {
    try {
      return _apiClient.delete<Map<String, dynamic>>(
        '/api/v1/projects/$projectId',
        converter: ProjectConverters.simpleMap,
      );
    } catch (e) {
      _logger.severe('Error deleting project $projectId: $e');
      rethrow;
    }
  }

  /// Get a single project by ID
  Future<ApiResponse<ApiProject>> getProject(int projectId, {bool includeData = false}) async {
    try {
      final params = <String, dynamic>{};
      if (includeData) {
        params['include_data'] = '1';
      }

      return _apiClient.get<ApiProject>(
        '/api/v1/projects/$projectId',
        params: params,
        converter: ProjectConverters.project,
      );
    } catch (e) {
      _logger.severe('Error getting project $projectId: $e');
      rethrow;
    }
  }

  /// Get list of projects with filters
  Future<ApiResponse<ProjectsResponse>> getProjects([ProjectFilters? filters]) async {
    try {
      final params = filters?.toQueryParams() ?? {};

      return _apiClient.get<ProjectsResponse>(
        '/api/v1/projects',
        params: {...params, 'debug': '1'},
        converter: ProjectConverters.projectsList,
      );
    } catch (e) {
      _logger.severe('Error getting projects: $e');
      rethrow;
    }
  }

  /// Get featured projects
  Future<ApiResponse<List<ApiProject>>> getFeaturedProjects({int limit = 10}) async {
    try {
      return _apiClient.get<List<ApiProject>>(
        '/api/v1/projects/featured',
        params: {'limit': limit},
        converter: ProjectConverters.projects,
      );
    } catch (e) {
      _logger.severe('Error getting featured projects: $e');
      rethrow;
    }
  }

  /// Get projects by username
  Future<ApiResponse<List<ApiProject>>> getUserProjects(String username) async {
    try {
      return _apiClient.get<List<ApiProject>>(
        '/api/v1/users/$username/projects',
        converter: ProjectConverters.projects,
      );
    } catch (e) {
      _logger.severe('Error getting projects for user $username: $e');
      rethrow;
    }
  }

  // Social Features

  /// Toggle like on a project
  Future<ApiResponse<LikeResponse>> toggleLike(int projectId) async {
    try {
      return _apiClient.post<LikeResponse>(
        '/api/v1/projects/$projectId/like',
        converter: ProjectConverters.likeResponse,
      );
    } catch (e) {
      _logger.severe('Error toggling like for project $projectId: $e');
      rethrow;
    }
  }

  // Comments

  /// Get comments for a project
  Future<ApiResponse<List<ApiComment>>> getComments(
    int projectId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return _apiClient.get<List<ApiComment>>(
        '/api/v1/projects/$projectId/comments',
        params: {
          'page': page,
          'limit': limit,
        },
        converter: ProjectConverters.comments,
      );
    } catch (e) {
      _logger.severe('Error getting comments for project $projectId: $e');
      rethrow;
    }
  }

  /// Add a comment to a project
  Future<ApiResponse<Map<String, dynamic>>> addComment(
    int projectId,
    String content, {
    int? parentId,
  }) async {
    try {
      final data = {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      };

      return _apiClient.post<Map<String, dynamic>>(
        '/api/v1/projects/$projectId/comments',
        data: data,
        converter: ProjectConverters.simpleMap,
      );
    } catch (e) {
      _logger.severe('Error adding comment to project $projectId: $e');
      rethrow;
    }
  }

  /// Update a comment
  Future<ApiResponse<Map<String, dynamic>>> updateComment(
    int commentId,
    String content,
  ) async {
    try {
      return _apiClient.put<Map<String, dynamic>>(
        '/api/v1/comments/$commentId',
        data: {'content': content},
        converter: ProjectConverters.simpleMap,
      );
    } catch (e) {
      _logger.severe('Error updating comment $commentId: $e');
      rethrow;
    }
  }

  /// Delete a comment
  Future<ApiResponse<Map<String, dynamic>>> deleteComment(int commentId) async {
    try {
      return _apiClient.delete<Map<String, dynamic>>(
        '/api/v1/comments/$commentId',
        converter: ProjectConverters.simpleMap,
      );
    } catch (e) {
      _logger.severe('Error deleting comment $commentId: $e');
      rethrow;
    }
  }

  // Tags

  /// Get popular tags
  Future<ApiResponse<List<ApiTag>>> getPopularTags({int limit = 20}) async {
    try {
      return _apiClient.get<List<ApiTag>>(
        '/api/v1/tags',
        params: {'limit': limit},
        converter: ProjectConverters.tags,
      );
    } catch (e) {
      _logger.severe('Error getting popular tags: $e');
      rethrow;
    }
  }

  /// Search tags
  Future<ApiResponse<List<ApiTag>>> searchTags(String query, {int limit = 20}) async {
    try {
      return _apiClient.get<List<ApiTag>>(
        '/api/v1/tags/search',
        params: {
          'q': query,
          'limit': limit,
        },
        converter: ProjectConverters.tags,
      );
    } catch (e) {
      _logger.severe('Error searching tags with query "$query": $e');
      rethrow;
    }
  }

  // Utility Methods

  /// Search projects with text query
  Future<ApiResponse<ProjectsResponse>> searchProjects(
    String query, {
    int page = 1,
    int limit = 20,
    String sort = 'popular',
  }) async {
    try {
      return getProjects(ProjectFilters(
        search: query,
        page: page,
        limit: limit,
        sort: sort,
      ));
    } catch (e) {
      _logger.severe('Error searching projects with query "$query": $e');
      rethrow;
    }
  }

  /// Get projects by size range
  Future<ApiResponse<ProjectsResponse>> getProjectsBySize({
    int? minWidth,
    int? maxWidth,
    int? minHeight,
    int? maxHeight,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return getProjects(ProjectFilters(
        minWidth: minWidth,
        maxWidth: maxWidth,
        minHeight: minHeight,
        maxHeight: maxHeight,
        page: page,
        limit: limit,
      ));
    } catch (e) {
      _logger.severe('Error getting projects by size: $e');
      rethrow;
    }
  }

  /// Get projects by tags
  Future<ApiResponse<ProjectsResponse>> getProjectsByTags(
    List<String> tags, {
    int page = 1,
    int limit = 20,
    String sort = 'popular',
  }) async {
    try {
      return getProjects(ProjectFilters(
        tags: tags,
        page: page,
        limit: limit,
        sort: sort,
      ));
    } catch (e) {
      _logger.severe('Error getting projects by tags $tags: $e');
      rethrow;
    }
  }

  /// Get trending projects (popular in the last week)
  Future<ApiResponse<ProjectsResponse>> getTrendingProjects({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      return getProjects(ProjectFilters(
        sort: 'popular',
        createdAfter: oneWeekAgo,
        page: page,
        limit: limit,
      ));
    } catch (e) {
      _logger.severe('Error getting trending projects: $e');
      rethrow;
    }
  }

  /// Get recent projects
  Future<ApiResponse<ProjectsResponse>> getRecentProjects({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return getProjects(ProjectFilters(
        sort: 'recent',
        page: page,
        limit: limit,
      ));
    } catch (e) {
      _logger.severe('Error getting recent projects: $e');
      rethrow;
    }
  }

  Future<List<ApiResponse<ApiProject>>> getProjectsBatch(List<int> projectIds) async {
    final results = <ApiResponse<ApiProject>>[];

    // Execute requests concurrently but limit to avoid overwhelming server
    const batchSize = 5;
    for (int i = 0; i < projectIds.length; i += batchSize) {
      final batch = projectIds.skip(i).take(batchSize);
      final futures = batch.map((id) => getProject(id)).toList();
      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);
    }

    return results;
  }
}
