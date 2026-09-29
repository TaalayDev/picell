import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/challenge_models.dart';
import '../../l10n/strings.dart';
import '../../providers/challenges_provider.dart';
import '../widgets/challenges/challenges_banner.dart';
import 'challenge_screen.dart';

/// Every challenge the user entered, newest first, with each entry's review
/// status, placement and rejection reason.
class MyChallengeEntriesScreen extends ConsumerWidget {
  const MyChallengeEntriesScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MyChallengeEntriesScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final entries = ref.watch(myChallengeEntriesProvider);

    Future<void> refresh() async {
      ref.invalidate(myChallengeEntriesProvider);
      await ref.read(myChallengeEntriesProvider.future).catchError((_) => const <MyChallengeEntry>[]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.challengeYourEntries)),
      body: entries.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Message(
          icon: Icons.cloud_off_outlined,
          text: s.myChallengeEntriesLoadFailed,
          action: OutlinedButton(onPressed: refresh, child: Text(s.tryAgain)),
        ),
        data: (entries) {
          final groups = _groupByChallenge(entries);
          return RefreshIndicator(
            onRefresh: refresh,
            child: groups.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _Message(icon: Icons.emoji_events_outlined, text: s.myChallengeEntriesEmpty),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const maxWidth = 720.0;
                      final horizontal = constraints.maxWidth > maxWidth + 32 ? (constraints.maxWidth - maxWidth) / 2 : 16.0;
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, index) => _ChallengeGroup(entries: groups[index]),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  /// Entries of the same challenge together, in the order the list arrived.
  static List<List<MyChallengeEntry>> _groupByChallenge(List<MyChallengeEntry> entries) {
    final groups = <int, List<MyChallengeEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.challengeId, () => []).add(entry);
    }
    return groups.values.toList();
  }
}

class _ChallengeGroup extends StatelessWidget {
  const _ChallengeGroup({required this.entries});

  /// Entries of one challenge; never empty.
  final List<MyChallengeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final first = entries.first;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    final String? stage = switch (first.challengeStatus) {
      'active' when first.endsAt != null && first.endsAt!.isAfter(DateTime.now()) =>
        s.challengeEndsIn(formatChallengeRemaining(context, first.endsAt!.difference(DateTime.now()))),
      'judging' => s.challengeStatusJudging,
      'completed' => s.challengeStatusCompleted,
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ChallengeScreen.open(context, challengeId: first.challengeId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.challengeTitle.isEmpty ? '#${first.tag}' : first.challengeTitle,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            challengeCadenceLabel(context, first.cadence),
                            '#${first.tag}',
                            if (stage != null) stage,
                          ].join('  ·  '),
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: muted),
                ],
              ),
              const SizedBox(height: 8),
              for (final entry in entries) _EntryRow(entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final MyChallengeEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (label, color, icon) = challengeEntryStatusStyle(context, entry.status);
    final result = switch (entry) {
      MyChallengeEntry(:final place?) => s.challengePlace(place),
      MyChallengeEntry(isMention: true) => s.challengeMention,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: colors.surfaceContainerHighest,
              child: CachedNetworkImage(
                imageUrl: entry.thumbnailUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorWidget: (_, __, ___) => Icon(Icons.image_not_supported_outlined, color: colors.outline),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.projectTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (result != null)
                      Text(result, style: theme.textTheme.bodyMedium?.copyWith(color: colors.primary)),
                  ],
                ),
                if (entry.status == 'rejected' && (entry.rejectionReason?.isNotEmpty ?? false))
                  Text(
                    entry.rejectionReason!,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: colors.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
