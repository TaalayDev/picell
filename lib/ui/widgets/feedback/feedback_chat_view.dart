import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/feedback_chat_models.dart';
import '../../../l10n/strings.dart';
import '../../../providers/feedback_chat_provider.dart';
import '../notifications/app_notification.dart';

/// The conversation about a sent feedback: the team's replies and the
/// user's messages, with a field to write more. Not real time; new replies
/// are fetched every few seconds while it is open.
class FeedbackChatView extends HookConsumerWidget {
  const FeedbackChatView({super.key, required this.thread});

  final FeedbackThreadRef thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(feedbackChatProvider(thread));
    final notifier = ref.read(feedbackChatProvider(thread).notifier);
    final input = useTextEditingController();
    final scroll = useScrollController();
    final hasText = useListenableSelector(input, () => input.text.trim().isNotEmpty);

    // Keep the newest message in view when messages arrive.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
      });
      return null;
    }, [state.messages.length]);

    Future<void> send() async {
      final text = input.text;
      if (text.trim().isEmpty) return;
      final sent = await notifier.send(text);
      if (!context.mounted) return;
      if (sent) {
        input.clear();
      } else {
        AppNotification.error(context, s.feedback_chat_send_failed);
      }
    }

    Widget body;
    if (state.isLoading && state.messages.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.loadFailed) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(s.feedback_chat_load_failed),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: notifier.refresh, child: Text(s.tryAgain)),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          controller: scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            _SystemNote(
              icon: Icons.check_circle_outline,
              text: state.submittedAt == null
                  ? s.feedback_chat_submitted
                  : '${s.feedback_chat_submitted} · ${DateFormat.yMMMd().format(state.submittedAt!.toLocal())}',
            ),
            _SystemNote(icon: Icons.forum_outlined, text: s.feedback_chat_intro),
            for (final message in state.messages) _MessageBubble(message: message),
            if (state.isClosed) _SystemNote(icon: Icons.lock_outline, text: s.feedback_chat_closed),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: body),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: s.feedback_chat_hint,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: s.feedback_chat_send,
                  onPressed: hasText && !state.isSending ? send : null,
                  icon: state.isSending
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final FeedbackChatMessage message;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mine = message.isMine;
    final time = DateFormat.MMMd().add_Hm().format(message.createdAt.toLocal());

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!mine)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.author ?? s.feedback_chat_team,
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: mine ? colors.primary : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(mine ? 16 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SelectableText(
                    message.body,
                    style: theme.textTheme.bodyMedium?.copyWith(color: mine ? colors.onPrimary : colors.onSurface),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: muted))),
        ],
      ),
    );
  }
}
