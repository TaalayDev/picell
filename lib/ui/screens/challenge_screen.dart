import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/challenge_models.dart';
import '../../data/models/project_api_models.dart';
import '../../l10n/strings.dart';
import '../../pixel/effects/effect_pack_catalog.dart';
import '../../providers/challenges_provider.dart';
import '../widgets/challenges/challenges_banner.dart';
import '../widgets/community_project_card.dart';
import '../widgets/effects/effect_pack_l10n.dart';
import '../widgets/notifications/app_notification.dart';
import '../widgets/progression/quests_view.dart';
import 'project_detail_screen.dart';

/// A challenge: its theme, how to join, rewards, the user's entries, the
/// winners once judged, and a gallery of every accepted entry.
class ChallengeScreen extends HookConsumerWidget {
  const ChallengeScreen({
    super.key,
    required this.challengeId,
    this.initial,
    this.initialServerNow,
    this.onStartDrawing,
    this.inDialog = false,
  });

  final int challengeId;

  /// Shown until the full details load, such as the banner's copy.
  final Challenge? initial;
  final DateTime Function()? initialServerNow;

  /// Opens a new project; the screen closes first.
  final VoidCallback? onStartDrawing;

  /// Shown in a dialog on desktop: the app bar gets a close button.
  final bool inDialog;

  static const double _maxContentWidth = 1100;

  /// Screens at least this wide open the challenge as a dialog.
  static const double dialogBreakpoint = 800;

  static Future<void> show(
    BuildContext context, {
    required Challenge challenge,
    DateTime Function()? serverNow,
    VoidCallback? onStartDrawing,
  }) {
    return open(
      context,
      challengeId: challenge.id,
      initial: challenge,
      serverNow: serverNow,
      onStartDrawing: onStartDrawing,
    );
  }

