import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/subscription_model.dart';
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
          plan != SubscriptionPlan.free ? 'Premium' : 'Pro',
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

class SubscriptionPromoBanner extends ConsumerStatefulWidget {
  final VoidCallback? onDismiss;

  const SubscriptionPromoBanner({super.key, this.onDismiss});

  @override
  ConsumerState<SubscriptionPromoBanner> createState() => _SubscriptionPromoBannerState();
}

class _SubscriptionPromoBannerState extends ConsumerState<SubscriptionPromoBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(subscriptionStateProvider).plan;

    // Only show for free users
    if (plan != SubscriptionPlan.free) {
      return const SizedBox.shrink();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    Color.lerp(primaryColor, secondaryColor, 0.7)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => SubscriptionOfferScreen.show(context),
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        _buildSparklingStar(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Upgrade to Pro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlock advanced tools, unlimited projects, and more!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildUpgradeButton(),
                        if (widget.onDismiss != null) ...[
                          const SizedBox(width: 8),
                          _buildDismissButton(),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparklingStar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          MaterialCommunityIcons.star,
          color: Colors.white,
          size: 24,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2.seconds, color: Colors.white)
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(duration: 8.seconds);
  }

  Widget _buildUpgradeButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => SubscriptionOfferScreen.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'UPGRADE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideX(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildDismissButton() {
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.white, size: 18),
      onPressed: widget.onDismiss,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
