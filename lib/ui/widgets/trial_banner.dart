import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';

/// Shows how long a running plan trial has left, and leads to the plans so the
/// user can keep what they are trying. Renders nothing without a trial.
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trial = ref.watch(subscriptionStateProvider.select((s) => s.planTrial));
    // A purchase made during the trial makes the countdown moot.
    final owned = ref.watch(subscriptionStateProvider.select((s) => s.plan.isPaid));
    if (trial == null || !trial.isActive || owned) return const SizedBox.shrink();

    final strings = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final plan = trial.tier == SubscriptionPlan.ultimate ? strings.planUltimate : strings.planPro;
    final label = trial.endsToday ? strings.trialBannerEndsToday(plan) : strings.trialBannerDaysLeft(plan, trial.daysLeft);

    return Material(
      key: const ValueKey('trial-banner'),
      color: colors.primaryContainer,
      child: InkWell(
        onTap: () {
          ref.read(analyticsProvider).logEvent(name: 'trial_banner_tapped', parameters: {'subject': trial.tier.name});
          SubscriptionOfferScreen.show(context);
        },
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.hourglass_bottom, size: 18, color: colors.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Text(
                  strings.trialSeePlans,
                  style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Icon(Icons.chevron_right, size: 18, color: colors.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
