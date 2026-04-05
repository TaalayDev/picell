import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../screens/subscription_screen.dart';
import '../../../data/models/subscription_model.dart';
import '../../../l10n/strings.dart';
import '../../../providers/subscription_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A widget that controls access to features based on subscription plans.
/// It displays a lock overlay on the child widget if the feature is not available
/// for the current subscription plan.
class FeatureGate extends ConsumerWidget {
  /// The feature that this gate controls
  final SubscriptionFeature feature;

  /// The minimum plan required to access this feature
  final SubscriptionPlan minimumPlan;

  /// The child widget to display
  final Widget child;

  /// Whether to show a visual indicator for premium features
  final bool showPremiumBadge;

  /// Whether to blur the content when locked
  final bool blurWhenLocked;

  /// Custom message to display when locked
  final String? lockedMessage;

  /// Callback when the locked feature is tapped
  final VoidCallback? onLockedTap;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.minimumPlan,
    required this.child,
    this.showPremiumBadge = true,
    this.blurWhenLocked = true,
    this.lockedMessage,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final hasAccess = _hasFeatureAccess(subscriptionState.plan);

    if (hasAccess) {
      return _buildUnlockedContent(context);
    } else {
      return _buildLockedContent(context);
    }
  }

  Widget _buildUnlockedContent(BuildContext context) {
    if (!showPremiumBadge || minimumPlan == SubscriptionPlan.free) {
      return child;
    }

    // Show the child with a subtle premium indicator
    return Stack(
      children: [
        child,
        Positioned(
          top: 4,
          right: 4,
          child: _buildPremiumBadge(context),
        ),
      ],
    );
  }

  Widget _buildPremiumBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            MaterialCommunityIcons.star,
            color: Colors.white,
            size: 10,
          ),
          SizedBox(width: 2),
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().scale(
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildLockedContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onLockedTap != null) {
          onLockedTap!();
        } else {
          _showUpgradeDialog(context);
        }
      },
      child: Stack(
        children: [
          // The child with optional blur effect
          if (blurWhenLocked)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.grey.withValues(alpha: 0.7),
                  BlendMode.saturation,
                ),
                child: child,
              ),
            )
          else
            Opacity(opacity: 0.6, child: child),

          // Lock overlay
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: _buildLockContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ).animate().shake(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            lockedMessage ?? 'PRO Feature',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to Upgrade',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }

  /// Helper method to determine if the feature is accessible
  bool _hasFeatureAccess(SubscriptionPlan currentPlan) {
    // Compare enum ordinals to determine if user has sufficient plan level
    return currentPlan.index >= minimumPlan.index;
  }

  /// Show the upgrade dialog
  void _showUpgradeDialog(BuildContext context) {
    SubscriptionOfferScreen.show(
      context,
      featurePrompt: feature,
    );
  }
}

/// A version of FeatureGate that shows different widgets based on feature availability
class FeatureSwitch extends ConsumerWidget {
  /// The feature that this gate controls
  final SubscriptionFeature feature;

  /// The minimum plan required to access this feature
  final SubscriptionPlan minimumPlan;

  /// The widget to display if the feature is available
  final Widget whenAvailable;

  /// The widget to display if the feature is not available
  final Widget? whenUnavailable;

  /// Callback when the unavailable widget is tapped
  final VoidCallback? onUnavailableTap;

  const FeatureSwitch({
    super.key,
    required this.feature,
    required this.minimumPlan,
    required this.whenAvailable,
    this.whenUnavailable,
    this.onUnavailableTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final hasAccess = _hasFeatureAccess(subscriptionState.plan);

    if (hasAccess) {
      return whenAvailable;
    } else if (whenUnavailable != null) {
      return GestureDetector(
        onTap: () {
          if (onUnavailableTap != null) {
            onUnavailableTap!();
          } else {
            _showUpgradeDialog(context);
          }
        },
        child: whenUnavailable!,
      );
    } else {
      // Return an empty box if no unavailable widget is provided
      return const SizedBox.shrink();
    }
  }

  /// Helper method to determine if the feature is accessible
  bool _hasFeatureAccess(SubscriptionPlan currentPlan) {
    // Compare enum ordinals to determine if user has sufficient plan level
    return currentPlan.index >= minimumPlan.index;
  }

  /// Show the upgrade dialog
  void _showUpgradeDialog(BuildContext context) {
    SubscriptionOfferScreen.show(
      context,
      featurePrompt: feature,
    );
  }
}

/// A widget that displays a pro badge on the corner of a child widget
class ProBadge extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;
  final bool show;

  const ProBadge({
    super.key,
    required this.child,
    this.alignment = const Alignment(5, 5),
    this.padding = EdgeInsets.zero,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = child;
    if (show) {
      widget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => SubscriptionOfferScreen.show(context),
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: padding,
                child: child,
              ),
              Positioned(
                top: alignment.y,
                right: alignment.x,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MaterialCommunityIcons.star,
                        color: Colors.white,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget;
  }
}

/// A widget that shows a prompt to upgrade when a feature is locked
class UpgradePrompt extends StatelessWidget {
  final SubscriptionFeature feature;
  final SubscriptionPlan minimumTier;
  final VoidCallback? onUpgradePressed;

  const UpgradePrompt({
    super.key,
    required this.feature,
    required this.minimumTier,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'This feature requires ${minimumTier.name}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            feature.name,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (onUpgradePressed != null) {
                onUpgradePressed!();
              } else {
                SubscriptionOfferScreen.show(context);
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

/// A button that checks feature access before executing an action
class FeatureButton extends ConsumerWidget {
  final SubscriptionFeature feature;
  final SubscriptionPlan minimumTier;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const FeatureButton({
    super.key,
    required this.feature,
    required this.minimumTier,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(subscriptionStateProvider).hasFeatureAccess(feature);

    return FilledButton(
      style: style,
      onPressed: hasAccess ? onPressed : () => _showUpgradeDialog(context, ref),
      child: child,
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${minimumTier.name} Feature'),
        content: Text(
          'The ${feature.name} feature is available in the '
          '${minimumTier.name} subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              SubscriptionOfferScreen.show(context);
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
