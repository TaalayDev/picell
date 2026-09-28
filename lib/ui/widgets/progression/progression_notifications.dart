import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/strings.dart';
import '../../../providers/progression_provider.dart';
import '../../screens/effect_store_screen.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
