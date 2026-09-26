import 'package:logging/logging.dart';

import '../../core/utils/api_client.dart';
import '../models/api_models.dart';
import '../models/discovery_api_models.dart';

class DiscoveryAPIRepo {
  final ApiClient _apiClient;
  final Logger _logger = Logger('DiscoveryAPIRepo');

  DiscoveryAPIRepo(this._apiClient);

  /// Cross-promo ads for the developer's other apps.
  Future<ApiResponse<List<PromoAppItem>>> getPromoApps({int limit = 20}) async {
    try {
      return _apiClient.get<List<PromoAppItem>>(
        '/api/v1/promo/apps',
        params: {'limit': limit},
        forceRefresh: true,
        converter: DiscoveryConverters.promoApps,
      );
    } catch (e) {
      _logger.severe('Error getting promo apps: $e');
      rethrow;
    }
  }

  /// Increment the backend click count for a cross-promo app.
  Future<ApiResponse<Map<String, dynamic>>> recordPromoAppClick(int appId) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/api/v1/promo/apps/$appId/click',
      converter: (data) => data as Map<String, dynamic>,
    );
  }

  /// Record the first time this installation sees a cross-promo app.
  Future<ApiResponse<Map<String, dynamic>>> recordPromoAppImpression(
    int appId,
    String installationId,
  ) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/api/v1/promo/apps/$appId/impression',
      data: {'installation_id': installationId},
      converter: (data) => data as Map<String, dynamic>,
    );
  }

  /// News / announcements for the discovery carousel.
  Future<ApiResponse<List<NewsItemModel>>> getNews({int limit = 20}) async {
    try {
      return _apiClient.get<List<NewsItemModel>>(
        '/api/v1/news',
        params: {'limit': limit},
        forceRefresh: true,
        converter: DiscoveryConverters.newsItems,
      );
    } catch (e) {
      _logger.severe('Error getting news: $e');
      rethrow;
    }
  }
}
