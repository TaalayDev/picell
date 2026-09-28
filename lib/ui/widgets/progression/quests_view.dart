import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/progression_model.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/effects/effects.dart';
import '../../../providers/ad/reward_video_ad_controller.dart';
import '../../../providers/progression_provider.dart';
import '../notifications/app_notification.dart';

extension QuestPresentation on Quest {
  String title(BuildContext context) {
    final s = Strings.of(context);
    return switch (event) {
      ProgressionEvent.projectCreated => s.questProjectCreated(target),
      ProgressionEvent.strokeCompleted => s.questStrokeCompleted(target),
      ProgressionEvent.layerAdded => s.questLayerAdded(target),
      ProgressionEvent.frameAdded => s.questFrameAdded(target),
      ProgressionEvent.effectAdded => s.questEffectAdded(target),
      ProgressionEvent.animationGenerated => s.questAnimationGenerated,
      ProgressionEvent.imageExported => s.questImageExported,
      ProgressionEvent.animationExported => s.questAnimationExported,
      ProgressionEvent.projectImported => s.questProjectImported,
      ProgressionEvent.projectPublished => s.questProjectPublished(target),
    };
  }
}

/// An amount of gems, drawn with an icon because pixel theme fonts have no emoji.
class GemAmount extends StatelessWidget {
  const GemAmount(this.amount, {super.key, this.style, this.color, this.prefix = ''});

  final int amount;
  final TextStyle? style;
  final Color? color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.diamond_outlined, size: (textStyle.fontSize ?? 14) + 2, color: textStyle.color),
        const SizedBox(width: 3),
        Text('$prefix$amount', style: textStyle),
      ],
    );
  }
}

/// Current gem balance.
class WalletChip extends ConsumerWidget {
  const WalletChip({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(progressionProvider.select((state) => state.coins));
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: Strings.of(context).walletTooltip,
      child: InkWell(
        key: const ValueKey('wallet-chip'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GemAmount(
            coins,
            color: colors.primary,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// Streak, daily and starter quests, and rewarded ads for gems.
class QuestsView extends ConsumerWidget {
  const QuestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final state = ref.watch(progressionProvider);
    final starter = [
      ...QuestCatalog.starter.where((quest) => !state.isClaimed(quest)),
      ...QuestCatalog.starter.where(state.isClaimed),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _StreakCard(streakDays: state.streakDays),
        const SizedBox(height: 12),
        const _AdRewardCard(),
        const SizedBox(height: 20),
        _SectionTitle(s.dailyQuestsTitle),
        for (final quest in state.dailyQuests) _QuestTile(quest: quest),
        const SizedBox(height: 20),
        _SectionTitle(s.starterQuestsTitle),
        for (final quest in starter) _QuestTile(quest: quest),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final next = StreakRewards.nextMilestone(streakDays);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.streakTitle(streakDays),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSecondaryContainer,
                      ),
                ),
                if (next != null)
                  Text(
                    s.streakNextReward(next, StreakRewards.coinsByDay[next]!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSecondaryContainer),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdRewardCard extends ConsumerWidget {
  const _AdRewardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final adReady = ref.watch(rewardVideoAdProvider);
    final adsLeft = CoinPrices.maxAdsPerDay - ref.watch(progressionProvider.select((state) => state.adsWatchedToday));

    // Rewarded ads only exist on mobile; the controller never loads elsewhere.
    if (!adReady && adsLeft == CoinPrices.maxAdsPerDay) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: Text(s.watchAdForCoins(CoinPrices.adReward)),
        subtitle: Text(s.adsLeftToday(adsLeft.clamp(0, CoinPrices.maxAdsPerDay).toInt())),
        trailing: FilledButton(
          onPressed: adReady && adsLeft > 0
              ? () async {
                  final earned = await ref.read(rewardVideoAdProvider.notifier).showAdIfLoaded();
                  if (earned) ref.read(progressionProvider.notifier).rewardAd();
                }
              : null,
          child: const Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}

class _QuestTile extends ConsumerWidget {
  const _QuestTile({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final state = ref.watch(progressionProvider);
    final colors = Theme.of(context).colorScheme;
    final progress = state.progressOf(quest);
    final claimed = state.isClaimed(quest);
    final canClaim = state.canClaim(quest);
    final rewardEffect = quest.rewardEffect;
    final detailStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.7),
        );

    return Card(
      key: ValueKey('quest-${quest.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title(context),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface.withValues(alpha: claimed ? 0.5 : 1),
                        ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / quest.target,
                      minHeight: 6,
                      // Explicit colors: some themes use the same color for track and bar.
                      color: colors.primary,
                      backgroundColor: colors.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('$progress/${quest.target}', style: detailStyle),
                      GemAmount(quest.coins, style: detailStyle),
                      if (rewardEffect != null)
                        Text(
                          s.questRewardEffect(EffectsManager.createEffect(rewardEffect).getName(context)),
                          style: detailStyle,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (claimed)
              Icon(Icons.check_circle, color: colors.primary)
            else
              FilledButton(
                key: ValueKey('claim-${quest.id}'),
                onPressed: canClaim
                    ? () {
                        final before = ref.read(progressionProvider).coins;
                        if (!ref.read(progressionProvider.notifier).claim(quest)) return;
                        // Pro owners get a multiplier, so report what was actually paid.
                        final earned = ref.read(progressionProvider).coins - before;
                        final effect = rewardEffect == null ? null : EffectsManager.createEffect(rewardEffect);
                        AppNotification.success(
                          context,
                          effect == null
                              ? s.gemsReward(earned)
                              : '${s.gemsReward(earned)} · ${s.effectUnlocked(effect.getName(context))}',
                        );
                      }
                    : null,
                child: Text(s.questClaim),
              ),
          ],
        ),
      ),
    );
  }
}
