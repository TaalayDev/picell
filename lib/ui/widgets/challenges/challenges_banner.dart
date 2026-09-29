import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/challenge_models.dart';
import '../../../l10n/strings.dart';
import '../../../data/storage/local_storage.dart';
import '../../../providers/challenges_provider.dart';
import '../../screens/challenge_screen.dart';
import '../progression/quests_view.dart';

/// Active challenges on the projects screen. Hidden while loading, on errors
/// and when nothing is running, so it never pushes the page around.
class ChallengesBanner extends HookConsumerWidget {
  const ChallengesBanner({super.key, this.onStartDrawing, this.padding = EdgeInsets.zero});

  /// Opens a new project from the challenge details.
  final VoidCallback? onStartDrawing;

  /// Applied only while the banner is visible, so a hidden banner leaves no gap.
  final EdgeInsetsGeometry padding;

  static const double _minCardWidth = 300;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentChallengesProvider).valueOrNull;

    // Countdowns show minutes, so a redraw every 30 seconds is enough.
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick.value++);
      return timer.cancel;
    }, const []);

    if (current == null) return const SizedBox.shrink();
    final challenges = current.running();
    if (challenges.isEmpty) return const SizedBox.shrink();

    final cardHeight = 92 + MediaQuery.textScalerOf(context).scale(52);
    void open(Challenge challenge) => ChallengeScreen.show(
          context,
          challenge: challenge,
          serverNow: current.serverNow,
          onStartDrawing: onStartDrawing,
        );
    Widget card(Challenge challenge) => _ChallengeCard(
          key: ValueKey('challenge-card-${challenge.id}'),
          challenge: challenge,
          serverNow: current.serverNow(),
          onTap: () => open(challenge),
        );
    // A big card needs a cover to look right; the rest are compact tiles.
    final withCover = challenges.where((challenge) => challenge.hasCover).toList();
    final withoutCover = challenges.where((challenge) => !challenge.hasCover).toList();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  Strings.of(context).challengesTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (withCover.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final fitsInRow =
                    withCover.length * _minCardWidth + (withCover.length - 1) * _gap <= constraints.maxWidth;
                if (fitsInRow) {
                  return SizedBox(
                    height: cardHeight,
                    child: Row(
                      children: [
                        for (final (index, challenge) in withCover.indexed) ...[
                          if (index > 0) const SizedBox(width: _gap),
                          Expanded(child: card(challenge)),
                        ],
                      ],
                    ),
                  );
                }
                return _ChallengeCarousel(
                    height: cardHeight, children: [for (final challenge in withCover) card(challenge)]);
              },
            ),
          if (withCover.isNotEmpty && withoutCover.isNotEmpty) const SizedBox(height: 8),
          for (final challenge in withoutCover)
            ChallengeTile(
              key: ValueKey('challenge-tile-${challenge.id}'),
              challenge: challenge,
              remaining: challenge.endsAt.difference(current.serverNow()),
              onTap: () => open(challenge),
            ),
        ],
      ),
    );
  }
}

