import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/strings.dart';
import '../../../providers/ad/reward_video_ad_controller.dart';
import '../../../providers/subscription_provider.dart';
import '../../screens/subscription_screen.dart';

class RewardDialog extends HookConsumerWidget {
  const RewardDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRewardEarned,
    this.showTemporaryProOption = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onRewardEarned,
    bool showTemporaryProOption = true,
  }) {
    return showDialog(
      context: context,
      builder: (context) => RewardDialog(
        title: title,
        subtitle: subtitle,
        onRewardEarned: onRewardEarned,
        showTemporaryProOption: showTemporaryProOption,
      ),
    );
  }

  final String title;
  final String subtitle;
  final VoidCallback? onRewardEarned;
  final bool showTemporaryProOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final rewardAdState = ref.watch(rewardVideoAdProvider);
    final subscription = ref.watch(subscriptionStateProvider);

    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Show current temporary pro status if active
          if (subscription.hasTemporaryPro) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        s.proAccessActive,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.proAccessRemaining(_formatRemainingTime(
                      context,
                      subscription.temporaryProAccess?.remainingTime,
                    )),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Premium upgrade option
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.diamond, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.upgradeToPro,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.rewardUpgradeBullets,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Temporary pro access option (only show if not already active and enabled)
          if (showTemporaryProOption && !subscription.hasTemporaryPro) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.tryPro45Minutes,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rewardAdState
                        ? s.rewardAdReadyBullets
                        : s.rewardAdLoadingBullets,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        // TextButton(
        //   onPressed: () {
        //     Navigator.of(context).pop();
        //   },
        //   child: const Text('Maybe Later'),
        // ),
        if (showTemporaryProOption && !subscription.hasTemporaryPro)
          ElevatedButton(
            onPressed: rewardAdState
                ? () async {
                    Navigator.of(context).pop();
                    await _watchVideoForTemporaryPro(context, ref);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(rewardAdState ? s.watchAd : s.loadingEllipsis),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            SubscriptionOfferScreen.show(context);
          },
          child: Text(s.buyPro),
        ),
      ],
    );
  }

  String _formatRemainingTime(BuildContext context, Duration? duration) {
    final s = Strings.of(context);
    if (duration == null || duration <= Duration.zero) {
      return s.rewardTimeZeroMinutes;
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return s.rewardTimeMinutesSeconds(minutes, seconds);
    } else {
      return s.rewardTimeSeconds(seconds);
    }
  }

  Future<void> _watchVideoForTemporaryPro(
      BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(Strings.of(context).loadingVideoAd),
            ],
          ),
        ),
      );

      final rewardController = ref.read(rewardVideoAdProvider.notifier);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final rewardEarned = await rewardController.showAdIfLoaded();
      debugPrint('Reward video ad completed: $rewardEarned');

      if (rewardEarned) {
        onRewardEarned?.call();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Strings.of(context).proAccessGranted45),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Strings.of(context).videoAdNotCompleted),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Strings.of(context).failedToLoadVideoAd('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