  /// A full page on phones, a dialog on wide screens.
  static Future<void> open(
    BuildContext context, {
    required int challengeId,
    Challenge? initial,
    DateTime Function()? serverNow,
    VoidCallback? onStartDrawing,
  }) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= dialogBreakpoint) {
      return showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(32),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 960, maxHeight: size.height * 0.9),
            child: ChallengeScreen(
              challengeId: challengeId,
              initial: initial,
              initialServerNow: serverNow,
              onStartDrawing: onStartDrawing,
              inDialog: true,
            ),
          ),
        ),
      );
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeScreen(
          challengeId: challengeId,
          initial: initial,
          initialServerNow: serverNow,
          onStartDrawing: onStartDrawing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final details = ref.watch(challengeDetailsProvider(challengeId));
    final challenge = details.valueOrNull?.challenge ?? initial;
    final serverNow = details.valueOrNull?.serverNow ?? initialServerNow ?? DateTime.now;

    // Countdowns show minutes, so a redraw every 30 seconds is enough.
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick.value++);
      return timer.cancel;
    }, const []);

    final sort = useState(ChallengeEntrySort.recent);
    final entriesKey = (challengeId: challengeId, sort: sort.value);
    final entries = ref.watch(challengeEntriesProvider(entriesKey));

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !inDialog,
          leading: inDialog ? const CloseButton() : null,
        ),
        body: details.hasError
            ? _ErrorView(
                message: s.challengeLoadFailed,
                onRetry: () => ref.invalidate(challengeDetailsProvider(challengeId)),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    Future<void> refresh() async {
      ref.invalidate(challengeDetailsProvider(challengeId));
      await ref.read(challengeEntriesProvider(entriesKey).notifier).refresh();
    }

    void openProject(ApiProject project) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 600) {
              ref.read(challengeEntriesProvider(entriesKey).notifier).loadMore();
            }
            return false;
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = math.max(16.0, (constraints.maxWidth - _maxContentWidth) / 2);
              final contentWidth = constraints.maxWidth - horizontal * 2;
              final columns = switch (contentWidth) {
                < 500 => 2,
                < 800 => 3,
                < 1000 => 4,
                _ => 5,
              };
              SliverPadding padded(Widget sliver, {double top = 0, double bottom = 0}) => SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
                    sliver: sliver,
                  );

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: !inDialog,
                    leading: inDialog ? const CloseButton() : null,
                    // No cover, no big header: nothing to fill it with.
                    expandedHeight: challenge.hasCover ? math.min(constraints.maxWidth / 2, 280) : null,
                    flexibleSpace: !challenge.hasCover
                        ? null
                        : FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          ChallengeCover(url: challenge.coverImageUrl),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                                stops: const [0, 0.4],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  padded(
                    SliverToBoxAdapter(child: _ChallengeHeader(challenge: challenge, serverNow: serverNow())),
                    top: 16,
                  ),
                  if (challenge.winners.isNotEmpty) ...[
                    padded(SliverToBoxAdapter(child: _SectionTitle(s.challengeWinnersTitle)), top: 8),
                    padded(
                      SliverMasonryGrid.count(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childCount: challenge.winners.length,
                        itemBuilder: (context, index) {
                          final winner = challenge.winners[index];
                          return _PlacedCard(
                            key: ValueKey('winner-${winner.project.id}'),
                            label: winner.place == null ? s.challengeMention : s.challengePlace(winner.place!),
                            highlight: winner.place == 1,
                            child: CommunityProjectCard(
                              project: winner.project,
                              onTap: () => openProject(winner.project),
                            ),
                          );
                        },
                      ),
                      bottom: 8,
                    ),
                  ],
                  padded(
                    SliverToBoxAdapter(
                      child: _EntriesHeader(
                        count: challenge.entryCount,
                        showSort: challenge.isCompleted,
                        sort: sort.value,
                        onSortChanged: (value) => sort.value = value,
                      ),
                    ),
                    top: 8,
                  ),
                  if (entries.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (entries.projects.isEmpty)
                    padded(
                      SliverToBoxAdapter(
                        child: entries.error != null
                            ? _ErrorView(
                                message: s.challengeEntriesLoadFailed,
                                onRetry: () => ref.read(challengeEntriesProvider(entriesKey).notifier).refresh(),
                              )
                            : _EmptyEntries(message: s.challengeNoEntriesYet),
                      ),
                    )
                  else
                    padded(
                      SliverMasonryGrid.count(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childCount: entries.projects.length,
                        itemBuilder: (context, index) {
                          final project = entries.projects[index];
                          return CommunityProjectCard(
                            key: ValueKey('entry-${project.id}'),
                            project: project,
                            onTap: () => openProject(project),
                            onLike: (project) =>
                                ref.read(challengeEntriesProvider(entriesKey).notifier).toggleLike(project),
                          );
                        },
                      ),
                      top: 8,
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 96,
                      child: entries.isLoadingMore ? const Center(child: CircularProgressIndicator()) : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: challenge.isActive && onStartDrawing != null
          ? SafeArea(
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      key: const ValueKey('challenge-start-drawing'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.brush_outlined),
                      label: Text(s.challengeStartDrawing),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onStartDrawing!();
                      },
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Status, title, description, how to join, rules, rewards, the user's entries.
class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader({required this.challenge, required this.serverNow});

  final Challenge challenge;
  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final canJoin = challenge.status == 'active' || challenge.status == 'scheduled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(challengeCadenceLabel(context, challenge.cadence)),
              visualDensity: VisualDensity.compact,
            ),
            if (challenge.isCompetition)
              Chip(
                avatar: const Icon(Icons.emoji_events_outlined, size: 16),
                label: Text(s.challengeCompetition),
                visualDensity: VisualDensity.compact,
              ),
            Text(_statusText(context), style: textTheme.bodySmall),
            Text(s.challengeEntries(challenge.entryCount), style: textTheme.bodySmall),
            if (challenge.joined)
              Chip(
                avatar: const Icon(Icons.check, size: 16),
                label: Text(s.challengeJoined),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(challenge.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        if (challenge.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(challenge.description, style: textTheme.bodyMedium),
        ],
        if (canJoin) ...[
          _SectionTitle(s.challengeHowToJoin),
          Text(s.challengeJoinSteps, style: textTheme.bodyMedium),
          const SizedBox(height: 10),
          _TagBox(tag: challenge.tag),
        ],
        _SectionTitle(s.challengeRulesTitle),
        _Bullet(s.challengeRuleMaxEntries(challenge.maxEntriesPerUser)),
        _Bullet(s.challengeRuleStartsAfter),
        if (_requiredPackName(context) case final pack?) _Bullet(s.challengeRuleRequiredPack(pack)),
        _Bullet(switch (challenge) {
          Challenge(isCompetition: true) => s.challengeRuleCompetition,
          Challenge(participationGems: > 0) => s.challengeRuleNoWinners,
          _ => s.challengeRuleJustForFun,
        }),
        if (challenge.participationGems > 0 || challenge.placements.isNotEmpty) ...[
          _SectionTitle(s.challengeRewards),
          for (final reward in challenge.placements)
            _RewardRow(
              label: s.challengePlace(reward.place),
              gems: reward.gems,
              effectPack: reward.effectPack != null,
            ),
          if (challenge.participationGems > 0)
            _RewardRow(
              label: challenge.isCompetition ? s.challengeParticipationReward : s.challengeAcceptedEntryReward,
              gems: challenge.participationGems,
            ),
        ],
        if (challenge.myEntries.isNotEmpty) ...[
          _SectionTitle(s.challengeYourEntries),
          for (final (index, entry) in challenge.myEntries.indexed) _MyEntryRow(number: index + 1, entry: entry),
        ],
        if (challenge.myRewards.isNotEmpty || (challenge.joined && challenge.topGems > 0)) ...[
          _SectionTitle(s.challengeYourReward),
          _MyRewards(challenge: challenge),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  String _statusText(BuildContext context) {
    final s = Strings.of(context);
    return switch (challenge.status) {
      'scheduled' => s.challengeStartsIn(formatChallengeRemaining(context, challenge.startsAt.difference(serverNow))),
      'active' => s.challengeEndsIn(formatChallengeRemaining(context, challenge.endsAt.difference(serverNow))),
      'judging' => challenge.judgingEndsAt == null
          ? s.challengeStatusJudging
          : '${s.challengeStatusJudging} · ${s.challengeResultsBy(_formatDate(context, challenge.judgingEndsAt!))}',
      'cancelled' => s.challengeStatusCancelled,
      _ => s.challengeStatusCompleted,
    };
  }

  String _formatDate(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date.toLocal());

  String? _requiredPackName(BuildContext context) {
    final name = challenge.requiredPack;
    if (name == null) return null;
    final pack = EffectPackId.values.where((id) => id.name == name).firstOrNull;
    return pack?.localizedName(context) ?? name;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: textTheme.bodyMedium),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// The challenge tag, copyable, so users can paste it or recognise it later.
class _TagBox extends StatelessWidget {
  const _TagBox({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              '#$tag',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            key: const ValueKey('copy-challenge-tag'),
            tooltip: s.challengeCopyTag,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: tag));
              if (context.mounted) AppNotification.success(context, s.challengeTagCopied);
            },
          ),
        ],
      ),
    );
  }
}

