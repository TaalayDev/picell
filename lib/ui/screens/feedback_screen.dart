import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/feedback_models.dart';
import '../../providers/feedback_providers.dart';
import '../../l10n/strings.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackNotifierProvider);
    final notifier = ref.read(feedbackNotifierProvider.notifier);
    final theme = Theme.of(context);
    final s = Strings.of(context);

    final feedbackQuestions = _getFeedbackQuestions(context);

    if (state.isSubmitted) {
      return Scaffold(
        appBar: AppBar(
          title: Text(s.feedback_title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  s.feedback_thank_you,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  s.feedback_thank_you_message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(s.feedback_return),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.feedback_title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _getCompletionProgress(feedbackQuestions, state),
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.feedback_help_us,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.feedback_intro,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (notifier.getAnsweredCount() > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          s.feedback_answered(
                            notifier.getAnsweredCount(),
                            feedbackQuestions.length,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...feedbackQuestions.map((question) {
                return _QuestionCard(
                  question: question,
                  key: ValueKey(question.id),
                );
              }),
              const SizedBox(height: 24),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isSubmitting ? null : () => _submitFeedback(context, ref, feedbackQuestions, state),
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(state.isSubmitting ? s.feedback_sending : s.feedback_send),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  double _getCompletionProgress(List<FeedbackQuestion> feedbackQuestions, FeedbackState state) {
    final requiredQuestions = feedbackQuestions.where((q) => q.isRequired).toList();
    if (requiredQuestions.isEmpty) return 1.0;

    final answeredRequired = requiredQuestions.where((q) => state.isQuestionAnswered(q.id)).length;

    return answeredRequired / requiredQuestions.length;
  }

  void _submitFeedback(
    BuildContext context,
    WidgetRef ref,
    List<FeedbackQuestion> feedbackQuestions,
    FeedbackState state,
  ) {
    final s = Strings.of(context);
    final notifier = ref.read(feedbackNotifierProvider.notifier);

    if (!_validateAnswers(feedbackQuestions, state)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.feedback_validation_error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    notifier.submitFeedback();
  }

  bool _validateAnswers(List<FeedbackQuestion> feedbackQuestions, FeedbackState state) {
    for (final question in feedbackQuestions) {
      if (question.isRequired && !state.isQuestionAnswered(question.id)) {
        return false;
      }
    }
    return true;
  }

  List<FeedbackQuestion> _getFeedbackQuestions(BuildContext context) {
    final s = Strings.of(context);
    return [
      FeedbackQuestion(
        id: 'satisfaction',
        question: s.feedback_q_satisfaction,
        type: QuestionType.rating,
        isRequired: true,
      ),
      FeedbackQuestion(
        id: 'missing_features',
        question: s.feedback_q_missing_features,
        type: QuestionType.textInput,
        placeholder: s.feedback_q_missing_features_placeholder,
      ),
      FeedbackQuestion(
        id: 'bug_reports',
        question: s.feedback_q_bug_reports,
        type: QuestionType.textInput,
        placeholder: s.feedback_q_bug_reports_placeholder,
      ),
      FeedbackQuestion(
        id: 'price_satisfaction',
        question: s.feedback_q_price_satisfaction,
        type: QuestionType.yesNo,
        isRequired: true,
      ),
      FeedbackQuestion(
        id: 'price_feedback',
        question: s.feedback_q_price_feedback,
        type: QuestionType.singleChoice,
        options: [
          s.feedback_q_price_free,
          s.feedback_q_price_up_to_5,
          s.feedback_q_price_5_to_10,
          s.feedback_q_price_10_to_20,
          s.feedback_q_price_more_20,
        ],
      ),
      FeedbackQuestion(
        id: 'patreon_support',
        question: s.feedback_q_patreon_support,
        type: QuestionType.singleChoice,
        options: [
          s.feedback_q_patreon_definitely,
          s.feedback_q_patreon_if_exclusive,
          s.feedback_q_patreon_if_reasonable,
          s.feedback_q_patreon_probably_not,
          s.feedback_q_patreon_no,
        ],
        isRequired: true,
      ),
      FeedbackQuestion(
        id: 'patreon_tier',
        question: s.feedback_q_patreon_tier,
        type: QuestionType.singleChoice,
        options: [
          s.feedback_q_patreon_tier_3,
          s.feedback_q_patreon_tier_5,
          s.feedback_q_patreon_tier_10,
        ],
      ),
      FeedbackQuestion(
        id: 'usage_frequency',
        question: s.feedback_q_usage_frequency,
        type: QuestionType.singleChoice,
        options: [
          s.feedback_q_usage_daily,
          s.feedback_q_usage_several_week,
          s.feedback_q_usage_once_week,
          s.feedback_q_usage_several_month,
          s.feedback_q_usage_rarely,
        ],
        isRequired: true,
      ),
      FeedbackQuestion(
        id: 'main_use_case',
        question: s.feedback_q_main_use_case,
        type: QuestionType.multiChoice,
        options: [
          s.feedback_q_use_pixel_art,
          s.feedback_q_use_game_design,
          s.feedback_q_use_animation,
          s.feedback_q_use_hobby,
          s.feedback_q_use_professional,
          s.feedback_q_use_learning,
        ],
      ),
      FeedbackQuestion(
        id: 'additional_feedback',
        question: s.feedback_q_additional_feedback,
        type: QuestionType.textInput,
        placeholder: s.feedback_q_additional_feedback_placeholder,
      ),
      FeedbackQuestion(
        id: 'recommend',
        question: s.feedback_q_recommend,
        type: QuestionType.rating,
        isRequired: true,
      ),
    ];
  }
}

class _QuestionCard extends ConsumerWidget {
  final FeedbackQuestion question;

  const _QuestionCard({required this.question, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = Strings.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question.question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (question.isRequired)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.feedback_required,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuestionInput(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(BuildContext context, WidgetRef ref) {
    switch (question.type) {
      case QuestionType.rating:
        return _RatingInput(questionId: question.id);
      case QuestionType.multiChoice:
        return _MultiChoiceInput(
          questionId: question.id,
          options: question.options!,
        );
      case QuestionType.singleChoice:
        return _SingleChoiceInput(
          questionId: question.id,
          options: question.options!,
        );
      case QuestionType.textInput:
        return _TextInput(
          questionId: question.id,
          placeholder: question.placeholder,
        );
      case QuestionType.yesNo:
        return _YesNoInput(questionId: question.id);
    }
  }
}

class _RatingInput extends ConsumerWidget {
  final String questionId;

  const _RatingInput({required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackNotifierProvider);
    final notifier = ref.read(feedbackNotifierProvider.notifier);
    final currentRating = state.getAnswer(questionId) as int?;
    final theme = Theme.of(context);
    final s = Strings.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = currentRating == rating;

            return GestureDetector(
              onTap: () => notifier.setAnswer(questionId, rating),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.feedback_very_poor,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              s.feedback_excellent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MultiChoiceInput extends ConsumerWidget {
  final String questionId;
  final List<String> options;

  const _MultiChoiceInput({
    required this.questionId,
    required this.options,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackNotifierProvider);
    final notifier = ref.read(feedbackNotifierProvider.notifier);
    final selectedOptions = state.getAnswer(questionId) as List<String>? ?? [];

    return Column(
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) => notifier.toggleMultiChoice(questionId, option),
          title: Text(option),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}

class _SingleChoiceInput extends ConsumerWidget {
  final String questionId;
  final List<String> options;

  const _SingleChoiceInput({
    required this.questionId,
    required this.options,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackNotifierProvider);
    final notifier = ref.read(feedbackNotifierProvider.notifier);
    final selectedOption = state.getAnswer(questionId) as String?;

    return Column(
      children: options.map((option) {
        final isSelected = selectedOption == option;
        return RadioListTile<String>(
          value: option,
          groupValue: selectedOption,
          onChanged: (value) => notifier.setAnswer(questionId, value),
          title: Text(option),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}

class _TextInput extends ConsumerWidget {
  final String questionId;
  final String? placeholder;

  const _TextInput({
    required this.questionId,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackNotifierProvider);
    final notifier = ref.read(feedbackNotifierProvider.notifier);
    final currentValue = state.getAnswer(questionId) as String? ?? '';

    return TextField(
      controller: TextEditingController(text: currentValue)
        ..selection = TextSelection.collapsed(offset: currentValue.length),
      onChanged: (value) => notifier.setAnswer(questionId, value),
      maxLines: 4,
      decoration: InputDecoration(
        hintText: placeholder ?? 'Введите ваш ответ...',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _YesNoInput extends ConsumerWidget {
  final String questionId;

  const _YesNoInput({required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackNotifierProvider);
    final notifier = ref.read(feedbackNotifierProvider.notifier);
    final currentValue = state.getAnswer(questionId) as bool?;
    final theme = Theme.of(context);
    final s = Strings.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => notifier.setAnswer(questionId, true),
            icon: Icon(
              currentValue == true ? Icons.check_circle : Icons.check_circle_outline,
            ),
            label: Text(s.feedback_yes),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: currentValue == true ? theme.colorScheme.primaryContainer : null,
              foregroundColor: currentValue == true ? theme.colorScheme.primary : null,
              side: BorderSide(
                color: currentValue == true ? theme.colorScheme.primary : theme.colorScheme.outline,
                width: currentValue == true ? 2 : 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => notifier.setAnswer(questionId, false),
            icon: Icon(
              currentValue == false ? Icons.cancel : Icons.cancel_outlined,
            ),
            label: Text(s.feedback_no),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: currentValue == false ? theme.colorScheme.errorContainer : null,
              foregroundColor: currentValue == false ? theme.colorScheme.error : null,
              side: BorderSide(
                color: currentValue == false ? theme.colorScheme.error : theme.colorScheme.outline,
                width: currentValue == false ? 2 : 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
