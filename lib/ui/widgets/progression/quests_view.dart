import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/challenge_models.dart';
import '../../../data/models/progression_model.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/effects/effects.dart';
import '../../../providers/ad/reward_video_ad_controller.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenges_provider.dart';
import '../../../providers/progression_provider.dart';
import '../../screens/challenge_screen.dart';
import '../../screens/effect_store_screen.dart';
import '../../screens/my_challenge_entries_screen.dart';
import '../challenges/challenges_banner.dart';
import '../effects/effect_pack_l10n.dart';
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
      ProgressionEvent.animationGenerated => s.questAnimationGenerated(target),
      ProgressionEvent.imageExported => s.questImageExported(target),
      ProgressionEvent.animationExported => s.questAnimationExported(target),
      ProgressionEvent.projectImported => s.questProjectImported(target),
      ProgressionEvent.projectPublished => s.questProjectPublished(target),
      ProgressionEvent.templateUsed => s.questTemplateUsed(target),
      ProgressionEvent.imageImported => s.questImageImported(target),
      ProgressionEvent.animationStateAdded => s.questAnimationStateAdded(target),
      ProgressionEvent.fillUsed => s.questFillUsed(target),
      ProgressionEvent.shapeDrawn => s.questShapeDrawn(target),
      ProgressionEvent.projectLiked => s.questProjectLiked(target),
      ProgressionEvent.challengeEntered => s.questChallengeEntered(target),
      ProgressionEvent.oldProjectStroke => s.questOldProjectStroke(target),
      ProgressionEvent.dailyQuestClaimed => s.questDailyQuestClaimed(target),
    };
  }
}

extension QuestTierPresentation on QuestTier {
  String label(BuildContext context) {
    final s = Strings.of(context);
    return switch (this) {
      QuestTier.easy => s.questTierEasy,
      QuestTier.medium => s.questTierMedium,
      QuestTier.hard => s.questTierHard,
      QuestTier.bonus => s.questBonusTitle,
    };
  }

  Color color(ColorScheme colors) {
    return switch (this) {
      QuestTier.easy => Colors.green.shade600,
      QuestTier.medium => Colors.orange.shade700,
      QuestTier.hard => Colors.red.shade600,
      QuestTier.bonus => colors.primary,
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

  static const double _twoColumnBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final state = ref.watch(progressionProvider);
    // Open quests first, finished ones dimmed at the end.
    List<Quest> openFirst(Iterable<Quest> quests) => [
          ...quests.where((quest) => !state.isClaimed(quest)),
          ...quests.where(state.isClaimed),
        ];

    final starter = openFirst(QuestCatalog.starter);
    // One tier per chain: claimed tiers give way to the tier they unlock.
    final achievements = openFirst(
      QuestCatalog.achievements.where(
        (quest) =>
            state.isUnlocked(quest) && !(state.isClaimed(quest) && QuestCatalog.nextTier.containsKey(quest.id)),
      ),
    );

    final bonusQuest = state.bonusDailyQuest;
    final now = DateTime.now();
    final daysToNewWeek = 8 - now.weekday;
    final muted = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        );
    final today = [
      _LoginCycleCard(state: state),
      const SizedBox(height: 12),
      if (state.welcomeBackToday) ...[
        const _WelcomeBackCard(),
        const SizedBox(height: 12),
      ],
      const _SavingsGoalCard(),
      const SizedBox(height: 12),
      const _AdRewardCard(),
      const SizedBox(height: 20),
      const _ChallengesSection(),
      _SectionTitle(s.dailyQuestsTitle),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          s.questRerollsLeft(state.rerollsLeft),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ),
      for (final quest in state.mainDailyQuests) _QuestTile(quest: quest),
      const _AllDoneBonusCard(weekly: false),
      if (bonusQuest != null) ...[
        const SizedBox(height: 12),
        _SectionTitle(s.questBonusTitle),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            s.questBonusHint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ),
        _QuestTile(quest: bonusQuest),
      ],
      const SizedBox(height: 12),
      _SectionTitle(s.weeklyQuestsTitle),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s.weeklyResetsIn(daysToNewWeek), style: muted),
      ),
      for (final quest in state.weeklyQuests) _QuestTile(quest: quest),
      const _AllDoneBonusCard(weekly: true),
    ];
    final gettingStarted = [
      _SectionTitle(s.starterQuestsTitle),
      for (final quest in starter) _QuestTile(quest: quest),
      if (achievements.isNotEmpty) ...[
        const SizedBox(height: 20),
        _SectionTitle(s.achievementsTitle),
        for (final quest in achievements) _QuestTile(quest: quest),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on wide screens; a single readable column otherwise.
        final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;
        final maxWidth = twoColumns ? 1100.0 : 720.0;
        final horizontal = math.max(16.0, (constraints.maxWidth - maxWidth) / 2);
        final padding = EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24);

        if (!twoColumns) {
          return ListView(
            padding: padding,
            children: [...today, const SizedBox(height: 20), ...gettingStarted],
          );
        }
        return SingleChildScrollView(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: today)),
              const SizedBox(width: 24),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gettingStarted)),
            ],
          ),
        );
      },
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