/// The user's rewards from this challenge with a claim button, or what they
/// are waiting for when nothing is paid yet.
class _MyRewards extends ConsumerStatefulWidget {
  const _MyRewards({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_MyRewards> createState() => _MyRewardsState();
}

class _MyRewardsState extends ConsumerState<_MyRewards> {
  /// Grants claimed from this screen, shown as received until it reloads.
  final _claimed = <String>{};
  String? _claiming;

  Future<void> _claim(RewardGrant grant) async {
    setState(() => _claiming = grant.id);
    final confirmed = await ref.read(serverRewardsProvider).claim(grant);
    if (!mounted) return;
    setState(() {
      _claiming = null;
      if (confirmed) _claimed.add(grant.id);
    });
    if (confirmed) {
      ref.invalidate(challengeDetailsProvider(widget.challenge.id));
    } else {
      AppNotification.error(context, Strings.of(context).challengeRewardClaimFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final challenge = widget.challenge;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final muted = textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.7));

    if (challenge.myRewards.isEmpty) {
      // Joined, nothing paid yet: say what the reward waits for.
      final String waiting;
      if (!challenge.hasAcceptedEntry) {
        waiting = s.challengeRewardAfterReview;
      } else if (challenge.isCompetition && !challenge.isCompleted) {
        waiting = s.challengeRewardAfterResults;
      } else {
        waiting = s.challengeRewardSoon;
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 18, color: colors.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Expanded(child: Text(waiting, style: muted)),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final grant in challenge.myRewards)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    switch (grant.reason) {
                      RewardGrantReason.challengePlacement => s.challengeRewardPrize,
                      RewardGrantReason.challengeMention => s.challengeMention,
                      _ => challenge.isCompetition ? s.challengeParticipationReward : s.challengeAcceptedEntryReward,
                    },
                    style: textTheme.bodyMedium,
                  ),
                ),
                if (grant.gems > 0)
                  GemAmount(
                    grant.gems,
                    prefix: '+',
                    color: colors.primary,
                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(width: 12),
                if (grant.isUnclaimed && !_claimed.contains(grant.id))
                  FilledButton(
                    onPressed: _claiming == null ? () => _claim(grant) : null,
                    child: _claiming == grant.id
                        ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.challengeClaimReward),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(s.challengeRewardClaimed, style: textTheme.bodyMedium?.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.label, required this.gems, this.effectPack = false});

  final String label;
  final int gems;
  final bool effectPack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          GemAmount(gems, color: colors.primary, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (effectPack) ...[
            const SizedBox(width: 8),
            Text(
              Strings.of(context).challengeEffectPackReward,
              style: textTheme.labelMedium?.copyWith(color: colors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the user's entries with its review status and any rejection reason.
class _MyEntryRow extends StatelessWidget {
  const _MyEntryRow({required this.number, required this.entry});

  final int number;
  final ChallengeEntrySummary entry;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (label, color, icon) = challengeEntryStatusStyle(context, entry.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${s.challengeEntryNumber(number)}  ·  '),
                      TextSpan(text: label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  style: textTheme.bodyMedium,
                ),
                if (entry.rejectionReason case final reason? when reason.isNotEmpty)
                  Text(reason, style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A community card with its placement ribbon on top.
class _PlacedCard extends StatelessWidget {
  const _PlacedCard({super.key, required this.label, required this.highlight, required this.child});

  final String label;
  final bool highlight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: highlight ? Colors.amber.shade700 : colors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EntriesHeader extends StatelessWidget {
  const _EntriesHeader({
    required this.count,
    required this.showSort,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;

  /// Winners-first sorting only makes sense once winners exist.
  final bool showSort;
  final ChallengeEntrySort sort;
  final ValueChanged<ChallengeEntrySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: s.challengeEntriesTitle),
                TextSpan(
                  text: '  $count',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (showSort)
            SegmentedButton<ChallengeEntrySort>(
              segments: [
                ButtonSegment(value: ChallengeEntrySort.recent, label: Text(s.challengeSortRecent)),
                ButtonSegment(value: ChallengeEntrySort.winners, label: Text(s.challengeWinnersTitle)),
              ],
              selected: {sort},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onSortChanged(selection.first),
            ),
        ],
      ),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.brush_outlined, size: 40, color: colors.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(Strings.of(context).tryAgain)),
        ],
      ),
    );
  }
}
