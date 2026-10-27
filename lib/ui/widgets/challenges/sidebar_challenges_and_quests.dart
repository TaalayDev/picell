import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/progression_model.dart';
import '../../../l10n/strings.dart';
import '../../../providers/challenges_provider.dart';
import '../../../providers/progression_provider.dart';
import '../../screens/challenge_screen.dart';
import '../../screens/effect_store_screen.dart';
import '../progression/quests_view.dart';
import 'challenges_banner.dart';

/// A scrollable activity area for the desktop projects sidebar.
class SidebarChallengesAndQuests extends HookConsumerWidget {
  const SidebarChallengesAndQuests({super.key, required this.onStartDrawing});

  final VoidCallback onStartDrawing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentChallengesProvider).valueOrNull;
    final state = ref.watch(progressionProvider);
    final strings = Strings.of(context);
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick.value++);
      return timer.cancel;
    }, const []);

    void openQuests() => EffectStoreScreen.show(context, tab: EffectStoreTab.quests);

    return ListView(
      key: const ValueKey('sidebar-challenges-and-quests'),
      padding: const EdgeInsets.all(12),
      children: [
        if (current != null && current.running().isNotEmpty) ...[
          _SectionHeading(title: strings.challengesTitle, icon: Icons.emoji_events_outlined),
          for (final challenge in current.running())
            ChallengeTile(
              key: ValueKey('sidebar-challenge-${challenge.id}'),
              challenge: challenge,
              remaining: challenge.endsAt.difference(current.serverNow()),
              onTap: () => ChallengeScreen.show(
                context,
                challenge: challenge,
                serverNow: current.serverNow,
                onStartDrawing: onStartDrawing,
              ),
            ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(child: _SectionHeading(title: strings.dailyQuestsTitle, icon: Icons.task_alt)),
            WalletChip(onTap: openQuests),
          ],
        ),
        const SizedBox(height: 8),
        for (final quest in state.dailyQuests) _SidebarQuest(quest: quest),
        const SizedBox(height: 12),
        _SectionHeading(title: strings.weeklyQuestsTitle, icon: Icons.date_range_outlined),
        for (final quest in state.weeklyQuests) _SidebarQuest(quest: quest),
        TextButton.icon(
          key: const ValueKey('sidebar-open-quests'),
          onPressed: openQuests,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(strings.storeTabQuests),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ))),
        ],
      ),
    );
  }
}

class _SidebarQuest extends ConsumerWidget {
  const _SidebarQuest({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionProvider);
    final strings = Strings.of(context);
    final progress = state.progressOf(quest);
    final claimed = state.isClaimed(quest);
    final canClaim = state.canClaim(quest);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detailStyle = textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7));

    return Card(
      key: ValueKey('sidebar-quest-${quest.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(quest.title(context), style: textTheme.bodySmall?.copyWith(color: colors.onSurface)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress / quest.target),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('$progress / ${quest.target}', style: detailStyle)),
                if (claimed)
                  Text(strings.questClaimed, style: detailStyle)
                else if (canClaim)
                  TextButton(
                    onPressed: () => ref.read(progressionProvider.notifier).claim(quest),
                    child: Text(strings.questClaim),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
