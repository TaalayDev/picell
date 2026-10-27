import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../data/models/subscription_model.dart';
import '../../../l10n/strings.dart';
import '../../../providers/subscription_provider.dart';
import '../../screens/subscription_screen.dart';

/// A widget to display subscription information in a user menu
class SubscriptionMenuItem extends ConsumerWidget {
  const SubscriptionMenuItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionStateProvider);

    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: Icon(
            subscription.plan == SubscriptionPlan.free
                ? MaterialCommunityIcons.star_outline
                : MaterialCommunityIcons.star,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            subscription.plan.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_getSubscriptionStatus(subscription)),
          trailing: TextButton(
            onPressed: () {
              SubscriptionOfferScreen.show(context);
            },
            child: Text(
              subscription.plan == SubscriptionPlan.free ? 'Upgrade' : 'Manage',
            ),
          ),
          onTap: () {
            SubscriptionOfferScreen.show(context);
          },
        ),
        const Divider(),
      ],
    );
  }

  String _getSubscriptionStatus(UserSubscription subscription) {
    if (subscription.plan == SubscriptionPlan.free) {
      return 'Limited features';
    }

    // if (subscription.expiryDate != null) {
    //   final formatter = DateFormat.yMMMd();
    //   final endDate = formatter.format(subscription.expiryDate!);

    //   return 'Renews on $endDate';
    // }

    return subscription.plan.name;
  }
}

/// A badge to show subscription status in the app bar
class SubscriptionBadge extends ConsumerWidget {
  const SubscriptionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(subscriptionStateProvider).plan;

    if (plan == SubscriptionPlan.free) {
      return IconButton(
        icon: const Icon(MaterialCommunityIcons.star_outline),
        tooltip: 'Upgrade',
        onPressed: () {
          SubscriptionOfferScreen.show(context);
        },
      );
    }

    return IconButton(
      icon: Badge(
        label: Text(
          plan == SubscriptionPlan.ultimate ? 'Ultimate' : 'Pro',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: const Icon(MaterialCommunityIcons.star),
      ),
      tooltip: '${plan.name} Subscription',
      onPressed: () {
        SubscriptionOfferScreen.show(context);
      },
    );
  }
}

class SubscriptionPromoBanner extends ConsumerWidget {
  final VoidCallback? onDismiss;

  const SubscriptionPromoBanner({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(subscriptionStateProvider).plan;

    // Only show for free users
    if (plan != SubscriptionPlan.free) {
      return const SizedBox.shrink();
    }

    final pv = context.pv;
    final strings = Strings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Material(
        color: pv.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: pv.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => SubscriptionOfferScreen.show(context),
          child: Stack(
            children: [
              Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: DecoratedBox(decoration: BoxDecoration(gradient: pv.gradient))),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.workspace_premium, size: 18, color: pv.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.promoBannerSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: pv.body(size: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(strings.upgrade, style: pv.body(size: 13, color: pv.accent, weight: FontWeight.w700)),
                    if (onDismiss != null)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        icon: Icon(Icons.close, size: 18, color: pv.textSecondary),
                        onPressed: onDismiss,
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
