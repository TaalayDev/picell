import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_io/io.dart';

import '../data/models/feedback_chat_models.dart';
import '../data/models/feedback_models.dart';
import 'feedback_chat_provider.dart';
import 'providers.dart';

part 'feedback_providers.g.dart';

@riverpod
class FeedbackNotifier extends _$FeedbackNotifier {
  @override
  FeedbackState build() {
    return const FeedbackState();
  }

  /// Установить ответ на вопрос
  void setAnswer(String questionId, dynamic value) {
    final newAnswers = Map<String, dynamic>.from(state.answers);
    newAnswers[questionId] = value;

    state = state.copyWith(
      answers: newAnswers,
      errorMessage: null,
    );
  }

  /// Переключить значение в multi-choice вопросе
  void toggleMultiChoice(String questionId, String option) {
    final currentAnswers = state.getAnswer(questionId) as List<String>? ?? [];
    final newAnswers = List<String>.from(currentAnswers);

    if (newAnswers.contains(option)) {
      newAnswers.remove(option);
    } else {
      newAnswers.add(option);
    }

    setAnswer(questionId, newAnswers);
  }

  Future<void> submitFeedback() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await _sendFeedbackToServer(state.answers);

      state = state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Ошибка при отправке: ${e.toString()}',
      );
    }
  }

  Future<void> _sendFeedbackToServer(Map<String, dynamic> answers) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      final feedbackData = {
        'answers': answers,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': await _getAppVersion(),
        'platform': _getPlatform(),
      };

      final response = await apiClient.post<Map<String, dynamic>>(
        '/api/v1/feedback',
        data: feedbackData,
        converter: (data) => data as Map<String, dynamic>,
      );

      if (response.error != null) {
        throw Exception(response.error);
      }

      // The conversation about this feedback opens right after sending.
      final data = response.data;
      final thread = data == null ? null : FeedbackThreadRef.tryParse({'id': data['id'], 'token': data['thread_token']});
      if (thread != null) ref.read(feedbackThreadsProvider.notifier).add(thread);

      ref.read(localStorageProvider).feedbackPromptNeverAskAgain = true;

      debugPrint('Feedback sent successfully: ${response.data}');
    } catch (e) {
      debugPrint('Error sending feedback: $e');
      rethrow;
    }
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  String _getPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }

  void reset() {
    state = const FeedbackState();
  }

  /// Получить количество заполненных вопросов
  int getAnsweredCount() {
    return state.answers.length;
  }
}
