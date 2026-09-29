import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/utils/api_client.dart';
import '../models/api_models.dart';
import '../models/challenge_models.dart';
import '../models/project_api_models.dart';

class ChallengeAPIRepo {
  final ApiClient _apiClient;
  final Logger _logger = Logger('ChallengeAPIRepo');

  ChallengeAPIRepo(this._apiClient);

  /// Active challenges for the home banner, with titles in [languageCode].
  Future<ApiResponse<CurrentChallenges>> getCurrent({required String languageCode}) async {
    try {
      return _apiClient.get<CurrentChallenges>(
        '/api/v1/challenges/current',
        options: Options(headers: {'Accept-Language': languageCode}),
        forceRefresh: true,
        converter: (data) => CurrentChallenges.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      _logger.severe('Error getting current challenges: $e');
      rethrow;
    }
  }

  /// One challenge with rules, rewards, the user's entries and its winners.
  Future<ApiResponse<ChallengeDetails>> getChallenge(int id, {required String languageCode}) async {
    try {
      return _apiClient.get<ChallengeDetails>(
        '/api/v1/challenges/$id',
        options: Options(headers: {'Accept-Language': languageCode}),
        forceRefresh: true,
        converter: (data) =>
            ChallengeDetails.tryParse(data as Map<String, dynamic>) ??
            (throw const FormatException('Unsupported challenge')),
      );
    } catch (e) {
      _logger.severe('Error getting challenge $id: $e');
      rethrow;
    }
  }

  /// Accepted and winning entries of a challenge, a page at a time.
  /// [sort] is `recent` or `winners`.
  Future<ApiResponse<ProjectsResponse>> getEntries(
    int id, {
    required String sort,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return _apiClient.get<ProjectsResponse>(
        '/api/v1/challenges/$id/entries',
        params: {'sort': sort, 'page': page, 'limit': limit},
        forceRefresh: true,
        converter: ProjectConverters.projectsList,
      );
    } catch (e) {
      _logger.severe('Error getting entries of challenge $id: $e');
      rethrow;
    }
  }

  /// Rewards the server paid to the signed-in user, newest first.
  Future<ApiResponse<List<RewardGrant>>> getMyGrants({required String languageCode}) async {
    try {
      return _apiClient.get<List<RewardGrant>>(
        '/api/v1/me/grants',
        options: Options(headers: {'Accept-Language': languageCode}),
        forceRefresh: true,
        converter: (data) => [
          for (final item in (data as Map<String, dynamic>)['grants'] as List? ?? const [])
            if (RewardGrant.tryParse(item) case final grant?) grant,
        ],
      );
    } catch (e) {
      _logger.severe('Error getting reward grants: $e');
      rethrow;
    }
  }

  /// Marks a grant claimed. Safe to repeat; fails once a grant is revoked.
  Future<ApiResponse<RewardGrant>> claimGrant(String id) async {
    try {
      return _apiClient.post<RewardGrant>(
        '/api/v1/me/grants/$id/claim',
        converter: (data) =>
            RewardGrant.tryParse((data as Map<String, dynamic>)['grant']) ??
            (throw const FormatException('Unsupported grant')),
      );
    } catch (e) {
      _logger.severe('Error claiming reward grant $id: $e');
      rethrow;
    }
  }

  /// The signed-in user's entries in every challenge, newest first.
  Future<ApiResponse<List<MyChallengeEntry>>> getMyEntries({required String languageCode}) async {
    try {
      return _apiClient.get<List<MyChallengeEntry>>(
        '/api/v1/me/challenge-entries',
        options: Options(headers: {'Accept-Language': languageCode}),
        forceRefresh: true,
        converter: (data) => [
          for (final item in (data as Map<String, dynamic>)['entries'] as List? ?? const [])
            if (MyChallengeEntry.tryParse(item) case final entry?) entry,
        ],
      );
    } catch (e) {
      _logger.severe('Error getting my challenge entries: $e');
      rethrow;
    }
  }
}
