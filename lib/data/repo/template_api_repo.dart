import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/utils/api_client.dart';
import '../models/api_models.dart';
import '../models/template.dart';

class TemplateAPIRepo {
  final ApiClient _apiClient;
  final Logger _logger = Logger('TemplateAPIRepo');

  TemplateAPIRepo(this._apiClient);

  /// Upload a new template to the server
  Future<ApiResponse<Template>> uploadTemplate({
    required String name,
    required int width,
    required int height,
    required List<int> pixels,
    String? description,
    String? category,
    List<String> tags = const [],
    bool isPublic = true,
    Uint8List? thumbnailBytes,
  }) async {
    try {
      final formData = FormData();

      // Add template data
      formData.fields.addAll([
        MapEntry('name', name),
        MapEntry('width', width.toString()),
        MapEntry('height', height.toString()),
        MapEntry('pixels', pixels.join(',')),
        MapEntry('is_public', isPublic.toString()),
      ]);

      if (description != null) {
        formData.fields.add(MapEntry('description', description));
      }

      if (category != null) {
        formData.fields.add(MapEntry('category', category));
      }

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

      return _apiClient.post(
        '/api/v1/templates',
        data: formData,
        converter: (data) => Template.fromJson(data['template']),
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } catch (e) {
      _logger.severe('Error uploading template: $e');
      rethrow;
    }
  }

  /// Get templates with pagination and filters
  Future<ApiResponse<TemplatesResponse>> fetchTemplates({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String sort = 'popular',
    List<String>? tags,
    int? minWidth,
    int? maxWidth,
    int? minHeight,
    int? maxHeight,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };

    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    if (tags != null && tags.isNotEmpty) params['tags'] = tags.join(',');
    if (minWidth != null) params['min_width'] = minWidth;
    if (maxWidth != null) params['max_width'] = maxWidth;
    if (minHeight != null) params['min_height'] = minHeight;
    if (maxHeight != null) params['max_height'] = maxHeight;
    params['debug'] = '1'; // Debug parameter

    return _apiClient.get(
      '/api/v1/templates',
      params: params,
      converter: (data) => TemplatesResponse.fromJson(data),
    );
  }

  /// Get template by ID
  Future<ApiResponse<Template>> fetchTemplate(int templateId) async {
    try {
      return _apiClient.get<Template>(
        '/api/v1/templates/$templateId',
        converter: (data) => Template.fromJson(data['template']),
      );
    } catch (e) {
      _logger.severe('Error fetching template $templateId: $e');
      rethrow;
    }
  }

  /// Get template categories
  Future<ApiResponse<List<TemplateCategory>>> fetchCategories() async {
    try {
      return _apiClient.get<List<TemplateCategory>>(
        '/api/v1/templates/categories',
        converter: (data) => (data['categories'] as List).map((cat) => TemplateCategory.fromJson(cat)).toList(),
      );
    } catch (e) {
      _logger.severe('Error fetching template categories: $e');
      rethrow;
    }
  }

  /// Get featured templates
  Future<ApiResponse<List<Template>>> fetchFeaturedTemplates({
    int limit = 10,
  }) async {
    try {
      return _apiClient.get<List<Template>>(
        '/api/v1/templates/featured',
        params: {'limit': limit},
        converter: (data) => (data['templates'] as List).map((template) => Template.fromJson(template)).toList(),
      );
    } catch (e) {
      _logger.severe('Error fetching featured templates: $e');
      rethrow;
    }
  }

  /// Search templates
  Future<ApiResponse<TemplatesResponse>> searchTemplates(
    String query, {
    int page = 1,
    int limit = 20,
    String sort = 'relevance',
  }) async {
    try {
      return fetchTemplates(
        page: page,
        limit: limit,
        search: query,
        sort: sort,
      );
    } catch (e) {
      _logger.severe('Error searching templates with query "$query": $e');
      rethrow;
    }
  }

  /// Delete a template (only if owned by user)
  Future<ApiResponse<Map<String, dynamic>>> deleteTemplate(int templateId) async {
    try {
      return _apiClient.delete<Map<String, dynamic>>(
        '/api/v1/templates/$templateId',
        converter: (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      _logger.severe('Error deleting template $templateId: $e');
      rethrow;
    }
  }

  /// Toggle like on a template
  Future<ApiResponse<TemplateLikeResponse>> toggleLike(int templateId) async {
    try {
      return _apiClient.post<TemplateLikeResponse>(
        '/api/v1/templates/$templateId/like',
        converter: (data) => TemplateLikeResponse.fromJson(data),
      );
    } catch (e) {
      _logger.severe('Error toggling like for template $templateId: $e');
      rethrow;
    }
  }

  /// Get user's templates
  Future<ApiResponse<TemplatesResponse>> fetchUserTemplates({
    int page = 1,
    int limit = 20,
    String sort = 'recent',
  }) async {
    try {
      return _apiClient.get<TemplatesResponse>(
        '/api/v1/user/templates',
        params: {
          'page': page,
          'limit': limit,
          'sort': sort,
        },
        converter: (data) => TemplatesResponse.fromJson(data),
      );
    } catch (e) {
      _logger.severe('Error fetching user templates: $e');
      rethrow;
    }
  }
}

// Response models for API
class TemplatesResponse {
  final List<Template> templates;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  const TemplatesResponse({
    required this.templates,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasMore,
  });

  factory TemplatesResponse.fromJson(Map<String, dynamic> json) {
    return TemplatesResponse(
      templates: (json['templates'] as List).map((t) => Template.fromJson(t)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      hasMore: json['has_more'] ?? false,
    );
  }
}

class TemplateLikeResponse {
  final bool isLiked;
  final int totalLikes;

  const TemplateLikeResponse({
    required this.isLiked,
    required this.totalLikes,
  });

  factory TemplateLikeResponse.fromJson(Map<String, dynamic> json) {
    return TemplateLikeResponse(
      isLiked: json['is_liked'] ?? false,
      totalLikes: json['total_likes'] ?? 0,
    );
  }
}
