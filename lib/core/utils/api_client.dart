import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:tf_dio_cache/tf_dio_cache.dart';

import '../../data.dart';
import '../../data/models/api_models.dart';

class ApiClient {
  final Dio _dio;
  final Logger _logger;
  final DioCacheManager cacheManager;

  ApiClient._(this._dio, this.cacheManager) : _logger = Logger('ApiClient');

  factory ApiClient(
    String baseUrl, {
    required LocalStorage storage,
    List<Interceptor> interceptors = const [],
  }) {
    final cacheManager = DioCacheManager(CacheConfig(
      defaultMaxAge: const Duration(days: 7),
      baseUrl: baseUrl,
    ));
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    dio.interceptors.add(cacheManager.interceptor);
    dio.interceptors.addAll(interceptors);

    return ApiClient._(dio, cacheManager);
  }

  Future<ApiResponse<T>> get<T>(
    String url, {
    Map<String, dynamic>? params,
    Options? options,
    Duration? cacheMaxAge,
    required T Function(dynamic data) converter,
  }) {
    return request<T>(
      url,
      'get',
      converter: converter,
      params: params,
      options: buildCacheOptions(
        cacheMaxAge ?? _cacheMaxAgeFor(url),
        options: options,
      ),
    );
  }

  Future<ApiResponse<T>> post<T>(
    String url, {
    T Function(dynamic data)? converter,
    dynamic data,
    Options? options,
  }) {
    return request<T>(
      url,
      'POST',
      converter: converter,
      data: data,
      options: options,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String url, {
    T Function(dynamic data)? converter,
    dynamic data,
    Options? options,
  }) {
    return request<T>(
      url,
      'PUT',
      converter: converter,
      data: data,
      options: options,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String url, {
    T Function(dynamic data)? converter,
    dynamic data,
  }) {
    return request<T>(
      url,
      'PATCH',
      converter: converter,
      data: data,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String url, {
    T Function(dynamic data)? converter,
    dynamic params,
  }) {
    return request<T>(
      url,
      'DELETE',
      converter: converter,
      params: params,
    );
  }

  Future<ApiResponse<T>> request<T>(
    String url,
    String method, {
    required T Function(dynamic data)? converter,
    Map<String, dynamic>? params,
    dynamic data,
    Options? options,
  }) async {
    try {
      final opt = options ?? Options();
      final response = await _dio.request(
        url,
        queryParameters: params,
        data: data,
        options: opt.copyWith(method: method, headers: {
          ..._dio.options.headers,
          ...?opt.headers,
        }),
      );

      _logger.info(
        'request $url \nstatus-code:${response.statusCode};',
      );

      if (response.data is! Map<String, dynamic>) {
        _logger.warning('Response data is not a Map: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        return ApiResponse<T>(
          success: true,
          data: converter?.call(responseData['data']),
          error: null,
          details: null,
          timestamp: responseData['timestamp'] ??
              DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          data: null,
          error: responseData['error']?.toString() ?? 'Unknown error',
          details: responseData['details'],
          timestamp: responseData['timestamp'] ??
              DateTime.now().millisecondsSinceEpoch,
        );
      }
    } on DioException catch (e) {
      _logger
          .warning('Request failed: $method $url - ${e.response?.statusCode}');
      _logger.warning('Error data: ${e.response?.data}');

      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        LocalStorage().clearToken();
      }

      String errorMessage = 'Network error';
      dynamic details;

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        errorMessage = errorData['error']?.toString() ??
            errorData['message']?.toString() ??
            'Server error';
        details = errorData['details'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      return ApiResponse<T>(
        success: false,
        data: null,
        error: errorMessage,
        details: details,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e, trace) {
      _logger.severe('Unexpected error: $method $url', e, trace);

      return ApiResponse<T>(
        success: false,
        data: null,
        error: 'Unexpected error: ${e.toString()}',
        details: null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  static Duration _cacheMaxAgeFor(String url) {
    if (url == '/api/v1/projects' ||
        url == '/api/v1/projects/featured' ||
        url == '/api/v1/promo/apps' ||
        url == '/api/v1/news' ||
        url.contains('/forks')) {
      return const Duration(minutes: 5);
    }

    if (url.contains('/thumbnail')) {
      return const Duration(days: 7);
    }

    return const Duration(minutes: 15);
  }
}
