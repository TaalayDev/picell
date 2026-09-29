import 'package:dio/dio.dart';

import '../../core/utils/api_client.dart';
import '../models/api_models.dart';
import '../models/feedback_chat_models.dart';

/// The conversation about a feedback submission. Every call is authorized by
/// the thread's token (sent as `X-Feedback-Token`), so it works for
/// anonymous feedback too.
class FeedbackAPIRepo {
  FeedbackAPIRepo(this._apiClient);

  final ApiClient _apiClient;

  Options _auth(FeedbackThreadRef thread) => Options(headers: {'X-Feedback-Token': thread.token});

  /// Messages after [afterId]; the server marks the team's messages read.
  Future<ApiResponse<FeedbackThreadPage>> getThread(FeedbackThreadRef thread, {int afterId = 0}) {
    return _apiClient.get<FeedbackThreadPage>(
      '/api/v1/feedback/${thread.id}/thread',
      params: {'after_id': afterId},
      options: _auth(thread),
      forceRefresh: true,
      converter: (data) => FeedbackThreadPage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// How many replies from the team the user has not seen yet.
  Future<ApiResponse<int>> getUnread(FeedbackThreadRef thread) {
    return _apiClient.get<int>(
      '/api/v1/feedback/${thread.id}/unread',
      options: _auth(thread),
      forceRefresh: true,
      converter: (data) => (data as Map<String, dynamic>)['unread'] as int? ?? 0,
    );
  }

  Future<ApiResponse<FeedbackChatMessage?>> sendMessage(FeedbackThreadRef thread, String body) {
    return _apiClient.post<FeedbackChatMessage?>(
      '/api/v1/feedback/${thread.id}/messages',
      data: {'body': body},
      options: _auth(thread),
      converter: (data) => FeedbackChatMessage.tryParse((data as Map<String, dynamic>)['message']),
    );
  }
}
