import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/strings.dart';
import '../../../data/models/challenge_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenges_provider.dart';
import '../../../providers/feedback_chat_provider.dart';
import '../../../providers/progression_provider.dart';
import '../../screens/effect_store_screen.dart';
import '../../screens/feedback_screen.dart';
import '../effects/effect_pack_l10n.dart';
import '../notifications/app_notification.dart';
import 'quests_view.dart';

/// Announces completed quests and streak rewards anywhere in the app.
///
/// Wraps the home route, which stays mounted under every other route, so its
/// context always reaches the root overlay and navigator.
class ProgressionNotifications extends ConsumerStatefulWidget {
  const ProgressionNotifications({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProgressionNotifications> createState() => _ProgressionNotificationsState();
}

class _ProgressionNotificationsState extends ConsumerState<ProgressionNotifications> {
  StreamSubscription<ProgressionNotice>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(progressionProvider.notifier).notices.listen(_show);
    // Rewards paid while the app was closed (challenge results, gifts).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(serverRewardsProvider).sync();
      // Replies the team wrote to the user's feedback while the app was closed.
      ref.read(feedbackRepliesProvider.notifier).check(force: true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _show(ProgressionNotice notice) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final s = Strings.of(context);

    switch (notice) {
      case QuestCompletedNotice(:final quest):
        AppNotification.success(
          context,
          s.questCompletedToast(quest.title(context)),
          duration: const Duration(seconds: 6),
          actionLabel: s.questClaim,
          onAction: () => navigator.push(EffectStoreScreen.route(tab: EffectStoreTab.quests)),
        );
      case StreakRewardNotice(:final days, :final coins):
        AppNotification.success(context, s.streakRewardToast(days, coins));
      case ServerRewardNotice(:final grant, :final pack):
        final title = grant.challengeTitle ?? (grant.challengeTag == null ? null : '#${grant.challengeTag}');
        final parts = [
          if (grant.gems > 0) s.serverRewardGems(grant.gems),
          if (pack != null) pack.localizedName(context),
        ];
        AppNotification.success(
          context,
          parts.join(' + '),
          title: switch (grant.reason) {
            RewardGrantReason.challengePlacement => s.serverRewardPlacementTitle(title ?? ''),
            RewardGrantReason.challengeMention => s.serverRewardMentionTitle(title ?? ''),
            RewardGrantReason.challengeParticipation => s.serverRewardParticipationTitle(title ?? ''),
            RewardGrantReason.manual || RewardGrantReason.unknown => s.serverRewardGiftTitle,
          },
          duration: const Duration(seconds: 6),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider.select((auth) => auth.isSignedIn), (wasSignedIn, isSignedIn) {
      if (isSignedIn && wasSignedIn != true) ref.read(serverRewardsProvider).sync(force: true);
    });
    ref.listen(feedbackRepliesProvider, (previous, unread) {
      if (unread <= (previous ?? 0) || !mounted) return;
      final s = Strings.of(context);
      AppNotification.info(
        context,
        s.feedback_reply_toast,
        duration: const Duration(seconds: 8),
        actionLabel: s.feedback_reply_open,
        onAction: () => FeedbackScreen.show(context),
      );
    });
    return widget.child;
  }
}
