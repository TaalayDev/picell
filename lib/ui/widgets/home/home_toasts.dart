import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/strings.dart';
import '../../../providers/challenges_provider.dart';
import '../challenges/challenges_banner.dart';
import '../discovery/whats_new.dart';
import '../pv/pv.dart';
import '../../../app/theme/theme.dart';

/// Closable notification cards stacked in the bottom-right corner of the
/// desktop projects screen: What's New and running challenges.
class HomeToasts extends ConsumerWidget {
  const HomeToasts({
    super.key,
    required this.showWhatsNew,
    required this.showChallenges,
    required this.onCloseWhatsNew,
    required this.onCloseChallenges,
    this.onStartDrawing,
    this.onOpenBoneRigExample,
  });

  final bool showWhatsNew;
  final bool showChallenges;
  final VoidCallback onCloseWhatsNew;
  final VoidCallback onCloseChallenges;
  final VoidCallback? onStartDrawing;
  final VoidCallback? onOpenBoneRigExample;

  static const double width = 380;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = Strings.of(context);
    final hasChallenges = ref.watch(currentChallengesProvider).valueOrNull?.running().isNotEmpty ?? false;
    final challengesVisible = showChallenges && hasChallenges;
    if (!showWhatsNew && !challengesVisible) return const SizedBox.shrink();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (challengesVisible)
              _ToastCard(
                key: const ValueKey('toast-challenges'),
                title: strings.challengesTitle,
                onClose: onCloseChallenges,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: ChallengesBanner(showHeader: false, onStartDrawing: onStartDrawing),
                  ),
                ),
              ),
            if (challengesVisible && showWhatsNew) const SizedBox(height: 12),
            if (showWhatsNew)
              _ToastCard(
                key: const ValueKey('toast-whats-new'),
                title: strings.whatsNew,
                onClose: onCloseWhatsNew,
                child: WhatsNewTitles(onOpenBoneRigExample: onOpenBoneRigExample),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({super.key, required this.title, required this.onClose, required this.child});

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Material(
      color: pv.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pv.cardRadius),
        side: BorderSide(color: pv.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PvSectionHeader(
              title: title,
              icon: Icons.campaign_outlined,
              padding: const EdgeInsets.only(left: 4),
              trailing: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: pv.textSecondary,
                onPressed: onClose,
                icon: const Icon(Feather.x),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