/// Swipeable cards with a peek of the next one and page dots.
class _ChallengeCarousel extends HookWidget {
  const _ChallengeCarousel({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController(viewportFraction: 0.9);
    final page = useState(0);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView(
            controller: controller,
            padEnds: false,
            onPageChanged: (index) => page.value = index,
            children: [
              for (final child in children) Padding(padding: const EdgeInsets.only(right: 12), child: child),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < children.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page.value ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == page.value ? colors.primary : colors.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String challengeCadenceLabel(BuildContext context, ChallengeCadence cadence) {
  final s = Strings.of(context);
  return switch (cadence) {
    ChallengeCadence.daily => s.challengeCadenceDaily,
    ChallengeCadence.weekly => s.challengeCadenceWeekly,
    ChallengeCadence.monthly => s.challengeCadenceMonthly,
    ChallengeCadence.seasonal => s.challengeCadenceSeasonal,
  };
}

/// Label, color and icon for an entry status (`pending`, `accepted`, ...).
(String, Color, IconData) challengeEntryStatusStyle(BuildContext context, String status) {
  final s = Strings.of(context);
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    'accepted' => (s.challengeEntryAccepted, Colors.green.shade600, Icons.check_circle_outline),
    'winner' => (s.challengeEntryWinner, colors.primary, Icons.emoji_events_outlined),
    'rejected' => (s.challengeEntryRejected, colors.error, Icons.cancel_outlined),
    'withdrawn' => (s.challengeEntryWithdrawn, colors.onSurface.withValues(alpha: 0.6), Icons.undo),
    _ => (s.challengeEntryPending, Colors.orange.shade700, Icons.hourglass_top_rounded),
  };
}

/// "2d 5h", "5h 12m" or "12m"; never below one minute while running.
String formatChallengeRemaining(BuildContext context, Duration remaining) {
  final s = Strings.of(context);
  final minutes = remaining.inMinutes < 1 ? 1 : remaining.inMinutes;
  if (minutes >= 24 * 60) return s.durationDaysHours(minutes ~/ (24 * 60), (minutes % (24 * 60)) ~/ 60);
  if (minutes >= 60) return s.durationHoursMinutes(minutes ~/ 60, minutes % 60);
  return s.durationMinutes(minutes);
}

/// The challenge cover, or the diamond mark when there is none or it fails
/// to load. Pixel art is scaled without smoothing so it stays crisp.
class ChallengeCover extends StatelessWidget {
  const ChallengeCover({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const ChallengeDiamond(),
    );
    final cover = url;
    if (cover == null || cover.isEmpty) return fallback;
    return Image.network(
      cover,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        child: child,
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({super.key, required this.challenge, required this.serverNow, required this.onTap});

  final Challenge challenge;
  final DateTime serverNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final textTheme = Theme.of(context).textTheme;
    const light = Colors.white;
    final quiet = Colors.white.withValues(alpha: 0.85);

    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChallengeCover(url: challenge.coverImageUrl),
            // Darkens the lower part so white text stays readable on any cover.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Pill(child: Text(challengeCadenceLabel(context, challenge.cadence))),
                      const Spacer(),
                      if (challenge.joined)
                        _Pill(
                          color: Colors.green.shade600,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 12, color: light),
                              const SizedBox(width: 3),
                              Text(s.challengeJoined),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    challenge.title,
                    style: textTheme.titleMedium?.copyWith(color: light, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: quiet),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          [
                            s.challengeEndsIn(
                                formatChallengeRemaining(context, challenge.endsAt.difference(serverNow))),
                            s.challengeEntries(challenge.entryCount),
                          ].join('  ·  '),
                          style: textTheme.bodySmall?.copyWith(color: quiet),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (challenge.topGems > 0)
                        GemAmount(
                          challenge.topGems,
                          color: light,
                          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The diamond mark shown where a challenge has no cover image.
class ChallengeDiamond extends StatelessWidget {
  const ChallengeDiamond({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SvgPicture.asset('assets/vectors/diamond.svg', fit: BoxFit.contain),
    );
  }
}

/// A compact row for one challenge: cover (or diamond), title, cadence and
/// time left, and the joined mark or the top prize.
class ChallengeTile extends StatelessWidget {
  const ChallengeTile({super.key, required this.challenge, required this.remaining, required this.onTap, this.margin});

  final Challenge challenge;
  final Duration remaining;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(dimension: 52, child: ChallengeCover(url: challenge.coverImageUrl)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        challengeCadenceLabel(context, challenge.cadence),
                        s.challengeEndsIn(formatChallengeRemaining(context, remaining)),
                      ].join('  ·  '),
                      style: textTheme.labelSmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (challenge.joined)
                Icon(Icons.check_circle, color: Colors.green.shade600, semanticLabel: s.challengeJoined)
              else if (challenge.topGems > 0)
                GemAmount(
                  challenge.topGems,
                  color: colors.primary,
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop: running challenges in a card floating over the bottom-right
/// corner. Closing it hides it until the set of running challenges changes,
/// so a new challenge always shows up again.
class ChallengesFloatingPanel extends HookConsumerWidget {
  const ChallengesFloatingPanel({super.key, this.onStartDrawing, this.width = 340});

  final VoidCallback? onStartDrawing;
  final double width;

  static const _dismissedKey = 'challenges_panel_dismissed_v1';

  static String? _readDismissed() {
    try {
      return LocalStorage.instance.getString(_dismissedKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentChallengesProvider).valueOrNull;
    final dismissed = useState(_readDismissed());

    // Countdowns show minutes, so a redraw every 30 seconds is enough.
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick.value++);
      return timer.cancel;
    }, const []);

    final challenges = current?.running() ?? const <Challenge>[];
    final signature = (challenges.map((challenge) => challenge.id).toList()..sort()).join(',');
    final visible = current != null && challenges.isNotEmpty && dismissed.value != signature;

    void close() {
      dismissed.value = signature;
      try {
        LocalStorage.instance.setString(_dismissedKey, signature);
      } catch (_) {}
    }

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: !visible
          ? const SizedBox.shrink()
          : SizedBox(
              key: const ValueKey('challenges-floating-panel'),
              width: width,
              child: Material(
                elevation: 8,
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 4, 0),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 18, color: colors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                Strings.of(context).challengesTitle,
                                style: textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('close-challenges-panel'),
                              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: close,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          children: [
                            for (final challenge in challenges)
                              ChallengeTile(
                                key: ValueKey('floating-challenge-${challenge.id}'),
                                challenge: challenge,
                                remaining: challenge.endsAt.difference(current.serverNow()),
                                margin: const EdgeInsets.only(bottom: 6),
                                onTap: () => ChallengeScreen.show(
                                  context,
                                  challenge: challenge,
                                  serverNow: current.serverNow,
                                  onStartDrawing: onStartDrawing,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
