import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pro Access Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have ${_formatRemainingTime(subscription.temporaryProAccess?.remainingTime)} of Pro access remaining.',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.diamond, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Unlimited access to all features\n• One-time purchase\n• No ads\n• Priority support',
                  style: TextStyle(fontSize: 14),
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
                  const Row(
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Try Pro for 45 Minutes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rewardAdState
                        ? '• Watch a short video ad\n• Get 45 minutes of Pro access\n• Support the app development'
                        : '• Video ad is loading...\n• Please try again in a moment',
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
            child: Text(rewardAdState ? 'Watch Ad' : 'Loading...'),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            SubscriptionOfferScreen.show(context);
          },
          child: const Text('Buy Pro'),
        ),
      ],
    );
  }

  String _formatRemainingTime(Duration? duration) {
    if (duration == null || duration <= Duration.zero) return '0 minutes';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<void> _watchVideoForTemporaryPro(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading video ad...'),
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
            const SnackBar(
              content: Text('🎉 Pro access granted for 45 minutes!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video ad was not completed. Please try again or upgrade to Pro.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video ad: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
