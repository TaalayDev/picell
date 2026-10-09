import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/providers/subscription_provider.dart';

import '../../providers/app_settings_provider.dart';
import 'ad_banner.dart';

class AdWrapper extends ConsumerWidget {
  const AdWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!isMobile) return child;

    final settings = ref.watch(appSettingsProvider);
    final subscription = ref.watch(subscriptionStateProvider);
    if (!settings.mobileBottomBannerEnabled || subscription.isPro) return child;

    return SafeArea(
      top: false,
      child: Column(
          children: [Expanded(child: child), const AdBanner(height: 50)]),
    );
  }
}