/// Running challenges, so challenges and quests live in one place. Hidden
/// when none are running or they cannot be loaded.
class _ChallengesSection extends HookConsumerWidget {
  const _ChallengesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentChallengesProvider).valueOrNull;

    // Countdowns show minutes, so a redraw every 30 seconds is enough.
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick.value++);
      return timer.cancel;
    }, const []);

    final s = Strings.of(context);
    final signedIn = ref.watch(authProvider.select((auth) => auth.isSignedIn));
    final challenges = current?.running() ?? const <Challenge>[];
    // Signed-in users keep the section for "Your entries" between challenges.
    if (challenges.isEmpty && !signedIn) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _SectionTitle(s.challengesTitle)),
            if (signedIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  onPressed: () => MyChallengeEntriesScreen.show(context),
                  icon: const Icon(Icons.collections_outlined, size: 18),
                  label: Text(s.challengeYourEntries),
                ),
              ),
          ],
        ),
        if (current != null)
          for (final challenge in challenges)
            ChallengeTile(
              key: ValueKey('quests-challenge-${challenge.id}'),
              challenge: challenge,
              remaining: challenge.endsAt.difference(current.serverNow()),
              onTap: () => ChallengeScreen.show(context, challenge: challenge, serverNow: current.serverNow),
            ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// The repeating seven-day login cycle: today's reward, tomorrow's and the
/// big seventh day, paid automatically when the app is opened.
class _LoginCycleCard extends StatelessWidget {
  const _LoginCycleCard({required this.state});

  final ProgressionState state;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = state.loginCycleDay.clamp(1, LoginRewards.cycleLength);
    final tomorrow = today % LoginRewards.cycleLength + 1;
    final onCard = colors.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.streakTitle(state.streakDays),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: onCard),
                ),
              ),
              Text(
                s.loginCycleTomorrow(LoginRewards.coinsFor(tomorrow)),
                style: textTheme.labelMedium?.copyWith(color: onCard),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var day = 1; day <= LoginRewards.cycleLength; day++) ...[
                if (day > 1) const SizedBox(width: 6),
                Expanded(
                  flex: day == LoginRewards.cycleLength ? 2 : 1,
                  child: _LoginDay(
                    day: day,
                    coins: LoginRewards.coinsFor(day),
                    reached: day <= today,
                    isToday: day == today,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.loginCycleGrace,
            style: textTheme.labelSmall?.copyWith(color: onCard.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _LoginDay extends StatelessWidget {
  const _LoginDay({required this.day, required this.coins, required this.reached, required this.isToday});

  final int day;
  final int coins;
  final bool reached;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = reached ? colors.primary : colors.surface.withValues(alpha: 0.6);
    final foreground = reached ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: Colors.deepOrange, width: 2) : null,
      ),
      child: Column(
        children: [
          Text('$day', style: textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.bold)),
          FittedBox(
            child: GemAmount(coins, color: foreground, style: textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

/// The bonus for claiming all three main daily (or weekly) quests.
class _AllDoneBonusCard extends ConsumerWidget {
  const _AllDoneBonusCard({required this.weekly});

  final bool weekly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(progressionProvider);
    final quests = weekly ? state.weeklyQuests : state.mainDailyQuests;
    final claimedCount = quests.where(state.isClaimed).length;
    final alreadyPaid = weekly ? state.weeklyBonusClaimed : state.dailyBonusClaimed;
    final canClaim = weekly ? state.canClaimWeeklyBonus : state.canClaimDailyBonus;
    final bonus = weekly ? QuestCatalog.allWeeklyBonus : QuestCatalog.allDailyBonus;
    final onCard = colors.onPrimaryContainer;

    return Card(
      key: ValueKey(weekly ? 'weekly-bonus' : 'daily-bonus'),
      margin: const EdgeInsets.only(bottom: 8),
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(weekly ? Icons.emoji_events_outlined : Icons.card_giftcard, color: onCard),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekly ? s.weeklyBonusTitle : s.dailyBonusTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: onCard),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$claimedCount/${quests.length} · ${weekly ? s.weeklyBonusHint : s.dailyBonusHint}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onCard),
                      ),
                      GemAmount(bonus, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onCard)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (alreadyPaid)
              Icon(Icons.check_circle, color: colors.primary)
            else
              FilledButton(
                key: ValueKey(weekly ? 'claim-weekly-bonus' : 'claim-daily-bonus'),
                onPressed: canClaim
                    ? () {
                        final notifier = ref.read(progressionProvider.notifier);
                        final before = ref.read(progressionProvider).coins;
                        final paid = weekly ? notifier.claimWeeklyBonus() : notifier.claimDailyBonus();
                        if (!paid) return;
                        final earned = ref.read(progressionProvider).coins - before;
                        AppNotification.success(context, s.gemsReward(earned));
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

/// Shown the first day back after a long break: daily quests pay double.
class _WelcomeBackCard extends StatelessWidget {
  const _WelcomeBackCard();

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.waving_hand_outlined, color: colors.onTertiaryContainer),
        title: Text(
          s.welcomeBackTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.onTertiaryContainer),
        ),
        subtitle: Text(s.welcomeBackHint, style: TextStyle(color: colors.onTertiaryContainer)),
        trailing: Text('×2', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.onTertiaryContainer)),
      ),
    );
  }
}

/// The pack the user saves for: progress, and how long it takes at their
/// pace, so saving is visible progress rather than a far-off number.
class _SavingsGoalCard extends ConsumerWidget {
  const _SavingsGoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(progressionProvider);
    final goal = state.goalPack;
    final muted = textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7));

    if (goal == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.savings_outlined, color: colors.primary),
          title: Text(s.savingsGoalPick),
          trailing: TextButton(
            key: const ValueKey('pick-savings-goal'),
            onPressed: () => EffectStoreScreen.show(context),
            child: Text(s.savingsGoalPickAction),
          ),
        ),
      );
    }

    final price = state.packPrice(goal);
    final eta = state.goalEtaDays(DateTime.now());
    final ready = eta == 0;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => EffectStoreScreen.show(context, pack: goal),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.savings_outlined, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.savingsGoalTitle(goal.localizedName(context)),
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GemAmount(
                    price,
                    color: colors.primary,
                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: price <= 0 ? 1 : (state.coins / price).clamp(0.0, 1.0),
                  minHeight: 8,
                  color: colors.primary,
                  backgroundColor: colors.onSurface.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${state.coins.clamp(0, price)}/$price · ${switch (eta) {
                  0 => s.savingsGoalReady,
                  null => s.savingsGoalNoPace,
                  final days => s.savingsGoalEta(days),
                }}',
                style: ready ? textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.bold) : muted,
              ),
            ],
          ),
        ),
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
                  if (quest.tier case final tier? when tier != QuestTier.bonus)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tier.label(context).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: tier.color(colors),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                      ),
                    ),
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
            if (state.canReroll(quest))
              IconButton(
                key: ValueKey('reroll-${quest.id}'),
                tooltip: s.questReroll,
                icon: const Icon(Icons.autorenew),
                onPressed: () => ref.read(progressionProvider.notifier).rerollDaily(quest),
              ),
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
